local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Ganfuren", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 5
local var_0_7 = {
	10000794,
	10000795,
	10000796,
	10000797,
	10000798
}
local var_0_8 = 10000800
local var_0_9 = 10000799
local var_0_10 = 0
local var_0_11 = 0.6
local var_0_12 = 40010868
local var_0_13 = 180
local var_0_14 = 80010162
local var_0_15 = 60

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

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.FlowerCardBuffs = {
			40012189,
			40012190,
			40012191,
			40012192,
			40012193
		}
		arg_2_0.BlueShowSkillID = 10002045
		arg_2_0.EnergyShowBuffID = 40012188
		arg_2_0.EnergySkill = 10002044
	else
		arg_2_0.FlowerCardBuffs = {
			40010877,
			40010878,
			40010879,
			40010880,
			40010881
		}
		arg_2_0.BlueShowSkillID = 10000801
		arg_2_0.EnergyShowBuffID = 40010876
		arg_2_0.EnergySkill = 50010162
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("createAttack_info")) do
		if not iter_3_1:isDeath() and iter_3_1:getTeamType() ~= arg_3_0:getTeamType() and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None then
			if arg_3_0.energyAttackNum_[iter_3_1] then
				arg_3_0.energyAttackNum_[iter_3_1] = arg_3_0.energyAttackNum_[iter_3_1] + 1
			else
				arg_3_0.energyAttackNum_[iter_3_1] = 1
			end
		end
	end

	if arg_3_0.curEnergyTarget_ and (arg_3_0.curEnergyTarget_:isDeath() or not arg_3_0.curEnergyTarget_:isHasBuffByID(arg_3_0.EnergyShowBuffID)) then
		arg_3_0.curEnergyTarget_ = nil
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_3_0 = {}

		for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			local var_3_1 = iter_3_3.fighter
			local var_3_2 = iter_3_3.target
			local var_3_3 = iter_3_3:getTime()

			if var_3_2:getTeamType() == arg_3_0:getTeamType() and var_3_1:getTeamType() ~= arg_3_0:getTeamType() and var_3_3 >= 60 and (iter_3_3:isApUnable() and iter_3_3:isAdUnable() or iter_3_3:isPugongOnly()) and not var_3_0[iter_3_3:getTableID()] then
				var_3_0[iter_3_3:getTableID()] = true

				arg_3_0:addFlowerCard(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), 1)

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_3_4 = arg_3_0:createAttackUnits({
						arg_3_0
					}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					for iter_3_4, iter_3_5 in ipairs(var_3_4) do
						table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
						table.insert(arg_3_0.records_.special_units, iter_3_5)
					end
				end
			end
		end
	end

	if arg_3_0.skinSkillID_ == var_0_14 and var_0_1.ctx.battle.count % var_0_13 == 1 then
		arg_3_0:addFlowerCard(var_0_14, 1)
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	arg_4_0.isBlueSkill_ = false

	if var_0_5:father(arg_4_1.rootID_) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_4_0.flowerCardNum_ < var_0_6 then
		arg_4_0:addFlowerCard(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green), 1)
	elseif var_0_5:father(arg_4_1.rootID_) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_4_0.flowerCardNum_ > 0 then
		arg_4_1.idQueue_ = {}
		arg_4_1.pretimeQueue_ = {}

		for iter_4_0 = 1, arg_4_0.flowerCardNum_ do
			local var_4_0 = var_0_7[iter_4_0]
			local var_4_1 = var_0_5:pretime(var_4_0)

			table.insert(arg_4_1.pretimeQueue_, var_4_1)
			table.insert(arg_4_1.idQueue_, arg_4_0.BlueShowSkillID)
		end

		arg_4_0.blueRecordTargets_ = {}
		arg_4_0.blueShowSkillCount_ = 0
		arg_4_0.isBlueSkill_ = true

		arg_4_0:setImmuneControl(true)
	end

	if not arg_4_0.isBlueSkill_ then
		arg_4_0:setImmuneControl(false)
	end
