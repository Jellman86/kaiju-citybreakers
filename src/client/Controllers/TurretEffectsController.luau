--!strict

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local TurretContract = require(ReplicatedStorage.Shared.TurretContract)

type TracerEntry = {
	part: Part,
	generation: number,
}

type ProjectileEntry = {
	part: Part,
	trail: Trail,
	generation: number,
	activeId: string?,
	origin: Vector3,
	velocity: Vector3,
	startedAt: number,
	expiresAt: number,
}

type ImpactEntry = {
	part: Part,
	generation: number,
	tween: Tween?,
}

type LockEntry = {
	part: Part,
	activeTurretId: string?,
	targetUserId: number,
	origin: Vector3,
	targetPosition: Vector3,
	expiresAt: number,
}

type AimEntry = {
	model: Model,
	turretId: string?,
	origin: BasePart,
	visualMuzzle: BasePart?,
	rigRoot: BasePart?,
	yawMotor: Motor6D?,
	pitchMotor: Motor6D?,
	currentYaw: number,
	currentPitch: number,
	turntable: BasePart?,
	turntableLocal: CFrame?,
	barrels: { BasePart },
	muzzle: BasePart?,
	direction: Vector3,
	restDirection: Vector3,
}

local MAXIMUM_TRACERS = 24
local MAXIMUM_PROJECTILES = 16
local MAXIMUM_IMPACTS = 12
local MAXIMUM_LOCKS = 12

local TEAM_COLORS = table.freeze({
	Human = Color3.fromRGB(65, 190, 255),
	Kaiju = Color3.fromRGB(255, 102, 55),
})

local EFFECTS = table.freeze({
	Bullet = true,
	Minigun = true,
	CannonShell = true,
	Rocket = true,
})

local TurretEffectsController = {}
TurretEffectsController.__index = TurretEffectsController

local function preparePart(part: Part)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
end

local function createTracer(): Part
	local part = Instance.new("Part")
	part.Name = "TurretTracer"
	part.Material = Enum.Material.Neon
	preparePart(part)
	return part
end

local function createProjectile(): ProjectileEntry
	local part = Instance.new("Part")
	part.Name = "TurretProjectile"
	part.Material = Enum.Material.Neon
	preparePart(part)
	local rear = Instance.new("Attachment")
	rear.Name = "TrailRear"
	rear.Position = Vector3.new(0, 0, 1.4)
	rear.Parent = part
	local front = Instance.new("Attachment")
	front.Name = "TrailFront"
	front.Position = Vector3.new(0, 0, -1.4)
	front.Parent = part
	local trail = Instance.new("Trail")
	trail.Name = "ProjectileTrail"
	trail.Attachment0 = rear
	trail.Attachment1 = front
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = part
	return {
		part = part,
		trail = trail,
		generation = 0,
		activeId = nil,
		origin = Vector3.zero,
		velocity = Vector3.zero,
		startedAt = 0,
		expiresAt = 0,
	}
end

local function createImpact(): ImpactEntry
	local part = Instance.new("Part")
	part.Name = "TurretImpact"
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	preparePart(part)
	return { part = part, generation = 0, tween = nil }
end

local function createLock(): LockEntry
	local part = Instance.new("Part")
	part.Name = "TurretLockCue"
	part.Material = Enum.Material.Neon
	preparePart(part)
	return {
		part = part,
		activeTurretId = nil,
		targetUserId = 0,
		origin = Vector3.zero,
		targetPosition = Vector3.zero,
		expiresAt = 0,
	}
end

local function isFiniteVector3(value: any): boolean
	return typeof(value) == "Vector3"
		and value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
end

local function isValidTeam(value: any): boolean
	return value == "Human" or value == "Kaiju"
end

local function setLine(part: Part, origin: Vector3, target: Vector3, width: number)
	local direction = target - origin
	local length = direction.Magnitude
	if length < 0.1 or length > 700 then
		part.Parent = nil
		return
	end
	part.Size = Vector3.new(width, width, length)
	part.CFrame = CFrame.lookAt(origin:Lerp(target, 0.5), target)
	part.Parent = workspace
