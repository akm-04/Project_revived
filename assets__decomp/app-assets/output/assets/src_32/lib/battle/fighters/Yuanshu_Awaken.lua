local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuanshu", var_0_1.ctx.battle.requireFighter("Yuanshu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10001311
local var_0_8 = 10001312
local var_0_9 = 10000285
local var_0_10 = 10000287
local var_0_11 = 0.1
local var_0_12 = 8
local var_0_13 = 10002389
local var_0_14 = 10002390

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.babyCount = {}
end

function var_0_3.updateUnitDataBySpecialHero(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	if arg_2_1.skillID == var_0_9 and arg_2_1.target:getTeamType() ~= arg_2_0:getTeamType() and arg_2_4 > 0 then
		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, var_0_7)

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end

		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			local var_2_1 = arg_2_0:createAttackUnits({
				arg_2_1.target
			}, var_0_13)

			for iter_2_2, iter_2_3 in ipairs(var_2_1) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
				table.insert(arg_2_0.records_.special_units, iter_2_3)
			end
		end

		if not arg_2_0.babyCount[arg_2_1.target] then
			arg_2_0.babyCount[arg_2_1.target] = 0
		end

		arg_2_4 = arg_2_4 * (1 + arg_2_0.babyCount[arg_2_1.target] * var_0_11)
		arg_2_0.babyCount[arg_2_1.target] = arg_2_0.babyCount[arg_2_1.target] + 1

		if arg_2_0.babyCount[arg_2_1.target] > var_0_12 then
			arg_2_0.babyCount[arg_2_1.target] = var_0_12
		end
	elseif arg_2_1.skillID == var_0_10 and arg_2_1.target:getTeamType() ~= arg_2_0:getTeamType() and arg_2_4 > 0 then
		local var_2_2 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, var_0_8)

		for iter_2_4, iter_2_5 in ipairs(var_2_2) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
			table.insert(arg_2_0.records_.special_units, iter_2_5)
		end

		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			local var_2_3 = arg_2_0:createAttackUnits({
				arg_2_1.target
			}, var_0_14)

			for iter_2_6, iter_2_7 in ipairs(var_2_3) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_7)
				table.insert(arg_2_0.records_.special_units, iter_2_7)
			end
		end
	end

	return arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7
end

return var_0_3
