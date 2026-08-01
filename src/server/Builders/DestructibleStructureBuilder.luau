--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)

export type VisualModels = {
	intact: Model,
	damaged: Model,
	collapsed: Model,
}

export type Definition = {
	name: string,
	structureId: string,
	maxHealth: number,
	energyValue: number,
	materialProfile: string,
	intactCollisionCFrame: CFrame,
	intactCollisionSize: Vector3,
	collapsedCollisionCFrame: CFrame,
	collapsedCollisionSize: Vector3,
	damageHitboxCFrame: CFrame,
	damageHitboxSize: Vector3,
}

type VisualBuilder = (visuals: VisualModels) -> ()

local DestructibleStructureBuilder = {}

local function createModel(name: string, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

local function createInvisiblePart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	parent: Instance,
	canCollide: boolean,
	canQuery: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = canCollide
	part.CanTouch = false
	part.CanQuery = canQuery
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function validateAuthoredVisuals(visuals: VisualModels)
	for variantName, variant in visuals do
		local partCount = 0
		for _, descendant in variant:GetDescendants() do
			if descendant:IsA("BasePart") then
				partCount += 1
				assert(descendant.Anchored, `{variantName} visual parts must be anchored`)
				assert(
					not descendant.CanCollide
						and not descendant.CanTouch
						and not descendant.CanQuery,
					`{variantName} visual parts must not participate in gameplay physics`
				)
			end
		end
		assert(partCount > 0, `{variantName} must contain at least one visual part`)
	end
end

function DestructibleStructureBuilder.Build(
	parent: Instance,
	definition: Definition,
	buildVisuals: VisualBuilder
): Model
	local structure = Instance.new("Model")
	structure.Name = definition.name
	structure.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	structure:SetAttribute(DestructibleContract.Attribute.StructureId, definition.structureId)
	structure:SetAttribute(DestructibleContract.Attribute.MaxHealth, definition.maxHealth)
	structure:SetAttribute(DestructibleContract.Attribute.EnergyValue, definition.energyValue)
	structure:SetAttribute(
		DestructibleContract.Attribute.MaterialProfile,
		definition.materialProfile
	)

	local visualRoot = createModel("Visuals", structure)
	local visuals: VisualModels = {
		intact = createModel("Intact", visualRoot),
		damaged = createModel("Damaged", visualRoot),
		collapsed = createModel("Collapsed", visualRoot),
	}
	buildVisuals(visuals)
	validateAuthoredVisuals(visuals)

	local collision = createModel("Collision", structure)
	createInvisiblePart(
		"IntactProxy",
		definition.intactCollisionSize,
		definition.intactCollisionCFrame,
		collision,
		true,
		false
	)
	createInvisiblePart(
		"CollapsedProxy",
		definition.collapsedCollisionSize,
		definition.collapsedCollisionCFrame,
		collision,
		false,
		false
	)

	local damageHitbox = createInvisiblePart(
		"DamageHitbox",
		definition.damageHitboxSize,
		definition.damageHitboxCFrame,
		structure,
		false,
		true
	)
	local fxOrigin = Instance.new("Attachment")
	fxOrigin.Name = "FxOrigin"
	fxOrigin.Parent = damageHitbox

	local _, validationError = DestructibleContract.Validate(structure)
	assert(validationError == nil, validationError)

	structure.Parent = parent
	CollectionService:AddTag(structure, DestructibleContract.Tag)
	return structure
end

return table.freeze(DestructibleStructureBuilder)