end

function TurretEffectsController.new(effectRemote: RemoteEvent)
	local self = setmetatable({}, TurretEffectsController)
	self._effectRemote = effectRemote
	self._tracers = {} :: { TracerEntry }
	self._projectiles = {} :: { ProjectileEntry }
	self._impacts = {} :: { ImpactEntry }
	self._locks = {} :: { LockEntry }
	self._projectileById = {} :: { [string]: ProjectileEntry }
	self._lockByTurretId = {} :: { [string]: LockEntry }
	self._aimByModel = {} :: { [Model]: AimEntry }
	self._aimByTurretId = {} :: { [string]: AimEntry }
	self._connections = {} :: { RBXScriptConnection }
	self._nextTracer = 1
	self._nextProjectile = 1
	self._nextImpact = 1
	self._nextLock = 1
	self._remoteConnection = nil :: RBXScriptConnection?
	self._renderConnection = nil :: RBXScriptConnection?
	for _ = 1, MAXIMUM_TRACERS do
		table.insert(self._tracers, { part = createTracer(), generation = 0 })
	end
	for _ = 1, MAXIMUM_PROJECTILES do
		table.insert(self._projectiles, createProjectile())
	end
	for _ = 1, MAXIMUM_IMPACTS do
		table.insert(self._impacts, createImpact())
	end
	for _ = 1, MAXIMUM_LOCKS do
		table.insert(self._locks, createLock())
	end
	return self
end

local function horizontalUnit(direction: Vector3, fallback: Vector3): Vector3
	local horizontal = Vector3.new(direction.X, 0, direction.Z)
	if horizontal.Magnitude < 0.001 then
		horizontal = Vector3.new(fallback.X, 0, fallback.Z)
	end
	if horizontal.Magnitude < 0.001 then
		return Vector3.new(0, 0, -1)
	end
	return horizontal.Unit
end

local function stepAngle(current: number, target: number, alpha: number): number
	local difference = math.atan2(math.sin(target - current), math.cos(target - current))
	return current + difference * alpha
end

