--!strict

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)

type AbilityResult = Types.AbilityResult

local ACTION_BASIC_ATTACK = "KaijuBasicAttack"
local ACTION_CHARGE = "KaijuCharge"

local CombatController = {}
CombatController.__index = CombatController

function CombatController.new(abilityRequestRemote: RemoteEvent, abilityResultRemote: RemoteEvent)
	local self = setmetatable({}, CombatController)

	self._abilityRequestRemote = abilityRequestRemote
	self._abilityResultRemote = abilityResultRemote
	self._sequence = 0
	self._lastRequestedAt = -math.huge
	self._lastChargeRequestedAt = -math.huge
	self._resultConnection = nil :: RBXScriptConnection?

	return self
end

function CombatController:_requestBasicAttack()
	local now = os.clock()
	if now - self._lastRequestedAt < Config.Combat.BasicAttackCooldownSeconds then
		return
	end

	self._lastRequestedAt = now
	self._sequence += 1
	self._abilityRequestRemote:FireServer({
		abilityId = "basic",
		sequence = self._sequence,
	})
end

function CombatController:_requestCharge()
	local now = os.clock()
	if now - self._lastChargeRequestedAt < Config.Combat.ChargeCooldownSeconds then
		return
	end

	self._lastChargeRequestedAt = now
	self._sequence += 1
	self._abilityRequestRemote:FireServer({
		abilityId = "charge",
		sequence = self._sequence,
	})
end

function CombatController:_pulseCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local outward = TweenService:Create(camera, TweenInfo.new(0.08), {
		FieldOfView = Config.StarterKaiju.CameraFieldOfView + 3,
	})
	local inward = TweenService:Create(camera, TweenInfo.new(0.18), {
		FieldOfView = Config.StarterKaiju.CameraFieldOfView,
	})
	outward:Play()
	outward.Completed:Once(function()
		inward:Play()
	end)
end

function CombatController:Start()
	ContextActionService:BindAction(ACTION_BASIC_ATTACK, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:_requestBasicAttack()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.E, Enum.KeyCode.ButtonR2)
	ContextActionService:SetTitle(ACTION_BASIC_ATTACK, "SMASH")
	ContextActionService:SetPosition(ACTION_BASIC_ATTACK, UDim2.fromScale(0.82, 0.72))
	ContextActionService:BindAction(ACTION_CHARGE, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:_requestCharge()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Q, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle(ACTION_CHARGE, "CHARGE")
	ContextActionService:SetPosition(ACTION_CHARGE, UDim2.fromScale(0.68, 0.77))

	self._resultConnection = self._abilityResultRemote.OnClientEvent:Connect(
		function(result: AbilityResult)
			if result.accepted and (result.hitCount > 0 or result.abilityId == "charge") then
				self:_pulseCamera()
			end
		end
	)
end

function CombatController:Destroy()
	ContextActionService:UnbindAction(ACTION_BASIC_ATTACK)
	ContextActionService:UnbindAction(ACTION_CHARGE)
	if self._resultConnection then
		self._resultConnection:Disconnect()
		self._resultConnection = nil
	end
end

return CombatController
