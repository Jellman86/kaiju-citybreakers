--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DestructibleContract = require(ReplicatedStorage.Shared.DestructibleContract)
local FactoryContract = require(ReplicatedStorage.Shared.FactoryContract)
local PlayerRole = require(ReplicatedStorage.Shared.PlayerRole)
local TurretContract = require(ReplicatedStorage.Shared.TurretContract)
local VehicleContract = require(ReplicatedStorage.Shared.VehicleContract)

type VehicleArchetype = "Tank" | "Helicopter"

type FactoryRecord = {
	model: Model,
	id: string,
	initialOwnerTeam: string,
	ownerTeam: string,
	state: string,
	spawnProfile: string,
	spawnInterval: number,
	captureRadius: number,
	captureSeconds: number,
	captureProgress: number,
	captureTeam: string,
	spawnSequence: number,
	nextSpawnAt: number,
	linkedStructure: Model?,
	captureZone: BasePart?,
	tankSpawn: BasePart?,
	helicopterSpawn: BasePart?,
	groundRoute: { BasePart },
	airRoute: { BasePart },
}

type VehicleRecord = {
	id: string,
	factoryId: string,
	model: Model,
	rootPart: BasePart,
	aimPart: BasePart?,
	archetype: VehicleArchetype,
	ownerTeam: string,
	health: number,
	maxHealth: number,
	route: { BasePart },
	routeIndex: number,
	lastShotAt: number,
	attackSequence: number,
}

type ProjectileRecord = {
	id: string,
	sourceModel: Model,
	visual: BasePart,
	position: Vector3,
	velocity: Vector3,
	damage: number,
	kind: string,
	expiresAt: number,
}

type PlayerTarget = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	rootPart: BasePart,
	distance: number,
}

local FactoryService = {}
FactoryService.__index = FactoryService

local function dictionaryCount(dictionary: { [any]: any }): number
	local count = 0
	for _ in dictionary do
		count += 1
	end
	return count
end

local function setAttributeIfChanged(instance: Instance, name: string, value: any)
	if instance:GetAttribute(name) ~= value then
		instance:SetAttribute(name, value)
	end
end

local function readNumber(
	instance: Instance,
	name: string,
	fallback: number,
	minimum: number
): number
	local value = instance:GetAttribute(name)
	if typeof(value) == "number" and value == value and value >= minimum then
		return value
	end
	return fallback
end

local function findNamedPart(model: Model, name: string): BasePart?
	local candidate = model:FindFirstChild(name, true)
	return if candidate and candidate:IsA("BasePart") then candidate else nil
end

local function collectRoute(model: Model, folderName: string): { BasePart }
	local folder = model:FindFirstChild(folderName, true)
	local route = {} :: { BasePart }
	if not folder then
		return route
	end
	for _, child in folder:GetChildren() do
		if
			child:IsA("BasePart")
			and string.find(child.Name, FactoryContract.Authoring.NodePrefix, 1, true) == 1
		then
			table.insert(route, child)
		end
	end
	table.sort(route, function(a, b)
		return a.Name < b.Name
	end)
	return route
end

local function hideAuthoringMarker(marker: BasePart?)
	if not marker then
		return
	end
	marker.Transparency = 1
	marker.CanCollide = false
	marker.CanTouch = false
	for _, descendant in marker:GetDescendants() do
		if descendant:IsA("BillboardGui") then
			descendant.Enabled = false
		end
	end
end

local function findLinkedStructure(structureId: string): Model?
	if structureId == "" then
		return nil
	end
	for _, instance in CollectionService:GetTagged(DestructibleContract.Tag) do
		if
			instance:IsA("Model")
			and instance:GetAttribute(DestructibleContract.Attribute.StructureId) == structureId
		then
			return instance
		end
	end
	return nil
end

local function getLivingPlayerTargets(origin: Vector3, range: number): { PlayerTarget }
	local targets = {} :: { PlayerTarget }
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if
			PlayerRole.Get(player)
			and character
			and humanoid
			and humanoid.Health > 0
			and rootPart
			and rootPart:IsA("BasePart")
		then
			local distance = (rootPart.Position - origin).Magnitude
			if distance <= range then
				table.insert(targets, {
					player = player,
					character = character,
					humanoid = humanoid,
					rootPart = rootPart,
					distance = distance,
				})
			end
		end
	end
	table.sort(targets, function(a, b)
		return a.distance < b.distance
	end)
	return targets