function TurretEffectsController:_registerAim(instance: Instance)
	if not instance:IsA("Model") or self._aimByModel[instance] then
		return
	end
	local assembly = instance:FindFirstChild(TurretContract.Aim.AssemblyName)
	if not assembly then
		return
	end
	local origin = assembly:FindFirstChild(TurretContract.Aim.OriginName)
	if not origin or not origin:IsA("BasePart") then
		return
	end
	local barrels = {} :: { BasePart }
	for _, descendant in assembly:GetDescendants() do
		if
			descendant:IsA("BasePart")
			and string.sub(descendant.Name, 1, #TurretContract.Aim.BarrelPrefix)
				== TurretContract.Aim.BarrelPrefix
		then
			table.insert(barrels, descendant)
		end
	end
	if #barrels == 0 then
		return
	end
	local turntable = assembly:FindFirstChild(TurretContract.Aim.TurntableName)
	local muzzle = assembly:FindFirstChild(TurretContract.Aim.MuzzleName)
	local rig = instance:FindFirstChild(TurretContract.Rig.ModelName)
	local rigRoot = if rig then rig:FindFirstChild(TurretContract.Rig.RootName) else nil
	local yawMotor = if rig then rig:FindFirstChild(TurretContract.Rig.YawMotorName, true) else nil
	local pitchMotor = if rig
		then rig:FindFirstChild(TurretContract.Rig.PitchMotorName, true)
		else nil
	local visualMuzzle = if rig
		then rig:FindFirstChild(TurretContract.Rig.VisualMuzzleName, true)
		else nil
	local validRigRoot = if rigRoot and rigRoot:IsA("BasePart") then rigRoot else nil
	local validYawMotor = if yawMotor and yawMotor:IsA("Motor6D") then yawMotor else nil
	local validPitchMotor = if pitchMotor and pitchMotor:IsA("Motor6D") then pitchMotor else nil
	local validVisualMuzzle = if visualMuzzle and visualMuzzle:IsA("BasePart")
		then visualMuzzle
		else nil
	local turretId = instance:GetAttribute(TurretContract.Attribute.Id)
	turretId = if type(turretId) == "string" then turretId else nil
	local restDirection = if validRigRoot
		then validRigRoot.CFrame.LookVector
		else origin.CFrame.LookVector
	local entry = {
		model = instance,
		turretId = turretId,
		origin = origin,
		visualMuzzle = validVisualMuzzle,
		rigRoot = validRigRoot,
		yawMotor = validYawMotor,
		pitchMotor = validPitchMotor,
		currentYaw = 0,
		currentPitch = 0,
		turntable = if turntable and turntable:IsA("BasePart") then turntable else nil,
		turntableLocal = if turntable and turntable:IsA("BasePart")
			then origin.CFrame:ToObjectSpace(turntable.CFrame)
			else nil,
		barrels = barrels,
		muzzle = if muzzle and muzzle:IsA("BasePart") then muzzle else nil,
		direction = restDirection,
		restDirection = restDirection,
	}
	self._aimByModel[instance] = entry
	if turretId then
		self._aimByTurretId[turretId] = entry
	end
end

function TurretEffectsController:_unregisterAim(instance: Instance)
	if instance:IsA("Model") then
		local entry = self._aimByModel[instance]
		if entry and entry.turretId then
			self._aimByTurretId[entry.turretId] = nil
		end
		self._aimByModel[instance] = nil
	end
end

function TurretEffectsController:_visualOrigin(turretId: any, fallback: Vector3): Vector3
	if type(turretId) ~= "string" then
		return fallback
	end
	local entry = self._aimByTurretId[turretId]
	if entry and entry.visualMuzzle and entry.visualMuzzle:IsDescendantOf(workspace) then
		return entry.visualMuzzle.Position
	end
	return fallback
end

function TurretEffectsController:_renderAim(entry: AimEntry, dt: number)
	if not entry.model:IsDescendantOf(workspace) then
		self:_unregisterAim(entry.model)
		return
	end
	local targetPosition = entry.model:GetAttribute(TurretContract.Attribute.AimTargetPosition)
	local aimActive = entry.model:GetAttribute(TurretContract.Attribute.AimActive) == true
	local desired = entry.restDirection
	if aimActive and isFiniteVector3(targetPosition) then
		local sourcePosition = if entry.rigRoot
			then entry.rigRoot.Position
			else entry.origin.Position
		local offset = targetPosition - sourcePosition
		if offset.Magnitude >= 0.1 then
			desired = offset.Unit
		end
	end
	local alpha = 1 - math.exp(-8 * math.min(dt, 0.1))
	local blended = entry.direction:Lerp(desired, alpha)
	if blended.Magnitude >= 0.001 then
		entry.direction = blended.Unit
	end

	if entry.rigRoot and entry.yawMotor and entry.pitchMotor then
		local localDirection = entry.rigRoot.CFrame:VectorToObjectSpace(entry.direction)
		local horizontalMagnitude = Vector2.new(localDirection.X, localDirection.Z).Magnitude
		local desiredYaw = math.atan2(-localDirection.X, -localDirection.Z)
		local desiredPitch = math.atan2(localDirection.Y, math.max(0.001, horizontalMagnitude))
		desiredPitch = math.clamp(
			desiredPitch,
			math.rad(TurretContract.Rig.MinimumPitchDegrees),
			math.rad(TurretContract.Rig.MaximumPitchDegrees)
		)
		entry.currentYaw = stepAngle(entry.currentYaw, desiredYaw, alpha)
		entry.currentPitch += (desiredPitch - entry.currentPitch) * alpha
		entry.yawMotor.Transform = CFrame.Angles(0, entry.currentYaw, 0)
		entry.pitchMotor.Transform = CFrame.Angles(entry.currentPitch, 0, 0)
		return
	end

	local yawDirection = horizontalUnit(entry.direction, entry.restDirection)
	local yawFrame = CFrame.lookAt(entry.origin.Position, entry.origin.Position + yawDirection)
	if entry.turntable and entry.turntableLocal then
		entry.turntable.CFrame = yawFrame * entry.turntableLocal
	end
	local maximumLength = 0
	for _, barrel in entry.barrels do
		local offsetX = barrel:GetAttribute(TurretContract.Aim.OffsetXAttribute)
		local offsetY = barrel:GetAttribute(TurretContract.Aim.OffsetYAttribute)
		local length = barrel:GetAttribute(TurretContract.Aim.LengthAttribute)
		offsetX = if type(offsetX) == "number" then offsetX else 0
		offsetY = if type(offsetY) == "number" then offsetY else 0
		length = if type(length) == "number" and length > 0 then length else barrel.Size.Z
		maximumLength = math.max(maximumLength, length)
		local barrelStart = entry.origin.Position
			+ yawFrame.RightVector * offsetX
			+ Vector3.yAxis * offsetY
		local centre = barrelStart + entry.direction * (length * 0.5)
		barrel.CFrame = CFrame.lookAt(centre, centre + entry.direction)
	end
	if entry.muzzle then
		entry.muzzle.CFrame = CFrame.lookAt(
			entry.origin.Position + entry.direction * maximumLength,
			entry.origin.Position + entry.direction * (maximumLength + 1)
		)
	end
end

function TurretEffectsController:_cancelLock(turretId: any)
	if type(turretId) ~= "string" then
		return
	end
	local entry = self._lockByTurretId[turretId]
	if not entry then
		return
	end
	entry.part.Parent = nil
	entry.activeTurretId = nil
	self._lockByTurretId[turretId] = nil
end

function TurretEffectsController:_showLock(payload: any)
	local turretId = payload.turretId
	local effect = payload.effect
	local ownerTeam = payload.ownerTeam
	local origin = payload.origin
	local targetUserId = payload.targetUserId
	local targetPosition = payload.targetPosition
	local lockSeconds = payload.lockSeconds
	if
		type(turretId) ~= "string"
		or not EFFECTS[effect]
		or not isValidTeam(ownerTeam)
		or not isFiniteVector3(origin)
		or type(targetUserId) ~= "number"
		or not isFiniteVector3(targetPosition)
		or type(lockSeconds) ~= "number"
		or lockSeconds < 0.1
		or lockSeconds > 3
	then
		return
	end
	self:_cancelLock(turretId)
	local entry = self._locks[self._nextLock]
	self._nextLock = self._nextLock % #self._locks + 1
	if entry.activeTurretId then
		self._lockByTurretId[entry.activeTurretId] = nil
	end
	entry.activeTurretId = turretId
	entry.targetUserId = targetUserId
	entry.origin = origin
	entry.targetPosition = targetPosition
	entry.expiresAt = os.clock() + lockSeconds + 0.4
	entry.part.Color = if effect == "Rocket"
		then Color3.fromRGB(255, 70, 42)
		else TEAM_COLORS[ownerTeam]
	entry.part.Transparency = 0.62
	self._lockByTurretId[turretId] = entry
end

function TurretEffectsController:_showHitscan(payload: any)
	local origin = payload.origin
	local target = payload.target
	local effect = payload.effect
	local ownerTeam = payload.ownerTeam
	if
		not isFiniteVector3(origin)
		or not isFiniteVector3(target)
		or (effect ~= "Bullet" and effect ~= "Minigun")
		or not isValidTeam(ownerTeam)
	then
		return
	end
	self:_cancelLock(payload.turretId)
	local entry = self._tracers[self._nextTracer]
	self._nextTracer = self._nextTracer % #self._tracers + 1
	entry.generation += 1
	local generation = entry.generation
	local part = entry.part
	part.Color = if effect == "Minigun"
		then Color3.fromRGB(255, 239, 145)
		else TEAM_COLORS[ownerTeam]
	local width = if effect == "Minigun" then 0.14 else 0.34
	origin = self:_visualOrigin(payload.turretId, origin)
	setLine(part, origin, target, width)
	part.Transparency = if effect == "Minigun" then 0.15 else 0.06
	local lifetime = if effect == "Minigun" then 0.045 else 0.09
	task.delay(lifetime, function()
		if entry.generation == generation then
			part.Parent = nil
		end
	end)
end

function TurretEffectsController:_deactivateProjectile(entry: ProjectileEntry)
	if entry.activeId then
		self._projectileById[entry.activeId] = nil
	end
	entry.activeId = nil
	entry.trail.Enabled = false
	entry.part.Parent = nil
end

function TurretEffectsController:_launchProjectile(payload: any)
	local projectileId = payload.projectileId
	local effect = payload.effect
	local ownerTeam = payload.ownerTeam
	local origin = payload.origin
	local velocity = payload.velocity
	local lifetime = payload.lifetime
	if
		type(projectileId) ~= "string"
		or (effect ~= "CannonShell" and effect ~= "Rocket")
		or not isValidTeam(ownerTeam)
		or not isFiniteVector3(origin)
		or not isFiniteVector3(velocity)
		or velocity.Magnitude > 300
		or type(lifetime) ~= "number"
		or lifetime <= 0
		or lifetime > 4.1
	then
		return
	end
	self:_cancelLock(payload.turretId)
	local entry = self._projectiles[self._nextProjectile]
	self._nextProjectile = self._nextProjectile % #self._projectiles + 1
	self:_deactivateProjectile(entry)
	entry.generation += 1
	entry.activeId = projectileId
	entry.origin = self:_visualOrigin(payload.turretId, origin)
	entry.velocity = velocity
	entry.startedAt = os.clock()
	entry.expiresAt = entry.startedAt + lifetime + 0.35
	entry.part.Shape = if effect == "CannonShell" then Enum.PartType.Ball else Enum.PartType.Block
	entry.part.Size = if effect == "CannonShell"
		then Vector3.new(1.8, 1.8, 1.8)
		else Vector3.new(1.25, 1.25, 3.5)
	entry.part.Color = if effect == "CannonShell"
		then Color3.fromRGB(255, 195, 76)
		else Color3.fromRGB(255, 72, 38)
	entry.part.Transparency = 0.02
	entry.trail.Color = ColorSequence.new(entry.part.Color, TEAM_COLORS[ownerTeam])
	entry.trail.Lifetime = if effect == "CannonShell" then 0.16 else 0.38
	entry.trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, if effect == "CannonShell" then 0.55 else 1.1),
		NumberSequenceKeypoint.new(1, 0),
	})
	entry.trail.Enabled = true
	entry.part.CFrame = CFrame.lookAt(origin, origin + velocity)
	entry.part.Parent = workspace
	self._projectileById[projectileId] = entry
