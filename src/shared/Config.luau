--!strict

local Config = {
	Round = {
		MinimumPlayers = 1,
		CountdownSeconds = 5,
		ActiveSeconds = 8 * 60,
		ResultsSeconds = 8,
	},

	Combat = {
		MaximumAimDistance = 250,
		AbilityRequestRatePerSecond = 8,
	},

	Destruction = {
		MaximumCosmeticDebris = 100,
		CosmeticDebrisLifetimeSeconds = 5,
	},

	StarterKaiju = {
		Id = "brontide",
		DisplayName = "Brontide",
		MaxHealth = 1000,
		WalkSpeed = 24,
		ChargeSpeed = 44,
	},
}

return table.freeze(Config)
