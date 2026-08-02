--!strict

local LocalizedDamage = {}

LocalizedDamage.ZoneCount = 24
LocalizedDamage.EmptyState = string.rep("-", LocalizedDamage.ZoneCount)

export type AttackType = "Smash" | "Charge" | "Beam"
export type SurfaceProfile = "Box" | "Cylinder"

local ATTACK_TO_CODE: { [AttackType]: string } = table.freeze({
	Smash = "S",
	Charge = "C",
	Beam = "B",
})

local CODE_TO_ATTACK: { [string]: AttackType } = table.freeze({
	S = "Smash",
	C = "Charge",
	B = "Beam",
})

local function resolveHeightBand(localY: number, halfHeight: number): number
	local normalized =
		math.clamp((localY + halfHeight) / math.max(halfHeight * 2, 0.001), 0, 0.999999)
	return math.floor(normalized * 3)
end

local function resolveHeight(halfHeight: number, band: number): number
	return -halfHeight + (band + 0.5) * ((halfHeight * 2) / 3)
end

function LocalizedDamage.IsAttackType(value: any): boolean
	return value == "Smash" or value == "Charge" or value == "Beam"
end

function LocalizedDamage.NormalizeSurfaceProfile(value: any): SurfaceProfile
	return if value == "Cylinder" then "Cylinder" else "Box"
end

function LocalizedDamage.NormalizeState(value: any): string
	if typeof(value) ~= "string" or #value ~= LocalizedDamage.ZoneCount then
		return LocalizedDamage.EmptyState
	end

	for index = 1, LocalizedDamage.ZoneCount do
		local code = string.sub(value, index, index)
		if code ~= "-" and CODE_TO_ATTACK[code] == nil then
			return LocalizedDamage.EmptyState
		end
	end
	return value
end

function LocalizedDamage.CountMarks(state: string): number
	local normalized = LocalizedDamage.NormalizeState(state)
	local count = 0
	for index = 1, LocalizedDamage.ZoneCount do
		if string.sub(normalized, index, index) ~= "-" then
			count += 1
		end
	end
	return count
end

function LocalizedDamage.GetAttackType(state: string, zoneIndex: number): AttackType?
	if zoneIndex % 1 ~= 0 or zoneIndex < 1 or zoneIndex > LocalizedDamage.ZoneCount then
		return nil
	end
	local normalized = LocalizedDamage.NormalizeState(state)
	return CODE_TO_ATTACK[string.sub(normalized, zoneIndex, zoneIndex)]
end

function LocalizedDamage.ApplyImpact(
	state: string,
	zoneIndex: number,
	attackType: AttackType,
	maximumMarks: number
): (string, boolean)
	local normalized = LocalizedDamage.NormalizeState(state)
	if
		zoneIndex % 1 ~= 0
		or zoneIndex < 1
		or zoneIndex > LocalizedDamage.ZoneCount
		or not LocalizedDamage.IsAttackType(attackType)
	then
		return normalized, false
	end

	local currentCode = string.sub(normalized, zoneIndex, zoneIndex)
	local nextCode = ATTACK_TO_CODE[attackType]
	if currentCode == nextCode then
		return normalized, false
	end
	if currentCode == "-" and LocalizedDamage.CountMarks(normalized) >= maximumMarks then
		return normalized, false
	end

	local nextState = string.sub(normalized, 1, zoneIndex - 1)
		.. nextCode
		.. string.sub(normalized, zoneIndex + 1)
	return nextState, true
end

function LocalizedDamage.ResolveImpactZone(
	hitbox: BasePart,
	surfaceProfile: SurfaceProfile,
	worldPosition: Vector3
): number
	local localPoint = hitbox.CFrame:PointToObjectSpace(worldPosition)
	local halfSize = hitbox.Size * 0.5
	local heightBand = resolveHeightBand(localPoint.Y, halfSize.Y)

	if surfaceProfile == "Cylinder" then
		local sectorSize = math.pi / 4
		local angle = math.atan2(localPoint.X, -localPoint.Z)
		local sector = math.floor(((angle + sectorSize * 0.5) % (math.pi * 2)) / sectorSize)
		return sector * 3 + heightBand + 1
	end

	local normalizedX = localPoint.X / math.max(halfSize.X, 0.001)
	local normalizedZ = localPoint.Z / math.max(halfSize.Z, 0.001)
	local side: number
	local tangent: number
	if math.abs(normalizedZ) >= math.abs(normalizedX) then
		side = if normalizedZ < 0 then 0 else 2
		tangent = normalizedX
	else
		side = if normalizedX > 0 then 1 else 3
		tangent = normalizedZ
	end
	local column = if tangent >= 0 then 1 else 0
	return side * 6 + heightBand * 2 + column + 1
end

function LocalizedDamage.ResolveZoneFrame(
	hitbox: BasePart,
	surfaceProfile: SurfaceProfile,
	zoneIndex: number
): (Vector3, Vector3)
	local safeIndex = math.clamp(math.floor(zoneIndex), 1, LocalizedDamage.ZoneCount) - 1
	local halfSize = hitbox.Size * 0.5
	local localPosition: Vector3
	local localNormal: Vector3

	if surfaceProfile == "Cylinder" then
		local sector = math.floor(safeIndex / 3)
		local heightBand = safeIndex % 3
		local angle = sector * (math.pi / 4)
		localPosition = Vector3.new(
			math.sin(angle) * halfSize.X,
			resolveHeight(halfSize.Y, heightBand),
			-math.cos(angle) * halfSize.Z
		)
		localNormal = Vector3.new(
			math.sin(angle) / math.max(halfSize.X, 0.001),
			0,
			-math.cos(angle) / math.max(halfSize.Z, 0.001)
		).Unit
	else
		local side = math.floor(safeIndex / 6)
		local withinSide = safeIndex % 6
		local heightBand = math.floor(withinSide / 2)
		local column = withinSide % 2
		local tangentSign = if column == 0 then -1 else 1
		local localY = resolveHeight(halfSize.Y, heightBand)
		if side == 0 then
			localPosition = Vector3.new(tangentSign * halfSize.X * 0.28, localY, -halfSize.Z)
			localNormal = Vector3.new(0, 0, -1)
		elseif side == 1 then
			localPosition = Vector3.new(halfSize.X, localY, tangentSign * halfSize.Z * 0.28)
			localNormal = Vector3.new(1, 0, 0)
		elseif side == 2 then
			localPosition = Vector3.new(tangentSign * halfSize.X * 0.28, localY, halfSize.Z)
			localNormal = Vector3.new(0, 0, 1)
		else
			localPosition = Vector3.new(-halfSize.X, localY, tangentSign * halfSize.Z * 0.28)
			localNormal = Vector3.new(-1, 0, 0)
		end
	end

	return hitbox.CFrame:PointToWorldSpace(localPosition),
		hitbox.CFrame:VectorToWorldSpace(localNormal).Unit
end

return table.freeze(LocalizedDamage)
