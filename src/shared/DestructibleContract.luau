--!strict

local DestructibleContract = {}

DestructibleContract.Tag = "Destructible"
DestructibleContract.DamageHitboxCollisionGroup = "DestructibleQuery"
DestructibleContract.AttackQueryCollisionGroup = "KaijuAttackQuery"

DestructibleContract.Attribute = table.freeze({
	StructureId = "StructureId",
	MaxHealth = "MaxHealth",
	CurrentHealth = "CurrentHealth",
	EnergyValue = "EnergyValue",
	MaterialProfile = "MaterialProfile",
	State = "DestructionState",
	StateSequence = "DestructionStateSequence",
})

export type DestructionState = "Intact" | "Damaged" | "Collapsed"

export type Components = {
	visuals: Model,
	intactVisual: Model,
	damagedVisual: Model,
	collapsedVisual: Model,
	collision: Model,
	intactCollision: BasePart,
	collapsedCollision: BasePart,
	damageHitbox: BasePart,
	fxOrigin: Attachment,
}

local function isFiniteNumber(value: any): boolean
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

local function requireChild(parent: Instance, name: string, className: string): (Instance?, string?)
	local child = parent:FindFirstChild(name)
	if not child then
		return nil, `{parent:GetFullName()} is missing {name}`
	end
	if not child:IsA(className) then
		return nil, `{child:GetFullName()} must be a {className}`
	end
	return child, nil
end

function DestructibleContract.IsState(value: any): boolean
	return value == "Intact" or value == "Damaged" or value == "Collapsed"
end

function DestructibleContract.Validate(structure: Model): (Components?, string?)
	local structureId = structure:GetAttribute(DestructibleContract.Attribute.StructureId)
	if typeof(structureId) ~= "string" or structureId == "" then
		return nil, `{structure:GetFullName()} requires a non-empty StructureId attribute`
	end

	local maxHealth = structure:GetAttribute(DestructibleContract.Attribute.MaxHealth)
	if not isFiniteNumber(maxHealth) or maxHealth <= 0 then
		return nil, `{structure:GetFullName()} requires a finite MaxHealth greater than zero`
	end

	local energyValue = structure:GetAttribute(DestructibleContract.Attribute.EnergyValue)
	if not isFiniteNumber(energyValue) or energyValue < 0 then
		return nil, `{structure:GetFullName()} requires a finite, non-negative EnergyValue`
	end

	local materialProfile = structure:GetAttribute(DestructibleContract.Attribute.MaterialProfile)
	if typeof(materialProfile) ~= "string" or materialProfile == "" then
		return nil, `{structure:GetFullName()} requires a non-empty MaterialProfile attribute`
	end

	local visualsInstance, visualsError = requireChild(structure, "Visuals", "Model")
	if not visualsInstance then
		return nil, visualsError
	end
	local visuals = visualsInstance :: Model

	local intactVisualInstance, intactVisualError = requireChild(visuals, "Intact", "Model")
	if not intactVisualInstance then
		return nil, intactVisualError
	end
	local damagedVisualInstance, damagedVisualError = requireChild(visuals, "Damaged", "Model")
	if not damagedVisualInstance then
		return nil, damagedVisualError
	end
	local collapsedVisualInstance, collapsedVisualError =
		requireChild(visuals, "Collapsed", "Model")
	if not collapsedVisualInstance then
		return nil, collapsedVisualError
	end

	local collisionInstance, collisionError = requireChild(structure, "Collision", "Model")
	if not collisionInstance then
		return nil, collisionError
	end
	local collision = collisionInstance :: Model

	local intactCollisionInstance, intactCollisionError =
		requireChild(collision, "IntactProxy", "BasePart")
	if not intactCollisionInstance then
		return nil, intactCollisionError
	end
	local collapsedCollisionInstance, collapsedCollisionError =
		requireChild(collision, "CollapsedProxy", "BasePart")
	if not collapsedCollisionInstance then
		return nil, collapsedCollisionError
	end

	local damageHitboxInstance, damageHitboxError =
		requireChild(structure, "DamageHitbox", "BasePart")
	if not damageHitboxInstance then
		return nil, damageHitboxError
	end
	local damageHitbox = damageHitboxInstance :: BasePart

	local fxOriginInstance, fxOriginError = requireChild(damageHitbox, "FxOrigin", "Attachment")
	if not fxOriginInstance then
		return nil, fxOriginError
	end

	return {
		visuals = visuals,
		intactVisual = intactVisualInstance :: Model,
		damagedVisual = damagedVisualInstance :: Model,
		collapsedVisual = collapsedVisualInstance :: Model,
		collision = collision,
		intactCollision = intactCollisionInstance :: BasePart,
		collapsedCollision = collapsedCollisionInstance :: BasePart,
		damageHitbox = damageHitbox,
		fxOrigin = fxOriginInstance :: Attachment,
	},
		nil
end

return table.freeze(DestructibleContract)
