-- Generated from template

if CRikiOhGameMode == nil then
	CRikiOhGameMode = class({})
end

function CRikiOhGameMode:PrepareBuildings()		
	local towers = Entities:FindByName(nil, "dota_goodguys_tower1_top")
	towers:ForceKill(false)
	towers = Entities:FindByName(nil, "dota_goodguys_tower1_mid")
	towers:ForceKill(false)
	towers = Entities:FindByName(nil, "dota_goodguys_tower1_bot")
	towers:ForceKill(false)
	towers = Entities:FindByName(nil, "dota_goodguys_tower2_top")
	towers:ForceKill(false)
	towers = Entities:FindByName(nil, "dota_goodguys_tower2_mid")
	towers:ForceKill(false)
	towers = Entities:FindByName(nil, "dota_goodguys_tower2_bot")
	towers:ForceKill(false)
	towers = Entities:FindByName(nil, "dota_goodguys_tower3_top")
	towers:ForceKill(false)
	towers = Entities:FindByName(nil, "dota_goodguys_tower3_mid")
	towers:ForceKill(false)
	towers = Entities:FindByName(nil, "dota_goodguys_tower3_bot")
	towers:ForceKill(false)
	towers = Entities:FindByName(nil, "dota_goodguys_tower4_top")
	towers:ForceKill(false)
	towers = Entities:FindByName(nil, "dota_goodguys_tower4_bot")
	towers:ForceKill(false)

	towers = Entities:FindAllByClassname("npc_dota_tower")
	for k, v in pairs(towers) do
		v:SetBaseMaxHealth(12000)
	end
	
	local fountains = Entities:FindAllByName("ent_dota_fountain_good")
	for k, v in pairs(fountains) do
		v:ForceKill(false)
	end
	
	local racks = Entities:FindAllByClassname("npc_dota_barracks")
	for k, v in pairs(racks) do
		v:ForceKill(false)
	end
		
	local goodfort = Entities:FindAllByName("dota_goodguys_fort")
	for k, v in pairs(goodfort) do
		v:SetBaseMaxHealth(300)
	end
	local badfort = Entities:FindAllByName("dota_badguys_fort")
	for k, v in pairs(badfort) do
		v:SetBaseMaxHealth(12000)
	end
end

function CRikiOhGameMode:SpawnAsRiki(playerID)
	local ent = PlayerResource:GetSelectedHeroEntity(playerID)
	PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_BADGUYS)
	local ent = PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_riki", 2000, 0)
	if ent == nil then return nil end
	ent:ForceKill(false)
	GameRules:SendCustomMessage("Another Sniper joins the Rikis!", DOTA_TEAM_GOODGUYS, 1)
end

function CRikiOhGameMode:OnEntityHurt( event )
	if event.entindex_killed == nil or event.entindex_attacker == nil then return nil end

	local killedUnit = EntIndexToHScript( event.entindex_killed )
	local killedTeam = killedUnit:GetTeam()
	local hero = EntIndexToHScript( event.entindex_attacker )
	local heroTeam = hero:GetTeam()

	if killedUnit == nil or hero == nil then return nil end
	
	if not killedUnit:IsRealHero() or not hero:IsRealHero() then return nil end

	local currHealth = killedUnit:GetHealth()
	local maxHealth = killedUnit:GetMaxHealth()
	local dmgModifier = 1
	if hero:HasItemInInventory("item_broadsword") then dmgModifier = dmgModifier + 1 end
	if hero:GetClassname() == "npc_dota_hero_riki" then dmgModifier = dmgModifier + 1 end
	if killedUnit:HasItemInInventory("item_chainmail") then dmgModifier = dmgModifier - 1 end
	if currHealth > ((maxHealth/3)*dmgModifier) then
		killedUnit:SetHealth(currHealth - ((maxHealth/3)*dmgModifier))
		return nil
	end

	if hero:GetClassname() == "npc_dota_hero_riki" and 
			killedUnit:GetClassname() == "npc_dota_hero_sniper" then
		self:SpawnAsRiki(killedUnit:GetPlayerID())
		PlayerResource:SetGold(hero:GetPlayerID(), 
							   PlayerResource:GetGold(hero:GetPlayerID()) + 1000,
							   true)
	else 
		killedUnit:SetHealth(0)
	end
