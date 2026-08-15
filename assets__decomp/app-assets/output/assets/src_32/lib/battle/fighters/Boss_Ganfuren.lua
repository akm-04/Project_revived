local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Ganfuren", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 5
local var_0_7 = {
	40010877,
	40010878,
	40010879,
	40010880,
	40010881
}
local var_0_8 = 10000801
local var_0_9 = {
	81170001,
	81170002,
	81170003,
	81170004,
	81170005
}
local var_0_10 = 81170007
local var_0_11 = 81170006
local var_0_12 = 40010876
local var_0_13 = 0
local var_0_14 = 0.05
local var_0_15 = 40010981

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("createAttack_info")
	arg_1_0:listenInfo("buff_info")

	arg_1_0.flowerCardNum_ = 0
	arg_1_0.blueShowSkillCount_ = 0
	arg_1_0.blueRecordTargets_ = {}
	arg_1_0.isBlueSkill_ = false
	arg_1_0.energyAttackNum_ = {}
	arg_1_0.curEnergyTarget_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("createAttack_info")) do
		if not iter_2_1:isDeath() and iter_2_1:getTeamType() ~= arg_2_0:getTeamType() and iter_2_1:getSummonType() == var_0_2.summonMonsterType.None then
			if arg_2_0.energyAttackNum_[iter_2_1] then
				arg_2_0.energyAttackNum_[iter_2_1] = arg_2_0.energyAttackNum_[iter_2_1] + 1
			else
				arg_2_0.energyAttackNum_[iter_2_1] = 1
			end
		end
	end

	if arg_2_0.curEnergyTarget_ and (arg_2_0.curEnergyTarget_:isDeath() or not arg_2_0.curEnergyTarget_:isHasBuffByID(var_0_12)) then
		arg_2_0.curEnergyTarget_ = nil
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_2_0 = {}

		for iter_2_2, iter_2_3 in ipairs(arg_2_0:getInfoByKey("buff_info")) do
			local var_2_1 = iter_2_3.fighter
			local var_2_2 = iter_2_3.target
			local var_2_3 = iter_2_3:getTime()

			if var_2_2:getTeamType() == arg_2_0:getTeamType() and var_2_1:getTeamType() ~= arg_2_0:getTeamType() and var_2_3 >= 60 and (iter_2_3:isApUnable() and iter_2_3:isAdUnable() or iter_2_3:isPugongOnly()) and not var_2_0[iter_2_3:getTableID()] then
				var_2_0[iter_2_3:getTableID()] = true

				arg_2_0:addFlowerCard(arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), 1)

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_2_4 = arg_2_0:createAttackUnits({
						arg_2_0
					}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					for iter_2_4, iter_2_5 in ipairs(var_2_4) do
						table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
						table.insert(arg_2_0.records_.special_units, iter_2_5)
					end
				end
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	arg_3_0.isBlueSkill_ = false

	if arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_3_0.flowerCardNum_ < var_0_6 then
		arg_3_0:addFlowerCard(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green), 1)
	elseif arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_3_0.flowerCardNum_ > 0 then
		arg_3_1.idQueue_ = {}
		arg_3_1.pretimeQueue_ = {}

		for iter_3_0 = 1, arg_3_0.flowerCardNum_ do
			local var_3_0 = var_0_9[iter_3_0]
			local var_3_1 = var_0_5:pretime(var_3_0)

			table.insert(arg_3_1.pretimeQueue_, var_3_1)
			table.insert(arg_3_1.idQueue_, var_0_8)
		end

		arg_3_0.blueRecordTargets_ = {}
		arg_3_0.blueShowSkillCount_ = 0
		arg_3_0.isBlueSkill_ = true

		arg_3_0:setImmuneControl(true)
	end

	if not arg_3_0.isBlueSkill_ then
		arg_3_0:setImmuneControl(false)
	end
end

function var_0_3.unitAfterCreate(arg_4_0, arg_4_1, arg_4_2)
	var_0_3.super.unitAfterCreate(arg_4_0, arg_4_1, arg_4_2)

	if not arg_4_2 or not next(arg_4_2) or arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) <= 0 or not arg_4_0.isBlueSkill_ then
		return
	end

	for iter_4_0, iter_4_1 in ipairs(arg_4_2) do
		if iter_4_1.skillID == var_0_8 then
			arg_4_0:removeFlowerCard(1)

			break
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_5_0.blueShowSkillCount_ = arg_5_0.blueShowSkillCount_ + 1

		local var_5_0 = var_0_9[arg_5_0.blueShowSkillCount_]

		if var_5_0 and var_5_0 > 0 then
			local var_5_1 = arg_5_0:getBlueHarmTargets(arg_5_1.target, var_5_0)
			local var_5_2 = arg_5_0:createAttackUnits(var_5_1, var_5_0)

			for iter_5_0, iter_5_1 in ipairs(var_5_2) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end
		end
	elseif var_0_5:father(arg_5_1.skillID) == arg_5_0:getEnergySkillID() and arg_5_1.target ~= arg_5_0 then
		arg_5_0.curEnergyTarget_ = arg_5_1.target
	elseif var_0_5:father(arg_5_1.skillID) == arg_5_0:getEnergySkillID() and arg_5_1.target == arg_5_0 then
		arg_5_0:addFlowerCard(arg_5_0:getEnergySkillID(), 3)
	end
end

