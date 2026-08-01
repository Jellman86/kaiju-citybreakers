--!strict

export type Stats = {
	active: number,
	available: number,
	created: number,
	maximum: number,
	peakActive: number,
	recycled: number,
	spawned: number,
}

type Entry = {
	part: Part,
	generation: number,
	active: boolean,
	activationOrder: number,
}

local CosmeticDebrisPool = {}
CosmeticDebrisPool.__index = CosmeticDebrisPool

local function createPart(): Part
	local part = Instance.new("Part")
	part.Name = "CosmeticDebris"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	return part
end

local function deactivate(entry: Entry)
	local part = entry.part
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
	part.Anchored = true
	part.Transparency = 1
	part.Parent = nil
	entry.active = false
end

function CosmeticDebrisPool.new(maximumSize: number, prewarmSize: number)
	assert(maximumSize % 1 == 0 and maximumSize > 0, "maximumSize must be a positive integer")
	assert(
		prewarmSize % 1 == 0 and prewarmSize >= 0 and prewarmSize <= maximumSize,
		"prewarmSize must be an integer within the pool maximum"
	)

	local self = setmetatable({}, CosmeticDebrisPool)
	self._maximumSize = maximumSize
	self._entries = {} :: { Entry }
	self._available = {} :: { Entry }
	self._activeCount = 0
	self._activationOrder = 0
	self._peakActive = 0
	self._recycledCount = 0
	self._spawnCount = 0
	self._destroyed = false

	for _ = 1, prewarmSize do
		local entry = self:_createEntry()
		table.insert(self._available, entry)
	end

	return self
end

function CosmeticDebrisPool:_createEntry(): Entry
	assert(#self._entries < self._maximumSize, "pool maximum exceeded")
	local entry: Entry = {
		part = createPart(),
		generation = 0,
		active = false,
		activationOrder = 0,
	}
	table.insert(self._entries, entry)
	return entry
end

function CosmeticDebrisPool:_release(entry: Entry, generation: number)
	if self._destroyed or not entry.active or entry.generation ~= generation then
		return
	end

	deactivate(entry)
	self._activeCount -= 1
	table.insert(self._available, entry)
end

function CosmeticDebrisPool:_recycleOldest(): Entry?
	local oldestEntry = nil :: Entry?
	for _, entry in self._entries do
		if
			entry.active
			and (not oldestEntry or entry.activationOrder < oldestEntry.activationOrder)
		then
			oldestEntry = entry
		end
	end

	if not oldestEntry then
		return nil
	end

	self:_release(oldestEntry, oldestEntry.generation)
	self._recycledCount += 1
	return table.remove(self._available)
end

function CosmeticDebrisPool:_acquire(): Entry?
	local entry = table.remove(self._available)
	if entry then
		return entry
	end

	if #self._entries < self._maximumSize then
		return self:_createEntry()
	end

	return self:_recycleOldest()
end

function CosmeticDebrisPool:Spawn(
	cframe: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	linearVelocity: Vector3,
	angularVelocity: Vector3,
	lifetimeSeconds: number
): Part?
	if self._destroyed then
		return nil
	end

	local entry = self:_acquire()
	if not entry then
		return nil
	end

	entry.generation += 1
	entry.active = true
	self._activationOrder += 1
	entry.activationOrder = self._activationOrder
	self._activeCount += 1
	self._peakActive = math.max(self._peakActive, self._activeCount)
	self._spawnCount += 1

	local part = entry.part
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Transparency = 0
	part.Anchored = false
	part.Parent = workspace
	part.AssemblyLinearVelocity = linearVelocity
	part.AssemblyAngularVelocity = angularVelocity

	local generation = entry.generation
	task.delay(lifetimeSeconds, function()
		self:_release(entry, generation)
	end)

	return part
end

function CosmeticDebrisPool:GetStats(): Stats
	return {
		active = self._activeCount,
		available = #self._available,
		created = #self._entries,
		maximum = self._maximumSize,
		peakActive = self._peakActive,
		recycled = self._recycledCount,
		spawned = self._spawnCount,
	}
end

function CosmeticDebrisPool:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	for _, entry in self._entries do
		entry.active = false
		entry.part:Destroy()
	end
	table.clear(self._entries)
	table.clear(self._available)
	self._activeCount = 0
end

return CosmeticDebrisPool
