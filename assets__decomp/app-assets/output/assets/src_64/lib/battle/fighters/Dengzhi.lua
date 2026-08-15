local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dengzhi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_9 = 40011486
local var_0_10 = 10001449
local var_0_11 = 10001450
local var_0_12 = 40011488
local var_0_13 = 0.2
local var_0_14 = 40011490
local var_0_15 = 300
local var_0_16 = 0.3
local var_0_17 = 500
local var_0_18 = 100
local var_0_19 = 40011489
local var_0_20 = 80010212
local var_0_21 = 0.2

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.GreenSkillID = 10002261
		arg_1_0.EnergySkillID = 10002262
	else
		arg_1_0.GreenSkillID = 20010212
		arg_1_0.EnergySkillID = 50010212
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.accHarms = {}
	arg_2_0.accHarmRaw = 0
	arg_2_0.accHarmUsed = false

	arg_2_0:listenInfo("harm_info")
end

function var_0_3.buffRemoveAction(arg_3_0, arg_3_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_1.tableID_ == var_0_9 then
		local var_3_0 = arg_3_0:createAttackUnits({
			arg_3_0
		}, var_0_11)

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end

		local var_3_1 = arg_3_0:createAttackUnits({
			arg_3_1.target
		}, var_0_10)

		for iter_3_2, iter_3_3 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_0.EnergySkillID

	if arg_4_1.rootID_ == var_4_0 then
		local var_4_1 = arg_4_0:getTargets(var_4_0)
		local var_4_2 = 0
		local var_4_3 = 0

		for iter_4_0, iter_4_1 in ipairs(var_4_1) do
			var_4_2 = var_4_2 + iter_4_1:getX()
			var_4_3 = var_4_3 + iter_4_1:getY()
		end

		local var_4_4 = var_4_2 / #var_4_1
		local var_4_5 = var_4_3 / #var_4_1

		arg_4_0.energyEffect = var_0_1.ctx.battle.getSpine(var_4_0, "area", 1)

		arg_4_0.energyEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
		arg_4_0.energyEffect:pos(var_4_4, var_4_5)
		arg_4_0.energyEffect:setScale(1)
		arg_4_0.energyEffect:playOnce()
	end
end

function var_0_3.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_0:isHasBuffByID(var_0_12) and arg_5_1.attackType == var_0_2.AttackType.AD then
		arg_5_2 = true
		arg_5_4 = 0
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	local var_6_0 = var_0_3.super.getDHuJia

	if arg_6_1.skillID == arg_6_0.GreenSkillID then
		arg_6_1.mustBaoji = true

		function arg_6_0.getDHuJia(arg_7_0)
			return var_0_3.super.getDHuJia(arg_7_0) + arg_6_1.target:getHuJia() * var_0_13
		end
	end

	if arg_6_0.accHarmRaw > 0 and arg_6_1.target:getTeamType() ~= arg_6_0:getTeamType() then
		local var_6_1 = var_0_17 + var_0_18 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_6_2 = math.min(arg_6_0.accHarmRaw * var_0_16, var_6_1)

		arg_6_1:setExtraHarm(var_6_2)

		arg_6_0.accHarmUsed = true
	end

	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	arg_6_0.getDHuJia = var_6_0
end

function var_0_3.selectTargetByTypeD3(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.selfTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1:getSummonType() == var_0_2.summonMonsterType.None and iter_8_1.hero_:getHeroType() == var_0_2.HeroType.AGILE then
			table.insert(var_8_0, iter_8_1)
		end
	end

	return var_8_0
end

function var_0_3.deathFeedback(arg_9_0, arg_9_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_9_1.killer_ == arg_9_0 and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_9_0 = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
		local var_9_1 = arg_9_0:selectTargetByTypeD3(var_9_0, nil)
		local var_9_2 = arg_9_0:createAttackUnits(var_9_1, var_9_0)

		for iter_9_0, iter_9_1 in ipairs(var_9_2) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end
end

function var_0_3.toDoPerFrames(arg_10_0)
	local var_10_0 = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if not arg_10_0:isDeath() and var_10_0 > 0 then
		local var_10_1 = math.fmod(var_0_1.ctx.battle.count, var_0_15)
		local var_10_2 = math.fmod(var_10_1 + 299, var_0_15)
		local var_10_3 = math.fmod(var_10_1 + 1, var_0_15)

		arg_10_0.accHarms[var_10_2] = arg_10_0.accHarms[var_10_2] or 0
		arg_10_0.accHarms[var_10_1] = arg_10_0.accHarms[var_10_2]

		for iter_10_0, iter_10_1 in ipairs(arg_10_0:getInfoByKey("harm_info")) do
			if iter_10_1.type == var_0_2.AttackType.AD and iter_10_1.isBaoji then
				arg_10_0.accHarms[var_10_1] = arg_10_0.accHarms[var_10_1] + iter_10_1.harm
			end
		end

		arg_10_0.accHarms[var_10_3] = arg_10_0.accHarms[var_10_3] or 0

		if var_10_1 == 0 then
			arg_10_0.accHarmRaw = arg_10_0.accHarms[var_10_1] - arg_10_0.accHarms[var_10_3]
		end

		if arg_10_0.accHarmRaw > 0 then
			if not arg_10_0:isHasBuffByID(var_0_19) then
				arg_10_0:addBuffs({
					var_0_5.new({
						tableID = var_0_19,
						start = var_0_1.ctx.battle.count,
						level = var_10_0,
						skillID = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
						fighter = arg_10_0,
						target = arg_10_0
					})
				})
			end

			if arg_10_0.accHarmUsed then
				arg_10_0.accHarmUsed = false
				arg_10_0.accHarmRaw = 0
			end
		else
			arg_10_0:removeBuffByID(var_0_19)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7 = var_0_3.super.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	if arg_11_3 and arg_11_4 > 0 and arg_11_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_11_1.skillID ~= var_0_20 then
		local var_11_0 = var_0_20
		local var_11_1 = var_0_6:selectType(var_11_0)
		local var_11_2 = var_0_8[var_11_1](arg_11_0, var_11_0)
		local var_11_3 = arg_11_0:createAttackUnits(var_11_2, var_11_0)

		for iter_11_0, iter_11_1 in ipairs(var_11_3) do
			table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
			table.insert(arg_11_0.records_.special_units, iter_11_1)
		end
	end

	return arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7
end

function var_0_3.buffAddAction(arg_12_0, arg_12_1)
	var_0_3.super.buffAddAction(arg_12_0, arg_12_1)

	if arg_12_0.skinSkillIndex_ == 1 and arg_12_1:getBuffForm() == var_0_2.BuffForm.GAIN then
		local var_12_0 = arg_12_1:getTime() * var_0_21

		arg_12_1:setExtraTime(var_12_0)
	end
end

return var_0_3
