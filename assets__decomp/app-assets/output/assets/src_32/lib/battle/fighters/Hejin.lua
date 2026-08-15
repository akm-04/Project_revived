local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hejin", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 0.05
local var_0_6 = 40011095
local var_0_7 = 1
local var_0_8 = 0.01
local var_0_9 = 40011096
local var_0_10 = 0.3
local var_0_11 = 0.005
local var_0_12 = 10000990
local var_0_13 = 10000991
local var_0_14 = 0.003
local var_0_15 = 0.5
local var_0_16 = 80010180
local var_0_17 = 10001447
local var_0_18 = 40011484
local var_0_19 = 40011482
local var_0_20 = 0.4
local var_0_21 = 10001445
local var_0_22 = 10001446
local var_0_23 = 40011483
local var_0_24 = 10001782
local var_0_25 = 10001667
local var_0_26 = 40011770
local var_0_27 = 40011771
local var_0_28 = 40011443

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_2_0.EnergyBuffID = 40011771
		arg_2_0.EnergyDieSkill = 10001785
	else
		arg_2_0.EnergyBuffID = 40011097
		arg_2_0.EnergyDieSkill = 10001002
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.energyTargets_ = {}
	arg_3_0.blueTargetHarmInfo = {}
	arg_3_0.energyTarget_ = nil
	arg_3_0.skinSkillUsed_CaptainGirl = false
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	arg_4_0:checkEnergy()

	if next(arg_4_0.blueTargetHarmInfo) then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
			local var_4_0 = iter_4_1.harm
			local var_4_1 = iter_4_1.target

			if arg_4_0.blueTargetHarmInfo[var_4_1] then
				arg_4_0.blueTargetHarmInfo[var_4_1] = arg_4_0.blueTargetHarmInfo[var_4_1] + var_4_0
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_0:getEnergySkillID()

	if arg_5_1.rootID_ == var_5_0 or arg_5_1.rootID_ == var_0_17 or arg_5_1.rootID_ == var_0_24 then
		arg_5_0.energyTarget_ = nil
	end
end

function var_0_3.checkEnergy(arg_6_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_6_0 = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_0.energyTargets_) do
		if iter_6_1 and not iter_6_0:isDeath() and not iter_6_0:isAffected() and not iter_6_0:isBoss() and iter_6_0:getHp() / iter_6_0:getHpLimit() <= var_0_5 then
			table.insert(var_6_0, iter_6_0)

			arg_6_0.energyTargets_[iter_6_0] = false
		end
	end

	if next(var_6_0) then
		local var_6_1 = arg_6_0:createAttackUnits(var_6_0, arg_6_0.EnergyDieSkill)

		for iter_6_2, iter_6_3 in ipairs(var_6_1) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
			table.insert(arg_6_0.records_.special_units, iter_6_3)
		end
	end
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	var_0_3.super.buffAddAction(arg_7_0, arg_7_1)

	if arg_7_1:getTableID() == (arg_7_0.skinSkillID_ == var_0_16 and var_0_18 or arg_7_0.EnergyBuffID) then
		arg_7_0.energyTargets_[arg_7_1.target] = true
	elseif arg_7_1:getTableID() == var_0_9 or arg_7_1:getTableID() == var_0_23 or arg_7_1:getTableID() == var_0_26 then
		arg_7_0.blueTargetHarmInfo[arg_7_1.target] = 0
	end
end

function var_0_3.buffRemoveAction(arg_8_0, arg_8_1)
	var_0_3.super.buffRemoveAction(arg_8_0, arg_8_1)

	if arg_8_1:getTableID() == (arg_8_0.skinSkillID_ == var_0_16 and var_0_18 or arg_8_0.EnergyBuffID) then
		arg_8_0.energyTargets_[arg_8_1.target] = false
	elseif (arg_8_1:getTableID() == var_0_9 or arg_8_1:getTableID() == var_0_23 or arg_8_1:getTableID() == var_0_26) and not arg_8_1.target:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_8_0.blueTargetHarmInfo[arg_8_1.target] then
		local var_8_0 = arg_8_0.skinSkillID_ == var_0_16 and var_0_22 or arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) <= 0 and var_0_12 or var_0_25
		local var_8_1 = arg_8_0:createAttackUnits({
			arg_8_1.target
		}, var_8_0)

		for iter_8_0, iter_8_1 in ipairs(var_8_1) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end
	end
end

