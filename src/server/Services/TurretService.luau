--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerRole = require(ReplicatedStorage.Shared.PlayerRole)
local TurretContract = require(ReplicatedStorage.Shared.TurretContract)
local TurretDefinitions = require(ReplicatedStorage.Shared.TurretDefinitions)

type TurretProfile = TurretDefinitions.Profile

type RosterEntry = {
	player: Player,
	role: PlayerRole.Value,
	character: Model,
	humanoid: Humanoid,
	rootPart: BasePart,
}

type TargetEntry = {
	id: string,
	team: string,
	character: Model,
	humanoid: Humanoid?,
	rootPart: BasePart,
	userId: number,
}

type TurretRecord = {
	model: Model,
	muzzle: BasePart,
	captureZone: BasePart?,
	profile: TurretProfile,
	lastShotAt: number,
	shotSequence: number,
	captureTeam: string,
	captureProgress: number,
	targetUserId: number,
	targetEntityId: string,
	targetAcquiredAt: number,
}

type ProjectileRecord = {
	id: string,
	sourceModel: Model,
	ownerTeam: PlayerRole.Value,
	profile: TurretProfile,
	position: Vector3,
	velocity: Vector3,
	expiresAt: number,
}

local TEAM_COLORS = table.freeze({
	Neutral = Color3.fromRGB(145, 150, 160),
	Human = Color3.fromRGB(65, 171, 255),
	Kaiju = Color3.fromRGB(255, 111, 62),
	Contested = Color3.fromRGB(255, 210, 68),
})

local TurretService = {}
TurretService.__index = TurretService

local function readNumber(model: Model, name: string, minimum: number): number?
	local value = model:GetAttribute(name)
	if type(value) ~= "number" or value ~= value or value < minimum then
		return nil
	end
	return value
end

local function setAttributeIfChanged(instance: Instance, name: string, value: any)
	if instance:GetAttribute(name) ~= value then
		instance:SetAttribute(name, value)
	end
end

local function getRoster(): { RosterEntry }
	local roster = {}
	for _, player in Players:GetPlayers() do
		local role = PlayerRole.Get(player)
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if
			role
			and character
			and humanoid
			and humanoid.Health > 0
			and rootPart
			and rootPart:IsA("BasePart")
		then
			table.insert(roster, {
				player = player,
				role = role,
				character = character,
				humanoid = humanoid,
				rootPart = rootPart,
			})
		end
	end
	return roster
end

local function hasUnsafeUnanchoredPart(model: Model): boolean
	local rig = model:FindFirstChild(TurretContract.Rig.ModelName)
	local rigRoot = if rig then rig:FindFirstChild(TurretContract.Rig.RootName) else nil
	local yawMotor = if rig then rig:FindFirstChild(TurretContract.Rig.YawMotorName, true) else nil
	local pitchMotor = if rig
		then rig:FindFirstChild(TurretContract.Rig.PitchMotorName, true)
		else nil
	if rig then
		if
			not rigRoot
			or not rigRoot:IsA("BasePart")
			or not rigRoot.Anchored
			or not yawMotor
			or not yawMotor:IsA("Motor6D")
			or yawMotor.Part0 ~= rigRoot
			or not pitchMotor
			or not pitchMotor:IsA("Motor6D")
			or pitchMotor.Part0 ~= yawMotor.Part1
		then
			return true
		end
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and not descendant.Anchored then
			if not rigRoot or not rigRoot:IsA("BasePart") then
				return true
			end
			if descendant.AssemblyRootPart ~= rigRoot then
				return true
			end
		end
	end
	return false
end

function TurretService.new(effectRemote: RemoteEvent, roundService: any, enemyService: any)
	local self = setmetatable({}, TurretService)
	self._effectRemote = effectRemote
	self._roundService = roundService
	self._enemyService = enemyService
	self._records = {} :: { [Model]: TurretRecord }
	self._ids = {} :: { [string]: Model }
	self._projectiles = {} :: { [string]: ProjectileRecord }
	self._connections = {} :: { RBXScriptConnection }
	self._perceptionAccumulator = 0
	self._projectileAccumulator = 0
	self._lastRoundPhase = roundService:GetPhase()
	return self
