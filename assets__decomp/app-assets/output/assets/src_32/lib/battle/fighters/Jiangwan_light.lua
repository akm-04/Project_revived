local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiangwan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = 0.1
local var_0_6 = 0.002
local var_0_7 = 4

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleSkillTimes_ = 0
	arg_1_0.purpleSpecail_ = false
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 and arg_2_1.rootID_ ~= arg_2_0:getPugongID() then
		if arg_2_0.purpleSkillTimes_ >= var_0_7 and arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
			arg_2_0.purpleSpecail_ = true
			arg_2_0.purpleSkillTimes_ = arg_2_0.purpleSkillTimes_ - var_0_7
		else
			arg_2_0.purpleSpecail_ = false
			arg_2_0.purpleSkillTimes_ = arg_2_0.purpleSkillTimes_ + 1
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_3_0:purpleRemoveBuff(arg_3_1.target, true)
	end
end

function var_0_3.purpleRemoveBuff(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_1:getBuffs()
	local var_4_1

	if arg_4_2 then
		var_4_1 = var_0_2.BuffForm.GAIN
	else
		var_4_1 = var_0_2.BuffForm.DEBUFF
	end

	for iter_4_0, iter_4_1 in ipairs(var_4_0) do
		local var_4_2 = iter_4_1:getTableID()

		if var_0_4:buffForm(var_4_2) == var_4_1 then
			arg_4_1:removeBuffByID(var_4_2)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 and arg_5_1.skillID ~= arg_5_0:getPugongID() then
		local var_5_0 = var_0_5 + var_0_6 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		arg_5_4 = (1 + var_5_0) * arg_5_4
		arg_5_5 = (1 + var_5_0) * arg_5_5
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.checkEnergySkill(arg_6_0)
	return false
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0
	local var_7_1
	local var_7_2
	local var_7_3

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.targetTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
			if not var_7_1 or var_7_1 < iter_7_1.harms then
				if var_7_0 then
					var_7_3 = var_7_0
					var_7_2 = var_7_0.harms
				end

				var_7_0 = iter_7_1
				var_7_1 = iter_7_1.harms
			elseif not var_7_2 or var_7_2 < iter_7_1.harms then
				var_7_3 = iter_7_1
				var_7_2 = iter_7_1.harms
			end
		end
	end

	if arg_7_0.purpleSpecail_ and var_7_3 then
		return {
			var_7_0,
			var_7_3
		}
	else
		return {
			var_7_0
		}
	end
end

return var_0_3
