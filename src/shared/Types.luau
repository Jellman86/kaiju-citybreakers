--!strict

export type RoundPhase = "Waiting" | "Countdown" | "Active" | "Results"

export type RoundSnapshot = {
	phase: RoundPhase,
	serverNow: number,
	endsAt: number?,
	sequence: number,
}

return {}