function var_0_3.deathFeedback(arg_9_0, arg_9_1)
	var_0_3.super.deathFeedback(arg_9_0, arg_9_1)

	if arg_9_0.blueTargetHarmInfo[arg_9_1] and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_9_0 = arg_9_0.skinSkillID_ == var_0_16 and var_0_22 or arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) <= 0 and var_0_12 or var_0_25
		local var_9_1 = arg_9_0:createAttackUnits({
			arg_9_1
		}, var_9_0)

		for iter_9_0, iter_9_1 in ipairs(var_9_1) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_10_0, arg_10_1)
	var_0_3.super.applySingleUnit(arg_10_0, arg_10_1)

	if arg_10_1.target:isDeath() and var_0_4:father(arg_10_1.skillID) == arg_10_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_10_1:recordData(false, false, 0, 0, 0, 0)
	end

	local var_10_0 = arg_10_0.skinSkillID_ == var_0_16 and var_0_22 or arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) <= 0 and var_0_12 or var_0_25

	if arg_10_1.skillID == arg_10_0.EnergyDieSkill and not arg_10_1.target:isDeath() then
		if arg_10_1.target:isHasBuffByID(var_0_28) then
			arg_10_1.target:removeBuffByID(var_0_28)
		end

		arg_10_1.target:updateHp(0)
		arg_10_1.target:die()
	elseif arg_10_1.skillID == var_10_0 and arg_10_0.blueTargetHarmInfo[arg_10_1.target] then
		if arg_10_1.target:isDeath() then
			local var_10_1 = var_0_1.ctx.battle.getSpine(var_10_0, "hurt", arg_10_1.target:getScale())

			var_10_1:addTo(var_0_1.ctx.battle.unitLayer)
			var_10_1:pos(arg_10_1.target:getX(), arg_10_1.target:getY())
			var_10_1:playOnce()
			var_10_1:flipX(arg_10_1.target:getFlipX())
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			if arg_10_1.target:isDeath() then
				arg_10_1:recordData(false, false, 0, 0, 0, 0)
			end

			local var_10_2 = arg_10_0:getTargets(var_0_13)

			if next(var_10_2) then
				local var_10_3 = arg_10_0:createAttackUnits(var_10_2, var_0_13)
				local var_10_4 = arg_10_0.skinSkillUsed_CaptainGirl and var_0_20 or arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) * var_0_11 + var_0_10
				local var_10_5 = arg_10_0.blueTargetHarmInfo[arg_10_1.target] * var_10_4

				for iter_10_0, iter_10_1 in ipairs(var_10_3) do
					iter_10_1:setExtraHarm(var_10_5)
					table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
					table.insert(arg_10_0.records_.special_units, iter_10_1)
				end
			end

			if not arg_10_0.skinSkillUsed_CaptainGirl and arg_10_0.skinSkillID_ == var_0_16 then
				arg_10_0.skinSkillUsed_CaptainGirl = true

				local var_10_6
				local var_10_7
				local var_10_8
				local var_10_9

				for iter_10_2, iter_10_3 in ipairs(arg_10_0.sideTeam_) do
					if not iter_10_3:isDeath() and not iter_10_3:isAffected() then
						local var_10_10 = iter_10_3:getHp()

						if not var_10_8 or var_10_10 <= var_10_6 then
							var_10_8 = iter_10_3
							var_10_6 = var_10_10
						end

						if not var_10_9 or var_10_7 <= var_10_10 then
							var_10_9 = iter_10_3
							var_10_7 = var_10_10
						end
					end
				end

				local var_10_11 = var_10_8 == var_10_9 and {
					var_10_8
				} or {
					var_10_8,
					var_10_9
				}
				local var_10_12 = arg_10_0:createAttackUnits(var_10_11, var_0_21)

				for iter_10_4, iter_10_5 in ipairs(var_10_12) do
					table.insert(arg_10_0.moveAttackUnits_, iter_10_5)
					table.insert(arg_10_0.records_.special_units, iter_10_5)
				end
			end
		end

		arg_10_0.blueTargetHarmInfo[arg_10_1.target] = nil
	elseif arg_10_1.skillID == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		for iter_10_6, iter_10_7 in ipairs(arg_10_0:getBuffs()) do
			local var_10_13 = iter_10_7:getDHarm()

			if var_10_13 > 0 then
				local var_10_14 = var_10_13 * (1 - (arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_14 + var_0_15))

				iter_10_7.dHarm_ = var_10_13 - var_10_14

				local var_10_15 = arg_10_0:createNewBuffs({
					iter_10_7:getTableID()
				}, arg_10_1.target, arg_10_1.skillID)

				var_10_15[1].manualDharm = var_10_15[1].manualDharm + var_10_14

				arg_10_1.target:addBuffs(var_10_15)
			end
		end
	end
end

