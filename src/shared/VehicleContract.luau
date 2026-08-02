--!strict

local VehicleContract = {}

VehicleContract.Tag = "CombatVehicle"

VehicleContract.Archetype = table.freeze({
	Tank = "Tank",
	Helicopter = "Helicopter",
})

VehicleContract.State = table.freeze({
	Advancing = "Advancing",
	Engaging = "Engaging",
	Defeated = "Defeated",
})

VehicleContract.Attack = table.freeze({
	CannonShell = "CannonShell",
	HelicopterBullet = "HelicopterBullet",
})

VehicleContract.Attribute = table.freeze({
	Id = "VehicleId",
	FactoryId = "SourceFactoryId",
	OwnerTeam = "OwnerTeam",
	Archetype = "VehicleArchetype",
	State = "VehicleState",
	Health = "VehicleHealth",
	MaxHealth = "VehicleMaxHealth",
	TargetUserId = "TargetUserId",
	TargetEntityId = "TargetEntityId",
	AimTargetPosition = "AimTargetPosition",
	AttackKind = "VehicleAttackKind",
	AttackSequence = "VehicleAttackSequence",
})

return table.freeze(VehicleContract)
