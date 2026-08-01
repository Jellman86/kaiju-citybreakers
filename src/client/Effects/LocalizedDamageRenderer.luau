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

local function getDimensions(
	attackType: AttackType,
	hitbox: BasePart,
	normal: Vector3
): (number, number)
	local height: number
	local width: number
	if attackType == "Charge" then
		height = Config.Destruction.ChargeMarkDiameter * 0.68
		width = Config.Destruction.ChargeMarkDiameter * 1.28
	elseif attackType == "Beam" then
		height = Config.Destruction.BeamMarkDiameter * 1.28
		width = Config.Destruction.BeamMarkDiameter * 0.52
	else
		height = Config.Destruction.SmashMarkDiameter * 0.88
		width = Config.Destruction.SmashMarkDiameter * 1.12
	end

	local localNormal = hitbox.CFrame:VectorToObjectSpace(normal)
	local faceWidth = if math.abs(localNormal.X) > math.abs(localNormal.Z)
		then hitbox.Size.Z
		else hitbox.Size.X
	return math.max(4, math.min(height, hitbox.Size.Y * 0.56)),
		math.max(4, math.min(width, faceWidth * 0.84))
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
	part.CastShadow = name == "LocalizedDamageRim"
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
	local height, width = getDimensions(attackType, self._components.damageHitbox, normal)
	local profile = DestructionEffectProfiles.Get(self._materialProfile)

	local mark = Instance.new("Model")
	mark.Name = `DamageZone{zoneIndex}_{attackType}`

	local cavityRotation = if attackType == "Charge"
		then math.rad(6)
		elseif attackType == "Beam" then math.rad(-9)
		else math.rad((zoneIndex * 17) % 24 - 12)
	for cavityIndex, definition in
		{
			{ heightScale = 1, widthScale = 1, y = 0, z = 0 },
			{ heightScale = 0.62, widthScale = 0.7, y = -0.27, z = 0.29 },
			{ heightScale = 0.5, widthScale = 0.58, y = 0.32, z = -0.31 },
		}
	do
		local cavity = createPart(
			if cavityIndex == 1 then "LocalizedDamageHole" else "LocalizedDamageVoid",
			Vector3.new(
				1.7 + cavityIndex * 0.18,
				height * definition.heightScale,
				width * definition.widthScale
			),
			surfaceFrame
				* CFrame.new(
					0.16 + cavityIndex * 0.035,
					height * definition.y,
					width * definition.z
				)
				* CFrame.Angles(cavityRotation + math.rad((cavityIndex - 2) * 7), 0, 0),
			Color3.fromRGB(10 + cavityIndex * 3, 12 + cavityIndex * 3, 13 + cavityIndex * 3),
			Enum.Material.SmoothPlastic,
			mark,
			false
		)
		cavity.Shape = Enum.PartType.Cylinder
	end

	local rimColor = profile.fragmentColor:Lerp(Color3.fromRGB(44, 39, 35), 0.26)
	for rimIndex, angleDegrees in { 16, 82, 151, 224, 303 } do
		local angle = math.rad(angleDegrees)
		local radialScale = if rimIndex % 2 == 0 then 0.51 else 0.56
		local y = math.cos(angle) * height * radialScale
		local z = math.sin(angle) * width * radialScale
		local length = math.max(2.4, math.min(height, width) * (0.26 + rimIndex * 0.018))
		createPart(
			"LocalizedDamageRim",
			Vector3.new(2.2, length, math.max(1.15, math.min(height, width) * 0.14)),
			surfaceFrame
				* CFrame.new(0.62 + (rimIndex % 2) * 0.18, y, z)
				* CFrame.Angles(angle + math.rad(rimIndex * 4), 0, math.rad((rimIndex - 3) * 9)),
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
