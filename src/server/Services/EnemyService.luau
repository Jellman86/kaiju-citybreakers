--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local EnemyContract = require(ReplicatedStorage.Shared.EnemyContract)

export type Target = {
	id: string,
	team: string,
	character: Model,
	rootPart: BasePart,
	userId: number,
}

export type TargetProvider = {
	GetTargets: (self: any) -> { Target },
	Damage: (self: any, enemyId: string, amount: number) -> boolean,
}

type SensedTarget = {
	player: Player,
	character: Model,
	rootPart: BasePart,
	distance: number,
	position: Vector3,
}

type EnemyRecord = {
	id: string,
	model: Model,
	rootPart: BasePart,
	health: number,
	state: string,
	targetUserId: number,
	stateEndsAt: number,
	lastAttackAt: number,
	pendingAttack: string,
	attackSequence: number,
	enraged: boolean,
	staggerDamage: number,
	lastStaggerAt: number,
	rootGroundOffset: number,
	spawnPosition: Vector3,
	patrolIndex: number,
	patrolTarget: Vector3,
	lastKnownTargetPosition: Vector3,
	targetMemoryEndsAt: number,
	pathWaypoints: { PathWaypoint },
	pathIndex: number,
	lastPathAt: number,
	lastPathTarget: Vector3,
	forcePathRecompute: boolean,
	pathBlockedConnection: RBXScriptConnection?,
	lastProgressAt: number,
	lastProgressPosition: Vector3,
}

local PATROL_DIRECTIONS = table.freeze({
	Vector3.new(1, 0, 0),
	Vector3.new(0.35, 0, 0.94),
	Vector3.new(-0.8, 0, 0.6),
	Vector3.new(-0.7, 0, -0.72),
	Vector3.new(0.45, 0, -0.9),
})

local EnemyService = {}
EnemyService.__index = EnemyService

local function setAttributeIfChanged(instance: Instance, name: string, value: any)
	if instance:GetAttribute(name) ~= value then
		instance:SetAttribute(name, value)
	end
end

local function getRoot(model: Model): BasePart?
	local named = model:FindFirstChild("EnemyRoot", true)
	if named and named:IsA("BasePart") then
		return named
	end
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function prepareActor(model: Model): BasePart?
	local rootPart = getRoot(model)
	if not rootPart then
		return nil
	end
	model.PrimaryPart = rootPart
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			if descendant.Name == "AuthoringLabelHost" then
				descendant:Destroy()
			else
				descendant.Anchored = descendant == rootPart
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = true
				descendant.Massless = descendant ~= rootPart
			end
		end
	end
	return rootPart
end

local function livingCharacter(player: Player): (Model?, BasePart?)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if character and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return character, root
	end
	return nil, nil
end

function EnemyService.new(roundService: any)
	local self = setmetatable({}, EnemyService)
	self._roundService = roundService
	self._records = {} :: { [string]: EnemyRecord }
	self._heartbeat = nil :: RBXScriptConnection?
	self._templateSource = nil :: Model?
	self._accumulator = 0
	self._lastRoundPhase = roundService:GetPhase()
	self._targetProviders = {} :: { [string]: TargetProvider }
	return self
end

function EnemyService:RegisterTargetProvider(name: string, provider: TargetProvider)
	assert(name ~= "", "Target provider name cannot be empty")
	assert(self._targetProviders[name] == nil, `Target provider {name} is already registered`)
	self._targetProviders[name] = provider
end

function EnemyService:UnregisterTargetProvider(name: string)
	self._targetProviders[name] = nil
end

function EnemyService:_setState(record: EnemyRecord, state: string, stateEndsAt: number)
	record.state = state
	record.stateEndsAt = stateEndsAt
	setAttributeIfChanged(record.model, EnemyContract.Attribute.State, state)
	local highlight = record.model:FindFirstChild("AttackTelegraph")
	if highlight and highlight:IsA("Highlight") then
		highlight.Enabled = state == EnemyContract.State.Telegraphing
		highlight.FillColor = if record.pendingAttack == EnemyContract.Attack.Lunge
			then Color3.fromRGB(255, 55, 120)
			else Color3.fromRGB(255, 76, 48)
	end
