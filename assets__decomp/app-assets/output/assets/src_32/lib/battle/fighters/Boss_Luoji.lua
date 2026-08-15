local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Luoji", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 240
local var_0_7 = 40011870
local var_0_8 = 40011871
local var_0_9 = 0.1
local var_0_10 = 10001741
local var_0_11 = 10001744
local var_0_12 = 10001742
local var_0_13 = 10001743
local var_0_14 = {
	40011870,
	40011871
}
local var_0_15 = 0.25
local var_0_16 = {
	40011869,
	40011872,
	40011873
}
local var_0_17 = 810005
local var_0_18 = 40012257

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleCount = var_0_6

	arg_1_0:listenInfo("harm_info")

	arg_1_0.purpleHarmFighter = {}
end

function var_0_3.isSuper(arg_2_0)
	return true
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0.purpleCount <= 0 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("harm_info")) do
			local var_3_0 = iter_3_1.harm
			local var_3_1 = iter_3_1.fighter

			if not var_3_1:isDeath() and var_3_1:getTeamType() == arg_3_0:getTeamType() and var_3_0 >= var_3_1:getHpLimit() * var_0_9 then
				local var_3_2 = arg_3_0:createNewBuffs({
					var_0_7
				}, var_3_1, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				var_3_1:addBuffs(var_3_2)

				arg_3_0.purpleCount = var_0_6
			end
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_3_0.purpleCount = arg_3_0.purpleCount - 1
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_0 = var_0_10
			local var_4_1 = var_0_5:selectType(var_4_0)
			local var_4_2 = var_0_4[var_4_1](arg_4_0, var_4_0)
			local var_4_3 = arg_4_0:createAttackUnits(var_4_2, var_4_0)

			for iter_4_0, iter_4_1 in ipairs(var_4_3) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end

			local var_4_4 = var_0_11
			local var_4_5 = var_0_5:selectType(var_4_4)
			local var_4_6 = var_0_4[var_4_5](arg_4_0, var_4_4)
			local var_4_7 = arg_4_0:createAttackUnits(var_4_6, var_4_4)

			for iter_4_2, iter_4_3 in ipairs(var_4_7) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end
		end

		if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_8 = var_0_12
				local var_4_9 = var_0_5:selectType(var_4_8)
				local var_4_10 = var_0_4[var_4_9](arg_4_0, var_4_8)
				local var_4_11 = arg_4_0:createAttackUnits(var_4_10, var_4_8)

				for iter_4_4, iter_4_5 in ipairs(var_4_11) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
					table.insert(arg_4_0.records_.special_units, iter_4_5)
				end
			end

			local var_4_12 = arg_4_1.target:getBuffs()

			for iter_4_6, iter_4_7 in ipairs(var_4_12) do
				if iter_4_7:getBuffForm() == var_0_2.BuffForm.GAIN and iter_4_7:canRemove() then
					arg_4_1.target:removeBuffByID(iter_4_7:getTableID())
				end
			end
		end

		if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_13 = var_0_13
			local var_4_14 = var_0_5:selectType(var_4_13)
			local var_4_15 = var_0_4[var_4_14](arg_4_0, var_4_13)
			local var_4_16 = arg_4_0:createAttackUnits(var_4_15, var_4_13)

			for iter_4_8, iter_4_9 in ipairs(var_4_16) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_9)
				table.insert(arg_4_0.records_.special_units, iter_4_9)
			end
		end
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	if arg_5_0.skinSkillID_ == var_0_17 then
		if not arg_5_1.target:isHasBuffByID(var_0_18) and var_0_0.table.indexof(var_0_16, arg_5_1:getTableID()) then
			local var_5_0 = arg_5_0:createNewBuffs({
				var_0_18
			}, arg_5_1.target, var_0_17)

			arg_5_1.target:addBuffs(var_5_0)
		elseif var_0_0.table.indexof(var_0_14, arg_5_1:getTableID()) then
			arg_5_1.manualDharm = arg_5_1:totalDHarm() * var_0_15
		end
	end
end

return var_0_3
