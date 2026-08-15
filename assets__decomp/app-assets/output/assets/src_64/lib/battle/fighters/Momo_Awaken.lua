local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Momo"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 0.003

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	local var_2_0 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_5

	for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("attack_info")) do
		local var_2_1 = iter_2_1.fighter_

		if var_2_1 ~= arg_2_0 and var_2_1:getTeamType() == arg_2_0:getTeamType() and (iter_2_1.rootID_ == var_2_1:getEnergySkillID() or var_0_4:father(iter_2_1.rootID_) == var_2_1:getEnergySkillID() and var_2_1.isSkinSkillOn_ or var_2_1.skinSkillIndex_ > 0 and iter_2_1.rootID_ == var_0_4:skinSkill(var_2_1:getEnergySkillID(), var_2_1.skinSkillIndex_)) then
			local var_2_2 = var_2_0 * ((var_0_2.PERCENT_BASE - var_2_1:getDMP()) / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

			var_2_1:updateEnergyBy(var_2_2)
		end
	end
end

return var_0_3
