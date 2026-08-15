local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wolong", var_0_1.ctx.battle.requireFighter("Wolong"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = 0.2
local var_0_7 = 0.004

function var_0_3.buffAddAction(arg_1_0, arg_1_1)
	var_0_3.super.buffAddAction(arg_1_0, arg_1_1)

	if (arg_1_1:Xchange() ~= 0 or arg_1_1:Ychange() ~= 0 or arg_1_1.resetXchange_ ~= 0 or arg_1_1.resetYchange_ ~= 0) and arg_1_1.target:getTeamType() ~= arg_1_0:getTeamType() and arg_1_1.target:getSummonType() == var_0_2.summonMonsterType.None then
		local var_1_0 = var_0_6 + var_0_7 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
		local var_1_1 = arg_1_1.resetXchange_ or var_0_5:x(arg_1_1:getTableID())

		if not arg_1_1.resetYchange_ then
			local var_1_2 = var_0_5:y(arg_1_1:getTableID())
		end

		arg_1_1.resetXchange_ = math.ceil(var_1_1 * (1 + var_1_0))
		arg_1_1.target.buffMovePath_ = arg_1_1:getPath()

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_1_3 = arg_1_0:createAttackUnits({
				arg_1_0
			}, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_1_0, iter_1_1 in ipairs(var_1_3) do
				table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
				table.insert(arg_1_0.records_.special_units, iter_1_1)
			end
		end
	end
end

return var_0_3