end

function CRikiOhGameMode:OnEntitySpawn(event)	
	--DELETE IF CREEP/SIEGE
	local spawnedEnt = EntIndexToHScript( event.entindex )
	if spawnedEnt == nil then return end
	if spawnedEnt:GetClassname() == "npc_dota_creep_lane" or 
				spawnedEnt:GetClassname() == "npc_dota_creep_siege" then
		spawnedEnt:ForceKill(false)
	end
	
	--PLAYER PORTION
	if not spawnedEnt:IsRealHero() then return nil end
	
	if spawnedEnt:GetClassname() == "npc_dota_hero_riki" then
		spawnedEnt:GetAbilityByIndex(0):SetLevel(1)
		spawnedEnt:GetAbilityByIndex(1):SetLevel(1)
		spawnedEnt:SetAbilityPoints(0)
	elseif spawnedEnt:GetClassname() == "npc_dota_hero_sniper" then
		spawnedEnt:GetAbilityByIndex(0):SetLevel(1)
		spawnedEnt:SetAbilityPoints(0)
	end
	
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then	
		spawnedEnt:SetAbilityPoints(0)
		local playerID = spawnedEnt:GetPlayerOwnerID()
		PlayerResource:SetGold(playerID, 0, false)
		PlayerResource:SetGold(playerID, 2000, true)
	end
end

function CRikiOhGameMode:OnPlayerLevel(event)	
	local hero = PlayerResource:GetSelectedHeroEntity(event. player )
	if hero == nil then return nil end 
	hero:SetAbilityPoints(0)
end

function CRikiOhGameMode:OnGameInProgress()
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 24)
	local totalPlayers = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
	for i=0,totalPlayers/8 do
		local numPlayers = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
		local badGuy = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, 
														   math.random(1, numPlayers))
		self:SpawnAsRiki(badGuy)
	end
end

function Precache( context )
    PrecacheUnitByNameSync( "npc_dota_hero_riki", context )
    PrecacheModel( "npc_dota_hero_riki", context )
end

function Activate()
	GameRules.AddonTemplate = CRikiOhGameMode()
	GameRules.AddonTemplate:InitGameMode()
end

function CRikiOhGameMode:InitGameMode()
	math.randomseed( Time() )
    ListenToGameEvent( "entity_hurt", Dynamic_Wrap( CRikiOhGameMode, "OnEntityHurt" ), self )
    ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CRikiOhGameMode, "OnEntitySpawn" ), self )
    ListenToGameEvent( "dota_player_gained_level", Dynamic_Wrap( CRikiOhGameMode, "OnPlayerLevel" ), self )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
	CRikiOhGameMode.started = false
	GameRules:GetGameModeEntity():SetCustomHeroMaxLevel(1)
	GameRules:GetGameModeEntity():SetFixedRespawnTime(10.0)
	GameRules:GetGameModeEntity():SetFountainPercentageHealthRegen(0.0)
	GameRules:GetGameModeEntity():SetCustomGameForceHero("npc_dota_hero_sniper")
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath(false)
	GameRules:SetHeroSelectionTime(30.0)
	GameRules:SetGoldPerTick(0)
	GameRules:SetPreGameTime(35.0)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 24)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)
	self:PrepareBuildings()	
end

function CRikiOhGameMode:OnThink()
	if not CRikiOhGameMode.started and GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self:OnGameInProgress()
		CRikiOhGameMode.started = true
		GameRules:SendCustomMessage("The Riki has been selected! Protect your ancient for 10 minutes, Snipers!", 
									DOTA_TEAM_GOODGUYS, 1)
	elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		local survivors = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
		if survivors == 0 then
			GameRules:MakeTeamLose(DOTA_TEAM_GOODGUYS)
			GameRules:SendCustomMessage("The Rikis Win!", DOTA_TEAM_GOODGUYS, 1)
		elseif GameRules:GetDOTATime(false, false) > 600.0 then
			GameRules:MakeTeamLose(DOTA_TEAM_BADGUYS)
			GameRules:SendCustomMessage("The Snipers Win!", DOTA_TEAM_GOODGUYS, 1)
		end
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end