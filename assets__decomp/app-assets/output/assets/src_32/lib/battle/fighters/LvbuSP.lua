local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("LvbuSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 0
local var_0_8 = 0.002
local var_0_9 = 10002546
local var_0_10 = 10002548
local var_0_11 = 10002549
local var_0_12 = 10002551
local var_0_13 = 250
local var_0_14 = 40012723
local var_0_15 = 40012724
local var_0_16 = 10002539
local var_0_17 = 10002541
local var_0_18 = 10002542
local var_0_19 = 10002544
local var_0_20 = 5
local var_0_21 = 8
local var_0_22 = 15
local var_0_23 = 100
local var_0_24 = {
	40012728,
	40012729,
	40012730,
	40012731
}
local var_0_25 = 40012732
local var_0_26 = 0.003

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleState = false
	arg_1_0.purpleCount = 0
	arg_1_0.greenTarget = nil
	arg_1_0.blueTarget = nil
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_2_0.purpleState then
			arg_2_0:updatePurpleCount(var_0_21 - var_0_22)
		else
			arg_2_0:updatePurpleCount(var_0_21)
		end
	end
end

function var_0_3.applyHurtFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5 = var_0_3.super.applyHurtFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5)

	if arg_3_2 > 0 and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_3_0:updatePurpleCount(var_0_20)
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5
end

function var_0_3.updatePurpleCount(arg_4_0, arg_4_1)
	arg_4_0.purpleCount = arg_4_0.purpleCount + arg_4_1
	arg_4_0.purpleCount = math.min(arg_4_0.purpleCount, var_0_23)
	arg_4_0.purpleCount = math.max(arg_4_0.purpleCount, 0)

	if arg_4_0.purpleState and arg_4_0.purpleCount == 0 then
		arg_4_0.purpleState = false

		for iter_4_0, iter_4_1 in ipairs(var_0_24) do
			arg_4_0:removeBuffByID(iter_4_1)
		end

		local var_4_0 = arg_4_0:createNewBuffs({
			var_0_25
		}, arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		arg_4_0:addBuffs(var_4_0)
	elseif not arg_4_0.purpleState and arg_4_0.purpleCount == var_0_23 then
		arg_4_0.purpleState = true

		local var_4_1 = arg_4_0:createNewBuffs(var_0_24, arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		arg_4_0:addBuffs(var_4_1)
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	if arg_5_1.skillID == var_0_10 or arg_5_1.skillID == var_0_18 then
		local var_5_0 = arg_5_1.target:getX()
		local var_5_1 = arg_5_1.target:getY()
		local var_5_2

		if arg_5_0:getTeamType() == var_0_2.TeamType.A then
			var_5_2 = -1

			arg_5_0:flipX(false)
		else
			var_5_2 = 1

			arg_5_0:flipX(true)
		end

		arg_5_0:x(var_5_0 + 100 * var_5_2)
		arg_5_0:y(var_5_1)
	elseif arg_5_1.skillID == var_0_11 then
		local var_5_3 = arg_5_1.target
		local var_5_4 = var_5_3:getBuffs()

		for iter_5_0 = #var_5_4, 1, -1 do
			local var_5_5 = var_5_4[iter_5_0]

			if var_5_5:getDHarm() > 0 and var_5_5:canRemove() then
				var_5_3:removeBuffs(var_5_5)
			end
		end
	elseif arg_5_1.skillID == var_0_16 and arg_5_1.target:getAD() < arg_5_0:getAD() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_6 = arg_5_0:createAttackUnits({
			arg_5_0
		}, var_0_17)

		for iter_5_1, iter_5_2 in ipairs(var_5_6) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_2)
			table.insert(arg_5_0.records_.special_units, iter_5_2)
		end
	end

	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if var_0_6:father(arg_5_1.skillID) == arg_5_0:getEnergySkillID() and arg_5_1.skillID ~= var_0_12 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_1.harm > 0 then
			local var_5_7 = arg_5_0:energyChildSkillTargets(arg_5_1.target)
			local var_5_8 = arg_5_0:createAttackUnits(var_5_7, var_0_12)

			for iter_5_3, iter_5_4 in ipairs(var_5_8) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_4)
				table.insert(arg_5_0.records_.special_units, iter_5_4)
			end
		end
	elseif arg_5_1.skillID == var_0_19 then
		arg_5_0.blueTarget = nil
	end
