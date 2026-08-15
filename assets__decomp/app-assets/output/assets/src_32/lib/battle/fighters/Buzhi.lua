local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Buzhi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = {
	40010158
}
local var_0_8 = 0.04
local var_0_9 = 0.0003
local var_0_10 = 0
local var_0_11 = 1.2
local var_0_12 = 10000435
local var_0_13 = 200
local var_0_14 = 5
local var_0_15 = 80010106
local var_0_16 = 80020106
local var_0_17 = 10001455
local var_0_18 = 0.2
local var_0_19 = 0.002
local var_0_20 = var_0_2.tables.elementEquip
local var_0_21 = 20001470
local var_0_22 = 10002249

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.blueCount_ = 1
	arg_2_0.greenTargets_ = {}
	arg_2_0.energyMoveUnit_ = nil
	arg_2_0.purpleHalo_ = nil
	arg_2_0.isSkinAddBlue_ = false
	arg_2_0.skinAddBlueCount_ = 0
	arg_2_0.records_.lottery = {}
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_3_1.skillID == var_0_22 then
		local var_3_0 = arg_3_1.target
		local var_3_1 = arg_3_0:newBuff(var_0_7, var_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		var_3_1[1].manualHarmRevise = var_3_0:getHpLimit() * (var_0_8 + var_0_9 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))

		var_3_0:addBuffs(var_3_1)

		if var_3_1[1] then
			local var_3_2 = {
				target = var_3_0,
				harm = var_3_1[1].manualHarmRevise or 0
			}

			table.insert(arg_3_0.greenTargets_, var_3_2)
		end
	end
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_6.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_3),
			skillID = arg_4_3,
			fighter = arg_4_0,
			target = arg_4_2
		})

		var_4_1:setIsHit(true)
		var_4_1:setDirection(arg_4_0:getFighterModel():getFlipX())
		table.insert(var_4_0, var_4_1)
	end

	return var_4_0
end

function var_0_3.isControlBuff(arg_5_0, arg_5_1)
	if arg_5_0.skinSkillID_ == var_0_16 and var_0_5:dbuffType(arg_5_1) > 0 or var_0_5:isLimit(arg_5_1) == 1 then
		return true
	else
		return false
	end
end

