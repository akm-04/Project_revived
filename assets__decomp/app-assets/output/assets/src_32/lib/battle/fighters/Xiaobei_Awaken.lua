local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Xiaobei"))
local var_0_4 = 0.03
local var_0_5 = 40010055

function var_0_3.toDoPerFrames(arg_1_0)
	if var_0_1.ctx.battle.count % 30 == 0 then
		local var_1_0 = arg_1_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsA or var_0_1.ctx.battle.globalBuffsB

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			if iter_1_1:getTableID() == var_0_5 and iter_1_1.fighter == arg_1_0 then
				if not iter_1_1.manualRevise then
					iter_1_1.manualRevise = var_0_4 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
				else
					iter_1_1.manualRevise = iter_1_1.manualRevise + var_0_4 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
				end

				var_0_1.ctx.battle.clearAttrCache(arg_1_0.selfTeam_, iter_1_1:getAttrType())

				break
			end
		end
	end
end

return var_0_3
