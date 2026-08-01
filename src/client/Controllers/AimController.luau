--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local AimController = {}
AimController.__index = AimController

local player = Players.LocalPlayer

local function usesMouseAim(): boolean
	return UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
end

local function getCharacterParts(): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or not rootPart:IsA("BasePart") then
		return character, humanoid, nil
	end

	return character, humanoid, rootPart
end

local function getFallbackDirection(rootPart: BasePart, camera: Camera): Vector3
	local cameraForward = camera.CFrame.LookVector
	local flatCameraForward = Vector3.new(cameraForward.X, 0, cameraForward.Z)
	if flatCameraForward.Magnitude >= Config.StarterKaiju.AimMinimumDistance then
		return flatCameraForward.Unit
	end

	local rootForward = rootPart.CFrame.LookVector
	return Vector3.new(rootForward.X, 0, rootForward.Z).Unit
end

local function getAimDirection(character: Model, rootPart: BasePart, camera: Camera): Vector3
	local mousePosition = UserInputService:GetMouseLocation()
	local mouseRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local rayDirection = mouseRay.Direction * Config.StarterKaiju.AimRayDistance

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	local result = Workspace:Raycast(mouseRay.Origin, rayDirection, raycastParams)
	local aimPoint: Vector3? = if result then result.Position else nil

	if not aimPoint and math.abs(mouseRay.Direction.Y) > 0.001 then
		local distanceToPlane = (rootPart.Position.Y - mouseRay.Origin.Y) / mouseRay.Direction.Y
		if distanceToPlane > 0 and distanceToPlane <= Config.StarterKaiju.AimRayDistance then
			aimPoint = mouseRay.Origin + mouseRay.Direction * distanceToPlane
		end
	end

	if aimPoint then
		local flatOffset =
			Vector3.new(aimPoint.X - rootPart.Position.X, 0, aimPoint.Z - rootPart.Position.Z)
		if flatOffset.Magnitude >= Config.StarterKaiju.AimMinimumDistance then
			return flatOffset.Unit
		end
	end

	return getFallbackDirection(rootPart, camera)
end

function AimController.new()
	local self = setmetatable({}, AimController)

	self._characterAddedConnection = nil :: RBXScriptConnection?
	self._preferredInputConnection = nil :: RBXScriptConnection?
	self._renderConnection = nil :: RBXScriptConnection?

	return self
end

function AimController:_configureCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.AutoRotate = not usesMouseAim()
	end
end

function AimController:Start()
	if player.Character then
		self:_configureCharacter(player.Character)
	end

	self._characterAddedConnection = player.CharacterAdded:Connect(function(character)
		self:_configureCharacter(character)
	end)

	self._preferredInputConnection = UserInputService:GetPropertyChangedSignal("PreferredInput")
		:Connect(function()
			if player.Character then
				self:_configureCharacter(player.Character)
			end
		end)

	self._renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if not usesMouseAim() then
			return
		end

		local character, humanoid, rootPart = getCharacterParts()
		local camera = Workspace.CurrentCamera
		if not character or not humanoid or not rootPart or not camera or humanoid.Health <= 0 then
			return
		end

		if humanoid.AutoRotate then
			humanoid.AutoRotate = false
		end

		local aimDirection = getAimDirection(character, rootPart, camera)
		local targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + aimDirection)
		local turnAlpha = 1 - math.exp(-Config.StarterKaiju.AimTurnResponsiveness * deltaTime)
		rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, turnAlpha)
	end)
end

function AimController:Destroy()
	if self._characterAddedConnection then
		self._characterAddedConnection:Disconnect()
		self._characterAddedConnection = nil
	end
	if self._preferredInputConnection then
		self._preferredInputConnection:Disconnect()
		self._preferredInputConnection = nil
	end
	if self._renderConnection then
		self._renderConnection:Disconnect()
		self._renderConnection = nil
	end

	local _, humanoid = getCharacterParts()
	if humanoid then
		humanoid.AutoRotate = true
	end
end

return AimController
