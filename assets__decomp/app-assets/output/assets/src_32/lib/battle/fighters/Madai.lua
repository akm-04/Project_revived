local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Madai", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.model
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 0.46
local var_0_8 = 0.04
local var_0_9 = 200
local var_0_10 = 50
local var_0_11 = 80010097
local var_0_12 = 40010078
local var_0_13 = var_0_2.tables.elementEquip
local var_0_14 = 20001474
local var_0_15 = 60

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.jumpToX_ = nil
	arg_1_0.jumpToY_ = nil
	arg_1_0.jumpCount_ = nil
	arg_1_0.elementEquipCount = 0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.EnergyHarmID = 10002477
		arg_2_0.EnergySkillID = 10002479
	elseif arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_2_0.EnergyHarmID = 10001687
		arg_2_0.EnergySkillID = 51010097
	else
		arg_2_0.EnergyHarmID = 10000379
		arg_2_0.EnergySkillID = 50010097
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_12 and arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_11 then
		local var_3_0 = false
		local var_3_1 = arg_3_1.target:getBuffs()

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			if iter_3_1:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				var_3_0 = true
			end
		end

		if var_3_0 then
			local var_3_2 = arg_3_1:getTime()

			arg_3_1:setExtraTime(var_3_2)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0
	local var_4_1

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_4_2 = iter_4_1.hero_:getMainAttr(var_0_2.AttributeType.STRENGTH)

			if not var_4_0 or var_4_2 < var_4_0 then
				var_4_1 = iter_4_1
				var_4_0 = var_4_2
			end
		end
	end

	return {
		var_4_1
	}
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if var_5_2 > 0 and not var_5_0 and arg_5_1.target:getTeamType() ~= arg_5_0:getTeamType() and arg_5_0.isSkinSkillOn_ and arg_5_0.skinSkillID_ == var_0_11 and arg_5_1.skillID ~= var_0_11 then
		local var_5_6 = arg_5_1.target:getBuffs()
		local var_5_7 = false

		for iter_5_0, iter_5_1 in ipairs(var_5_6) do
			if iter_5_1:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				var_5_7 = true

				break
			end
		end

		if var_5_7 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_5_8 = arg_5_0:createAttackUnits({
				arg_5_1.target
			}, var_0_11)

			for iter_5_2, iter_5_3 in ipairs(var_5_8) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
				table.insert(arg_5_0.records_.special_units, iter_5_3)
			end
		end
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.calculateUnitData(arg_6_0, arg_6_1)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.calculateUnitData(arg_6_0, arg_6_1)
	local var_6_6 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if arg_6_1.skillID == arg_6_0.EnergyHarmID then
		local var_6_7 = arg_6_1.target.hero_:getMainAttr(var_0_2.AttributeType.AGILE)
		local var_6_8 = arg_6_0.hero_:getMainAttr(var_0_2.AttributeType.AGILE)
		local var_6_9

		var_6_2 = var_6_2 + (var_6_8 - var_6_7 <= 0 and 0 or (var_6_8 - var_6_7) * (var_0_7 + var_0_8 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)))
	end

	if var_6_6 > 0 and var_6_2 > 0 then
		var_6_2 = var_6_2 + (var_0_10 * var_6_6 + var_0_9) * (arg_6_1.target:getHp() / arg_6_1.target:getHpLimit())
	end

	if var_6_2 > 0 and arg_6_1.target:getTeamType() ~= arg_6_0:getTeamType() and arg_6_0:hasElementEquipByID(var_0_14) and (arg_6_0.elementEquipCount == 0 or var_0_1.ctx.battle.count - arg_6_0.elementEquipCount > var_0_15) then
		local var_6_10 = arg_6_1.target
		local var_6_11 = var_0_14
		local var_6_12 = var_0_13:battleAttr(var_6_11, arg_6_0:getElementEquipLevelByID(var_6_11))
		local var_6_13 = arg_6_0.hero_:getElementEquipActiveRate(var_6_11)
		local var_6_14 = (var_6_10:getHpLimit() - var_6_10:getHp()) * var_6_12

		if var_6_10:isBoss() then
			var_6_14 = math.min(var_6_14, arg_6_0:getHpLimit())
		end

		var_6_2 = var_6_2 + var_6_14
		arg_6_0.elementEquipCount = var_0_1.ctx.battle.count
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

function var_0_3.beginAttack(arg_7_0)
	arg_7_0:jumpTo()
	var_0_3.super.beginAttack(arg_7_0)