end

function TurretEffectsController:_showImpact(payload: any)
	local projectileId = payload.projectileId
	local effect = payload.effect
	local position = payload.position
	local radius = payload.radius
	if
		type(projectileId) ~= "string"
		or (effect ~= "CannonShell" and effect ~= "Rocket")
		or not isFiniteVector3(position)
		or type(radius) ~= "number"
		or radius < 0
		or radius > 30
	then
		return
	end
	local projectile = self._projectileById[projectileId]
	if projectile then
		self:_deactivateProjectile(projectile)
	end
	local entry = self._impacts[self._nextImpact]
	self._nextImpact = self._nextImpact % #self._impacts + 1
	entry.generation += 1
	if entry.tween then
		entry.tween:Cancel()
	end
	local part = entry.part
	part.Color = if effect == "Rocket"
		then Color3.fromRGB(255, 83, 38)
		else Color3.fromRGB(255, 202, 82)
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = CFrame.new(position)
	part.Transparency = 0.18
	part.Parent = workspace
	local visualRadius = math.max(3, radius)
	local duration = if effect == "Rocket" then 0.42 else 0.24
	local tween = TweenService:Create(
		part,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.one * visualRadius * 2, Transparency = 1 }
	)
	entry.tween = tween
	tween:Play()
	local generation = entry.generation
	task.delay(duration, function()
		if entry.generation == generation then
			part.Parent = nil
			entry.tween = nil
		end
	end)
