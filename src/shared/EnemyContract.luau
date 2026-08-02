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
})

EnemyContract.State = table.freeze({
	Idle = "Idle",
	Chasing = "Chasing",
	Telegraphing = "Telegraphing",
	Recovering = "Recovering",
	Defeated = "Defeated",
})

return table.freeze(EnemyContract)
