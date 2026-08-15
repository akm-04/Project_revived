local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiaxu", var_0_1.ctx.battle.requireFighter("Jiaxu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10010008
local var_0_6 = 40011295
local var_0_7 = 40011597
local var_0_8 = 0.2
local var_0_9 = 30010007
local var_0_10 = 10000601
local var_0_11 = 10001180
local var_0_12 = 10001182

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.guaCount = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_1.skillID

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and (var_2_0 == var_0_9 or var_2_0 == var_0_10 or var_2_0 == var_0_11 or var_2_0 == var_0_12) then
		arg_2_0.guaCount = arg_2_0.guaCount + 1

		arg_2_0:addBuffs({
			var_0_4.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice),
				skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
				fighter = arg_2_0,
				target = arg_2_0
			})
		})

		if arg_2_0.guaCount == 4 then
			for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
				if not iter_2_1:isDeath() then
					for iter_2_2 = #iter_2_1:getBuffsByID(var_0_7) + 1, 4 do
						iter_2_1:addBuffs({
							var_0_4.new({
								tableID = var_0_7,
								start = var_0_1.ctx.battle.count,
								level = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice),
								skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
								fighter = arg_2_0,
								target = iter_2_1
							})
						})
					end
				end
			end

			arg_2_0.guaCount = 0
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_1.fighter:getTeamType() == arg_3_0:getTeamType() and arg_3_1.fighter:isHasBuffByID(var_0_7) and (arg_3_1.target:isHasBuffByID(var_0_5) or arg_3_1.target:isHasBuffByID(var_0_6)) and arg_3_4 > 0 then
		arg_3_4 = arg_3_4 + arg_3_4 * var_0_8 * arg_3_0.guaCount
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

return var_0_3
