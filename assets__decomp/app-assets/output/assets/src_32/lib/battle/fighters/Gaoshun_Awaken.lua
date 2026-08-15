local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Gaoshun", var_0_1.ctx.battle.requireFighter("Gaoshun"))
local var_0_4 = var_0_2.tables.skill

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.count_ = false
	arg_1_0.awakeNum_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if not arg_2_0.count_ then
		arg_2_0.count_ = true

		local var_2_0 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
		local var_2_1 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		arg_2_0.awakeNum_ = (var_0_4:descNumInit(var_2_0)[1] + var_0_4:descNumStep(var_2_0)[1] * var_2_1) * 0.01
	end
end

function var_0_3.getCurrentAckSpeed(arg_3_0)
	local var_3_0 = var_0_3.super.getCurrentAckSpeed(arg_3_0)
	local var_3_1 = math.floor((1 - arg_3_0:getHp() / arg_3_0:getHpLimit()) * 10)

	return var_3_0 * (1 + arg_3_0.awakeNum_ * var_3_1)
end

return var_0_3
