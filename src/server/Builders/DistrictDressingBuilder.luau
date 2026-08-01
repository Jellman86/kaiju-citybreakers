--!strict

local DistrictDressingBuilder = {}

local GRASS = Color3.fromRGB(72, 112, 81)
local DEEP_GRASS = Color3.fromRGB(47, 82, 59)
local PAVING = Color3.fromRGB(150, 151, 143)
local PAVING_DARK = Color3.fromRGB(92, 101, 104)
local TRUNK = Color3.fromRGB(79, 61, 48)
local CYAN = Color3.fromRGB(62, 221, 211)
local AMBER = Color3.fromRGB(255, 176, 68)
local WATER = Color3.fromRGB(42, 132, 176)
local SAND = Color3.fromRGB(199, 181, 135)
local ROCK = Color3.fromRGB(83, 91, 96)
local INDUSTRIAL = Color3.fromRGB(47, 56, 61)

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

local function createZoneLabel(
	parent: Instance,
	name: string,
	text: string,
	position: Vector3,
	accent: Color3
)
	local sign = Instance.new("Model")
	sign.Name = name
	sign.Parent = parent

	createPart(
		"Post",
		Vector3.new(3, 18, 3),
		CFrame.new(position.X, 9, position.Z),
		PAVING_DARK,
		Enum.Material.Metal,
		sign,
		false
	)
	local face = createPart(
		"Face",
		Vector3.new(30, 8, 2),
		CFrame.new(position.X, 20, position.Z),
		accent,
		Enum.Material.Neon,
		sign,
		false
	)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ZoneName"
	billboard.Adornee = face
	billboard.Size = UDim2.fromOffset(250, 50)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 230
	billboard.Parent = face

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(14, 22, 28)
	label.BackgroundTransparency = 0.14
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(244, 249, 246)
	label.TextScaled = true
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label
end

local function createWedge(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	parent: Instance
): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Color = color
	wedge.Material = Enum.Material.Slate
	wedge.Anchored = true
	wedge.CanCollide = true
	wedge.CanTouch = false
	wedge.CanQuery = false
	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth
	wedge.Parent = parent
	return wedge
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

function DistrictDressingBuilder.BuildTitanPark(parent: Instance): Model
	local park = Instance.new("Model")
	park.Name = "TitanParkZone"

	createPart(
		"TitanParkGround",
		Vector3.new(340, 0.7, 260),
		CFrame.new(-450, 0.35, 145),
		GRASS,
		Enum.Material.Grass,
		park,
		true
	)
	createPart(
		"GrandPromenade",
		Vector3.new(300, 0.35, 26),
		CFrame.new(-450, 0.78, 145),
		PAVING,
		Enum.Material.Concrete,
		park,
		true
	)
	createPart(
		"NorthSouthPath",
		Vector3.new(26, 0.35, 226),
		CFrame.new(-450, 0.8, 145),
		PAVING,
		Enum.Material.Concrete,
		park,
		true
	)
	createPart(
		"FestivalPlaza",
		Vector3.new(104, 0.4, 76),
		CFrame.new(-450, 0.86, 145),
		PAVING_DARK,
		Enum.Material.Slate,
		park,
		true
	)

	for index, position in
		{
			Vector3.new(-595, 0, 45),
			Vector3.new(-550, 0, 45),
			Vector3.new(-500, 0, 45),
			Vector3.new(-400, 0, 45),
			Vector3.new(-350, 0, 45),
			Vector3.new(-305, 0, 45),
			Vector3.new(-595, 0, 245),
			Vector3.new(-550, 0, 245),
			Vector3.new(-500, 0, 245),
			Vector3.new(-400, 0, 245),
			Vector3.new(-350, 0, 245),
			Vector3.new(-305, 0, 245),
			Vector3.new(-590, 0, 105),
			Vector3.new(-590, 0, 185),
			Vector3.new(-310, 0, 105),
			Vector3.new(-310, 0, 185),
		}
	do
		createTree(park, `TitanTree{index}`, position)
	end

	createPart(
		"TitanMonumentBase",
		Vector3.new(30, 4, 30),
		CFrame.new(-450, 2.5, 145),
		PAVING,
		Enum.Material.Concrete,
		park,
		false
	)
	local monument = createPart(
		"TitanEnergyOrb",
		Vector3.new(22, 22, 22),
		CFrame.new(-450, 20, 145),
		CYAN,
		Enum.Material.Neon,
		park,
		false
	)
	monument.Shape = Enum.PartType.Ball
	createZoneLabel(
		park,
		"TitanParkSign",
		"TITAN PARK",
		Vector3.new(-275, 0, 145),
		Color3.fromRGB(73, 168, 91)
	)

	park.Parent = parent
	return park
end

