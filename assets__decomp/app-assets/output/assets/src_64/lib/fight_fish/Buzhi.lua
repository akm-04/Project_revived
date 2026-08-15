local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Buzhi", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 0.25
local var_0_5 = 1

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1 == var_0_2.FishSkill.SKILL then
		local var_1_0 = arg_1_0:newBuff(var_0_5, nil, nil, nil, arg_1_0, arg_1_0.target)

		arg_1_0.target:addBuff(var_1_0)
	end
end

function var_0_3.skillAction(arg_2_0, arg_2_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		arg_2_0:applySingleUnit(arg_2_1)
	else
		arg_2_0:xuliAction(arg_2_0.applySingleUnit, arg_2_1)
	end
end

function var_0_3.beforeAttack(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0.target:getBuffs()

	for iter_3_0 = #var_3_0, 1, -1 do
		local var_3_1 = var_3_0[iter_3_0]

		if var_3_1.fighter == arg_3_0 then
			arg_3_0.target:removeBuff(var_3_1)
			arg_3_0:addStopMessage()

			return false
		end
	end

	return true
end

function var_0_3.addSkillMessage(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_4_0 = arg_4_0:getRandomMessage("buzhi1")
	local var_4_1 = string.format(var_4_0[1], arg_4_0:getName(), arg_4_0.target:getName())
	local var_4_2 = string.format(var_4_0[2], arg_4_0.target:getName())
	local var_4_3

	if arg_4_1 then
		local var_4_4 = arg_4_0:getRandomMessage("shanbi")

		var_4_3 = string.format(var_4_4[1], arg_4_0.target:getName())
	elseif arg_4_2 then
		local var_4_5 = arg_4_0:getRandomMessage("baoji")

		var_4_3 = string.format(var_4_5[1], arg_4_0.target:getName(), arg_4_3)
	else
		local var_4_6 = arg_4_0:getRandomMessage("mingzhong")

		var_4_3 = string.format(var_4_6[1], arg_4_0.target:getName(), arg_4_3)
	end

	local var_4_7 = var_4_1 .. "|" .. var_4_2 .. "|" .. var_4_3

	arg_4_0:addMessage(var_4_7)
end

function var_0_3.getCurrentSkill(arg_5_0)
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
