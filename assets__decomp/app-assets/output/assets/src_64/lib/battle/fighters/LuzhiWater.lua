local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("LuzhiWater", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40010709
local var_0_6 = 40010710
local var_0_7 = 1

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("buff_info")

	arg_1_0.isAddInitBuff = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_2_0:updateHp(0)
		arg_2_0:die()

		return
	end

	if not arg_2_0.isAddInitBuff then
		arg_2_0.isAddInitBuff = true

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				local var_2_0 = arg_2_0:newBuff({
					var_0_5,
					var_0_6
				}, iter_2_1, arg_2_0:getLevel())

				iter_2_1:addBuffs(var_2_0)
			end
		end
	end

	local var_2_1 = arg_2_0:getHp() / arg_2_0:getHpLimit() * var_0_7

	for iter_2_2, iter_2_3 in ipairs(arg_2_0:getInfoByKey("buff_info")) do
		if iter_2_3.target:getTeamType() ~= arg_2_0:getTeamType() and iter_2_3.target:getBuffByID(var_0_6) and not iter_2_3:isYongJiu() and iter_2_3:getBuffForm() == var_0_2.BuffForm.GAIN then
			local var_2_2 = iter_2_3:getTime() * var_2_1

			iter_2_3:setExtraTime(-var_2_2)
		end
	end
end

function var_0_3.die(arg_3_0)
	for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1:getBuffByID(var_0_6) then
			iter_3_1:removeBuffByID(var_0_6)
			iter_3_1:removeBuffByID(var_0_5)
		end
	end

	return var_0_3.super.die(arg_3_0)
end

function var_0_3.checkMove(arg_4_0)
	return false
end

function var_0_3.canAttack(arg_5_0)
	return false
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_4.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByID(arg_6_3),
			skillID = arg_6_3,
			fighter = arg_6_0,
			target = arg_6_2
		})

		var_6_1:setIsHit(true)
		var_6_1:setDirection(arg_6_0:getFighterModel():getFlipX())
		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.deathFeedback(arg_7_0, arg_7_1)
	for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
		if not iter_7_1:isDeath() and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
			return
		end
	end

	arg_7_0:updateHp(0)
	arg_7_0:die()
end

return var_0_3
