--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AimController = require(script.Controllers.AimController)
local CameraController = require(script.Controllers.CameraController)
local CombatController = require(script.Controllers.CombatController)
local DestructionController = require(script.Controllers.DestructionController)
local PrototypeHudController = require(script.Controllers.PrototypeHudController)
local RoundController = require(script.Controllers.RoundController)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundStateRemote = remotes:WaitForChild("RoundState") :: RemoteEvent
local abilityRequestRemote = remotes:WaitForChild("AbilityRequest") :: RemoteEvent
local abilityResultRemote = remotes:WaitForChild("AbilityResult") :: RemoteEvent
local destructionStateRemote = remotes:WaitForChild("DestructionState") :: RemoteEvent

local roundController = RoundController.new(roundStateRemote)
local aimController = AimController.new()
local cameraController = CameraController.new()
local combatController = CombatController.new(abilityRequestRemote, abilityResultRemote)
local destructionController = DestructionController.new(destructionStateRemote)
local prototypeHudController = PrototypeHudController.new(roundController)

roundController:Start()
aimController:Start()
cameraController:Start()
combatController:Start()
destructionController:Start()
prototypeHudController:Start()

-- Never load Studio-only test dependencies in a live client. In particular,
-- this lets the HUD and controls start even though StudioTestService does not
-- exist in the Roblox app.
if RunService:IsStudio() then
	local MultiplayerDestructionRegression = require(script.Tests.MultiplayerDestructionRegression)
	MultiplayerDestructionRegression.TryStart(abilityRequestRemote, remotes)
end

print("[Kaiju Citybreakers] Kaiju Feel Lab client started")
