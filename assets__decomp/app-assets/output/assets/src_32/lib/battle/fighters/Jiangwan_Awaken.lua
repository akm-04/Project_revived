local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiangwan", var_0_1.ctx.battle.requireFighter("Jiangwan"))
local var_0_4 = 0.1
local var_0_5 = 0.002
local var_0_6 = 4

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleSkillTimes_ = 0
	arg_1_0.purpleSpecail_ = false
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ ~= arg_2_0:getPugongID() then
		if arg_2_0.purpleSkillTimes_ >= var_0_6 and arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
			arg_2_0.purpleSpecail_ = true
			arg_2_0.purpleSkillTimes_ = arg_2_0.purpleSkillTimes_ - var_0_6
		else
			arg_2_0.purpleSpecail_ = false
			arg_2_0.purpleSkillTimes_ = arg_2_0.purpleSkillTimes_ + 1
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_1.skillID ~= arg_3_0:getPugongID() then
		local var_3_0 = var_0_4 + var_0_5 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		arg_3_4 = (1 + var_3_0) * arg_3_4
		arg_3_5 = (1 + var_3_0) * arg_3_5
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	return arg_4_0:choseTarget(false)
end

function var_0_3.selectTargetByTypeD2(arg_5_0, arg_5_1, arg_5_2)
	return arg_5_0:choseTarget(true)
end

function var_0_3.choseTarget(arg_6_0, arg_6_1)
	local var_6_0

	if arg_6_1 then
		var_6_0 = arg_6_0.selfTeam_
	else
		var_6_0 = arg_6_0.targetTeam_
	end

	local var_6_1
	local var_6_2
	local var_6_3
	local var_6_4

	for iter_6_0, iter_6_1 in ipairs(var_6_0) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
			if not var_6_2 or var_6_2 < iter_6_1.harms then
				if var_6_1 then
					var_6_4 = var_6_1
					var_6_3 = var_6_1.harms
				end

				var_6_1 = iter_6_1
				var_6_2 = iter_6_1.harms
			elseif not var_6_3 or var_6_3 < iter_6_1.harms then
				var_6_4 = var_6_1
				var_6_3 = iter_6_1.harms
			end
		end
	end

	if arg_6_0.purpleSpecail_ and var_6_4 then
		return {
			var_6_1,
			var_6_4
		}
	else
		return {
			var_6_1
		}
	end
end

return var_0_3
