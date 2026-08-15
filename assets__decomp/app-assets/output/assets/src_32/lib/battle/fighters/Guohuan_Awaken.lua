local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guohuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 11000512
local var_0_8 = 11000513
local var_0_9 = 40010344
local var_0_10 = 40010332
local var_0_11 = 40010336
local var_0_12 = {
	40010334,
	40010335
}
local var_0_13 = 150
local var_0_14 = 600
local var_0_15 = 45
local var_0_16 = 0
local var_0_17 = 0.005
local var_0_18 = 1
local var_0_19 = 80010118
local var_0_20 = 10000918
local var_0_21 = 40011021
local var_0_22 = 13000512
local var_0_23 = 40011022
local var_0_24 = 40011024
local var_0_25 = 1
local var_0_26 = 10000924
local var_0_27 = 0.3
local var_0_28 = 0.005
local var_0_29 = 0.1
local var_0_30 = 40010337
local var_0_31 = var_0_2.tables.elementEquip
local var_0_32 = 20001494
local var_0_33 = 10002393
local var_0_34 = 40012600

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.greenTargets_ = {}
	arg_2_0.greenSkillCD_ = {}
	arg_2_0.greemHurtHarm_ = 0
	arg_2_0.purpleCount_ = 0
	arg_2_0.blueCount_ = 150
	arg_2_0.skinTargetsCount = {}
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if var_0_7 == arg_3_1.skillID or arg_3_1.skillID == var_0_22 then
		local var_3_0 = false

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.greenTargets_) do
			if iter_3_1 == arg_3_1.target then
				var_3_0 = true
			end
		end

		if not var_3_0 then
			table.insert(arg_3_0.greenTargets_, arg_3_1.target)
		end
	elseif arg_3_1.skillID == var_0_26 and var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if not arg_3_0.skinTargetsCount[arg_3_1.target] then
			arg_3_0.skinTargetsCount[arg_3_1.target] = 0
		end

		arg_3_0.skinTargetsCount[arg_3_1.target] = arg_3_0.skinTargetsCount[arg_3_1.target] + 1

		if arg_3_0.skinTargetsCount[arg_3_1.target] >= var_0_25 then
			arg_3_1.target:removeBuffByID(var_0_21)
		end
	end
end

function var_0_3.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_4 > 0 and arg_4_0.isSkinSkillOn_ and arg_4_1.skillID == var_0_20 and arg_4_1.fighter == arg_4_0 and arg_4_1.change_harm and arg_4_1.change_harm > 0 then
		arg_4_4 = arg_4_4 + arg_4_1.change_harm * arg_4_0:getADJianShang()
	end

	if next(arg_4_0.greenTargets_) and arg_4_1.attackType == var_0_2.AttackType.AD and arg_4_4 > 0 and (not arg_4_0.greenSkillCD_[arg_4_1.fighter] or arg_4_0.greenSkillCD_[arg_4_1.fighter] < 1) then
		local var_4_0 = {}

		arg_4_0.greenSkillCD_[arg_4_1.fighter] = var_0_15

		for iter_4_0 = #arg_4_0.greenTargets_, 1, -1 do
			local var_4_1 = arg_4_0.greenTargets_[iter_4_0]

			if var_4_1:isDeath() then
				table.remove(arg_4_0.greenTargets_, iter_4_0)
			elseif not var_4_1:isHasBuffByID(var_0_9) and not var_4_1:isHasBuffByID(var_0_23) then
				table.remove(arg_4_0.greenTargets_, iter_4_0)
			elseif not var_4_1:isAffected() or not not var_4_1:isInvisible() then
				table.insert(var_4_0, var_4_1)
			end
		end

		if next(var_4_0) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			arg_4_0.greemHurtHarm_ = arg_4_4 / math.min(arg_4_0:getADJianShang(), 1) * var_0_18

			local var_4_2 = arg_4_0:createAttackUnits(var_4_0, var_0_8)

			for iter_4_1, iter_4_2 in ipairs(var_4_2) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_2)
				table.insert(arg_4_0.records_.special_units, iter_4_2)
			end
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
end

