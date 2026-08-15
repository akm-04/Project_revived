local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Feiyi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.cabinetSkillTable
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 0.004
local var_0_8 = 0
local var_0_9 = 30000
local var_0_10 = 40010994
local var_0_11 = 10000911
local var_0_12 = 2
local var_0_13 = 40010992
local var_0_14 = 40010993
local var_0_15 = 0
local var_0_16 = 0.002
local var_0_17 = 5
local var_0_18 = 20040002
local var_0_19 = 20040005
local var_0_20 = 40012132
local var_0_21 = 40012133
local var_0_22 = 10001983

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyTargets_ = {}
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel1 = 0
	arg_1_0.addAPBaojiRate = 0
	arg_1_0.extraSkillLevel2 = 0
	arg_1_0.addADRate = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true

		local var_2_0 = arg_2_0.hero_:skillBook()

		arg_2_0.extraSkillLevel1 = var_2_0[tostring(var_0_18)] or 0
		arg_2_0.addAPBaojiRate = arg_2_0.extraSkillLevel1 * var_0_5:attrValues(var_0_18) * 0.01
		arg_2_0.extraSkillLevel2 = var_2_0[tostring(var_0_19)] or 0
		arg_2_0.addADRate = arg_2_0.extraSkillLevel2 * var_0_5:attrValues(var_0_19) * 0.01
	end
end

function var_0_3.getAPBaoJi(arg_3_0)
	local var_3_0 = var_0_3.super.getAPBaoJi(arg_3_0)

	if arg_3_0.extraSkillLevel1 > 0 then
		var_3_0 = var_3_0 + arg_3_0:getADBaoJi() * arg_3_0.addAPBaojiRate
	end

	return var_3_0
end

function var_0_3.getAD(arg_4_0)
	local var_4_0 = var_0_3.super.getAD(arg_4_0)

	if arg_4_0.extraSkillLevel2 > 0 then
		var_4_0 = var_4_0 + arg_4_0:getAP() * arg_4_0.addADRate
	end

	return var_4_0
end

function var_0_3.selectTargetByTypeD1(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = 0
	local var_5_1

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and (not var_5_1 or var_5_0 > iter_5_1:getHp() / iter_5_1:getHpLimit()) then
			var_5_1 = iter_5_1
			var_5_0 = iter_5_1:getHp() / iter_5_1:getHpLimit()
		end
	end

	return {
		var_5_1
	}
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_4 > 0 and arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_6_1.target:getSummonType() ~= var_0_2.summonMonsterType.None then
		arg_6_4 = arg_6_4 * var_0_12
	elseif arg_6_4 > 0 and arg_6_1.skillID == var_0_11 and arg_6_1.change_harm and arg_6_1.change_harm > 0 then
		arg_6_4 = arg_6_4 + arg_6_1.change_harm
	end

	if arg_6_4 > 0 and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_6_0 = (var_0_16 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) + var_0_15) * arg_6_4
		local var_6_1 = arg_6_0:newBuff({
			var_0_14
		}, arg_6_1.target, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		var_6_1[1].manualHarmRevise = var_6_0 / var_0_17

		arg_6_1.target:addBuffs(var_6_1)

		local var_6_2 = arg_6_0:newBuff({
			var_0_13
		}, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		var_6_2[1].manualHarmRevise = var_6_0 / var_0_17

		arg_6_0:addBuffs(var_6_2)

		arg_6_6 = arg_6_6 + var_6_0
		arg_6_4 = arg_6_4 + var_6_0
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	if arg_7_1:getTableID() == var_0_21 then
		local var_7_0 = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_7 + var_0_8
		local var_7_1 = arg_7_1.target:getHpLimit() * var_7_0

		if var_7_1 > var_0_9 then
			var_7_1 = var_0_9
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			arg_7_1:setManualDharm(var_7_1)
		end
	end

	var_0_3.super.buffAddAction(arg_7_0, arg_7_1)

	if arg_7_1:getTableID() == var_0_10 or arg_7_1:getTableID() == var_0_20 then
		local var_7_2 = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_7 + var_0_8
		local var_7_3 = arg_7_1.target:getHpLimit() * var_7_2

		if var_7_3 > var_0_9 then
			var_7_3 = var_0_9
		end

		table.insert(arg_7_0.energyTargets_, {
			target = arg_7_1.target,
			dHp = var_7_3
		})

		local var_7_4 = arg_7_1.target:getTempHpLimit() + var_7_3

		arg_7_1.target:setTempHpLimit(var_7_4)

		local var_7_5 = arg_7_1.target:getHp()

		if var_7_5 > arg_7_1.target:getHpLimit() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_6 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_11)

			for iter_7_0, iter_7_1 in ipairs(var_7_6) do
				iter_7_1.change_harm = var_7_5 - arg_7_1.target:getHpLimit()

				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		end
	end
end

function var_0_3.buffRemoveAction(arg_8_0, arg_8_1)
	var_0_3.super.buffRemoveAction(arg_8_0, arg_8_1)

	if arg_8_1:getTableID() == var_0_10 or arg_8_1:getTableID() == var_0_20 then
		for iter_8_0 = 1, #arg_8_0.energyTargets_ do
			if arg_8_0.energyTargets_[iter_8_0].target == arg_8_1.target then
				local var_8_0 = arg_8_1.target:getTempHpLimit() - arg_8_0.energyTargets_[iter_8_0].dHp

				arg_8_1.target:setTempHpLimit(var_8_0)
				table.remove(arg_8_0.energyTargets_, iter_8_0)

				break
			end
		end
	end
end

function var_0_3.newBuff(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_1) do
		local var_9_1 = var_0_4.new({
			tableID = iter_9_1,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0:getSkillLevelByID(arg_9_3),
			skillID = arg_9_3,
			fighter = arg_9_0,
			target = arg_9_2
		})

		var_9_1:setIsHit(true)
		var_9_1:setDirection(arg_9_0:getFighterModel():getFlipX())
		table.insert(var_9_0, var_9_1)
	end

	return var_9_0
end

return var_0_3
