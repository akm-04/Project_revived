local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caorui", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40010926
local var_0_8 = {
	40010928,
	40010929,
	40010930
}
local var_0_9 = 180
local var_0_10 = {
	1.5,
	1.75,
	2
}
local var_0_11 = 40010948
local var_0_12 = 10000870
local var_0_13 = 0.3
local var_0_14 = 0.0003
local var_0_15 = 80010166
local var_0_16 = 40011742
local var_0_17 = 40011743
local var_0_18 = 0.5
local var_0_19 = 0.003

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isEnergyType = 0
	arg_2_0.greenBuffsCD_ = {}
	arg_2_0.purpleDieTargets_ = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		if arg_3_0.isEnergyType > 0 then
			for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
				local var_3_0 = arg_3_0.skinSkillID_ == var_0_15 and var_0_16 or var_0_11

				if not iter_3_1:isDeath() and iter_3_1:isHasBuffByID(var_3_0) then
					iter_3_1:removeBuffByID(var_3_0)
				end
			end
		end

		return
	end

	if arg_3_0.isEnergyType > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("attack_info")) do
			local var_3_1 = iter_3_3.fighter_
			local var_3_2 = arg_3_0.skinSkillID_ == var_0_15 and var_0_16 or var_0_11

			if not var_3_1:isDeath() and not var_3_1:isAffected() and var_3_1:getEnergySkillID() == var_0_6:father(iter_3_3.rootID_) and var_3_1:isHasBuffByID(var_3_2) then
				local var_3_3 = arg_3_0:createAttackUnits({
					var_3_1
				}, var_0_12)

				for iter_3_4, iter_3_5 in ipairs(var_3_3) do
					iter_3_5.arrived = true

					table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
					table.insert(arg_3_0.records_.special_units, iter_3_5)
				end
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == var_0_12 then
		arg_4_0:addBlueSpecialBuff(true)
	elseif var_0_6:father(arg_4_1.skillID) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if arg_4_1.target:isHasBuffByID(var_0_7) then
			arg_4_0:addBlueSpecialBuff(false, arg_4_1.target)
		end
	elseif arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		if arg_4_1.target:isDeath() then
			table.insert(arg_4_0.purpleDieTargets_, arg_4_1.target)
		end
	elseif arg_4_0.skinSkillID_ == var_0_15 and var_0_6:father(arg_4_1.skillID) == arg_4_0:getPugongID() then
		local var_4_0 = math.min(1, var_0_18 + var_0_19 * arg_4_0:getLevel())

		arg_4_1.target:addBuffs(arg_4_0:newBuff({
			var_0_17
		}, arg_4_1.target, var_0_15))

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_2.weightedChoise({
			var_4_0,
			1 - var_4_0
		}) then
			local var_4_1 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_15)

			for iter_4_0, iter_4_1 in ipairs(var_4_1) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	elseif arg_4_1.skillID == var_0_15 then
		arg_4_0:addBlueSpecialBuff(false, arg_4_1.target)
	end
end

function var_0_3.getBlueBuffsNum(arg_5_0, arg_5_1)
	local var_5_0 = 0

	for iter_5_0 = 1, #var_0_8 do
		if arg_5_1:isHasBuffByID(var_0_8[iter_5_0]) then
			var_5_0 = var_5_0 + 1
		end
	end

	return var_5_0
end

function var_0_3.addBlueSpecialBuff(arg_6_0, arg_6_1, arg_6_2)
	local function var_6_0(arg_7_0)
		for iter_7_0 = 1, #var_0_8 do
			if not arg_7_0:isHasBuffByID(var_0_8[iter_7_0]) then
				local var_7_0 = arg_6_0:newBuff({
					var_0_8[iter_7_0]
				}, arg_7_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				arg_7_0:addBuffs(var_7_0)

				arg_6_0.greenBuffsCD_[arg_7_0] = var_0_1.ctx.battle.count

				break
			end
		end
	end

	if not arg_6_1 and arg_6_2 and (not arg_6_0.greenBuffsCD_[arg_6_2] or var_0_1.ctx.battle.count - arg_6_0.greenBuffsCD_[arg_6_2] >= var_0_9) then
		var_6_0(arg_6_2)
	elseif arg_6_1 then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_1:isDeath() and not iter_6_1:isAffected() and arg_6_0:getBlueBuffsNum(iter_6_1) > 0 then
				var_6_0(iter_6_1)
			end
		end
	end
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_4.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_0:getSkillLevelByID(arg_8_3) or arg_8_0:getLevel(),
			skillID = arg_8_3,
			fighter = arg_8_0,
			target = arg_8_2
		})

		var_8_1:setIsHit(true)
		var_8_1:setDirection(arg_8_0:getFighterModel():getFlipX())
		table.insert(var_8_0, var_8_1)
	end

	return var_8_0
end

function var_0_3.skillIsBreakAction(arg_9_0, arg_9_1)
	var_0_3.super.skillIsBreakAction(arg_9_0, arg_9_1)

	local var_9_0 = arg_9_0.skinSkillID_ == var_0_15 and var_0_16 or var_0_11

	if arg_9_1.skillID == var_0_12 then
		arg_9_1.target:removeBuffByID(var_9_0)
	end
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if var_10_2 > 0 and var_0_6:father(arg_10_1.skillID) == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_10_6 = arg_10_0:getBlueBuffsNum(arg_10_1.target)

		if var_10_6 > 0 then
			var_10_2 = var_10_2 + var_0_10[var_10_6] * var_10_2
		end
	end

	return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
end

function var_0_3.updateUnitDataBySpecialHero(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	if var_11_2 > 0 and arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_0.table.keyof(arg_11_0.purpleDieTargets_, arg_11_1.fighter) and arg_11_1.fighter:isDeath() and arg_11_1.skillID == var_0_5:dieSkill(arg_11_1.fighter:getTableID()) then
		var_11_2 = var_11_2 - var_11_2 * (var_0_13 + var_0_14 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
	end

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5
end

function var_0_3.buffRemoveAction(arg_12_0, arg_12_1)
	var_0_3.super.buffRemoveAction(arg_12_0, arg_12_1)

	local var_12_0 = arg_12_0.skinSkillID_ == var_0_15 and var_0_16 or var_0_11

	if arg_12_1:getTableID() == var_12_0 then
		arg_12_0.isEnergyType = arg_12_0.isEnergyType - 1
	end
end

function var_0_3.buffAddAction(arg_13_0, arg_13_1)
	var_0_3.super.buffAddAction(arg_13_0, arg_13_1)

	local var_13_0 = arg_13_0.skinSkillID_ == var_0_15 and var_0_16 or var_0_11

	if arg_13_1:getTableID() == var_13_0 then
		arg_13_0.isEnergyType = arg_13_0.isEnergyType + 1
	elseif arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_0.table.keyof(var_0_8, arg_13_1:getTableID()) and arg_13_0:getBlueBuffsNum(arg_13_1.target) == #var_0_8 - 1 then
		arg_13_0:usePurpleSkill(arg_13_1.target)
	end
end

function var_0_3.usePurpleSkill(arg_14_0, arg_14_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_14_0 = arg_14_0:createAttackUnits({
		arg_14_1
	}, arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

	for iter_14_0, iter_14_1 in ipairs(var_14_0) do
		table.insert(arg_14_0.moveAttackUnits_, iter_14_1)
		table.insert(arg_14_0.records_.special_units, iter_14_1)
	end
end

return var_0_3
