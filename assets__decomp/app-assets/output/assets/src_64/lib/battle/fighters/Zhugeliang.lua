local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhugeliang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_9 = {
	wind = 50010144,
	water = 50030144,
	thunder = 50050144,
	fire = 50040144,
	dark = 50020144
}
local var_0_10 = {
	wind = 20010144,
	water = 20030144,
	thunder = 20050144,
	fire = 20040144,
	dark = 20020144
}
local var_0_11 = {
	wind = 30010144,
	water = 30030144,
	thunder = 30050144,
	fire = 30040144,
	dark = 30020144
}
local var_0_12 = {
	wind = 40010144,
	water = 40030144,
	thunder = 40050144,
	fire = 40040144,
	dark = 40020144
}
local var_0_13 = {
	wind = 60010144,
	water = 60030144,
	thunder = 60050144,
	fire = 60040144,
	dark = 60020144
}
local var_0_14 = 10000653
local var_0_15 = 40010623
local var_0_16 = 1
local var_0_17 = 0
local var_0_18 = 0
local var_0_19 = 50
local var_0_20 = 10000806
local var_0_21 = 10001126
local var_0_22 = 2
local var_0_23 = 40011443
local var_0_24 = 120
local var_0_25 = 10001341
local var_0_26 = 1
local var_0_27 = 10
local var_0_28 = 10000654
local var_0_29 = 10000655
local var_0_30 = 0.15
local var_0_31 = {
	first = 0.005,
	second = 0.01,
	third = 0.02
}
local var_0_32 = 300
local var_0_33 = 40010619
local var_0_34 = 10000656
local var_0_35 = 0
local var_0_36 = 0.003
local var_0_37 = {
	first = 0.0025,
	second = 0.005,
	third = 0.012
}
local var_0_38 = 40011221
local var_0_39 = 10001120
local var_0_40 = 300
local var_0_41 = 300
local var_0_42 = 80000272
local var_0_43 = 0.006
local var_0_44 = 80000273
local var_0_45 = 10000869
local var_0_46 = 10000868
local var_0_47 = 300
local var_0_48 = 90
local var_0_49 = 0
local var_0_50 = -0.5
local var_0_51 = 0
local var_0_52 = 6
local var_0_53 = 10000804
local var_0_54 = 10000805
local var_0_55 = 3
local var_0_56 = {
	wind = 20060002,
	water = 20060005,
	thunder = 20060006,
	fire = 20060004,
	dark = 20060003
}
local var_0_57 = 0.1
local var_0_58 = 0.1
local var_0_59 = 10001569
local var_0_60 = 0.2
local var_0_61 = 40011643
local var_0_62 = 15
local var_0_63 = 0.15
local var_0_64 = math.max
local var_0_65 = var_0_2.tables.elementEquip
local var_0_66 = 20001476
local var_0_67 = 10

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isRestartInit_ = false
	arg_1_0.energyDarkTargets_ = {}
	arg_1_0.greenWindTarget_ = {}
	arg_1_0.greenDarkHp_ = 0
	arg_1_0.lessHeros_ = 0
	arg_1_0.blueWindTargets_ = {}
	arg_1_0.purpleWindCD_ = 0
	arg_1_0.isPurpleWindAttack_ = false
	arg_1_0.purpleDarkExtraHpLimit_ = 0
	arg_1_0.energyFireSacrificeHp = 0
	arg_1_0.isEnergyType_ = false
	arg_1_0.greenFireTargets_ = {}
	arg_1_0.waterMonsters_ = {}
	arg_1_0.smallWaterMonsters_ = {}
	arg_1_0.blueWaterFuseJudge_ = false
	arg_1_0.blueFireCount = 0
	arg_1_0.blueFireTempTargets = {}
	arg_1_0.purpleFireBuffLocks = {}
	arg_1_0.energyOverdraftAllies = {}
	arg_1_0.energyThunderCD = 0
	arg_1_0.nThunderCounts = 0
	arg_1_0.extraSkillBookLevel = {}
	arg_1_0.extraSkillTrigger = {}
	arg_1_0.records_.fire_hit = {}
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_0:getSkillLevelByID(var_0_12.thunder)

	if var_2_0 > 0 then
		arg_2_0:updateEnergyBy(3.2 * var_2_0)
	end

	local var_2_1 = {
		var_0_9,
		var_0_10,
		var_0_11,
		var_0_12,
		var_0_13
	}

	for iter_2_0, iter_2_1 in ipairs(var_2_1) do
		for iter_2_2, iter_2_3 in pairs(iter_2_1) do
			if arg_2_0:getSkillLevelByID(iter_2_3) > 0 then
				arg_2_0.extraSkillTrigger[iter_2_2] = (arg_2_0.extraSkillTrigger[iter_2_2] or 0) + 1
			end
		end
	end

	local var_2_2 = arg_2_0.hero_:skillBook()

	for iter_2_4, iter_2_5 in pairs(arg_2_0.extraSkillTrigger) do
		if iter_2_5 > 1 then
			arg_2_0.extraSkillBookLevel[iter_2_4] = var_2_2[tostring(var_0_56[iter_2_4])] or 0
		end
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	arg_3_0.isPurpleWindAttack_ = false

	if arg_3_1.rootID_ == var_0_10.wind then
		arg_3_0.greenWindTarget_ = {}
	elseif arg_3_1.rootID_ == var_0_10.dark then
		arg_3_0.greenDarkHp_ = 0
	elseif arg_3_1.rootID_ == var_0_9.fire then
		arg_3_0.energyFireSacrificeHp = arg_3_0:getHp() - 1

		arg_3_0:updateHp(1)
	elseif arg_3_1.rootID_ == var_0_10.fire then
		arg_3_0.greenFireTargets_ = {}
	end

	if arg_3_1.rootID_ ~= arg_3_0:getPugongID() and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) == var_0_12.wind and arg_3_0.purpleWindCD_ < 1 then
		arg_3_0.lessHeros_ = arg_3_0:isSelfTeamLess()

		if arg_3_0.lessHeros_ ~= 0 then
			arg_3_0.isPurpleWindAttack_ = true
			arg_3_0.purpleWindCD_ = var_0_48
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == var_0_10.wind then
		if not arg_4_0.greenWindTarget_[arg_4_1.target] then
			arg_4_0.greenWindTarget_[arg_4_1.target] = true
		else
			arg_4_1.target:checkSkillBreak(var_0_2.BreakSkillType.AP, arg_4_1)
			arg_4_1.target:checkSkillBreak(var_0_2.BreakSkillType.AD, arg_4_1)
		end
	elseif arg_4_1.skillID == var_0_11.wind then
		table.insert(arg_4_0.blueWindTargets_, arg_4_1.target)
	elseif arg_4_1.skillID == var_0_9.dark then
		table.insert(arg_4_0.energyDarkTargets_, arg_4_1.target)
	elseif arg_4_1.skillID == var_0_9.water then
		arg_4_0.isEnergyType_ = true
	elseif arg_4_1.skillID == var_0_10.water then
		arg_4_0:summonWaters(arg_4_1.target, nil, false)
	elseif arg_4_1.skillID == var_0_46 then
		arg_4_0:summonWaters(arg_4_1.target, {
			var_0_44,
			var_0_44
		}, true, false)
		arg_4_1.target:updateHp(0)
		arg_4_1.target:die()
		arg_4_0:removeWaterMonster(arg_4_1.target)
	elseif arg_4_1.skillID == var_0_45 then
		if not arg_4_0.blueWaterFuseJudge_ then
			arg_4_0.blueWaterFuseJudge_ = true

			arg_4_0:summonWaters(arg_4_1.target, {
				var_0_42
			}, true, true)
		else
			arg_4_0.blueWaterFuseJudge_ = false
		end

		arg_4_1.target:updateHp(0)
		arg_4_1.target:die()
		arg_4_0:removeWaterMonster(arg_4_1.target, true)
	elseif arg_4_1.skillID == var_0_9.thunder and arg_4_1.target == arg_4_0 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getBuffs()) do
			if iter_4_1.fighter:getTeamType() ~= arg_4_0:getTeamType() then
				arg_4_0:removeBuffs(iter_4_1)
			end
		end

		local var_4_0 = 0

		for iter_4_2, iter_4_3 in ipairs(arg_4_0.selfTeam_) do
			if not iter_4_3:isDeath() and iter_4_3 ~= arg_4_0 then
				arg_4_0.energyOverdraftAllies[iter_4_3] = arg_4_0.energyOverdraftAllies[iter_4_3] or 500
				var_4_0 = var_4_0 + 1

				if var_4_0 >= 4 then
					break
				end
			end
		end

		arg_4_0:updateEnergyBy(var_4_0 * 250)

		arg_4_0.energyThunderCD = var_0_24
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_1.skillID ~= arg_4_0:getPugongID() and arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) == var_0_12.fire and arg_4_1.target:isHasBuffByID(var_0_38) then
		for iter_4_4, iter_4_5 in ipairs(arg_4_0.purpleFireBuffLocks) do
			if iter_4_5 == arg_4_1.target then
				table.remove(arg_4_0.purpleFireBuffLocks, iter_4_4)

				return
			end
		end

		arg_4_1.target:removeBuffByID(var_0_38)

		local var_4_1 = arg_4_0:createAttackUnits({
			arg_4_1.target
		}, var_0_39)

		for iter_4_6, iter_4_7 in ipairs(var_4_1) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
			table.insert(arg_4_0.records_.special_units, iter_4_7)
		end
	end

	if arg_4_0:hasElementEquipByID(var_0_66) then
		arg_4_0:updateEnergyBy(var_0_67)
	end
