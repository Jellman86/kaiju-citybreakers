--!strict

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)
local Types = require(ReplicatedStorage.Shared.Types)

type Components = DestructibleContract.Components
type DestructionEvent = Types.DestructionEvent
type DestructionState = Types.DestructionState

type StructureView = {
	structure: Model,
	components: Components,
	connections: { RBXScriptConnection },
	lastSequence: number,
}

local MATERIAL_COLORS = table.freeze({
	Concrete = Color3.fromRGB(84, 89, 94),
	Metal = Color3.fromRGB(74, 87, 94),
	Lightweight = Color3.fromRGB(120, 105, 86),
})

local DestructionController = {}
DestructionController.__index = DestructionController

local function setVariantVisible(variant: Model, visible: boolean)
	for _, descendant in variant:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = if visible then 0 else 1
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = visible
		end
	end
end

local function isValidEvent(payload: any): boolean
	return typeof(payload) == "table"
		and typeof(payload.structureId) == "string"
		and DestructibleContract.IsState(payload.state)
		and typeof(payload.sequence) == "number"
		and payload.sequence % 1 == 0
		and payload.sequence >= 1
		and typeof(payload.position) == "Vector3"
		and typeof(payload.materialProfile) == "string"
end

function DestructionController.new(destructionStateRemote: RemoteEvent)
	local self = setmetatable({}, DestructionController)

	self._destructionStateRemote = destructionStateRemote
	self._connections = {} :: { RBXScriptConnection }
	self._views = {} :: { [Model]: StructureView }
	self._viewsById = {} :: { [string]: StructureView }
	self._lastEffectSequence = {} :: { [string]: number }

	return self
end

function DestructionController:_applyState(view: StructureView, state: DestructionState)
	setVariantVisible(view.components.intactVisual, state == "Intact")
	setVariantVisible(view.components.damagedVisual, state == "Damaged")
	setVariantVisible(view.components.collapsedVisual, state == "Collapsed")
end

function DestructionController:_syncState(view: StructureView)
	local state = view.structure:GetAttribute(DestructibleContract.Attribute.State)
	local sequence = view.structure:GetAttribute(DestructibleContract.Attribute.StateSequence)
	if
		DestructibleContract.IsState(state)
		and typeof(sequence) == "number"
		and sequence % 1 == 0
		and sequence >= view.lastSequence
	then
		view.lastSequence = sequence
		self:_applyState(view, state :: DestructionState)
	end
end

function DestructionController:_register(tagged: Instance)
	if not tagged:IsA("Model") or self._views[tagged] then
		return
	end

	local components, validationError = DestructibleContract.Validate(tagged)
	if not components then
		warn(`[DestructionController] Ignoring invalid destructible: {validationError}`)
		return
	end

	local structureId = tagged:GetAttribute(DestructibleContract.Attribute.StructureId) :: string
	if self._viewsById[structureId] then
		warn(`[DestructionController] Duplicate StructureId ignored: {structureId}`)
		return
	end

	local view: StructureView = {
		structure = tagged,
		components = components,
		connections = {},
		lastSequence = 0,
	}
	self._views[tagged] = view
	self._viewsById[structureId] = view

	table.insert(
		view.connections,
		tagged:GetAttributeChangedSignal(DestructibleContract.Attribute.State):Connect(function()
			self:_syncState(view)
		end)
	)
	table.insert(
		view.connections,
		tagged
			:GetAttributeChangedSignal(DestructibleContract.Attribute.StateSequence)
			:Connect(function()
				self:_syncState(view)
			end)
	)
	self:_syncState(view)
end

function DestructionController:_unregister(tagged: Instance)
	if not tagged:IsA("Model") then
		return
	end

	local view = self._views[tagged]
	if not view then
		return
	end

	for _, connection in view.connections do
		connection:Disconnect()
	end
	table.clear(view.connections)
	self._views[tagged] = nil

	local structureId = tagged:GetAttribute(DestructibleContract.Attribute.StructureId)
	if typeof(structureId) == "string" and self._viewsById[structureId] == view then
		self._viewsById[structureId] = nil
	end
end

function DestructionController:_emitCollapseDebris(event: DestructionEvent)
	local player = Players.LocalPlayer
	local character = player.Character
	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if rootPart and rootPart:IsA("BasePart") then
		local effectDistance = (rootPart.Position - event.position).Magnitude
		if effectDistance > Config.Destruction.MaximumEffectDistance then
			return
		end
	end

	local fragmentColor = MATERIAL_COLORS[event.materialProfile] or MATERIAL_COLORS.Concrete
	for index = 1, Config.Destruction.FragmentsPerCollapse do
		local fragment = Instance.new("Part")
		fragment.Name = "CosmeticDebris"
		fragment.Size = Vector3.new(1.5 + (index % 3), 1 + (index % 2), 1.5)
		fragment.CFrame = CFrame.new(event.position)
			* CFrame.new((index - 5) * 1.2, 6 + (index % 4), 0)
		fragment.Color = fragmentColor
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

function DestructionController:_onStateEvent(payload: any)
	if not isValidEvent(payload) then
		return
	end

	local event = payload :: DestructionEvent
	local view = self._viewsById[event.structureId]
	if view and event.sequence >= view.lastSequence then
		view.lastSequence = event.sequence
		self:_applyState(view, event.state)
	end

	local lastEffectSequence = self._lastEffectSequence[event.structureId] or 0
	if event.sequence <= lastEffectSequence then
		return
	end
	self._lastEffectSequence[event.structureId] = event.sequence

	if event.state == "Collapsed" then
		self:_emitCollapseDebris(event)
	end
end

function DestructionController:Start()
	table.insert(
		self._connections,
		CollectionService:GetInstanceAddedSignal(DestructibleContract.Tag)
			:Connect(function(instance)
				task.defer(function()
					if instance:IsDescendantOf(workspace) then
						self:_register(instance)
					end
				end)
			end)
	)
	table.insert(
		self._connections,
		CollectionService:GetInstanceRemovedSignal(DestructibleContract.Tag)
			:Connect(function(instance)
				self:_unregister(instance)
			end)
	)
	table.insert(
		self._connections,
		self._destructionStateRemote.OnClientEvent:Connect(function(payload)
			self:_onStateEvent(payload)
		end)
	)

	for _, tagged in CollectionService:GetTagged(DestructibleContract.Tag) do
		task.defer(function()
			if tagged:IsDescendantOf(workspace) then
				self:_register(tagged)
			end
		end)
	end
end

function DestructionController:Destroy()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)

	local registeredStructures = {}
	for structure in self._views do
		table.insert(registeredStructures, structure)
	end
	for _, structure in registeredStructures do
		self:_unregister(structure)
	end
	table.clear(self._lastEffectSequence)
end

return DestructionController
