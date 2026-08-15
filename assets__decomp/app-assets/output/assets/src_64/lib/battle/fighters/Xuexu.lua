local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xuexu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.cabinetSkillTable
local var_0_7 = 10001624
local var_0_8 = 20100005
local var_0_9 = 5
local var_0_10 = 600
local var_0_11 = 80010228
local var_0_12 = 40012502
local var_0_13 = 30

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.PugongSkillID = 10002324
		arg_2_0.GreenSkillID = 10002325
		arg_2_0.BlueSkillID = 10002326
		arg_2_0.PurpleSkillID = 10002327
		arg_2_0.EnergySkillID = 10002328
		arg_2_0.AwakeSkillID = 10002329
		arg_2_0.AffectBuff = 40012515
		arg_2_0.GreenSubSkill = 10002323
	elseif arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_2_0.PugongSkillID = 10001625
		arg_2_0.GreenSkillID = 10001626
		arg_2_0.BlueSkillID = 10001627
		arg_2_0.PurpleSkillID = 10001631
		arg_2_0.EnergySkillID = 10001628
		arg_2_0.AwakeSkillID = 60010228
		arg_2_0.AffectBuff = 40011726
		arg_2_0.GreenSubSkill = 10001623
	else
		arg_2_0.PugongSkillID = 10020228
		arg_2_0.GreenSkillID = 20020228
		arg_2_0.BlueSkillID = 30010228
		arg_2_0.PurpleSkillID = 40010228
		arg_2_0.EnergySkillID = 50010228
		arg_2_0.AwakeSkillID = 60010228
		arg_2_0.AffectBuff = 40011719
		arg_2_0.GreenSubSkill = 10001623
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.greenEatCount = 0
	arg_3_0.maxPurpleCount = 5
	arg_3_0.maxUsePurpleCount = 5
	arg_3_0.extraSkillJudge = false
	arg_3_0.extraSkillLevel = 0
end

function var_0_3.applyPurpleSkill(arg_4_0, arg_4_1)
	arg_4_1:updateHp(1)
	arg_4_1:addBuffs({
		var_0_4.new({
			tableID = arg_4_0.AffectBuff,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
			skillID = arg_4_0.PurpleSkillID,
			fighter = arg_4_0,
			target = arg_4_1
		})
	})
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	if arg_5_1:getTableID() == arg_5_0.AffectBuff and arg_5_1.target:getTeamType() == arg_5_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_1.target
		}, var_0_7)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_6_0)
	local var_6_0 = var_0_3.super.getOrbOfFrontSkill(arg_6_0)

	if arg_6_0.skinSkillIndex_ == 0 and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		if var_6_0 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
			var_6_0 = arg_6_0.EnergySkillID
		elseif var_6_0 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
			var_6_0 = arg_6_0.GreenSkillID
		elseif var_6_0 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
			var_6_0 = arg_6_0.BlueSkillID
		elseif var_6_0 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
			var_6_0 = arg_6_0.PurpleSkillID
		elseif var_6_0 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
			var_6_0 = arg_6_0.AwakeSkillID
		elseif var_6_0 == arg_6_0:getPugongID() then
			var_6_0 = arg_6_0.PugongSkillID
		end
	end

	return var_6_0
end

function var_0_3.forceGreenUnitArrive(arg_7_0)
	for iter_7_0, iter_7_1 in ipairs(arg_7_0.moveUnits_) do
		if iter_7_1.skillID == arg_7_0.GreenSkillID then
			iter_7_1.arrived = true
		end
	end
end

function var_0_3.getPurpleCount(arg_8_0)
	local var_8_0 = var_0_5:buffs(arg_8_0.PurpleSkillID)[1]
	local var_8_1 = arg_8_0:getBuffByID(var_8_0)

	return var_8_1 and var_8_1:actNum() or 0
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	if arg_9_1:getTableID() == var_0_12 then
		arg_9_1.manualDharm = var_0_13 * arg_9_0:getLevel()
	end
end

function var_0_3.updatePurpleCountBy(arg_10_0, arg_10_1)
	local var_10_0 = var_0_5:buffs(arg_10_0.PurpleSkillID)[1]
	local var_10_1 = arg_10_0:getBuffByID(var_10_0)

	if arg_10_1 < 0 then
		local var_10_2 = arg_10_0.extraSkillLevel * var_0_6:attrValues(var_0_8) * math.abs(arg_10_1)

		arg_10_0:updateEnergyTo(arg_10_0:getEnergy() + var_10_2)
	end

	arg_10_0.maxPurpleCount = math.min(var_0_9, arg_10_0.maxUsePurpleCount)

	local var_10_3 = math.max(0, math.min(arg_10_0.maxPurpleCount, (var_10_1 and var_10_1:actNum() or 0) + arg_10_1))

	if var_10_3 > 0 then
		local var_10_4 = var_0_4.new({
			tableID = var_10_0,
			start = var_0_1.ctx.battle.count,
			level = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
			skillID = arg_10_0.PurpleSkillID,
			fighter = arg_10_0,
			target = arg_10_0
		})

		var_10_4:setActNum(var_10_3)
		arg_10_0:addBuffs({
			var_10_4
		})
	else
		arg_10_0:removeBuffByID(var_10_0)
	end
