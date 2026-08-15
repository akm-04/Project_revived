local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Aidehua", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 3
local var_0_7 = 40010545
local var_0_8 = 0
local var_0_9 = 25
local var_0_10 = 100
local var_0_11 = 40010546

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergyBuff_ = false
	arg_1_0.purpleTarget_ = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isEnergyBuff_ and var_0_1.ctx.battle.count % 30 < 1 and arg_2_0:getNearestTarget() then
		arg_2_0:updateEnergyTo(arg_2_0:getEnergy() - var_0_10)

		if arg_2_0:getEnergy() < 1 then
			arg_2_0.isEnergyBuff_ = false

			arg_2_0:removeBuffByID(var_0_11)
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if var_0_5:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if arg_3_1.target:getHp() > arg_3_0:getHp() then
			local var_3_0 = arg_3_0:newBuff({
				var_0_7
			}, arg_3_1.target, arg_3_1.skillID)

			arg_3_1.target:addBuffs(var_3_0)
		end
	elseif arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		arg_3_0.isEnergyBuff_ = true
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_3_1.skillID ~= arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_3_0:addPurpleHarmNum(arg_3_1.target)
	end
end

function var_0_3.addPurpleHarmNum(arg_4_0, arg_4_1)
	if not arg_4_1 or arg_4_1:isDeath() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_4_0 = arg_4_0.purpleTarget_[arg_4_1]

	arg_4_0.purpleTarget_[arg_4_1] = var_4_0 and var_4_0 + 1 or 0

	if arg_4_0.purpleTarget_[arg_4_1] >= var_0_6 then
		arg_4_0.purpleTarget_[arg_4_1] = 0

		local var_4_1 = {
			arg_4_1
		}
		local var_4_2 = arg_4_0:createAttackUnits(var_4_1, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_4_0, iter_4_1 in ipairs(var_4_2) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_5_0)
	local var_5_0 = var_0_3.super.getOrbOfFrontSkill(arg_5_0)
	local var_5_1 = var_0_5:buffOrb(var_5_0)

	if var_5_1 > 0 and arg_5_0.isEnergyBuff_ then
		return var_5_1
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_5_0)
end

function var_0_3.getCurrentAckSpeed(arg_6_0)
	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) < 1 then
		return var_0_3.super.getCurrentAckSpeed(arg_6_0)
	end

	local var_6_0 = arg_6_0:getAttrByType(var_0_2.AttributeType.ACK_SPEED) + arg_6_0:getExtraAckSpeed()
	local var_6_1 = math.min(var_6_0 / var_0_2.DECIMAL_BASE, var_0_2.MAX_ATTACK_SPEED)

	return (math.max(var_6_1, var_0_2.MIN_ATTACK_SPEED))
end

function var_0_3.getExtraAckSpeed(arg_7_0)
	local var_7_0 = 0
	local var_7_1 = 0

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
		if not iter_7_1:isDeath() and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_7_0 = var_7_0 + 1
		end
	end

	for iter_7_2, iter_7_3 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_3:isDeath() and iter_7_3:getSummonType() == var_0_2.summonMonsterType.None then
			var_7_1 = var_7_1 + 1
		end
	end

	return math.max(var_7_1 - var_7_0, 0) * (var_0_8 + var_0_9 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_4.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_0:getSkillLevelByID(arg_8_3),
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

function var_0_3.checkEnergySkill(arg_9_0)
	if arg_9_0.isEnergyBuff_ then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_9_0)
	end
end

function var_0_3.energyAction(arg_10_0, arg_10_1)
	if var_0_5:father(arg_10_1) == arg_10_0:getEnergySkillID() then
		arg_10_0:getFighterModel():playEnergyEffect_()

		if arg_10_0:getTeamType() == var_0_2.TeamType.A or arg_10_0.isInArena_ then
			arg_10_0:addBlackLayer()
		end
	end
end

return var_0_3
