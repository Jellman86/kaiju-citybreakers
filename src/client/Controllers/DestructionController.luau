--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)
local LocalizedDamage = require(ReplicatedStorage.Shared.LocalizedDamage)
local Types = require(ReplicatedStorage.Shared.Types)
local CosmeticDebrisPool = require(script.Parent.Parent.Effects.CosmeticDebrisPool)
local DestructionEffectProfiles = require(script.Parent.Parent.Effects.DestructionEffectProfiles)
local LocalizedDamageRenderer = require(script.Parent.Parent.Effects.LocalizedDamageRenderer)

type Components = DestructibleContract.Components
type DestructionEvent = Types.DestructionEvent
type DestructionState = Types.DestructionState

type StructureView = {
	structure: Model,
	components: Components,
	connections: { RBXScriptConnection },
	lastSequence: number,
	localizedDamageRenderer: any,
}

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
		and typeof(payload.stateSequence) == "number"
		and payload.stateSequence % 1 == 0
		and payload.stateSequence >= 0
		and typeof(payload.impactSequence) == "number"
		and payload.impactSequence % 1 == 0
		and payload.impactSequence >= 1
		and typeof(payload.position) == "Vector3"
		and typeof(payload.normal) == "Vector3"
		and payload.normal.Magnitude > 0.9
		and payload.normal.Magnitude < 1.1
		and LocalizedDamage.IsAttackType(payload.attackType)
		and typeof(payload.zoneIndex) == "number"
		and payload.zoneIndex % 1 == 0
		and payload.zoneIndex >= 1
		and payload.zoneIndex <= LocalizedDamage.ZoneCount
		and LocalizedDamage.NormalizeState(payload.zoneState) == payload.zoneState
		and typeof(payload.materialProfile) == "string"
end

function DestructionController.new(destructionStateRemote: RemoteEvent)
	local self = setmetatable({}, DestructionController)

	self._destructionStateRemote = destructionStateRemote
	self._connections = {} :: { RBXScriptConnection }
	self._views = {} :: { [Model]: StructureView }
	self._viewsById = {} :: { [string]: StructureView }
	self._lastImpactSequence = {} :: { [string]: number }
	self._debrisPool = CosmeticDebrisPool.new(
		Config.Destruction.MaximumCosmeticDebris,
		Config.Destruction.CosmeticDebrisPrewarmCount
	)

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
		view.localizedDamageRenderer:Sync(
			view.structure:GetAttribute(DestructibleContract.Attribute.DamageZoneState),
			state :: DestructionState
		)
	end
end

function DestructionController:_syncLocalizedDamage(view: StructureView)
	local state = view.structure:GetAttribute(DestructibleContract.Attribute.State)
	if DestructibleContract.IsState(state) then
		view.localizedDamageRenderer:Sync(
			view.structure:GetAttribute(DestructibleContract.Attribute.DamageZoneState),
			state
		)
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
		localizedDamageRenderer = LocalizedDamageRenderer.new(
			tagged,
			components,
			tagged:GetAttribute(DestructibleContract.Attribute.MaterialProfile) :: string
		),
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
	table.insert(
		view.connections,
		tagged
			:GetAttributeChangedSignal(DestructibleContract.Attribute.DamageZoneState)
			:Connect(function()
				self:_syncLocalizedDamage(view)
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
	view.localizedDamageRenderer:Destroy()
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

	local profile = DestructionEffectProfiles.Get(event.materialProfile)
	for index = 1, Config.Destruction.FragmentsPerCollapse do
		self._debrisPool:Spawn(
			CFrame.new(event.position) * CFrame.new((index - 5) * 1.2, 6 + (index % 4), 0),
			Vector3.new(1.5 + (index % 3), 1 + (index % 2), 1.5) * profile.fragmentSizeScale,
			profile.fragmentColor,
			profile.fragmentMaterial,
			Vector3.new((index - 5) * 3, 18 + (index % 3) * 3, (index % 2) * 8 - 4)
				* profile.fragmentSpeedScale,
			Vector3.new(index, index * 0.5, -index * 0.4),
			Config.Destruction.CosmeticDebrisLifetimeSeconds
		)
	end
end

function DestructionController:_emitImpactDebris(event: DestructionEvent)
	local player = Players.LocalPlayer
	local character = player.Character
	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if rootPart and rootPart:IsA("BasePart") then
		local effectDistance = (rootPart.Position - event.position).Magnitude
		if effectDistance > Config.Destruction.MaximumEffectDistance then
			return
		end
	end

	local profile = DestructionEffectProfiles.Get(event.materialProfile)
	local attackScale = if event.attackType == "Charge"
		then 1.35
		elseif event.attackType == "Beam" then 0.65
		else 1
	local tangent = event.normal:Cross(Vector3.yAxis)
	if tangent.Magnitude < 0.1 then
		tangent = Vector3.xAxis
	else
		tangent = tangent.Unit
	end
	for index = 1, Config.Destruction.FragmentsPerImpact do
		local spread = index - (Config.Destruction.FragmentsPerImpact + 1) * 0.5
		self._debrisPool:Spawn(
			CFrame.new(event.position + tangent * spread * 0.7 + Vector3.new(0, index % 2, 0)),
			Vector3.new(1.2 + (index % 2), 0.8 + (index % 3) * 0.35, 1)
				* profile.fragmentSizeScale
				* attackScale,
			profile.fragmentColor,
			profile.fragmentMaterial,
			event.normal * (13 + index * 2) * profile.fragmentSpeedScale * attackScale
				+ tangent * spread * 3
				+ Vector3.new(0, 8 + index * 1.5, 0),
			Vector3.new(index * 0.7, -index, index * 0.4),
			math.min(2.2, Config.Destruction.CosmeticDebrisLifetimeSeconds)
		)
	end
end

function DestructionController:_onStateEvent(payload: any)
	if not isValidEvent(payload) then
		return
	end

	local event = payload :: DestructionEvent
	local view = self._viewsById[event.structureId]
	if view and event.stateSequence >= view.lastSequence then
		view.lastSequence = event.stateSequence
		self:_applyState(view, event.state)
		view.localizedDamageRenderer:Sync(event.zoneState, event.state)
	end

	local lastImpactSequence = self._lastImpactSequence[event.structureId] or 0
	if event.impactSequence <= lastImpactSequence then
		return
	end
	self._lastImpactSequence[event.structureId] = event.impactSequence

	self:_emitImpactDebris(event)
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
	table.clear(self._lastImpactSequence)
	self._debrisPool:Destroy()
end

return DestructionController
