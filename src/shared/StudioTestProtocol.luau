--!strict

local StudioTestProtocol = {
	MultiplayerDestructionTest = "KaijuMultiplayerDestructionV1",
	RemoteName = "__StudioMultiplayerDestructionTest",
	TargetStructureId = "north_warehouse",
	ExistingClientStage = "existing_client",
	LateClientStage = "late_client",
}

return table.freeze(StudioTestProtocol)
