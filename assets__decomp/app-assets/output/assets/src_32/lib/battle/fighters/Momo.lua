local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 40011086
local var_0_6 = 40011087
local var_0_7 = 10000983
local var_0_8 = 0.25
local var_0_9 = 40011088
local var_0_10 = 40011089
local var_0_11 = 40011090
local var_0_12 = {
	40011091,
	40011092,
	40011093
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyTargets_ = {}
	arg_2_0.blueTargets_ = {}
	arg_2_0.isAddGreenBuff_ = false
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.isAddGreenBuff_ and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		arg_3_0.isAddGreenBuff_ = true

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_1:isDeath() and iter_3_1:getSummonType() ~= var_0_2.summonMonsterType.Pet and (iter_3_1.hero_:getDistanceType() == var_0_2.DistanceType.ZHONGPAI or iter_3_1.hero_:getDistanceType() == var_0_2.DistanceType.HOUPAI) then
				local var_3_0 = arg_3_0:createNewBuffs({
					var_0_9
				}, iter_3_1, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

				iter_3_1:addBuffs(var_3_0)
			end
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("attack_info")) do
			local var_3_1 = iter_3_3.fighter_

			if var_3_1:getTeamType() == arg_3_0:getTeamType() and var_3_1:isHasBuffByID(var_0_10) then
				if arg_3_0.blueTargets_[var_3_1] then
					var_3_1:removeBuffByID(var_0_10)

					arg_3_0.blueTargets_[var_3_1] = false
				elseif var_0_4:type(iter_3_3.rootID_) == var_0_2.AttackType.AP then
					arg_3_0.blueTargets_[var_3_1] = true
				end
			end
		end
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	var_0_3.super.buffRemoveAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_5 and arg_4_1.leftCount_ > 1 and not arg_4_1.target:isAffected() and not arg_4_1.target:isDeath() then
		arg_4_0.energyTargets_[arg_4_1.target] = arg_4_1.leftCount_

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_0 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_7)

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_6 and arg_5_0.energyTargets_[arg_5_1.target] and arg_5_0.energyTargets_[arg_5_1.target] > 0 then
		arg_5_1.leftCount_ = arg_5_0.energyTargets_[arg_5_1.target]
		arg_5_0.energyTargets_[arg_5_1.target] = 0
	elseif arg_5_1:getTableID() == var_0_5 and arg_5_0.isStarEnergy_ then
		local var_5_0 = var_0_4:desc4NumStep(arg_5_0:getEnergySkillID())[2]

		arg_5_1:setExtraTime(var_5_0 * 30)
	elseif arg_5_1:getTableID() == var_0_10 and arg_5_0.isStarBlue_ then
		local var_5_1 = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
		local var_5_2 = var_0_4:desc4NumStep(var_5_1)[2]

		arg_5_1.manualRevise = arg_5_1.manualRevise + var_5_2
	elseif var_0_0.table.keyof(var_0_12, arg_5_1:getTableID()) then
		local var_5_3 = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_5_4 = var_0_4:desc4NumStep(var_5_3)[2]

		arg_5_1:setExtraTime(var_5_4 * 30)
	end
end

function var_0_3.deathFeedback(arg_6_0, arg_6_1)
	var_0_3.super.deathFeedback(arg_6_0, arg_6_1)

	if arg_6_1:getTeamType() == arg_6_0:getTeamType() and arg_6_1.killer_ and arg_6_1.killer_:isHasBuffByID(var_0_5) then
		arg_6_1.killer_:removeBuffByID(var_0_5)
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_4 > 0 and arg_7_1.attackType == var_0_2.AttackType.AD and arg_7_1.target:getTeamType() == arg_7_0:getTeamType() and arg_7_1.target:getSummonType() ~= var_0_2.summonMonsterType.Pet and arg_7_1.target.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI and arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and var_0_2.weightedChoise({
		var_0_8,
		1 - var_0_8
	}) == 1 then
		arg_7_4 = 0
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	if arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_8_0 = var_0_10

		if arg_8_1.target:isHasBuffByID(var_0_10) then
			var_8_0 = var_0_11
		end

		local var_8_1 = arg_8_0:createNewBuffs({
			var_8_0
		}, arg_8_1.target, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_8_1.target:addBuffs(var_8_1)
	end
end

function var_0_3.selectTargetByTypeD1(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		if not iter_9_1:isDeath() and iter_9_1:getSummonType() == var_0_2.summonMonsterType.None and iter_9_1.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI then
			table.insert(var_9_0, iter_9_1)
		end
	end

	return var_9_0
end

function var_0_3.selectTargetByTypeD2(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.selfTeam_) do
		if not iter_10_1:isDeath() and iter_10_1:getSummonType() == var_0_2.summonMonsterType.None and iter_10_1.hero_:getDistanceType() == var_0_2.DistanceType.ZHONGPAI then
			table.insert(var_10_0, iter_10_1)
		end
	end

	return var_10_0
end

function var_0_3.selectTargetByTypeD3(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.selfTeam_) do
		if not iter_11_1:isDeath() and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None and iter_11_1.hero_:getDistanceType() == var_0_2.DistanceType.HOUPAI then
			table.insert(var_11_0, iter_11_1)
		end
	end

	return var_11_0
end

return var_0_3
