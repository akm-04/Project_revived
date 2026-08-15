local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Duwei", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.hero
local var_0_10 = 40011978
local var_0_11 = 10001827
local var_0_12 = 1.5
local var_0_13 = 0.035
local var_0_14 = 0.005
local var_0_15 = {
	10001830,
	10001831,
	10001832
}
local var_0_16 = 40011979
local var_0_17 = 30
local var_0_18 = 10001829
local var_0_19 = 10001828
local var_0_20 = 240

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyMode = false
	arg_1_0.energyDanceCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.energyDanceCount > 0 then
		arg_2_0.energyDanceCount = arg_2_0.energyDanceCount - 1

		if arg_2_0.energyDanceCount == 0 and arg_2_0.energyEffect then
			arg_2_0.energyEffect:removeSelf()

			arg_2_0.energyEffect = nil
		end
	end

	if arg_2_0.energyMode and var_0_1.ctx.battle.count % var_0_17 == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = var_0_15[math.random(1, #var_0_15)]
		local var_2_1 = arg_2_0:createAttackUnits(var_0_6.A3(arg_2_0, var_2_0), var_2_0)

		for iter_2_0, iter_2_1 in ipairs(var_2_1) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == var_0_11 then
		if arg_3_1.target:isHasBuffByID(var_0_10) then
			arg_3_1.target:removeBuffByID(var_0_10)
		end
	elseif arg_3_1.skillID == var_0_19 then
		local var_3_0 = {}

		for iter_3_0, iter_3_1 in pairs(arg_3_1.target:getBuffs()) do
			if (iter_3_1:getBuffForm() == var_0_2.BuffForm.GAIN or iter_3_1:getBuffForm() == var_0_2.BuffForm.DEBUFF) and iter_3_1:canRemove() then
				table.insert(var_3_0, iter_3_1:getTableID())
			end
		end

		for iter_3_2, iter_3_3 in ipairs(var_3_0) do
			arg_3_1.target:removeBuffByID(iter_3_3)
		end
	elseif arg_3_1.skillID == var_0_18 and var_0_1.ctx.battle.unitBottomLayer.getContentSize then
		local var_3_1 = var_0_1.ctx.battle.unitBottomLayer:getContentSize()

		if type(var_3_1) == "table" and var_3_1.width and var_3_1.height then
			arg_3_0.energyEffect = var_0_1.ctx.battle.getSpine(var_0_18, "area", 1)

			arg_3_0.energyEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
			arg_3_0.energyEffect:pos(var_3_1.width / 2, var_3_1.height / 2)
			arg_3_0.energyEffect:setScale(1 / var_0_1.ctx.battle.unitBottomLayer:getScale())
			arg_3_0.energyEffect:playRepeat()

			arg_3_0.energyDanceCount = arg_3_0.energyDanceCount + var_0_20
		end
	end
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_16 then
		arg_4_0.energyMode = true
	end
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	if arg_5_1:getTableID() == var_0_16 then
		arg_5_0.energyMode = false

		if arg_5_0.energyEffect then
			arg_5_0.energyDanceCount = 0

			arg_5_0.energyEffect:removeSelf()

			arg_5_0.energyEffect = nil
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_6_1.fighter:getTeamType() == arg_6_0:getTeamType() and arg_6_1.skillID == arg_6_1.fighter:getPugongID() and var_6_2 > 0 then
		var_6_2 = var_6_2 + arg_6_0:getAP() * var_0_14 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end

	if arg_6_1.fighter:isHasBuffByID(var_0_10) and arg_6_1.fighter:getTeamType() == arg_6_0:getTeamType() and arg_6_1.skillID == arg_6_1.fighter:getPugongID() and var_6_2 > 0 then
		var_6_2 = (var_0_12 + var_0_13 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)) * var_6_2

		local var_6_6 = arg_6_0:createAttackUnits({
			arg_6_1.fighter
		}, var_0_11)

		for iter_6_0, iter_6_1 in ipairs(var_6_6) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {}

	table.insert(var_7_0, arg_7_0)

	local var_7_1

	for iter_7_0, iter_7_1 in pairs(arg_7_0.selfTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and (not var_7_1 or iter_7_1:getAD() > var_7_1:getAD()) then
			var_7_1 = iter_7_1
		end
	end

	if var_7_1 then
		table.insert(var_7_0, var_7_1)
	end

	return var_7_0
end

function var_0_3.selectTargetByTypeD2(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in pairs(arg_8_0.selfTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() then
			table.insert(var_8_0, iter_8_1)
		end
	end

	for iter_8_2, iter_8_3 in pairs(arg_8_0.sideTeam_) do
		if not iter_8_3:isDeath() and not iter_8_3:isAffected() then
			table.insert(var_8_0, iter_8_3)
		end
	end

	return var_8_0
end

return var_0_3
