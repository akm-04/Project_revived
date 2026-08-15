local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shiziyu", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 0.6
local var_0_5 = 0.3

function var_0_3.getTriggerFlag(arg_1_0)
	return var_0_2.weightedChoise({
		var_0_4,
		1 - var_0_4
	}) == 1
end

function var_0_3.afterHurt(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6)
	if arg_2_0:isTriggerSkill() then
		arg_2_0.target:beforeTrigger()

		if arg_2_0:isDeath() then
			return
		end

		arg_2_0:skill(arg_2_4)
	end
end

function var_0_3.skill(arg_3_0, arg_3_1)
	arg_3_1 = math.ceil(var_0_5 * arg_3_1)

	arg_3_0.target:updateHp(arg_3_0.target:getHp() - arg_3_1)
	arg_3_0.target:playHPDeltas(-arg_3_1, false)
	arg_3_0:addSkillMessage(arg_3_1)
end

function var_0_3.addSkillMessage(arg_4_0, arg_4_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_4_0 = arg_4_0:getRandomMessage("shiziyu")
	local var_4_1 = string.format(var_4_0[1], arg_4_0:getName())
	local var_4_2 = string.format(var_4_0[2], arg_4_0.target:getName(), arg_4_1)
	local var_4_3 = var_4_1 .. "|" .. var_4_2

	arg_4_0:addMessage(var_4_3)
end

return var_0_3
