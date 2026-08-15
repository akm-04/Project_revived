local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhoutai", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 30010033
local var_0_7 = 20010142
local var_0_8 = 20010143
local var_0_9 = 20010057
local var_0_10 = 30010057
local var_0_11 = 10000214
local var_0_12 = 10000218
local var_0_13 = 3
local var_0_14 = 10001301
local var_0_15 = 10001302
local var_0_16 = 10001303
local var_0_17 = 80010057
local var_0_18 = 40011369
local var_0_19 = 20010152
local var_0_20 = 20010152
local var_0_21 = var_0_2.tables.elementEquip
local var_0_22 = 20001472
local var_0_23 = 10002342
local var_0_24 = 40012553

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.records_.is_hit = {}
	arg_1_0.count = false
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if not arg_2_0.count then
		arg_2_0.blueSkillPer = var_0_4:init(var_0_11) + var_0_4:step(var_0_11) * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		arg_2_0.energyPercent = var_0_4:init(var_0_12) + var_0_4:step(var_0_12) * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
		arg_2_0.count = true
	end
end

function var_0_3.deathFeedback(arg_3_0, arg_3_1)
	if arg_3_0:isEnergy() and arg_3_1:getTeamType() ~= arg_3_0:getTeamType() then
		local var_3_0 = arg_3_1:getSummonType() == var_0_2.summonMonsterType.Copy and arg_3_0.energyPercent / var_0_13 or arg_3_0.energyPercent

		arg_3_0.cureHp = arg_3_0.cureHp + arg_3_0:getHpLimit() * var_3_0

		arg_3_0.fighterModel:playHPDeltas({
			{
				arg_3_0:getHpLimit() * var_3_0,
				false
			}
		}, nil)
		arg_3_0:updateHp(arg_3_0:getHp() + arg_3_0:getHpLimit() * var_3_0)
	end
end

function var_0_3.isEnergy(arg_4_0)
	return arg_4_0:isHasBuffByID(var_0_6)
end

function var_0_3.targetIsPlague(arg_5_0, arg_5_1)
	return arg_5_1:isHasBuffByID(var_0_19)
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	local var_6_0 = var_0_5.new({
		tableID = arg_6_1,
		start = var_0_1.ctx.battle.count,
		level = arg_6_3,
		skillID = arg_6_2,
		fighter = arg_6_0,
		target = arg_6_4,
		manualRevise = arg_6_5
	})

	return {
		var_6_0
	}
end

