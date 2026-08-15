local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 0.9
local var_0_8 = 10001930
local var_0_9 = 100
local var_0_10 = {
	40012068,
	40012069,
	40012070
}
local var_0_11 = 10001931
local var_0_12 = 0.1
local var_0_13 = 0.002
local var_0_14 = 10001927
local var_0_15 = 10001937
local var_0_16 = 300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyHarmRate = 1
	arg_1_0.greenPos = {}
	arg_1_0.greenSkillTarget = {}
	arg_1_0.purpleCount = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getEnergySkillID() and arg_2_0.isStarEnergy_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, var_0_8)

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	if arg_3_1.rootID_ == arg_3_0:getEnergySkillID() then
		arg_3_0.energyHarmRate = 1
	elseif arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_3_0.isStarBlue_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = var_0_6.A3(arg_3_0, var_0_14)
		local var_3_1 = arg_3_0:createAttackUnits(var_3_0, var_0_14)

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end

	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)
end

function var_0_3.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_0.isStarPurple_ and arg_4_0:getTeamType() ~= arg_4_1.target:getTeamType() and arg_4_5 > 0 and arg_4_0.purpleCount <= 0 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_0 = var_0_6.A4(arg_4_0, var_0_15)
			local var_4_1 = arg_4_0:createAttackUnits(var_4_0, var_0_15)

			for iter_4_0, iter_4_1 in ipairs(var_4_1) do
				iter_4_1.unitCure = arg_4_5

				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end

		arg_4_5 = 0
		arg_4_0.purpleCount = var_0_16
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	local var_5_0 = arg_5_1.skillID

	if var_5_0 == arg_5_0:getEnergySkillID() and arg_5_4 > 0 then
		arg_5_4 = arg_5_4 * arg_5_0.energyHarmRate
		arg_5_0.energyHarmRate = arg_5_0.energyHarmRate * var_0_7
	elseif var_5_0 == var_0_8 and arg_5_4 > 0 then
		arg_5_4 = arg_5_4 * arg_5_0.energyHarmRate
	elseif var_5_0 == var_0_15 then
		arg_5_5 = arg_5_1.unitCure
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	arg_6_0.purpleCount = arg_6_0.purpleCount - 1

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if arg_6_0.greenPos[iter_6_1] and arg_6_0.greenPos[iter_6_1] - iter_6_1:getX() >= var_0_9 then
			for iter_6_2, iter_6_3 in ipairs(arg_6_0.selfTeam_) do
				if not iter_6_3:isDeath() and not iter_6_3:isAffected() and iter_6_3.hero_:getDistanceType() == var_0_2.DistanceType.HOUPAI then
					local var_6_0 = arg_6_0:createNewBuffs(var_0_10, iter_6_3, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

					iter_6_3:addBuffs(var_6_0)
				end
			end

			if arg_6_0.isStarGreen_ then
				table.insert(arg_6_0.greenSkillTarget, iter_6_1)
			end
		end

		arg_6_0.greenPos[iter_6_1] = iter_6_1:getX()
	end

	for iter_6_4 = #arg_6_0.greenSkillTarget, 1, -1 do
		local var_6_1 = arg_6_0.greenSkillTarget[iter_6_4]

		if not var_6_1:isDeath() and not var_6_1:isAffected() then
			local var_6_2 = var_0_12 + var_0_13 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

			if var_0_2.weightedChoise({
				var_6_2,
				1 - var_6_2
			}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_3 = arg_6_0:createAttackUnits({
					var_6_1
				}, var_0_11)

				for iter_6_5, iter_6_6 in ipairs(var_6_3) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_6)
					table.insert(arg_6_0.records_.special_units, iter_6_6)
				end
			end

			table.remove(arg_6_0.greenSkillTarget, iter_6_4)
		end
	end
end

return var_0_3