end

function TurretService:_getTargets(roster: { RosterEntry }): { TargetEntry }
	local targets = {}
	for _, entry in roster do
		table.insert(targets, {
			id = `player:{entry.player.UserId}`,
			team = entry.role,
			character = entry.character,
			humanoid = entry.humanoid,
			rootPart = entry.rootPart,
			userId = entry.player.UserId,
		})
	end
	for _, entry in self._enemyService:GetTargets() do
		table.insert(targets, {
			id = entry.id,
			team = entry.team,
			character = entry.character,
			humanoid = nil,
			rootPart = entry.rootPart,
			userId = entry.userId,
		})
	end
	return targets
end

function TurretService:_setPresentation(record: TurretRecord, state: string, team: string)
	local zone = record.captureZone
	if not zone then
		return
	end
	local colorKey = if state == TurretContract.State.Contested then "Contested" else team
	zone.Color = TEAM_COLORS[colorKey] or TEAM_COLORS.Neutral
	zone.Transparency = if state == TurretContract.State.Capturing then 0.48 else 0.72
end

function TurretService:_setCaptureState(
	record: TurretRecord,
	ownerTeam: string,
	state: string,
	captureTeam: string,
	progress: number
)
	local model = record.model
	record.captureTeam = captureTeam
	record.captureProgress = progress
	setAttributeIfChanged(model, TurretContract.Attribute.OwnerTeam, ownerTeam)
	setAttributeIfChanged(model, TurretContract.Attribute.CaptureState, state)
	setAttributeIfChanged(model, TurretContract.Attribute.CaptureTeam, captureTeam)
	setAttributeIfChanged(model, TurretContract.Attribute.CaptureProgress, progress)
	local presentationTeam = if state == TurretContract.State.Capturing
		then captureTeam
		else ownerTeam
	self:_setPresentation(record, state, presentationTeam)
end

function TurretService:_clearTarget(record: TurretRecord)
	if record.targetEntityId ~= "" then
		self._effectRemote:FireAllClients({
			phase = "CancelLock",
			turretId = record.model:GetAttribute(TurretContract.Attribute.Id),
		})
	end
	record.targetUserId = 0
	record.targetEntityId = ""
	record.targetAcquiredAt = 0
	setAttributeIfChanged(record.model, TurretContract.Attribute.TargetUserId, 0)
	setAttributeIfChanged(record.model, TurretContract.Attribute.TargetEntityId, "")
	setAttributeIfChanged(record.model, TurretContract.Attribute.AimActive, false)
	setAttributeIfChanged(
		record.model,
		TurretContract.Attribute.TargetingState,
		TurretContract.TargetingState.Idle
	)
end

function TurretService:_reset(record: TurretRecord)
	self:_clearTarget(record)
	record.lastShotAt = -math.huge
	record.shotSequence = 0
	self:_setCaptureState(
		record,
		TurretContract.NeutralTeam,
		TurretContract.State.Neutral,
		TurretContract.NeutralTeam,
		0
	)
	setAttributeIfChanged(record.model, TurretContract.Attribute.ShotSequence, 0)
end

