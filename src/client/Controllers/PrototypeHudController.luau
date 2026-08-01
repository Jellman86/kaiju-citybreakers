--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PrototypeHudController = {}
PrototypeHudController.__index = PrototypeHudController

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
	self._screenGui = nil :: ScreenGui?

	return self
end

function PrototypeHudController:Start()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "KaijuFeelLabHud"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self._screenGui = screenGui

	createLabel(
		"Title",
		UDim2.fromScale(0.5, 0.035),
		UDim2.fromOffset(360, 44),
		"KAIJU FEEL LAB",
		24,
		screenGui
	)
	createLabel(
		"Objective",
		UDim2.fromScale(0.5, 0.095),
		UDim2.fromOffset(560, 54),
		"Q / SHIFT to CHARGE  •  E / CLICK to SMASH twice",
		20,
		screenGui
	)
	local phaseLabel = createLabel(
		"Phase",
		UDim2.fromScale(0.5, 0.16),
		UDim2.fromOffset(300, 38),
		"Preparing...",
		17,
		screenGui
	)

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
	if self._screenGui then
		self._screenGui:Destroy()
		self._screenGui = nil
	end
end

return PrototypeHudController
