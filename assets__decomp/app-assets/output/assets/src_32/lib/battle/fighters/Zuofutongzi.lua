local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zuofutongzi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 55
local var_0_8 = 1
local var_0_9 = 0.5
local var_0_10 = 10001458
local var_0_11 = 40011508
local var_0_12 = 40011509
local var_0_13 = 450
local var_0_14 = 30
local var_0_15 = 0.2
local var_0_16 = 0.2
local var_0_17 = 0.06
local var_0_18 = 10020213

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.PugongSkillID = 10002208
		arg_1_0.EnergyMarkBuff = 40012362
		arg_1_0.GreenSkillID = 10002209
		arg_1_0.BlueSkillID = 10002210
		arg_1_0.EnergySkillID = 10002211
	else
		arg_1_0.PugongSkillID = 10020213
		arg_1_0.EnergyMarkBuff = 40011507
		arg_1_0.GreenSkillID = 20010213
		arg_1_0.BlueSkillID = 30010213
		arg_1_0.EnergySkillID = 50010213
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.nGreenMarkedTargets = 0
	arg_2_0.nBlueChildCount = 0
	arg_2_0.nBlueSkipCount = 0
	arg_2_0.isGreenExtraHarm = false
	arg_2_0.isGreenExtraHarmUsed = false

	arg_2_0:listenInfo("buff_info")
end

function var_0_3.getFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getFrontSkill(arg_3_0)

	if arg_3_0.BlueEffect and math.abs(arg_3_0:getX() - arg_3_0.BlueEffect:getX()) < var_0_5:scope(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) / 2 then
		if var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
			arg_3_0:popFrontSkill()

			var_3_0 = var_0_3.super.getFrontSkill(arg_3_0)
		end

		local var_3_1 = 0

		while var_3_1 < arg_3_0.nBlueSkipCount and (var_3_0 == var_0_18 or var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) do
			arg_3_0:popFrontSkill()

			var_3_0 = var_0_3.super.getFrontSkill(arg_3_0)

			if var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
				arg_3_0:popFrontSkill()

				var_3_0 = var_0_3.super.getFrontSkill(arg_3_0)
			end

			var_3_1 = var_3_1 + 1
		end
	end

	return var_3_0
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	if arg_4_1.skillID == arg_4_0.GreenSkillID then
		local var_4_0 = 0

		if arg_4_0.isGreenExtraHarm then
			arg_4_0.isGreenExtraHarmUsed = true
			var_4_0 = arg_4_1.basicHarm * var_0_9
		end

		if arg_4_1.target:isHasBuffByID(arg_4_0.EnergyMarkBuff) then
			local var_4_1 = arg_4_1.target
			local var_4_2 = var_4_1:getBuffByID(arg_4_0.EnergyMarkBuff)

			var_4_1:removeBuffs(var_4_2)

			var_4_0 = var_4_0 + var_0_7 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) + arg_4_0:getAP() * var_0_8

			if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
				local var_4_3 = 0.3

				if var_0_2.weightedChoise({
					1 - var_4_3,
					var_4_3
				}) == 1 then
					local var_4_4 = arg_4_0:createAttackUnits({
						var_4_1
					}, var_0_10)

					for iter_4_0, iter_4_1 in ipairs(var_4_4) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
						table.insert(arg_4_0.records_.special_units, iter_4_1)
					end
				end
			end

			arg_4_0.nGreenMarkedTargets = arg_4_0.nGreenMarkedTargets + 1
		end

		arg_4_1:setExtraHarm(var_4_0)
	end

	if arg_4_1.skillID == arg_4_0.EnergySkillID then
		for iter_4_2, iter_4_3 in ipairs(arg_4_1.target:getBuffs()) do
			if iter_4_3:dBuffType() == var_0_2.DBuffType.BING_DONG or iter_4_3:dBuffType() == var_0_2.DBuffType.SHI_HUA then
				arg_4_1.target:addBuffs({
					var_0_4.new({
						tableID = arg_4_0.EnergyMarkBuff,
						start = var_0_1.ctx.battle.count,
						level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
						skillID = arg_4_0.EnergySkillID,
						fighter = arg_4_0,
						target = arg_4_1.target
					})
				})
			end
		end
	end

	if arg_4_1.skillID == arg_4_0.BlueSkillID then
		if arg_4_0.BlueEffect then
			arg_4_0.BlueEffect:stop()

			arg_4_0.BlueEffect = nil
		end

		arg_4_0.BlueEffect = var_0_1.ctx.battle.getSpine(arg_4_0.BlueSkillID, "area", 1)

		arg_4_0.BlueEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
		arg_4_0.BlueEffect:pos(arg_4_0:getX(), arg_4_0:getY())
		arg_4_0.BlueEffect:setScale(0.5)
		arg_4_0.BlueEffect:playRepeat()
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		if arg_5_0.BlueEffect then
			arg_5_0.BlueEffect:stop()

			arg_5_0.BlueEffect = nil
		end

		return
	end

	local var_5_0 = 0
	local var_5_1 = 0
	local var_5_2 = 0

	if arg_5_0.BlueEffect then
		var_5_0 = arg_5_0.BlueEffect:getX()

		local var_5_3 = arg_5_0.BlueEffect:getY()

		var_5_2 = var_0_5:scope(arg_5_0.BlueSkillID) / 2

		if math.abs(arg_5_0:getX() - arg_5_0.BlueEffect:getX()) < var_0_5:scope(arg_5_0.BlueSkillID) / 2 then
			arg_5_0.nBlueChildCount = arg_5_0.nBlueChildCount + 1

			if arg_5_0.nBlueChildCount == var_0_13 then
				arg_5_0.nBlueChildCount = 0
				arg_5_0.nBlueSkipCount = math.min(arg_5_0.nBlueSkipCount + 1, 5)
			end
		end

		if var_0_1.ctx.battle.walk2NextBattle_ then
			arg_5_0.BlueEffect:stop()

			arg_5_0.BlueEffect = nil
		end
	end

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
			if var_5_2 > math.abs(iter_5_1:getX() - var_5_0) then
				if not iter_5_1:isHasBuffByID(var_0_11) then
					iter_5_1:addBuffs({
						var_0_4.new({
							tableID = var_0_11,
							start = var_0_1.ctx.battle.count,
							level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
							skillID = arg_5_0.BlueSkillID,
							fighter = arg_5_0,
							target = iter_5_1
						})
					})
				end
			else
				iter_5_1:removeBuffByID(var_0_11)
			end
		end
	end

	for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_3:isDeath() and not iter_5_3:isAffected() then
			if var_5_2 > math.abs(iter_5_3:getX() - var_5_0) then
				if not iter_5_3:isHasBuffByID(var_0_12) then
					iter_5_3:addBuffs({
						var_0_4.new({
							tableID = var_0_12,
							start = var_0_1.ctx.battle.count,
							level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
							skillID = arg_5_0.BlueSkillID,
							fighter = arg_5_0,
							target = iter_5_3
						})
					})
				end
			else
				iter_5_3:removeBuffByID(var_0_12)
			end
		end
	end

	if arg_5_0.isGreenExtraHarmUsed then
		arg_5_0.isGreenExtraHarm = false
		arg_5_0.isGreenExtraHarmUsed = false
	end

	if arg_5_0.nGreenMarkedTargets >= 3 then
		arg_5_0:createSkillByID(arg_5_0.GreenSkillID, arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), var_0_2.SKILL_INDEX.Green)

		arg_5_0.isGreenExtraHarm = true
	end

	arg_5_0.nGreenMarkedTargets = 0

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_5_4, iter_5_5 in ipairs(arg_5_0:getInfoByKey("buff_info")) do
			if iter_5_5.target:getTeamType() ~= arg_5_0:getTeamType() and (iter_5_5:dBuffType() == var_0_2.DBuffType.SHI_HUA or iter_5_5:dBuffType() == var_0_2.DBuffType.BING_DONG) then
				iter_5_5.target:addBuffs({
					var_0_4.new({
						tableID = arg_5_0.EnergyMarkBuff,
						start = var_0_1.ctx.battle.count,
						level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy),
						skillID = arg_5_0.EnergySkillID,
						fighter = arg_5_0,
						target = iter_5_5.target
					})
				})
			end
		end
	end
