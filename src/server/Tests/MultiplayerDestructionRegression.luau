--!strict

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StudioTestService: any = nil
if RunService:IsStudio() then
	StudioTestService = game:GetService("StudioTestService")
end

local Config = require(ReplicatedStorage.Shared.Config)
local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)
local LocalizedDamage = require(ReplicatedStorage.Shared.LocalizedDamage)
local PlayerRole = require(ReplicatedStorage.Shared.PlayerRole)
local StudioTestProtocol = require(ReplicatedStorage.Shared.StudioTestProtocol)

type RoundService = {
	GetPhase: (self: RoundService) -> string,
}

type ClientReport = {
	player: Player,
	state: string,
	sequence: number,
	health: number,
	intactVisible: number,
	damagedVisible: number,
	collapsedVisible: number,
	debrisCount: number,
	damageZoneState: string,
	impactSequence: number,
	localizedHoleCount: number,
	localizedPartCount: number,
	localizedMaximumSpan: number,
	damagedNeonCount: number,
	smashAnimationCount: number,
	smashAnimationPhase: string,
	role: string,
	cameraMin: number,
	cameraMax: number,
	cameraType: string,
	hasSmashButton: boolean,
	hasHumanFireButton: boolean,
	hasHumanReticle: boolean,
	characterHealth: number,
}

local MultiplayerDestructionRegression = {}

local function isRequestedTest(): boolean
	if StudioTestService == nil then
		return false
	end

	local ok, args = pcall(function()
		return StudioTestService:GetTestArgs()
	end)
	return ok and args == StudioTestProtocol.MultiplayerDestructionTest
end

local function waitUntil(predicate: () -> boolean, timeoutSeconds: number): boolean
	local deadline = os.clock() + timeoutSeconds
	while os.clock() < deadline do
		if predicate() then
			return true
		end
		task.wait(0.1)
	end
	return predicate()
end

local function findTargetById(structureId: string): Model?
	for _, tagged in CollectionService:GetTagged(DestructibleContract.Tag) do
		if
			tagged:IsA("Model")
			and tagged:GetAttribute(DestructibleContract.Attribute.StructureId) == structureId
		then
			return tagged
		end
	end
	return nil
end

local function parseReport(player: Player, payload: any): ClientReport?
	if
		type(payload.state) ~= "string"
		or type(payload.sequence) ~= "number"
		or type(payload.health) ~= "number"
		or type(payload.intactVisible) ~= "number"
		or type(payload.damagedVisible) ~= "number"
		or type(payload.collapsedVisible) ~= "number"
		or type(payload.debrisCount) ~= "number"
		or type(payload.damageZoneState) ~= "string"
		or type(payload.impactSequence) ~= "number"
		or type(payload.localizedHoleCount) ~= "number"
		or type(payload.localizedPartCount) ~= "number"
		or type(payload.localizedMaximumSpan) ~= "number"
		or type(payload.damagedNeonCount) ~= "number"
		or type(payload.smashAnimationCount) ~= "number"
		or type(payload.smashAnimationPhase) ~= "string"
		or type(payload.role) ~= "string"
		or type(payload.cameraMin) ~= "number"
		or type(payload.cameraMax) ~= "number"
		or type(payload.cameraType) ~= "string"
		or type(payload.hasSmashButton) ~= "boolean"
		or type(payload.hasHumanFireButton) ~= "boolean"
		or type(payload.hasHumanReticle) ~= "boolean"
		or type(payload.characterHealth) ~= "number"
	then
		return nil
	end

	return {
		player = player,
		state = payload.state,
		sequence = payload.sequence,
		health = payload.health,
		intactVisible = payload.intactVisible,
		damagedVisible = payload.damagedVisible,
		collapsedVisible = payload.collapsedVisible,
		debrisCount = payload.debrisCount,
		damageZoneState = payload.damageZoneState,
		impactSequence = payload.impactSequence,
		localizedHoleCount = payload.localizedHoleCount,
		localizedPartCount = payload.localizedPartCount,
		localizedMaximumSpan = payload.localizedMaximumSpan,
		damagedNeonCount = payload.damagedNeonCount,
		smashAnimationCount = payload.smashAnimationCount,
		smashAnimationPhase = payload.smashAnimationPhase,
		role = payload.role,
		cameraMin = payload.cameraMin,
		cameraMax = payload.cameraMax,
		cameraType = payload.cameraType,
		hasSmashButton = payload.hasSmashButton,
		hasHumanFireButton = payload.hasHumanFireButton,
		hasHumanReticle = payload.hasHumanReticle,
		characterHealth = payload.characterHealth,
	}