end

function var_0_3.energyChildSkillTargets(arg_6_0, arg_6_1)
	local var_6_0 = {}
	local var_6_1 = var_0_13
	local var_6_2, var_6_3 = arg_6_1:getPos()

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.targetTeam_) do
		local var_6_4, var_6_5 = iter_6_1:getPos()

		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and var_6_1 >= math.abs(var_6_2 - var_6_4) and iter_6_1 ~= arg_6_1 then
			table.insert(var_6_0, iter_6_1)
		end
	end

	return var_6_0
end

function var_0_3.afterDamageHarm(arg_7_0, arg_7_1, arg_7_2)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_7_1 > 0 and arg_7_2.isBaoJi then
		local var_7_0 = var_0_7 + arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_8
		local var_7_1 = arg_7_0:createAttackUnits({
			arg_7_0
		}, var_0_9)

		for iter_7_0, iter_7_1 in ipairs(var_7_1) do
			iter_7_1:setExtraHarm(arg_7_1 * var_7_0)
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end
	end

	return arg_7_1, arg_7_2
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	if arg_8_1:getTableID() == var_0_14 then
		if arg_8_0.greenTarget then
			arg_8_0.greenTarget:removeBuffByID(var_0_14)
		end

		arg_8_0:removeBuffByID(var_0_15)

		arg_8_0.greenTarget = arg_8_1.target

		local var_8_0 = arg_8_1.target
		local var_8_1 = arg_8_1:getAttr()
		local var_8_2 = -var_8_0:getAD() * var_8_1
		local var_8_3 = arg_8_0:createNewBuffs({
			var_0_15
		}, arg_8_0, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		var_8_3[1].manualRevise = var_8_2

		arg_8_0:addBuffs(var_8_3)
	end
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7 = var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_3 and arg_9_4 > 0 and arg_9_0.purpleState then
		arg_9_4 = arg_9_4 * (1 + var_0_26 * arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

function var_0_3.popSkillByType(arg_10_0)
	if arg_10_0.purpleState then
		arg_10_0:popPugong()
	end

	return var_0_3.super.popSkillByType(arg_10_0)
end

function var_0_3.popPugong(arg_11_0)
	local var_11_0 = 0

	local function var_11_1()
		if next(arg_11_0.startSkillQueue_) ~= nil then
			local var_12_0 = arg_11_0.startSkillQueue_[1]

			table.remove(arg_11_0.startSkillQueue_, 1)
		else
			local var_12_1 = table.remove(arg_11_0.skillQueue_, 1)

			table.insert(arg_11_0.skillQueue_, var_12_1)

			var_11_0 = var_11_0 + 1
		end
	end

	local function var_11_2()
		local var_13_0

		if next(arg_11_0.startSkillQueue_) ~= nil then
			var_13_0 = arg_11_0.startSkillQueue_[1]
		else
			var_13_0 = arg_11_0.skillQueue_[1]
		end

		return var_13_0
	end

	while var_11_2() == arg_11_0:getPugongID() and var_11_0 <= #arg_11_0.skillQueue_ do
		var_11_1()
	end

	if var_11_0 > #arg_11_0.skillQueue_ then
		return 0
	end
end

function var_0_3.selectTargetByTypeD1(arg_14_0, arg_14_1, arg_14_2)
	if arg_14_0.blueTarget then
		return {
			arg_14_0.blueTarget
		}
	end

	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.targetTeam_) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() and iter_14_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_14_0, iter_14_1)
		end
	end

	if next(var_14_0) then
		local var_14_1
		local var_14_2

		for iter_14_2, iter_14_3 in ipairs(var_14_0) do
			if arg_14_0:getTeamType() == var_0_2.TeamType.A then
				if not var_14_1 or var_14_2 < iter_14_3:getX() then
					var_14_1 = iter_14_3
					var_14_2 = iter_14_3:getX()
				end
			elseif not var_14_1 or var_14_2 > iter_14_3:getX() then
				var_14_1 = iter_14_3
				var_14_2 = iter_14_3:getX()
			end
		end

		arg_14_0.blueTarget = var_14_1

		return {
			var_14_1
		}
	else
		return {}
	end
end

return var_0_3
