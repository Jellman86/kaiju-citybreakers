--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EnemyContract = require(ReplicatedStorage.Shared.EnemyContract)

type RigEntry = {
	model: Model,
	motors: { [string]: Motor6D },
	state: string,
	stateStartedAt: number,
	aura: Highlight,
}

local EnemyEffectsController = {}
EnemyEffectsController.__index = EnemyEffectsController

local function desiredTransform(name: string, state: string, attack: string, now: number): CFrame
	local moving = state == EnemyContract.State.Patrolling
		or state == EnemyContract.State.Investigating
		or state == EnemyContract.State.Chasing
	local stride = if moving then math.sin(now * 7.5) else math.sin(now * 1.8) * 0.12
	if name == "LeftLeg" then
		return CFrame.Angles(stride * 0.5, 0, 0)
	elseif name == "RightLeg" then
		return CFrame.Angles(-stride * 0.5, 0, 0)
	elseif name == "LeftArm" then
		if state == EnemyContract.State.Telegraphing and attack == EnemyContract.Attack.Swipe then
			return CFrame.Angles(math.rad(-58), 0, math.rad(-24))
		end
		return CFrame.Angles(-stride * 0.38, 0, math.rad(-7))
	elseif name == "RightArm" then
		if state == EnemyContract.State.Telegraphing and attack == EnemyContract.Attack.Swipe then
			return CFrame.Angles(math.rad(-70), 0, math.rad(28))
		end
		return CFrame.Angles(stride * 0.38, 0, math.rad(7))
	elseif name == "Chest" then
		if state == EnemyContract.State.Telegraphing and attack == EnemyContract.Attack.Lunge then
			return CFrame.Angles(math.rad(-18), 0, 0)
		elseif state == EnemyContract.State.Staggered then
			return CFrame.Angles(math.rad(20), 0, math.rad(8))
		end
		return CFrame.Angles(math.sin(now * 1.8) * 0.025, 0, 0)
	elseif name == "Head" or name == "Muzzle" then
		if state == EnemyContract.State.Telegraphing then
			return CFrame.Angles(math.rad(-10), math.sin(now * 9) * 0.05, 0)
		end
		return CFrame.Angles(0, math.sin(now * 1.25) * 0.08, 0)
	elseif string.sub(name, 1, 4) == "Tail" then
		local index = tonumber(string.sub(name, 5)) or 1
		return CFrame.Angles(0, math.sin(now * 2.5 - index * 0.65) * (0.16 + index * 0.035), 0)
	end
	return CFrame.identity
end

function EnemyEffectsController.new()
	local self = setmetatable({}, EnemyEffectsController)
	self._rigs = {} :: { [Model]: RigEntry }
	self._connections = {} :: { RBXScriptConnection }
	self._renderConnection = nil :: RBXScriptConnection?
	return self
end

function EnemyEffectsController:_register(instance: Instance)
	if not instance:IsA("Model") or self._rigs[instance] then
		return
	end
	local motors = {} :: { [string]: Motor6D }
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("Motor6D") and string.sub(descendant.Name, 1, 4) == "Rig_" then
			motors[string.sub(descendant.Name, 5)] = descendant
		end
	end
	if next(motors) == nil then
		return
	end
	local aura = Instance.new("Highlight")
	aura.Name = "EnemyEnragedAura"
	aura.Adornee = instance
	aura.DepthMode = Enum.HighlightDepthMode.Occluded
	aura.FillColor = Color3.fromRGB(190, 35, 255)
	aura.FillTransparency = 0.82
	aura.OutlineColor = Color3.fromRGB(255, 95, 180)
	aura.OutlineTransparency = 0.22
	aura.Enabled = false
	aura.Parent = instance
	self._rigs[instance] = {
		model = instance,
		motors = motors,
		state = "",
		stateStartedAt = os.clock(),
		aura = aura,
	}
end

function EnemyEffectsController:_unregister(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local entry = self._rigs[instance]
	if not entry then
		return
	end
	for _, motor in entry.motors do
		motor.Transform = CFrame.identity
	end
	entry.aura:Destroy()
	self._rigs[instance] = nil
end

function EnemyEffectsController:_render(dt: number)
	local now = os.clock()
	local alpha = 1 - math.exp(-12 * math.min(dt, 0.1))
	for model, entry in self._rigs do
		if not model:IsDescendantOf(workspace) then
			self:_unregister(model)
			continue
		end
		local state = model:GetAttribute(EnemyContract.Attribute.State)
		state = if type(state) == "string" then state else EnemyContract.State.Idle
		if state ~= entry.state then
			entry.state = state
			entry.stateStartedAt = now
		end
		local attack = model:GetAttribute(EnemyContract.Attribute.AttackKind)
		attack = if type(attack) == "string" then attack else EnemyContract.Attack.None
		entry.aura.Enabled = model:GetAttribute(EnemyContract.Attribute.Enraged) == true
		for name, motor in entry.motors do
			local desired = desiredTransform(name, state, attack, now)
			motor.Transform = motor.Transform:Lerp(desired, alpha)
		end
	end
end

function EnemyEffectsController:Start()
	for _, instance in CollectionService:GetTagged(EnemyContract.Tag) do
		self:_register(instance)
	end
	table.insert(
		self._connections,
		CollectionService:GetInstanceAddedSignal(EnemyContract.Tag):Connect(function(instance)
			self:_register(instance)
		end)
	)
	table.insert(
		self._connections,
		CollectionService:GetInstanceRemovedSignal(EnemyContract.Tag):Connect(function(instance)
			self:_unregister(instance)
		end)
	)
	self._renderConnection = RunService.RenderStepped:Connect(function(dt)
		self:_render(dt)
	end)
end

function EnemyEffectsController:Destroy()
	if self._renderConnection then
		self._renderConnection:Disconnect()
		self._renderConnection = nil
	end
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	local models = {}
	for model in self._rigs do
		table.insert(models, model)
	end
	for _, model in models do
		self:_unregister(model)
	end
end

return EnemyEffectsController