end

function var_0_3.updateEnergyByHarm(arg_5_0, arg_5_1)
	if arg_5_0:isHasBuffByID(var_0_23) then
		return
	else
		var_0_3.super.updateEnergyByHarm(arg_5_0, arg_5_1)
	end
end

function var_0_3.removeWaterMonster(arg_6_0, arg_6_1, arg_6_2)
	if not arg_6_2 then
		for iter_6_0 = #arg_6_0.waterMonsters_, 1, -1 do
			if arg_6_0.waterMonsters_[iter_6_0].fighter and arg_6_0.waterMonsters_[iter_6_0].fighter == arg_6_1 then
				table.remove(arg_6_0.waterMonsters_, iter_6_0)

				break
			end
		end
	else
		for iter_6_1 = #arg_6_0.smallWaterMonsters_, 1, -1 do
			if arg_6_0.smallWaterMonsters_[iter_6_1].fighter and arg_6_0.smallWaterMonsters_[iter_6_1].fighter == arg_6_1 then
				table.remove(arg_6_0.smallWaterMonsters_, iter_6_1)

				break
			end
		end
	end
end

function var_0_3.updateUnitInfoBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	if arg_7_2 and arg_7_1.target == arg_7_0 and (arg_7_0.extraSkillBookLevel.water or 0) > 0 then
		local function var_7_0(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
			local var_8_0 = {}

			for iter_8_0, iter_8_1 in ipairs(arg_8_0) do
				local var_8_1 = var_0_5.new({
					skillID = 0,
					tableID = iter_8_1,
					start = var_0_1.ctx.battle.count,
					level = arg_8_3,
					fighter = arg_8_1,
					target = arg_8_2
				})

				var_8_1:setIsHit(true)
				var_8_1:setDirection(arg_8_1:getFighterModel():getFlipX())

				var_8_1.manualRevise = arg_8_2:getAttrByType(var_0_2.AttributeType.ACK_SPEED) * var_0_60 * arg_8_3

				table.insert(var_8_0, var_8_1)
			end

			return var_8_0
		end

		arg_7_0:addBuffs(var_7_0({
			var_0_61
		}, arg_7_0, arg_7_0, arg_7_0.extraSkillBookLevel.water))

		arg_7_0.___ackSpeed = nil
		arg_7_0.___attrCache[var_0_2.AttributeType.ACK_SPEED] = nil

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.waterMonsters_) do
			iter_7_1.fighter:addBuffs(var_7_0({
				var_0_61
			}, arg_7_0, iter_7_1.fighter, arg_7_0.extraSkillBookLevel.water))

			iter_7_1.fighter.___ackSpeed = nil
			iter_7_1.fighter.___attrCache[var_0_2.AttributeType.ACK_SPEED] = nil
		end

		for iter_7_2, iter_7_3 in ipairs(arg_7_0.smallWaterMonsters_) do
			iter_7_3.fighter:addBuffs(var_7_0({
				var_0_61
			}, arg_7_0, iter_7_3.fighter, arg_7_0.extraSkillBookLevel.water))

			iter_7_3.fighter.___ackSpeed = nil
			iter_7_3.fighter.___attrCache[var_0_2.AttributeType.ACK_SPEED] = nil
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_1.target == arg_9_0 and arg_9_0:getSkillLevelByID(var_0_12.thunder) > 0 then
		arg_9_7 = math.max(arg_9_7, -50)
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_0 = arg_10_1.skillID

	if var_10_0 == var_0_28 then
		arg_10_0.greenDarkHp_ = arg_10_0.greenDarkHp_ + arg_10_4
	elseif var_10_0 == var_0_29 then
		arg_10_4 = arg_10_4 + arg_10_0.greenDarkHp_
	end

	if arg_10_0.isPurpleWindAttack_ then
		arg_10_7 = arg_10_7 + (var_0_49 + var_0_50 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)) * arg_10_0.lessHeros_
	end

	if arg_10_4 > 0 and var_10_0 == var_0_21 then
		arg_10_4 = arg_10_4 + arg_10_0.energyFireSacrificeHp * var_0_16
	elseif arg_10_4 > 0 and var_10_0 == var_0_10.fire then
		if arg_10_0.greenFireTargets_[arg_10_1.target] then
			arg_10_0.greenFireTargets_[arg_10_1.target] = arg_10_0.greenFireTargets_[arg_10_1.target] + var_0_30
		else
			arg_10_0.greenFireTargets_[arg_10_1.target] = var_0_30
		end

		arg_10_4 = arg_10_4 * (arg_10_0.greenFireTargets_[arg_10_1.target] + 1)
	end

	if arg_10_1.attackType == var_0_2.AttackType.AP and arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) == var_0_11.dark then
		arg_10_6 = arg_10_6 + arg_10_4 * (var_0_35 + var_0_36 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
	end

	if (arg_10_0.extraSkillBookLevel.wind or 0) > 0 and var_0_6:father(var_10_0) == var_0_9.wind and arg_10_4 > 0 then
		arg_10_4 = arg_10_4 + arg_10_4 * arg_10_0.extraSkillBookLevel.wind * var_0_57
	end

	if (arg_10_0.extraSkillBookLevel.dark or 0) > 0 and var_10_0 == var_0_59 then
		arg_10_5 = arg_10_5 + arg_10_0.extraSkillBookLevel.dark * var_0_58 * (arg_10_0:getHpLimit() - arg_10_0:getHp())
	end

	return var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
end

function var_0_3.getUnitData(arg_11_0, arg_11_1)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = var_0_3.super.getUnitData(arg_11_0, arg_11_1)

	if arg_11_1.skillID == var_0_25 then
		local var_11_6 = 1 + arg_11_0:getSkillLevelByID(var_0_10.thunder) * (arg_11_0.nThunderCounts > 9 and var_0_31.third or arg_11_0.nThunderCounts > 6 and var_0_31.second or arg_11_0.nThunderCounts > 3 and var_0_31.first or 0)

		var_11_2 = (arg_11_0:getAttrByType(var_0_2.AttributeType.AP) * var_0_26 + arg_11_0:getSkillLevelByID(var_0_9) * var_0_27) * var_11_6

		if (arg_11_0.extraSkillBookLevel.thunder or 0) > 0 then
			local var_11_7 = 0

			for iter_11_0, iter_11_1 in ipairs(arg_11_1.target:getBuffs()) do
				var_11_7 = var_11_7 + iter_11_1:getDHarm()
			end

			var_11_2 = var_11_2 + math.min(var_11_2 * arg_11_0.extraSkillBookLevel.thunder * var_0_63, var_11_7)
		end
	end

	if var_11_2 > 0 and arg_11_0:hasElementEquipByID(var_0_66) then
		local var_11_8 = var_0_66

		var_11_2 = var_11_2 * (1 + var_0_65:battleAttr(var_11_8, arg_11_0:getElementEquipLevelByID(var_11_8)) * arg_11_0.hero_:getElementEquipActiveRate(var_11_8))
	end

	arg_11_1:recordData(var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5)

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5
end

function var_0_3.canAttack(arg_12_0)
	if arg_12_0:isHasBuffByID(var_0_23) then
		return false
	else
		return var_0_3.super.canAttack(arg_12_0)
	end
end

function var_0_3.toDoPerFrames(arg_13_0)
	for iter_13_0, iter_13_1 in pairs(arg_13_0.energyOverdraftAllies) do
		if iter_13_1 > 0 and not iter_13_0:isDeath() then
			local var_13_0 = iter_13_0:getEnergy()

			if iter_13_1 < var_13_0 then
				iter_13_0:updateEnergyBy(-iter_13_1)

				arg_13_0.energyOverdraftAllies[iter_13_0] = 0
			else
				iter_13_0:updateEnergyTo(0)

				arg_13_0.energyOverdraftAllies[iter_13_0] = arg_13_0.energyOverdraftAllies[iter_13_0] - var_13_0
			end
		end
	end

	if not arg_13_0:isHasBuffByID(var_0_23) and arg_13_0.nThunderCounts ~= 0 then
		arg_13_0.nThunderCounts = 0
	end

	if arg_13_0.energyThunderCD > 0 then
		arg_13_0.energyThunderCD = arg_13_0.energyThunderCD - 1
	elseif arg_13_0:isHasBuffByID(var_0_23) then
		if arg_13_0:getEnergy() >= 150 and arg_13_0.nThunderCounts < 17 then
			arg_13_0.nThunderCounts = arg_13_0.nThunderCounts + 1

			local var_13_1 = 1 + arg_13_0:getSkillLevelByID(var_0_11.thunder) * (arg_13_0.nThunderCounts > 9 and var_0_37.third or arg_13_0.nThunderCounts > 6 and var_0_37.second or arg_13_0.nThunderCounts > 3 and var_0_37.first or 0)
			local var_13_2 = var_0_6:scope(var_0_25) * var_13_1
			local var_13_3 = arg_13_0:selectTargetByTypeB30(arg_13_0, var_0_25, var_13_2)
			local var_13_4 = 0
			local var_13_5 = 0
			local var_13_6 = 0
			local var_13_7 = 0
			local var_13_8 = 0
			local var_13_9 = 0

			for iter_13_2, iter_13_3 in ipairs(var_13_3) do
				local var_13_10 = iter_13_3:getX()
				local var_13_11 = iter_13_3:getY()

				if var_13_4 == 0 or var_13_10 < var_13_4 then
					var_13_4 = var_13_10
				end

				if var_13_5 == 0 or var_13_11 < var_13_5 then
					var_13_5 = var_13_11
				end

				if var_13_6 < var_13_10 then
					var_13_6 = var_13_10
				end

				if var_13_7 < var_13_11 then
					var_13_7 = var_13_11
				end
			end

			local var_13_12 = (var_13_4 + var_13_6) / 2
			local var_13_13 = (var_13_5 + var_13_7) / 2

			arg_13_0.thunderEffect = var_0_1.ctx.battle.getSpine(var_0_25, "area", 1)

			arg_13_0.thunderEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			arg_13_0.thunderEffect:pos(var_13_12, var_13_13)
			arg_13_0.thunderEffect:setScale(0.5 * var_13_1)
			arg_13_0.thunderEffect:playOnce()

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and #var_13_3 > 0 then
				local var_13_14 = arg_13_0:createAttackUnits(var_13_3, var_0_25)

				for iter_13_4, iter_13_5 in ipairs(var_13_14) do
					table.insert(arg_13_0.moveAttackUnits_, iter_13_5)
					table.insert(arg_13_0.records_.special_units, iter_13_5)
				end
			end

			arg_13_0.energyThunderCD = var_0_24

			arg_13_0:updateEnergyBy(-80)
		else
			arg_13_0:removeBuffByID(var_0_23)

			arg_13_0.nThunderCounts = 0
		end
	end

	arg_13_0:blueWindJudge()
	arg_13_0:energyDarkJudge()

	for iter_13_6, iter_13_7 in pairs(arg_13_0.blueFireTempTargets) do
		if not iter_13_7:isCreatingUnits() then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				iter_13_7:popFrontSkill()
			end

			table.remove(arg_13_0.blueFireTempTargets, iter_13_6)
		end
	end

	if not arg_13_0:isDeath() and arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) == var_0_11.fire then
		if arg_13_0.blueFireCount == 0 then
			local var_13_15 = arg_13_0:getBlueFireTargets()

			for iter_13_8, iter_13_9 in ipairs(var_13_15) do
				local var_13_16 = math.min(1 / (var_0_2.tables.battleConfig.buffHitParam1 * math.max(iter_13_9:getLevel() - math.max(arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), 20), 0) + var_0_2.tables.battleConfig.buffHitParam2), 1)
				local var_13_17

				if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
					var_13_17 = arg_13_0.fireHit_[tostring(var_0_1.ctx.battle.count)] or false
				else
					var_13_17 = var_0_2.weightedChoise({
						var_13_16,
						1 - var_13_16
					}) == 1
					arg_13_0.records_.fire_hit[tostring(var_0_1.ctx.battle.count)] = var_13_17
				end

				if var_13_17 then
					if not iter_13_9:isCreatingUnits() then
						if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
							iter_13_9:popFrontSkill()
						end
					else
						table.insert(arg_13_0.blueFireTempTargets, iter_13_9)
					end
				end
			end
		end

		arg_13_0.blueFireCount = arg_13_0.blueFireCount + 1

		if arg_13_0.blueFireCount > var_0_47 then
			arg_13_0.blueFireCount = 0
		end
	end

	if arg_13_0:isDeath() then
		arg_13_0:waterMonsterDie()

		return
	end

	if not arg_13_0.isRestartInit_ then
		arg_13_0.isRestartInit_ = true

		local var_13_18 = math.min(arg_13_0:getHp(), arg_13_0:getHpLimit())

		arg_13_0:updateHp(var_13_18)
	end

	if arg_13_0.purpleWindCD_ > 0 then
		arg_13_0.purpleWindCD_ = arg_13_0.purpleWindCD_ - 1
	end

	if var_0_1.ctx.battle.count % 30 < 1 and arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) == var_0_12.dark then
		local var_13_19 = var_0_51 + var_0_52 * arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		arg_13_0.purpleDarkExtraHpLimit_ = arg_13_0.purpleDarkExtraHpLimit_ - var_13_19

		arg_13_0:setTempHpLimit(arg_13_0.purpleDarkExtraHpLimit_)
	end

	if arg_13_0.isEnergyType_ and arg_13_0:getEnergySkillID() == var_0_9.water and arg_13_0:getNearestTarget() and var_0_1.ctx.battle.count % 30 < 1 then
		arg_13_0:updateEnergyTo(arg_13_0:getEnergy() - var_0_19)

		if arg_13_0:getEnergy() < 1 then
			arg_13_0.isEnergyType_ = false

			local var_13_20 = var_0_6:buffs(arg_13_0:getEnergySkillID())

			for iter_13_10, iter_13_11 in ipairs(var_13_20) do
				arg_13_0:removeBuffByID(iter_13_11)
			end
		end
	end

	if arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) == var_0_11.water and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_13_0:checkBlueWaterMonster()
	end
