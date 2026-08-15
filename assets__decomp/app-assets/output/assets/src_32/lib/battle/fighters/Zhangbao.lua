local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangbao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.cabinetSkillTable
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 300
local var_0_7 = 40010476
local var_0_8 = 0.3
local var_0_9 = 10000588
local var_0_10 = 10000586
local var_0_11 = 10000587
local var_0_12 = 0
local var_0_13 = 10
local var_0_14 = 40010477
local var_0_15 = 10400003

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.blueColdCD_ = {}
	arg_2_0.blueForceFighters_ = {}
	arg_2_0.greenEnemyHarm_ = 0
	arg_2_0.greenSpecialTarget_ = {}
	arg_2_0.records_.green_buff = {}
	arg_2_0.greenCureHp_ = 0
	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel = 0
	arg_2_0.currentSkillID_ = nil
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_3_0.greenEnemyHarm_ = 0

		if arg_3_0:isHasBuffByID(var_0_14) then
			arg_3_0:removeGreenSelfBuff()
			arg_3_0:removeBuffByID(var_0_14)
		end

		arg_3_0.greenSpecialTarget_ = {}
	end
end

function var_0_3.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_4_0 > 0 and var_0_5:type(arg_4_1.skillID) ~= var_0_2.AttackType.Cure and arg_4_4 > 0 then
		arg_4_4 = math.max(0, arg_4_4 - (var_0_12 + var_0_13 * var_4_0))
	end

	return var_0_3.super.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_1.skillID == var_0_9 then
		arg_5_0.greenEnemyHarm_ = arg_5_0.greenEnemyHarm_ + arg_5_4

		table.insert(arg_5_0.greenSpecialTarget_, arg_5_1.target)
	elseif arg_5_1.skillID == var_0_11 then
		arg_5_5 = arg_5_5 + arg_5_0.greenCureHp_
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.removeGreenSelfBuff(arg_6_0)
	local var_6_0 = arg_6_0:getBuffByID(var_0_14):getDHarm()
	local var_6_1 = {}

	if var_6_0 > 0 then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0.greenSpecialTarget_) do
			if not iter_6_1:isDeath() then
				table.insert(var_6_1, iter_6_1)
			end
		end

		if #var_6_1 > 0 then
			arg_6_0.greenCureHp_ = math.ceil(var_6_0 / #var_6_1)

			local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_0_11)

			for iter_6_2, iter_6_3 in ipairs(var_6_2) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
				table.insert(arg_6_0.records_.special_units, iter_6_3)
			end
		end
	end
end

function var_0_3.removeBuffs(arg_7_0, arg_7_1)
	if arg_7_1:getTableID() == var_0_14 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_7_0:removeGreenSelfBuff()
	end

	var_0_3.super.removeBuffs(arg_7_0, arg_7_1)
end

