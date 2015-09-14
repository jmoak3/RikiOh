-- Generated from template

if CRikiOhGameMode == nil then
	CRikiOhGameMode = class({})
end

function CRikiOhGameMode:OnHitByTower( event )
	local player = PlayerResource:GetPlayer(event.PlayerID):GetAssignedHero()
	player:SetHealth(player:GetHealth() + event.damage + 1)
end

function CRikiOhGameMode:OnEntityKilled( event )
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	local killedTeam = killedUnit:GetTeam()
	local hero = EntIndexToHScript( event.entindex_attacker )
	local heroTeam = hero:GetTeam()
	
	if not killedUnit:IsRealHero() or not hero:IsRealHero() then return nil end

	if hero:GetClassname() == "npc_dota_hero_riki" and killedUnit:GetClassname() == "npc_dota_hero_sniper" then
		local playerID = killedUnit:GetPlayerID()
		PlayerResource:SetCustomTeamAssignment(playerID, heroTeam )
		PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_riki", 0, 0):ForceKill(false)
		print("Changing Team of killed player!")
	end
end

function CRikiOhGameMode:OnGameInProgress()
	print("on game start")
	local numPlayers = 0
	for team = 0, (DOTA_TEAM_COUNT-1) do
	    numPlayers = numPlayers + PlayerResource:GetPlayerCountForTeam(team)
		GameRules:SetCustomGameTeamMaxPlayers(team, 24)
	end
	for playerID = 1,numPlayers do
	    PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
	end
	local startingBadGuy = math.random(1, numPlayers) - 1
	print(startingBadGuy)
	PlayerResource:SetCustomTeamAssignment(startingBadGuy, DOTA_TEAM_BADGUYS)
	local ent = PlayerResource:ReplaceHeroWith(startingBadGuy, "npc_dota_hero_riki", 0, 0)
	ent:ForceKill(false)
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
    ListenToGameEvent( "entity_killed", Dynamic_Wrap( CRikiOhGameMode, "OnEntityKilled" ), self )
    ListenToGameEvent( "dota_player_take_tower_damage", Dynamic_Wrap( CRikiOhGameMode, "OnHitByTower" ), self )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
	CRikiOhGameMode.started = false
	GameRules:GetGameModeEntity():SetFixedRespawnTime(10.0)
	GameRules:GetGameModeEntity():SetCustomHeroMaxLevel(1)
	for team = 0,(DOTA_TEAM_COUNT-1) do
	    GameRules:SetCustomGameTeamMaxPlayers(team, 10)
	end
end

function CRikiOhGameMode:OnThink()
	if not CRikiOhGameMode.started and GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self:OnGameInProgress()
		CRikiOhGameMode.started = true
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end