end

local function reportMatchesCollapsedState(report: ClientReport): boolean
	return report.state == "Collapsed"
		and report.sequence == 2
		and report.health == 0
		and report.intactVisible == 0
		and report.damagedVisible == 0
		and report.collapsedVisible > 0
		and report.localizedHoleCount == 0
		and report.localizedPartCount == 0
end

local function reportMatchesLocalizedDamage(report: ClientReport): boolean
	return report.state == "Damaged"
		and report.sequence == 1
		and report.health == 4
		and report.intactVisible == 0
		and report.damagedVisible > 0
		and report.collapsedVisible == 0
		and report.impactSequence == 1
		and LocalizedDamage.CountMarks(report.damageZoneState) == 1
		and report.localizedHoleCount == 1
		and report.localizedPartCount == 8
		and report.localizedMaximumSpan >= 22
		and report.damagedNeonCount == 0
end

local function countBaseParts(root: Instance): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			count += 1
		end
	end
	return count
end

function MultiplayerDestructionRegression.TryStart(roundService: RoundService, remotes: Folder)
	if not isRequestedTest() then
		return
	end

	task.spawn(function()
		local completed = false
		local testRemote = Instance.new("RemoteEvent")
		testRemote.Name = StudioTestProtocol.RemoteName
		testRemote.Parent = remotes

		local readyPlayers = {} :: { [Player]: boolean }
		local reports = {} :: { [string]: ClientReport }
		local reportErrors = {} :: { [string]: string }
		local connection = testRemote.OnServerEvent:Connect(function(player, payload)
			if type(payload) ~= "table" or type(payload.kind) ~= "string" then
				return
			end
			if payload.kind == "ready" then
				readyPlayers[player] = true
				return
			end
			if
				payload.kind == "report_error"
				and type(payload.stage) == "string"
				and type(payload.reason) == "string"
			then
				reportErrors[payload.stage] = payload.reason
				return
			end
			if payload.kind ~= "report" or type(payload.stage) ~= "string" then
				return
			end

			local report = parseReport(player, payload)
			if report then
				reports[payload.stage] = report
			end
		end)

		local function finish(result: { [string]: any })
			if completed then
				return
			end
			completed = true
			connection:Disconnect()
			testRemote:Destroy()
			StudioTestService:EndTest(result)
		end

		local function fail(reason: string)
			finish({ passed = false, reason = reason })
		end

		if not waitUntil(function()
			return #Players:GetPlayers() == 1
		end, 20) then
			fail("initial client did not join")
			return
		end

		local firstPlayer = Players:GetPlayers()[1]
		if not waitUntil(function()
			return readyPlayers[firstPlayer] == true
		end, 20) then
			fail("initial client harness did not become ready")
			return
		end

		local target = findTargetById(StudioTestProtocol.TargetStructureId)
		if not target then
			fail("target destructible was not registered")
			return
		end

		local world = workspace:FindFirstChild(Config.Prototype.WorldName)
		local plant = world and world:FindFirstChild("ArcPowerPlantZone")
		if not plant or not plant:IsA("Model") then
			fail("Arc Power Plant dressing was unavailable")
			return
		end
		for _, requiredName in
			{
				"CoolingWaterHeader",
				"SteamServiceHeader",
				"TransmissionSwitchyard",
				"StepUpTransformer1",
				"HighVoltageBusbar1",
				"TransmissionGantryCrossarm",
			}
		do
			if not plant:FindFirstChild(requiredName, true) then
				fail(`Arc Power Plant was missing {requiredName}`)
				return
			end
		end
		for _, descendant in plant:GetDescendants() do
			if string.find(descendant.Name, "EnergyChannel", 1, true) then
				fail("Arc Power Plant retained decorative EnergyChannel floor lights")
				return
			end
		end
		local plantDressingParts = countBaseParts(plant)
		if plantDressingParts < 30 or plantDressingParts > 36 then
			fail(`Arc Power Plant dressing part budget was {plantDressingParts}`)
			return
		end

		if not waitUntil(function()
			return roundService:GetPhase() == "Active"
		end, 15) then
			fail("round did not become active")
			return
		end

		local character = firstPlayer.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if not root or not root:IsA("BasePart") then
			fail("initial client character was not ready")
			return
		end

		local localizedTarget = findTargetById(StudioTestProtocol.LocalizedTargetStructureId)
		if not localizedTarget then
			fail("localized-damage cooling tower was not registered")
			return
		end
		local localizedHitbox = localizedTarget:FindFirstChild("DamageHitbox")
		if not localizedHitbox or not localizedHitbox:IsA("BasePart") then
			fail("localized-damage cooling tower hitbox was unavailable")
			return
		end
		local localizedTargetPosition = localizedHitbox.Position
		local localizedAttackPosition = localizedTargetPosition
			+ Vector3.new(
				0,
				-5,
				localizedHitbox.Size.Z * 0.5 + Config.Combat.BasicAttackForwardOffset
			)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = CFrame.lookAt(localizedAttackPosition, localizedTargetPosition)
		testRemote:FireClient(firstPlayer, { command = "attack", hits = 1 })

		if
			not waitUntil(function()
				local zoneState =
					localizedTarget:GetAttribute(DestructibleContract.Attribute.DamageZoneState)
				return localizedTarget:GetAttribute(DestructibleContract.Attribute.State)
						== "Damaged"
					and localizedTarget:GetAttribute(DestructibleContract.Attribute.ImpactSequence) == 1
					and type(zoneState) == "string"
					and LocalizedDamage.CountMarks(zoneState) == 1
			end, 8)
		then
			fail("cooling tower did not record the first localized Smash impact")
			return
		end
		-- Ability results and harness commands use separate RemoteEvents, so wait for the
		-- confirmed client-side pose to finish before asking the client to report it.
		task.wait(
			Config.Combat.SmashWindupSeconds
				+ Config.Combat.SmashStrikeSeconds
				+ Config.Combat.SmashImpactHoldSeconds
				+ Config.Combat.SmashRecoverySeconds
				+ 0.1
		)

		testRemote:FireClient(firstPlayer, {
			command = "report",
			stage = StudioTestProtocol.LocalizedExistingStage,
			structureId = StudioTestProtocol.LocalizedTargetStructureId,
			expectedState = "Damaged",
		})
		if
			not waitUntil(function()
				return reports[StudioTestProtocol.LocalizedExistingStage] ~= nil
					or reportErrors[StudioTestProtocol.LocalizedExistingStage] ~= nil
			end, 10)
		then
			fail("initial client did not report localized cooling-tower damage")
			return
		end
		if reportErrors[StudioTestProtocol.LocalizedExistingStage] then
			fail(
				`initial localized report failed: {reportErrors[StudioTestProtocol.LocalizedExistingStage]}`
			)
			return
		end
		if not reportMatchesLocalizedDamage(reports[StudioTestProtocol.LocalizedExistingStage]) then
			fail("initial client localized rupture did not match the server zone")
			return
		end
		if reports[StudioTestProtocol.LocalizedExistingStage].smashAnimationCount < 1 then
			fail(
				`initial client did not play the confirmed Smash animation (phase={reports[StudioTestProtocol.LocalizedExistingStage].smashAnimationPhase})`
			)
			return
		end

		local targetPosition = target.DamageHitbox.Position
		local attackPosition = targetPosition + Vector3.new(0, 4, 18)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = CFrame.lookAt(attackPosition, targetPosition)
		testRemote:FireClient(firstPlayer, { command = "attack", hits = 3 })

		if
			not waitUntil(function()
				return target:GetAttribute(DestructibleContract.Attribute.State) == "Collapsed"
			end, 10)
		then
			fail("warehouse did not collapse through the client attack path")
			return
		end
		task.wait(
			Config.Combat.SmashWindupSeconds
				+ Config.Combat.SmashStrikeSeconds
				+ Config.Combat.SmashImpactHoldSeconds
				+ Config.Combat.SmashRecoverySeconds
				+ 0.1
		)

		testRemote:FireClient(firstPlayer, {
			command = "report",
			stage = StudioTestProtocol.ExistingClientStage,
			structureId = StudioTestProtocol.TargetStructureId,
			expectedState = "Collapsed",
		})
		if
			not waitUntil(function()
				return reports[StudioTestProtocol.ExistingClientStage] ~= nil
					or reportErrors[StudioTestProtocol.ExistingClientStage] ~= nil
			end, 10)
		then
			fail("initial client did not report collapsed state")
			return
		end
		if reportErrors[StudioTestProtocol.ExistingClientStage] then
			fail(
				`initial client report failed: {reportErrors[StudioTestProtocol.ExistingClientStage]}`
			)
			return
		end

		StudioTestService:AddPlayers(1)
		if not waitUntil(function()
			return #Players:GetPlayers() == 2
		end, 20) then
			fail("late client did not join")
			return
		end

		local latePlayer: Player? = nil
		for _, player in Players:GetPlayers() do
			if player ~= firstPlayer then
				latePlayer = player
				break
			end
		end
		if not latePlayer then
			fail("late client identity was not found")
			return
		end
		local resolvedLatePlayer = latePlayer :: Player

		if
			not waitUntil(function()
				return readyPlayers[resolvedLatePlayer] == true
					and firstPlayer.Character ~= nil
					and resolvedLatePlayer.Character ~= nil
			end, 20)
		then
			fail("late client harness did not become ready")
			return
		end

		if
			firstPlayer:GetAttribute(PlayerRole.Attribute) ~= PlayerRole.Kaiju
			or resolvedLatePlayer:GetAttribute(PlayerRole.Attribute) ~= PlayerRole.Human
		then
			fail("server role assignment did not produce one kaiju and one human")
			return
		end
		local kaijuCharacter = firstPlayer.Character :: Model
		local humanCharacter = resolvedLatePlayer.Character :: Model
		local kaijuHeight = kaijuCharacter:GetExtentsSize().Y
		local humanHeight = humanCharacter:GetExtentsSize().Y
		local heightRatio = kaijuHeight / math.max(humanHeight, 0.001)
		if heightRatio < Config.MixedScale.ProvisionalMinimumHeightRatio then
			fail(`actual character height ratio was only {heightRatio}`)
			return
		end
		local kaijuRoot = kaijuCharacter:FindFirstChild("HumanoidRootPart")
		local humanRoot = humanCharacter:FindFirstChild("HumanoidRootPart")
		local humanHumanoid = humanCharacter:FindFirstChildOfClass("Humanoid")
		local kaijuHumanoid = kaijuCharacter:FindFirstChildOfClass("Humanoid")
		local contactHull = kaijuCharacter:FindFirstChild("KaijuContactHull")
		if
			not kaijuRoot
			or not kaijuRoot:IsA("BasePart")
			or not humanRoot
			or not humanRoot:IsA("BasePart")
			or kaijuRoot.CollisionGroup ~= PlayerRole.CollisionGroup.Kaiju
			or humanRoot.CollisionGroup ~= PlayerRole.CollisionGroup.Human
			or not humanHumanoid
			or not kaijuHumanoid
			or not contactHull
			or not contactHull:IsA("BasePart")
			or not contactHull.CanCollide
			or contactHull.CollisionGroup ~= PlayerRole.CollisionGroup.KaijuContact
		then
			fail("role collision groups or kaiju contact hull were not applied")
			return
		end
		if
			not PhysicsService:CollisionGroupsAreCollidable(
				PlayerRole.CollisionGroup.KaijuContact,
				PlayerRole.CollisionGroup.Human
			)
			or PhysicsService:CollisionGroupsAreCollidable(
				PlayerRole.CollisionGroup.Kaiju,
				PlayerRole.CollisionGroup.Human
			)
		then
			fail("controlled contact collision matrix was incorrect")
			return
		end

		testRemote:FireClient(resolvedLatePlayer, {
			command = "report",
			stage = StudioTestProtocol.LocalizedLateStage,
			structureId = StudioTestProtocol.LocalizedTargetStructureId,
			expectedState = "Damaged",
		})
		if
			not waitUntil(function()
				return reports[StudioTestProtocol.LocalizedLateStage] ~= nil
					or reportErrors[StudioTestProtocol.LocalizedLateStage] ~= nil
			end, 15)
		then
			fail("late client did not reconstruct localized cooling-tower damage")
			return
		end
		if reportErrors[StudioTestProtocol.LocalizedLateStage] then
			fail(
				`late localized report failed: {reportErrors[StudioTestProtocol.LocalizedLateStage]}`
			)
			return
		end
		local localizedLateReport = reports[StudioTestProtocol.LocalizedLateStage]
		if not reportMatchesLocalizedDamage(localizedLateReport) then
			fail("late client localized rupture did not match durable server state")
			return
		end
		if localizedLateReport.debrisCount ~= 0 then
			fail("late client replayed historical localized impact debris")
			return
		end

		local humanSecurityTarget = findTargetById("north_tower")
		if not humanSecurityTarget then
			fail("human security target was unavailable")
			return
		end
		local healthBeforeHumanAttack =
			humanSecurityTarget:GetAttribute(DestructibleContract.Attribute.CurrentHealth)
		if type(healthBeforeHumanAttack) ~= "number" then
			fail("human security target health was invalid")
			return
		end
		local securityTargetPosition = humanSecurityTarget.DamageHitbox.Position
		humanRoot.CFrame =
			CFrame.lookAt(securityTargetPosition + Vector3.new(0, 3, 18), securityTargetPosition)
		testRemote:FireClient(resolvedLatePlayer, { command = "attack", hits = 1 })
		task.wait(1.25)
		if
			humanSecurityTarget:GetAttribute(DestructibleContract.Attribute.CurrentHealth)
			~= healthBeforeHumanAttack
		then
			fail("human client damaged a kaiju-only destructible")
			return
		end

		kaijuRoot.Anchored = true
		humanRoot.Anchored = true
		kaijuRoot.CFrame = CFrame.lookAt(Vector3.new(0, 200, 80), Vector3.new(0, 200, 0))
		humanRoot.CFrame = CFrame.lookAt(Vector3.new(0, 200, 0), kaijuRoot.Position)
		local kaijuHealthBeforeHumanFire = kaijuHumanoid.Health
		testRemote:FireClient(resolvedLatePlayer, {
			command = "human_fire",
			shots = 1,
			target = kaijuRoot.Position,
		})
		if
			not waitUntil(function()
				return kaijuHumanoid.Health
					<= kaijuHealthBeforeHumanFire - Config.Combat.HumanFireDamage
			end, 5)
		then
			fail("server-validated human fire did not damage the kaiju")
			return
		end
		local kaijuHealthAfterHumanFire = kaijuHumanoid.Health
		local kaijuCharacterBeforeDeath = kaijuCharacter
		-- Include two idempotent safety shots because the mobile-style client cadence
		-- runs close to the server cooldown and an individual request can be rejected.
		local remainingShots = math.ceil(kaijuHealthAfterHumanFire / Config.Combat.HumanFireDamage)
			+ 2
		testRemote:FireClient(resolvedLatePlayer, {
			command = "human_fire",
			shots = remainingShots,
			target = kaijuRoot.Position,
		})
		if
			not waitUntil(function()
				return kaijuHumanoid.Health <= 0
			end, remainingShots * (Config.Combat.HumanFireCooldownSeconds + 0.1) + 5)
		then
			fail(
				`human fire damaged but did not defeat the kaiju; health={kaijuHumanoid.Health}, shots={remainingShots}`
			)
			return
		end
		if
			not waitUntil(function()
				local replacement = firstPlayer.Character
				local replacementHumanoid = if replacement
					then replacement:FindFirstChildOfClass("Humanoid")
					else nil
				return replacement ~= nil
					and replacement ~= kaijuCharacterBeforeDeath
					and replacement:GetAttribute(PlayerRole.Attribute) == PlayerRole.Kaiju
					and replacement:FindFirstChild("BrontideVisual") ~= nil
					and replacement:FindFirstChild("KaijuContactHull") ~= nil
					and replacementHumanoid ~= nil
					and replacementHumanoid.Health == Config.StarterKaiju.MaxHealth
			end, Players.RespawnTime + 15)
		then
			fail("defeated kaiju did not respawn with the Kaiju role and full health")
			return
		end
		kaijuCharacter = firstPlayer.Character :: Model
		kaijuRoot = kaijuCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
		kaijuHumanoid = kaijuCharacter:FindFirstChildOfClass("Humanoid") :: Humanoid
		contactHull = kaijuCharacter:FindFirstChild("KaijuContactHull") :: BasePart
		local kaijuRespawnHealth = kaijuHumanoid.Health

		kaijuRoot.Anchored = false
		humanRoot.Anchored = false
		kaijuRoot.CFrame = CFrame.lookAt(Vector3.new(0, 30, 120), Vector3.new(0, 30, 0))
		kaijuRoot.AssemblyLinearVelocity = Vector3.zero
		humanRoot.CFrame = CFrame.new(0, 30, 109)
		humanRoot.AssemblyLinearVelocity = Vector3.zero
		local humanHealthBeforeContact = humanHumanoid.Health
		if
			not waitUntil(function()
				return humanHumanoid.Health
					<= humanHealthBeforeContact - Config.MixedScale.ContactDamage
			end, 3)
		then
			fail("kaiju contact query did not damage the human")
			return
		end
		local contactVelocity = humanRoot.AssemblyLinearVelocity.Magnitude
		if contactVelocity > Config.MixedScale.MaximumContactVelocity + 1 then
			fail(`controlled contact exceeded its velocity cap: {contactVelocity}`)
			return
		end

		local humanCharacterBeforeDeath = humanCharacter
		kaijuRoot.Anchored = true
		humanRoot.Anchored = true
		kaijuRoot.CFrame = CFrame.lookAt(Vector3.new(0, 120, 120), Vector3.new(0, 120, 0))
		local basicAttackCenter = (kaijuRoot.CFrame * CFrame.new(
			0,
			0,
			-Config.Combat.BasicAttackForwardOffset
		)).Position
		humanRoot.CFrame = CFrame.new(basicAttackCenter)
		kaijuRoot.AssemblyLinearVelocity = Vector3.zero
		humanRoot.AssemblyLinearVelocity = Vector3.zero
		task.wait(Config.Combat.BasicAttackCooldownSeconds + 0.1)
		testRemote:FireClient(firstPlayer, { command = "attack", hits = 1 })
		if not waitUntil(function()
			return humanHumanoid.Health <= 0
		end, 5) then
			fail("kaiju basic attack did not defeat the human")
			return
		end
		if
			not waitUntil(function()
				local replacement = resolvedLatePlayer.Character
				local replacementHumanoid = if replacement
					then replacement:FindFirstChildOfClass("Humanoid")
					else nil
				return replacement ~= nil
					and replacement ~= humanCharacterBeforeDeath
					and replacement:GetAttribute(PlayerRole.Attribute) == PlayerRole.Human
					and replacementHumanoid ~= nil
					and replacementHumanoid.Health == Config.Human.MaxHealth
			end, Players.RespawnTime + 15)
		then
			fail("defeated human did not respawn with the Human role and full health")
			return
		end
		humanCharacter = resolvedLatePlayer.Character :: Model
		humanRoot = humanCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
		humanHumanoid = humanCharacter:FindFirstChildOfClass("Humanoid") :: Humanoid
		local humanRespawnHealth = humanHumanoid.Health

		testRemote:FireClient(resolvedLatePlayer, {
			command = "report",
			stage = StudioTestProtocol.LateClientStage,
			structureId = StudioTestProtocol.TargetStructureId,
			expectedState = "Collapsed",
		})
		if
			not waitUntil(function()
				return reports[StudioTestProtocol.LateClientStage] ~= nil
					or reportErrors[StudioTestProtocol.LateClientStage] ~= nil
			end, 20)
		then
			fail("late client did not report collapsed state")
			return
		end
		if reportErrors[StudioTestProtocol.LateClientStage] then
			fail(`late client report failed: {reportErrors[StudioTestProtocol.LateClientStage]}`)
			return
		end

		local existingReport = reports[StudioTestProtocol.ExistingClientStage]
		local lateReport = reports[StudioTestProtocol.LateClientStage]
		if existingReport.player ~= firstPlayer or lateReport.player ~= resolvedLatePlayer then
			fail("client reports were not bound to the expected players")
			return
		end
		if not reportMatchesCollapsedState(existingReport) then
			fail("initial client state or visual selection disagreed with the server")
			return
		end
		if
			existingReport.smashAnimationCount < 4
			or existingReport.smashAnimationPhase ~= "Idle"
		then
			fail("Smash animation did not complete and restore its procedural pose")
			return
		end
		if not reportMatchesCollapsedState(lateReport) then
			fail("late client state or visual selection disagreed with the server")
			return
		end
		if lateReport.debrisCount ~= 0 then
			fail("late client replayed historical collapse debris")
			return
		end
		if
			existingReport.role ~= PlayerRole.Kaiju
			or existingReport.cameraMin ~= Config.StarterKaiju.CameraMinZoom
			or existingReport.cameraMax ~= Config.StarterKaiju.CameraMaxZoom
			or existingReport.hasHumanFireButton
			or existingReport.hasHumanReticle
		then
			fail("kaiju client did not apply its role camera metrics")
			return
		end
		if
			lateReport.role ~= PlayerRole.Human
			or lateReport.cameraMin ~= Config.Human.CameraMinZoom
			or lateReport.cameraMax ~= Config.Human.CameraMaxZoom
			or lateReport.cameraType ~= tostring(Enum.CameraType.Custom)
			or lateReport.hasSmashButton
			or not lateReport.hasHumanFireButton
			or not lateReport.hasHumanReticle
			or lateReport.characterHealth ~= Config.Human.MaxHealth
		then
			fail("human client retained kaiju camera or touch-action state")
			return
		end

		local collision = target:FindFirstChild("Collision")
		local intactProxy = if collision then collision:FindFirstChild("IntactProxy") else nil
		local collapsedProxy = if collision then collision:FindFirstChild("CollapsedProxy") else nil
		if
			not intactProxy
			or not intactProxy:IsA("BasePart")
			or not collapsedProxy
			or not collapsedProxy:IsA("BasePart")
			or intactProxy.CanCollide
			or not collapsedProxy.CanCollide
			or target.DamageHitbox.CanQuery
		then
			fail("server collision or query proxies disagreed with collapsed state")
			return
		end

		testRemote:FireClient(firstPlayer, { command = "leave" })
		if
			not waitUntil(function()
				local promotedCharacter = resolvedLatePlayer.Character
				return #Players:GetPlayers() == 1
					and resolvedLatePlayer:GetAttribute(PlayerRole.Attribute) == PlayerRole.Kaiju
					and promotedCharacter ~= nil
					and promotedCharacter:GetAttribute(PlayerRole.Attribute) == PlayerRole.Kaiju
					and promotedCharacter:FindFirstChild("BrontideVisual") ~= nil
					and promotedCharacter:GetExtentsSize().Y >= kaijuHeight * 0.9
			end, 20)
		then
			fail("remaining human was not promoted after the kaiju left")
			return
		end
		local promotedHeight = (resolvedLatePlayer.Character :: Model):GetExtentsSize().Y
		if promotedHeight < kaijuHeight * 0.9 then
			fail(`promoted human height {promotedHeight} was below kaiju height {kaijuHeight}`)
			return
		end

		finish({
			passed = true,
			playersBeforePromotion = 2,
			playersAfterPromotion = #Players:GetPlayers(),
			structureId = StudioTestProtocol.TargetStructureId,
			state = target:GetAttribute(DestructibleContract.Attribute.State),
			sequence = target:GetAttribute(DestructibleContract.Attribute.StateSequence),
			health = target:GetAttribute(DestructibleContract.Attribute.CurrentHealth),
			existingClientDebris = existingReport.debrisCount,
			lateClientDebris = lateReport.debrisCount,
			kaijuHeight = kaijuHeight,
			humanHeight = humanHeight,
			heightRatio = heightRatio,
			kaijuRole = firstPlayer:GetAttribute(PlayerRole.Attribute),
			initialHumanRole = PlayerRole.Human,
			promotedRole = resolvedLatePlayer:GetAttribute(PlayerRole.Attribute),
			promotedHeight = promotedHeight,
			humanCamera = `{lateReport.cameraMin}-{lateReport.cameraMax}`,
			humanCameraType = lateReport.cameraType,
			humanHadSmashButton = lateReport.hasSmashButton,
			humanHadFireButton = lateReport.hasHumanFireButton,
			humanHadReticle = lateReport.hasHumanReticle,
			kaijuHealthAfterHumanFire = kaijuHealthAfterHumanFire,
			kaijuRespawnHealth = kaijuRespawnHealth,
			contactVelocity = contactVelocity,
			humanRespawnHealth = humanRespawnHealth,
			localizedStructureId = StudioTestProtocol.LocalizedTargetStructureId,
			localizedImpactSequence = localizedTarget:GetAttribute(
				DestructibleContract.Attribute.ImpactSequence
			),
			localizedZoneState = localizedTarget:GetAttribute(
				DestructibleContract.Attribute.DamageZoneState
			),
			localizedExistingHoles = reports[StudioTestProtocol.LocalizedExistingStage].localizedHoleCount,
			localizedMaximumSpan = localizedLateReport.localizedMaximumSpan,
			localizedLateHoles = localizedLateReport.localizedHoleCount,
			localizedDamagedNeon = localizedLateReport.damagedNeonCount,
			smashAnimationCount = reports[StudioTestProtocol.LocalizedExistingStage].smashAnimationCount,
			smashAnimationPhase = existingReport.smashAnimationPhase,
			plantDressingParts = plantDressingParts,
		})
	end)
end

return table.freeze(MultiplayerDestructionRegression)
