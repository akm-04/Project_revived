local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementZhurong", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.selectHeroType = nil
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_0.isJudge and arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_2_0:jugeDestroy()

		arg_2_0.isJudge = false
	end
end

function var_0_3.jugeDestroy(arg_3_0)
	if arg_3_0.selectHeroType == nil then
		return
	end

	for iter_3_0, iter_3_1 in ipairs(var_0_1.ctx.battle.teamA) do
		if not iter_3_1:isDeath() and var_0_5:heroType(iter_3_1:getTableID()) ~= arg_3_0.selectHeroType then
			iter_3_1:updateHp(0)
			iter_3_1:die()
		end
	end

	arg_3_0.selectHeroType = nil
end

function var_0_3.getTargets(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = {}
	local var_4_1 = var_0_4:selectType(arg_4_1)

	if arg_4_0["selectTargetByType" .. var_4_1] then
		var_4_0 = arg_4_0["selectTargetByType" .. var_4_1](arg_4_0, arg_4_1, arg_4_2)
	else
		var_4_0 = var_0_6[var_4_1](arg_4_0, arg_4_1, arg_4_2)
	end

	if arg_4_1 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_4_0.selectHeroType = var_0_5:heroType(var_4_0[1]:getTableID())
		arg_4_0.isJudge = true
	end

	return var_4_0
end

return var_0_3
