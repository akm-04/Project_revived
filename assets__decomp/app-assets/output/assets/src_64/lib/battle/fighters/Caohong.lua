local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caohong", var_0_1.ctx.battle.getRequire("BaseFighter"))

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_1.target

	if var_1_0:isDeath() then
		return
	end

	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID ~= arg_1_0:getEnergySkillID() then
		return
	end

	local var_1_1 = arg_1_0:getX()
	local var_1_2 = arg_1_0:getY()
	local var_1_3 = var_1_0:getX()
	local var_1_4 = var_1_0:getY()

	if var_1_0:avoidHeroMoveBehind() then
		local var_1_5 = var_1_0:getFlipX() and -1 or 1

		arg_1_0.fighterModel:pos(var_1_3 + var_1_5 * 100, var_1_4 + 1)
		arg_1_0:flipX(var_1_3 < var_1_1)
	else
		arg_1_0:pos(var_1_3, var_1_4)
		arg_1_0:flipX(var_1_1 < var_1_3)
		var_1_0:pos(var_1_1, var_1_2)
		var_1_0:flipX(var_1_3 < var_1_1)
	end

	if arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and var_1_0:isDeath() ~= true then
		table.insert(arg_1_0.startSkillQueue_, 1, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		arg_1_0.manualTargets_ = {
			var_1_0
		}
		arg_1_0.leftInterval_ = 10
	end
end

return var_0_3
