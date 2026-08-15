local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guoxiu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 0.7
local var_0_8 = 0
local var_0_9 = 300
local var_0_10 = 10001789
local var_0_11 = 10001792
local var_0_12 = 0.5

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.BlueChildSkill = 10002216
		arg_1_0.GreenSkill = 10002220
		arg_1_0.BlueSkill = 10002218
		arg_1_0.PurpleSkill = 10002221
		arg_1_0.EnergySkill = 10002219
		arg_1_0.MoveSignBuff1 = 40012367
		arg_1_0.MoveSignBuff2 = 40012369
		arg_1_0.PurpleBuff = 40012368
	else
		arg_1_0.BlueChildSkill = 10001788
		arg_1_0.GreenSkill = 20020240
		arg_1_0.BlueSkill = 30010240
		arg_1_0.PurpleSkill = 40010240
		arg_1_0.EnergySkill = 50010240
		arg_1_0.MoveSignBuff1 = 40011930
		arg_1_0.MoveSignBuff2 = 40011933
		arg_1_0.PurpleBuff = 40011931
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.beginJump_ = false
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	for iter_3_0, iter_3_1 in pairs(arg_3_0.sideTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and (iter_3_1:isHasBuffByID(arg_3_0.MoveSignBuff1) or iter_3_1:isHasBuffByID(arg_3_0.MoveSignBuff2)) then
			local var_3_0 = iter_3_1:getX() < arg_3_0:getX() and 1 or -1

			iter_3_1:moveByX(var_3_0)
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0.BlueSkill then
		arg_4_0:blueSkill()
	elseif var_0_5:father(arg_4_1.skillID) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		arg_4_0:energyJump(arg_4_1)
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_1.target:isDeath() then
		local var_4_0 = arg_4_0:createNewBuffs({
			arg_4_0.PurpleBuff
		}, arg_4_0, arg_4_0.PurpleSkill)

		arg_4_0:addBuffs(var_4_0)
	end
end

function var_0_3.energyJump(arg_5_0, arg_5_1)
	if arg_5_1.skillID == var_0_10 then
		local var_5_0 = arg_5_1.target

		arg_5_0.originX = arg_5_0:getX()
		arg_5_0.originY = arg_5_0:getY()

		arg_5_0:x(var_5_0:getX())
		arg_5_0:y(var_5_0:getY())
	elseif arg_5_1.skillID == var_0_11 then
		arg_5_0:x(arg_5_0.originX)
		arg_5_0:y(arg_5_0.originY)
	end
end

function var_0_3.blueSkill(arg_6_0)
	local var_6_0 = var_0_7 + var_0_8 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

	if var_0_2.weightedChoise({
		var_6_0,
		1 - var_6_0
	}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_1 = arg_6_0.BlueChildSkill
		local var_6_2 = var_0_5:selectType(var_6_1)
		local var_6_3 = var_0_4[var_6_2](arg_6_0, var_6_1)
		local var_6_4 = arg_6_0:createAttackUnits(var_6_3, arg_6_0.BlueChildSkill)

		for iter_6_0, iter_6_1 in ipairs(var_6_4) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

function var_0_3.isBreakImmortal(arg_7_0)
	if arg_7_0.beginJump_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_7_0)
	end
end

function var_0_3.createUnits(arg_8_0, arg_8_1)
	var_0_3.super.createUnits(arg_8_0, arg_8_1)

	if arg_8_0.beginJump_ then
		arg_8_0.beginJump_ = false
	end
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	var_0_3.super.buffAddAction(arg_9_0, arg_9_1)

	if arg_9_1:getTableID() == arg_9_0.PurpleBuff then
		arg_9_0:setImmuneControl(true)
	end

	if arg_9_0.skinSkillIndex_ == 1 and arg_9_1:getTableID() == arg_9_0.MoveSignBuff1 then
		local var_9_0 = var_0_6:time(arg_9_1:getTableID()) + arg_9_1.level_ * arg_9_1:getTimeStep()

		arg_9_1:setExtraTime(var_9_0)
	end
end

function var_0_3.buffRemoveAction(arg_10_0, arg_10_1)
	var_0_3.super.buffRemoveAction(arg_10_0, arg_10_1)

	if arg_10_1:getTableID() == arg_10_0.PurpleBuff then
		arg_10_0:updateEnergyBy(var_0_9)
		arg_10_0:setImmuneControl(false)
	end
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0.targetTeam_
	local var_11_1
	local var_11_2

	for iter_11_0, iter_11_1 in pairs(var_11_0) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() then
			local var_11_3 = iter_11_1:getAttrByType(var_0_2.AttributeType.WISE)

			if not var_11_1 or var_11_2 < var_11_3 then
				var_11_1 = iter_11_1
				var_11_2 = var_11_3
			end
		end
	end

	if not var_11_1 then
		return {}
	end

	local var_11_4 = {}
	local var_11_5 = var_0_5:scope(arg_11_1) / 2
	local var_11_6, var_11_7 = var_11_1:getPos()

	table.insert(var_11_4, var_11_1)

	for iter_11_2, iter_11_3 in ipairs(var_11_0) do
		local var_11_8, var_11_9 = iter_11_3:getPos()

		if not iter_11_3:isDeath() and not iter_11_3:isAffected() and var_11_5 >= math.abs(var_11_6 - var_11_8) and iter_11_3 ~= var_11_1 then
			table.insert(var_11_4, iter_11_3)
		end
	end

	return var_11_4
end

function var_0_3.updateUnitDataByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
	if arg_12_0.skinSkillIndex_ == 1 and arg_12_4 > 0 and arg_12_1.skillID == arg_12_0.GreenSkill then
		arg_12_4 = arg_12_4 + arg_12_4 * var_0_12
	end

	return var_0_3.super.updateUnitDataByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
end

return var_0_3
