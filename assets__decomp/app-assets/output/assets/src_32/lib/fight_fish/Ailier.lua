local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Ailier", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 0.2
local var_0_5 = 10
local var_0_6 = 3

function var_0_3.skill(arg_1_0)
	local var_1_0 = arg_1_0:newBuff(var_0_6, nil, nil, var_0_5, arg_1_0, arg_1_0)

	arg_1_0:addBuff(var_1_0)
	arg_1_0:addSkillMessage()
end

function var_0_3.skillAction(arg_2_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		arg_2_0:skill()
	else
		arg_2_0:buffAction(arg_2_0.skill)
	end
end

function var_0_3.addSkillMessage(arg_3_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_3_0 = arg_3_0:getRandomMessage("ailier")
	local var_3_1 = string.format(var_3_0[1], arg_3_0:getName(), arg_3_0:getSkillName())
	local var_3_2 = string.format(var_3_0[2], arg_3_0:getName())
	local var_3_3 = var_3_1 .. "|" .. var_3_2

	arg_3_0:addMessage(var_3_3)
end

function var_0_3.getCurrentSkill(arg_4_0)
	if var_0_2.weightedChoise({
		var_0_4,
		1 - var_0_4
	}) == 1 then
		return var_0_2.FishSkill.SKILL
	else
		return var_0_2.FishSkill.PUGONG
	end
end

return var_0_3
