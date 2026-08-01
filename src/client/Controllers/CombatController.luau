--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)

type AbilityResult = Types.AbilityResult

local ACTION_BASIC_ATTACK = "KaijuBasicAttack"
local ACTION_CHARGE = "KaijuCharge"
local TOUCH_BUTTON_MIN_SIZE = 72
local TOUCH_BUTTON_MAX_SIZE = 96
local TOUCH_BUTTON_FRAME_HEIGHT_RATIO = 0.25
local TOUCH_BUTTON_GAP_RATIO = 0.16
local player = Players.LocalPlayer

local CombatController = {}
CombatController.__index = CombatController

function CombatController.new(abilityRequestRemote: RemoteEvent, abilityResultRemote: RemoteEvent)
	local self = setmetatable({}, CombatController)

	self._abilityRequestRemote = abilityRequestRemote
	self._abilityResultRemote = abilityResultRemote
	self._sequence = 0
	self._lastRequestedAt = -math.huge
	self._lastChargeRequestedAt = -math.huge
	self._playerGuiDescendantAddedConnection = nil :: RBXScriptConnection?
	self._resultConnection = nil :: RBXScriptConnection?
	self._touchLayoutConnection = nil :: RBXScriptConnection?

	return self
end

function CombatController:_requestBasicAttack()
	local now = os.clock()
	if now - self._lastRequestedAt < Config.Combat.BasicAttackCooldownSeconds then
		return
	end

	self._lastRequestedAt = now
	self._sequence += 1
	self._abilityRequestRemote:FireServer({
		abilityId = "basic",
		sequence = self._sequence,
	})
end

function CombatController:_requestCharge()
	local now = os.clock()
	if now - self._lastChargeRequestedAt < Config.Combat.ChargeCooldownSeconds then
		return
	end

	self._lastChargeRequestedAt = now
	self._sequence += 1
	self._abilityRequestRemote:FireServer({
		abilityId = "charge",
		sequence = self._sequence,
	})
end

function CombatController:_pulseCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local outward = TweenService:Create(camera, TweenInfo.new(0.08), {
		FieldOfView = Config.StarterKaiju.CameraFieldOfView + 3,
	})
	local inward = TweenService:Create(camera, TweenInfo.new(0.18), {
		FieldOfView = Config.StarterKaiju.CameraFieldOfView,
	})
	outward:Play()
	outward.Completed:Once(function()
		inward:Play()
	end)
end

