--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

			if payload.command ~= "report" or type(payload.stage) ~= "string" then
				return
			end

			local target: Model? = nil
			waitUntil(function()
				target = findTarget()
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
						== "Collapsed"
				end, 15)
			then
				testRemote:FireServer({
					kind = "report_error",
					stage = payload.stage,
					reason = "collapsed attributes did not replicate to client",
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
			})
		end)

		testRemote:FireServer({ kind = "ready" })
	end)
end

return table.freeze(MultiplayerDestructionRegression)
