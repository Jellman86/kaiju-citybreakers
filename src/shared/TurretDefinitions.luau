--!strict

export type Profile = {
	Id: string,
	Effect: string,
	AttackKind: string,
	FireIntervalSeconds: number,
	TargetLockSeconds: number,
	Range: number,
	HumanDamage: number,
	KaijuDamage: number,
	ProjectileSpeed: number,
	ProjectileLifetimeSeconds: number,
	ImpactRadius: number,
}

local PROFILES: { [string]: Profile } = {
	MachineGun = {
		Id = "MachineGun",
		Effect = "Bullet",
		AttackKind = "Hitscan",
		FireIntervalSeconds = 0.38,
		TargetLockSeconds = 0.45,
		Range = 260,
		HumanDamage = 4,
		KaijuDamage = 12,
		ProjectileSpeed = 0,
		ProjectileLifetimeSeconds = 0,
		ImpactRadius = 0,
	},
	Minigun = {
		Id = "Minigun",
		Effect = "Minigun",
		AttackKind = "Hitscan",
		FireIntervalSeconds = 0.2,
		TargetLockSeconds = 0.8,
		Range = 230,
		HumanDamage = 2,
		KaijuDamage = 4,
		ProjectileSpeed = 0,
		ProjectileLifetimeSeconds = 0,
		ImpactRadius = 0,
	},
	Cannon = {
		Id = "Cannon",
		Effect = "CannonShell",
		AttackKind = "Projectile",
		FireIntervalSeconds = 1.15,
		TargetLockSeconds = 0.75,
		Range = 280,
		HumanDamage = 18,
		KaijuDamage = 40,
		ProjectileSpeed = 190,
		ProjectileLifetimeSeconds = 3,
		ImpactRadius = 7,
	},
	Rocket = {
		Id = "Rocket",
		Effect = "Rocket",
		AttackKind = "Projectile",
		FireIntervalSeconds = 2.4,
		TargetLockSeconds = 1.1,
		Range = 320,
		HumanDamage = 30,
		KaijuDamage = 75,
		ProjectileSpeed = 90,
		ProjectileLifetimeSeconds = 4,
		ImpactRadius = 20,
	},
}

local TurretDefinitions = {}

function TurretDefinitions.Get(archetype: any): Profile?
	if type(archetype) ~= "string" then
		return nil
	end
	return PROFILES[archetype]
end

function TurretDefinitions.GetAll(): { [string]: Profile }
	return PROFILES
end

return table.freeze(TurretDefinitions)