local function styleTouchButton(button: ImageButton, color: Color3, buttonSize: number)
	button.AnchorPoint = Vector2.zero
	button.Size = UDim2.fromOffset(buttonSize, buttonSize)
	button.ImageColor3 = color

	local stroke = button:FindFirstChild("KaijuButtonStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "KaijuButtonStroke"
		stroke.Color = Color3.fromRGB(235, 248, 245)
		stroke.Thickness = 3
		stroke.Transparency = 0.2
		stroke.Parent = button
	end

	local corner = button:FindFirstChild("KaijuButtonCorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Name = "KaijuButtonCorner"
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = button
	end
end

local function overlapsGuiObject(
	localPosition: Vector2,
	buttonSize: number,
	buttonFrame: GuiObject,
	other: GuiObject
): boolean
	if not other.Visible or other.AbsoluteSize.X <= 0 or other.AbsoluteSize.Y <= 0 then
		return false
	end

	local buttonTopLeft = buttonFrame.AbsolutePosition + localPosition
	local buttonBottomRight = buttonTopLeft + Vector2.new(buttonSize, buttonSize)
	local otherTopLeft = other.AbsolutePosition
	local otherBottomRight = otherTopLeft + other.AbsoluteSize

	return buttonTopLeft.X < otherBottomRight.X
		and buttonBottomRight.X > otherTopLeft.X
		and buttonTopLeft.Y < otherBottomRight.Y
		and buttonBottomRight.Y > otherTopLeft.Y
end

function CombatController:_layoutTouchButtons()
	local smashButton = ContextActionService:GetButton(ACTION_BASIC_ATTACK)
	local chargeButton = ContextActionService:GetButton(ACTION_CHARGE)
	if
		not smashButton
		or not smashButton:IsA("ImageButton")
		or not chargeButton
		or not chargeButton:IsA("ImageButton")
	then
		return
	end

	local buttonFrame = smashButton.Parent
	if not buttonFrame or not buttonFrame:IsA("GuiObject") then
		return
	end

	local frameSize = buttonFrame.AbsoluteSize
	local buttonSize = math.clamp(
		math.round(frameSize.Y * TOUCH_BUTTON_FRAME_HEIGHT_RATIO),
		TOUCH_BUTTON_MIN_SIZE,
		TOUCH_BUTTON_MAX_SIZE
	)
	local gap = math.max(12, math.round(buttonSize * TOUCH_BUTTON_GAP_RATIO))
	local margin = gap
	local rightColumnX = math.max(margin, math.round(frameSize.X - margin - buttonSize))
	local bottomRowY = math.max(margin, math.round(frameSize.Y - margin - buttonSize))
	local requiredSideBySideWidth = buttonSize * 2 + gap + margin * 2

	local smashPosition = Vector2.new(rightColumnX, bottomRowY)
	local chargePosition: Vector2
	if frameSize.X >= requiredSideBySideWidth then
		chargePosition = Vector2.new(rightColumnX - buttonSize - gap, bottomRowY)
	else
		chargePosition = Vector2.new(rightColumnX, math.max(margin, bottomRowY - buttonSize - gap))
	end

	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local jumpButton = playerGui and playerGui:FindFirstChild("JumpButton", true)
	if
		jumpButton
		and jumpButton:IsA("GuiObject")
		and (
			overlapsGuiObject(smashPosition, buttonSize, buttonFrame, jumpButton)
			or overlapsGuiObject(chargePosition, buttonSize, buttonFrame, jumpButton)
		)
	then
		local jumpLeftInFrame = jumpButton.AbsolutePosition.X - buttonFrame.AbsolutePosition.X
		local screenLeftInFrame = -buttonFrame.AbsolutePosition.X
		local obstacleColumnX =
			math.max(screenLeftInFrame + margin, math.round(jumpLeftInFrame - gap - buttonSize))
		smashPosition = Vector2.new(obstacleColumnX, bottomRowY)
		chargePosition =
			Vector2.new(obstacleColumnX, math.max(margin, bottomRowY - buttonSize - gap))
	end

	ContextActionService:SetPosition(
		ACTION_BASIC_ATTACK,
		UDim2.fromOffset(smashPosition.X, smashPosition.Y)
	)
	ContextActionService:SetPosition(
		ACTION_CHARGE,
		UDim2.fromOffset(chargePosition.X, chargePosition.Y)
	)
	styleTouchButton(smashButton, Color3.fromRGB(230, 105, 59), buttonSize)
	styleTouchButton(chargeButton, Color3.fromRGB(35, 190, 178), buttonSize)
end

function CombatController:Start()
	local playerGui = player:WaitForChild("PlayerGui")
	self._playerGuiDescendantAddedConnection = playerGui.DescendantAdded:Connect(function(instance)
		if instance.Name == "JumpButton" then
			task.defer(function()
				self:_layoutTouchButtons()
			end)
		end
	end)

	ContextActionService:BindAction(ACTION_BASIC_ATTACK, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:_requestBasicAttack()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.E, Enum.KeyCode.ButtonR2)
	ContextActionService:SetTitle(ACTION_BASIC_ATTACK, "SMASH")
	ContextActionService:SetDescription(
		ACTION_BASIC_ATTACK,
		"Smash structures in front of Brontide"
	)
	ContextActionService:BindAction(ACTION_CHARGE, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:_requestCharge()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Q, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL2, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle(ACTION_CHARGE, "CHARGE")
	ContextActionService:SetDescription(
		ACTION_CHARGE,
		"Charge quickly in the direction Brontide faces"
	)
	task.defer(function()
		self:_layoutTouchButtons()
		local button = ContextActionService:GetButton(ACTION_BASIC_ATTACK)
		local buttonFrame = button and button.Parent
		if buttonFrame and buttonFrame:IsA("GuiObject") then
			self._touchLayoutConnection = buttonFrame
				:GetPropertyChangedSignal("AbsoluteSize")
				:Connect(function()
					self:_layoutTouchButtons()
				end)
		end
	end)

	self._resultConnection = self._abilityResultRemote.OnClientEvent:Connect(
		function(result: AbilityResult)
			if result.accepted and (result.hitCount > 0 or result.abilityId == "charge") then
				self:_pulseCamera()
			end
		end
	)
end

function CombatController:Destroy()
	ContextActionService:UnbindAction(ACTION_BASIC_ATTACK)
	ContextActionService:UnbindAction(ACTION_CHARGE)
	if self._resultConnection then
		self._resultConnection:Disconnect()
		self._resultConnection = nil
	end
	if self._playerGuiDescendantAddedConnection then
		self._playerGuiDescendantAddedConnection:Disconnect()
		self._playerGuiDescendantAddedConnection = nil
	end
	if self._touchLayoutConnection then
		self._touchLayoutConnection:Disconnect()
		self._touchLayoutConnection = nil
	end
end

return CombatController
