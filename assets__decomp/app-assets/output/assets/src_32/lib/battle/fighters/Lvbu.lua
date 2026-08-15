local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lvbu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_9 = var_0_2.tables.skinSkill
local var_0_10 = var_0_2.tables.cabinetSkillTable
local var_0_11 = 0.002
local var_0_12 = 0.001
local var_0_13 = 10000110
local var_0_14 = 40010292
local var_0_15 = 0.3
local var_0_16 = 25
local var_0_17 = 10000503
local var_0_18 = 80010041
local var_0_19 = 40010705
local var_0_20 = 40010706
local var_0_21 = 450
local var_0_22 = 0.04
local var_0_23 = 80120041
local var_0_24 = 10000966
local var_0_25 = 10000967
local var_0_26 = 10000501
local var_0_27 = 10001035
local var_0_28 = 20050004
local var_0_29 = 20050005
local var_0_30 = 20050006
local var_0_31 = 40011375
local var_0_32 = 40011376
local var_0_33 = 40011377
local var_0_34 = 40011378
local var_0_35 = 40011383
local var_0_36 = 80220041
local var_0_37 = 40011552
local var_0_38 = var_0_2.tables.elementEquip
local var_0_39 = 20001463
local var_0_40 = 10002224
local var_0_41 = {
	40012370,
	40012371
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("move_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.bloodyTarget_ = nil
	arg_2_0.isEnergyBuff_ = false
	arg_2_0.purpleSkillCount_ = nil
	arg_2_0.blueReHp_ = 0
	arg_2_0.isAddSkinBuff_ = false
	arg_2_0.isSkinHide_ = false
	arg_2_0.moveHarmCache_ = {}
	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel1 = 0
	arg_2_0.extraSkillLevel2 = 0
	arg_2_0.extraSkillLevel3 = 0
	arg_2_0.extraSkillRate1 = 0
	arg_2_0.extraSkillRate2 = 0
	arg_2_0.extraSkillRate3 = 0
	arg_2_0.skinMarryBuffOn = false
	arg_2_0.partnerKiller_ = nil
	arg_2_0.records_.target_count = {}
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.target == arg_3_0 and var_0_7:father(arg_3_1.skillID) == arg_3_0:getEnergySkillID() then
		arg_3_0.isEnergyBuff_ = true
	end

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_3_0.leftInterval_ = 0
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_1.skillID == var_0_26 and arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_23 then
		arg_3_0:skinSkill2(arg_3_1.target)
	end

	if arg_3_1.skillID == var_0_26 and arg_3_0.extraSkillLevel1 > 0 then
		local var_3_0 = var_0_8.new({
			tableID = var_0_31,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0.extraSkillLevel1,
			skillID = var_0_26,
			fighter = arg_3_0,
			target = arg_3_1.target,
			manualRevise = arg_3_0.extraSkillRate1
		})

		arg_3_1.target:addBuffs({
			var_3_0
		})
	end

	if arg_3_0:hasElementEquipByID(var_0_39) then
		local var_3_1 = arg_3_1.target

		if var_3_1:getBuffByID(var_0_41[1]) then
			var_3_1:removeBuffByID(var_0_41[1])
		end

		if var_3_1:getBuffByID(var_0_41[2]) then
			var_3_1:removeBuffByID(var_0_41[2])
		end

		local var_3_2 = var_0_39
		local var_3_3 = var_0_38:battleAttr(var_3_2, arg_3_0:getElementEquipLevelByID(var_3_2))
		local var_3_4 = arg_3_0.hero_:getElementEquipActiveRate(var_3_2)
		local var_3_5 = arg_3_0:createNewBuffs(var_0_41, var_3_1, var_0_40)
		local var_3_6 = math.floor((1 - var_3_1:getHp() / var_3_1:getHpLimit()) * 10)

		for iter_3_0, iter_3_1 in ipairs(var_3_5) do
			if iter_3_1:getAttrType() == var_0_2.AttributeType.AP then
				iter_3_1.manualRevise = -math.abs(var_3_3 * var_3_6 * var_3_1:getAP() * var_3_4)
			elseif iter_3_1:getAttrType() == var_0_2.AttributeType.AD then
				iter_3_1.manualRevise = -math.abs(var_3_3 * var_3_6 * var_3_1:getAD() * var_3_4)
			end
		end

		var_3_1:addBuffs(var_3_5)
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0.skinSkillID_ == var_0_36 and not arg_4_0.skinMarryBuffOn then
		local var_4_0 = {}
		local var_4_1 = {}

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
			if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1 ~= arg_4_0 then
				table.insert(var_4_0, iter_4_1)
				table.insert(var_4_1, 1)
			end
		end

		if next(var_4_0) then
			local var_4_2 = 1

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				var_4_2 = arg_4_0.targetCount_[tostring(var_0_1.ctx.battle.count)] or 1
			else
				var_4_2 = var_0_2.weightedChoise(var_4_1)
				arg_4_0.records_.target_count[tostring(var_0_1.ctx.battle.count)] = var_4_2
			end

			local var_4_3 = var_4_0[var_4_2]

			if var_4_3 then
				var_4_3:addBuffs({
					var_0_8.new({
						tableID = var_0_37,
						start = var_0_1.ctx.battle.count,
						level = arg_4_0:getLevel(),
						skillID = var_0_36,
						fighter = arg_4_0,
						target = var_4_3
					})
				})
			end
		end

		arg_4_0.skinMarryBuffOn = true
	end

	if not arg_4_0.isAddSkinBuff_ and arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_18 then
		arg_4_0.isAddSkinBuff_ = true

		local var_4_4 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
		local var_4_5 = arg_4_0:newBuffs({
			var_0_19
		}, arg_4_0:getEnergySkillID(), var_4_4, arg_4_0)

		arg_4_0:addBuffs(var_4_5)
	end

	if not arg_4_0.extraSkillJudge then
		arg_4_0.extraSkillJudge = true

		local var_4_6 = arg_4_0.hero_:skillBook()

		arg_4_0.extraSkillLevel1 = var_4_6[tostring(var_0_28)] or 0
		arg_4_0.extraSkillLevel2 = var_4_6[tostring(var_0_29)] or 0
		arg_4_0.extraSkillLevel3 = var_4_6[tostring(var_0_30)] or 0
		arg_4_0.extraSkillRate1 = -arg_4_0.extraSkillLevel1 * var_0_10:attrValues(var_0_28) / var_0_2.PERCENT_BASE
		arg_4_0.extraSkillRate2 = arg_4_0.extraSkillLevel2 * var_0_10:attrValues(var_0_29) / var_0_2.PERCENT_BASE
		arg_4_0.extraSkillRate3 = arg_4_0.extraSkillLevel3 * var_0_10:attrValues(var_0_30) / var_0_2.PERCENT_BASE

		if arg_4_0.extraSkillLevel3 > 0 then
			local var_4_7 = var_0_8.new({
				tableID = var_0_34,
				start = var_0_1.ctx.battle.count,
				level = arg_4_0.extraSkillLevel3,
				skillID = arg_4_0:getPugongID(),
				fighter = arg_4_0,
				target = arg_4_0
			})
			local var_4_8 = var_0_8.new({
				tableID = var_0_35,
				start = var_0_1.ctx.battle.count,
				level = arg_4_0.extraSkillLevel3,
				skillID = arg_4_0:getPugongID(),
				fighter = arg_4_0,
				target = arg_4_0
			})

			arg_4_0:addBuffs({
				var_4_7
			})
			arg_4_0:addBuffs({
				var_4_8
			})
		end
	end

	if arg_4_0.isEnergyBuff_ and not arg_4_0:isHasBuffByID(var_0_14) then
		arg_4_0.isEnergyBuff_ = false
	end

	if arg_4_0.purpleSkillCount_ then
		arg_4_0.purpleSkillCount_ = arg_4_0.purpleSkillCount_ - 1

		if arg_4_0.purpleSkillCount_ <= 0 then
			arg_4_0.purpleSkillCount_ = nil
		end
	end

	if arg_4_0:isDeath() then
		return
	end

	arg_4_0:purpleSkill()
	arg_4_0:energySkill()

	if arg_4_0.isSkinHide_ then
		arg_4_0:updateSkinSkill()
	end
end

function var_0_3.purpleSkill(arg_5_0)
	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_5_0.bloodyTarget_ and var_0_1.ctx.battle.count % 10 == 0 and not arg_5_0:isCreatingUnits() then
		local var_5_0
		local var_5_1

		if arg_5_0.partnerKiller_ and not arg_5_0.partnerKiller_:isDeath() and not arg_5_0.partnerKiller_:isAffected() and arg_5_0.partnerKiller_:getTeamType() ~= arg_5_0:getTeamType() then
			var_5_1 = arg_5_0.partnerKiller_
			arg_5_0.partnerKiller_ = nil
		else
			for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
				if not iter_5_1:isDeath() and (not iter_5_1:isAffected() or not not iter_5_1:isInvisible()) and iter_5_1:getSummonType() == var_0_2.summonMonsterType.None then
					local var_5_2 = iter_5_1:getHp() / iter_5_1:getHpLimit()

					if var_5_2 <= var_0_15 and (not var_5_0 or var_5_2 < var_5_0) then
						var_5_0 = var_5_2
						var_5_1 = iter_5_1
					end
				end
			end
		end

		if var_5_1 then
			arg_5_0.bloodyTarget_ = var_5_1

			arg_5_0:removeNegativeBuff()

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_3 = arg_5_0:createAttackUnits({
					arg_5_0
				}, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				for iter_5_2, iter_5_3 in ipairs(var_5_3) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
					table.insert(arg_5_0.records_.special_units, iter_5_3)
				end
			end
		end
	elseif arg_5_0.bloodyTarget_ and (arg_5_0.bloodyTarget_:isAffected() and not arg_5_0.bloodyTarget_:isInvisible() or arg_5_0.bloodyTarget_:isDeath()) and (not arg_5_0.unitSkills_ or arg_5_0.unitSkills_.rootID_ ~= arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) then
		arg_5_0.bloodyTarget_ = nil

		arg_5_0:removePurpleBuff()
	end
end

function var_0_3.energySkill(arg_6_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_6_0.isEnergyBuff_ then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0:getInfoByKey("move_info")) do
			local var_6_0 = iter_6_1.fighter
			local var_6_1 = math.abs(iter_6_1.x or 0)

			if var_6_0:getTeamType() ~= arg_6_0:getTeamType() and not var_6_0:isDeath() and (not var_6_0:isAffected() or var_6_0:isInvisible()) and var_6_1 >= 100 then
				local var_6_2 = math.min(math.ceil(var_6_1 * 0.01), 10) * var_0_16 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

				if not arg_6_0.moveHarmCache_[var_6_0] then
					arg_6_0.moveHarmCache_[var_6_0] = var_6_2
				else
					arg_6_0.moveHarmCache_[var_6_0] = arg_6_0.moveHarmCache_[var_6_0] + var_6_2
				end

				local var_6_3 = {
					var_6_0
				}
				local var_6_4 = arg_6_0:createAttackUnits(var_6_3, var_0_13)

				for iter_6_2, iter_6_3 in ipairs(var_6_4) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
					table.insert(arg_6_0.records_.special_units, iter_6_3)
				end
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and (not iter_7_1:isAffected() or not not iter_7_1:isInvisible()) then
			table.insert(var_7_0, iter_7_1)
		end
	end

	return var_7_0
end

function var_0_3.selectTargetByTypeD2(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}
	local var_8_1 = var_0_7:scope(arg_8_1) / 2
	local var_8_2

	if not arg_8_0.bloodyTarget_ then
		var_8_2 = unpack(var_0_4.B1(arg_8_0, arg_8_1))
	else
		var_8_2 = arg_8_0.bloodyTarget_
	end

	if not var_8_2 then
		return {}
	end

	local var_8_3, var_8_4 = var_8_2:getPos()
	local var_8_5, var_8_6 = var_0_4.getTeam(arg_8_0)

	table.insert(var_8_0, var_8_2)

	for iter_8_0, iter_8_1 in ipairs(var_8_6) do
		local var_8_7, var_8_8 = iter_8_1:getPos()

		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and var_8_1 >= math.abs(var_8_3 - var_8_7) and iter_8_1 ~= var_8_2 then
			table.insert(var_8_0, iter_8_1)
		end
	end

	return var_8_0
end

function var_0_3.getTargets(arg_9_0, arg_9_1, arg_9_2)
	if (arg_9_1 == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_9_1 == var_0_27) and arg_9_0.bloodyTarget_ and not arg_9_0.bloodyTarget_:isDeath() and (not arg_9_0.bloodyTarget_:isAffected() or not not arg_9_0.bloodyTarget_:isInvisible()) then
		return {
			arg_9_0.bloodyTarget_
		}
	end

	local var_9_0 = {}
	local var_9_1 = var_0_7:selectType(arg_9_1)

	if not arg_9_0.bloodyTarget_ and arg_9_0:getForceTarget() and not arg_9_0:getForceTarget():isDeath() then
		if var_9_1 == "C11" then
			local var_9_2 = arg_9_0:getForceTarget()

			if (arg_9_2.iniX_ < var_9_2:getX() and var_9_2:getX() <= arg_9_2:getX() or arg_9_2.iniX_ > var_9_2:getX() and var_9_2:getX() >= arg_9_2:getX()) and not arg_9_2.targets[var_9_2.fighterIndex] then
				arg_9_2.targets[var_9_2.fighterIndex] = var_9_2

				return {
					var_9_2
				}
			end

			return {}
		end

		return {
			arg_9_0:getForceTarget()
		}
	end

	if arg_9_0["selectTargetByType" .. var_9_1] then
		var_9_0 = arg_9_0["selectTargetByType" .. var_9_1](arg_9_0, arg_9_1, arg_9_2)
	else
		var_9_0 = var_0_4[var_9_1](arg_9_0, arg_9_1, arg_9_2)
	end

	return var_9_0
end

function var_0_3.deathFeedback(arg_10_0, arg_10_1)
	if arg_10_1.killer_ then
		local var_10_0 = arg_10_1:getBuffByID(var_0_37)

		if var_10_0 and var_10_0.fighter == arg_10_0 then
			arg_10_0.partnerKiller_ = arg_10_1.killer_
		end

		local var_10_1 = 1

		if arg_10_1.killer_ and arg_10_1.killer_ == arg_10_0 then
			var_10_1 = 2
		end

		if arg_10_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_10_1 = var_10_1 * var_0_11 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		else
			var_10_1 = var_10_1 * var_0_12 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		end

		arg_10_0.blueReHp_ = arg_10_0:getDCureRate() * var_10_1 * math.min(arg_10_0:getHpLimit(), arg_10_1:getHpLimit())

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_10_2 = arg_10_0:createAttackUnits({
				arg_10_0
			}, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			for iter_10_0, iter_10_1 in ipairs(var_10_2) do
				table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
				table.insert(arg_10_0.records_.special_units, iter_10_1)
			end
		end
	end

	if arg_10_0.bloodyTarget_ and arg_10_1 == arg_10_0.bloodyTarget_ and (not arg_10_0.unitSkills_ or arg_10_0.unitSkills_.rootID_ ~= arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) then
		arg_10_0.bloodyTarget_ = nil

		arg_10_0:removePurpleBuff()
	end

	if arg_10_1:getTeamType() == arg_10_0:getTeamType() and arg_10_1:getSummonType() == var_0_2.summonMonsterType.None and arg_10_0.extraSkillLevel3 > 0 then
		local var_10_3 = var_0_8.new({
			tableID = var_0_32,
			start = var_0_1.ctx.battle.count,
			level = arg_10_0.extraSkillLevel3,
			skillID = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
			fighter = arg_10_0,
			target = arg_10_0,
			manualRevise = arg_10_1:getHuJia() * arg_10_0.extraSkillRate3
		})

		arg_10_0:addBuffs({
			var_10_3
		})

		local var_10_4 = var_0_8.new({
			tableID = var_0_33,
			start = var_0_1.ctx.battle.count,
			level = arg_10_0.extraSkillLevel3,
			skillID = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
			fighter = arg_10_0,
			target = arg_10_0,
			manualRevise = arg_10_1:getMoKang() * arg_10_0.extraSkillRate3
		})

		arg_10_0:addBuffs({
			var_10_4
		})
	end
end

function var_0_3.getForceTarget(arg_11_0)
	if arg_11_0.bloodyTarget_ and not arg_11_0.bloodyTarget_:isDeath() and (not arg_11_0.bloodyTarget_:isAffected() or not not arg_11_0.bloodyTarget_:isInvisible()) then
		return arg_11_0.bloodyTarget_
	end

	return var_0_3.super.getForceTarget(arg_11_0)
end

function var_0_3.removePurpleBuff(arg_12_0)
	local var_12_0 = var_0_7:buffs(arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

	for iter_12_0, iter_12_1 in ipairs(var_12_0) do
		arg_12_0:removeBuffByID(iter_12_1)
	end
end

function var_0_3.updateUnitDataByFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
	if arg_13_1.skillID == var_0_13 then
		arg_13_4 = (arg_13_0.moveHarmCache_[arg_13_1.target] or 0) * arg_13_1.target:getADJianShang()
		arg_13_0.moveHarmCache_[arg_13_1.target] = nil
	elseif arg_13_1.skillID == arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_13_5 = arg_13_5 + arg_13_0.blueReHp_
	elseif arg_13_4 > 0 and (arg_13_1.skillID == var_0_27 or arg_13_1.skillID == arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)) and arg_13_0.extraSkillLevel2 > 0 then
		arg_13_4 = arg_13_4 + arg_13_0:getHpLimit() * arg_13_0.extraSkillRate2
	end

	return var_0_3.super.updateUnitDataByFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
end

function var_0_3.isBreakImmortal(arg_14_0)
	if arg_14_0.purpleSkillCount_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_14_0)
	end
end

function var_0_3.removeNegativeBuff(arg_15_0)
	for iter_15_0 = #arg_15_0.buffs_, 1, -1 do
		local var_15_0 = arg_15_0.buffs_[iter_15_0]

		if var_15_0 and var_15_0.fighter:getTeamType() ~= arg_15_0:getTeamType() and var_0_6:isLimit(var_15_0:getTableID()) == 1 then
			arg_15_0:removeBuffs(var_15_0)
		end
	end
end

function var_0_3.newBuffs(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4)
	local var_16_0 = {}

	for iter_16_0, iter_16_1 in ipairs(arg_16_1) do
		local var_16_1 = var_0_8.new({
			tableID = iter_16_1,
			start = var_0_1.ctx.battle.count,
			level = arg_16_3,
			skillID = arg_16_2,
			fighter = arg_16_0,
			target = arg_16_4
		})

		table.insert(var_16_0, var_16_1)
	end

	return var_16_0
end

function var_0_3.neverDieFeedBack(arg_17_0, arg_17_1)
	arg_17_1:updateHp(1)

	local var_17_0 = arg_17_0:getBuffs()

	for iter_17_0 = #var_17_0, 1, -1 do
		local var_17_1 = var_17_0[iter_17_0]

		if var_17_1 and var_17_1.fighter:getTeamType() ~= arg_17_0:getTeamType() then
			arg_17_0:removeBuffs(var_17_1)
		end
	end

	local var_17_2 = arg_17_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
	local var_17_3 = arg_17_0:newBuffs({
		var_0_20
	}, arg_17_0:getEnergySkillID(), var_17_2, arg_17_0)

	arg_17_0:addBuffs(var_17_3)

	arg_17_0.isSkinHide_ = true
	arg_17_0.skinHideCount_ = var_0_1.ctx.battle.count
end

function var_0_3.updateSkinSkill(arg_18_0)
	if var_0_1.ctx.battle.count - arg_18_0.skinHideCount_ >= var_0_21 then
		arg_18_0:removeBuffByID(var_0_20)

		arg_18_0.isSkinHide_ = false

		return
	end

	if (var_0_1.ctx.battle.count - arg_18_0.skinHideCount_) % 30 == 0 then
		local var_18_0 = arg_18_0:getHpLimit() * arg_18_0:getDCureRate() * var_0_22

		arg_18_0:updateHp(arg_18_0:getHp() + var_18_0)
	end

	for iter_18_0, iter_18_1 in ipairs(arg_18_0.selfTeam_) do
		if not iter_18_1:isDeath() and iter_18_1 ~= arg_18_0 and iter_18_1:getSummonType() == var_0_2.summonMonsterType.None then
			return
		end
	end

	arg_18_0:removeBuffByID(var_0_20)

	arg_18_0.isSkinHide_ = false
end

function var_0_3.skinSkill2(arg_19_0, arg_19_1)
	local var_19_0 = arg_19_0:createAttackUnits({
		arg_19_1
	}, var_0_25)

	for iter_19_0, iter_19_1 in ipairs(var_19_0) do
		table.insert(arg_19_0.moveAttackUnits_, iter_19_1)
		table.insert(arg_19_0.records_.special_units, iter_19_1)
	end

	local var_19_1 = arg_19_0:createAttackUnits({
		arg_19_0
	}, var_0_24)

	for iter_19_2, iter_19_3 in ipairs(var_19_1) do
		table.insert(arg_19_0.moveAttackUnits_, iter_19_3)
		table.insert(arg_19_0.records_.special_units, iter_19_3)
	end
end

function var_0_3.setupReport(arg_20_0, arg_20_1)
	var_0_3.super.setupReport(arg_20_0, arg_20_1)

	arg_20_0.targetCount_ = arg_20_1.target_count
end

function var_0_3.writeReport(arg_21_0)
	local var_21_0 = var_0_3.super.writeReport(arg_21_0)

	var_21_0.target_count = arg_21_0.records_.target_count

	return var_21_0
end

return var_0_3
