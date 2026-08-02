--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FactoryContract = require(ReplicatedStorage.Shared.FactoryContract)
local PlayerRole = require(ReplicatedStorage.Shared.PlayerRole)

local FactoryObjectiveController = {}
FactoryObjectiveController.__index = FactoryObjectiveController

local player = Players.LocalPlayer

type Presentation = {
	model: Model,
	zone: BasePart,
	ring: CylinderHandleAdornment,
	billboard: BillboardGui,
	label: TextLabel,
	barFill: Frame,
	connections: { RBXScriptConnection },
}

local COLORS = table.freeze({
	Neutral = Color3.fromRGB(255, 177, 58),
	Human = Color3.fromRGB(65, 177, 255),
	Enemy = Color3.fromRGB(255, 76, 65),
	Destroyed = Color3.fromRGB(90, 96, 105),
})

local function findCaptureZone(model: Model): BasePart?
	local zone = model:FindFirstChild(FactoryContract.Authoring.CaptureZoneName, true)
	return if zone and zone:IsA("BasePart") then zone else nil
end

local function stateText(model: Model): (string, Color3, number)
	local ownerTeam = model:GetAttribute(FactoryContract.Attribute.OwnerTeam)
	local state = model:GetAttribute(FactoryContract.Attribute.State)
	local progress = model:GetAttribute(FactoryContract.Attribute.CaptureProgress)
	local resolvedProgress = if typeof(progress) == "number" then math.clamp(progress, 0, 1) else 0
	if state == FactoryContract.State.Destroyed then
		return "FACTORY DESTROYED", COLORS.Destroyed, 1
	end
	if ownerTeam == FactoryContract.Team.Human then
		return "HUMAN FACTORY  •  REINFORCEMENTS ALLIED", COLORS.Human, 1
	end
	if state == FactoryContract.State.Capturing then
		return `CAPTURING FACTORY  •  {math.floor(resolvedProgress * 100 + 0.5)}%`,
			COLORS.Human,
			resolvedProgress
	end
	if ownerTeam == FactoryContract.Team.Enemy then
		return "ENEMY FACTORY", COLORS.Enemy, resolvedProgress
	end
	if PlayerRole.IsHuman(player) then
		return "NEUTRAL FACTORY  •  HOLD THIS ZONE", COLORS.Neutral, resolvedProgress
	end
	return "NEUTRAL FACTORY  •  DESTROY THE PLANT", COLORS.Neutral, resolvedProgress
end

function FactoryObjectiveController.new()
	local self = setmetatable({}, FactoryObjectiveController)
	self._presentations = {} :: { [Model]: Presentation }
	self._pending = {} :: { [Model]: { RBXScriptConnection } }
	self._connections = {} :: { RBXScriptConnection }
	return self
end

function FactoryObjectiveController:_clearPending(model: Model)
	local connections = self._pending[model]
	if not connections then
		return
	end
	self._pending[model] = nil
	for _, connection in connections do
		connection:Disconnect()
	end
end

function FactoryObjectiveController:_update(presentation: Presentation)
	local text, color, progress = stateText(presentation.model)
	presentation.label.Text = text
	presentation.label.TextColor3 = color
	presentation.barFill.BackgroundColor3 = color
	presentation.barFill.Size = UDim2.fromScale(progress, 1)
	presentation.ring.Color3 = color
	presentation.ring.Transparency = if progress > 0 and progress < 1 then 0.42 else 0.7
end

function FactoryObjectiveController:_unregister(model: Model)
	self:_clearPending(model)
	local presentation = self._presentations[model]
	if not presentation then
		return
	end
	self._presentations[model] = nil
	for _, connection in presentation.connections do
		connection:Disconnect()
	end
	presentation.ring:Destroy()
	presentation.billboard:Destroy()
end