end

function EnemyService:_setAttack(record: EnemyRecord, attackKind: string)
	record.pendingAttack = attackKind
	setAttributeIfChanged(record.model, EnemyContract.Attribute.AttackKind, attackKind)
end

function EnemyService:_clearPath(record: EnemyRecord)
	if record.pathBlockedConnection then
		record.pathBlockedConnection:Disconnect()
		record.pathBlockedConnection = nil
	end
	table.clear(record.pathWaypoints)
	record.pathIndex = 1
	record.forcePathRecompute = true
end

function EnemyService:_clearRuntimeActors()
	for _, record in self._records do
		self:_clearPath(record)
		record.model:Destroy()
	end
	table.clear(self._records)
	local world = workspace:FindFirstChild(Config.Prototype.WorldName)
	local folder = if world then world:FindFirstChild(EnemyContract.RuntimeFolderName) else nil
	if folder then
		folder:Destroy()
	end
end

function EnemyService:_spawnActors()
	self:_clearRuntimeActors()
	local world = workspace:FindFirstChild(Config.Prototype.WorldName)
	if not world then
		return
	end
	local templateFolder = world:FindFirstChild(EnemyContract.TemplateFolderName)
	local template = if templateFolder then templateFolder:FindFirstChildWhichIsA("Model") else nil
	if not self._templateSource and template then
		self._templateSource = template:Clone()
		self._templateSource.Parent = nil
	end
	local templateSource = self._templateSource
	if not templateSource or not templateFolder then
		warn("[EnemyService] No editable enemy template is present; enemy spawn skipped")
		return
	end
	local runtimeFolder = Instance.new("Folder")
	runtimeFolder.Name = EnemyContract.RuntimeFolderName
	runtimeFolder.Parent = world

	local spawns = CollectionService:GetTagged(EnemyContract.SpawnTag)
	local spawned = 0
	for _, spawn in spawns do
		if spawned >= Config.Enemies.MaximumActive then
			break
		end
		if not spawn:IsA("BasePart") or not spawn:IsDescendantOf(world) then
			continue
		end
		spawn.Transparency = 1
		local label = spawn:FindFirstChild("MarkerLabel")
		if label and label:IsA("BillboardGui") then
			label.Enabled = false
		end
		local model = templateSource:Clone()
		model.Name = `RogueKaiju{spawned + 1}`
		model.Parent = runtimeFolder
		local rootPart = prepareActor(model)
		if not rootPart then
			model:Destroy()
			continue
		end
		model:PivotTo(spawn.CFrame * CFrame.new(0, rootPart.Size.Y * 0.5, 0))
		local id = `rogue_kaiju_{spawned + 1}`
		local spawnPosition = rootPart.Position
		model:SetAttribute(EnemyContract.Attribute.Id, id)
		model:SetAttribute(EnemyContract.Attribute.Team, EnemyContract.RogueTeam)
		model:SetAttribute(EnemyContract.Attribute.Health, Config.Enemies.MaximumHealth)
		model:SetAttribute(EnemyContract.Attribute.MaxHealth, Config.Enemies.MaximumHealth)
		model:SetAttribute(EnemyContract.Attribute.TargetUserId, 0)
		model:SetAttribute(EnemyContract.Attribute.TargetPosition, spawnPosition)
		model:SetAttribute(EnemyContract.Attribute.AttackKind, EnemyContract.Attack.None)
		model:SetAttribute(EnemyContract.Attribute.AttackSequence, 0)
		model:SetAttribute(EnemyContract.Attribute.Enraged, false)
		CollectionService:AddTag(model, EnemyContract.Tag)
		local highlight = Instance.new("Highlight")
		highlight.Name = "AttackTelegraph"
		highlight.Adornee = model
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillColor = Color3.fromRGB(255, 76, 48)
		highlight.FillTransparency = 0.42
		highlight.OutlineColor = Color3.fromRGB(255, 225, 148)
		highlight.OutlineTransparency = 0.08
		highlight.Enabled = false
		highlight.Parent = model
		self._records[id] = {
			id = id,
			model = model,
			rootPart = rootPart,
			health = Config.Enemies.MaximumHealth,
			state = EnemyContract.State.Idle,
			targetUserId = 0,
			stateEndsAt = 0,
			lastAttackAt = -math.huge,
			pendingAttack = EnemyContract.Attack.None,
			attackSequence = 0,
			enraged = false,
			staggerDamage = 0,
			lastStaggerAt = -math.huge,
			rootGroundOffset = math.max(1, rootPart.Size.Y * 0.5),
			spawnPosition = spawnPosition,
			patrolIndex = 0,
			patrolTarget = spawnPosition,
			lastKnownTargetPosition = spawnPosition,
			targetMemoryEndsAt = 0,
			pathWaypoints = {},
			pathIndex = 1,
			lastPathAt = -math.huge,
			lastPathTarget = spawnPosition,
			forcePathRecompute = true,
			pathBlockedConnection = nil,
			lastProgressAt = os.clock(),
			lastProgressPosition = spawnPosition,
		}
		self:_setState(self._records[id], EnemyContract.State.Idle, 0)
		spawned += 1
	end
	for _, descendant in templateFolder:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanQuery = false
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = false
		end
	end
	print(`[EnemyService] Spawned {spawned} articulated rogue kaiju`)
