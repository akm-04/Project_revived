local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liushan", var_0_1.ctx.battle.requireFighter("Liushan"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = {
	10000063,
	10000064,
	10000065,
	10000066
}
local var_0_8 = 4
local var_0_9 = 10001990
local var_0_10 = 10001989
local var_0_11 = 0.2
local var_0_12 = 0.01

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.addAPBaojiRate = 0
	arg_1_0.addHarm = false
	arg_1_0.energySkillID = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	for iter_2_0, iter_2_1 in ipairs(var_0_7) do
		if iter_2_1 == arg_2_1.skillID then
			arg_2_0.addAPBaojiRate = iter_2_0

			break
		end
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)
end

function var_0_3.getAPBaoJi(arg_3_0)
	local var_3_0 = var_0_3.super.getAPBaoJi(arg_3_0)

	if arg_3_0.addAPBaojiRate ~= 0 then
		var_3_0 = var_3_0 + var_0_8 * arg_3_0.addAPBaojiRate * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
		arg_3_0.addAPBaojiRate = 0
	end

	return var_3_0
end

function var_0_3.getHpLimit(arg_4_0)
	return var_0_3.super.getHpLimit(arg_4_0) + arg_4_0:getAP()
end

function var_0_3.getOrbOfFrontSkill(arg_5_0)
	local var_5_0 = var_0_3.super.getOrbOfFrontSkill(arg_5_0)

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		if var_0_5:father(var_5_0) == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
			if arg_5_0.hero_.isSkinOn_ and arg_5_0.hero_.isSkinOn_ ~= 0 or arg_5_0.isSkinSkillOn_ then
				var_5_0 = var_0_5:skinSkill(var_0_10, arg_5_0.skinSkillIndex_)
			else
				var_5_0 = var_0_10
			end
		elseif var_0_5:father(var_5_0) == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
			var_5_0 = var_0_9

			local var_5_1 = var_0_5:randomOrb(var_5_0)

			if next(var_5_1) then
				local var_5_2 = {}

				for iter_5_0, iter_5_1 in ipairs(var_5_1) do
					table.insert(var_5_2, 1)
				end

				local var_5_3 = var_0_2.weightedChoise(var_5_2)
				local var_5_4 = var_5_1[var_5_3]

				if var_5_3 > 1 then
					arg_5_0.addHarm = true
					arg_5_0.energySkillID = var_5_4
				end

				return var_5_4
			end
		end
	end

	return var_5_0
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_6_4 > 0 and arg_6_0:getPugongID() ~= arg_6_1.skillID and arg_6_0.energySkillID ~= arg_6_1.skillID and arg_6_0.addHarm then
		arg_6_0.addHarm = false
		arg_6_4 = arg_6_4 * (1 + (var_0_11 + var_0_12 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)))
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

return var_0_3
