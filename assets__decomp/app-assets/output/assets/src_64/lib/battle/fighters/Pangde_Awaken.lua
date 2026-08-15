local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pangde", var_0_1.ctx.battle.requireFighter("Pangde"))
local var_0_4 = 0.002
local var_0_5 = 0
local var_0_6 = 10010009
local var_0_7 = 0.4
local var_0_8 = 40012030

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakenSkillTarget = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0.awakenSkillTarget and next(arg_2_0.awakenSkillTarget) then
		for iter_2_0 = #arg_2_0.awakenSkillTarget, 1, -1 do
			if arg_2_0.awakenSkillTarget[iter_2_0]:isDeath() or not arg_2_0.awakenSkillTarget[iter_2_0]:isHasBuffByID(var_0_6) then
				table.remove(arg_2_0.awakenSkillTarget, iter_2_0)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_0_2.weightedChoise({
			var_0_7,
			1 - var_0_7
		}) == 1 then
			arg_3_1.mustBaoji = true
		end

		if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
			local var_3_0 = arg_3_0:createNewBuffs({
				var_0_8
			}, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			arg_3_0:addBuffs(var_3_0)
		end
	end

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and not var_0_0.table.indexof(arg_3_0.awakenSkillTarget, arg_3_1.target) then
		table.insert(arg_3_0.awakenSkillTarget, arg_3_1.target)
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if var_4_2 > 0 and arg_4_1.fighter:getTeamType() == arg_4_0:getTeamType() and var_0_0.table.indexof(arg_4_0.awakenSkillTarget, arg_4_1.target) and var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
		local var_4_6 = var_4_2 * (var_0_4 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) + var_0_5)
		local var_4_7 = {
			arg_4_0
		}
		local var_4_8 = arg_4_0:createAttackUnits(var_4_7, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_4_0, iter_4_1 in ipairs(var_4_8) do
			iter_4_1.change_cure = var_4_6

			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) and arg_5_1.change_cure and arg_5_1.change_cure > 0 then
		var_5_3 = arg_5_1.change_cure * arg_5_0:getCureRate()
		arg_5_1.change_cure = 0
	end

	if var_5_2 > 0 and arg_5_1.skillID == arg_5_0:getPugongID() and arg_5_0:isHasBuffByID(var_0_8) then
		arg_5_0:removeBuffByID(var_0_8)

		var_5_2 = var_5_2 + arg_5_0:getHpLimit() * 0.1
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

return var_0_3
