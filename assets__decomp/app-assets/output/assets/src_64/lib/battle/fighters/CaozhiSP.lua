local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("CaozhiSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40012528
local var_0_7 = 0.03
local var_0_8 = 0.125
local var_0_9 = 40012529
local var_0_10 = 0.3
local var_0_11 = 0.004
local var_0_12 = 900
local var_0_13 = 40012531
local var_0_14 = 40012532
local var_0_15 = 0.1
local var_0_16 = 0.002
local var_0_17 = 10002335
local var_0_18 = 0.2
local var_0_19 = 0.005
local var_0_20 = 40012535
local var_0_21 = 40012534
local var_0_22 = 0.2

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleBuffTargets_ = {}
	arg_1_0.PurpleNeverDieBuffTime_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	arg_2_0.PurpleNeverDieBuffTime_ = arg_2_0.PurpleNeverDieBuffTime_ - 1

	if arg_2_0.PurpleNeverDieBuffTime_ < 0 and var_0_1.ctx.battle.count % 30 < 1 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if iter_2_1:getSummonType() == var_0_2.summonMonsterType.None and not arg_2_0.purpleBuffTargets_[iter_2_1] and not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				arg_2_0.purpleBuffTargets_[iter_2_1] = true

				local var_2_0 = arg_2_0:createNewBuffs({
					var_0_13
				}, iter_2_1, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				iter_2_1:addBuffs(var_2_0)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_6 = arg_3_1.target

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		var_3_3 = var_3_3 + (arg_3_1.addCure or 0)

		if var_3_6:isHasBuffByID(var_0_14) then
			var_3_6:removeBuffByID(var_0_14)
		end
	elseif arg_3_1.skillID == var_0_17 then
		var_3_2 = var_3_2 + (arg_3_1.addHarm or 0)
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.neverDieFeedBack(arg_4_0, arg_4_1)
	for iter_4_0, iter_4_1 in pairs(arg_4_0.purpleBuffTargets_) do
		if iter_4_0:isHasBuffByID(var_0_13) then
			iter_4_0:removeBuffByID(var_0_13)
		end
	end

	local var_4_0 = arg_4_0:createNewBuffs({
		var_0_14
	}, arg_4_1, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

	arg_4_1:addBuffs(var_4_0)

	arg_4_0.purpleBuffTargets_ = {}
	arg_4_0.PurpleNeverDieBuffTime_ = var_0_12

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_1 = arg_4_0:createAttackUnits({
			arg_4_1
		}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
		local var_4_2 = var_0_15 + var_0_16 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_4_3 = var_0_18 + var_0_19 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		for iter_4_2, iter_4_3 in ipairs(var_4_1) do
			iter_4_3.addCure = arg_4_1:getHpLimit() * var_4_2

			table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
			table.insert(arg_4_0.records_.special_units, iter_4_3)
		end

		local var_4_4 = var_0_4.B14(arg_4_0, var_0_17)
		local var_4_5 = arg_4_0:createAttackUnits(var_4_4, var_0_17)

		for iter_4_4, iter_4_5 in ipairs(var_4_5) do
			iter_4_5.addHarm = arg_4_1:getHpLimit() * var_4_2 * var_4_3

			table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
			table.insert(arg_4_0.records_.special_units, iter_4_5)
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	local var_5_0 = arg_5_1.target

	if var_5_0:getTeamType() == arg_5_0:getTeamType() and var_5_0:isHasBuffByID(var_0_9) and arg_5_4 > 0 then
		local var_5_1 = arg_5_4 * (var_0_10 + var_0_11 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
		local var_5_2 = var_5_1 / var_5_0:getHpLimit()

		arg_5_4 = arg_5_4 - var_5_1

		local var_5_3 = math.ceil(var_0_2.ENERGY_DECIMAL_BASE * var_5_2)

		var_5_0:updateEnergyBy(var_5_3)
	elseif var_5_0:getTeamType() ~= arg_5_0:getTeamType() and var_5_0:isHasBuffByID(var_0_21) and arg_5_4 > 0 then
		arg_5_4 = arg_5_4 * (1 + var_0_22)
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	var_0_3.super.buffAddAction(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.target

	if arg_6_1:getTableID() == var_0_6 then
		if var_6_0:isBoss() then
			arg_6_1.manualHarmRevise = arg_6_0:getHpLimit() * var_0_8
		else
			arg_6_1.manualHarmRevise = var_6_0:getHpLimit() * var_0_7
		end
	elseif arg_6_1:getTableID() == var_0_20 then
		local var_6_1

		for iter_6_0, iter_6_1 in pairs(arg_6_0.sideTeam_) do
			if iter_6_1:isHasBuffByID(var_0_21) then
				var_6_1 = iter_6_1
			end
		end

		if var_6_1 then
			arg_6_1:setForceTarget(var_6_1)
		end
	end
end

return var_0_3
