local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caozhen", var_0_1.ctx.battle.requireFighter("Caozhen"))
local var_0_4 = 0.2
local var_0_5 = 0.002
local var_0_6 = 150

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.buffShanbiCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	arg_2_0.buffShanbiCount = arg_2_0.buffShanbiCount - 1
end

function var_0_3.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_4 > 0 then
		local var_3_0 = var_0_4 + var_0_5 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		if var_0_2.weightedChoise({
			var_3_0,
			1 - var_3_0
		}) == 1 then
			arg_3_2 = true
		end
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.fliterBuffs(arg_4_0, arg_4_1)
	var_0_3.super.fliterBuffs(arg_4_0, arg_4_1)

	if arg_4_0.buffShanbiCount <= 0 then
		for iter_4_0 = #arg_4_1, 1, -1 do
			if arg_4_1[iter_4_0]:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				table.remove(arg_4_1, iter_4_0)

				arg_4_0.buffShanbiCount = var_0_6

				break
			end
		end
	end
end

return var_0_3
