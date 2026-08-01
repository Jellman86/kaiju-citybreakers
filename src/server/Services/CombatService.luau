--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)

type AbilityResult = Types.AbilityResult

type RateState = {
	tokens: number,
	lastRefill: number,
	lastBasicAttack: number,
	lastCharge: number,
}

local CombatService = {}
CombatService.__index = CombatService

local function findDestructible(part: BasePart): Model?
	local candidate: Instance? = part
	while candidate and candidate ~= workspace do
		if candidate:IsA("Model") and CollectionService:HasTag(candidate, "Destructible") then
			return candidate
		end
		candidate = candidate.Parent
	end
	return nil
end

function CombatService.new(
	abilityRequestRemote: RemoteEvent,
	abilityResultRemote: RemoteEvent,
	destructionService: any,
	roundService: any
)
	local self = setmetatable({}, CombatService)

	self._abilityRequestRemote = abilityRequestRemote
	self._abilityResultRemote = abilityResultRemote
	self._destructionService = destructionService
	self._roundService = roundService
	self._rateStates = {} :: { [Player]: RateState }
	self._connections = {} :: { RBXScriptConnection }

	return self
end

function CombatService:_sendResult(player: Player, result: AbilityResult)
	self._abilityResultRemote:FireClient(player, result)
end

function CombatService:_consumeRateToken(player: Player): boolean
	local now = os.clock()
	local state = self._rateStates[player]
	if not state then
		state = {
			tokens = Config.Combat.AbilityRequestRatePerSecond,
			lastRefill = now,
			lastBasicAttack = -math.huge,
			lastCharge = -math.huge,
		}
		self._rateStates[player] = state
	end

	local elapsed = now - state.lastRefill
	state.tokens = math.min(
		Config.Combat.AbilityRequestRatePerSecond,
		state.tokens + elapsed * Config.Combat.AbilityRequestRatePerSecond
	)
	state.lastRefill = now

	if state.tokens < 1 then
		return false
	end

	state.tokens -= 1
	return true
end

function CombatService:_performBasicAttack(player: Player, sequence: number)
	local state = self._rateStates[player]
	assert(state, "Rate state must exist before performing an attack")

	local now = os.clock()
	if now - state.lastBasicAttack < Config.Combat.BasicAttackCooldownSeconds then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "basic",
			sequence = sequence,
			hitCount = 0,
			reason = "cooldown",
		})
		return
	end

	if self._roundService:GetPhase() ~= "Active" then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "basic",
			sequence = sequence,
			hitCount = 0,
			reason = "round_inactive",
		})
		return
	end

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if
		not character
		or not humanoid
		or humanoid.Health <= 0
		or not rootPart
		or not rootPart:IsA("BasePart")
	then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "basic",
			sequence = sequence,
			hitCount = 0,
			reason = "invalid_character",
		})
		return
	end

	state.lastBasicAttack = now

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { character }

	local hitboxCFrame = rootPart.CFrame * CFrame.new(0, 0, -Config.Combat.BasicAttackForwardOffset)
	local parts = workspace:GetPartBoundsInBox(
		hitboxCFrame,
		Config.Combat.BasicAttackHitboxSize,
		overlapParams
	)
	local seen = {} :: { [Model]: boolean }
	local hitCount = 0

	for _, part in parts do
		local structure = findDestructible(part)
		if structure and not seen[structure] then
			seen[structure] = true
			if
				self._destructionService:Damage(player, structure, Config.Combat.BasicAttackDamage)
			then
				hitCount += 1
				if hitCount >= Config.Combat.MaximumStructuresPerAttack then
					break
				end
			end
		end
	end

	self:_sendResult(
		player,
		{ accepted = true, abilityId = "basic", sequence = sequence, hitCount = hitCount }
	)
end

function CombatService:_performCharge(player: Player, sequence: number)
	local state = self._rateStates[player]
	assert(state, "Rate state must exist before performing a charge")

	local now = os.clock()
	if now - state.lastCharge < Config.Combat.ChargeCooldownSeconds then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "charge",
			sequence = sequence,
			hitCount = 0,
			reason = "cooldown",
		})
		return
	end

	if self._roundService:GetPhase() ~= "Active" then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "charge",
			sequence = sequence,
			hitCount = 0,
			reason = "round_inactive",
		})
		return
	end

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if
		not character
		or not humanoid
		or humanoid.Health <= 0
		or not rootPart
		or not rootPart:IsA("BasePart")
	then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "charge",
			sequence = sequence,
			hitCount = 0,
			reason = "invalid_character",
		})
		return
	end

	state.lastCharge = now
	local forward = rootPart.CFrame.LookVector
	local attachment = Instance.new("Attachment")
	attachment.Name = "ChargeAttachment"
	attachment.Parent = rootPart

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "ChargeVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.new(
		forward.X * Config.StarterKaiju.ChargeSpeed,
		Config.Combat.ChargeVerticalVelocity,
		forward.Z * Config.StarterKaiju.ChargeSpeed
	)
	velocity.Parent = rootPart

	task.delay(Config.Combat.ChargeDurationSeconds, function()
		velocity:Destroy()
		attachment:Destroy()
	end)
	self:_sendResult(
		player,
		{ accepted = true, abilityId = "charge", sequence = sequence, hitCount = 0 }
	)
end

function CombatService:_onAbilityRequest(player: Player, payload: any)
	if not self:_consumeRateToken(player) then
		return
	end

	if typeof(payload) ~= "table" then
		return
	end

	local abilityId = payload.abilityId
	local sequence = payload.sequence
	if
		(abilityId ~= "basic" and abilityId ~= "charge")
		or typeof(sequence) ~= "number"
		or sequence % 1 ~= 0
		or sequence < 1
	then
		return
	end

	if abilityId == "basic" then
		self:_performBasicAttack(player, sequence)
	else
		self:_performCharge(player, sequence)
	end
end

function CombatService:Start()
	table.insert(
		self._connections,
		self._abilityRequestRemote.OnServerEvent:Connect(function(player, payload)
			self:_onAbilityRequest(player, payload)
		end)
	)
	table.insert(
		self._connections,
		Players.PlayerRemoving:Connect(function(player)
			self._rateStates[player] = nil
		end)
	)
end

function CombatService:Stop()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._rateStates)
end

return CombatService
