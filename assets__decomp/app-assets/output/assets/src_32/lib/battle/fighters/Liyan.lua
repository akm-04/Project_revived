local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liyan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = 40012037
local var_0_9 = 40012038
local var_0_10 = 0.3
local var_0_11 = 0.006
local var_0_12 = 4
local var_0_13 = 30010247
local var_0_14 = 0.4
local var_0_15 = 3
local var_0_16 = 750
local var_0_17 = 20
local var_0_18 = 10001890
local var_0_19 = 10001889
local var_0_20 = 3
local var_0_21 = 40012565
local var_0_22 = 8
local var_0_23 = 0.5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenBuffCount = 0
	arg_1_0.blueBuffCount = 0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.ControlBuff = 40012572
		arg_2_0.PurpleBuff = 40012573
		arg_2_0.GreenBuff = 40012574
		arg_2_0.PurpleControlSkill = 10002355
		arg_2_0.EnergyJumpSkill1 = 10002356
		arg_2_0.EnergyJumpSkill2 = 10002357
		arg_2_0.GreenSkill = 10002359
		arg_2_0.BlueSkill = 10002360
		arg_2_0.EnergySkill = 10002361
	else
		arg_2_0.ControlBuff = 40012035
		arg_2_0.PurpleBuff = 40012036
		arg_2_0.GreenBuff = 40012039
		arg_2_0.PurpleControlSkill = 10001891
		arg_2_0.EnergyJumpSkill1 = 10001892
		arg_2_0.EnergyJumpSkill2 = 10001893
		arg_2_0.GreenSkill = 20020247
		arg_2_0.BlueSkill = 30010247
		arg_2_0.EnergySkill = 50010247
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0.EnergyJumpSkill1 then
		arg_3_0:playAttack(3)
	elseif arg_3_1.skillID == arg_3_0.EnergyJumpSkill2 then
		arg_3_0:playAttack(4)

		local var_3_0 = arg_3_1.target:getX()
		local var_3_1 = arg_3_1.target:getY()
		local var_3_2

		if var_3_0 > arg_3_0:getX() then
			var_3_2 = 1

			arg_3_0:flipX(true)
		else
			var_3_2 = -1

			arg_3_0:flipX(false)
		end

		arg_3_0:x(var_3_0 + 100 * var_3_2)
		arg_3_0:y(var_3_1)
	elseif arg_3_1.skillID == var_0_18 and not arg_3_1.isExtra then
		arg_3_0:purpleExtraSkill(arg_3_1)
	elseif arg_3_1.skillID == arg_3_0.GreenSkill and arg_3_0.skinSkillIndex_ == 1 then
		local var_3_3 = arg_3_0:createNewBuffs({
			var_0_21
		}, arg_3_0, arg_3_0.GreenSkill)

		arg_3_0:addBuffs(var_3_3)
	end

	if arg_3_1.skillID == var_0_18 or arg_3_1.skillID == var_0_19 then
		local var_3_4 = arg_3_1.target

		if not var_3_4:isHasBuffByID(arg_3_0.ControlBuff) then
			local var_3_5 = arg_3_0:createNewBuffs({
				arg_3_0.PurpleBuff
			}, var_3_4, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			var_3_4:addBuffs(var_3_5)
		end
	end
end

function var_0_3.afterDamageHarm(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_0:isHasBuffByID(var_0_8) then
		local var_4_0 = arg_4_0:createNewBuffs({
			var_0_9
		}, arg_4_0, arg_4_0.EnergySkill)

		var_4_0[1].manualDharm = arg_4_1 * var_0_10 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_11

		arg_4_0:addBuffs(var_4_0)
	end
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_0:isHasBuffByID(arg_5_0.GreenBuff) and arg_5_0:isAttackSkill(arg_5_1.rootID_) then
		if arg_5_0.greenBuffCount > 0 then
			arg_5_0.greenBuffCount = arg_5_0.greenBuffCount - 1
		end

		if arg_5_0.greenBuffCount == 0 then
			arg_5_0:removeBuffByID(arg_5_0.GreenBuff)
		end
	end
end

function var_0_3.isAttackSkill(arg_6_0, arg_6_1)
	return arg_6_1 == arg_6_0:getPugongID() or arg_6_1 == var_0_18 or arg_6_1 == var_0_19
end

function var_0_3.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_7_0.blueBuffCount < var_0_15 and var_7_2 > 0 and arg_7_0:getTeamType() ~= arg_7_1.fighter:getTeamType() and arg_7_1.attackType == var_0_2.AttackType.AD then
		local var_7_6 = var_0_14

		if var_0_2.weightedChoise({
			var_7_6,
			1 - var_7_6
		}) == 1 then
			local var_7_7 = arg_7_1.fighter

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_7_8 = arg_7_0:createAttackUnits({
					var_7_7
				}, var_0_13)

				for iter_7_0, iter_7_1 in ipairs(var_7_8) do
					iter_7_1.isExtra = true

					table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
					table.insert(arg_7_0.records_.special_units, iter_7_1)
				end
			end

			if var_7_7:isHasBuffByID(arg_7_0.PurpleBuff) then
				var_7_7:removeBuffByID(arg_7_0.PurpleBuff)
			end
		end
	end

	if arg_7_0.skinSkillIndex_ == 1 and arg_7_0:getHp() <= arg_7_0:getHpLimit() * 0.5 then
		var_7_3 = var_7_3 + var_7_3 * var_0_23
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

function var_0_3.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_6 = arg_8_1.target

	if var_8_6:isHasBuffByID(arg_8_0.ControlBuff) and var_8_2 > 0 and arg_8_0:getTeamType() ~= var_8_6:getTeamType() then
		var_8_2 = var_8_2 + var_0_16 + var_0_17 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.getOrbOfFrontSkill(arg_9_0)
	local var_9_0 = var_0_3.super.getOrbOfFrontSkill(arg_9_0)

	if var_9_0 == arg_9_0:getPugongID() and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_9_1 = 0

		for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
			if not iter_9_1:isDeath() and not iter_9_1:isAffected() then
				var_9_1 = var_9_1 + 1
			end
		end

		if var_9_1 < 2 then
			var_9_0 = var_0_19
		else
			var_9_0 = var_0_18
		end
	end

	return var_9_0
end

function var_0_3.purpleExtraSkill(arg_10_0, arg_10_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_10_0
		local var_10_1

		for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
			if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1 ~= arg_10_1.target and (not var_10_0 or var_10_1 > iter_10_1:getHp() / iter_10_1:getHpLimit() or var_10_1 == iter_10_1:getHp() / iter_10_1:getHpLimit() and var_10_0:getHp() > iter_10_1:getHp()) then
				var_10_0 = iter_10_1
				var_10_1 = var_10_0:getHp() / var_10_0:getHpLimit()
			end
		end

		local var_10_2 = arg_10_0:createAttackUnits({
			var_10_0
		}, var_0_18)

		for iter_10_2, iter_10_3 in ipairs(var_10_2) do
			iter_10_3.isExtra = true

			table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
			table.insert(arg_10_0.records_.special_units, iter_10_3)
		end
	end
end

function var_0_3.buffAddAction(arg_11_0, arg_11_1)
	var_0_3.super.buffAddAction(arg_11_0, arg_11_1)

	if arg_11_1:getTableID() == arg_11_0.GreenBuff then
		arg_11_0.greenBuffCount = var_0_12
	elseif arg_11_1:getTableID() == arg_11_0.PurpleBuff then
		local var_11_0 = arg_11_1.target:getBuffsByID(arg_11_0.PurpleBuff)

		arg_11_1:setActNum(#var_11_0 + 1)
	elseif arg_11_1:getTableID() == arg_11_0.ControlBuff and arg_11_1:getSkillID() == arg_11_0.BlueSkill then
		arg_11_0.blueBuffCount = arg_11_0.blueBuffCount + 1
	elseif arg_11_1:getTableID() == var_0_21 then
		arg_11_1.manualRevise = var_0_22 * arg_11_0:getLevel()
	end
end

function var_0_3.buffRemoveAction(arg_12_0, arg_12_1)
	var_0_3.super.buffRemoveAction(arg_12_0, arg_12_1)

	if arg_12_1:getTableID() == arg_12_0.ControlBuff and arg_12_1:getSkillID() == arg_12_0.BlueSkill then
		arg_12_0.blueBuffCount = arg_12_0.blueBuffCount - 1
	end
end

function var_0_3.toDoPerFrames(arg_13_0)
	if arg_13_0:isDeath() then
		return
	end

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and #iter_13_1:getBuffsByID(arg_13_0.PurpleBuff) >= var_0_20 then
			iter_13_1:removeBuffByID(arg_13_0.PurpleBuff)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_13_0 = arg_13_0.PurpleControlSkill
				local var_13_1 = arg_13_0:createAttackUnits({
					iter_13_1
				}, var_13_0)

				for iter_13_2, iter_13_3 in ipairs(var_13_1) do
					table.insert(arg_13_0.moveAttackUnits_, iter_13_3)
					table.insert(arg_13_0.records_.special_units, iter_13_3)
				end
			end
		end
	end

	if arg_13_0.skinSkillIndex_ == 1 and var_0_1.ctx.battle.count % 5 == 1 and arg_13_0:isHasBuffByID(var_0_21) then
		local var_13_2 = arg_13_0:getBuffByID(var_0_21)
		local var_13_3 = var_13_2.leftCount_ / var_13_2:getTime()

		var_13_2.manualRevise = var_0_22 * arg_13_0:getLevel() * var_13_3
		arg_13_0.___attrCache[var_13_2:getAttrType()] = nil
	end
end

function var_0_3.addBuffBySpecialHero(arg_14_0, arg_14_1)
	if arg_14_0.skinSkillIndex_ == 1 and arg_14_0:getHp() <= arg_14_0:getHpLimit() * 0.5 then
		for iter_14_0 = #arg_14_1, 1, -1 do
			local var_14_0 = arg_14_1[iter_14_0]

			if var_14_0.target == arg_14_0 then
				if var_14_0:getType() == var_0_2.BuffType.REVIVIE then
					var_14_0.manualHarmRevise = var_14_0:getHarm() * var_0_23
				elseif var_14_0:isDHarmBuff() then
					var_14_0.manualDharm = var_14_0:totalDHarm() * var_0_23
				end
			end
		end
	end
end

return var_0_3