end

function var_0_3.getBlueFireTargets(arg_14_0)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in pairs(arg_14_0.sideTeam_) do
		if iter_14_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_14_1:isDeath() then
			table.insert(var_14_0, iter_14_1)
		end
	end

	table.sort(var_14_0, function(arg_15_0, arg_15_1)
		return math.abs(arg_14_0.fighterModel:getPosition() - arg_15_0.fighterModel:getPosition()) < math.abs(arg_14_0.fighterModel:getPosition() - arg_15_1.fighterModel:getPosition())
	end)

	local var_14_1 = {}

	for iter_14_2, iter_14_3 in ipairs(var_14_0) do
		if iter_14_2 <= 3 then
			table.insert(var_14_1, iter_14_3)
		end
	end

	return var_14_1
end

function var_0_3.waterMonsterDie(arg_16_0)
	if arg_16_0.waterMonsters_ and next(arg_16_0.waterMonsters_) then
		for iter_16_0 = #arg_16_0.waterMonsters_, 1, -1 do
			if arg_16_0.waterMonsters_[iter_16_0].fighter and not arg_16_0.waterMonsters_[iter_16_0].fighter:isDeath() then
				arg_16_0.waterMonsters_[iter_16_0].fighter:updateHp(0)
				arg_16_0.waterMonsters_[iter_16_0].fighter:die()
			end

			table.remove(arg_16_0.waterMonsters_, iter_16_0)
		end
	end

	if arg_16_0.smallWaterMonsters_ and next(arg_16_0.smallWaterMonsters_) then
		for iter_16_1 = #arg_16_0.smallWaterMonsters_, 1, -1 do
			if arg_16_0.smallWaterMonsters_[iter_16_1].fighter and not arg_16_0.smallWaterMonsters_[iter_16_1].fighter:isDeath() then
				arg_16_0.smallWaterMonsters_[iter_16_1].fighter:updateHp(0)
				arg_16_0.smallWaterMonsters_[iter_16_1].fighter:die()
			end

			table.remove(arg_16_0.smallWaterMonsters_, iter_16_1)
		end
	end
