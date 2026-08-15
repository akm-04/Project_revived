local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhaozilong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = 150
local var_0_7 = {
	20010138,
	20010139,
	20010140
}
local var_0_8 = {
	20010135,
	20010136,
	20010137
}
local var_0_9 = 10010062
local var_0_10 = {
	40012396,
	40012397,
	40012398,
	40012399
}
local var_0_11 = 10010102
local var_0_12 = 80010062
local var_0_13 = 1

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleCount = 0
	arg_1_0.purpleSkill = false
	arg_1_0.count = false
	arg_1_0.purpleBuff = nil
	arg_1_0.nextPurpleBuffIndex = 1
	arg_1_0.currentPurpleBuffID = nil
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if not arg_2_0.count then
		arg_2_0.count = true

		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_2_0.purpleSkill = true
			arg_2_0.extraXixue = var_0_5:init(var_0_8[1]) + var_0_5:step(var_0_8[1]) * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
			arg_2_0.extraHarm = var_0_5:init(var_0_8[2]) + var_0_5:step(var_0_8[2]) * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
			arg_2_0.extraMpDamage = var_0_5:init(var_0_8[3]) + var_0_5:step(var_0_8[3]) * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		end
	end

	if arg_2_0:acttionInBlack() and arg_2_0.purpleSkill and not arg_2_0:isDeath() then
		if arg_2_0.purpleCount % var_0_6 == 0 then
			arg_2_0:changePurpleBuff()
		end

		arg_2_0.purpleCount = arg_2_0.purpleCount + 1
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getPugongID() and arg_3_0.skinSkillIndex_ == 1 and var_0_2.weightedChoise({
		var_0_13,
		1 - var_0_13
	}) == 1 then
		local var_3_0 = math.random(#var_0_10)
		local var_3_1 = var_0_10[var_3_0]
		local var_3_2 = arg_3_0:createNewBuffs({
			var_3_1
		}, arg_3_1.target, arg_3_1.skillID)

		arg_3_1.target:addBuffs(var_3_2)
	end
end

function var_0_3.calculateUnitData(arg_4_0, arg_4_1)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.calculateUnitData(arg_4_0, arg_4_1)

	if arg_4_0.currentPurpleBuffID and (arg_4_1.skillID ~= var_0_9 or arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0) then
		if arg_4_0.currentPurpleBuffID == var_0_7[1] then
			var_4_4 = var_4_4 + arg_4_0.extraXixue
		elseif arg_4_0.currentPurpleBuffID == var_0_7[2] and var_4_2 > 0 then
			var_4_2 = var_4_2 + arg_4_0.extraHarm
		elseif arg_4_0.currentPurpleBuffID == var_0_7[3] then
			var_4_5 = var_4_5 + arg_4_0.extraMpDamage
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	if arg_5_0.skinSkillIndex_ == 1 and (arg_5_1:getType() == var_0_2.BuffType.MOVE_SKILL_LIMIT or arg_5_1:getType() == var_0_2.BuffType.MOVE or arg_5_1:getTableID() == var_0_11) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_0
		}, var_0_12)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end
end

function var_0_3.changePurpleBuff(arg_6_0)
	local function var_6_0(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
		local var_7_0 = var_0_4.new({
			tableID = arg_7_0,
			start = var_0_1.ctx.battle.count,
			level = arg_7_2,
			skillID = arg_7_1,
			fighter = arg_6_0,
			target = arg_7_3
		})

		return {
			var_7_0
		}
	end

	if arg_6_0.purpleBuff then
		arg_6_0:removeBuffs(arg_6_0.purpleBuff[1])
	end

	local var_6_1 = var_0_7[var_0_0.table.keys(var_0_7)[arg_6_0.nextPurpleBuffIndex]]
	local var_6_2 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_6_3 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	arg_6_0.currentPurpleBuffID = var_6_1
	arg_6_0.nextPurpleBuffIndex = arg_6_0.nextPurpleBuffIndex + 1

	if arg_6_0.nextPurpleBuffIndex == #var_0_7 + 1 then
		arg_6_0.nextPurpleBuffIndex = 1
	end

	arg_6_0.purpleBuff = var_6_0(var_6_1, var_6_2, var_6_3, arg_6_0)

	arg_6_0:addBuffs(arg_6_0.purpleBuff)
end

return var_0_3