function TurretService:_register(instance: Instance)
	if
		not instance:IsA("Model")
		or self._records[instance]
		or not instance:IsDescendantOf(workspace)
	then
		return
	end
	if self:GetRegisteredCount() >= Config.Turrets.MaximumActive then
		warn(`[TurretService] Turret cap reached; ignored {instance:GetFullName()}`)
		return
	end

	local turretId = instance:GetAttribute(TurretContract.Attribute.Id)
	local profile = TurretDefinitions.Get(instance:GetAttribute(TurretContract.Attribute.Archetype))
	local muzzle = instance:FindFirstChild("Muzzle", true)
	local captureZone = instance:FindFirstChild("CaptureZone", true)
	if
		type(turretId) ~= "string"
		or turretId == ""
		or self._ids[turretId]
		or not profile
		or not muzzle
		or not muzzle:IsA("BasePart")
		or not muzzle.Anchored
		or hasUnsafeUnanchoredPart(instance)
		or not readNumber(instance, TurretContract.Attribute.CaptureRadius, 1)
		or not readNumber(instance, TurretContract.Attribute.CaptureSeconds, 0.1)
	then
		warn(`[TurretService] Invalid or unsafe turret contract: {instance:GetFullName()}`)
		return
	end

	local record: TurretRecord = {
		model = instance,
		muzzle = muzzle,
		captureZone = if captureZone and captureZone:IsA("BasePart") then captureZone else nil,
		profile = profile,
		lastShotAt = -math.huge,
		shotSequence = 0,
		captureTeam = TurretContract.NeutralTeam,
		captureProgress = 0,
		targetUserId = 0,
		targetEntityId = "",
		targetAcquiredAt = 0,
	}
	self._records[instance] = record
	self._ids[turretId] = instance
	self:_reset(record)
end

