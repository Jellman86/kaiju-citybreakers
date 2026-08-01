--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PrototypeHudController = {}
PrototypeHudController.__index = PrototypeHudController

local function getObjectiveText(preferredInput: Enum.PreferredInput): string
	if preferredInput == Enum.PreferredInput.Touch then
		return "BREAK THE CITY • USE THE LEFT THUMBSTICK\nTAP CHARGE • SMASH • BEAM"
	elseif preferredInput == Enum.PreferredInput.Gamepad then
		return "BREAK THE CITY • LEFT STICK TO MOVE\nLT/B: CHARGE • RT: SMASH • X: BEAM"
	end

	return "BREAK THE CITY • WASD MOVE • MOUSE LOOK/AIM\nQ/SHIFT: CHARGE • E/CLICK: SMASH • R: BEAM"
end

local function createLabel(
	name: string,
	position: UDim2,
	size: UDim2,
	text: string,
	textSize: number,
	parent: Instance
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = position
	label.Size = size
	label.BackgroundColor3 = Color3.fromRGB(14, 19, 29)
	label.BackgroundTransparency = 0.15
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = Color3.fromRGB(241, 245, 249)
	label.TextSize = textSize
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	return label
end

function PrototypeHudController.new(roundController: any)
	local self = setmetatable({}, PrototypeHudController)

	self._roundController = roundController
	self._heartbeatConnection = nil :: RBXScriptConnection?
	self._preferredInputConnection = nil :: RBXScriptConnection?
	self._screenGui = nil :: ScreenGui?

	return self
end

function PrototypeHudController:Start()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "KaijuFeelLabHud"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	screenGui.ClipToDeviceSafeArea = true
	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self._screenGui = screenGui

	local titleLabel = createLabel(
		"Title",
		UDim2.new(0.5, 0, 0, 8),
		UDim2.new(0.9, 0, 0, 44),
		"BRONTIDE: CITYBREAKERS",
		24,
		screenGui
	)
	local titleSizeConstraint = Instance.new("UISizeConstraint")
	titleSizeConstraint.MaxSize = Vector2.new(420, 44)
	titleSizeConstraint.Parent = titleLabel

	local objectiveLabel = createLabel(
		"Objective",
		UDim2.new(0.5, 0, 0, 60),
		UDim2.new(0.92, 0, 0, 64),
		getObjectiveText(UserInputService.PreferredInput),
		18,
		screenGui
	)
	local objectiveSizeConstraint = Instance.new("UISizeConstraint")
	objectiveSizeConstraint.MaxSize = Vector2.new(620, 64)
	objectiveSizeConstraint.Parent = objectiveLabel

	local phaseLabel = createLabel(
		"Phase",
		UDim2.new(0.5, 0, 0, 132),
		UDim2.new(0.8, 0, 0, 38),
		"Preparing...",
		17,
		screenGui
	)
	local phaseSizeConstraint = Instance.new("UISizeConstraint")
	phaseSizeConstraint.MaxSize = Vector2.new(360, 38)
	phaseSizeConstraint.Parent = phaseLabel

	self._preferredInputConnection = UserInputService:GetPropertyChangedSignal("PreferredInput")
		:Connect(function()
			objectiveLabel.Text = getObjectiveText(UserInputService.PreferredInput)
		end)

	self._heartbeatConnection = RunService.Heartbeat:Connect(function()
		local snapshot = self._roundController:GetSnapshot()
		if not snapshot then
			phaseLabel.Text = "Preparing..."
			return
		end

		local remaining = math.ceil(self._roundController:GetRemainingSeconds())
		if snapshot.phase == "Active" then
			phaseLabel.Text = `SMASH NOW  •  {remaining}s`
		elseif snapshot.phase == "Countdown" then
			phaseLabel.Text = `Ready in {remaining}...`
		elseif snapshot.phase == "Results" then
			phaseLabel.Text = `Resetting lab in {remaining}...`
		else
			phaseLabel.Text = "Waiting for kaiju..."
		end
	end)
end

function PrototypeHudController:Destroy()
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end
	if self._preferredInputConnection then
		self._preferredInputConnection:Disconnect()
		self._preferredInputConnection = nil
	end
	if self._screenGui then
		self._screenGui:Destroy()
		self._screenGui = nil
	end
end

return PrototypeHudController
