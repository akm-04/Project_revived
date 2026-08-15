local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huangdaiyu", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 10
local var_0_5 = -4
local var_0_6 = -8
local var_0_7 = -4
local var_0_8 = 5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.firstAttack = false
end

function var_0_3.skill(arg_2_0)
	local var_2_0 = var_0_4

	arg_2_0.target:updateHp(arg_2_0.target:getHp() - var_2_0)
	arg_2_0.target:playHPDeltas(-var_2_0, false)

	local var_2_1 = arg_2_0:newBuff(var_0_8, var_0_2.FishAttributeType.AD, var_0_5, nil, arg_2_0, arg_2_0.target)

	arg_2_0.target:addBuff(var_2_1)

	local var_2_2 = arg_2_0:newBuff(var_0_8, var_0_2.FishAttributeType.SPEED, var_0_6, nil, arg_2_0, arg_2_0.target)

	arg_2_0.target:addBuff(var_2_2)

	local var_2_3 = arg_2_0:newBuff(var_0_8, var_0_2.FishAttributeType.HUJIA, var_0_7, nil, arg_2_0, arg_2_0.target)

	arg_2_0.target:addBuff(var_2_3)
	arg_2_0:addSkillMessage()
end

function var_0_3.skillAction(arg_3_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		arg_3_0:skill()
	else
		arg_3_0:buffAction(arg_3_0.skill)
	end
end

function var_0_3.getCurrentSkill(arg_4_0)
	if not arg_4_0.firstAttack then
		arg_4_0.firstAttack = true

		return var_0_2.FishSkill.SKILL
	else
		return var_0_2.FishSkill.PUGONG
	end
end

function var_0_3.addSkillMessage(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_5_0 = arg_5_0:getRandomMessage("huangdaiyu")
	local var_5_1 = string.format(var_5_0[1], arg_5_0:getName())
	local var_5_2 = string.format(var_5_0[2], arg_5_0.target:getName(), var_0_4)
	local var_5_3 = var_5_1 .. "|" .. var_5_2

	arg_5_0:addMessage(var_5_3)
end

return var_0_3