function var_0_3.toDoPerFrames(arg_8_0)
	if arg_8_0:isDeath() then
		return
	end

	if not arg_8_0.extraSkillJudge then
		arg_8_0.extraSkillJudge = true
		arg_8_0.extraSkillLevel = arg_8_0.hero_:skillBook()[tostring(var_0_15)] or 0
	end

	if next(arg_8_0.blueColdCD_) then
		for iter_8_0, iter_8_1 in pairs(arg_8_0.blueColdCD_) do
			if iter_8_1 > 0 then
				arg_8_0.blueColdCD_[iter_8_0] = arg_8_0.blueColdCD_[iter_8_0] - 1
			end
		end
	end

	if arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_8_2, iter_8_3 in ipairs(arg_8_0:getInfoByKey("harm_info")) do
			local var_8_0 = iter_8_3.fighter
			local var_8_1 = iter_8_3.target

			if var_8_1 ~= arg_8_0 and var_8_1:getSummonType() == var_0_2.summonMonsterType.None and not var_8_0:isAffected() then
				local var_8_2 = arg_8_0:getTeamType()

				if var_8_1:getTeamType() == var_8_2 and var_8_0:getTeamType() ~= var_8_2 and var_8_1:getHp() <= var_8_1:getHpLimit() * var_0_8 and (not arg_8_0.blueColdCD_[var_8_1] or arg_8_0.blueColdCD_[var_8_1] <= 0 and not var_8_0:isHasBuffByID(var_0_7)) then
					local var_8_3 = arg_8_0:createAttackUnits({
						var_8_0
					}, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

					for iter_8_4, iter_8_5 in ipairs(var_8_3) do
						table.insert(arg_8_0.moveAttackUnits_, iter_8_5)
						table.insert(arg_8_0.records_.special_units, iter_8_5)
					end

					table.insert(arg_8_0.blueForceFighters_, var_8_0)

					arg_8_0.blueColdCD_[var_8_1] = var_0_6

					arg_8_0:addExtraSkllHp(var_8_1)
				end
			end
		end
	end
end

function var_0_3.addExtraSkllHp(arg_9_0, arg_9_1)
	if arg_9_0.extraSkillLevel > 0 and not arg_9_1:isDeath() then
		local var_9_0 = arg_9_1:getHp()
		local var_9_1 = arg_9_1:getHpLimit() * (arg_9_0.extraSkillLevel * var_0_4:attrValues(var_0_15) * 0.01) * arg_9_1:getDCureRate()

		arg_9_1:updateHp(var_9_1 + var_9_0, true)
		arg_9_1.fighterModel:playHPDeltas({
			{
				var_9_1,
				false
			}
		}, nil)
	end
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	var_0_3.super.buffAddAction(arg_10_0, arg_10_1)

	if arg_10_1:getTableID() == var_0_7 then
		arg_10_1:setForceTarget(arg_10_0)
	elseif arg_10_1:getSkillID() == var_0_10 then
		local var_10_0 = arg_10_0.greenEnemyHarm_

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			arg_10_0.records_.green_buff[tostring(var_0_1.ctx.battle.count)] = arg_10_0.greenEnemyHarm_
		else
			var_10_0 = arg_10_0.greenBuffNum_[tostring(var_0_1.ctx.battle.count)]
		end

		arg_10_1.manualDharm = var_10_0
	end
end

function var_0_3.die(arg_11_0)
	var_0_3.super.die(arg_11_0)

	if next(arg_11_0.blueForceFighters_) then
		for iter_11_0 = #arg_11_0.blueForceFighters_, 1, -1 do
			arg_11_0.blueForceFighters_[iter_11_0]:removeBuffByID(var_0_7)
		end

		arg_11_0.blueForceFighters_ = {}
	end
end

function var_0_3.deathFeedback(arg_12_0, arg_12_1)
	if next(arg_12_0.blueForceFighters_) then
		for iter_12_0, iter_12_1 in ipairs(arg_12_0.blueForceFighters_) do
			if iter_12_1 == arg_12_1 then
				table.remove(arg_12_0.blueForceFighters_, iter_12_0)

				break
			end
		end
	end
end

function var_0_3.setupReport(arg_13_0, arg_13_1)
	var_0_3.super.setupReport(arg_13_0, arg_13_1)

	arg_13_0.greenBuffNum_ = arg_13_1.green_buff
end

function var_0_3.writeReport(arg_14_0)
	local var_14_0 = var_0_3.super.writeReport(arg_14_0)

	var_14_0.green_buff = arg_14_0.records_.green_buff

	return var_14_0
end

function var_0_3.selectTargetByTypeD1(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = {}
	local var_15_1
	local var_15_2

	for iter_15_0, iter_15_1 in ipairs(arg_15_0.targetTeam_) do
		if not iter_15_1:isDeath() and not iter_15_1:isAffected() and iter_15_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_15_3 = math.abs(arg_15_0:getX() - iter_15_1:getX())

			if not var_15_1 or var_15_3 < var_15_1 then
				var_15_2 = iter_15_1
				var_15_1 = var_15_3
			end
		end
	end

	return {
		var_15_2
	}
end

return var_0_3
