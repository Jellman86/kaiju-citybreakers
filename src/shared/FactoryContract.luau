--!strict

local FactoryContract = {}

FactoryContract.Tag = "ReinforcementFactory"
FactoryContract.RuntimeFolderName = "RuntimeReinforcements"

FactoryContract.Team = table.freeze({
	Enemy = "Enemy",
	Neutral = "Neutral",
	Human = "Human",
	Kaiju = "Kaiju",
})

FactoryContract.State = table.freeze({
	Operational = "Operational",
	Alerted = "Alerted",
	Disabled = "Disabled",
	Capturing = "Capturing",
	Contested = "Contested",
	Captured = "Captured",
	Destroyed = "Destroyed",
})

FactoryContract.SpawnProfile = table.freeze({
	Tank = "Tank",
	Helicopter = "Helicopter",
	Mixed = "Mixed",
})

FactoryContract.Attribute = table.freeze({
	Id = "FactoryId",
	OwnerTeam = "OwnerTeam",
	State = "FactoryState",
	LaneId = "LaneId",
	SpawnProfile = "SpawnProfile",
	SpawnInterval = "SpawnInterval",
	LinkedStructureId = "LinkedStructureId",
	ObjectiveId = "ObjectiveId",
	CaptureRadius = "CaptureRadius",
	CaptureSeconds = "CaptureSeconds",
	CaptureTeam = "CaptureTeam",
	CaptureProgress = "CaptureProgress",
	SpawnSequence = "SpawnSequence",
})

FactoryContract.Authoring = table.freeze({
	CaptureZoneName = "CaptureZone",
	TankSpawnName = "TankSpawn",
	HelicopterSpawnName = "HelicopterSpawn",
	GroundRouteName = "GroundRoute",
	AirRouteName = "AirRoute",
	NodePrefix = "Node",
})

function FactoryContract.IsTeam(value: any): boolean
	return value == FactoryContract.Team.Enemy
		or value == FactoryContract.Team.Neutral
		or value == FactoryContract.Team.Human
		or value == FactoryContract.Team.Kaiju
end

function FactoryContract.IsSpawnProfile(value: any): boolean
	return value == FactoryContract.SpawnProfile.Tank
		or value == FactoryContract.SpawnProfile.Helicopter
		or value == FactoryContract.SpawnProfile.Mixed
end

return table.freeze(FactoryContract)
