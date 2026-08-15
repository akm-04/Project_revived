local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xunyu", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 8

function var_0_3.beforeAttack(arg_1_0, arg_1_1)
	if arg_1_1 ~= var_0_2.FishSkill.PUGONG then
		arg_1_0:skill()
	end

	return var_0_3.super.beforeAttack(arg_1_0)
end

function var_0_3.beforeTrigger(arg_2_0, arg_2_1)
	if arg_2_1 ~= var_0_2.FishSkill.PUGONG then
		arg_2_0:skill()
	end

	return var_0_3.super.beforeTrigger(arg_2_0)
end

function var_0_3.skill(arg_3_0)
	local var_3_0 = var_0_4

	arg_3_0.target:updateHp(arg_3_0.target:getHp() - var_3_0)
	arg_3_0.target:playHPDeltas(-var_3_0, false)
	arg_3_0:addSkillMessage()
end

function var_0_3.addSkillMessage(arg_4_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_4_0 = arg_4_0:getRandomMessage("xunyu")
	local var_4_1 = string.format(var_4_0[1], arg_4_0:getName())
	local var_4_2 = string.format(var_4_0[2], arg_4_0.target:getName(), var_0_4)
	local var_4_3 = var_4_1 .. "|" .. var_4_2

	arg_4_0:addMessage(var_4_3)
end

return var_0_3
