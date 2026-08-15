local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Kongmingdeng", var_0_1.ctx.battle.requireFighter("Kongmingdeng"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40011313
local var_0_7 = 40011314
local var_0_8 = 40011636
local var_0_9 = 0.2
local var_0_10 = 40012471
local var_0_11 = 40012472
local var_0_12 = 0.3
local var_0_13 = 10002284

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_harm")
	arg_1_0:listenInfo("death_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.awakeTwiceReHp = {}
	arg_2_0.awakeTwiceReMp = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_harm")) do
			local var_3_0 = iter_3_1.buff
			local var_3_1 = var_3_0.target
			local var_3_2 = var_3_0.fighter
			local var_3_3 = iter_3_1.harm
			local var_3_4 = iter_3_1.cure
			local var_3_5 = iter_3_1.mp

			if var_3_2 == arg_3_0 and var_3_3 > 0 and var_3_0:getTableID() == var_0_10 then
				if not arg_3_0.awakeTwiceReHp[var_3_1] then
					arg_3_0.awakeTwiceReHp[var_3_1] = 0
				end

				arg_3_0.awakeTwiceReHp[var_3_1] = arg_3_0.awakeTwiceReHp[var_3_1] + var_3_3 * var_0_12
			elseif var_3_2 == arg_3_0 and var_3_5 ~= 0 and var_3_0:getTableID() == var_0_11 then
				if not arg_3_0.awakeTwiceReMp[var_3_1] then
					arg_3_0.awakeTwiceReMp[var_3_1] = 0
				end

				arg_3_0.awakeTwiceReMp[var_3_1] = arg_3_0.awakeTwiceReMp[var_3_1] + math.abs(var_3_5 * var_0_12)
			end
		end
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("death_info")) do
		if iter_3_3:getTeamType() ~= arg_3_0:getTeamType() then
			iter_3_3:removeBuffByID(var_0_10)
			iter_3_3:removeBuffByID(var_0_11)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
				local var_3_6 = arg_3_0:createAttackUnits({
					arg_3_0
				}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

				for iter_3_4, iter_3_5 in ipairs(var_3_6) do
					iter_3_5.removeBuffTarget = iter_3_3

					table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
					table.insert(arg_3_0.records_.special_units, iter_3_5)
				end
			end
		end
	end
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	var_0_3.super.buffAddAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_6 or arg_4_1:getTableID() == var_0_7 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_0 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end

		if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_1 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_13)

			for iter_4_2, iter_4_3 in ipairs(var_4_1) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end
		end
	end
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	var_0_3.super.buffRemoveAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_6 or arg_5_1:getTableID() == var_0_7 then
		arg_5_1.target:removeBuffByID(var_0_10)
		arg_5_1.target:removeBuffByID(var_0_10)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			local var_5_0 = arg_5_0:createAttackUnits({
				arg_5_0
			}, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_5_0, iter_5_1 in ipairs(var_5_0) do
				iter_5_1.removeBuffTarget = arg_5_1.target

				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) then
		local var_6_6 = arg_6_0.awakeTwiceReHp[arg_6_1.removeBuffTarget] or 0
		local var_6_7 = arg_6_0.awakeTwiceReMp[arg_6_1.removeBuffTarget] or 0

		var_6_3 = var_6_3 + var_6_6
		var_6_5 = var_6_5 + var_6_7
		arg_6_0.awakeTwiceReHp[arg_6_1.removeBuffTarget] = 0
		arg_6_0.awakeTwiceReMp[arg_6_1.removeBuffTarget] = 0
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

function var_0_3.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	local var_7_0 = arg_7_1.target:getBuffByID(var_0_8)

	if var_7_0 and var_7_0.fighter == arg_7_0 and arg_7_1.attackType == var_0_2.AttackType.AP and arg_7_4 > 0 then
		arg_7_6 = arg_7_6 + arg_7_4 * var_0_9
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

return var_0_3
