local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhangheSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40012177
local var_0_7 = 0.22
local var_0_8 = 30
local var_0_9 = 0.6
local var_0_10 = {
	10002009,
	10002010,
	10002011,
	10002012,
	10002013
}
local var_0_11 = {
	10002005,
	10002006,
	10002007,
	10002008
}
local var_0_12 = 40012162
local var_0_13 = 40012164
local var_0_14 = 5
local var_0_15 = 0.05
local var_0_16 = 0.2
local var_0_17 = 0.005
local var_0_18 = 10002015
local var_0_19 = {
	40012166,
	40012167
}
local var_0_20 = 50
local var_0_21 = 150
local var_0_22 = 80010255

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyCount = 0
	arg_1_0.isPurpleStrike = false
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.PurplePugongSkill = 10002568
		arg_2_0.PurpleSelfSkill = 10002569
	else
		arg_2_0.PurplePugongSkill = 10002014
		arg_2_0.PurpleSelfSkill = 10002016
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	if var_0_5:father(arg_3_1.rootID_) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_3_0.isPurpleStrike = false

		local var_3_0 = var_0_16 + var_0_17 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if var_0_2.weightedChoise({
			var_3_0,
			1 - var_3_0
		}) == 1 then
			arg_3_0.isPurpleStrike = true

			if arg_3_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_1 = arg_3_0:createAttackUnits({
					arg_3_0
				}, var_0_22)

				for iter_3_0, iter_3_1 in ipairs(var_3_1) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
					table.insert(arg_3_0.records_.special_units, iter_3_1)
				end
			end
		end
	end

	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if var_0_5:father(arg_4_1.skillID) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_4_1.target.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI then
		local var_4_0 = arg_4_0:createNewBuffs({
			var_0_12
		}, arg_4_1.target, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		arg_4_1.target:addBuffs(var_4_0)
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if var_0_5:father(arg_4_1.skillID) == arg_4_0:getPugongID() then
			local var_4_1 = var_0_16 + var_0_17 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

			if var_0_2.weightedChoise({
				var_4_1,
				1 - var_4_1
			}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				if arg_4_0.skinSkillIndex_ == 1 then
					local var_4_2 = arg_4_0:createAttackUnits({
						arg_4_0
					}, var_0_22)

					for iter_4_0, iter_4_1 in ipairs(var_4_2) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
						table.insert(arg_4_0.records_.special_units, iter_4_1)
					end
				end

				local var_4_3 = arg_4_0:createAttackUnits({
					arg_4_0
				}, arg_4_0.PurplePugongSkill)

				for iter_4_2, iter_4_3 in ipairs(var_4_3) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
					table.insert(arg_4_0.records_.special_units, iter_4_3)
				end

				local var_4_4 = arg_4_0:createAttackUnits({
					arg_4_0
				}, arg_4_0.PurpleSelfSkill)

				for iter_4_4, iter_4_5 in ipairs(var_4_4) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
					table.insert(arg_4_0.records_.special_units, iter_4_5)
				end
			end
		elseif var_0_5:father(arg_4_1.skillID) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
			local var_4_5 = var_0_16 + var_0_17 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

			if var_0_2.weightedChoise({
				var_4_5,
				1 - var_4_5
			}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				if arg_4_0.skinSkillIndex_ == 1 then
					local var_4_6 = arg_4_0:createAttackUnits({
						arg_4_0
					}, var_0_22)

					for iter_4_6, iter_4_7 in ipairs(var_4_6) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
						table.insert(arg_4_0.records_.special_units, iter_4_7)
					end
				end

				local var_4_7 = arg_4_0:createAttackUnits({
					arg_4_0
				}, var_0_18)

				for iter_4_8, iter_4_9 in ipairs(var_4_7) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_9)
					table.insert(arg_4_0.records_.special_units, iter_4_9)
				end

				local var_4_8 = arg_4_0:createAttackUnits({
					arg_4_0
				}, arg_4_0.PurpleSelfSkill)

				for iter_4_10, iter_4_11 in ipairs(var_4_8) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_11)
					table.insert(arg_4_0.records_.special_units, iter_4_11)
				end
			end
		end
	end

	if arg_4_1.skillID == var_0_18 then
		local var_4_9 = arg_4_0:createNewBuffs(var_0_19, arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_4_0:addBuffs(var_4_9)
	end
end

function var_0_3.selectTargetByTypeD1(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0
	local var_5_1

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
			local var_5_2 = iter_5_1:getHuJia() + iter_5_1:getMoKang()

			if not var_5_0 or var_5_0 < var_5_2 then
				var_5_1 = iter_5_1
				var_5_0 = var_5_2
			end
		end
	end

	return {
		var_5_1
	}
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.energyCount > 0 then
		arg_6_0.energyCount = arg_6_0.energyCount - 1
	end
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5 = var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_7_2 > 0 and arg_7_0.energyCount == 0 and arg_7_0:isHasBuffByID(var_0_6) then
		arg_7_0.energyCount = var_0_8

		local var_7_0

		if arg_7_0.skinSkillIndex_ == 1 then
			local var_7_1 = (1 - 4 * var_0_7) * 2
			local var_7_2 = (1 - var_7_1) / 4

			var_7_0 = var_0_2.weightedChoise({
				var_7_2,
				var_7_2,
				var_7_2,
				var_7_2,
				var_7_1
			})
		else
			var_7_0 = var_0_2.weightedChoise({
				var_0_7,
				var_0_7,
				var_0_7,
				var_0_7,
				1 - 4 * var_0_7
			})
		end

		local var_7_3 = arg_7_0:createAttackUnits({
			arg_7_0
		}, var_0_10[var_7_0])

		for iter_7_0, iter_7_1 in ipairs(var_7_3) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end

		if var_7_0 < 3 then
			local var_7_4 = arg_7_0:createAttackUnits({
				arg_7_0
			}, var_0_11[var_7_0])

			for iter_7_2, iter_7_3 in ipairs(var_7_4) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		elseif var_7_0 < 5 then
			local var_7_5 = arg_7_0:createAttackUnits({
				arg_7_1.fighter
			}, var_0_11[var_7_0])

			for iter_7_4, iter_7_5 in ipairs(var_7_5) do
				if var_7_0 == 4 then
					iter_7_5:setExtraHarm(arg_7_2 * var_0_9)
				end

				table.insert(arg_7_0.moveAttackUnits_, iter_7_5)
				table.insert(arg_7_0.records_.special_units, iter_7_5)
			end
		else
			for iter_7_6 = 1, 2 do
				local var_7_6 = arg_7_0:createAttackUnits({
					arg_7_0
				}, var_0_11[iter_7_6])

				for iter_7_7, iter_7_8 in ipairs(var_7_6) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_8)
					table.insert(arg_7_0.records_.special_units, iter_7_8)
				end

				local var_7_7 = arg_7_0:createAttackUnits({
					arg_7_1.fighter
				}, var_0_11[iter_7_6 + 2])

				for iter_7_9, iter_7_10 in ipairs(var_7_7) do
					if iter_7_6 + 2 == 4 then
						iter_7_10:setExtraHarm(arg_7_2 * var_0_9)
					end

					table.insert(arg_7_0.moveAttackUnits_, iter_7_10)
					table.insert(arg_7_0.records_.special_units, iter_7_10)
				end
			end
		end
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_8_4 = arg_8_4 + (var_0_4:init(var_0_13) + var_0_4:step(var_0_13) * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)) * -2 * (var_0_14 + var_0_15 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
	end

	if arg_8_1.skillID == var_0_22 then
		arg_8_7 = var_0_20
	end

	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_8_0.isPurpleStrike then
		arg_8_4 = arg_8_1.basicHarm

		if arg_8_3 and arg_8_1.attackType == var_0_2.AttackType.AD then
			arg_8_4 = arg_8_4 * (arg_8_1.fighter:getADBaoJiHarm() + arg_8_1.fighter:getBothBaojiHarm()) / var_0_2.DECIMAL_BASE
			arg_8_4 = arg_8_4 * math.max(0.01, arg_8_1.target:getADBaoJiJianShang())
		elseif arg_8_3 and arg_8_1.attackType == var_0_2.AttackType.AP then
			arg_8_4 = arg_8_4 * (arg_8_1.fighter:getAPBaoJiHarm() + arg_8_1.fighter:getBothBaojiHarm()) / var_0_2.DECIMAL_BASE
			arg_8_4 = arg_8_4 * math.max(0.01, arg_8_1.target:getAPBaoJiJianShang())
		elseif arg_8_3 and arg_8_1.attackType == var_0_2.AttackType.CURE then
			arg_8_4 = arg_8_4 * (arg_8_1.fighter:getAPBaoJiHarm() + arg_8_1.fighter:getBothBaojiHarm()) / var_0_2.DECIMAL_BASE
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_8_0 = arg_8_0:createAttackUnits({
				arg_8_0
			}, arg_8_0.PurpleSelfSkill)

			for iter_8_0, iter_8_1 in ipairs(var_8_0) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
				table.insert(arg_8_0.records_.special_units, iter_8_1)
			end
		end
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	if arg_9_1:getTableID() == var_0_6 and arg_9_0.skinSkillIndex_ == 1 then
		arg_9_1:setExtraTime(var_0_21)
	end
end

return var_0_3
