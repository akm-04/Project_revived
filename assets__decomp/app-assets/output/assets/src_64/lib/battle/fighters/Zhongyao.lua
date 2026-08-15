local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_2.tables.skill
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_0.class("Zhongyao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_7 = 500
local var_0_8 = 40011121
local var_0_9 = 10001008
local var_0_10 = 0.7
local var_0_11 = 0.1
local var_0_12 = 0.6
local var_0_13 = 10000
local var_0_14 = 40011122
local var_0_15 = 10001011
local var_0_16 = 40011127
local var_0_17 = 40011128
local var_0_18 = 3
local var_0_19 = 10001012
local var_0_20 = 500
local var_0_21 = 40011121
local var_0_22 = 0.7
local var_0_23 = 10001014
local var_0_24 = 0.1
local var_0_25 = 0.6
local var_0_26 = 10000
local var_0_27 = 40011122
local var_0_28 = 10001015
local var_0_29 = 40011127
local var_0_30 = 40011128
local var_0_31 = 3
local var_0_32 = 0.2
local var_0_33 = 10001017
local var_0_34 = 150
local var_0_35 = 10001007
local var_0_36 = 10001006
local var_0_37 = 10001010
local var_0_38 = 1
local var_0_39 = 80010183
local var_0_40 = 10001545
local var_0_41 = 10001549
local var_0_42 = 10001546
local var_0_43 = 10001547
local var_0_44 = 10001550
local var_0_45 = 10001551
local var_0_46 = 10001554
local var_0_47 = 10001553

function var_0_6.ctor(arg_1_0, arg_1_1)
	var_0_6.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
	arg_1_0:listenInfo("attack_info")
	arg_1_0:listenInfo("death_info")
end

function var_0_6.init(arg_2_0)
	var_0_6.super.init(arg_2_0)

	arg_2_0.greenTarget1 = nil
	arg_2_0.greenHarm = 0
	arg_2_0.extraGreenHarm = 0
	arg_2_0.blueTarget = nil
	arg_2_0.blueCountDown = 0
	arg_2_0.blueCount = 0
	arg_2_0.blueCureHP = 0
	arg_2_0.extraBlueTargets = {}
	arg_2_0.extraBlueCountDown = 0
	arg_2_0.extraBlueCount = 0
	arg_2_0.extraBlueCureHP = 0
	arg_2_0.purpleBuffNum = 2
	arg_2_0.reloadNum = false
	arg_2_0.energyEffect_ = nil
	arg_2_0.energyCountDown = 0
	arg_2_0.energyTargets = nil
	arg_2_0.energyPosX_ = 0
	arg_2_0.energyCureHp = 0

	arg_2_0:updateStateNumber()
end

function var_0_6.buffHarmFeedBack(arg_3_0, arg_3_1)
	arg_3_0.super.buffHarmFeedBack(arg_3_0, arg_3_1)

	arg_3_0.energyCureHp = arg_3_0.energyCureHp + arg_3_1 * var_0_38
end

function var_0_6.getEnergyCureTarget(arg_4_0)
	local var_4_0
	local var_4_1

	for iter_4_0, iter_4_1 in pairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() and iter_4_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_4_1 or var_4_0 > iter_4_1:getHp() / iter_4_1:getHpLimit() or var_4_0 == iter_4_1:getHp() / iter_4_1:getHpLimit() and var_4_1:getHp() > iter_4_1:getHp()) then
			var_4_1 = iter_4_1
			var_4_0 = var_4_1:getHp() / var_4_1:getHpLimit()
		end
	end

	if var_4_1 then
		return var_4_1
	else
		return nil
	end
end

