--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)

local PrototypeWorldService = {}
PrototypeWorldService.__index = PrototypeWorldService

local ASPHALT = Color3.fromRGB(43, 49, 55)
local CONCRETE = Color3.fromRGB(111, 120, 126)
local CURB = Color3.fromRGB(177, 183, 181)
local WINDOW = Color3.fromRGB(255, 187, 77)
local CYAN = Color3.fromRGB(62, 221, 211)

local function createPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createTrimPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = createPart(name, size, cframe, color, material, parent)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	return part
end

local function createVisualPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = createPart(name, size, cframe, color, material, parent)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	return part
end

local function createLabel(adornee: BasePart)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ObjectiveLabel"
	billboard.Adornee = adornee
	billboard.Size = UDim2.fromOffset(420, 100)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 13, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Text = "BREAK THE CITY GATE\nCHARGE • THEN SMASH TWICE"
	label.TextColor3 = Color3.fromRGB(255, 224, 92)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
end

local function createWindowBands(
	building: Model,
	position: Vector3,
	size: Vector3,
	baseHeight: number,
	windowColor: Color3
)
	local bandCount = math.clamp(math.floor(size.Y / 8), 2, 5)
	for index = 1, bandCount do
		local y = baseHeight
			- size.Y / 2
			+ 5
			+ (index - 1) * ((size.Y - 8) / math.max(bandCount - 1, 1))
		createTrimPart(
			`FrontWindows{index}`,
			Vector3.new(math.max(size.X - 5, 4), 1.5, 0.3),
			CFrame.new(position.X, y, position.Z - size.Z / 2 - 0.16),
			windowColor,
			Enum.Material.Neon,
			building
		)
		createTrimPart(
			`SideWindows{index}`,
			Vector3.new(0.3, 1.5, math.max(size.Z - 5, 4)),
			CFrame.new(position.X + size.X / 2 + 0.16, y, position.Z),
			windowColor,
			Enum.Material.Neon,
			building
		)
	end
end

local function createBuilding(
	parent: Instance,
	name: string,
	position: Vector3,
	size: Vector3,
	color: Color3,
	accent: Color3
): Model
	local building = Instance.new("Model")
	building.Name = name
	building.Parent = parent

	local baseHeight = size.Y / 2
	createPart(
		"Shell",
		size,
		CFrame.new(position.X, baseHeight, position.Z),
		color,
		Enum.Material.Concrete,
		building
	)
	createPart(
		"Roof",
		Vector3.new(size.X + 1.5, 1.2, size.Z + 1.5),
		CFrame.new(position.X, size.Y + 0.6, position.Z),
		accent,
		Enum.Material.Metal,
		building
	)
	createPart(
		"RooftopUnit",
		Vector3.new(math.min(size.X * 0.38, 9), 3, math.min(size.Z * 0.38, 8)),
		CFrame.new(position.X, size.Y + 2.1, position.Z),
		Color3.fromRGB(67, 76, 82),
		Enum.Material.Metal,
		building
	)
	createWindowBands(building, position, size, baseHeight, WINDOW)

	return building
end

local function createStreetlight(parent: Instance, position: Vector3, facing: number)
	local light = Instance.new("Model")
	light.Name = "Streetlight"
	light.Parent = parent

	createPart(
		"Pole",
		Vector3.new(0.65, 11, 0.65),
		CFrame.new(position.X, 5.5, position.Z),
		Color3.fromRGB(42, 51, 57),
		Enum.Material.Metal,
		light
	)
	createPart(
		"Arm",
		Vector3.new(3.5, 0.5, 0.5),
		CFrame.new(position.X + facing * 1.45, 10.8, position.Z),
		Color3.fromRGB(42, 51, 57),
		Enum.Material.Metal,
		light
	)
	local lamp = createTrimPart(
		"Lamp",
		Vector3.new(1.4, 0.45, 1.2),
		CFrame.new(position.X + facing * 3, 10.45, position.Z),
		Color3.fromRGB(255, 218, 124),
		Enum.Material.Neon,
		light
	)
	local pointLight = Instance.new("PointLight")
	pointLight.Color = lamp.Color
	pointLight.Brightness = 0.7
	pointLight.Range = 16
	pointLight.Parent = lamp
