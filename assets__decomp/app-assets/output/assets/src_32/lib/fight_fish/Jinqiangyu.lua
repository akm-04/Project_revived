local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jinqiangyu", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 0.3
local var_0_5 = {
	0.2,
	0.4,
	0.4
}

function var_0_3.getCurrentSkill(arg_1_0)
	if var_0_2.weightedChoise({
		var_0_4,
		1 - var_0_4
	}) == 1 then
		return var_0_2.FishSkill.SKILL
	else
		return var_0_2.FishSkill.PUGONG
	end
end

function var_0_3.skillAction(arg_2_0, arg_2_1)
	arg_2_0.count = 0

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = var_0_2.weightedChoise({
			var_0_5[1],
			var_0_5[2],
			var_0_5[3]
		}) + 1

		for iter_2_0 = 1, var_2_0 do
			arg_2_0:inputSpecialSkill(var_0_2.FishSkill.SKILL)
		end
	end

	arg_2_0:delayStartBattle(0.1)
end

function var_0_3.skillSpecialAction(arg_3_0, arg_3_1)
	arg_3_0:pugongAction(arg_3_1)
end

function var_0_3.addSkillMessage(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_4_0.count = arg_4_0.count + 1

	local var_4_0 = arg_4_0:getRandomMessage("jinqiangyu")
	local var_4_1 = string.format(var_4_0[1], arg_4_0:getName(), arg_4_0.count)
	local var_4_2

	if arg_4_1 then
		local var_4_3 = arg_4_0:getRandomMessage("shanbi")

		var_4_2 = string.format(var_4_3[1], arg_4_0.target:getName())
	elseif arg_4_2 then
		local var_4_4 = arg_4_0:getRandomMessage("baoji")

		var_4_2 = string.format(var_4_4[1], arg_4_0.target:getName(), arg_4_3)
	else
		local var_4_5 = arg_4_0:getRandomMessage("mingzhong")

		var_4_2 = string.format(var_4_5[1], arg_4_0.target:getName(), arg_4_3)
	end

	local var_4_6 = var_4_1 .. "|" .. var_4_2

	arg_4_0:addMessage(var_4_6)
end

return var_0_3