function var_0_3.toDoPerFrames(arg_5_0)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.greenSkillCD_) do
		arg_5_0.greenSkillCD_[iter_5_0] = iter_5_1 - 1
	end

	if not arg_5_0:isDeath() and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_5_0.purpleCount_ <= var_0_13 * 2 then
		arg_5_0.purpleCount_ = arg_5_0.purpleCount_ + 1

		if arg_5_0.purpleCount_ % var_0_13 < 1 then
			local var_5_0 = arg_5_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsA or var_0_1.ctx.battle.globalBuffsB

			for iter_5_2, iter_5_3 in ipairs(var_5_0) do
				local var_5_1 = iter_5_3:getTableID()
				local var_5_2 = iter_5_3.fighter

				if (var_5_1 == var_0_12[1] or var_5_1 == var_0_12[2]) and var_5_2 == arg_5_0 then
					iter_5_3.manualRevise = -((iter_5_3:getAttr() - iter_5_3.manualRevise) * 0.5 * (arg_5_0.purpleCount_ / var_0_13))

					for iter_5_4, iter_5_5 in ipairs(arg_5_0.selfTeam_) do
						if not iter_5_5:isDeath() then
							iter_5_5.___attrCache[iter_5_3:getAttrType()] = nil

							if iter_5_3:getAttrType() == var_0_2.AttributeType.ACK_SPEED then
								iter_5_5.___ackSpeed = nil
							end
						end
					end
				end
			end
		end
	end

	if not arg_5_0:isDeath() and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		if arg_5_0.blueCount_ < 1 then
			local var_5_3 = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

			for iter_5_6, iter_5_7 in ipairs(arg_5_0.selfTeam_) do
				if not iter_5_7:isDeath() and not iter_5_7:isAffected() then
					local var_5_4 = var_0_4.new({
						tableID = var_0_11,
						start = var_0_1.ctx.battle.count,
						level = arg_5_0:getSkillLevelByID(var_5_3),
						skillID = var_5_3,
						fighter = arg_5_0,
						target = iter_5_7
					})

					var_5_4:setIsHit(true)
					var_5_4:setDirection(arg_5_0:getFighterModel():getFlipX())

					var_5_4.manualDharm = -var_5_4:totalDHarm() * (1 - arg_5_0:getHp() / arg_5_0:getHpLimit())

					iter_5_7:addBuffs({
						var_5_4
					})
				end
			end

			arg_5_0.blueCount_ = var_0_14
		else
			arg_5_0.blueCount_ = arg_5_0.blueCount_ - 1
		end
	end

	for iter_5_8, iter_5_9 in ipairs(arg_5_0:getInfoByKey("buff_info")) do
		local var_5_5 = iter_5_9:getTableID()
		local var_5_6 = iter_5_9.fighter
		local var_5_7 = iter_5_9.target
		local var_5_8 = var_5_7:getBuffByID(var_0_9) or var_5_7:getBuffByID(var_0_23)

		if var_5_8 and var_5_8.fighter == arg_5_0 and var_5_7:getTeamType() ~= arg_5_0:getTeamType() and iter_5_9:getAttrType() == var_0_2.AttributeType.HUJIA and (var_0_6:step(var_5_5) < 0 or var_0_6:init(var_5_5) < 0) then
			iter_5_9.manualRevise = iter_5_9:getAttr() * (var_0_16 + var_0_17 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
		end
	end

	if arg_5_0.isSkinSkillOn_ then
		arg_5_0:updateFlowerBuff()
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_1.skillID == var_0_8 then
		local var_6_0 = arg_6_1.target

		arg_6_4 = arg_6_4 + arg_6_0.greemHurtHarm_ * arg_6_0.greemHurtHarm_ / (arg_6_0.greemHurtHarm_ + 8 * math.max(var_6_0:getHuJia() - arg_6_0:getDHuJia(), 0)) * var_6_0:getADJianShang()
	end

	return var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0
	local var_7_1

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.targetTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
			local var_7_2 = iter_7_1:getHuJia()

			if not var_7_0 or var_7_0 < var_7_2 then
				var_7_0 = var_7_2
				var_7_1 = iter_7_1
			end
		end
	end

	return {
		var_7_1
	}
end

function var_0_3.createUnits(arg_8_0, arg_8_1)
	var_0_3.super.createUnits(arg_8_0, arg_8_1)

	local var_8_0, var_8_1 = (arg_8_1 or arg_8_0.unitSkills_):getFront()

	if arg_8_0.isSkinSkillOn_ and var_8_1 == var_0_22 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_2 = {}

		for iter_8_0, iter_8_1 in ipairs(arg_8_0.selfTeam_) do
			if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1 ~= arg_8_0 and iter_8_1:getSummonType() == var_0_2.summonMonsterType.None then
				table.insert(var_8_2, iter_8_1)
			end
		end

		if next(var_8_2) then
			local var_8_3 = arg_8_0:createAttackUnits(var_8_2, var_0_19)

			for iter_8_2, iter_8_3 in ipairs(var_8_3) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
				table.insert(arg_8_0.records_.special_units, iter_8_3)
			end
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_4 > 0 and arg_9_0.isSkinSkillOn_ and arg_9_1.attackType == var_0_2.AttackType.AD and arg_9_1.target:getTeamType() == arg_9_0:getTeamType() and arg_9_1.target:isHasBuffByID(var_0_21) and (not arg_9_0.skinTargetsCount[arg_9_1.target] or arg_9_0.skinTargetsCount[arg_9_1.target] < var_0_25) then
		local var_9_0 = arg_9_0:createAttackUnits({
			arg_9_0
		}, var_0_20)

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			iter_9_1.change_harm = arg_9_4

			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end

		local var_9_1 = arg_9_0:createAttackUnits({
			arg_9_1.target
		}, var_0_26)

		for iter_9_2, iter_9_3 in ipairs(var_9_1) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
			table.insert(arg_9_0.records_.special_units, iter_9_3)
		end

		if not arg_9_0.skinTargetsCount[arg_9_1.target] then
			arg_9_0.skinTargetsCount[arg_9_1.target] = 0
		end

		arg_9_0.skinTargetsCount[arg_9_1.target] = arg_9_0.skinTargetsCount[arg_9_1.target] + 1

		if arg_9_0.skinTargetsCount[arg_9_1.target] >= var_0_25 then
			arg_9_1.target:removeBuffByID(var_0_21)
		end

		arg_9_4 = 0
	elseif arg_9_4 > 0 and arg_9_1.target:getTeamType() ~= arg_9_0:getTeamType() and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) and (arg_9_1.target:isHasBuffByID(var_0_9) or arg_9_1.target:isHasBuffByID(var_0_23)) then
		arg_9_4 = (1 + var_0_29) * arg_9_4
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	var_0_3.super.buffAddAction(arg_10_0, arg_10_1)

	if (arg_10_1:getTableID() == var_0_9 or arg_10_1:getTableID() == var_0_23 or arg_10_1:getTableID() == var_0_10 or arg_10_1:getTableID() == var_0_24) and arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_10_0 = arg_10_1:getTime() * (var_0_27 + arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) * var_0_28)

		arg_10_1:setExtraTime(var_10_0)
	elseif arg_10_1:getTableID() == var_0_30 and arg_10_0:hasElementEquipByID(var_0_32) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_10_1 = arg_10_0:createAttackUnits({
			arg_10_0
		}, var_0_33)

		for iter_10_0, iter_10_1 in ipairs(var_10_1) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
			table.insert(arg_10_0.records_.special_units, iter_10_1)
		end
	elseif arg_10_1:getTableID() == var_0_34 and arg_10_0:hasElementEquipByID(var_0_32) then
		local var_10_2 = var_0_32

		arg_10_1.manualRevise = var_0_31:battleAttr(var_10_2, arg_10_0:getElementEquipLevelByID(var_10_2)) * arg_10_0.hero_:getElementEquipActiveRate(var_10_2)
	end
end

function var_0_3.buffRemoveAction(arg_11_0, arg_11_1)
	var_0_3.super.buffRemoveAction(arg_11_0, arg_11_1)

	if arg_11_0.isSkinSkillOn_ and arg_11_1:getTableID() == var_0_21 and arg_11_0.skinTargetsCount[arg_11_1.target] then
		arg_11_0.skinTargetsCount[arg_11_1.target] = 0
	end
end

function var_0_3.updateFlowerBuff(arg_12_0)
	if arg_12_0.skinTargetsCount and next(arg_12_0.skinTargetsCount) then
		for iter_12_0, iter_12_1 in pairs(arg_12_0.skinTargetsCount) do
			if not iter_12_0:isDeath() and iter_12_1 >= var_0_25 then
				iter_12_0:removeBuffByID(var_0_21)
			end
		end
	end
end

return var_0_3