function var_0_6.greenSecondSkill(arg_5_0)
	if arg_5_0.greenTarget1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0.skinSkillID_ == var_0_39 and var_0_42 or var_0_9
		local var_5_1 = arg_5_0:createAttackUnits(arg_5_0:selectGreenTarget2(), var_5_0)

		for iter_5_0, iter_5_1 in pairs(var_5_1) do
			iter_5_1.iniX_ = arg_5_0.greenTarget1:getX()
			iter_5_1.iniY_ = arg_5_0.greenTarget1:getY()

			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)

			if iter_5_1.resource then
				iter_5_1.resource:pos(iter_5_1.iniX_, iter_5_1.iniY_)
				iter_5_1:rotate()
				iter_5_1:movePosition()
				iter_5_1.resource:addTo(var_0_1.ctx.battle.unitLayer)
				iter_5_1.resource:playRepeat()
			end
		end

		arg_5_0.greenTarget1 = nil
	end
end

function var_0_6.buffRemoveAction(arg_6_0, arg_6_1)
	if arg_6_1.tableID_ == var_0_8 then
		arg_6_0:greenSecondSkill()
	end
end

function var_0_6.toDoPerFrames(arg_7_0)
	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_7_0.reloadNum then
		arg_7_0:updateStateNumber(arg_7_0.purpleBuffNum)

		arg_7_0.reloadNum = true
	end

	if arg_7_0.blueCountDown > 0 then
		arg_7_0.blueCountDown = arg_7_0.blueCountDown - 1
	end

	for iter_7_0, iter_7_1 in pairs(arg_7_0:getInfoByKey("death_info")) do
		if arg_7_0.greenTarget1 and iter_7_1 == arg_7_0.greenTarget1 then
			arg_7_0:greenSecondSkill()
		end
	end

	arg_7_0:collectGreenHarm()
	arg_7_0:dealWithBlueBuff()
	arg_7_0:dealWithPurpleSkill()
	arg_7_0:updateEnergySkill()
end

function var_0_6.applyUnitMoves(arg_8_0)
	arg_8_0.super.applyUnitMoves(arg_8_0)

	local var_8_0 = {}

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		for iter_8_0 = 1, #arg_8_0.reportUnits_ do
			local var_8_1 = arg_8_0.reportUnits_[iter_8_0]
			local var_8_2

			if var_8_1.skillID == var_0_9 or var_8_1.skillID == var_0_42 then
				var_8_2 = arg_8_0.greenTarget1
			elseif var_8_1.skillID == var_0_19 or var_8_1.skillID == var_0_43 then
				var_8_2 = arg_8_0
			end

			if var_8_2 and var_8_1.resource and var_8_1.count and var_0_1.ctx.battle.count >= var_8_1.count then
				if var_8_1.reportData_.calculate[tostring(var_0_1.ctx.battle.count)] then
					var_8_1.arrived = true

					if var_8_1.resource then
						var_8_1.resource:stop()
					end

					table.insert(var_8_0, iter_8_0)
				elseif arg_8_0.greenTarget1 then
					var_8_1:rotate()
					var_8_1:movePosition()

					if not var_8_1.resource:getParent() then
						var_8_1.resource:pos(var_8_2:getX(), var_8_2:getY())
						var_8_1.resource:addTo(var_0_1.ctx.battle.unitLayer)
						var_8_1.resource:playRepeat()
					end
				end
			end
		end

		for iter_8_1 = #var_8_0, 1, -1 do
			local var_8_3 = var_8_0[iter_8_1]

			table.remove(arg_8_0.reportUnits_, var_8_3)
		end
	end
end

function var_0_6.collectGreenHarm(arg_9_0)
	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and arg_9_0.greenTarget1 then
		for iter_9_0, iter_9_1 in pairs(arg_9_0:getInfoByKey("harm_info")) do
			if arg_9_0.greenTarget1 and iter_9_1.target == arg_9_0.greenTarget1 and (iter_9_1.skillID ~= arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and iter_9_1.skillID ~= var_0_40 and iter_9_1.fighter == arg_9_0 or iter_9_1.fighter ~= arg_9_0) then
				arg_9_0.greenHarm = arg_9_0.greenHarm + iter_9_1.harm * var_0_10
			end
		end
	end
end

