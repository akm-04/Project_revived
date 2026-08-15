local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guanxing", var_0_1.ctx.battle.requireFighter("Guanxing"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 0.4
local var_0_8 = 40012310
local var_0_9 = 40012309
local var_0_10 = 0.2
local var_0_11 = 0.002

function var_0_3.toDoPerFrames(arg_1_0)
	if arg_1_0:isDeath() then
		return
	end

	if arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_0_1.ctx.battle.count == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_0 = arg_1_0:createAttackUnits(var_0_4.A2(arg_1_0, nil), arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if var_0_6:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				local var_2_0 = arg_2_0:createNewBuffs({
					var_0_8
				}, iter_2_1, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

				iter_2_1:addBuffs(var_2_0)
			end
		end
	end
end

function var_0_3.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if var_0_2.weightedChoise({
		var_0_7,
		1 - var_0_7
	}) == 1 and arg_3_4 > 0 then
		arg_3_4 = 0
		arg_3_3 = arg_3_3 and false

		if arg_3_7 > 0 then
			arg_3_7 = 0
		end

		if arg_3_6 > 0 then
			arg_3_6 = 0
		end

		arg_3_2 = true

		local var_3_0 = arg_3_0:createAttackUnits(var_0_4.A2(arg_3_0, nil), arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	local var_4_0 = arg_4_1.fighter

	if arg_4_1.attackType ~= var_0_2.AttackType.Cure and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_4_0:isHasBuffByID(var_0_8) and arg_4_4 > 0 then
		arg_4_4 = arg_4_4 + arg_4_4 * (var_0_10 + var_0_11 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		var_4_0:removeBuffByID(var_0_8)
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.die(arg_5_0)
	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() and iter_5_1:isHasBuffByID(var_0_9) then
			iter_5_1:removeBuffByID(var_0_9)
		end
	end

	return var_0_3.super.die(arg_5_0)
end

return var_0_3
