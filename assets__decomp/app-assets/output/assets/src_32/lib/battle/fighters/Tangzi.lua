local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Tangzi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_2.tables.battleConfig
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = 40011943
local var_0_10 = 40010241
local var_0_11 = 300
local var_0_12 = 10001804

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.baoji_ = false
	arg_1_0.purpleSkillCount = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_2_0, iter_2_1 in pairs(arg_2_0.purpleSkillCount) do
			arg_2_0.purpleSkillCount[iter_2_0] = arg_2_0.purpleSkillCount[iter_2_0] + 1

			if arg_2_0.purpleSkillCount[iter_2_0] > var_0_11 then
				arg_2_0.purpleSkillCount[iter_2_0] = var_0_11
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if (arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_3_1.skillID == arg_3_0:getPugongID()) and arg_3_0.baoji_ then
		if not arg_3_3 then
			arg_3_4 = arg_3_4 * (arg_3_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_3_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE) * math.max(0.01, arg_3_1.target:getADBaoJiJianShang())
			arg_3_3 = true
		end

		arg_3_0.baoji_ = false
	elseif var_0_6:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) and arg_3_0.baoji_ then
		if not arg_3_3 then
			arg_3_4 = arg_3_4 * (arg_3_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_3_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE) * math.max(0.01, arg_3_1.target:getADBaoJiJianShang())
			arg_3_3 = true
		end

		if arg_3_1.skillID == var_0_12 then
			arg_3_0.baoji_ = false
		end
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_9 then
		arg_4_0.baoji_ = true
	end
end

function var_0_3.skillIsBreakAction(arg_5_0, arg_5_1)
	if arg_5_1.fighter ~= arg_5_0 then
		arg_5_0.baoji_ = false
	end
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == arg_6_0:getPugongID() and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and (not arg_6_0.purpleSkillCount[arg_6_1.target] or arg_6_0.purpleSkillCount[arg_6_1.target] >= var_0_11) then
		arg_6_0.purpleSkillCount[arg_6_1.target] = 0

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_0 = arg_6_0:createAttackUnits({
				arg_6_1.target
			}, var_0_10)

			for iter_6_0, iter_6_1 in ipairs(var_6_0) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	end
end

return var_0_3
