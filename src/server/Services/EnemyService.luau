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

type EnemyRecord = {
	id: string,
	model: Model,
	rootPart: BasePart,
	health: number,
	state: string,
	targetUserId: number,
	stateEndsAt: number,
	lastAttackAt: number,
	rootGroundOffset: number,
	pathWaypoints: { PathWaypoint },
	pathIndex: number,
	lastPathAt: number,
	lastPathTarget: Vector3,
}

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
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = true
		end
	end
	return rootPart
end

function EnemyService.new(roundService: any)
	local self = setmetatable({}, EnemyService)
	self._roundService = roundService
	self._records = {} :: { [string]: EnemyRecord }
	self._heartbeat = nil :: RBXScriptConnection?
	self._templateSource = nil :: Model?
	self._accumulator = 0
	self._lastRoundPhase = roundService:GetPhase()
	return self
end

function EnemyService:_setState(record: EnemyRecord, state: string, stateEndsAt: number)
	record.state = state
	record.stateEndsAt = stateEndsAt
	setAttributeIfChanged(record.model, EnemyContract.Attribute.State, state)
	local highlight = record.model:FindFirstChild("AttackTelegraph")
	if highlight and highlight:IsA("Highlight") then
		highlight.Enabled = state == EnemyContract.State.Telegraphing
	end
end

function EnemyService:_clearRuntimeActors()
	for _, record in self._records do
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
		model:SetAttribute(EnemyContract.Attribute.Id, id)
		model:SetAttribute(EnemyContract.Attribute.Team, EnemyContract.RogueTeam)
		model:SetAttribute(EnemyContract.Attribute.Health, Config.Enemies.MaximumHealth)
		model:SetAttribute(EnemyContract.Attribute.MaxHealth, Config.Enemies.MaximumHealth)
		model:SetAttribute(EnemyContract.Attribute.TargetUserId, 0)
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
			rootGroundOffset = math.max(1, rootPart.Size.Y * 0.5),
			pathWaypoints = {},
			pathIndex = 1,
			lastPathAt = -math.huge,
			lastPathTarget = spawn.Position,
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
	print(`[EnemyService] Spawned {spawned} editable-template rogue kaiju`)
end

function EnemyService:_nearestPlayer(record: EnemyRecord): (Player?, Model?, BasePart?, number)
	local nearestPlayer = nil :: Player?
	local nearestCharacter = nil :: Model?
	local nearestRoot = nil :: BasePart?
	local nearestDistance = math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			local distance = (root.Position - record.rootPart.Position).Magnitude
			if distance < nearestDistance and distance <= Config.Enemies.PerceptionRange then
				nearestPlayer = player
				nearestCharacter = character
				nearestRoot = root
				nearestDistance = distance
			end
		end
	end
	return nearestPlayer, nearestCharacter, nearestRoot, nearestDistance
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

function EnemyService:_moveToward(record: EnemyRecord, targetPosition: Vector3, dt: number)
	local now = os.clock()
	local targetMoved = (targetPosition - record.lastPathTarget).Magnitude
	if
		now - record.lastPathAt >= Config.Enemies.PathRecomputeSeconds
		or targetMoved >= Config.Enemies.PathTargetMovementThreshold
		or record.pathIndex > #record.pathWaypoints
	then
		record.lastPathAt = now
		record.lastPathTarget = targetPosition
		local path = PathfindingService:CreatePath({
			AgentRadius = 5,
			AgentHeight = 18,
			AgentCanJump = false,
			AgentCanClimb = false,
			WaypointSpacing = 10,
		})
		local succeeded = pcall(function()
			path:ComputeAsync(record.rootPart.Position, targetPosition)
		end)
		if succeeded and path.Status == Enum.PathStatus.Success then
			record.pathWaypoints = path:GetWaypoints()
			record.pathIndex = math.min(2, #record.pathWaypoints)
		else
			record.pathWaypoints = {}
			record.pathIndex = 1
		end
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
	local step = math.min(horizontal.Magnitude, Config.Enemies.MoveSpeed * dt)
	local position = record.rootPart.Position + horizontal.Unit * step
	position = self:_groundedPosition(record, position)
	record.model:PivotTo(CFrame.lookAt(position, position + horizontal.Unit))
end

function EnemyService:_attack(record: EnemyRecord, character: Model, now: number)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		self:_setState(record, EnemyContract.State.Idle, 0)
		return
	end
	if
		(root.Position - record.rootPart.Position).Magnitude
		<= Config.Enemies.AttackRange * 1.25
	then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { record.model }
		raycastParams.IgnoreWater = true
		local result = workspace:Raycast(
			record.rootPart.Position,
			root.Position - record.rootPart.Position,
			raycastParams
		)
		if not result or result.Instance:IsDescendantOf(character) then
			humanoid:TakeDamage(Config.Enemies.AttackDamage)
		end
	end
	record.lastAttackAt = now
	self:_setState(
		record,
		EnemyContract.State.Recovering,
		now + Config.Enemies.AttackRecoverySeconds
	)
end

function EnemyService:_stepRecord(record: EnemyRecord, dt: number, now: number)
	if record.health <= 0 then
		return
	end
	local player, character, root, distance = self:_nearestPlayer(record)
	local userId = if player then player.UserId else 0
	record.targetUserId = userId
	setAttributeIfChanged(record.model, EnemyContract.Attribute.TargetUserId, userId)
	if not player or not character or not root then
		self:_setState(record, EnemyContract.State.Idle, 0)
		return
	end
	if record.state == EnemyContract.State.Telegraphing then
		if now >= record.stateEndsAt then
			self:_attack(record, character, now)
		end
		return
	end
	if record.state == EnemyContract.State.Recovering and now < record.stateEndsAt then
		return
	end
	if distance <= Config.Enemies.AttackRange then
		self:_setState(
			record,
			EnemyContract.State.Telegraphing,
			now + Config.Enemies.AttackTelegraphSeconds
		)
		return
	end
	self:_setState(record, EnemyContract.State.Chasing, 0)
	self:_moveToward(record, root.Position, dt)
end

function EnemyService:GetTargets(): { Target }
	local targets = {}
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
	return targets
end

function EnemyService:Damage(enemyId: string, amount: number): boolean
	local record = self._records[enemyId]
	if not record or record.health <= 0 or amount <= 0 or amount ~= amount then
		return false
	end
	record.health = math.max(0, record.health - amount)
	setAttributeIfChanged(record.model, EnemyContract.Attribute.Health, record.health)
	if record.health <= 0 then
		self:_setState(record, EnemyContract.State.Defeated, 0)
		CollectionService:RemoveTag(record.model, EnemyContract.Tag)
		for _, descendant in record.model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Transparency = math.max(descendant.Transparency, 0.65)
				descendant.CanQuery = false
			end
		end
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