end

function var_0_3.isSelfTeamLess(arg_17_0)
	local var_17_0 = 0
	local var_17_1 = 0

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.selfTeam_) do
		if not iter_17_1:isDeath() and not iter_17_1:isAffected() and iter_17_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_17_0 = var_17_0 + 1
		end
	end

	for iter_17_2, iter_17_3 in ipairs(arg_17_0.sideTeam_) do
		if not iter_17_3:isDeath() and not iter_17_3:isAffected() and iter_17_3:getSummonType() == var_0_2.summonMonsterType.None then
			var_17_1 = var_17_1 + 1
		end
	end

	return math.max(0, var_17_1 - var_17_0)
end

function var_0_3.selectTargetByTypeD1(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = {}

	for iter_18_0, iter_18_1 in ipairs(arg_18_0.selfTeam_) do
		if not iter_18_1:isDeath() and iter_18_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_18_0, iter_18_1)
		end
	end

	if #var_18_0 >= 1 then
		local var_18_1 = arg_18_0:getTeamType() == var_0_2.TeamType.A and 1 or -1

		local function var_18_2(arg_19_0, arg_19_1)
			return arg_19_0:getX() * var_18_1 < arg_19_1:getX() * var_18_1
		end

		table.sort(var_18_0, var_18_2)

		local var_18_3 = 1

		while true do
			if var_18_0[var_18_3]:isHasBuffByID(var_0_33) then
				var_18_3 = var_18_3 + 1
			else
				return {
					var_18_0[var_18_3]
				}
			end

			if var_18_3 > #var_18_0 then
				return {}
			end
		end

		return
	end

	return {}