end

function EnemyService:_hasLineOfSight(
	record: EnemyRecord,
	character: Model,
	root: BasePart
): boolean
	local origin = record.rootPart.Position + Vector3.yAxis * record.rootGroundOffset
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { record.model }
	raycastParams.IgnoreWater = true
	local result = workspace:Raycast(origin, root.Position - origin, raycastParams)
	return result == nil or result.Instance:IsDescendantOf(character)
end

function EnemyService:_canSense(
	record: EnemyRecord,
	character: Model,
	root: BasePart,
	distance: number
): boolean
	if distance <= Config.Enemies.HearingRange then
		return true
	end
	local horizontal = Vector3.new(
		root.Position.X - record.rootPart.Position.X,
		0,
		root.Position.Z - record.rootPart.Position.Z
	)
	if horizontal.Magnitude < 0.01 then
		return true
	end
	local forward = record.rootPart.CFrame.LookVector
	forward = Vector3.new(forward.X, 0, forward.Z)
	if forward.Magnitude < 0.01 then
		forward = Vector3.new(0, 0, -1)
	end
	local minimumDot = math.cos(math.rad(Config.Enemies.SightFieldOfViewDegrees * 0.5))
	if forward.Unit:Dot(horizontal.Unit) < minimumDot then
		return false
	end
	return self:_hasLineOfSight(record, character, root)
end

function EnemyService:_selectTarget(record: EnemyRecord): SensedTarget?
	local selected = nil :: SensedTarget?
	local selectedScore = math.huge
	for _, player in Players:GetPlayers() do
		local character, root = livingCharacter(player)
		if character and root then
			local distance = (root.Position - record.rootPart.Position).Magnitude
			if
				distance <= Config.Enemies.PerceptionRange
				and self:_canSense(record, character, root, distance)
			then
				local score = distance
				if player.UserId == record.targetUserId then
					score *= Config.Enemies.CurrentTargetScoreMultiplier
				end
				if score < selectedScore then
					selectedScore = score
					selected = {
						player = player,
						character = character,
						rootPart = root,
						distance = distance,
						position = root.Position,
					}
				end
			end
		end
	end
	return selected
end

function EnemyService:_groundedPosition(record: EnemyRecord, position: Vector3): Vector3
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { record.model }
	raycastParams.IgnoreWater = false
	local origin = position + Vector3.yAxis * Config.Enemies.GroundProbeHeight
	local result = workspace:Raycast(
		origin,
		-Vector3.yAxis * Config.Enemies.GroundProbeDistance,
		raycastParams
	)
	if result then
		return Vector3.new(position.X, result.Position.Y + record.rootGroundOffset, position.Z)
	end
	return position
end

