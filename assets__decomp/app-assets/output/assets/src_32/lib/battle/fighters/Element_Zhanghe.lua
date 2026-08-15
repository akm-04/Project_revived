local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementZhanghe", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = {
	80022018,
	80022020,
	80022021,
	80022019
}
local var_0_9 = {
	40010501,
	40010502,
	40010503,
	40010504
}
local var_0_10 = 5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergySign_ = false
	arg_1_0.energyExtraCount_ = 0
	arg_1_0.extraEnergyAttackTime_ = 0
	arg_1_0.energyChildSkill_ = 0
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if var_0_5:father(arg_2_1.rootID_) == arg_2_0:getEnergySkillID() then
		arg_2_0.isEnergySign_ = true
	end
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getFrontSkill(arg_3_0)

	if var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_3_1 = var_0_5:randomOrb(var_3_0)

		if next(var_3_1) then
			local var_3_2 = {}

			for iter_3_0, iter_3_1 in ipairs(var_3_1) do
				table.insert(var_3_2, 1)
			end

			local var_3_3 = var_3_1[var_0_2.weightedChoise(var_3_2)]

			if var_3_0 == arg_3_0:getEnergySkillID() then
				arg_3_0.extraEnergyAttackTime_ = arg_3_0:getExtraEnergyTime(var_3_3)
				arg_3_0.energyChildSkill_ = var_3_3
			end

			return var_3_3
		end
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_3_0)
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_0.isEnergySign_ and var_0_5:father(arg_4_1.skillID) == arg_4_0:getEnergySkillID() then
		if arg_4_0.extraEnergyAttackTime_ > 0 then
			arg_4_0.energyExtraCount_ = var_0_10
		end

		arg_4_0.isEnergySign_ = false
	end
end

function var_0_3.energyAction(arg_5_0, arg_5_1)
	if var_0_5:father(arg_5_1) == arg_5_0:getEnergySkillID() then
		arg_5_0:getFighterModel():playEnergyEffect_()
		arg_5_0:updateEnergyTo(arg_5_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

		if arg_5_0:getTeamType() == var_0_2.TeamType.A or arg_5_0.isInArena_ then
			arg_5_0:addBlackLayer()
		end
	end
end

function var_0_3.getExtraEnergyTime(arg_6_0, arg_6_1)
	local var_6_0

	for iter_6_0, iter_6_1 in ipairs(var_0_8) do
		if iter_6_1 == arg_6_1 then
			var_6_0 = iter_6_0
		end
	end

	if var_6_0 then
		local var_6_1 = var_0_9[var_6_0]
		local var_6_2 = 0

		for iter_6_2, iter_6_3 in ipairs(arg_6_0.sideTeam_) do
			if iter_6_3:isHasBuffByID(var_6_1) then
				var_6_2 = var_6_2 + 1
			end
		end

		return var_6_2
	else
		return 0
	end
end

function var_0_3.toDoPerFrames(arg_7_0)
	if arg_7_0:isDeath() then
		return
	end

	if arg_7_0.energyExtraCount_ > 0 then
		arg_7_0.energyExtraCount_ = arg_7_0.energyExtraCount_ - 1

		if arg_7_0.energyExtraCount_ == 0 then
			local var_7_0 = {}

			for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
				if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
					table.insert(var_7_0, iter_7_1)
				end
			end

			local var_7_1 = arg_7_0:createAttackUnits(var_7_0, arg_7_0.energyChildSkill_)

			for iter_7_2, iter_7_3 in ipairs(var_7_1) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end

			arg_7_0.extraEnergyAttackTime_ = arg_7_0.extraEnergyAttackTime_ - 1

			if arg_7_0.extraEnergyAttackTime_ > 0 then
				arg_7_0.energyExtraCount_ = var_0_10
			end
		end
	end
end

return var_0_3
