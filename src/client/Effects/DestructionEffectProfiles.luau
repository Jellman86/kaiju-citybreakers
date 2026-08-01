--!strict

export type Profile = {
	fragmentColor: Color3,
	fragmentMaterial: Enum.Material,
	fragmentSizeScale: number,
	fragmentSpeedScale: number,
}

local CONCRETE: Profile = table.freeze({
	fragmentColor = Color3.fromRGB(84, 89, 94),
	fragmentMaterial = Enum.Material.Concrete,
	fragmentSizeScale = 1,
	fragmentSpeedScale = 1,
})

local PROFILES: { [string]: Profile } = table.freeze({
	Concrete = CONCRETE,
	Metal = table.freeze({
		fragmentColor = Color3.fromRGB(74, 87, 94),
		fragmentMaterial = Enum.Material.Metal,
		fragmentSizeScale = 0.85,
		fragmentSpeedScale = 0.8,
	}),
	Lightweight = table.freeze({
		fragmentColor = Color3.fromRGB(120, 105, 86),
		fragmentMaterial = Enum.Material.WoodPlanks,
		fragmentSizeScale = 0.75,
		fragmentSpeedScale = 1.25,
	}),
})

local DestructionEffectProfiles = {}

function DestructionEffectProfiles.Get(materialProfile: string): Profile
	return PROFILES[materialProfile] or CONCRETE
end

return table.freeze(DestructionEffectProfiles)