end

function var_0_3.unitAfterCreate(arg_5_0, arg_5_1, arg_5_2)
	var_0_3.super.unitAfterCreate(arg_5_0, arg_5_1, arg_5_2)

	if not arg_5_2 or not next(arg_5_2) or arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) <= 0 or not arg_5_0.isBlueSkill_ then
		return
	end

	for iter_5_0, iter_5_1 in ipairs(arg_5_2) do
		if iter_5_1.skillID == arg_5_0.BlueShowSkillID then
			arg_5_0:removeFlowerCard(1)

			break
		end
	end
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == arg_6_0.BlueShowSkillID and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_6_0.blueShowSkillCount_ = arg_6_0.blueShowSkillCount_ + 1

		local var_6_0 = var_0_7[arg_6_0.blueShowSkillCount_]

		if var_6_0 and var_6_0 > 0 then
			local var_6_1 = arg_6_0:getBlueHarmTargets(arg_6_1.target, var_6_0)
			local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_6_0)

			for iter_6_0, iter_6_1 in ipairs(var_6_2) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	elseif var_0_5:father(arg_6_1.skillID) == arg_6_0.EnergySkill and arg_6_1.target ~= arg_6_0 then
		arg_6_0.curEnergyTarget_ = arg_6_1.target
	elseif var_0_5:father(arg_6_1.skillID) == arg_6_0.EnergySkill and arg_6_1.target == arg_6_0 then
		arg_6_0:addFlowerCard(arg_6_0:getEnergySkillID(), 3)
	end
end

