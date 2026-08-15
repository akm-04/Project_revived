local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Ruanji", var_0_1.ctx.battle.requireFighter("Ruanji"))
local var_0_4 = 2

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeNum_ = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_2_0:addAwakeNum()
	end
end

function var_0_3.addAwakeNum(arg_3_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_3_0.awakeNum_ = arg_3_0.awakeNum_ + 1

	if arg_3_0.awakeNum_ >= var_0_4 then
		arg_3_0.awakeNum_ = 0

		local var_3_0 = {
			arg_3_0
		}
		local var_3_1 = arg_3_0:createAttackUnits(var_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end
end

return var_0_3