end

local function createCar(parent: Instance, name: string, position: Vector3, color: Color3)
	local car = Instance.new("Model")
	car.Name = name
	car.Parent = parent

	createPart(
		"Body",
		Vector3.new(5.5, 1.7, 9),
		CFrame.new(position.X, 1.4, position.Z),
		color,
		Enum.Material.Metal,
		car
	)
	createPart(
		"Cabin",
		Vector3.new(4.4, 1.8, 4.4),
		CFrame.new(position.X, 3.1, position.Z + 0.4),
		Color3.fromRGB(49, 74, 84),
		Enum.Material.Glass,
		car
	)
	createTrimPart(
		"Headlights",
		Vector3.new(4.2, 0.45, 0.25),
		CFrame.new(position.X, 1.55, position.Z - 4.62),
		Color3.fromRGB(255, 239, 170),
		Enum.Material.Neon,
		car
	)
end

local function createCrosswalk(parent: Instance, zPosition: number)
	for index = -4, 4 do
		createTrimPart(
			`CrosswalkStripe{index + 5}`,
			Vector3.new(2.2, 0.08, 8),
			CFrame.new(index * 3.2, 0.08, zPosition),
			Color3.fromRGB(225, 225, 211),
			Enum.Material.Concrete,
			parent
		)
	end
end

local function createWall(parent: Instance): Model
	local wall = Instance.new("Model")
	wall.Name = "BreakableCityGate"
	wall.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	wall:SetAttribute(DestructibleContract.Attribute.StructureId, Config.Prototype.WallStructureId)
	wall:SetAttribute(DestructibleContract.Attribute.MaxHealth, Config.Prototype.WallMaxHealth)
	wall:SetAttribute(DestructibleContract.Attribute.EnergyValue, 10)
	wall:SetAttribute(DestructibleContract.Attribute.MaterialProfile, "Concrete")

	local wallCFrame = CFrame.new(0, 11, -28)

	local visuals = Instance.new("Model")
	visuals.Name = "Visuals"
	visuals.Parent = wall

	local intact = Instance.new("Model")
	intact.Name = "Intact"
	intact.Parent = visuals
	local intactPart = createVisualPart(
		"Gate",
		Vector3.new(30, 22, 7),
		wallCFrame,
		Color3.fromRGB(54, 86, 112),
		Enum.Material.Concrete,
		intact
	)
	createTrimPart(
		"WarningBand",
		Vector3.new(26, 2.4, 0.35),
		wallCFrame * CFrame.new(0, 2, -3.7),
		Color3.fromRGB(255, 153, 61),
		Enum.Material.Neon,
		intact
	)
	createLabel(intactPart)

	local damaged = Instance.new("Model")
	damaged.Name = "Damaged"
	damaged.Parent = visuals
	local damagedPart = createVisualPart(
		"Gate",
		Vector3.new(30, 22, 7),
		wallCFrame * CFrame.Angles(0, 0, math.rad(-2)),
		Color3.fromRGB(93, 73, 69),
		Enum.Material.Concrete,
		damaged
	)

	for index = -1, 1 do
		local crack = createTrimPart(
			`Crack{index + 2}`,
			Vector3.new(0.35, 9, 0.35),
			wallCFrame
				* CFrame.new(index * 6, index * 2, -3.65)
				* CFrame.Angles(0, 0, math.rad(index * 18 + 12)),
			Color3.fromRGB(255, 139, 61),
			Enum.Material.Neon,
			damaged
		)
		crack.CanCollide = false
	end
	createLabel(damagedPart)

	local collapsed = Instance.new("Model")
	collapsed.Name = "Collapsed"
	collapsed.Parent = visuals
	for index = 1, 7 do
		local column = ((index - 1) % 4) - 1.5
		local row = math.floor((index - 1) / 4)
		createVisualPart(
			`Rubble{index}`,
			Vector3.new(6.5, 3 + (index % 2), 6),
			CFrame.new(column * 6.5, 1.5 + row, -28 + row * 4)
				* CFrame.Angles(0, math.rad(index * 19), math.rad(index * 7)),
			Color3.fromRGB(70, 78, 83),
			Enum.Material.Concrete,
			collapsed
		)
	end

	local collision = Instance.new("Model")
	collision.Name = "Collision"
	collision.Parent = wall

	local intactProxy = createPart(
		"IntactProxy",
		Vector3.new(30, 22, 7),
		wallCFrame,
		Color3.new(0, 0, 0),
		Enum.Material.SmoothPlastic,
		collision
	)
	intactProxy.Transparency = 1
	intactProxy.CanTouch = false
	intactProxy.CanQuery = false
	intactProxy.CastShadow = false

	local collapsedProxy = createPart(
		"CollapsedProxy",
		Vector3.new(30, 1.5, 8),
		CFrame.new(0, 0.75, -28),
		Color3.new(0, 0, 0),
		Enum.Material.SmoothPlastic,
		collision
	)
	collapsedProxy.Transparency = 1
	collapsedProxy.CanCollide = false
	collapsedProxy.CanTouch = false
	collapsedProxy.CanQuery = false
	collapsedProxy.CastShadow = false

	local damageHitbox = createPart(
		"DamageHitbox",
		Vector3.new(30, 22, 10),
		wallCFrame,
		Color3.new(0, 0, 0),
		Enum.Material.SmoothPlastic,
		wall
	)
	damageHitbox.Transparency = 1
	damageHitbox.CanCollide = false
	damageHitbox.CanTouch = false
	damageHitbox.CanQuery = true
	damageHitbox.CastShadow = false

	local fxOrigin = Instance.new("Attachment")
	fxOrigin.Name = "FxOrigin"
	fxOrigin.Position = Vector3.new(0, 0, 0)
	fxOrigin.Parent = damageHitbox

	CollectionService:AddTag(wall, DestructibleContract.Tag)
	wall.Parent = parent
	return wall
