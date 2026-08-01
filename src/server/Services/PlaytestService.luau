--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

type DestructionState = Types.DestructionState

type TesterState = {
	ordinal: number,
	controlGrantedAt: number,
	firstHitRecorded: boolean,
	firstCollapseRecorded: boolean,
}

local PlaytestService = {}
PlaytestService.__index = PlaytestService

function PlaytestService.new()
	local self = setmetatable({}, PlaytestService)

	self._nextOrdinal = 1
	self._testers = {} :: { [Player]: TesterState }
	self._playerRemovingConnection = nil :: RBXScriptConnection?

	return self
end

function PlaytestService:Start()
	self._playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		self._testers[player] = nil
	end)
end

function PlaytestService:MarkControlGranted(player: Player)
	local existing = self._testers[player]
	if existing then
		existing.controlGrantedAt = os.clock()
		existing.firstHitRecorded = false
		existing.firstCollapseRecorded = false
		return
	end

	self._testers[player] = {
		ordinal = self._nextOrdinal,
		controlGrantedAt = os.clock(),
		firstHitRecorded = false,
		firstCollapseRecorded = false,
	}
	self._nextOrdinal += 1

	print(`[H1] ftue_control_granted tester={self._testers[player].ordinal}`)
end

function PlaytestService:RecordStructureState(player: Player, state: DestructionState)
	local tester = self._testers[player]
	if not tester then
		return
	end

	local elapsed = os.clock() - tester.controlGrantedAt

	if state == "Damaged" and not tester.firstHitRecorded then
		tester.firstHitRecorded = true
		print(
			("[H1] first_structure_hit tester=%d elapsed_seconds=%.2f"):format(
				tester.ordinal,
				elapsed
			)
		)
	end

	if state == "Collapsed" and not tester.firstCollapseRecorded then
		tester.firstCollapseRecorded = true
		print(
			("[H1] first_structure_collapsed tester=%d elapsed_seconds=%.2f target_seconds=60"):format(
				tester.ordinal,
				elapsed
			)
		)
	end
end

function PlaytestService:Stop()
	if self._playerRemovingConnection then
		self._playerRemovingConnection:Disconnect()
		self._playerRemovingConnection = nil
	end

	table.clear(self._testers)
end

return PlaytestService
