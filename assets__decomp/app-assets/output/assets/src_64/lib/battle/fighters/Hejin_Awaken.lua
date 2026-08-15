local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hejin", var_0_1.ctx.battle.requireFighter("Hejin"))
local var_0_4 = 0.3

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeSkillTrigger = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:getHp() < arg_2_0:getHpLimit() * var_0_4 and not arg_2_0.awakeSkillTrigger then
		arg_2_0.awakeSkillTrigger = true

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_0 = arg_2_0:createAttackUnits({
				arg_2_0
			}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_2_0, iter_2_1 in ipairs(var_2_0) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end
	end
end

return var_0_3
