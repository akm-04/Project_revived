local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xuexu", var_0_1.ctx.battle.requireFighter("Xuexu"))

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.AffectBuff = 40012515
	elseif arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_1_0.AffectBuff = 40011726
	else
		arg_1_0.AffectBuff = 40011719
	end
end

function var_0_3.buffRemoveAction(arg_2_0, arg_2_1)
	var_0_3.super.buffRemoveAction(arg_2_0, arg_2_1)

	if arg_2_1:getTableID() == arg_2_0.AffectBuff and arg_2_1.target:getTeamType() == arg_2_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

return var_0_3
