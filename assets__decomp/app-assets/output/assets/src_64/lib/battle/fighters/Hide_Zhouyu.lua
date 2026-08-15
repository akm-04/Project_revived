local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhouyu", var_0_1.ctx.battle.requireFighter("HideBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 20010219
local var_0_8 = 10000299
local var_0_9 = 0.2
local var_0_10 = 0.5
local var_0_11 = 40011071
local var_0_12 = 0.75

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("move_info")
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.shanbiCount_ = 0
	arg_2_0.greenCount_ = 0
	arg_2_0.foxFire_ = 0
	arg_2_0.energyExtraRate_ = 0
	arg_2_0.greenExtraUnits_ = {}
	arg_2_0.purpleTargetCache_ = {}
	arg_2_0.isAddSkinBuff = false
	arg_2_0.doubleFoxFireCount = {}
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)
	arg_3_0:greenSkill()
	arg_3_0:purpleSkill()
	arg_3_0:skinSkill()
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0.isSkinSkillOn_ and not arg_4_0.isAddSkinBuff and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) >= 1 then
		arg_4_0.isAddSkinBuff = true

		local var_4_0 = arg_4_0:newBuff({
			var_0_11
		}, arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_4_0:addBuffs(var_4_0)
	end
end

function var_0_3.greenSkill(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) < 1 then
		return
	end

	if arg_5_0:acttionInBlack() then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.greenExtraUnits_) do
			arg_5_0.greenExtraUnits_[iter_5_0] = arg_5_0.greenExtraUnits_[iter_5_0] - 1
		end

		if arg_5_0.greenExtraUnits_[1] and arg_5_0.greenExtraUnits_[1] < 1 then
			arg_5_0:createSpecialSkill()
			table.remove(arg_5_0.greenExtraUnits_, 1)
		end
	end

	local var_5_0 = arg_5_0:getInfoByKey("attack_info")

	if not var_5_0 or not next(var_5_0) then
		return
	end

	for iter_5_2, iter_5_3 in ipairs(var_5_0) do
		if iter_5_3.fighter_:getTeamType() ~= arg_5_0:getTeamType() and iter_5_3.rootID_ == iter_5_3.fighter_:getEnergySkillID() then
			arg_5_0.greenCount_ = arg_5_0.greenCount_ + 1
		end
	end
end

function var_0_3.skinSkill(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if not arg_6_0.isSkinSkillOn_ or not arg_6_0.isAddSkinBuff then
		return
	end

	if not next(arg_6_0.doubleFoxFireCount) then
		return
	end

	if arg_6_0:acttionInBlack() then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0.doubleFoxFireCount) do
			arg_6_0.doubleFoxFireCount[iter_6_0] = arg_6_0.doubleFoxFireCount[iter_6_0] - 1
		end

		if arg_6_0.doubleFoxFireCount[1] and arg_6_0.doubleFoxFireCount[1] < 1 then
			arg_6_0:createSpecialSkill()
			table.remove(arg_6_0.doubleFoxFireCount, 1)
		end
	end
end

function var_0_3.purpleSkill(arg_7_0)
	if arg_7_0:isDeath() then
		return
	end

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 or arg_7_0:getX() < 0 or arg_7_0:getX() > var_0_2.STAGE_WIDTH then
		return
	end

	local var_7_0 = arg_7_0:getInfoByKey("move_info")

	if not var_7_0 or not next(var_7_0) then
		return
	end

	for iter_7_0, iter_7_1 in ipairs(var_7_0) do
		if iter_7_1.fighter and not iter_7_1.fighter:isAffected() and iter_7_1.fighter:getTeamType() ~= arg_7_0:getTeamType() and iter_7_1.fighter:getX() > 0 and iter_7_1.fighter:getX() < var_0_2.STAGE_WIDTH then
			arg_7_0:updatePurpleSkill(iter_7_1.fighter)
		end
	end
end

