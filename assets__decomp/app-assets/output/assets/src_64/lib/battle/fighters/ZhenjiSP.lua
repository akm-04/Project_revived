local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhenjiSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.elementEquip
local var_0_7 = 0.10300000000000001
local var_0_8 = 30010265
local var_0_9 = 10002256
local var_0_10 = 0.05
local var_0_11 = 40012416
local var_0_12 = 40012417
local var_0_13 = 0.2
local var_0_14 = 40012423
local var_0_15 = 40012424
local var_0_16 = 900
local var_0_17 = 10002259
local var_0_18 = 80010265
local var_0_19 = 5
local var_0_20 = {
	40012720,
	40012721
}
local var_0_21 = 20001508
local var_0_22 = 40012769
local var_0_23 = {
	40012770,
	40012771
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.iceTarget_ = {}
	arg_1_0.purpleBuffCDCount = var_0_16
	arg_1_0.changeIceBuffShow = false
	arg_1_0.isAddPurpleBuff = false
	arg_1_0.IceBuffNum = 0
	arg_1_0.records_.ice_num = {}
	arg_1_0.records_.pugong_add_ice = {}
	arg_1_0.skinRempCount = 0
	arg_1_0.skinBuffCount = 0
	arg_1_0.elementTarget = nil
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.IceShowBuffs = {
			40012735,
			40012736,
			40012737,
			40012738,
			40012739
		}
		arg_2_0.PurpleChildSkillID = 10002561
		arg_2_0.EnergyChildSkill1 = 10002562
	else
		arg_2_0.IceShowBuffs = {
			40012418,
			40012419,
			40012420,
			40012421,
			40012422
		}
		arg_2_0.PurpleChildSkillID = 10002257
		arg_2_0.EnergyChildSkill1 = 10002258
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	arg_3_0:updateIceNums()

	arg_3_0.purpleBuffCDCount = arg_3_0.purpleBuffCDCount + 1

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_3_0.isAddPurpleBuff and arg_3_0.purpleBuffCDCount > var_0_16 and arg_3_0.IceBuffNum > 0 then
		arg_3_0.isAddPurpleBuff = true
		arg_3_0.purpleBuffCDCount = 0

		local var_3_0 = arg_3_0:createNewBuffs({
			var_0_14
		}, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		arg_3_0:addBuffs(var_3_0)
	end

	if arg_3_0.changeIceBuffShow == true then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_1:isDeath() then
				local var_3_1 = arg_3_0:getIceNum(iter_3_1)

				for iter_3_2, iter_3_3 in ipairs(arg_3_0.IceShowBuffs) do
					if iter_3_1:getBuffsByID(iter_3_3) then
						iter_3_1:removeBuffByID(iter_3_3)
					end
				end

				if var_3_1 > 0 then
					local var_3_2 = arg_3_0:createNewBuffs({
						arg_3_0.IceShowBuffs[var_3_1]
					}, iter_3_1, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					iter_3_1:addBuffs(var_3_2)
				end
			end
		end

		arg_3_0.changeIceBuffShow = false
	end

	if arg_3_0.IceBuffNum == 0 and arg_3_0:isHasBuffByID(var_0_14) then
		arg_3_0:removeBuffByID(var_0_14)

		arg_3_0.purpleBuffCDCount = var_0_16
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.target

	if arg_4_1.skillID == arg_4_0:getPugongID() and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if (arg_4_0.pugongAddIceBuff_[tostring(var_0_1.ctx.battle.count)] or 1) == 1 then
				local var_4_1 = 1

				arg_4_0:updateIceBuff(arg_4_1.target, var_4_1)
			end
		else
			local var_4_2 = var_0_2.weightedChoise({
				var_0_7,
				1 - var_0_7
			})

			arg_4_0.records_.pugong_add_ice[tostring(var_0_1.ctx.battle.count)] = var_4_2

			if var_4_2 == 1 then
				local var_4_3 = 1

				arg_4_0:updateIceBuff(arg_4_1.target, var_4_3)
			end
		end
	elseif arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			local var_4_4 = arg_4_0.iceNum_[tostring(var_0_1.ctx.battle.count)] or 1

			arg_4_0:updateIceBuff(arg_4_1.target, var_4_4)
		else
			local var_4_5 = math.random(2)

			arg_4_0.records_.ice_num[tostring(var_0_1.ctx.battle.count)] = var_4_5

			arg_4_0:updateIceBuff(arg_4_1.target, var_4_5)
		end
	elseif arg_4_1.skillID == var_0_8 then
		local var_4_6 = arg_4_0:getBlueRoundSkillTarget(arg_4_1.target, var_0_8)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_7 = arg_4_0:createAttackUnits(var_4_6, var_0_9)

			for iter_4_0, iter_4_1 in ipairs(var_4_7) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	elseif arg_4_1.skillID == var_0_9 then
		local var_4_8 = 1

		arg_4_0:updateIceBuff(arg_4_1.target, var_4_8)
	elseif arg_4_1.skillID == arg_4_0.EnergyChildSkill1 then
		local var_4_9 = 1

		arg_4_0:updateIceBuff(arg_4_1.target, var_4_9)
	elseif arg_4_1.skillID == var_0_17 then
		local var_4_10 = 1

		arg_4_0:updateIceBuff(arg_4_1.target, var_4_10)
	end

	if arg_4_0:getTeamType() ~= var_4_0:getTeamType() then
		local var_4_11 = false

		arg_4_0:judgeIceStone(var_4_0, var_4_11)
	end
end

function var_0_3.judgeIceStone(arg_5_0, arg_5_1, arg_5_2)
	if not arg_5_0.iceTarget_[arg_5_1] then
		arg_5_0.iceTarget_[arg_5_1] = 0

		return
	end

	local var_5_0 = arg_5_0.iceTarget_[arg_5_1] * var_0_13

	if var_0_2.weightedChoise({
		var_5_0,
		1 - var_5_0
	}) == 1 then
		arg_5_2 = true
	end

	if arg_5_2 == true then
		local var_5_1 = arg_5_0:createNewBuffs({
			var_0_11
		}, arg_5_1, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_5_1:addBuffs(var_5_1)
	end
end

function var_0_3.updateIceBuff(arg_6_0, arg_6_1, arg_6_2)
	if not arg_6_0.iceTarget_[arg_6_1] then
		arg_6_0.iceTarget_[arg_6_1] = 0
	end

	if arg_6_0.iceTarget_[arg_6_1] == 0 and arg_6_2 > 0 then
		local var_6_0 = true

		arg_6_0:judgeIceStone(arg_6_1, var_6_0)
	end

	local var_6_1 = arg_6_0.iceTarget_[arg_6_1]

	arg_6_0.iceTarget_[arg_6_1] = arg_6_0.iceTarget_[arg_6_1] + arg_6_2
	arg_6_0.iceTarget_[arg_6_1] = math.max(0, arg_6_0.iceTarget_[arg_6_1])
	arg_6_0.iceTarget_[arg_6_1] = math.min(5, arg_6_0.iceTarget_[arg_6_1])
	arg_6_0.changeIceBuffShow = true

	local var_6_2 = arg_6_0.iceTarget_[arg_6_1] - var_6_1

	if arg_6_0.skinSkillIndex_ == 1 and var_6_2 > 0 then
		arg_6_0.skinBuffCount = arg_6_0.skinBuffCount + var_6_2

		if arg_6_0.skinRempCount < math.floor(arg_6_0.skinBuffCount / var_0_19) then
			arg_6_0.skinRempCount = math.floor(arg_6_0.skinBuffCount / var_0_19)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_3 = arg_6_0:createAttackUnits({
					arg_6_0
				}, var_0_18)

				for iter_6_0, iter_6_1 in ipairs(var_6_3) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
					table.insert(arg_6_0.records_.special_units, iter_6_1)
				end
			end
		end
	end
end

function var_0_3.getIceNum(arg_7_0, arg_7_1)
	if not arg_7_0.iceTarget_[arg_7_1] then
		arg_7_0.iceTarget_[arg_7_1] = 0
	end

	return arg_7_0.iceTarget_[arg_7_1]
end

function var_0_3.updateIceNums(arg_8_0)
	local function var_8_0(arg_9_0, arg_9_1, arg_9_2)
		local var_9_0 = arg_9_2:getBuffsByID(arg_9_1)

		if arg_9_0 > #var_9_0 then
			local var_9_1 = arg_9_0 - #var_9_0

			for iter_9_0 = 1, var_9_1 do
				local var_9_2 = arg_8_0:createNewBuffs({
					arg_9_1
				}, arg_9_2, var_0_18)

				arg_9_2:addBuffs(var_9_2)
			end
		elseif arg_9_0 < #var_9_0 then
			local var_9_3 = #var_9_0 - arg_9_0
			local var_9_4 = 0
			local var_9_5 = arg_9_2:getBuffsByID(arg_9_1)

			for iter_9_1 = #var_9_5, 1, -1 do
				if var_9_4 < var_9_3 then
					local var_9_6 = var_9_5[iter_9_1]

					arg_9_2:removeBuffs(var_9_6)

					var_9_4 = var_9_4 + 1
				else
					break
				end
			end
		end
	end

	local var_8_1
	local var_8_2

	arg_8_0.IceBuffNum = 0

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		local var_8_3 = arg_8_0:getIceNum(iter_8_1)

		arg_8_0.IceBuffNum = arg_8_0.IceBuffNum + var_8_3

		if arg_8_0:hasElementEquipByID(var_0_21) then
			var_8_0(var_8_3, var_0_22, iter_8_1)

			if var_8_3 > 0 and (not var_8_1 or var_8_2 < var_8_3) then
				var_8_1 = iter_8_1
				var_8_2 = var_8_3
			end
		end
	end

	if arg_8_0.skinSkillIndex_ == 1 then
		var_8_0(arg_8_0.IceBuffNum, var_0_20[1], arg_8_0)
		var_8_0(arg_8_0.IceBuffNum, var_0_20[2], arg_8_0)
	end

	if arg_8_0.elementTarget and arg_8_0.elementTarget ~= var_8_1 then
		arg_8_0.elementTarget:removeBuffByID(var_0_23[1])
		arg_8_0.elementTarget:removeBuffByID(var_0_23[2])
	end

	if var_8_1 then
		var_8_0(1, var_0_23[1], var_8_1)
		var_8_0(1, var_0_23[2], var_8_1)

		arg_8_0.elementTarget = var_8_1
	end
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	var_0_3.super.buffAddAction(arg_10_0, arg_10_1)

	if arg_10_1:getTableID() == var_0_22 then
		local var_10_0 = var_0_21

		arg_10_1.manualRevise = var_0_6:battleAttr(var_10_0, arg_10_0:getElementEquipLevelByID(var_10_0)) * arg_10_0.hero_:getElementEquipActiveRate(var_10_0)
	end
end

function var_0_3.removeIceBuffs(arg_11_0, arg_11_1)
	arg_11_0:updateIceNums()

	if arg_11_1 < 1 or arg_11_0.IceBuffNum < 1 then
		return
	end

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.sideTeam_) do
		local var_11_0 = arg_11_0:getIceNum(iter_11_1)

		if arg_11_1 > 0 then
			if var_11_0 > 0 then
				arg_11_0:updateIceBuff(iter_11_1, -1)

				arg_11_1 = arg_11_1 - 1
			end
		else
			return
		end
	end

	if arg_11_1 > 0 then
		arg_11_0:removeIceBuffs(arg_11_1)
	end
end

function var_0_3.selectTargetByTypeD1(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0
	local var_12_1 = 0

	for iter_12_0, iter_12_1 in pairs(arg_12_0.sideTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() then
			if not var_12_0 then
				var_12_0 = iter_12_1
				var_12_1 = arg_12_0:getIceNum(iter_12_1)
			else
				local var_12_2 = arg_12_0:getIceNum(iter_12_1)

				if var_12_1 < var_12_2 then
					var_12_0 = iter_12_1
					var_12_1 = var_12_2
				end
			end
		end
	end

	return {
		var_12_0
	}
end

function var_0_3.getBlueRoundSkillTarget(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {}
	local var_13_1, var_13_2 = arg_13_1:getPos()
	local var_13_3 = var_0_5:scope(arg_13_2)
	local var_13_4, var_13_5 = var_0_4.getTeam(arg_13_1)

	for iter_13_0, iter_13_1 in ipairs(var_13_4) do
		local var_13_6, var_13_7 = iter_13_1:getPos()

		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and var_13_3 >= math.abs(var_13_1 - var_13_6) and iter_13_1 ~= arg_13_1 then
			table.insert(var_13_0, iter_13_1)
		end
	end

	return var_13_0
end

function var_0_3.updateUnitDataByFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)
	local var_14_0, var_14_1, var_14_2, var_14_3, var_14_4, var_14_5 = var_0_3.super.updateUnitDataByFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)
	local var_14_6 = arg_14_1.target

	if arg_14_1.skillID == arg_14_0.PurpleChildSkillID then
		local var_14_7 = math.min(5, arg_14_0.IceBuffNum)

		var_14_3 = var_14_3 * var_14_7

		arg_14_0:removeIceBuffs(var_14_7)

		if arg_14_0:isHasBuffByID(var_0_15) then
			arg_14_0:removeBuffByID(var_0_15)

			arg_14_0.purpleBuffCDCount = 0
		end
	elseif arg_14_1.skillID == var_0_8 then
		local var_14_8 = arg_14_0.iceTarget_[var_14_6] or 0
		local var_14_9 = arg_14_0:getHpLimit()
		local var_14_10 = var_14_6:getHpLimit() * var_0_10 * var_14_8

		var_14_2 = var_14_2 + math.min(var_14_10, var_14_9)

		arg_14_0:updateIceBuff(var_14_6, -var_14_8)
	end

	return var_14_0, var_14_1, var_14_2, var_14_3, var_14_4, var_14_5
end

function var_0_3.buffRemoveAction(arg_15_0, arg_15_1)
	if arg_15_1:getTableID() == var_0_14 then
		arg_15_0.isAddPurpleBuff = false
	end
end

function var_0_3.neverDieFeedBack(arg_16_0, arg_16_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_16_0 = arg_16_0:createNewBuffs({
			var_0_15
		}, arg_16_0, arg_16_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		arg_16_0:addBuffs(var_16_0)

		local var_16_1 = arg_16_0:createAttackUnits({
			arg_16_0
		}, arg_16_0.PurpleChildSkillID)

		for iter_16_0, iter_16_1 in ipairs(var_16_1) do
			table.insert(arg_16_0.moveAttackUnits_, iter_16_1)
			table.insert(arg_16_0.records_.special_units, iter_16_1)
		end
	end
end

function var_0_3.setupReport(arg_17_0, arg_17_1)
	var_0_3.super.setupReport(arg_17_0, arg_17_1)

	arg_17_0.iceNum_ = arg_17_1.ice_num
	arg_17_0.pugongAddIceBuff_ = arg_17_1.pugong_add_ice
end

function var_0_3.writeReport(arg_18_0)
	local var_18_0 = var_0_3.super.writeReport(arg_18_0)

	var_18_0.ice_num = arg_18_0.records_.ice_num
	var_18_0.pugong_add_ice = arg_18_0.records_.pugong_add_ice

	return var_18_0
end

return var_0_3
