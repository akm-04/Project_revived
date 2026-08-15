local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wangyuanji", var_0_1.ctx.battle.requireFighter("Wangyuanji"))
local var_0_4 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 40012741
local var_0_9 = 3

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.GreenHarmBuffID = 40011302
	else
		arg_1_0.GreenHarmBuffID = 40010696
	end
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	if arg_2_1:getTableID() == arg_2_0.GreenHarmBuffID then
		local var_2_0 = arg_2_1.target

		if #var_2_0:getBuffsByID(var_0_8) >= var_0_9 - 1 then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_1 = arg_2_0:createAttackUnits({
					var_2_0
				}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

				for iter_2_0, iter_2_1 in ipairs(var_2_1) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
					table.insert(arg_2_0.records_.special_units, iter_2_1)
				end
			end

			var_2_0:removeBuffByID(var_0_8)
		else
			local var_2_2 = arg_2_0:createNewBuffs({
				var_0_8
			}, var_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			var_2_0:addBuffs(var_2_2)
		end
	end
end

return var_0_3
