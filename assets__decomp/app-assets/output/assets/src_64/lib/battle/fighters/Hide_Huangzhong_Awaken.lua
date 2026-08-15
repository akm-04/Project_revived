local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huangzhong", var_0_1.ctx.battle.requireFighter("Hide_Huangzhong"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 1
local var_0_6 = 0.06
local var_0_7 = 2
local var_0_8 = 10010010
local var_0_9 = 3
local var_0_10 = 10000912

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isAwakeTwice_ = false
	arg_1_0.awakeTwiceJudge = false
	arg_1_0.twiceEnergyHarmRate = 0
	arg_1_0.twiceGreenFlag_ = false
	arg_1_0.twiceBlueCount_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if not arg_2_0.awakeTwiceJudge then
		arg_2_0.awakeTwiceJudge = true

		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			arg_2_0.isAwakeTwice_ = true
		end
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if var_0_4:father(arg_3_1.rootID_) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_3_0.twiceBlueCount_ = arg_3_0.twiceBlueCount_ + 1
	end

	arg_3_0.twiceEnergyHarmRate = 0
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_4 > 0 and arg_4_0.isAwakeTwice_ then
		local var_4_0 = var_0_4:father(arg_4_1.skillID)

		if var_4_0 == arg_4_0:getEnergySkillID() then
			arg_4_4 = arg_4_4 + arg_4_4 * arg_4_0.twiceEnergyHarmRate
			arg_4_0.twiceEnergyHarmRate = arg_4_0.twiceEnergyHarmRate + var_0_6

			if arg_4_0.twiceEnergyHarmRate > var_0_5 then
				arg_4_0.twiceEnergyHarmRate = var_0_5
			end
		elseif var_4_0 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and not arg_4_0.twiceGreenFlag_ then
			arg_4_4 = arg_4_4 * var_0_7
		elseif var_4_0 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and not arg_4_1.target:isDeath() and arg_4_0.twiceBlueCount_ % 3 < 1 then
			local var_4_1 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_10)

			for iter_4_0, iter_4_1 in ipairs(var_4_1) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.getTargets(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = var_0_3.super.getTargets(arg_5_0, arg_5_1, arg_5_2)

	if var_0_4:father(arg_5_1) == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_5_0.isAwakeTwice_ and #var_5_0 == 2 then
		if var_5_0[1].hero_:getHeroType() == var_5_0[2].hero_:getHeroType() then
			arg_5_0.twiceGreenFlag_ = true
		else
			arg_5_0.twiceGreenFlag_ = false
		end
	end

	return var_5_0
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	var_0_3.super.buffAddAction(arg_6_0, arg_6_1)

	if arg_6_0.isAwakeTwice_ and arg_6_0.twiceGreenFlag_ and arg_6_1:getTableID() == var_0_8 then
		local var_6_0 = arg_6_1:getTime()

		arg_6_1:setExtraTime(var_6_0)
	end
end

return var_0_3
