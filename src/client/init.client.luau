--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundController = require(script.Controllers.RoundController)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundStateRemote = remotes:WaitForChild("RoundState") :: RemoteEvent

local roundController = RoundController.new(roundStateRemote)
roundController:Start()

print("[Kaiju Citybreakers] Client foundation started")
