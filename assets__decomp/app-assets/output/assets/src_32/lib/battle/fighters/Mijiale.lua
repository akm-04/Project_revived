local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Mijiale", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 600
local var_0_7 = 0.25
local var_0_8 = 10000763
local var_0_9 = 10
local var_0_10 = 8
local var_0_11 = 6
local var_0_12 = 40011877
local var_0_13 = 0.15
local var_0_14 = 80010157
local var_0_15 = 80020157
local var_0_16 = 30
local var_0_17 = 10001154
local var_0_18 = 0.2
local var_0_19 = 0.5
local var_0_20 = var_0_2.tables.elementEquip
local var_0_21 = 20001437
local var_0_22 = 10002090
local var_0_23 = 20110004
local var_0_24 = 20110005
local var_0_25 = 20110006
local var_0_26 = 0.05
local var_0_27 = 5000
local var_0_28 = 30

function var_0_4.ctor(arg_1_0, arg_1_1)
	var_0_4.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
	arg_1_0:listenInfo("death_info")
end

function var_0_4.populateWithHero(arg_2_0, arg_2_1)
	var_0_4.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.SHIELD_BUFF = 40010819
		arg_2_0.ENERGY_BUFF = 40011878
	elseif arg_2_0.skinSkillIndex_ == 2 then
		arg_2_0.SHIELD_BUFF = 40012242
		arg_2_0.ENERGY_BUFF = 40012241
	else
		arg_2_0.SHIELD_BUFF = 40010819
		arg_2_0.ENERGY_BUFF = 40010817
	end
end

function var_0_4.init(arg_3_0)
	var_0_4.super.init(arg_3_0)

	arg_3_0.skinCDCount = 0
	arg_3_0.tempEnergyHarm = 0
	arg_3_0.energyTotalDamage = 0
	arg_3_0.energyTarget = nil
	arg_3_0.firstShield = true
	arg_3_0.hasSaved = false
end

function var_0_4.applySingleUnit(arg_4_0, arg_4_1)
	var_0_4.super.applySingleUnit(arg_4_0, arg_4_1)

	if var_0_5:father(arg_4_1.skillID) == arg_4_0:getEnergySkillID() then
		arg_4_0.energyTarget = arg_4_1.target
		arg_4_0.energyTotalDamage = 0
	end

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		-- block empty
	end
end

