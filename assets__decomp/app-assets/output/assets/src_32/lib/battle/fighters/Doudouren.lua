local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Doudouren", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = {
	40010402,
	40010403,
	40010404
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.foucsTarget_ = nil
end

function var_0_3.addBuffs(arg_2_0, arg_2_1)
	return
end

function var_0_3.die(arg_3_0)
	var_0_3.super.die(arg_3_0)

	if arg_3_0.summoner and not arg_3_0.summoner:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = var_0_4:scope(arg_3_0:getEnergySkillID())
		local var_3_1 = {}

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() and math.abs(iter_3_1:getX() - arg_3_0:getX()) <= 2 * var_3_0 then
				table.insert(var_3_1, iter_3_1)
			end
		end

		local var_3_2 = arg_3_0:createAttackUnits(var_3_1, arg_3_0:getEnergySkillID())

		for iter_3_2, iter_3_3 in ipairs(var_3_2) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	end

	if arg_3_0.foucsTarget_ and not arg_3_0.foucsTarget_:isDeath() then
		for iter_3_4, iter_3_5 in ipairs(var_0_5) do
			arg_3_0.foucsTarget_:removeBuffByID(iter_3_5)
		end
	end
end

function var_0_3.checkMove(arg_4_0)
	if var_0_1.ctx.battle.isEnergySkilling or arg_4_0:isDeath() then
		return
	end

	arg_4_0.isWalking_ = 1
	arg_4_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk

	if var_0_1.ctx.battle.walk2NextBattle_ and arg_4_0:getTeamType() == var_0_2.TeamType.A then
		arg_4_0:flipX(false)
	elseif not arg_4_0:getFlipX() and arg_4_0:getX() >= var_0_2.STAGE_WIDTH then
		arg_4_0:flipX(true)
	elseif arg_4_0:getFlipX() and arg_4_0:getX() <= 0 then
		arg_4_0:flipX(false)
	end

	local var_4_0 = arg_4_0:getFlipX() == true and -1 or 1

	if not arg_4_0:isWalking() then
		arg_4_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
	elseif arg_4_0:isWalking() == 2 then
		arg_4_0:moveByX(arg_4_0:getCurrentSpeed() * var_4_0)
	end

	if not arg_4_0:isWalkAnimation() then
		arg_4_0:modelWalk()
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if not arg_5_0:isDeath() and arg_5_0:getFighterModel().currentAnimation_ ~= "run" then
		arg_5_0:modelWalk()
	end
end

function var_0_3.canAttack(arg_6_0)
	return false
end

function var_0_3.updateEnergyTo(arg_7_0, arg_7_1)
	return
end

function var_0_3.updateEnergyBy(arg_8_0, arg_8_1, arg_8_2)
	return
end

function var_0_3.updateEnergyByHarm(arg_9_0, arg_9_1)
	return
end

function var_0_3.updateEnergyByCount(arg_10_0)
	return
end

function var_0_3.toDoPerFrames(arg_11_0)
	return
end

return var_0_3
