local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhouyuSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10002505
local var_0_8 = 10002508
local var_0_9 = 10002515
local var_0_10 = 40012693
local var_0_11 = 0.25
local var_0_12 = 40012692
local var_0_13 = 0.1
local var_0_14 = 0.0015
local var_0_15 = 10002497
local var_0_16 = {
	40012688,
	40012689
}
local var_0_17 = 10002499
local var_0_18 = 10002500
local var_0_19 = 10002501
local var_0_20 = 3
local var_0_21 = 10002502
local var_0_22 = {
	40012690,
	40012691
}
local var_0_23 = 0.1
local var_0_24 = 0.3

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.greenHarm = 0
	arg_2_0.purpleHarm = 0
	arg_2_0.greenTargets = {}
	arg_2_0.energyTarget = nil
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	if var_0_6:father(arg_3_1.skillID) == arg_3_0:getEnergySkillID() and arg_3_1.skillID == var_0_7 then
		local var_3_0 = arg_3_1.target:getX()
		local var_3_1 = arg_3_1.target:getY()
		local var_3_2

		if arg_3_0:getTeamType() == var_0_2.TeamType.A then
			var_3_2 = -1

			arg_3_0:flipX(false)
		else
			var_3_2 = 1

			arg_3_0:flipX(true)
		end

		arg_3_0:x(var_3_0 + 100 * var_3_2)
		arg_3_0:y(var_3_1)
	end

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == var_0_8 then
		if arg_3_1.target:isDeath() then
			local var_3_3 = arg_3_0:createNewBuffs({
				var_0_12
			}, arg_3_0, arg_3_0:getEnergySkillID())
			local var_3_4 = var_0_13 + var_0_14 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

			var_3_3[1].manualRevise = arg_3_1.target:getAD() * var_3_4

			arg_3_0:addBuffs(var_3_3)
		end
	elseif arg_3_1.skillID == var_0_17 then
		arg_3_0:x(arg_3_1.target:getX())
		arg_3_0:y(arg_3_1.target:getY())
	elseif (arg_3_1.skillID == var_0_18 or arg_3_1.skillID == var_0_19) and arg_3_1.isBaoJi and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_5
		local var_3_6 = {}

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
			if iter_3_1 ~= arg_3_1.target and not iter_3_1:isDeath() and not iter_3_1:isAffected() and not var_0_2.tableHaveElement(arg_3_0.greenTargets, iter_3_1) then
				table.insert(var_3_6, iter_3_1)
			end
		end

		if #var_3_6 > 0 and #arg_3_0.greenTargets < var_0_20 then
			local var_3_7 = var_3_6[math.random(#var_3_6)]

			table.insert(arg_3_0.greenTargets, var_3_7)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_8 = arg_3_0:createAttackUnits({
					var_3_7
				}, var_0_19)

				for iter_3_2, iter_3_3 in ipairs(var_3_8) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			end
		elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_9 = arg_3_0:createAttackUnits({
				arg_3_0
			}, var_0_21)

			for iter_3_4, iter_3_5 in ipairs(var_3_9) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
				table.insert(arg_3_0.records_.special_units, iter_3_5)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.skillID == var_0_21 then
		arg_4_5 = arg_4_5 * (#arg_4_0.greenTargets + 1)
		arg_4_0.greenTargets = {}
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.selectTargetByTypeD1(arg_5_0)
	local var_5_0

	if arg_5_0.energyTarget then
		var_5_0 = arg_5_0.energyTarget
	else
		for iter_5_0, iter_5_1 in pairs(arg_5_0.targetTeam_) do
			if not iter_5_1:isDeath() and not iter_5_1:isAffected() and (not arg_5_0.energyTarget or arg_5_0.energyTarget:getAttrByType(var_0_2.AttributeType.HUJIA) > iter_5_1:getAttrByType(var_0_2.AttributeType.HUJIA)) then
				arg_5_0.energyTarget = iter_5_1
			end
		end

		var_5_0 = arg_5_0.energyTarget
	end

	if var_5_0 then
		return {
			var_5_0
		}
	end

	return var_0_5.B1(arg_5_0)
end

function var_0_3.afterDamageHarm(arg_6_0, arg_6_1, arg_6_2)
	if var_0_6:father(arg_6_2.skillID) == arg_6_0:getEnergySkillID() then
		if arg_6_2.skillID ~= var_0_7 then
			if arg_6_1 > 0 then
				local var_6_0 = arg_6_0:createNewBuffs({
					var_0_10
				}, arg_6_0, arg_6_0:getEnergySkillID())

				var_6_0[1].manualDharm = arg_6_1 * var_0_11

				arg_6_0:addBuffs(var_6_0)
			end

			if arg_6_2.skillID == var_0_8 then
				if arg_6_0.purpleHarm > 0 then
					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_6_1 = arg_6_0:createAttackUnits({
							arg_6_2.target
						}, var_0_9)

						for iter_6_0, iter_6_1 in ipairs(var_6_1) do
							iter_6_1:setExtraHarm(arg_6_0.purpleHarm)
							table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
							table.insert(arg_6_0.records_.special_units, iter_6_1)
						end
					end

					arg_6_0.purpleHarm = 0
				end

				arg_6_0.energyTarget = nil
			end
		end
	elseif var_0_6:father(arg_6_2.skillID) == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_6_0.greenHarm = arg_6_0.greenHarm + arg_6_1

		if arg_6_2.skillID == var_0_15 then
			local var_6_2 = arg_6_0:createNewBuffs(var_0_16, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))
			local var_6_3 = arg_6_0.greenHarm / arg_6_2.target:getHpLimit()

			for iter_6_2, iter_6_3 in ipairs(var_6_2) do
				iter_6_3.manualRevise = -var_6_3
			end

			arg_6_0:addBuffs(var_6_2)

			arg_6_0.greenHarm = 0
		end
	end

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_6_2.isBaoJi then
		local var_6_4 = arg_6_0:createNewBuffs(var_0_22, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		arg_6_0:addBuffs(var_6_4)

		arg_6_0.purpleHarm = math.min(arg_6_0.purpleHarm + arg_6_1 * var_0_23, var_0_24 * arg_6_0:getHpLimit())
	end

	return arg_6_1, arg_6_2
end

return var_0_3