function EnemyService:_recomputePath(record: EnemyRecord, targetPosition: Vector3, now: number)
	if record.pathBlockedConnection then
		record.pathBlockedConnection:Disconnect()
		record.pathBlockedConnection = nil
	end
	record.lastPathAt = now
	record.lastPathTarget = targetPosition
	record.forcePathRecompute = false
	local path = PathfindingService:CreatePath({
		AgentRadius = Config.Enemies.PathAgentRadius,
		AgentHeight = Config.Enemies.PathAgentHeight,
		AgentCanJump = false,
		AgentCanClimb = false,
		WaypointSpacing = Config.Enemies.PathWaypointSpacing,
	})
	local succeeded = pcall(function()
		path:ComputeAsync(record.rootPart.Position, targetPosition)
	end)
	if succeeded and path.Status == Enum.PathStatus.Success then
		record.pathWaypoints = path:GetWaypoints()
		record.pathIndex = math.min(2, #record.pathWaypoints)
		record.pathBlockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
			if blockedWaypointIndex >= record.pathIndex then
				record.forcePathRecompute = true
			end
		end)
	else
		record.pathWaypoints = {}
		record.pathIndex = 1
	end
end

function EnemyService:_moveToward(record: EnemyRecord, targetPosition: Vector3, dt: number)
	local now = os.clock()
	local targetMoved = (targetPosition - record.lastPathTarget).Magnitude
	if
		record.forcePathRecompute
		or now - record.lastPathAt >= Config.Enemies.PathRecomputeSeconds
		or targetMoved >= Config.Enemies.PathTargetMovementThreshold
		or record.pathIndex > #record.pathWaypoints
	then
		self:_recomputePath(record, targetPosition, now)
	end

	local movementTarget = targetPosition
	local waypoint = record.pathWaypoints[record.pathIndex]
	if waypoint then
		movementTarget = waypoint.Position
		if (movementTarget - record.rootPart.Position).Magnitude <= 5 then
			record.pathIndex += 1
			waypoint = record.pathWaypoints[record.pathIndex]
			if waypoint then
				movementTarget = waypoint.Position
			end
		end
	end
	local offset = movementTarget - record.rootPart.Position
	local horizontal = Vector3.new(offset.X, 0, offset.Z)
	if horizontal.Magnitude < 0.1 then
		return
	end
	local speed = Config.Enemies.MoveSpeed
	if record.enraged then
		speed *= Config.Enemies.EnragedMoveSpeedMultiplier
	end
	local step = math.min(horizontal.Magnitude, speed * dt)
	local position = record.rootPart.Position + horizontal.Unit * step
	position = self:_groundedPosition(record, position)
	record.model:PivotTo(CFrame.lookAt(position, position + horizontal.Unit))

	if now - record.lastProgressAt >= Config.Enemies.StuckSampleSeconds then
		local progress = (record.rootPart.Position - record.lastProgressPosition).Magnitude
		if progress < Config.Enemies.StuckDistanceThreshold then
			record.forcePathRecompute = true
		end
		record.lastProgressAt = now
		record.lastProgressPosition = record.rootPart.Position
	end
end

function EnemyService:_beginAttack(record: EnemyRecord, attackKind: string, now: number)
	self:_setAttack(record, attackKind)
	local telegraphSeconds = if attackKind == EnemyContract.Attack.Lunge
		then Config.Enemies.LungeTelegraphSeconds
		else Config.Enemies.AttackTelegraphSeconds
	self:_setState(record, EnemyContract.State.Telegraphing, now + telegraphSeconds)
end

