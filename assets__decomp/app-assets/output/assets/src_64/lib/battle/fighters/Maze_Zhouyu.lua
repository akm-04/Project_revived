local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("MazeZhouyu", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 20010219
local var_0_7 = 10000299
local var_0_8 = 0.2
local var_0_9 = 0.5

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
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)
	arg_3_0:greenSkill()
	arg_3_0:purpleSkill()
end

function var_0_3.greenSkill(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) < 1 then
		return
	end

	if arg_4_0:acttionInBlack() then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0.greenExtraUnits_) do
			arg_4_0.greenExtraUnits_[iter_4_0] = arg_4_0.greenExtraUnits_[iter_4_0] - 1
		end

		if arg_4_0.greenExtraUnits_[1] and arg_4_0.greenExtraUnits_[1] < 1 then
			arg_4_0:createSpecialSkill()
			table.remove(arg_4_0.greenExtraUnits_, 1)
		end
	end

	local var_4_0 = arg_4_0:getInfoByKey("attack_info")

	if not var_4_0 or not next(var_4_0) then
		return
	end

	for iter_4_2, iter_4_3 in ipairs(var_4_0) do
		if iter_4_3.fighter_:getTeamType() ~= arg_4_0:getTeamType() and iter_4_3.rootID_ == iter_4_3.fighter_:getEnergySkillID() then
			arg_4_0.greenCount_ = arg_4_0.greenCount_ + 1
		end
	end
end

function var_0_3.purpleSkill(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 or arg_5_0:getX() < 0 or arg_5_0:getX() > var_0_2.STAGE_WIDTH then
		return
	end

	local var_5_0 = arg_5_0:getInfoByKey("move_info")

	if not var_5_0 or not next(var_5_0) then
		return
	end

	for iter_5_0, iter_5_1 in ipairs(var_5_0) do
		if iter_5_1.fighter and not iter_5_1.fighter:isAffected() and iter_5_1.fighter:getTeamType() ~= arg_5_0:getTeamType() and iter_5_1.fighter:getX() > 0 and iter_5_1.fighter:getX() < var_0_2.STAGE_WIDTH then
			arg_5_0:updatePurpleSkill(iter_5_1.fighter)
		end
	end
end

function var_0_3.updatePurpleSkill(arg_6_0, arg_6_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_6_0.purpleTargetCache_[arg_6_1] or arg_6_0.purpleTargetCache_[arg_6_1] and var_0_1.ctx.battle.count - arg_6_0.purpleTargetCache_[arg_6_1] > 30 then
		arg_6_0.purpleTargetCache_[arg_6_1] = var_0_1.ctx.battle.count

		local var_6_0 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_6_1 = {
			arg_6_1
		}
		local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_6_0)

		for iter_6_0, iter_6_1 in ipairs(var_6_2) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

function var_0_3.beginAttack(arg_7_0)
	var_0_3.super.beginAttack(arg_7_0)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_7_0 = arg_7_0.unitSkills_

	if not var_7_0 then
		return
	end

	if var_7_0.rootID_ == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_7_1 = var_0_5:pretime(var_7_0.rootID_)

		for iter_7_0 = 1, arg_7_0.greenCount_ do
			table.insert(arg_7_0.greenExtraUnits_, iter_7_0 * (var_7_1 + 1))
		end

		arg_7_0.greenCount_ = 0
	end
end

function var_0_3.beginAttackEnd(arg_8_0, arg_8_1)
	var_0_3.super.beginAttackEnd(arg_8_0, arg_8_1)

	if arg_8_1.rootID_ == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_8_0.foxFire_ = arg_8_0.foxFire_ + 1
	elseif arg_8_1.rootID_ == arg_8_0:getEnergySkillID() then
		arg_8_0.energyExtraRate_ = arg_8_0.foxFire_
		arg_8_0.foxFire_ = 0
	end
end

function var_0_3.createSpecialSkill(arg_9_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_9_0 = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	local var_9_1 = var_0_5:sound(var_9_0)

	var_0_1.ctx.battle.pushSoundQueue(var_9_1)

	arg_9_0.specialSkills_ = var_0_4.new({
		fighter = arg_9_0,
		skillID = var_9_0
	})

	arg_9_0:beginAttackEnd(arg_9_0.specialSkills_)

	local var_9_2 = arg_9_0:createAttackUnits({
		arg_9_0
	}, var_0_7)

	for iter_9_0, iter_9_1 in ipairs(var_9_2) do
		table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
		table.insert(arg_9_0.records_.special_units, iter_9_1)
	end
end

function var_0_3.playShanbi(arg_10_0, arg_10_1)
	var_0_3.super.playShanbi(arg_10_0, arg_10_1)

	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) < 1 then
		return
	end

	if arg_10_0:isHasBuffByID(var_0_6) then
		arg_10_0.shanbiCount_ = arg_10_0.shanbiCount_ + 1

		if arg_10_0.shanbiCount_ % 3 < 1 then
			arg_10_0:createSpecialSkill()
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0
	local var_11_1

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.sideTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and not arg_11_0.greenTargetCache_[iter_11_1] and (not var_11_0 or var_11_1 > math.abs(iter_11_1:getX() - arg_11_0:getX())) then
			var_11_0 = iter_11_1
			var_11_1 = math.abs(iter_11_1:getX() - arg_11_0:getX())
		end
	end

	if var_11_0 then
		arg_11_0.greenTargetCache_[var_11_0] = true

		return {
			var_11_0
		}
	end

	for iter_11_2, iter_11_3 in ipairs(arg_11_0.sideTeam_) do
		if not iter_11_3:isDeath() and not iter_11_3:isAffected() and (not var_11_0 or var_11_1 > math.abs(iter_11_3:getX() - arg_11_0:getX())) then
			var_11_0 = iter_11_3
			var_11_1 = math.abs(iter_11_3:getX() - arg_11_0:getX())
		end
	end

	if var_11_0 then
		return {
			var_11_0
		}
	end

	return {}
end

function var_0_3.updateUnitBaseByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if var_0_5:father(arg_12_1.skillID) == arg_12_0:getEnergySkillID() then
		arg_12_3 = (var_0_8 * arg_12_0.energyExtraRate_ + 1) * arg_12_3
	elseif arg_12_1.skillID == arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_12_3 = (1 - arg_12_1.target:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE) * var_0_9 * arg_12_3 + arg_12_3
	end

	return var_0_3.super.updateUnitBaseByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
end

function var_0_3.buffAddAction(arg_13_0, arg_13_1)
	if arg_13_1:getTableID() == var_0_6 then
		arg_13_0.shanbiCount_ = 0
	end
end

return var_0_3
