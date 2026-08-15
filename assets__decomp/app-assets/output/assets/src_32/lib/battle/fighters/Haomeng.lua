local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Haomeng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40012129
local var_0_7 = 40012127
local var_0_8 = 10001979
local var_0_9 = 0.1
local var_0_10 = 0.004

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_1_0.forceTarget_ = arg_1_1.target
	end

	if not arg_1_1.isEnergyChild and arg_1_0:isHasBuffByID(var_0_6) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_0 = arg_1_0:createAttackUnits({
			arg_1_1.target
		}, arg_1_1.skillID)

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			iter_1_1.isEnergyChild = true

			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_2_0)
	local var_2_0 = 0
	local var_2_1

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
		if not iter_2_1:isDeath() and not iter_2_1:isAffected() and (not var_2_1 or var_2_0 < iter_2_1:getAttrByType(var_0_2.AttributeType.AGILE)) then
			var_2_0 = iter_2_1:getAttrByType(var_0_2.AttributeType.AGILE)
			var_2_1 = iter_2_1
		end
	end

	return {
		var_2_1
	}
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_1.rootID_ == arg_3_0:getPugongID() then
		local var_3_0 = var_0_9 + var_0_10 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if var_0_2.weightedChoise({
			var_3_0,
			1 - var_3_0
		}) == 1 then
			local var_3_1 = var_0_8
			local var_3_2 = var_0_5:selectType(var_3_1)
			local var_3_3 = var_0_4[var_3_2](arg_3_0, var_3_1)
			local var_3_4 = arg_3_0:createAttackUnits(var_3_3, var_3_1)

			for iter_3_0, iter_3_1 in ipairs(var_3_4) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	end
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_7 then
		arg_4_1:setForceTarget(arg_4_0.forceTarget_)
	end
end

return var_0_3
