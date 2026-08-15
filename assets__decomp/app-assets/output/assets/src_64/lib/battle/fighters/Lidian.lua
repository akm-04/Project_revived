local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lidian", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = {
	10000321,
	10000322,
	10000323
}
local var_0_5 = 10000324
local var_0_6 = 0.15
local var_0_7 = 0.001
local var_0_8 = 0

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energySkilling_ = nil
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getEnergySkillID() then
		arg_2_0.energySkilling_ = true
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == var_0_5 then
		arg_3_0.energySkilling_ = nil
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.skillID == var_0_4[1] or arg_4_1.skillID == var_0_4[2] or arg_4_1.skillID == var_0_4[3] then
		var_4_4 = math.min(arg_4_1.target:getHp() * var_0_6, arg_4_0:getHpLimit() * var_0_6)
		arg_4_0.energySkilling_ = arg_4_1.target
	elseif arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and var_4_2 > 0 then
		local var_4_6 = arg_4_1.target:getHp() * (var_0_8 + var_0_7 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
		local var_4_7 = math.min(var_4_6, arg_4_0:getHpLimit() * var_0_6)

		var_4_2 = var_4_2 + var_4_7
		var_4_4 = var_4_4 + var_4_7
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.skillIsBreak(arg_5_0, arg_5_1)
	var_0_3.super.skillIsBreak(arg_5_0, arg_5_1)

	if arg_5_0.energySkilling_ and type(arg_5_0.energySkilling_) == "table" and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_5_0.energySkilling_:isDeath() then
			return
		end

		local var_5_0 = var_0_5
		local var_5_1 = {
			arg_5_0.energySkilling_
		}
		local var_5_2 = arg_5_0:createAttackUnits(var_5_1, var_5_0)

		for iter_5_0, iter_5_1 in ipairs(var_5_2) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end

		arg_5_0.energySkilling_ = nil
	end
end

return var_0_3
