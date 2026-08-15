local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guohuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10000512
local var_0_7 = 10000513
local var_0_8 = 40010332
local var_0_9 = 40010333
local var_0_10 = 40010336
local var_0_11 = {
	40010334,
	40010335
}
local var_0_12 = 150
local var_0_13 = 600
local var_0_14 = 45
local var_0_15 = 1
local var_0_16 = 80010118
local var_0_17 = 10000918
local var_0_18 = 40011021
local var_0_19 = 12000512
local var_0_20 = 40011024
local var_0_21 = 40011022
local var_0_22 = 1
local var_0_23 = 10000924
local var_0_24 = 0.3
local var_0_25 = 0.005
local var_0_26 = 0.1
local var_0_27 = 40010337
local var_0_28 = var_0_2.tables.elementEquip
local var_0_29 = 20001494
local var_0_30 = 10002393
local var_0_31 = 40012600

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenTargets_ = {}
	arg_1_0.greenSkillCD_ = {}
	arg_1_0.greemHurtHarm_ = 0
	arg_1_0.purpleCount_ = 0
	arg_1_0.blueCount_ = 150
	arg_1_0.skinTargetsCount = {}
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if var_0_6 == arg_2_1.skillID or arg_2_1.skillID == var_0_19 then
		local var_2_0 = false

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.greenTargets_) do
			if iter_2_1 == arg_2_1.target then
				var_2_0 = true
			end
		end

		if not var_2_0 then
			table.insert(arg_2_0.greenTargets_, arg_2_1.target)
		end
	elseif arg_2_1.skillID == var_0_23 and var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if not arg_2_0.skinTargetsCount[arg_2_1.target] then
			arg_2_0.skinTargetsCount[arg_2_1.target] = 0
		end

		arg_2_0.skinTargetsCount[arg_2_1.target] = arg_2_0.skinTargetsCount[arg_2_1.target] + 1

		if arg_2_0.skinTargetsCount[arg_2_1.target] >= var_0_22 then
			arg_2_1.target:removeBuffByID(var_0_18)
		end
	end
end