end

function TurretEffectsController:_expireProjectile(payload: any)
	local projectileId = payload.projectileId
	if type(projectileId) ~= "string" then
		return
	end
	local entry = self._projectileById[projectileId]
	if entry then
		self:_deactivateProjectile(entry)
	end
end

function TurretEffectsController:_handle(payload: any)
	if type(payload) ~= "table" then
		return
	end
	if payload.phase == "Lock" then
		self:_showLock(payload)
	elseif payload.phase == "CancelLock" then
		self:_cancelLock(payload.turretId)
	elseif payload.phase == "Hitscan" then
		self:_showHitscan(payload)
	elseif payload.phase == "Launch" then
		self:_launchProjectile(payload)
	elseif payload.phase == "Impact" then
		self:_showImpact(payload)
	elseif payload.phase == "Expire" then
		self:_expireProjectile(payload)
	end
end

function TurretEffectsController:_render(now: number, dt: number)
	for _, entry in self._aimByModel do
		self:_renderAim(entry, dt)
	end
	for _, entry in self._projectiles do
		if entry.activeId then
			if now >= entry.expiresAt then
				self:_deactivateProjectile(entry)
			else
				local position = entry.origin + entry.velocity * (now - entry.startedAt)
				entry.part.CFrame = CFrame.lookAt(position, position + entry.velocity)
			end
		end
	end
	for _, entry in self._locks do
		if entry.activeTurretId then
			if now >= entry.expiresAt then
				self:_cancelLock(entry.activeTurretId)
			else
				local player = Players:GetPlayerByUserId(entry.targetUserId)
				local character = if player then player.Character else nil
				local rootPart = if character
					then character:FindFirstChild("HumanoidRootPart")
					else nil
				if rootPart and rootPart:IsA("BasePart") then
					local origin = self:_visualOrigin(entry.activeTurretId, entry.origin)
					setLine(entry.part, origin, rootPart.Position, 0.1)
				elseif entry.targetUserId == 0 then
					local origin = self:_visualOrigin(entry.activeTurretId, entry.origin)
					setLine(entry.part, origin, entry.targetPosition, 0.1)
				else
					entry.part.Parent = nil
				end
			end
		end
	end