end

function var_0_3.selectTargetByTypeB30(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local function var_20_0(arg_21_0, arg_21_1)
		local var_21_0, var_21_1 = var_0_8.getTeam(arg_21_0)
		local var_21_2 = {}

		table.insert(var_21_2, arg_21_0)

		for iter_21_0, iter_21_1 in ipairs(var_21_0) do
			if not iter_21_1:isDeath() and not iter_21_1:isAffected() and iter_21_1 ~= arg_21_0 and arg_21_1 >= math.abs(iter_21_1:getX() - arg_21_0:getX()) then
				table.insert(var_21_2, iter_21_1)
			end
		end

		return var_21_2
	end

	local var_20_1 = {}
	local var_20_2 = 0
	local var_20_3 = arg_20_3 * 0.5
	local var_20_4, var_20_5 = var_0_8.getTeam(arg_20_1)

	for iter_20_0, iter_20_1 in ipairs(var_20_5) do
		if not iter_20_1:isDeath() and not iter_20_1:isAffected() then
			local var_20_6 = var_20_0(iter_20_1, var_20_3)

			if var_20_2 < #var_20_6 then
				var_20_1 = var_20_6
				var_20_2 = #var_20_6
			end
		end
	end

	return var_20_1
end

function var_0_3.blueWindJudge(arg_22_0)
	if not next(arg_22_0.blueWindTargets_) or var_0_1.ctx.battle.count % 10 >= 1 then
		return
	end

	for iter_22_0 = #arg_22_0.blueWindTargets_, 1, -1 do
		if arg_22_0.blueWindTargets_[iter_22_0]:isDeath() then
			table.remove(arg_22_0.blueWindTargets_, iter_22_0)
		end
	end

	if next(arg_22_0.blueWindTargets_) then
		for iter_22_1, iter_22_2 in ipairs(arg_22_0.sideTeam_) do
			if not iter_22_2:isDeath() and not iter_22_2:isAffected() then
				for iter_22_3, iter_22_4 in ipairs(arg_22_0.blueWindTargets_) do
					if math.abs(iter_22_4:getX() - iter_22_2:getX()) <= var_0_32 * 0.5 then
						if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
							local var_22_0 = arg_22_0:createAttackUnits({
								iter_22_2
							}, var_0_34)

							for iter_22_5, iter_22_6 in ipairs(var_22_0) do
								table.insert(arg_22_0.moveAttackUnits_, iter_22_6)
								table.insert(arg_22_0.records_.special_units, iter_22_6)
							end
						end

						iter_22_4:removeBuffByID(var_0_33)
						table.remove(arg_22_0.blueWindTargets_, iter_22_3)

						break
					end
				end
			end

			if not next(arg_22_0.blueWindTargets_) then
				break
			end
		end
	end
end

function var_0_3.energyDarkJudge(arg_23_0)
	if not next(arg_23_0.energyDarkTargets_) or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or var_0_1.ctx.battle.count % 30 >= 1 then
		return
	end

	for iter_23_0 = #arg_23_0.energyDarkTargets_, 1, -1 do
		local var_23_0 = arg_23_0.energyDarkTargets_[iter_23_0]

		if var_23_0:isDeath() or not var_23_0:isHasBuffByID(var_0_15) then
			table.remove(arg_23_0.energyDarkTargets_, iter_23_0)
		else
			local var_23_1 = arg_23_0:createAttackUnits({
				var_23_0
			}, var_0_14)

			for iter_23_1, iter_23_2 in ipairs(var_23_1) do
				table.insert(arg_23_0.moveAttackUnits_, iter_23_2)
				table.insert(arg_23_0.records_.special_units, iter_23_2)
			end
		end
	end
end

function var_0_3.buffAddAction(arg_24_0, arg_24_1)
	if arg_24_1:getTableID() == var_0_18 then
		arg_24_1.manualHarmRevise = arg_24_1.manualHarmRevise + arg_24_0.energyFireSacrificeHp * var_0_17
	end
end

function var_0_3.playShanbi(arg_25_0, arg_25_1)
	var_0_3.super.playShanbi(arg_25_0, arg_25_1)

	if arg_25_0.isEnergyType_ and arg_25_0:getEnergySkillID() == var_0_9.water and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_25_0 = arg_25_0:createAttackUnits({
			arg_25_1.target
		}, var_0_20)

		for iter_25_0, iter_25_1 in ipairs(var_25_0) do
			table.insert(arg_25_0.moveAttackUnits_, iter_25_1)
			table.insert(arg_25_0.records_.special_units, iter_25_1)
		end
	end
end

function var_0_3.summonWaters(arg_26_0, arg_26_1, arg_26_2, arg_26_3, arg_26_4)
	local var_26_0 = arg_26_2
	local var_26_1 = var_0_10.water

	if not var_26_0 or next(var_26_0) == nil then
		var_26_0 = var_0_6:summonMonster(var_26_1)
	end

	for iter_26_0, iter_26_1 in ipairs(var_26_0) do
		local var_26_2 = arg_26_0:getSkillLevelByID(var_26_1)
		local var_26_3 = arg_26_0.hero_:getColor()
		local var_26_4

		if arg_26_1:isBoss() then
			local var_26_5 = arg_26_1:getFlipX() == true and -1 or 1

			var_26_4 = arg_26_1:getX() + var_26_5 * 100
		else
			var_26_4 = arg_26_0:getX() < arg_26_1:getX() and arg_26_1:getX() + 100 or arg_26_1:getX() - 100
		end

		local var_26_6 = var_0_1.ctx.battle.adjustX(var_26_4, arg_26_0)
		local var_26_7 = {
			y = 230,
			x = var_26_6
		}

		if arg_26_1:avoidHeroMoveBehind() then
			var_26_7.x = var_26_7.x - arg_26_1:getFighterModel():getWidth()
		end

		arg_26_0:setSummonMonsters(iter_26_1, var_26_2, var_26_3, var_26_7, arg_26_3, arg_26_4)
	end
end

function var_0_3.setSummonMonsters(arg_27_0, arg_27_1, arg_27_2, arg_27_3, arg_27_4, arg_27_5, arg_27_6)
	local var_27_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_27_0 = arg_27_0:getSummonMonster()
	else
		local var_27_1 = var_0_4.new()

		var_27_1:populateWithTableID(arg_27_1)

		var_27_1.level_ = arg_27_2 or var_27_1.level_
		var_27_1.color_ = arg_27_3 or var_27_1.color_

		for iter_27_0, iter_27_1 in ipairs(var_27_1.skillLev_) do
			local var_27_2 = arg_27_0.hero_:getSkillLevel(iter_27_0)

			if var_27_2 and var_27_2 > 0 then
				var_27_1.skillLev_[iter_27_0] = var_0_0.clone(var_27_2)
			end
		end

		local var_27_3 = var_27_1:className()

		var_27_0 = var_0_1.ctx.battle.requireFighter(var_27_3).new({
			is_arena = arg_27_0.isInArena_
		})

		var_27_0:populateWithHero(var_27_1)
		var_27_0:initModels()
		var_27_0.fighterModel:initHeaderView(arg_27_0:getTeamType() - 1)

		var_27_0.fighterIndex = arg_27_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_27_0:setFormationDelay(0, 100)
	end

	if not var_27_0 then
		arg_27_0:summonMonstersErrorLog()
	end

	if not var_27_0 then
		return
	end

	var_27_0:setSmallType(arg_27_5)
	var_27_0:setTeamType(arg_27_0:getTeamType())

	var_27_0.summoner = arg_27_0

	var_27_0.fighterModel:pos(arg_27_4.x, arg_27_4.y)
	var_27_0:getFighterModel():flipX(arg_27_0:getTeamType() == var_0_2.TeamType.B)
	var_27_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_27_0:born()
	var_27_0:setGlobalBuffs()

	if arg_27_6 then
		local var_27_4 = arg_27_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) * var_0_43

		var_27_0:updateHp(var_27_0:getHpLimit() * var_27_4)
	else
		var_27_0:updateHp(var_27_0:getHpLimit())
	end

	local var_27_5 = {
		fighter = var_27_0,
		time = var_0_1.ctx.battle.count
	}

	if arg_27_5 then
		table.insert(arg_27_0.smallWaterMonsters_, var_27_5)
	else
		table.insert(arg_27_0.waterMonsters_, var_27_5)
	end

	local var_27_6 = var_27_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_27_6, var_27_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_27_0)
	var_0_1.ctx.battle.updateZorder()
