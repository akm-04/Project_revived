local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huanggai", var_0_1.ctx.battle.requireFighter("Huanggai"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.model
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = 0.4

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeCollectHp_ = 0
end

function var_0_3.updateHp(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = arg_2_0:getHp()

	var_0_3.super.updateHp(arg_2_0, arg_2_1, arg_2_2)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_2_0:isDeath() then
		local var_2_1 = arg_2_0:getHp()

		if var_2_1 < var_2_0 then
			arg_2_0.awakeCollectHp_ = arg_2_0.awakeCollectHp_ + var_2_0 - var_2_1

			if arg_2_0.awakeCollectHp_ >= arg_2_0:getHpLimit() * var_0_8 then
				local var_2_2 = arg_2_0:createAttackUnits(arg_2_0:getTargets(arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)), arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

				for iter_2_0, iter_2_1 in ipairs(var_2_2) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
					table.insert(arg_2_0.records_.special_units, iter_2_1)
				end

				arg_2_0.awakeCollectHp_ = 0
			end
		end
	end
end

return var_0_3
