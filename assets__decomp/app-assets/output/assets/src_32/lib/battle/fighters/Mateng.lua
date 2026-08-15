local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Mateng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = var_0_2.tables.dbuff
local var_0_9 = var_0_2.tables.skill
local var_0_10 = 10001260
local var_0_11 = 10001261
local var_0_12 = 40011331
local var_0_13 = 40011332
local var_0_14 = 0.5
local var_0_15 = 40011334
local var_0_16 = 30
local var_0_17 = 0
local var_0_18 = 40011327
local var_0_19 = 10001258
local var_0_20 = 10001263
local var_0_21 = 10001259
local var_0_22 = 0.1
local var_0_23 = 10000661
local var_0_24 = 80010203
local var_0_25 = 0.3

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.BlueBuffID = 40012380
		arg_1_0.EnergyBuff1 = 40012379
		arg_1_0.GreenSkillID = 10002228
		arg_1_0.BlueSkillID = 10002229
	else
		arg_1_0.BlueBuffID = 40011333
		arg_1_0.EnergyBuff1 = 40011326
		arg_1_0.GreenSkillID = 20010203
		arg_1_0.BlueSkillID = 30010203
	end
end

function var_0_3.ctor(arg_2_0, arg_2_1)
	var_0_3.super.ctor(arg_2_0, arg_2_1)
	arg_2_0:listenInfo("buff_info")
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.greenTarget = nil
	arg_3_0.purpleBuffMap = {}
	arg_3_0.energyBuffJudge = true
	arg_3_0.EnergyBuff2Harm = 0
end

