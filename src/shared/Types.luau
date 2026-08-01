--!strict

export type RoundPhase = "Waiting" | "Countdown" | "Active" | "Results"
export type DestructionState = "Intact" | "Damaged" | "Collapsed"

export type RoundSnapshot = {
	phase: RoundPhase,
	serverNow: number,
	endsAt: number?,
	sequence: number,
}

export type AbilityRequest = {
	abilityId: string,
	sequence: number,
}

export type AbilityResult = {
	accepted: boolean,
	abilityId: string,
	sequence: number,
	hitCount: number,
	reason: string?,
}

return {}
