local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_2.tables.skill
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_0.class("Sunying", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = 40011616
local var_0_9 = 40011617
local var_0_10 = 10001561
local var_0_11 = 10001560
local var_0_12 = 40011620
local var_0_13 = 90
local var_0_14 = 0
local var_0_15 = 40011621
local var_0_16 = 10001562
local var_0_17 = 10001563

function var_0_6.init(arg_1_0)
	var_0_6.super.init(arg_1_0)

	arg_1_0.purpleUsed = false
	arg_1_0.greenTargetsCount = {}
end

function var_0_6.isBreakImmortal(arg_2_0)
	if arg_2_0:isHasBuffByID(var_0_9) then
		return true
	else
		return var_0_6.super.isBreakImmortal(arg_2_0)
	end
end

function var_0_6.buffRemoveAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_8 then
		if arg_3_1.leftCount_ > 0 then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_0 = arg_3_0:createAttackUnits({
					arg_3_0
				}, var_0_10)

				for iter_3_0, iter_3_1 in ipairs(var_3_0) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
					table.insert(arg_3_0.records_.special_units, iter_3_1)
				end
			end
		elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_1 = arg_3_0:createAttackUnits({
				arg_3_0
			}, var_0_11)

			for iter_3_2, iter_3_3 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end
	elseif arg_3_1:getTableID() == var_0_15 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_2 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_16)

			for iter_3_4, iter_3_5 in ipairs(var_3_2) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
				table.insert(arg_3_0.records_.special_units, iter_3_5)
			end
		end

		arg_3_0.greenTargetsCount[arg_3_1.target] = nil
	end
end

function var_0_6.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_6.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_0:isHasBuffByID(var_0_12) and arg_4_4 > 0 and arg_4_1.target:getTeamType() ~= arg_4_0:getTeamType() then
		arg_4_7 = arg_4_7 - var_0_13 - var_0_14 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_6.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0 = arg_5_1.fighter
	local var_5_1 = arg_5_1.target
	local var_5_2 = var_5_0:getBuffByID(var_0_15)

	if var_5_2 and var_5_2.fighter == arg_5_0 and arg_5_4 > 0 and var_5_1:getTeamType() == arg_5_0:getTeamType() and var_5_1:getSummonType() == var_0_2.summonMonsterType.None then
		arg_5_0.greenTargetsCount[var_5_0] = (arg_5_0.greenTargetsCount[var_5_0] or 0) + 1

		if arg_5_0.greenTargetsCount[var_5_0] > 5 then
			var_5_0:removeBuffs(var_5_2)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_3 = arg_5_0:createAttackUnits({
					var_5_0
				}, var_0_17)

				for iter_5_0, iter_5_1 in ipairs(var_5_3) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
					table.insert(arg_5_0.records_.special_units, iter_5_1)
				end
			end
		end
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_6.selectTargetByTypeD2(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.targetTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_6_0 or math.abs(iter_6_1:getX() - arg_6_0:getX()) < math.abs(var_6_0:getX() - arg_6_0:getX())) then
			var_6_0 = iter_6_1
		end
	end

	if var_6_0 then
		return {
			var_6_0
		}
	else
		return var_0_7.B1(arg_6_0, arg_6_1)
	end
end

function var_0_6.toDoPerFrames(arg_7_0)
	var_0_6.super.toDoPerFrames(arg_7_0)

	if arg_7_0:isDeath() then
		return
	end

	if not arg_7_0.purpleUsed and arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_7_0.purpleUsed = true

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_0 = arg_7_0:createAttackUnits(var_0_7.A2(arg_7_0, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)), arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_7_0, iter_7_1 in ipairs(var_7_0) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		end
	end
end

return var_0_6