function var_0_6.addSelfBuff(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = var_0_5.new({
		tableID = arg_10_1,
		start = var_0_1.ctx.battle.count,
		level = arg_10_0:getSkillLevelByID(arg_10_2),
		skillID = arg_10_2,
		fighter = arg_10_0,
		target = arg_10_0
	})

	arg_10_0:addBuffs({
		var_10_0
	})
end

function var_0_6.dealWithBlueBuff(arg_11_0)
	if arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_11_0.blueTarget and arg_11_0.blueTarget:getBuffByID(var_0_14) and arg_11_0.blueCountDown % 30 == 0 then
		local var_11_0 = arg_11_0.blueTarget:getBuffByID(var_0_14)
		local var_11_1 = math.min(var_11_0:totalDHarm() * var_0_11, var_11_0:getDHarm())

		var_11_0:setDHarm(var_11_1)
		var_11_0.target:updateHpBar(true)

		local var_11_2 = var_11_1 * var_0_12

		arg_11_0.blueCureHP = var_11_2
		arg_11_0.blueCount = arg_11_0.blueCount + 1

		if var_11_2 > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_11_3 = arg_11_0:createAttackUnits({
				arg_11_0.blueTarget
			}, var_0_15)

			for iter_11_0, iter_11_1 in ipairs(var_11_3) do
				table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
				table.insert(arg_11_0.records_.special_units, iter_11_1)
			end
		end

		if arg_11_0.blueCount == 3 and var_11_0:getDHarm() > 0 then
			arg_11_0:addSelfBuff(var_0_16, arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))
			arg_11_0:addSelfBuff(var_0_17, arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))
		end

		if var_11_0:getDHarm() <= 0 then
			arg_11_0.blueCountDown = 0
			arg_11_0.blueCount = 0
			arg_11_0.blueTarget = nil
		end
	end
end

