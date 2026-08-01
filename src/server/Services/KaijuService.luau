--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

type ControlGrantedCallback = (player: Player) -> ()

local BODY_COLOR = Color3.fromRGB(31, 48, 55)
local ARMOR_COLOR = Color3.fromRGB(22, 33, 42)
local ENERGY_COLOR = Color3.fromRGB(53, 225, 211)
local EYE_COLOR = Color3.fromRGB(255, 190, 64)
local SPAWN_CLEARANCE_STUDS = 1

local function getBodyPart(character: Model, name: string): BasePart?
	local bodyPart = character:FindFirstChild(name)
	if bodyPart and bodyPart:IsA("BasePart") then
		return bodyPart
	end
	return nil
end

local function createShellPart(
	parent: Instance,
	target: BasePart,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = target.CFrame * offset
	part.Color = color
	part.Material = material
	part.Shape = shape
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	local weld = Instance.new("WeldConstraint")
	weld.Name = "ShellWeld"
	weld.Part0 = target
	weld.Part1 = part
	weld.Parent = part

	return part
end

local function attachShellPart(
	character: Model,
	parent: Instance,
	targetName: string,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType
)
	local target = getBodyPart(character, targetName)
	if target then
		createShellPart(parent, target, name, size, offset, color, material, shape)
	end
end

local function hideAvatarAppearance(character: Model)
	local shell = character:FindFirstChild("BrontideVisual")
	for _, descendant in character:GetDescendants() do
		if shell and descendant:IsDescendantOf(shell) then
			continue
		end
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CastShadow = false
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 1
		end
	end
end

local function createBrontideShell(character: Model)
	local previousShell = character:FindFirstChild("BrontideVisual")
	if previousShell then
		previousShell:Destroy()
	end

	hideAvatarAppearance(character)

	local shell = Instance.new("Model")
	shell.Name = "BrontideVisual"
	shell:SetAttribute("OriginalCharacter", "Brontide")
	shell.Parent = character

	attachShellPart(
		character,
		shell,
		"UpperTorso",
		"Chest",
		Vector3.new(10, 7.5, 6),
		CFrame.new(0, 0.3, 0),
		BODY_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Block
	)
	attachShellPart(
		character,
		shell,
		"LowerTorso",
		"Belly",
		Vector3.new(7.5, 4.5, 5.5),
		CFrame.new(0, 0, 0),
		ARMOR_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Block
	)
	attachShellPart(
		character,
		shell,
		"UpperTorso",
		"LeftShoulder",
		Vector3.new(5, 5, 5),
		CFrame.new(-5.2, 1.5, 0),
		BODY_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"UpperTorso",
		"RightShoulder",
		Vector3.new(5, 5, 5),
		CFrame.new(5.2, 1.5, 0),
		BODY_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)

	attachShellPart(
		character,
		shell,
		"Head",
		"Skull",
		Vector3.new(7, 5.8, 6.5),
		CFrame.new(0, 0.2, 0),
		BODY_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"Head",
		"Muzzle",
		Vector3.new(5.8, 2.8, 5),
		CFrame.new(0, -1.1, -4),
		ARMOR_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Block
	)
	attachShellPart(
		character,
		shell,
		"Head",
		"LeftEye",
		Vector3.new(0.8, 0.8, 0.8),
		CFrame.new(-1.65, 0.65, -3),
		EYE_COLOR,
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"Head",
		"RightEye",
		Vector3.new(0.8, 0.8, 0.8),
		CFrame.new(1.65, 0.65, -3),
		EYE_COLOR,
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"Head",
		"CrownLeft",
		Vector3.new(1.4, 4.5, 1.4),
		CFrame.new(-2, 3, 0.4) * CFrame.Angles(0, 0, math.rad(-24)),
		ENERGY_COLOR,
		Enum.Material.Neon,
		Enum.PartType.Block
	)
	attachShellPart(
		character,
		shell,
		"Head",
		"CrownCentre",
		Vector3.new(1.6, 5.5, 1.6),
		CFrame.new(0, 3.5, 0.8) * CFrame.Angles(math.rad(-10), 0, 0),
		ENERGY_COLOR,
		Enum.Material.Neon,
		Enum.PartType.Block
	)
	attachShellPart(
		character,
		shell,
		"Head",
		"CrownRight",
		Vector3.new(1.4, 4.5, 1.4),
		CFrame.new(2, 3, 0.4) * CFrame.Angles(0, 0, math.rad(24)),
		ENERGY_COLOR,
		Enum.Material.Neon,
		Enum.PartType.Block
	)

	attachShellPart(
		character,
		shell,
		"LeftUpperArm",
		"LeftUpperArmShell",
		Vector3.new(4.2, 7.5, 4.2),
		CFrame.identity,
		BODY_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"RightUpperArm",
		"RightUpperArmShell",
		Vector3.new(4.2, 7.5, 4.2),
		CFrame.identity,
		BODY_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"LeftLowerArm",
		"LeftForearmShell",
		Vector3.new(4.5, 7, 4.5),
		CFrame.new(0, -0.2, 0),
		ARMOR_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"RightLowerArm",
		"RightForearmShell",
		Vector3.new(4.5, 7, 4.5),
		CFrame.new(0, -0.2, 0),
		ARMOR_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"LeftHand",
		"LeftClaw",
		Vector3.new(5.5, 2.4, 6),
		CFrame.new(0, -0.5, -1.2),
		ARMOR_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"RightHand",
		"RightClaw",
		Vector3.new(5.5, 2.4, 6),
		CFrame.new(0, -0.5, -1.2),
		ARMOR_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)

	attachShellPart(
		character,
		shell,
		"LeftUpperLeg",
		"LeftThighShell",
		Vector3.new(5.2, 8, 5.2),
		CFrame.identity,
		BODY_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"RightUpperLeg",
		"RightThighShell",
		Vector3.new(5.2, 8, 5.2),
		CFrame.identity,
		BODY_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"LeftLowerLeg",
		"LeftShinShell",
		Vector3.new(4.7, 7.5, 4.7),
		CFrame.identity,
		ARMOR_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"RightLowerLeg",
		"RightShinShell",
		Vector3.new(4.7, 7.5, 4.7),
		CFrame.identity,
		ARMOR_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Ball
	)
	attachShellPart(
		character,
		shell,
		"LeftFoot",
		"LeftFootShell",
		Vector3.new(5.5, 2.5, 8),
		CFrame.new(0, -0.2, -1.5),
		ARMOR_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Block
	)
	attachShellPart(
		character,
		shell,
		"RightFoot",
		"RightFootShell",
		Vector3.new(5.5, 2.5, 8),
		CFrame.new(0, -0.2, -1.5),
		ARMOR_COLOR,
		Enum.Material.Slate,
		Enum.PartType.Block
	)

	for index = 1, 4 do
		local height = 5 - index * 0.55
		attachShellPart(
			character,
			shell,
			if index <= 2 then "UpperTorso" else "LowerTorso",
			`EnergySpine{index}`,
			Vector3.new(1.4, height, 1.4),
			CFrame.new(0, 3.2 - index * 2.25, 3.5) * CFrame.Angles(math.rad(38), 0, math.rad(45)),
			ENERGY_COLOR,
			Enum.Material.Neon,
			Enum.PartType.Block
		)
	end

	for index = 1, 5 do
		local width = 4.8 - index * 0.55
		attachShellPart(
			character,
			shell,
			"LowerTorso",
			`Tail{index}`,
			Vector3.new(width, width, 4.8),
			CFrame.new(0, -0.7 - index * 0.45, 3.5 + index * 3.35)
				* CFrame.Angles(math.rad(8 + index * 2), 0, 0),
			if index == 5 then ENERGY_COLOR else BODY_COLOR,
			if index == 5 then Enum.Material.Neon else Enum.Material.Slate,
			Enum.PartType.Ball
		)
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ReadabilityOutline"
	highlight.Adornee = shell
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(13, 26, 31)
	highlight.OutlineTransparency = 0.25
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = shell
end

local KaijuService = {}
KaijuService.__index = KaijuService

local function placeCharacterAtSpawn(character: Model, rootPart: BasePart): boolean
	local world = workspace:FindFirstChild(Config.Prototype.WorldName)
	local spawn = world and world:FindFirstChild("KaijuSpawn")
	if not spawn or not spawn:IsA("SpawnLocation") then
		warn("[KaijuService] Generated KaijuSpawn is unavailable")
		return false
	end

	local boundingCFrame, boundingSize = character:GetBoundingBox()
	local characterBottom = boundingCFrame.Position.Y - boundingSize.Y / 2
	local rootToBottom = math.max(rootPart.Position.Y - characterBottom, 0)
	local spawnTop = spawn.Position.Y + spawn.Size.Y / 2
	local rootPosition = Vector3.new(
		spawn.Position.X,
		spawnTop + rootToBottom + SPAWN_CLEARANCE_STUDS,
		spawn.Position.Z
	)
	local lookVector = spawn.CFrame.LookVector
	local horizontalLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if horizontalLook.Magnitude < 0.001 then
		horizontalLook = Vector3.new(0, 0, -1)
	else
		horizontalLook = horizontalLook.Unit
	end

	rootPart.CFrame = CFrame.lookAt(rootPosition, rootPosition + horizontalLook)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	return true
end

function KaijuService.new(onControlGranted: ControlGrantedCallback)
	local self = setmetatable({}, KaijuService)

	self._onControlGranted = onControlGranted
	self._connections = {} :: { RBXScriptConnection }
	self._loadingPlayers = {} :: { [Player]: boolean }
	self._stopped = false

	return self
end

function KaijuService:_configureCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if
		not humanoid
		or not humanoid:IsA("Humanoid")
		or not rootPart
		or not rootPart:IsA("BasePart")
	then
		warn(`[KaijuService] Character for {player.Name} is incomplete`)
		return
	end

	character:ScaleTo(Config.StarterKaiju.PrototypeScale)
	character:SetAttribute("KaijuId", Config.StarterKaiju.Id)
	createBrontideShell(character)
	if not placeCharacterAtSpawn(character, rootPart) then
		return
	end
	humanoid.MaxHealth = Config.StarterKaiju.MaxHealth
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = Config.StarterKaiju.WalkSpeed
	humanoid.CameraOffset = Vector3.new(0, 5, 0)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	player.CameraMinZoomDistance = Config.StarterKaiju.CameraMinZoom
	player.CameraMaxZoomDistance = Config.StarterKaiju.CameraMaxZoom

	table.insert(
		self._connections,
		humanoid.Died:Once(function()
			task.delay(Players.RespawnTime, function()
				if not self._stopped and player.Parent == Players then
					self:_loadCharacter(player)
				end
			end)
		end)
	)

	self._onControlGranted(player)
end

function KaijuService:_loadCharacter(player: Player)
	if self._stopped or player.Parent ~= Players or self._loadingPlayers[player] then
		return
	end

	self._loadingPlayers[player] = true
	local succeeded, message = pcall(function()
		player:LoadCharacterAsync()
	end)
	self._loadingPlayers[player] = nil

	if not succeeded and not self._stopped and player.Parent == Players then
		warn(`[KaijuService] Failed to load {player.Name}: {message}`)
	end
end

function KaijuService:_watchPlayer(player: Player)
	table.insert(
		self._connections,
		player.CharacterAppearanceLoaded:Connect(function(character)
			hideAvatarAppearance(character)
		end)
	)

	table.insert(
		self._connections,
		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				self:_configureCharacter(player, character)
			end)
		end)
	)

	if player.Character then
		task.defer(function()
			self:_configureCharacter(player, player.Character :: Model)
		end)
	else
		task.defer(function()
			self:_loadCharacter(player)
		end)
	end
end

function KaijuService:Start()
	self._stopped = false
	table.insert(
		self._connections,
		Players.PlayerAdded:Connect(function(player)
			self:_watchPlayer(player)
		end)
	)

	for _, player in Players:GetPlayers() do
		self:_watchPlayer(player)
	end
end

function KaijuService:Stop()
	self._stopped = true
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._loadingPlayers)
end

return KaijuService
