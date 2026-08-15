local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guohuai", var_0_1.ctx.battle.requireFighter("Guohuai"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.model
local var_0_7 = var_0_2.tables.dbuff

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.AwakeSkillIDs = {
			10001852,
			10002392,
			10001854
		}
	else
		arg_1_0.AwakeSkillIDs = {
			10001852,
			10001853,
			10001854
		}
	end
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if (arg_2_1.skillID == arg_2_0:getPugongID() or arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, arg_2_0.AwakeSkillIDs[math.random(1, #arg_2_0.AwakeSkillIDs)])

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

return var_0_3