end

function var_0_3.checkBlueWaterMonster(arg_28_0)
	if not arg_28_0:getNearestTarget() then
		return
	end

	if var_0_1.ctx.battle.count % 30 < 1 and arg_28_0.waterMonsters_ and next(arg_28_0.waterMonsters_) then
		local var_28_0 = {}
		local var_28_1 = var_0_1.ctx.battle.count

		for iter_28_0 = #arg_28_0.waterMonsters_, 1, -1 do
			local var_28_2 = arg_28_0.waterMonsters_[iter_28_0]
			local var_28_3 = var_28_2.fighter
			local var_28_4 = var_28_2.time

			if not var_28_3.isSplit and not var_28_3:isDeath() and not var_28_3:isAffected() and var_28_1 - var_28_4 >= var_0_41 then
				table.insert(var_28_0, var_28_2)
			elseif var_28_3:isDeath() then
				table.remove(arg_28_0.waterMonsters_, iter_28_0)
			end
		end

		if #var_28_0 > 0 then
			for iter_28_1 = 1, #var_28_0 do
				local var_28_5 = var_28_0[iter_28_1].fighter

				var_28_5.isSplit = true

				local var_28_6 = arg_28_0:createAttackUnits({
					var_28_5
				}, var_0_46)

				for iter_28_2, iter_28_3 in ipairs(var_28_6) do
					table.insert(arg_28_0.moveAttackUnits_, iter_28_3)
					table.insert(arg_28_0.records_.special_units, iter_28_3)
				end

				arg_28_0:checkPurpleWaterSkill({
					var_28_5
				}, var_0_53)
			end
		end
	end

	if var_0_1.ctx.battle.count % 30 < 1 and arg_28_0.smallWaterMonsters_ and next(arg_28_0.smallWaterMonsters_) then
		local var_28_7 = {}
		local var_28_8 = var_0_1.ctx.battle.count

		for iter_28_4 = #arg_28_0.smallWaterMonsters_, 1, -1 do
			local var_28_9 = arg_28_0.smallWaterMonsters_[iter_28_4]
			local var_28_10 = var_28_9.fighter
			local var_28_11 = var_28_9.time

			if not var_28_10.isFuse and not var_28_10:isDeath() and not var_28_10:isAffected() and var_28_8 - var_28_11 >= var_0_40 then
				table.insert(var_28_7, var_28_9)
			elseif var_28_10:isDeath() then
				table.remove(arg_28_0.smallWaterMonsters_, iter_28_4)
			end
		end

		if #var_28_7 > 1 then
			for iter_28_5 = 1, #var_28_7, 2 do
				if var_28_7[iter_28_5 + 1] then
					local var_28_12 = var_28_7[iter_28_5].fighter
					local var_28_13 = var_28_7[iter_28_5 + 1].fighter

					var_28_12.isFuse = true
					var_28_13.isFuse = true

					local var_28_14 = arg_28_0:createAttackUnits({
						var_28_12,
						var_28_13
					}, var_0_45)

					for iter_28_6, iter_28_7 in ipairs(var_28_14) do
						table.insert(arg_28_0.moveAttackUnits_, iter_28_7)
						table.insert(arg_28_0.records_.special_units, iter_28_7)
					end

					arg_28_0:checkPurpleWaterSkill({
						var_28_12,
						var_28_13
					}, var_0_54)
				end
			end
		end
	end
