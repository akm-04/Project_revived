local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Simashi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10000388
local var_0_8 = 10000387
local var_0_9 = 10000381
local var_0_10 = {
	40010100,
	40010101,
	40010102
}
local var_0_11 = {
	40010091,
	40010092
}
local var_0_12 = {
	40010086,
	40010087
}
local var_0_13 = {
	40010088,
	40010089
}
local var_0_14 = 40010093
local var_0_15 = 10000383
local var_0_16 = {
	40010096
}
local var_0_17 = 40010099
local var_0_18 = 0
local var_0_19 = 0.004
local var_0_20 = 90
local var_0_21 = 0
local var_0_22 = 11007
local var_0_23 = 80010098

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("flip_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isEnergyBuff_ = false
	arg_2_0.greenSkillTarget_ = nil
	arg_2_0.greenSkillCount_ = nil
	arg_2_0.blueSkillTarget_ = {}
	arg_2_0.skinJudge = false
	arg_2_0.skinTarget = nil
	arg_2_0.upHp = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_23 and not arg_3_0.skinJudge then
		arg_3_0.skinJudge = true

		for iter_3_0, iter_3_1 in pairs(arg_3_0.selfTeam_) do
			if iter_3_1:getTableID() == var_0_22 then
				arg_3_0.skinTarget = iter_3_1
			end
		end

		if arg_3_0.skinTarget and not arg_3_0.skinTarget:isDeath() then
			arg_3_0.upHp = arg_3_0:getHpLimit()

			arg_3_0:resetHpLimit(arg_3_0:getHpLimit() * 2)
		end
	end

	if arg_3_0.isEnergyBuff_ and arg_3_0:isHasBuffByID(var_0_17) and (not arg_3_0.greenSkillTarget_ or arg_3_0.greenSkillTarget_:isDeath()) then
		arg_3_0:removeBuffByID(var_0_17)

		arg_3_0.isEnergyBuff_ = false
	end

	if arg_3_0.greenSkillCount_ then
		arg_3_0.greenSkillCount_ = arg_3_0.greenSkillCount_ - 1

		if arg_3_0.greenSkillCount_ <= 0 then
			arg_3_0.greenSkillCount_ = nil
		end
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("flip_info")) do
		if next(arg_3_0.blueSkillTarget_) then
			for iter_3_4, iter_3_5 in ipairs(arg_3_0.blueSkillTarget_) do
				if not iter_3_3:isDeath() and not iter_3_3:isAffected() and iter_3_5.hero == iter_3_3 then
					if iter_3_3:getFlipX() == (iter_3_3:getTeamType() == var_0_1.ctx.battle.teamA) then
						arg_3_0:addExtraBlueSkill(iter_3_3)
						table.remove(arg_3_0.blueSkillTarget_, iter_3_4)
					end

					break
				end
			end
		end
	end

	if next(arg_3_0.blueSkillTarget_) then
		for iter_3_6 = #arg_3_0.blueSkillTarget_, 1, -1 do
			local var_3_0 = arg_3_0.blueSkillTarget_[iter_3_6]

			if var_3_0.hero:isDeath() then
				table.remove(arg_3_0.blueSkillTarget_, iter_3_6)
			else
				var_3_0.count = var_3_0.count - 1

				if var_3_0.count <= 0 then
					table.remove(arg_3_0.blueSkillTarget_, iter_3_6)
				end
			end
		end
	end

	if arg_3_0:isDeath() then
		return
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	if arg_4_1.skillID == var_0_8 then
		arg_4_0:addEnergyBuff(arg_4_1.target)
		arg_4_0:addEnergyHarm(arg_4_1.target)

		arg_4_0.isEnergyBuff_ = true
	end

	if arg_4_1.skillID == var_0_9 then
		arg_4_0.greenSkillTarget_ = arg_4_1.target
		arg_4_0.greenSkillCount_ = var_0_6:pretime(arg_4_1.skillID)
	end

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_4_0:addTeamDHarmBuff()
	end

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_4_0 = arg_4_1.target

		if var_4_0:getFlipX() == (var_4_0:getTeamType() == var_0_1.ctx.battle.teamA) then
			arg_4_0:addExtraBlueSkill(var_4_0)
		else
			local var_4_1 = {
				hero = var_4_0,
				count = var_0_5:time(var_0_14)
			}

			table.insert(arg_4_0.blueSkillTarget_, var_4_1)
		end
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)
end

