local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiangwei", var_0_1.ctx.battle.requireFighter("Jiangwei"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0
local var_0_7 = 0.003
local var_0_8 = -100
local var_0_9 = 10000327
local var_0_10 = 40010656
local var_0_11 = 90
local var_0_12 = 20010227
local var_0_13 = 40010651
local var_0_14 = 40010650

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("unit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.awakeHarm_ = {}
	arg_2_0.records_.stun_hit = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_3_0:awakeTwiceSkillDeal()
	end

	if arg_3_0.purpleEnhance then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("unit_info")) do
			local var_3_0 = iter_3_1.target
			local var_3_1 = iter_3_1.fighter

			if var_3_0 == arg_3_0 and var_3_1:getTeamType() ~= arg_3_0:getTeamType() and not var_3_1:isDeath() and not var_3_1:isAffected() and #var_3_1:getBuffsByID(var_0_14) < 10 then
				local var_3_2 = var_0_4.new({
					tableID = var_0_14,
					start = var_0_1.ctx.battle.count,
					level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice),
					skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
					fighter = arg_3_0,
					target = var_3_1
				})

				var_3_1:addBuffs({
					var_3_2
				})
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == var_0_9 and arg_4_0.energyEnhance then
		local var_4_0
		local var_4_1 = var_0_2.split(arg_4_1.target.fighterIndex, "|")
		local var_4_2 = tostring(var_4_1[2])

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_4_0.stunHit_[var_4_2] and arg_4_0.stunHit_[var_4_2][tostring(var_0_1.ctx.battle.count)] then
				var_4_0 = true
			end
		else
			var_4_0 = var_0_2.weightedChoise({
				arg_4_0.hitRate,
				1 - arg_4_0.hitRate
			}) == 1

			if var_4_0 then
				if not arg_4_0.records_.stun_hit[var_4_2] then
					arg_4_0.records_.stun_hit[var_4_2] = {}
				end

				arg_4_0.records_.stun_hit[var_4_2][tostring(var_0_1.ctx.battle.count)] = true
			end
		end

		if var_4_0 then
			arg_4_1.target:checkSkillBreak(var_0_2.BreakSkillType.AD, arg_4_1)
		end
	end
end

function var_0_3.awakeTwiceSkillDeal(arg_5_0)
	if arg_5_0.awakeTwiceInit then
		return
	end

	arg_5_0.awakeTwiceInit = true

	local var_5_0 = 0
	local var_5_1 = 0

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if iter_5_1.hero_:getHeroType() == var_0_2.HeroType.WISE then
			var_5_0 = var_5_0 + 1
		elseif iter_5_1.hero_:getHeroType() == var_0_2.HeroType.AGILE then
			var_5_1 = var_5_1 + 1
		end
	end

	if var_5_0 > 2 then
		arg_5_0.greenEnhance = true
	elseif var_5_1 > 2 then
		arg_5_0.purpleEnhance = true
	else
		arg_5_0.energyEnhance = true

		local var_5_2 = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		arg_5_0.hitRate = math.min(1, var_0_5:init(var_5_2) + var_0_5:step(var_5_2) * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice))
	end
end

function var_0_3.updateUnitDataByTarget(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_4 >= 0.18 * arg_6_0:getHpLimit() then
		local var_6_0 = arg_6_4 * (var_0_6 + var_0_7 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

		if not arg_6_0.awakeHarm_[arg_6_1.fighter] then
			arg_6_0.awakeHarm_[arg_6_1.fighter] = var_6_0
		else
			arg_6_0.awakeHarm_[arg_6_1.fighter] = arg_6_0.awakeHarm_[arg_6_1.fighter] + var_6_0
		end

		if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport and not arg_6_1.fighter:isAffected() then
			local var_6_1 = arg_6_0:createAttackUnits({
				arg_6_1.fighter
			}, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_6_0, iter_6_1 in ipairs(var_6_1) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end

		arg_6_4 = arg_6_4 - var_6_0
	end

	return var_0_3.super.updateUnitDataByTarget(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	if arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) and arg_7_0.awakeHarm_[arg_7_1.target] then
		arg_7_4 = arg_7_4 + arg_7_0.awakeHarm_[arg_7_1.target]
		arg_7_0.awakeHarm_[arg_7_1.target] = 0
	end

	return var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
end

function var_0_3.updateEnergySkill(arg_8_0)
	if not arg_8_0.isEnergy_ or var_0_1.ctx.battle.count % 30 > 0 then
		return
	end

	if var_0_1.ctx.battle.teamBEnd then
		if arg_8_0.energyEffect_ then
			arg_8_0.energyEffect_:stop()

			arg_8_0.energyEffect_ = nil
		end

		return
	end

	arg_8_0:updateEnergyBy(var_0_8)

	if arg_8_0:getEnergy() < 1 then
		if not arg_8_0.energyStillCount or arg_8_0.energyStillCount < 1 then
			arg_8_0.isEnergy_ = nil
			arg_8_0.noEnergy_ = nil

			if arg_8_0.energyEffect_ then
				arg_8_0.energyEffect_:stop()

				arg_8_0.energyEffect_ = nil
			end
		else
			arg_8_0.energyStillCount = arg_8_0.energyStillCount - 1
		end
	end

	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		return
	end

	local var_8_0 = var_0_9
	local var_8_1 = arg_8_0:getEnergyTarget()
	local var_8_2 = arg_8_0:createAttackUnits(var_8_1, var_8_0)

	for iter_8_0, iter_8_1 in ipairs(var_8_2) do
		table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
		table.insert(arg_8_0.records_.special_units, iter_8_1)
	end
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	if not arg_9_0.greenEnhance or arg_9_1:getTableID() ~= var_0_12 then
		return
	end

	arg_9_1:setExtraTime(30)

	local var_9_0 = var_0_4.new({
		tableID = var_0_13,
		start = var_0_1.ctx.battle.count,
		level = arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice),
		skillID = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
		fighter = arg_9_0,
		target = arg_9_1.target
	})

	arg_9_1.target:addBuffs({
		var_9_0
	})
end

function var_0_3.die(arg_10_0)
	var_0_3.super.die(arg_10_0)

	if arg_10_0.isEnergy_ and arg_10_0.energyEnhance then
		arg_10_0.energyStillCount = var_0_11
	end
end

function var_0_3.setupReport(arg_11_0, arg_11_1)
	var_0_3.super.setupReport(arg_11_0, arg_11_1)

	arg_11_0.stunHit_ = arg_11_1.stun_hit
end

function var_0_3.writeReport(arg_12_0)
	local var_12_0 = var_0_3.super.writeReport(arg_12_0)

	var_12_0.stun_hit = arg_12_0.records_.stun_hit

	return var_12_0
end

return var_0_3
