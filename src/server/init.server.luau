--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatService = require(script.Services.CombatService)
local DestructionService = require(script.Services.DestructionService)
local KaijuService = require(script.Services.KaijuService)
local PlaytestService = require(script.Services.PlaytestService)
local PrototypeWorldService = require(script.Services.PrototypeWorldService)
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
local abilityRequestRemote = getOrCreateRemoteEvent("AbilityRequest")
local abilityResultRemote = getOrCreateRemoteEvent("AbilityResult")
local destructionStateRemote = getOrCreateRemoteEvent("DestructionState")

local playtestService = PlaytestService.new()
local prototypeWorldService = PrototypeWorldService.new()
local roundService = RoundService.new(roundStateRemote)
local destructionService = DestructionService.new(
	destructionStateRemote,
	function(player, _structure, state)
		playtestService:RecordStructureState(player, state)
	end
)
local kaijuService = KaijuService.new(function(player)
	playtestService:MarkControlGranted(player)
end)
local combatService =
	CombatService.new(abilityRequestRemote, abilityResultRemote, destructionService, roundService)

playtestService:Start()
prototypeWorldService:Start()
destructionService:Start()
roundService:Start()
kaijuService:Start()
combatService:Start()

game:BindToClose(function()
	combatService:Stop()
	kaijuService:Stop()
	roundService:Stop()
	playtestService:Stop()
end)

print("[Kaiju Citybreakers] Kaiju Feel Lab server started")