function var_0_3.addEnergyBuff(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0:getEnergySkillID()
	local var_5_1 = arg_5_0:getSkillLevelByID(var_5_0)
	local var_5_2 = 0.3
	local var_5_3 = {}

	for iter_5_0, iter_5_1 in ipairs(var_0_10) do
		local var_5_4 = var_0_4.new({
			tableID = iter_5_1,
			start = var_0_1.ctx.battle.count,
			level = var_5_1,
			skillID = var_5_0,
			fighter = arg_5_0,
			target = arg_5_1
		})

		if iter_5_0 == 1 then
			var_5_4.manualRevise = arg_5_0:getAP() * var_5_2
		elseif iter_5_0 == 2 then
			var_5_4.manualRevise = arg_5_0:getAPBaoJi() * var_5_2
		else
			var_5_4.manualRevise = arg_5_0:getHuJia() * var_5_2
		end

		var_5_4:setYongJiu()
		var_5_4:setIsHit(true)
		var_5_4:setDirection(arg_5_0:getFighterModel():getFlipX())
		table.insert(var_5_3, var_5_4)
	end

	arg_5_1:addBuffs(var_5_3)
end

function var_0_3.energyAction(arg_6_0, arg_6_1)
	if arg_6_1 == arg_6_0:getEnergySkillID() or arg_6_1 == var_0_7 then
		arg_6_0:getFighterModel():playEnergyEffect_()
		arg_6_0:updateEnergyTo(arg_6_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

		if arg_6_0:getTeamType() == var_0_2.TeamType.A or arg_6_0.isInArena_ then
			arg_6_0:addBlackLayer()
		end
	end
end

function var_0_3.addEnergyHarm(arg_7_0, arg_7_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_7_0 = {}
	local var_7_1 = var_0_6:scope(var_0_7) / 2
	local var_7_2 = arg_7_1:getX()

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and var_7_1 >= math.abs(iter_7_1:getX() - var_7_2) then
			table.insert(var_7_0, iter_7_1)
		end
	end

	local var_7_3 = arg_7_0:createAttackUnits(var_7_0, var_0_7)

	for iter_7_2, iter_7_3 in ipairs(var_7_3) do
		table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
		table.insert(arg_7_0.records_.special_units, iter_7_3)
	end
end

function var_0_3.addTeamDHarmBuff(arg_8_0)
	for iter_8_0, iter_8_1 in ipairs(arg_8_0.selfTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1 ~= arg_8_0 then
			local var_8_0 = arg_8_0:newBuff(var_0_16, iter_8_1, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			iter_8_1:addBuffs(var_8_0)
		end
	end
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)

	if arg_9_1.rootID_ ~= arg_9_0:getPugongID() and arg_9_1.rootID_ ~= arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_9_0.greenSkillTarget_ then
		arg_9_0:addExtraGreenBuff()
	end
end

function var_0_3.addExtraGreenBuff(arg_10_0)
	if not arg_10_0.greenSkillTarget_ then
		return
	end

	local var_10_0 = arg_10_0:newBuff(var_0_11, arg_10_0.greenSkillTarget_, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

	arg_10_0.greenSkillTarget_:addBuffs(var_10_0)
end

function var_0_3.addExtraBlueSkill(arg_11_0, arg_11_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_11_0 = {
		arg_11_1
	}
	local var_11_1 = arg_11_0:createAttackUnits(var_11_0, var_0_15)

	for iter_11_0, iter_11_1 in ipairs(var_11_1) do
		table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
		table.insert(arg_11_0.records_.special_units, iter_11_1)
	end
end

function var_0_3.getFrontSkill(arg_12_0)
	if arg_12_0:isPugongOnly() then
		return arg_12_0:getPugongID()
	end

	if arg_12_0.isEnergySkill_ and arg_12_0:getEnergySkillID() > 0 then
		if not arg_12_0.greenSkillTarget_ then
			return var_0_7
		else
			local var_12_0 = var_0_6:repulsionHero(var_0_8)
			local var_12_1 = arg_12_0.greenSkillTarget_:getTableID()

			for iter_12_0, iter_12_1 in ipairs(var_12_0) do
				if var_12_1 == iter_12_1 then
					return var_0_7
				end
			end

			return arg_12_0:getEnergySkillID()
		end
	end

	if next(arg_12_0.startSkillQueue_) then
		if arg_12_0.startSkillQueue_[1] == arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and not next(arg_12_0:selectTargetByTypeD1()) then
			return arg_12_0:getPugongID()
		end

		return arg_12_0.startSkillQueue_[1]
	end

	return arg_12_0.skillQueue_[1]
end

function var_0_3.isBreakImmortal(arg_13_0)
	if arg_13_0.greenSkillCount_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_13_0)
	end
end

function var_0_3.selectTargetByTypeD1(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = math.random(tonumber(os.time()))

	math.randomseed(tonumber(tostring(os.time() + var_14_0):reverse():sub(1, 6)))

	local var_14_1 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.selfTeam_) do
		if iter_14_1 ~= arg_14_0 and not iter_14_1:isDeath() and not iter_14_1:isAffected() and iter_14_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_14_1, iter_14_1)
		end
	end

	if not var_14_1 or next(var_14_1) == nil then
		return {}
	end

	math.randomseed(var_14_0)

	return {
		var_14_1[math.random(#var_14_1)]
	}
end

function var_0_3.selectTargetByTypeD2(arg_15_0, arg_15_1, arg_15_2)
	if arg_15_0.greenSkillTarget_ then
		local var_15_0 = var_0_6:repulsionHero(arg_15_1)
		local var_15_1 = arg_15_0.greenSkillTarget_:getTableID()

		for iter_15_0, iter_15_1 in ipairs(var_15_0) do
			if var_15_1 == iter_15_1 then
				return {}
			end
		end

		return {
			arg_15_0.greenSkillTarget_
		}
	else
		return {}
	end
end

function var_0_3.newBuff(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	local var_16_0 = {}

	for iter_16_0, iter_16_1 in ipairs(arg_16_1) do
		local var_16_1 = var_0_4.new({
			tableID = iter_16_1,
			start = var_0_1.ctx.battle.count,
			level = arg_16_0:getSkillLevelByID(arg_16_3),
			skillID = arg_16_3,
			fighter = arg_16_0,
			target = arg_16_2
		})

		var_16_1:setIsHit(true)
		var_16_1:setDirection(arg_16_0:getFighterModel():getFlipX())
		table.insert(var_16_0, var_16_1)
	end

	return var_16_0
end

function var_0_3.shieldFeedBack(arg_17_0, arg_17_1, arg_17_2)
	var_0_3.super.shieldFeedBack(arg_17_0, arg_17_1, arg_17_2)

	local var_17_0 = var_0_20 + var_0_21 * arg_17_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	arg_17_0:updateEnergyBy(var_17_0)
end

function var_0_3.neverDieFeedBack(arg_18_0, arg_18_1)
	var_0_3.super.neverDieFeedBack(arg_18_0, arg_18_1)

	local var_18_0 = arg_18_0:getHp() * (var_0_18 + var_0_19 * arg_18_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

	arg_18_1:updateHp(var_18_0)

	for iter_18_0, iter_18_1 in ipairs(var_0_10) do
		arg_18_1:removeBuffByID(iter_18_1)
	end

	local var_18_1 = arg_18_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_18_2 = arg_18_1:getX() - var_18_1 * 100
	local var_18_3 = arg_18_1:getY()

	arg_18_0:x(var_18_2)
	arg_18_0:y(var_18_3)
	arg_18_0:updateHp(0)
	arg_18_0:die()
end

function var_0_3.deathFeedback(arg_19_0, arg_19_1)
	var_0_3.super.deathFeedback(arg_19_0, arg_19_1)

	if arg_19_1 == arg_19_0.greenSkillTarget_ then
		arg_19_0.greenSkillTarget_ = nil

		for iter_19_0, iter_19_1 in ipairs(var_0_13) do
			arg_19_0:removeBuffByID(var_0_13)
		end
	end

	if arg_19_0.isSkinSkillOn_ and arg_19_0.skinSkillID_ == var_0_23 and arg_19_0.skinTarget and arg_19_1 == arg_19_0.skinTarget then
		arg_19_0.hpLimit_ = math.max(arg_19_0.hpLimit_ - arg_19_0.upHp, 0)

		arg_19_0:updateHp(math.min(arg_19_0.hpLimit_, arg_19_0:getHp()))
	end
end

function var_0_3.die(arg_20_0)
	if arg_20_0.greenSkillTarget_ and not arg_20_0.greenSkillTarget_:isDeath() then
		for iter_20_0, iter_20_1 in ipairs(var_0_12) do
			arg_20_0.greenSkillTarget_:removeBuffByID(iter_20_1)
		end
	end

	var_0_3.super.die(arg_20_0)
end

return var_0_3
