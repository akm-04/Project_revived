local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("SceneFighter", var_0_1.ctx.battle.requireFighter("SceneFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = 90000102
local var_0_9 = 80000262
local var_0_10 = 120
local var_0_11 = var_0_2.tables.conquerSchoolBuff
local var_0_12 = {
	10020022,
	10020023
}
local var_0_13 = {
	10020024,
	10020025
}
local var_0_14 = var_0_2.tables.skill
local var_0_15 = 180
local var_0_16 = 120
local var_0_17 = var_0_1.ctx.battle.getRequire("SpineEffect")

function var_0_3.ctor(arg_1_0, arg_1_1)
	arg_1_0.buffType = arg_1_1.buffType or 0
	arg_1_0.inspireBuffLev = arg_1_1.inspireBuffLev or 0

	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:laterInit()
end

function var_0_3.laterInit(arg_2_0)
	arg_2_0:listenInfo("buff_info")

	if arg_2_0:checkListenDeathInfo() then
		arg_2_0:listenInfo("death_info")
	end

	if arg_2_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_SUMMON or arg_2_0.buffType == var_0_2.ConquerSchoolBuff.POWER_OVERWHELMING or arg_2_0.buffType == var_0_2.ConquerSchoolBuff.ONE_SHOT then
		arg_2_0:listenInfo("attack_info")
	end

	if arg_2_0.buffType == var_0_2.ConquerSchoolBuff.HERO_MAX_ATTACK then
		arg_2_0:listenInfo("harm_info")
	end

	if arg_2_0.buffType == var_0_2.ConquerSchoolBuff.SUMMON_STRONG then
		arg_2_0:listenInfo("born_info")
	end

	if arg_2_0.buffType == var_0_2.ConquerSchoolBuff.SUPER_FEAR then
		arg_2_0:listenInfo("buff_info")
	end
end

function var_0_3.checkListenDeathInfo(arg_3_0)
	if arg_3_0.buffType == var_0_2.ConquerSchoolBuff.HERO_BOUNTY or arg_3_0.buffType == var_0_2.ConquerSchoolBuff.DIE_HARM or arg_3_0.buffType == var_0_2.ConquerSchoolBuff.KILL_ENERGY or arg_3_0.buffType == var_0_2.ConquerSchoolBuff.ATTR_DOWN or arg_3_0.buffType == var_0_2.ConquerSchoolBuff.DIE_COMEBACK or arg_3_0.buffType == var_0_2.ConquerSchoolBuff.ONE_FOR_ALL or arg_3_0.buffType == var_0_2.ConquerSchoolBuff.KOF or arg_3_0.buffType == var_0_2.ConquerSchoolBuff.FIRST_KILL_TARGET or arg_3_0.buffType == var_0_2.ConquerSchoolBuff.KILL_ONE_FREEZE then
		return true
	end

	return false
end

function var_0_3.initSpecial(arg_4_0)
	if arg_4_0.buffType == var_0_2.ConquerSchoolBuff.KOF then
		for iter_4_0, iter_4_1 in ipairs(var_0_1.ctx.battle.teamA) do
			iter_4_1.fighterModel:setVisible(false)
		end

		for iter_4_2, iter_4_3 in ipairs(var_0_1.ctx.battle.teamB) do
			iter_4_3.fighterModel:setVisible(false)
		end

		arg_4_0.teamA = var_0_1.ctx.battle.teamA
		arg_4_0.teamB = var_0_1.ctx.battle.teamB
		var_0_1.ctx.battle.teamA = {}
		var_0_1.ctx.battle.teamB = {}
	end
end

function var_0_3.init(arg_5_0)
	var_0_3.super.init(arg_5_0)

	arg_5_0.skillLevelByID_ = {}
	arg_5_0.isOnlyOneTurn = false
	arg_5_0.isInspireBuffAdd_ = false
	arg_5_0.records_.kill_a_hero_id = {}
	arg_5_0.records_.kill_b_hero_id = {}
	arg_5_0.records_.random_buff_count = {}
	arg_5_0.records_.pos_attr_a = {}
	arg_5_0.records_.pos_attr_b = {}
	arg_5_0.records_.self_random = {}
	arg_5_0.records_.side_random = {}

	local var_5_0 = var_0_11:buff(arg_5_0.buffType)

	if arg_5_0.buffType == var_0_2.ConquerSchoolBuff.SINGLE_BATTLE then
		arg_5_0.singleBattleBuffId = 10020002
		arg_5_0.singleBattleList = {}

		for iter_5_0, iter_5_1 in ipairs(var_0_1.ctx.battle.teamA) do
			if iter_5_0 == 1 then
				arg_5_0.singleBattleHero = iter_5_1
			else
				table.insert(arg_5_0.singleBattleList, iter_5_1)
			end
		end

		arg_5_0.singleBattlePre = true
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.TIME_RANDOM_KILL then
		arg_5_0.effectStartTime = 600
		arg_5_0.killPerCount = 150
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_SCENE_LAY then
		var_0_1.ctx.battle.timeCount = -900
		arg_5_0.teamABuffs = var_5_0
		arg_5_0.teamBBuffs = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_SCENE then
		arg_5_0.teamABuffs = var_5_0
		arg_5_0.teamBBuffs = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.MIRAGE then
		arg_5_0.mirageInterval = 450
		arg_5_0.mirageCount = arg_5_0.mirageInterval
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.STUN_MIRAGE then
		arg_5_0.stunMirageInterval = 150
		arg_5_0.stunMirageList = {}
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_UNOBTAIN then
		arg_5_0.teamABuffs = var_5_0
		arg_5_0.teamBBuffs = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.HERO_BOUNTY then
		arg_5_0.bountyBuffs = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.MORE_BUFFHARM then
		arg_5_0.teamABuffs = var_5_0
		arg_5_0.teamBBuffs = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.LIGHTNING then
		arg_5_0.lightningSkillId = 80039001
		arg_5_0.lightningInterval = 150
		arg_5_0.lightningCount = arg_5_0.lightningInterval
		arg_5_0.skillLevelByID_[arg_5_0.lightningSkillId] = 1
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.CURE_UP then
		arg_5_0.teamABuffs = var_5_0
		arg_5_0.teamBBuffs = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_LOSING then
		arg_5_0.energyLosebuff = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.EASILY_CRIT then
		arg_5_0.teamABuffs = var_5_0
		arg_5_0.teamBBuffs = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.NO_CURE then
		arg_5_0.teamABuffs = var_5_0
		arg_5_0.teamBBuffs = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.RANDOM_POS then
		arg_5_0.randomPosCount = 105
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.AEROLITE then
		arg_5_0.aeroliteSkillId = 10000663
		arg_5_0.aeroliteInterval = 165
		arg_5_0.aeroliteCount = arg_5_0.aeroliteInterval
		arg_5_0.skillLevelByID_[arg_5_0.aeroliteSkillId] = 1
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_SUMMON then
		arg_5_0.energyCountA = 0
		arg_5_0.energyCountB = 0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.ATTR_DOWN then
		arg_5_0.isAddMarkBuff = false
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.DIE_COMEBACK then
		arg_5_0.dieComebackList_ = {}
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.SUMMON_AID then
		var_0_1.ctx.battle.timeCount = -2700
		arg_5_0.summonAidCount_ = 0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.KOF then
		var_0_1.ctx.battle.timeCount = -2700
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.POWER_OVERWHELMING then
		arg_5_0.dyingHeroTimeCount = {}
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.FIRST_KILL_TARGET then
		arg_5_0.isFirstKillBuffAdd = false
		arg_5_0.firstKillBuffID = 10020041
		arg_5_0.firstKillTarget = nil
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.KILL_ONE_FREEZE then
		arg_5_0.killOneFreezeBuffID = 10020042
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.TWOSIDE_BUFF then
		arg_5_0.gainBuffIDs = {
			10020043,
			10020044,
			10020045,
			10020046
		}
		arg_5_0.deBuffIDs = {
			10020047,
			10020048,
			10020049,
			10020050
		}
		arg_5_0.exchangeBuffTime = var_0_7:time(arg_5_0.gainBuffIDs[1]) + 5
		arg_5_0.selfTeamGain = false
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.BET_MACHINE then
		arg_5_0.selfRandom = 0
		arg_5_0.sideRandom = 0
		arg_5_0.isInitBetNum = false
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.Boss_50 then
		var_0_1.ctx.battle.timeCount = -2700
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.DOUBLE_CRIT then
		arg_5_0.teamABuffs = var_5_0
		arg_5_0.teamBBuffs = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.FIST_TO_FIST then
		var_0_1.ctx.battle.timeCount = -1800
		arg_5_0.teamABuffs = var_5_0
		arg_5_0.teamBBuffs = var_5_0
	elseif arg_5_0.buffType == var_0_2.ConquerSchoolBuff.ENDLESS_DARK then
		arg_5_0.teamABuffs = var_5_0
		arg_5_0.teamBBuffs = var_5_0
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0.isOnlyOneTurn then
		return
	end

	if not arg_6_0.isInspireBuffAdd_ then
		arg_6_0.isInspireBuffAdd_ = true

		arg_6_0:addInspireBuff()
	end

	if arg_6_0.buffType == var_0_2.ConquerSchoolBuff.SINGLE_BATTLE then
		arg_6_0:singleBattleDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.TIME_RANDOM_KILL then
		arg_6_0:timeRandomKillDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_SCENE_LAY or arg_6_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_UNOBTAIN or arg_6_0.buffType == var_0_2.ConquerSchoolBuff.MORE_BUFFHARM or arg_6_0.buffType == var_0_2.ConquerSchoolBuff.CURE_UP or arg_6_0.buffType == var_0_2.ConquerSchoolBuff.EASILY_CRIT or arg_6_0.buffType == var_0_2.ConquerSchoolBuff.NO_CURE or arg_6_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_SCENE or arg_6_0.buffType == var_0_2.ConquerSchoolBuff.DOUBLE_CRIT or arg_6_0.buffType == var_0_2.ConquerSchoolBuff.FIST_TO_FIST or arg_6_0.buffType == var_0_2.ConquerSchoolBuff.ENDLESS_DARK then
		arg_6_0.isOnlyOneTurn = true

		arg_6_0:addTeamBuffs(1)
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.LIGHTNING then
		arg_6_0:lightningDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.MIRAGE then
		arg_6_0:mirageDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.STUN_MIRAGE then
		arg_6_0:stunMirageDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.HERO_BOUNTY then
		arg_6_0:heroBountyDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_LOSING then
		arg_6_0:eneryLosingDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.LIMIT_TIME_UP then
		arg_6_0:limitTimeUpDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.RANDOM_POS then
		arg_6_0:randomPosDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.AEROLITE then
		arg_6_0:aeroliteDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.ENERGY_SUMMON then
		arg_6_0:energySummonDeal()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.DIE_HARM then
		arg_6_0:heroDieSkill()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.KILL_ENERGY then
		arg_6_0:heroKillEnergy()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.ATTR_DOWN then
		arg_6_0:attrDown()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.DIE_COMEBACK then
		arg_6_0:dieComeback()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.HERO_MAX_ATTACK then
		arg_6_0:heroMaxAttack()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.DOUBLE_MOVE then
		arg_6_0:doubleMove()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.D_HARM_UP then
		arg_6_0:dHarmUp()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.SUMMON_STRONG then
		arg_6_0:summonStrong()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.SUMMON_AID then
		arg_6_0:summonAid()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.ONE_FOR_ALL then
		arg_6_0:killOneForAll()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.KOF then
		arg_6_0:KOF()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.POWER_OVERWHELMING then
		arg_6_0:powerOverWhelming()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.SUPER_FEAR then
		arg_6_0:superFear()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.FIRST_KILL_TARGET then
		arg_6_0:firstKill()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.KILL_ONE_FREEZE then
		arg_6_0:killOneFreeze()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.TWOSIDE_BUFF then
		arg_6_0:twoSideBuff()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.BET_MACHINE then
		arg_6_0:betMachine()
	elseif arg_6_0.buffType == var_0_2.ConquerSchoolBuff.ONE_SHOT then
		arg_6_0:energyOneShot()
	end
end

function var_0_3.addInspireBuff(arg_7_0)
	local function var_7_0(arg_8_0, arg_8_1, arg_8_2)
		local var_8_0 = {}

		for iter_8_0, iter_8_1 in ipairs(arg_8_0) do
			local var_8_1 = {
				tableID = iter_8_1,
				start = var_0_1.ctx.battle.count,
				level = arg_7_0.inspireBuffLev,
				skillID = arg_8_2,
				fighter = arg_7_0,
				target = arg_8_1
			}
			local var_8_2 = var_0_5.new(var_8_1)

			var_8_2:setIsHit(true)
			var_8_2:setDirection(arg_7_0:getFlipX())
			table.insert(var_8_0, var_8_2)
		end

		return var_8_0
	end

	for iter_7_0, iter_7_1 in ipairs(var_0_1.ctx.battle.teamA) do
		if not iter_7_1:isDeath() and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_7_1 = var_7_0(var_0_12, iter_7_1, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

			iter_7_1:addBuffs(var_7_1)
		end
	end

	for iter_7_2, iter_7_3 in ipairs(var_0_1.ctx.battle.teamB) do
		if not iter_7_3:isDeath() and iter_7_3:getSummonType() == var_0_2.summonMonsterType.None then
			local var_7_2 = var_7_0(var_0_13, iter_7_3, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

			iter_7_3:addBuffs(var_7_2)
		end
	end
end

function var_0_3.singleBattleDeal(arg_9_0)
	if arg_9_0.singleBattlePre then
		arg_9_0.singleBattlePre = false

		for iter_9_0, iter_9_1 in ipairs(arg_9_0.singleBattleList) do
			local var_9_0 = var_0_5.new({
				level = 1,
				tableID = arg_9_0.singleBattleBuffId,
				start = var_0_1.ctx.battle.count,
				skillID = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
				fighter = arg_9_0,
				target = iter_9_1
			})

			iter_9_1:addBuffs({
				var_9_0
			})

			local var_9_1, var_9_2 = iter_9_1:getPos()

			iter_9_1:pos(iter_9_0 * 120 + 50, 375)
		end
	end

	if arg_9_0.singleBattleHero:isDeath() and not arg_9_0.singleBattleHero:canReborn() then
		for iter_9_2, iter_9_3 in ipairs(arg_9_0.singleBattleList) do
			iter_9_3:forceDie()
		end
	end
end

function var_0_3.timeRandomKillDeal(arg_10_0)
	if var_0_1.ctx.battle.count >= arg_10_0.effectStartTime and arg_10_0.killPerCount > 0 then
		arg_10_0.killPerCount = arg_10_0.killPerCount - 1

		if arg_10_0.killPerCount <= 0 then
			local var_10_0 = {}
			local var_10_1 = {}

			for iter_10_0, iter_10_1 in ipairs(var_0_1.ctx.battle.teamA) do
				if not iter_10_1:isDeath() and iter_10_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
					table.insert(var_10_0, iter_10_1)
				end
			end

			for iter_10_2, iter_10_3 in ipairs(var_0_1.ctx.battle.teamB) do
				if not iter_10_3:isDeath() and iter_10_3:getSummonType() ~= var_0_2.summonMonsterType.Pet then
					table.insert(var_10_1, iter_10_3)
				end
			end

			local var_10_2 = 1
			local var_10_3 = 1

			if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
				var_10_2 = arg_10_0.killAHeroCount_[tostring(var_0_1.ctx.battle.count)] or 1
				var_10_3 = arg_10_0.killBHeroCount_[tostring(var_0_1.ctx.battle.count)] or 1
			else
				var_10_2 = math.random(1, #var_10_0)
				arg_10_0.records_.kill_a_hero_id[tostring(var_0_1.ctx.battle.count)] = var_10_2
				var_10_3 = math.random(1, #var_10_1)
				arg_10_0.records_.kill_b_hero_id[tostring(var_0_1.ctx.battle.count)] = var_10_3
			end

			if next(var_10_0) then
				var_10_0[var_10_2]:die()
			end

			if next(var_10_1) then
				var_10_1[var_10_3]:die()
			end

			arg_10_0.killPerCount = 150
		end
	end
end

function var_0_3.enerySceneDeal(arg_11_0)
	return
end

function var_0_3.lightningDeal(arg_12_0)
	arg_12_0.lightningCount = arg_12_0.lightningCount - 1

	if arg_12_0.lightningCount == 0 then
		arg_12_0.lightningCount = arg_12_0.lightningInterval

		local var_12_0

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_12_0 = arg_12_0.reportSkills_[1]

			table.remove(arg_12_0.reportSkills_, 1)
		else
			var_12_0 = var_0_4.new({
				fighter = arg_12_0,
				skillID = arg_12_0.lightningSkillId
			})
		end

		arg_12_0:createUnits(var_12_0)
		table.insert(arg_12_0.records_.skills, var_12_0)
	end
end

function var_0_3.mirageDeal(arg_13_0)
	arg_13_0.mirageCount = arg_13_0.mirageCount - 1

	if arg_13_0.mirageCount == 0 then
		arg_13_0.mirageCount = arg_13_0.mirageInterval

		for iter_13_0, iter_13_1 in ipairs(var_0_1.ctx.battle.teamA) do
			if iter_13_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_13_1:isDeath() then
				arg_13_0:summonMirage(iter_13_1, var_0_8, 1, 1)
			end
		end

		for iter_13_2, iter_13_3 in ipairs(var_0_1.ctx.battle.teamB) do
			if iter_13_3:getSummonType() == var_0_2.summonMonsterType.None and not iter_13_3:isDeath() then
				arg_13_0:summonMirage(iter_13_3, var_0_8, 1, 1)
			end
		end
	end
end

function var_0_3.stunMirageDeal(arg_14_0)
	for iter_14_0, iter_14_1 in pairs(arg_14_0.stunMirageList) do
		if iter_14_1 > 0 then
			arg_14_0.stunMirageList[iter_14_0] = arg_14_0.stunMirageList[iter_14_0] - 1
		end
	end

	for iter_14_2, iter_14_3 in ipairs(arg_14_0:getInfoByKey("buff_info")) do
		local var_14_0 = iter_14_3.target

		if var_14_0:getSummonType() == var_0_2.summonMonsterType.None and arg_14_0:isStunBuff(iter_14_3) then
			local var_14_1 = arg_14_0.stunMirageList[var_14_0]

			if not var_14_1 or var_14_1 == 0 then
				arg_14_0:summonMirage(var_14_0, var_0_8, 1, 1)

				arg_14_0.stunMirageList[var_14_0] = arg_14_0.stunMirageInterval
			end
		end
	end
end

function var_0_3.heroBountyDeal(arg_15_0)
	local var_15_0 = 1

	for iter_15_0, iter_15_1 in ipairs(arg_15_0:getInfoByKey("death_info")) do
		if iter_15_1.killer_ and not iter_15_1.killer_:isDeath() then
			local var_15_1 = 1

			if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
				var_15_1 = arg_15_0.randomBuffCount_[tostring(var_0_1.ctx.battle.count)][var_15_0] or 1
				var_15_0 = var_15_0 + 1
			else
				var_15_1 = math.random(1, #arg_15_0.bountyBuffs)

				if not arg_15_0.records_.random_buff_count[tostring(var_0_1.ctx.battle.count)] then
					arg_15_0.records_.random_buff_count[tostring(var_0_1.ctx.battle.count)] = {}
				end

				arg_15_0.records_.random_buff_count[tostring(var_0_1.ctx.battle.count)][var_15_0] = var_15_1
				var_15_0 = var_15_0 + 1
			end

			local var_15_2 = arg_15_0:newBuff({
				arg_15_0.bountyBuffs[var_15_1]
			}, iter_15_1.killer_, arg_15_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

			iter_15_1.killer_:addBuffs(var_15_2)
		end
	end
end

function var_0_3.eneryLosingDeal(arg_16_0)
	for iter_16_0, iter_16_1 in ipairs(arg_16_0:getInfoByKey("buff_info")) do
		local var_16_0 = iter_16_1:getTableID()
		local var_16_1 = iter_16_1.target

		if not var_0_7:adUnable(var_16_0) and var_0_7:apUnable(var_16_0) then
			local var_16_2 = arg_16_0:newBuff(arg_16_0.energyLosebuff, var_16_1, arg_16_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

			var_16_1:addBuffs(var_16_2)
		end
	end
end

function var_0_3.limitTimeUpDeal(arg_17_0)
	for iter_17_0, iter_17_1 in ipairs(arg_17_0:getInfoByKey("buff_info")) do
		local var_17_0 = iter_17_1:getTableID()

		if (iter_17_1:isApUnable() or iter_17_1:isAdUnable() or iter_17_1:isPugongOnly() or iter_17_1:isMoveUnable()) and var_0_7:isLimit(var_17_0) == 1 then
			iter_17_1:setExtraTime(var_0_7:time(var_17_0))
		end
	end
end

function var_0_3.summonMirage(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4)
	local var_18_0
	local var_18_1 = {
		x = arg_18_1:getX() + var_0_10,
		y = arg_18_1:getY()
	}
	local var_18_2

	if arg_18_1:getTeamType() == var_0_2.TeamType.A then
		var_18_2 = "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)
	else
		var_18_2 = "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_18_0 = var_0_1.ctx.battle.summonMonsters[var_18_2]
	else
		local var_18_3 = var_0_6.new()

		var_18_3:populateWithTableID(arg_18_2)

		var_18_3.level_ = arg_18_3 or var_18_3.level_
		var_18_3.color_ = arg_18_4 or var_18_3.color_
		var_18_3.skillLev_ = {
			1,
			1,
			1,
			1,
			1
		}

		local var_18_4 = var_18_3:className()

		var_18_0 = var_0_1.ctx.battle.requireFighter(var_18_4).new({
			is_arena = arg_18_0.isInArena_
		})

		var_18_0:populateWithHero(var_18_3)
		var_18_0:initModels()

		if arg_18_1:getTeamType() == var_0_2.TeamType.A then
			var_18_0.fighterModel:initHeaderView(var_0_2.TeamType.B - 1)
		else
			var_18_0.fighterModel:initHeaderView(var_0_2.TeamType.A - 1)
		end

		var_18_0.fighterIndex = var_18_2

		var_18_0:setFormationDelay(0, 100)
	end

	if arg_18_1:getTeamType() == var_0_2.TeamType.A then
		var_18_0:setTeamType(var_0_2.TeamType.B)
		table.insert(var_0_1.ctx.battle.teamB, var_18_0)
	else
		var_18_0:setTeamType(var_0_2.TeamType.A)
		table.insert(var_0_1.ctx.battle.teamA, var_18_0)
	end

	var_18_0.fighterModel:pos(var_18_1.x, var_18_1.y)
	var_18_0:updateHp(arg_18_1:getHpLimit())
	var_18_0:getFighterModel():flipX(arg_18_0:getTeamType() == var_0_2.TeamType.B)
	var_18_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_18_0:born()
	var_18_0:setGlobalBuffs()
	table.insert(var_0_1.ctx.battle.yOrder, var_18_0)
	var_0_1.ctx.battle.updateZorder()
end

function var_0_3.addTeamBuffs(arg_19_0, arg_19_1)
	if arg_19_1 == 1 or arg_19_1 == 2 then
		if not arg_19_0.teamABuffs or not next(arg_19_0.teamABuffs) then
			return
		end

		for iter_19_0, iter_19_1 in ipairs(var_0_1.ctx.battle.teamA) do
			if not iter_19_1:isDeath() and iter_19_1:getSummonType() == var_0_2.summonMonsterType.None then
				local var_19_0 = arg_19_0:newBuff(arg_19_0.teamABuffs, iter_19_1, arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				iter_19_1:addBuffs(var_19_0)
			end
		end
	end

	if arg_19_1 == 1 or arg_19_1 == 3 then
		if not arg_19_0.teamBBuffs or not next(arg_19_0.teamBBuffs) then
			return
		end

		for iter_19_2, iter_19_3 in ipairs(var_0_1.ctx.battle.teamB) do
			if not iter_19_3:isDeath() and iter_19_3:getSummonType() == var_0_2.summonMonsterType.None then
				local var_19_1 = arg_19_0:newBuff(arg_19_0.teamBBuffs, iter_19_3, arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				iter_19_3:addBuffs(var_19_1)
			end
		end
	end
end

function var_0_3.newBuff(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local var_20_0 = {}

	for iter_20_0, iter_20_1 in ipairs(arg_20_1) do
		local var_20_1 = {
			level = 1,
			tableID = iter_20_1,
			start = var_0_1.ctx.battle.count,
			skillID = arg_20_3,
			fighter = arg_20_0,
			target = arg_20_2
		}
		local var_20_2 = var_0_5.new(var_20_1)

		var_20_2:setIsHit(true)
		var_20_2:setDirection(arg_20_0:getFlipX())
		table.insert(var_20_0, var_20_2)
	end

	return var_20_0
end

function var_0_3.isStunBuff(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_1:getTableID()

	if var_0_7:adUnable(var_21_0) and var_0_7:apUnable(var_21_0) and var_0_7:type(var_21_0) == var_0_2.BuffType.MOVE_SKILL_LIMIT and not arg_21_1:isFear() and not var_0_7:pause(var_21_0) and not var_0_7:sleep(var_21_0) then
		return true
	end

	return false
end

function var_0_3.selectTargetByTypeD3(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = math.random(tonumber(os.time()))

	math.randomseed(tonumber(tostring(os.time() + var_22_0):reverse():sub(1, 6)))

	local var_22_1 = {}

	for iter_22_0, iter_22_1 in ipairs(var_0_1.ctx.battle.teamA) do
		if not iter_22_1:isDeath() and not iter_22_1:isAffected() then
			table.insert(var_22_1, iter_22_1)
		end
	end

	for iter_22_2, iter_22_3 in ipairs(var_0_1.ctx.battle.teamB) do
		if not iter_22_3:isDeath() and not iter_22_3:isAffected() then
			table.insert(var_22_1, iter_22_3)
		end
	end

	if not var_22_1 or next(var_22_1) == nil then
		return {}
	end

	math.randomseed(var_22_0)

	return {
		var_22_1[math.random(#var_22_1)]
	}
end

function var_0_3.selectTargetByTypeC12(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = 0
	local var_23_1

	for iter_23_0, iter_23_1 in ipairs(var_0_1.ctx.battle.teamA) do
		if var_23_0 < iter_23_1.harms then
			var_23_0 = iter_23_1.harms
			var_23_1 = iter_23_1
		end
	end

	for iter_23_2, iter_23_3 in ipairs(var_0_1.ctx.battle.teamB) do
		if var_23_0 < iter_23_3.harms then
			var_23_0 = iter_23_3.harms
			var_23_1 = iter_23_3
		end
	end

	if not var_23_1 then
		return {}
	end

	local var_23_2 = {}
	local var_23_3, var_23_4 = var_23_1:getPos()
	local var_23_5 = var_0_14:scope(arg_23_1)

	for iter_23_4, iter_23_5 in ipairs(var_0_1.ctx.battle.teamA) do
		local var_23_6, var_23_7 = iter_23_5:getPos()

		if not iter_23_5:isDeath() and not iter_23_5:isAffected() and math.abs(var_23_3 - var_23_6) <= var_23_5 / 2 then
			table.insert(var_23_2, iter_23_5)
		end
	end

	for iter_23_6, iter_23_7 in ipairs(var_0_1.ctx.battle.teamB) do
		local var_23_8, var_23_9 = iter_23_7:getPos()

		if not iter_23_7:isDeath() and not iter_23_7:isAffected() and math.abs(var_23_3 - var_23_8) <= var_23_5 / 2 then
			table.insert(var_23_2, iter_23_7)
		end
	end

	return var_23_2
end

function var_0_3.randomPosDeal(arg_24_0)
	if not arg_24_0.randomPosCount then
		return
	end

	arg_24_0.randomPosCount = arg_24_0.randomPosCount - 1

	local var_24_0 = 20

	if arg_24_0.randomPosCount == var_24_0 then
		var_0_1.ctx.battle.stopAllFighter()
		var_0_1.ctx.battle.blackLayer:show()

		var_0_1.ctx.battle.isEnergySkilling = var_24_0

		if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.CreateReport then
			local var_24_1 = "skeletons/ui_effect/conquer_school/test01"
			local var_24_2 = var_0_17.new(var_24_1 .. ".json", var_24_1 .. ".atlas", 1)

			var_24_2:addTo(var_0_1.ctx.battle.unitLayer, 100)
			var_24_2:setScale(1.6)
			var_24_2:pos(640, 360)
			var_24_2:play(function()
				var_24_2:setVisible(false)
			end, false)
		end
	elseif arg_24_0.randomPosCount == 0 then
		arg_24_0.randomPosCount = nil

		local var_24_3 = {}

		for iter_24_0, iter_24_1 in ipairs(var_0_1.ctx.battle.teamA) do
			if iter_24_1:getSummonType() == var_0_2.summonMonsterType.None then
				table.insert(var_24_3, cc.p(iter_24_1:getPos()))
			end
		end

		for iter_24_2, iter_24_3 in ipairs(var_0_1.ctx.battle.teamB) do
			if iter_24_3:getSummonType() == var_0_2.summonMonsterType.None then
				table.insert(var_24_3, cc.p(iter_24_3:getPos()))
			end
		end

		for iter_24_4, iter_24_5 in ipairs(var_0_1.ctx.battle.teamA) do
			if iter_24_5:getSummonType() == var_0_2.summonMonsterType.None then
				local var_24_4 = 1

				if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
					var_24_4 = arg_24_0.posAttrA_[tostring(var_0_1.ctx.battle.count)][iter_24_4] or 1
				else
					var_24_4 = math.random(#var_24_3)

					if not arg_24_0.records_.pos_attr_a[tostring(var_0_1.ctx.battle.count)] then
						arg_24_0.records_.pos_attr_a[tostring(var_0_1.ctx.battle.count)] = {}
					end

					arg_24_0.records_.pos_attr_a[tostring(var_0_1.ctx.battle.count)][iter_24_4] = var_24_4
				end

				local var_24_5 = var_24_4

				iter_24_5:pos(var_24_3[var_24_5].x, var_24_3[var_24_5].y)
				table.remove(var_24_3, var_24_5)
			end
		end

		for iter_24_6, iter_24_7 in ipairs(var_0_1.ctx.battle.teamB) do
			if iter_24_7:getSummonType() == var_0_2.summonMonsterType.None then
				local var_24_6 = 1

				if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
					var_24_6 = arg_24_0.posAttrB_[tostring(var_0_1.ctx.battle.count)][iter_24_6] or 1
				else
					var_24_6 = math.random(#var_24_3)

					if not arg_24_0.records_.pos_attr_b[tostring(var_0_1.ctx.battle.count)] then
						arg_24_0.records_.pos_attr_b[tostring(var_0_1.ctx.battle.count)] = {}
					end

					arg_24_0.records_.pos_attr_b[tostring(var_0_1.ctx.battle.count)][iter_24_6] = var_24_6
				end

				local var_24_7 = var_24_6

				iter_24_7:pos(var_24_3[var_24_7].x, var_24_3[var_24_7].y)
				table.remove(var_24_3, var_24_7)
			end
		end

		arg_24_0.isOnlyOneTurn = true
	end
end

function var_0_3.aeroliteDeal(arg_26_0)
	arg_26_0.aeroliteCount = arg_26_0.aeroliteCount - 1

	if arg_26_0.aeroliteCount == 0 then
		arg_26_0.aeroliteCount = arg_26_0.aeroliteInterval

		local var_26_0

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_26_0 = arg_26_0.reportSkills_[1]

			table.remove(arg_26_0.reportSkills_, 1)
		else
			var_26_0 = var_0_4.new({
				fighter = arg_26_0,
				skillID = arg_26_0.aeroliteSkillId
			})
		end

		arg_26_0:createUnits(var_26_0)
		table.insert(arg_26_0.records_.skills, var_26_0)
	end
end

function var_0_3.energySummonDeal(arg_27_0)
	local var_27_0 = arg_27_0:getInfoByKey("attack_info")

	if not var_27_0 or not next(var_27_0) then
		return
	end

	for iter_27_0, iter_27_1 in ipairs(var_27_0) do
		local var_27_1 = iter_27_1.fighter_

		if iter_27_1.rootID_ == var_27_1:getEnergySkillID() then
			if var_27_1:getTeamType() == var_0_2.TeamType.A then
				arg_27_0.energyCountA = arg_27_0.energyCountA + 1

				if arg_27_0.energyCountA == 3 then
					arg_27_0.energyCountA = 0

					arg_27_0:summonMonster(var_27_1, var_0_9, 1, 1)
				end
			elseif var_27_1:getTeamType() == var_0_2.TeamType.B then
				arg_27_0.energyCountB = arg_27_0.energyCountB + 1

				if arg_27_0.energyCountB == 3 then
					arg_27_0.energyCountB = 0

					arg_27_0:summonMonster(var_27_1, var_0_9, 1, 1)
				end
			end
		end
	end
end

function var_0_3.summonMonster(arg_28_0, arg_28_1, arg_28_2, arg_28_3, arg_28_4)
	local var_28_0
	local var_28_1 = {
		x = arg_28_1:getX(),
		y = arg_28_1:getY()
	}
	local var_28_2

	if arg_28_1:getTeamType() == var_0_2.TeamType.A then
		var_28_2 = "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1)
	else
		var_28_2 = "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_28_0 = var_0_1.ctx.battle.summonMonsters[var_28_2]
	else
		local var_28_3 = var_0_6.new()

		var_28_3:populateWithTableID(arg_28_2)

		var_28_3.level_ = arg_28_3 or var_28_3.level_
		var_28_3.color_ = arg_28_4 or var_28_3.color_
		var_28_3.skillLev_ = {
			1,
			1,
			1,
			1,
			1
		}

		local var_28_4 = var_28_3:className()

		var_28_0 = var_0_1.ctx.battle.requireFighter(var_28_4).new({
			is_arena = arg_28_0.isInArena_
		})

		var_28_0:populateWithHero(var_28_3)
		var_28_0:initModels()

		if arg_28_1:getTeamType() == var_0_2.TeamType.A then
			var_28_0.fighterModel:initHeaderView(var_0_2.TeamType.A - 1)
		else
			var_28_0.fighterModel:initHeaderView(var_0_2.TeamType.B - 1)
		end

		var_28_0.fighterIndex = var_28_2

		var_28_0:setFormationDelay(0, 100)
	end

	if arg_28_1:getTeamType() == var_0_2.TeamType.A then
		var_28_0:setTeamType(var_0_2.TeamType.A)
		table.insert(var_0_1.ctx.battle.teamA, var_28_0)
	elseif arg_28_1:getTeamType() == var_0_2.TeamType.B then
		var_28_0:setTeamType(var_0_2.TeamType.B)
		table.insert(var_0_1.ctx.battle.teamB, var_28_0)
	end

	var_28_0.fighterModel:pos(var_28_1.x, var_28_1.y)
	var_28_0:updateHp(arg_28_1:getHpLimit())
	var_28_0:getFighterModel():flipX(arg_28_0:getTeamType() == var_0_2.TeamType.B)
	var_28_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_28_0:born()
	var_28_0:setGlobalBuffs()
	table.insert(var_0_1.ctx.battle.yOrder, var_28_0)
	var_0_1.ctx.battle.updateZorder()
end

function var_0_3.heroDieSkill(arg_29_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_29_0 = 10000960

	function getDieSkillTargets(arg_30_0)
		local var_30_0 = var_0_14:scope(var_29_0) / 2
		local var_30_1 = arg_30_0:getX()
		local var_30_2 = {}

		for iter_30_0, iter_30_1 in ipairs(var_0_1.ctx.battle.teamA) do
			if not iter_30_1:isDeath() and not iter_30_1:isAffected() and var_30_0 >= math.abs(var_30_1 - iter_30_1:getX()) then
				table.insert(var_30_2, iter_30_1)
			end
		end

		for iter_30_2, iter_30_3 in ipairs(var_0_1.ctx.battle.teamB) do
			if not iter_30_3:isDeath() and not iter_30_3:isAffected() and var_30_0 >= math.abs(var_30_1 - iter_30_3:getX()) then
				table.insert(var_30_2, iter_30_3)
			end
		end

		return var_30_2
	end

	for iter_29_0, iter_29_1 in ipairs(arg_29_0:getInfoByKey("death_info")) do
		if iter_29_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_29_1 = getDieSkillTargets(iter_29_1)
			local var_29_2 = arg_29_0:createAttackUnits(var_29_1, var_29_0)

			for iter_29_2, iter_29_3 in ipairs(var_29_2) do
				table.insert(arg_29_0.moveAttackUnits_, iter_29_3)
				table.insert(arg_29_0.records_.special_units, iter_29_3)
			end
		end
	end
end

function var_0_3.heroKillEnergy(arg_31_0)
	for iter_31_0, iter_31_1 in ipairs(arg_31_0:getInfoByKey("death_info")) do
		if iter_31_1:getSummonType() == var_0_2.summonMonsterType.None and iter_31_1.killer_ and not iter_31_1.killer_:isDeath() and iter_31_1.killer_:getSummonType() == var_0_2.summonMonsterType.None then
			iter_31_1.killer_:updateEnergyBy(1000)
		end
	end
end

function var_0_3.attrDown(arg_32_0)
	local var_32_0 = var_0_1.ctx.battle.teamA[1]
	local var_32_1 = var_0_1.ctx.battle.teamB[1]

	if not arg_32_0.isAddMarkBuff then
		arg_32_0.isAddMarkBuff = true

		local var_32_2 = var_0_11:buff(arg_32_0.buffType)
		local var_32_3 = arg_32_0:newBuff(var_32_2, var_32_0, skillID)

		var_32_0:addBuffs(var_32_3)

		local var_32_4 = arg_32_0:newBuff(var_32_2, var_32_1, skillID)

		var_32_1:addBuffs(var_32_4)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local function var_32_5(arg_33_0)
		local var_33_0 = arg_33_0.selfTeam_
		local var_33_1 = {}

		for iter_33_0, iter_33_1 in ipairs(var_33_0) do
			if not iter_33_1:isDeath() then
				table.insert(var_33_1, iter_33_1)
			end
		end

		return var_33_1
	end

	for iter_32_0, iter_32_1 in ipairs(arg_32_0:getInfoByKey("death_info")) do
		if iter_32_1 == var_32_0 or iter_32_1 == var_32_1 then
			local var_32_6 = var_32_5(iter_32_1)
			local var_32_7 = arg_32_0:createAttackUnits(var_32_6, 10000959)

			for iter_32_2, iter_32_3 in ipairs(var_32_7) do
				table.insert(arg_32_0.moveAttackUnits_, iter_32_3)
				table.insert(arg_32_0.records_.special_units, iter_32_3)
			end
		end
	end
end

function var_0_3.dieComeback(arg_34_0)
	local var_34_0 = 120

	for iter_34_0, iter_34_1 in ipairs(arg_34_0:getInfoByKey("death_info")) do
		if iter_34_1:getTeamType() == var_0_2.TeamType.B and iter_34_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(arg_34_0.dieComebackList_, {
				target = iter_34_1,
				time_ = var_34_0
			})
		end
	end

	if arg_34_0:acttionInBlack() then
		for iter_34_2 = #arg_34_0.dieComebackList_, 1, -1 do
			arg_34_0.dieComebackList_[iter_34_2].time_ = arg_34_0.dieComebackList_[iter_34_2].time_ - 1

			if arg_34_0.dieComebackList_[iter_34_2].time_ <= 0 then
				local var_34_1 = arg_34_0.dieComebackList_[iter_34_2].target

				arg_34_0:summonMonsterByTarget(var_34_1)
				table.remove(arg_34_0.dieComebackList_, iter_34_2)
			end
		end
	end
end

function var_0_3.summonMonsterByTarget(arg_35_0, arg_35_1)
	if arg_35_1:getTeamType() == var_0_2.TeamType.A then
		-- block empty
	end

	local var_35_0 = true
	local var_35_1 = 0

	if var_35_0 then
		var_35_1 = var_0_2.STAGE_WIDTH
	end

	local var_35_2 = arg_35_1:getY()
	local var_35_3

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_35_4 = arg_35_1:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_35_3 = var_0_1.ctx.battle.summonMonsters[var_35_4]
	else
		local var_35_5 = var_0_6.new()
		local var_35_6 = arg_35_1.hero_:toParams()

		var_35_5:populate(var_35_6)

		local var_35_7 = var_35_5:className()

		var_35_3 = var_0_1.ctx.battle.requireFighter(var_35_7).new({
			is_arena = arg_35_0.isInArena_
		})

		var_35_3:populateWithHero(var_35_5)
		var_35_3:initModels()
		var_35_3:getFighterModel():idle()

		local var_35_8 = arg_35_1:getTeamType() - 1

		var_35_3.fighterModel:initHeaderView(var_35_8)
		var_35_3:getFighterModel():flipX(flipX)

		local var_35_9 = #arg_35_1.selfTeam_ + 1

		var_35_3.fighterIndex = arg_35_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_35_3:setFormationDelay(0, 100)
	end

	var_35_3.summoner = arg_35_0

	var_35_3.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_35_3:setTeamType(arg_35_1:getTeamType())
	var_35_3.fighterModel:pos(var_35_1, var_35_2)
	var_35_3:setupBattleAttrInfo()
	var_35_3:setGlobalBuffs()
	var_35_3:born()
	var_35_3:flipX(var_35_0)

	var_35_3.summonType_ = var_0_2.summonMonsterType.Mirrow

	table.insert(arg_35_1.selfTeam_, var_35_3)
end

function var_0_3.heroMaxAttack(arg_36_0)
	local var_36_0 = 40011053

	local function var_36_1(arg_37_0, arg_37_1)
		local var_37_0 = arg_36_0:newBuff({
			var_36_0
		}, arg_37_0, arg_36_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		var_37_0[1]:setShieldNum(arg_37_1)
		var_37_0[1]:setActNum(arg_37_1)
		arg_37_0:addBuffs(var_37_0)
	end

	if not arg_36_0.isAddAttackMarkBuff_ then
		arg_36_0.isAddAttackMarkBuff_ = true

		for iter_36_0, iter_36_1 in ipairs(var_0_1.ctx.battle.teamB) do
			if not iter_36_1:isDeath() then
				var_36_1(iter_36_1, 20)
			end
		end

		for iter_36_2, iter_36_3 in ipairs(var_0_1.ctx.battle.teamA) do
			if not iter_36_3:isDeath() then
				var_36_1(iter_36_3, 20)
			end
		end
	end

	for iter_36_4, iter_36_5 in ipairs(arg_36_0:getInfoByKey("harm_info")) do
		local var_36_2 = iter_36_5.harm
		local var_36_3 = iter_36_5.target
		local var_36_4 = var_36_3:getBuffByID(var_36_0)

		if var_36_2 > 0 and var_36_4 then
			local var_36_5 = var_36_4:getShieldNum()

			if var_36_5 - 1 <= 0 then
				var_36_3:updateHp(0)
				var_36_3:die()
			else
				var_36_3:removeBuffs(var_36_4)
				var_36_1(var_36_3, var_36_5 - 1)
			end
		end
	end
end

function var_0_3.doubleMove(arg_38_0)
	local var_38_0 = 1

	for iter_38_0, iter_38_1 in ipairs(arg_38_0:getInfoByKey("buff_info")) do
		local var_38_1 = iter_38_1.target

		if not var_38_1:isBreakImmortal() and iter_38_1:getType() == var_0_2.BuffType.MOVE and iter_38_1:Xchange() > 0 then
			if iter_38_1:getYx() > 0 and var_38_1.buffMovePath_ and next(var_38_1.buffMovePath_) then
				local var_38_2 = iter_38_1:getPath()

				for iter_38_2, iter_38_3 in pairs(var_38_2) do
					var_38_1.buffMovePath_[iter_38_2] = var_38_1.buffMovePath_[iter_38_2] or {
						0,
						0
					}
					var_38_1.buffMovePath_[iter_38_2][1] = var_38_1.buffMovePath_[iter_38_2][1] + var_38_2[iter_38_2][1] * var_38_0
				end
			elseif iter_38_1:getYx() > 0 then
				var_38_1.buffMovePath_ = iter_38_1:getPath()
			end
		end
	end
end

function var_0_3.dHarmUp(arg_39_0)
	local var_39_0 = 0.75

	for iter_39_0, iter_39_1 in ipairs(arg_39_0:getInfoByKey("buff_info")) do
		if iter_39_1:getType() == var_0_2.BuffType.D_HARM then
			local var_39_1 = iter_39_1:getDHarm() * var_39_0

			iter_39_1.dHarm_ = iter_39_1.dHarm_ + var_39_1
		elseif iter_39_1:getType() == var_0_2.BuffType.SHIELD_BUFF then
			local var_39_2 = iter_39_1:getShieldMaxHarm() * var_39_0

			iter_39_1.manualHarmRevise = iter_39_1.manualHarmRevise + var_39_2
		end
	end
end

function var_0_3.summonStrong(arg_40_0)
	local var_40_0 = {
		40011065,
		40011066
	}

	for iter_40_0, iter_40_1 in ipairs(arg_40_0:getInfoByKey("born_info")) do
		if iter_40_1:getSummonType() ~= var_0_2.summonMonsterType.None then
			local var_40_1 = arg_40_0:newBuff(var_40_0, iter_40_1, arg_40_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

			iter_40_1:addBuffs(var_40_1)
		end
	end
end

function var_0_3.summonAid(arg_41_0)
	local var_41_0 = 88400002
	local var_41_1 = 9
	local var_41_2 = 300
	local var_41_3 = 150

	if var_0_1.ctx.battle.count == var_41_2 then
		arg_41_0:summonAidMonster(var_41_0)

		arg_41_0.summonAidCount_ = 1
	elseif var_41_2 < var_0_1.ctx.battle.count and (var_0_1.ctx.battle.count - var_41_2) % var_41_3 < 1 then
		local var_41_4 = var_41_0 + arg_41_0.summonAidCount_

		arg_41_0:summonAidMonster(var_41_4)

		arg_41_0.summonAidCount_ = arg_41_0.summonAidCount_ + 1

		if arg_41_0.summonAidCount_ % var_41_1 == 1 then
			arg_41_0.summonAidCount_ = 1
		end
	end
end

function var_0_3.summonAidMonster(arg_42_0, arg_42_1)
	local var_42_0
	local var_42_1 = {
		y = 350,
		x = var_0_2.STAGE_WIDTH
	}
	local var_42_2 = "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_42_0 = var_0_1.ctx.battle.summonMonsters[var_42_2]
	else
		local var_42_3 = var_0_6.new()

		var_42_3:populateWithTableID(arg_42_1)

		local var_42_4 = var_42_3:className()

		var_42_0 = var_0_1.ctx.battle.requireFighter(var_42_4).new({
			is_arena = arg_42_0.isInArena_
		})

		var_42_0:populateWithHero(var_42_3)
		var_42_0:initModels()
		var_42_0.fighterModel:initHeaderView(var_0_2.TeamType.B - 1)

		var_42_0.fighterIndex = var_42_2

		var_42_0:setFormationDelay(0, 100)
	end

	var_42_0:setTeamType(var_0_2.TeamType.B)
	table.insert(var_0_1.ctx.battle.teamB, var_42_0)
	var_42_0.fighterModel:pos(var_42_1.x, var_42_1.y)
	var_42_0:updateHp(var_42_0:getHpLimit())
	var_42_0:getFighterModel():flipX(true)
	var_42_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_42_0:born()
	var_42_0:setGlobalBuffs()
	table.insert(var_0_1.ctx.battle.yOrder, var_42_0)
	var_0_1.ctx.battle.updateZorder()
end

function var_0_3.killOneForAll(arg_43_0)
	for iter_43_0, iter_43_1 in ipairs(arg_43_0:getInfoByKey("death_info")) do
		if iter_43_1:getSummonType() == var_0_2.summonMonsterType.None and iter_43_1:getTeamType() == var_0_2.TeamType.A then
			for iter_43_2, iter_43_3 in pairs(var_0_1.ctx.battle.teamA) do
				if not iter_43_3:isDeath() then
					iter_43_3:forceDie(0)
				end
			end

			break
		end
	end
end

function var_0_3.checkNoAlive(arg_44_0, arg_44_1)
	local var_44_0 = arg_44_1 == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_44_1 = false

	for iter_44_0, iter_44_1 in pairs(var_44_0) do
		if iter_44_1:getSummonType() == var_0_2.summonMonsterType.None and (not iter_44_1:isDeath() or iter_44_1:canReborn()) then
			var_44_1 = true

			break
		end
	end

	return var_44_1
end

function var_0_3.checkNotEnd(arg_45_0)
	if arg_45_0.buffType == var_0_2.ConquerSchoolBuff.KOF then
		if #arg_45_0.teamA == 0 and not arg_45_0:checkNoAlive(var_0_2.TeamType.A) or #arg_45_0.teamB == 0 and not arg_45_0:checkNoAlive(var_0_2.TeamType.B) then
			return false
		end

		return true
	end
end

function var_0_3.KOF(arg_46_0)
	local var_46_0 = {}

	for iter_46_0, iter_46_1 in pairs(var_0_1.ctx.battle.teamA) do
		if not iter_46_1:isDeath() then
			-- block empty
		end
	end

	function getCurrentFighter(arg_47_0)
		local var_47_0 = arg_47_0 == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
		local var_47_1 = arg_47_0 == var_0_2.TeamType.A and arg_46_0.teamA or arg_46_0.teamB
		local var_47_2 = false

		for iter_47_0, iter_47_1 in pairs(var_47_0) do
			if iter_47_1:getSummonType() == var_0_2.summonMonsterType.None and (not iter_47_1:isDeath() or iter_47_1:canReborn()) then
				var_47_2 = iter_47_1
			end
		end

		if not var_47_2 then
			killAllMonsters()

			for iter_47_2, iter_47_3 in pairs(var_47_1) do
				table.insert(var_47_0, iter_47_3)
				iter_47_3.fighterModel:setVisible(true)
				iter_47_3:updateTeamCache()
				table.remove(var_47_1, iter_47_2)

				break
			end

			for iter_47_4, iter_47_5 in pairs(var_47_1) do
				iter_47_5.fighterModel:setVisible(false)
			end
		end
	end

	function killAllMonsters()
		for iter_48_0, iter_48_1 in ipairs(var_0_1.ctx.battle.teamA) do
			if iter_48_1:getSummonType() ~= var_0_2.summonMonsterType.None then
				iter_48_1:forceDie()
			end
		end

		for iter_48_2, iter_48_3 in ipairs(var_0_1.ctx.battle.teamB) do
			if iter_48_3:getSummonType() ~= var_0_2.summonMonsterType.None then
				iter_48_3:forceDie()
			end
		end
	end

	getCurrentFighter(var_0_2.TeamType.A)
	getCurrentFighter(var_0_2.TeamType.B)

	for iter_46_2, iter_46_3 in ipairs(arg_46_0:getInfoByKey("death_info")) do
		if iter_46_3:getSummonType() == var_0_2.summonMonsterType.None and not iter_46_3:canReborn() then
			for iter_46_4, iter_46_5 in pairs(var_0_1.ctx.battle.teamA) do
				iter_46_5:cleanAllBuffs()
				iter_46_5:setGlobalBuffs()

				if (#arg_46_0.teamA ~= 0 or not not arg_46_0:checkNoAlive(var_0_2.TeamType.A)) and (#arg_46_0.teamB ~= 0 or not not arg_46_0:checkNoAlive(var_0_2.TeamType.B)) and not iter_46_5:isDeath() then
					iter_46_5:x(-100)
				end
			end

			for iter_46_6, iter_46_7 in pairs(var_0_1.ctx.battle.teamB) do
				iter_46_7:cleanAllBuffs()
				iter_46_7:setGlobalBuffs()

				if (#arg_46_0.teamA ~= 0 or not not arg_46_0:checkNoAlive(var_0_2.TeamType.A)) and (#arg_46_0.teamB ~= 0 or not not arg_46_0:checkNoAlive(var_0_2.TeamType.B)) and not iter_46_7:isDeath() then
					iter_46_7:x(1380)
				end
			end

			killAllMonsters()
		end
	end
end

function var_0_3.powerOverWhelming(arg_49_0)
	if var_0_1.ctx.battle.count == 1 then
		for iter_49_0, iter_49_1 in pairs(var_0_1.ctx.battle.teamA) do
			if iter_49_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
				iter_49_1:updateEnergyBy(1000)
			end
		end

		for iter_49_2, iter_49_3 in pairs(var_0_1.ctx.battle.teamB) do
			if iter_49_3:getSummonType() ~= var_0_2.summonMonsterType.Pet then
				iter_49_3:updateEnergyBy(1000)
			end
		end
	end

	for iter_49_4, iter_49_5 in pairs(arg_49_0:getInfoByKey("attack_info")) do
		if iter_49_5.fighter_:getEnergySkillID() == var_0_14:father(iter_49_5.rootID_) and iter_49_5.fighter_:getSummonType() ~= var_0_2.summonMonsterType.Pet and iter_49_5.fighter_:getTeamType() ~= var_0_2.TeamType.B and not arg_49_0.dyingHeroTimeCount[iter_49_5.fighter_] then
			arg_49_0.dyingHeroTimeCount[iter_49_5.fighter_] = var_0_1.ctx.battle.count
		end
	end

	for iter_49_6, iter_49_7 in pairs(arg_49_0.dyingHeroTimeCount) do
		if var_0_1.ctx.battle.count - iter_49_7 > var_0_15 and not iter_49_6:isDeath() then
			arg_49_0.dyingHeroTimeCount[iter_49_6] = nil

			iter_49_6:die()
			iter_49_6:updateHp(0)
			iter_49_6:forceDie()
		end
	end
end

function var_0_3.superFear(arg_50_0)
	for iter_50_0, iter_50_1 in ipairs(arg_50_0:getInfoByKey("buff_info")) do
		if iter_50_1:isFear() then
			iter_50_1:setExtraTime(var_0_16)
		end
	end
end

function var_0_3.firstKill(arg_51_0)
	if not arg_51_0.isFirstKillBuffAdd then
		arg_51_0.isFirstKillBuffAdd = true
		arg_51_0.firstKillTarget = var_0_1.ctx.battle.teamB[math.ceil(#var_0_1.ctx.battle.teamB / 2)]

		local var_51_0 = var_0_5.new({
			level = 1,
			tableID = arg_51_0.firstKillBuffID,
			start = var_0_1.ctx.battle.count,
			skillID = arg_51_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
			fighter = arg_51_0,
			target = arg_51_0.firstKillTarget
		})

		arg_51_0.firstKillTarget:addBuffs({
			var_51_0
		})
	end

	local var_51_1

	for iter_51_0, iter_51_1 in ipairs(arg_51_0:getInfoByKey("death_info")) do
		if iter_51_1:getSummonType() == var_0_2.summonMonsterType.None and iter_51_1:getTeamType() == var_0_2.TeamType.B and not iter_51_1:canReborn() then
			var_51_1 = iter_51_1

			break
		end
	end

	if var_51_1 and arg_51_0.firstKillTarget and var_51_1 == arg_51_0.firstKillTarget then
		arg_51_0.firstKillTarget = nil
	elseif var_51_1 and arg_51_0.firstKillTarget and var_51_1 ~= arg_51_0.firstKillTarget then
		for iter_51_2, iter_51_3 in ipairs(var_0_1.ctx.battle.teamA) do
			iter_51_3:forceDie()
		end
	end
end

function var_0_3.killOneFreeze(arg_52_0)
	for iter_52_0, iter_52_1 in ipairs(arg_52_0:getInfoByKey("death_info")) do
		if iter_52_1:getSummonType() == var_0_2.summonMonsterType.None and iter_52_1.killer_ and not iter_52_1.killer_:isDeath() and not iter_52_1.killer_:isAffected() then
			local var_52_0 = var_0_5.new({
				level = 1,
				tableID = arg_52_0.killOneFreezeBuffID,
				start = var_0_1.ctx.battle.count,
				skillID = arg_52_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
				fighter = arg_52_0,
				target = iter_52_1.killer_
			})

			iter_52_1.killer_:addBuffs({
				var_52_0
			})
		end
	end
end

function var_0_3.twoSideBuff(arg_53_0)
	local function var_53_0(arg_54_0, arg_54_1, arg_54_2)
		local var_54_0 = {}

		for iter_54_0, iter_54_1 in ipairs(arg_54_0) do
			local var_54_1 = {
				level = 1,
				tableID = iter_54_1,
				start = var_0_1.ctx.battle.count,
				skillID = arg_54_2,
				fighter = arg_53_0,
				target = arg_54_1
			}
			local var_54_2 = var_0_5.new(var_54_1)

			var_54_2:setIsHit(true)
			var_54_2:setDirection(arg_53_0:getFlipX())
			table.insert(var_54_0, var_54_2)
		end

		return var_54_0
	end

	if var_0_1.ctx.battle.count % arg_53_0.exchangeBuffTime == 1 then
		if arg_53_0.selfTeamGain then
			arg_53_0.selfTeamGain = false

			for iter_53_0, iter_53_1 in ipairs(var_0_1.ctx.battle.teamA) do
				if not iter_53_1:isDeath() and not iter_53_1:isAffected() then
					local var_53_1 = var_53_0(arg_53_0.gainBuffIDs, iter_53_1, arg_53_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

					iter_53_1:addBuffs(var_53_1)
				end
			end

			for iter_53_2, iter_53_3 in ipairs(var_0_1.ctx.battle.teamB) do
				if not iter_53_3:isDeath() and not iter_53_3:isAffected() then
					local var_53_2 = var_53_0(arg_53_0.deBuffIDs, iter_53_3, arg_53_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

					iter_53_3:addBuffs(var_53_2)
				end
			end
		else
			arg_53_0.selfTeamGain = true

			for iter_53_4, iter_53_5 in ipairs(var_0_1.ctx.battle.teamB) do
				if not iter_53_5:isDeath() and not iter_53_5:isAffected() then
					local var_53_3 = var_53_0(arg_53_0.gainBuffIDs, iter_53_5, arg_53_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

					iter_53_5:addBuffs(var_53_3)
				end
			end

			for iter_53_6, iter_53_7 in ipairs(var_0_1.ctx.battle.teamA) do
				if not iter_53_7:isDeath() and not iter_53_7:isAffected() then
					local var_53_4 = var_53_0(arg_53_0.deBuffIDs, iter_53_7, arg_53_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

					iter_53_7:addBuffs(var_53_4)
				end
			end
		end
	end
end

function var_0_3.betMachine(arg_55_0)
	local var_55_0 = math.random

	if not arg_55_0.isInitBetNum then
		arg_55_0.isInitBetNum = true

		if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
			arg_55_0.selfRandom = arg_55_0.selfRandom_[tostring(var_0_1.ctx.battle.count)] or 100
			arg_55_0.sideRandom = arg_55_0.sideRandom_[tostring(var_0_1.ctx.battle.count)] or 100
		else
			local var_55_1 = var_55_0(1, 100)
			local var_55_2 = var_55_0(1, 100)

			if var_55_1 <= 90 then
				arg_55_0.selfRandom = var_55_0(40, 99)
			else
				arg_55_0.selfRandom = var_55_0(100, 160)
			end

			if var_55_1 <= 90 then
				arg_55_0.sideRandom = var_55_0(100, 160)
			else
				arg_55_0.sideRandom = var_55_0(40, 99)
			end

			arg_55_0.records_.self_random[tostring(var_0_1.ctx.battle.count)] = arg_55_0.selfRandom
			arg_55_0.records_.side_random[tostring(var_0_1.ctx.battle.count)] = arg_55_0.sideRandom
		end

		local var_55_3 = var_0_2.AssetLoader.get():loadNodeFromJson("windows/conquer_school/bet_machine/bet_machine.csb")

		var_55_3:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_55_3:setVisible(true)
		var_55_3:setAnchorPoint(cc.p(0, 0))
		var_55_3:setPosition(150, 530)

		local var_55_4 = var_55_3:getChildByName("bg")
		local var_55_5 = var_0_2.AssetLoader.get():loadNodeFromJson("windows/conquer_school/bet_machine/bet_machine.csb")

		var_55_5:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_55_5:setVisible(true)
		var_55_5:setAnchorPoint(cc.p(0, 0))
		var_55_5:setPosition(930, 530)

		local var_55_6 = var_55_5:getChildByName("bg")

		for iter_55_0 = 1, 3 do
			local var_55_7 = "skeletons/conquer_school/laoguji01"
			local var_55_8 = var_55_7 .. ".json"
			local var_55_9 = var_55_7 .. ".atlas"
			local var_55_10 = var_0_17.new(var_55_8, var_55_9, 1)

			var_55_10:addTo(var_55_4)
			var_55_10:setVisible(true)
			var_55_10:setAnchorPoint(cc.p(0, 0))
			var_55_10:setPosition(var_55_4:getChildByName("text" .. iter_55_0):getPosition())

			local var_55_11 = "skeletons/conquer_school/laohuji02"
			local var_55_12 = var_55_11 .. ".json"
			local var_55_13 = var_55_11 .. ".atlas"
			local var_55_14 = var_0_17.new(var_55_12, var_55_13, 1)

			var_55_14:addTo(var_55_4)
			var_55_14:setAnchorPoint(cc.p(0, 0))
			var_55_14:setPosition(var_55_4:getChildByName("text" .. iter_55_0):getPosition())
			var_55_10:play(function()
				var_55_10:setVisible(false)
				var_55_14:setVisible(true)
				var_55_14:play(function()
					var_55_14:setVisible(false)

					if iter_55_0 == 3 then
						var_55_4:getChildByName("text1"):setString(arg_55_0.selfRandom >= 100 and "1." or "0.")
						var_55_4:getChildByName("text2"):setString(math.floor(arg_55_0.selfRandom % 100 / 10))
						var_55_4:getChildByName("text3"):setString(arg_55_0.selfRandom % 10)
					end
				end, false)
			end, false)
		end

		for iter_55_1 = 1, 3 do
			local var_55_15 = "skeletons/conquer_school/laoguji01"
			local var_55_16 = var_55_15 .. ".json"
			local var_55_17 = var_55_15 .. ".atlas"
			local var_55_18 = var_0_17.new(var_55_16, var_55_17, 1)

			var_55_18:addTo(var_55_6)
			var_55_18:setAnchorPoint(cc.p(0, 0))
			var_55_18:setPosition(var_55_6:getChildByName("text" .. iter_55_1):getPosition())

			local var_55_19 = "skeletons/conquer_school/laohuji02"
			local var_55_20 = var_55_19 .. ".json"
			local var_55_21 = var_55_19 .. ".atlas"
			local var_55_22 = var_0_17.new(var_55_20, var_55_21, 1)

			var_55_22:addTo(var_55_6)
			var_55_22:setAnchorPoint(cc.p(0, 0))
			var_55_22:setPosition(var_55_6:getChildByName("text" .. iter_55_1):getPosition())
			var_55_18:play(function()
				var_55_18:setVisible(false)
				var_55_22:setVisible(true)
				var_55_22:play(function()
					var_55_22:setVisible(false)

					if iter_55_1 == 3 then
						var_55_6:getChildByName("text1"):setString(arg_55_0.sideRandom >= 100 and "1." or "0.")
						var_55_6:getChildByName("text2"):setString(math.floor(arg_55_0.sideRandom % 100 / 10))
						var_55_6:getChildByName("text3"):setString(arg_55_0.sideRandom % 10)
					end
				end, false)
			end, false)
		end
	end
end

function var_0_3.energyOneShot(arg_60_0)
	local var_60_0 = arg_60_0:getInfoByKey("attack_info")

	if not var_60_0 or not next(var_60_0) then
		return
	end

	for iter_60_0, iter_60_1 in ipairs(var_60_0) do
		local var_60_1 = iter_60_1.fighter_

		if var_0_14:father(iter_60_1.rootID_) == var_60_1:getEnergySkillID() and arg_60_0.buffType == var_0_2.ConquerSchoolBuff.ONE_SHOT then
			var_60_1:addBuffs(arg_60_0:newBuff(var_0_11:buff(arg_60_0.buffType), var_60_1, arg_60_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)))
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_61_0, arg_61_1, arg_61_2, arg_61_3, arg_61_4, arg_61_5, arg_61_6, arg_61_7)
	local var_61_0, var_61_1, var_61_2, var_61_3, var_61_4, var_61_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_61_0, arg_61_1, arg_61_2, arg_61_3, arg_61_4, arg_61_5, arg_61_6, arg_61_7)

	if arg_61_0.buffType == var_0_2.ConquerSchoolBuff.BET_MACHINE then
		if var_61_2 > 0 and arg_61_1.fighter:getTeamType() == var_0_2.TeamType.A and arg_61_1.target:getTeamType() == var_0_2.TeamType.B then
			var_61_2 = var_61_2 * arg_61_0.selfRandom / 100
		elseif var_61_2 > 0 and arg_61_1.fighter:getTeamType() == var_0_2.TeamType.B and arg_61_1.target:getTeamType() == var_0_2.TeamType.A then
			var_61_2 = var_61_2 * arg_61_0.sideRandom / 100
		end
	end

	return var_61_0, var_61_1, var_61_2, var_61_3, var_61_4, var_61_5
end

function var_0_3.setupReport(arg_62_0, arg_62_1)
	var_0_3.super.setupReport(arg_62_0, arg_62_1)

	arg_62_0.killAHeroCount_ = arg_62_1.kill_a_hero_id or {}
	arg_62_0.killBHeroCount_ = arg_62_1.kill_b_hero_id or {}
	arg_62_0.randomBuffCount_ = arg_62_1.random_buff_count or {}
	arg_62_0.posAttrA_ = arg_62_1.pos_attr_a or {}
	arg_62_0.posAttrB_ = arg_62_1.pos_attr_b or {}
	arg_62_0.selfRandom_ = arg_62_1.self_random or {}
	arg_62_0.sideRandom_ = arg_62_1.side_random or {}
end

function var_0_3.writeReport(arg_63_0)
	local var_63_0 = var_0_3.super.writeReport(arg_63_0)

	var_63_0.kill_a_hero_id = arg_63_0.records_.kill_a_hero_id
	var_63_0.kill_b_hero_id = arg_63_0.records_.kill_b_hero_id
	var_63_0.random_buff_count = arg_63_0.records_.random_buff_count
	var_63_0.pos_attr_a = arg_63_0.records_.pos_attr_a
	var_63_0.pos_attr_b = arg_63_0.records_.pos_attr_b
	var_63_0.self_random = arg_63_0.records_.self_random
	var_63_0.side_random = arg_63_0.records_.side_random

	return var_63_0
end

return var_0_3
