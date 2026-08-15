local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liubiao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 20010175
local var_0_8 = 10
local var_0_9 = 1

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.silenceArea_ = false
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
	arg_2_0:updatePurpleSkill()
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getOrbOfFrontSkill(arg_3_0)
	local var_3_1 = var_0_5:buffOrb(var_3_0)

	if var_3_1 > 0 and arg_3_0.silenceArea_ then
		return var_3_1
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_3_0)
end

function var_0_3.checkEnergySkill(arg_4_0)
	if arg_4_0.silenceArea_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_4_0)
end

function var_0_3.selectTargetByTypeD1(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {
		arg_5_0
	}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and iter_5_1.__cname == arg_5_0.__cname then
			table.insert(var_5_0, iter_5_1)
		end
	end

	return var_5_0
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	if arg_6_1.target == arg_6_0 and arg_6_1.skillID == arg_6_0:getEnergySkillID() then
		arg_6_0.silenceArea_ = true

		arg_6_0:setGlobalEnergyBuffs()

		if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.CreateReport and not var_0_1.ctx.battle.isUnlimitBattle then
			if arg_6_0.isSkinSkillOn_ then
				var_0_1.ctx.battle.setupBackground("yxt2.png")
			else
				var_0_1.ctx.battle.setupBackground("yxt.png")
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)
end

function var_0_3.setGlobalEnergyBuffs(arg_7_0)
	local function var_7_0(arg_8_0, arg_8_1, arg_8_2)
		local var_8_0 = {}

		for iter_8_0, iter_8_1 in ipairs(arg_8_0) do
			local var_8_1 = var_0_4.new({
				tableID = iter_8_1,
				start = var_0_1.ctx.battle.count,
				level = arg_8_2,
				skillID = arg_8_1,
				fighter = arg_7_0
			})

			var_8_1:setYongJiu()
			table.insert(var_8_0, var_8_1)
		end

		return var_8_0
	end

	local var_7_1 = {
		var_0_7
	}
	local var_7_2 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)
	local var_7_3 = var_7_0(var_7_1, var_7_2, arg_7_0:getSkillLevelByID(var_7_2))

	for iter_7_0, iter_7_1 in ipairs(var_7_3) do
		table.insert(var_0_1.ctx.battle.globalBuffs, iter_7_1)
		var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamA, iter_7_1:getAttrType())
		var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamB, iter_7_1:getAttrType())
	end
end

function var_0_3.getAP(arg_9_0)
	if arg_9_0.silenceArea_ then
		return arg_9_0:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE * var_0_8 * arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + var_0_3.super.getAP(arg_9_0)
	end

	return var_0_3.super.getAP(arg_9_0)
end

function var_0_3.updatePurpleSkill(arg_10_0)
	if arg_10_0:isDeath() or arg_10_0:isAffected() then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if var_0_1.ctx.battle.count % 30 > 0 or arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return
	end

	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1:isApUnable() and not iter_10_1:isAdUnable() then
			table.insert(var_10_0, iter_10_1)
		end
	end

	if next(var_10_0) == nil then
		return
	end

	local var_10_1 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_10_2 = arg_10_0:createAttackUnits(var_10_0, var_10_1)

	for iter_10_2, iter_10_3 in ipairs(var_10_2) do
		table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
		table.insert(arg_10_0.records_.special_units, iter_10_3)
	end
end

function var_0_3.checkSkillBreak(arg_11_0, arg_11_1, arg_11_2)
	if arg_11_0.silenceArea_ then
		return
	end

	var_0_3.super.checkSkillBreak(arg_11_0, arg_11_1, arg_11_2)
end

function var_0_3.addBuffs(arg_12_0, arg_12_1)
	local var_12_0 = {}

	if arg_12_0.silenceArea_ then
		for iter_12_0, iter_12_1 in ipairs(arg_12_1) do
			if not iter_12_1:isFear() and not iter_12_1:isApUnable() and not iter_12_1:isAdUnable() and not iter_12_1:isExcuteAdCircle() and not iter_12_1:isAttackFriend() and not iter_12_1:isPugongOnly() then
				table.insert(var_12_0, iter_12_1)
			end
		end

		var_0_3.super.addBuffs(arg_12_0, var_12_0)

		return
	end

	var_0_3.super.addBuffs(arg_12_0, arg_12_1)
end

function var_0_3.updateUnitDataBySpecialHero(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
	local var_13_0, var_13_1, var_13_2, var_13_3, var_13_4, var_13_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)

	if arg_13_0.isSkinSkillOn_ and arg_13_0.silenceArea_ and var_13_2 > 0 and arg_13_1.target == arg_13_0 then
		local var_13_6 = arg_13_0:getEnergy()
		local var_13_7 = (var_13_6 + var_13_5 > 0 and var_13_6 + var_13_5 or 0) / var_0_2.ENERGY_DECIMAL_BASE - var_13_2 / arg_13_0:getHpLimit()

		if var_13_7 > 0 then
			arg_13_0:updateEnergyTo(math.floor(var_13_7 * var_0_2.ENERGY_DECIMAL_BASE))

			var_13_2 = 0
		else
			var_13_2 = -var_13_7 * arg_13_0:getHpLimit()
		end

		var_13_5 = 0
	end

	return var_13_0, var_13_1, var_13_2, var_13_3, var_13_4, var_13_5
end

function var_0_3.getDMP(arg_14_0)
	local var_14_0 = var_0_3.super.getDMP(arg_14_0)

	if arg_14_0.isSkinSkillOn_ then
		var_14_0 = var_0_2.PERCENT_BASE * var_0_9
	end

	return var_14_0
end

return var_0_3
