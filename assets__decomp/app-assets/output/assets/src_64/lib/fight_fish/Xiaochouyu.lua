local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiaochouyu", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 0.9

function var_0_3.getTriggerFlag(arg_1_0)
	return var_0_2.weightedChoise({
		var_0_4,
		1 - var_0_4
	}) == 1
end

function var_0_3.playShanbi(arg_2_0)
	var_0_3.super.playShanbi(arg_2_0)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_2_0:isTriggerSkill() then
		arg_2_0:inputSpecialSkill(var_0_2.FishSkill.SKILL, true)
	end
end

function var_0_3.skillSpecialAction(arg_3_0, arg_3_1)
	arg_3_0.target:beforeTrigger()

	if arg_3_0:isDeath() then
		arg_3_0:delayStartBattle()

		return
	end

	arg_3_0:pugongAction(arg_3_1)
end

function var_0_3.addSkillMessage(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_4_0 = arg_4_0:getRandomMessage("xiaochouyu")
	local var_4_1 = string.format(var_4_0[1], arg_4_0:getName())
	local var_4_2 = string.format(var_4_0[2], arg_4_0.target:getName(), arg_4_3)
	local var_4_3 = var_4_1 .. "|" .. var_4_2

	arg_4_0:addMessage(var_4_3)
end

return var_0_3