function var_0_3.getBlueHarmTargets(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1:getX()
	local var_7_1 = var_0_5:scope(arg_7_2)
	local var_7_2 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and var_7_1 >= math.abs(var_7_0 - iter_7_1:getX()) then
			table.insert(var_7_2, iter_7_1)
		end
	end

	return var_7_2
end

function var_0_3.addFlowerCard(arg_8_0, arg_8_1, arg_8_2)
	if not arg_8_1 or not arg_8_2 or arg_8_0.flowerCardNum_ >= var_0_6 then
		return
	end

	if arg_8_0.flowerCardNum_ > 0 then
		arg_8_0:removeBuffByID(arg_8_0.FlowerCardBuffs[arg_8_0.flowerCardNum_])
	end

	arg_8_0.flowerCardNum_ = arg_8_0.flowerCardNum_ + arg_8_2

	if arg_8_0.flowerCardNum_ > var_0_6 then
		arg_8_0.flowerCardNum_ = var_0_6
	end

	local var_8_0 = arg_8_0.FlowerCardBuffs[arg_8_0.flowerCardNum_]
	local var_8_1 = arg_8_0:newBuff({
		var_8_0
	}, arg_8_0, arg_8_1)

	arg_8_0:addBuffs(var_8_1)
end

function var_0_3.removeFlowerCard(arg_9_0, arg_9_1)
	if arg_9_0.flowerCardNum_ > 0 then
		arg_9_0:removeBuffByID(arg_9_0.FlowerCardBuffs[arg_9_0.flowerCardNum_])
	end

	if arg_9_0.skinSkillID_ == var_0_14 then
		arg_9_0:updateEnergyBy(var_0_15 * arg_9_1)
	end

	arg_9_0.flowerCardNum_ = arg_9_0.flowerCardNum_ - arg_9_1

	if arg_9_0.flowerCardNum_ <= 0 then
		arg_9_0.flowerCardNum_ = 0
	else
		local var_9_0 = arg_9_0.FlowerCardBuffs[arg_9_0.flowerCardNum_]
		local var_9_1 = arg_9_0:newBuff({
			var_9_0
		}, arg_9_0, arg_9_0:getEnergySkillID())

		arg_9_0:addBuffs(var_9_1)
	end
end

function var_0_3.selectTargetByTypeD1(arg_10_0)
	local var_10_0 = arg_10_0.blueRecordTargets_
	local var_10_1 = 0

	if #var_10_0 <= 0 then
		var_10_1 = arg_10_0:getX()
	else
		var_10_1 = var_10_0[#var_10_0]:getX()
	end

	local var_10_2
	local var_10_3

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() then
			local var_10_4 = iter_10_1:getX()
			local var_10_5 = math.abs(var_10_1 - var_10_4)

			if (not var_10_2 or var_10_5 < var_10_2) and not var_0_0.table.keyof(var_10_0, iter_10_1) then
				var_10_2 = var_10_5
				var_10_3 = iter_10_1
			end
		end
	end

	local var_10_6 = {}

	if var_10_3 then
		var_10_6 = {
			var_10_3
		}

		table.insert(arg_10_0.blueRecordTargets_, var_10_3)
	elseif #var_10_0 > 0 then
		for iter_10_2 = #var_10_0, 1, -1 do
			if not var_10_0[iter_10_2]:isDeath() and not var_10_0[iter_10_2]:isAffected() then
				local var_10_7 = var_10_0[iter_10_2]

				var_10_6 = {
					var_10_7
				}

				var_0_0.table.removebyvalue(arg_10_0.blueRecordTargets_, var_10_7)
				table.insert(arg_10_0.blueRecordTargets_, var_10_7)

				break
			end
		end
	end

	return var_10_6
end

function var_0_3.selectTargetByTypeD2(arg_11_0)
	local var_11_0
	local var_11_1 = 0

	for iter_11_0, iter_11_1 in pairs(arg_11_0.energyAttackNum_) do
		if not iter_11_0:isDeath() and not iter_11_0:isAffected() and var_11_1 < iter_11_1 then
			var_11_0 = iter_11_0
			var_11_1 = iter_11_1
		end
	end

	return {
		var_11_0
	}
end

function var_0_3.applyHurtFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5)
	local var_12_0, var_12_1, var_12_2, var_12_3 = var_0_3.super.applyHurtFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5)

	if var_12_0 > 0 and arg_12_0.curEnergyTarget_ and not arg_12_0.curEnergyTarget_:isDeath() and not arg_12_0.curEnergyTarget_:isAffected() then
		local var_12_4 = var_12_0 * (var_0_10 * arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + var_0_11)

		var_12_0 = var_12_0 - var_12_4

		local var_12_5 = arg_12_0:newBuff({
			var_0_12
		}, arg_12_0.curEnergyTarget_, arg_12_0:getEnergySkillID())
		local var_12_6 = var_0_2.tables.dbuff:time(var_0_12) / 30

		if var_12_6 > 0 then
			var_12_5[1].change_harm = var_12_4 / var_12_6

			arg_12_0.curEnergyTarget_:addBuffs(var_12_5)
		end
	end

	return var_12_0, var_12_1, var_12_2, var_12_3
end

function var_0_3.buffAddAction(arg_13_0, arg_13_1)
	var_0_3.super:buffAddAction(arg_13_0, arg_13_1)

	if arg_13_1:getTableID() == var_0_12 and arg_13_1.change_harm and arg_13_1.change_harm > 0 then
		arg_13_1.manualHarmRevise = arg_13_1.change_harm
	end
end

function var_0_3.newBuff(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_1) do
		local var_14_1 = var_0_4.new({
			tableID = iter_14_1,
			start = var_0_1.ctx.battle.count,
			level = arg_14_0:getSkillLevelByID(arg_14_3),
			skillID = arg_14_3,
			fighter = arg_14_0,
			target = arg_14_2
		})

		var_14_1:setIsHit(true)
		var_14_1:setDirection(arg_14_0:getFighterModel():getFlipX())
		table.insert(var_14_0, var_14_1)
	end

	return var_14_0
end

return var_0_3
