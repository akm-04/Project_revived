local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuanshao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = 40010678
local var_0_7 = 60
local var_0_8 = 150
local var_0_9 = 80010071

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.purpleCount_ = var_0_8
	arg_2_0.energyExtraTarget = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport and not arg_3_0:isDeath() and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_3_0.purpleCount_ = arg_3_0.purpleCount_ - 1

		if arg_3_0.purpleCount_ < 1 then
			arg_3_0.purpleCount_ = var_0_8

			arg_3_0:updatePurpleSkill()
		end
	end

	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_9 then
		arg_3_0.GainBuffsTillNow = arg_3_0.GainBuffsTillNow or {}
		arg_3_0.DebuffsTillNow = arg_3_0.DebuffsTillNow or {}

		arg_3_0:updateBuffInfo()
	end
end

function var_0_3.updateBuffInfo(arg_4_0)
	for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
		local var_4_0 = iter_4_1.target

		if iter_4_1:getBuffForm() == var_0_2.BuffForm.GAIN then
			arg_4_0.GainBuffsTillNow[var_4_0] = (arg_4_0.GainBuffsTillNow[var_4_0] or 0) + 1
			arg_4_0.GainBuffsTillNow[var_4_0] = math.min(10, arg_4_0.GainBuffsTillNow[var_4_0])
		elseif iter_4_1:getBuffForm() == var_0_2.BuffForm.DEBUFF then
			arg_4_0.DebuffsTillNow[var_4_0] = (arg_4_0.DebuffsTillNow[var_4_0] or 0) + 1
			arg_4_0.DebuffsTillNow[var_4_0] = math.min(10, arg_4_0.DebuffsTillNow[var_4_0])
		end
	end
end

function var_0_3.getAndResetDebuffCountByFighter(arg_5_0, arg_5_1)
	if arg_5_0.isSkinSkillOn_ and arg_5_0.skinSkillID_ == var_0_9 then
		local var_5_0 = arg_5_0.DebuffsTillNow[arg_5_1] or 0

		arg_5_0.DebuffsTillNow[arg_5_1] = 0

		return var_5_0
	else
		return arg_5_1:getDebuffNum()
	end
end

function var_0_3.getAndResetGainBuffCountByFighter(arg_6_0, arg_6_1)
	if arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_9 then
		local var_6_0 = arg_6_0.GainBuffsTillNow[arg_6_1] or 0

		arg_6_0.GainBuffsTillNow[arg_6_1] = 0

		return var_6_0
	else
		return arg_6_1:getGainBuffNum()
	end
end

function var_0_3.createUnits(arg_7_0, arg_7_1)
	var_0_3.super.createUnits(arg_7_0, arg_7_1)

	if arg_7_1.rootID_ == arg_7_0:getEnergySkillID() then
		arg_7_0.energyExtraTarget = {}
	end
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	if arg_8_1:getSkillID() == arg_8_0:getEnergySkillID() and arg_8_1:getTableID() ~= var_0_6 and arg_8_0.energyExtraTarget[arg_8_1.target] then
		arg_8_1:setExtraTime(var_0_7)
	end
end

function var_0_3.updatePurpleSkill(arg_9_0)
	local var_9_0 = 0
	local var_9_1 = 0

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		if not iter_9_1:isDeath() and iter_9_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_9_0 = var_9_0 + iter_9_1:getEnergy()
		end
	end

	for iter_9_2, iter_9_3 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_3:isDeath() and iter_9_3:getSummonType() == var_0_2.summonMonsterType.None then
			var_9_1 = var_9_1 + iter_9_3:getEnergy()
		end
	end

	local var_9_2 = var_0_4:selectChildren(arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
	local var_9_3 = var_9_1 <= var_9_0 and var_9_2[1] or var_9_2[2]
	local var_9_4 = arg_9_0:createAttackUnits(var_0_5.A2(arg_9_0, var_9_3), var_9_3)

	for iter_9_4, iter_9_5 in ipairs(var_9_4) do
		table.insert(arg_9_0.moveAttackUnits_, iter_9_5)
		table.insert(arg_9_0.records_.special_units, iter_9_5)
	end
end

function var_0_3.selectTargetByTypeD1(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0
	local var_10_1

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and not var_10_0 then
			var_10_0 = iter_10_1
		elseif not iter_10_1:isDeath() and not iter_10_1:isAffected() and var_10_1 and var_10_1 < iter_10_1:getGainBuffNum() then
			var_10_0 = iter_10_1
		end
	end

	if not var_10_0 then
		return {}
	end

	return {
		var_10_0
	}
end

function var_0_3.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = var_0_3.super.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	if var_0_4:father(arg_11_1.skillID) == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_11_2 > 0 then
		var_11_2 = var_11_2 * (1 + arg_11_0:getAndResetDebuffCountByFighter(arg_11_1.target) * 0.2)
	end

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5
end

function var_0_3.checkUnitBuffs(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0, var_12_1, var_12_2, var_12_3, var_12_4 = var_0_3.super.checkUnitBuffs(arg_12_0, arg_12_1, arg_12_2)

	if var_0_4:father(arg_12_1.skillID) == arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		for iter_12_0, iter_12_1 in ipairs(var_12_0) do
			local var_12_5 = arg_12_0:getAndResetGainBuffCountByFighter(iter_12_1.target)

			iter_12_1.leftCount_ = iter_12_1.leftCount_ * (2 + var_12_5)
		end
	end

	return var_12_0, var_12_1, var_12_2, var_12_3, var_12_4
end

function var_0_3.applySingleUnit(arg_13_0, arg_13_1)
	var_0_3.super.applySingleUnit(arg_13_0, arg_13_1)

	if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport and arg_13_1.skillID == arg_13_0:getEnergySkillID() then
		local var_13_0 = arg_13_1.target

		if var_13_0:getDebuffNum() > 0 then
			arg_13_0.energyExtraTarget[var_13_0] = true
		end

		local var_13_1 = var_0_4:selectChildren(arg_13_0:getEnergySkillID())

		if #var_13_1 < 3 then
			return
		end

		local var_13_2 = var_13_1[var_13_0.hero_:getHeroType()]
		local var_13_3 = {
			var_13_0
		}
		local var_13_4 = arg_13_0:createAttackUnits(var_13_3, var_13_2)

		for iter_13_0, iter_13_1 in ipairs(var_13_4) do
			table.insert(arg_13_0.moveAttackUnits_, iter_13_1)
			table.insert(arg_13_0.records_.special_units, iter_13_1)
		end
	end
end

return var_0_3
