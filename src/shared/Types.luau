--!strict

export type RoundPhase = "Waiting" | "Countdown" | "Active" | "Results"
export type DestructionState = "Intact" | "Damaged" | "Collapsed"
export type PlayerRole = "Kaiju" | "Human"
export type DamageAttackType = "Smash" | "Charge" | "Beam"

export type StructureDamageContext = {
	attackType: DamageAttackType,
	position: Vector3,
	normal: Vector3?,
}

export type RoundSnapshot = {
	phase: RoundPhase,
	serverNow: number,
	endsAt: number?,
	sequence: number,
}

export type AbilityRequest = {
	abilityId: string,
	sequence: number,
	aimDirection: Vector3?,
}

export type AbilityResult = {
	accepted: boolean,
	abilityId: string,
	sequence: number,
	hitCount: number,
	reason: string?,
	effectOrigin: Vector3?,
	effectTarget: Vector3?,
}

export type DestructionEvent = {
	structureId: string,
	state: DestructionState,
	stateSequence: number,
	impactSequence: number,
	position: Vector3,
	normal: Vector3,
	attackType: DamageAttackType,
	zoneIndex: number,
	zoneState: string,
	materialProfile: string,
}

return {}