function var_0_3.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_4 > 0 and arg_3_0.isSkinSkillOn_ and arg_3_1.skillID == var_0_17 and arg_3_1.fighter == arg_3_0 and arg_3_1.change_harm and arg_3_1.change_harm > 0 then
		arg_3_4 = arg_3_4 + arg_3_1.change_harm * arg_3_0:getADJianShang()
	end

	if next(arg_3_0.greenTargets_) and arg_3_1.attackType == var_0_2.AttackType.AD and arg_3_4 > 0 and (not arg_3_0.greenSkillCD_[arg_3_1.fighter] or arg_3_0.greenSkillCD_[arg_3_1.fighter] < 1) then
		local var_3_0 = {}

		arg_3_0.greenSkillCD_[arg_3_1.fighter] = var_0_14

		for iter_3_0 = #arg_3_0.greenTargets_, 1, -1 do
			local var_3_1 = arg_3_0.greenTargets_[iter_3_0]

			if var_3_1:isDeath() then
				table.remove(arg_3_0.greenTargets_, iter_3_0)
			elseif not var_3_1:isHasBuffByID(var_0_9) and not var_3_1:isHasBuffByID(var_0_21) then
				table.remove(arg_3_0.greenTargets_, iter_3_0)
			elseif not var_3_1:isAffected() or not not var_3_1:isInvisible() then
				table.insert(var_3_0, var_3_1)
			end
		end

		if next(var_3_0) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			arg_3_0.greemHurtHarm_ = arg_3_4 / math.min(arg_3_0:getADJianShang(), 1) * var_0_15

			local var_3_2 = arg_3_0:createAttackUnits(var_3_0, var_0_7)

			for iter_3_1, iter_3_2 in ipairs(var_3_2) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_2)
				table.insert(arg_3_0.records_.special_units, iter_3_2)
			end
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.toDoPerFrames(arg_4_0)
	for iter_4_0, iter_4_1 in pairs(arg_4_0.greenSkillCD_) do
		arg_4_0.greenSkillCD_[iter_4_0] = iter_4_1 - 1
	end

	if not arg_4_0:isDeath() and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_0.purpleCount_ <= var_0_12 * 2 then
		arg_4_0.purpleCount_ = arg_4_0.purpleCount_ + 1

		if arg_4_0.purpleCount_ % var_0_12 < 1 then
			local var_4_0 = arg_4_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsA or var_0_1.ctx.battle.globalBuffsB

			for iter_4_2, iter_4_3 in ipairs(var_4_0) do
				local var_4_1 = iter_4_3:getTableID()
				local var_4_2 = iter_4_3.fighter

				if (var_4_1 == var_0_11[1] or var_4_1 == var_0_11[2]) and var_4_2 == arg_4_0 then
					iter_4_3.manualRevise = -((iter_4_3:getAttr() - iter_4_3.manualRevise) * 0.5 * (arg_4_0.purpleCount_ / var_0_12))

					for iter_4_4, iter_4_5 in ipairs(arg_4_0.selfTeam_) do
						if not iter_4_5:isDeath() then
							iter_4_5.___attrCache[iter_4_3:getAttrType()] = nil

							if iter_4_3:getAttrType() == var_0_2.AttributeType.ACK_SPEED then
								iter_4_5.___ackSpeed = nil
							end
						end
					end
				end
			end
		end
	end

	if not arg_4_0:isDeath() and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		if arg_4_0.blueCount_ < 1 then
			local var_4_3 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

			for iter_4_6, iter_4_7 in ipairs(arg_4_0.selfTeam_) do
				if not iter_4_7:isDeath() and not iter_4_7:isAffected() then
					local var_4_4 = var_0_4.new({
						tableID = var_0_10,
						start = var_0_1.ctx.battle.count,
						level = arg_4_0:getSkillLevelByID(var_4_3),
						skillID = var_4_3,
						fighter = arg_4_0,
						target = iter_4_7
					})

					var_4_4:setIsHit(true)
					var_4_4:setDirection(arg_4_0:getFighterModel():getFlipX())

					var_4_4.manualDharm = -var_4_4:totalDHarm() * (1 - arg_4_0:getHp() / arg_4_0:getHpLimit())

					iter_4_7:addBuffs({
						var_4_4
					})
				end
			end

			arg_4_0.blueCount_ = var_0_13
		else
			arg_4_0.blueCount_ = arg_4_0.blueCount_ - 1
		end
	end

	if arg_4_0.isSkinSkillOn_ then
		arg_4_0:updateFlowerBuff()
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_1.skillID == var_0_7 then
		local var_5_0 = arg_5_1.target

		arg_5_4 = arg_5_4 + arg_5_0.greemHurtHarm_ * arg_5_0.greemHurtHarm_ / (arg_5_0.greemHurtHarm_ + 8 * math.max(var_5_0:getHuJia() - arg_5_0:getDHuJia(), 0)) * var_5_0:getADJianShang()
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0
	local var_6_1

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.targetTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
			local var_6_2 = iter_6_1:getHuJia()

			if not var_6_0 or var_6_0 < var_6_2 then
				var_6_0 = var_6_2
				var_6_1 = iter_6_1
			end
		end
	end

	return {
		var_6_1
	}
end

