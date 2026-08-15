local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseLvlingqi", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.cabinetSkillTable
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = {
	40010384
}
local var_0_11 = 3
local var_0_12 = {
	40010380
}
local var_0_13 = 4
local var_0_14 = 10000542
local var_0_15 = 10000543
local var_0_16 = 10
local var_0_17 = 300
local var_0_18 = 10420004
local var_0_19 = 10420006
local var_0_20 = 80010112
local var_0_21 = 0.3
local var_0_22 = {
	40010949,
	40010950,
	40010951
}
local var_0_23 = 0.002
local var_0_24 = 0.2
local var_0_25 = 40010655
local var_0_26 = 50
local var_0_27 = 0.25
local var_0_28 = 1.25
local var_0_29 = 330

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energySpecialAttackTimes_ = 0
	arg_1_0.energyAttackTimes_ = 0
	arg_1_0.energySpecialHarm_ = 0
	arg_1_0.energySpecialCount_ = 0
	arg_1_0.illusionCount_ = 0
	arg_1_0.timeSeed_ = 1
	arg_1_0.records_.purple_buff_time = {}
	arg_1_0.purpleBuffTime_ = {}
	arg_1_0.summonMonsters_ = {}
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel1 = 0
	arg_1_0.extraSkillLevel2 = 0
	arg_1_0.bloodyTarget_ = nil
	arg_1_0.energySkillTime = 0
	arg_1_0.records_.awaken_add_buff = {}
	arg_1_0.nAwakenBuffs = 0
	arg_1_0.nAttackedCount = 0
	arg_1_0.harmRate = var_0_27
	arg_1_0.highHarmCount = 0
end

