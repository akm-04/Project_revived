local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xingdaorong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 0.15
local var_0_5 = 40011887
local var_0_6 = 300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueCount = var_0_6
end

function var_0_3.toDoPerFrames(arg_2_0)
	arg_2_0.blueCount = arg_2_0.blueCount - 1
end

function var_0_3.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_4 > arg_3_0:getHpLimit() * var_0_4 then
		local var_3_0 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		local var_3_1 = (var_3_0 + 1) * 3
		local var_3_2 = (arg_3_4 - 0.15 * arg_3_0:getHpLimit()) * (var_3_0 + 1) * 0.008
		local var_3_3 = math.max(var_3_1, var_3_2)

		arg_3_4 = math.max(arg_3_4 - var_3_3, 0)

		if arg_3_0.blueCount < 0 then
			arg_3_0.blueCount = var_0_6

			local var_3_4 = arg_3_0:createNewBuffs({
				var_0_5
			}, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_3_0:addBuffs(var_3_4)
		end
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

return var_0_3
