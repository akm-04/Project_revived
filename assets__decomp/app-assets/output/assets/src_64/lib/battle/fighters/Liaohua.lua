local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liaohua", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.hero
local var_0_10 = var_0_2.tables.model
local var_0_11 = 40010045
local var_0_12 = 10000300
local var_0_13 = 10000301
local var_0_14 = -0.09
local var_0_15 = -0.004
local var_0_16 = -0.49
local var_0_17 = -0.004
local var_0_18 = 40011787
local var_0_19 = 0.005

function var_0_3.singleLoop(arg_1_0)
	var_0_3.super.singleLoop(arg_1_0)
	arg_1_0:applyPurpleBuffs()
end

function var_0_3.getHpPercent(arg_2_0)
	return arg_2_0:getHp() / arg_2_0:getHpLimit()
end

function var_0_3.getExtraADJianShang(arg_3_0)
	local var_3_0 = var_0_14 + var_0_15 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
	local var_3_1 = var_0_16 + var_0_17 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

	return (1 - arg_3_0:getHpPercent()) * (var_3_1 - var_3_0) + var_3_0
end

function var_0_3.getADJianShang(arg_4_0)
	local var_4_0 = var_0_3.super.getADJianShang(arg_4_0)

	if arg_4_0:isHasBuffByID(var_0_11) then
		local var_4_1 = arg_4_0:getExtraADJianShang()

		return math.max(0, var_4_0 + var_4_1)
	end

	return var_4_0
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_5_1.target:getHp() / arg_5_1.target:getHpLimit() > arg_5_0:getHpPercent() then
			local var_5_0 = {
				arg_5_1.target
			}
			local var_5_1 = arg_5_0:createAttackUnits(var_5_0, var_0_12)

			for iter_5_0, iter_5_1 in ipairs(var_5_1) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end
		elseif arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_5_1.target:getHp() / arg_5_1.target:getHpLimit() > arg_5_0:getHpPercent() then
			local var_5_2 = {
				arg_5_1.target
			}
			local var_5_3 = arg_5_0:createAttackUnits(var_5_2, var_0_13)

			for iter_5_2, iter_5_3 in ipairs(var_5_3) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
				table.insert(arg_5_0.records_.special_units, iter_5_3)
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if arg_6_0.isSkinSkillOn_ then
		arg_6_0:addSkinBuff()
	end
end

function var_0_3.applyPurpleBuffs(arg_7_0)
	if arg_7_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count < 30 then
		return
	end

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 or var_0_1.ctx.battle.count % 30 > 1 then
		return
	end

	local var_7_0 = (1 - arg_7_0:getHp() / arg_7_0:getHpLimit()) * 10
	local var_7_1 = math.floor(var_7_0)
	local var_7_2 = arg_7_0:purpleUnitCure()

	arg_7_0:updateHp(arg_7_0:getHp() + var_7_2 * var_7_1)
end

function var_0_3.purpleUnitCure(arg_8_0)
	if not arg_8_0.purple_ then
		local var_8_0 = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_8_1 = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_8_2 = var_0_8:ad(var_8_0) + var_0_8:adStep(var_8_0) * var_8_1
		local var_8_3 = var_0_8:ap(var_8_0) + var_0_8:apStep(var_8_0) * var_8_1
		local var_8_4 = var_0_8:init(var_8_0)
		local var_8_5 = var_0_8:step(var_8_0)

		arg_8_0.purple_ = {
			ad = var_8_2,
			ap = var_8_3,
			base = var_8_4 + var_8_5 * var_8_1
		}
	end

	return (arg_8_0:updateUnitBaseByFighter(arg_8_0, arg_8_0.purple_.ad, arg_8_0.purple_.ap) + arg_8_0.purple_.base) * arg_8_0:getCureRate() * (1 + arg_8_0:getAddCure())
end

function var_0_3.addSkinBuff(arg_9_0)
	local var_9_0 = var_0_7.new({
		tableID = var_0_18,
		start = var_0_1.ctx.battle.count,
		level = arg_9_0:getLevel(),
		fighter = arg_9_0,
		target = arg_9_0
	})

	var_9_0:setIsHit(true)
	var_9_0:setDirection(arg_9_0:getFighterModel():getFlipX())
	arg_9_0:addBuffs({
		var_9_0
	})
end

function var_0_3.updateUnitBaseByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = var_0_3.super.updateUnitBaseByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3)

	if arg_10_0.isSkinSkillOn_ then
		return var_10_0 * (1 + var_0_19 * arg_10_0:getLevel())
	else
		return var_10_0
	end
end

return var_0_3
