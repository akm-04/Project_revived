local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Tianxiegui", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.battleConfig
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.model
local var_0_10 = 0.45
local var_0_11 = -0.0018
local var_0_12 = 0.33
local var_0_13 = 250
local var_0_14 = 0.45
local var_0_15 = -0.0018
local var_0_16 = 250
local var_0_17 = 0.45
local var_0_18 = -0.0018
local var_0_19 = 400
local var_0_20 = 0.5
local var_0_21 = 0.07
local var_0_22 = 0.035
local var_0_23 = 10001500
local var_0_24 = 10001501
local var_0_25 = 10001502
local var_0_26 = 10001503
local var_0_27 = 40011561
local var_0_28 = 40011570
local var_0_29 = 10001517
local var_0_30 = 10001505
local var_0_31 = 10001506
local var_0_32 = 10001508
local var_0_33 = 10001509
local var_0_34 = 10001510
local var_0_35 = 40011560
local var_0_36 = 40011889
local var_0_37 = 80010217
local var_0_38 = 10001764
local var_0_39 = 10001765
local var_0_40 = 10001766

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.greenChangeHp = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			if iter_3_1.target and iter_3_1.target:isHasBuffByID(var_0_27) and iter_3_1:getTableID() ~= var_0_28 and iter_3_1:canRemove() and iter_3_1:getType() == var_0_2.BuffType.REVIVIE then
				iter_3_1.target:removeBuffs(iter_3_1)

				local var_3_0 = var_0_4.new({
					tableID = var_0_28,
					start = var_0_1.ctx.battle.count,
					level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
					skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
					fighter = arg_3_0,
					target = iter_3_1.target
				})

				var_3_0.manualHarmRevise = iter_3_1:getHarm()

				if iter_3_1.target:isBoss() or not arg_3_0:isPVP() then
					var_3_0.manualHarmRevise = math.min(var_3_0.manualHarmRevise, 60 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
				end

				var_3_0:setExtraTime(iter_3_1:getTime())
				iter_3_1.target:addBuffs({
					var_3_0
				})
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	local var_4_0

	if arg_4_1.skillID == var_0_23 then
		local var_4_1 = arg_4_1.target:getHp() * (var_0_10 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) * var_0_11)

		if arg_4_1.target:isBoss() or not arg_4_0:isPVP() then
			var_4_1 = math.min(var_4_1, var_0_13 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
		end

		arg_4_0:updateHp(arg_4_0:getHp() - var_4_1)
		arg_4_0.fighterModel:playHPDeltas({
			{
				-var_4_1
			}
		}, nil)

		arg_4_0.selfHarm = var_4_1
	elseif arg_4_1.skillID == var_0_26 then
		local var_4_2 = arg_4_1.target:getHp() * (var_0_14 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) * var_0_15)

		if arg_4_1.target:isBoss() or not arg_4_0:isPVP() then
			var_4_2 = math.min(var_4_2, var_0_16 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
		end

		arg_4_0:updateHp(arg_4_0:getHp() - var_4_2)
		arg_4_0.fighterModel:playHPDeltas({
			{
				-var_4_2
			}
		}, nil)

		arg_4_0.selfHarm = var_4_2
	elseif arg_4_1.skillID == var_0_33 then
		local var_4_3 = arg_4_1.target:getHp() * (var_0_17 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_18)

		if arg_4_1.target:isBoss() or not arg_4_0:isPVP() then
			var_4_3 = math.min(var_4_3, var_0_19 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))
		end

		arg_4_0:updateHp(arg_4_0:getHp() - var_4_3)
		arg_4_0.fighterModel:playHPDeltas({
			{
				-var_4_3
			}
		}, nil)

		arg_4_0.selfHarm = var_4_3
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_1.skillID == var_0_23 then
		var_5_2 = 0
	elseif arg_5_1.skillID == var_0_24 then
		var_5_2 = arg_5_1.target:getHp() * var_0_12

		if arg_5_1.target:isBoss() or not arg_5_0:isPVP() then
			var_5_2 = math.min(var_5_2, var_0_13 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
		end

		arg_5_0.greenChangeHp = var_5_2
	elseif arg_5_1.skillID == var_0_25 then
		var_5_3 = arg_5_0.greenChangeHp / 2
	elseif arg_5_1.skillID == var_0_26 then
		var_5_2 = 0
	elseif arg_5_1.skillID == var_0_29 and arg_5_1.totalHarm then
		var_5_2 = arg_5_1.totalHarm

		if arg_5_1.target:isBoss() or not arg_5_0:isPVP() then
			var_5_2 = math.min(var_5_2, var_0_16 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
		end
	elseif arg_5_1.skillID == var_0_33 then
		var_5_2 = 0
	elseif arg_5_1.skillID == var_0_34 then
		var_5_2 = arg_5_1.target:getHp() * var_0_20

		if arg_5_1.target:isBoss() or not arg_5_0:isPVP() then
			var_5_2 = math.min(var_5_2, var_0_19 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))
		end
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_1.attackType == var_0_2.AttackType.CURE and arg_6_5 > 0 and arg_6_1.target:isHasBuffByID(var_0_27) and arg_6_1.skillID ~= var_0_29 then
		local var_6_0 = arg_6_0:createAttackUnits({
			arg_6_1.target
		}, var_0_29)

		for iter_6_0, iter_6_1 in ipairs(var_6_0) do
			iter_6_1.totalHarm = arg_6_5

			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end

		arg_6_5 = 0
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.forceDie(arg_7_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_7_0 = arg_7_0.isSkinSkillOn_ and var_0_38 or var_0_30
		local var_7_1 = arg_7_0.isSkinSkillOn_ and var_0_39 or var_0_31
		local var_7_2 = arg_7_0.isSkinSkillOn_ and var_0_40 or var_0_32
		local var_7_3 = arg_7_0:selectTargetByTypeD3()
		local var_7_4 = arg_7_0:createAttackUnits(var_7_3, var_7_0)

		for iter_7_0, iter_7_1 in ipairs(var_7_4) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end

		local var_7_5 = arg_7_0:selectTargetByTypeD4()

		if var_7_5 and next(var_7_5) then
			if var_7_5[1]:isBoss() then
				local var_7_6 = arg_7_0:createAttackUnits(var_7_5, var_7_2)

				for iter_7_2, iter_7_3 in ipairs(var_7_6) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
					table.insert(arg_7_0.records_.special_units, iter_7_3)
				end
			else
				local var_7_7 = arg_7_0:createAttackUnits(var_7_5, var_7_1)

				for iter_7_4, iter_7_5 in ipairs(var_7_7) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_5)
					table.insert(arg_7_0.records_.special_units, iter_7_5)
				end
			end
		end
	end

	var_0_3.super.forceDie(arg_7_0)
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	var_0_3.super.buffAddAction(arg_8_0, arg_8_1)

	if arg_8_1:getTableID() == var_0_35 and not arg_8_1.target:isBoss() then
		if arg_8_1.target:getTeamType() == arg_8_0:getTeamType() then
			arg_8_1.manualHarmRevise = var_0_21 * (arg_8_1.target:getHpLimit() - arg_8_1.target:getHp())
		else
			arg_8_1.manualHarmRevise = var_0_22 * (arg_8_1.target:getHpLimit() - arg_8_1.target:getHp())
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_9_0)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() then
			table.insert(var_9_0, iter_9_1)
		end
	end

	for iter_9_2, iter_9_3 in ipairs(arg_9_0.selfTeam_) do
		if not iter_9_3:isDeath() and not iter_9_3:isAffected() and iter_9_3 ~= arg_9_0 then
			table.insert(var_9_0, iter_9_3)
		end
	end

	return var_9_0
