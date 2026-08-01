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
local ACTION_BEAM = "KaijuEnergyBeam"
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
	self._beamCooldownVisualToken = 0
	self._sequence = 0
	self._lastRequestedAt = -math.huge
	self._lastChargeRequestedAt = -math.huge
	self._lastBeamRequestedAt = -math.huge
	self._jumpLayoutConnections = {} :: { RBXScriptConnection }
	self._playerGuiDescendantAddedConnection = nil :: RBXScriptConnection?
	self._resultConnection = nil :: RBXScriptConnection?
	self._touchLayoutConnection = nil :: RBXScriptConnection?
	self._touchLayoutPositionConnection = nil :: RBXScriptConnection?

	return self
end

function CombatController:_requestBeam()
	local now = os.clock()
	if now - self._lastBeamRequestedAt < Config.Combat.BeamCooldownSeconds then
		return
	end

	self._lastBeamRequestedAt = now
	self._sequence += 1
	self._abilityRequestRemote:FireServer({
		abilityId = "beam",
		sequence = self._sequence,
	})
	self:_startBeamCooldownVisual()
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

function CombatController:_resetBeamCooldownVisual()
	self._beamCooldownVisualToken += 1
	ContextActionService:SetTitle(ACTION_BEAM, "BEAM")
	local button = ContextActionService:GetButton(ACTION_BEAM)
	if button and button:IsA("ImageButton") then
		button.ImageTransparency = 0
	end
end

function CombatController:_startBeamCooldownVisual()
	self._beamCooldownVisualToken += 1
	local visualToken = self._beamCooldownVisualToken

	task.spawn(function()
		while visualToken == self._beamCooldownVisualToken do
			local remaining = Config.Combat.BeamCooldownSeconds
				- (os.clock() - self._lastBeamRequestedAt)
			if remaining <= 0 then
				break
			end

			ContextActionService:SetTitle(ACTION_BEAM, string.format("%.1f", remaining))
			local button = ContextActionService:GetButton(ACTION_BEAM)
			if button and button:IsA("ImageButton") then
				button.ImageTransparency = 0.42
			end
			task.wait(0.1)
		end

		if visualToken == self._beamCooldownVisualToken then
			self:_resetBeamCooldownVisual()
		end
	end)
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

function CombatController:_emitImpactFeedback(position: Vector3, color: Color3, size: number)
	local flash = Instance.new("Part")
	flash.Name = "KaijuImpactFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(size, size, size)
	flash.CFrame = CFrame.new(position)
	flash.Color = color
	flash.Material = Enum.Material.Neon
	flash.Transparency = 0.08
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanTouch = false
	flash.CanQuery = false
	flash.CastShadow = false
	flash.Parent = workspace

	TweenService:Create(
		flash,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(size * 2.8, size * 2.8, size * 2.8), Transparency = 1 }
	):Play()
	Debris:AddItem(flash, 0.25)
end

function CombatController:_emitBeam(origin: Vector3, target: Vector3, hit: boolean)
	local delta = target - origin
	local length = delta.Magnitude
	if length < 0.1 then
		return
	end

	local midpoint = origin + delta * 0.5
	local beamCFrame = CFrame.lookAt(midpoint, target)
	for index, definition in
		{
			{ thickness = 3.8, color = Color3.fromRGB(19, 168, 219), transparency = 0.12 },
			{ thickness = 1.7, color = Color3.fromRGB(224, 255, 251), transparency = 0 },
		}
	do
		local segment = Instance.new("Part")
		segment.Name = `BrontideBeam{index}`
		segment.Size = Vector3.new(definition.thickness, definition.thickness, length)
		segment.CFrame = beamCFrame
		segment.Color = definition.color
		segment.Material = Enum.Material.Neon
		segment.Transparency = definition.transparency
		segment.Anchored = true
		segment.CanCollide = false
		segment.CanTouch = false
		segment.CanQuery = false
		segment.CastShadow = false
		segment.Parent = workspace
		TweenService:Create(
			segment,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.15, 0.15, length), Transparency = 1 }
		):Play()
		Debris:AddItem(segment, 0.25)
	end

	self:_emitImpactFeedback(
		target,
		if hit then Color3.fromRGB(255, 174, 74) else Color3.fromRGB(53, 225, 211),
		if hit then 4.5 else 2.5
	)
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
	other: GuiObject,
	clearance: number
): boolean
	if not other.Visible or other.AbsoluteSize.X <= 0 or other.AbsoluteSize.Y <= 0 then
		return false
	end

	local buttonTopLeft = buttonFrame.AbsolutePosition + localPosition
	local buttonBottomRight = buttonTopLeft + Vector2.new(buttonSize, buttonSize)
	local clearanceVector = Vector2.new(clearance, clearance)
	local otherTopLeft = other.AbsolutePosition - clearanceVector
	local otherBottomRight = other.AbsolutePosition + other.AbsoluteSize + clearanceVector

	return buttonTopLeft.X < otherBottomRight.X
		and buttonBottomRight.X > otherTopLeft.X
		and buttonTopLeft.Y < otherBottomRight.Y
		and buttonBottomRight.Y > otherTopLeft.Y
