local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Bulianshi", var_0_1.ctx.battle.requireFighter("Bulianshi"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 600
local var_0_8 = 40011410
local var_0_9 = 10001324
local var_0_10 = 10001323
local var_0_11 = 150
local var_0_12 = 0.005
local var_0_13 = 0.1

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")

	arg_1_0.removeBuffCount = {}
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 2 then
		arg_2_0.EnergyFirstSkill = 10002074
		arg_2_0.EnergySecondSkill = 10002075
		arg_2_0.EnergyLastSkill = 10002076
	else
		arg_2_0.EnergyFirstSkill = 10000407
		arg_2_0.EnergySecondSkill = 10000408
		arg_2_0.EnergyLastSkill = 10000409
	end
end

function var_0_3.addBuffBySpecialHero(arg_3_0, arg_3_1)
	var_0_3.super.addBuffBySpecialHero(arg_3_0, arg_3_1)

	for iter_3_0 = #arg_3_1, 1, -1 do
		local var_3_0 = arg_3_1[iter_3_0]

		if var_3_0.target:isHasBuffByID(var_0_8) and var_3_0:getYx() > 0 and var_3_0:canRemove() then
			table.remove(arg_3_1, iter_3_0)
		end
	end
end

function var_0_3.die(arg_4_0)
	var_0_3.super.die(arg_4_0)

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if iter_4_1:isHasBuffByID(var_0_8) then
			iter_4_1:removeBuffByID(var_0_8)
		end
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	var_0_3.super.toDoPerFrames(arg_5_0)

	if arg_5_0:isDeath() then
		return
	end

	for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("attack_info")) do
		local var_5_0 = iter_5_1.fighter_

		if var_0_5:father(iter_5_1.rootID_) == var_5_0:getEnergySkillID() and var_5_0:isHasBuffByID(var_0_8) and not arg_5_0.removeBuffCount[var_5_0] then
			arg_5_0.removeBuffCount[var_5_0] = var_0_11
		end
	end

	for iter_5_2, iter_5_3 in pairs(arg_5_0.removeBuffCount) do
		arg_5_0.removeBuffCount[iter_5_2] = arg_5_0.removeBuffCount[iter_5_2] - 1

		if arg_5_0.removeBuffCount[iter_5_2] < 1 then
			if iter_5_2:isHasBuffByID(var_0_8) then
				iter_5_2:removeBuffByID(var_0_8)
			end

			arg_5_0.removeBuffCount[iter_5_2] = nil
		end
	end

	if var_0_1.ctx.battle.count % var_0_7 == 1 then
		for iter_5_4, iter_5_5 in ipairs(arg_5_0.selfTeam_) do
			if not iter_5_5:isDeath() and not iter_5_5:isAffected() and not iter_5_5:isHasBuffByID(var_0_8) and iter_5_5:getSummonType() == var_0_2.summonMonsterType.None then
				local var_5_1 = var_0_4.new({
					tableID = var_0_8,
					start = var_0_1.ctx.battle.count,
					level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
					skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
					fighter = arg_5_0,
					target = iter_5_5
				})

				iter_5_5:addBuffs({
					var_5_1
				})
			end
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_6_0)
	local var_6_0 = var_0_3.super.getOrbOfFrontSkill(arg_6_0)

	if var_6_0 == arg_6_0:getPugongID() and arg_6_0:isHasBuffByID(var_0_8) then
		var_6_0 = var_0_9
	end

	return var_6_0
end

function var_0_3.selectTargetByTypeD3(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1 ~= arg_7_1 and math.abs(iter_7_1:getX() - arg_7_1:getX()) < var_0_5:scope(arg_7_2) then
			table.insert(var_7_0, iter_7_1)
		end
	end

	return var_7_0
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if var_8_2 > 0 and (arg_8_1.skillID == arg_8_0.EnergyFirstSkill or arg_8_1.skillID == arg_8_0.EnergySecondSkill or arg_8_1.skillID == arg_8_0.EnergyLastSkill) and arg_8_0:isHasBuffByID(var_0_8) then
		local var_8_6 = arg_8_0:selectTargetByTypeD3(arg_8_1.target, var_0_10)
		local var_8_7 = arg_8_0:createAttackUnits(var_8_6, var_0_10)

		for iter_8_0, iter_8_1 in ipairs(var_8_7) do
			iter_8_1.addHarm = var_8_2 * (var_0_13 + var_0_12 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end
	elseif arg_8_1.skillID == var_0_10 and arg_8_1.addHarm then
		var_8_2 = var_8_2 + arg_8_1.addHarm
	end

	return var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5)
end

return var_0_3
