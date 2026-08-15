local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Beimihu", var_0_1.ctx.battle.requireFighter("Beimihu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 0.5
local var_0_8 = 40011286

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.daiLiTarget = nil
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.AwakeSkill = 10002206
	else
		arg_2_0.AwakeSkill = 60010197
	end
end

function var_0_3.energyAction(arg_3_0, arg_3_1)
	if var_0_6:father(arg_3_1) == arg_3_0:getEnergySkillID() then
		arg_3_0:getFighterModel():playEnergyEffect_()

		if arg_3_0.daiLiTarget and not arg_3_0.daiLiTarget:isDeath() then
			arg_3_0:updateEnergyTo((arg_3_0:getDMP() + var_0_7 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)) / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)
		else
			arg_3_0:updateEnergyTo(arg_3_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)
		end

		if arg_3_0.daiLiTarget and not arg_3_0.daiLiTarget:isDeath() then
			arg_3_0.daiLiTarget:updateEnergyBy(-var_0_7 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)
			arg_3_0.daiLiTarget:removeBuffByID(var_0_8)
		end

		local var_3_0 = arg_3_0:getTargets(arg_3_0.AwakeSkill)

		if var_3_0 and next(var_3_0) then
			arg_3_0.daiLiTarget = var_3_0[1]
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_1 = arg_3_0:createAttackUnits({
				arg_3_0.daiLiTarget
			}, arg_3_0.AwakeSkill)

			for iter_3_0, iter_3_1 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end

		if arg_3_0:getTeamType() == var_0_2.TeamType.A or arg_3_0.isInArena_ or arg_3_0:isMainRole() then
			arg_3_0:addBlackLayer()
		end
	end
end

return var_0_3