end

local function findPlayerFromPart(part: BasePart): (Player?, Humanoid?)
	local candidate: Instance? = part
	while candidate and candidate ~= workspace do
		if candidate:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(candidate)
			local humanoid = candidate:FindFirstChildOfClass("Humanoid")
			if player and humanoid then
				return player, humanoid
			end
		end
		candidate = candidate.Parent
	end
	return nil, nil
end

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.CastShadow = true
	part.Parent = parent
	return part
end

local function makeVehicleProxy(archetype: VehicleArchetype): (Model, BasePart, BasePart?)
	local model = Instance.new("Model")
	model.Name = `{archetype}Proxy`
	local root = makePart(
		model,
		"VehicleRoot",
		Vector3.new(1, 1, 1),
		Color3.new(),
		Enum.Material.SmoothPlastic
	)
	root.Transparency = 1
	local aimPart: BasePart? = nil
	if archetype == VehicleContract.Archetype.Tank then
		local hull = makePart(
			model,
			"Hull",
			Vector3.new(12, 4, 18),
			Color3.fromRGB(63, 83, 55),
			Enum.Material.Metal
		)
		hull.CFrame = CFrame.new(0, 2.5, 0)
		local tracksLeft = makePart(
			model,
			"LeftTrack",
			Vector3.new(3, 3, 20),
			Color3.fromRGB(32, 35, 32),
			Enum.Material.DiamondPlate
		)
		tracksLeft.CFrame = CFrame.new(-6, 1.5, 0)
		local tracksRight = tracksLeft:Clone()
		tracksRight.Name = "RightTrack"
		tracksRight.CFrame = CFrame.new(6, 1.5, 0)
		tracksRight.Parent = model
		local turret = makePart(
			model,
			"Turret",
			Vector3.new(7, 3, 8),
			Color3.fromRGB(72, 94, 61),
			Enum.Material.Metal
		)
		turret.CFrame = CFrame.new(0, 5.5, 0)
		local barrel = makePart(
			model,
			"Barrel",
			Vector3.new(1.4, 1.4, 12),
			Color3.fromRGB(48, 58, 45),
			Enum.Material.Metal
		)
		barrel.CFrame = CFrame.new(0, 5.7, -8)
		aimPart = turret
	else
		local body = makePart(
			model,
			"Fuselage",
			Vector3.new(8, 6, 17),
			Color3.fromRGB(54, 67, 75),
			Enum.Material.Metal
		)
		body.CFrame = CFrame.new(0, 0, 0)
		local tail = makePart(
			model,
			"Tail",
			Vector3.new(2.5, 2.5, 14),
			Color3.fromRGB(47, 58, 65),
			Enum.Material.Metal
		)
		tail.CFrame = CFrame.new(0, 1, 14)
		local rotor = makePart(
			model,
			"Rotor",
			Vector3.new(28, 0.35, 2),
			Color3.fromRGB(28, 31, 34),
			Enum.Material.Metal
		)
		rotor.CFrame = CFrame.new(0, 5, 0)
		local skids = makePart(
			model,
			"Skids",
			Vector3.new(10, 0.5, 12),
			Color3.fromRGB(28, 31, 34),
			Enum.Material.Metal
		)
		skids.CFrame = CFrame.new(0, -4, 1)
		aimPart = body
	end
	model.PrimaryPart = root
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = DestructibleContract.DamageHitboxCollisionGroup
		end
	end
	return model, root, aimPart
end

function FactoryService.new(roundService: any, enemyService: any)
	local self = setmetatable({}, FactoryService)
	self._roundService = roundService
	self._enemyService = enemyService
	self._factories = {} :: { [Model]: FactoryRecord }
	self._factoryIds = {} :: { [string]: Model }
	self._vehicles = {} :: { [string]: VehicleRecord }
	self._projectiles = {} :: { [string]: ProjectileRecord }
	self._connections = {} :: { RBXScriptConnection }
	self._heartbeat = nil :: RBXScriptConnection?
	self._accumulator = 0
	self._lastRoundPhase = roundService:GetPhase()
	self._runtimeFolder = nil :: Folder?
	return self
end