function var_0_3.unitAfterCreate(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_1 and (arg_6_1.skillID == arg_6_0:getEnergySkillID() or arg_6_1.skillID == var_0_17) then
		arg_6_0.energyMoveUnit_ = arg_6_1
	end
end

function var_0_3.getEnergyTargets(arg_7_0)
	if not arg_7_0.energyMoveUnit_ or arg_7_0.energyMoveUnit_.arrived then
		return {}
	end

	local var_7_0 = var_0_4:scope(arg_7_0.energyMoveUnit_.skillID)
	local var_7_1 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and math.abs(iter_7_1:getX() - arg_7_0.energyMoveUnit_:getX()) < var_7_0 / 2 then
			table.insert(var_7_1, iter_7_1)
		end
	end

	return var_7_1
end

function var_0_3.toDoPerFrames(arg_8_0)
	if next(arg_8_0.greenTargets_) then
		for iter_8_0 = #arg_8_0.greenTargets_, 1, -1 do
			local var_8_0 = arg_8_0.greenTargets_[iter_8_0].target

			if not var_8_0 or var_8_0:isDeath() or not var_8_0:isHasBuffByID(var_0_7[1]) then
				table.remove(arg_8_0.greenTargets_, iter_8_0)
			else
				for iter_8_1, iter_8_2 in ipairs(arg_8_0:getInfoByKey("harm_info")) do
					if iter_8_2.target and iter_8_2.target == var_8_0 and iter_8_2.harm and iter_8_2.harm > arg_8_0.greenTargets_[iter_8_0].harm then
						var_8_0:removeBuffByID(var_0_7[1])
						table.remove(arg_8_0.greenTargets_, iter_8_0)

						break
					end
				end
			end
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_8_0.energyMoveUnit_ and not arg_8_0.energyMoveUnit_.arrived and var_0_1.ctx.battle.count % 30 < 1 then
		local var_8_1 = arg_8_0:getEnergyTargets()
		local var_8_2 = arg_8_0:createAttackUnits(var_8_1, var_0_12)

		for iter_8_3, iter_8_4 in ipairs(var_8_2) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_4)
			table.insert(arg_8_0.records_.special_units, iter_8_4)
		end
	end

	if arg_8_0:isDeath() then
		return
	end

	local function var_8_3(arg_9_0)
		if arg_8_0.blueCount_ <= 0 or not next(arg_9_0) then
			return
		end

		local var_9_0 = {}

		for iter_9_0, iter_9_1 in ipairs(arg_9_0) do
			local var_9_1 = iter_9_1.target
			local var_9_2 = iter_9_1.fighter
			local var_9_3 = iter_9_1:getTableID()

			if arg_8_0:getTeamType() == var_9_1:getTeamType() and var_9_2:getTeamType() ~= var_9_1:getTeamType() and arg_8_0:isControlBuff(var_9_3) then
				table.insert(var_9_0, iter_9_1)
			end
		end

		table.sort(var_9_0, function(arg_10_0, arg_10_1)
			return arg_10_0.leftCount_ > arg_10_1.leftCount_
		end)

		while true do
			if arg_8_0.blueCount_ <= 0 or not next(var_9_0) then
				break
			end

			local var_9_4 = var_9_0[1]

			var_9_4.target:removeBuffs(var_9_4)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_8_0.skinSkillID_ == var_0_16 then
				local var_9_5 = arg_8_0:createAttackUnits({
					var_9_4.target
				}, var_0_16)

				for iter_9_2, iter_9_3 in ipairs(var_9_5) do
					table.insert(arg_8_0.moveAttackUnits_, iter_9_3)
					table.insert(arg_8_0.records_.special_units, iter_9_3)
				end
			end

			table.remove(var_9_0, 1)
			arg_8_0:updateBlueCount(-1)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_9_6 = {
					var_9_4.target
				}
				local var_9_7 = arg_8_0:createAttackUnits(var_9_6, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				for iter_9_4, iter_9_5 in ipairs(var_9_7) do
					table.insert(arg_8_0.moveAttackUnits_, iter_9_5)
					table.insert(arg_8_0.records_.special_units, iter_9_5)
				end
			end
		end
	end

	local var_8_4 = arg_8_0.skinSkillID_ == var_0_16 and 150 or var_0_13

	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		if var_0_1.ctx.battle.count % var_8_4 < 1 then
			arg_8_0:updateBlueCount(1)

			for iter_8_5, iter_8_6 in ipairs(arg_8_0.selfTeam_) do
				local var_8_5 = iter_8_6:getBuffs()

				var_8_3(var_8_5)

				if arg_8_0.blueCount_ <= 0 then
					break
				end
			end
		end

		if arg_8_0.blueCount_ > 0 then
			var_8_3(arg_8_0:getInfoByKey("buff_info"))
		end
	end

	if not arg_8_0.purpleHalo_ then
		local var_8_6 = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if var_8_6 > 0 then
			local var_8_7 = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
			local var_8_8 = var_0_4:buffs(var_8_7)
			local var_8_9 = {
				fighter = arg_8_0,
				effect_area = function(arg_11_0)
					return true
				end,
				target_type = var_0_2.HaloEffect.selfTeam,
				buffs = var_8_8,
				level = var_8_6,
				skillID = var_8_7,
				manualAttr = function(arg_12_0)
					local var_12_0 = {
						200,
						400,
						600,
						800
					}

					for iter_12_0 = 1, #var_12_0 - 1 do
						if math.abs(arg_12_0:getX() - arg_8_0:getX()) < var_12_0[iter_12_0] then
							if iter_12_0 == 1 then
								return var_0_10 + var_0_11 * var_8_6
							end

							return 2 * (iter_12_0 - 1) * (var_0_10 + var_0_11 * var_8_6)
						end
					end

					return 8 * (var_0_10 + var_0_11 * var_8_6)
				end
			}

			arg_8_0:addBuffHalo(var_8_9)

			arg_8_0.purpleHalo_ = var_8_9
		end
	end

	if arg_8_0.skinSkillID_ == var_0_15 and not arg_8_0.isSkinAddBlue_ then
		arg_8_0.isSkinAddBlue_ = true

		arg_8_0:updateBlueCount(2)
	end
end

function var_0_3.updateBlueCount(arg_13_0, arg_13_1)
	if arg_13_0.skinSkillID_ == var_0_15 and arg_13_1 == 1 and arg_13_0.skinAddBlueCount_ < var_0_14 then
		arg_13_1 = 2
		arg_13_0.skinAddBlueCount_ = arg_13_0.skinAddBlueCount_ + 1
	end

	if arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_13_1 < 0 then
		local var_13_0 = var_0_18 + var_0_19 * arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)
		local var_13_1 = true

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_13_1 = arg_13_0.lottery_[tostring(var_0_1.ctx.battle.count)] or var_0_2.weightedChoise({
				var_13_0,
				1 - var_13_0
			}) == 1
		else
			var_13_1 = var_0_2.weightedChoise({
				var_13_0,
				1 - var_13_0
			}) == 1
			arg_13_0.records_.lottery[tostring(var_0_1.ctx.battle.count)] = hit
		end

		if var_13_1 then
			arg_13_1 = 0
		end
	end

	arg_13_0.blueCount_ = arg_13_0.blueCount_ + arg_13_1

	arg_13_0:updateStateNumber(arg_13_0.blueCount_)
