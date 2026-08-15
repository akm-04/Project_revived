local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Luxifakulou", var_0_1.ctx.battle.getRequire("BaseFighter"))

function var_0_3.singleLoop(arg_1_0)
	var_0_3.super.singleLoop(arg_1_0)

	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_1_0.leftCount_ = 0
	end
end

function var_0_3.checkMove(arg_2_0)
	return false
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_3_0:updateHp(0)
		arg_3_0:die()

		return
	end
end

function var_0_3.deathFeedback(arg_4_0, arg_4_1)
	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() and iter_4_1:getSummonType() == var_0_2.summonMonsterType.None then
			return
		end
	end

	arg_4_0:updateHp(0)
	arg_4_0:die()
end

return var_0_3