function EnemyService:_resolveAttack(record: EnemyRecord, now: number)
	local player = Players:GetPlayerByUserId(record.targetUserId)
	local character = nil :: Model?
	local root = nil :: BasePart?
	if player then
		character, root = livingCharacter(player)
	end
	local attackKind = record.pendingAttack
	local recovery = Config.Enemies.AttackRecoverySeconds
	if attackKind == EnemyContract.Attack.Lunge then
		recovery = Config.Enemies.LungeRecoverySeconds
		if root then
			local offset = root.Position - record.rootPart.Position
			local horizontal = Vector3.new(offset.X, 0, offset.Z)
			if horizontal.Magnitude > 0.1 then
				local distance = math.min(Config.Enemies.LungeDistance, horizontal.Magnitude)
				local position = record.rootPart.Position + horizontal.Unit * distance
				position = self:_groundedPosition(record, position)
				record.model:PivotTo(CFrame.lookAt(position, position + horizontal.Unit))
			end
		end
	end
	if character and root then
		local damage = if attackKind == EnemyContract.Attack.Lunge
			then Config.Enemies.LungeDamage
			else Config.Enemies.AttackDamage
		local range = if attackKind == EnemyContract.Attack.Lunge
			then Config.Enemies.AttackRange * 1.45
			else Config.Enemies.AttackRange * 1.25
		if
			(root.Position - record.rootPart.Position).Magnitude <= range
			and self:_hasLineOfSight(record, character, root)
		then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:TakeDamage(damage)
			end
		end
	end
	record.lastAttackAt = now
	record.attackSequence += 1
	setAttributeIfChanged(
		record.model,
		EnemyContract.Attribute.AttackSequence,
		record.attackSequence
	)
	self:_setAttack(record, EnemyContract.Attack.None)
	if record.enraged then
		recovery *= Config.Enemies.EnragedRecoveryMultiplier
	end
	self:_setState(record, EnemyContract.State.Recovering, now + recovery)
end

function EnemyService:_advancePatrol(record: EnemyRecord)
	record.patrolIndex = record.patrolIndex % #PATROL_DIRECTIONS + 1
	record.patrolTarget = record.spawnPosition
		+ PATROL_DIRECTIONS[record.patrolIndex] * Config.Enemies.PatrolRadius
	record.forcePathRecompute = true
	setAttributeIfChanged(record.model, EnemyContract.Attribute.TargetPosition, record.patrolTarget)
end

function EnemyService:_stepRecord(record: EnemyRecord, dt: number, now: number)
	if record.health <= 0 then
		return
	end
	if record.state == EnemyContract.State.Staggered then
		if now < record.stateEndsAt then
			return
		end
		self:_setState(record, EnemyContract.State.Investigating, 0)
	end
	if record.state == EnemyContract.State.Telegraphing then
		if now >= record.stateEndsAt then
			self:_resolveAttack(record, now)
		end
		return
	end
	if record.state == EnemyContract.State.Recovering and now < record.stateEndsAt then
		return
	end

	local sensed = self:_selectTarget(record)
	if sensed then
		record.targetUserId = sensed.player.UserId
		record.lastKnownTargetPosition = sensed.position
		record.targetMemoryEndsAt = now + Config.Enemies.TargetMemorySeconds
		setAttributeIfChanged(
			record.model,
			EnemyContract.Attribute.TargetUserId,
			record.targetUserId
		)
		setAttributeIfChanged(record.model, EnemyContract.Attribute.TargetPosition, sensed.position)
		if sensed.distance <= Config.Enemies.AttackRange then
			self:_beginAttack(record, EnemyContract.Attack.Swipe, now)
		elseif sensed.distance <= Config.Enemies.LungeRange then
			self:_beginAttack(record, EnemyContract.Attack.Lunge, now)
		else
			self:_setState(record, EnemyContract.State.Chasing, 0)
			self:_moveToward(record, sensed.position, dt)
		end
		return
	end

	if record.targetUserId ~= 0 and now <= record.targetMemoryEndsAt then
		setAttributeIfChanged(
			record.model,
			EnemyContract.Attribute.TargetPosition,
			record.lastKnownTargetPosition
		)
		if
			(record.lastKnownTargetPosition - record.rootPart.Position).Magnitude
			<= Config.Enemies.PatrolArrivalDistance
		then
			record.targetMemoryEndsAt = 0
		else
			self:_setState(record, EnemyContract.State.Investigating, 0)
			self:_moveToward(record, record.lastKnownTargetPosition, dt)
			return
		end
	end

	if record.targetUserId ~= 0 then
		record.targetUserId = 0
		setAttributeIfChanged(record.model, EnemyContract.Attribute.TargetUserId, 0)
		self:_advancePatrol(record)
	end
	if record.state == EnemyContract.State.Idle and now < record.stateEndsAt then
		return
	end
	if record.patrolIndex == 0 then
		self:_advancePatrol(record)
	end
	if
		(record.patrolTarget - record.rootPart.Position).Magnitude
		<= Config.Enemies.PatrolArrivalDistance
	then
		self:_setState(record, EnemyContract.State.Idle, now + Config.Enemies.PatrolPauseSeconds)
		self:_advancePatrol(record)
		return
	end
	self:_setState(record, EnemyContract.State.Patrolling, 0)
	self:_moveToward(record, record.patrolTarget, dt)
