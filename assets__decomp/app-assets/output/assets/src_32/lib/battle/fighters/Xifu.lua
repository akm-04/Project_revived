local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xifu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.hero
local var_0_10 = 40012010
local var_0_11 = 10001860
local var_0_12 = 5
local var_0_13 = 0.003
local var_0_14 = 0.2
local var_0_15 = 40012011
local var_0_16 = 40012012
local var_0_17 = -0.3
local var_0_18 = -0.003
local var_0_19 = 30
local var_0_20 = 150
local var_0_21 = 40012019
local var_0_22 = 40012015
local var_0_23 = 10001861
local var_0_24 = 810008
local var_0_25 = 0.08

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isAddPurple = false
	arg_1_0.puprleCount = 0
	arg_1_0.purpleStopCount = 0
	arg_1_0.energyTarget = nil
	arg_1_0.energyTargetX = 0
	arg_1_0.energyMap = {}
	arg_1_0.isAdd2Effect = false
	arg_1_0.isAdd3Effect = false
	arg_1_0.blueHarmCount = 0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.PurpleEffectBuff1 = 40012632
		arg_2_0.PurpleEffectBuff2 = 40012633
		arg_2_0.PurpleEffectBuff3 = 40012634
	else
		arg_2_0.PurpleEffectBuff1 = 40012016
		arg_2_0.PurpleEffectBuff2 = 40012017
		arg_2_0.PurpleEffectBuff3 = 40012018
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	arg_3_0.blueHarmCount = arg_3_0.blueHarmCount - 1

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if not arg_3_0.isAddPurple then
			arg_3_0.isAddPurple = true

			local var_3_0 = var_0_5.new({
				tableID = var_0_15,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_3_0,
				target = arg_3_0,
				manualRevise = var_0_17 + var_0_18 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
			})
			local var_3_1 = var_0_5.new({
				tableID = var_0_16,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_3_0,
				target = arg_3_0,
				manualRevise = var_0_17 + var_0_18 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
			})
			local var_3_2 = var_0_5.new({
				tableID = arg_3_0.PurpleEffectBuff1,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_3_0,
				target = arg_3_0
			})

			arg_3_0:addBuffs({
				var_3_0,
				var_3_1,
				var_3_2
			})
		end

		if arg_3_0.purpleStopCount <= 0 then
			arg_3_0.puprleCount = arg_3_0.puprleCount + 1

			if arg_3_0.puprleCount % var_0_19 == 0 then
				local var_3_3 = arg_3_0:getBuffByID(var_0_15)

				if var_3_3 then
					var_3_3.manualRevise = (var_0_17 + var_0_18 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)) * (120 - arg_3_0.puprleCount / var_0_19) / 120

					local var_3_4 = arg_3_0.hero_:getBattleAttr(var_0_2.AttributeType.AD_JIANSHANG)
					local var_3_5, var_3_6 = arg_3_0:getBuffAttrChange(var_0_2.AttributeType.AD_JIANSHANG)
					local var_3_7 = math.max(1 + var_3_6, 0) * var_3_4 + var_3_5

					arg_3_0.___attrCache[var_0_2.AttributeType.AD_JIANSHANG] = math.max(var_3_7, 0)
				end

				local var_3_8 = arg_3_0:getBuffByID(var_0_16)

				if var_3_8 then
					var_3_8.manualRevise = (var_0_17 + var_0_18 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)) * (120 - arg_3_0.puprleCount / var_0_19) / 120

					local var_3_9 = arg_3_0.hero_:getBattleAttr(var_0_2.AttributeType.AP_JIANSHANG)
					local var_3_10, var_3_11 = arg_3_0:getBuffAttrChange(var_0_2.AttributeType.AP_JIANSHANG)
					local var_3_12 = math.max(1 + var_3_11, 0) * var_3_9 + var_3_10

					arg_3_0.___attrCache[var_0_2.AttributeType.AP_JIANSHANG] = math.max(var_3_12, 0)

					if var_3_8.manualRevise <= (var_0_17 + var_0_18 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)) * 0.75 and not arg_3_0.isAdd2Effect then
						arg_3_0.isAdd2Effect = true

						arg_3_0:removeBuffByID(arg_3_0.PurpleEffectBuff1)

						local var_3_13 = var_0_5.new({
							tableID = arg_3_0.PurpleEffectBuff2,
							start = var_0_1.ctx.battle.count,
							level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
							skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
							fighter = arg_3_0,
							target = arg_3_0
						})

						arg_3_0:addBuffs({
							var_3_13
						})
					elseif var_3_8.manualRevise <= (var_0_17 + var_0_18 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)) * 0.5 and not arg_3_0.isAdd3Effect then
						arg_3_0.isAdd3Effect = true

						arg_3_0:removeBuffByID(arg_3_0.PurpleEffectBuff2)

						local var_3_14 = var_0_5.new({
							tableID = arg_3_0.PurpleEffectBuff3,
							start = var_0_1.ctx.battle.count,
							level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
							skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
							fighter = arg_3_0,
							target = arg_3_0
						})

						arg_3_0:addBuffs({
							var_3_14
						})
					end
				end
			end
		else
			arg_3_0.purpleStopCount = arg_3_0.purpleStopCount - 1
		end
	end

	if arg_3_0.energyTarget and arg_3_0.energyTarget:isHasBuffByID(var_0_21) and not arg_3_0.energyTarget:isDeath() then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1 ~= arg_3_0.energyTarget and not arg_3_0.energyMap[iter_3_1.fighterIndex] and math.abs(iter_3_1:getX() - arg_3_0.energyTarget:getX()) < 20 then
				arg_3_0.energyMap[iter_3_1.fighterIndex] = true

				local var_3_15 = var_0_5.new({
					tableID = var_0_22,
					start = var_0_1.ctx.battle.count,
					level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
					skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
					fighter = arg_3_0,
					target = iter_3_1
				})

				var_3_15.resetXchange_ = math.max(800 - math.abs(arg_3_0.energyTargetX - iter_3_1:getX()), 0) / 2

				iter_3_1:addBuffs({
					var_3_15
				})

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_3_16 = arg_3_0:createAttackUnits({
						iter_3_1
					}, var_0_23)

					for iter_3_2, iter_3_3 in ipairs(var_3_16) do
						iter_3_3.harms = math.max(800 - math.abs(arg_3_0.energyTargetX - iter_3_1:getX()), 0)

						table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
						table.insert(arg_3_0.records_.special_units, iter_3_3)
					end
				end
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.energyTarget = nil
		arg_4_0.energyTargetX = 0
		arg_4_0.energyMap = {}
	end
