local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pangtong", var_0_1.ctx.battle.requireFighter("Pangtong"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 7
local var_0_6 = 0
local var_0_7 = 0.005
local var_0_8 = 10000340
local var_0_9 = 10000341
local var_0_10 = 10000788
local var_0_11 = 10000789

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.records_.awake_magic_count = {}
end

function var_0_3.getUnitData(arg_2_0, arg_2_1)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.getUnitData(arg_2_0, arg_2_1)

	if var_2_1 and (arg_2_1.skillID == var_0_8 or arg_2_1.skillID == var_0_9 or var_0_4:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_2_1.skillID == var_0_10 or arg_2_1.skillID == var_0_11) and arg_2_0:reMagicCount() then
		arg_2_0.magicCount_ = math.min(arg_2_0.magicCount_ + 1, var_0_5)

		arg_2_0:updateStateNumber(arg_2_0.magicCount_)
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_3.reMagicCount(arg_3_0)
	local var_3_0 = false

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_3_0.awakeMagicCount and arg_3_0.awakeMagicCount[tostring(var_0_1.ctx.battle.count)] then
			var_3_0 = true
		end
	else
		local var_3_1 = var_0_6 + var_0_7 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		var_3_0 = var_0_2.weightedChoise({
			var_3_1,
			1 - var_3_1
		}) == 1

		if var_3_0 then
			arg_3_0.records_.awake_magic_count[tostring(var_0_1.ctx.battle.count)] = 1
		end
	end

	return var_3_0
end

function var_0_3.setupReport(arg_4_0, arg_4_1)
	var_0_3.super.setupReport(arg_4_0, arg_4_1)

	arg_4_0.awakeMagicCount = arg_4_1.awake_magic_count
end

function var_0_3.writeReport(arg_5_0)
	local var_5_0 = var_0_3.super.writeReport(arg_5_0)

	var_5_0.awake_magic_count = arg_5_0.records_.awake_magic_count

	return var_5_0
end

return var_0_3