end

function var_0_3.updateUnitDataByFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)
	arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7 = var_0_3.super.updateUnitDataByFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)

	if arg_14_0:hasElementEquipByID(var_0_21) and arg_14_5 > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_14_0 = var_0_21
		local var_14_1 = var_0_20:battleAttr(var_14_0, arg_14_0:getElementEquipLevelByID(var_14_0))
		local var_14_2 = 1
		local var_14_3 = arg_14_0.hero_:getElementEquipActiveRate(var_14_0)

		if var_0_2.weightedChoise({
			var_14_2,
			1 - var_14_2
		}) == 1 then
			local var_14_4 = arg_14_0:getElementTarget()
			local var_14_5 = arg_14_0:createAttackUnits(var_14_4, var_0_22)

			for iter_14_0, iter_14_1 in ipairs(var_14_5) do
				table.insert(arg_14_0.moveAttackUnits_, iter_14_1)
				table.insert(arg_14_0.records_.special_units, iter_14_1)
			end
		end
	end

	return arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7
end

function var_0_3.getElementTarget(arg_15_0)
	local var_15_0 = {}
	local var_15_1 = {}
	local var_15_2

	for iter_15_0, iter_15_1 in pairs(arg_15_0.selfTeam_) do
		if not iter_15_1:isDeath() and not iter_15_1:isAffected() then
			if iter_15_1:isHasBuffByID(var_0_7[1]) then
				table.insert(var_15_0, iter_15_1)
			else
				table.insert(var_15_1, iter_15_1)
			end
		end
	end

	local var_15_3 = math.random(tonumber(os.time()))

	math.randomseed(var_15_3)

	if #var_15_1 > 0 then
		var_15_2 = var_15_1[math.random(#var_15_1)]
	elseif #var_15_0 > 0 then
		var_15_2 = var_15_0[math.random(#var_15_0)]
	end

	return {
		var_15_2
	}
end

function var_0_3.setupReport(arg_16_0, arg_16_1)
	var_0_3.super.setupReport(arg_16_0, arg_16_1)

	arg_16_0.lottery_ = arg_16_1.lottery or {}
end

function var_0_3.writeReport(arg_17_0)
	local var_17_0 = var_0_3.super.writeReport(arg_17_0)

	var_17_0.lottery = arg_17_0.records_.lottery

	return var_17_0
end

return var_0_3
