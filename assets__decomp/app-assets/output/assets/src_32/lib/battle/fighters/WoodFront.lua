local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("WoodFront", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_2.tables.hero
local var_0_5 = var_0_2.tables.model

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.isInitPos then
		local var_2_0 = var_0_2.tables.misc.summerQuizBossLocation

		arg_2_0:pos(var_2_0[1], var_2_0[2])

		arg_2_0.isInitPos = true

		arg_2_0:resumeIdle()
	end
end

function var_0_3.canAttack(arg_3_0)
	return false
end

function var_0_3.checkMove(arg_4_0)
	return
end

function var_0_3.resumeIdle(arg_5_0)
	if not arg_5_0:isDeath() and arg_5_0:getFighterModel() then
		arg_5_0:getFighterModel():playAnimation_("idle01", true, nil, nil, nil)
	end
end

function var_0_3.die(arg_6_0)
	var_0_3.super.die(arg_6_0)
	arg_6_0:getFighterModel():playAnimation_("dead01", false, nil, nil, nil)
end

function var_0_3.attacked(arg_7_0)
	if arg_7_0:getFighterModel().currentAnimation_ and arg_7_0:getFighterModel().currentAnimation_ == "hurt01" then
		return
	end

	if arg_7_0.fighterModel:getScale() ~= 1 then
		arg_7_0.fighterModel:scale(1)
	end

	local var_7_0 = var_0_5:hurtDuration(arg_7_0:getModelID())

	arg_7_0.skillRoll_ = var_7_0
	arg_7_0.unableEnergySkill_ = var_0_1.ctx.battle.count + var_7_0

	arg_7_0:getFighterModel():playAnimation_("hurt01", false, nil, nil, function()
		if arg_7_0:getFighterModel().currentAnimation_ == "hurt01" then
			arg_7_0:resumeIdle()
		end
	end)
end

function var_0_3.updateUnitDataByTarget(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	if var_0_4:distanceType(arg_9_1.fighter:getTableID()) ~= var_0_2.DistanceType.QIANPAI then
		arg_9_2 = true
	end

	return var_0_3.super.updateUnitDataByTarget(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
end

return var_0_3
