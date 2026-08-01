--!strict

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)
local LocalizedDamage = require(ReplicatedStorage.Shared.LocalizedDamage)
local Types = require(ReplicatedStorage.Shared.Types)

type Components = DestructibleContract.Components
type DestructionEvent = Types.DestructionEvent
type DestructionState = Types.DestructionState
type StructureDamageContext = Types.StructureDamageContext
type SurfaceProfile = LocalizedDamage.SurfaceProfile
type StateCallback = (player: Player, structure: Model, state: DestructionState) -> ()

type StructureRecord = {
	structure: Model,
	structureId: string,
	maxHealth: number,
	materialProfile: string,
	components: Components,
	state: DestructionState,
	sequence: number,
	impactSequence: number,
	damageZoneState: string,
	surfaceProfile: SurfaceProfile,
}

local DestructionService = {}
DestructionService.__index = DestructionService

local function isFinitePositiveNumber(value: any): boolean
	return typeof(value) == "number" and value == value and value > 0 and value < math.huge
end

local function isFiniteVector3(value: any): boolean
	return typeof(value) == "Vector3"
		and value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
		and math.abs(value.X) < math.huge
		and math.abs(value.Y) < math.huge
		and math.abs(value.Z) < math.huge
end

local function configureCollisionGroup(name: string)
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
end

local function configureVisuals(components: Components)
	for _, variant in
		{
			components.intactVisual,
			components.damagedVisual,
			components.collapsedVisual,
		}
	do
		for _, descendant in variant:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
			end
		end
	end
end

local function setCollisionProxyActive(proxy: BasePart, active: boolean)
	proxy.Transparency = 1
	proxy.Anchored = true
	proxy.CanCollide = active
	proxy.CanTouch = false
	proxy.CanQuery = false
	proxy.CastShadow = false
end

function DestructionService.new(destructionStateRemote: RemoteEvent, onStateChanged: StateCallback)
	local self = setmetatable({}, DestructionService)

	self._destructionStateRemote = destructionStateRemote
	self._onStateChanged = onStateChanged
	self._records = {} :: { [Model]: StructureRecord }
	self._recordsById = {} :: { [string]: StructureRecord }
	self._connections = {} :: { RBXScriptConnection }

	return self
end

function DestructionService:_configureCollisionGroups()
	configureCollisionGroup(DestructibleContract.DamageHitboxCollisionGroup)
	configureCollisionGroup(DestructibleContract.AttackQueryCollisionGroup)

	PhysicsService:CollisionGroupSetCollidable(
		DestructibleContract.AttackQueryCollisionGroup,
		"Default",
		false
	)
	PhysicsService:CollisionGroupSetCollidable(
		DestructibleContract.AttackQueryCollisionGroup,
		DestructibleContract.DamageHitboxCollisionGroup,
		true
	)
	PhysicsService:CollisionGroupSetCollidable(
		DestructibleContract.DamageHitboxCollisionGroup,
		"Default",
		false
	)
	PhysicsService:CollisionGroupSetCollidable(
		DestructibleContract.DamageHitboxCollisionGroup,
		DestructibleContract.DamageHitboxCollisionGroup,
		false
	)
end

function DestructionService:_applyCollisionState(record: StructureRecord, state: DestructionState)
	setCollisionProxyActive(record.components.intactCollision, state ~= "Collapsed")
	setCollisionProxyActive(record.components.collapsedCollision, state == "Collapsed")
	record.components.damageHitbox.CanQuery = state ~= "Collapsed"
end

function DestructionService:_setState(
	record: StructureRecord,
	state: DestructionState,
	player: Player?
): boolean
	local changed = record.state ~= state
	if changed then
		record.sequence += 1
	end
	record.state = state

	self:_applyCollisionState(record, state)
	record.structure:SetAttribute(DestructibleContract.Attribute.State, state)
	record.structure:SetAttribute(DestructibleContract.Attribute.StateSequence, record.sequence)

	if changed and player then
		self._onStateChanged(player, record.structure, state)
	end
	return changed
end

