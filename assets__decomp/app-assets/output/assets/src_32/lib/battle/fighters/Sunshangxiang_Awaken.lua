local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunshangxiang", var_0_1.ctx.battle.requireFighter("Sunshangxiang"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 60020003
local var_0_7 = 40011513
local var_0_8 = 10001461
local var_0_9 = 0.15
local var_0_10 = 10010003
local var_0_11 = 50010003
local var_0_12 = 60010003

function var_0_3.beginAttackEnd(arg_1_0, arg_1_1)
	var_0_3.super.beginAttackEnd(arg_1_0, arg_1_1)

	if var_0_4:father(arg_1_1.rootID_) == var_0_11 and arg_1_0:getSkillLevelByID(var_0_6) > 0 then
		arg_1_0:addBuffs({
			var_0_5.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = arg_1_0:getSkillLevelByID(var_0_6),
				skillID = var_0_6,
				fighter = arg_1_0,
				target = arg_1_0
			})
		})
	end
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7 = var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)

	if arg_2_0:getSkillLevelByID(var_0_6) > 0 and arg_2_0:isHasBuffByID(var_0_7) then
		if var_0_4:father(arg_2_1.skillID) == var_0_10 or var_0_4:father(arg_2_1.skillID) == var_0_12 then
			local var_2_0 = arg_2_0:createAttackUnits({
				arg_2_1.target
			}, var_0_8)

			for iter_2_0, iter_2_1 in ipairs(var_2_0) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end

		if arg_2_4 > 0 then
			for iter_2_2, iter_2_3 in ipairs(arg_2_1.target:getBuffs()) do
				if iter_2_3:dBuffType() == var_0_2.DBuffType.CHEN_MO then
					arg_2_4 = arg_2_4 * (1 + var_0_9)

					break
				end
			end
		end
	end

	return arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7
end

return var_0_3
