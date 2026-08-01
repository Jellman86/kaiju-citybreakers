--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local cameraController = CameraController.new()
local combatController = CombatController.new(abilityRequestRemote, abilityResultRemote)
local destructionController = DestructionController.new(destructionStateRemote)
local prototypeHudController = PrototypeHudController.new(roundController)

roundController:Start()
cameraController:Start()
combatController:Start()
destructionController:Start()
prototypeHudController:Start()

print("[Kaiju Citybreakers] Kaiju Feel Lab client started")
