local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhuran", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 40011076
local var_0_7 = 10000980
local var_0_8 = 0.7
local var_0_9 = 500
local var_0_10 = 40011080
local var_0_11 = 40011083
local var_0_12 = 40011082
local var_0_13 = 0.07
local var_0_14 = 10
local var_0_15 = 40011084
local var_0_16 = 80010179
local var_0_17 = 0.3
local var_0_18 = 40011504
local var_0_19 = 40011505

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isEnergyType_ = false
	arg_2_0.energyFirstPos_ = nil
	arg_2_0.energyTotalHarm_ = 0
	arg_2_0.energyTarget_ = nil
	arg_2_0.energyAttackPreTime_ = 0
	arg_2_0.energyHarmInfo_ = {}
	arg_2_0.skinBuffTargets = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0.isEnergyType_ then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("harm_info")) do
			local var_3_0 = iter_3_1.harm
			local var_3_1 = iter_3_1.fighter

			if var_3_0 > 0 and var_3_1:getTeamType() ~= arg_3_0:getTeamType() and var_3_1:getSummonType() == var_0_2.summonMonsterType.None then
				arg_3_0.energyHarmInfo_[var_3_1] = (arg_3_0.energyHarmInfo_[var_3_1] or 0) + var_3_0
			end
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_0.energyAttackPreTime_ > 0 then
		arg_3_0.energyAttackPreTime_ = arg_3_0.energyAttackPreTime_ - 1

		if arg_3_0.energyAttackPreTime_ <= 0 and arg_3_0.energyTarget_ and not arg_3_0.energyTarget_:isDeath() and not arg_3_0.energyTarget_:isAffected() then
			local var_3_2 = arg_3_0:createAttackUnits({
				arg_3_0.energyTarget_
			}, var_0_7)

			for iter_3_2, iter_3_3 in ipairs(var_3_2) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == var_0_7 then
		for iter_4_0, iter_4_1 in pairs(arg_4_0.skinBuffTargets) do
			if iter_4_1 then
				local var_4_0 = iter_4_1[1]
				local var_4_1 = iter_4_1[2]

				if var_4_0 then
					for iter_4_2, iter_4_3 in ipairs(arg_4_0:getBuffs()) do
						if var_4_0 == iter_4_3 then
							arg_4_0:removeBuffs(var_4_0)
						end
					end
				end

				if var_4_1 then
					for iter_4_4, iter_4_5 in ipairs(iter_4_0:getBuffs()) do
						if var_4_1 == iter_4_5 then
							iter_4_0:removeBuffs(var_4_1)
						end
					end
				end
			end
		end
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_6 then
		arg_5_0.isEnergyType_ = true
		arg_5_0.energyTotalHarm_ = 0
	elseif arg_5_1:getTableID() == var_0_15 then
		local var_5_0 = #arg_5_0:getBuffsByID(var_0_15)

		arg_5_0:updateStateNumber(var_5_0 + 1)
	end

	if arg_5_0.skinSkillID_ == var_0_16 and arg_5_1:getTableID() == var_0_12 then
		local var_5_1 = arg_5_1.target
		local var_5_2 = var_5_1:getAD() * var_0_17
		local var_5_3 = var_0_5.new({
			tableID = var_0_19,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getLevel(),
			skillID = var_0_16,
			fighter = arg_5_0,
			target = var_5_1
		})

		var_5_3.manualRevise = -var_5_2

		var_5_1:addBuffs({
			var_5_3
		})

		local var_5_4 = var_0_5.new({
			tableID = var_0_18,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getLevel(),
			skillID = var_0_16,
			fighter = arg_5_0,
			target = arg_5_0
		})

		var_5_4.manualRevise = var_5_2

		arg_5_0:addBuffs({
			var_5_4
		})

		arg_5_0.skinBuffTargets[var_5_1] = {
			var_5_4,
			var_5_3
		}
	end
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	var_0_3.super.buffRemoveAction(arg_6_0, arg_6_1)

	if arg_6_1:getTableID() == var_0_6 then
		arg_6_0:useEnergyAttackSkill()
	elseif arg_6_1:getTableID() == var_0_10 then
		local var_6_0 = var_0_11

		if arg_6_1.target ~= arg_6_0 then
			var_6_0 = var_0_12
		end

		local var_6_1 = arg_6_0:createNewBuffs({
			var_6_0
		}, arg_6_1.target, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_6_1.target:addBuffs(var_6_1)
	end
end

function var_0_3.useEnergyAttackSkill(arg_7_0)
	if arg_7_0:isDeath() then
		return
	end

	arg_7_0.isEnergyType_ = false

	local var_7_0, var_7_1 = arg_7_0:getEnergyTarget()

	if not var_7_0 then
		return
	end

	arg_7_0.energyFirstPos_ = {
		x = arg_7_0:getX(),
		y = arg_7_0:getY(),
		flipX_ = arg_7_0:getFlipX()
	}

	local var_7_2 = var_7_0:getFlipX()
	local var_7_3 = var_7_2 and 1 or -1
	local var_7_4 = var_7_0:getX() + var_7_3 * 100

	if var_7_0:isBoss() then
		var_7_4 = var_7_0:getX() - 100
		var_7_2 = false
	end

	arg_7_0:pos(var_7_4, var_7_0:getY())
	arg_7_0:flipX(var_7_2)
	arg_7_0:playAttack(var_0_4:attackIndex(var_0_7), function()
		if arg_7_0.energyFirstPos_ and next(arg_7_0.energyFirstPos_) then
			arg_7_0:pos(arg_7_0.energyFirstPos_.x, arg_7_0.energyFirstPos_.y)
			arg_7_0:flipX(arg_7_0.energyFirstPos_.flipX_)
		end
	end)

	arg_7_0.energyAttackPreTime_ = var_0_4:pretime(var_0_7)
	arg_7_0.energyTarget_ = var_7_0
	arg_7_0.energyTotalHarm_ = var_7_1
end

function var_0_3.getEnergyTarget(arg_9_0)
	local var_9_0
	local var_9_1 = 0

	if arg_9_0.energyHarmInfo_ and next(arg_9_0.energyHarmInfo_) then
		for iter_9_0, iter_9_1 in pairs(arg_9_0.energyHarmInfo_) do
			if not iter_9_0:isDeath() and not iter_9_0:isAffected() and var_9_1 < iter_9_1 then
				var_9_1 = iter_9_1
				var_9_0 = iter_9_0
			end
		end
	else
		local var_9_2 = arg_9_0:getTargets(var_0_7)

		if next(var_9_2) then
			var_9_0 = var_9_2[1]
		end
	end

	arg_9_0.energyHarmInfo_ = {}

	return var_9_0, var_9_1
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if arg_10_4 > 0 and arg_10_1.skillID == var_0_7 and arg_10_0.energyTotalHarm_ > 0 then
		local var_10_0 = arg_10_0.energyTotalHarm_ * var_0_8 * arg_10_1.target:getADJianShang()
		local var_10_1 = var_0_9 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

		if var_10_1 < var_10_0 then
			var_10_0 = var_10_1
		end

		arg_10_4 = arg_10_4 + var_10_0
		arg_10_0.energyTotalHarm_ = 0
	end

	return arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.targetTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1 ~= arg_11_0 then
			table.insert(var_11_0, iter_11_1)
		end
	end

	table.sort(var_11_0, function(arg_12_0, arg_12_1)
		return math.abs(arg_11_0:getX() - arg_12_0:getX()) < math.abs(arg_11_0:getX() - arg_12_1:getX())
	end)

	local var_11_1 = {}

	for iter_11_2, iter_11_3 in ipairs(var_11_0) do
		if #var_11_1 < 3 then
			table.insert(var_11_1, iter_11_3)
		end
	end

	return var_11_1
end

function var_0_3.selectTargetByTypeD2(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0
	local var_13_1 = 0

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.targetTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1 ~= arg_13_0 and var_13_1 < iter_13_1:getAD() then
			var_13_0 = iter_13_1
			var_13_1 = iter_13_1:getAD()
		end
	end

	return {
		var_13_0
	}
end

function var_0_3.applyHurtFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_14_1.attackType == var_0_2.AttackType.AD and arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_14_2 > arg_14_0:getHpLimit() * var_0_13 and #arg_14_0:getBuffsByID(var_0_15) < var_0_14 then
		local var_14_0 = arg_14_0:createAttackUnits({
			arg_14_0
		}, arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_14_0, iter_14_1 in ipairs(var_14_0) do
			table.insert(arg_14_0.moveAttackUnits_, iter_14_1)
			table.insert(arg_14_0.records_.special_units, iter_14_1)
		end
	end

	return var_0_3.super.applyHurtFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5)
end

function var_0_3.checkEnergySkill(arg_15_0)
	if arg_15_0.isEnergyType_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_15_0)
end

return var_0_3