function var_0_3.getUnitData(arg_11_0, arg_11_1)
	isShanbi, isBaoji, harm, cure, xixue, mp = var_0_3.super.getUnitData(arg_11_0, arg_11_1)

	if harm > 0 and arg_11_1.skillID == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_11_0 = arg_11_0.skinSkillID_ == var_0_16 and var_0_19 or var_0_6
		local var_11_1 = arg_11_0:getBuffByID(var_11_0)

		if not var_11_1 then
			local var_11_2 = arg_11_0:createNewBuffs({
				var_11_0
			}, arg_11_0, arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

			var_11_1 = var_11_2[1]

			local var_11_3 = var_11_1:getDHarm()
			local var_11_4 = harm * (var_0_8 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) + var_0_7)

			var_11_1.dHarm_ = var_11_3 + var_11_4
			var_11_1.manualDharm = var_11_1.manualDharm + var_11_4

			arg_11_0:addBuffs(var_11_2)
		else
			local var_11_5 = var_11_1:getDHarm()
			local var_11_6 = harm * (var_0_8 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) + var_0_7)

			var_11_1.dHarm_ = var_11_5 + var_11_6
			var_11_1.manualDharm = var_11_1.manualDharm + var_11_6
		end

		if var_11_1 then
			arg_11_0.showDHarmbuff_ = var_11_1
		end

		arg_11_0:updateHpBar(true)
	end

	return isShanbi, isBaoji, harm, cure, xixue, mp
end

function var_0_3.checkMove(arg_12_0)
	if arg_12_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_12_0.hero_:enterDuration() then
			arg_12_0.isWalking_ = 1

			if not arg_12_0:isWalking() then
				arg_12_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_12_0:isWalking() == 2 then
				local var_12_0 = arg_12_0:getFlipX() and -1 or 1

				arg_12_0:moveByX(arg_12_0.hero_:enterSpeed() * var_12_0)
			end

			if arg_12_0:getCurrentAnimation() ~= "run" then
				arg_12_0:modelWalk()
			end
		elseif not arg_12_0.playedEnterSkill_ then
			if arg_12_0:isWalking() ~= 3 then
				arg_12_0.preWalk_ = false
				arg_12_0.isWalking_ = false
				arg_12_0.behindWalk_ = false
				arg_12_0.playedEnterSkill_ = true
				arg_12_0.walk2Position_ = false

				if arg_12_0:getCurrentAnimation() == "run" then
					arg_12_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_12_0.hero_:enterDelayDuration() then
			arg_12_0.isEnterSkill_ = nil
			arg_12_0.walk2Position_ = false
			arg_12_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_12_0)
end

function var_0_3.setFormation(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	arg_13_0.isEnterSkill_ = arg_13_0:enterSkill() > 0 and arg_13_0:getSkillLevelByID(arg_13_0:enterSkill()) > 0

	if arg_13_0.isEnterSkill_ then
		arg_13_0.playedEnterSkill_ = false

		local var_13_0 = arg_13_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_13_0:x(var_13_0)
		arg_13_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_13_3 - 90 * (arg_13_2 % 2))

		return arg_13_2 + 1
	end

	return var_0_3.super.setFormation(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
end

function var_0_3.enterSkill(arg_14_0)
	return arg_14_0.hero_:enterSkill()
end

function var_0_3.selectTargetByTypeD4(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0
	local var_15_1

	for iter_15_0, iter_15_1 in pairs(arg_15_0.selfTeam_) do
		if not iter_15_1:isDeath() and iter_15_1:getSummonType() == var_0_2.summonMonsterType.None and iter_15_1 ~= arg_15_0 and (not var_15_0 or var_15_1 > iter_15_1:getHp() / iter_15_1:getHpLimit() or var_15_1 == iter_15_1:getHp() / iter_15_1:getHpLimit() and var_15_0:getHp() > iter_15_1:getHp()) then
			var_15_0 = iter_15_1
			var_15_1 = var_15_0:getHp() / var_15_0:getHpLimit()
		end
	end

	return {
		var_15_0
	}
end

function var_0_3.selectTargetByTypeD3(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_0.energyTarget_ then
		return {
			arg_16_0.energyTarget_
		}
	end

	local var_16_0
	local var_16_1

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.sideTeam_) do
		if not iter_16_1:isDeath() and not iter_16_1:isAffected() and iter_16_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_16_1 or var_16_1 < iter_16_1.harms) then
			var_16_0 = iter_16_1
			var_16_1 = iter_16_1.harms
		end
	end

	arg_16_0.energyTarget_ = var_16_0

	return {
		var_16_0
	}
end

return var_0_3
