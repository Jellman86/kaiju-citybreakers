--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

type ControlGrantedCallback = (player: Player) -> ()

local KaijuService = {}
KaijuService.__index = KaijuService

function KaijuService.new(onControlGranted: ControlGrantedCallback)
	local self = setmetatable({}, KaijuService)

	self._onControlGranted = onControlGranted
	self._connections = {} :: { RBXScriptConnection }

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
	humanoid.MaxHealth = Config.StarterKaiju.MaxHealth
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = Config.StarterKaiju.WalkSpeed
	humanoid.CameraOffset = Vector3.new(0, 5, 0)
	player.CameraMinZoomDistance = Config.StarterKaiju.CameraMinZoom
	player.CameraMaxZoomDistance = Config.StarterKaiju.CameraMaxZoom

	self._onControlGranted(player)
end

function KaijuService:_watchPlayer(player: Player)
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
	end
end

function KaijuService:Start()
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
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

return KaijuService