function var_0_3.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_1.skillID == var_0_23 and arg_7_1.addCure and arg_7_1.addCure > 0 then
		arg_7_5 = arg_7_5 + arg_7_1.addCure * arg_7_0:getDCureRate()
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	if not arg_8_0:isDeath() and not arg_8_1.target:isDeath() and not arg_8_1.target:isAffected() and arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_17 and arg_8_0:targetIsPlague(arg_8_1.target) and arg_8_1.fighter:getTeamType() == arg_8_0:getTeamType() and arg_8_1.target:getTeamType() ~= arg_8_0:getTeamType() and arg_8_4 > 0 then
		local var_8_0 = arg_8_0:createAttackUnits({
			arg_8_1.target
		}, var_0_17)

		for iter_8_0, iter_8_1 in ipairs(var_8_0) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end
	end

	if arg_8_1.target == arg_8_0 and arg_8_5 > 0 and arg_8_0:hasElementEquipByID(var_0_22) then
		local var_8_1 = var_0_22

		arg_8_5 = (1 + var_0_21:battleAttr(var_8_1, arg_8_0:getElementEquipLevelByID(var_8_1)) * arg_8_0.hero_:getElementEquipActiveRate(var_8_1)) * arg_8_5

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_8_2 = var_0_21:skillIDs(var_8_1)[1]
			local var_8_3 = arg_8_0:createAttackUnits({
				arg_8_0
			}, var_8_2)

			for iter_8_2, iter_8_3 in ipairs(var_8_3) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
				table.insert(arg_8_0.records_.special_units, iter_8_3)
			end
		end
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	if var_0_4:father(arg_9_1.skillID) == var_0_10 then
		local var_9_0 = math.max(arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), 20)
		local var_9_1 = math.min(1 / (var_0_2.tables.battleConfig.buffHitParam1 * math.max(arg_9_1.target:getLevel() - var_9_0, 0) + var_0_2.tables.battleConfig.buffHitParam2), 1)
		local var_9_2 = true

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_9_2 = arg_9_0.isHit_[tostring(var_0_1.ctx.battle.count)] or true
		else
			var_9_2 = var_0_2.weightedChoise({
				var_9_1,
				1 - var_9_1
			}) == 1
			arg_9_0.records_.is_hit[tostring(var_0_1.ctx.battle.count)] = var_9_2
		end

		if var_9_2 then
			arg_9_0:retakeHujia(arg_9_1.target)
		else
			arg_9_1.target.fighterModel:playFloatText({
				var_0_2.BattleFloatType.BUFF_MISS
			}, arg_9_1.target:getTeamType())
		end
	end

	local var_9_3 = arg_9_1.target

	if arg_9_0.isSkinSkillOn_ and arg_9_0.skinSkillID_ == var_0_17 and arg_9_1.skillID == var_0_15 then
		arg_9_0.greenEffect = var_0_1.ctx.battle.getSpine(var_0_15, "area", 1)

		arg_9_0.greenEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
		arg_9_0.greenEffect:pos(var_9_3:getX(), var_9_3:getY())
		arg_9_0.greenEffect:setScale(0.64)
		arg_9_0.greenEffect:playOnce()

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_9_4 = {}
			local var_9_5 = var_0_4:scope(var_0_14) / 2
			local var_9_6, var_9_7 = var_9_3:getPos()

			table.insert(var_9_4, var_9_3)

			for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
				local var_9_8, var_9_9 = iter_9_1:getPos()

				if not iter_9_1:isDeath() and not iter_9_1:isAffected() and var_9_5 >= math.abs(var_9_8 - var_9_6) and iter_9_1 ~= var_9_3 then
					table.insert(var_9_4, iter_9_1)
				end
			end

			local var_9_10 = arg_9_0:createAttackUnits(var_9_4, var_0_14)

			for iter_9_2, iter_9_3 in ipairs(var_9_10) do
				table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
				table.insert(arg_9_0.records_.special_units, iter_9_3)
			end
		end
	end
end

function var_0_3.retakeHujia(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
	local var_10_1 = arg_10_1:getHuJia() * arg_10_0.blueSkillPer
	local var_10_2 = arg_10_0:getSkillLevelByID(var_10_0)

	arg_10_1:addBuffs(arg_10_0:newBuff(var_0_7, var_10_0, var_10_2, arg_10_1, -var_10_1))
	arg_10_0:addBuffs(arg_10_0:newBuff(var_0_8, var_10_0, var_10_2, arg_10_0, var_10_1))
end

function var_0_3.beginAttackEnd(arg_11_0, arg_11_1)
	var_0_3.super.beginAttackEnd(arg_11_0, arg_11_1)
end

function var_0_3.buffRemoveAction(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_1.target

	if arg_12_1:getTableID() == var_0_20 and var_12_0:isHasBuffByID(var_0_24) then
		var_12_0:removeBuffByID(var_0_24)
	end
end

function var_0_3.buffAddAction(arg_13_0, arg_13_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_13_1:getTableID() == var_0_20 and arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_13_0 = arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)
		local var_13_1 = arg_13_1.target
		local var_13_2 = arg_13_0:createAttackUnits({
			var_13_1
		}, var_13_0)

		for iter_13_0, iter_13_1 in ipairs(var_13_2) do
			table.insert(arg_13_0.moveAttackUnits_, iter_13_1)
			table.insert(arg_13_0.records_.special_units, iter_13_1)
		end
	end
end

function var_0_3.setupReport(arg_14_0, arg_14_1)
	var_0_3.super.setupReport(arg_14_0, arg_14_1)

	arg_14_0.isHit_ = arg_14_1.is_hit or {}
end

function var_0_3.writeReport(arg_15_0)
	local var_15_0 = var_0_3.super.writeReport(arg_15_0)

	var_15_0.is_hit = arg_15_0.records_.is_hit

	return var_15_0
end

return var_0_3
