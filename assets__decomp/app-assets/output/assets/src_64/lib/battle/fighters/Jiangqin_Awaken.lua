local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiangqin", var_0_1.ctx.battle.requireFighter("Jiangqin"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10000976
local var_0_8 = 0.002
local var_0_9 = 10002156

function var_0_3.getOrbOfFrontSkill(arg_1_0)
	local var_1_0 = var_0_3.super.getOrbOfFrontSkill(arg_1_0)

	if var_1_0 == arg_1_0:getPugongID() or var_1_0 == var_0_9 then
		var_1_0 = arg_1_0.AwakeChildSkill
	end

	return var_1_0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.AwakeChildSkill = 10002154
	else
		arg_2_0.AwakeChildSkill = 10000975
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_1.skillID == arg_3_0.AwakeChildSkill then
		local var_3_0 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_8

		if var_0_2.weightedChoise({
			var_3_0,
			1 - var_3_0
		}) == 1 then
			local var_3_1 = arg_3_0:createAttackUnits({
				arg_3_0
			}, var_0_7)

			for iter_3_0, iter_3_1 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	end
end

return var_0_3
