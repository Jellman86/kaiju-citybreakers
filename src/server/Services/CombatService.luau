--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)
local PlayerRole = require(ReplicatedStorage.Shared.PlayerRole)
local Types = require(ReplicatedStorage.Shared.Types)
local VehicleContract = require(ReplicatedStorage.Shared.VehicleContract)

type AbilityResult = Types.AbilityResult

type RateState = {
	tokens: number,
	lastRefill: number,
	lastHumanFire: number,
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

local function findVehicleId(part: BasePart): string?
	local candidate: Instance? = part
	while candidate and candidate ~= workspace do
		if candidate:IsA("Model") and CollectionService:HasTag(candidate, VehicleContract.Tag) then
			local id = candidate:GetAttribute(VehicleContract.Attribute.Id)
			return if typeof(id) == "string" and id ~= "" then id else nil
		end
		candidate = candidate.Parent
	end
	return nil
end

function CombatService.new(
	abilityRequestRemote: RemoteEvent,
	abilityResultRemote: RemoteEvent,
	destructionService: any,
	roundService: any,
	enemyService: any
)
	local self = setmetatable({}, CombatService)

	self._abilityRequestRemote = abilityRequestRemote
	self._abilityResultRemote = abilityResultRemote
	self._destructionService = destructionService
	self._roundService = roundService
	self._enemyService = enemyService
	self._rateStates = {} :: { [Player]: RateState }
	self._lastContactDamage = {} :: { [Player]: number }
	self._contactAccumulator = 0
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
			lastHumanFire = -math.huge,
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

function CombatService:_getLivingCharacterForRole(
	player: Player,
	role: PlayerRole.Value
): (Model?, BasePart?, Humanoid?)
	if PlayerRole.Get(player) ~= role then
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
		return nil, nil, nil
	end

	return character, rootPart, humanoid
end

function CombatService:_getLivingCharacter(player: Player): (Model?, BasePart?)
	local character, rootPart = self:_getLivingCharacterForRole(player, PlayerRole.Kaiju)
	return character, rootPart
end

local function findPlayerCharacterFromPart(part: BasePart): (Player?, Humanoid?, Model?)
	local candidate: Instance? = part
	while candidate and candidate ~= workspace do
		if candidate:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(candidate)
			local humanoid = candidate:FindFirstChildOfClass("Humanoid")
			if player and humanoid then
				return player, humanoid, candidate
			end
		end
		candidate = candidate.Parent
	end
	return nil, nil, nil
end

function CombatService:_damageHumansInBox(
	attackerCharacter: Model,
	hitboxCFrame: CFrame,
	hitboxSize: Vector3,
	damage: number
): number
	local overlapParams = OverlapParams.new()
	overlapParams.CollisionGroup = PlayerRole.CollisionGroup.KaijuDamageQuery
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { attackerCharacter }

	local seen = {} :: { [Player]: boolean }
	local hitCount = 0
	for _, part in workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, overlapParams) do
		local targetPlayer, humanoid = findPlayerCharacterFromPart(part)
		if
			targetPlayer
			and humanoid
			and not seen[targetPlayer]
			and PlayerRole.IsHuman(targetPlayer)
			and humanoid.Health > 0
		then
			seen[targetPlayer] = true
			humanoid:TakeDamage(damage)
			hitCount += 1
		end
	end
	return hitCount
end

local function getValidatedHumanAimDirection(rootPart: BasePart, requestedDirection: any): Vector3
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
	if
		direction:Dot(fallback) < math.cos(math.rad(Config.Combat.HumanFireMaximumAimAngleDegrees))
	then
		return fallback
	end
	return direction
end