function var_0_4.addBuff(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_0:newBuff(arg_5_1, arg_5_0:getEnergySkillID(), arg_5_2)

	arg_5_2:addBuffs({
		var_5_0
	})
end

function var_0_4.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	return (var_0_3.new({
		tableID = arg_6_1,
		start = var_0_1.ctx.battle.count,
		level = arg_6_0:getSkillLevelByID(arg_6_2),
		skillID = arg_6_2,
		fighter = arg_6_0,
		target = arg_6_3
	}))
end

function var_0_4.getUnitData(arg_7_0, arg_7_1)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_4.super.getUnitData(arg_7_0, arg_7_1)

	if arg_7_1.skillID == var_0_8 and arg_7_0.tempEnergyHarm ~= 0 then
		var_7_2 = arg_7_0.tempEnergyHarm
		arg_7_0.tempEnergyHarm = 0
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

function var_0_4.addShields(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0:getBuffByID(arg_8_0.SHIELD_BUFF)

	if var_8_0 then
		var_8_0:setShieldNum(var_8_0:getShieldNum() + arg_8_1)
	else
		local var_8_1 = var_0_3.new({
			tableID = arg_8_0.SHIELD_BUFF,
			start = var_0_1.ctx.battle.count,
			level = arg_8_0:getSkillLevelByID(arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)),
			skillID = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
			fighter = arg_8_0,
			target = arg_8_0
		})

		var_8_1:setShieldNum(arg_8_1)
		arg_8_0:addBuffs({
			var_8_1
		})
	end
end

function var_0_4.toDoPerFrames(arg_9_0)
	if not arg_9_0.extraSkillJudge then
		arg_9_0.extraSkillJudge = true

		local var_9_0 = arg_9_0.hero_:skillBook()

		arg_9_0.extraSkillLevel1 = var_9_0[tostring(var_0_23)] or 0
		arg_9_0.extraSkillLevel2 = var_9_0[tostring(var_0_24)] or 0
		arg_9_0.extraSkillLevel3 = var_9_0[tostring(var_0_25)] or 0
	end

	var_0_4.super.toDoPerFrames(arg_9_0)

	if arg_9_0.firstShield and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_9_0.firstShield = false

		arg_9_0:addShields(var_0_9)
	end

	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_9_0, iter_9_1 in ipairs(arg_9_0:getInfoByKey("death_info")) do
			if iter_9_1:getTeamType() ~= arg_9_0:getTeamType() then
				if iter_9_1.summonType_ == var_0_2.summonMonsterType.None then
					arg_9_0:addShields(var_0_10)
				else
					arg_9_0:addShields(var_0_11)
				end
			end
		end
	end

	if arg_9_0:getBuffByID(arg_9_0.SHIELD_BUFF) then
		arg_9_0:updateStateNumber(arg_9_0:getBuffByID(arg_9_0.SHIELD_BUFF):getShieldNum() or 0)
	else
		arg_9_0:updateStateNumber()
	end

	if arg_9_0.energyTarget and not arg_9_0.energyTarget:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_9_1 = 0
		local var_9_2 = false

		for iter_9_2, iter_9_3 in ipairs(arg_9_0:getInfoByKey("harm_info")) do
			local var_9_3 = iter_9_3.harm
			local var_9_4 = iter_9_3.target

			for iter_9_4, iter_9_5 in pairs(arg_9_0.sideTeam_) do
				if arg_9_0.energyTarget and iter_9_5 == var_9_4 and iter_9_5 ~= arg_9_0.energyTarget and not var_9_2 then
					var_9_1 = var_9_1 + var_9_3 * var_0_7
					arg_9_0.energyTotalDamage = arg_9_0.energyTotalDamage + var_9_3 * var_0_7

					local var_9_5 = var_0_6 * arg_9_0:getSkillLevelByID(arg_9_0:getEnergySkillID())

					if arg_9_0.extraSkillLevel3 > 0 then
						var_9_5 = var_9_5 + arg_9_0.extraSkillLevel3 * var_0_27
					end

					if var_9_5 < arg_9_0.energyTotalDamage or not arg_9_0.energyTarget:isTeamAffected() then
						var_9_2 = true

						break
					end
				end
			end
		end

		local var_9_6

		arg_9_0.tempEnergyHarm = arg_9_0.tempEnergyHarm + var_9_1

		if arg_9_0.tempEnergyHarm > 0 then
			local var_9_7 = arg_9_0:createAttackUnits({
				arg_9_0.energyTarget
			}, var_0_8)

			table.insert(arg_9_0.moveAttackUnits_, var_9_7[1])
			arg_9_0:unitAfterCreate(nil, var_9_7)
		end

		if var_9_2 then
			if arg_9_0:hasElementEquipByID(var_0_21) and arg_9_0.energyTotalDamage > 0 then
				local var_9_8 = var_0_21
				local var_9_9 = var_0_20:battleAttr(var_9_8, arg_9_0:getElementEquipLevelByID(var_9_8))
				local var_9_10 = arg_9_0.hero_:getElementEquipActiveRate(var_9_8)
				local var_9_11 = {}

				for iter_9_6, iter_9_7 in ipairs(arg_9_0.sideTeam_) do
					if iter_9_7 ~= arg_9_0.energyTarget and not iter_9_7:isDeath() and not iter_9_7:isAffected() then
						table.insert(var_9_11, iter_9_7)
					end
				end

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_9_12 = arg_9_0:createAttackUnits(var_9_11, var_0_22)

					for iter_9_8, iter_9_9 in ipairs(var_9_12) do
						iter_9_9.basicHarm = arg_9_0.energyTotalDamage * var_9_9 * var_9_10

						table.insert(arg_9_0.moveAttackUnits_, iter_9_9)
						table.insert(arg_9_0.records_.special_units, iter_9_9)
					end
				end
			end

			arg_9_0.energyTarget = nil
			arg_9_0.energyTotalDamage = 0
		end
	end

	if arg_9_0.isSkinSkillOn_ and arg_9_0.skinSkillID_ == var_0_15 and var_0_1.ctx.battle.count % 30 == 1 then
		arg_9_0.skinCDCount = arg_9_0.skinCDCount - 1

		if arg_9_0.skinCDCount <= 0 then
			arg_9_0.hasSaved = false
		end

		arg_9_0.skinTarget_ = nil

		for iter_9_10, iter_9_11 in ipairs(arg_9_0.selfTeam_) do
			if iter_9_11 ~= arg_9_0 and iter_9_11:getSummonType() == var_0_2.summonMonsterType.None and not iter_9_11:isDeath() and not iter_9_11:isAffected() then
				if not arg_9_0.skinTarget_ then
					arg_9_0.skinTarget_ = iter_9_11
					arg_9_0.leastHp = iter_9_11:getHp()
				elseif arg_9_0.skinTarget_ ~= iter_9_11 and iter_9_11:getHp() < arg_9_0.leastHp then
					arg_9_0.skinTarget_ = iter_9_11
					arg_9_0.leastHp = iter_9_11:getHp()
				end
			end
		end
	end
end

function var_0_4.updateBuffDataBySpecialHero(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0

	if arg_10_1 and next(arg_10_1) then
		local var_10_1 = arg_10_1[1].target

		if arg_10_0.isSkinSkillOn_ and arg_10_0.skinSkillID_ == var_0_15 and var_10_1:getTeamType() == arg_10_0:getTeamType() and var_10_1:getHp() <= arg_10_2 - arg_10_3 and arg_10_0.skinCDCount <= 0 and not arg_10_0.hasSaved then
			arg_10_2 = arg_10_3
			arg_10_0.skinCDCount = var_0_16
			arg_10_0.hasSaved = true
		end
	end

	return arg_10_2, arg_10_3, arg_10_4
end

function var_0_4.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7 = var_0_4.super.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	local var_11_0 = arg_11_1.target
	local var_11_1 = 1

	if arg_11_0.extraSkillLevel1 > 0 and arg_11_4 > 0 and var_0_5:father(arg_11_1.skillID) == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		var_11_1 = var_11_1 + var_0_26 * arg_11_0.extraSkillLevel1
	end

	if arg_11_4 > 0 and arg_11_1.target:isHasBuffByID(var_0_12) and arg_11_0.isSkinSkillOn_ and arg_11_0.skinSkillID_ == var_0_14 then
		var_11_1 = var_11_1 + var_0_13
	end

	arg_11_4 = var_11_1 * arg_11_4

	return arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7
end

function var_0_4.updateUnitDataBySpecialHero(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
	arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7 = var_0_4.super.updateUnitDataBySpecialHero(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)

	local var_12_0 = arg_12_1.target

	if arg_12_4 > 0 and arg_12_0.isSkinSkillOn_ and arg_12_0.skinSkillID_ == var_0_15 and arg_12_0.skinTarget_ and var_12_0 == arg_12_0.skinTarget_ then
		arg_12_4 = arg_12_4 - arg_12_4 * var_0_18

		local var_12_1 = arg_12_4 * var_0_19

		arg_12_4 = arg_12_4 - var_12_1

		local var_12_2 = arg_12_0:getHp()

		if var_12_2 <= var_12_1 and arg_12_0.skinCDCount <= 0 and not arg_12_0.hasSaved then
			var_12_1 = 0
			arg_12_0.skinCDCount = var_0_16
			arg_12_0.hasSaved = true
		end

		arg_12_0:updateHp(var_12_2 - var_12_1)
		arg_12_0.fighterModel:playHPDeltas({
			{
				-var_12_1,
				false
			}
		}, nil)

		if arg_12_0:isDeath() then
			arg_12_0.killer_ = arg_12_1.fighter

			arg_12_0:die()
		end
	end

	if arg_12_4 > 0 and arg_12_0.isSkinSkillOn_ and arg_12_0.skinSkillID_ == var_0_15 and var_12_0:getTeamType() == arg_12_0:getTeamType() and arg_12_4 >= var_12_0:getHp() and arg_12_0.skinCDCount <= 0 and not arg_12_0.hasSaved then
		arg_12_4 = 0
		arg_12_0.skinCDCount = var_0_16
		arg_12_0.hasSaved = true
	end

	return arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7
end

function var_0_4.buffAddAction(arg_13_0, arg_13_1)
	if arg_13_1:getTableID() == arg_13_0.ENERGY_BUFF and arg_13_0.extraSkillLevel3 > 0 then
		arg_13_1:setExtraTime(var_0_28 * arg_13_0.extraSkillLevel3)
	end
end

return var_0_4
