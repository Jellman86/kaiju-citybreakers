--!strict

local Workspace = game:GetService("Workspace")

local TerrainBuilder = {}

local PROFILE = "BrontideTerrainV1"

type BallDefinition = {
	center: Vector3,
	radius: number,
	material: Enum.Material,
}

local function fillBalls(terrain: Terrain, definitions: { BallDefinition }): number
	for _, definition in definitions do
		terrain:FillBall(definition.center, definition.radius, definition.material)
	end
	return #definitions
end

function TerrainBuilder.Build(world: Instance): Terrain
	local terrain = Workspace.Terrain
	terrain:Clear()
	terrain.WaterColor = Color3.fromRGB(34, 111, 151)
	terrain.WaterReflectance = 0.18
	terrain.WaterTransparency = 0.28
	terrain.WaterWaveSize = 0.18
	terrain.WaterWaveSpeed = 7
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(67, 104, 67))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(79, 84, 88))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(190, 171, 124))

	local operations = 0
	terrain:FillBlock(CFrame.new(0, -12, -100), Vector3.new(1520, 24, 1220), Enum.Material.Grass)
	operations += 1

	-- Low perimeter relief removes the infinite-flat-slab horizon without adding
	-- renderable Instances. These stay outside the main road grid.
	operations += fillBalls(terrain, {
		{ center = Vector3.new(-690, -24, 260), radius = 66, material = Enum.Material.Grass },
		{ center = Vector3.new(-650, -34, 390), radius = 72, material = Enum.Material.Grass },
		{ center = Vector3.new(-300, -30, 470), radius = 68, material = Enum.Material.Grass },
		{ center = Vector3.new(20, -36, 470), radius = 70, material = Enum.Material.Grass },
		{ center = Vector3.new(680, -28, 110), radius = 72, material = Enum.Material.Rock },
		{ center = Vector3.new(690, -34, -330), radius = 68, material = Enum.Material.Grass },
		{ center = Vector3.new(500, -36, -640), radius = 72, material = Enum.Material.Rock },
		{ center = Vector3.new(-70, -38, -650), radius = 68, material = Enum.Material.Grass },
	})

	-- Mount Brontide is a distant layered massif. The centres sit behind its
	-- approach road and buildings so traversal remains flat while the skyline gains depth.
	operations += fillBalls(terrain, {
		{ center = Vector3.new(560, 28, 410), radius = 132, material = Enum.Material.Rock },
		{ center = Vector3.new(650, 15, 330), radius = 112, material = Enum.Material.Rock },
		{ center = Vector3.new(500, -18, 500), radius = 96, material = Enum.Material.Grass },
		{ center = Vector3.new(675, -20, 455), radius = 88, material = Enum.Material.Grass },
	})

	-- Terrain mounds sit at the park edges, leaving the promenade and festival
	-- plaza clear for kaiju movement and future encounters.
	operations += fillBalls(terrain, {
		{ center = Vector3.new(-595, -27, 72), radius = 38, material = Enum.Material.Grass },
		{ center = Vector3.new(-565, -30, 224), radius = 40, material = Enum.Material.Grass },
		{ center = Vector3.new(-335, -28, 70), radius = 38, material = Enum.Material.Grass },
		{ center = Vector3.new(-325, -31, 220), radius = 41, material = Enum.Material.Grass },
		{ center = Vector3.new(-225, -23, 43), radius = 28, material = Enum.Material.Grass },
		{ center = Vector3.new(-210, -24, 91), radius = 27, material = Enum.Material.Grass },
	})

	-- A native water volume and overlapping sand banks replace the rectangular
	-- glass plate. Carve the grass base before filling water so the lake owns its
	-- voxel cells instead of competing with the base fill at the same surface.
	local lakeCFrame = CFrame.new(-465, -4, -400)
	local lakeSize = Vector3.new(320, 16, 272)
	terrain:FillBlock(lakeCFrame, lakeSize, Enum.Material.Air)
	terrain:FillBlock(lakeCFrame, Vector3.new(320, 8, 272), Enum.Material.Water)
	operations += 2
	operations += fillBalls(terrain, {
		{ center = Vector3.new(-625, -24, -400), radius = 42, material = Enum.Material.Sand },
		{ center = Vector3.new(-305, -24, -405), radius = 42, material = Enum.Material.Sand },
		{ center = Vector3.new(-560, -24, -535), radius = 38, material = Enum.Material.Sand },
		{ center = Vector3.new(-460, -25, -535), radius = 40, material = Enum.Material.Sand },
		{ center = Vector3.new(-360, -24, -530), radius = 38, material = Enum.Material.Sand },
		{ center = Vector3.new(-565, -25, -265), radius = 40, material = Enum.Material.Sand },
		{ center = Vector3.new(-455, -26, -266), radius = 42, material = Enum.Material.Sand },
		{ center = Vector3.new(-350, -25, -272), radius = 39, material = Enum.Material.Sand },
	})

	world:SetAttribute("TerrainProfile", PROFILE)
	world:SetAttribute("TerrainOperationCount", operations)
	world:SetAttribute("TerrainCellCount", terrain:CountCells())

	return terrain
end

return table.freeze(TerrainBuilder)
