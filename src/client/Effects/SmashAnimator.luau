--!strict

local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

type ShellPose = {
	motor: Motor6D,
	baseC0: CFrame,
	part: BasePart,
	initialPosition: Vector3,
}

local SmashAnimator = {}
SmashAnimator.__index = SmashAnimator

local RENDER_STEP_NAME = "BrontideVisibleSmashPose"

-- These offsets animate dedicated visual-shell motors, not Roblox's
-- animator-owned avatar joints. Translation is intentionally generous because
-- Brontide is ten times human scale and a sub-stud pose is unreadable on phones.
local WINDUP_OFFSETS: { [string]: CFrame } = table.freeze({
	RightUpperArmShell = CFrame.new(1.5, 3, 4.5)
		* CFrame.Angles(math.rad(-48), math.rad(-10), math.rad(24)),
	LeftUpperArmShell = CFrame.new(-1.5, 3, 4.5)
		* CFrame.Angles(math.rad(-48), math.rad(10), math.rad(-24)),
	RightForearmShell = CFrame.new(2, 5, 6.5)
		* CFrame.Angles(math.rad(-62), math.rad(-8), math.rad(18)),
	LeftForearmShell = CFrame.new(-2, 5, 6.5)
		* CFrame.Angles(math.rad(-62), math.rad(8), math.rad(-18)),
	RightClaw = CFrame.new(2.5, 7, 8.5) * CFrame.Angles(math.rad(-72), math.rad(-8), math.rad(14)),
	LeftClaw = CFrame.new(-2.5, 7, 8.5) * CFrame.Angles(math.rad(-72), math.rad(8), math.rad(-14)),
})

local STRIKE_OFFSETS: { [string]: CFrame } = table.freeze({
	RightUpperArmShell = CFrame.new(1, -2, -4)
		* CFrame.Angles(math.rad(38), math.rad(8), math.rad(-16)),
	LeftUpperArmShell = CFrame.new(-1, -2, -4)
		* CFrame.Angles(math.rad(38), math.rad(-8), math.rad(16)),
	RightForearmShell = CFrame.new(1.5, -4, -8)
		* CFrame.Angles(math.rad(54), math.rad(6), math.rad(-12)),
	LeftForearmShell = CFrame.new(-1.5, -4, -8)
		* CFrame.Angles(math.rad(54), math.rad(-6), math.rad(12)),
	RightClaw = CFrame.new(2, -6, -12) * CFrame.Angles(math.rad(68), math.rad(5), math.rad(-8)),
	LeftClaw = CFrame.new(-2, -6, -12) * CFrame.Angles(math.rad(68), math.rad(-5), math.rad(8)),
})

local function cubicIn(alpha: number): number
	return alpha * alpha * alpha
end

local function quartIn(alpha: number): number
	local squared = alpha * alpha
	return squared * squared
end

local function cubicOut(alpha: number): number
	local inverse = 1 - alpha
	return 1 - inverse * inverse * inverse
end

local function collectShellPoses(character: Model): { ShellPose }
	local poses = {} :: { ShellPose }
	local shell = character:FindFirstChild("BrontideVisual")
	if not shell then
		return poses
	end

	for _, descendant in shell:GetDescendants() do
		if not descendant:IsA("BasePart") or not WINDUP_OFFSETS[descendant.Name] then
			continue
		end
		local motor = descendant:FindFirstChild("ShellMotor")
		if motor and motor:IsA("Motor6D") then
			table.insert(poses, {
				motor = motor,
				baseC0 = motor.C0,
				part = descendant,
				initialPosition = descendant.Position,
			})
		end
	end
	return poses
end

function SmashAnimator.new()
	local self = setmetatable({}, SmashAnimator)
	self._activePoses = {} :: { ShellPose }
	self._activeCharacter = nil :: Model?
	self._onImpact = nil :: (() -> ())?
	self._impactFired = false
	self._startedAt = 0
	self._maximumShellDisplacement = 0
	return self
end

function SmashAnimator:_setPose(offsets: { [string]: CFrame }, alpha: number)
	for _, pose in self._activePoses do
		local targetOffset = offsets[pose.part.Name] or CFrame.identity
		pose.motor.C0 = pose.baseC0 * CFrame.new():Lerp(targetOffset, alpha)
	end
end