function FactoryService:_ensureRuntimeFolder(): Folder
	if self._runtimeFolder and self._runtimeFolder.Parent then
		return self._runtimeFolder
	end
	local folder = Instance.new("Folder")
	folder.Name = FactoryContract.RuntimeFolderName
	local world = workspace:FindFirstChild(Config.Prototype.WorldName)
	folder.Parent = world or workspace
	self._runtimeFolder = folder
	return folder
end

function FactoryService:_setFactoryState(record: FactoryRecord, state: string)
	record.state = state
	setAttributeIfChanged(record.model, FactoryContract.Attribute.State, state)
end

function FactoryService:_resetFactory(record: FactoryRecord)
	record.ownerTeam = record.initialOwnerTeam
	record.captureProgress = 0
	record.captureTeam = FactoryContract.Team.Neutral
	record.nextSpawnAt = os.clock() + 2
	setAttributeIfChanged(record.model, FactoryContract.Attribute.OwnerTeam, record.ownerTeam)
	setAttributeIfChanged(record.model, FactoryContract.Attribute.CaptureTeam, record.captureTeam)
	setAttributeIfChanged(record.model, FactoryContract.Attribute.CaptureProgress, 0)
	self:_setFactoryState(record, FactoryContract.State.Operational)
end

function FactoryService:_register(instance: Instance)
	if not instance:IsA("Model") or self._factories[instance] then
		return
	end
	if dictionaryCount(self._factoryIds) >= Config.Factories.MaximumActiveFactories then
		warn("[FactoryService] Factory cap reached; registration skipped")
		return
	end
	local id = instance:GetAttribute(FactoryContract.Attribute.Id)
	local ownerTeam = instance:GetAttribute(FactoryContract.Attribute.OwnerTeam)
	local spawnProfile = instance:GetAttribute(FactoryContract.Attribute.SpawnProfile)
	if
		type(id) ~= "string"
		or id == ""
		or self._factoryIds[id] ~= nil
		or not FactoryContract.IsTeam(ownerTeam)
		or not FactoryContract.IsSpawnProfile(spawnProfile)
	then
		warn(`[FactoryService] Rejected malformed or duplicate factory {instance:GetFullName()}`)
		return
	end
	local linkedStructureId = instance:GetAttribute(FactoryContract.Attribute.LinkedStructureId)
	local record: FactoryRecord = {
		model = instance,
		id = id,
		initialOwnerTeam = ownerTeam,
		ownerTeam = ownerTeam,
		state = FactoryContract.State.Operational,
		spawnProfile = spawnProfile,
		spawnInterval = readNumber(
			instance,
			FactoryContract.Attribute.SpawnInterval,
			Config.Factories.DefaultSpawnIntervalSeconds,
			Config.Factories.MinimumSpawnIntervalSeconds
		),
		captureRadius = readNumber(
			instance,
			FactoryContract.Attribute.CaptureRadius,
			Config.Factories.DefaultCaptureRadius,
			1
		),
		captureSeconds = readNumber(
			instance,
			FactoryContract.Attribute.CaptureSeconds,
			Config.Factories.DefaultCaptureSeconds,
			0.5
		),
		captureProgress = 0,
		captureTeam = FactoryContract.Team.Neutral,
		spawnSequence = 0,
		nextSpawnAt = os.clock() + 2,
		linkedStructure = if type(linkedStructureId) == "string"
			then findLinkedStructure(linkedStructureId)
			else nil,
		captureZone = findNamedPart(instance, FactoryContract.Authoring.CaptureZoneName),
		tankSpawn = findNamedPart(instance, FactoryContract.Authoring.TankSpawnName),
		helicopterSpawn = findNamedPart(instance, FactoryContract.Authoring.HelicopterSpawnName),
		groundRoute = collectRoute(instance, FactoryContract.Authoring.GroundRouteName),
		airRoute = collectRoute(instance, FactoryContract.Authoring.AirRouteName),
	}
	self._factories[instance] = record
	self._factoryIds[id] = instance
	hideAuthoringMarker(record.tankSpawn)
	hideAuthoringMarker(record.helicopterSpawn)
	for _, node in record.groundRoute do
		hideAuthoringMarker(node)
	end
	for _, node in record.airRoute do
		hideAuthoringMarker(node)
	end
	self:_resetFactory(record)
end

