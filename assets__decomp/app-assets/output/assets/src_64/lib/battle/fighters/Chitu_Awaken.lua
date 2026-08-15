local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chitu", var_0_1.ctx.battle.requireFighter("Chitu"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = 0.5
local var_0_7 = 10010143
local var_0_8 = 10001239
local var_0_9 = 10001242
local var_0_10 = 3
local var_0_11 = 40011939
local var_0_12 = 0.8

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.AwakeHurtTarget = {}
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	if arg_2_1:getTableID() == var_0_7 then
		local var_2_0 = arg_2_1:getTime()

		arg_2_1:setExtraTime(var_2_0 * var_0_6)
	end
end

function var_0_3.buffRemoveAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_7 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_0:createAttackUnits({
			arg_3_1.target
		}, var_0_9)

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_4_1.attackType == var_0_2.AttackType.AD then
		local var_4_6 = arg_4_1.target

		for iter_4_0, iter_4_1 in ipairs(var_4_6:getBuffs()) do
			if var_0_5:dbuffType(iter_4_1:getTableID()) == var_0_2.DBuffType.ZHI_MANG then
				var_4_4 = var_4_4 + var_4_2 * var_0_12

				break
			end
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	if arg_5_2 > 0 and arg_5_1.attackType == var_0_2.AttackType.AD and arg_5_1.fighter:getTeamType() ~= arg_5_0:getTeamType() then
		if not arg_5_0.AwakeHurtTarget[arg_5_1.fighter] then
			arg_5_0.AwakeHurtTarget[arg_5_1.fighter] = 0
		end

		arg_5_0.AwakeHurtTarget[arg_5_1.fighter] = arg_5_0.AwakeHurtTarget[arg_5_1.fighter] + 1

		if arg_5_0.AwakeHurtTarget[arg_5_1.fighter] >= 3 then
			arg_5_0.AwakeHurtTarget[arg_5_1.fighter] = 0

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_0 = arg_5_0:createAttackUnits({
					arg_5_1.fighter
				}, var_0_8)

				for iter_5_0, iter_5_1 in ipairs(var_5_0) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
					table.insert(arg_5_0.records_.special_units, iter_5_1)
				end
			end
		end
	end

	return var_0_3.super.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
end

function var_0_3.playShanbi(arg_6_0, arg_6_1)
	var_0_3.super.playShanbi(arg_6_0, arg_6_1)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_6_0 = arg_6_0:createNewBuffs({
			var_0_11
		}, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		arg_6_0:addBuffs(var_6_0)
	end
end

return var_0_3
