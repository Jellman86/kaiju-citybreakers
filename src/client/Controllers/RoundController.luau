--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

type RoundSnapshot = Types.RoundSnapshot

local RoundController = {}
RoundController.__index = RoundController

function RoundController.new(roundStateRemote: RemoteEvent)
	local self = setmetatable({}, RoundController)

	self._roundStateRemote = roundStateRemote
	self._snapshot = nil :: RoundSnapshot?
	self._connection = nil :: RBXScriptConnection?

	return self
end

function RoundController:Start()
	if self._connection then
		return
	end

	self._connection = self._roundStateRemote.OnClientEvent:Connect(
		function(snapshot: RoundSnapshot)
			if self._snapshot and snapshot.sequence <= self._snapshot.sequence then
				return
			end

			self._snapshot = snapshot
			print(("[RoundController] Phase changed to %s"):format(snapshot.phase))
		end
	)
end

function RoundController:GetSnapshot(): RoundSnapshot?
	return self._snapshot
end

function RoundController:GetRemainingSeconds(): number
	local snapshot = self._snapshot
	if not snapshot or not snapshot.endsAt then
		return 0
	end

	return math.max(0, snapshot.endsAt - workspace:GetServerTimeNow())
end

function RoundController:Destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

return RoundController
