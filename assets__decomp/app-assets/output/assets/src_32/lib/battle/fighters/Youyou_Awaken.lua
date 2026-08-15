local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Youyou"))
local var_0_4 = 0.15
local var_0_5 = 10000673
local var_0_6 = 0.2
local var_0_7 = 0.005
local var_0_8 = 300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("harm_info")

	arg_1_0.awakeSkillCount = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	for iter_2_0, iter_2_1 in pairs(arg_2_0.awakeSkillCount) do
		if arg_2_0.awakeSkillCount[iter_2_0] > 0 then
			arg_2_0.awakeSkillCount[iter_2_0] = arg_2_0.awakeSkillCount[iter_2_0] - 1
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	local var_3_0 = arg_3_4
	local var_3_1 = arg_3_1.target
	local var_3_2 = arg_3_1.fighter

	if var_3_1:getTeamType() == arg_3_0:getTeamType() and (not arg_3_0.awakeSkillCount[var_3_1] or arg_3_0.awakeSkillCount[var_3_1] <= 0) and var_3_0 > var_3_1:getHpLimit() * var_0_4 then
		local var_3_3 = (var_3_0 - var_3_1:getHpLimit() * var_0_4) * (var_0_6 + var_0_7 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

		arg_3_4 = arg_3_4 - var_3_3
		arg_3_0.awakeSkillCount[var_3_1] = var_0_8

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_4 = arg_3_0:createAttackUnits({
				var_3_2
			}, var_0_5)

			for iter_3_0, iter_3_1 in ipairs(var_3_4) do
				iter_3_1.basicHarm = var_3_3

				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

return var_0_3
