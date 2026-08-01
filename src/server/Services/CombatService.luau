--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)
local PlayerRole = require(ReplicatedStorage.Shared.PlayerRole)
local Types = require(ReplicatedStorage.Shared.Types)

type AbilityResult = Types.AbilityResult

type RateState = {
	tokens: number,
	lastRefill: number,
	lastBasicAttack: number,
	lastCharge: number,
	lastBeam: number,
}

local CombatService = {}
CombatService.__index = CombatService

local function findDestructible(part: BasePart): Model?
	local candidate: Instance? = part
	while candidate and candidate ~= workspace do
		if
			candidate:IsA("Model")
			and CollectionService:HasTag(candidate, DestructibleContract.Tag)
		then
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
			lastBeam = -math.huge,
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

function CombatService:_getLivingCharacter(player: Player): (Model?, BasePart?)
	if not PlayerRole.IsKaiju(player) then
		return nil, nil
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
		return nil, nil
	end

	return character, rootPart
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

	local character, rootPart = self:_getLivingCharacter(player)
	if not character or not rootPart then
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
	overlapParams.CollisionGroup = DestructibleContract.AttackQueryCollisionGroup
	overlapParams.ExcludeInstances = { character }
	overlapParams.MaxParts = Config.Combat.MaximumStructuresPerAttack

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

	local character, rootPart = self:_getLivingCharacter(player)
	if not character or not rootPart then
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

	local overlapParams = OverlapParams.new()
	overlapParams.CollisionGroup = DestructibleContract.AttackQueryCollisionGroup
	overlapParams.ExcludeInstances = { character }
	overlapParams.MaxParts = Config.Combat.MaximumChargeStructures * 2
	local seen = {} :: { [Model]: boolean }
	local impactCount = 0
	task.spawn(function()
		local endsAt = os.clock() + Config.Combat.ChargeDurationSeconds
		while os.clock() < endsAt and rootPart.Parent and character.Parent do
			local impactCFrame = rootPart.CFrame
				* CFrame.new(0, 0, -Config.Combat.ChargeImpactForwardOffset)
			local parts = workspace:GetPartBoundsInBox(
				impactCFrame,
				Config.Combat.ChargeImpactHitboxSize,
				overlapParams
			)
			for _, part in parts do
				local structure = findDestructible(part)
				if structure and not seen[structure] then
					seen[structure] = true
					if
						self._destructionService:Damage(
							player,
							structure,
							Config.Combat.ChargeImpactDamage
						)
					then
						impactCount += 1
						self:_sendResult(player, {
							accepted = true,
							abilityId = "chargeImpact",
							sequence = sequence,
							hitCount = 1,
							effectTarget = part.Position,
						})
						if impactCount >= Config.Combat.MaximumChargeStructures then
							break
						end
					end
				end
			end
			if impactCount >= Config.Combat.MaximumChargeStructures then
				break
			end
			RunService.Heartbeat:Wait()
		end
	end)

	task.delay(Config.Combat.ChargeDurationSeconds, function()
		velocity:Destroy()
		attachment:Destroy()
	end)
	self:_sendResult(
		player,
		{ accepted = true, abilityId = "charge", sequence = sequence, hitCount = 0 }
	)
end

local function getValidatedBeamDirection(rootPart: BasePart, requestedDirection: any): Vector3
	local fallback = rootPart.CFrame.LookVector
	if typeof(requestedDirection) ~= "Vector3" then
		return fallback
	end
	if
		requestedDirection.X ~= requestedDirection.X
		or requestedDirection.Y ~= requestedDirection.Y
		or requestedDirection.Z ~= requestedDirection.Z
		or requestedDirection.Magnitude < 0.5
	then
		return fallback
	end

	local direction = requestedDirection.Unit
	local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
	local horizontalForward = Vector3.new(fallback.X, 0, fallback.Z)
	if
		horizontalDirection.Magnitude < 0.1
		or horizontalForward.Magnitude < 0.1
		or horizontalDirection.Unit:Dot(horizontalForward.Unit) < math.cos(math.rad(75))
	then
		return fallback
	end

	local clampedY = math.clamp(direction.Y, -0.7, 0.7)
	local horizontalScale = math.sqrt(math.max(0, 1 - clampedY * clampedY))
	return horizontalDirection.Unit * horizontalScale + Vector3.new(0, clampedY, 0)
end

function CombatService:_performBeam(player: Player, sequence: number, requestedDirection: any)
	local state = self._rateStates[player]
	assert(state, "Rate state must exist before performing a beam")

	local now = os.clock()
	if now - state.lastBeam < Config.Combat.BeamCooldownSeconds then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "beam",
			sequence = sequence,
			hitCount = 0,
			reason = "cooldown",
		})
		return
	end

	if self._roundService:GetPhase() ~= "Active" then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "beam",
			sequence = sequence,
			hitCount = 0,
			reason = "round_inactive",
		})
		return
	end

	local character, rootPart = self:_getLivingCharacter(player)
	if not character or not rootPart then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "beam",
			sequence = sequence,
			hitCount = 0,
			reason = "invalid_character",
		})
		return
	end

	state.lastBeam = now
	local aimDirection = getValidatedBeamDirection(rootPart, requestedDirection)
	local head = character:FindFirstChild("Head")
	local mouthPosition = if head and head:IsA("BasePart")
		then head.Position
			+ Vector3.new(0, Config.Combat.BeamMouthVerticalOffset, 0)
			+ aimDirection * Config.Combat.BeamMouthForwardOffset
		else rootPart.Position + Vector3.new(0, Config.Combat.BeamOriginHeight, 0)
	local origin = mouthPosition
	local direction = aimDirection * Config.Combat.BeamRange
	local raycastParams = RaycastParams.new()
	raycastParams.CollisionGroup = DestructibleContract.AttackQueryCollisionGroup
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.IgnoreWater = true

	local raycastResult =
		workspace:Spherecast(origin, Config.Combat.BeamCastRadius, direction, raycastParams)
	local target = origin + direction
	local hitCount = 0
	if raycastResult then
		target = raycastResult.Position
		local structure = findDestructible(raycastResult.Instance)
		if
			structure
			and self._destructionService:Damage(player, structure, Config.Combat.BeamDamage)
		then
			hitCount = 1
		end
	end

	self:_sendResult(player, {
		accepted = true,
		abilityId = "beam",
		sequence = sequence,
		hitCount = hitCount,
		effectOrigin = origin,
		effectTarget = target,
	})
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
		(abilityId ~= "basic" and abilityId ~= "charge" and abilityId ~= "beam")
		or typeof(sequence) ~= "number"
		or sequence % 1 ~= 0
		or sequence < 1
	then
		return
	end

	if abilityId == "basic" then
		self:_performBasicAttack(player, sequence)
	elseif abilityId == "charge" then
		self:_performCharge(player, sequence)
	else
		self:_performBeam(player, sequence, payload.aimDirection)
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
