local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Snow", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = {
	one = 81160012
}
local var_0_6 = {
	two = 81160003,
	one = 81160002,
	three = 81160004,
	four = 81160005
}
local var_0_7 = {
	two = 81160007,
	one = 81160006,
	three = 81160008
}
local var_0_8 = {
	two = 81160010,
	one = 81160009,
	three = 81160011
}
local var_0_9 = 10000889
local var_0_10 = 40011004
local var_0_11 = 0
local var_0_12 = 0.005
local var_0_13 = 200
local var_0_14 = 40010997
local var_0_15 = 0.01
local var_0_16 = 0
local var_0_17 = 10000890
local var_0_18 = 10000891
local var_0_19 = 2
local var_0_20 = 40011001
local var_0_21 = 0
local var_0_22 = 5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleOneAttackNum_ = 0
	arg_1_0.isPurpleOneType_ = false
	arg_1_0.greenThreeEffect_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0.greenThreeEffect_ and next(arg_2_0.greenThreeEffect_) then
		local var_2_0 = arg_2_0.greenThreeEffect_.effect
		local var_2_1 = arg_2_0.greenThreeEffect_.startTime

		if var_0_1.ctx.battle.count - var_2_1 >= var_0_13 then
			var_2_0:removeSelf()

			arg_2_0.greenThreeEffect_ = nil
		end
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == var_0_6.three then
		local var_3_0 = var_0_1.ctx.battle.getSpine(var_0_6.three, "area", 1)

		var_3_0:addTo(var_0_1.ctx.battle.unitLayer)
		var_3_0:playRepeat()
		var_3_0:hide()

		arg_3_0.greenThreeEffect_ = {
			effect = var_3_0,
			startTime = var_0_1.ctx.battle.count
		}
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	var_0_3.super.buffRemoveAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_10 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0:createAttackUnits({
			arg_4_1.target
		}, var_0_9)

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	elseif arg_4_1:getTableID() == var_0_20 then
		arg_4_0.isPurpleOneType_ = false
		arg_4_0.purpleOneAttackNum_ = 0
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_20 then
		arg_5_0.isPurpleOneType_ = true
	end
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == var_0_17 or arg_6_1.skillID == var_0_18 then
		arg_6_0:removeBuffByID(var_0_14)
	elseif arg_6_1.skillID == var_0_6.three and arg_6_0.greenThreeEffect_ and next(arg_6_0.greenThreeEffect_) then
		local var_6_0 = arg_6_0.greenThreeEffect_.effect

		var_6_0:show()

		local var_6_1 = {
			x = arg_6_1.target:getX(),
			y = arg_6_1.target:getY()
		}

		var_6_0:pos(var_6_1.x, var_6_1.y + 180)
	end
end

function var_0_3.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if var_7_2 > 0 and not arg_7_1.fighter:isAffected() and arg_7_0:isHasBuffByID(var_0_14) then
		local var_7_6 = arg_7_1.attackType
		local var_7_7 = 0

		if var_7_6 == var_0_2.AttackType.AD then
			var_7_7 = var_0_17
		else
			var_7_7 = var_0_18
		end

		local var_7_8 = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) * var_0_15 + var_0_16
		local var_7_9 = arg_7_0:createAttackUnits({
			arg_7_1.fighter
		}, var_7_7)

		for iter_7_0, iter_7_1 in ipairs(var_7_9) do
			iter_7_1.change_harm = var_7_8

			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end

		arg_7_0:removeBuffByID(var_0_14)

		var_7_2 = 0
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if var_8_2 > 0 and arg_8_1.skillID == var_0_6.four then
		var_8_4 = var_8_4 + var_8_2 * (arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) * var_0_12 + var_0_11)
	elseif var_8_2 > 0 and (arg_8_1.skillID == var_0_17 or arg_8_1.skillID == var_0_18) and arg_8_1.change_harm and arg_8_1.change_harm > 0 then
		var_8_2 = var_8_2 + arg_8_1.change_harm
	end

	if var_8_2 > 0 and arg_8_0.isPurpleOneType_ and arg_8_0.purpleOneAttackNum_ >= var_0_19 and arg_8_1.attackType == var_0_2.AttackType.AD then
		var_8_4 = var_8_4 + (var_0_22 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) + var_0_21)
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.createUnits(arg_9_0, arg_9_1)
	var_0_3.super.createUnits(arg_9_0, arg_9_1)

	if arg_9_0.isPurpleOneType_ and arg_9_1 and var_0_4:type(arg_9_1.rootID_) == var_0_2.AttackType.AD then
		arg_9_0.purpleOneAttackNum_ = arg_9_0.purpleOneAttackNum_ + 1
	end
end

function var_0_3.clearUnitSkillAction(arg_10_0, arg_10_1)
	if arg_10_1 and arg_10_1.rootID_ == var_0_6.three and arg_10_0.greenThreeEffect_ and next(arg_10_0.greenThreeEffect_) then
		local var_10_0 = arg_10_0.greenThreeEffect_.effect

		arg_10_0.greenThreeEffect_ = nil

		var_10_0:removeSelf()
	end
end

return var_0_3
