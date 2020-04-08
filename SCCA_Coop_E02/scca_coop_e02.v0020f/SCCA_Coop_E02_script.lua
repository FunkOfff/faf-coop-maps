-- ****************************************************************************
-- **
-- **  File     :  /maps/scca_coop_e02.v0016/SCCA_Coop_E02_script.lua
-- **  Author(s):  David Tomandl
-- **
-- **  Summary  :  This is the main file in control of the events during
-- **              operation E2.
-- **
-- **              My apologies for the confusing naming schemes used throughout;
-- **              this was the first operation completed and as a result it
-- **              was rather heavily revised after it was first complete.
-- **              This included adding a new mission between missions 1 and 2.
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local Objectives = ScenarioFramework.Objectives
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local AIBuildStructures = import('/lua/ai/AIBuildStructures.lua')
local Cinematics = import('/lua/cinematics.lua')
local ScenarioStrings = import('/lua/ScenarioStrings.lua')
local OpStrings = import ('/maps/scca_coop_e02.v0020f/SCCA_Coop_E02_strings.lua')

-----------------
-- Debug Variables
-----------------
-- Difficulty values are
-- easy = 1
-- medium = 2
-- hard = 3
-- ScenarioInfo.Options.Difficulty is the difficulty passed in from the front end
local Difficulty = ScenarioInfo.Options.Difficulty or 2

------------------------
-- Local Tuning Variables
------------------------

-- Multi-mission variables:
-- How often the player should be attacked, broken out by difficulty
local M1PeriodicAttackPlayerDelay = { 180, 150, 120 }
local M2PeriodicAttackPlayerDelay = { 180, 150, 150 }
local M3PeriodicAttackPlayerDelay = { 180, 150, 120 }

local M1DifficultyModifierUnitCountLevel1 = {100, 50, 40}
local M1DifficultyModifierUnitCountLevel2 = {200, 100, 80}

local M1PeriodicAttackPlayerInitialDelay = { 600, 300, 120 }
local M1EarlyAttackPlayerInitialDelay  = { 100, 40, 10 }
local M1DropPlayerInitialDelay = {700, 400, 150}
local M2PeriodicAttackPlayerInitialDelay = { 600, 300, 120 }
local M3PeriodicAttackPlayerInitialDelay = { 600, 300, 120 }

-- How often should we spawn a group to attack the trucks in M2
local M2PeriodicAttackDelayTruck = 60

-- How many attacks on the player before the attacking
-- wave gets more units?
local M1AttacksBecomeMediumSizedAfter = 2
local M1AttacksBecomeLargeSizedAfter = 5

local M2AttacksBecomeMediumSizedAfter = 2
local M2AttacksBecomeLargeSizedAfter = 5

local M3AttacksBecomeMediumSizedAfter = 2 -- currently unused
local M3AttacksBecomeLargeSizedAfter = 5 -- currently unused


-- This is a bit complicated:
-- Route 1 is the west-most route to the player
-- Route 2 is the northwest route (most direct) to the player
-- Route 3 is the north-most route to the player
-- Research: attack the research base location instead of
-- the original base location
-- These are the relative chances that a periodic attack will
-- use that specific route.  The numbers only matter relative to
-- each other.
-- (THEY DO NOT HAVE TO ADD UP TO 100)
local AttackPlayerRoute1Chance = 20
local AttackPlayerRoute2Chance = 40
local AttackPlayerRoute3Chance = 20
local AttackResearchChance = 20

-- The relative chances of just a land attack, just an air attack,
-- or both.
-- (THEY DO NOT HAVE TO ADD UP TO 100)
local SendLandSquadChance = 80
local SendAirSquadChance = 5
local SendLandAndAirSquadChance = 15

-- Bonus objective details
-- local BonusEnergyAmount = 10000
-- local BonusVeterancyLevelNeeded = 2 # this is 100 kills

-- Mission 1

-- How often should the token attacks against the facility take place?
-- local M1PeriodicAttackDelayResearch = 60

-- The initial health percentage of the research facility
local M1ResearchFacilityInitialHealthPercentage = 46

-- How long does the player have until the research facility dies (in minutes)
local M1ResearchFacilityMinutesUntilDead = { 45, 33.5, 24 }

-- How often should the research facility lose health? (in seconds)
local M1ResearchFacilityHealthDrainInterval = 5

-- At which values of health will the research facility give warnings to the player?
local ResearchFacilityHealthThreshold1 = 30 -- 30%
local ResearchFacilityHealthThreshold2 = 20 -- 30%
local ResearchFacilityHealthThreshold3 = 10 -- 10%

-- How long to delay the dialog, in seconds
local M1_Dialogue_Delay_1 = 120
local M1_Dialogue_Delay_2 = 300

-- How long to delay between reminders
local M1P1InitialReminderDelay = 600
local M1P1ReoccuringReminderDelay = 600

local M1P3InitialReminderDelay = 180
local M1P3ReoccuringReminderDelay = 120

-- Mission 1.5

-- How long after this mission starts before
-- we give another warning about the big attack?
local M15TimeUntilWarningBeforeWave1 = 120

-- How long after the warning before
-- the big attack is launched?
local M15TimeUntilAttackOnResearchFacilityWave1 = 120

-- How long after the first wave is defeated before the second wave starts?
local M15TimeUntilAttackOnResearchFacilityWave2 = 30

-- How long after the first wave is defeated before the third wave starts?
local M15TimeUntilAttackOnResearchFacilityWave3 = 30

-- Mission 2

-- How many seconds between trucks
local TruckInterval = 2 -- Was 3

-- How long to wait before acknowledging another truck verbally
local TruckArrivalDialogDelay = 20
local TruckRespawnDialogDelay = 45

-- How many trucks to send { difficulty 1, 2, 3 }
local TotalNumberOfTrucks = { 8, 12, 15 }

-- Number of Aeon Light Radar stations that the player should capture
local TotalAeonRadar = 3

-- This many trucks can be killed and the player will still succeed
-- (Difficulty 1: this doesn't apply.)
local TrucksAllowedToDie = { -1, 6, 5 }

-- How many land need to arrive at the civilian facility for it
-- to be considered "reinforced"
-- Gunships
local CivilianReinforcementsNeededGunships = 10
-- Tanks
local CivilianReinforcementsNeededTanks = 10
-- Anti-air units
local CivilianReinforcementsNeededAntiAir = 10

-- How long to delay between reminders
local M2P1InitialReminderDelay = 900
local M2P1ReoccuringReminderDelay = 600

local M2P2InitialReminderDelay = 300
local M2P2ReoccuringReminderDelay = 600

-- Mission 3

-- How long to delay the dialog, in seconds
local M3_Aeon_Comment_Dialogue_Delay = 120
local M3_Base_Hint_Dialogue_Delay = 300

-- How long after the player attacks the Aeon base to taunt him
-- a second and third time?
local M3Taunt2Delay = 480
local M3Taunt3Delay = 420

-- How long to delay between reminders
local M3P2InitialReminderDelay = 1200
local M3P2ReoccuringReminderDelay = 900

-- ### Global variables
ScenarioInfo.MissionNumber = 1

ScenarioInfo.Player1 = 1
ScenarioInfo.Aeon = 2
ScenarioInfo.AllyResearch = 3
ScenarioInfo.AllyCivilian = 4
ScenarioInfo.AeonNeutral = 5
ScenarioInfo.Player2 = 6
ScenarioInfo.Player3 = 7
ScenarioInfo.Player4 = 8
ScenarioInfo.VarTable = {}
ScenarioInfo.VarTable['BuildDefenseGunships'] = false
ScenarioInfo.PreviousResearchHealthPercentage = 110
ScenarioInfo.ResearchFacilityThreshold1Reached = false
ScenarioInfo.ResearchFacilityThreshold2Reached = false
ScenarioInfo.ResearchFacilityThreshold3Reached = false
ScenarioInfo.ResearchFacilityRepaired = false
ScenarioInfo.NumberOfPeriodicAttacks = 0
ScenarioInfo.StopPeriodicAttacks = false
ScenarioInfo.AeonPatrolsDefeatedM1 = false
ScenarioInfo.AttackPlatoonsAlive = 0
ScenarioInfo.M15TransportsAreDead = false
ScenarioInfo.CivilianFacilityReinforcedObjectiveComplete = false
ScenarioInfo.ReinforceTriggerCalled = 0
ScenarioInfo.TruckList = {}
ScenarioInfo.TrucksSent = 0
ScenarioInfo.TrucksKilled = 0
ScenarioInfo.TrucksDone = 0
ScenarioInfo.TrucksSafe = 0
ScenarioInfo.TrucksActive = 0
ScenarioInfo.TruckAttacked = false
ScenarioInfo.TruckOrdersRepeated = {}
ScenarioInfo.CivilianFacilityAlive = true
ScenarioInfo.CivilianFacilityNeeded = true
ScenarioInfo.NumberOfAeonRadarDestroyed = 0
ScenarioInfo.M2AttackFinalOrdersGiven = false
ScenarioInfo.NextBaseDrop = 0
ScenarioInfo.M1DifficultyModifier = 1 -- This will range of 1 to 3, depending on how well the player is doing



-- #### LOCALS #####
local MissionTexture = '/textures/ui/common/missions/mission.dds'

local Difficulty1_Suffix = '_D1'
local Difficulty2_Suffix = '_D2'
local Difficulty3_Suffix = '_D3'

local TauntTable = {
    OpStrings.TAUNT1,
    OpStrings.TAUNT2,
    OpStrings.TAUNT3,
    OpStrings.TAUNT4,
    OpStrings.TAUNT5,
    OpStrings.TAUNT6,
    OpStrings.TAUNT7,
    OpStrings.TAUNT8,
}

-- It looks like we're cutting all NIS's from this op, so these will be permanent now.
-- Leaving this in for the mod community to play with. (Hi everyone! :)
local SkipM1IntroNIS = true
local SkipM2IntroNIS = true
local SkipM3IntroNIS = true

local Player1 = ScenarioInfo.Player1
local Player2 = ScenarioInfo.Player2
local Player3 = ScenarioInfo.Player3
local Player4 = ScenarioInfo.Player4
local Aeon = ScenarioInfo.Aeon
local AllyResearch = ScenarioInfo.AllyResearch
local AllyCivilian = ScenarioInfo.AllyCivilian
local AeonNeutral = ScenarioInfo.AeonNeutral

-- How often should we check the health of the research building to
-- see if we should give warnings about its health level
local CheckResearchFacilityHealthInterval = 10

-- How many times we will try to give movement orders to a truck before giving up
-- local TruckOrderRepeatThreshold = 3
-- How long to wait after giving up before trying again
-- (The player will be notified each time we give up)
-- local SendTruckAgainDelay = 30

-- This will control whether or not to alert the player that a truck has arrived safely
local ReadyForTruckArrivedDialog = true
local ReadyForTruckRespawnDialog = true

local M1Attacks = 0
local M2Attacks = 0
local M3Attacks = 0

-- ### Routes and other tables of goodies
local AeonM1AirPatrol01Route = {
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point01'),
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point02'),
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point03'),
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point04'),
}

local AeonM1AirPatrol02Route = {
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol02_Point01'),
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol02_Point02'),
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol02_Point03'),
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol02_Point04'),
}

local AeonM1PeriodicAttackRoute = {
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_5'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_6'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_7'),
    ScenarioUtils.MarkerToPosition('Player_Start_Position'),
    ScenarioUtils.MarkerToPosition('Player_Base_1'),
    ScenarioUtils.MarkerToPosition('Player_Base_2'),
    ScenarioUtils.MarkerToPosition('Player_Base_3'),
}

local AllyResearchRepairPatrolRoute = {
    ScenarioUtils.MarkerToPosition('Research_Base_Repair_Route01'),
    ScenarioUtils.MarkerToPosition('Research_Base_Repair_Route02'),
    ScenarioUtils.MarkerToPosition('Research_Base_Repair_Route03'),
    ScenarioUtils.MarkerToPosition('Research_Base_Repair_Route04'),
}

local AeonM2FinalAttackRoute = {
    ScenarioUtils.MarkerToPosition('M2_Attack_Point01'),
    ScenarioUtils.MarkerToPosition('Research_Facility'),
}

local AeonM2HoldingPattern = {
    ScenarioUtils.MarkerToPosition('Attack_Staging_Point_1'),
    ScenarioUtils.MarkerToPosition('Attack_Staging_Point_2'),
}

local AeonM2PeriodicAttackPlayerRoute1 = {
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_1'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_2'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_3'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_4'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_5'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_6'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_7'),
    ScenarioUtils.MarkerToPosition('Player_Start_Position'),
    ScenarioUtils.MarkerToPosition('Player_Base_1'),
    ScenarioUtils.MarkerToPosition('Player_Base_2'),
    ScenarioUtils.MarkerToPosition('Player_Base_3'),
}

local AeonM2PeriodicAttackPlayerRoute2 = {
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_1'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_2'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_3'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_4'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_6'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_7'),
    ScenarioUtils.MarkerToPosition('Player_Start_Position'),
    ScenarioUtils.MarkerToPosition('Player_Base_1'),
    ScenarioUtils.MarkerToPosition('Player_Base_2'),
    ScenarioUtils.MarkerToPosition('Player_Base_3'),
}

