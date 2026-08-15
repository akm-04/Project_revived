local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xunyou", var_0_1.ctx.battle.requireFighter("Xunyou"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 750
local var_0_7 = 0.2
local var_0_8 = 60010063
local var_0_9 = 10001032
local var_0_10 = 10001037
local var_0_11 = 10001038
local var_0_12 = 10001451
local var_0_13 = 10001452
local var_0_14 = 10001453
local var_0_15 = 40011492
local var_0_16 = 40011493
local var_0_17 = 40011494
local var_0_18 = 40011495
local var_0_19 = 30

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.ADTotalHarm = 0
	arg_2_0.APTotalHarm = 0
	arg_2_0.totalHarm = 0
	arg_2_0.twiceAwakenCount = var_0_19
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0.twiceAwakenCount > 0 then
		arg_3_0.twiceAwakenCount = arg_3_0.twiceAwakenCount - 1
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("harm_info")) do
			local var_3_0 = iter_3_1.harm
			local var_3_1 = iter_3_1.target
			local var_3_2 = iter_3_1.type

			if var_3_0 > 0 and var_3_1 == arg_3_0 then
				arg_3_0.totalHarm = arg_3_0.totalHarm + var_3_0

				if var_3_2 == var_0_2.AttackType.AD then
					arg_3_0.ADTotalHarm = arg_3_0.ADTotalHarm + var_3_0
				elseif var_3_2 == var_0_2.AttackType.AP then
					arg_3_0.APTotalHarm = arg_3_0.APTotalHarm + var_3_0
				end
			end
		end

		if var_0_1.ctx.battle.count > 0 and var_0_1.ctx.battle.count % var_0_6 == 0 then
			local var_3_3
			local var_3_4
			local var_3_5 = arg_3_0:createAttackUnits({
				arg_3_0
			}, var_0_8)

			for iter_3_2, iter_3_3 in ipairs(var_3_5) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end

			local var_3_6 = arg_3_0:getTargets(var_0_9)
			local var_3_7 = arg_3_0:createAttackUnits(var_3_6, var_0_9)

			for iter_3_4, iter_3_5 in ipairs(var_3_7) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
				table.insert(arg_3_0.records_.special_units, iter_3_5)
			end

			if arg_3_0.ADTotalHarm > arg_3_0.APTotalHarm then
				local var_3_8 = arg_3_0:getTargets(var_0_10)
				local var_3_9 = arg_3_0:createAttackUnits(var_3_8, var_0_10)

				for iter_3_6, iter_3_7 in ipairs(var_3_9) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_7)
					table.insert(arg_3_0.records_.special_units, iter_3_7)
				end
			else
				local var_3_10 = arg_3_0:getTargets(var_0_11)
				local var_3_11 = arg_3_0:createAttackUnits(var_3_10, var_0_11)

				for iter_3_8, iter_3_9 in ipairs(var_3_11) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_9)
					table.insert(arg_3_0.records_.special_units, iter_3_9)
				end
			end

			arg_3_0.ADTotalHarm = 0
			arg_3_0.APTotalHarm = 0
		end
	end
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	var_0_3.super.buffAddAction(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.target

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) < 1 or arg_4_0.twiceAwakenCount > 0 or var_4_0:getTeamType() == arg_4_0:getTeamType() then
		return
	end

	local function var_4_1(arg_5_0)
		return arg_5_0:getBuffForm() == var_0_2.BuffForm.DEBUFF and arg_5_0.fighter == arg_4_0 and not arg_5_0:getTableID() == var_0_16 and not arg_5_0:getTableID() == var_0_17 and not arg_5_0:getTableID() == var_0_18 and not arg_5_0:getTableID() == var_0_15
	end

	if var_4_1(arg_4_1) then
		local var_4_2 = 1

		for iter_4_0, iter_4_1 in ipairs(var_4_0:getBuffs()) do
			if var_4_1(iter_4_1) then
				var_4_2 = var_4_2 + 1
			end
		end

		if var_4_0:getSummonType() == var_0_2.summonMonsterType.None and var_4_2 >= 3 and not var_4_0:isAffected() and not var_4_0:isDeath() then
			arg_4_0.twiceAwakenCount = var_0_19

			local var_4_3 = var_4_0.hero_:getHeroType()

			if var_4_3 == var_0_2.HeroType.STRENGTH then
				local var_4_4 = arg_4_0:createAttackUnits({
					var_4_0
				}, var_0_12)

				for iter_4_2, iter_4_3 in ipairs(var_4_4) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
					table.insert(arg_4_0.records_.special_units, iter_4_3)
				end
			elseif var_4_3 == var_0_2.HeroType.WISE then
				local var_4_5 = arg_4_0:createAttackUnits({
					var_4_0
				}, var_0_13)

				for iter_4_4, iter_4_5 in ipairs(var_4_5) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
					table.insert(arg_4_0.records_.special_units, iter_4_5)
				end
			elseif var_4_3 == var_0_2.HeroType.AGILE then
				local var_4_6 = arg_4_0:createAttackUnits({
					var_4_0
				}, var_0_14)

				for iter_4_6, iter_4_7 in ipairs(var_4_6) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
					table.insert(arg_4_0.records_.special_units, iter_4_7)
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if var_6_2 > 0 and arg_6_1.skillID == var_0_9 then
		var_6_2 = arg_6_0.totalHarm * var_0_7
		arg_6_0.totalHarm = 0
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

return var_0_3