function var_0_3.getBlueHarmTargets(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_1:getX()
	local var_6_1 = var_0_5:scope(arg_6_2)
	local var_6_2 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and var_6_1 >= math.abs(var_6_0 - iter_6_1:getX()) then
			table.insert(var_6_2, iter_6_1)
		end
	end

	return var_6_2
end

function var_0_3.addFlowerCard(arg_7_0, arg_7_1, arg_7_2)
	if not arg_7_1 or not arg_7_2 or arg_7_0.flowerCardNum_ >= var_0_6 then
		return
	end

	if arg_7_0.flowerCardNum_ > 0 then
		arg_7_0:removeBuffByID(var_0_7[arg_7_0.flowerCardNum_])
	end

	arg_7_0.flowerCardNum_ = arg_7_0.flowerCardNum_ + arg_7_2

	if arg_7_0.flowerCardNum_ > var_0_6 then
		arg_7_0.flowerCardNum_ = var_0_6
	end

	local var_7_0 = var_0_7[arg_7_0.flowerCardNum_]
	local var_7_1 = arg_7_0:newBuff({
		var_7_0
	}, arg_7_0, arg_7_1)

	arg_7_0:addBuffs(var_7_1)
end

function var_0_3.removeFlowerCard(arg_8_0, arg_8_1)
	if arg_8_0.flowerCardNum_ > 0 then
		arg_8_0:removeBuffByID(var_0_7[arg_8_0.flowerCardNum_])
	end

	arg_8_0.flowerCardNum_ = arg_8_0.flowerCardNum_ - arg_8_1

	if arg_8_0.flowerCardNum_ <= 0 then
		arg_8_0.flowerCardNum_ = 0
	else
		local var_8_0 = var_0_7[arg_8_0.flowerCardNum_]
		local var_8_1 = arg_8_0:newBuff({
			var_8_0
		}, arg_8_0, arg_8_0:getEnergySkillID())

		arg_8_0:addBuffs(var_8_1)
	end
end

function var_0_3.selectTargetByTypeD1(arg_9_0)
	local var_9_0 = arg_9_0.blueRecordTargets_
	local var_9_1 = 0

	if #var_9_0 <= 0 then
		var_9_1 = arg_9_0:getX()
	else
		var_9_1 = var_9_0[#var_9_0]:getX()
	end

	local var_9_2
	local var_9_3

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() then
			local var_9_4 = iter_9_1:getX()
			local var_9_5 = math.abs(var_9_1 - var_9_4)

			if (not var_9_2 or var_9_5 < var_9_2) and not var_0_0.table.keyof(var_9_0, iter_9_1) then
				var_9_2 = var_9_5
				var_9_3 = iter_9_1
			end
		end
	end

	local var_9_6 = {}

	if var_9_3 then
		var_9_6 = {
			var_9_3
		}

		table.insert(arg_9_0.blueRecordTargets_, var_9_3)
	elseif #var_9_0 > 0 then
		for iter_9_2 = #var_9_0, 1, -1 do
			if not var_9_0[iter_9_2]:isDeath() and not var_9_0[iter_9_2]:isAffected() then
				local var_9_7 = var_9_0[iter_9_2]

				var_9_6 = {
					var_9_7
				}

				var_0_0.table.removebyvalue(arg_9_0.blueRecordTargets_, var_9_7)
				table.insert(arg_9_0.blueRecordTargets_, var_9_7)

				break
			end
		end
	end

	return var_9_6
end

function var_0_3.selectTargetByTypeD2(arg_10_0)
	local var_10_0
	local var_10_1 = 0

	for iter_10_0, iter_10_1 in pairs(arg_10_0.energyAttackNum_) do
		if not iter_10_0:isDeath() and not iter_10_0:isAffected() and var_10_1 < iter_10_1 then
			var_10_0 = iter_10_0
			var_10_1 = iter_10_1
		end
	end

	return {
		var_10_0
	}
end

function var_0_3.applyHurtFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5)
	local var_11_0, var_11_1, var_11_2, var_11_3 = var_0_3.super.applyHurtFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5)

	if var_11_0 > 0 and arg_11_0.curEnergyTarget_ and not arg_11_0.curEnergyTarget_:isDeath() and not arg_11_0.curEnergyTarget_:isAffected() then
		local var_11_4 = var_11_0 * (var_0_13 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + var_0_14)

		var_11_0 = var_11_0 - var_11_4

		local var_11_5 = arg_11_0:newBuff({
			var_0_15
		}, arg_11_0.curEnergyTarget_, arg_11_0:getEnergySkillID())
		local var_11_6 = var_0_2.tables.dbuff:time(var_0_15) / 30

		if var_11_6 > 0 then
			var_11_5[1].change_harm = var_11_4 / var_11_6

			arg_11_0.curEnergyTarget_:addBuffs(var_11_5)
		end
	end

	return var_11_0, var_11_1, var_11_2, var_11_3
end

function var_0_3.buffAddAction(arg_12_0, arg_12_1)
	var_0_3.super:buffAddAction(arg_12_0, arg_12_1)

	if arg_12_1:getTableID() == var_0_15 and arg_12_1.change_harm and arg_12_1.change_harm > 0 then
		arg_12_1.manualHarmRevise = arg_12_1.change_harm
	end
end

function var_0_3.newBuff(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		local var_13_1 = var_0_4.new({
			tableID = iter_13_1,
			start = var_0_1.ctx.battle.count,
			level = arg_13_0:getSkillLevelByID(arg_13_3),
			skillID = arg_13_3,
			fighter = arg_13_0,
			target = arg_13_2
		})

		var_13_1:setIsHit(true)
		var_13_1:setDirection(arg_13_0:getFighterModel():getFlipX())
		table.insert(var_13_0, var_13_1)
	end

	return var_13_0
end

return var_0_3
