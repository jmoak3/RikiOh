-- Generated from template

if CRikiOhGameMode == nil then
	CRikiOhGameMode = class({})
end

function CRikiOhGameMode:OnEntityHurt( event )
	if event.entindex_killed == nil or event.entindex_attacker == nil then return nil end

	local killedUnit = EntIndexToHScript( event.entindex_killed )
	local killedTeam = killedUnit:GetTeam()
	local hero = EntIndexToHScript( event.entindex_attacker )
	local heroTeam = hero:GetTeam()

	if killedUnit == nil or hero == nil then return nil end
	
	if not killedUnit:IsRealHero() or not hero:IsRealHero() then return nil end

	if killedUnit:GetHealth() > 0.4*hero:GetBaseDamageMax() then return nil end

	if hero:GetClassname() == "npc_dota_hero_riki" and 
			killedUnit:GetClassname() == "npc_dota_hero_sniper" then
		local playerID = killedUnit:GetPlayerID()
		print(playerID)
		PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_BADGUYS)
		local ent = PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_riki", 0, 0)
		ent:ForceKill(false)
		PlayerResource:SetGold(playerID, 675, true)
		--local playerName = PlayerResource:GetPlayerName(killedUnit:GetPlayerOwnerID())
		--print(playerName)
		GameRules:SendCustomMessage("Another Sniper joins the Rikis!", DOTA_TEAM_GOODGUYS, 1)
		print("Changing Team of killed player!")
	end
end

function CRikiOhGameMode:OnGameInProgress()
	print("on game start")
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 24)
	local numPlayers = 0
	for team = 0,(DOTA_TEAM_COUNT-1) do
	    numPlayers = numPlayers + PlayerResource:GetPlayerCountForTeam(team)
	end
	local startingBadGuy = math.random(0, numPlayers-1)
	print(startingBadGuy)
	PlayerResource:SetCustomTeamAssignment(startingBadGuy, DOTA_TEAM_BADGUYS)
	local ent = PlayerResource:ReplaceHeroWith(startingBadGuy, "npc_dota_hero_riki", 0, 0)
	ent:ForceKill(false)
	PlayerResource:SetGold(startingBadGuy, 675, true)
end

function CRikiOhGameMode:PrepareBuildings()		
	local towers = Entities:FindAllByClassname("npc_dota_tower")
	for k, v in pairs(towers) do
		v:ForceKill(false)
	end
	
	local fountains = Entities:FindAllByClassname("ent_dota_fountain")
	for k, v in pairs(fountains) do
		v:ForceKill(false)
	end
	
	local racks = Entities:FindAllByClassname("npc_dota_barracks")
	for k, v in pairs(racks) do
		v:ForceKill(false)
	end
	
	local fort = Entities:FindAllByClassname("npc_dota_fort")
	for k, v in pairs(fort) do
		v:SetBaseMaxHealth(600)
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
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
	CRikiOhGameMode.started = false
	GameRules:GetGameModeEntity():SetFixedRespawnTime(10.0)
	GameRules:GetGameModeEntity():SetCustomHeroMaxLevel(3)
	GameRules:GetGameModeEntity():SetFountainPercentageHealthRegen(0.0)
	GameRules:GetGameModeEntity():SetCustomGameForceHero("npc_dota_hero_sniper")
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath(false)
	GameRules:SetCustomGameSetupRemainingTime(0.0)
	GameRules:SetPreGameTime(35.0)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 24)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)
	self:PrepareBuildings()
	
end

function CRikiOhGameMode:OnThink()
	if not CRikiOhGameMode.started and GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self:OnGameInProgress()
		CRikiOhGameMode.started = true
		GameRules:SendCustomMessage("The Riki has been selected! Survive for 10 minutes, Snipers!", 
									DOTA_TEAM_GOODGUYS, 1)
	elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		local creeps = Entities:FindAllByClassname("npc_dota_creep_lane")
		for k, v in pairs(creeps) do
			v:ForceKill(false)
		end
		local siege = Entities:FindAllByClassname("npc_dota_creep_siege")
		for k, v in pairs(siege) do
			v:ForceKill(false)
		end
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