end

function CombatController:_layoutTouchButtons()
	local smashButton = ContextActionService:GetButton(ACTION_BASIC_ATTACK)
	local chargeButton = ContextActionService:GetButton(ACTION_CHARGE)
	local beamButton = ContextActionService:GetButton(ACTION_BEAM)
	if
		not smashButton
		or not smashButton:IsA("ImageButton")
		or not chargeButton
		or not chargeButton:IsA("ImageButton")
		or not beamButton
		or not beamButton:IsA("ImageButton")
	then
		return
	end
	smashButton.Name = "SmashTouchButton"
	chargeButton.Name = "ChargeTouchButton"
	beamButton.Name = "BeamTouchButton"

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
	local requiredSideBySideWidth = buttonSize * 3 + gap * 2 + margin * 2

	local smashPosition = Vector2.new(rightColumnX, bottomRowY)
	local chargePosition: Vector2
	local beamPosition: Vector2
	if frameSize.X >= requiredSideBySideWidth then
		chargePosition = Vector2.new(rightColumnX - buttonSize - gap, bottomRowY)
		beamPosition = Vector2.new(rightColumnX - (buttonSize + gap) * 2, bottomRowY)
	else
		chargePosition = Vector2.new(rightColumnX, math.max(margin, bottomRowY - buttonSize - gap))
		beamPosition =
			Vector2.new(rightColumnX, math.max(margin, bottomRowY - (buttonSize + gap) * 2))
	end

	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local jumpButton = playerGui and playerGui:FindFirstChild("JumpButton", true)
	if
		jumpButton
		and jumpButton:IsA("GuiObject")
		and (
			overlapsGuiObject(smashPosition, buttonSize, buttonFrame, jumpButton, gap)
			or overlapsGuiObject(chargePosition, buttonSize, buttonFrame, jumpButton, gap)
			or overlapsGuiObject(beamPosition, buttonSize, buttonFrame, jumpButton, gap)
		)
	then
		local jumpLeftInFrame = jumpButton.AbsolutePosition.X - buttonFrame.AbsolutePosition.X
		local screenLeftInFrame = -buttonFrame.AbsolutePosition.X
		local smashLeftOfJumpX = math.round(jumpLeftInFrame - gap - buttonSize)
		local chargeLeftOfJumpX = smashLeftOfJumpX - buttonSize - gap
		local beamLeftOfJumpX = chargeLeftOfJumpX - buttonSize - gap

		if beamLeftOfJumpX >= screenLeftInFrame + margin then
			smashPosition = Vector2.new(smashLeftOfJumpX, bottomRowY)
			chargePosition = Vector2.new(chargeLeftOfJumpX, bottomRowY)
			beamPosition = Vector2.new(beamLeftOfJumpX, bottomRowY)
		else
			local obstacleColumnX = math.max(screenLeftInFrame + margin, smashLeftOfJumpX)
			smashPosition = Vector2.new(obstacleColumnX, bottomRowY)
			chargePosition =
				Vector2.new(obstacleColumnX, math.max(margin, bottomRowY - buttonSize - gap))
			beamPosition =
				Vector2.new(obstacleColumnX, math.max(margin, bottomRowY - (buttonSize + gap) * 2))
		end
	end

	ContextActionService:SetPosition(
		ACTION_BASIC_ATTACK,
		UDim2.fromOffset(smashPosition.X, smashPosition.Y)
	)
	ContextActionService:SetPosition(
		ACTION_CHARGE,
		UDim2.fromOffset(chargePosition.X, chargePosition.Y)
	)
	ContextActionService:SetPosition(ACTION_BEAM, UDim2.fromOffset(beamPosition.X, beamPosition.Y))
	styleTouchButton(smashButton, Color3.fromRGB(230, 105, 59), buttonSize)
	styleTouchButton(chargeButton, Color3.fromRGB(35, 190, 178), buttonSize)
	styleTouchButton(beamButton, Color3.fromRGB(34, 133, 222), buttonSize)