end

function var_0_3.popSkillByType(arg_8_0, arg_8_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_8_0 = arg_8_0.reportSkills_[1]

		if not var_8_0 then
			return 0
		end

		return var_8_0.rootID_
	end

	if arg_8_0.isEnergySkill_ then
		if arg_8_1 then
			arg_8_0.__popSkillByTypeCache = arg_8_0:getOrbOfFrontSkill()
		end

		return arg_8_0.__popSkillByTypeCache
	end

	if arg_8_0:isApUnable() or arg_8_0:isAttackFriend() then
		if arg_8_1 then
			arg_8_0.__popSkillByTypeCache = arg_8_0:popAdSkill()
		end

		return arg_8_0.__popSkillByTypeCache
	elseif arg_8_0:isAdUnable() and not arg_8_0:isExcuteAdCircle() then
		if arg_8_1 then
			arg_8_0.__popSkillByTypeCache = arg_8_0:popApSkill()
		end

		return arg_8_0.__popSkillByTypeCache
	end

	if arg_8_1 then
		arg_8_0.__popSkillByTypeCache = arg_8_0:popColorSkill()
	end

	return arg_8_0.__popSkillByTypeCache
end

function var_0_3.jumpTo(arg_9_0)
	if not arg_9_0:canAttack() then
		return
	end

	local var_9_0 = arg_9_0:popSkillByType(true)
	local var_9_1

	if var_9_0 == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) or var_9_0 == arg_9_0.EnergySkillID then
		var_9_1 = arg_9_0:selectTargetByTypeD1()[1]
	end

	if not var_9_1 then
		return
	end

	arg_9_0.jumpCount_ = var_0_6:pretime(var_9_0)

	if not var_9_1:avoidHeroMoveBehind() then
		local var_9_2 = var_9_1:getFlipX() and 1 or -1

		if var_9_1:getFlipX() == arg_9_0:getFlipX() then
			arg_9_0.willFlip = arg_9_0:getFlipX()
		else
			arg_9_0.willFlip = not arg_9_0:getFlipX()
		end

		arg_9_0.jumpToY_ = var_9_1:getY()
		arg_9_0.jumpToX_ = var_9_1:getX() + var_9_2 * 100
	else
		local var_9_3 = arg_9_0:getX()
		local var_9_4 = arg_9_0:getY()
		local var_9_5 = var_9_1:getX()
		local var_9_6 = var_9_1:getY()
		local var_9_7 = var_9_5 + (var_9_5 - var_9_3 > 0 and -300 or 300)

		arg_9_0.willFlip = arg_9_0:getFlipX()
		arg_9_0.jumpToX_ = var_0_1.ctx.battle.adjustX(var_9_7, arg_9_0)
		arg_9_0.jumpToY_ = var_9_1:getY()
	end
end

function var_0_3.updateBaseInfo(arg_10_0)
	var_0_3.super.updateBaseInfo(arg_10_0)

	if arg_10_0.jumpCount_ then
		arg_10_0.jumpCount_ = arg_10_0.jumpCount_ - 1

		if arg_10_0.jumpCount_ <= 0 then
			arg_10_0:x(arg_10_0.jumpToX_)
			arg_10_0:y(arg_10_0.jumpToY_)
			arg_10_0:flipX(arg_10_0.willFlip)

			arg_10_0.jumpCount_ = nil
		end
	end
end

function var_0_3.die(arg_11_0)
	var_0_3.super.die(arg_11_0)

	arg_11_0.jumpCount_ = nil
end

function var_0_3.deathFeedback(arg_12_0, arg_12_1)
	if arg_12_0:hasElementEquipByID(var_0_14) and arg_12_1:getSummonType() == var_0_2.summonMonsterType.None and arg_12_1:getTeamType() ~= arg_12_0:getTeamType() and arg_12_1.killer_ and arg_12_1.killer_ == arg_12_0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		local var_12_0 = arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

		arg_12_0:createSkillByID(var_12_0, arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_6:attackIndex(var_12_0))
	end
end

function var_0_3.getOrbOfFrontSkill(arg_13_0)
	local var_13_0 = var_0_3.super.getOrbOfFrontSkill(arg_13_0)

	if var_13_0 == arg_13_0:getEnergySkillID() then
		var_13_0 = arg_13_0.EnergySkillID
	end

	return var_13_0
end

return var_0_3
