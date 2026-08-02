--!strict

local TurretContract = {}

TurretContract.Tag = "CapturableTurret"
TurretContract.NeutralTeam = "Neutral"

TurretContract.State = table.freeze({
	Neutral = "Neutral",
	Capturing = "Capturing",
	Contested = "Contested",
	Owned = "Owned",
})

TurretContract.Attribute = table.freeze({
	Id = "TurretId",
	Archetype = "TurretArchetype",
	OwnerTeam = "OwnerTeam",
	CaptureState = "CaptureState",
	CaptureTeam = "CaptureTeam",
	CaptureProgress = "CaptureProgress",
	CaptureRadius = "CaptureRadius",
	CaptureSeconds = "CaptureSeconds",
	TargetUserId = "TargetUserId",
	TargetEntityId = "TargetEntityId",
	TargetingState = "TargetingState",
	AimActive = "AimActive",
	AimTargetPosition = "AimTargetPosition",
	ShotSequence = "ShotSequence",
	FactoryId = "FactoryId",
})

TurretContract.Aim = table.freeze({
	AssemblyName = "AimAssembly",
	OriginName = "AimOrigin",
	TurntableName = "AimTurntable",
	BarrelPrefix = "AimBarrel",
	MuzzleName = "Muzzle",
	OffsetXAttribute = "AimOffsetX",
	OffsetYAttribute = "AimOffsetY",
	LengthAttribute = "AimLength",
})

TurretContract.Rig = table.freeze({
	ModelName = "TurretRig",
	RootName = "RigRoot",
	YawMotorName = "YawMotor",
	PitchMotorName = "PitchMotor",
	VisualMuzzleName = "VisualMuzzle",
	MinimumPitchDegrees = -12,
	MaximumPitchDegrees = 42,
})

TurretContract.TargetingState = table.freeze({
	Idle = "Idle",
	Locking = "Locking",
	Tracking = "Tracking",
})

function TurretContract.IsTeam(value: any): boolean
	return value == TurretContract.NeutralTeam or value == "Human" or value == "Kaiju"
end

return table.freeze(TurretContract)
