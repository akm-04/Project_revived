local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhangfeiSP", var_0_1.ctx.battle.requireFighter("ZhangfeiSP"))
local var_0_4 = {
	40012201,
	40012202
}
local var_0_5 = {
	40012203,
	40012204,
	40012205
}
local var_0_6 = 0.5

function var_0_3.toDoPerFrames(arg_1_0)
	var_0_3.super.toDoPerFrames(arg_1_0)

	if arg_1_0:getHp() / arg_1_0:getHpLimit() >= var_0_6 and not arg_1_0:isHasBuffByID(var_0_4[1]) then
		local var_1_0 = arg_1_0:createNewBuffs(var_0_4, arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_1_0:addBuffs(var_1_0)

		for iter_1_0, iter_1_1 in ipairs(var_0_5) do
			arg_1_0:removeBuffByID(iter_1_1)
		end
	elseif arg_1_0:getHp() / arg_1_0:getHpLimit() < var_0_6 and not arg_1_0:isHasBuffByID(var_0_5[1]) then
		local var_1_1 = arg_1_0:createNewBuffs(var_0_5, arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_1_0:addBuffs(var_1_1)

		for iter_1_2, iter_1_3 in ipairs(var_0_4) do
			arg_1_0:removeBuffByID(iter_1_3)
		end
	end
end

return var_0_3