end

function var_0_3.checkPurpleWaterSkill(arg_29_0, arg_29_1, arg_29_2)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_29_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_29_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) == var_0_12.water and arg_29_1 then
		local var_29_0 = {}
		local var_29_1 = var_0_6:scope(arg_29_2) / 2

		for iter_29_0 = 1, #arg_29_1 do
			for iter_29_1, iter_29_2 in ipairs(arg_29_0.sideTeam_) do
				if not iter_29_2:isDeath() and not iter_29_2:isAffected() and var_29_1 > iter_29_2:getX() - arg_29_1[iter_29_0]:getX() then
					table.insert(var_29_0, iter_29_2)
				end
			end
		end

		local var_29_2 = arg_29_0:createAttackUnits(var_29_0, arg_29_2)

		for iter_29_3, iter_29_4 in ipairs(var_29_2) do
			table.insert(arg_29_0.moveAttackUnits_, iter_29_4)
			table.insert(arg_29_0.records_.special_units, iter_29_4)
		end
	end
end

function var_0_3.getDMP(arg_30_0)
	if arg_30_0:getEnergySkillID() == var_0_9.water then
		return arg_30_0:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE * var_0_2.PERCENT_BASE
	end

	return var_0_3.super.getDMP(arg_30_0)
end

function var_0_3.energyDecimalBase(arg_31_0)
	local var_31_0 = var_0_3.super.energyDecimalBase(arg_31_0)

	if arg_31_0:getEnergySkillID() == var_0_9.thunder then
		return var_31_0 * 0.5
	else
		return var_31_0
	end