end

local function configureLighting()
	Lighting.ClockTime = 17.25
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(61, 69, 82)
	Lighting.OutdoorAmbient = Color3.fromRGB(103, 111, 126)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 210, 156)

	local oldAtmosphere = Lighting:FindFirstChild("KaijuCityAtmosphere")
	if oldAtmosphere then
		oldAtmosphere:Destroy()
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "KaijuCityAtmosphere"
	atmosphere.Color = Color3.fromRGB(183, 203, 218)
	atmosphere.Decay = Color3.fromRGB(86, 100, 122)
	atmosphere.Density = 0.24
	atmosphere.Haze = 1.25
	atmosphere.Glare = 0.08
	atmosphere.Parent = Lighting
end

function PrototypeWorldService.new()
	return setmetatable({}, PrototypeWorldService)
end

function PrototypeWorldService:Start()
	local existing = workspace:FindFirstChild(Config.Prototype.WorldName)
	if existing then
		existing:Destroy()
	end

	local legacyBaseplate = workspace:FindFirstChild("Baseplate")
	if legacyBaseplate and legacyBaseplate:IsA("BasePart") then
		legacyBaseplate:Destroy()
	end

	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			descendant.Enabled = false
		end
	end

	configureLighting()

	local world = Instance.new("Folder")
	world.Name = Config.Prototype.WorldName
	world.Parent = workspace

	createPart(
		"CityFoundation",
		Vector3.new(220, 2, 220),
		CFrame.new(0, -1, -18),
		CONCRETE,
		Enum.Material.Concrete,
		world
	)
	createPart(
		"MainAvenue",
		Vector3.new(34, 0.3, 220),
		CFrame.new(0, 0.08, -18),
		ASPHALT,
		Enum.Material.Asphalt,
		world
	)
	createPart(
		"CrossStreet",
		Vector3.new(220, 0.3, 28),
		CFrame.new(0, 0.1, 24),
		ASPHALT,
		Enum.Material.Asphalt,
		world
	)

	for _, x in { -20, 20 } do
		createPart(
			`MainSidewalk{x}`,
			Vector3.new(6, 0.6, 220),
			CFrame.new(x, 0.3, -18),
			CURB,
			Enum.Material.Concrete,
			world
		)
	end
	for _, z in { 7, 41 } do
		createPart(
			`CrossSidewalk{z}`,
			Vector3.new(220, 0.6, 5),
			CFrame.new(0, 0.3, z),
			CURB,
			Enum.Material.Concrete,
			world
		)
	end

	createCrosswalk(world, 9)
	createCrosswalk(world, 39)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "KaijuSpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 1, 69), Vector3.new(0, 1, -28))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Enabled = true
	spawn.Duration = 0
	spawn.Anchored = true
	spawn.Parent = world

	createBuilding(
		world,
		"GateTowerWest",
		Vector3.new(-28, 0, -28),
		Vector3.new(20, 38, 24),
		Color3.fromRGB(58, 77, 91),
		Color3.fromRGB(44, 55, 65)
	)
	createBuilding(
		world,
		"GateTowerEast",
		Vector3.new(28, 0, -28),
		Vector3.new(20, 38, 24),
		Color3.fromRGB(58, 77, 91),
		Color3.fromRGB(44, 55, 65)
	)
	createWall(world)

	createBuilding(
		world,
		"CivicWest",
		Vector3.new(-47, 0, 48),
		Vector3.new(32, 25, 28),
		Color3.fromRGB(91, 105, 112),
		Color3.fromRGB(63, 73, 80)
	)
	createBuilding(
		world,
		"CivicEast",
		Vector3.new(49, 0, 51),
		Vector3.new(35, 33, 26),
		Color3.fromRGB(68, 92, 105),
		Color3.fromRGB(45, 59, 69)
	)
	createBuilding(
		world,
		"MarketWest",
		Vector3.new(-48, 0, 22),
		Vector3.new(30, 20, 18),
		Color3.fromRGB(112, 84, 76),
		Color3.fromRGB(74, 56, 54)
	)
	createBuilding(
		world,
		"MarketEast",
		Vector3.new(49, 0, 20),
		Vector3.new(32, 25, 18),
		Color3.fromRGB(79, 94, 112),
		Color3.fromRGB(52, 65, 79)
	)
	createBuilding(
		world,
		"HarbourWest",
		Vector3.new(-52, 0, -67),
		Vector3.new(38, 30, 30),
		Color3.fromRGB(72, 93, 97),
		Color3.fromRGB(46, 63, 67)
	)
	createBuilding(
		world,
		"HarbourEast",
		Vector3.new(51, 0, -68),
		Vector3.new(34, 44, 32),
		Color3.fromRGB(65, 78, 94),
		Color3.fromRGB(40, 50, 64)
	)

	for _, z in { 57, 34, 4, -14, -49 } do
		createStreetlight(world, Vector3.new(-15, 0, z), 1)
		createStreetlight(world, Vector3.new(15, 0, z), -1)
	end

	createCar(world, "EmergencyCar", Vector3.new(-8, 0, 18), Color3.fromRGB(217, 74, 59))
	createCar(world, "CityCar", Vector3.new(8, 0, -52), Color3.fromRGB(59, 121, 168))

	createTrimPart(
		"AvenueCentreLine",
		Vector3.new(0.45, 0.08, 210),
		CFrame.new(0, 0.25, -18),
		Color3.fromRGB(255, 196, 61),
		Enum.Material.Neon,
		world
	)
	createTrimPart(
		"EnergyBeacon",
		Vector3.new(2.2, 14, 2.2),
		CFrame.new(0, 7, -82),
		CYAN,
		Enum.Material.Neon,
		world
	)

	print("[PrototypeWorldService] Brontide city block generated")
end

return PrototypeWorldService