function TurretService:_unregister(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local record = self._records[instance]
	if not record then
		return
	end
	self:_clearTarget(record)
	local turretId = instance:GetAttribute(TurretContract.Attribute.Id)
	if type(turretId) == "string" then
		self._ids[turretId] = nil
	end
	self._records[instance] = nil
	for projectileId, projectile in self._projectiles do
		if projectile.sourceModel == instance then
			self._projectiles[projectileId] = nil
			self._effectRemote:FireAllClients({ phase = "Expire", projectileId = projectileId })
		end
	end
end

function TurretService:_updateCapture(record: TurretRecord, roster: { RosterEntry }, dt: number)
	local model = record.model
	local radius = readNumber(model, TurretContract.Attribute.CaptureRadius, 1)
	local captureSeconds = readNumber(model, TurretContract.Attribute.CaptureSeconds, 0.1)
	if not radius or not captureSeconds then
		return
	end

	local centre = if record.captureZone
		then record.captureZone.Position
		else model:GetPivot().Position
	local humanPresent = false
	local kaijuPresent = false
	for _, entry in roster do
		local offset = entry.rootPart.Position - centre
		local horizontalDistance = Vector2.new(offset.X, offset.Z).Magnitude
		if
			horizontalDistance <= radius
			and math.abs(offset.Y) <= Config.Turrets.MaximumCaptureVerticalDistance
		then
			if entry.role == PlayerRole.Human then
				humanPresent = true
			else
				kaijuPresent = true
			end
		end
	end

	local ownerTeam = model:GetAttribute(TurretContract.Attribute.OwnerTeam)
	if not TurretContract.IsTeam(ownerTeam) then
		ownerTeam = TurretContract.NeutralTeam
	end
	if humanPresent and kaijuPresent then
		self:_setCaptureState(
			record,
			ownerTeam,
			TurretContract.State.Contested,
			TurretContract.NeutralTeam,
			record.captureProgress
		)
		return
	end

	local activeTeam = if humanPresent
		then PlayerRole.Human
		elseif kaijuPresent then PlayerRole.Kaiju
		else nil
	if not activeTeam then
		self:_setCaptureState(
			record,
			ownerTeam,
			if ownerTeam == TurretContract.NeutralTeam
				then TurretContract.State.Neutral
				else TurretContract.State.Owned,
			ownerTeam,
			if ownerTeam == TurretContract.NeutralTeam then 0 else 1
		)
		return
	end
	if activeTeam == ownerTeam then
		self:_setCaptureState(record, ownerTeam, TurretContract.State.Owned, ownerTeam, 1)
		return
	end

	if record.captureTeam ~= activeTeam then
		record.captureTeam = activeTeam
		record.captureProgress = 0
	end
	local progress = math.min(1, record.captureProgress + dt / captureSeconds)
	if progress >= 1 then
		self:_setCaptureState(record, activeTeam, TurretContract.State.Owned, activeTeam, 1)
	else
		self:_setCaptureState(
			record,
			ownerTeam,
			TurretContract.State.Capturing,
			activeTeam,
			progress
		)
	end
end

function TurretService:_hasLineOfSight(record: TurretRecord, entry: TargetEntry): (boolean, Vector3)
	local targetPosition = entry.rootPart.Position
	local origin = record.muzzle.Position
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { record.model }
	raycastParams.IgnoreWater = false
	local result = workspace:Raycast(origin, targetPosition - origin, raycastParams)
	return result == nil or result.Instance:IsDescendantOf(entry.character), targetPosition
end

function TurretService:_findTarget(
	record: TurretRecord,
	ownerTeam: string,
	targets: { TargetEntry }
): (TargetEntry?, Vector3?)
	local nearest = nil :: TargetEntry?
	local nearestTargetPosition = nil :: Vector3?
	local nearestDistance = math.huge
	for _, entry in targets do
		if entry.team ~= ownerTeam then
			local distance = (entry.rootPart.Position - record.muzzle.Position).Magnitude
			if distance <= record.profile.Range and distance < nearestDistance then
				local visible, targetPosition = self:_hasLineOfSight(record, entry)
				if visible then
					nearest = entry
					nearestTargetPosition = targetPosition
					nearestDistance = distance
				end
			end
		end
	end
	return nearest, nearestTargetPosition
end

function TurretService:_acquireTarget(
	record: TurretRecord,
	target: TargetEntry,
	targetPosition: Vector3,
	now: number
)
	record.targetUserId = target.userId
	record.targetEntityId = target.id
	record.targetAcquiredAt = now
	setAttributeIfChanged(record.model, TurretContract.Attribute.TargetUserId, target.userId)
	setAttributeIfChanged(
		record.model,
		TurretContract.Attribute.TargetEntityId,
		record.targetEntityId
	)
	setAttributeIfChanged(record.model, TurretContract.Attribute.AimActive, true)
	setAttributeIfChanged(record.model, TurretContract.Attribute.AimTargetPosition, targetPosition)
	setAttributeIfChanged(
		record.model,
		TurretContract.Attribute.TargetingState,
		TurretContract.TargetingState.Locking
	)
	self._effectRemote:FireAllClients({
		phase = "Lock",
		turretId = record.model:GetAttribute(TurretContract.Attribute.Id),
		effect = record.profile.Effect,
		ownerTeam = record.model:GetAttribute(TurretContract.Attribute.OwnerTeam),
		origin = record.muzzle.Position,
		targetUserId = target.userId,
		targetPosition = targetPosition,
		lockSeconds = record.profile.TargetLockSeconds,
	})
end

function TurretService:_damageTarget(target: TargetEntry, amount: number)
	if target.humanoid then
		target.humanoid:TakeDamage(amount)
	else
		self._enemyService:Damage(target.id, amount)
	end
end

function TurretService:_resolveHitscan(
	record: TurretRecord,
	ownerTeam: PlayerRole.Value,
	target: TargetEntry,
	targetPosition: Vector3
)
	local damage = if target.team == PlayerRole.Human
		then record.profile.HumanDamage
		else record.profile.KaijuDamage
	self:_damageTarget(target, damage)
	self._effectRemote:FireAllClients({
		phase = "Hitscan",
		turretId = record.model:GetAttribute(TurretContract.Attribute.Id),
		effect = record.profile.Effect,
		ownerTeam = ownerTeam,
		origin = record.muzzle.Position,
		target = targetPosition,
		sequence = record.shotSequence,
	})
end

function TurretService:_launchProjectile(
	record: TurretRecord,
	ownerTeam: PlayerRole.Value,
	targetPosition: Vector3,
	now: number
): boolean
	if self:GetActiveProjectileCount() >= Config.Turrets.MaximumActiveProjectiles then
		warn("[TurretService] Projectile cap reached; launch skipped")
		return false
	end
	local origin = record.muzzle.Position
	local offset = targetPosition - origin
	if offset.Magnitude < 0.1 then
		return false
	end
	local turretId = record.model:GetAttribute(TurretContract.Attribute.Id) :: string
	local projectileId = `{turretId}:{record.shotSequence}`
	local velocity = offset.Unit * record.profile.ProjectileSpeed
	self._projectiles[projectileId] = {
		id = projectileId,
		sourceModel = record.model,
		ownerTeam = ownerTeam,
		profile = record.profile,
		position = origin,
		velocity = velocity,
		expiresAt = now + record.profile.ProjectileLifetimeSeconds,
	}
	self._effectRemote:FireAllClients({
		phase = "Launch",
		projectileId = projectileId,
		turretId = turretId,
		effect = record.profile.Effect,
		ownerTeam = ownerTeam,
		origin = origin,
		velocity = velocity,
		lifetime = record.profile.ProjectileLifetimeSeconds,
		sequence = record.shotSequence,
	})
	return true
end

function TurretService:_tryFire(record: TurretRecord, targets: { TargetEntry }, now: number)
	local model = record.model
	local ownerTeam = model:GetAttribute(TurretContract.Attribute.OwnerTeam)
	local state = model:GetAttribute(TurretContract.Attribute.CaptureState)
	if
		(ownerTeam ~= PlayerRole.Human and ownerTeam ~= PlayerRole.Kaiju)
		or state ~= TurretContract.State.Owned
	then
		self:_clearTarget(record)
		return
	end

	local target, targetPosition = self:_findTarget(record, ownerTeam, targets)
	if not target or not targetPosition then
		self:_clearTarget(record)
		return
	end
	if target.id ~= record.targetEntityId then
		self:_acquireTarget(record, target, targetPosition, now)
		return
	end
	setAttributeIfChanged(record.model, TurretContract.Attribute.AimActive, true)
	setAttributeIfChanged(record.model, TurretContract.Attribute.AimTargetPosition, targetPosition)
	if now - record.targetAcquiredAt < record.profile.TargetLockSeconds then
		return
	end
	setAttributeIfChanged(
		model,
		TurretContract.Attribute.TargetingState,
		TurretContract.TargetingState.Tracking
	)
	if now - record.lastShotAt < record.profile.FireIntervalSeconds then
		return
	end

	record.shotSequence += 1
	local fired = true
	if record.profile.AttackKind == "Hitscan" then
		self:_resolveHitscan(record, ownerTeam, target, targetPosition)
	else
		fired = self:_launchProjectile(record, ownerTeam, targetPosition, now)
	end
	if fired then
		record.lastShotAt = now
		setAttributeIfChanged(model, TurretContract.Attribute.ShotSequence, record.shotSequence)
	else
		record.shotSequence -= 1
	end
end

function TurretService:_splashHasLineOfSight(
	projectile: ProjectileRecord,
	entry: TargetEntry,
	position: Vector3
): boolean
	local offset = entry.rootPart.Position - position
	if offset.Magnitude < 0.1 then
		return true
	end
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { projectile.sourceModel }
	raycastParams.IgnoreWater = false
	local origin = position + offset.Unit * 0.25
	local result = workspace:Raycast(origin, entry.rootPart.Position - origin, raycastParams)
	return result == nil or result.Instance:IsDescendantOf(entry.character)
end

function TurretService:_applyProjectileDamage(
	projectile: ProjectileRecord,
	position: Vector3,
	directHit: Instance?
)
	local targets = self:_getTargets(getRoster())
	for _, entry in targets do
		if entry.team ~= projectile.ownerTeam then
			local direct = directHit ~= nil and directHit:IsDescendantOf(entry.character)
			local distance = (entry.rootPart.Position - position).Magnitude
			if
				(direct or distance <= projectile.profile.ImpactRadius)
				and (direct or self:_splashHasLineOfSight(projectile, entry, position))
			then
				local baseDamage = if entry.team == PlayerRole.Human
					then projectile.profile.HumanDamage
					else projectile.profile.KaijuDamage
				local scale = if direct or projectile.profile.ImpactRadius <= 0
					then 1
					else math.max(0.35, 1 - 0.65 * distance / projectile.profile.ImpactRadius)
				self:_damageTarget(entry, baseDamage * scale)
			end
		end
	end
end

function TurretService:_finishProjectile(
	projectile: ProjectileRecord,
	phase: string,
	position: Vector3,
	directHit: Instance?
)
	self._projectiles[projectile.id] = nil
	if phase == "Impact" then
		self:_applyProjectileDamage(projectile, position, directHit)
	end
	self._effectRemote:FireAllClients({
		phase = phase,
		projectileId = projectile.id,
		effect = projectile.profile.Effect,
		ownerTeam = projectile.ownerTeam,
		position = position,
		radius = projectile.profile.ImpactRadius,
	})
end

function TurretService:_stepProjectiles(dt: number, now: number)
	for _, projectile in self._projectiles do
		if now >= projectile.expiresAt then
			self:_finishProjectile(projectile, "Expire", projectile.position, nil)
			continue
		end
		local displacement = projectile.velocity * dt
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { projectile.sourceModel }
		raycastParams.IgnoreWater = false
		local result = workspace:Raycast(projectile.position, displacement, raycastParams)
		if result then
			self:_finishProjectile(projectile, "Impact", result.Position, result.Instance)
		else
			projectile.position += displacement
		end
	end
end

function TurretService:_cancelAllProjectiles()
	for projectileId in self._projectiles do
		self._effectRemote:FireAllClients({ phase = "Expire", projectileId = projectileId })
	end
	table.clear(self._projectiles)
end

function TurretService:_handleRoundPhase(phase: string)
	if phase == self._lastRoundPhase then
		return
	end
	self._lastRoundPhase = phase
	if phase ~= "Active" then
		self:_cancelAllProjectiles()
		for _, record in self._records do
			self:_clearTarget(record)
		end
	end
	if phase == "Countdown" then
		for _, record in self._records do
			self:_reset(record)
		end
	end
end

function TurretService:_stepPerception(dt: number, now: number)
	local roster = getRoster()
	local targets = self:_getTargets(roster)
	for _, record in self._records do
		self:_updateCapture(record, roster, dt)
		self:_tryFire(record, targets, now)
	end
end

function TurretService:Start()
	for _, instance in CollectionService:GetTagged(TurretContract.Tag) do
		self:_register(instance)
	end
	table.insert(
		self._connections,
		CollectionService:GetInstanceAddedSignal(TurretContract.Tag):Connect(function(instance)
			self:_register(instance)
		end)
	)
	table.insert(
		self._connections,
		CollectionService:GetInstanceRemovedSignal(TurretContract.Tag):Connect(function(instance)
			self:_unregister(instance)
		end)
	)
	table.insert(
		self._connections,
		RunService.Heartbeat:Connect(function(dt)
			local now = os.clock()
			local phase = self._roundService:GetPhase()
			self:_handleRoundPhase(phase)
			if phase ~= "Active" then
				self._perceptionAccumulator = 0
				self._projectileAccumulator = 0
				return
			end

			self._perceptionAccumulator += dt
			if self._perceptionAccumulator >= Config.Turrets.SampleIntervalSeconds then
				local sampleDt = self._perceptionAccumulator
				self._perceptionAccumulator = 0
				self:_stepPerception(sampleDt, now)
			end

			if next(self._projectiles) == nil then
				self._projectileAccumulator = 0
				return
			end
			self._projectileAccumulator += dt
			local fixedDt = Config.Turrets.ProjectileSampleIntervalSeconds
			local steps = 0
			while self._projectileAccumulator >= fixedDt and steps < 4 do
				self._projectileAccumulator -= fixedDt
				self:_stepProjectiles(fixedDt, now)
				steps += 1
			end
		end)
	)
	print(`[TurretService] Registered {self:GetRegisteredCount()} capturable turrets`)
end

function TurretService:GetRegisteredCount(): number
	local count = 0
	for _ in self._records do
		count += 1
	end
	return count
end

function TurretService:GetActiveProjectileCount(): number
	local count = 0
	for _ in self._projectiles do
		count += 1
	end
	return count
end

function TurretService:Stop()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	self:_cancelAllProjectiles()
	table.clear(self._records)
	table.clear(self._ids)
end

return TurretService
