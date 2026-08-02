--!strict

local PlayerRole = {}

PlayerRole.Attribute = "CharacterRole"
PlayerRole.Kaiju = "Kaiju"
PlayerRole.Human = "Human"
PlayerRole.HumanScaleGeometryTag = "HumanScaleGeometry"

PlayerRole.CollisionGroup = table.freeze({
	Kaiju = "KaijuCharacters",
	Human = "HumanCharacters",
	KaijuContact = "KaijuContact",
	KaijuDamageQuery = "KaijuDamageQuery",
	HumanWeaponQuery = "HumanWeaponQuery",
	HumanScaleGeometry = "HumanScaleGeometry",
})

export type Value = "Kaiju" | "Human"

function PlayerRole.Is(value: any): boolean
	return value == PlayerRole.Kaiju or value == PlayerRole.Human
end

function PlayerRole.Get(player: Player): Value?
	local value = player:GetAttribute(PlayerRole.Attribute)
	return if PlayerRole.Is(value) then value :: Value else nil
end

function PlayerRole.IsKaiju(player: Player): boolean
	return PlayerRole.Get(player) == PlayerRole.Kaiju
end

function PlayerRole.IsHuman(player: Player): boolean
	return PlayerRole.Get(player) == PlayerRole.Human
end

return table.freeze(PlayerRole)
