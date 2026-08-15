local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Qinggang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = {
	40011972,
	40011973
}
local var_0_8 = 0.3
local var_0_9 = 0.5
local var_0_10 = 10001833
local var_0_11 = 0.3
local var_0_12 = 600
local var_0_13 = 40010244
local var_0_14 = 0.15
local var_0_15 = 300
local var_0_16 = 90
local var_0_17 = 0.15

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.PurpleBuffSkill = 10002465
		arg_1_0.CommonBuff = 40012660
		arg_1_0.PurpleSelfBuff = 40012661
		arg_1_0.BlueBuffSkill = 10002464
		arg_1_0.PugongSkill = 10002468
		arg_1_0.GreenSkill = 10002469
		arg_1_0.BlueSkill = 10002470
		arg_1_0.EnergySkill = 10002471
	else
		arg_1_0.PurpleBuffSkill = 10001824
		arg_1_0.CommonBuff = 40011974
		arg_1_0.PurpleSelfBuff = 40011976
		arg_1_0.BlueBuffSkill = 10001823
		arg_1_0.PugongSkill = 10020244
		arg_1_0.GreenSkill = 20020244
		arg_1_0.BlueSkill = 30010244
		arg_1_0.EnergySkill = 50010244
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.purpleXixueCount = 0
	arg_2_0.PurpleBuffSkillCount = 0
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_1.skillID

	if var_3_0 == arg_3_0.GreenSkill then
		local var_3_1 = arg_3_0:createNewBuffs(var_0_7, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		arg_3_0:addBuffs(var_3_1)
	elseif var_3_0 == arg_3_0.BlueSkill then
		arg_3_0:blueSkill(arg_3_1)
	elseif var_0_4:father(var_3_0) == arg_3_0:getEnergySkillID() and arg_3_1.target:isHasBuffByID(arg_3_0.CommonBuff) then
		arg_3_0:energySkill(arg_3_1)
	end

	if arg_3_0.skinSkillIndex_ == 1 and arg_3_1.target:isHasBuffByID(arg_3_0.CommonBuff) and (var_3_0 == arg_3_0.PugongSkill or var_3_0 == arg_3_0.GreenSkill or var_3_0 == arg_3_0.BlueSkill or var_3_0 == arg_3_0.EnergySkill) then
		local var_3_2 = arg_3_1.target:getBuffByID(arg_3_0.CommonBuff)

		var_3_2:setLeftCount(var_3_2:getLeftCount() + var_0_16)
	end
end

function var_0_3.blueSkill(arg_4_0, arg_4_1)
	local var_4_0 = var_0_8

	if var_0_2.weightedChoise({
		var_4_0,
		1 - var_4_0
	}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_1 = arg_4_0:createAttackUnits({
			arg_4_1.target
		}, arg_4_0.BlueBuffSkill)

		for iter_4_0, iter_4_1 in ipairs(var_4_1) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end
end

function var_0_3.energySkill(arg_5_0, arg_5_1)
	local var_5_0 = var_0_15

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and math.abs(iter_5_1:getX() - arg_5_1.target:getX()) <= var_5_0 / 2 and not iter_5_1:isHasBuffByID(arg_5_0.CommonBuff) then
			local var_5_1 = arg_5_0:createNewBuffs({
				arg_5_0.CommonBuff
			}, iter_5_1, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

			iter_5_1:addBuffs(var_5_1)
		end
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_6_0.purpleXixueCount > 0 then
			arg_6_0.purpleXixueCount = arg_6_0.purpleXixueCount - 1
		elseif arg_6_0:getHp() / arg_6_0:getHpLimit() <= var_0_11 then
			local var_6_0 = arg_6_0:createNewBuffs({
				arg_6_0.PurpleSelfBuff
			}, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			arg_6_0:addBuffs(var_6_0)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_1 = {}

				for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
					if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:isHasBuffByID(arg_6_0.CommonBuff) then
						table.insert(var_6_1, iter_6_1)
					end
				end

				if next(var_6_1) then
					local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_0_13)

					for iter_6_2, iter_6_3 in ipairs(var_6_2) do
						table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
						table.insert(arg_6_0.records_.special_units, iter_6_3)
					end
				end
			end

			arg_6_0.purpleXixueCount = var_0_12
		end

		if arg_6_0.PurpleBuffSkillCount > 0 then
			arg_6_0.PurpleBuffSkillCount = arg_6_0.PurpleBuffSkillCount - 1
		else
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_3 = arg_6_0.PurpleBuffSkill
				local var_6_4 = var_0_4:selectType(var_6_3)
				local var_6_5 = var_0_6[var_6_4](arg_6_0, var_6_3)
				local var_6_6 = arg_6_0:createAttackUnits(var_6_5, var_6_3)

				for iter_6_4, iter_6_5 in ipairs(var_6_6) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_5)
					table.insert(arg_6_0.records_.special_units, iter_6_5)
				end
			end

			arg_6_0.PurpleBuffSkillCount = var_0_12
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_1.skillID == var_0_10 then
		arg_7_4 = arg_7_1.ignoreHarm
	elseif arg_7_4 > 0 and arg_7_1.skillID == arg_7_0.EnergySkill and arg_7_1.target:isHasBuffByID(arg_7_0.CommonBuff) then
		arg_7_4 = 2 * arg_7_4
	elseif arg_7_1.skillID == var_0_13 then
		local var_7_0 = arg_7_0:getHpLimit() * var_0_14

		arg_7_4 = var_7_0

		arg_7_0.fighterModel:playHPDeltas({
			{
				var_7_0,
				false
			}
		}, nil)
		arg_7_0:updateHp(arg_7_0:getHp() + var_7_0)
	end

	if arg_7_0.skinSkillIndex_ == 1 and arg_7_1.target:isHasBuffByID(arg_7_0.CommonBuff) and (arg_7_1.skillID == arg_7_0.PugongSkill or arg_7_1.skillID == arg_7_0.GreenSkill or arg_7_1.skillID == arg_7_0.BlueSkill or arg_7_1.skillID == arg_7_0.EnergySkill) then
		arg_7_4 = arg_7_4 * (1 + var_0_17)
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_1.target == arg_8_0 and arg_8_4 > 0 and arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_8_1.fighter:isHasBuffByID(arg_8_0.CommonBuff) then
		local var_8_0 = arg_8_4 * var_0_9

		arg_8_4 = arg_8_4 - var_8_0

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_8_1 = arg_8_0:createAttackUnits({
				arg_8_1.fighter
			}, var_0_10)

			for iter_8_0, iter_8_1 in ipairs(var_8_1) do
				iter_8_1.ignoreHarm = var_8_0

				table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
				table.insert(arg_8_0.records_.special_units, iter_8_1)
			end
		end
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

return var_0_3
