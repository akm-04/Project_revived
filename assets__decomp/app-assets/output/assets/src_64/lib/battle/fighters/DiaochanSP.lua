local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("DiaochanSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = {
	40012461,
	40012462
}
local var_0_11 = {
	40012451,
	40012452,
	40012453
}
local var_0_12 = {
	40012455,
	40012457,
	40012459
}
local var_0_13 = {
	40012456,
	40012458,
	40012460
}
local var_0_14 = 10002271
local var_0_15 = 40012454
local var_0_16 = 10002272
local var_0_17 = 30
local var_0_18 = 40012450
local var_0_19 = 0.1
local var_0_20 = 0.003
local var_0_21 = 0.1
local var_0_22 = 0.001
local var_0_23 = 10002273
local var_0_24 = 10002274

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("buff_harm")

	arg_1_0.BlueOrbNum = 0
	arg_1_0.ConsumeOrbNum = 0
	arg_1_0.EnergyOrbNum = {}
end

function var_0_3.getBlueSkillTarget(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = {}
	local var_2_1 = var_0_6:scope(arg_2_2)
	local var_2_2, var_2_3 = arg_2_1:getPos()
	local var_2_4, var_2_5 = var_0_5.getTeam(arg_2_1)

	for iter_2_0, iter_2_1 in ipairs(var_2_5) do
		local var_2_6, var_2_7 = iter_2_1:getPos()

		if not iter_2_1:isDeath() and not iter_2_1:isAffected() and var_2_1 >= math.abs(var_2_6 - var_2_2) then
			table.insert(var_2_0, iter_2_1)
		end
	end

	return var_2_0
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if var_0_1.ctx.battle.count % 5 == 1 and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
		local var_3_1 = arg_3_0:getBlueSkillTarget(arg_3_0, var_3_0)
		local var_3_2 = 0

		arg_3_0:updateBlueOrbNum()

		if next(var_3_1) then
			for iter_3_0, iter_3_1 in ipairs(var_3_1) do
				if not iter_3_1:isHasBuffByID(var_0_15) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_3_2 < arg_3_0.BlueOrbNum then
					local var_3_3 = var_0_14
					local var_3_4 = arg_3_0:createAttackUnits({
						iter_3_1
					}, var_3_3)

					for iter_3_2, iter_3_3 in ipairs(var_3_4) do
						table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
						table.insert(arg_3_0.records_.special_units, iter_3_3)
					end

					var_3_2 = var_3_2 + 1
				end
			end
		end

		if var_3_2 > 0 then
			arg_3_0:consumeBlueOrb(var_3_2)
		end
	end
end

function var_0_3.addBuffBySpecialHero(arg_4_0, arg_4_1)
	var_0_3.super.addBuffBySpecialHero(arg_4_0, arg_4_1)

	for iter_4_0 = #arg_4_1, 1, -1 do
		local var_4_0 = arg_4_1[iter_4_0]
		local var_4_1 = var_4_0.target

		if var_4_1 and not var_4_1:isDeath() and var_4_1:getTeamType() == arg_4_0:getTeamType() and var_0_9:dbuffType(var_4_0:getTableID()) > 0 then
			if var_4_1:isHasBuffByID(var_0_10[2]) then
				var_4_1:getBuffByID(var_0_10[2]).DiaoChanSPConsumeFlag = true

				var_4_1:removeBuffByID(var_0_10[2])
				table.remove(arg_4_1, iter_4_0)
				arg_4_0:consumeEnergyOrb(1)

				local var_4_2 = arg_4_0:createNewBuffs({
					var_0_10[1]
				}, var_4_1, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				var_4_1:addBuffs(var_4_2)
			elseif var_4_1:isHasBuffByID(var_0_10[1]) then
				var_4_1:getBuffByID(var_0_10[1]).DiaoChanSPConsumeFlag = true

				var_4_1:removeBuffByID(var_0_10[1])
				table.remove(arg_4_1, iter_4_0)
				arg_4_0:consumeEnergyOrb(1)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_5_0:updateBlueOrbNum()

		if arg_5_0.BlueOrbNum > 0 then
			for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
				if not iter_5_1:isDeath() and iter_5_1:getSummonType() == var_0_2.summonMonsterType.None then
					local var_5_0 = arg_5_0:createNewBuffs({
						var_0_12[arg_5_0.BlueOrbNum],
						var_0_13[arg_5_0.BlueOrbNum]
					}, iter_5_1, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

					iter_5_1:addBuffs(var_5_0)
				end
			end

			arg_5_0:removeBuffByID(var_0_11[arg_5_0.BlueOrbNum])
		end

		local var_5_1 = arg_5_0:createNewBuffs({
			var_0_11[3]
		}, arg_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_5_0:addBuffs(var_5_1)
		arg_5_0:setBlueOrbNum(3)
	elseif arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_5_2 = arg_5_1.target

		if not arg_5_0.EnergyOrbNum[var_5_2] then
			arg_5_0.EnergyOrbNum[var_5_2] = 0
		elseif arg_5_0.EnergyOrbNum[var_5_2] > 0 then
			local var_5_3 = arg_5_0.EnergyOrbNum[var_5_2]

			var_5_2:removeBuffByID(var_0_10[var_5_3])
		end

		local var_5_4 = arg_5_0:createNewBuffs({
			var_0_10[2]
		}, var_5_2, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		var_5_2:addBuffs(var_5_4)
	end
end

function var_0_3.updateBlueOrbNum(arg_6_0)
	if arg_6_0:isHasBuffByID(var_0_11[3]) then
		arg_6_0.BlueOrbNum = 3
	elseif arg_6_0:isHasBuffByID(var_0_11[2]) then
		arg_6_0.BlueOrbNum = 2
	elseif arg_6_0:isHasBuffByID(var_0_11[1]) then
		arg_6_0.BlueOrbNum = 1
	end
end

function var_0_3.setBlueOrbNum(arg_7_0, arg_7_1)
	arg_7_0.BlueOrbNum = arg_7_1
end

function var_0_3.consumeBlueOrb(arg_8_0, arg_8_1)
	arg_8_0.ConsumeOrbNum = arg_8_0.ConsumeOrbNum + arg_8_1

	arg_8_0:updateEnergyBy(arg_8_1 * var_0_17)

	if arg_8_0.BlueOrbNum > 0 then
		arg_8_0:removeBuffByID(var_0_11[arg_8_0.BlueOrbNum])

		arg_8_0.BlueOrbNum = arg_8_0.BlueOrbNum - arg_8_1
	end

	if arg_8_0.BlueOrbNum > 0 then
		local var_8_0 = arg_8_0:createNewBuffs({
			var_0_11[arg_8_0.BlueOrbNum]
		}, arg_8_0, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_8_0:addBuffs(var_8_0)
	end

	if arg_8_0.ConsumeOrbNum >= 10 then
		local var_8_1 = arg_8_0:getTargets(var_0_16)

		if var_8_1 and next(var_8_1) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_8_2 = arg_8_0:createAttackUnits(var_8_1, var_0_16)

			for iter_8_0, iter_8_1 in ipairs(var_8_2) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
				table.insert(arg_8_0.records_.special_units, iter_8_1)
			end
		end

		local var_8_3 = arg_8_0:getTargets(var_0_14)

		if var_8_3 and next(var_8_3) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_8_4 = arg_8_0:createAttackUnits(var_8_3, var_0_14)

			for iter_8_2, iter_8_3 in ipairs(var_8_4) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
				table.insert(arg_8_0.records_.special_units, iter_8_3)
			end
		end

		arg_8_0.ConsumeOrbNum = 0
	end
end

function var_0_3.consumeEnergyOrb(arg_9_0, arg_9_1)
	arg_9_0.ConsumeOrbNum = arg_9_0.ConsumeOrbNum + arg_9_1

	arg_9_0:updateEnergyBy(arg_9_1 * var_0_17)

	if arg_9_0.ConsumeOrbNum >= 10 then
		local var_9_0 = arg_9_0:getTargets(var_0_16)

		if var_9_0 and next(var_9_0) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_9_1 = arg_9_0:createAttackUnits(var_9_0, var_0_16)

			for iter_9_0, iter_9_1 in ipairs(var_9_1) do
				table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
				table.insert(arg_9_0.records_.special_units, iter_9_1)
			end
		end

		local var_9_2 = arg_9_0:getTargets(var_0_14)

		if var_9_2 and next(var_9_2) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_9_3 = arg_9_0:createAttackUnits(var_9_2, var_0_14)

			for iter_9_2, iter_9_3 in ipairs(var_9_3) do
				table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
				table.insert(arg_9_0.records_.special_units, iter_9_3)
			end
		end

		arg_9_0.ConsumeOrbNum = 0
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5 = var_0_3.super.updateUnitDataByTarget(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_6 = arg_10_1.target
	local var_10_7 = arg_10_1.fighter

	if var_10_7:getTeamType() ~= arg_10_0:getTeamType() and var_10_2 > 0 and var_10_6:getTeamType() == arg_10_0:getTeamType() and var_10_7:isHasBuffByID(var_0_18) then
		var_10_2 = var_10_2 - var_10_2 * (var_0_19 + var_0_20 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
	end

	if var_10_7:getTeamType() ~= arg_10_0:getTeamType() and var_10_2 > 0 and var_10_6:getTeamType() == arg_10_0:getTeamType() then
		local var_10_8 = var_0_21 + var_0_22 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
		local var_10_9 = math.min(var_10_6:getHpLimit() * var_10_8, var_10_6:getHp())

		if var_10_6:isHasBuffByID(var_0_10[2]) and var_10_9 <= var_10_2 then
			var_10_6:getBuffByID(var_0_10[2]).DiaoChanSPConsumeFlag = true
			var_10_2 = 0

			var_10_6:removeBuffByID(var_0_10[2])
			arg_10_0:consumeEnergyOrb(1)

			local var_10_10 = arg_10_0:createNewBuffs({
				var_0_10[1]
			}, var_10_6, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

			var_10_6:addBuffs(var_10_10)
		elseif var_10_6:isHasBuffByID(var_0_10[1]) and var_10_9 <= var_10_2 then
			var_10_6:getBuffByID(var_0_10[1]).DiaoChanSPConsumeFlag = true
			var_10_2 = 0

			var_10_6:removeBuffByID(var_0_10[1])
			arg_10_0:consumeEnergyOrb(1)
		end
	end

	return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
end

function var_0_3.buffRemoveAction(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1.target

	if (arg_11_1:getTableID() == var_0_10[1] or arg_11_1:getTableID() == var_0_10[2]) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_11_1.DiaoChanSPConsumeFlag then
			local var_11_1 = arg_11_0:createAttackUnits({
				var_11_0
			}, var_0_23)

			for iter_11_0, iter_11_1 in ipairs(var_11_1) do
				table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
				table.insert(arg_11_0.records_.special_units, iter_11_1)
			end
		else
			local var_11_2 = arg_11_0:createAttackUnits({
				var_11_0
			}, var_0_24)

			for iter_11_2, iter_11_3 in ipairs(var_11_2) do
				table.insert(arg_11_0.moveAttackUnits_, iter_11_3)
				table.insert(arg_11_0.records_.special_units, iter_11_3)
			end
		end
	end
end

return var_0_3
