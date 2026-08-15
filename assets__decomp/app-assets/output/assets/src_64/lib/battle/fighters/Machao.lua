local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Machao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.model
local var_0_7 = var_0_2.tables.elementEquip
local var_0_8 = 0.5
local var_0_9 = 120
local var_0_10 = 30
local var_0_11 = 0.8
local var_0_12 = 0.5
local var_0_13 = 0.2
local var_0_14 = 4
local var_0_15 = 15000
local var_0_16 = 10001114
local var_0_17 = 20001505
local var_0_18 = {
	40012747,
	40012748,
	40012749,
	40012750
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.wolf_ = false
	arg_1_0.firstWolf = false
	arg_1_0.transExtraHP = 0
	arg_1_0.transExtraMP = 0

	if arg_1_0.fighterModel then
		arg_1_0.fighterModel:transformModel(1)
		arg_1_0:flipX(false)
		arg_1_0:resumeIdle()
	end
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getOrbOfFrontSkill(arg_3_0)
	local var_3_1 = var_0_4:buffOrb(var_3_0)

	if var_3_1 and arg_3_0.wolf_ then
		return var_3_1
	end

	if arg_3_0.isSkinSkillOn_ and var_3_0 == arg_3_0:getEnergySkillID() then
		return var_0_16
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_3_0)
end

function var_0_3.isBreakImmortal(arg_4_0)
	if arg_4_0.wolf_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_4_0)
	end
end

function var_0_3.checkEnergySkill(arg_5_0)
	if arg_5_0.wolf_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_5_0)
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.target

	if var_6_0:isDeath() then
		return
	end

	local var_6_1 = var_0_4:father(arg_6_1.skillID)

	if arg_6_0.wolf_ and var_6_1 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_6_0 ~= arg_6_0 then
		local var_6_2 = arg_6_0:getX()
		local var_6_3 = arg_6_0:getY()
		local var_6_4 = var_6_0:getX()
		local var_6_5 = var_6_0:getY()
		local var_6_6 = var_6_4 - var_6_2 > 0 and -120 or 120
		local var_6_7 = var_0_1.ctx.battle.adjustX(var_6_4 + var_6_6, arg_6_0)

		if var_6_0:avoidHeroMoveBehind() then
			local var_6_8 = var_6_0:getX() - var_6_6

			var_6_7 = var_0_1.ctx.battle.adjustX(var_6_8, arg_6_0)
			var_6_6 = 0
		end

		arg_6_0:pos(var_6_7, var_6_5)
		arg_6_0:flipX(var_6_6 > 0)
	end

	if not arg_6_0.wolf_ and var_6_1 == arg_6_0:getEnergySkillID() and var_6_0 == arg_6_0 then
		arg_6_0:transformIntoWolf()
	end
end

function var_0_3.transformIntoWolf(arg_7_0)
	if arg_7_0.wolf_ then
		return
	end

	arg_7_0.wolf_ = true

	if arg_7_0:hasElementEquipByID(var_0_17) and not arg_7_0.firstWolf then
		arg_7_0.firstWolf = true

		local var_7_0 = var_0_17
		local var_7_1 = var_0_7:skillIDs(var_7_0)
		local var_7_2 = arg_7_0:createNewBuffs(var_0_18, arg_7_0, var_7_1[1])
		local var_7_3 = var_0_7:battleAttr(var_7_0, arg_7_0:getElementEquipLevelByID(var_7_0))
		local var_7_4 = arg_7_0.hero_:getElementEquipActiveRate(var_7_0)

		for iter_7_0, iter_7_1 in ipairs(var_7_2) do
			if iter_7_0 > 1 then
				iter_7_1.manualRevise = var_7_3 * var_7_4
			end
		end

		arg_7_0:addBuffs(var_7_2)
	end

	local var_7_5 = arg_7_0:getHp() + var_0_8 * arg_7_0:getHpLimit()

	if arg_7_0.isSkinSkillOn_ then
		var_7_5 = arg_7_0:getHp() + var_0_8 * arg_7_0:getHpLimit() + var_0_11 * arg_7_0:getHpLimit()
		arg_7_0.transExtraHP = math.max(var_7_5 - arg_7_0:getHpLimit(), 0)

		local var_7_6 = arg_7_0:getEnergy() + var_0_12 * arg_7_0:energyDecimalBase()

		arg_7_0.transExtraMP = math.max(var_7_6 - arg_7_0:energyDecimalBase(), 0)

		arg_7_0:updateEnergyTo(var_7_6)
	end

	arg_7_0:updateHp(var_7_5)
	arg_7_0.fighterModel:transformModel(2)

	local var_7_7 = arg_7_0:getFlipX()

	arg_7_0:flipX(var_7_7)
	arg_7_0:summon()

	arg_7_0.startSkillQueue_ = {}
	arg_7_0.skillQueue_ = arg_7_0.hero_:getCircle()

	arg_7_0:popColorSkill()

	arg_7_0.leftInterval_ = 0
end

function var_0_3.getDMP(arg_8_0)
	return var_0_2.PERCENT_BASE
end

function var_0_3.die(arg_9_0)
	if not arg_9_0.wolf_ then
		return
	end

	return var_0_3.super.die(arg_9_0)
end

function var_0_3.isDeath(arg_10_0)
	if not arg_10_0.wolf_ and arg_10_0:getHp() <= 0 then
		arg_10_0:transformIntoWolf()
		arg_10_0:updateEnergyTo(0)

		return false
	end

	return var_0_3.super.isDeath(arg_10_0)
end

function var_0_3.getAD(arg_11_0)
	if arg_11_0.wolf_ then
		local var_11_0 = var_0_10 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * arg_11_0:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE

		if arg_11_0.isSkinSkillOn_ then
			var_11_0 = var_11_0 + math.min(arg_11_0.transExtraHP * var_0_13 + arg_11_0.transExtraMP * var_0_14, var_0_15)
		end

		return var_0_3.super.getAD(arg_11_0) + var_11_0
	end

	return var_0_3.super.getAD(arg_11_0)
end

function var_0_3.getHuJia(arg_12_0)
	if not arg_12_0.wolf_ and arg_12_0.isSkinSkillOn_ then
		local var_12_0 = var_0_3.super.getHuJia(arg_12_0) * (1 - arg_12_0:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE)

		return var_0_3.super.getHuJia(arg_12_0) + var_12_0
	end

	return var_0_3.super.getHuJia(arg_12_0)
end

function var_0_3.buffRemoveAction(arg_13_0, arg_13_1)
	if arg_13_1:getRemoveSkill() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_13_0 = arg_13_1:getRemoveSkill()
	local var_13_1 = arg_13_0:getTargets(var_13_0)
	local var_13_2 = arg_13_0:createAttackUnits(var_13_1, var_13_0)

	for iter_13_0, iter_13_1 in ipairs(var_13_2) do
		table.insert(arg_13_0.moveAttackUnits_, iter_13_1)
		table.insert(arg_13_0.records_.special_units, iter_13_1)
	end
end

function var_0_3.getHpLimit(arg_14_0)
	if arg_14_0.wolf_ then
		local var_14_0 = var_0_9 * arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

		return arg_14_0.hpLimit_ + (arg_14_0.isInArena_ and var_14_0 * var_0_2.tables.battleConfig.arenaHpIncrease or var_14_0)
	end

	return arg_14_0.hpLimit_
end

return var_0_3
