-- Generated from template

if CRikiOhGameMode == nil then
	CRikiOhGameMode = class({})
end

function CRikiOhGameMode:OnPlayerSpawn( event )
	print("on player spawn")
	--local player = PlayerResource:GetPlayer( event.userid )
	local deaths = PlayerResource:GetDeaths( event.userid )
	if deaths == 0 then PlayerResource:ReplaceHeroWith( event.userid, "npc_dota_hero_sniper", 0, 999999 ) end
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
		PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_riki", 0, 99999):ForceKill(false)
		print("Changing Team of killed player!")
	end

end

function CRikiOhGameMode:OnGameInProgress()
	print("on game start")
	local numPlayers = 0
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 40)
	for team = 0, (DOTA_TEAM_COUNT-1) do
	    numPlayers = numPlayers + PlayerResource:GetPlayerCountForTeam(team)
	end
	for playerID = 0, numPlayers do
	    PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
		PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_sniper", 0, 999999)
	end
	local startingBadGuy = math.random(numPlayers)
	PlayerResource:ReplaceHeroWith(startingBadGuy, "npc_dota_hero_riki", 0, 99999):ForceKill(false)
	PlayerResource:SetCustomTeamAssignment(startingBadGuy, DOTA_TEAM_BADGUYS)

end

function Precache( context )
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = CRikiOhGameMode()
	GameRules.AddonTemplate:InitGameMode()
end

function CRikiOhGameMode:InitGameMode()
    ListenToGameEvent( "entity_killed", Dynamic_Wrap( CRikiOhGameMode, "OnEntityKilled" ), self )
    ListenToGameEvent( "player_spawn", Dynamic_Wrap( CRikiOhGameMode, "OnPlayerSpawn" ), self )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
	CRikiOhGameMode.started = false
	for team = 0, (DOTA_TEAM_COUNT-1) do
	    GameRules:SetCustomGameTeamMaxPlayers(team, 10)
	end

end

-- Evaluate the state of the game
function CRikiOhGameMode:OnThink()
	if not CRikiOhGameMode.started and GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self:OnGameInProgress()
		CRikiOhGameMode.started = true
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end