function var_0_6.dealWithPurpleSkill(arg_12_0)
	if arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_12_0, iter_12_1 in ipairs(arg_12_0.extraBlueTargets) do
			if iter_12_1:getBuffByID(var_0_27) and arg_12_0.extraBlueCountDown % 30 == 0 then
				local var_12_0 = iter_12_1:getBuffByID(var_0_27)
				local var_12_1 = math.min(var_12_0:totalDHarm() * var_0_24, var_12_0:getDHarm())

				var_12_0:setDHarm(var_12_1)
				var_12_0.target:updateHpBar(true)

				local var_12_2 = var_12_1 * var_0_25

				arg_12_0.extraBlueCureHP = var_12_2
				arg_12_0.extraBlueCount = arg_12_0.blueCount + 1

				if var_12_2 > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_12_3 = arg_12_0:createAttackUnits({
						iter_12_1
					}, var_0_28)

					for iter_12_2, iter_12_3 in ipairs(var_12_3) do
						table.insert(arg_12_0.moveAttackUnits_, iter_12_3)
						table.insert(arg_12_0.records_.special_units, iter_12_3)
					end
				end

				if arg_12_0.extraBlueCount == 3 and var_12_0:getDHarm() > 0 then
					arg_12_0:addSelfBuff(var_0_29, arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
					arg_12_0:addSelfBuff(var_0_30, arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
				end

				if var_12_0:getDHarm() <= 0 then
					arg_12_0.extraBlueCountDown = 0
					arg_12_0.extraBlueCount = 0

					table.remove(arg_12_0.extraBlueTargets, iter_12_0)
				end
			end
		end

		for iter_12_4, iter_12_5 in pairs(arg_12_0:getInfoByKey("attack_info")) do
			if iter_12_5.fighter_:getEnergySkillID() == iter_12_5.rootID_ and iter_12_5.fighter_:getSummonType() ~= var_0_2.summonMonsterType.Pet and iter_12_5.fighter_ ~= arg_12_0 then
				if arg_12_0.purpleBuffNum >= 10 then
					break
				end

				arg_12_0.purpleBuffNum = arg_12_0.purpleBuffNum + 1

				arg_12_0:updateStateNumber(arg_12_0.purpleBuffNum)
			end
		end
	end
end

function var_0_6.unitAfterCreate(arg_13_0, arg_13_1, arg_13_2)
	arg_13_0.super.unitAfterCreate(arg_13_0, arg_13_1, arg_13_2)

	for iter_13_0, iter_13_1 in pairs(arg_13_2) do
		if iter_13_1.skillID == arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) or iter_13_1.skillID == var_0_41 then
			arg_13_0.blueTarget = iter_13_1.target
			arg_13_0.blueCountDown = var_0_13
		end

		if iter_13_1.skillID == arg_13_0:getSkillByColor(var_0_23) or iter_13_1.skillID == var_0_44 then
			table.insert(arg_13_0.extraBlueTargets, iter_13_1.target)

			arg_13_0.extraBlueCountDown = var_0_13
		end
	end
end

function var_0_6.createUnits(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_1 or arg_14_0.unitSkills_
	local var_14_1, var_14_2 = var_14_0:getFront()

	if var_14_2 ~= arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_14_2 ~= var_0_41 or not arg_14_0.blueTarget or var_14_2 ~= var_0_23 and var_14_2 ~= var_0_44 or not next(arg_14_0.extraBlueTargets) then
		arg_14_0.super.createUnits(arg_14_0, var_14_0)
	end

	if var_14_2 == arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_14_2 == var_0_40 and arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_14_0.purpleBuffNum > 0 then
		local var_14_3 = arg_14_0:getExtraGreenTargets()

		if next(var_14_3) then
			arg_14_0.purpleBuffNum = arg_14_0.purpleBuffNum - 1

			arg_14_0:updateStateNumber(arg_14_0.purpleBuffNum)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_14_4 = arg_14_0.skinSkillID_ == var_0_39 and var_0_43 or var_0_19
				local var_14_5 = arg_14_0:createAttackUnits(var_14_3, var_14_4)

				for iter_14_0, iter_14_1 in pairs(var_14_5) do
					table.insert(arg_14_0.moveAttackUnits_, iter_14_1)
					table.insert(arg_14_0.records_.special_units, iter_14_1)

					if iter_14_1.resource then
						iter_14_1.resource:pos(iter_14_1:getIniPos())
						iter_14_1:rotate()
						iter_14_1:movePosition()
						iter_14_1.resource:addTo(var_0_1.ctx.battle.unitLayer)
						iter_14_1.resource:playRepeat()
					end
				end
			end
		end
	end

	if var_14_2 == arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) or var_14_2 == var_0_41 and arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_14_0.purpleBuffNum > 0 then
		local var_14_6 = arg_14_0:getExtraBlueTargets()

		if next(var_14_6) then
			arg_14_0.purpleBuffNum = arg_14_0.purpleBuffNum - 1

			arg_14_0:updateStateNumber(arg_14_0.purpleBuffNum)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_14_7 = arg_14_0.skinSkillID_ == var_0_39 and var_0_44 or var_0_23
				local var_14_8 = arg_14_0:createAttackUnits(var_14_6, var_14_7)

				for iter_14_2, iter_14_3 in pairs(var_14_8) do
					table.insert(arg_14_0.moveAttackUnits_, iter_14_3)
					table.insert(arg_14_0.records_.special_units, iter_14_3)

					if iter_14_3.resource then
						iter_14_3.resource:pos(iter_14_3:getIniPos())
						iter_14_3:rotate()
						iter_14_3:movePosition()
						iter_14_3.resource:addTo(var_0_1.ctx.battle.unitLayer)
						iter_14_3.resource:playRepeat()
					end
				end
			end
		end
	end
end

function var_0_6.getExtraGreenTarget(arg_15_0)
	local var_15_0 = 0
	local var_15_1

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		arg_15_0:selectTargetByTypeD1(arg_15_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))
	end

	for iter_15_0, iter_15_1 in pairs(arg_15_0.sideTeam_) do
		if not iter_15_1:isDeath() and not iter_15_1:isAffected() and var_15_0 <= iter_15_1:getAttrByType(var_0_2.AttributeType.AGILE) and arg_15_0.greenTarget1 and iter_15_1 ~= arg_15_0.greenTarget1 then
			var_15_0 = iter_15_1:getAttrByType(var_0_2.AttributeType.AGILE)
			var_15_1 = iter_15_1
		end
	end

	return var_15_1