end

function EnemyService:GetTargets(): { Target }
	local targets = {} :: { Target }
	for _, record in self._records do
		if record.health > 0 and record.model:IsDescendantOf(workspace) then
			table.insert(targets, {
				id = record.id,
				team = EnemyContract.RogueTeam,
				character = record.model,
				rootPart = record.rootPart,
				userId = 0,
			})
		end
	end
	for _, provider in self._targetProviders do
		for _, target in provider:GetTargets() do
			table.insert(targets, target)
		end
	end
	return targets
end

function EnemyService:Damage(enemyId: string, amount: number): boolean
	local record = self._records[enemyId]
	if amount <= 0 or amount ~= amount then
		return false
	end
	if not record then
		for _, provider in self._targetProviders do
			if provider:Damage(enemyId, amount) then
				return true
			end
		end
		return false
	end
	if record.health <= 0 then
		return false
	end
	local now = os.clock()
	record.health = math.max(0, record.health - amount)
	record.staggerDamage += amount
	setAttributeIfChanged(record.model, EnemyContract.Attribute.Health, record.health)
	local enraged = record.health > 0
		and record.health / Config.Enemies.MaximumHealth <= Config.Enemies.EnragedHealthFraction
	if enraged ~= record.enraged then
		record.enraged = enraged
		setAttributeIfChanged(record.model, EnemyContract.Attribute.Enraged, enraged)
	end
	if record.health <= 0 then
		self:_clearPath(record)
		self:_setAttack(record, EnemyContract.Attack.None)
		self:_setState(record, EnemyContract.State.Defeated, 0)
		CollectionService:RemoveTag(record.model, EnemyContract.Tag)
		for _, descendant in record.model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Transparency = math.max(descendant.Transparency, 0.65)
				descendant.CanQuery = false
			end
		end
	elseif
		record.staggerDamage >= Config.Enemies.StaggerDamageThreshold
		and now - record.lastStaggerAt >= Config.Enemies.StaggerCooldownSeconds
	then
		record.staggerDamage = 0
		record.lastStaggerAt = now
		self:_setAttack(record, EnemyContract.Attack.None)
		self:_setState(record, EnemyContract.State.Staggered, now + Config.Enemies.StaggerSeconds)
	end
	return true
end

function EnemyService:Start()
	self:_spawnActors()
	self._heartbeat = RunService.Heartbeat:Connect(function(dt)
		local phase = self._roundService:GetPhase()
		if phase ~= self._lastRoundPhase then
			self._lastRoundPhase = phase
			if phase == "Countdown" then
				self:_spawnActors()
			end
		end
		if phase ~= "Active" then
			self._accumulator = 0
			return
		end
		self._accumulator += dt
		if self._accumulator < Config.Enemies.SampleIntervalSeconds then
			return
		end
		local sampleDt = self._accumulator
		self._accumulator = 0
		local now = os.clock()
		for _, record in self._records do
			self:_stepRecord(record, sampleDt, now)
		end
	end)
end

function EnemyService:Stop()
	if self._heartbeat then
		self._heartbeat:Disconnect()
		self._heartbeat = nil
	end
	self:_clearRuntimeActors()
	if self._templateSource then
		self._templateSource:Destroy()
		self._templateSource = nil
	end
end

return EnemyService
