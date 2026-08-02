--!strict

local EnemyContract = {}

EnemyContract.Tag = "EnemyKaiju"
EnemyContract.SpawnTag = "EnemySpawn"
EnemyContract.RogueTeam = "Rogue"
EnemyContract.TemplateFolderName = "EnemyTemplates"
EnemyContract.RuntimeFolderName = "RuntimeEnemies"

EnemyContract.Attribute = table.freeze({
	Id = "EnemyId",
	Team = "CombatTeam",
	State = "EnemyState",
	Health = "EnemyHealth",
	MaxHealth = "EnemyMaxHealth",
	TargetUserId = "EnemyTargetUserId",
	TargetPosition = "EnemyTargetPosition",
	AttackKind = "EnemyAttackKind",
	AttackSequence = "EnemyAttackSequence",
	Enraged = "EnemyEnraged",
})

EnemyContract.State = table.freeze({
	Idle = "Idle",
	Patrolling = "Patrolling",
	Investigating = "Investigating",
	Chasing = "Chasing",
	Telegraphing = "Telegraphing",
	Recovering = "Recovering",
	Staggered = "Staggered",
	Defeated = "Defeated",
})

EnemyContract.Attack = table.freeze({
	None = "None",
	Swipe = "Swipe",
	Lunge = "Lunge",
})

return table.freeze(EnemyContract)
