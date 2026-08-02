--!strict

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local StudioTestService: any = nil
if RunService:IsStudio() then
	StudioTestService = game:GetService("StudioTestService")
end

local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)
local StudioTestProtocol = require(ReplicatedStorage.Shared.StudioTestProtocol)

local MultiplayerDestructionRegression = {}

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

local function isRequestedTest(): boolean
	if StudioTestService == nil then
		return false
	end

	local ok, args = pcall(function()
		return StudioTestService:GetTestArgs()
	end)
	return ok and args == StudioTestProtocol.MultiplayerDestructionTest
end

local function findTarget(structureId: string): Model?
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

local function measureLocalizedDamage(target: Model): (number, number, number)
	local container = target:FindFirstChild("ClientLocalizedDamage")
	if not container or not container:IsA("Model") then
		return 0, 0, 0
	end
	local holes = 0
	local visibleParts = 0
	for _, descendant in container:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.LocalTransparencyModifier < 1 then
			visibleParts += 1
			if descendant.Name == "LocalizedDamageHole" then
				holes += 1
			end
		end
	end
	local maximumSpan = 0
	if visibleParts > 0 then
		local _, bounds = container:GetBoundingBox()
		maximumSpan = math.max(bounds.X, bounds.Y, bounds.Z)
	end
	return holes, visibleParts, maximumSpan
end

local function countVisibleNeon(variant: Model): number
	local count = 0
	for _, descendant in variant:GetDescendants() do
		if
			descendant:IsA("BasePart")
			and descendant.LocalTransparencyModifier < 1
			and descendant.Material == Enum.Material.Neon
		then
			count += 1
		end
	end
	return count
end

local function countVisibleParts(variant: Model): number
	local visible = 0
	for _, descendant in variant:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.LocalTransparencyModifier < 1 then
			visible += 1
		end
	end
	return visible
end

local function countActiveDebris(): number
	local active = 0
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name == "CosmeticDebris" then
			active += 1
		end
	end
	return active
end

local function getReticleViewportFraction(): Vector2
	local camera = workspace.CurrentCamera
	local reticle = Players.LocalPlayer.PlayerGui:FindFirstChild("AimReticle", true)
	if
		not camera
		or not reticle
		or not reticle:IsA("GuiObject")
		or camera.ViewportSize.X <= 0
		or camera.ViewportSize.Y <= 0
	then
		return Vector2.zero
	end
	local reticleCenter = reticle.AbsolutePosition + reticle.AbsoluteSize * 0.5
	return Vector2.new(
		reticleCenter.X / camera.ViewportSize.X,
		reticleCenter.Y / camera.ViewportSize.Y
	)
end

