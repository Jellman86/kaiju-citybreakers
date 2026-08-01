--!strict

local StudioTestProtocol = {
	MultiplayerDestructionTest = "KaijuSmashRuptureV4",
	RemoteName = "__StudioMultiplayerDestructionTest",
	TargetStructureId = "north_warehouse",
	LocalizedTargetStructureId = "arc_cooling_tower_west",
	LocalizedExistingStage = "localized_existing_client",
	LocalizedLateStage = "localized_late_client",
	ExistingClientStage = "existing_client",
	LateClientStage = "late_client",
}

return table.freeze(StudioTestProtocol)