function var_0_3.updatePurpleSkill(arg_8_0, arg_8_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_8_0.purpleTargetCache_[arg_8_1] or arg_8_0.purpleTargetCache_[arg_8_1] and var_0_1.ctx.battle.count - arg_8_0.purpleTargetCache_[arg_8_1] > 30 then
		arg_8_0.purpleTargetCache_[arg_8_1] = var_0_1.ctx.battle.count

		local var_8_0 = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_8_1 = {
			arg_8_1
		}
		local var_8_2 = arg_8_0:createAttackUnits(var_8_1, var_8_0)

		for iter_8_0, iter_8_1 in ipairs(var_8_2) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end
	end
end

function var_0_3.beginAttack(arg_9_0)
	var_0_3.super.beginAttack(arg_9_0)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_9_0 = arg_9_0.unitSkills_

	if not var_9_0 then
		return
	end

	if var_9_0.rootID_ == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_9_1 = var_0_6:pretime(var_9_0.rootID_)

		for iter_9_0 = 1, arg_9_0.greenCount_ do
			table.insert(arg_9_0.greenExtraUnits_, iter_9_0 * (var_9_1 + 1))
		end

		arg_9_0.greenCount_ = 0
	end
end

function var_0_3.beginAttackEnd(arg_10_0, arg_10_1)
	var_0_3.super.beginAttackEnd(arg_10_0, arg_10_1)

	if arg_10_1.rootID_ == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_10_0.foxFire_ = arg_10_0.foxFire_ + 1
	elseif arg_10_1.rootID_ == arg_10_0:getEnergySkillID() then
		arg_10_0.energyExtraRate_ = arg_10_0.foxFire_
		arg_10_0.foxFire_ = 0
	end
end

function var_0_3.createSpecialSkill(arg_11_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_11_0 = arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	local var_11_1 = var_0_6:sound(var_11_0)

	var_0_1.ctx.battle.pushSoundQueue(var_11_1)

	arg_11_0.specialSkills_ = var_0_4.new({
		fighter = arg_11_0,
		skillID = var_11_0
	})

	arg_11_0:beginAttackEnd(arg_11_0.specialSkills_)

	local var_11_2 = arg_11_0:createAttackUnits({
		arg_11_0
	}, var_0_8)

	for iter_11_0, iter_11_1 in ipairs(var_11_2) do
		table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
		table.insert(arg_11_0.records_.special_units, iter_11_1)
	end
end

function var_0_3.playShanbi(arg_12_0, arg_12_1)
	var_0_3.super.playShanbi(arg_12_0, arg_12_1)

	if arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) < 1 then
		return
	end

	if arg_12_0:isHasBuffByID(var_0_7) and arg_12_0:isHasBuffByID(var_0_11) then
		arg_12_0.shanbiCount_ = arg_12_0.shanbiCount_ + 1

		if arg_12_0.shanbiCount_ % 3 < 1 then
			arg_12_0:createSpecialSkill()

			local var_12_0 = var_0_6:pretime(arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

			table.insert(arg_12_0.doubleFoxFireCount, var_12_0 + 1)
			table.insert(arg_12_0.doubleFoxFireCount, 2 * (var_12_0 + 1))
		end
	elseif arg_12_0:isHasBuffByID(var_0_7) then
		arg_12_0.shanbiCount_ = arg_12_0.shanbiCount_ + 1

		if arg_12_0.shanbiCount_ % 3 < 1 then
			arg_12_0:createSpecialSkill()
		end
	elseif arg_12_0:isHasBuffByID(var_0_11) then
		arg_12_0.shanbiCount_ = arg_12_0.shanbiCount_ + 1

		if arg_12_0.shanbiCount_ % 3 < 1 then
			arg_12_0:createSpecialSkill()
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0
	local var_13_1

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and not arg_13_0.greenTargetCache_[iter_13_1] and (not var_13_0 or var_13_1 > math.abs(iter_13_1:getX() - arg_13_0:getX())) then
			var_13_0 = iter_13_1
			var_13_1 = math.abs(iter_13_1:getX() - arg_13_0:getX())
		end
	end

	if var_13_0 then
		arg_13_0.greenTargetCache_[var_13_0] = true

		return {
			var_13_0
		}
	end

	for iter_13_2, iter_13_3 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_3:isDeath() and not iter_13_3:isAffected() and (not var_13_0 or var_13_1 > math.abs(iter_13_3:getX() - arg_13_0:getX())) then
			var_13_0 = iter_13_3
			var_13_1 = math.abs(iter_13_3:getX() - arg_13_0:getX())
		end
	end

	if var_13_0 then
		return {
			var_13_0
		}
	end

	return {}
end

function var_0_3.updateUnitBaseByFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	if var_0_6:father(arg_14_1.skillID) == arg_14_0:getEnergySkillID() then
		arg_14_3 = (var_0_9 * arg_14_0.energyExtraRate_ + 1) * arg_14_3
	elseif arg_14_1.skillID == arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_14_3 = (1 - arg_14_1.target:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE) * var_0_10 * arg_14_3 + arg_14_3
	end

	return var_0_3.super.updateUnitBaseByFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
end

function var_0_3.buffAddAction(arg_15_0, arg_15_1)
	if arg_15_1:getTableID() == var_0_7 then
		-- block empty
	end
end

function var_0_3.updateUnitDataByTarget(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)
	local var_16_0 = arg_16_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

	if arg_16_1.attackType == var_0_2.AttackType.AP and arg_16_4 > 0 and var_16_0 > 0 and arg_16_0:isHasBuffByID(var_0_7) and arg_16_0:isHasBuffByID(var_0_11) and var_0_2.weightedChoise({
		var_0_12,
		1 - var_0_12
	}) == 1 then
		arg_16_0.fighterModel:playFloatText({
			var_0_2.BattleFloatType.AP_IMMORTAL
		}, arg_16_0:getTeamType())

		arg_16_4 = 0
	end

	return var_0_3.super.updateUnitDataByTarget(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)
end

function var_0_3.newBuff(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	local var_17_0 = {}

	for iter_17_0, iter_17_1 in ipairs(arg_17_1) do
		local var_17_1 = var_0_5.new({
			tableID = iter_17_1,
			start = var_0_1.ctx.battle.count,
			level = arg_17_0:getSkillLevelByID(arg_17_3),
			skillID = arg_17_3,
			fighter = arg_17_0,
			target = arg_17_2
		})

		var_17_1:setIsHit(true)
		var_17_1:setDirection(arg_17_0:getFighterModel():getFlipX())
		table.insert(var_17_0, var_17_1)
	end

	return var_17_0
end

function var_0_3.die(arg_18_0)
	if not arg_18_0.isSkinSkillOn_ and arg_18_0:isHasBuffByID(var_0_11) then
		arg_18_0:removeBuffByID(var_0_11)
	end

	return var_0_3.super.die(arg_18_0)
end

return var_0_3
