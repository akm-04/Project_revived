local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yidazhengzong", var_0_1.ctx.battle.requireFighter("Yidazhengzong"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40010987
local var_0_6 = 6
local var_0_7 = 293
local var_0_8 = 0
local var_0_9 = 0.17
local var_0_10 = 40010989
local var_0_11 = 120
local var_0_12 = 60020171
local var_0_13 = 0.05
local var_0_14 = 0.002
local var_0_15 = 0.1
local var_0_16 = var_0_2.tables.skill
local var_0_17 = math.abs

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyHarm = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if arg_3_0:isDeath() then
		return
	end

	for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("crit_info")) do
		if iter_3_1.unit.fighter == arg_3_0 and #arg_3_0:getBuffsByID(var_0_5) < var_0_6 then
			local var_3_0 = arg_3_0:newBuff({
				var_0_5
			}, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			arg_3_0:addBuffs(var_3_0)

			local var_3_1 = #arg_3_0:getBuffsByID(var_0_5)

			arg_3_0:updateStateNumber(var_3_1)
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_3_0.isEnergyType_ then
		for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("harm_info")) do
			if iter_3_3.fighter == arg_3_0 and iter_3_3.harm > 0 then
				arg_3_0.energyHarm = arg_3_0.energyHarm + iter_3_3.harm
			end
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and not arg_3_0.firstEnergySkill and arg_3_0:getHp() / arg_3_0:getHpLimit() < var_0_15 and var_0_1.ctx.battle.count % 10 == 0 and not arg_3_0:isCreatingUnits() and arg_3_0:checkAutoEnergySkill() then
		arg_3_0.isEnergySkill_ = true
		arg_3_0.leftInterval_ = 0
		arg_3_0.arenaEnergyFull_ = nil

		table.insert(arg_3_0.records_.energy, var_0_1.ctx.battle.count)
	end
end

function var_0_3.applyHurtFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
	if arg_4_2 > 0 and arg_4_0:isHasBuffByID(var_0_5) and arg_4_2 >= var_0_9 * arg_4_0:getHpLimit() then
		local var_4_0 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_7 + var_0_8

		arg_4_2 = math.max(0, arg_4_2 - var_4_0)

		local var_4_1 = arg_4_0:getBuffByID(var_0_5)

		arg_4_0:removeBuffs(var_4_1)
	end

	return var_0_3.super.applyHurtFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	var_0_3.super.buffRemoveAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_5 then
		local var_5_0 = #arg_5_0:getBuffsByID(var_0_5) - 1

		if var_5_0 > 0 then
			arg_5_0:updateStateNumber(var_5_0)
		else
			arg_5_0:updateStateNumber()
		end
	end
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_4.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByID(arg_6_3),
			skillID = arg_6_3,
			fighter = arg_6_0,
			target = arg_6_2
		})

		var_6_1:setIsHit(true)
		var_6_1:setDirection(arg_6_0:getFighterModel():getFlipX())
		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.checkReHpMp(arg_7_0)
	var_0_3.super.checkReHpMp(arg_7_0)

	if arg_7_0:isDeath() then
		return
	end

	arg_7_0:updateStateNumber()
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_8_1.skillID == var_0_12 then
		arg_8_5 = arg_8_0.energyHarm * (var_0_13 + var_0_14 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice))
		arg_8_0.energyHarm = 0
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	var_0_3.super.buffRemoveAction(arg_9_0, arg_9_1)

	if arg_9_1:getTableID() == var_0_10 and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_9_0 = arg_9_0:createAttackUnits({
			arg_9_0
		}, var_0_12)

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end
end

function var_0_3.checkAutoEnergySkill(arg_10_0)
	if arg_10_0.isEnergyType_ then
		return false
	elseif arg_10_0.lastEnergyTime_ and var_0_1.ctx.battle.count - arg_10_0.lastEnergyTime_ < var_0_11 then
		return false
	end

	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		return false
	end

	if arg_10_0:isDeath() then
		return false
	end

	if arg_10_0:getDelaySkill() > var_0_1.ctx.battle.count then
		return false
	end

	if arg_10_0.walk2Position_ then
		return false
	end

	if arg_10_0:isBattleUnable() then
		return false
	end

	if arg_10_0:isApUnable() and (var_0_16:type(arg_10_0:getEnergySkillID()) == var_0_2.AttackType.AP or var_0_16:type(arg_10_0:getEnergySkillID()) == var_0_2.AttackType.CURE) then
		return false
	end

	if arg_10_0:isAdUnable() and var_0_16:type(arg_10_0:getEnergySkillID()) == var_0_2.AttackType.AD then
		return false
	end

	if arg_10_0.isEnergySkill_ and arg_10_0:isCreatingUnits() then
		return false
	end

	if arg_10_0:isAutoFighter() and arg_10_0:isInSkillRoll() then
		return false
	end

	if arg_10_0:isPugongOnly() then
		return false
	end

	if arg_10_0:isInvalidEnergySkill() then
		return false
	end

	if not arg_10_0:getNearestTarget() then
		return false
	end

	local var_10_0 = var_0_16:distance(arg_10_0:getEnergySkillID())

	if var_10_0 > 0 and var_10_0 < var_0_17(arg_10_0:getNearestTarget():getX() - arg_10_0:getX()) then
		return false
	end

	if arg_10_0.leftInterval_ > 0 and arg_10_0.arenaEnergyFull_ ~= true and (var_0_2.CampaignType.ARENA == var_0_1.ctx.battle.campaignType or var_0_2.CampaignType.SUPER_ARENA == var_0_1.ctx.battle.campaignType) then
		return false
	end

	if var_0_1.ctx.battle.isActivity and not arg_10_0:isMainRole() then
		return false
	end

	return true
end

return var_0_3
