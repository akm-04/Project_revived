local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZuociSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = 40012662
local var_0_11 = 40012663
local var_0_12 = 10002472
local var_0_13 = 0.1
local var_0_14 = 0.005
local var_0_15 = 40012665
local var_0_16 = 40012664
local var_0_17 = 0.2
local var_0_18 = 0.003
local var_0_19 = 10002482
local var_0_20 = 40012666
local var_0_21 = 40012667
local var_0_22 = 0.3
local var_0_23 = 10002473
local var_0_24 = 10002474
local var_0_25 = 10002475
local var_0_26 = 40012669
local var_0_27 = 250
local var_0_28 = 600
local var_0_29 = 3

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenTarget = nil
	arg_1_0.greenConnectTarget = {}
	arg_1_0.energyMarkTarget = nil
	arg_1_0.energyChildSkillNum = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0.energyMarkTarget and not arg_2_0.energyMarkTarget:isDeath() and not arg_2_0.energyMarkTarget:isAffected() then
		local var_2_0 = var_0_27

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() and iter_2_1 ~= arg_2_0.energyMarkTarget and var_2_0 > math.abs(arg_2_0.energyMarkTarget:getX() - iter_2_1:getX()) then
				local var_2_1 = var_0_29

				if iter_2_1:getX() < arg_2_0.energyMarkTarget:getX() then
					iter_2_1:moveByX(var_2_1)
				else
					iter_2_1:moveByX(-var_2_1)
				end
			end
		end
	end

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count % var_0_28 == 1 then
		local var_2_2 = false

		if arg_2_0:isHasBuffByID(var_0_15) then
			var_2_2 = true

			arg_2_0:removeBuffByID(var_0_15)
		end

		local var_2_3 = arg_2_0:getAD()
		local var_2_4 = arg_2_0:getAP()

		if var_2_4 < var_2_3 then
			local var_2_5 = arg_2_0:createNewBuffs({
				var_0_21
			}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
			local var_2_6 = math.min(var_2_4 * 0.3, var_2_3 - var_2_4)

			for iter_2_2, iter_2_3 in ipairs(var_2_5) do
				iter_2_3.manualRevise = var_2_6
			end

			arg_2_0:addBuffs(var_2_5)
		elseif var_2_3 < var_2_4 then
			local var_2_7 = arg_2_0:createNewBuffs({
				var_0_20
			}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
			local var_2_8 = math.min(var_2_3 * 0.3, var_2_4 - var_2_3)

			for iter_2_4, iter_2_5 in ipairs(var_2_7) do
				iter_2_5.manualRevise = var_2_8
			end

			arg_2_0:addBuffs(var_2_7)
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_9 = arg_2_0:createAttackUnits({
				arg_2_0
			}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_2_6, iter_2_7 in ipairs(var_2_9) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_7)
				table.insert(arg_2_0.records_.special_units, iter_2_7)
			end
		end

		if var_2_2 == true then
			local var_2_10 = arg_2_0:createNewBuffs({
				var_0_15
			}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_2_0:addBuffs(var_2_10)
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_0:selectTargetByTypeD2(var_0_19)
		local var_3_1 = arg_3_0:createAttackUnits(var_3_0, var_0_19)

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end

	if arg_3_1.skillID == var_0_19 then
		if arg_3_0:isHasBuffByID(var_0_15) then
			arg_3_0:removeBuffByID(var_0_15)
		end

		if arg_3_0:isHasBuffByID(var_0_16) then
			arg_3_0:removeBuffByID(var_0_16)
		end
	elseif arg_3_1.skillID == var_0_23 then
		arg_3_0.energyChildSkillNum = #arg_3_0.greenConnectTarget

		if arg_3_0.energyChildSkillNum > 0 then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_2 = arg_3_0:createAttackUnits({
					arg_3_1.target
				}, var_0_24)

				for iter_3_2, iter_3_3 in ipairs(var_3_2) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			end

			arg_3_0.energyChildSkillNum = arg_3_0.energyChildSkillNum - 1
		end
	elseif arg_3_1.skillID == var_0_24 and arg_3_0.energyChildSkillNum > 0 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_3 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_24)

			for iter_3_4, iter_3_5 in ipairs(var_3_3) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
				table.insert(arg_3_0.records_.special_units, iter_3_5)
			end
		end

		arg_3_0.energyChildSkillNum = arg_3_0.energyChildSkillNum - 1
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.skillID == var_0_12 and arg_4_1.extraHarm then
		var_4_2 = arg_4_1.extraHarm
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_1.target

	if arg_5_1:getTableID() == var_0_10 then
		if arg_5_0.greenTarget and arg_5_0.greenTarget:getBuffByID(var_0_10) then
			arg_5_0.greenTarget:removeBuffByID(var_0_10)
		end

		if #arg_5_0.greenConnectTarget > 0 then
			for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
				if iter_5_1:getBuffByID(var_0_11) then
					iter_5_1:removeBuffByID(var_0_11)

					arg_5_0.greenConnectTarget = {}
				end
			end
		end

		arg_5_0.greenTarget = var_5_0

		for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
			if iter_5_3.hero_:getHeroType() == var_5_0.hero_:getHeroType() and not iter_5_3:isDeath() and not iter_5_3:isAffected() and iter_5_3:getSummonType() == var_0_2.summonMonsterType.None and iter_5_3 ~= arg_5_0.greenTarget then
				local var_5_1 = arg_5_0:createNewBuffs({
					var_0_11
				}, iter_5_3, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

				iter_5_3:addBuffs(var_5_1)
				table.insert(arg_5_0.greenConnectTarget, iter_5_3)
			end
		end
	elseif arg_5_1:getTableID() == var_0_15 then
		local var_5_2 = 0

		for iter_5_4, iter_5_5 in ipairs(arg_5_0.selfTeam_) do
			if iter_5_5.hero_:getHeroType() == var_0_2.HeroType.WISE and iter_5_5 ~= arg_5_0 and iter_5_5:getSummonType() == var_0_2.summonMonsterType.None then
				var_5_2 = var_5_2 + iter_5_5:getAP()
			end
		end

		arg_5_1.manualRevise = var_5_2 * (var_0_17 + var_0_18 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
	elseif arg_5_1:getTableID() == var_0_26 then
		arg_5_0.energyMarkTarget = arg_5_1.target
	end
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == var_0_26 then
		arg_6_0.energyMarkTarget = nil
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	if arg_7_4 > 0 and arg_7_1.target:isHasBuffByID(var_0_10) and arg_7_1.attackType == var_0_2.AttackType.AP and arg_7_1.target:getTeamType() ~= arg_7_0:getTeamType() then
		for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1:isHasBuffByID(var_0_11) then
				local var_7_0 = arg_7_0:createAttackUnits({
					iter_7_1
				}, var_0_12)

				for iter_7_2, iter_7_3 in ipairs(var_7_0) do
					iter_7_3.extraHarm = arg_7_4 * (var_0_13 + var_0_14 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))

					table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
					table.insert(arg_7_0.records_.special_units, iter_7_3)
				end
			end
		end
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.selectTargetByTypeD1(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}
	local var_8_1 = math.random(tonumber(os.time()))

	math.randomseed(tonumber(tostring(os.time() + var_8_1):reverse():sub(1, 6)))

	local var_8_2 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_8_2, iter_8_1)
		end
	end

	if not var_8_2 or next(var_8_2) == nil then
		return {}
	end

	math.randomseed(var_8_1)

	return {
		var_8_2[math.random(#var_8_2)]
	}
end

function var_0_3.selectTargetByTypeD2(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and iter_9_1:isHasBuffByID(var_0_10) then
			table.insert(var_9_0, iter_9_1)
		end
	end

	if #var_9_0 >= 1 then
		return var_9_0
	end

	local var_9_1 = math.random(tonumber(os.time()))

	math.randomseed(tonumber(tostring(os.time() + var_9_1):reverse():sub(1, 6)))

	local var_9_2 = {}

	for iter_9_2, iter_9_3 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_3:isDeath() and not iter_9_3:isAffected() and iter_9_3:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_9_2, iter_9_3)
		end
	end

	if not var_9_2 or next(var_9_2) == nil then
		return {}
	end

	math.randomseed(var_9_1)

	return {
		var_9_2[math.random(#var_9_2)]
	}
end

return var_0_3