function DestructionService:_register(tagged: Instance)
	if not tagged:IsA("Model") or self._records[tagged] then
		return
	end

	local components, validationError = DestructibleContract.Validate(tagged)
	if not components then
		warn(`[DestructionService] Ignoring invalid destructible: {validationError}`)
		return
	end

	local structureId = tagged:GetAttribute(DestructibleContract.Attribute.StructureId) :: string
	if self._recordsById[structureId] then
		warn(`[DestructionService] Duplicate StructureId ignored: {structureId}`)
		return
	end

	local maxHealth = tagged:GetAttribute(DestructibleContract.Attribute.MaxHealth) :: number
	local materialProfile =
		tagged:GetAttribute(DestructibleContract.Attribute.MaterialProfile) :: string
	local surfaceProfile = LocalizedDamage.NormalizeSurfaceProfile(
		tagged:GetAttribute(DestructibleContract.Attribute.DamageSurfaceProfile)
	)
	local record: StructureRecord = {
		structure = tagged,
		structureId = structureId,
		maxHealth = maxHealth,
		materialProfile = materialProfile,
		components = components,
		state = "Intact",
		sequence = 0,
		impactSequence = 0,
		damageZoneState = LocalizedDamage.EmptyState,
		surfaceProfile = surfaceProfile,
	}

	configureVisuals(components)
	components.damageHitbox.Transparency = 1
	components.damageHitbox.Anchored = true
	components.damageHitbox.CanCollide = false
	components.damageHitbox.CanTouch = false
	components.damageHitbox.CanQuery = true
	components.damageHitbox.CastShadow = false
	components.damageHitbox.CollisionGroup = DestructibleContract.DamageHitboxCollisionGroup

	self._records[tagged] = record
	self._recordsById[structureId] = record
	tagged:SetAttribute(DestructibleContract.Attribute.CurrentHealth, maxHealth)
	tagged:SetAttribute(DestructibleContract.Attribute.ImpactSequence, 0)
	tagged:SetAttribute(DestructibleContract.Attribute.DamageZoneState, LocalizedDamage.EmptyState)
	tagged:SetAttribute(DestructibleContract.Attribute.DamageSurfaceProfile, surfaceProfile)
	self:_setState(record, "Intact", nil)
end

function DestructionService:_unregister(tagged: Instance)
	if not tagged:IsA("Model") then
		return
	end

	local record = self._records[tagged]
	if not record then
		return
	end

	self._records[tagged] = nil
	if self._recordsById[record.structureId] == record then
		self._recordsById[record.structureId] = nil
	end
end

function DestructionService:Start()
	self:_configureCollisionGroups()

	table.insert(
		self._connections,
		CollectionService:GetInstanceAddedSignal(DestructibleContract.Tag)
			:Connect(function(instance)
				self:_register(instance)
			end)
	)
	table.insert(
		self._connections,
		CollectionService:GetInstanceRemovedSignal(DestructibleContract.Tag)
			:Connect(function(instance)
				self:_unregister(instance)
			end)
	)

	for _, tagged in CollectionService:GetTagged(DestructibleContract.Tag) do
		self:_register(tagged)
	end
end

function DestructionService:Damage(
	player: Player,
	structure: Model,
	amount: number,
	context: StructureDamageContext
): boolean
	local record = self._records[structure]
	if
		not record
		or not isFinitePositiveNumber(amount)
		or typeof(context) ~= "table"
		or not LocalizedDamage.IsAttackType(context.attackType)
		or not isFiniteVector3(context.position)
		or (context.normal ~= nil and not isFiniteVector3(context.normal))
	then
		return false
	end

	local currentState = record.state
	if currentState == "Collapsed" then
		return false
	end

	local currentHealth = structure:GetAttribute(DestructibleContract.Attribute.CurrentHealth)
	if not isFinitePositiveNumber(currentHealth) then
		warn(`Invalid CurrentHealth on registered destructible {structure:GetFullName()}`)
		return false
	end

	local nextHealth = math.max(0, math.min(record.maxHealth, currentHealth - amount))
	local nextState: DestructionState = if nextHealth <= 0 then "Collapsed" else "Damaged"
	local zoneIndex = LocalizedDamage.ResolveImpactZone(
		record.components.damageHitbox,
		record.surfaceProfile,
		context.position
	)
	local impactPosition, impactNormal = LocalizedDamage.ResolveZoneFrame(
		record.components.damageHitbox,
		record.surfaceProfile,
		zoneIndex
	)
	local nextZoneState = LocalizedDamage.ApplyImpact(
		record.damageZoneState,
		zoneIndex,
		context.attackType,
		Config.Destruction.MaximumPersistentMarksPerStructure
	)
	record.damageZoneState = nextZoneState
	record.impactSequence += 1

	structure:SetAttribute(DestructibleContract.Attribute.CurrentHealth, nextHealth)
	structure:SetAttribute(DestructibleContract.Attribute.DamageZoneState, record.damageZoneState)
	structure:SetAttribute(DestructibleContract.Attribute.ImpactSequence, record.impactSequence)
	self:_setState(record, nextState, player)

	local payload: DestructionEvent = {
		structureId = record.structureId,
		state = nextState,
		stateSequence = record.sequence,
		impactSequence = record.impactSequence,
		position = impactPosition,
		normal = impactNormal,
		attackType = context.attackType,
		zoneIndex = zoneIndex,
		zoneState = record.damageZoneState,
		materialProfile = record.materialProfile,
	}
	self._destructionStateRemote:FireAllClients(payload)

	return true
end

function DestructionService:Reset(structure: Model): boolean
	local record = self._records[structure]
	if not record then
		return false
	end

	structure:SetAttribute(DestructibleContract.Attribute.CurrentHealth, record.maxHealth)
	record.damageZoneState = LocalizedDamage.EmptyState
	structure:SetAttribute(
		DestructibleContract.Attribute.DamageZoneState,
		LocalizedDamage.EmptyState
	)
	self:_setState(record, "Intact", nil)
	return true
end

function DestructionService:GetRegisteredCount(): number
	local count = 0
	for _ in self._records do
		count += 1
	end
	return count
end

function DestructionService:Stop()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._records)
	table.clear(self._recordsById)
end

return DestructionService
