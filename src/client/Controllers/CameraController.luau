--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerRole = require(ReplicatedStorage.Shared.PlayerRole)

local CameraController = {}
CameraController.__index = CameraController

local RENDER_STEP_NAME = "KaijuThirdPersonCamera"
local player = Players.LocalPlayer

local function isKaiju(): boolean
	return PlayerRole.IsKaiju(player)
end

local function getCameraMetrics()
	return if isKaiju() then Config.StarterKaiju else Config.Human
end

local function usesMouseCamera(): boolean
	return UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
end

local function getCharacterRoot(): (Model?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return character, nil
	end

	return character, rootPart
end

function CameraController.new()
	local self = setmetatable({}, CameraController)

	self._characterAddedConnection = nil :: RBXScriptConnection?
	self._inputChangedConnection = nil :: RBXScriptConnection?
	self._preferredInputConnection = nil :: RBXScriptConnection?
	self._roleConnection = nil :: RBXScriptConnection?
	self._mouseCameraEnabled = false
	self._yaw = 0
	self._pitch = 0
	self._distance = Config.StarterKaiju.CameraMaxZoom

	return self
end

function CameraController:_configureCharacter(character: Model)
	local metrics = getCameraMetrics()
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.CameraOffset = Vector3.new(0, metrics.CameraFocusHeight, 0)
	end

	local camera = Workspace.CurrentCamera
	if camera then
		camera.FieldOfView = metrics.CameraFieldOfView
	end
	player.CameraMinZoomDistance = metrics.CameraMinZoom
	player.CameraMaxZoomDistance = metrics.CameraMaxZoom
	self._distance = math.clamp(self._distance, metrics.CameraMinZoom, metrics.CameraMaxZoom)
end

function CameraController:_setMouseCaptured(isCaptured: boolean)
	UserInputService.MouseBehavior = if isCaptured
		then Enum.MouseBehavior.LockCenter
		else Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = not isCaptured
end

function CameraController:_enableMouseCamera()
	if self._mouseCameraEnabled or not isKaiju() then
		return
	end

	local camera = Workspace.CurrentCamera
	local _, rootPart = getCharacterRoot()
	if not camera or not rootPart then
		return
	end

	local cameraLook = camera.CFrame.LookVector
	self._yaw = math.atan2(-cameraLook.X, -cameraLook.Z)
	self._pitch = math.clamp(
		math.asin(math.clamp(cameraLook.Y, -1, 1)),
		math.rad(Config.StarterKaiju.CameraPitchMinDegrees),
		math.rad(Config.StarterKaiju.CameraPitchMaxDegrees)
	)

	local metrics = getCameraMetrics()
	local focusPosition = rootPart.Position + Vector3.new(0, metrics.CameraFocusHeight, 0)
	self._distance = math.clamp(
		(camera.CFrame.Position - focusPosition).Magnitude,
		metrics.CameraMinZoom,
		metrics.CameraMaxZoom
	)

	camera.CameraType = Enum.CameraType.Scriptable
	self._mouseCameraEnabled = true
	self:_setMouseCaptured(not GuiService.MenuIsOpen)
end

function CameraController:_disableMouseCamera()
	if not self._mouseCameraEnabled then
		return
	end

	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end

	self._mouseCameraEnabled = false
	self:_setMouseCaptured(false)
end

function CameraController:_updateInputMode()
	if isKaiju() and usesMouseCamera() then
		self:_enableMouseCamera()
	else
		self:_disableMouseCamera()
	end
end

function CameraController:_updateCamera()
	if not isKaiju() or not usesMouseCamera() then
		return
	end
	if not self._mouseCameraEnabled then
		self:_enableMouseCamera()
	end

	local character, rootPart = getCharacterRoot()
	local camera = Workspace.CurrentCamera
	if not self._mouseCameraEnabled or not character or not rootPart or not camera then
		return
	end

	local menuIsOpen = GuiService.MenuIsOpen
	self:_setMouseCaptured(not menuIsOpen)
	if not menuIsOpen then
		local mouseDelta = UserInputService:GetMouseDelta()
		self._yaw -= mouseDelta.X * Config.StarterKaiju.MouseCameraSensitivity
		self._pitch = math.clamp(
			self._pitch - mouseDelta.Y * Config.StarterKaiju.MouseCameraSensitivity,
			math.rad(Config.StarterKaiju.CameraPitchMinDegrees),
			math.rad(Config.StarterKaiju.CameraPitchMaxDegrees)
		)
	end

	local metrics = getCameraMetrics()
	local focusPosition = rootPart.Position + Vector3.new(0, metrics.CameraFocusHeight, 0)
	local cameraRotation = CFrame.fromOrientation(self._pitch, self._yaw, 0)
	local desiredPosition = focusPosition - cameraRotation.LookVector * self._distance

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	local collision =
		Workspace:Raycast(focusPosition, desiredPosition - focusPosition, raycastParams)
	local cameraPosition = if collision
		then collision.Position + collision.Normal * metrics.CameraCollisionPadding
		else desiredPosition

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(cameraPosition, focusPosition)
	camera.Focus = CFrame.new(focusPosition)
end

function CameraController:Start()
	local metrics = getCameraMetrics()
	player.CameraMinZoomDistance = metrics.CameraMinZoom
	player.CameraMaxZoomDistance = metrics.CameraMaxZoom

	self._characterAddedConnection = player.CharacterAdded:Connect(function(character)
		self:_configureCharacter(character)
		self._mouseCameraEnabled = false
		self:_updateInputMode()
	end)

	self._preferredInputConnection = UserInputService:GetPropertyChangedSignal("PreferredInput")
		:Connect(function()
			self:_updateInputMode()
		end)
	self._roleConnection = player:GetAttributeChangedSignal(PlayerRole.Attribute):Connect(function()
		self:_disableMouseCamera()
		if player.Character then
			self:_configureCharacter(player.Character)
		end
		self._distance = getCameraMetrics().CameraMaxZoom
		self:_updateInputMode()
	end)

	self._inputChangedConnection = UserInputService.InputChanged:Connect(
		function(input, gameProcessedEvent)
			if gameProcessedEvent or not self._mouseCameraEnabled then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				local currentMetrics = getCameraMetrics()
				self._distance = math.clamp(
					self._distance - input.Position.Z * currentMetrics.CameraZoomStep,
					currentMetrics.CameraMinZoom,
					currentMetrics.CameraMaxZoom
				)
			end
		end
	)

	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value, function()
		self:_updateCamera()
	end)

	if player.Character then
		self:_configureCharacter(player.Character)
	end
	self:_updateInputMode()
end

function CameraController:Destroy()
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
	if self._characterAddedConnection then
		self._characterAddedConnection:Disconnect()
		self._characterAddedConnection = nil
	end
	if self._preferredInputConnection then
		self._preferredInputConnection:Disconnect()
		self._preferredInputConnection = nil
	end
	if self._roleConnection then
		self._roleConnection:Disconnect()
		self._roleConnection = nil
	end
	if self._inputChangedConnection then
		self._inputChangedConnection:Disconnect()
		self._inputChangedConnection = nil
	end
	self:_disableMouseCamera()
end

return CameraController
