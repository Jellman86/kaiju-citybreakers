--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)
local LocalizedDamage = require(ReplicatedStorage.Shared.LocalizedDamage)
local DestructionEffectProfiles = require(script.Parent.DestructionEffectProfiles)

type AttackType = LocalizedDamage.AttackType
type Components = DestructibleContract.Components
type DestructionState = DestructibleContract.DestructionState
type SurfaceProfile = LocalizedDamage.SurfaceProfile

local LocalizedDamageRenderer = {}
LocalizedDamageRenderer.__index = LocalizedDamageRenderer

local function getDimensions(attackType: AttackType): (number, number)
	if attackType == "Charge" then
		return Config.Destruction.ChargeMarkDiameter * 0.75,
			Config.Destruction.ChargeMarkDiameter * 1.35
	elseif attackType == "Beam" then
		return Config.Destruction.BeamMarkDiameter * 1.35,
			Config.Destruction.BeamMarkDiameter * 0.65
	end
	return Config.Destruction.SmashMarkDiameter * 0.85, Config.Destruction.SmashMarkDiameter * 1.15
end

local function makeSurfaceFrame(position: Vector3, normal: Vector3): CFrame
	local referenceUp = if math.abs(normal:Dot(Vector3.yAxis)) > 0.95
		then Vector3.zAxis
		else Vector3.yAxis
	local yAxis = (referenceUp - normal * normal:Dot(referenceUp)).Unit
	local zAxis = normal:Cross(yAxis).Unit
	return CFrame.fromMatrix(position + normal * 0.12, normal, yAxis, zAxis)
end

local function createPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	isWedge: boolean?
): BasePart
	local part = if isWedge then Instance.new("WedgePart") else Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function setVisible(container: Model, visible: boolean)
	for _, descendant in container:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = if visible then 0 else 1
		end
	end
end

function LocalizedDamageRenderer.new(
	structure: Model,
	components: Components,
	materialProfile: string
)
	local self = setmetatable({}, LocalizedDamageRenderer)
	self._structure = structure
	self._components = components
	self._materialProfile = materialProfile
	self._surfaceProfile = LocalizedDamage.NormalizeSurfaceProfile(
		structure:GetAttribute(DestructibleContract.Attribute.DamageSurfaceProfile)
	) :: SurfaceProfile
	self._zoneState = ""
	self._container = Instance.new("Model")
	self._container.Name = "ClientLocalizedDamage"
	self._container.Parent = structure
	return self
end

function LocalizedDamageRenderer:_createMark(zoneIndex: number, attackType: AttackType)
	local position, normal = LocalizedDamage.ResolveZoneFrame(
		self._components.damageHitbox,
		self._surfaceProfile,
		zoneIndex
	)
	local surfaceFrame = makeSurfaceFrame(position, normal)
	local height, width = getDimensions(attackType)
	local profile = DestructionEffectProfiles.Get(self._materialProfile)

	local mark = Instance.new("Model")
	mark.Name = `DamageZone{zoneIndex}_{attackType}`

	local cavity = createPart(
		"LocalizedDamageHole",
		Vector3.new(0.55, height, width),
		surfaceFrame,
		Color3.fromRGB(18, 20, 21),
		Enum.Material.SmoothPlastic,
		mark,
		false
	)
	cavity.Shape = Enum.PartType.Cylinder

	local rimColor = profile.fragmentColor:Lerp(Color3.fromRGB(38, 34, 32), 0.38)
	for rimIndex, angleDegrees in { 22, 112, 202, 292 } do
		local angle = math.rad(angleDegrees)
		local y = math.cos(angle) * height * 0.48
		local z = math.sin(angle) * width * 0.48
		local length = if rimIndex % 2 == 0 then width * 0.32 else height * 0.34
		createPart(
			"LocalizedDamageRim",
			Vector3.new(0.85, math.max(1.2, length), math.max(0.7, math.min(height, width) * 0.1)),
			surfaceFrame
				* CFrame.new(0.18, y, z)
				* CFrame.Angles(angle + math.rad(rimIndex * 5), 0, math.rad((rimIndex - 2) * 7)),
			rimColor,
			profile.fragmentMaterial,
			mark,
			true
		)
	end

	mark.Parent = self._container
end

function LocalizedDamageRenderer:Sync(zoneState: any, state: DestructionState)
	local normalized = LocalizedDamage.NormalizeState(zoneState)
	if normalized ~= self._zoneState then
		self._zoneState = normalized
		self._container:ClearAllChildren()
		for zoneIndex = 1, LocalizedDamage.ZoneCount do
			local attackType = LocalizedDamage.GetAttackType(normalized, zoneIndex)
			if attackType then
				self:_createMark(zoneIndex, attackType)
			end
		end
	end
	setVisible(self._container, state == "Damaged")
end

function LocalizedDamageRenderer:Destroy()
	self._container:Destroy()
end

return LocalizedDamageRenderer