function FactoryService:_unregister(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local record = self._factories[instance]
	if not record then
		return
	end
	self._factories[instance] = nil
	self._factoryIds[record.id] = nil
end

function FactoryService:_captureNearbyTurrets(record: FactoryRecord, ownerTeam: string)
	for _, instance in CollectionService:GetTagged(TurretContract.Tag) do
		if
			instance:IsA("Model")
			and instance:GetAttribute(TurretContract.Attribute.FactoryId) == record.id
		then
			instance:SetAttribute(TurretContract.Attribute.OwnerTeam, ownerTeam)
			instance:SetAttribute(TurretContract.Attribute.CaptureState, TurretContract.State.Owned)
			instance:SetAttribute(TurretContract.Attribute.CaptureTeam, ownerTeam)
			instance:SetAttribute(TurretContract.Attribute.CaptureProgress, 1)
		end
	end
end

function FactoryService:_updateCapture(record: FactoryRecord, dt: number)
	if record.state == FactoryContract.State.Destroyed then
		return
	end
	local origin = if record.captureZone
		then record.captureZone.Position
		else record.model:GetPivot().Position
	local teams = {} :: { [string]: boolean }
	for _, target in getLivingPlayerTargets(origin, record.captureRadius) do
		if
			math.abs(target.rootPart.Position.Y - origin.Y)
			<= Config.Factories.MaximumCaptureVerticalDistance
		then
			local role = PlayerRole.Get(target.player)
			if role and role ~= record.ownerTeam then
				teams[role] = true
			end
		end
	end
	local capturingTeam: string? = nil
	local teamCount = 0
	for team in teams do
		capturingTeam = team
		teamCount += 1
	end
	if teamCount > 1 then
		self:_setFactoryState(record, FactoryContract.State.Contested)
		return
	end
	if not capturingTeam then
		record.captureProgress = math.max(0, record.captureProgress - dt / record.captureSeconds)
		if record.captureProgress == 0 then
			record.captureTeam = FactoryContract.Team.Neutral
			self:_setFactoryState(
				record,
				if record.ownerTeam == record.initialOwnerTeam
					then FactoryContract.State.Operational
					else FactoryContract.State.Captured
			)
		end
	else
		if record.captureTeam ~= capturingTeam then
			record.captureTeam = capturingTeam
			record.captureProgress = 0
		end
		record.captureProgress = math.min(1, record.captureProgress + dt / record.captureSeconds)
		self:_setFactoryState(record, FactoryContract.State.Capturing)
		if record.captureProgress >= 1 then
			record.ownerTeam = capturingTeam
			record.captureProgress = 0
			record.captureTeam = FactoryContract.Team.Neutral
			setAttributeIfChanged(
				record.model,
				FactoryContract.Attribute.OwnerTeam,
				record.ownerTeam
			)
			self:_setFactoryState(record, FactoryContract.State.Captured)
			self:_captureNearbyTurrets(record, record.ownerTeam)
		end
	end
	setAttributeIfChanged(record.model, FactoryContract.Attribute.CaptureTeam, record.captureTeam)
	setAttributeIfChanged(
		record.model,
		FactoryContract.Attribute.CaptureProgress,
		record.captureProgress
	)
end

function FactoryService:_countFactoryVehicles(
	factoryId: string,
	archetype: VehicleArchetype
): number
	local count = 0
	for _, vehicle in self._vehicles do
		if
			vehicle.factoryId == factoryId
			and vehicle.archetype == archetype
			and vehicle.health > 0
		then
			count += 1
		end
	end
	return count
end

function FactoryService:_spawnVehicle(record: FactoryRecord, archetype: VehicleArchetype): boolean
	local maximum = if archetype == VehicleContract.Archetype.Tank
		then Config.Factories.MaximumTanksPerFactory
		else Config.Factories.MaximumHelicoptersPerFactory
	if self:_countFactoryVehicles(record.id, archetype) >= maximum then
		return false
	end
	local spawn = if archetype == VehicleContract.Archetype.Tank
		then record.tankSpawn
		else record.helicopterSpawn
	if not spawn then
		warn(`[FactoryService] {record.id} has no {archetype} spawn marker`)
		return false
	end
	local model, rootPart, aimPart = makeVehicleProxy(archetype)
	record.spawnSequence += 1
	local id = `{record.id}:{string.lower(archetype)}:{record.spawnSequence}`
	model.Name = `{archetype}_{record.spawnSequence}`
	model.Parent = self:_ensureRuntimeFolder()
	model:PivotTo(spawn.CFrame)
	local maximumHealth = if archetype == VehicleContract.Archetype.Tank
		then Config.Factories.TankHealth
		else Config.Factories.HelicopterHealth
	model:SetAttribute(VehicleContract.Attribute.Id, id)
	model:SetAttribute(VehicleContract.Attribute.FactoryId, record.id)
	model:SetAttribute(VehicleContract.Attribute.OwnerTeam, record.ownerTeam)
	model:SetAttribute(VehicleContract.Attribute.Archetype, archetype)
	model:SetAttribute(VehicleContract.Attribute.State, VehicleContract.State.Advancing)
	model:SetAttribute(VehicleContract.Attribute.Health, maximumHealth)
	model:SetAttribute(VehicleContract.Attribute.MaxHealth, maximumHealth)
	model:SetAttribute(VehicleContract.Attribute.TargetUserId, 0)
	model:SetAttribute(VehicleContract.Attribute.AttackSequence, 0)
	CollectionService:AddTag(model, VehicleContract.Tag)
	self._vehicles[id] = {
		id = id,
		factoryId = record.id,
		model = model,
		rootPart = rootPart,
		aimPart = aimPart,
		archetype = archetype,
		ownerTeam = record.ownerTeam,
		health = maximumHealth,
		maxHealth = maximumHealth,
		route = if archetype == VehicleContract.Archetype.Tank
			then record.groundRoute
			else record.airRoute,
		routeIndex = 1,
		lastShotAt = -math.huge,
		attackSequence = 0,
	}
	setAttributeIfChanged(
		record.model,
		FactoryContract.Attribute.SpawnSequence,
		record.spawnSequence
	)
	return true
end

function FactoryService:_trySpawn(record: FactoryRecord, now: number)
	if
		record.ownerTeam ~= FactoryContract.Team.Enemy
		or record.state == FactoryContract.State.Destroyed
		or now < record.nextSpawnAt
	then
		return
	end
	record.nextSpawnAt = now + record.spawnInterval
	local archetype: VehicleArchetype
	if record.spawnProfile == FactoryContract.SpawnProfile.Tank then
		archetype = VehicleContract.Archetype.Tank
	elseif record.spawnProfile == FactoryContract.SpawnProfile.Helicopter then
		archetype = VehicleContract.Archetype.Helicopter
	else
		archetype = if record.spawnSequence % 3 == 2
			then VehicleContract.Archetype.Helicopter
			else VehicleContract.Archetype.Tank
	end
	self:_spawnVehicle(record, archetype)
end

function FactoryService:_moveVehicle(record: VehicleRecord, dt: number)
	if #record.route == 0 then
		return
	end
	local node = record.route[record.routeIndex]
	if not node or not node.Parent then
		return
	end
	local current = record.model:GetPivot()
	local target = node.Position
	if record.archetype == VehicleContract.Archetype.Tank then
		target = Vector3.new(target.X, current.Position.Y, target.Z)
	end
	local offset = target - current.Position
	if offset.Magnitude <= Config.Factories.RouteArrivalDistance then
		record.routeIndex = record.routeIndex % #record.route + 1
		return
	end
	local speed = if record.archetype == VehicleContract.Archetype.Tank
		then Config.Factories.TankMoveSpeed
		else Config.Factories.HelicopterMoveSpeed
	local distance = math.min(offset.Magnitude, speed * dt)
	local nextPosition = current.Position + offset.Unit * distance
	local flatDirection = Vector3.new(offset.X, 0, offset.Z)
	local lookDirection = if flatDirection.Magnitude > 0.01
		then flatDirection.Unit
		else current.LookVector
	record.model:PivotTo(CFrame.lookAt(nextPosition, nextPosition + lookDirection))
end

function FactoryService:_launchProjectile(record: VehicleRecord, target: PlayerTarget, now: number)
	if dictionaryCount(self._projectiles) >= Config.Factories.MaximumActiveProjectiles then
		return
	end
	local isTank = record.archetype == VehicleContract.Archetype.Tank
	local origin = record.rootPart.Position
		+ (if isTank then Vector3.new(0, 5.7, 0) else Vector3.new(0, -1, 0))
	local targetPosition = target.rootPart.Position
		+ target.rootPart.AssemblyLinearVelocity * (if isTank then 0.25 else 0.08)
	local offset = targetPosition - origin
	if offset.Magnitude < 1 then
		return
	end
	local speed = if isTank
		then Config.Factories.TankProjectileSpeed
		else Config.Factories.HelicopterProjectileSpeed
	local kind = if isTank
		then VehicleContract.Attack.CannonShell
		else VehicleContract.Attack.HelicopterBullet
	local visual = makePart(
		self:_ensureRuntimeFolder(),
		kind,
		if isTank then Vector3.new(2.4, 2.4, 2.4) else Vector3.new(0.45, 0.45, 3.5),
		if isTank then Color3.fromRGB(255, 112, 38) else Color3.fromRGB(255, 236, 92),
		Enum.Material.Neon
	)
	visual.CanQuery = false
	visual.Shape = if isTank then Enum.PartType.Ball else Enum.PartType.Block
	visual.CFrame = CFrame.lookAt(origin, targetPosition)
	record.attackSequence += 1
	local id = `{record.id}:shot:{record.attackSequence}`
	record.lastShotAt = now
	setAttributeIfChanged(record.model, VehicleContract.Attribute.AttackKind, kind)
	setAttributeIfChanged(
		record.model,
		VehicleContract.Attribute.AttackSequence,
		record.attackSequence
	)
	self._projectiles[id] = {
		id = id,
		sourceModel = record.model,
		visual = visual,
		position = origin,
		velocity = offset.Unit * speed,
		damage = if isTank then Config.Factories.TankDamage else Config.Factories.HelicopterDamage,
		kind = kind,
		expiresAt = now + (if isTank
			then Config.Factories.TankProjectileLifetimeSeconds
			else Config.Factories.HelicopterProjectileLifetimeSeconds),
	}
end

function FactoryService:_stepVehicle(record: VehicleRecord, dt: number, now: number)
	if record.health <= 0 or not record.model.Parent then
		return
	end
	local attackRange = if record.archetype == VehicleContract.Archetype.Tank
		then Config.Factories.TankAttackRange
		else Config.Factories.HelicopterAttackRange
	local targets = getLivingPlayerTargets(
		record.rootPart.Position,
		math.min(attackRange, Config.Factories.VehicleDetectionRange)
	)
	local target = targets[1]
	if target then
		setAttributeIfChanged(
			record.model,
			VehicleContract.Attribute.State,
			VehicleContract.State.Engaging
		)
		setAttributeIfChanged(
			record.model,
			VehicleContract.Attribute.TargetUserId,
			target.player.UserId
		)
		setAttributeIfChanged(
			record.model,
			VehicleContract.Attribute.AimTargetPosition,
			target.rootPart.Position
		)
		local flatDirection = Vector3.new(
			target.rootPart.Position.X - record.rootPart.Position.X,
			0,
			target.rootPart.Position.Z - record.rootPart.Position.Z
		)
		if record.aimPart and flatDirection.Magnitude > 0.01 then
			record.aimPart.CFrame =
				CFrame.lookAt(record.aimPart.Position, record.aimPart.Position + flatDirection.Unit)
		end
		local interval = if record.archetype == VehicleContract.Archetype.Tank
			then Config.Factories.TankFireIntervalSeconds
			else Config.Factories.HelicopterFireIntervalSeconds
		if now - record.lastShotAt >= interval then
			self:_launchProjectile(record, target, now)
		end
	else
		setAttributeIfChanged(
			record.model,
			VehicleContract.Attribute.State,
			VehicleContract.State.Advancing
		)
		setAttributeIfChanged(record.model, VehicleContract.Attribute.TargetUserId, 0)
		self:_moveVehicle(record, dt)
	end
end

function FactoryService:_finishProjectile(id: string, projectile: ProjectileRecord, hit: BasePart?)
	self._projectiles[id] = nil
	projectile.visual:Destroy()
	if not hit then
		return
	end
	local player, humanoid = findPlayerFromPart(hit)
	if player and humanoid and PlayerRole.Get(player) and humanoid.Health > 0 then
		humanoid:TakeDamage(projectile.damage)
	end
end

function FactoryService:_stepProjectiles(dt: number, now: number)
	for id, projectile in self._projectiles do
		if now >= projectile.expiresAt or not projectile.sourceModel.Parent then
			self:_finishProjectile(id, projectile, nil)
			continue
		end
		local displacement = projectile.velocity * dt
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { projectile.sourceModel, projectile.visual }
		params.IgnoreWater = false
		local result = workspace:Raycast(projectile.position, displacement, params)
		if result then
			self:_finishProjectile(id, projectile, result.Instance)
		else
			projectile.position += displacement
			projectile.visual.CFrame =
				CFrame.lookAt(projectile.position, projectile.position + projectile.velocity)
		end
	end
end

function FactoryService:GetTargets(): { any }
	local targets = {}
	for _, record in self._vehicles do
		if record.health > 0 and record.model:IsDescendantOf(workspace) then
			table.insert(targets, {
				id = record.id,
				team = record.ownerTeam,
				character = record.model,
				rootPart = record.rootPart,
				userId = 0,
			})
		end
	end
	return targets
end

function FactoryService:GetRegisteredFactoryCount(): number
	return dictionaryCount(self._factories)
end

function FactoryService:GetActiveVehicleCount(): number
	return dictionaryCount(self._vehicles)
end

function FactoryService:GetActiveProjectileCount(): number
	return dictionaryCount(self._projectiles)
end

function FactoryService:Damage(vehicleId: string, amount: number): boolean
	local record = self._vehicles[vehicleId]
	if not record or record.health <= 0 or amount <= 0 or amount ~= amount then
		return false
	end
	record.health = math.max(0, record.health - amount)
	setAttributeIfChanged(record.model, VehicleContract.Attribute.Health, record.health)
	if record.health <= 0 then
		setAttributeIfChanged(
			record.model,
			VehicleContract.Attribute.State,
			VehicleContract.State.Defeated
		)
		CollectionService:RemoveTag(record.model, VehicleContract.Tag)
		for _, descendant in record.model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CanQuery = false
				descendant.Transparency = math.max(descendant.Transparency, 0.55)
			end
		end
		task.delay(4, function()
			if self._vehicles[vehicleId] == record then
				self._vehicles[vehicleId] = nil
				record.model:Destroy()
			end
		end)
	end
	return true
end

function FactoryService:_clearRuntime()
	for id, projectile in self._projectiles do
		self._projectiles[id] = nil
		projectile.visual:Destroy()
	end
	for id, record in self._vehicles do
		self._vehicles[id] = nil
		record.model:Destroy()
	end
	if self._runtimeFolder then
		self._runtimeFolder:Destroy()
		self._runtimeFolder = nil
	end
end

function FactoryService:_step(dt: number, now: number)
	for _, record in self._factories do
		if
			record.linkedStructure
			and record.linkedStructure:GetAttribute(DestructibleContract.Attribute.State)
				== "Collapsed"
		then
			self:_setFactoryState(record, FactoryContract.State.Destroyed)
		else
			self:_updateCapture(record, dt)
			self:_trySpawn(record, now)
		end
	end
	for _, record in self._vehicles do
		self:_stepVehicle(record, dt, now)
	end
	self:_stepProjectiles(dt, now)
end

function FactoryService:Start()
	self._enemyService:RegisterTargetProvider("FactoryVehicles", self)
	for _, instance in CollectionService:GetTagged(FactoryContract.Tag) do
		self:_register(instance)
	end
	table.insert(
		self._connections,
		CollectionService:GetInstanceAddedSignal(FactoryContract.Tag):Connect(function(instance)
			self:_register(instance)
		end)
	)
	table.insert(
		self._connections,
		CollectionService:GetInstanceRemovedSignal(FactoryContract.Tag):Connect(function(instance)
			self:_unregister(instance)
		end)
	)
	self._heartbeat = RunService.Heartbeat:Connect(function(dt)
		local phase = self._roundService:GetPhase()
		if phase ~= self._lastRoundPhase then
			self._lastRoundPhase = phase
			if phase == "Countdown" then
				self:_clearRuntime()
				for _, record in self._factories do
					self:_resetFactory(record)
				end
			end
		end
		if phase ~= "Active" then
			self._accumulator = 0
			return
		end
		self._accumulator += dt
		if self._accumulator < Config.Factories.SampleIntervalSeconds then
			return
		end
		local sampleDt = self._accumulator
		self._accumulator = 0
		self:_step(sampleDt, os.clock())
	end)
end

function FactoryService:Stop()
	if self._heartbeat then
		self._heartbeat:Disconnect()
		self._heartbeat = nil
	end
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	self._enemyService:UnregisterTargetProvider("FactoryVehicles")
	self:_clearRuntime()
	table.clear(self._factories)
	table.clear(self._factoryIds)
end

return FactoryService