end

function var_0_3.checkEnergySkill(arg_32_0)
	if arg_32_0.isEnergyType_ and arg_32_0:getEnergySkillID() == var_0_9.water then
		return false
	end

	if arg_32_0:getEnergySkillID() == var_0_9.thunder and arg_32_0:isHasBuffByID(var_0_23) then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_32_0)
end

function var_0_3.selectTargetByTypeD2(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = {}

	for iter_33_0, iter_33_1 in pairs(arg_33_0.sideTeam_) do
		if not iter_33_1:isDeath() and iter_33_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_33_1:isAffected() then
			table.insert(var_33_0, iter_33_1)
		end
	end

	if #var_33_0 > var_0_55 then
		for iter_33_2 = #var_33_0, var_0_55 + 1, -1 do
			table.remove(var_33_0, math.random(1, iter_33_2))
		end
	end

	arg_33_0.purpleFireBuffLocks = var_33_0

	return var_33_0
end

function var_0_3.deathFeedback(arg_34_0, arg_34_1)
	if arg_34_1:getSummonType() == var_0_2.summonMonsterType.None and (arg_34_0.extraSkillBookLevel.dark or 0) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_34_0 = arg_34_0:createAttackUnits({
			arg_34_0
		}, var_0_59)

		for iter_34_0, iter_34_1 in ipairs(var_34_0) do
			table.insert(arg_34_0.moveAttackUnits_, iter_34_1)
			table.insert(arg_34_0.records_.special_units, iter_34_1)
		end
	end
end

function var_0_3.setupReport(arg_35_0, arg_35_1)
	var_0_3.super.setupReport(arg_35_0, arg_35_1)

	arg_35_0.fireHit_ = arg_35_1.fire_hit or {}
end

function var_0_3.writeReport(arg_36_0)
	local var_36_0 = var_0_3.super.writeReport(arg_36_0)

	var_36_0.fire_hit = arg_36_0.records_.fire_hit

	return var_36_0
end

return var_0_3
