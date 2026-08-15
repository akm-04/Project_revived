local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liubiao", var_0_1.ctx.battle.requireFighter("Liubiao"))
local var_0_4 = 20010175
local var_0_5 = 40011866
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")

function var_0_3.setGlobalEnergyBuffs(arg_1_0)
	local function var_1_0(arg_2_0, arg_2_1, arg_2_2)
		local var_2_0 = {}

		for iter_2_0, iter_2_1 in ipairs(arg_2_0) do
			local var_2_1 = var_0_6.new({
				tableID = iter_2_1,
				start = var_0_1.ctx.battle.count,
				level = arg_2_2,
				skillID = arg_2_1,
				fighter = arg_1_0
			})

			var_2_1:setYongJiu()
			table.insert(var_2_0, var_2_1)
		end

		return var_2_0
	end

	local var_1_1 = arg_1_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsB or var_0_1.ctx.battle.globalBuffsA
	local var_1_2 = {
		var_0_4
	}
	local var_1_3 = arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)
	local var_1_4 = var_1_0(var_1_2, var_1_3, arg_1_0:getSkillLevelByID(var_1_3))

	for iter_1_0, iter_1_1 in ipairs(var_1_4) do
		table.insert(var_1_1, iter_1_1)
		var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamA, iter_1_1:getAttrType())
		var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamB, iter_1_1:getAttrType())
	end

	local var_1_5 = arg_1_0:createNewBuffs(var_1_2, arg_1_0, var_1_3)

	arg_1_0:addBuffs(var_1_5)

	local var_1_6 = arg_1_0:createNewBuffs({
		var_0_5
	}, arg_1_0, var_1_3)

	arg_1_0:addBuffs(var_1_6)
end

return var_0_3
