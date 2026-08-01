--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)

type DestructionState = Types.DestructionState

local DestructionController = {}
DestructionController.__index = DestructionController

function DestructionController.new(destructionStateRemote: RemoteEvent)
	local self = setmetatable({}, DestructionController)

	self._destructionStateRemote = destructionStateRemote
	self._connection = nil :: RBXScriptConnection?

	return self
end

function DestructionController:_emitCollapseDebris(structure: Model)
	local pivot = structure:GetPivot()
	for index = 1, 10 do
		local fragment = Instance.new("Part")
		fragment.Name = "CosmeticDebris"
		fragment.Size = Vector3.new(1.5 + (index % 3), 1 + (index % 2), 1.5)
		fragment.CFrame = pivot * CFrame.new((index - 5) * 1.2, 6 + (index % 4), 0)
		fragment.Color = Color3.fromRGB(84, 89, 94)
		fragment.Material = Enum.Material.Concrete
		fragment.CanCollide = false
		fragment.CanTouch = false
		fragment.CanQuery = false
		fragment.AssemblyLinearVelocity =
			Vector3.new((index - 5) * 3, 18 + (index % 3) * 3, (index % 2) * 8 - 4)
		fragment.AssemblyAngularVelocity = Vector3.new(index, index * 0.5, -index * 0.4)
		fragment.Parent = workspace
		Debris:AddItem(fragment, Config.Destruction.CosmeticDebrisLifetimeSeconds)
	end
end

function DestructionController:Start()
	self._connection = self._destructionStateRemote.OnClientEvent:Connect(
		function(structure: Model, state: DestructionState)
			if structure:IsDescendantOf(workspace) and state == "Collapsed" then
				self:_emitCollapseDebris(structure)
			end
		end
	)
end

function DestructionController:Destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

return DestructionController
