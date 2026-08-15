local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liucong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skinSkill
local var_0_7 = 40012556
local var_0_8 = 40012557
local var_0_9 = 60
local var_0_10 = {
	10002349,
	10002350,
	10002351
}
local var_0_11 = {
	40012558,
	40012559,
	40012560
}
local var_0_12 = 10002352
local var_0_13 = 10
local var_0_14 = 40012564
local var_0_15 = 9

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.firstTarget = nil
	arg_2_0.secondTarget = nil
	arg_2_0.purpleSkillTargetCount = nil
	arg_2_0.gemStoneNum = 0
	arg_2_0.gemStoneBuffCountNum = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			local var_3_0 = iter_3_1.target

			if var_3_0 and not var_3_0:isDeath() and not var_3_0:isAffected() and var_3_0:getTeamType() ~= arg_3_0:getTeamType() and iter_3_1:getTableID() ~= var_0_11[3] and iter_3_1:dBuffType() > 0 and iter_3_1:dBuffType() ~= var_0_2.DBuffType.ATTR_CHANGE and var_3_0:isHasBuffByID(var_0_11[3]) then
				local var_3_1 = var_0_4.A1(var_3_0)

				var_3_0:removeBuffByID(var_0_11[3])

				if #var_3_1 > 0 then
					for iter_3_2, iter_3_3 in ipairs(var_3_1) do
						local var_3_2 = arg_3_0:createNewBuffs({
							iter_3_1:getTableID()
						}, iter_3_3, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

						iter_3_3:addBuffs(var_3_2)
					end
				end
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	if arg_4_1.rootID_ == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_4_0.gemStoneNum = arg_4_0.gemStoneNum + 1
	elseif arg_4_1.rootID_ == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_4_0.gemStoneNum = arg_4_0.gemStoneNum + 1
	elseif arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.gemStoneBuffCountNum = arg_4_0.gemStoneNum
		arg_4_0.gemStoneNum = 0
	end

	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_5_0 = arg_5_1.target
		local var_5_1 = false

		for iter_5_0, iter_5_1 in ipairs(var_5_0:getBuffs()) do
			if iter_5_1:totalDHarm() > 0 and iter_5_1:canRemove() then
				var_5_0:removeBuffs(iter_5_1)

				var_5_1 = true
			end
		end

		if var_5_1 == false then
			local var_5_2 = arg_5_0:createNewBuffs({
				var_0_7
			}, var_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

			var_5_0:addBuffs(var_5_2)
		end
	elseif arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_5_3 = arg_5_0:getBlueTarget()

		if arg_5_0.firstTarget then
			local var_5_4 = arg_5_0:createNewBuffs({
				var_0_8
			}, arg_5_0.firstTarget, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_5_0.firstTarget:addBuffs(var_5_4)

			if arg_5_0.secondTarget then
				local var_5_5, var_5_6 = arg_5_0.firstTarget:getPos()
				local var_5_7, var_5_8 = arg_5_0.secondTarget:getPos()

				arg_5_0.firstTarget:pos(var_5_7, var_5_8)
				arg_5_0.secondTarget:pos(var_5_5, var_5_6)

				local var_5_9 = arg_5_0:createNewBuffs({
					var_0_8
				}, arg_5_0.secondTarget, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				arg_5_0.secondTarget:addBuffs(var_5_9)
			end
		end

		arg_5_0.firstTarget = nil
		arg_5_0.secondTarget = nil
	end

	if arg_5_1.skillID == var_0_10[1] or arg_5_1.skillID == var_0_10[2] or arg_5_1.skillID == var_0_10[3] then
		arg_5_0.gemStoneNum = arg_5_0.gemStoneNum + 1
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	local var_6_0 = arg_6_1.target

	if arg_6_1.skillID == var_0_12 and var_6_0:getTeamType() == arg_6_0:getTeamType() and arg_6_1.extraCure and arg_6_1.extraCure > 0 then
		arg_6_5 = arg_6_1.extraCure
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	local var_7_0 = arg_7_1.fighter

	if arg_7_4 > 0 and var_7_0:getTeamType() ~= arg_7_0:getTeamType() and arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_7_1 = var_0_1.ctx.battle.count

		if not arg_7_0.purpleSkillTargetCount or var_7_1 - arg_7_0.purpleSkillTargetCount > var_0_9 then
			local var_7_2 = var_0_10[math.random(#var_0_10)]
			local var_7_3 = arg_7_0:createAttackUnits({
				var_7_0
			}, var_7_2)

			for iter_7_0, iter_7_1 in ipairs(var_7_3) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end

			arg_7_0.purpleSkillTargetCount = var_7_1
		end
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	local var_8_0 = arg_8_1.target

	if arg_8_5 > 0 and var_8_0:getTeamType() ~= arg_8_0:getTeamType() and var_8_0:isHasBuffByID(var_0_11[1]) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_1 = var_0_4.A3(arg_8_0)
		local var_8_2 = arg_8_0:createAttackUnits(var_8_1, var_0_12)

		for iter_8_0, iter_8_1 in ipairs(var_8_2) do
			iter_8_1.extraCure = arg_8_5

			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end

		arg_8_5 = 0
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.getBlueTarget(arg_9_0)
	local var_9_0 = arg_9_0:getX()
	local var_9_1
	local var_9_2
	local var_9_3, var_9_4 = var_0_4.getTeam(arg_9_0)

	for iter_9_0, iter_9_1 in ipairs(var_9_4) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and (not var_9_1 or var_9_1 < math.abs(iter_9_1:getX() - var_9_0)) then
			var_9_2 = iter_9_1
			var_9_1 = math.abs(iter_9_1:getX() - var_9_0)
		end
	end

	if not var_9_2 then
		return {}
	end

	arg_9_0.firstTarget = var_9_2

	local var_9_5
	local var_9_6

	for iter_9_2, iter_9_3 in ipairs(var_9_4) do
		if not iter_9_3:isDeath() and not iter_9_3:isAffected() and iter_9_3 ~= var_9_2 and (not var_9_5 or var_9_5 < math.abs(iter_9_3:getX() - var_9_0)) then
			var_9_6 = iter_9_3
			var_9_5 = math.abs(iter_9_3:getX() - var_9_0)
		end
	end

	if not var_9_6 then
		return {
			var_9_2
		}
	end

	arg_9_0.secondTarget = var_9_6

	return {
		var_9_2,
		var_9_6
	}
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	var_0_3.super.buffAddAction(arg_10_0, arg_10_1)

	if arg_10_1:getTableID() == var_0_14 then
		local var_10_0 = var_0_15 * math.min(arg_10_0.gemStoneBuffCountNum, var_0_13)

		arg_10_1:setExtraTime(var_10_0)
	end
end

return var_0_3
