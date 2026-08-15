local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lvlingqi", var_0_1.ctx.battle.requireFighter("Lvlingqi"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = 0.002
local var_0_7 = 0.2
local var_0_8 = 40010655

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energySkillTime = 0
	arg_1_0.records_.awaken_add_buff = {}
	arg_1_0.nAwakenBuffs = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:getBuffByID(var_0_8) == nil then
		arg_2_0.nAwakenBuffs = 0
	end
end

function var_0_3.getUnitData(arg_3_0, arg_3_1)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.getUnitData(arg_3_0, arg_3_1)

	if var_3_1 and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		extraHarm = math.min(5, arg_3_0.nAwakenBuffs) * arg_3_1.basicHarm * 0.1
		var_3_2 = var_3_2 + extraHarm

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_6 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_3_0, iter_3_1 in ipairs(var_3_6) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.addAwakenBuff(arg_4_0)
	if arg_4_0:getBuffByID(var_0_8) then
		local var_4_0 = arg_4_0:getBuffByID(var_0_8)
		local var_4_1 = var_4_0.leftCount_

		var_4_0:setExtraTime(var_4_1)

		local var_4_2 = var_0_5:dHarm(var_0_8) + var_4_0:getLevel() * var_4_0:stepHarm()

		var_4_0.dHarm_ = var_4_0.dHarm_ + var_4_2
		arg_4_0.nAwakenBuffs = arg_4_0.nAwakenBuffs + 1
	else
		local var_4_3 = arg_4_0:newBuff({
			var_0_8
		}, arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_4_0:addBuffs(var_4_3)

		arg_4_0.nAwakenBuffs = 1
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

	if var_5_0 > 0 then
		local var_5_1 = false

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_5_0.awakenAddBuff[tostring(var_0_1.ctx.battle.count)] then
				var_5_1 = true
			end
		else
			local var_5_2 = var_0_6 * var_5_0 + var_0_7
			local var_5_3 = math.min(1, var_5_2)

			var_5_1 = var_0_2.weightedChoise({
				var_5_3,
				1 - var_5_3
			}) == 1

			if var_5_1 then
				arg_5_0.records_.awaken_add_buff[tostring(var_0_1.ctx.battle.count)] = 1
			end
		end

		if var_5_1 then
			arg_5_0:addAwakenBuff()
		end
	end
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_4.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByID(arg_6_3),
			skillID = arg_6_3,
			fighter = arg_6_0,
			target = arg_6_2
		})

		var_6_1:setIsHit(true)
		var_6_1:setDirection(arg_6_0:getFighterModel():getFlipX())
		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.setupReport(arg_7_0, arg_7_1)
	var_0_3.super.setupReport(arg_7_0, arg_7_1)

	arg_7_0.awakenAddBuff = arg_7_1.awaken_add_buff
end

function var_0_3.writeReport(arg_8_0)
	local var_8_0 = var_0_3.super.writeReport(arg_8_0)

	var_8_0.awaken_add_buff = arg_8_0.records_.awaken_add_buff

	return var_8_0
end

return var_0_3