end

function var_0_3.toDoPerFrames(arg_11_0)
	if arg_11_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_11_0 = arg_11_0:createAttackUnits({
			arg_11_0
		}, arg_11_0.PurpleSkillID)

		for iter_11_0, iter_11_1 in ipairs(var_11_0) do
			table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
			table.insert(arg_11_0.records_.special_units, iter_11_1)
		end
	end

	if arg_11_0.skinSkillIndex_ == 1 and var_0_1.ctx.battle.count % var_0_10 == 1 and var_0_1.ctx.battle.count ~= 1 then
		arg_11_0.maxUsePurpleCount = arg_11_0.maxUsePurpleCount + 1
	end

	if not arg_11_0.extraSkillJudge then
		arg_11_0.extraSkillJudge = true
		arg_11_0.extraSkillLevel = arg_11_0.hero_:skillBook()[tostring(var_0_8)] or 0
	end

	for iter_11_2, iter_11_3 in ipairs(arg_11_0.selfTeam_) do
		if not iter_11_3:isDeath() and iter_11_3:getSummonType() == var_0_2.summonMonsterType.None and not iter_11_3.XuexuPurpleSkillAffected then
			iter_11_3.XuexuPurpleSkillAffected = true

			local var_11_1 = iter_11_3.forceDie

			function iter_11_3.forceDie(arg_12_0)
				if arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
					if arg_11_0:getPurpleCount() > 0 then
						arg_11_0.maxUsePurpleCount = arg_11_0.maxUsePurpleCount > 0 and arg_11_0.maxUsePurpleCount - 1 or 0

						arg_11_0:updatePurpleCountBy(-1)
						arg_11_0:applyPurpleSkill(arg_12_0)
						arg_11_0:judgeSkinSkill(arg_12_0)
					else
						var_11_1(arg_12_0)
					end
				end
			end
		end
	end

	for iter_11_4, iter_11_5 in ipairs(arg_11_0:getInfoByKey("attack_info")) do
		if iter_11_5.fighter_:getTeamType() ~= arg_11_0:getTeamType() and iter_11_5.fighter_:getEnergySkillID() == iter_11_5.rootID_ then
			arg_11_0:updatePurpleCountBy(1)
		end
	end
end

function var_0_3.moveUnitArrive(arg_13_0, arg_13_1)
	var_0_3.super.moveUnitArrive(arg_13_0, arg_13_1)

	if arg_13_1.skillID == arg_13_0.GreenSkillID then
		arg_13_0.greenEatCount = 0

		local var_13_0 = var_0_5:scope(arg_13_0.GreenSubSkill) / 2

		for iter_13_0, iter_13_1 in ipairs(arg_13_0.targetTeam_) do
			if not iter_13_1:isDeath() and not iter_13_1:isAffected() and var_13_0 > math.abs(iter_13_1:getX() - arg_13_1:getX()) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_13_1 = arg_13_0:createAttackUnits({
					iter_13_1
				}, arg_13_0.GreenSubSkill)

				for iter_13_2, iter_13_3 in ipairs(var_13_1) do
					table.insert(arg_13_0.moveAttackUnits_, iter_13_3)
					table.insert(arg_13_0.records_.special_units, iter_13_3)
				end
			end
		end
	end
end

function var_0_3.skillIsBreakAction(arg_14_0, arg_14_1)
	arg_14_0:forceGreenUnitArrive()
end

function var_0_3.judgeSkinSkill(arg_15_0, arg_15_1)
	if arg_15_0.skinSkillIndex_ == 1 and arg_15_1 ~= arg_15_0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_15_0 = arg_15_0:createAttackUnits({
			arg_15_0
		}, var_0_11)

		for iter_15_0, iter_15_1 in ipairs(var_15_0) do
			table.insert(arg_15_0.moveAttackUnits_, iter_15_1)
			table.insert(arg_15_0.records_.special_units, iter_15_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_16_0, arg_16_1)
	if arg_16_1.skillID == arg_16_0.GreenSkillID then
		local var_16_0 = false

		for iter_16_0, iter_16_1 in ipairs(arg_16_1.target:getBuffs()) do
			if (iter_16_1:getBuffForm() == var_0_2.BuffForm.GAIN or iter_16_1:totalDHarm() > 0) and iter_16_1:canRemove() then
				arg_16_1.target:removeBuffs(iter_16_1)

				if arg_16_1.target:getSummonType() == var_0_2.summonMonsterType.None then
					var_16_0 = true
				end
			end
		end

		if var_16_0 then
			arg_16_0.greenEatCount = arg_16_0.greenEatCount + 1

			if arg_16_0.greenEatCount > 2 then
				arg_16_0:forceGreenUnitArrive()
			end
		end
	elseif arg_16_1.skillID == arg_16_0.EnergySkillID then
		for iter_16_2, iter_16_3 in ipairs(arg_16_1.target:getBuffs()) do
			if (iter_16_3:getBuffForm() == var_0_2.BuffForm.GAIN or iter_16_3:totalDHarm() > 0) and iter_16_3:canRemove() then
				arg_16_1.target:removeBuffs(iter_16_3)
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_16_0, arg_16_1)
end

return var_0_3
