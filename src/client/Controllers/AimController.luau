--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerRole = require(ReplicatedStorage.Shared.PlayerRole)

local AimController = {}
AimController.__index = AimController

local RENDER_STEP_NAME = "KaijuCameraFacing"
local AIM_RESPONSE_SECONDS = 0.18
local MAX_HEAD_YAW = math.rad(38)
local MAX_HEAD_PITCH = math.rad(24)
local player = Players.LocalPlayer

type AimJoint = Motor6D | AnimationConstraint

local function usesCameraFacing(): boolean
	return PlayerRole.IsKaiju(player)
		and UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
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

local function getAimJoint(character: Model): AimJoint?
	local aimMotor = character:FindFirstChild("HeadAimMotor", true)
	if aimMotor and aimMotor:IsA("Motor6D") then
		return aimMotor
	end

	local neck = character:FindFirstChild("Neck", true)
	if neck and neck:IsA("Motor6D") then
		return neck
	end
	if neck and neck:IsA("AnimationConstraint") then
		return neck
	end
	return nil
end

local function setAimJointPose(aimJoint: AimJoint, pose: CFrame)
	if aimJoint:IsA("Motor6D") and aimJoint.Name == "HeadAimMotor" then
		-- HeadAimMotor is a dedicated visual pivot, not an animator-owned body joint.
		-- C0 persists through the engine's animation pass, whereas Transform is
		-- cleared before display on the current avatar rig.
		aimJoint.C0 = pose
		return
	end

	aimJoint.Transform = pose
end

local function getConstrainedAim(
	rootPart: BasePart,
	aimDirection: Vector3
): (Vector3, number, number)
	local localDirection = rootPart.CFrame:VectorToObjectSpace(aimDirection)
	local yaw =
		math.clamp(-math.atan2(localDirection.X, -localDirection.Z), -MAX_HEAD_YAW, MAX_HEAD_YAW)
	local pitch =
		math.clamp(math.asin(math.clamp(localDirection.Y, -1, 1)), -MAX_HEAD_PITCH, MAX_HEAD_PITCH)
	local constrainedLocalDirection = CFrame.Angles(pitch, yaw, 0).LookVector
	local constrainedWorldDirection =
		rootPart.CFrame:VectorToWorldSpace(constrainedLocalDirection).Unit
	return constrainedWorldDirection, pitch, yaw
end

function AimController.new()
	local self = setmetatable({}, AimController)

	self._characterAddedConnection = nil :: RBXScriptConnection?
	self._preferredInputConnection = nil :: RBXScriptConnection?
	self._roleConnection = nil :: RBXScriptConnection?
	self._smoothedAimDirection = nil :: Vector3?

	return self
end

function AimController:_configureCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.AutoRotate = not usesCameraFacing()
	end
	self._smoothedAimDirection = nil
end

function AimController:_getDesiredAimDirection(rootPart: BasePart, camera: Camera): Vector3
	local viewportPoint = camera.ViewportSize * 0.5
	if UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then
		viewportPoint = UserInputService:GetMouseLocation()
	end

	local aimRay = camera:ViewportPointToRay(viewportPoint.X, viewportPoint.Y)
	if aimRay.Direction.Magnitude > 0.001 then
		return aimRay.Direction.Unit
	end
	return rootPart.CFrame.LookVector
end

function AimController:_turnHead(character: Model, rootPart: BasePart, aimDirection: Vector3)
	local aimJoint = getAimJoint(character)
	if not aimJoint then
		return
	end

	local _, pitch, yaw = getConstrainedAim(rootPart, aimDirection)
	setAimJointPose(aimJoint, CFrame.Angles(pitch, yaw, 0))
end

function AimController:_updateFacing(deltaTime: number)
	local humanoid, rootPart = getCharacterParts()
	local camera = Workspace.CurrentCamera
	if not humanoid or not rootPart or not camera or humanoid.Health <= 0 then
		return
	end
	if not PlayerRole.IsKaiju(player) then
		if not humanoid.AutoRotate then
			humanoid.AutoRotate = true
		end
		return
	end

	if usesCameraFacing() then
		if humanoid.AutoRotate then
			humanoid.AutoRotate = false
		end

		local cameraForward = camera.CFrame.LookVector
		local flatForward = Vector3.new(cameraForward.X, 0, cameraForward.Z)
		if flatForward.Magnitude > 0.001 then
			rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + flatForward.Unit)
		end
	end

	local desiredDirection = self:_getDesiredAimDirection(rootPart, camera)
	local currentDirection = self._smoothedAimDirection or desiredDirection
	local alpha = 1 - math.exp(-deltaTime / AIM_RESPONSE_SECONDS)
	local blendedDirection = currentDirection:Lerp(desiredDirection, alpha)
	local smoothedDirection = if blendedDirection.Magnitude > 0.001
		then blendedDirection.Unit
		else desiredDirection
	self._smoothedAimDirection = getConstrainedAim(rootPart, smoothedDirection)

	local character = player.Character
	if character then
		self:_turnHead(character, rootPart, self._smoothedAimDirection)
	end
end

function AimController:GetAimDirection(): Vector3
	if self._smoothedAimDirection then
		return self._smoothedAimDirection
	end

	local _, rootPart = getCharacterParts()
	return if rootPart then rootPart.CFrame.LookVector else -Vector3.zAxis
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
	self._roleConnection = player:GetAttributeChangedSignal(PlayerRole.Attribute):Connect(function()
		if player.Character then
			self:_configureCharacter(player.Character)
		end
	end)

	RunService:BindToRenderStep(
		RENDER_STEP_NAME,
		Enum.RenderPriority.Camera.Value + 1,
		function(deltaTime)
			self:_updateFacing(deltaTime)
		end
	)
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
	if self._roleConnection then
		self._roleConnection:Disconnect()
		self._roleConnection = nil
	end

	local humanoid = getCharacterParts()
	if humanoid then
		humanoid.AutoRotate = true
	end
	local character = player.Character
	local aimJoint = if character then getAimJoint(character) else nil
	if aimJoint then
		setAimJointPose(aimJoint, CFrame.identity)
	end
end

return AimController
