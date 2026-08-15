local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementLiushan", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.model

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		for iter_1_0, iter_1_1 in ipairs(arg_1_0.sideTeam_) do
			if not iter_1_1:isDeath() and not iter_1_1:isAffected() and iter_1_1:getSummonType() ~= var_0_2.summonMonsterType.None then
				iter_1_1:updateHp(0)
				iter_1_1:die()
			end
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_2_0)
	local var_2_0 = var_0_3.super.getFrontSkill(arg_2_0)

	if var_2_0 == arg_2_0:getEnergySkillID() then
		local var_2_1 = var_0_4:randomOrb(var_2_0)

		if next(var_2_1) then
			local var_2_2 = {}

			for iter_2_0, iter_2_1 in ipairs(var_2_1) do
				table.insert(var_2_2, 1)
			end

			return var_2_1[var_0_2.weightedChoise(var_2_2)]
		end
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_2_0)
end

function var_0_3.updateEnergyBy(arg_3_0, arg_3_1)
	var_0_3.super.updateEnergyBy(arg_3_0, arg_3_1)
end

function var_0_3.energyAction(arg_4_0, arg_4_1)
	if var_0_4:father(arg_4_1) == arg_4_0:getEnergySkillID() then
		arg_4_0:getFighterModel():playEnergyEffect_()
		arg_4_0:updateEnergyTo(arg_4_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

		if arg_4_0:getTeamType() == var_0_2.TeamType.A or arg_4_0.isInArena_ then
			arg_4_0:addBlackLayer()
		end
	end
end

return var_0_3
