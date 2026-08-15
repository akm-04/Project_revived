local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Liao"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40011170
local var_0_6 = 40011171
local var_0_7 = 40010394
local var_0_8 = 30
local var_0_9 = 70050013

function var_0_3.toDoPerFrames(arg_1_0)
	var_0_3.super.toDoPerFrames(arg_1_0)

	if var_0_1.ctx.battle.count > 0 and var_0_1.ctx.battle.count % var_0_8 == 0 then
		local var_1_0 = false

		for iter_1_0, iter_1_1 in ipairs(arg_1_0.sideTeam_) do
			if not iter_1_1:isDeath() and not iter_1_1:isAffected() and iter_1_1:isHasBuffByID(var_0_7) then
				local var_1_1 = arg_1_0:createNewBuffs({
					var_0_5
				}, iter_1_1, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake), arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

				iter_1_1:addBuffs(var_1_1)

				var_1_0 = true
			end
		end

		if var_1_0 then
			local var_1_2 = arg_1_0:createNewBuffs({
				var_0_6
			}, arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake), arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

			arg_1_0:addBuffs(var_1_2)
		end
	end
end

return var_0_3