local AeonM2PeriodicAttackPlayerRoute3 = {
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_1'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_2'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_3'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_4'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_5'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_6'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_7'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_8'),
    ScenarioUtils.MarkerToPosition('Player_Start_Position'),
    ScenarioUtils.MarkerToPosition('Player_Base_1'),
    ScenarioUtils.MarkerToPosition('Player_Base_2'),
    ScenarioUtils.MarkerToPosition('Player_Base_3'),
}

local AeonM2PeriodicAttackPlayerRouteAirOnly = {
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_1'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_2'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_3'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_Air_West_1'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_Air_West_2'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_Air_West_3'),
    ScenarioUtils.MarkerToPosition('Player_Base_2'),
    ScenarioUtils.MarkerToPosition('Player_Start_Position'),
    ScenarioUtils.MarkerToPosition('Player_Base_1'),
    ScenarioUtils.MarkerToPosition('Player_Base_3'),
}

local AeonM2PeriodicAttackResearchRoute1 = {
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_1'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_2'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_3'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NE_1'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NE_2'),
    ScenarioUtils.MarkerToPosition('Research_Facility'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_1'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_2'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_3'),
}

local AeonM2PeriodicAttackResearchRouteAirOnly = {
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_1'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_2'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_3'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_4'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_N_5'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_1'),
    ScenarioUtils.MarkerToPosition('Research_Facility'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_2'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_3'),
}

