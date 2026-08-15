local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fengxian", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = 40011791
local var_0_9 = 40011790
local var_0_10 = 10001690
local var_0_11 = 30010232
local var_0_12 = 10001692
local var_0_13 = 10001693
local var_0_14 = 10001694
local var_0_15 = 10001695
local var_0_16 = 10001696
local var_0_17 = 0.1
local var_0_18 = 300
local var_0_19 = 40011808
local var_0_20 = 40011809
local var_0_21 = 40011792
local var_0_22 = 20080004
local var_0_23 = 20080005
local var_0_24 = 20080006
local var_0_25 = 40012020
local var_0_26 = 40012021
local var_0_27 = 30
local var_0_28 = 9
local var_0_29 = var_0_2.tables.elementEquip
local var_0_30 = 20001483
local var_0_31 = 10002308
local var_0_32 = {
	40012504,
	40012505,
	40012506,
	40012507
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.purpleSkillCount = 0
	arg_2_0.greenX = 0
	arg_2_0.greenY = 0
	arg_2_0.greenPhase = 0
	arg_2_0.greenSkilling = false
	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel1 = 0
	arg_2_0.extraSkillLevel2 = 0
	arg_2_0.extraSkillLevel3 = 0
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_19 or arg_3_1:getTableID() == var_0_20 and arg_3_0.extraSkillLevel2 > 0 then
		arg_3_1:setExtraTime(arg_3_0.extraSkillLevel2 * var_0_27)
	elseif arg_3_1:getTableID() == var_0_21 and arg_3_0.extraSkillLevel3 > 0 then
		arg_3_1:setExtraTime(arg_3_0.extraSkillLevel3 * var_0_28)
	elseif arg_3_1:getTableID() == var_0_32[1] then
		local var_3_0 = var_0_30

		arg_3_1.manualRevise = var_0_29:battleAttr(var_3_0, arg_3_0:getElementEquipLevelByID(var_3_0)) * arg_3_0.hero_:getElementEquipActiveRate(var_3_0)
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_8 then
		local var_4_0 = arg_4_0:getBuffByID(var_0_9)

		if #arg_4_0:getBuffsByID(var_0_8) == 1 and var_4_0 then
			var_4_0.extraTime_ = 0

			local var_4_1 = var_0_7:time(var_0_8) / var_0_7:time(var_0_9)

			var_4_0.leftCount_ = math.floor(var_4_0.leftCount_ / var_4_1)
		end
	end
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if var_0_6:father(arg_5_1.rootID_) == arg_5_0:getEnergySkillID() then
		local var_5_0, var_5_1 = next(var_0_4.B4(arg_5_0, arg_5_0:getEnergySkillID()))

		if var_5_1 then
			arg_5_0:x(var_5_1:getX() + (var_5_1:getFlipX() and 50 or -50))
			arg_5_0:y(var_5_1:getY())
		end

		arg_5_0:judgeElementSkill()
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	local var_6_0 = arg_6_0:getBuffByID(var_0_8) or arg_6_0:getBuffByID(var_0_9)

	if var_6_0 and var_6_0.leftCount_ % math.ceil(var_6_0:getTime() / 5 + 1) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_1 = arg_6_0:createAttackUnits(var_0_4.B8(arg_6_0, var_0_10), var_0_10)

		for iter_6_0, iter_6_1 in ipairs(var_6_1) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end

	if arg_6_0.purpleSkillCount > 0 then
		arg_6_0.purpleSkillCount = arg_6_0.purpleSkillCount - 1
	end

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_6_2, iter_6_3 in ipairs(arg_6_0:getInfoByKey("buff_info")) do
			if iter_6_3.target:getTeamType() ~= arg_6_0:getTeamType() and arg_6_0.purpleSkillCount <= 0 and iter_6_3:isFear() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_2 = arg_6_0:createAttackUnits({
					arg_6_0
				}, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				for iter_6_4, iter_6_5 in ipairs(var_6_2) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_5)
					table.insert(arg_6_0.records_.special_units, iter_6_5)
				end
			end
		end
	end

	if not arg_6_0.extraSkillJudge then
		arg_6_0.extraSkillJudge = true

		local var_6_3 = arg_6_0.hero_:skillBook()

		arg_6_0.extraSkillLevel1 = var_6_3[tostring(var_0_22)] or 0
		arg_6_0.extraSkillLevel2 = var_6_3[tostring(var_0_23)] or 0
		arg_6_0.extraSkillLevel3 = var_6_3[tostring(var_0_24)] or 0

		if arg_6_0.extraSkillLevel3 >= 6 then
			local var_6_4 = var_0_5.new({
				tableID = var_0_26,
				start = var_0_1.ctx.battle.count,
				level = arg_6_0.extraSkillLevel3,
				skillID = arg_6_0:getPugongID(),
				fighter = arg_6_0,
				target = arg_6_0
			})

			arg_6_0:addBuffs({
				var_6_4
			})
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	if arg_7_1.basicHarm > 0 and var_0_2.weightedChoise({
		var_0_17,
		1 - var_0_17
	}) == 1 and arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_7_1.target:getTeamType() ~= arg_7_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_0 = arg_7_0:createAttackUnits({
			arg_7_1.target
		}, var_0_16)

		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end
	end

	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.skillID == var_0_11 then
		arg_7_0.greenSkilling = true

		if arg_7_0.greenPhase == 0 then
			arg_7_0.greenX = arg_7_0:getX()
			arg_7_0.greenY = arg_7_0:getY()

			if next(arg_7_0:selectTargetByTypeD1()) then
				local var_7_1 = arg_7_0:selectTargetByTypeD1()[1]

				arg_7_0:x(var_7_1:getX() + (var_7_1:getFlipX() and -50 or 50))
				arg_7_0:y(var_7_1:getY())
				arg_7_0:createSkillByID(var_0_12, arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_6:attackIndex(var_0_12))
			end
		elseif arg_7_0.greenPhase == 1 then
			if next(arg_7_0:selectTargetByTypeD2()) then
				local var_7_2 = arg_7_0:selectTargetByTypeD2()[1]

				arg_7_0:x(var_7_2:getX() + (var_7_2:getFlipX() and -50 or 50))
				arg_7_0:y(var_7_2:getY())
				arg_7_0:createSkillByID(var_0_13, arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_6:attackIndex(var_0_13))
			end
		elseif arg_7_0.greenPhase == 2 and next(arg_7_0:selectTargetByTypeD3()) then
			local var_7_3 = arg_7_0:selectTargetByTypeD3()[1]

			arg_7_0:x(var_7_3:getX() + (var_7_3:getFlipX() and -50 or 50))
			arg_7_0:y(var_7_3:getY())
			arg_7_0:createSkillByID(var_0_14, arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_6:attackIndex(var_0_14))
		end
	elseif arg_7_1.skillID == var_0_12 then
		arg_7_0.greenPhase = 1

		arg_7_0:createSkillByID(var_0_11, arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_6:attackIndex(var_0_11))

		if arg_7_0.extraSkillLevel1 > 0 then
			local var_7_4 = var_0_5.new({
				tableID = var_0_25,
				start = var_0_1.ctx.battle.count,
				level = arg_7_0.extraSkillLevel1,
				skillID = arg_7_0:getPugongID(),
				fighter = arg_7_0,
				target = arg_7_1.target
			})

			arg_7_1.target:addBuffs({
				var_7_4
			})
		end

		arg_7_0:judgeElementSkill()
	elseif arg_7_1.skillID == var_0_13 then
		arg_7_0.greenPhase = 2

		arg_7_0:createSkillByID(var_0_11, arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_6:attackIndex(var_0_11))

		if arg_7_0.extraSkillLevel1 > 0 then
			local var_7_5 = var_0_5.new({
				tableID = var_0_25,
				start = var_0_1.ctx.battle.count,
				level = arg_7_0.extraSkillLevel1,
				skillID = arg_7_0:getPugongID(),
				fighter = arg_7_0,
				target = arg_7_1.target
			})

			arg_7_1.target:addBuffs({
				var_7_5
			})
		end

		arg_7_0:judgeElementSkill()
	elseif arg_7_1.skillID == var_0_14 then
		arg_7_0:createSkillByID(var_0_15, arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_6:attackIndex(var_0_15))

		if arg_7_0.extraSkillLevel1 > 0 then
			local var_7_6 = var_0_5.new({
				tableID = var_0_25,
				start = var_0_1.ctx.battle.count,
				level = arg_7_0.extraSkillLevel1,
				skillID = arg_7_0:getPugongID(),
				fighter = arg_7_0,
				target = arg_7_1.target
			})

			arg_7_1.target:addBuffs({
				var_7_6
			})
		end

		arg_7_0:judgeElementSkill()
	elseif arg_7_1.skillID == var_0_15 then
		arg_7_0.greenPhase = 0

		arg_7_0:x(arg_7_0.greenX)
		arg_7_0:y(arg_7_0.greenY)

		arg_7_0.greenSkilling = false
	end
end

function var_0_3.judgeElementSkill(arg_8_0)
	if arg_8_0:hasElementEquipByID(var_0_30) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_0 = arg_8_0:getTargets(var_0_31)
		local var_8_1 = arg_8_0:createAttackUnits({
			arg_8_0
		}, var_0_31)

		for iter_8_0, iter_8_1 in ipairs(var_8_1) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end
	end
end

function var_0_3.isBreakImmortal(arg_9_0)
	return arg_9_0.greenSkilling or var_0_3.super.isBreakImmortal(arg_9_0)
end

function var_0_3.selectTargetByTypeD1(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.targetTeam_) do
		var_10_0 = not iter_10_1:isDeath() and not iter_10_1:isAffected() and ((not var_10_0 or not (var_10_0:getAD() < iter_10_1:getAD())) and var_10_0 or iter_10_1) or var_10_0
	end

	return {
		var_10_0
	}
end

function var_0_3.selectTargetByTypeD2(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.targetTeam_) do
		var_11_0 = not iter_11_1:isDeath() and not iter_11_1:isAffected() and ((not var_11_0 or not (var_11_0:getAP() < iter_11_1:getAP())) and var_11_0 or iter_11_1) or var_11_0
	end

	return {
		var_11_0
	}
end

function var_0_3.selectTargetByTypeD3(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.targetTeam_) do
		var_12_0 = not iter_12_1:isDeath() and not iter_12_1:isAffected() and ((not var_12_0 or not (var_12_0:getEnergy() < iter_12_1:getEnergy())) and var_12_0 or iter_12_1) or var_12_0
	end

	return {
		var_12_0
	}
end

return var_0_3
