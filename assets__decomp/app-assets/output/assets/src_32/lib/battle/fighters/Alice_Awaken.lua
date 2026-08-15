local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Alice", var_0_1.ctx.battle.requireFighter("Alice"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = {
	40010605,
	40010606,
	40010607
}
local var_0_6 = {
	40010614,
	40010615,
	40010616,
	40010617,
	40010618
}
local var_0_7 = 5

function var_0_3.updateHp(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = arg_1_0.purpleBuffCount_

	var_0_3.super.updateHp(arg_1_0, arg_1_1, arg_1_2)

	if var_1_0 < arg_1_0.purpleBuffCount_ and arg_1_0.purpleBuffCount_ <= var_0_7 then
		local var_1_1 = arg_1_0:newBuff(var_0_5, arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_1_0:addBuffs(var_1_1)

		if arg_1_0.purpleBuffCount_ > 1 then
			arg_1_0:removeBuffByID(var_0_6[arg_1_0.purpleBuffCount_ - 1])
		end

		local var_1_2 = arg_1_0:newBuff({
			var_0_6[arg_1_0.purpleBuffCount_]
		}, arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_1_0:addBuffs(var_1_2)
	end
end

return var_0_3