end

function var_0_3.updateUnitDataByTarget(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_6_0 > 0 and arg_6_1.fighter:isHasBuffByID(arg_6_0.EnergyMarkBuff) then
		local var_6_1 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

		arg_6_4 = arg_6_4 * (1 - (var_0_14 + var_6_0 * var_0_15) / 100)
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_0.skinSkillIndex_ == 1 then
		local var_7_6 = 0
		local var_7_7 = arg_7_1.target:getBuffs()
		local var_7_8 = false

		if var_7_7 and next(var_7_7) then
			for iter_7_0, iter_7_1 in ipairs(var_7_7) do
				if iter_7_1.target:getTeamType() ~= arg_7_0:getTeamType() and (iter_7_1:dBuffType() == var_0_2.DBuffType.SHI_HUA or iter_7_1:dBuffType() == var_0_2.DBuffType.BING_DONG) then
					var_7_6 = var_7_6 + var_0_16
					var_7_8 = true

					break
				end
			end

			for iter_7_2, iter_7_3 in ipairs(var_7_7) do
				if iter_7_3.target:getTeamType() ~= arg_7_0:getTeamType() and iter_7_3.tableID_ == arg_7_0.EnergyMarkBuff and var_7_8 == true then
					var_7_6 = var_7_6 + var_0_17
				end
			end
		end

		var_7_2 = var_7_2 * (1 + var_7_6)
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

return var_0_3
