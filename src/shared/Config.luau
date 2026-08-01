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
		BasicAttackCooldownSeconds = 0.65,
		BasicAttackDamage = 1,
		BasicAttackHitboxSize = Vector3.new(30, 24, 26),
		BasicAttackForwardOffset = 13,
		MaximumStructuresPerAttack = 3,
		ChargeCooldownSeconds = 2.5,
		ChargeDurationSeconds = 0.6,
		ChargeVerticalVelocity = 2,
		ChargeImpactDamage = 2,
		ChargeImpactHitboxSize = Vector3.new(26, 24, 22),
		ChargeImpactForwardOffset = 11,
		MaximumChargeStructures = 4,
		BeamCooldownSeconds = 4,
		BeamDamage = 2,
		BeamRange = 180,
		BeamOriginHeight = 7,
	},

	Destruction = {
		MaximumCosmeticDebris = 100,
		CosmeticDebrisPrewarmCount = 10,
		CosmeticDebrisLifetimeSeconds = 5,
		FragmentsPerCollapse = 10,
		MaximumEffectDistance = 300,
	},

	StarterKaiju = {
		Id = "brontide",
		DisplayName = "Brontide",
		MaxHealth = 1000,
		WalkSpeed = 24,
		ChargeSpeed = 80,
		PrototypeScale = 4,
		CameraMinZoom = 24,
		CameraMaxZoom = 42,
		CameraFieldOfView = 67,
		CameraFocusHeight = 5,
		CameraPitchMinDegrees = -20,
		CameraPitchMaxDegrees = 35,
		CameraCollisionPadding = 0.75,
		CameraZoomStep = 3,
		MouseCameraSensitivity = 0.003,
	},

	Prototype = {
		WorldName = "KaijuFeelLab",
		WallStructureId = "feel_lab_wall",
		WallMaxHealth = 2,
		Structures = {
			Warehouse = {
				Id = "north_warehouse",
				MaxHealth = 3,
				EnergyValue = 15,
			},
			Tower = {
				Id = "north_tower",
				MaxHealth = 4,
				EnergyValue = 25,
			},
			Substation = {
				Id = "harbour_substation",
				MaxHealth = 3,
				EnergyValue = 20,
			},
		},
	},
}

return table.freeze(Config)
