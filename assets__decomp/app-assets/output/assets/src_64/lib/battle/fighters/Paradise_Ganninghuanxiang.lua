local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseGanninghuanxiang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 80032004
local var_0_6 = {
	MIRROW = 3,
	AP_IMMUNE = 2,
	AD_IMMUNE = 1
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.monsterType = nil
	arg_1_0.monsterTarget = nil
	arg_1_0.leftCount_ = 10 * var_0_1.ctx.battleConst.frames
end

function var_0_3.canAttack(arg_2_0)
	if arg_2_0.monsterType == var_0_6.MIRROW then
		return false
	else
		return var_0_3.super.canAttack(arg_2_0)
	end
end

function var_0_3.isAffected(arg_3_0)
	if arg_3_0.monsterType == var_0_6.MIRROW then
		return true
	else
		return var_0_3.super.isAffected(arg_3_0)
	end
end

function var_0_3.setMonsterType(arg_4_0, arg_4_1)
	arg_4_0.monsterType = arg_4_1
end

function var_0_3.setMonsterTarget(arg_5_0, arg_5_1)
	arg_5_0.monsterTarget = arg_5_1
end

function var_0_3.checkEnergySkill(arg_6_0)
	return false
end

function var_0_3.updateBaseInfo(arg_7_0)
	var_0_3.super.updateBaseInfo(arg_7_0)

	if arg_7_0.monsterType ~= var_0_6.MIRROW then
		arg_7_0.leftCount_ = arg_7_0.leftCount_ - 1

		if arg_7_0.leftCount_ < 1 and not arg_7_0:isDeath() then
			arg_7_0:updateHp(0)
			arg_7_0:die()
		end
	end
end

function var_0_3.checkMove(arg_8_0)
	if arg_8_0.monsterType == var_0_6.MIRROW then
		if var_0_1.ctx.battle.isEnergySkilling or arg_8_0:isDeath() then
			return
		end

		if arg_8_0:isTargetBeyondReach() then
			arg_8_0.isWalking_ = 1
			arg_8_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk

			local var_8_0 = arg_8_0.monsterTarget:getX() > arg_8_0:getX() and 1 or -1

			arg_8_0:flipX(var_8_0 < 0)

			if not arg_8_0:isWalking() then
				arg_8_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_8_0:isWalking() == 2 then
				arg_8_0:moveByX(arg_8_0:getCurrentSpeed() * var_8_0)
			end

			if not arg_8_0:isWalkAnimation() then
				arg_8_0:modelWalk()
			end

			arg_8_0:writeWalkState()
		else
			return var_0_3.super.checkMove(arg_8_0)
		end
	else
		return var_0_3.super.checkMove(arg_8_0)
	end
end

function var_0_3.isTargetBeyondReach(arg_9_0)
	if arg_9_0.monsterType == var_0_6.MIRROW then
		local var_9_0 = var_0_4:scope(var_0_5)

		if arg_9_0.monsterTarget and not arg_9_0.monsterTarget:isDeath() and var_9_0 < math.abs(arg_9_0.monsterTarget:getX() - arg_9_0:getX()) then
			return true
		end

		return false
	else
		return var_0_3.super.isTargetBeyondReach(arg_9_0)
	end
end

return var_0_3
