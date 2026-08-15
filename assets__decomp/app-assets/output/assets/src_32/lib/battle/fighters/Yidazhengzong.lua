local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yidazhengzong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10000904
local var_0_7 = 3
local var_0_8 = 0.15
local var_0_9 = 10000908
local var_0_10 = 40010989
local var_0_11 = 0.1
local var_0_12 = 2
local var_0_13 = 40010986
local var_0_14 = 10
local var_0_15 = 120
local var_0_16 = 0.65
local var_0_17 = 0.3
local var_0_18 = 0.5
local var_0_19 = 10001961
local var_0_20 = 10001965
local var_0_21 = 10001964

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("crit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isEnergyType_ = false
	arg_2_0.greenSkill1Count_ = 0
	arg_2_0.isGreenType_ = false
	arg_2_0.lastEnergyTime_ = nil
	arg_2_0.firstEnergySkill = false
	arg_2_0.mustBaojiCount = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("crit_info")) do
			if iter_3_1.unit.fighter == arg_3_0 and #arg_3_0:getBuffsByID(var_0_13) < var_0_14 then
				local var_3_0 = arg_3_0:newBuff({
					var_0_13
				}, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				arg_3_0:addBuffs(var_3_0)
			end
		end
	end

	if arg_3_0.mustBaojiCount > 0 then
		arg_3_0.mustBaojiCount = arg_3_0.mustBaojiCount - 1

		if arg_3_0.mustBaojiCount == 0 then
			arg_3_0.greenMustBaoji = true
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_4_0)
	local var_4_0 = var_0_3.super.getOrbOfFrontSkill(arg_4_0)

	if arg_4_0.isEnergyType_ and var_0_5:father(var_4_0) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if not arg_4_0.isSkinSkillOn_ then
			var_4_0 = var_0_6
		else
			var_4_0 = var_0_19
		end
	end

	return var_4_0
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_1.rootID_ == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_5_1.rootID_ == var_0_20 then
		arg_5_0.greenSkill1Count_ = arg_5_0.greenSkill1Count_ + 1

		if arg_5_0.greenSkill1Count_ >= var_0_7 then
			arg_5_0.isGreenType_ = true
			arg_5_0.greenSkill1Count_ = 0
		end
	else
		arg_5_0.isGreenType_ = false
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0.isSkinSkillOn_ and arg_6_4 > 0 and arg_6_1.target:getHp() / arg_6_1.target:getHpLimit() > var_0_16 then
		arg_6_4 = arg_6_4 * (1 + var_0_17)
	end

	if arg_6_4 > 0 and arg_6_0.isGreenType_ and (arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_6_1.skillID == var_0_20) then
		arg_6_6 = arg_6_6 + arg_6_4 * var_0_8
	elseif arg_6_0.isSkinSkillOn_ and arg_6_4 > 0 and arg_6_0.isEnergyType_ and var_0_5:father(arg_6_1.skillID) == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_6_6 = arg_6_6 + arg_6_4 * var_0_8 * var_0_18
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.distributeBuff(arg_7_0, arg_7_1)
	var_0_3.super.distributeBuff(arg_7_0, arg_7_1)

	if arg_7_0.isEnergyType_ and arg_7_0:checkIsDouble(arg_7_1) then
		local var_7_0 = arg_7_1.manualRevise
		local var_7_1, var_7_2 = arg_7_1:getAttr()

		arg_7_1.manualRevise = var_7_0 + (var_7_1 - var_7_0) * var_0_12
	end
end

function var_0_3.checkIsDouble(arg_8_0, arg_8_1)
	if arg_8_1:getBuffForm() == var_0_2.BuffForm.GAIN and (arg_8_1:getAttrType() == var_0_2.AttributeType.AGILE or arg_8_1:getAttrType() == var_0_2.AttributeType.AD or arg_8_1:getAttrType() == var_0_2.AttributeType.AD_BAOJI or arg_8_1:getAttrType() == var_0_2.AttributeType.D_HUJIA or arg_8_1:getAttrType() == var_0_2.AttributeType.AD_BAOJIHARM or arg_8_1:getAttrType() == var_0_2.AttributeType.MINGZHONG) then
		return true
	end

	return false
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	if arg_9_0.isSkinSkillOn_ and var_0_5:father(arg_9_1.skillID) == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_9_0.greenMustBaoji then
		arg_9_1.mustBaoji = true
	end

	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	if arg_9_0.isEnergyType_ and arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_9_0 = arg_9_0:getTargets(var_0_9)

		if next(var_9_0) then
			local var_9_1 = arg_9_0:createAttackUnits(var_9_0, var_0_9)

			for iter_9_0, iter_9_1 in ipairs(var_9_1) do
				table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
				table.insert(arg_9_0.records_.special_units, iter_9_1)
			end
		end
	end

	if arg_9_0.isSkinSkillOn_ and var_0_5:father(arg_9_1.skillID) == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_9_1.target:isDeath() then
		arg_9_0.mustBaojiCount = 60
	end
end

function var_0_3.moveUnitArrive(arg_10_0, arg_10_1)
	var_0_3.super.moveUnitArrive(arg_10_0, arg_10_1)

	if arg_10_0.isSkinSkillOn_ and (arg_10_1.skillID == var_0_20 or arg_10_1.skillID == var_0_21) then
		arg_10_0.greenMustBaoji = false
	end
end

function var_0_3.buffAddAction(arg_11_0, arg_11_1)
	var_0_3.super.buffAddAction(arg_11_0, arg_11_1)

	if arg_11_1:getTableID() == var_0_10 then
		arg_11_1.target:setMinHpValue(var_0_11)

		arg_11_0.isEnergyType_ = true
		arg_11_0.firstEnergySkill = true
	end
end

function var_0_3.buffRemoveAction(arg_12_0, arg_12_1)
	var_0_3.super.buffRemoveAction(arg_12_0, arg_12_1)

	if arg_12_1:getTableID() == var_0_10 then
		arg_12_0.isEnergyType_ = false
		arg_12_0.lastEnergyTime_ = var_0_1.ctx.battle.count
	end
end

function var_0_3.newBuff(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		local var_13_1 = var_0_4.new({
			tableID = iter_13_1,
			start = var_0_1.ctx.battle.count,
			level = arg_13_0:getSkillLevelByID(arg_13_3),
			skillID = arg_13_3,
			fighter = arg_13_0,
			target = arg_13_2
		})

		var_13_1:setIsHit(true)
		var_13_1:setDirection(arg_13_0:getFighterModel():getFlipX())
		table.insert(var_13_0, var_13_1)
	end

	return var_13_0
end

function var_0_3.checkEnergySkill(arg_14_0)
	if arg_14_0.isEnergyType_ then
		return false
	elseif arg_14_0.lastEnergyTime_ and var_0_1.ctx.battle.count - arg_14_0.lastEnergyTime_ < var_0_15 then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_14_0)
end

return var_0_3