function var_0_3.getUnitData(arg_2_0, arg_2_1)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.getUnitData(arg_2_0, arg_2_1)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and not var_2_0 and arg_2_1.target ~= arg_2_0 then
		arg_2_1.target:addBuffs(arg_2_0:newBuff(var_0_10, arg_2_1.target, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)))

		if var_2_1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			var_2_2 = var_2_2 * arg_2_0:getRandomRate(var_0_11)
		end
	end

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_2_6 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			var_2_2 = var_2_2 * arg_2_0:getRandomRate(var_0_13)

			local var_2_7 = math.min(1 / (var_0_2.tables.battleConfig.buffHitParam1 * math.max(arg_2_1.target:getLevel() - var_2_6, 0) + var_0_2.tables.battleConfig.buffHitParam2), 1)

			if var_0_2.weightedChoise({
				var_2_7,
				1 - var_2_7
			}) == 1 then
				local var_2_8 = unpack(arg_2_0:newBuff(var_0_12, arg_2_1.target, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))
				local var_2_9 = (arg_2_0:getRandomRate(var_0_13) - 1) * (var_0_9:time(var_2_8:getTableID()) + var_2_6 * var_2_8:getTimeStep())

				var_2_8:setExtraTime(var_2_9)

				arg_2_0.records_.purple_buff_time[tostring(var_0_1.ctx.battle.count)] = var_2_9

				arg_2_1.target:addBuffs({
					var_2_8
				})
			end
		else
			local var_2_10 = arg_2_0.purpleBuffTime_[tostring(var_0_1.ctx.battle.count)]

			if var_2_10 then
				local var_2_11 = unpack(arg_2_0:newBuff(var_0_12, arg_2_1.target, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))

				var_2_11:setExtraTime(var_2_10)
				arg_2_1.target:addBuffs({
					var_2_11
				})
			end
		end
	end

	if var_2_1 and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		extraHarm = math.min(5, arg_2_0.nAwakenBuffs) * arg_2_1.basicHarm * 0.1
		var_2_2 = var_2_2 + extraHarm

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_12 = arg_2_0:createAttackUnits({
				arg_2_1.target
			}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_2_0, iter_2_1 in ipairs(var_2_12) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		arg_3_0.energySpecialHarm_ = arg_3_0.energySpecialHarm_ + arg_3_4
		arg_3_4 = 0
		arg_3_0.energyAttackTimes_ = arg_3_0.energyAttackTimes_ - 1

		if arg_3_0.energyAttackTimes_ == 0 then
			local var_3_0 = {}

			for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
				if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None then
					table.insert(var_3_0, iter_3_1)
				end
			end

			arg_3_0.energySpecialAttackTimes_ = #var_3_0

			local var_3_1 = arg_3_0:createAttackUnits(var_3_0, var_0_14)

			for iter_3_2, iter_3_3 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end

			if arg_3_0.energySpecialCount_ <= 0 then
				arg_3_0.energySpecialCount_ = var_0_16
			end
		end
	elseif arg_3_1.skillID == var_0_14 then
		arg_3_0.energySpecialAttackTimes_ = arg_3_0.energySpecialAttackTimes_ - 1

		if arg_3_0.energySpecialAttackTimes_ == 0 then
			arg_3_4 = arg_3_0.energySpecialHarm_
			arg_3_0.energySpecialHarm_ = 0
		else
			math.randomseed(tonumber(tostring(os.time() + arg_3_0.timeSeed_):reverse():sub(1, 6)))

			local var_3_2 = math.random(tonumber(os.time()))

			arg_3_0.timeSeed_ = var_3_2

			math.randomseed(var_3_2)

			arg_3_4 = math.random(1, math.max(math.ceil(arg_3_0.energySpecialHarm_), 1))
			arg_3_0.energySpecialHarm_ = math.max(math.ceil(arg_3_0.energySpecialHarm_ - arg_3_4), 1)
		end
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.skillID

	if var_0_7:father(var_4_0) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_4_1 = var_0_7:summonMonster(var_4_0)

		if next(var_4_1) == nil then
			return
		end

		arg_4_0:removeSummonMonster()

		arg_4_0.illusionCount_ = var_0_17

		if arg_4_0.extraSkillLevel1 > 0 then
			local var_4_2 = arg_4_0.extraSkillLevel1 * var_0_8:attrValues(var_0_18) * 30

			arg_4_0.illusionCount_ = arg_4_0.illusionCount_ + var_4_2
		end

		for iter_4_0, iter_4_1 in ipairs(var_4_1) do
			local var_4_3 = arg_4_0:getSkillLevelByID(var_4_0)
			local var_4_4 = arg_4_0.hero_:getColor()
			local var_4_5 = arg_4_0:getFlipX() and arg_4_0:getX() - 75 or arg_4_0:getX() + 75
			local var_4_6 = var_0_1.ctx.battle.adjustX(var_4_5, arg_4_0)
			local var_4_7 = {
				x = var_4_6,
				y = arg_4_0:getY() - 150 + 100 * iter_4_0
			}

			arg_4_0:setSummonMonsters(iter_4_1, var_4_3, var_4_4, var_4_7)
		end

		local var_4_8 = arg_4_0:getFlipX() and arg_4_0:getX() + 50 or arg_4_0:getX() - 50
		local var_4_9 = var_0_1.ctx.battle.adjustX(var_4_8, arg_4_0)

		arg_4_0:x(var_4_9)
	elseif var_4_0 == var_0_20 then
		arg_4_0.leftInterval_ = 0
	end

	local var_4_10 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

	if var_4_10 > 0 then
		local var_4_11 = false

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_4_0.awakenAddBuff[tostring(var_0_1.ctx.battle.count)] then
				var_4_11 = true
			end
		else
			local var_4_12 = var_0_23 * var_4_10 + var_0_24
			local var_4_13 = math.min(1, var_4_12)

			var_4_11 = var_0_2.weightedChoise({
				var_4_13,
				1 - var_4_13
			}) == 1

			if var_4_11 then
				arg_4_0.records_.awaken_add_buff[tostring(var_0_1.ctx.battle.count)] = 1
			end
		end

		if var_4_11 then
			arg_4_0:addAwakenBuff()
		end
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0.highHarmCount < var_0_29 and arg_5_0.harmRate == var_0_28 then
		arg_5_0.highHarmCount = arg_5_0.highHarmCount + 1
	else
		arg_5_0.harmRate = var_0_27
		arg_5_0.highHarmCount = 0
	end

	if arg_5_0.illusionCount_ > 0 then
		arg_5_0.illusionCount_ = arg_5_0.illusionCount_ - 1

		if arg_5_0.illusionCount_ == 0 then
			arg_5_0:removeSummonMonster()
		end
	end

	if arg_5_0.energySpecialCount_ > 0 then
		arg_5_0.energySpecialCount_ = arg_5_0.energySpecialCount_ - 1

		if arg_5_0.energySpecialCount_ == 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_5_0 = {}

			for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
				if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1:getSummonType() == var_0_2.summonMonsterType.None then
					table.insert(var_5_0, iter_5_1)
				end
			end

			if #var_5_0 >= 1 then
				local var_5_1 = var_5_0[math.random(#var_5_0)]
				local var_5_2 = arg_5_0:createAttackUnits({
					var_5_1
				}, var_0_15)

				for iter_5_2, iter_5_3 in ipairs(var_5_2) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
					table.insert(arg_5_0.records_.special_units, iter_5_3)
				end
			end
		end
	end

	if not arg_5_0.extraSkillJudge then
		arg_5_0.extraSkillJudge = true

		local var_5_3 = arg_5_0.hero_:skillBook()

		arg_5_0.extraSkillLevel1 = var_5_3[tostring(var_0_18)] or 0
		arg_5_0.extraSkillLevel2 = var_5_3[tostring(var_0_19)] or 0
	end

	if arg_5_0.isSkinSkillOn_ then
		arg_5_0:checkSkinSkill()
	end

	if arg_5_0:getBuffByID(var_0_25) == nil then
		arg_5_0.nAwakenBuffs = 0
	end
end

function var_0_3.setSummonMonsters(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_6_1 = arg_6_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_6_0 = var_0_1.ctx.battle.summonMonsters[var_6_1]
	else
		local var_6_2 = var_0_5.new()

		var_6_2:populateWithTableID(arg_6_1)

		var_6_2.level_ = arg_6_2 or var_6_2.level_
		var_6_2.color_ = arg_6_3 or var_6_2.color_

		for iter_6_0, iter_6_1 in ipairs(var_6_2.skillLev_) do
			local var_6_3 = var_6_2:getSkillId(iter_6_0)
			local var_6_4 = arg_6_0.hero_:getSkillLevelByID(var_6_3)

			if var_6_4 and var_6_4 > 0 then
				var_6_2.skillLev_[iter_6_0] = var_6_4
			end
		end

		local var_6_5 = var_6_2:className()

		var_6_0 = var_0_1.ctx.battle.requireFighter(var_6_5).new({
			is_arena = arg_6_0.isInArena_
		})

		var_6_0:populateWithHero(var_6_2)
		var_6_0:initModels()
		var_6_0.fighterModel:initHeaderView(arg_6_0:getTeamType() - 1)

		var_6_0.fighterIndex = arg_6_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_6_0:setFormationDelay(0, 100)
	end

	if arg_6_0.extraSkillLevel2 > 0 then
		local var_6_6 = arg_6_0.extraSkillLevel2 * var_0_8:attrValues(var_0_19) / var_0_2.PERCENT_BASE * arg_6_0:getAD()

		var_6_0:setExtraAD(var_6_6)
	end

	var_6_0:setTeamType(arg_6_0:getTeamType())

	var_6_0.summoner = arg_6_0

	var_6_0.fighterModel:pos(arg_6_4.x, arg_6_4.y)
	var_6_0:updateHp(var_6_0:getHpLimit())
	var_6_0:getFighterModel():flipX(arg_6_0:getTeamType() == var_0_2.TeamType.B)
	var_6_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_6_0:born()
	var_6_0:setGlobalBuffs()

	if arg_6_0.bloodyTarget_ and not arg_6_0.bloodyTarget_:isDeath() then
		var_6_0.bloodyTarget_ = arg_6_0.bloodyTarget_

		local var_6_7 = arg_6_0:newBuff(var_0_22, var_6_0, arg_6_0:getEnergySkillID())

		var_6_0:addBuffs(var_6_7)
	end

	local var_6_8 = var_6_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_6_8, var_6_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_6_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_6_0.summonMonsters_, var_6_0)
end

function var_0_3.newBuff(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_1) do
		local var_7_1 = var_0_6.new({
			tableID = iter_7_1,
			start = var_0_1.ctx.battle.count,
			level = arg_7_0:getSkillLevelByID(arg_7_3),
			skillID = arg_7_3,
			fighter = arg_7_0,
			target = arg_7_2
		})

		var_7_1:setIsHit(true)
		var_7_1:setDirection(arg_7_0:getFighterModel():getFlipX())
		table.insert(var_7_0, var_7_1)
	end

	return var_7_0
end

function var_0_3.setupReport(arg_8_0, arg_8_1)
	var_0_3.super.setupReport(arg_8_0, arg_8_1)

	arg_8_0.purpleBuffTime_ = arg_8_1.purple_buff_time
	arg_8_0.awakenAddBuff = arg_8_1.awaken_add_buff
end

function var_0_3.writeReport(arg_9_0)
	local var_9_0 = var_0_3.super.writeReport(arg_9_0)

	var_9_0.purple_buff_time = arg_9_0.records_.purple_buff_time
	var_9_0.awaken_add_buff = arg_9_0.records_.awaken_add_buff

	return var_9_0
end

function var_0_3.getRandomRate(arg_10_0, arg_10_1)
	local var_10_0 = math.ceil(arg_10_1) * 10

	if var_10_0 > 10 then
		return math.random(10, var_10_0) * 0.1
	else
		return 1
	end
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.sideTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_11_0, iter_11_1)
		end
	end

	return var_11_0
end

function var_0_3.die(arg_12_0)
	arg_12_0:removeSummonMonster()
	var_0_3.super.die(arg_12_0)
end

function var_0_3.removeSummonMonster(arg_13_0)
	for iter_13_0, iter_13_1 in ipairs(arg_13_0.summonMonsters_) do
		if not iter_13_1:isDeath() then
			iter_13_1:updateHp(0)
			iter_13_1:die()
		end
	end

	arg_13_0.summonMonsters_ = {}
end

function var_0_3.checkSkinSkill(arg_14_0)
	if not arg_14_0.bloodyTarget_ and var_0_1.ctx.battle.count % 10 == 0 and not arg_14_0:isCreatingUnits() then
		local var_14_0
		local var_14_1

		for iter_14_0, iter_14_1 in ipairs(arg_14_0.sideTeam_) do
			if not iter_14_1:isDeath() and (not iter_14_1:isAffected() or not not iter_14_1:isInvisible()) and iter_14_1:getSummonType() == var_0_2.summonMonsterType.None then
				local var_14_2 = iter_14_1:getHp() / iter_14_1:getHpLimit()

				if var_14_2 <= var_0_21 and (not var_14_0 or var_14_2 < var_14_0) then
					var_14_0 = var_14_2
					var_14_1 = iter_14_1
				end
			end
		end

		if var_14_1 then
			arg_14_0.bloodyTarget_ = var_14_1

			arg_14_0:removeNegativeBuff()

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_14_3 = arg_14_0:createAttackUnits({
					arg_14_0
				}, var_0_20)

				for iter_14_2, iter_14_3 in ipairs(var_14_3) do
					table.insert(arg_14_0.moveAttackUnits_, iter_14_3)
					table.insert(arg_14_0.records_.special_units, iter_14_3)
				end

				local var_14_4 = var_0_7:skinSkill(arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Green), 1)
				local var_14_5 = arg_14_0:createAttackUnits({
					arg_14_0
				}, var_14_4)

				for iter_14_4, iter_14_5 in ipairs(var_14_5) do
					table.insert(arg_14_0.moveAttackUnits_, iter_14_5)
					table.insert(arg_14_0.records_.special_units, iter_14_5)
				end
			end
		end
	elseif arg_14_0.bloodyTarget_ and (arg_14_0.bloodyTarget_:isAffected() and not arg_14_0.bloodyTarget_:isInvisible() or arg_14_0.bloodyTarget_:isDeath()) and (not arg_14_0.unitSkills_ or arg_14_0.unitSkills_.rootID_ ~= var_0_20) then
		arg_14_0.bloodyTarget_ = nil

		arg_14_0:removeSkinBuff()
	end
end

function var_0_3.getTargets(arg_15_0, arg_15_1, arg_15_2)
	if arg_15_1 == arg_15_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and arg_15_0.bloodyTarget_ and not arg_15_0.bloodyTarget_:isDeath() and (not arg_15_0.bloodyTarget_:isAffected() or not not arg_15_0.bloodyTarget_:isInvisible()) then
		return {
			arg_15_0.bloodyTarget_
		}
	end

	local var_15_0 = {}
	local var_15_1 = var_0_7:selectType(arg_15_1)

	if not arg_15_0.bloodyTarget_ and arg_15_0:getForceTarget() and not arg_15_0:getForceTarget():isDeath() then
		if var_15_1 == "C11" then
			local var_15_2 = arg_15_0:getForceTarget()

			if (arg_15_2.iniX_ < var_15_2:getX() and var_15_2:getX() <= arg_15_2:getX() or arg_15_2.iniX_ > var_15_2:getX() and var_15_2:getX() >= arg_15_2:getX()) and not arg_15_2.targets[var_15_2.fighterIndex] then
				arg_15_2.targets[var_15_2.fighterIndex] = var_15_2

				return {
					var_15_2
				}
			end

			return {}
		end

		return {
			arg_15_0:getForceTarget()
		}
	end

	if arg_15_0["selectTargetByType" .. var_15_1] then
		var_15_0 = arg_15_0["selectTargetByType" .. var_15_1](arg_15_0, arg_15_1, arg_15_2)
	else
		var_15_0 = var_0_4[var_15_1](arg_15_0, arg_15_1, arg_15_2)
	end

	if arg_15_1 == arg_15_0:getEnergySkillID() then
		arg_15_0.energyAttackTimes_ = #var_15_0
	end

	return var_15_0
end

function var_0_3.getForceTarget(arg_16_0)
	if arg_16_0.bloodyTarget_ and not arg_16_0.bloodyTarget_:isDeath() and (not arg_16_0.bloodyTarget_:isAffected() or not not arg_16_0.bloodyTarget_:isInvisible()) then
		return arg_16_0.bloodyTarget_
	end

	return var_0_3.super.getForceTarget(arg_16_0)
end

function var_0_3.removeNegativeBuff(arg_17_0)
	for iter_17_0 = #arg_17_0.buffs_, 1, -1 do
		local var_17_0 = arg_17_0.buffs_[iter_17_0]

		if var_17_0 and var_17_0.fighter:getTeamType() ~= arg_17_0:getTeamType() and var_0_9:isLimit(var_17_0:getTableID()) == 1 then
			arg_17_0:removeBuffs(var_17_0)
		end
	end
end

function var_0_3.removeSkinBuff(arg_18_0)
	for iter_18_0 = 1, #var_0_22 do
		arg_18_0:removeBuffByID(var_0_22[iter_18_0])

		for iter_18_1, iter_18_2 in ipairs(arg_18_0.summonMonsters_) do
			if not iter_18_2:isDeath() then
				iter_18_2:removeBuffByID(var_0_22[iter_18_0])

				iter_18_2.bloodyTarget_ = nil
			end
		end
	end
end

function var_0_3.addAwakenBuff(arg_19_0)
	if arg_19_0:getBuffByID(var_0_25) then
		local var_19_0 = arg_19_0:getBuffByID(var_0_25)
		local var_19_1 = var_19_0.leftCount_

		var_19_0:setExtraTime(var_19_1)

		local var_19_2 = var_0_9:dHarm(var_0_25) + var_19_0:getLevel() * var_19_0:stepHarm()

		var_19_0.dHarm_ = var_19_0.dHarm_ + var_19_2
		arg_19_0.nAwakenBuffs = arg_19_0.nAwakenBuffs + 1
	else
		local var_19_3 = arg_19_0:newBuff({
			var_0_25
		}, arg_19_0, arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_19_0:addBuffs(var_19_3)

		arg_19_0.nAwakenBuffs = 1
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_20_0, arg_20_1, arg_20_2, arg_20_3, arg_20_4, arg_20_5, arg_20_6, arg_20_7)
	if arg_20_1.target == arg_20_0 and arg_20_4 > 0 then
		arg_20_4 = arg_20_4 * arg_20_0.harmRate
	end

	return arg_20_2, arg_20_3, arg_20_4, arg_20_5, arg_20_6, arg_20_7
end

function var_0_3.updateUnitInfoBySpecialHero(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4, arg_21_5, arg_21_6, arg_21_7)
	if arg_21_1.target == arg_21_0 and arg_21_4 > 0 and arg_21_0.harmRate == var_0_27 then
		arg_21_0.nAttackedCount = arg_21_0.nAttackedCount + 1

		if arg_21_0.nAttackedCount >= var_0_26 then
			arg_21_0.nAttackedCount = 0
			arg_21_0.harmRate = var_0_28
			arg_21_0.highHarmCount = 0
		end
	end
end

return var_0_3