end

function var_0_6.getExtraGreenTargets(arg_16_0)
	if arg_16_0.skinSkillID_ == var_0_39 then
		local var_16_0 = {}

		for iter_16_0, iter_16_1 in pairs(arg_16_0.sideTeam_) do
			if not iter_16_1:isDeath() and not iter_16_1:isAffected() and arg_16_0.greenTarget1 and iter_16_1 ~= arg_16_0.greenTarget1 then
				table.insert(var_16_0, iter_16_1)
			end
		end

		table.sort(var_16_0, function(arg_17_0, arg_17_1)
			return arg_17_0:getAttrByType(var_0_2.AttributeType.AGILE) > arg_17_1:getAttrByType(var_0_2.AttributeType.AGILE)
		end)

		local var_16_1 = {}

		for iter_16_2 = 1, math.min(arg_16_0.purpleBuffNum, 4) do
			var_16_1[iter_16_2] = var_16_0[iter_16_2]
		end

		return var_16_1
	else
		return {
			arg_16_0:getExtraGreenTarget()
		}
	end
end

function var_0_6.getExtraBlueTarget(arg_18_0)
	local var_18_0
	local var_18_1

	for iter_18_0, iter_18_1 in pairs(arg_18_0.selfTeam_) do
		if iter_18_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_18_1:isDeath() and iter_18_1 ~= arg_18_0.blueTarget and (not var_18_0 or var_18_1 > iter_18_1:getHp() / iter_18_1:getHpLimit() or var_18_1 == iter_18_1:getHp() / iter_18_1:getHpLimit() and var_18_0:getHp() > iter_18_1:getHp()) then
			var_18_0 = iter_18_1
			var_18_1 = var_18_0:getHp() / var_18_0:getHpLimit()
		end
	end

	return var_18_0
end

function var_0_6.getExtraBlueTargets(arg_19_0)
	if arg_19_0.skinSkillID_ == var_0_39 then
		local var_19_0 = {}

		for iter_19_0, iter_19_1 in pairs(arg_19_0.selfTeam_) do
			if iter_19_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_19_1:isDeath() and iter_19_1 ~= arg_19_0.blueTarget then
				table.insert(var_19_0, iter_19_1)
			end
		end

		table.sort(var_19_0, function(arg_20_0, arg_20_1)
			return arg_20_0:getHp() / arg_20_0:getHpLimit() < arg_20_1:getHp() / arg_20_1:getHpLimit()
		end)

		local var_19_1 = {}

		for iter_19_2 = 1, math.min(arg_19_0.purpleBuffNum, 4) do
			var_19_1[iter_19_2] = var_19_0[iter_19_2]
		end

		return var_19_1
	else
		return {
			arg_19_0:getExtraBlueTarget()
		}
	end
end

function var_0_6.calculateUnitData(arg_21_0, arg_21_1)
	local var_21_0, var_21_1, var_21_2, var_21_3, var_21_4, var_21_5 = arg_21_0.super.calculateUnitData(arg_21_0, arg_21_1)

	if arg_21_1.skillID == var_0_9 or arg_21_1.skillID == var_0_42 then
		var_21_2 = arg_21_0.greenHarm
		arg_21_0.greenHarm = 0
	end

	if arg_21_1.skillID == var_0_15 or arg_21_1.skillID == SKIN_BLUE_CURE_SKILL then
		var_21_3 = arg_21_0.blueCureHP
		arg_21_0.blueCureHP = 0
	end

	if arg_21_1.skillID == var_0_28 then
		var_21_3 = arg_21_0.extraBlueCureHP
		arg_21_0.extraBlueCureHP = 0
	end

	if arg_21_1.skillID == var_0_37 then
		var_21_3 = arg_21_0.energyCureHp
		arg_21_0.energyCureHp = 0
	end

	if var_0_3:father(arg_21_1.skillID) == arg_21_0:getEnergySkillID() and arg_21_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		var_21_2 = var_21_2 + var_21_2 * var_0_32 * arg_21_0.purpleBuffNum
	end

	return var_21_0, var_21_1, var_21_2, var_21_3, var_21_4, var_21_5
