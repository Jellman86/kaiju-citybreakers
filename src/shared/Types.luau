--!strict

export type RoundPhase = "Waiting" | "Countdown" | "Active" | "Results"
export type DestructionState = "Intact" | "Damaged" | "Collapsed"
export type PlayerRole = "Kaiju" | "Human"

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
	sequence: number,
	position: Vector3,
	materialProfile: string,
}

return {}
