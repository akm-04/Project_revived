local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hanshaodi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = 10001958
local var_0_10 = 10001959
local var_0_11 = 0.1
local var_0_12 = 0.001
local var_0_13 = 0.05
local var_0_14 = 0.0015
local var_0_15 = 11
local var_0_16 = 0.2
local var_0_17 = 0.005
local var_0_18 = 0.2
local var_0_19 = 360
local var_0_20 = 40010251
local var_0_21 = 0.2
local var_0_22 = 0.003
local var_0_23 = 10001351
local var_0_24 = 80010251
local var_0_25 = 40012519

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyCount = 0
	arg_1_0.purpleCount = 0
	arg_1_0.purpleTotalHarm = 0
	arg_1_0.purpleHarm = {}

	arg_1_0:listenInfo("buff_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.EnergyShoujiSkill = 10002333
		arg_2_0.EnergyHarmBuffID1 = 40012521
		arg_2_0.PurpleBuff = 40012523
		arg_2_0.EnergyHarmBuffID2 = 40012524
		arg_2_0.EnergySingleBuff = {
			40012525,
			40012098
		}
	else
		arg_2_0.EnergyShoujiSkill = 10001960
		arg_2_0.EnergyHarmBuffID1 = 40012093
		arg_2_0.PurpleBuff = 40012095
		arg_2_0.EnergyHarmBuffID2 = 40012096
		arg_2_0.EnergySingleBuff = {
			40012097,
			40012098
		}
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	arg_3_0.purpleCount = arg_3_0.purpleCount - 1

	if arg_3_0.skinSkillIndex_ == 1 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			if iter_3_1.target:getTeamType() ~= arg_3_0:getTeamType() and (iter_3_1:getTableID() == arg_3_0.EnergyHarmBuffID1 or iter_3_1:getTableID() == arg_3_0.EnergyHarmBuffID2) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_0 = arg_3_0:createAttackUnits({
					iter_3_1.target
				}, var_0_24)

				for iter_3_2, iter_3_3 in ipairs(var_3_0) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getEnergySkillID() then
		arg_4_0:energySkill()
	elseif arg_4_1.skillID == var_0_9 then
		local var_4_0 = arg_4_1.target
		local var_4_1 = arg_4_1.energyBuffID

		if var_4_1 == arg_4_0.EnergyHarmBuffID2 and var_4_0:isHasBuffByID(arg_4_0.EnergyHarmBuffID1) then
			var_4_0:removeBuffByID(arg_4_0.EnergyHarmBuffID1)
		end

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
			if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1:isHasBuffByID(arg_4_0.EnergyHarmBuffID1) then
				local var_4_2 = arg_4_0:createNewBuffs({
					arg_4_0.EnergyHarmBuffID1
				}, iter_4_1, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				iter_4_1:addBuffs(var_4_2)
			end
		end

		local var_4_3 = arg_4_0:createNewBuffs({
			var_4_1
		}, var_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		var_4_0:addBuffs(var_4_3)
	end
end

function var_0_3.energySkill(arg_5_0)
	local var_5_0 = {}
	local var_5_1 = arg_5_0:getX()
	local var_5_2 = {}
	local var_5_3, var_5_4 = var_0_4.getTeam(arg_5_0)

	for iter_5_0, iter_5_1 in ipairs(var_5_4) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
			table.insert(var_5_2, iter_5_1)
		end
	end

	if not next(var_5_2) then
		return
	end

	table.sort(var_5_2, function(arg_6_0, arg_6_1)
		return math.abs(arg_6_0:getX() - var_5_1) < math.abs(arg_6_1:getX() - var_5_1)
	end)

	for iter_5_2, iter_5_3 in ipairs(var_5_2) do
		table.insert(var_5_0, iter_5_3)
	end

	local var_5_5
	local var_5_6 = 0
	local var_5_7 = true

	for iter_5_4, iter_5_5 in ipairs(var_5_4) do
		if not iter_5_5:isDeath() and not iter_5_5:isAffected() then
			if iter_5_5:isHasBuffByID(arg_5_0.EnergyHarmBuffID1) or iter_5_5:isHasBuffByID(arg_5_0.EnergyHarmBuffID2) then
				var_5_6 = var_5_6 + 1
			else
				var_5_7 = false
			end
		end
	end

	if #var_5_0 == 1 then
		local var_5_8 = var_5_0[1]
		local var_5_9 = arg_5_0:createNewBuffs(arg_5_0.EnergySingleBuff, var_5_8, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		var_5_8:addBuffs(var_5_9)
	elseif var_5_7 then
		for iter_5_6, iter_5_7 in ipairs(var_5_0) do
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_10 = arg_5_0:createAttackUnits({
					iter_5_7
				}, arg_5_0.EnergyShoujiSkill)

				for iter_5_8, iter_5_9 in ipairs(var_5_10) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_9)
					table.insert(arg_5_0.records_.special_units, iter_5_9)
				end

				local var_5_11 = arg_5_0:createAttackUnits({
					iter_5_7
				}, var_0_9)

				for iter_5_10, iter_5_11 in ipairs(var_5_11) do
					iter_5_11.energyBuffID = arg_5_0.EnergyHarmBuffID2

					table.insert(arg_5_0.moveAttackUnits_, iter_5_11)
					table.insert(arg_5_0.records_.special_units, iter_5_11)
				end
			end
		end

		arg_5_0.energyCount = math.min(arg_5_0.energyCount + 1, var_0_15)
	else
		local var_5_12 = var_5_6 > 0 and 1 or 2
		local var_5_13 = 0

		for iter_5_12, iter_5_13 in ipairs(var_5_0) do
			if var_5_12 <= var_5_13 then
				break
			end

			if not iter_5_13:isHasBuffByID(arg_5_0.EnergyHarmBuffID1) then
				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_5_14 = arg_5_0:createAttackUnits({
						iter_5_13
					}, arg_5_0.EnergyShoujiSkill)

					for iter_5_14, iter_5_15 in ipairs(var_5_14) do
						table.insert(arg_5_0.moveAttackUnits_, iter_5_15)
						table.insert(arg_5_0.records_.special_units, iter_5_15)
					end

					local var_5_15 = arg_5_0:createAttackUnits({
						iter_5_13
					}, var_0_9)

					for iter_5_16, iter_5_17 in ipairs(var_5_15) do
						iter_5_17.energyBuffID = arg_5_0.EnergyHarmBuffID1

						table.insert(arg_5_0.moveAttackUnits_, iter_5_17)
						table.insert(arg_5_0.records_.special_units, iter_5_17)
					end
				end

				var_5_13 = var_5_13 + 1
			end
		end

		arg_5_0.energyCount = 0
	end
end

function var_0_3.updateUnitInfoBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	if arg_7_1.skillID ~= var_0_10 and arg_7_1.skillID ~= var_0_23 and (arg_7_1.target:isHasBuffByID(arg_7_0.EnergyHarmBuffID1) or arg_7_1.target:isHasBuffByID(arg_7_0.EnergyHarmBuffID2)) then
		for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
			if iter_7_1 ~= arg_7_1.target and not iter_7_1:isDeath() and not iter_7_1:isAffected() then
				if iter_7_1:isHasBuffByID(arg_7_0.EnergyHarmBuffID2) then
					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_7_0 = arg_7_0:createAttackUnits({
							iter_7_1
						}, var_0_10)

						for iter_7_2, iter_7_3 in ipairs(var_7_0) do
							iter_7_3.energyHarm = arg_7_4 * ((var_0_11 + var_0_12 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)) * (1 + (var_0_13 + var_0_14 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)) * arg_7_0.energyCount))

							table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
							table.insert(arg_7_0.records_.special_units, iter_7_3)
						end
					end
				elseif iter_7_1:isHasBuffByID(arg_7_0.EnergyHarmBuffID1) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_7_1 = arg_7_0:createAttackUnits({
						iter_7_1
					}, var_0_10)

					for iter_7_4, iter_7_5 in ipairs(var_7_1) do
						iter_7_5.energyHarm = arg_7_4 * (var_0_11 + var_0_12 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

						table.insert(arg_7_0.moveAttackUnits_, iter_7_5)
						table.insert(arg_7_0.records_.special_units, iter_7_5)
					end
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_1.skillID == var_0_10 then
		arg_8_4 = arg_8_1.energyHarm
	elseif arg_8_1.skillID == var_0_20 then
		arg_8_4 = arg_8_1.purpleTotalHarm
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.checkSpGive(arg_9_0, arg_9_1, arg_9_2)
	return arg_9_2 * (var_0_16 + var_0_17 * arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
end

function var_0_3.applyHurtFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_10_0:isHasBuffByID(arg_10_0.PurpleBuff) then
			arg_10_0.purpleTotalHarm = arg_10_0.purpleTotalHarm + arg_10_2

			if not arg_10_0.purpleHarm[arg_10_1.fighter] then
				arg_10_0.purpleHarm[arg_10_1.fighter] = arg_10_2
			else
				arg_10_0.purpleHarm[arg_10_1.fighter] = arg_10_0.purpleHarm[arg_10_1.fighter] + arg_10_2
			end

			arg_10_2 = 0
		elseif arg_10_2 > arg_10_0:getHpLimit() * var_0_18 and arg_10_0.purpleCount <= 0 then
			arg_10_0.purpleTotalHarm = arg_10_0.purpleTotalHarm + arg_10_2

			if not arg_10_0.purpleHarm[arg_10_1.fighter] then
				arg_10_0.purpleHarm[arg_10_1.fighter] = arg_10_2
			else
				arg_10_0.purpleHarm[arg_10_1.fighter] = arg_10_0.purpleHarm[arg_10_1.fighter] + arg_10_2
			end

			arg_10_2 = 0

			local var_10_0 = arg_10_0:createNewBuffs({
				arg_10_0.PurpleBuff
			}, arg_10_0, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			arg_10_0:addBuffs(var_10_0)

			arg_10_0.purpleCount = var_0_19
		end
	end

	return var_0_3.super.applyHurtFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
end

function var_0_3.buffAddAction(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1.target

	if arg_11_0.skinSkillIndex_ == 1 and (arg_11_1:getTableID() == arg_11_0.EnergyHarmBuffID1 or arg_11_1:getTableID() == arg_11_0.EnergyHarmBuffID2) then
		if arg_11_0:isHasBuffByID(var_0_25) then
			arg_11_0:removeBuffByID(var_0_25)
		end

		local var_11_1 = arg_11_0:createNewBuffs({
			var_0_25
		}, arg_11_0, arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		arg_11_0:addBuffs(var_11_1)

		for iter_11_0, iter_11_1 in ipairs(arg_11_0.sideTeam_) do
			if not iter_11_1:isDeath() and not iter_11_1:isAffected() and (iter_11_1:isHasBuffByID(arg_11_0.EnergyHarmBuffID1) or iter_11_1:isHasBuffByID(arg_11_0.EnergyHarmBuffID2)) and iter_11_1 ~= var_11_0 then
				local var_11_2 = arg_11_0:createNewBuffs({
					var_0_25
				}, arg_11_0, arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				arg_11_0:addBuffs(var_11_2)
			end
		end
	end
end

function var_0_3.buffRemoveAction(arg_12_0, arg_12_1)
	if arg_12_1:getTableID() == arg_12_0.PurpleBuff then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_12_0 = var_0_20
			local var_12_1
			local var_12_2

			for iter_12_0, iter_12_1 in pairs(arg_12_0.purpleHarm) do
				if not iter_12_0:isDeath() and not iter_12_0:isAffected() and (not var_12_1 or var_12_2 < iter_12_1) then
					var_12_1 = iter_12_0
					var_12_2 = iter_12_1
				end
			end

			local var_12_3 = arg_12_0:createAttackUnits({
				var_12_1
			}, var_12_0)

			for iter_12_2, iter_12_3 in ipairs(var_12_3) do
				local var_12_4 = var_0_21 + var_0_22 * arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

				iter_12_3.purpleTotalHarm = math.min(arg_12_0.purpleTotalHarm * var_12_4, arg_12_0:getHpLimit())

				table.insert(arg_12_0.moveAttackUnits_, iter_12_3)
				table.insert(arg_12_0.records_.special_units, iter_12_3)
			end

			arg_12_0.purpleTotalHarm = 0
			arg_12_0.purpleHarm = {}
		end
	elseif arg_12_0.skinSkillIndex_ == 1 and (arg_12_1:getTableID() == arg_12_0.EnergyHarmBuffID1 or arg_12_1:getTableID() == arg_12_0.EnergyHarmBuffID2) then
		if arg_12_0:isHasBuffByID(var_0_25) then
			arg_12_0:removeBuffByID(var_0_25)
		end

		for iter_12_4, iter_12_5 in ipairs(arg_12_0.sideTeam_) do
			if not iter_12_5:isDeath() and not iter_12_5:isAffected() and (iter_12_5:isHasBuffByID(arg_12_0.EnergyHarmBuffID1) or iter_12_5:isHasBuffByID(arg_12_0.EnergyHarmBuffID2)) then
				local var_12_5 = arg_12_0:createNewBuffs({
					var_0_25
				}, arg_12_0, arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				arg_12_0:addBuffs(var_12_5)
			end
		end
	end
end

return var_0_3
