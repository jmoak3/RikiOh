-- Generated from template

if CRikiOhGameMode == nil then
	CRikiOhGameMode = class({})
end

function CRikiOhGameMode:OnHitByTower( event )
	local player = PlayerResource:GetPlayer(event.PlayerID):GetAssignedHero()
	player:SetHealth(player:GetHealth() + event.damage + 30)
end

function CRikiOhGameMode:OnEntityHurt( event )
	if event.entindex_killed == nil or event.entindex_attacker == nil then return nil end

	local killedUnit = EntIndexToHScript( event.entindex_killed )
	local killedTeam = killedUnit:GetTeam()
	local hero = EntIndexToHScript( event.entindex_attacker )
	local heroTeam = hero:GetTeam()

	if killedUnit == nil or hero == nil then return nil end
	
	if not killedUnit:IsRealHero() or not hero:IsRealHero() then return nil end

	if killedUnit:GetHealth() > hero:GetBaseDamageMax() then return nil end

	if hero:GetClassname() == "npc_dota_hero_riki" and 
			killedUnit:GetClassname() == "npc_dota_hero_sniper" then
		local playerID = killedUnit:GetPlayerID()
		print(playerID)
		PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_BADGUYS)
		local ent = PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_riki", 0, 0)
		ent:ForceKill(false)
		local playerName = PlayerResource:GetPlayerName(killedUnit:GetPlayerOwnerID()-1)
		print(playerName)
		GameRules:SendCustomMessage("Another Sniper joins the Rikis!", DOTA_TEAM_GOODGUYS, 1)
		print("Changing Team of killed player!")
	end
end

function CRikiOhGameMode:OnGameInProgress()
	print("on game start")
	local numPlayers = 0
	for team = 0,(DOTA_TEAM_COUNT-1) do
	    numPlayers = numPlayers + PlayerResource:GetPlayerCountForTeam(team)
	end
	for playerID = 0,numPlayers-1 do
	    PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
		PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_sniper", 0, 0)
	end
	local startingBadGuy = math.random(0, numPlayers-1)
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
    ListenToGameEvent( "entity_hurt", Dynamic_Wrap( CRikiOhGameMode, "OnEntityHurt" ), self )
    ListenToGameEvent( "dota_player_take_tower_damage", Dynamic_Wrap( CRikiOhGameMode, "OnHitByTower" ), self )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
	CRikiOhGameMode.started = false
	GameRules:GetGameModeEntity():SetFixedRespawnTime(10.0)
	GameRules:GetGameModeEntity():SetCustomHeroMaxLevel(1)
	GameRules:SetCustomGameSetupRemainingTime(0.0)
	GameRules:SetPreGameTime(15.0)
	for team = 0,(DOTA_TEAM_COUNT-1) do
	    GameRules:SetCustomGameTeamMaxPlayers(team, 24)
	end
end

function CRikiOhGameMode:OnThink()
	if not CRikiOhGameMode.started and GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self:OnGameInProgress()
		CRikiOhGameMode.started = true
		GameRules:SendCustomMessage("The Riki has been selected! Survive for 5 minutes, Snipers!", 
									DOTA_TEAM_GOODGUYS, 1)
	elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		local survivors = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
		if survivors == 0 then
			GameRules:MakeTeamLose(DOTA_TEAM_GOODGUYS)
			GameRules:SendCustomMessage("The Rikis Win!", DOTA_TEAM_GOODGUYS, 1)
		elseif GameRules:GetDOTATime(false, false) > 300.0 then
			GameRules:MakeTeamLose(DOTA_TEAM_BADGUYS)
			GameRules:SendCustomMessage("The Snipers Win!", DOTA_TEAM_GOODGUYS, 1)
		end
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end