local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhangjiaoSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = 40012348
local var_0_6 = 40012349
local var_0_7 = 40012353
local var_0_8 = 10002191
local var_0_9 = 150
local var_0_10 = 10002192
local var_0_11 = 0.3
local var_0_12 = 0.003
local var_0_13 = 0.5
local var_0_14 = 30
local var_0_15 = 40012355
local var_0_16 = -30

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.PositiveChargeNums = 0
	arg_1_0.NegativeChargeNums = 0
	arg_1_0.ChargeNums = 0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.PositiveChargeSkillID = 10002397
		arg_2_0.NegativeChargeSkillID = 10002398
		arg_2_0.EnergyChildLightSkillID = 10002399
		arg_2_0.ChargedBuffID = 40012603
		arg_2_0.PugongSkillID = 10002400
		arg_2_0.EnergySkillID = 10002402
	else
		arg_2_0.PositiveChargeSkillID = 10002189
		arg_2_0.NegativeChargeSkillID = 10002190
		arg_2_0.EnergyChildLightSkillID = 10002193
		arg_2_0.ChargedBuffID = 40012350
		arg_2_0.PugongSkillID = 10020261
		arg_2_0.EnergySkillID = 50010261
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_1.skillID
	local var_3_1 = arg_3_1.target

	if var_3_0 == arg_3_0.PugongSkillID and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) > 0 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_2 = var_0_11 + arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_12

			if var_0_2.weightedChoise({
				var_3_2,
				1 - var_3_2
			}) == 1 then
				if var_0_2.weightedChoise({
					var_0_13,
					1 - var_0_13
				}) == 1 then
					local var_3_3 = arg_3_0:createAttackUnits({
						var_3_1
					}, arg_3_0.PositiveChargeSkillID)

					for iter_3_0, iter_3_1 in ipairs(var_3_3) do
						table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
						table.insert(arg_3_0.records_.special_units, iter_3_1)
					end
				else
					local var_3_4 = arg_3_0:createAttackUnits({
						var_3_1
					}, arg_3_0.NegativeChargeSkillID)

					for iter_3_2, iter_3_3 in ipairs(var_3_4) do
						table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
						table.insert(arg_3_0.records_.special_units, iter_3_3)
					end
				end
			end
		end
	elseif var_3_0 == arg_3_0.EnergySkillID then
		arg_3_0.PositiveChargeNums = 0
		arg_3_0.NegativeChargeNums = 0

		for iter_3_4, iter_3_5 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_5:isDeath() and not iter_3_5:isAffected() then
				if iter_3_5:isHasBuffByID(var_0_5) then
					local var_3_5 = iter_3_5:getBuffByID(var_0_5)

					iter_3_5:removeBuffs(var_3_5)

					arg_3_0.PositiveChargeNums = arg_3_0.PositiveChargeNums + 1
				end

				if iter_3_5:isHasBuffByID(var_0_6) then
					local var_3_6 = iter_3_5:getBuffByID(var_0_6)

					iter_3_5:removeBuffs(var_3_6)

					arg_3_0.NegativeChargeNums = arg_3_0.NegativeChargeNums + 1
				end

				if iter_3_5:isHasBuffByID(arg_3_0.ChargedBuffID) and iter_3_5:getBuffsByID(arg_3_0.ChargedBuffID) then
					local var_3_7 = iter_3_5:getBuffsByID(arg_3_0.ChargedBuffID)
					local var_3_8 = #iter_3_5:getBuffsByID(arg_3_0.ChargedBuffID)

					for iter_3_6 = #var_3_7, 1, -1 do
						iter_3_5:removeBuffs(var_3_7[iter_3_6])
					end

					arg_3_0.ChargeNums = arg_3_0.ChargeNums + var_3_8
				end
			end
		end

		arg_3_0.ChargeNums = arg_3_0.ChargeNums + math.min(arg_3_0.PositiveChargeNums, arg_3_0.NegativeChargeNums)
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count ~= 0 and var_0_1.ctx.battle.count % var_0_9 == 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = var_0_4.B3(arg_4_0, arg_4_0.EnergySkillID)

		if var_0_1.ctx.battle.count / var_0_9 % 2 == 1 then
			if var_4_0 and next(var_4_0) then
				for iter_4_0, iter_4_1 in ipairs(var_4_0) do
					local var_4_1 = arg_4_0:createAttackUnits({
						iter_4_1
					}, arg_4_0.PositiveChargeSkillID)

					for iter_4_2, iter_4_3 in ipairs(var_4_1) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
						table.insert(arg_4_0.records_.special_units, iter_4_3)
					end
				end
			end
		elseif var_4_0 and next(var_4_0) then
			for iter_4_4, iter_4_5 in ipairs(var_4_0) do
				local var_4_2 = arg_4_0:createAttackUnits({
					iter_4_5
				}, arg_4_0.NegativeChargeSkillID)

				for iter_4_6, iter_4_7 in ipairs(var_4_2) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
					table.insert(arg_4_0.records_.special_units, iter_4_7)
				end
			end
		end
	end

	if var_0_1.ctx.battle.count ~= 0 and var_0_1.ctx.battle.count % var_0_14 == 0 and arg_4_0.ChargeNums > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_3 = var_0_4.B3(arg_4_0, arg_4_0.EnergySkillID)

		if var_4_3 and next(var_4_3) then
			local var_4_4 = arg_4_0:createAttackUnits(var_4_3, arg_4_0.EnergyChildLightSkillID)

			for iter_4_8, iter_4_9 in ipairs(var_4_4) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_9)
				table.insert(arg_4_0.records_.special_units, iter_4_9)
			end

			arg_4_0.ChargeNums = arg_4_0.ChargeNums - 1
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_6 = arg_5_1.fighter
	local var_5_7 = arg_5_1.target

	if var_5_6:getTeamType() ~= arg_5_0:getTeamType() and var_5_7 == arg_5_0 and arg_5_0:isHasBuffByID(var_0_7) then
		local var_5_8 = arg_5_0:createNewBuffs({
			var_0_6
		}, var_5_6, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		var_5_6:addBuffs(var_5_8)
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	var_0_3.super.buffAddAction(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.target

	if arg_6_1:getTableID() == arg_6_0.ChargedBuffID and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and (not var_6_0:isHasBuffByID(arg_6_0.ChargedBuffID) or arg_6_0.skinSkillIndex_ == 1) then
		local var_6_1 = arg_6_0:createAttackUnits({
			var_6_0
		}, var_0_10)

		for iter_6_0, iter_6_1 in ipairs(var_6_1) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end

	if arg_6_1:getTableID() == var_0_15 then
		local var_6_2 = var_0_16 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)

		var_6_0.hpLimit_ = var_6_0.hpLimit_ + var_6_2
	end
end

function var_0_3.specialBuffExecute(arg_7_0, arg_7_1)
	var_0_3.super.specialBuffExecute(arg_7_0, arg_7_1)

	local var_7_0 = arg_7_1.target

	if arg_7_1:getTableID() == var_0_5 then
		if var_7_0:isHasBuffByID(var_0_6) then
			local var_7_1 = arg_7_0:createNewBuffs({
				arg_7_0.ChargedBuffID
			}, var_7_0, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			var_7_0:addBuffs(var_7_1)
		end
	elseif arg_7_1:getTableID() == var_0_6 and var_7_0:isHasBuffByID(var_0_5) then
		local var_7_2 = arg_7_0:createNewBuffs({
			arg_7_0.ChargedBuffID
		}, var_7_0, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		var_7_0:addBuffs(var_7_2)
	end

	if arg_7_1:getTableID() == arg_7_0.ChargedBuffID then
		if var_7_0:isHasBuffByID(var_0_6) then
			local var_7_3 = var_7_0:getBuffByID(var_0_6)

			var_7_0:removeBuffs(var_7_3)
		end

		if var_7_0:isHasBuffByID(var_0_5) then
			local var_7_4 = var_7_0:getBuffByID(var_0_5)

			var_7_0:removeBuffs(var_7_4)
		end
	end
end

return var_0_3
