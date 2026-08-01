--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local AimController = {}
AimController.__index = AimController

local RENDER_STEP_NAME = "KaijuCameraFacing"
local player = Players.LocalPlayer

local function usesCameraFacing(): boolean
	return UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
end

local function getCharacterParts(): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or not rootPart:IsA("BasePart") then
		return humanoid, nil
	end

	return humanoid, rootPart
end

function AimController.new()
	local self = setmetatable({}, AimController)

	self._characterAddedConnection = nil :: RBXScriptConnection?
	self._preferredInputConnection = nil :: RBXScriptConnection?

	return self
end

function AimController:_configureCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.AutoRotate = not usesCameraFacing()
	end
end

function AimController:_updateFacing()
	if not usesCameraFacing() then
		return
	end

	local humanoid, rootPart = getCharacterParts()
	local camera = Workspace.CurrentCamera
	if not humanoid or not rootPart or not camera or humanoid.Health <= 0 then
		return
	end

	if humanoid.AutoRotate then
		humanoid.AutoRotate = false
	end

	local cameraForward = camera.CFrame.LookVector
	local flatForward = Vector3.new(cameraForward.X, 0, cameraForward.Z)
	if flatForward.Magnitude < 0.001 then
		return
	end

	rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + flatForward.Unit)
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

	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, function()
		self:_updateFacing()
	end)
end

function AimController:Destroy()
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
	if self._characterAddedConnection then
		self._characterAddedConnection:Disconnect()
		self._characterAddedConnection = nil
	end
	if self._preferredInputConnection then
		self._preferredInputConnection:Disconnect()
		self._preferredInputConnection = nil
	end

	local humanoid = getCharacterParts()
	if humanoid then
		humanoid.AutoRotate = true
	end
end

return AimController