end

function var_0_3.deathFeedback(arg_5_0, arg_5_1)
	if arg_5_1:getTeamType() == arg_5_0:getTeamType() and arg_5_1:getSummonType() == var_0_2.summonMonsterType.None then
		arg_5_0.purpleStopCount = var_0_20 + 3 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == var_0_10 then
		arg_6_1:setForceTarget(arg_6_0)
	end
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	if arg_7_2 > 0 and arg_7_1.fighter:isHasBuffByID(var_0_10) and arg_7_0.blueHarmCount <= 0 then
		arg_7_0.blueHarmCount = var_0_12

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_0 = arg_7_0:createAttackUnits({
				arg_7_1.fighter
			}, var_0_11)

			for iter_7_0, iter_7_1 in ipairs(var_7_0) do
				iter_7_1.harms = arg_7_2 * (var_0_14 + var_0_13 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))

				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		end
	end

	return var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if var_8_2 > 0 and arg_8_1.skillID == var_0_11 and arg_8_1.harms then
		var_8_2 = var_8_2 + arg_8_1.harms
	elseif var_8_2 > 0 and arg_8_1.skillID == var_0_23 and arg_8_1.harms then
		var_8_2 = var_8_2 + arg_8_1.harms
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.updateUnitDataBySpecialHero(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_1.target == arg_9_0 and arg_9_4 > arg_9_0:getHpLimit() * var_0_25 then
		arg_9_4 = arg_9_0:getHpLimit() * var_0_25

		local var_9_0 = arg_9_0:createAttackUnits({
			arg_9_0
		}, var_0_24)

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

function var_0_3.applySingleUnit(arg_10_0, arg_10_1)
	var_0_3.super.applySingleUnit(arg_10_0, arg_10_1)

	if arg_10_1.skillID == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		arg_10_0.energyTarget = arg_10_1.target
		arg_10_0.energyTargetX = arg_10_1.target:getX()
	end
end

return var_0_3
