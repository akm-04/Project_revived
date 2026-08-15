local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("MazeGuanyu", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.model
local var_0_7 = 40010008

function var_0_3.selectTargetByTypeD2(arg_1_0, arg_1_1)
	local var_1_0 = {}

	arg_1_0.greenSkill_ = arg_1_0.greenSkill_ or {}
	arg_1_0.greenSkill_[tostring(arg_1_1)] = arg_1_0.greenSkill_[tostring(arg_1_1)] or {}

	local var_1_1
	local var_1_2
	local var_1_3
	local var_1_4 = arg_1_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_1_5 = arg_1_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_1_6 = arg_1_0:isAttackFriend() and var_1_4 or var_1_5
	local var_1_7 = var_0_4:scope(arg_1_1)
	local var_1_8 = arg_1_0:getX()

	for iter_1_0, iter_1_1 in ipairs(var_1_6) do
		local var_1_9 = iter_1_1:getX()

		if not iter_1_1:isDeath() and not iter_1_1:isAffected() and var_1_7 >= math.abs(var_1_9 - var_1_8) and not var_0_0.table.keyof(arg_1_0.greenSkill_[tostring(arg_1_1)], iter_1_1) then
			table.insert(var_1_0, iter_1_1)
			table.insert(arg_1_0.greenSkill_[tostring(arg_1_1)], iter_1_1)
		end
	end

	return var_1_0
end

function var_0_3.beginAttack(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0:canAttack() then
		return
	end

	if arg_2_0:getLeftInterval() > 0 then
		return
	end

	arg_2_0.greenSkill_ = nil

	var_0_3.super.beginAttack(arg_2_0)
end

function var_0_3.applyBuffMoves(arg_3_0)
	if var_0_1.ctx.battle.isEnergySkilling and arg_3_0.acttionInBlack_ ~= true and arg_3_0:isHasBuffByID(var_0_7) then
		return
	end

	var_0_3.super.applyBuffMoves(arg_3_0)
end

return var_0_3
