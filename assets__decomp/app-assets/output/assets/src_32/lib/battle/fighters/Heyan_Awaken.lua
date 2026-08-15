local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Heyan", var_0_1.ctx.battle.requireFighter("Heyan"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 60010205
local var_0_7 = 40011390
local var_0_8 = 40011391

function var_0_3.neverDieFeedBack(arg_1_0, arg_1_1)
	local var_1_0 = 0.05
	local var_1_1 = 0.002
	local var_1_2 = var_1_0 + arg_1_0:getSkillLevelByID(var_0_6) * var_1_1
	local var_1_3 = math.min(var_1_2, 1)

	arg_1_1:updateHp(arg_1_1:getHpLimit() * var_1_3)
end

function var_0_3.buffRemoveAction(arg_2_0, arg_2_1)
	if arg_2_1.tableID_ == var_0_7 and arg_2_1.leftCount_ == 0 then
		local var_2_0 = var_0_5.new({
			tableID = var_0_8,
			start = var_0_1.ctx.battle.count,
			level = arg_2_0:getSkillLevelByID(var_0_6),
			skillID = var_0_6,
			fighter = arg_2_0,
			target = arg_2_1.target
		})

		var_2_0.target:addBuffs({
			var_2_0
		})
	end
end

return var_0_3
