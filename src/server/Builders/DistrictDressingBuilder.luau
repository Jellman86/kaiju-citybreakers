--!strict

local DistrictDressingBuilder = {}

local GRASS = Color3.fromRGB(72, 112, 81)
local DEEP_GRASS = Color3.fromRGB(47, 82, 59)
local PAVING = Color3.fromRGB(150, 151, 143)
local PAVING_DARK = Color3.fromRGB(92, 101, 104)
local TRUNK = Color3.fromRGB(79, 61, 48)
local CYAN = Color3.fromRGB(62, 221, 211)
local AMBER = Color3.fromRGB(255, 176, 68)

local function createPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	canCollide: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = canCollide
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createTree(parent: Instance, name: string, position: Vector3)
	local tree = Instance.new("Model")
	tree.Name = name
	tree.Parent = parent

	local trunk = createPart(
		"Trunk",
		Vector3.new(9, 2.8, 2.8),
		CFrame.new(position.X, 5.5, position.Z) * CFrame.Angles(0, 0, math.rad(90)),
		TRUNK,
		Enum.Material.Wood,
		tree,
		false
	)
	trunk.Shape = Enum.PartType.Cylinder

	local canopy = createPart(
		"Canopy",
		Vector3.new(10, 10, 10),
		CFrame.new(position.X, 12, position.Z),
		DEEP_GRASS,
		Enum.Material.Grass,
		tree,
		false
	)
	canopy.Shape = Enum.PartType.Ball
end

local function createLandmark(parent: Instance)
	local landmark = Instance.new("Model")
	landmark.Name = "ParkEnergyMonument"
	landmark.Parent = parent

	createPart(
		"Base",
		Vector3.new(12, 2, 12),
		CFrame.new(-216, 1, 65),
		PAVING_DARK,
		Enum.Material.Concrete,
		landmark,
		false
	)
	createPart(
		"Column",
		Vector3.new(5, 23, 5),
		CFrame.new(-216, 12.5, 65),
		Color3.fromRGB(55, 70, 76),
		Enum.Material.Metal,
		landmark,
		false
	)
	createPart(
		"Crown",
		Vector3.new(10, 3, 10),
		CFrame.new(-216, 25.5, 65),
		AMBER,
		Enum.Material.Neon,
		landmark,
		false
	)
	createPart(
		"EnergyCore",
		Vector3.new(2.2, 14, 2.2),
		CFrame.new(-216, 17, 65),
		CYAN,
		Enum.Material.Neon,
		landmark,
		false
	)
end

local function createEntryPylon(parent: Instance, name: string, position: Vector3)
	local pylon = Instance.new("Model")
	pylon.Name = name
	pylon.Parent = parent

	createPart(
		"Post",
		Vector3.new(3, 14, 3),
		CFrame.new(position.X, 7, position.Z),
		PAVING_DARK,
		Enum.Material.Concrete,
		pylon,
		false
	)
	createPart(
		"Signal",
		Vector3.new(4.5, 2, 4.5),
		CFrame.new(position.X, 14.5, position.Z),
		AMBER,
		Enum.Material.Neon,
		pylon,
		false
	)
end

function DistrictDressingBuilder.BuildWestParkPlaza(parent: Instance): Model
	local park = Instance.new("Model")
	park.Name = "WestParkPlaza"

	createPart(
		"ParkGround",
		Vector3.new(136, 0.5, 64),
		CFrame.new(-166, 0.25, 65),
		GRASS,
		Enum.Material.Grass,
		park,
		true
	)
	createPart(
		"OpenPlaza",
		Vector3.new(88, 0.6, 52),
		CFrame.new(-162, 0.58, 65),
		PAVING,
		Enum.Material.Concrete,
		park,
		true
	)

	for index, ring in
		{
			{ diameter = 46, height = 0.12, color = PAVING_DARK },
			{ diameter = 32, height = 0.14, color = PAVING },
			{ diameter = 16, height = 0.16, color = CYAN },
		}
	do
		local pavingRing = createPart(
			`PlazaRing{index}`,
			Vector3.new(ring.height, ring.diameter, ring.diameter),
			CFrame.new(-162, 0.92 + index * 0.08, 65) * CFrame.Angles(0, 0, math.rad(90)),
			ring.color,
			Enum.Material.Slate,
			park,
			false
		)
		pavingRing.Shape = Enum.PartType.Cylinder
	end

	for index, position in
		{
			Vector3.new(-225, 0, 43),
			Vector3.new(-225, 0, 65),
			Vector3.new(-225, 0, 87),
			Vector3.new(-203, 0, 92),
			Vector3.new(-178, 0, 92),
			Vector3.new(-108, 0, 43),
			Vector3.new(-108, 0, 87),
		}
	do
		createTree(park, `Tree{index}`, position)
	end

	for index, position in
		{
			Vector3.new(-211, 0, 41),
			Vector3.new(-211, 0, 89),
			Vector3.new(-113, 0, 52),
			Vector3.new(-113, 0, 78),
		}
	do
		createPart(
			`Planter{index}`,
			Vector3.new(12, 2, 4),
			CFrame.new(position.X, 1, position.Z),
			PAVING_DARK,
			Enum.Material.Concrete,
			park,
			false
		)
	end

	createLandmark(park)
	createEntryPylon(park, "SouthEntryPylon", Vector3.new(-118, 0, 41))
	createEntryPylon(park, "NorthEntryPylon", Vector3.new(-118, 0, 89))

	park.Parent = parent
	return park
end

return table.freeze(DistrictDressingBuilder)