function SmashAnimator:_blendPose(
	fromOffsets: { [string]: CFrame },
	toOffsets: { [string]: CFrame },
	alpha: number
)
	for _, pose in self._activePoses do
		local fromOffset = fromOffsets[pose.part.Name] or CFrame.identity
		local toOffset = toOffsets[pose.part.Name] or CFrame.identity
		pose.motor.C0 = pose.baseC0 * fromOffset:Lerp(toOffset, alpha)
	end
end

function SmashAnimator:_recordVisibleDisplacement()
	local character = self._activeCharacter
	if not character then
		return
	end
	for _, pose in self._activePoses do
		if pose.part.Parent then
			self._maximumShellDisplacement = math.max(
				self._maximumShellDisplacement,
				(pose.part.Position - pose.initialPosition).Magnitude
			)
		end
	end
	character:SetAttribute("ClientSmashMaximumShellDisplacement", self._maximumShellDisplacement)
end

function SmashAnimator:_restoreActivePose()
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
	for _, pose in self._activePoses do
		if pose.motor.Parent then
			pose.motor.C0 = pose.baseC0
		end
	end
	table.clear(self._activePoses)
	if self._activeCharacter and self._activeCharacter.Parent then
		self._activeCharacter:SetAttribute("ClientSmashAnimationPhase", "Idle")
	end
	self._activeCharacter = nil
	self._onImpact = nil
	self._impactFired = false
end

function SmashAnimator:_updatePose()
	local character = self._activeCharacter
	if not character or not character.Parent then
		self:Reset()
		return
	end

	local elapsed = os.clock() - self._startedAt
	local windupEnd = Config.Combat.SmashWindupSeconds
	local strikeEnd = windupEnd + Config.Combat.SmashStrikeSeconds
	local impactAt = windupEnd + Config.Combat.SmashStrikeSeconds * 0.72
	local holdEnd = strikeEnd + Config.Combat.SmashImpactHoldSeconds
	local recoveryEnd = holdEnd + Config.Combat.SmashRecoverySeconds
	if not self._impactFired and elapsed >= impactAt then
		self._impactFired = true
		local onImpact = self._onImpact
		if onImpact then
			onImpact()
		end
	end

	if elapsed < windupEnd then
		character:SetAttribute("ClientSmashAnimationPhase", "Windup")
		self:_setPose(WINDUP_OFFSETS, cubicIn(math.clamp(elapsed / windupEnd, 0, 1)))
	elseif elapsed < strikeEnd then
		character:SetAttribute("ClientSmashAnimationPhase", "Strike")
		local alpha = math.clamp((elapsed - windupEnd) / Config.Combat.SmashStrikeSeconds, 0, 1)
		self:_blendPose(WINDUP_OFFSETS, STRIKE_OFFSETS, quartIn(alpha))
	elseif elapsed < holdEnd then
		character:SetAttribute("ClientSmashAnimationPhase", "ImpactHold")
		self:_setPose(STRIKE_OFFSETS, 1)
	elseif elapsed < recoveryEnd then
		character:SetAttribute("ClientSmashAnimationPhase", "Recovery")
		local alpha = math.clamp((elapsed - holdEnd) / Config.Combat.SmashRecoverySeconds, 0, 1)
		self:_blendPose(STRIKE_OFFSETS, {}, cubicOut(alpha))
	else
		self:_restoreActivePose()
		return
	end

	self:_recordVisibleDisplacement()
end

function SmashAnimator:Play(character: Model, onImpact: () -> ()): boolean
	self:_restoreActivePose()

	local poses = collectShellPoses(character)
	if #poses == 0 then
		character:SetAttribute("ClientSmashAnimationPhase", "Unavailable")
		onImpact()
		return false
	end

	self._maximumShellDisplacement = 0
	character:SetAttribute("ClientSmashMaximumShellDisplacement", 0)
	self._activePoses = poses
	self._activeCharacter = character
	self._onImpact = onImpact
	self._impactFired = false
	self._startedAt = os.clock()
	character:SetAttribute("ClientSmashAnimationPhase", "Windup")

	-- C0 on these dedicated shell motors persists through the avatar animation
	-- pass. Updating after the camera step makes the pose deterministic and keeps
	-- the same timing contract on desktop, gamepad, and touch clients.
	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 2, function()
		self:_updatePose()
	end)
	return true
end

function SmashAnimator:Reset()
	self:_restoreActivePose()
end

function SmashAnimator:Destroy()
	self:Reset()
end

return SmashAnimator
