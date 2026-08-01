--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StudioTestService: any = nil
if RunService:IsStudio() then
	StudioTestService = game:GetService("StudioTestService")
end

local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)
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

local function findTarget(): Model?
	for _, tagged in CollectionService:GetTagged(DestructibleContract.Tag) do
		if
			tagged:IsA("Model")
			and tagged:GetAttribute(DestructibleContract.Attribute.StructureId)
				== StudioTestProtocol.TargetStructureId
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
	}
end

local function reportMatchesCollapsedState(report: ClientReport): boolean
	return report.state == "Collapsed"
		and report.sequence == 2
		and report.health == 0
		and report.intactVisible == 0
		and report.damagedVisible == 0
		and report.collapsedVisible > 0
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

		local target = findTarget()
		if not target then
			fail("target destructible was not registered")
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

		testRemote:FireClient(firstPlayer, {
			command = "report",
			stage = StudioTestProtocol.ExistingClientStage,
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
			end, 20)
		then
			fail("late client harness did not become ready")
			return
		end

		testRemote:FireClient(resolvedLatePlayer, {
			command = "report",
			stage = StudioTestProtocol.LateClientStage,
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
		if not reportMatchesCollapsedState(lateReport) then
			fail("late client state or visual selection disagreed with the server")
			return
		end
		if lateReport.debrisCount ~= 0 then
			fail("late client replayed historical collapse debris")
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
			or not target.DamageHitbox.CanQuery
		then
			fail("server collision or query proxies disagreed with collapsed state")
			return
		end

		finish({
			passed = true,
			players = #Players:GetPlayers(),
			structureId = StudioTestProtocol.TargetStructureId,
			state = target:GetAttribute(DestructibleContract.Attribute.State),
			sequence = target:GetAttribute(DestructibleContract.Attribute.StateSequence),
			health = target:GetAttribute(DestructibleContract.Attribute.CurrentHealth),
			existingClientDebris = existingReport.debrisCount,
			lateClientDebris = lateReport.debrisCount,
		})
	end)
end

return table.freeze(MultiplayerDestructionRegression)
