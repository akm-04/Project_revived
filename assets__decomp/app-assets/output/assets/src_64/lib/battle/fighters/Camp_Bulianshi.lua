local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Bulianshi", var_0_1.ctx.battle.requireFighter("CampWarBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 10000407
local var_0_8 = 10000408
local var_0_9 = 10000409
local var_0_10 = 10000406
local var_0_11 = 10000413
local var_0_12 = {
	40010122
}
local var_0_13 = {
	40010131
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.flyTime_ = nil
	arg_2_0.dropTime1_ = nil
	arg_2_0.dropTime2_ = nil
	arg_2_0.flyTarget_ = nil
	arg_2_0.dropTarget_ = nil
	arg_2_0.energyTarget_ = nil
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0.flyTime_ then
		arg_3_0:attackFly(arg_3_0.flyTarget_)

		arg_3_0.flyTime_ = math.max(0, arg_3_0.flyTime_ - 1)

		if arg_3_0.flyTime_ == 0 then
			arg_3_0.flyTime_ = nil
			arg_3_0.flyTarget_ = nil
		end
	end

	if arg_3_0.dropTime1_ or arg_3_0.dropTime2_ then
		arg_3_0:attackDrop(arg_3_0.dropTarget_)

		if arg_3_0.dropTime1_ > 0 then
			arg_3_0.dropTime1_ = math.max(0, arg_3_0.dropTime1_ - 1)
		else
			arg_3_0.dropTime2_ = math.max(0, arg_3_0.dropTime2_ - 1)
		end

		if arg_3_0.dropTime2_ == 0 then
			arg_3_0.dropTime2_ = nil
			arg_3_0.dropTime1_ = nil
			arg_3_0.dropTarget_ = nil
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			local var_3_0 = iter_3_1.target

			if var_3_0 and not var_3_0:isDeath() and not var_3_0:isAffected() and var_3_0:getTeamType() ~= arg_3_0:getTeamType() and arg_3_0:isFlyBuff(iter_3_1) then
				arg_3_0:addExtraPurpleSkill(iter_3_1.target)
			end
		end
	end
end

function var_0_3.isFlyBuff(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1:getTableID()

	if var_0_6:type(var_4_0) == var_0_2.BuffType.MOVE and var_0_6:y(var_4_0) > 0 then
		return true
	else
		return false
	end
end

function var_0_3.attackFly(arg_5_0, arg_5_1)
	if not arg_5_1:isDeath() then
		if arg_5_0.flyTime_ <= 4 then
			arg_5_1:moveByY(-arg_5_0.flySpeed_)
		else
			arg_5_1:moveByY(arg_5_0.flySpeed_)
		end

		if not arg_5_0.flyBuff_ and arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_5_0.flyBuff_ = true

			arg_5_0:addExtraPurpleSkill(arg_5_1)
		end
	end
end

function var_0_3.attackDrop(arg_6_0, arg_6_1)
	if not arg_6_1:isDeath() then
		if arg_6_0.dropTime1_ > 0 then
			arg_6_1:moveByY(arg_6_0.dropSpeed1_)
		else
			arg_6_1:moveByY(-arg_6_0.dropSpeed2_)
		end

		if not arg_6_0:getFlipX() and arg_6_1:getX() < var_0_2.STAGE_WIDTH then
			arg_6_1:moveByX(17)
		elseif arg_6_0:getFlipX() and arg_6_1:getX() > 0 then
			arg_6_1:moveByY(-17)
		end

		if not arg_6_0.dropBuff_ and arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_6_0.dropBuff_ = true

			arg_6_0:addExtraPurpleSkill(arg_6_1)
		end
	end
end

function var_0_3.addExtraPurpleSkill(arg_7_0, arg_7_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_7_0:isDeath() then
		return
	end

	local var_7_0 = {
		arg_7_1
	}
	local var_7_1 = arg_7_0:createAttackUnits(var_7_0, var_0_10)

	for iter_7_0, iter_7_1 in ipairs(var_7_1) do
		table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
		table.insert(arg_7_0.records_.special_units, iter_7_1)
	end

	local var_7_2 = {
		arg_7_0
	}
	local var_7_3 = arg_7_0:createAttackUnits(var_7_2, var_0_11)

	for iter_7_2, iter_7_3 in ipairs(var_7_3) do
		table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
		table.insert(arg_7_0.records_.special_units, iter_7_3)
	end
end

function var_0_3.deathFeedback(arg_8_0, arg_8_1)
	var_0_3.super.deathFeedback(arg_8_0, arg_8_1)

	if arg_8_1 == arg_8_0.energyTarget_ then
		arg_8_0:addBuffs(arg_8_0:newBuff(var_0_13, arg_8_0, arg_8_0:getEnergySkillID()))
	end
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	if arg_9_1.skillID == var_0_7 then
		arg_9_0.flyTime_ = var_0_5:pretime(var_0_8) - var_0_5:pretime(var_0_7)
		arg_9_0.flySpeed_ = (arg_9_0:getY() + 300 - arg_9_1.target:getY()) / arg_9_0.flyTime_
		arg_9_0.flyTarget_ = arg_9_1.target
		arg_9_0.energyTarget_ = arg_9_1.target
		arg_9_0.flyBuff_ = false

		arg_9_1.target:unsetMaskColor()
	end

	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	if arg_9_1.skillID == var_0_9 then
		local var_9_0 = var_0_5:pretime(var_0_8) - var_0_5:pretime(var_0_7)

		arg_9_0.dropTime1_ = var_9_0 / 4
		arg_9_0.dropTime2_ = var_9_0 * 3 / 4
		arg_9_0.dropSpeed1_ = 400 / var_9_0
		arg_9_0.dropSpeed2_ = (arg_9_1.target:getY() - arg_9_0:getY() + 100) * 4 / (var_9_0 * 3)
		arg_9_0.dropTarget_ = arg_9_1.target
		arg_9_0.dropBuff_ = false
		arg_9_0.energyTarget_ = nil
	end

	if arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_9_0:addExtraGreenBuff()
	end
end

function var_0_3.addExtraGreenBuff(arg_10_0)
	for iter_10_0, iter_10_1 in ipairs(arg_10_0.selfTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() then
			iter_10_1:addBuffs(arg_10_0:newBuff(var_0_12, iter_10_1, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)))
		end
	end
end

function var_0_3.calculateUnitData(arg_11_0, arg_11_1)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = var_0_3.super.calculateUnitData(arg_11_0, arg_11_1)

	if arg_11_1.skillID == var_0_9 and not var_11_1 and not var_11_0 then
		var_11_1 = true
		var_11_2 = var_11_2 * (arg_11_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_11_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		var_11_2 = var_11_2 * math.max(0.01, arg_11_1.target:getADBaoJiJianShang())
	end

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5
end

function var_0_3.selectTargetByTypeD1(arg_12_0, arg_12_1, arg_12_2)
	return {
		arg_12_0.energyTarget_
	}
end

function var_0_3.selectTargetByTypeD2(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_0:getX()
	local var_13_1
	local var_13_2
	local var_13_3 = var_0_5:distance(arg_13_1)

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_13_4 = math.abs(var_13_0 - iter_13_1:getX())

			if var_13_4 <= var_13_3 and (not var_13_1 or var_13_4 < var_13_1) then
				var_13_1 = var_13_4
				var_13_2 = iter_13_1
			end
		end
	end

	return {
		var_13_2
	}
end

function var_0_3.newBuff(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_1) do
		local var_14_1 = var_0_4.new({
			tableID = iter_14_1,
			start = var_0_1.ctx.battle.count,
			level = arg_14_0:getSkillLevelByID(arg_14_3),
			skillID = arg_14_3,
			fighter = arg_14_0,
			target = arg_14_2
		})

		var_14_1:setIsHit(true)
		var_14_1:setDirection(arg_14_0:getFighterModel():getFlipX())
		table.insert(var_14_0, var_14_1)
	end

	return var_14_0
end

function var_0_3.checkEnergySkill(arg_15_0)
	if not next(arg_15_0:selectTargetByTypeD2(arg_15_0:getEnergySkillID())) then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_15_0)
	end
end

return var_0_3
