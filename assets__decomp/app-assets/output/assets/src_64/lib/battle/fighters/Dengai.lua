local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dengai", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 20010117
local var_0_6 = 30010059
local var_0_7 = 10010059
local var_0_8 = 0.1
local var_0_9 = 0.005
local var_0_10 = 80010059
local var_0_11 = 80020059
local var_0_12 = 0.1
local var_0_13 = 40012043
local var_0_14 = 10001909
local var_0_15 = 10001912

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueSkillExist = false
	arg_1_0.count = false
	arg_1_0.isEnergyBuff_ = false
	arg_1_0.records_.blue_buff_add = {}
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if not arg_2_0.count then
		arg_2_0.blueSkillLevel = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		if arg_2_0.blueSkillLevel > 0 then
			arg_2_0.blueSkillExist = true
		end

		arg_2_0.count = true
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	var_0_3.super.buffAddAction(arg_3_0, arg_3_1)

	if arg_3_1:getTableID() == var_0_5 then
		arg_3_0.isEnergyBuff_ = true
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	var_0_3.super.buffRemoveAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_5 then
		arg_4_0.isEnergyBuff_ = false
	end
end

function var_0_3.getFrontSkill(arg_5_0)
	if arg_5_0.isEnergyBuff_ then
		if arg_5_0.blueSkillExist then
			return var_0_6
		else
			return var_0_7
		end
	end

	return var_0_3.super.getFrontSkill(arg_5_0)
end

function var_0_3.getOrbOfFrontSkill(arg_6_0)
	local var_6_0 = var_0_3.super.getOrbOfFrontSkill(arg_6_0)

	if var_0_4:father(var_6_0) == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_11 then
		if arg_6_0.isEnergyBuff_ then
			var_6_0 = var_0_14
		else
			var_6_0 = var_0_15
		end
	end

	return var_6_0
end

function var_0_3.checkEnergySkill(arg_7_0)
	if arg_7_0.isEnergyBuff_ then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_7_0)
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if var_0_4:father(arg_8_1.skillID) == var_0_6 then
		if arg_8_0:isBackPosition(arg_8_1.target) then
			arg_8_4 = (var_0_8 + var_0_9 * arg_8_0.blueSkillLevel) * arg_8_4
		else
			arg_8_4 = (1 + var_0_8 + var_0_9 * arg_8_0.blueSkillLevel) * arg_8_4
		end
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_9_0.isSkinSkillOn_ and arg_9_0.skinSkillID_ == var_0_10 and arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_9_0 = {
			arg_9_1.target
		}
		local var_9_1 = arg_9_0:createAttackUnits(var_9_0, arg_9_0.skinSkillID_)

		for iter_9_0, iter_9_1 in ipairs(var_9_1) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end

	if arg_9_0.isSkinSkillOn_ and arg_9_0.skinSkillID_ == var_0_11 and var_0_4:father(arg_9_1.skillID) == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_9_2 = arg_9_1.target
		local var_9_3

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_9_0.blueBuffAdd[tostring(var_0_1.ctx.battle.count)] and arg_9_0.blueBuffAdd[tostring(var_0_1.ctx.battle.count)][var_9_2.fighterIndex] then
				var_9_3 = true
			end
		else
			local var_9_4 = var_0_12

			var_9_3 = var_0_2.weightedChoise({
				var_9_4,
				1 - var_9_4
			}) == 1

			if var_9_3 then
				if not arg_9_0.records_.blue_buff_add[tostring(var_0_1.ctx.battle.count)] then
					arg_9_0.records_.blue_buff_add[tostring(var_0_1.ctx.battle.count)] = {}
				end

				if not arg_9_0.records_.blue_buff_add[tostring(var_0_1.ctx.battle.count)][var_9_2.fighterIndex] then
					arg_9_0.records_.blue_buff_add[tostring(var_0_1.ctx.battle.count)][var_9_2.fighterIndex] = 1
				end
			end
		end

		if var_9_3 then
			local var_9_5 = arg_9_0:createNewBuffs({
				var_0_13
			}, var_9_2, var_0_11)

			var_9_2:addBuffs(var_9_5)
		end
	end
end

function var_0_3.isBackPosition(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0:getNearestTarget()

	if var_0_4:scope(var_0_7) < math.abs(arg_10_1:getX() - var_10_0:getX()) then
		return true
	end

	return false
end

function var_0_3.setupReport(arg_11_0, arg_11_1)
	var_0_3.super.setupReport(arg_11_0, arg_11_1)

	arg_11_0.blueBuffAdd = arg_11_1.blue_buff_add
end

function var_0_3.writeReport(arg_12_0)
	local var_12_0 = var_0_3.super.writeReport(arg_12_0)

	var_12_0.blue_buff_add = arg_12_0.records_.blue_buff_add

	return var_12_0
end

return var_0_3
