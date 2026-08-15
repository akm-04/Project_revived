local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Panzhang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.battleConfig
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.model
local var_0_10 = 10001214
local var_0_11 = 10001216
local var_0_12 = 10001217
local var_0_13 = 40011309
local var_0_14 = 0.5
local var_0_15 = 10001225
local var_0_16 = 250
local var_0_17 = 10001226
local var_0_18 = 10001227
local var_0_19 = 0.8
local var_0_20 = 80010199
local var_0_21 = 40011732
local var_0_22 = 40011733
local var_0_23 = 40011734
local var_0_24 = 40011735

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyCenterTarget = nil
	arg_1_0.blueTarget = nil
	arg_1_0.isAddBlueBuff = false
	arg_1_0.backPosX = nil
	arg_1_0.backPosY = nil
	arg_1_0.isJumping = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and not arg_2_0.isAddBlueBuff then
		arg_2_0.isAddBlueBuff = true

		local var_2_0 = var_0_5.B3(arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		if var_2_0 and next(var_2_0) then
			arg_2_0.blueTarget = var_2_0[1]
		end

		if arg_2_0.blueTarget and arg_2_0.blueTarget:isBoss() then
			arg_2_0.blueTarget = nil
		end

		if arg_2_0.blueTarget then
			local var_2_1 = var_0_4.new({
				tableID = var_0_13,
				start = var_0_1.ctx.battle.count,
				level = arg_2_0:getSkillLevelByID(arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)),
				skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
				fighter = arg_2_0,
				target = arg_2_0.blueTarget
			})

			arg_2_0.blueTarget:addBuffs({
				var_2_1
			})
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if var_3_2 > 0 and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_3_0.blueTarget and arg_3_1.target == arg_3_0.blueTarget then
		var_3_2 = var_3_2 * (1 + var_0_14)
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_4 > 0 and arg_4_1.fighter:getTeamType() == arg_4_0:getTeamType() and arg_4_1.fighter.hero_:getHeroType() == var_0_2.AttributeType.AGILE and arg_4_1.target:getTeamType() ~= arg_4_0:getTeamType() and math.abs(arg_4_1.fighter:getX() - arg_4_1.target:getX()) <= var_0_16 and arg_4_1.skillID ~= var_0_18 and arg_4_1.fighter:getSummonType() == var_0_2.summonMonsterType.None and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0:createAttackUnits({
			arg_4_1.target
		}, var_0_17)

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end

		if arg_4_1.target:getHp() / arg_4_1.target:getHpLimit() < var_0_19 then
			local var_4_1 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_18)

			for iter_4_2, iter_4_3 in ipairs(var_4_1) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end
		end
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.deathFeedback(arg_5_0, arg_5_1)
	var_0_3.super.deathFeedback(arg_5_0, arg_5_1)

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_5_0.blueTarget and arg_5_1 == arg_5_0.blueTarget and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_0
		}, var_0_15)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if arg_6_1.rootID_ == var_0_10 then
		arg_6_0:setImmuneControl(true)
	end

	if var_0_7:father(arg_6_1.rootID_) == arg_6_0:getPugongID() and arg_6_0.skinSkillID_ == var_0_20 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_0:createAttackUnits({
			arg_6_0
		}, var_0_20)

		for iter_6_0, iter_6_1 in ipairs(var_6_0) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

function var_0_3.isBreakImmortal(arg_7_0)
	if arg_7_0.isJumping then
		return true
	end

	return var_0_3.super.isBreakImmortal(arg_7_0)
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	if arg_8_1.skillID == var_0_10 then
		arg_8_0.backPosX = arg_8_0:getX()
		arg_8_0.backPosY = arg_8_0:getY()

		arg_8_0:x(arg_8_1.target:getX())
		arg_8_0:y(arg_8_1.target:getY())

		arg_8_0.isJumping = true
	elseif arg_8_1.skillID == var_0_12 and arg_8_0.backPosX then
		arg_8_0:x(arg_8_0.backPosX)
		arg_8_0:y(arg_8_0.backPosY)

		arg_8_0.isJumping = false
	end

	if arg_8_1.skillID == var_0_20 then
		if #arg_8_0:getBuffsByID(var_0_21) >= 10 and not arg_8_0:isHasBuffByID(var_0_23) then
			arg_8_0:addBuffs({
				var_0_4.new({
					tableID = var_0_23,
					start = var_0_1.ctx.battle.count,
					level = arg_8_0:getLevel(),
					skillID = var_0_20,
					fighter = arg_8_0,
					target = arg_8_0
				})
			})
		end

		if #arg_8_0:getBuffsByID(var_0_22) >= 10 and not arg_8_0:isHasBuffByID(var_0_24) then
			arg_8_0:addBuffs({
				var_0_4.new({
					tableID = var_0_24,
					start = var_0_1.ctx.battle.count,
					level = arg_8_0:getLevel(),
					skillID = var_0_20,
					fighter = arg_8_0,
					target = arg_8_0
				})
			})
		end
	end
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	if arg_9_1:getTableID() == var_0_23 then
		arg_9_0:removeBuffByID(var_0_21)
	end

	if arg_9_1:getTableID() == var_0_24 then
		arg_9_0:removeBuffByID(var_0_22)
	end
end

function var_0_3.selectTargetByTypeD1(arg_10_0)
	local function var_10_0(arg_11_0, arg_11_1)
		local var_11_0 = {}

		table.insert(var_11_0, arg_11_0)

		for iter_11_0, iter_11_1 in ipairs(arg_10_0.sideTeam_) do
			if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1 ~= arg_11_0 and arg_11_1 >= math.abs(iter_11_1:getX() - arg_11_0:getX()) then
				table.insert(var_11_0, iter_11_1)
			end
		end

		return var_11_0
	end

	local var_10_1
	local var_10_2 = 0
	local var_10_3 = var_0_7:scope(var_0_11) * 0.5

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() then
			local var_10_4 = var_10_0(iter_10_1, var_10_3)

			if not var_10_1 or var_10_2 < #var_10_4 then
				var_10_1 = iter_10_1
				var_10_2 = #var_10_4
			end
		end
	end

	arg_10_0.energyCenterTarget = var_10_1

	return {
		var_10_1
	}
end

function var_0_3.selectTargetByTypeD2(arg_12_0)
	local function var_12_0(arg_13_0, arg_13_1)
		local var_13_0 = {}

		table.insert(var_13_0, arg_13_0)

		for iter_13_0, iter_13_1 in ipairs(arg_12_0.sideTeam_) do
			if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1 ~= arg_13_0 and arg_13_1 >= math.abs(iter_13_1:getX() - arg_13_0:getX()) then
				table.insert(var_13_0, iter_13_1)
			end
		end

		return var_13_0
	end

	local var_12_1 = {}
	local var_12_2 = var_0_7:scope(var_0_11) * 0.5

	if arg_12_0.energyCenterTarget then
		var_12_1 = var_12_0(arg_12_0.energyCenterTarget, var_12_2)
	end

	return var_12_1
end

return var_0_3
