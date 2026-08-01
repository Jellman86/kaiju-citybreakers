--!strict

local KAIJU_PROTOTYPE_SCALE = 10
local KAIJU_METRIC_SCALE = KAIJU_PROTOTYPE_SCALE / 4

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
		BasicAttackHitboxSize = Vector3.new(30, 24, 26) * KAIJU_METRIC_SCALE,
		BasicAttackForwardOffset = 13 * KAIJU_METRIC_SCALE,
		MaximumStructuresPerAttack = 3,
		ChargeCooldownSeconds = 2.5,
		ChargeDurationSeconds = 0.6,
		ChargeVerticalVelocity = 2,
		ChargeImpactDamage = 2,
		ChargeImpactHitboxSize = Vector3.new(26, 24, 22) * KAIJU_METRIC_SCALE,
		ChargeImpactForwardOffset = 11 * KAIJU_METRIC_SCALE,
		MaximumChargeStructures = 4,
		BeamCooldownSeconds = 4,
		BeamDamage = 2,
		BeamRange = 480,
		BeamOriginHeight = 18,
		BeamMouthForwardOffset = 6.5 * KAIJU_METRIC_SCALE,
		BeamMouthVerticalOffset = -1.1 * KAIJU_METRIC_SCALE,
		BeamCastRadius = 9 * KAIJU_METRIC_SCALE,
		BeamVisualSeconds = 0.45,
	},

	Destruction = {
		MaximumCosmeticDebris = 100,
		CosmeticDebrisPrewarmCount = 10,
		CosmeticDebrisLifetimeSeconds = 5,
		FragmentsPerCollapse = 10,
		MaximumEffectDistance = 600,
	},

	MixedScale = {
		Enabled = true,
		MaximumKaijuPlayers = 1,
		ProvisionalMinimumHeightRatio = 10,
		HumanScaleGeometryTag = "HumanScaleGeometry",
	},

	Human = {
		MaxHealth = 100,
		WalkSpeed = 16,
		CameraMinZoom = 6,
		CameraMaxZoom = 18,
		CameraFieldOfView = 70,
		CameraFocusHeight = 1.5,
		CameraPitchMinDegrees = -20,
		CameraPitchMaxDegrees = 35,
		CameraCollisionPadding = 0.5,
		CameraZoomStep = 2,
		MouseCameraSensitivity = 0.003,
	},

	StarterKaiju = {
		Id = "brontide",
		DisplayName = "Brontide",
		MaxHealth = 1000,
		WalkSpeed = 32,
		ChargeSpeed = 120,
		PrototypeScale = KAIJU_PROTOTYPE_SCALE,
		ShellReferenceScale = 4,
		CameraMinZoom = 58,
		CameraMaxZoom = 105,
		CameraFieldOfView = 67,
		CameraFocusHeight = 16,
		CameraPitchMinDegrees = -20,
		CameraPitchMaxDegrees = 35,
		CameraCollisionPadding = 1.5,
		CameraZoomStep = 6,
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
