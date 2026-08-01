--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CameraController = {}
CameraController.__index = CameraController

function CameraController.new()
	local self = setmetatable({}, CameraController)

	self._connection = nil :: RBXScriptConnection?

	return self
end

function CameraController:_configureCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.CameraOffset = Vector3.new(0, 5, 0)
	end

	local camera = workspace.CurrentCamera
	if camera then
		camera.FieldOfView = Config.StarterKaiju.CameraFieldOfView
	end
end

function CameraController:Start()
	local player = Players.LocalPlayer
	player.CameraMinZoomDistance = Config.StarterKaiju.CameraMinZoom
	player.CameraMaxZoomDistance = Config.StarterKaiju.CameraMaxZoom

	self._connection = player.CharacterAdded:Connect(function(character)
		self:_configureCharacter(character)
	end)

	if player.Character then
		self:_configureCharacter(player.Character)
	end
end

function CameraController:Destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

return CameraController
