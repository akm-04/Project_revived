local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shangshanqianxin", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = 40012157
local var_0_9 = 10002004
local var_0_10 = 9
local var_0_11 = 180
local var_0_12 = 0.2
local var_0_13 = 0.002
local var_0_14 = 10002003
local var_0_15 = 40012158
local var_0_16 = 0.7
local var_0_17 = 80010254

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.hpRecord = {}
	arg_1_0.purpleTarget = nil
	arg_1_0.energyTarget = nil
	arg_1_0.tempEnergy = 0
	arg_1_0.records_.purple_buff_harm = {}
	arg_1_0.purpleBuffHarmRecord = {}
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getEnergySkillID() then
		local var_2_0 = arg_2_1.target

		if var_2_0 ~= arg_2_0 then
			arg_2_0.energyTarget = var_2_0
			arg_2_0.tempEnergy = var_2_0:getEnergy()

			var_2_0:updateEnergyBy(var_0_2.ENERGY_DECIMAL_BASE)

			if var_2_0:checkEnergySkill() and not var_2_0.isEnergySkill_ then
				if var_2_0:isCreatingUnits() then
					var_2_0:skillIsBreak()
				end

				var_2_0.isEnergySkill_ = true
				var_2_0.leftInterval_ = 0
			end
		elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_1 = var_0_9
			local var_2_2 = var_0_6:selectType(var_2_1)
			local var_2_3 = var_0_4[var_2_2](arg_2_0, var_2_1)
			local var_2_4 = arg_2_0:createAttackUnits(var_2_3, var_2_1)

			for iter_2_0, iter_2_1 in ipairs(var_2_4) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end

		local var_2_5 = arg_2_0:createNewBuffs({
			var_0_8
		}, arg_2_0, arg_2_0:getEnergySkillID())

		arg_2_0:addBuffs(var_2_5)

		if arg_2_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_6 = var_0_17
			local var_2_7 = arg_2_0:createAttackUnits({
				arg_2_0
			}, var_2_6)

			for iter_2_2, iter_2_3 in ipairs(var_2_7) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
				table.insert(arg_2_0.records_.special_units, iter_2_3)
			end
		end
	end

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_2_8 = arg_2_0:getBuffs()

		for iter_2_4 = #var_2_8, 1, -1 do
			local var_2_9 = var_2_8[iter_2_4]

			if var_2_9:getBuffForm() == var_0_2.BuffForm.DEBUFF and var_2_9:canRemove() then
				arg_2_0:removeBuffs(var_2_9)
			end
		end

		if #arg_2_0.hpRecord == var_0_10 then
			arg_2_0:updateHp(arg_2_0.hpRecord[1])
		end
	end

	if arg_2_1.skillID == var_0_14 then
		local var_2_10 = arg_2_0:createNewBuffs({
			var_0_15
		}, arg_2_1.target, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_2_10[1].manualHarmRevise = table.remove(arg_2_0.purpleBuffHarmRecord, 1)
		else
			var_2_10[1].manualHarmRevise = arg_2_1.buffHarm / var_2_10[1]:getTime() * 30

			table.insert(arg_2_0.records_.purple_buff_harm, var_2_10[1].manualHarmRevise)
		end

		arg_2_1.target:addBuffs(var_2_10)
	end
end

function var_0_3.energyActionBySpecialHero(arg_3_0, arg_3_1, arg_3_2)
	if arg_3_0.energyTarget and arg_3_0.energyTarget == arg_3_1 then
		if arg_3_0.skinSkillIndex_ == 1 and arg_3_0.energyTarget ~= arg_3_0 then
			arg_3_0:updateEnergyBy(arg_3_0.tempEnergy * var_0_16)
		end

		arg_3_1:updateEnergyBy(arg_3_0.tempEnergy)

		arg_3_0.tempEnergy = 0
		arg_3_0.energyTarget = nil
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count % 30 == 0 then
		if #arg_4_0.hpRecord >= var_0_10 then
			table.remove(arg_4_0.hpRecord, 1)
		end

		table.insert(arg_4_0.hpRecord, arg_4_0:getHp())
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count % var_0_11 == 1 then
		local var_4_0 = var_0_4.A4(arg_4_0)

		if #var_4_0 ~= 0 then
			arg_4_0.purpleTarget = var_4_0[1]
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	local var_5_0 = arg_5_1.target

	if var_5_0 == arg_5_0.purpleTarget and arg_5_4 > 0 then
		local var_5_1 = arg_5_4 * (var_0_12 + var_0_13 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

		arg_5_4 = arg_5_4 - var_5_1

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_5_2 = arg_5_0:createAttackUnits({
				var_5_0
			}, var_0_14)

			for iter_5_0, iter_5_1 in ipairs(var_5_2) do
				iter_5_1.buffHarm = var_5_1

				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end
		end

		arg_5_0.purpleTarget = nil
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.setupReport(arg_6_0, arg_6_1)
	var_0_3.super.setupReport(arg_6_0, arg_6_1)

	arg_6_0.purpleBuffHarmRecord = arg_6_1.purple_buff_harm
end

function var_0_3.writeReport(arg_7_0)
	local var_7_0 = var_0_3.super.writeReport(arg_7_0)

	var_7_0.purple_buff_harm = arg_7_0.records_.purple_buff_harm

	return var_7_0
end

return var_0_3
