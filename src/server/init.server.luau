--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- The release artifact has no authored SpawnLocation before this script builds
-- the runtime city. Keep characters unloaded until KaijuService can place them
-- on the generated spawn explicitly.
Players.CharacterAutoLoads = false

local CombatService = require(script.Services.CombatService)
local DestructionService = require(script.Services.DestructionService)
local EnemyService = require(script.Services.EnemyService)
local FactoryService = require(script.Services.FactoryService)
local KaijuService = require(script.Services.KaijuService)
local PlaytestService = require(script.Services.PlaytestService)
local PrototypeWorldService = require(script.Services.PrototypeWorldService)
local RoundService = require(script.Services.RoundService)
local TurretService = require(script.Services.TurretService)

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
local turretFiredRemote = getOrCreateRemoteEvent("TurretFired")

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
local enemyService = EnemyService.new(roundService)
local combatService = CombatService.new(
	abilityRequestRemote,
	abilityResultRemote,
	destructionService,
	roundService,
	enemyService
)
local factoryService = FactoryService.new(roundService, enemyService)
local turretService = TurretService.new(turretFiredRemote, roundService, enemyService)

playtestService:Start()
prototypeWorldService:Start()
destructionService:Start()
roundService:Start()
kaijuService:Start()
enemyService:Start()
factoryService:Start()
turretService:Start()
combatService:Start()

-- StudioTestService is unavailable to live experience servers. Keep the test
-- module completely outside the production bootstrap dependency graph so a
-- Studio-only API can never prevent the city or player character from loading.
if RunService:IsStudio() then
	local MultiplayerDestructionRegression = require(script.Tests.MultiplayerDestructionRegression)
	MultiplayerDestructionRegression.TryStart(roundService, remotes)
end

game:BindToClose(function()
	combatService:Stop()
	turretService:Stop()
	factoryService:Stop()
	enemyService:Stop()
	destructionService:Stop()
	kaijuService:Stop()
	roundService:Stop()
	playtestService:Stop()
end)

print("[Kaiju Citybreakers] Kaiju Feel Lab server started")
