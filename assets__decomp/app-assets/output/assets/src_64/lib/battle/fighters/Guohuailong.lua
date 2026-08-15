local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guohuailong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = 0.5
local var_0_7 = 0.005
local var_0_8 = 0.1
local var_0_9 = 0.001
local var_0_10 = 10001859
local var_0_11 = 450

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isAddFear = false
	arg_1_0.enhanceTimes = 0
	arg_1_0.dieCount = var_0_11
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.dieCount > 0 then
		arg_2_0.dieCount = arg_2_0.dieCount - 1

		if arg_2_0.dieCount == 0 then
			arg_2_0:updateHp(0)
			arg_2_0:die()
		end
	end

	if not arg_2_0.isAddFear and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = {}

		for iter_2_0, iter_2_1 in pairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				table.insert(var_2_0, iter_2_1)
			end
		end

		local var_2_1 = arg_2_0:createAttackUnits(var_2_0, var_0_10)

		for iter_2_2, iter_2_3 in ipairs(var_2_1) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
			table.insert(arg_2_0.records_.special_units, iter_2_3)
		end

		arg_2_0.isAddFear = true
	end
end

function var_0_3.getAttrByType(arg_3_0, arg_3_1)
	if arg_3_0.summoner then
		local var_3_0 = arg_3_0.summoner.getAttrByType(arg_3_0.summoner, arg_3_1) * (var_0_6 + arg_3_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_7)

		if arg_3_1 <= 10 then
			var_3_0 = var_3_0 * (1 + arg_3_0.enhanceTimes * (var_0_8 + arg_3_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_9))
		end

		return var_3_0
	end

	return var_0_3.super.getAttrByType(arg_3_0, arg_3_1)
end

return var_0_3
