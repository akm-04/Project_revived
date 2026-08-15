local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chenwu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10001956
local var_0_7 = 40012090
local var_0_8 = 0.3
local var_0_9 = 10001955
local var_0_10 = 400
local var_0_11 = 0.05
local var_0_12 = 0.001
local var_0_13 = 0.3
local var_0_14 = 0

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyTarget = nil
	arg_1_0.energyCanHarm = false
	arg_1_0.blueCount = 0
	arg_1_0.purpleTarget = nil

	arg_1_0:listenInfo("attack_info")

	arg_1_0.records_.purple_unit = {}
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_2_0 = arg_2_1.target

		if var_2_0:isDHarm() then
			local var_2_1 = var_2_0:getBuffs()

			for iter_2_0 = #var_2_1, 1, -1 do
				local var_2_2 = var_2_1[iter_2_0]

				if var_2_2:isDHarmBuff() then
					var_2_2:setDHarm(var_2_2:getDHarm() * var_0_8)
				end
			end
		elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_3 = var_0_9
			local var_2_4 = {}

			for iter_2_1, iter_2_2 in ipairs(arg_2_0.sideTeam_) do
				if iter_2_2 ~= var_2_0 and not iter_2_2:isDeath() and not iter_2_2:isAffected() and math.abs(iter_2_2:getX() - var_2_0:getX()) <= var_0_10 then
					table.insert(var_2_4, iter_2_2)
				end
			end

			local var_2_5 = arg_2_0:createAttackUnits(var_2_4, var_2_3)

			for iter_2_3, iter_2_4 in ipairs(var_2_5) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_4)
				table.insert(arg_2_0.records_.special_units, iter_2_4)
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_2_1.skillID == arg_2_0:getEnergySkillID() then
		arg_2_0.energyCanHarm = false

		local var_2_6

		if not arg_2_0.energyTarget then
			var_2_6 = var_0_4.A4(arg_2_0)[1]
			arg_2_0.energyTarget = var_2_6
		else
			var_2_6 = arg_2_0.energyTarget
		end

		local var_2_7 = var_0_6
		local var_2_8 = arg_2_0:createAttackUnits({
			var_2_6
		}, var_2_7)

		for iter_2_5, iter_2_6 in ipairs(var_2_8) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_6)
			table.insert(arg_2_0.records_.special_units, iter_2_6)
		end
	end
end

function var_0_3.buffRemoveAction(arg_3_0, arg_3_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_1:getTableID() == var_0_7 and not arg_3_0.energyTarget:isHasBuffByID(var_0_7) then
		arg_3_0.energyTarget = nil
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.target:isHasBuffByID(var_0_7) and arg_4_4 > 0 then
		if not arg_4_0.energyCanHarm then
			arg_4_4 = 0
		else
			arg_4_0.energyCanHarm = false
		end
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_0.energyTarget and not arg_5_0.energyCanHarm then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("attack_info")) do
			if iter_5_1.fighter_ == arg_5_0.energyTarget then
				arg_5_0.energyCanHarm = true

				break
			end
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_0.blueCount >= 5 and not arg_5_0:isCreatingUnits() then
		local var_5_0 = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

		arg_5_0:createSkillByID(var_5_0, arg_5_0:getSkillLevelByID(var_5_0), var_0_5:attackIndex(var_5_0))

		arg_5_0.blueCount = 0

		arg_5_0:updateStateNumber(arg_5_0.blueCount)
	end
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and (arg_6_1.rootID_ == arg_6_0:getPugongID() or arg_6_1.rootID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_6_1.rootID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) then
		arg_6_0.blueCount = arg_6_0.blueCount + 1

		arg_6_0:updateStateNumber(arg_6_0.blueCount)
	end
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5 = var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_7_0:isCreatingUnits() then
		local var_7_0

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_1 = var_0_13 + var_0_14 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

			var_7_0 = var_0_2.weightedChoise({
				var_7_1,
				1 - var_7_1
			}) == 1

			if var_7_0 then
				arg_7_0.records_.purple_unit[tostring(arg_7_1.recordIndex_)] = true
			end
		elseif arg_7_0.reportPurpleUnit[tostring(arg_7_1.recordIndex_)] then
			var_7_0 = true
		end

		if var_7_0 then
			local var_7_2 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

			arg_7_0.purpleTarget = arg_7_1.fighter

			arg_7_0:createSkillByID(var_7_2, arg_7_0:getSkillLevelByID(var_7_2), var_0_5:attackIndex(var_7_2))
		end
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5
end

function var_0_3.getTargets(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_1 == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_8_0 = arg_8_0.purpleTarget

		arg_8_0.purpleTarget = nil

		return {
			var_8_0
		}
	else
		return var_0_3.super.getTargets(arg_8_0, arg_8_1, arg_8_2)
	end
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7 = var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_9_0 = var_0_11 + var_0_12 * arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		arg_9_4 = math.min(arg_9_1.target:getHpLimit() * var_9_0, arg_9_0:getHpLimit())
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

function var_0_3.setupReport(arg_10_0, arg_10_1)
	var_0_3.super.setupReport(arg_10_0, arg_10_1)

	arg_10_0.reportPurpleUnit = arg_10_1.purple_unit
end

function var_0_3.writeReport(arg_11_0)
	local var_11_0 = var_0_3.super.writeReport(arg_11_0)

	var_11_0.purple_unit = arg_11_0.records_.purple_unit

	return var_11_0
end

return var_0_3
