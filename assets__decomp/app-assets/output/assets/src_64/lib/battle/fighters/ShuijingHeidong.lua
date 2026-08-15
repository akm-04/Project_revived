local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("BlackHole", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 300
local var_0_6 = 80010084
local var_0_7 = 10001333

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.leftCount_ = var_0_5
end

function var_0_3.singleLoop(arg_2_0)
	local var_2_0 = false

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
		if iter_2_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_2_1:isDeath() then
			var_2_0 = true

			break
		end
	end

	if var_2_0 ~= true then
		arg_2_0:forceDie()
	end

	var_0_3.super.singleLoop(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.leftCount_ > 0 and (arg_2_0.summoner == nil or arg_2_0.summoner.skinSkillID_ ~= var_0_6) then
		arg_2_0.leftCount_ = arg_2_0.leftCount_ - 1

		if arg_2_0.leftCount_ < 1 or var_0_1.ctx.battle.teamBEnd then
			arg_2_0.leftCount_ = 0

			arg_2_0:updateHp(0)
			arg_2_0:die()
		end
	end

	arg_2_0:updateSkill()
end

function var_0_3.updateSkill(arg_3_0)
	if arg_3_0:isDeath() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_3_0:updatePosition()

	if var_0_1.ctx.battle.count % 30 > 0 then
		return
	end

	local var_3_0 = arg_3_0:getPugongID()
	local var_3_1 = var_0_4:scope(var_3_0)
	local var_3_2 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and math.abs(iter_3_1:getX() - arg_3_0:getX()) < var_3_1 / 2 then
			table.insert(var_3_2, iter_3_1)
		end
	end

	local var_3_3 = arg_3_0:createAttackUnits(var_3_2, var_3_0)

	for iter_3_2, iter_3_3 in ipairs(var_3_3) do
		table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
		table.insert(arg_3_0.records_.special_units, iter_3_3)
	end
end

function var_0_3.updatePosition(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	local var_4_0 = arg_4_0:getPugongID()
	local var_4_1 = var_0_4:scope(var_4_0)

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and math.abs(iter_4_1:getX() - arg_4_0:getX()) > 50 then
			local var_4_2 = iter_4_1:getX() < arg_4_0:getX() and 1 or -1

			iter_4_1:moveByX(var_4_2)
		end
	end
end

function var_0_3.canAttack(arg_5_0)
	return false
end

function var_0_3.applyBuffMoves(arg_6_0)
	return
end

function var_0_3.isBreakImmortal(arg_7_0)
	return true
end

function var_0_3.checkMove(arg_8_0)
	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_8_0:forceDie()
	end
end

function var_0_3.deathFeedback(arg_9_0, arg_9_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_9_0.summoner and arg_9_0.summoner:isDeath() and arg_9_0.summoner.isSkinSkillOn_ and arg_9_1:getSummonType() == var_0_2.summonMonsterType.Monster then
		local var_9_0 = arg_9_0:createAttackUnits({
			arg_9_0
		}, var_0_7)

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			iter_9_1.basicHarm = arg_9_1:getHpLimit() / 4

			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end
end

function var_0_3.getAP(arg_10_0)
	if arg_10_0.summoner then
		return arg_10_0.summoner:getAP() + var_0_3.super.getAP(arg_10_0)
	end

	return var_0_3.super.getAP(arg_10_0)
end

return var_0_3