end

function var_0_3.selectTargetByTypeD2(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}
	local var_10_1

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.selfTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1 ~= arg_10_0 and (not var_10_1 or iter_10_1:getHp() / iter_10_1:getHpLimit() < var_10_1:getHp() / var_10_1:getHpLimit()) then
			var_10_1 = iter_10_1
		end
	end

	table.insert(var_10_0, var_10_1)
	table.insert(var_10_0, arg_10_0)

	return var_10_0
end

function var_0_3.selectTargetByTypeD3(arg_11_0)
	local var_11_0 = {}
	local var_11_1

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.selfTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1 ~= arg_11_0 and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_11_1 or iter_11_1:getHp() / iter_11_1:getHpLimit() < var_11_1:getHp() / var_11_1:getHpLimit()) then
			var_11_1 = iter_11_1
		end
	end

	table.insert(var_11_0, var_11_1)

	return var_11_0
end

function var_0_3.selectTargetByTypeD4(arg_12_0)
	local var_12_0 = {}
	local var_12_1

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.sideTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() and iter_12_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_12_1 or iter_12_1:getHp() / iter_12_1:getHpLimit() > var_12_1:getHp() / var_12_1:getHpLimit()) then
			var_12_1 = iter_12_1
		end
	end

	table.insert(var_12_0, var_12_1)

	return var_12_0
end

function var_0_3.afterDamageHarm(arg_13_0, arg_13_1, arg_13_2)
	if arg_13_0.isSkinSkillOn_ and (arg_13_2.skillID == var_0_33 or arg_13_2.skillID == var_0_23 or arg_13_2.skillID == var_0_26) then
		local var_13_0 = 0

		for iter_13_0, iter_13_1 in ipairs(arg_13_0.selfTeam_) do
			if not iter_13_1:isDeath() and iter_13_1:getSummonType() == var_0_2.summonMonsterType.None then
				var_13_0 = var_13_0 + 1
			end
		end

		local var_13_1 = math.min(var_13_0, 5)

		for iter_13_2, iter_13_3 in ipairs(arg_13_0.selfTeam_) do
			local var_13_2 = arg_13_0:createNewBuffs({
				var_0_36
			}, iter_13_3, var_0_37)[1]
			local var_13_3 = var_13_1 - 12.375
			local var_13_4 = var_13_3 * var_13_3 - 29.3906

			var_13_2.manualDharm = arg_13_0.selfHarm * var_13_4 * 0.01

			iter_13_3:addBuffs({
				var_13_2
			})
		end

		arg_13_0.selfHarm = 0
	end
end

return var_0_3
