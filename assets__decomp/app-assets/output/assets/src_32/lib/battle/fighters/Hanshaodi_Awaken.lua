local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Hanshaodi", var_0_1.ctx.battle.requireFighter("Hanshaodi"))
local var_0_5 = 40012099
local var_0_6 = {
	40012093,
	40012096,
	40012097,
	40012094
}
local var_0_7 = 2

function var_0_4.init(arg_1_0)
	var_0_4.super.init(arg_1_0)

	arg_1_0.awakeTargets = {}
end

function var_0_4.buffAddAction(arg_2_0, arg_2_1)
	var_0_4.super.buffAddAction(arg_2_0, arg_2_1)

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.awakeTargets) do
		if iter_2_1 == arg_2_1.target then
			return
		end
	end

	for iter_2_2 = 1, #var_0_6 do
		if arg_2_1:getTableID() == var_0_6[iter_2_2] then
			local var_2_0 = arg_2_0:createNewBuffs({
				var_0_5
			}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			arg_2_0:addBuffs(var_2_0)
			arg_2_0:updateEnergyBy(var_0_7 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
			table.insert(arg_2_0.awakeTargets, arg_2_1.target)

			break
		end
	end
end

return var_0_4