function var_0_3.createUnits(arg_7_0, arg_7_1)
	var_0_3.super.createUnits(arg_7_0, arg_7_1)

	local var_7_0, var_7_1 = (arg_7_1 or arg_7_0.unitSkills_):getFront()

	if arg_7_0.isSkinSkillOn_ and var_7_1 == var_0_19 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_2 = {}

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1 ~= arg_7_0 and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
				table.insert(var_7_2, iter_7_1)
			end
		end

		if next(var_7_2) then
			local var_7_3 = arg_7_0:createAttackUnits(var_7_2, var_0_16)

			for iter_7_2, iter_7_3 in ipairs(var_7_3) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_4 > 0 and arg_8_0.isSkinSkillOn_ and arg_8_1.attackType == var_0_2.AttackType.AD and arg_8_1.target:getTeamType() == arg_8_0:getTeamType() and arg_8_1.target:isHasBuffByID(var_0_18) and (not arg_8_0.skinTargetsCount[arg_8_1.target] or arg_8_0.skinTargetsCount[arg_8_1.target] < var_0_22) then
		local var_8_0 = arg_8_0:createAttackUnits({
			arg_8_0
		}, var_0_17)

		for iter_8_0, iter_8_1 in ipairs(var_8_0) do
			iter_8_1.change_harm = arg_8_4

			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end

		local var_8_1 = arg_8_0:createAttackUnits({
			arg_8_1.target
		}, var_0_23)

		for iter_8_2, iter_8_3 in ipairs(var_8_1) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
			table.insert(arg_8_0.records_.special_units, iter_8_3)
		end

		if not arg_8_0.skinTargetsCount[arg_8_1.target] then
			arg_8_0.skinTargetsCount[arg_8_1.target] = 0
		end

		arg_8_0.skinTargetsCount[arg_8_1.target] = arg_8_0.skinTargetsCount[arg_8_1.target] + 1

		if arg_8_0.skinTargetsCount[arg_8_1.target] >= var_0_22 then
			arg_8_1.target:removeBuffByID(var_0_18)
		end

		arg_8_4 = 0
	elseif arg_8_4 > 0 and arg_8_1.target:getTeamType() ~= arg_8_0:getTeamType() and arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) and not arg_8_1.target:isHasBuffByID(var_0_9) and arg_8_1.target:isHasBuffByID(var_0_21) then
		-- block empty
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	var_0_3.super.buffAddAction(arg_9_0, arg_9_1)

	if (arg_9_1:getTableID() == var_0_9 or arg_9_1:getTableID() == var_0_21 or arg_9_1:getTableID() == var_0_8 or arg_9_1:getTableID() == var_0_20) and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_9_0 = arg_9_1:getTime() * (var_0_24 + arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) * var_0_25)

		arg_9_1:setExtraTime(var_9_0)
	elseif arg_9_1:getTableID() == var_0_27 and arg_9_0:hasElementEquipByID(var_0_29) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_9_1 = arg_9_0:createAttackUnits({
			arg_9_0
		}, var_0_30)

		for iter_9_0, iter_9_1 in ipairs(var_9_1) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	elseif arg_9_1:getTableID() == var_0_31 and arg_9_0:hasElementEquipByID(var_0_29) then
		local var_9_2 = var_0_29

		arg_9_1.manualRevise = var_0_28:battleAttr(var_9_2, arg_9_0:getElementEquipLevelByID(var_9_2)) * arg_9_0.hero_:getElementEquipActiveRate(var_9_2)
	end
end

function var_0_3.buffRemoveAction(arg_10_0, arg_10_1)
	var_0_3.super.buffRemoveAction(arg_10_0, arg_10_1)

	if arg_10_0.isSkinSkillOn_ and arg_10_1:getTableID() == var_0_18 and arg_10_0.skinTargetsCount[arg_10_1.target] then
		arg_10_0.skinTargetsCount[arg_10_1.target] = 0
	end
end

function var_0_3.updateFlowerBuff(arg_11_0)
	if arg_11_0.skinTargetsCount and next(arg_11_0.skinTargetsCount) then
		for iter_11_0, iter_11_1 in pairs(arg_11_0.skinTargetsCount) do
			if not iter_11_0:isDeath() and iter_11_1 >= var_0_22 then
				iter_11_0:removeBuffByID(var_0_18)
			end
		end
	end
end

return var_0_3
