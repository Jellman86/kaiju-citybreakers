--!strict

local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

type SmashJoint = Motor6D | AnimationConstraint

type JointPose = {
	joint: SmashJoint,
	basePose: CFrame,
}

local SmashAnimator = {}
SmashAnimator.__index = SmashAnimator

local WINDUP_OFFSETS: { [string]: CFrame } = table.freeze({
	RightShoulder = CFrame.Angles(math.rad(-118), math.rad(-12), math.rad(24)),
	LeftShoulder = CFrame.Angles(math.rad(-96), math.rad(10), math.rad(-20)),
	Waist = CFrame.Angles(math.rad(-14), math.rad(-16), math.rad(-4)),
})

local STRIKE_OFFSETS: { [string]: CFrame } = table.freeze({
	RightShoulder = CFrame.Angles(math.rad(54), math.rad(8), math.rad(-12)),
	LeftShoulder = CFrame.Angles(math.rad(30), math.rad(-6), math.rad(10)),
	Waist = CFrame.Angles(math.rad(18), math.rad(12), math.rad(3)),
})

local function findJoint(character: Model, name: string): SmashJoint?
	-- Brontide's visual shell deliberately has Parts named LeftShoulder and
	-- RightShoulder. FindFirstChild(name, true) can return those before the R15
	-- joints, so filter by class while walking the descendants. Roblox can expose
	-- current avatar joints as AnimationConstraints or legacy Motor6Ds.
	for _, candidate in character:GetDescendants() do
		if
			(candidate:IsA("Motor6D") or candidate:IsA("AnimationConstraint"))
			and candidate.Name == name
		then
			return candidate
		end
	end
	return nil
end

function SmashAnimator.new()
	local self = setmetatable({}, SmashAnimator)
	self._token = 0
	self._activeTweens = {} :: { Tween }
	self._activeJoints = {} :: { JointPose }
	self._activeCharacter = nil :: Model?
	return self
end

function SmashAnimator:_restoreActivePose()
	for _, tween in self._activeTweens do
		tween:Cancel()
	end
	table.clear(self._activeTweens)

	for _, pose in self._activeJoints do
		if pose.joint.Parent then
			if pose.joint:IsA("Motor6D") then
				pose.joint.C0 = pose.basePose
			else
				pose.joint.Transform = pose.basePose
			end
		end
	end
	table.clear(self._activeJoints)
	if self._activeCharacter and self._activeCharacter.Parent then
		self._activeCharacter:SetAttribute("ClientSmashAnimationPhase", "Idle")
	end
	self._activeCharacter = nil
end

function SmashAnimator:_tweenPose(
	poses: { JointPose },
	offsets: { [string]: CFrame },
	duration: number,
	easingStyle: Enum.EasingStyle,
	easingDirection: Enum.EasingDirection
)
	for _, pose in poses do
		local offset = offsets[pose.joint.Name] or CFrame.identity
		local goal = pose.basePose * offset
		local goalProperties = if pose.joint:IsA("Motor6D")
			then { C0 = goal }
			else { Transform = goal }
		local tween = TweenService:Create(
			pose.joint,
			TweenInfo.new(duration, easingStyle, easingDirection),
			goalProperties
		)
		table.insert(self._activeTweens, tween)
		tween:Play()
	end
end

function SmashAnimator:Play(character: Model, onImpact: () -> ()): boolean
	self._token += 1
	local token = self._token
	self:_restoreActivePose()

	local poses = {} :: { JointPose }
	for _, jointName in { "RightShoulder", "LeftShoulder", "Waist" } do
		local joint = findJoint(character, jointName)
		if joint then
			local basePose = if joint:IsA("Motor6D") then joint.C0 else joint.Transform
			table.insert(poses, { joint = joint, basePose = basePose })
		end
	end
	if #poses == 0 then
		character:SetAttribute("ClientSmashAnimationPhase", "Unavailable")
		onImpact()
		return false
	end
	self._activeJoints = poses
	self._activeCharacter = character
	character:SetAttribute("ClientSmashAnimationPhase", "Windup")

	self:_tweenPose(
		poses,
		WINDUP_OFFSETS,
		Config.Combat.SmashWindupSeconds,
		Enum.EasingStyle.Cubic,
		Enum.EasingDirection.In
	)

	task.spawn(function()
		task.wait(Config.Combat.SmashWindupSeconds)
		if token ~= self._token then
			return
		end
		character:SetAttribute("ClientSmashAnimationPhase", "Strike")
		self:_tweenPose(
			poses,
			STRIKE_OFFSETS,
			Config.Combat.SmashStrikeSeconds,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.In
		)

		task.wait(Config.Combat.SmashStrikeSeconds * 0.72)
		if token ~= self._token then
			return
		end
		character:SetAttribute("ClientSmashAnimationPhase", "Recovery")
		onImpact()

		task.wait(Config.Combat.SmashStrikeSeconds * 0.28 + Config.Combat.SmashImpactHoldSeconds)
		if token ~= self._token then
			return
		end
		local restOffsets = {} :: { [string]: CFrame }
		self:_tweenPose(
			poses,
			restOffsets,
			Config.Combat.SmashRecoverySeconds,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		)

		task.wait(Config.Combat.SmashRecoverySeconds)
		if token == self._token then
			self:_restoreActivePose()
		end
	end)

	return true
end

function SmashAnimator:Reset()
	self._token += 1
	self:_restoreActivePose()
end

function SmashAnimator:Destroy()
	self:Reset()
end

return SmashAnimator