function var_0_3.toDoPerFrames(arg_4_0)
	var_0_3.super.toDoPerFrames(arg_4_0)

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
			local var_4_0 = iter_4_1.target

			if var_4_0 and not var_4_0:isDeath() and var_4_0:getTeamType() == arg_4_0:getTeamType() and var_4_0:isHasBuffByID(arg_4_0.BlueBuffID) and var_0_8:dbuffType(iter_4_1:getTableID()) > 0 then
				var_4_0:removeBuffs(iter_4_1)
				var_4_0:removeBuffByID(arg_4_0.BlueBuffID)
			end
		end
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_4_2, iter_4_3 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
			local var_4_1 = iter_4_3.target

			if var_4_1 and not var_4_1:isDeath() and var_4_1:getTeamType() == arg_4_0:getTeamType() and var_0_8:dbuffType(iter_4_3:getTableID()) > 0 then
				local var_4_2 = var_0_4.new({
					tableID = var_0_15,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
					skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
					fighter = arg_4_0,
					target = var_4_1
				})

				var_4_1:addBuffs({
					var_4_2
				})

				if not arg_4_0.purpleBuffMap[var_4_1] then
					arg_4_0.purpleBuffMap[var_4_1] = {}
				end

				local var_4_3 = var_0_8:dbuffType(iter_4_3:getTableID())

				if not arg_4_0.purpleBuffMap[var_4_1][var_4_3] then
					arg_4_0.purpleBuffMap[var_4_1][var_4_3] = 0
				end

				arg_4_0.purpleBuffMap[var_4_1][var_4_3] = arg_4_0.purpleBuffMap[var_4_1][var_4_3] + 1

				if arg_4_0.purpleBuffMap[var_4_1][var_4_3] > 1 then
					local var_4_4 = (arg_4_0.purpleBuffMap[var_4_1][var_4_3] - 1) * var_0_16
					local var_4_5 = iter_4_3:getTime()

					if var_4_5 - var_4_4 > 0 then
						iter_4_3:setExtraTime(-var_4_4)
					elseif var_4_5 % var_0_16 == 0 then
						iter_4_3:setExtraTime(var_0_17 - var_4_5)
					else
						iter_4_3:setExtraTime(var_4_5 % var_0_16 - var_4_5)
					end
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_1.skillID == var_0_21 and arg_5_1.extraHarm then
		var_5_2 = var_5_2 + arg_5_1.extraHarm
	elseif arg_5_1.skillID == var_0_24 and arg_5_1.extraHarm then
		var_5_3 = arg_5_1.extraHarm
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_4 > 0 and arg_6_1.target:isHasBuffByID(arg_6_0.EnergyBuff1) and arg_6_1.target:getTeamType() == arg_6_0:getTeamType() and arg_6_1.skillID ~= var_0_23 and arg_6_1.skillID ~= var_0_20 then
		local var_6_0 = 0

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
			if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:isHasBuffByID(arg_6_0.EnergyBuff1) then
				var_6_0 = var_6_0 + 1
			end
		end

		if var_6_0 == 0 then
			var_6_0 = 1
		end

		arg_6_4 = arg_6_4 / var_6_0
		arg_6_0.EnergyBuff2Harm = arg_6_0.EnergyBuff2Harm + arg_6_4

		for iter_6_2, iter_6_3 in ipairs(arg_6_0.selfTeam_) do
			if not iter_6_3:isDeath() and not iter_6_3:isAffected() and iter_6_3:isHasBuffByID(arg_6_0.EnergyBuff1) and iter_6_3 ~= arg_6_1.target then
				iter_6_3:updateHp(math.max(iter_6_3:getHp() - arg_6_4, 1))
			end
		end
	elseif arg_6_4 > 0 and arg_6_1.fighter:isHasBuffByID(var_0_18) and arg_6_1.skillID ~= var_0_21 then
		local var_6_1 = arg_6_0:createAttackUnits({
			arg_6_1.target
		}, var_0_21)

		for iter_6_4, iter_6_5 in ipairs(var_6_1) do
			iter_6_5.extraHarm = math.min(arg_6_0.EnergyBuff2Harm * var_0_22, arg_6_1.fighter:getAD())

			table.insert(arg_6_0.moveAttackUnits_, iter_6_5)
			table.insert(arg_6_0.records_.special_units, iter_6_5)
		end
	elseif arg_6_1.skillID == var_0_20 and arg_6_1.extraHarm then
		arg_6_4 = arg_6_1.extraHarm
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.skillID == arg_7_0.GreenSkillID then
		if arg_7_1.target:getTeamType() == arg_7_0:getTeamType() then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_7_0 = arg_7_0:createAttackUnits({
					arg_7_1.target
				}, var_0_11)

				for iter_7_0, iter_7_1 in ipairs(var_7_0) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
					table.insert(arg_7_0.records_.special_units, iter_7_1)
				end
			end
		elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_1 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_10)

			for iter_7_2, iter_7_3 in ipairs(var_7_1) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end
	elseif arg_7_1.skillID == arg_7_0.BlueSkillID then
		local var_7_2 = arg_7_1.target:getBuffs()
		local var_7_3

		for iter_7_4, iter_7_5 in ipairs(var_7_2) do
			if iter_7_5:getType() == var_0_2.BuffType.CONTINUE_HARM and (not var_7_3 or iter_7_5:getStartTime() > var_7_3:getStartTime()) then
				var_7_3 = iter_7_5
			end
		end

		if var_7_3 then
			arg_7_1.target:removeBuffs(var_7_3)
		else
			for iter_7_6, iter_7_7 in ipairs(var_7_2) do
				if var_0_8:dbuffType(iter_7_7:getTableID()) > 0 and (not var_7_3 or iter_7_7:getStartTime() > var_7_3:getStartTime()) then
					var_7_3 = iter_7_7
				end
			end

			if var_7_3 then
				arg_7_1.target:removeBuffs(var_7_3)
			end
		end
	elseif arg_7_1.skillID == var_0_24 then
		for iter_7_8, iter_7_9 in ipairs(arg_7_1.target:getBuffs()) do
			if iter_7_9:dBuffType() > 0 or iter_7_9:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				arg_7_1.target:removeBuffs(iter_7_9)
			end
		end
	end
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	var_0_3.super.buffAddAction(arg_8_0, arg_8_1)

	if arg_8_1:getTableID() == var_0_12 and arg_8_0.greenTarget then
		arg_8_1.manualRevise = arg_8_0.greenTarget:getAttrByType(var_0_2.AttributeType.AD) * var_0_14
	elseif arg_8_1:getTableID() == var_0_13 and arg_8_0.greenTarget then
		arg_8_1.manualRevise = arg_8_0.greenTarget:getAttrByType(var_0_2.AttributeType.AD_BAOJI) * var_0_14
	elseif arg_8_1:getTableID() == arg_8_0.EnergyBuff1 then
		arg_8_0.energyBuffJudge = false
	end
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	var_0_3.super.buffRemoveAction(arg_9_0, arg_9_1)

	if arg_9_1:getTableID() == arg_9_0.EnergyBuff1 and not arg_9_0.energyBuffJudge then
		arg_9_0.energyBuffJudge = true

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_9_0 = arg_9_0:selectTargetByTypeD2()
			local var_9_1 = arg_9_0:createAttackUnits(var_9_0, var_0_19)

			for iter_9_0, iter_9_1 in ipairs(var_9_1) do
				table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
				table.insert(arg_9_0.records_.special_units, iter_9_1)
			end

			if arg_9_0.skinSkillIndex_ == 1 then
				local var_9_2 = arg_9_0:createAttackUnits(var_0_7.A2(arg_9_0, var_0_24), var_0_24)

				for iter_9_2, iter_9_3 in ipairs(var_9_2) do
					iter_9_3.extraHarm = math.max(arg_9_0.EnergyBuff2Harm * var_0_25, 0)

					table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
					table.insert(arg_9_0.records_.special_units, iter_9_3)
				end
			end
		end
	elseif arg_9_1:getTableID() == var_0_18 then
		arg_9_0.EnergyBuff2Harm = 0
	end
end

function var_0_3.checkEnergySkill(arg_10_0)
	if not arg_10_0.energyBuffJudge then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_10_0)
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = {}
	local var_11_1

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.sideTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_11_1 or iter_11_1:getAttrByType(var_0_2.AttributeType.AGILE) > var_11_1:getAttrByType(var_0_2.AttributeType.AGILE)) then
			var_11_1 = iter_11_1
		end
	end

	arg_11_0.greenTarget = var_11_1

	table.insert(var_11_0, var_11_1)

	local var_11_2

	for iter_11_2, iter_11_3 in ipairs(arg_11_0.selfTeam_) do
		if not iter_11_3:isDeath() and not iter_11_3:isAffected() and iter_11_3:getSummonType() == var_0_2.summonMonsterType.None and (not var_11_2 or iter_11_3:getAttrByType(var_0_2.AttributeType.AGILE) > var_11_2:getAttrByType(var_0_2.AttributeType.AGILE)) then
			var_11_2 = iter_11_3
		end
	end

	table.insert(var_11_0, var_11_2)

	return var_11_0
end

function var_0_3.selectTargetByTypeD2(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.selfTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() and iter_12_1.hero_:getHeroType() == var_0_2.AttributeType.AGILE and iter_12_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_12_0, iter_12_1)
		end
	end

	return var_12_0
end

return var_0_3