end

function var_0_6.selectGreenTarget2(arg_22_0)
	local var_22_0 = {}

	if not arg_22_0.greenTarget1 then
		return var_22_0
	else
		for iter_22_0, iter_22_1 in pairs(arg_22_0.sideTeam_) do
			if not iter_22_1:isDeath() and not iter_22_1:isAffected() and math.abs(iter_22_1:getX() - arg_22_0.greenTarget1:getX()) < var_0_7 and iter_22_1 ~= arg_22_0.greenTarget1 then
				table.insert(var_22_0, iter_22_1)
			end
		end
	end

	return var_22_0
end

function var_0_6.updateEnergySkill(arg_23_0)
	if arg_23_0.energyCountDown <= 0 and arg_23_0.energyEffect_ then
		arg_23_0:energySubSkill2()
	elseif arg_23_0.energyCountDown > 0 and arg_23_0.energyEffect_ then
		arg_23_0.energyCountDown = arg_23_0.energyCountDown - 1

		arg_23_0:checkEnergyTargets()
	end

	if arg_23_0.energyCureHp > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_23_0 = arg_23_0:getEnergyCureTarget()

		if var_23_0 then
			local var_23_1 = arg_23_0:createAttackUnits({
				var_23_0
			}, var_0_37)

			for iter_23_0, iter_23_1 in ipairs(var_23_1) do
				table.insert(arg_23_0.moveAttackUnits_, iter_23_1)
				table.insert(arg_23_0.records_.special_units, iter_23_1)
			end
		end
	end
end

function var_0_6.energySubSkill2(arg_24_0)
	arg_24_0.energyEffect_:stop()

	arg_24_0.energyEffect_ = nil

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_24_0.skinSkillID_ ~= var_0_39 or not var_0_47 then
			local var_24_0 = var_0_36
		end

		local var_24_1 = arg_24_0:createAttackUnits(arg_24_0.energyTargets, var_0_36)

		for iter_24_0, iter_24_1 in ipairs(var_24_1) do
			table.insert(arg_24_0.moveAttackUnits_, iter_24_1)
			table.insert(arg_24_0.records_.special_units, iter_24_1)
		end
	end

	arg_24_0.energyCountDown = 0
	arg_24_0.energyTargets = nil
	arg_24_0.energyPosX_ = 0
end

function var_0_6.energySubSkill1(arg_25_0)
	arg_25_0.energyEffect_:stop()

	arg_25_0.energyEffect_ = nil

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_25_0 = {}

		for iter_25_0, iter_25_1 in pairs(arg_25_0.sideTeam_) do
			if not iter_25_1:isDeath() and not iter_25_1:isAffected() then
				table.insert(var_25_0, iter_25_1)
			end
		end

		if arg_25_0.skinSkillID_ ~= var_0_39 or not var_0_46 then
			local var_25_1 = var_0_35
		end

		local var_25_2 = arg_25_0:createAttackUnits(var_25_0, var_0_35)

		for iter_25_2, iter_25_3 in ipairs(var_25_2) do
			table.insert(arg_25_0.moveAttackUnits_, iter_25_3)
			table.insert(arg_25_0.records_.special_units, iter_25_3)
		end
	end

	arg_25_0.energyCountDown = 0
	arg_25_0.energyTargets = nil
	arg_25_0.energyPosX_ = 0
end