function DistrictDressingBuilder.BuildArcPowerPlant(parent: Instance): Model
	local plant = Instance.new("Model")
	plant.Name = "ArcPowerPlantZone"

	createPart(
		"PlantYard",
		Vector3.new(350, 0.8, 300),
		CFrame.new(455, 0.4, -80),
		INDUSTRIAL,
		Enum.Material.Asphalt,
		plant,
		true
	)
	for index, z in { -190, -120, -40, 40 } do
		createPart(
			`EnergyChannel{index}`,
			Vector3.new(310, 0.25, 3),
			CFrame.new(455, 0.92, z),
			CYAN,
			Enum.Material.Neon,
			plant,
			false
		)
	end
	for index, x in { 335, 455, 575 } do
		createPart(
			`ServiceLane{index}`,
			Vector3.new(28, 0.3, 270),
			CFrame.new(x, 0.95, -80),
			Color3.fromRGB(71, 77, 78),
			Enum.Material.Concrete,
			plant,
			true
		)
	end
	for index, position in
		{
			Vector3.new(390, 0, -155),
			Vector3.new(520, 0, -155),
			Vector3.new(390, 0, 15),
			Vector3.new(520, 0, 15),
		}
	do
		local basin = createPart(
			`CoolingBasin{index}`,
			Vector3.new(2, 54, 54),
			CFrame.new(position.X, 1.2, position.Z) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(73, 91, 98),
			Enum.Material.Metal,
			plant,
			false
		)
		basin.Shape = Enum.PartType.Cylinder
	end
	createZoneLabel(plant, "ArcPlantSign", "ARC POWER PLANT", Vector3.new(275, 0, -80), CYAN)

	plant.Parent = parent
	return plant
end

function DistrictDressingBuilder.BuildMountBrontide(parent: Instance): Model
	local mountain = Instance.new("Model")
	mountain.Name = "MountBrontideZone"

	createPart(
		"MountainFoothills",
		Vector3.new(370, 0.8, 270),
		CFrame.new(440, 0.4, 285),
		DEEP_GRASS,
		Enum.Material.Grass,
		mountain,
		true
	)
	for index, definition in
		{
			{ position = Vector3.new(535, 48, 330), size = Vector3.new(150, 96, 150), yaw = -18 },
			{ position = Vector3.new(455, 68, 355), size = Vector3.new(165, 136, 170), yaw = 12 },
			{ position = Vector3.new(590, 76, 245), size = Vector3.new(130, 152, 150), yaw = -35 },
			{ position = Vector3.new(385, 38, 350), size = Vector3.new(120, 76, 120), yaw = 24 },
		}
	do
		createWedge(
			`RidgeFace{index}`,
			definition.size,
			CFrame.new(definition.position) * CFrame.Angles(0, math.rad(definition.yaw), 0),
			ROCK:Lerp(Color3.new(1, 1, 1), index * 0.035),
			mountain
		)
	end
	createPart(
		"OverlookRoad",
		Vector3.new(42, 0.4, 220),
		CFrame.new(315, 0.85, 285),
		PAVING_DARK,
		Enum.Material.Slate,
		mountain,
		true
	)
	createPart(
		"SummitBeacon",
		Vector3.new(5, 42, 5),
		CFrame.new(455, 150, 355),
		AMBER,
		Enum.Material.Neon,
		mountain,
		false
	)
	createZoneLabel(
		mountain,
		"MountBrontideSign",
		"MOUNT BRONTIDE",
		Vector3.new(275, 0, 190),
		AMBER
	)

	mountain.Parent = parent
	return mountain
end

function DistrictDressingBuilder.BuildAzureLake(parent: Instance): Model
	local lake = Instance.new("Model")
	lake.Name = "AzureLakeZone"

	createPart(
		"LakeShore",
		Vector3.new(380, 0.7, 330),
		CFrame.new(-450, 0.35, -395),
		SAND,
		Enum.Material.Sand,
		lake,
		true
	)
	local water = createPart(
		"AzureWater",
		Vector3.new(320, 0.35, 270),
		CFrame.new(-465, 0.78, -400),
		WATER,
		Enum.Material.Glass,
		lake,
		false
	)
	water.Transparency = 0.18
	createPart(
		"KaijuIsland",
		Vector3.new(84, 1.1, 62),
		CFrame.new(-470, 1.15, -405) * CFrame.Angles(0, math.rad(12), 0),
		DEEP_GRASS,
		Enum.Material.Grass,
		lake,
		true
	)
	createPart(
		"MarinaBoardwalk",
		Vector3.new(150, 1, 20),
		CFrame.new(-300, 1.3, -305),
		TRUNK,
		Enum.Material.WoodPlanks,
		lake,
		true
	)
	for index, x in { -360, -320, -280 } do
		createPart(
			`MarinaPier{index}`,
			Vector3.new(12, 0.8, 92),
			CFrame.new(x, 1.15, -350),
			TRUNK,
			Enum.Material.WoodPlanks,
			lake,
			true
		)
	end
	for index, position in
		{
			Vector3.new(-515, 0, -402),
			Vector3.new(-470, 0, -425),
			Vector3.new(-435, 0, -390),
		}
	do
		createTree(lake, `IslandTree{index}`, position)
	end
	createZoneLabel(lake, "AzureLakeSign", "AZURE LAKE", Vector3.new(-255, 0, -250), WATER)

	lake.Parent = parent
	return lake
end

return table.freeze(DistrictDressingBuilder)
