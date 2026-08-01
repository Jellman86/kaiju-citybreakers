--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)

type RoundPhase = Types.RoundPhase
type RoundSnapshot = Types.RoundSnapshot

local RoundService = {}
RoundService.__index = RoundService

function RoundService.new(roundStateRemote: RemoteEvent)
	local self = setmetatable({}, RoundService)

	self._roundStateRemote = roundStateRemote
	self._phase = "Waiting" :: RoundPhase
	self._endsAt = nil :: number?
	self._sequence = 0
	self._running = false
	self._playerAddedConnection = nil :: RBXScriptConnection?

	return self
end

function RoundService:_snapshot(): RoundSnapshot
	return {
		phase = self._phase,
		serverNow = workspace:GetServerTimeNow(),
		endsAt = self._endsAt,
		sequence = self._sequence,
	}
end

function RoundService:_sendToPlayer(player: Player)
	self._roundStateRemote:FireClient(player, self:_snapshot())
end

function RoundService:_setPhase(phase: RoundPhase, durationSeconds: number?)
	self._phase = phase
	self._sequence += 1

	if durationSeconds then
		self._endsAt = workspace:GetServerTimeNow() + durationSeconds
	else
		self._endsAt = nil
	end

	self._roundStateRemote:FireAllClients(self:_snapshot())
	print(("[RoundService] Phase %s (sequence %d)"):format(phase, self._sequence))
end

function RoundService:_waitForMinimumPlayers(): boolean
	self:_setPhase("Waiting", nil)

	while self._running and #Players:GetPlayers() < Config.Round.MinimumPlayers do
		task.wait(0.5)
	end

	return self._running
end

function RoundService:_runTimedPhase(phase: RoundPhase, durationSeconds: number): boolean
	self:_setPhase(phase, durationSeconds)

	local endsAt = self._endsAt
	assert(endsAt ~= nil, "Timed round phase must have an end timestamp")

	while self._running and workspace:GetServerTimeNow() < endsAt do
		task.wait(0.25)
	end

	return self._running
end

function RoundService:_runLoop()
	while self._running do
		if not self:_waitForMinimumPlayers() then
			break
		end

		if not self:_runTimedPhase("Countdown", Config.Round.CountdownSeconds) then
			break
		end

		if not self:_runTimedPhase("Active", Config.Round.ActiveSeconds) then
			break
		end

		if not self:_runTimedPhase("Results", Config.Round.ResultsSeconds) then
			break
		end
	end
end

function RoundService:Start()
	if self._running then
		return
	end

	self._running = true
	self._playerAddedConnection = Players.PlayerAdded:Connect(function(player)
		self:_sendToPlayer(player)
	end)

	for _, player in Players:GetPlayers() do
		self:_sendToPlayer(player)
	end

	task.spawn(function()
		self:_runLoop()
	end)
end

function RoundService:Stop()
	self._running = false

	if self._playerAddedConnection then
		self._playerAddedConnection:Disconnect()
		self._playerAddedConnection = nil
	end
end

return RoundService
