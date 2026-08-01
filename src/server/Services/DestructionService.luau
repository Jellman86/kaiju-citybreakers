--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

type DestructionState = Types.DestructionState
type StateCallback = (player: Player, structure: Model, state: DestructionState) -> ()

local DestructionService = {}
DestructionService.__index = DestructionService

local function setVariantVisible(variant: Model, visible: boolean)
	for _, descendant in variant:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if visible then 0 else 1
			descendant.CanCollide = visible
			descendant.CanTouch = visible
			descendant.CanQuery = visible
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = visible
		end
	end
end

function DestructionService.new(destructionStateRemote: RemoteEvent, onStateChanged: StateCallback)
	local self = setmetatable({}, DestructionService)

	self._destructionStateRemote = destructionStateRemote
	self._onStateChanged = onStateChanged

	return self
end

function DestructionService:_applyState(structure: Model, state: DestructionState)
	for _, variantName in { "Intact", "Damaged", "Collapsed" } do
		local variant = structure:FindFirstChild(variantName)
		assert(
			variant and variant:IsA("Model"),
			`{structure:GetFullName()} is missing Model {variantName}`
		)
		setVariantVisible(variant, variantName == state)
	end

	structure:SetAttribute("DestructionState", state)
end

function DestructionService:Start()
	for _, tagged in CollectionService:GetTagged("Destructible") do
		if tagged:IsA("Model") then
			self:_applyState(tagged, "Intact")
		end
	end
end

function DestructionService:Damage(player: Player, structure: Model, amount: number): boolean
	if not CollectionService:HasTag(structure, "Destructible") then
		return false
	end

	local currentState = structure:GetAttribute("DestructionState")
	if currentState == "Collapsed" then
		return false
	end

	local maxHealth = structure:GetAttribute("MaxHealth")
	local currentHealth = structure:GetAttribute("CurrentHealth")
	if typeof(maxHealth) ~= "number" or typeof(currentHealth) ~= "number" then
		warn(`Invalid destructible health attributes on {structure:GetFullName()}`)
		return false
	end

	local nextHealth = math.max(0, currentHealth - math.max(0, amount))
	local nextState: DestructionState = if nextHealth <= 0 then "Collapsed" else "Damaged"
	structure:SetAttribute("CurrentHealth", nextHealth)
	self:_applyState(structure, nextState)
	self._destructionStateRemote:FireAllClients(structure, nextState)
	self._onStateChanged(player, structure, nextState)

	return true
end

return DestructionService
