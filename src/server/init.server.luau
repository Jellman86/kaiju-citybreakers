--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundService = require(script.Services.RoundService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function getOrCreateRemoteEvent(name: string): RemoteEvent
	local existing = remotes:FindFirstChild(name)
	if existing then
		assert(existing:IsA("RemoteEvent"), `Remotes.{name} must be a RemoteEvent`)
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local roundStateRemote = getOrCreateRemoteEvent("RoundState")
local roundService = RoundService.new(roundStateRemote)

roundService:Start()

game:BindToClose(function()
	roundService:Stop()
end)

print("[Kaiju Citybreakers] Server foundation started")
