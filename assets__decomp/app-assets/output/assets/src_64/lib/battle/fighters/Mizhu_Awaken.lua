local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Mizhu", var_0_1.ctx.battle.requireFighter("Mizhu"))
local var_0_5 = 40012100
local var_0_6 = 40012101
local var_0_7 = 10

function var_0_4.addBuffBySpecialHero(arg_1_0, arg_1_1)
	var_0_4.super.addBuffBySpecialHero(arg_1_0, arg_1_1)

	local var_1_0 = false

	for iter_1_0, iter_1_1 in ipairs(arg_1_1) do
		if iter_1_1:Ychange() > 0 then
			local var_1_1 = arg_1_0:createNewBuffs({
				var_0_5
			}, arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			arg_1_0:addBuffs(var_1_1)

			var_1_0 = true
		end
	end

	local var_1_2 = arg_1_0:getBuffsByID(var_0_5)

	if var_1_0 and #var_1_2 >= var_0_7 then
		local var_1_3 = arg_1_0:createNewBuffs({
			var_0_6
		}, arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_1_0:addBuffs(var_1_3)
	end
end

return var_0_4
