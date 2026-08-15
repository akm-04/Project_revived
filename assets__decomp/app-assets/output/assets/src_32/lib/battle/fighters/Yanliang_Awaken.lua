local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yanliang", var_0_1.ctx.battle.requireFighter("Yanliang"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0.2
local var_0_6 = 0
local var_0_7 = 40010313
local var_0_8 = var_0_2.tables.dbuff

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.harmCount_ = 0
	arg_1_0.awakeHeroNums_ = 0
	arg_1_0.skillRush_ = {}
	arg_1_0.canRush_ = nil
	arg_1_0.purpleTarget_ = nil
	arg_1_0.records_.purple_target = {}
	arg_1_0.purpleTargetReportData_ = {}
	arg_1_0.isAwakeTwiceJudge_ = false
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and not arg_2_0.purpleTarget_ and arg_2_1.target:getSummonType() == var_0_2.summonMonsterType.None then
		if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
			if arg_2_0.purpleTargetReportData_[tostring(var_0_1.ctx.battle.count)] then
				arg_2_0.purpleTarget_ = arg_2_1.target

				arg_2_0:addPurpleBuff()
				arg_2_0.purpleTarget_:moveByX(50, false)
				arg_2_0.purpleTarget_:moveByY(arg_2_0:getY() - arg_2_0.purpleTarget_:getY(), false)
			end
		else
			local var_2_0 = var_0_5 + var_0_6 * arg_2_0:getSkillLevelByID(arg_2_1.skillID)

			if var_0_2.weightedChoise({
				var_2_0,
				1 - var_2_0
			}) == 1 then
				arg_2_0.purpleTarget_ = arg_2_1.target

				arg_2_0:addPurpleBuff()

				local var_2_1
				local var_2_2 = arg_2_0:getFlipX() and -1 or 1

				arg_2_0.purpleTarget_:moveByX(50 * var_2_2, false)
				arg_2_0.purpleTarget_:moveByY(arg_2_0:getY() - arg_2_0.purpleTarget_:getY(), false)

				arg_2_0.records_.purple_target[tostring(var_0_1.ctx.battle.count)] = 1
			end
		end
	end
end

function var_0_3.writeReport(arg_3_0)
	local var_3_0 = var_0_3.super.writeReport(arg_3_0)

	var_3_0.purple_target = arg_3_0.records_.purple_target

	return var_3_0
end

function var_0_3.addPurpleBuff(arg_4_0)
	if not arg_4_0.purpleTarget_ then
		return
	end

	local var_4_0 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
	local var_4_1 = var_0_4.new({
		tableID = var_0_7,
		start = var_0_1.ctx.battle.count,
		level = arg_4_0:getSkillLevelByID(var_4_0),
		skillID = var_4_0,
		fighter = arg_4_0,
		target = arg_4_0.purpleTarget_
	})

	arg_4_0.purpleTarget_:addBuffs({
		var_4_1
	})
end

function var_0_3.setupReport(arg_5_0, arg_5_1)
	var_0_3.super.setupReport(arg_5_0, arg_5_1)

	arg_5_0.purpleTargetReportData_ = arg_5_1.purple_target
end

function var_0_3.removePurpleBuff(arg_6_0)
	var_0_3.super.removePurpleBuff(arg_6_0)

	if arg_6_0.purpleTarget_ then
		arg_6_0.purpleTarget_:removeBuffByID(var_0_7)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_0 = arg_6_0:createAttackUnits({
				arg_6_0.purpleTarget_
			}, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_6_0, iter_6_1 in ipairs(var_6_0) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_7_0, arg_7_1)
	var_0_3.super.beginAttackEnd(arg_7_0, arg_7_1)

	if arg_7_1.rootID_ == arg_7_0:getEnergySkillID() then
		arg_7_0.isAwakeTwiceJudge_ = false
	end
end

function var_0_3.toDoPerFrames(arg_8_0)
	var_0_3.super.toDoPerFrames(arg_8_0)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_8_0.awakeHeroNums_ > 0 and not arg_8_0.unitSkills_ and not arg_8_0.isAwakeTwiceJudge_ then
		local var_8_0 = arg_8_0:createAttackUnits({
			arg_8_0
		}, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		for iter_8_0, iter_8_1 in ipairs(var_8_0) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end

		arg_8_0.isAwakeTwiceJudge_ = true
	end
end

function var_0_3.getTargets(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = var_0_3.super.getTargets(arg_9_0, arg_9_1, arg_9_2)

	if arg_9_1 == arg_9_0:getEnergySkillID() and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_9_0.awakeHeroNums_ = #var_9_0
	end

	return var_9_0
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	var_0_3.super.buffAddAction(arg_10_0, arg_10_1)

	if arg_10_1:getSkillID() == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) then
		local var_10_0 = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)
		local var_10_1 = arg_10_1:getTableID()
		local var_10_2 = math.max(0, arg_10_0.awakeHeroNums_ - 1)

		arg_10_1.manualDharm = (var_10_0 * var_0_8:step(var_10_1) + var_0_8:init(var_10_1)) * var_10_2
		arg_10_0.awakeHeroNums_ = 0
	end
end

return var_0_3