function CombatService:_performHumanFire(player: Player, sequence: number, requestedDirection: any)
	local state = self._rateStates[player]
	assert(state, "Rate state must exist before firing")

	local now = os.clock()
	if now - state.lastHumanFire < Config.Combat.HumanFireCooldownSeconds then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "humanFire",
			sequence = sequence,
			hitCount = 0,
			reason = "cooldown",
		})
		return
	end
	if self._roundService:GetPhase() ~= "Active" then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "humanFire",
			sequence = sequence,
			hitCount = 0,
			reason = "round_inactive",
		})
		return
	end

	local character, rootPart = self:_getLivingCharacterForRole(player, PlayerRole.Human)
	if not character or not rootPart then
		self:_sendResult(player, {
			accepted = false,
			abilityId = "humanFire",
			sequence = sequence,
			hitCount = 0,
			reason = "invalid_character",
		})
		return
	end

	state.lastHumanFire = now
	local direction = getValidatedHumanAimDirection(rootPart, requestedDirection)
	local head = character:FindFirstChild("Head")
	local origin = if head and head:IsA("BasePart")
		then head.Position
		else rootPart.Position + Vector3.new(0, Config.Combat.HumanFireOriginHeight, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.CollisionGroup = PlayerRole.CollisionGroup.HumanWeaponQuery
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.IgnoreWater = true
	local result =
		workspace:Raycast(origin, direction * Config.Combat.HumanFireRange, raycastParams)
	local target = origin + direction * Config.Combat.HumanFireRange
	local hitCount = 0
	if result then
		target = result.Position
		local targetPlayer, humanoid = findPlayerCharacterFromPart(result.Instance)
		if
			targetPlayer
			and humanoid
			and PlayerRole.IsKaiju(targetPlayer)
			and humanoid.Health > 0
		then
			humanoid:TakeDamage(Config.Combat.HumanFireDamage)
			hitCount = 1
		else
			local vehicleId = findVehicleId(result.Instance)
			if
				vehicleId and self._enemyService:Damage(vehicleId, Config.Combat.HumanFireDamage)
			then
				hitCount = 1
			end
		end
	end

	self:_sendResult(player, {
		accepted = true,
		abilityId = "humanFire",
		sequence = sequence,
		hitCount = hitCount,
		effectOrigin = origin,
		effectTarget = target,
	})
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
	local seenVehicles = {} :: { [string]: boolean }
	local hitCount = 0

	for _, part in parts do
		local vehicleId = findVehicleId(part)
		if vehicleId and not seenVehicles[vehicleId] then
			seenVehicles[vehicleId] = true
			if self._enemyService:Damage(vehicleId, Config.Combat.BasicAttackHumanDamage) then
				hitCount += 1
			end
		end
		local structure = findDestructible(part)
		if structure and not seen[structure] then
			seen[structure] = true
			if
				self._destructionService:Damage(
					player,
					structure,
					Config.Combat.BasicAttackDamage,
					{
						attackType = "Smash",
						position = hitboxCFrame.Position,
					}
				)
			then
				hitCount += 1
				if hitCount >= Config.Combat.MaximumStructuresPerAttack then
					break
				end
			end
		end
	end
	hitCount += self:_damageHumansInBox(
		character,
		hitboxCFrame,
		Config.Combat.BasicAttackHitboxSize,
		Config.Combat.BasicAttackHumanDamage
	)

	self:_sendResult(player, {
		accepted = true,
		abilityId = "basic",
		sequence = sequence,
		hitCount = hitCount,
		effectOrigin = rootPart.Position,
		effectTarget = hitboxCFrame.Position,
	})
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
	local seenVehicles = {} :: { [string]: boolean }
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
			self:_damageHumansInBox(
				character,
				impactCFrame,
				Config.Combat.ChargeImpactHitboxSize,
				Config.Combat.ChargeHumanDamage
			)
			for _, part in parts do
				local vehicleId = findVehicleId(part)
				if vehicleId and not seenVehicles[vehicleId] then
					seenVehicles[vehicleId] = true
					if self._enemyService:Damage(vehicleId, Config.Combat.ChargeHumanDamage) then
						impactCount += 1
					end
				end
				local structure = findDestructible(part)
				if structure and not seen[structure] then
					seen[structure] = true
					if
						self._destructionService:Damage(
							player,
							structure,
							Config.Combat.ChargeImpactDamage,
							{
								attackType = "Charge",
								position = impactCFrame.Position,
							}
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
			and self._destructionService:Damage(player, structure, Config.Combat.BeamDamage, {
				attackType = "Beam",
				position = raycastResult.Position,
				normal = raycastResult.Normal,
			})
		then
			hitCount = 1
		end
		local vehicleId = findVehicleId(raycastResult.Instance)
		if vehicleId and self._enemyService:Damage(vehicleId, Config.Combat.BeamHumanDamage) then
			hitCount += 1
		end
	end

	local characterRaycastParams = RaycastParams.new()
	characterRaycastParams.CollisionGroup = PlayerRole.CollisionGroup.HumanWeaponQuery
	characterRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	characterRaycastParams.FilterDescendantsInstances = { character }
	characterRaycastParams.IgnoreWater = true
	local characterResult = workspace:Spherecast(
		origin,
		Config.Combat.BeamHumanCastRadius,
		direction,
		characterRaycastParams
	)
	if characterResult then
		local targetPlayer, humanoid = findPlayerCharacterFromPart(characterResult.Instance)
		if
			targetPlayer
			and humanoid
			and PlayerRole.IsHuman(targetPlayer)
			and humanoid.Health > 0
		then
			humanoid:TakeDamage(Config.Combat.BeamHumanDamage)
			hitCount += 1
			if (characterResult.Position - origin).Magnitude < (target - origin).Magnitude then
				target = characterResult.Position
			end
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
		(
			abilityId ~= "humanFire"
			and abilityId ~= "basic"
			and abilityId ~= "charge"
			and abilityId ~= "beam"
		)
		or typeof(sequence) ~= "number"
		or sequence % 1 ~= 0
		or sequence < 1
	then
		return
	end

	if abilityId == "humanFire" then
		self:_performHumanFire(player, sequence, payload.aimDirection)
	elseif abilityId == "basic" then
		self:_performBasicAttack(player, sequence)
	elseif abilityId == "charge" then
		self:_performCharge(player, sequence)
	else
		self:_performBeam(player, sequence, payload.aimDirection)
	end
end

function CombatService:_applyContactDamage()
	if self._roundService:GetPhase() ~= "Active" then
		return
	end

	for _, kaijuPlayer in Players:GetPlayers() do
		if not PlayerRole.IsKaiju(kaijuPlayer) then
			continue
		end
		local character, rootPart = self:_getLivingCharacter(kaijuPlayer)
		local hull = if character then character:FindFirstChild("KaijuContactHull") else nil
		if not character or not rootPart or not hull or not hull:IsA("BasePart") then
			continue
		end

		local overlapParams = OverlapParams.new()
		overlapParams.CollisionGroup = PlayerRole.CollisionGroup.KaijuDamageQuery
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = { character }
		local querySize = hull.Size + Config.MixedScale.ContactQueryPadding
		local seen = {} :: { [Player]: boolean }
		for _, part in workspace:GetPartBoundsInBox(hull.CFrame, querySize, overlapParams) do
			local humanPlayer, humanoid, humanCharacter = findPlayerCharacterFromPart(part)
			if
				not humanPlayer
				or not humanoid
				or not humanCharacter
				or seen[humanPlayer]
				or not PlayerRole.IsHuman(humanPlayer)
				or humanoid.Health <= 0
			then
				continue
			end
			seen[humanPlayer] = true
			local now = os.clock()
			if
				now - (self._lastContactDamage[humanPlayer] or -math.huge)
				< Config.MixedScale.ContactDamageCooldownSeconds
			then
				continue
			end
			self._lastContactDamage[humanPlayer] = now
			humanoid:TakeDamage(Config.MixedScale.ContactDamage)

			local humanRoot = humanCharacter:FindFirstChild("HumanoidRootPart")
			if humanRoot and humanRoot:IsA("BasePart") and humanoid.Health > 0 then
				local away = humanRoot.Position - rootPart.Position
				local horizontalAway = Vector3.new(away.X, 0, away.Z)
				if horizontalAway.Magnitude < 0.01 then
					horizontalAway =
						Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z)
				end
				local velocity = horizontalAway.Unit
						* Config.MixedScale.ContactKnockbackHorizontalSpeed
					+ Vector3.new(0, Config.MixedScale.ContactKnockbackVerticalSpeed, 0)
				if velocity.Magnitude > Config.MixedScale.MaximumContactVelocity then
					velocity = velocity.Unit * Config.MixedScale.MaximumContactVelocity
				end
				humanRoot.AssemblyLinearVelocity = velocity
			end
		end
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
		RunService.Heartbeat:Connect(function(deltaTime)
			self._contactAccumulator += deltaTime
			if self._contactAccumulator < Config.MixedScale.ContactQueryIntervalSeconds then
				return
			end
			self._contactAccumulator %= Config.MixedScale.ContactQueryIntervalSeconds
			self:_applyContactDamage()
		end)
	)
	table.insert(
		self._connections,
		Players.PlayerRemoving:Connect(function(player)
			self._rateStates[player] = nil
			self._lastContactDamage[player] = nil
		end)
	)
end

function CombatService:Stop()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._rateStates)
	table.clear(self._lastContactDamage)
	self._contactAccumulator = 0
end

return CombatService