local AeonM2TruckAttackRoute1 = {
    ScenarioUtils.MarkerToPosition('Truck_Route_Point02'),
    ScenarioUtils.MarkerToPosition('Truck_Route_Point01'),
    ScenarioUtils.MarkerToPosition('Truck_Route_Point02'),
    ScenarioUtils.MarkerToPosition('Truck_Route_Point03'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_1'),
    ScenarioUtils.MarkerToPosition('Research_Facility'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_2'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_3'),
}

local AeonM2TruckAttackRoute2 = {
    ScenarioUtils.MarkerToPosition('Truck_Route_Point03'),
    ScenarioUtils.MarkerToPosition('Truck_Route_Point02'),
    ScenarioUtils.MarkerToPosition('Truck_Route_Point01'),
    ScenarioUtils.MarkerToPosition('Truck_Route_Point02'),
    ScenarioUtils.MarkerToPosition('Truck_Route_Point03'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_1'),
    ScenarioUtils.MarkerToPosition('Research_Facility'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_2'),
    ScenarioUtils.MarkerToPosition('Research_Attack_Point_3'),
}

local AeonM2TruckAttackRoute2 = {
    ScenarioUtils.MarkerToPosition('Civilian_Scout_Point03'),
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol02_Point02'),
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point03'),
}

local AeonM2NorthAttackRoute = {
    ScenarioUtils.MarkerToPosition('Civilian_Scout_Point03'),
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol02_Point02'),
    ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point03'),
    ScenarioUtils.MarkerToPosition('Player_Start_Position'),
}


local AeonM2LuthienAirPatrol = {
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_3'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_NW_5'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_Air_West_3'),
    ScenarioUtils.MarkerToPosition('Aeon_Path_Air_West_2'),
}

local AeonM2LuthienCrush = {
    ScenarioUtils.MarkerToPosition('Luthien_Defeat_1'),
    ScenarioUtils.MarkerToPosition('Civilian_Base_Position'),
}
--
-- Starter functions
--

function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()
    ScenarioFramework.GetLeaderAndLocalFactions()
end

function OnStart(self)
    -- This override will make sure that the Aeon army doesn't run into the unit cap
    SetArmyUnitCap(Aeon, 900)

    -- Restrict the map
    ScenarioFramework.SetPlayableArea('M1_Playable_Area', false)

    SetIgnorePlayableRect(Aeon, true)
    SetIgnorePlayableRect(AeonNeutral, true)
    SetIgnorePlayableRect(AllyResearch, true)
    SetIgnorePlayableRect(AllyCivilian, true)

    ScenarioFramework.SetUEFColor(Player1)
    ScenarioFramework.SetAeonColor(Aeon)
    ScenarioFramework.SetAeonColor(AeonNeutral)
    ScenarioFramework.SetUEFAllyColor(AllyResearch)
    ScenarioFramework.SetUEFAllyColor(AllyCivilian)
    local colors = {
        ['Player2'] = {67, 110, 238}, 
        ['Player3'] = {97, 109, 126}, 
        ['Player4'] = {255, 255, 255}
    }
    local tblArmy = ListArmies()
    for army, color in colors do
        if tblArmy[ScenarioInfo[army]] then
            ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
        end
    end

    -- Disable friendly AI sharing resources to players
    GetArmyBrain(AllyResearch):SetResourceSharing(false)
    GetArmyBrain(AllyCivilian):SetResourceSharing(false)
    
    -- Take away units that the player shouldn't have access to
    for _, player in ScenarioInfo.HumanPlayers do
         ScenarioFramework.AddRestriction(player,
             categories.NAVAL +
             categories.TECH2 +
             categories.TECH3 +
             categories.EXPERIMENTAL +
             categories.ueb3102 + -- Sonar buoy
             categories.ueb2109   -- Torpedo Launcher
         )
    end

    ScenarioFramework.RestrictEnhancements({'AdvancedEngineering',
                                            'T3Engineering',
                                            'ResourceAllocation',
                                            'RightPod Right',
                                            'ShieldGeneratorField',
                                            'TacticalMissile',
                                            'TacticalNukeMissile',
                                            'Teleporter',})

    ScenarioFramework.StartOperationJessZoom('Starting_Camera_Area', PreIntroNIS)
end

function PreIntroNIS()

    -- Set up a lot of the initial units

    -- Create the groups for the research ally that will be destroyed in subsequent attacks
    -- (These are no longer destroyed, and are even given to the player when the player arrives)
    ScenarioInfo.ResearchGroup = ScenarioUtils.CreateArmyGroup('AllyResearch', AdjustForDifficulty('Base'))
    ScenarioInfo.AeonEarlyPower = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_EconomyOutpost')

    -- Create some of the key units and save handles to them
    ScenarioInfo.PlayerCDR = ScenarioUtils.CreateArmyUnit('Player1', 'Commander')
    ScenarioInfo.PlayerCDR:PlayCommanderWarpInEffect()
    ScenarioInfo.PlayerCDR:SetCustomName(ArmyBrains[Player1].Nickname)

    -- spawn coop players too
    ScenarioInfo.CoopCDR = {}
    local tblArmy = ListArmies()
    coop = 1
    for iArmy, strArmy in pairs(tblArmy) do
        if iArmy >= ScenarioInfo.Player2 then
            ScenarioInfo.CoopCDR[coop] = ScenarioUtils.CreateArmyUnit(strArmy, 'Commander')
            ScenarioInfo.CoopCDR[coop]:PlayCommanderWarpInEffect()
            ScenarioInfo.CoopCDR[coop]:SetCustomName(ArmyBrains[iArmy].Nickname)
            coop = coop + 1
            WaitSeconds(0.5)
        end
    end

    ScenarioInfo.ResearchFacility = ScenarioUtils.CreateArmyUnit('AllyResearch', 'Research_Facility')
    ScenarioInfo.ResearchFacility:SetReclaimable(false)

    -- Set up a trigger to go off if the commander dies
    ScenarioFramework.CreateUnitDeathTrigger(PlayerCommanderDied, ScenarioInfo.PlayerCDR)
    -- Delay the explosion so that we can catch it on camera
    ScenarioFramework.PauseUnitDeath(ScenarioInfo.PlayerCDR)

    for index, coopACU in ScenarioInfo.CoopCDR do
        ScenarioFramework.PauseUnitDeath(coopACU)
        ScenarioFramework.CreateUnitDeathTrigger(PlayerCommanderDied, coopACU)
    end

    -- Set up a trigger to go off if the Research Facility dies
    ScenarioFramework.CreateUnitDeathTrigger(ResearchFacilityDied, ScenarioInfo.ResearchFacility)

    ScenarioInfo.M1AirPatrol01 = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M1_Air_Patrol01'),'NoFormation')
    ScenarioInfo.M1AirPatrol02 = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M1_Air_Patrol02'),'NoFormation')

    GivePlatoonInfiniteFuel(ScenarioInfo.M1AirPatrol01)
    GivePlatoonInfiniteFuel(ScenarioInfo.M1AirPatrol02)

    local TriggerHandle = {
        Active = true,
        Name = 'AeonPlatoonDeath1',
        Type = 'Platoon Death',
        Parameters = {
            Platoon = ScenarioInfo.M1AirPatrol01,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    TriggerHandle = {
        Active = true,
        Name = 'AeonPlatoonDeath2',
        Type = 'Platoon Death',
        Parameters = {
            Platoon = ScenarioInfo.M1AirPatrol02,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    ScenarioInfo.M1GroundPatrol01 = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_Patrol01')
    ScenarioInfo.M1GroundPatrol02 = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_Patrol02')
    ScenarioInfo.M1GroundPatrol03 = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_Patrol03')
    ScenarioInfo.M1GroundPatrol04 = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_Patrol04')
    ScenarioInfo.M1GroundPatrol05 = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_Patrol05')
    ScenarioInfo.M1GroundPatrol06 = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_Patrol06')
    ScenarioInfo.M1GroundPatrol07 = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_Patrol07')
    ScenarioInfo.M1GroundPatrol08 = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_Patrol08')

    -- I'm setting these patrols to go between markers; these markers
    -- were originally placed for other purposes, so have names that may look odd when
    -- used for this purpose
    IssuePatrol(ScenarioInfo.M1GroundPatrol01, ScenarioUtils.MarkerToPosition('Aeon_Path_NW_6'))
    IssuePatrol(ScenarioInfo.M1GroundPatrol01, ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point02'))

    IssuePatrol(ScenarioInfo.M1GroundPatrol02, ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point02'))
    IssuePatrol(ScenarioInfo.M1GroundPatrol02, ScenarioUtils.MarkerToPosition('Aeon_Path_N_7'))

    IssuePatrol(ScenarioInfo.M1GroundPatrol03, ScenarioUtils.MarkerToPosition('Aeon_Path_N_7'))
    IssuePatrol(ScenarioInfo.M1GroundPatrol03, ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point03'))

    IssuePatrol(ScenarioInfo.M1GroundPatrol04, ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point03'))
    IssuePatrol(ScenarioInfo.M1GroundPatrol04, ScenarioUtils.MarkerToPosition('Aeon_Path_N_6'))

    IssuePatrol(ScenarioInfo.M1GroundPatrol05, ScenarioUtils.MarkerToPosition('Aeon_Path_N_6'))
    IssuePatrol(ScenarioInfo.M1GroundPatrol05, ScenarioUtils.MarkerToPosition('Aeon_Path_N_5'))

    IssuePatrol(ScenarioInfo.M1GroundPatrol06, ScenarioUtils.MarkerToPosition('Aeon_Path_N_5'))
    IssuePatrol(ScenarioInfo.M1GroundPatrol06, ScenarioUtils.MarkerToPosition('M1_Air_Patrol02_Point02'))

    IssuePatrol(ScenarioInfo.M1GroundPatrol07, ScenarioUtils.MarkerToPosition('M1_Air_Patrol02_Point02'))
    IssuePatrol(ScenarioInfo.M1GroundPatrol07, ScenarioUtils.MarkerToPosition('Aeon_Path_N_4'))

    IssuePatrol(ScenarioInfo.M1GroundPatrol08, ScenarioUtils.MarkerToPosition('Aeon_Path_NW_5'))
    IssuePatrol(ScenarioInfo.M1GroundPatrol08, ScenarioUtils.MarkerToPosition('Aeon_Path_NW_6'))


    TriggerHandle = {
        Active = true,
        Name = 'AeonGroupDeath1',
        Type = 'Group Death',
        Parameters = {
            Group = ScenarioInfo.M1GroundPatrol01,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    TriggerHandle = {
        Active = true,
        Name = 'AeonGroupDeath2',
        Type = 'Group Death',
        Parameters = {
            Group = ScenarioInfo.M1GroundPatrol02,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    TriggerHandle = {
        Active = true,
        Name = 'AeonGroupDeath3',
        Type = 'Group Death',
        Parameters = {
            Group = ScenarioInfo.M1GroundPatrol03,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    TriggerHandle = {
        Active = true,
        Name = 'AeonGroupDeath4',
        Type = 'Group Death',
        Parameters = {
            Group = ScenarioInfo.M1GroundPatrol04,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    TriggerHandle = {
        Active = true,
        Name = 'AeonGroupDeath5',
        Type = 'Group Death',
        Parameters = {
            Group = ScenarioInfo.M1GroundPatrol05,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    TriggerHandle = {
        Active = true,
        Name = 'AeonGroupDeath6',
        Type = 'Group Death',
        Parameters = {
            Group = ScenarioInfo.M1GroundPatrol06,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    TriggerHandle = {
        Active = true,
        Name = 'AeonGroupDeath7',
        Type = 'Group Death',
        Parameters = {
            Group = ScenarioInfo.M1GroundPatrol07,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    TriggerHandle = {
        Active = true,
        Name = 'AeonGroupDeath8',
        Type = 'Group Death',
        Parameters = {
            Group = ScenarioInfo.M1GroundPatrol08,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    local ActionHandle = {
        Name = 'AeonPatrolsDefeatedM1',
        ActionConditions = {
            {
                'AeonPlatoonDeath1',
                'AeonPlatoonDeath2',
                'AeonGroupDeath1',
                'AeonGroupDeath2',
                'AeonGroupDeath3',
                'AeonGroupDeath4',
                'AeonGroupDeath5',
                'AeonGroupDeath6',
                'AeonGroupDeath7',
                'AeonGroupDeath8',
            },
        },
        Actions = {
            {
                ActionType = 'Function Call',
                Parameters = {
                    Functions = { AeonPatrolsDefeatedM1, },
                },
            },
        },
    }
    ScenarioInfo.TriggerManager:AddAction(ActionHandle)

    ScenarioFramework.PlatoonPatrolRoute(ScenarioInfo.M1AirPatrol01, AeonM1AirPatrol01Route)
    ScenarioFramework.PlatoonPatrolRoute(ScenarioInfo.M1AirPatrol02, AeonM1AirPatrol02Route)

    -- Set up the patrolling repair unit at the research base
    -- Removed to force the player to get over there in order to repair the facility
    -- local PatrollingEngineer = ScenarioUtils.SpawnPlatoon('AllyResearch', 'Repair_Patrol01')
    -- ScenarioFramework.PlatoonPatrolRoute(PatrollingEngineer, AllyResearchRepairPatrolRoute)

    TriggerHandle = {
        Active = true,
        Name = 'CommanderAtResearchFacility',
        Type = 'Area',
        Parameters = {
            Rectangle = { ScenarioUtils.AreaToRect('Research_Area'), },
            Category = categories.UEF * categories.ENGINEER,
            Brain = ArmyBrains[Player1],
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    ActionHandle = {
        Name = 'CommanderArrived',
        ActionConditions = {
            { 'CommanderAtResearchFacility' },
        },
        Actions = {
            {
                ActionType = 'Function Call',
                Parameters = {
                    Functions = { CommanderArrived, },
                },
            },
        },
    }
    ScenarioInfo.TriggerManager:AddAction(ActionHandle)

    TriggerHandle = {
        Active = true,
        Name = 'TransportBuiltTrigger',
        Type = 'Army Stats',
        Parameters = {
            StatName = 'Units_Active',
            Number = 1,
            Brain = ArmyBrains[Player1],
            Category = categories.TRANSPORTATION,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    ActionHandle = {
        Name = 'TransportBuiltAction',
        ActionConditions = {
            { 'TransportBuiltTrigger' },
        },
        Actions = {
            {
                ActionType = 'Function Call',
                Parameters = {
                    Functions = { TransportBuilt, },
                },
            },
        },
    }
    ScenarioInfo.TriggerManager:AddAction(ActionHandle)

    TriggerHandle = {
        Active = true,
        Name = 'AirFactoryBuiltTrigger',
        Type = 'Army Stats',
        Parameters = {
            StatName = 'Units_Active',
            Number = 1,
            Brain = ArmyBrains[Player1],
            Category = categories.FACTORY * categories.AIR,
        },
    }
    ScenarioInfo.TriggerManager:AddTrigger(TriggerHandle)

    ActionHandle = {
        Name = 'AirFactoryBuiltAction',
        ActionConditions = {
            { 'AirFactoryBuiltTrigger' },
        },
        Actions = {
            {
                ActionType = 'Function Call',
                Parameters = {
                    Functions = { AirFactoryBuilt, },
                },
            },
        },
    }
    ScenarioInfo.TriggerManager:AddAction(ActionHandle)

    -- Make the research facility get damaged
    CauseInitialResearchFacilityDamage()

    -- It looks like we're cutting all NIS's in this op, so this will probably be permanent...
    if not SkipM1IntroNIS then
        IntroNIS()
    else
        ScenarioFramework.CreateTimerTrigger(BeginMission1, 4.8)
        -- !BeginMission1()
    end
end

function IntroNIS()

    -- This is a marker that happens to be located centrally, so I'm using it to expose the map during the NIS
    ScenarioFramework.CreateVisibleAreaLocation(500, ScenarioUtils.MarkerToPosition('M1_Air_Patrol01_Point04'), 27, ArmyBrains[Player1])

    -- Now for the real NIS stuff: camera movements!

    -- Start things off
    Cinematics.EnterNISMode()

    -- Play the video after a brief delay
    ForkThread(PlayNIS1Video)

    -- Snap the camera to the view of the research base instantly
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Camera_M1_Intro_01'))

    -- Move the camera around the base a bit
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Camera_M1_Intro_02'), 10)

    -- Let the player absorb what they're seeing
    WaitSeconds(3)

    -- Whisk the camera across the map to see where the UEF commander is in relation to this base
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Camera_M1_Intro_03'), 10)

    -- Let the player absorb what they're seeing
    WaitSeconds(3)

    -- Bring the camera all the way back out to the highest zoom-out level
    Cinematics.CameraReset()

    -- Let the player absorb what they're seeing
    WaitSeconds(3)

    -- And we're done
    Cinematics.ExitNISMode()

    ScenarioFramework.CreateTimerTrigger(BeginMission1,  4.8)
    -- !BeginMission1()

end

function CauseInitialResearchFacilityDamage()
    local newHealth =(M1ResearchFacilityInitialHealthPercentage / 100) * ScenarioInfo.ResearchFacility:GetMaxHealth()
    ScenarioInfo.ResearchFacility:SetHealth(ScenarioInfo.ResearchFacility, newHealth)
    ScenarioInfo.ResearchFacilityCurrentHealth = newHealth
    ScenarioFramework.CreateTimerTrigger(HurtResearchFacility, M1ResearchFacilityHealthDrainInterval)
    -- Show the player how long they have to repair the building with an onscreen timer
    ScenarioInfo.CountdownTimer = ScenarioFramework.CreateTimerTrigger(KillResearchFacility, M1ResearchFacilityMinutesUntilDead[ Difficulty ] * 60, true)
end

function KillResearchFacility()
    CheckResearchFacilityHealth()
    WaitSeconds(0.5)
    if not ScenarioInfo.ResearchFacilityRepaired then
        ScenarioInfo.ResearchFacility:Kill()
    end
end

function BeginMission1()
    ScenarioInfo.VarTable['Mission1'] = true

    ScenarioFramework.SetSharedUnitCap(300)

    -- Bonus Objective 1
    -- ScenarioFramework.CreateArmyUnitCategoryVeterancyTrigger(KilledBonus, ArmyBrains[ Player1 ], categories.uea0203, BonusVeterancyLevelNeeded)

    -- Bonus Objective 2
    -- ScenarioFramework.CreateArmyStatTrigger(EnergyBonus, ArmyBrains[ Player1 ], 'Generator',
    -- {{ StatType = 'Economy_TotalProduced_Energy', CompareType = 'GreaterThan', Value = BonusEnergyAmount }})

    -- Look at the commander
    -- Cinematics.CameraMoveToRectangle(ScenarioUtils.AreaToRect('Starting_Camera_Area'))

    -- The research base allies with the player
    for _, player in ScenarioInfo.HumanPlayers do
        SetAlliance(player, AllyResearch, 'Ally')
    end

    ScenarioFramework.Dialogue(OpStrings.E02_M01_010)
    ScenarioInfo.M1P1 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M1P1Text,
        OpStrings.M1P1Detail,
        Objectives.GetActionIcon('build'),
        {
            Area = 'Starting_Camera_Area',
            Category = categories.ueb0102,
            -- MarkArea = true,
        }
   )
    ScenarioInfo.M1P3 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M1P3Text,
        OpStrings.M1P3Detail,
        Objectives.GetActionIcon('repair'),
        {
            Units = {ScenarioInfo.ResearchFacility},
            MarkUnits = true,
        }
   )
    ScenarioFramework.Dialogue(ScenarioStrings.NewPObj)

    -- If the player doesn't complete the objective soon, remind him that it's important
    ScenarioFramework.CreateTimerTrigger(M1P1Reminder, M1P1InitialReminderDelay)

    -- removed    ScenarioFramework.CreateTimerTrigger(M1AttackResearchFacilityLight, 1)
    ScenarioFramework.CreateTimerTrigger(AttackPlayerM1, M1PeriodicAttackPlayerInitialDelay[ Difficulty ])
    ScenarioFramework.CreateTimerTrigger(EarlyAttackPlayerM1, M1EarlyAttackPlayerInitialDelay[ Difficulty ])
    ScenarioFramework.CreateTimerTrigger(DropPlayerM1, M1DropPlayerInitialDelay [ Difficulty ])

    -- Dialog that will appear after a certain amount of time
    ScenarioFramework.CreateTimerTrigger(Dialogue_M1_1, M1_Dialogue_Delay_1)
    ScenarioFramework.CreateTimerTrigger(Dialogue_M1_2, M1_Dialogue_Delay_2)
    ScenarioFramework.CreateTimerTrigger(CheckResearchFacilityHealth, CheckResearchFacilityHealthInterval)

    --Create Aeon transport rally beacon + destroy location
    ScenarioInfo.DestroyTrigger = ScenarioFramework.CreateAreaTrigger(DestroyUnit, ScenarioUtils.AreaToRect('Transport_Rally'), categories.AEON,
        false, false, ArmyBrains[Aeon])
end

function DestroyUnit(unit)
    unit:Destroy()
end

function Dialogue_M1_1()
    if ScenarioInfo.MissionNumber == 1 then
        ScenarioFramework.Dialogue(OpStrings.E02_M01_040)
    end
end

function Dialogue_M1_2()
    if ScenarioInfo.MissionNumber == 1 then
        ScenarioFramework.Dialogue(OpStrings.E02_M01_050)
    end
end

function AttackPlayerM1()
    local newPlatoon

    if ScenarioInfo.MissionNumber <2 then
        -- See how many times we have attacked already
        -- Spawn the appropriate force
        if M1Attacks < M1AttacksBecomeMediumSizedAfter then
            -- Small
            newPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M1_Attack_Small'), 'AttackFormation')
        elseif M1Attacks < M1AttacksBecomeLargeSizedAfter then
            -- Medium
            newPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M1_Attack_Medium'), 'AttackFormation')
            --- M1_LandAttack()
        else
            -- Large
            newPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M1_Attack_Large'), 'AttackFormation')
            M1_LandAttack()
        end

        -- Send them at the player
        ScenarioFramework.PlatoonPatrolRoute(newPlatoon, AeonM1PeriodicAttackRoute)

        -- We have attacked one more time now
        M1Attacks = M1Attacks + 1

        -- Call this function again after the appropriate delay
        ScenarioFramework.CreateTimerTrigger(AttackPlayerM1, M1PeriodicAttackPlayerDelay[ Difficulty ])
    end
end

function M1_LandAttack()
    local newPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M1_LandAttack'), 'AttackFormation')
    -- Send them at the player
    ScenarioFramework.PlatoonPatrolRoute(newPlatoon, AeonM1PeriodicAttackRoute)
end

function GivePlatoonInfiniteFuel(platoon)
    for i, unit in platoon:GetPlatoonUnits() do
        unit:SetFuelUseTime(999999)
    end
end

function EarlyAttackPlayerM1()
    local newPlatoon

    if ScenarioInfo.MissionNumber == 1 then
        --newP_landlatoon = ScenarioUtils.SpawnPlatoon('Aeon', AdjustForDifficulty('M1_EarlyAttack'))
        newPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M1_EarlyAttack'), 'NoFormation')

        -- Send them at the player
        ScenarioFramework.PlatoonPatrolRoute(newPlatoon, AeonM1PeriodicAttackRoute)
    end
end

function DropPlayerM1()
    if ScenarioInfo.MissionNumber < 3 then
        UpdateDifficultyModifier()

        if ScenarioInfo.M1DifficultyModifier >2 then
            UpdateNextBaseDrop()
            AirAttackPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop)
            DropPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop, 'Player_Start_Position')
        end
        if ScenarioInfo.M1DifficultyModifier >1 then
            UpdateNextBaseDrop()
            AirAttackPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop)
            DropPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop, 'Player_Start_Position')
        end
         
        UpdateNextBaseDrop()
        AirAttackPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop)
        DropPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop, 'Player_Start_Position')

        -- Call this function again after the appropriate delay
        ScenarioFramework.CreateTimerTrigger(DropPlayerM1, M1PeriodicAttackPlayerDelay[ Difficulty ])
    end
end

function UpdateNextBaseDrop()
    if ScenarioInfo.NextBaseDrop == 0 then
        ScenarioInfo.NextBaseDrop = Random(1,4) 
    elseif ScenarioInfo.NextBaseDrop > 3 then
        ScenarioInfo.NextBaseDrop = 1
    else
        ScenarioInfo.NextBaseDrop = ScenarioInfo.NextBaseDrop + 1
    end
end

function UpdateDifficultyModifier()
    local area = 'Player_Base_Area'
    local Player1Strength = ScenarioFramework.NumCatUnitsInArea(categories.UEF, area, ArmyBrains[Player1])
    local Player2Strength = ScenarioFramework.NumCatUnitsInArea(categories.UEF, area, ArmyBrains[Player2])
    local Player3Strength = ScenarioFramework.NumCatUnitsInArea(categories.UEF, area, ArmyBrains[Player3])
    local Player4Strength = ScenarioFramework.NumCatUnitsInArea(categories.UEF, area, ArmyBrains[Player4])

    local PlayerStrength = Player1Strength + Player2Strength + Player3Strength + Player4Strength

    if PlayerStrength < M1DifficultyModifierUnitCountLevel1[Difficulty] then
        ScenarioInfo.M1DifficultyModifier = 1
    elseif PlayerStrength < M1DifficultyModifierUnitCountLevel2[Difficulty] then
        ScenarioInfo.M1DifficultyModifier = 2
    else
        ScenarioInfo.M1DifficultyModifier = 3
    end

end

function DropPlayerBase(DropPosition)
    if DropPosition then
        -- Spawn them
        local AttackGroup = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_DropUnits')
        local Transports = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_DropTransports', 'ChevronFormation')
        Transports:UnloadAllAtLocation(ScenarioUtils.MarkerToPosition(DropPosition))

        IssueMove(Transports:GetPlatoonUnits(), ScenarioUtils.MarkerToPosition('Transport_Rally'))

        ForkThread(WaitForUnloadBaseDrop, AttackGroup, Transports)

        ScenarioFramework.AttachUnitsToTransports(AttackGroup, Transports:GetPlatoonUnits())
    end    
end

function AttackPlayerM2()
    if ScenarioInfo.MissionNumber == 2 then
        local AttackRoute
        local randomNumber = Random(0,2)
        if randomNumber == 0 then
            AttackRoute = AeonM2PeriodicAttackPlayerRoute1
        elseif randomNumber == 1 then
            AttackRoute = AeonM2PeriodicAttackPlayerRoute2
        elseif randomNumber == 2 then
            AttackRoute = AeonM2PeriodicAttackPlayerRoute3
        else
            AttackRoute = AeonM2PeriodicAttackResearchRoute1
        end

        -- See how many times we have attacked already
        -- Spawn the appropriate force
        if M2Attacks < M2AttacksBecomeMediumSizedAfter then
            -- Small
            AeonScriptedAttack(AdjustForDifficulty('M2_Attack_Small'), AttackRoute,'AttackFormation')
        elseif M2Attacks < M2AttacksBecomeLargeSizedAfter then
            -- Medium
            AeonScriptedAttack(AdjustForDifficulty('M2_Attack_Medium'), AttackRoute,'AttackFormation')
            AeonScriptedAttack(AdjustForDifficulty('M2_Attack_Air'), AttackRoute,'ChevronFormation')
        else
            -- Large
            AeonScriptedAttack(AdjustForDifficulty('M2_Attack_Large'), AttackRoute,'AttackFormation')
            AeonScriptedAttack(AdjustForDifficulty('M2_Attack_Air'), AttackRoute,'ChevronFormation')
        end

        -- We have attacked one more time now
        M2Attacks = M2Attacks + 1

        --M2 North Route Attack --Was it's own function, now uses AeonScriptedAttack
        AeonScriptedAttack(AdjustForDifficulty('M2_NorthRouteAttack'), AeonM2NorthAttackRoute,'AttackFormation')

        -- Call this function again after the appropriate delay
        ScenarioFramework.CreateTimerTrigger(AttackPlayerM2, M2PeriodicAttackPlayerDelay[ Difficulty ])
    end
end

function AeonScriptedAttack(ArmyGroup, Chain, Formation)
    if not Formation then
        Formation = 'NoFormation'
    end
    newPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', ArmyGroup, Formation)
    ScenarioFramework.PlatoonPatrolRoute(newPlatoon, Chain)
end



function DropLuthienM2(DropPositionNumber)
    if ScenarioInfo.MissionNumber == 2 then
        local DropPosition = Random(0,3)

        if DropPositionNumber == 1 then
            DropPosition = 'Aeon_Path_Air_West_1'  
        elseif DropPositionNumber == 2 then
            DropPosition = 'Aeon_Path_NW_1'
        else
            DropPosition = 'Aeon_Path_Air_West_2'
        end
            
        if DropPosition then
            -- Spawn them
            local AttackGroup = ScenarioUtils.CreateArmyGroup('Aeon', 'M1_DropUnits')
            local Transports = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_DropTransports', 'ChevronFormation')
            Transports:UnloadAllAtLocation(ScenarioUtils.MarkerToPosition(DropPosition))
            IssueMove(Transports:GetPlatoonUnits(), ScenarioUtils.MarkerToPosition('Transport_Rally'))

            ForkThread(WaitForUnloadLuthienDrop, AttackGroup, Transports)

            ScenarioFramework.AttachUnitsToTransports(AttackGroup, Transports:GetPlatoonUnits())
        end
        ScenarioFramework.CreateTimerTrigger(DropLuthienM2, M2PeriodicAttackPlayerDelay[ Difficulty ])
    end    
end


function AttackPlayerM3()

    if ScenarioInfo.MissionNumber == 3 then

        local randomSquadGeneration = Random(0, SendLandSquadChance + SendAirSquadChance + SendLandAndAirSquadChance)

        if randomSquadGeneration <(SendLandSquadChance) then
            ScenarioInfo.VarTable['LaunchLandAttack'] = true
        elseif randomSquadGeneration <(SendLandSquadChance + SendAirSquadChance) then
            ScenarioInfo.VarTable['LaunchAirAttack'] = true
        else
            ScenarioInfo.VarTable['LaunchLandAttack'] = true
            ScenarioInfo.VarTable['LaunchAirAttack'] = true
        end

        if ScenarioFramework.UnitsInAreaCheck(categories.UEF, ScenarioUtils.AreaToRect('Player_Base_Area')) then
            local AttackPlayerBase = true
            -- See which route the platoon should follow
            local randomNumber = Random(0, AttackPlayerRoute1Chance + AttackPlayerRoute2Chance + AttackPlayerRoute3Chance + AttackResearchChance)
            if randomNumber < AttackPlayerRoute1Chance then
                ScenarioInfo.VarTable['UseLandRoute1'] = true
            elseif randomNumber < (AttackPlayerRoute1Chance + AttackPlayerRoute2Chance) then
                ScenarioInfo.VarTable['UseLandRoute2'] = true
            elseif randomNumber < (AttackPlayerRoute1Chance + AttackPlayerRoute2Chance + AttackPlayerRoute3Chance) then
                ScenarioInfo.VarTable['UseLandRoute3'] = true
            else
                ScenarioInfo.VarTable['AttackResearchFacility'] = true
            end
        else
            -- Player has moved out of the starting location,
            -- so we send attacks to the research base location
            ScenarioInfo.VarTable['AttackResearchFacility'] = true
        end

        -- Call this function again after the appropriate delay
        ScenarioFramework.CreateTimerTrigger(AttackPlayerM3, M3PeriodicAttackPlayerDelay[ Difficulty ])
    end
end

-- function M1AttackResearchFacilityLight()
-- if not ScenarioInfo.StopPeriodicAttacks then
--    # Make it happen again
--    ScenarioFramework.CreateTimerTrigger(M1AttackResearchFacilityLight, M1PeriodicAttackDelayResearch)
--
--    # Generate the attack squad and send them off
--    local AttackPlatoon = ScenarioUtils.SpawnPlatoon('Aeon', 'Research_Airstrike_Small')
--    ScenarioFramework.PlatoonPatrolRoute(AttackPlatoon, {'M1_Research_Attack_Patrol_1',
--                                                            'M1_Research_Attack_Patrol_2',
--                                                            'M1_Research_Attack_Patrol_3',})
-- end
-- end

function HurtResearchFacility()

    -- If it's dead, the player has lost already, and we don't need to go through all of this
    if ScenarioInfo.ResearchFacility:IsDead() then
        return
    end

    if not ScenarioInfo.ResearchFacilityRepaired then
        CheckResearchFacilityHealth()
    end

    WaitSeconds(0.5)

    if not ScenarioInfo.ResearchFacilityRepaired then
        if ScenarioInfo.ResearchDamageTicks then
            ScenarioInfo.ResearchDamageTicks = ScenarioInfo.ResearchDamageTicks + 1
        else
            ScenarioInfo.ResearchDamageTicks = 1
            -- ## Matt 12/20/06 used below to base the calcuation off the more dependable gametime
            ScenarioInfo.StartDamagerTimerTarget = math.floor(GetGameTimeSeconds()) + (M1ResearchFacilityMinutesUntilDead[ Difficulty ] * 60)
        end

        local maxHealth =(M1ResearchFacilityInitialHealthPercentage / 100) * ScenarioInfo.ResearchFacility:GetMaxHealth()
        local TimeTotal = M1ResearchFacilityMinutesUntilDead[ Difficulty ] * 60 -- convert to seconds
        -- why 0.81 at the end of this next line?  well...0.5 for the WaitSeconds(0.5) just above this,
        -- and after much experimenting, the time it takes to go through this script loop
        -- necessitates a bit more time per loop.  It's not exact and feels dirty, but another 0.31 gets it close.
        -- Since the building dies as the timer hits 0, it doesn't need to be *too* close.

        -- ##local TimeLeft = TimeTotal -(ScenarioInfo.ResearchDamageTicks *(M1ResearchFacilityHealthDrainInterval + 0.81))

        -- ## Matt 12/20/06 converting this to base the calcuation off the more dependable gametime
        local TimeLeft = ScenarioInfo.StartDamagerTimerTarget - math.floor(GetGameTimeSeconds())
        local newHealth = maxHealth *(TimeLeft / TimeTotal)
        if newHealth > 1 then
            ScenarioInfo.ResearchFacility:SetHealth(ScenarioInfo.ResearchFacility, newHealth)
            ScenarioInfo.ResearchFacilityCurrentHealth = newHealth
        end
        -- we dont want 2 things killing the facility. Now only the visible timer will actually kill it  Matt 12/20
        -- else
        -- ScenarioInfo.ResearchFacility:Kill()
        -- end
        ScenarioFramework.CreateTimerTrigger(HurtResearchFacility, M1ResearchFacilityHealthDrainInterval)
    end
end

function CheckResearchFacilityHealth()

    -- If it's dead, the player has lost already, and we don't need to go through all of these checks
    if ScenarioInfo.ResearchFacility:IsDead() then
        return
    end

    if ScenarioInfo.ResearchFacility:GetHealth() > ScenarioInfo.ResearchFacilityCurrentHealth and not ScenarioInfo.ResearchFacilityRepaired then
        ScenarioInfo.ResearchFacilityRepaired = true
        ScenarioFramework.ResetUITimer()
        ScenarioInfo.CountdownTimer:Destroy()
        ResearchFacilityRepaired()
    end

    if not ScenarioInfo.ResearchFacilityRepaired then

        local currentHealthPercentage = math.floor((ScenarioInfo.ResearchFacility:GetHealth() * 100) / ScenarioInfo.ResearchFacility:GetMaxHealth())

        if currentHealthPercentage < ScenarioInfo.PreviousResearchHealthPercentage then
            ScenarioInfo.PreviousResearchHealthPercentage = currentHealthPercentage

            if currentHealthPercentage <= ResearchFacilityHealthThreshold1 and not ScenarioInfo.ResearchFacilityThreshold1Reached then
                ScenarioFramework.Dialogue(OpStrings.E02_M01_060)
                ScenarioInfo.ResearchFacilityThreshold1Reached = true
            elseif currentHealthPercentage <= ResearchFacilityHealthThreshold2 and not ScenarioInfo.ResearchFacilityThreshold2Reached then
                ScenarioFramework.Dialogue(OpStrings.E02_M01_070)
                ScenarioInfo.ResearchFacilityThreshold2Reached = true
            elseif currentHealthPercentage <= ResearchFacilityHealthThreshold3 and not ScenarioInfo.ResearchFacilityThreshold3Reached then
                ScenarioFramework.Dialogue(OpStrings.E02_M01_080)
                ScenarioInfo.ResearchFacilityThreshold3Reached = true
            end
        end

        -- Check again as long as we haven't given all of the warnings yet
        if not ScenarioInfo.ResearchFacilityThreshold3Reached then
            ScenarioFramework.CreateTimerTrigger(CheckResearchFacilityHealth, CheckResearchFacilityHealthInterval)
        end
    end
end

function AirFactoryBuilt()
    ScenarioFramework.Dialogue(OpStrings.E02_M01_020)
    ScenarioInfo.M1P1:ManualResult(true)

    -- Add the next objective
    ScenarioInfo.M1P15 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M1P15Text,
        OpStrings.M1P15Detail,
        Objectives.GetActionIcon('build'),
        {
            Category = categories.uea0107,
            -- Area = 'Research_Area',
            -- MarkArea = true,
        }
   )

    -- Add the secondary objective of killing all patrols if they're not already dead
    if not ScenarioInfo.AeonPatrolsDefeatedM1 then
        ScenarioInfo.M1S1 = Objectives.Basic(
            'secondary',
            'incomplete',
            OpStrings.M1S1Text,
            OpStrings.M1S1Detail,
            Objectives.GetActionIcon('kill'),
            {
                ShowFaction = 'Aeon',
                -- Units = {ScenarioInfo.ResearchFacility},
                -- MarkUnits = true,
            }
       )
        ScenarioInfo.M1S1Assigned = true
        ScenarioFramework.Dialogue(ScenarioStrings.NewSObj)
    end
end

function TransportBuilt()
    -- Now that the transport is built, give the objective of transporting the commander to the research facility
    ScenarioInfo.M1P15:ManualResult(true)

    -- Stop the reminder text from playing
    ScenarioInfo.M1P1Complete = true

    -- Add the next objective
    ScenarioInfo.M1P2 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M1P2Text,
        OpStrings.M1P2Detail,
        Objectives.GetActionIcon('move'),
        {
            Area = 'Research_Area',
            MarkArea = true,
        }
   )

    ScenarioFramework.Dialogue(ScenarioStrings.PObjComp)
    ScenarioFramework.Dialogue(OpStrings.E02_M01_030)
end

-- This was changed to allow the commander *or* an engineer to fulfill this goal
function CommanderArrived()

    -- Give ally base buildings to the player
    for k, unit in ScenarioInfo.ResearchGroup do
        if not unit:IsDead() then
            ScenarioFramework.GiveUnitToArmy(unit, Player1)
        end
    end

    local health = ScenarioInfo.ResearchFacility:GetHealth()
    ScenarioInfo.ResearchFacility = ScenarioFramework.GiveUnitToArmy(ScenarioInfo.ResearchFacility, Player1)
    ScenarioInfo.ResearchFacility:SetReclaimable(false)
    ScenarioInfo.ResearchFacility:SetHealth(ScenarioInfo.ResearchFacility, health)
    -- Set up a trigger to go off if the (new) Research Facility dies
    ScenarioFramework.CreateUnitDeathTrigger(ResearchFacilityDied, ScenarioInfo.ResearchFacility)

    -- complete the relevant objective
    ScenarioInfo.M1P2:ManualResult(true)
    ScenarioFramework.Dialogue(ScenarioStrings.PObjComp)

    -- If the player doesn't complete the objective soon, remind him that it's important
    ScenarioFramework.CreateTimerTrigger(M1P3Reminder, M1P3InitialReminderDelay)

    -- "Thanks for arriving..."
    ScenarioFramework.Dialogue(OpStrings.E02_M01_090)
end

function AeonPatrolsDefeatedM1()
    if not ScenarioInfo.M1S1Assigned then
        ScenarioInfo.M1S1 = Objectives.Basic(
            'secondary',
            'complete',
            OpStrings.M1S1Text,
            OpStrings.M1S1Detail,
            Objectives.GetActionIcon('kill'),
            {
            }
       )
    else
        ScenarioInfo.M1S1:ManualResult(true)
    end
    ScenarioFramework.Dialogue(ScenarioStrings.SObjComp)
    ScenarioInfo.AeonPatrolsDefeatedM1 = true
    ScenarioFramework.Dialogue(OpStrings.E02_M01_140)
end

function ResearchFacilityRepaired()
    ScenarioInfo.ResearchFacilityRepaired = true

    -- complete the relevant objective
    ScenarioInfo.M1P3:ManualResult(true)
    ScenarioFramework.Dialogue(ScenarioStrings.PObjComp)

    ScenarioInfo.M1P3Complete = true

    ScenarioFramework.Dialogue(OpStrings.E02_M01_160)

    -- stop the periodic small attacks
    ScenarioInfo.StopPeriodicAttacks = true

    -- Research Facility Repaired
    local unit = ScenarioInfo.ResearchFacility
    local camInfo = {
        blendTime = 1.0,
        holdTime = 6.0,
        orientationOffset = { -0.9269, 0.2, 0 },
        positionOffset = { 0, 1, 0 },
        zoomVal = 20,
    }
    ScenarioFramework.OperationNISCamera(unit, camInfo)

    EndMission1()
end

function EndMission1()
    ScenarioFramework.Dialogue(ScenarioStrings.MissionSuccessDialogue)

    BeginMission1Point5()
end

function BeginMission1Point5()

    ScenarioFramework.SetSharedUnitCap(400)
 
    -- Tell the player that they need to defend the facility
    ScenarioFramework.Dialogue(OpStrings.E02_M02_010)
    ScenarioInfo.M15P1 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M15P1Text,
        OpStrings.M15P1Detail,
        Objectives.GetActionIcon('protect'),
        {
            Units = {ScenarioInfo.ResearchFacility},
            MarkUnits = true,
        }
   )

    AddTechMission15()
    ScenarioInfo.MissionNumber = 1.5

    -- This is for the next warning that they're coming soon
    ScenarioFramework.CreateTimerTrigger(M15WarningBeforeWave1, M15TimeUntilWarningBeforeWave1)

    ScenarioFramework.CreateTimerTrigger(M15DropPlayer, 20)

    M15SnipeAttack()
end

function M15DropPlayer()
    if ScenarioInfo.MissionNumber == 1.5  then
        UpdateDifficultyModifier()

        if ScenarioInfo.M1DifficultyModifier >2 then
            UpdateNextBaseDrop()
            AirAttackPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop)
            DropPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop, 'Player_Start_Position')
        end
        if ScenarioInfo.M1DifficultyModifier >1 then
            UpdateNextBaseDrop()
            AirAttackPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop)
            DropPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop, 'Player_Start_Position')
        end
         
        UpdateNextBaseDrop()
        AirAttackPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop)
        DropPlayerBase('Player_Base_' .. ScenarioInfo.NextBaseDrop, 'Player_Start_Position')

        ---Same as M1 drop, but only runs once
    end
end

function AirAttackPlayerBase(FirstPatrolPoint)
    local AirPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M1_Drop_Escort'), 'ChevronFormation')
    local PatrolRoute = {
        ScenarioUtils.MarkerToPosition(FirstPatrolPoint),
        ScenarioUtils.MarkerToPosition('Player_Start_Position'),
        ScenarioUtils.MarkerToPosition('Player_Base_1'),
        ScenarioUtils.MarkerToPosition('Player_Base_2'),
        ScenarioUtils.MarkerToPosition('Player_Base_3'),
    }
    IssueMove(AirPlatoon:GetPlatoonUnits(), ScenarioUtils.MarkerToPosition('Player_Drop_Staging')) --Mostly to make sure they avoid Luthien in M2
    ScenarioFramework.PlatoonPatrolRoute(AirPlatoon, PatrolRoute)
end

function M15SnipeAttack()
    --Spawn one for the first player
    local AirGroup = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M1_Drop_Escort'), 'ChevronFormation')
    local PatrolRoute = {
        ScenarioInfo.PlayerCDR:GetPosition(),
        ScenarioUtils.MarkerToPosition('Player_Start_Position'),
    }
    ScenarioFramework.PlatoonPatrolRoute(AirGroup, PatrolRoute)

    --And spawn one for each other player, too
    for index, coopACU in ScenarioInfo.CoopCDR do
        AirGroup = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M1_Drop_Escort'), 'ChevronFormation')
        PatrolRoute = {
            coopACU:GetPosition(),
            ScenarioUtils.MarkerToPosition('Player_Start_Position'),
        }
        ScenarioFramework.PlatoonPatrolRoute(AirGroup, PatrolRoute)
    end
    
end

function M15WarningBeforeWave1()
    -- another warning
    ScenarioFramework.Dialogue(OpStrings.E02_M02_020)

    -- Launch the first wave that the player is supposed to help defend against
    ScenarioFramework.CreateTimerTrigger(M15Wave1Attack, M15TimeUntilAttackOnResearchFacilityWave1)
end

function M15Wave1Attack()
    -- Warn the player that the attack is coming
    ScenarioFramework.Dialogue(OpStrings.E02_M02_030)

    -- Spawn them
    local AttackGroup = ScenarioUtils.CreateArmyGroup('Aeon', AdjustForDifficulty('M15_Wave1_Attackers'))
    
    -- Send them
    IssueAggressiveMove(AttackGroup, ScenarioUtils.MarkerToPosition('Research_Facility'))
    IssuePatrol(AttackGroup, ScenarioUtils.MarkerToPosition('M1_Research_Attack_Patrol_1'))
    IssuePatrol(AttackGroup, ScenarioUtils.MarkerToPosition('M1_Research_Attack_Patrol_2'))
    IssuePatrol(AttackGroup, ScenarioUtils.MarkerToPosition('M1_Research_Attack_Patrol_3'))

    -- Watch for when they die, air units trigger wave2delay
    ScenarioFramework.CreateGroupDeathTrigger(M15Wave2AttackDelay, AttackGroup)

    --Spawn land attack too
    M15LandAttack()
end

function M15LandAttack()
    local AttackGroup = ScenarioUtils.CreateArmyGroup('Aeon', AdjustForDifficulty('M15_LandAttack'))
    IssueAggressiveMove(AttackGroup, ScenarioUtils.MarkerToPosition('Research_Facility'))

    return AttackGroup
end

function M15Wave2AttackDelay()
    -- Launch it
    ScenarioFramework.CreateTimerTrigger(M15Wave2Attack, M15TimeUntilAttackOnResearchFacilityWave2)
end

function M15Wave2Attack()
    -- Play a random taunt
    PlayRandomTaunt()

    -- Warn the player that the attack is coming
    ScenarioFramework.Dialogue(OpStrings.E02_M02_035)

    --Wave 2 drop triggers wave 3 delay
    ScenarioFramework.CreateGroupDeathTrigger(M15Wave3AttackDelay, ResearchFacility_DropAttack(1))

    if Difficulty > 1 then
        ResearchFacility_DropAttack(2)
    end
    if Difficulty > 2 then
        ResearchFacility_DropAttack(math.random(3,4))
    end
    
    -- land attack too
    M15LandAttack()
end

function ResearchFacility_DropAttack (LandingPoint)
    -- Spawn them
    local AttackGroup = ScenarioUtils.CreateArmyGroup('Aeon', AdjustForDifficulty('M15_Wave2_Attackers'))
    local Transports = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M15_Transports', 'ChevronFormation')

    ScenarioFramework.AttachUnitsToTransports(AttackGroup, Transports:GetPlatoonUnits())

    Transports:UnloadAllAtLocation(ScenarioUtils.MarkerToPosition('Landing_Point_' .. LandingPoint))
    IssueMove(Transports:GetPlatoonUnits(), ScenarioUtils.MarkerToPosition('Transport_Rally'))

    ForkThread(WaitForUnload, AttackGroup, Transports)

    ScenarioFramework.CreateGroupDeathTrigger(Mission15PlatoonDefeated, AttackGroup)
    ScenarioFramework.CreatePlatoonDeathTrigger(Mission15TransportsDead, Transports)

    ScenarioInfo.AttackPlatoonsAlive = ScenarioInfo.AttackPlatoonsAlive + 1

    return AttackGroup
end

function WaitForUnload(Group1, Group2, Group3)
    WaitSeconds(2)
    local AllUnloaded = true
    for k, unit in Group1 do
        if(not unit:IsDead()) and unit:IsUnitState('Attached') then
            AllUnloaded = false
            break
        end
    end

    if AllUnloaded then
        -- LOG('All units are unloaded')
        -- On easy, they will patrol outside of the base
        -- Changing it back; all difficulties will attack the base itself
        -- if Difficulty == 1 then
        -- IssuePatrol(Group1, ScenarioUtils.MarkerToPosition('Landing_Point_1'))
        -- IssuePatrol(Group1, ScenarioUtils.MarkerToPosition('Landing_Point_3'))
        --
        -- Group2:Patrol(ScenarioUtils.MarkerToPosition('Landing_Point_1'))
        -- Group2:Patrol(ScenarioUtils.MarkerToPosition('Landing_Point_3'))
        --
        -- if Group3 then
        --    IssuePatrol(Group3, ScenarioUtils.MarkerToPosition('Landing_Point_1'))
        --    IssuePatrol(Group3, ScenarioUtils.MarkerToPosition('Landing_Point_3'))
        -- end
        -- else
            IssueAggressiveMove(Group1, ScenarioUtils.MarkerToPosition('Research_Facility'))
            IssuePatrol(Group1, ScenarioUtils.MarkerToPosition('M1_Research_Attack_Patrol_1'))
            IssuePatrol(Group1, ScenarioUtils.MarkerToPosition('M1_Research_Attack_Patrol_2'))
            IssuePatrol(Group1, ScenarioUtils.MarkerToPosition('M1_Research_Attack_Patrol_3'))

            if not ScenarioInfo.M15TransportsAreDead then
                Group2:Patrol(ScenarioUtils.MarkerToPosition('Research_Facility'))
                Group2:Patrol(ScenarioUtils.MarkerToPosition('M1_Research_Attack_Patrol_1'))
                Group2:Patrol(ScenarioUtils.MarkerToPosition('M1_Research_Attack_Patrol_2'))
                Group2:Patrol(ScenarioUtils.MarkerToPosition('M1_Research_Attack_Patrol_3'))
            end

    else
        -- LOG('Still loaded, checking again...')
        WaitSeconds(2)
        WaitForUnload(Group1, Group2, Group3)
    end
end

function WaitForUnloadBaseDrop(Group1, Group2)
    WaitSeconds(2)
    local AllUnloaded = true
    for k, unit in Group1 do
        if(not unit:IsDead()) and unit:IsUnitState('Attached') then
            AllUnloaded = false
            break
        end
    end

    if AllUnloaded then
            IssueAggressiveMove(Group1, ScenarioUtils.MarkerToPosition('Player_Start_Position'))
            IssuePatrol(Group1, ScenarioUtils.MarkerToPosition('Player_Base_1'))
            IssuePatrol(Group1, ScenarioUtils.MarkerToPosition('Player_Base_2'))
            IssuePatrol(Group1, ScenarioUtils.MarkerToPosition('Player_Base_3'))

    else
        -- LOG('Still loaded, checking again...')
        WaitSeconds(1)
        WaitForUnloadBaseDrop(Group1, Group2)
    end
end

function WaitForUnloadLuthienDrop(Group1, Group2)
    WaitSeconds(2)
    local AllUnloaded = true
    for k, unit in Group1 do
        if(not unit:IsDead()) and unit:IsUnitState('Attached') then
            AllUnloaded = false
            break
        end
    end

    if AllUnloaded then
            IssueAggressiveMove(Group1, ScenarioUtils.MarkerToPosition('Civilian_Base_Position'))
            IssuePatrol(Group1, ScenarioUtils.MarkerToPosition('Player_Start_Position'))

    else
        -- LOG('Still loaded, checking again...')
        WaitSeconds(2)
        WaitForUnloadLuthienDrop(Group1, Group2)
    end
end

function M15Wave3AttackDelay()
    -- Launch it
    ScenarioFramework.CreateTimerTrigger(M15Wave3Attack, M15TimeUntilAttackOnResearchFacilityWave3)
end

function M15Wave3Attack()
    -- Play a random taunt
    PlayRandomTaunt()

    -- Warn the player that the attack is coming
    ScenarioFramework.Dialogue(OpStrings.E02_M02_037)

    -- Again, the lead drop away from the base triggers next part, which here is M2
    ScenarioFramework.CreateGroupDeathTrigger(EndMission15, ResearchFacility_DropAttack(1))

    if Difficulty > 1 then
        ResearchFacility_DropAttack(2)
    end
    if Difficulty > 2 then
        ResearchFacility_DropAttack(math.random(3,4))
    end

    M15LandAttack()
end

function Mission15TransportsDead()
    ScenarioInfo.M15TransportsAreDead = true
end

function Mission15PlatoonDefeated()
    -- LOG('Attacking Platoon is dead')
    ScenarioInfo.AttackPlatoonsAlive = ScenarioInfo.AttackPlatoonsAlive - 1

    -- LOG('Platoons left: ', ScenarioInfo.AttackPlatoonsAlive)

    -- if ScenarioInfo.AttackPlatoonsAlive == 0 then
    --    EndMission15()
    -- end
end

function EndMission15()
    ScenarioFramework.Dialogue(ScenarioStrings.PObjComp)
    ScenarioFramework.Dialogue(ScenarioStrings.MissionSuccessDialogue)
    ScenarioInfo.M15P1:ManualResult(true)

    -- The enemy congratulates the player on defeating the attack
    ScenarioFramework.Dialogue(OpStrings.E02_M02_040)

    BeginMission2()
end

function BeginMission2()
    if ScenarioInfo.MissionNumber == 2 then
        return
    end

    ScenarioInfo.MissionNumber = 2

    -- Update the playable area
    ScenarioFramework.SetPlayableArea('M2_Playable_Area')
    ScenarioFramework.Dialogue(ScenarioStrings.MapExpansion)

    ScenarioFramework.SetSharedUnitCap(500)

    -- Unlock the T2 land factory
    AddTechMission2()

    -- Create the Civilian Base
    ScenarioInfo.CivilianFacility = ScenarioUtils.CreateArmyUnit('AllyCivilian', 'Civilian_Facility')
    -- This building is now invulnerable -- changing this for FAF harder version
    -- ScenarioInfo.CivilianFacility:SetCanTakeDamage(false)
    -- ScenarioInfo.CivilianFacility:SetCanBeKilled(false)
    ScenarioInfo.CivilianFacility:SetReclaimable(false)
    ScenarioInfo.CivilianFacility:SetCapturable(false)
    ScenarioInfo.CivilianFacility:SetCustomName(LOCF('<LOC planet_info_0040>Luthien'))

    -- Set up a trigger to go off if the Research Facility dies
    ScenarioFramework.CreateUnitDeathTrigger(CivilianFacilityDied, ScenarioInfo.CivilianFacility)

    -- Now they ally with the player (this used to happen later)
    for _, player in ScenarioInfo.HumanPlayers do
        SetAlliance(player, AllyCivilian, 'Ally')
    end

    -- the rest of the buildings/defenses
    ScenarioInfo.CivilianBase = ScenarioUtils.CreateArmyGroup('AllyCivilian', 'Structures')
    ScenarioInfo.CivilianBaseWalls = ScenarioUtils.CreateArmyGroup('AllyCivilian', 'Walls')

    -- Make Aeon T2 pgens in the M3 main base -- Making them here to provide T2 tank/shield gen power
    ScenarioUtils.CreateArmyGroup('Aeon', AdjustForDifficulty('M3_No_Rebuild')) 

    -- The colony asks for help
    ScenarioFramework.Dialogue(OpStrings.E02_M03_025)
    -- The player is told what to build
    ScenarioFramework.Dialogue(OpStrings.E02_M03_030)

    -- Add initial objectives
    ScenarioInfo.M2P1 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M2P1Text,
        LOCF(OpStrings.M2P1Detail, CivilianReinforcementsNeededTanks, CivilianReinforcementsNeededAntiAir, CivilianReinforcementsNeededGunships),
        Objectives.GetActionIcon('move'),
        {
            Area = 'Civilian_Area',
            MarkArea = true,
        }
   )

   ScenarioInfo.M2P2 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M2P2Text,
        OpStrings.M2P2Detail,
        Objectives.GetActionIcon('move'),
        {
            Area = 'Research_Area',
            MarkArea = true,
        }
   )

   ScenarioInfo.M2P3 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M2P3Text,
        OpStrings.M2P3Detail,
        Objectives.GetActionIcon('protect'),
        {
            Units = {ScenarioInfo.CivilianFacility},
            MarkUnits = true,
        }
   )
    Objectives.UpdateBasicObjective(ScenarioInfo.M2P2, 'progress', LOCF(OpStrings.TruckProgress, 0, TotalNumberOfTrucks[Difficulty]))

    ScenarioFramework.Dialogue(ScenarioStrings.NewPObj)

    -- If the player doesn't complete the objective soon, remind him that it's important
    ScenarioFramework.CreateTimerTrigger(M2P1Reminder, M2P1InitialReminderDelay)

    -- Detect when the player has helped the civilian base by getting land units there
    -- ScenarioFramework.CreateAreaTrigger(CivilianFacilityReinforced, ScenarioUtils.AreaToRect('Civilian_Area'), categories.DIRECTFIRE, true, false, ArmyBrains[Player1], CivilianReinforcementsNeededTanks, false)
    -- ScenarioFramework.CreateAreaTrigger(CivilianFacilityReinforced, ScenarioUtils.AreaToRect('Civilian_Area'), categories.ANTIAIR, true, false, ArmyBrains[Player1], CivilianReinforcementsNeededAntiAir, false)
    -- ScenarioFramework.CreateAreaTrigger(CivilianFacilityReinforced, ScenarioUtils.AreaToRect('Civilian_Area'), categories.uea0203, true, false, ArmyBrains[Player1], CivilianReinforcementsNeededGunships, false)
    ForkThread(M2ReinforcementWatch)

    -- Set up a trigger for when the player first sees an Aeon radar
    ScenarioFramework.CreateArmyIntelTrigger(AeonRadarSpotted, ArmyBrains[Player1], 'LOSNow', false, true, categories.RADAR, true, ArmyBrains[Aeon])


    -- These are the Aeon radar units
    ScenarioInfo.RadarStations = ScenarioUtils.CreateArmyGroup('Aeon', 'Radar')


    -- Matt reomved. KillOrCapture objective handles this
    -- Set up triggers to record when each one is captured
    -- for k, radar in ScenarioInfo.RadarStations do
    -- ScenarioFramework.CreateUnitCapturedTrigger(AeonRadarDestroyed, nil, radar)
    -- ScenarioFramework.CreateUnitDeathTrigger(AeonRadarDestroyed, radar)
    -- end


    -- Start up the attacks against the player again
    ScenarioFramework.CreateTimerTrigger(AttackPlayerM2, M2PeriodicAttackPlayerInitialDelay[ Difficulty ])

    -- Start drops against Luthien
    ScenarioFramework.CreateTimerTrigger(DropLuthienM2, M2PeriodicAttackPlayerInitialDelay[ Difficulty ])
end

function CivilianFacilityDied()    
    -- Let the player know what happened
    -- And end the game
    if not ScenarioInfo.CivilianFacilityNeeded then
        return
    elseif not ScenarioInfo.OpEnded then
        ScenarioFramework.Dialogue(OpStrings.E02_M01_151, false, true)
        if ScenarioInfo.MissionNumber == 2 and ScenarioInfo.M2P3 then
            ScenarioInfo.M2P3:ManualResult(false)
        end
        ScenarioFramework.PlayerLose()
    end
end

-- ScenarioFramework.CreateAreaTrigger(CivilianFacilityReinforced, ScenarioUtils.AreaToRect('Civilian_Area'), categories.DIRECTFIRE, true, false, ArmyBrains[Player1], CivilianReinforcementsNeededTanks, false)
-- ScenarioFramework.CreateAreaTrigger(CivilianFacilityReinforced, ScenarioUtils.AreaToRect('Civilian_Area'), categories.ANTIAIR, true, false, ArmyBrains[Player1], CivilianReinforcementsNeededAntiAir, false)
-- ScenarioFramework.CreateAreaTrigger(CivilianFacilityReinforced, ScenarioUtils.AreaToRect('Civilian_Area'), categories.uea0203, true, false, ArmyBrains[Player1], CivilianReinforcementsNeededGunships, false)
function M2ReinforcementWatch()
    local tanks = 0
    local aa    = 0
    local gunships = 0
    local oldTanks
    local oldAA
    local oldGunships
    local rect = ScenarioUtils.AreaToRect('Civilian_Area')
    local units

    while(tanks < CivilianReinforcementsNeededTanks or aa < CivilianReinforcementsNeededAntiAir or gunships < CivilianReinforcementsNeededGunships) do
        WaitSeconds(1)

        tanks = 0
        aa    = 0
        gunships = 0
        units = GetUnitsInRect(rect)

        if units then
            for k,unit in units do
                if not unit:IsDead() and not unit:IsBeingBuilt() then
                    if (Player1 == unit:GetArmy()) then
                        if EntityCategoryContains(categories.DIRECTFIRE, unit) and (tanks < CivilianReinforcementsNeededTanks)then
                            tanks = tanks+1
                        elseif EntityCategoryContains(categories.ANTIAIR, unit) and (aa < CivilianReinforcementsNeededAntiAir) then
                            aa = aa + 1
                        elseif EntityCategoryContains(categories.uea0203, unit) and (gunships < CivilianReinforcementsNeededGunships)then
                            gunships = gunships + 1
                        end
                    end
                end
            end
            if (tanks ~= oldTanks or aa ~= oldAA or gunships ~= oldGunships) then
                local progress = string.format('(%s/%s) (%s/%s) (%s/%s)', tanks, CivilianReinforcementsNeededTanks, aa, CivilianReinforcementsNeededAntiAir, gunships, CivilianReinforcementsNeededGunships)
                Objectives.UpdateBasicObjective(ScenarioInfo.M2P1, 'Progress', progress)
                oldTanks = tanks
                oldAA = aa
                oldGunships = gunships
            end
        end
    end
    ScenarioInfo.CivilianFacilityReinforcedObjectiveComplete = true
    ScenarioInfo.M2P1:ManualResult(true)
    ScenarioFramework.Dialogue(ScenarioStrings.PObjComp)

    ScenarioInfo.M2P1Complete = true

    -- If the player doesn't complete the objective soon, remind him that it's important
    ScenarioFramework.CreateTimerTrigger(M2P2Reminder, M2P2InitialReminderDelay)

    -- Spawn the trucks
    ForkThread(M2TrucksGettingSentNow)

    -- trucks spawned
    local unit = ScenarioInfo.CivilianFacility
    local camInfo = {
        blendTime = 1.0,
        holdTime = 6,
        orientationOffset = { 2.3562, 0.1, 0 },
        positionOffset = { 0, 1, 0 },
        zoomVal = 35,
    }
    ScenarioFramework.OperationNISCamera(unit, camInfo)

end


function AeonRadarSpotted()
    -- The player is given some story dialogue about the radar installations

    -- the one-shot intel trigger isnt behaving as one-shot.

    if not (ScenarioInfo.M2S1) then

        ScenarioFramework.Dialogue(OpStrings.E02_M03_010)
        -- Reveal where they are
        for k, radar in ScenarioInfo.RadarStations do
            if not radar:IsDead() then
                ScenarioFramework.CreateVisibleAreaLocation(5, radar:GetPosition(), 10, ArmyBrains[Player1])
            end
        end


       ScenarioInfo.M2S1 = Objectives.KillOrCapture(
            'secondary',
            'incomplete',
            OpStrings.M2S1Text,
            OpStrings.M2S1Detail,
            { Units = ScenarioInfo.RadarStations }
       )

        ScenarioInfo.M2S1:AddResultCallback(AeonRadarDestroyed)

        ScenarioFramework.Dialogue(ScenarioStrings.NewSObj)

    end


end

function AeonRadarDestroyed()

    -- Matt : removed the progress stuff, as its handled in the Kill objective

    -- Congratulate the player
    ScenarioFramework.Dialogue(ScenarioStrings.SObjComp)
    ScenarioFramework.Dialogue(OpStrings.E02_M03_020)
end

function M2TrucksGettingSentNow()
    ----Adding to try and troubleshoot " attempt to call method `AddDetectedByHook' (a nil value)" error"
    WaitTicks(3)
    -- Start sending the trucks
    SendTruck()

    -- Also start sending the Aeon anti-truck patrols
    SendAntiTruck()

    -- Start watching for them arriving
    ScenarioInfo.M2TruckAreaTrigger = ScenarioFramework.CreateAreaTrigger(TruckNearBase, 'Research_Area', categories.uec0001, false, false, ArmyBrains[Player1])

    -- Spawn the scouts and send them to their scouting positions
    -- Commented out per chrisT -Matt 11/29/06
    -- local Scout = ScenarioUtils.CreateArmyUnit('AllyCivilian', 'Scout01')
    -- IssueMove({ Scout }, ScenarioUtils.MarkerToPosition('Civilian_Scout_Point01'))
    -- Scout = ScenarioUtils.CreateArmyUnit('AllyCivilian', 'Scout02')
    -- IssueMove({ Scout }, ScenarioUtils.MarkerToPosition('Civilian_Scout_Point02'))
    -- Scout = ScenarioUtils.CreateArmyUnit('AllyCivilian', 'Scout03')
    -- IssueMove({ Scout }, ScenarioUtils.MarkerToPosition('Civilian_Scout_Point03'))

    -- Tell the player that the trucks are getting sent
    ScenarioFramework.Dialogue(OpStrings.E02_M03_050)
end

function SendTruck()
    if ScenarioInfo.CivilianFacilityAlive then
        if not ScenarioInfo.CurrentTruckNumber then
            ScenarioInfo.CurrentTruckNumber = 0
        end

        ScenarioInfo.CurrentTruckNumber = ScenarioInfo.CurrentTruckNumber + 1

        -- Spawn a truck
        local Truck = ScenarioUtils.CreateArmyUnit('Player1', 'Truck_' .. ScenarioInfo.CurrentTruckNumber)
        -- ScenarioFramework.GiveUnitToArmy(Truck, Player1)
        table.insert(ScenarioInfo.TruckList, Truck)

        -- add obj highlight to truck icon
        ScenarioInfo.M2P2:AddBasicUnitTarget(Truck)

        -- Record that another truck has been sent
        ScenarioInfo.TrucksSent = ScenarioInfo.TrucksSent + 1
        ScenarioInfo.TrucksActive = ScenarioInfo.TrucksActive + 1


        -- Set up a trigger to see if it gets hurt, if we haven't yet alerted the player
        -- that the trucks are under attack
        if not ScenarioInfo.TruckAttacked then
            ScenarioFramework.CreateUnitDamagedTrigger(TruckDamaged, Truck)
        end

        -- Set up a trigger to see if it dies
        ScenarioFramework.CreateUnitDestroyedTrigger(TruckDied, Truck)

        -- Launch another truck after the appropriate delay has passed
        if ScenarioInfo.TrucksSent < TotalNumberOfTrucks[Difficulty] then
            SendTruck()
            -- ScenarioFramework.CreateTimerTrigger(SendTruck, TruckInterval)
        else 
            M2P1Complete()
        end
    end
end

function M2P1Complete()
    ScenarioInfo.CivilianFacilityNeeded = false
    ScenarioInfo.M2P3:ManualResult(true)
    -- ScenarioFramework.Dialogue(ScenarioStrings.PObjComp)

    ScenarioInfo.M2P3Complete = true

end

function DestroyTruckAfterDelay(Truck)
    -- make it invincible, etc. so that it doesn't die to splash damage or anything
    Truck:SetCanTakeDamage(false)
    Truck:SetCanBeKilled(false)
    Truck:SetReclaimable(false)
    Truck:SetCapturable(false)
    WaitSeconds(10)
    Truck:Destroy()
end

function ResetTruckArrivedDialog()
    WaitSeconds(TruckArrivalDialogDelay)
    ReadyForTruckArrivedDialog = true
end

function TruckNearBase(unit)
    for j, Truck in(ScenarioInfo.TruckList) do
        if unit == Truck then
            -- Clean up the truck
            table.remove(ScenarioInfo.TruckList, j)

            Truck = ScenarioFramework.GiveUnitToArmy(Truck, AllyCivilian)
            IssueStop(Truck)
            IssueMove({ Truck }, ScenarioUtils.MarkerToPosition('Research_Facility'))

            ForkThread(DestroyTruckAfterDelay, Truck)
            ScenarioInfo.TrucksDone = ScenarioInfo.TrucksDone + 1
            ScenarioInfo.TrucksSafe = ScenarioInfo.TrucksSafe + 1
            ScenarioInfo.TrucksActive = ScenarioInfo.TrucksActive - 1
            Objectives.UpdateBasicObjective(ScenarioInfo.M2P2, 'progress', LOCF(OpStrings.TruckProgress, ScenarioInfo.TrucksSafe, TotalNumberOfTrucks[Difficulty]))
            if ReadyForTruckArrivedDialog  and(ScenarioInfo.TrucksDone < TotalNumberOfTrucks[Difficulty]) then
                local DialogueChooser = math.mod(ScenarioInfo.TrucksSafe, 3)
                if DialogueChooser == 1 then
                    ScenarioFramework.Dialogue(OpStrings.E02_M03_110)
                elseif DialogueChooser == 2 then
                    ScenarioFramework.Dialogue(OpStrings.E02_M03_120)
                else
                    ScenarioFramework.Dialogue(OpStrings.E02_M03_130)
                end
                ReadyForTruckArrivedDialog = false
                ForkThread(ResetTruckArrivedDialog)
            end
        end
    end

    if M2TrucksAllAccountedFor() then
        ScenarioInfo.M2TruckAreaTrigger:Destroy()
        BeginMission3()
        if ScenarioInfo.Options.Difficulty == 1 and ScenarioInfo.TrucksActive > 0 then
            ScenarioInfo.CleanupTrigger = ScenarioFramework.CreateAreaTrigger(TruckCleanup, 'Research_Area', categories.uec0001, false, false, ArmyBrains[Player1])
        end
    end
end

function M2TrucksAllAccountedFor()
    -- See if we're done, if so start mission 3
    if(ScenarioInfo.TrucksSafe == TotalNumberOfTrucks[Difficulty] and ScenarioInfo.Options.Difficulty == 1)
        or(ScenarioInfo.TrucksDone == TotalNumberOfTrucks[Difficulty] and ScenarioInfo.Options.Difficulty > 1) then
        ScenarioFramework.Dialogue(ScenarioStrings.PObjComp)

        ScenarioInfo.M2P1:ManualResult(true)
        ScenarioInfo.M2P2:ManualResult(true)
        ScenarioInfo.M2P2Complete = true
        ScenarioFramework.Dialogue(ScenarioStrings.MissionSuccessDialogue)

        if ScenarioInfo.TrucksKilled == 0 then
            -- ScenarioInfo.M2H1 = Objectives.Basic(
            -- 'bonus',
            -- 'complete',
            -- OpStrings.M2H1Text,
            -- OpStrings.M2H1Detail,
            -- Objectives.GetActionIcon('protect'),
            -- {
            --    #Units = {ScenarioInfo.RadarStations},
            --    #MarkUnits = true,
            -- }
            -- )
            ScenarioFramework.Dialogue(OpStrings.E02_M03_150)
        else
            -- Mission complete text
            ScenarioFramework.Dialogue(OpStrings.E02_M03_140)
        end

        -- trucks returned to base
        local unit = ScenarioInfo.ResearchFacility
        local camInfo = {
            blendTime = 1.0,
            holdTime = 6.0,
            orientationOffset = { -0.3927, 0.3, 0 },
            positionOffset = { 0, 3, 0 },
            zoomVal = 35,
        }
        ScenarioFramework.OperationNISCamera(unit, camInfo)

        return true
    else
        return false
    end
end

function TruckCleanup(unit)
    Truck = ScenarioFramework.GiveUnitToArmy(unit, AllyCivilian)
    IssueStop(Truck)
    IssueMove({ Truck }, ScenarioUtils.MarkerToPosition('Research_Facility'))

    ForkThread(DestroyTruckAfterDelay, Truck)
    ScenarioInfo.TrucksActive = ScenarioInfo.TrucksActive - 1
    if ScenarioInfo.TrucksActive == 0 then
        ScenarioInfo.CleanupTrigger:Destroy()
    end
end

function SendAntiTruck()
    if ScenarioInfo.TrucksDone < TotalNumberOfTrucks[Difficulty] then
        -- 50-50 chance
        if Random(0, 1) == 0 then
            local newPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M2_Truck_Attackers_1'), 'NoFormation')
            ScenarioFramework.PlatoonPatrolRoute(newPlatoon, AeonM2TruckAttackRoute1)
        else
            local newPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', AdjustForDifficulty('M2_Truck_Attackers_2'), 'NoFormation')
            ScenarioFramework.PlatoonPatrolRoute(newPlatoon, AeonM2TruckAttackRoute2)
        end

        -- Call this function again after the appropriate delay
        ScenarioFramework.CreateTimerTrigger(SendAntiTruck, M2PeriodicAttackDelayTruck)
    end
end

function TruckDamaged()
    if not ScenarioInfo.TruckAttacked then
        ScenarioInfo.TruckAttacked = true

        -- Tell the player that the convoy is under attack
        ScenarioFramework.Dialogue(OpStrings.E02_M03_070)
    end
end

function ResetTruckRespawnDialog()
    WaitSeconds(TruckRespawnDialogDelay)
    ReadyForTruckRespawnDialog = true
end

function TruckDied()
    ScenarioInfo.TrucksActive = ScenarioInfo.TrucksActive - 1
    ScenarioInfo.TrucksKilled = ScenarioInfo.TrucksKilled + 1
    ScenarioInfo.TrucksDone = ScenarioInfo.TrucksDone + 1
    if Difficulty == 1 then
        -- Tell the player that we are spawning another truck
        if (ReadyForTruckRespawnDialog) then
            ScenarioFramework.Dialogue(OpStrings.E02_M03_175)
            ReadyForTruckRespawnDialog = false
            ForkThread(ResetTruckRespawnDialog)
        end

        -- launch another truck
        ScenarioInfo.CurrentTruckNumber = 0
        ScenarioInfo.TrucksSent = ScenarioInfo.TrucksSent - 1
        SendTruck()
    elseif ScenarioInfo.TrucksKilled > TrucksAllowedToDie[Difficulty] then
        -- Let the player know that too many trucks died
        -- And end the game
        if not ScenarioInfo.OpEnded then
            ScenarioFramework.Dialogue(OpStrings.E02_M03_170, false, true)
            ScenarioInfo.M2P2:ManualResult(false)
            ScenarioFramework.PlayerLose()
        end
    else
        -- check to see if this is the last truck Matt 12/11/06
        if M2TrucksAllAccountedFor() then
            BeginMission3()
            -- skip truck death dialog if we're done
            -- $ This would be cleaner with the values at the top of the script...
        elseif (Difficulty == 2 and ScenarioInfo.TrucksKilled == 2) or
           (Difficulty == 3 and ScenarioInfo.TrucksKilled == 1) then
            ScenarioFramework.Dialogue(OpStrings.E02_M03_080)
        elseif (Difficulty == 2 and ScenarioInfo.TrucksKilled == 4) or
               (Difficulty == 3 and ScenarioInfo.TrucksKilled == 2) then
            ScenarioFramework.Dialogue(OpStrings.E02_M03_090)
        elseif (Difficulty == 2 and ScenarioInfo.TrucksKilled == 6) or
               (Difficulty == 3 and ScenarioInfo.TrucksKilled == 3) then
            ScenarioFramework.Dialogue(OpStrings.E02_M03_100)
        end
    end
end

function BeginMission3()
    ScenarioFramework.SetSharedUnitCap(700)

    -- Set the playable area
    ScenarioFramework.SetPlayableArea(Rect(0, 0, 512, 512))
    ScenarioFramework.Dialogue(ScenarioStrings.MapExpansion)

    local EnemyCommanderPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'Commander_Group', 'NoFormation')

    ---ACU upgrades
    for k, unit in EnemyCommanderPlatoon:GetPlatoonUnits() do
        unit:CreateEnhancement('Shield')
        unit:CreateEnhancement('HeatSink')
        unit:CreateEnhancement('CrysalisBeam')
    end

    EnemyCommanderPlatoon.CDRData = {}
    EnemyCommanderPlatoon.CDRData.LeashPosition = 'M3_Commander_Leash'
    EnemyCommanderPlatoon.CDRData.LeashRadius = 75
    EnemyCommanderPlatoon:ForkThread(import('/lua/ai/OpAI/OpBehaviors.lua').CDROverchargeBehavior)
    EnemyCommanderPlatoon:ForkAIThread(M3AeonCommanderAIThread)

    -- Track when the commander dies for the primary objective
    for k, unit in EnemyCommanderPlatoon:GetPlatoonUnits() do
        -- Delay the explosion so that we can catch it on camera
        ScenarioFramework.PauseUnitDeath(unit)
    end

    -- Create the Aeon base
    ScenarioUtils.CreateArmyGroup('Aeon', 'M3_Base_Economy')
    ScenarioUtils.CreateArmyGroup('Aeon', 'M3_Base_External_Economy')
    ScenarioUtils.CreateArmyGroup('Aeon', 'M3_Base_Misc')
    ScenarioUtils.CreateArmyGroup('Aeon', AdjustForDifficulty('M3_Base_Defenses_Guns'))
    ScenarioUtils.CreateArmyGroup('Aeon', 'M3_Base_Defenses_Shields')
    ScenarioUtils.CreateArmyGroup('Aeon', AdjustForDifficulty('M3_Base_Defenses_Walls'))
    -- This group has a different name since it will not really be considered part of the base
    -- It's just economy/defenses that happen to be in the same area...they will not be rebuilt if they are destroyed
    --ScenarioUtils.CreateArmyGroup('Aeon', AdjustForDifficulty('M3_No_Rebuild')) --(Moved to M2 in order to power T2 tanks/shields)

        --Create outter defenses
    ScenarioUtils.CreateArmyGroup('Aeon', AdjustForDifficulty('M3_Base_External_Defenses'))

    -- Now to create some gunships that will patrol the Aeon base
    local Gunships = ''

    -- This group is guaranteed to be created, even at the easiest difficulty
    Gunships = ScenarioUtils.CreateArmyGroup('Aeon', 'M3_Gunships_1')
    IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_1'))
    IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_2'))
    IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_3'))
    IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_4'))

    if Difficulty >= 2 then
        Gunships = ScenarioUtils.CreateArmyGroup('Aeon', 'M3_Gunships_2')
        IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_1'))
        IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_2'))
        IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_3'))
        IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_4'))
    end

    if Difficulty >= 3 then
        Gunships = ScenarioUtils.CreateArmyGroup('Aeon', 'M3_Gunships_3')
        IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_1'))
        IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_2'))
        IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_3'))
        IssuePatrol(Gunships, ScenarioUtils.MarkerToPosition('Aeon_Base_Patrol_4'))
    end

    local Factories = ScenarioUtils.CreateArmyGroup('Aeon', 'M3_Base_Factories')
    -- Track when the factories are dead for the secondary objective
    ScenarioFramework.CreateGroupDeathTrigger(EnemyFactoriesDestroyed, Factories)

    AddTechMission3()

    ScenarioInfo.MissionNumber = 3

    --Create attack to crush Luthien now that it's evacuated
    AeonScriptedAttack('M3_Luthien_Attack_D3', AeonM2LuthienCrush,'AttackFormation')

    -- try to snipe the player again, twice, just in case they got cocky
    M15SnipeAttack()
    M15SnipeAttack()

    -- Briefing
    ScenarioFramework.Dialogue(OpStrings.E02_M04_010)

    ScenarioInfo.M3P1 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M3P1Text,
        OpStrings.M3P1Detail,
        Objectives.GetActionIcon('protect'),
        {
            Units = { ScenarioInfo.ResearchFacility },
            MarkUnits = true,
        }
   )
    ScenarioInfo.M3P2 = Objectives.Kill(
        'primary',
        'incomplete',
        OpStrings.M3P2Text,
        OpStrings.M3P2Detail,
        {
            Units = EnemyCommanderPlatoon:GetPlatoonUnits()
        }
   )
    ScenarioInfo.M3P2:AddResultCallback(
        function(result, unit)
            if result then
                -- enemy aeon cdr destroyed
                ScenarioFramework.CDRDeathNISCamera(unit)

                -- Aeon commander's death cry
                ScenarioFramework.Dialogue(OpStrings.E02_M04_130, false, true)

                ScenarioInfo.M3P1:ManualResult(true)
                ScenarioInfo.M3P2Complete = true

                PlayerWin()
            end
        end
    )
    ScenarioInfo.M3S1 = Objectives.Basic(
        'secondary',
        'incomplete',
        OpStrings.M3S1Text,
        OpStrings.M3S1Detail,
        Objectives.GetActionIcon('kill'),
        {
            Units = Factories,
            MarkUnits = true,
        }
   )
    ScenarioFramework.Dialogue(ScenarioStrings.NewPObj)

    -- If the player doesn't complete the objective soon, remind him that it's important
    ScenarioFramework.CreateTimerTrigger(M3P2Reminder, M3P2InitialReminderDelay)

    -- Dialog that will appear after a certain amount of time
    ScenarioFramework.CreateTimerTrigger(Dialogue_M3_1, M3_Aeon_Comment_Dialogue_Delay)
    ScenarioFramework.CreateTimerTrigger(Dialogue_M3_2, M3_Base_Hint_Dialogue_Delay)

    -- Taunt the player when the player first attacks the Aeon base
    ScenarioFramework.CreateAreaTrigger(M3Taunt1, 'Aeon_Base_Area', categories.ALLUNITS, true, false, ArmyBrains[Player1], 1, false)

    -- Start up the attacks against the player again
    ScenarioFramework.CreateTimerTrigger(AttackPlayerM3, M3PeriodicAttackPlayerInitialDelay[ Difficulty ])
end

function M3AeonCommanderAIThread(platoon)
    platoon.PlatoonData.LocationType = 'Aeon_Base'
    platoon:PatrolLocationFactoriesAI()
end

function M3Taunt1()
    if not ScenarioInfo.M3P2Complete then
        PlayRandomTaunt()
        ScenarioFramework.CreateTimerTrigger(M3Taunt2, M3Taunt2Delay)
    end
end

function M3Taunt2()
    if not ScenarioInfo.M3P2Complete then
        PlayRandomTaunt()
        ScenarioFramework.CreateTimerTrigger(M3Taunt3, M3Taunt3Delay)
    end
end

function M3Taunt3()
    if not ScenarioInfo.M3P2Complete then
        PlayRandomTaunt()
    end
end

function Dialogue_M3_1()
    -- Enemy commander dialogue
    ScenarioFramework.Dialogue(OpStrings.E02_M04_040)
end

function Dialogue_M3_2()
    -- Advice on how to beat the enemy
    ScenarioFramework.Dialogue(OpStrings.E02_M04_050)
end

function EnemyFactoriesDestroyed()
    ScenarioInfo.M3S1:ManualResult(true)
    ScenarioFramework.Dialogue(ScenarioStrings.SObjComp)

    -- Congratulate player
    ScenarioFramework.Dialogue(OpStrings.E02_M04_070)
end

function AddTechMission15()
    ScenarioFramework.RemoveRestrictionForAllHumans(
        categories.ueb2204 +  -- T2 Anti-Air Flak Cannon
        categories.ueb2301 +  -- T2 Heavy Gun Tower
        categories.uel0208 +  -- T2 Engineer
        categories.ueb1202 +  -- T2 Mass Extractor
        categories.ueb0202 +  -- T2 Air Factory
        categories.zeb9502 +  -- T2 Support Air Factory
        categories.uea0203 +  -- Gunship
        categories.ueb0201 +  -- T2 Land Factory
        categories.zeb9501 +  -- T2 Support Land Factory
        categories.uel0205 +    -- Mobile AA Flak
        categories.uel0202 -- T2 Pillar --Added because fighting a T2 battle sucks without at least this
    )
end

function AddTechMission2()
    -- ScenarioFramework.PlayUnlockDialogue()
end

function AddTechMission3()
    ScenarioFramework.RemoveRestrictionForAllHumans(
        -- categories.uel0202 +  -- Heavy Tank
        categories.uel0111 +  -- Mobile Missile Launcher
        categories.uel0307 +    -- Mobile Shield Generator
        categories.uea0104 -- T2 transport
    )
end

function PlayerCommanderDied(unit)
    ScenarioFramework.PlayerDeath(unit, OpStrings.E02_D01_010)
end

function ResearchFacilityDied()
    -- Let the player know what happened
    -- And end the game
    if not ScenarioInfo.OpEnded then
        ScenarioFramework.Dialogue(OpStrings.E02_M01_150, false, true)
        if ScenarioInfo.MissionNumber == 3 and ScenarioInfo.M3P1 then
            ScenarioInfo.M3P1:ManualResult(false)
        elseif ScenarioInfo.MissionNumber == 1.5 and ScenarioInfo.M15P1 then
            ScenarioInfo.M15P1:ManualResult(false)
        elseif ScenarioInfo.MissionNumber == 1 and ScenarioInfo.M1P3 then
            ScenarioInfo.M1P3:ManualResult(false)
        end
        ScenarioFramework.PlayerLose()
    end
end

function PlayRandomTaunt()
    if not ScenarioInfo.OpEnded then
        local randomIndex = Random(1, table.getn(TauntTable))
        ScenarioFramework.Dialogue(TauntTable[ randomIndex ])
    end
end

function AdjustForDifficulty(string_in)
    local string_out = string_in
    if Difficulty == 1 then
        string_out = string_out .. Difficulty1_Suffix
    elseif Difficulty == 2 then
        string_out = string_out .. Difficulty2_Suffix
    elseif Difficulty == 3 then
        string_out = string_out .. Difficulty3_Suffix
    end
    return string_out
end

function M1P1Reminder()
    if not ScenarioInfo.M1P1Complete and not ScenarioInfo.OpEnded then
        if not ScenarioInfo.M1P1ReminderAlternate then
            ScenarioInfo.M1P1ReminderAlternate = true
            ScenarioFramework.Dialogue(OpStrings.E02_M01_200)
        else
            ScenarioInfo.M1P1ReminderAlternate = false
            ScenarioFramework.Dialogue(ScenarioStrings.UEFGenericReminder)
        end
        ScenarioFramework.CreateTimerTrigger(M1P1Reminder, M1P1ReoccuringReminderDelay)
    end
end

function M1P3Reminder()
    if not ScenarioInfo.M1P3Complete and not ScenarioInfo.OpEnded then
        if not ScenarioInfo.M1P3ReminderAlternate then
            ScenarioInfo.M1P3ReminderAlternate = true
            ScenarioFramework.Dialogue(OpStrings.E02_M01_210)
        else
            ScenarioInfo.M1P3ReminderAlternate = false
            ScenarioFramework.Dialogue(ScenarioStrings.UEFGenericReminder)
        end
        ScenarioFramework.CreateTimerTrigger(M1P3Reminder, M1P3ReoccuringReminderDelay)
    end
end

function M2P1Reminder()
    if not ScenarioInfo.M2P1Complete and not ScenarioInfo.OpEnded then
        if not ScenarioInfo.M2P1ReminderAlternate then
            ScenarioInfo.M2P1ReminderAlternate = true
            ScenarioFramework.Dialogue(OpStrings.E02_M03_200)
        else
            ScenarioInfo.M2P1ReminderAlternate = false
            ScenarioFramework.Dialogue(OpStrings.E02_M03_205)
        end
        ScenarioFramework.CreateTimerTrigger(M2P1Reminder, M2P1ReoccuringReminderDelay)
    end
end

function M2P2Reminder()
    if not ScenarioInfo.M2P2Complete and not ScenarioInfo.OpEnded then
        if not ScenarioInfo.M2P2ReminderAlternate then
            ScenarioInfo.M2P2ReminderAlternate = true
            ScenarioFramework.Dialogue(OpStrings.E02_M03_210)
        else
            ScenarioInfo.M2P2ReminderAlternate = false
            ScenarioFramework.Dialogue(OpStrings.E02_M03_215)
        end
        ScenarioFramework.CreateTimerTrigger(M2P2Reminder, M2P2ReoccuringReminderDelay)
    end
end

function M3P2Reminder()
    if not ScenarioInfo.M3P2Complete and not ScenarioInfo.OpEnded then
        if not ScenarioInfo.M3P2ReminderAlternate then
            ScenarioInfo.M3P2ReminderAlternate = true
            ScenarioFramework.Dialogue(OpStrings.E02_M04_210)
        else
            ScenarioInfo.M3P2ReminderAlternate = false
            ScenarioFramework.Dialogue(OpStrings.E02_M04_215)
        end
        ScenarioFramework.CreateTimerTrigger(M3P2Reminder, M3P2ReoccuringReminderDelay)
    end
end

----------
-- End Game
----------
function PlayerWin()
    if not ScenarioInfo.OpEnded then
        -- Turn everything neutral
        ScenarioFramework.EndOperationSafety({ ScenarioInfo.ResearchFacility })

        -- Celebration dialogue
        -- And end the game
        ScenarioFramework.Dialogue(OpStrings.E02_M04_150, WinGame, true)
    end
end

function WinGame()
    ScenarioInfo.OpComplete = true
    WaitSeconds(5)
    -- local bonus = Objectives.IsComplete(ScenarioInfo.M1H1) and Objectives.IsComplete(ScenarioInfo.M1H2) and Objectives.IsComplete(ScenarioInfo.M2H1)
    local secondary = Objectives.IsComplete(ScenarioInfo.M1S1) and Objectives.IsComplete(ScenarioInfo.M2S1) and Objectives.IsComplete(ScenarioInfo.M3S1)
    ScenarioFramework.EndOperation(ScenarioInfo.OpComplete, ScenarioInfo.OpComplete, secondary)
end
