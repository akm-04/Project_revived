local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Snow", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = {
	one = 50010144
}
local var_0_6 = {
	two = 20020144,
	one = 20010144,
	three = 0,
	four = 20030144
}
local var_0_7 = {
	two = 20020144,
	one = 20010144,
	three = 0
}
local var_0_8 = {
	two = 20020144,
	one = 20010144,
	three = 0
}
local var_0_9 = 0
local var_0_10 = 0
local var_0_11 = 0
local var_0_12 = 0
local var_0_13 = 0
local var_0_14 = 0
local var_0_15 = 0
local var_0_16 = 0
local var_0_17 = 0
local var_0_18 = 0
local var_0_19 = 5
local var_0_20 = 0
local var_0_21 = 0
local var_0_22 = 0

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleOneAttackNum_ = 0
	arg_1_0.isPurpleOneType_ = false
end

function var_0_3.buffRemoveAction(arg_2_0, arg_2_1)
	var_0_3.super.buffRemoveAction(arg_2_0, arg_2_1)

	if arg_2_1:getTableID() == var_0_10 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, var_0_9)

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	elseif arg_2_1:getTableID() == var_0_20 then
		arg_2_0.isPurpleOneType_ = false
		arg_2_0.purpleOneAttackNum_ = 0
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	var_0_3.super.buffAddAction(arg_3_0, arg_3_1)

	if arg_3_1:getTableID() == var_0_20 then
		arg_3_0.isPurpleOneType_ = true
	end
end

function var_0_3.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if var_4_2 > 0 and not arg_4_1.fighter:isAffected() and arg_4_0:isHasBuffByID(var_0_14) then
		local var_4_6 = arg_4_1.attackType
		local var_4_7 = 0

		if var_4_6 == var_0_2.AttackType.AD then
			var_4_7 = var_0_17
		else
			var_4_7 = var_0_18
		end

		local var_4_8 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) * var_0_15 + var_0_16
		local var_4_9 = arg_4_0:createAttackUnits({
			arg_4_1.fighter
		}, var_4_7)

		for iter_4_0, iter_4_1 in ipairs(var_4_9) do
			iter_4_1.change_harm = var_4_8

			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end

		var_4_2 = 0
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if var_5_2 > 0 and arg_5_1.skillID == var_0_6.four then
		var_5_4 = var_5_4 + var_5_2 * (arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) * var_0_13 + var_0_12)
	elseif var_5_2 > 0 and (arg_5_1.skillID == var_0_17 or arg_5_1.skillID == var_0_18) and arg_5_1.change_harm and arg_5_1.change_harm > 0 then
		var_5_2 = var_5_2 + arg_5_1.change_harm
	end

	if var_5_2 > 0 and arg_5_0.isPurpleOneType_ and arg_5_0.purpleOneAttackNum_ >= var_0_19 and arg_5_1.attackType == var_0_2.AttackType.AD then
		var_5_4 = var_5_4 + (var_0_22 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) + var_0_21)
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.createUnits(arg_6_0, arg_6_1)
	var_0_3.super.createUnits(arg_6_0, arg_6_1)

	if arg_6_0.isPurpleOneType_ and arg_6_1 and var_0_4:type(arg_6_1.rootID_) == var_0_2.AttackType.AD then
		arg_6_0.purpleOneAttackNum_ = arg_6_0.purpleOneAttackNum_ + 1
	end
end

return var_0_3