function MultiplayerDestructionRegression.TryStart(
	abilityRequestRemote: RemoteEvent,
	remotes: Folder
)
	if not isRequestedTest() then
		return
	end

	task.spawn(function()
		local remoteInstance = remotes:WaitForChild(StudioTestProtocol.RemoteName, 20)
		if not remoteInstance or not remoteInstance:IsA("RemoteEvent") then
			return
		end
		local testRemote = remoteInstance :: RemoteEvent
		local sequence = 9000

		testRemote.OnClientEvent:Connect(function(payload)
			if type(payload) ~= "table" or type(payload.command) ~= "string" then
				return
			end

			if payload.command == "attack" and type(payload.hits) == "number" then
				task.wait(0.5)
				for _ = 1, payload.hits do
					sequence += 1
					abilityRequestRemote:FireServer({ abilityId = "basic", sequence = sequence })
					task.wait(0.72)
				end
				return
			end
			if
				payload.command == "human_fire"
				and type(payload.shots) == "number"
				and typeof(payload.target) == "Vector3"
			then
				task.wait(0.3)
				for _ = 1, payload.shots do
					local character = Players.LocalPlayer.Character
					local head = character and character:FindFirstChild("Head")
					local origin = if head and head:IsA("BasePart")
						then head.Position
						else Vector3.zero
					local direction = payload.target - origin
					if direction.Magnitude > 0.001 then
						sequence += 1
						abilityRequestRemote:FireServer({
							abilityId = "humanFire",
							sequence = sequence,
							aimDirection = direction.Unit,
						})
					end
					task.wait(0.42)
				end
				return
			end
			if payload.command == "leave" then
				if StudioTestService:CanLeaveTest() then
					StudioTestService:LeaveTest()
				end
				return
			end

			if
				payload.command ~= "report"
				or type(payload.stage) ~= "string"
				or type(payload.structureId) ~= "string"
				or type(payload.expectedState) ~= "string"
			then
				return
			end

			local target: Model? = nil
			waitUntil(function()
				target = findTarget(payload.structureId)
				return target ~= nil
			end, 15)
			if not target then
				testRemote:FireServer({
					kind = "report_error",
					stage = payload.stage,
					reason = "tagged target did not stream to client",
				})
				return
			end
			local resolvedTarget = target :: Model
			if
				not waitUntil(function()
					return resolvedTarget:GetAttribute(DestructibleContract.Attribute.State)
						== payload.expectedState
				end, 15)
			then
				testRemote:FireServer({
					kind = "report_error",
					stage = payload.stage,
					reason = "expected destruction attributes did not replicate to client",
				})
				return
			end

			task.wait(0.35)
			local visuals = resolvedTarget:FindFirstChild("Visuals")
			if not visuals or not visuals:IsA("Model") then
				testRemote:FireServer({
					kind = "report_error",
					stage = payload.stage,
					reason = "target visuals were unavailable on client",
				})
				return
			end
			local intact = visuals:FindFirstChild("Intact")
			local damaged = visuals:FindFirstChild("Damaged")
			local collapsed = visuals:FindFirstChild("Collapsed")
			if
				not intact
				or not intact:IsA("Model")
				or not damaged
				or not damaged:IsA("Model")
				or not collapsed
				or not collapsed:IsA("Model")
			then
				testRemote:FireServer({
					kind = "report_error",
					stage = payload.stage,
					reason = "target visual variants were unavailable on client",
				})
				return
			end
			local localizedHoleCount, localizedPartCount, localizedMaximumSpan =
				measureLocalizedDamage(resolvedTarget)
			local reticleViewportFraction = getReticleViewportFraction()

			testRemote:FireServer({
				kind = "report",
				stage = payload.stage,
				state = resolvedTarget:GetAttribute(DestructibleContract.Attribute.State),
				sequence = resolvedTarget:GetAttribute(
					DestructibleContract.Attribute.StateSequence
				),
				health = resolvedTarget:GetAttribute(DestructibleContract.Attribute.CurrentHealth),
				intactVisible = countVisibleParts(intact),
				damagedVisible = countVisibleParts(damaged),
				collapsedVisible = countVisibleParts(collapsed),
				debrisCount = countActiveDebris(),
				damageZoneState = resolvedTarget:GetAttribute(
					DestructibleContract.Attribute.DamageZoneState
				),
				impactSequence = resolvedTarget:GetAttribute(
					DestructibleContract.Attribute.ImpactSequence
				),
				localizedHoleCount = localizedHoleCount,
				localizedPartCount = localizedPartCount,
				localizedMaximumSpan = localizedMaximumSpan,
				damagedNeonCount = countVisibleNeon(damaged),
				smashAnimationCount = Players.LocalPlayer:GetAttribute("ClientSmashAnimationCount")
					or 0,
				smashAnimationPhase = if Players.LocalPlayer.Character
					then Players.LocalPlayer.Character:GetAttribute("ClientSmashAnimationPhase")
						or "Idle"
					else "Unavailable",
				smashMaximumShellDisplacement = if Players.LocalPlayer.Character
					then Players.LocalPlayer.Character:GetAttribute(
						"ClientSmashMaximumShellDisplacement"
					) or 0
					else 0,
				role = Players.LocalPlayer:GetAttribute("CharacterRole"),
				cameraMin = Players.LocalPlayer.CameraMinZoomDistance,
				cameraMax = Players.LocalPlayer.CameraMaxZoomDistance,
				cameraType = if workspace.CurrentCamera
					then tostring(workspace.CurrentCamera.CameraType)
					else "Unavailable",
				hasSmashButton = ContextActionService:GetButton("KaijuBasicAttack") ~= nil,
				hasHumanFireButton = ContextActionService:GetButton("HumanBlasterFire") ~= nil,
				hasAimReticle = Players.LocalPlayer.PlayerGui:FindFirstChild("AimReticle", true)
					~= nil,
				reticleXFraction = reticleViewportFraction.X,
				reticleYFraction = reticleViewportFraction.Y,
				usesDesktopReticle = UserInputService.PreferredInput
					== Enum.PreferredInput.KeyboardAndMouse,
				characterHealth = if Players.LocalPlayer.Character
						and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					then (
						Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") :: Humanoid
					).Health
					else -1,
			})
		end)

		testRemote:FireServer({ kind = "ready" })
	end)
end

return table.freeze(MultiplayerDestructionRegression)
