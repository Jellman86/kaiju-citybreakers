--!strict

local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
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
	self._chargeCooldownVisualToken = 0
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
	self:_startChargeCooldownVisual()
end

function CombatController:_resetChargeCooldownVisual()
	self._chargeCooldownVisualToken += 1
	ContextActionService:SetTitle(ACTION_CHARGE, "CHARGE")
	local button = ContextActionService:GetButton(ACTION_CHARGE)
	if button and button:IsA("ImageButton") then
		button.ImageTransparency = 0
	end
end

function CombatController:_startChargeCooldownVisual()
	self._chargeCooldownVisualToken += 1
	local visualToken = self._chargeCooldownVisualToken

	task.spawn(function()
		while visualToken == self._chargeCooldownVisualToken do
			local remaining = Config.Combat.ChargeCooldownSeconds
				- (os.clock() - self._lastChargeRequestedAt)
			if remaining <= 0 then
				break
			end

			ContextActionService:SetTitle(ACTION_CHARGE, string.format("%.1f", remaining))
			local button = ContextActionService:GetButton(ACTION_CHARGE)
			if button and button:IsA("ImageButton") then
				button.ImageTransparency = 0.42
			end
			task.wait(0.1)
		end

		if visualToken == self._chargeCooldownVisualToken then
			self:_resetChargeCooldownVisual()
		end
	end)
end

function CombatController:_pulseCamera(
	fieldOfViewKick: number,
	kickSeconds: number,
	settleSeconds: number
)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local outward = TweenService:Create(camera, TweenInfo.new(kickSeconds, Enum.EasingStyle.Quad), {
		FieldOfView = Config.StarterKaiju.CameraFieldOfView + fieldOfViewKick,
	})
	local inward = TweenService:Create(
		camera,
		TweenInfo.new(settleSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			FieldOfView = Config.StarterKaiju.CameraFieldOfView,
		}
	)
	outward:Play()
	outward.Completed:Once(function()
		inward:Play()
	end)
end

function CombatController:_emitChargeFeedback()
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not rootPart or not rootPart:IsA("BasePart") then
		return
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ChargeEnergyBurst"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(224, 255, 251)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(53, 225, 211)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(31, 126, 155)),
	})
	emitter.LightEmission = 0.9
	emitter.Lifetime = NumberRange.new(0.28, 0.48)
	emitter.Speed = NumberRange.new(16, 28)
	emitter.Drag = 4
	emitter.SpreadAngle = Vector2.new(28, 28)
	emitter.EmissionDirection = Enum.NormalId.Back
	emitter.Rate = 0
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.8),
		NumberSequenceKeypoint.new(0.45, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(0.7, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Parent = rootPart
	emitter:Emit(28)
	Debris:AddItem(emitter, 1)

	local highlight = Instance.new("Highlight")
	highlight.Name = "ChargeEnergyHighlight"
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = Color3.fromRGB(53, 225, 211)
	highlight.FillTransparency = 0.72
	highlight.OutlineColor = Color3.fromRGB(224, 255, 251)
	highlight.OutlineTransparency = 0.08
	highlight.Parent = character

	TweenService:Create(
		highlight,
		TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FillTransparency = 1, OutlineTransparency = 1 }
	):Play()
	Debris:AddItem(highlight, 0.45)
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
	smashButton.Name = "SmashTouchButton"
	chargeButton.Name = "ChargeTouchButton"

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
			if not result.accepted then
				if result.abilityId == "charge" then
					self:_resetChargeCooldownVisual()
				end
				return
			end
			if result.abilityId == "charge" then
				self:_pulseCamera(8, 0.06, 0.28)
				self:_emitChargeFeedback()
			elseif result.hitCount > 0 then
				self:_pulseCamera(3, 0.08, 0.18)
			end
		end
	)
end

function CombatController:Destroy()
	self:_resetChargeCooldownVisual()
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
