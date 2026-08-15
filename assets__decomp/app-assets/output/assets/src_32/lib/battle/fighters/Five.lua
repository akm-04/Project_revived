local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Five", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = {
	40012607,
	40012608
}
local var_0_9 = {
	10002413,
	10002414
}
local var_0_10 = {
	10002415,
	10002416
}
local var_0_11 = 0.6
local var_0_12 = 40012636
local var_0_13 = 10002417
local var_0_14 = 10002418
local var_0_15 = 0.2
local var_0_16 = 0.002
local var_0_17 = 0.2
local var_0_18 = 0.001
local var_0_19 = 40012637
local var_0_20 = 10002427
local var_0_21 = 0.1
local var_0_22 = 0.005
local var_0_23 = 0.2
local var_0_24 = 0.005
local var_0_25 = {
	40012625,
	40012626,
	40012627
}
local var_0_26 = 10002419
local var_0_27 = 40012635
local var_0_28 = 40012625

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.BlueHarm = 0
	arg_2_0.PurpleTarget = nil
	arg_2_0.PurpleTargetHasAddBuff = false
	arg_2_0.EnergyHarm = 0
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == var_0_9[2] then
		arg_3_0:greenJump(arg_3_1)
	end
end

function var_0_3.greenJump(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.target:getX()

	arg_4_0:x(var_4_0)
end

function var_0_3.toDoPerFrames(arg_5_0)
	var_0_3.super.toDoPerFrames(arg_5_0)

	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_5_0:isHasBuffByID(var_0_12) then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("harm_info")) do
			local var_5_0 = iter_5_1.harm
			local var_5_1 = iter_5_1.fighter

			if iter_5_1.target == arg_5_0 and var_5_0 > 0 then
				arg_5_0.BlueHarm = arg_5_0.BlueHarm + var_5_0
			end
		end
	end

	if arg_5_0:isHasBuffByID(var_0_25[1]) then
		for iter_5_2, iter_5_3 in ipairs(arg_5_0:getInfoByKey("harm_info")) do
			local var_5_2 = iter_5_3.harm
			local var_5_3 = iter_5_3.fighter

			if iter_5_3.target == arg_5_0 then
				arg_5_0.EnergyHarm = arg_5_0.EnergyHarm + var_5_2
			end
		end

		if arg_5_0.EnergyHarm / arg_5_0:getHpLimit() > 0.15 then
			arg_5_0.EnergyHarm = 0

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_4 = arg_5_0:getTargets(var_0_26)
				local var_5_5 = arg_5_0:createAttackUnits(var_5_4, var_0_26)

				for iter_5_4, iter_5_5 in ipairs(var_5_5) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_5)
					table.insert(arg_5_0.records_.special_units, iter_5_5)
				end
			end
		end
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count ~= 0 and var_0_1.ctx.battle.count % 300 == 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_6 = arg_5_0:getPurpleTarget(arg_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
		local var_5_7 = arg_5_0:createAttackUnits(var_5_6, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_5_6, iter_5_7 in ipairs(var_5_7) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_7)
			table.insert(arg_5_0.records_.special_units, iter_5_7)
		end
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_5_8, iter_5_9 in ipairs(arg_5_0:getInfoByKey("buff_info")) do
			if iter_5_9.target == arg_5_0 and iter_5_9.target:isHasBuffByID(var_0_19) and (iter_5_9:getBuffForm() == var_0_2.BuffForm.GAIN or iter_5_9:getDHarm() > 0) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_0.PurpleTarget and not arg_5_0.PurpleTargetHasAddBuff then
				arg_5_0.PurpleTargetHasAddBuff = true

				local var_5_8 = arg_5_0.PurpleTarget

				if var_5_8 then
					local var_5_9 = var_0_4.new({
						tableID = iter_5_9:getTableID(),
						start = var_0_1.ctx.battle.count,
						level = iter_5_9.level_,
						skillID = iter_5_9.skillID_,
						fighter = arg_5_0,
						target = var_5_8
					})

					var_5_9.manualRevise = iter_5_9.manualRevise or 0
					var_5_9.manualHarmRevise = iter_5_9.manualHarmRevise or 0
					var_5_9.manualDharm = iter_5_9.manualDharm or 0
					var_5_9.extraTime_ = iter_5_9.extraTime_
					var_5_9.leftCount_ = iter_5_9.leftCount_ * GreenEffectRate

					var_5_8:addBuffs({
						var_5_9
					})
				end
			end
		end
	end
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	var_0_3.super.buffAddAction(arg_6_0, arg_6_1)

	if arg_6_1:getTableID() == var_0_19 then
		arg_6_0.PurpleTarget = arg_6_1.target
		arg_6_0.PurpleTargetHasAddBuff = false
	elseif arg_6_1:getTableID() == var_0_8[1] then
		arg_6_1.resetXchange_ = -200 * (arg_6_0:getFlipX() and -1 or 1)
	elseif arg_6_1:getTableID() == var_0_8[2] then
		arg_6_1.resetXchange_ = 200 * (arg_6_0:getFlipX() and -1 or 1)
	elseif arg_6_1:getTableID() == var_0_27 then
		arg_6_1:setForceTarget(arg_6_0)
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_1.target:isHasBuffByID(var_0_19) and arg_7_1.target:getTeamType() == arg_7_0:getTeamType() then
		local var_7_0 = arg_7_0:createAttackUnits({
			arg_7_0
		}, var_0_20)
		local var_7_1 = var_0_21 + var_0_22 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_7_2 = var_0_23 + var_0_24 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			iter_7_1.extraHarm = arg_7_4 * var_7_1 * (1 - var_7_2)

			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end

		arg_7_4 = arg_7_4 - arg_7_4 * var_7_1
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if (arg_8_1.skillID == var_0_10[1] or arg_8_1.skillID == var_0_10[2]) and arg_8_4 > 0 then
		arg_8_4 = arg_8_4 + arg_8_4 * (arg_8_0:getHp() / arg_8_0:getHpLimit()) * var_0_11
	elseif arg_8_1.skillID == var_0_20 and arg_8_1.extraHarm > 0 then
		arg_8_4 = arg_8_4 + arg_8_1.extraHarm
	end

	if arg_8_1.skillID == var_0_14 and arg_8_1.extraHarm then
		arg_8_4 = arg_8_1.extraHarm + arg_8_4
	elseif arg_8_1.skillID == var_0_13 and arg_8_1.extraCure then
		arg_8_5 = arg_8_1.extraCure + arg_8_5
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.selectTargetByTypeD1(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = {}

	if arg_9_2 and arg_9_2.manualTargets_ then
		return arg_9_2.manualTargets_
	end

	local var_9_1 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and iter_9_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
			local var_9_2, var_9_3 = iter_9_1.fighterModel:getPosition()

			table.insert(var_9_1, iter_9_1)
		end
	end

	if #var_9_1 == 0 then
		return var_9_0
	end

	for iter_9_2, iter_9_3 in ipairs(var_9_1) do
		local var_9_4, var_9_5 = iter_9_3.fighterModel:getPosition()
		local var_9_6, var_9_7 = arg_9_0.fighterModel:getPosition()

		if var_9_4 < var_9_6 then
			table.insert(var_9_0, iter_9_3)
		end
	end

	return var_9_0
end

function var_0_3.selectTargetByTypeD2(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}

	if arg_10_2 and arg_10_2.manualTargets_ then
		return arg_10_2.manualTargets_
	end

	local var_10_1 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and iter_10_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
			local var_10_2, var_10_3 = iter_10_1.fighterModel:getPosition()

			table.insert(var_10_1, iter_10_1)
		end
	end

	if #var_10_1 == 0 then
		return var_10_0
	end

	for iter_10_2, iter_10_3 in ipairs(var_10_1) do
		local var_10_4, var_10_5 = iter_10_3.fighterModel:getPosition()
		local var_10_6, var_10_7 = arg_10_0.fighterModel:getPosition()

		if var_10_6 <= var_10_4 then
			table.insert(var_10_0, iter_10_3)
		end
	end

	return var_10_0
end

function var_0_3.getPurpleTarget(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = var_0_5.A2(arg_11_1, arg_11_2)
	local var_11_1
	local var_11_2

	for iter_11_0, iter_11_1 in pairs(var_11_0) do
		if iter_11_1 ~= arg_11_0 and (not var_11_1 or var_11_2 > iter_11_1:getHp() / iter_11_1:getHpLimit() or var_11_2 == iter_11_1:getHp() / iter_11_1:getHpLimit() and var_11_1:getHp() > iter_11_1:getHp()) then
			var_11_1 = iter_11_1
			var_11_2 = var_11_1:getHp() / var_11_1:getHpLimit()
		end
	end

	if var_11_1 then
		return {
			var_11_1
		}
	else
		return {}
	end

	return targets
end

function var_0_3.buffRemoveAction(arg_12_0, arg_12_1)
	var_0_3.super.buffRemoveAction(arg_12_0, arg_12_1)

	if arg_12_1:getTableID() == var_0_12 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_12_0 = arg_12_0:createAttackUnits({
			arg_12_0
		}, var_0_13)
		local var_12_1 = var_0_15 + var_0_16 * arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		for iter_12_0, iter_12_1 in ipairs(var_12_0) do
			iter_12_1.extraCure = arg_12_0.BlueHarm * var_12_1

			table.insert(arg_12_0.moveAttackUnits_, iter_12_1)
			table.insert(arg_12_0.records_.special_units, iter_12_1)
		end

		local var_12_2 = arg_12_0:getTargets(var_0_14)
		local var_12_3 = arg_12_0:createAttackUnits(var_12_2, var_0_14)
		local var_12_4 = var_0_17 + var_0_18 * arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		for iter_12_2, iter_12_3 in ipairs(var_12_3) do
			iter_12_3.extraHarm = arg_12_0.BlueHarm * var_12_4

			table.insert(arg_12_0.moveAttackUnits_, iter_12_3)
			table.insert(arg_12_0.records_.special_units, iter_12_3)
		end
	end
end

return var_0_3
