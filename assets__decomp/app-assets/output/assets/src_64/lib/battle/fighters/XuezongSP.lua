local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("XuezongSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = 0.3
local var_0_10 = 0.004
local var_0_11 = 0.3
local var_0_12 = 0.004
local var_0_13 = 0.3
local var_0_14 = 0.004
local var_0_15 = {
	10002285,
	10002286,
	10002287,
	10002288
}
local var_0_16 = {
	10002289,
	10002290,
	10002291,
	10002292
}
local var_0_17 = {
	10002293,
	10002294,
	10002295
}
local var_0_18 = {
	10002296,
	10002297,
	10002298
}
local var_0_19 = {
	0.25,
	0.25,
	0.25,
	0.25
}
local var_0_20 = {
	0.3,
	0.3,
	0.3
}
local var_0_21 = {
	0.3,
	0.3,
	0.3
}
local var_0_22 = 10002300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.GreenPriceState = 0
	arg_1_0.BluePriceState = 0
	arg_1_0.EnergyPriceState = 0
	arg_1_0.GreenPriceCount = {
		0,
		0,
		0,
		0
	}
	arg_1_0.isGetPrice = false
	arg_1_0.loseLotteryTimes = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isGetPrice and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_0
		}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end

		arg_2_0.isGetPrice = false
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.rootID_

	if var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_3_1 = {
			var_0_19[1],
			var_0_19[2],
			var_0_19[3],
			var_0_19[4]
		}
		local var_3_2 = var_0_2.weightedChoise(var_3_1)

		if arg_3_0:JudgeIfWinning(var_3_0) then
			arg_3_0.GreenPriceState = var_3_2
			arg_3_0.GreenPriceCount[var_3_2] = arg_3_0.GreenPriceCount[var_3_2] + 1
		else
			arg_3_0.GreenPriceState = 0
		end
	elseif var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_3 = {
			var_0_20[1],
			var_0_20[2],
			var_0_20[3]
		}
		local var_3_4 = var_0_2.weightedChoise(var_3_3)

		if arg_3_0:JudgeIfWinning(var_3_0) then
			arg_3_0.BluePriceState = var_3_4
		else
			arg_3_0.BluePriceState = 0
		end
	elseif var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_3_5 = {
			var_0_21[1],
			var_0_21[2],
			var_0_21[3]
		}
		local var_3_6 = var_0_2.weightedChoise(var_3_5)

		if arg_3_0:JudgeIfWinning(var_3_0) then
			arg_3_0.EnergyPriceState = var_3_6
		else
			arg_3_0.EnergyPriceState = 0
		end
	end

	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.skillID
	local var_4_1 = arg_4_1.target

	if var_4_0 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_4_0.GreenPriceState and arg_4_0.GreenPriceState > 0 and arg_4_0.GreenPriceCount[arg_4_0.GreenPriceState] == 1 then
			local var_4_2 = var_0_15[arg_4_0.GreenPriceState]
			local var_4_3 = arg_4_0:createAttackUnits({
				var_4_1
			}, var_4_2)

			for iter_4_0, iter_4_1 in ipairs(var_4_3) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		elseif arg_4_0.GreenPriceState and arg_4_0.GreenPriceState > 0 and arg_4_0.GreenPriceCount[arg_4_0.GreenPriceState] > 1 then
			local var_4_4 = var_0_16[arg_4_0.GreenPriceState]
			local var_4_5 = arg_4_0:createAttackUnits({
				var_4_1
			}, var_4_4)

			for iter_4_2, iter_4_3 in ipairs(var_4_5) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end
		end
	elseif var_4_0 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_4_0.BluePriceState and arg_4_0.BluePriceState > 0 then
			local var_4_6 = var_0_17[arg_4_0.BluePriceState]
			local var_4_7 = arg_4_0:createAttackUnits({
				var_4_1
			}, var_4_6)

			for iter_4_4, iter_4_5 in ipairs(var_4_7) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
				table.insert(arg_4_0.records_.special_units, iter_4_5)
			end
		end
	elseif var_4_0 == var_0_22 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_0.EnergyPriceState and arg_4_0.EnergyPriceState > 0 then
		local var_4_8 = var_0_18[arg_4_0.EnergyPriceState]
		local var_4_9 = arg_4_0:createAttackUnits({
			var_4_1
		}, var_4_8)

		for iter_4_6, iter_4_7 in ipairs(var_4_9) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
			table.insert(arg_4_0.records_.special_units, iter_4_7)
		end
	end

	if var_4_0 == var_0_18[3] then
		arg_4_0:removeGoodBuff(var_4_1)
	end
end

function var_0_3.removeGoodBuff(arg_5_0, arg_5_1)
	for iter_5_0 = #arg_5_1.buffs_, 1, -1 do
		local var_5_0 = arg_5_1.buffs_[iter_5_0]

		if var_5_0 and var_5_0:getBuffForm() == var_0_2.BuffForm.GAIN and var_5_0:canRemove() and var_5_0.leftCount_ < 3000 then
			arg_5_1:removeBuffs(var_5_0)
		end
	end
end

function var_0_3.JudgeIfWinning(arg_6_0, arg_6_1)
	local var_6_0 = 0

	if arg_6_1 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		var_6_0 = var_0_11 + var_0_12 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)
	elseif arg_6_1 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		var_6_0 = var_0_13 + var_0_14 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
	elseif arg_6_1 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		var_6_0 = var_0_9 + var_0_10 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
	end

	if var_0_2.weightedChoise({
		var_6_0,
		1 - var_6_0
	}) == 1 or arg_6_0.loseLotteryTimes >= 2 then
		arg_6_0.loseLotteryTimes = 0
		arg_6_0.isGetPrice = true

		return true
	end

	arg_6_0.loseLotteryTimes = arg_6_0.loseLotteryTimes + 1

	return false
end

return var_0_3