function FactoryObjectiveController:_register(instance: Instance)
	if not instance:IsA("Model") or self._presentations[instance] then
		return
	end
	local zone = findCaptureZone(instance)
	if not zone then
		if not self._pending[instance] then
			local connections = {} :: { RBXScriptConnection }
			self._pending[instance] = connections
			table.insert(
				connections,
				instance.DescendantAdded:Connect(function(descendant)
					if
						descendant.Name == FactoryContract.Authoring.CaptureZoneName
						and descendant:IsA("BasePart")
					then
						self:_clearPending(instance)
						self:_register(instance)
					end
				end)
			)
			table.insert(
				connections,
				instance.AncestryChanged:Connect(function(_, parent)
					if not parent then
						self:_clearPending(instance)
					end
				end)
			)
			-- Close the streaming race where the zone arrives between the initial
			-- lookup and connection setup.
			if findCaptureZone(instance) then
				self:_clearPending(instance)
				self:_register(instance)
			end
		end
		return
	end
	self:_clearPending(instance)

	local ring = Instance.new("CylinderHandleAdornment")
	ring.Name = "FactoryCaptureRing"
	ring.Adornee = zone
	ring.AlwaysOnTop = false
	ring.Height = 0.35
	local authoredRadius = instance:GetAttribute(FactoryContract.Attribute.CaptureRadius)
	ring.Radius = if typeof(authoredRadius) == "number"
			and authoredRadius == authoredRadius
		then math.max(1, authoredRadius)
		else Config.Factories.DefaultCaptureRadius
	ring.ZIndex = 1
	ring.Parent = zone

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FactoryObjectiveBillboard"
	billboard.Adornee = zone
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = Config.Factories.ObjectiveFeedbackDistance
	billboard.Size = UDim2.fromOffset(310, 56)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 10, 0)
	billboard.Parent = zone

	local label = Instance.new("TextLabel")
	label.Name = "State"
	label.Size = UDim2.new(1, 0, 0, 38)
	label.BackgroundColor3 = Color3.fromRGB(12, 17, 24)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextStrokeTransparency = 0.72
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	local bar = Instance.new("Frame")
	bar.Name = "Progress"
	bar.Position = UDim2.new(0.05, 0, 0, 43)
	bar.Size = UDim2.new(0.9, 0, 0, 7)
	bar.BackgroundColor3 = Color3.fromRGB(29, 39, 51)
	bar.BackgroundTransparency = 0.15
	bar.BorderSizePixel = 0
	bar.ClipsDescendants = true
	bar.Parent = billboard

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local presentation: Presentation = {
		model = instance,
		zone = zone,
		ring = ring,
		billboard = billboard,
		label = label,
		barFill = fill,
		connections = {},
	}
	self._presentations[instance] = presentation
	table.insert(
		presentation.connections,
		zone.AncestryChanged:Connect(function()
			if not zone:IsDescendantOf(instance) then
				self:_unregister(instance)
				if instance.Parent then
					self:_register(instance)
				end
			end
		end)
	)
	for _, attributeName in
		{
			FactoryContract.Attribute.OwnerTeam,
			FactoryContract.Attribute.State,
			FactoryContract.Attribute.CaptureProgress,
		}
	do
		table.insert(
			presentation.connections,
			instance:GetAttributeChangedSignal(attributeName):Connect(function()
				self:_update(presentation)
			end)
		)
	end
	self:_update(presentation)
end

function FactoryObjectiveController:Start()
	for _, instance in CollectionService:GetTagged(FactoryContract.Tag) do
		self:_register(instance)
	end
	table.insert(
		self._connections,
		CollectionService:GetInstanceAddedSignal(FactoryContract.Tag):Connect(function(instance)
			self:_register(instance)
		end)
	)
	table.insert(
		self._connections,
		CollectionService:GetInstanceRemovedSignal(FactoryContract.Tag):Connect(function(instance)
			if instance:IsA("Model") then
				self:_unregister(instance)
			end
		end)
	)
	table.insert(
		self._connections,
		player:GetAttributeChangedSignal(PlayerRole.Attribute):Connect(function()
			for _, presentation in self._presentations do
				self:_update(presentation)
			end
		end)
	)
end

function FactoryObjectiveController:Destroy()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	local models = {}
	for model in self._presentations do
		table.insert(models, model)
	end
	for _, model in models do
		self:_unregister(model)
	end
	local pendingModels = {}
	for model in self._pending do
		table.insert(pendingModels, model)
	end
	for _, model in pendingModels do
		self:_clearPending(model)
	end
end

return FactoryObjectiveController