end

function TurretEffectsController:Start()
	for _, instance in CollectionService:GetTagged(TurretContract.Tag) do
		self:_registerAim(instance)
	end
	table.insert(
		self._connections,
		CollectionService:GetInstanceAddedSignal(TurretContract.Tag):Connect(function(instance)
			self:_registerAim(instance)
		end)
	)
	table.insert(
		self._connections,
		CollectionService:GetInstanceRemovedSignal(TurretContract.Tag):Connect(function(instance)
			self:_unregisterAim(instance)
		end)
	)
	self._remoteConnection = self._effectRemote.OnClientEvent:Connect(function(payload)
		self:_handle(payload)
	end)
	self._renderConnection = RunService.RenderStepped:Connect(function(dt)
		self:_render(os.clock(), dt)
	end)
end

function TurretEffectsController:Destroy()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	if self._remoteConnection then
		self._remoteConnection:Disconnect()
		self._remoteConnection = nil
	end
	if self._renderConnection then
		self._renderConnection:Disconnect()
		self._renderConnection = nil
	end
	for _, entry in self._aimByModel do
		if entry.yawMotor then
			entry.yawMotor.Transform = CFrame.identity
		end
		if entry.pitchMotor then
			entry.pitchMotor.Transform = CFrame.identity
		end
	end
	table.clear(self._aimByModel)
	for _, entry in self._tracers do
		entry.part:Destroy()
	end
	for _, entry in self._projectiles do
		entry.part:Destroy()
	end
	for _, entry in self._impacts do
		if entry.tween then
			entry.tween:Cancel()
		end
		entry.part:Destroy()
	end
	for _, entry in self._locks do
		entry.part:Destroy()
	end
	table.clear(self._tracers)
	table.clear(self._projectiles)
	table.clear(self._impacts)
	table.clear(self._locks)
	table.clear(self._projectileById)
	table.clear(self._lockByTurretId)
	table.clear(self._aimByModel)
	table.clear(self._aimByTurretId)
end

return TurretEffectsController