function var_0_6.checkEnergyTargets(arg_26_0)
	if arg_26_0.energyTargets and arg_26_0.energyEffect_ then
		local var_26_0 = arg_26_0:getEnemiesInEnergyEffect()

		for iter_26_0, iter_26_1 in pairs(arg_26_0.sideTeam_) do
			if not iter_26_1:isDeath() and not iter_26_1:isAffected() and (arg_26_0.energyCountDown > 0 and math.abs(iter_26_1:getX() - arg_26_0.energyPosX_) <= var_0_3:scope(var_0_33) and not var_0_0.table.indexof(arg_26_0.energyTargets, iter_26_1) or math.abs(iter_26_1:getX() - arg_26_0.energyPosX_) > var_0_3:scope(var_0_33) and var_0_0.table.indexof(arg_26_0.energyTargets, iter_26_1)) then
				arg_26_0:energySubSkill1()

				break
			end
		end
	end
end

function var_0_6.getEnemiesInEnergyEffect(arg_27_0)
	local var_27_0 = {}

	for iter_27_0, iter_27_1 in pairs(arg_27_0.sideTeam_) do
		if math.abs(iter_27_1:getX() - arg_27_0.energyPosX_) <= var_0_3:scope(var_0_33) then
			table.insert(var_27_0, iter_27_1)
		end
	end

	return var_27_0
end

function var_0_6.applySingleUnit(arg_28_0, arg_28_1)
	var_0_6.super.applySingleUnit(arg_28_0, arg_28_1)

	if arg_28_1.skillID == var_0_33 or arg_28_1.skillID == var_0_45 then
		if arg_28_0.energyEffect_ then
			arg_28_0:energySubSkill2()
		end

		arg_28_0.energyPosX_ = arg_28_1.target:getX()
		arg_28_0.energyCountDown = var_0_34

		if not arg_28_0.energyEffect_ then
			local var_28_0 = arg_28_0.skinSkillID_ == var_0_39 and var_0_45 or var_0_33
			local var_28_1, var_28_2 = var_0_3:areaResource(var_28_0)

			if var_28_1 and var_28_1 ~= "" and var_28_2 and var_28_2 ~= "" then
				arg_28_0.energyEffect_ = var_0_1.ctx.battle.getSpine(var_28_0, "area", arg_28_0:getScale())

				arg_28_0.energyEffect_:addTo(var_0_1.ctx.battle.unitBottomLayer)
			end
		end

		if arg_28_0.energyEffect_ then
			arg_28_0.energyEffect_:pos(arg_28_0.energyPosX_, arg_28_1.target:getY())
			arg_28_0.energyEffect_:playRepeat()
		end
	end
end

function var_0_6.selectTargetByTypeD1(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = 0
	local var_29_1

	for iter_29_0, iter_29_1 in pairs(arg_29_0.sideTeam_) do
		if not iter_29_1:isDeath() and not iter_29_1:isAffected() and var_29_0 <= iter_29_1:getAttrByType(var_0_2.AttributeType.AGILE) then
			var_29_0 = iter_29_1:getAttrByType(var_0_2.AttributeType.AGILE)
			var_29_1 = iter_29_1
		end
	end

	if arg_29_1 == arg_29_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_29_1 == var_0_40 then
		arg_29_0.greenTarget1 = var_29_1
	end

	return {
		var_29_1
	}
end

function var_0_6.selectTargetByTypeD4(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = 0
	local var_30_1
	local var_30_2 = {}

	for iter_30_0, iter_30_1 in pairs(arg_30_0.sideTeam_) do
		if not iter_30_1:isDeath() and not iter_30_1:isAffected() and var_30_0 <= iter_30_1:getAttrByType(var_0_2.AttributeType.AGILE) then
			var_30_0 = iter_30_1:getAttrByType(var_0_2.AttributeType.AGILE)
			var_30_1 = iter_30_1
		end
	end

	for iter_30_2, iter_30_3 in pairs(arg_30_0.sideTeam_) do
		if not iter_30_3:isDeath() and not iter_30_3:isAffected() and math.abs(iter_30_3:getX() - var_30_1:getX()) <= var_0_3:scope(arg_30_1) then
			table.insert(var_30_2, iter_30_3)
		end
	end

	arg_30_0.energyTargets = var_30_2

	return var_30_2
end

return var_0_6
