--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PrototypeWorldService = {}
PrototypeWorldService.__index = PrototypeWorldService

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
	label.Text = "CHARGE FORWARD • SMASH TWICE\nQ / SHIFT / B  •  CLICK / E / R2"
	label.TextColor3 = Color3.fromRGB(255, 224, 92)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
end

local function createWall(parent: Instance): Model
	local wall = Instance.new("Model")
	wall.Name = "BreakableWall"
	wall:SetAttribute("StructureId", Config.Prototype.WallStructureId)
	wall:SetAttribute("MaxHealth", Config.Prototype.WallMaxHealth)
	wall:SetAttribute("CurrentHealth", Config.Prototype.WallMaxHealth)
	wall:SetAttribute("DestructionState", "Intact")
	wall.Parent = parent

	local wallCFrame = CFrame.new(0, 11, -28)

	local intact = Instance.new("Model")
	intact.Name = "Intact"
	intact.Parent = wall
	local intactPart = createPart(
		"Wall",
		Vector3.new(30, 22, 7),
		wallCFrame,
		Color3.fromRGB(54, 86, 112),
		Enum.Material.Concrete,
		intact
	)
	createLabel(intactPart)

	local damaged = Instance.new("Model")
	damaged.Name = "Damaged"
	damaged.Parent = wall
	local damagedPart = createPart(
		"Wall",
		Vector3.new(30, 22, 7),
		wallCFrame * CFrame.Angles(0, 0, math.rad(-2)),
		Color3.fromRGB(93, 73, 69),
		Enum.Material.Concrete,
		damaged
	)

	for index = -1, 1 do
		local crack = createPart(
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
	collapsed.Parent = wall
	for index = 1, 7 do
		local column = ((index - 1) % 4) - 1.5
		local row = math.floor((index - 1) / 4)
		createPart(
			`Rubble{index}`,
			Vector3.new(6.5, 3 + (index % 2), 6),
			CFrame.new(column * 6.5, 1.5 + row, -28 + row * 4)
				* CFrame.Angles(0, math.rad(index * 19), math.rad(index * 7)),
			Color3.fromRGB(70, 78, 83),
			Enum.Material.Concrete,
			collapsed
		)
	end

	CollectionService:AddTag(wall, "Destructible")
	return wall
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

	local world = Instance.new("Folder")
	world.Name = Config.Prototype.WorldName
	world.Parent = workspace

	createPart(
		"ArenaFloor",
		Vector3.new(180, 2, 180),
		CFrame.new(0, -1, 0),
		Color3.fromRGB(40, 47, 54),
		Enum.Material.Asphalt,
		world
	)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "KaijuSpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 1, 38), Vector3.new(0, 1, -28))
	spawn.Color = Color3.fromRGB(67, 214, 154)
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Enabled = true
	spawn.Duration = 0
	spawn.Anchored = true
	spawn.Parent = world

	createWall(world)

	for side = -1, 1, 2 do
		for row = 0, 2 do
			createPart(
				`ScaleBuilding_{side}_{row}`,
				Vector3.new(18, 14 + row * 8, 18),
				CFrame.new(side * 42, 7 + row * 4, 15 - row * 28),
				Color3.fromRGB(39 + row * 12, 60 + row * 10, 76 + row * 12),
				Enum.Material.Concrete,
				world
			)
		end
	end

	print("[PrototypeWorldService] Kaiju Feel Lab generated")
end

return PrototypeWorldService
