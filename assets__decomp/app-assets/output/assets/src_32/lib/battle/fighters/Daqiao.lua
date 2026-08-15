local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Daqiao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.elementEquip
local var_0_7 = 20001447

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7 = var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_5 > 0 and arg_1_0:hasElementEquipByID(var_0_7) then
		local var_1_0 = var_0_7
		local var_1_1 = var_0_6:battleAttr(var_1_0, arg_1_0:getElementEquipLevelByID(var_1_0)) * arg_1_0.hero_:getElementEquipActiveRate(var_1_0)

		if var_0_2.weightedChoise({
			var_1_1,
			1 - var_1_1
		}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_1_2 = var_0_6:skillIDs(var_1_0)[1]
			local var_1_3 = var_0_5:selectType(var_1_2)
			local var_1_4 = var_0_4[var_1_3](arg_1_0, var_1_2)
			local var_1_5 = arg_1_0:createAttackUnits(var_1_4, var_1_2)

			for iter_1_0, iter_1_1 in ipairs(var_1_5) do
				table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
				table.insert(arg_1_0.records_.special_units, iter_1_1)
			end
		end
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

return var_0_3
