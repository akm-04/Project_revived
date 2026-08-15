local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liushan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = 10350006
local var_0_9 = 40010270

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.currentSkillID_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_8)] or 0
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ ~= arg_3_0:getPugongID() then
		arg_3_0.currentSkillID_ = arg_3_1.rootID_
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_0.extraSkillLevel > 0 and arg_4_0.currentSkillID_ then
		arg_4_0.currentSkillID_ = nil

		local var_4_0 = var_0_4.new({
			tableID = var_0_9,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0.extraSkillLevel,
			skillID = arg_4_1.skillID,
			fighter = arg_4_0,
			target = arg_4_0
		})

		arg_4_0:addBuffs({
			var_4_0
		})
	end
end

function var_0_3.getOrbOfFrontSkill(arg_5_0)
	local var_5_0 = var_0_3.super.getFrontSkill(arg_5_0)

	if var_5_0 == arg_5_0:getEnergySkillID() then
		local var_5_1 = var_0_5:randomOrb(var_5_0)

		if next(var_5_1) then
			local var_5_2 = {}

			for iter_5_0, iter_5_1 in ipairs(var_5_1) do
				table.insert(var_5_2, 1)
			end

			return var_5_1[var_0_2.weightedChoise(var_5_2)]
		end
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_5_0)
end

function var_0_3.updateEnergyBy(arg_6_0, arg_6_1)
	var_0_3.super.updateEnergyBy(arg_6_0, arg_6_1)
end

function var_0_3.energyAction(arg_7_0, arg_7_1)
	if var_0_5:father(arg_7_1) == arg_7_0:getEnergySkillID() then
		arg_7_0:getFighterModel():playEnergyEffect_()
		arg_7_0:updateEnergyTo(arg_7_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

		if arg_7_0:getTeamType() == var_0_2.TeamType.A or arg_7_0.isInArena_ then
			arg_7_0:addBlackLayer()
		end
	end
end

return var_0_3