end

function CombatController:_disconnectJumpLayoutConnections()
	for _, connection in self._jumpLayoutConnections do
		connection:Disconnect()
	end
	table.clear(self._jumpLayoutConnections)
end

function CombatController:_watchJumpButton(instance: Instance)
	if instance.Name ~= "JumpButton" or not instance:IsA("GuiObject") then
		return
	end

	self:_disconnectJumpLayoutConnections()
	local jumpButton = instance :: GuiObject
	local function relayout()
		task.defer(function()
			if jumpButton.Parent then
				self:_layoutTouchButtons()
			end
		end)
	end

	for _, propertyName in { "AbsolutePosition", "AbsoluteSize", "Visible" } do
		table.insert(
			self._jumpLayoutConnections,
			jumpButton:GetPropertyChangedSignal(propertyName):Connect(relayout)
		)
	end
	relayout()
end

function CombatController:Start()
	local playerGui = player:WaitForChild("PlayerGui")
	self._playerGuiDescendantAddedConnection = playerGui.DescendantAdded:Connect(function(instance)
		if instance.Name == "JumpButton" then
			self:_watchJumpButton(instance)
		end
	end)
	local existingJumpButton = playerGui:FindFirstChild("JumpButton", true)
	if existingJumpButton then
		self:_watchJumpButton(existingJumpButton)
	end

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
	ContextActionService:BindAction(ACTION_BEAM, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:_requestBeam()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
	ContextActionService:SetTitle(ACTION_BEAM, "BEAM")
	ContextActionService:SetDescription(ACTION_BEAM, "Fire Brontide's energy beam")
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
			self._touchLayoutPositionConnection = buttonFrame
				:GetPropertyChangedSignal("AbsolutePosition")
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
				elseif result.abilityId == "beam" then
					self:_resetBeamCooldownVisual()
				end
				return
			end
			if result.abilityId == "charge" then
				self:_pulseCamera(8, 0.06, 0.28)
				self:_emitChargeFeedback()
			elseif result.abilityId == "chargeImpact" and result.effectTarget then
				self:_pulseCamera(5, 0.04, 0.2)
				self:_emitImpactFeedback(result.effectTarget, Color3.fromRGB(255, 147, 61), 5)
			elseif result.abilityId == "beam" and result.effectOrigin and result.effectTarget then
				self:_pulseCamera(if result.hitCount > 0 then 6 else 3, 0.04, 0.22)
				self:_emitBeam(result.effectOrigin, result.effectTarget, result.hitCount > 0)
			elseif result.hitCount > 0 then
				self:_pulseCamera(3, 0.08, 0.18)
			end
		end
	)
end

function CombatController:Destroy()
	self:_resetChargeCooldownVisual()
	self:_resetBeamCooldownVisual()
	ContextActionService:UnbindAction(ACTION_BASIC_ATTACK)
	ContextActionService:UnbindAction(ACTION_CHARGE)
	ContextActionService:UnbindAction(ACTION_BEAM)
	self:_disconnectJumpLayoutConnections()
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
	if self._touchLayoutPositionConnection then
		self._touchLayoutPositionConnection:Disconnect()
		self._touchLayoutPositionConnection = nil
	end
end

return CombatController
