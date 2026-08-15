local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Donghe", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 180
local var_0_6 = 40011835
local var_0_7 = 40011836
local var_0_8 = 40011837
local var_0_9 = 40011838
local var_0_10 = 10002347
local var_0_11 = 10002348
local var_0_12 = 40011834
local var_0_13 = 40011832
local var_0_14 = 80010234
local var_0_15 = {
	40012447,
	40012448
}
local var_0_16 = 5
local var_0_17 = 150

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleCount = 0
	arg_1_0.skinKongzhiCount = 0
	arg_1_0.skinDurationCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.skinSkillID_ == var_0_14 and arg_2_0.skinDurationCount > 0 then
		arg_2_0.skinDurationCount = arg_2_0.skinDurationCount - 1
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_2_0.purpleCount = arg_2_0.purpleCount - 1
	end
end

function var_0_3.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_4 > 0 and arg_3_0.purpleCount < 0 then
		arg_3_0.purpleCount = var_0_5

		if arg_3_1.attackType == var_0_2.AttackType.AD then
			arg_3_0:removeBuffByID(var_0_8)
			arg_3_0:removeBuffByID(var_0_9)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_0 = arg_3_0:createAttackUnits({
					arg_3_0
				}, var_0_10)

				for iter_3_0, iter_3_1 in ipairs(var_3_0) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
					table.insert(arg_3_0.records_.special_units, iter_3_1)
				end
			end
		elseif arg_3_1.attackType == var_0_2.AttackType.AP then
			arg_3_0:removeBuffByID(var_0_6)
			arg_3_0:removeBuffByID(var_0_7)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_1 = arg_3_0:createAttackUnits({
					arg_3_0
				}, var_0_11)

				for iter_3_2, iter_3_3 in ipairs(var_3_1) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			end
		end
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	if arg_4_0.skinSkillID_ == var_0_14 and arg_4_0.skinDurationCount == 0 and (arg_4_1:getTableID() == var_0_12 or arg_4_1:getTableID() == var_0_13) then
		arg_4_0.skinKongzhiCount = arg_4_0.skinKongzhiCount + 1

		local var_4_0 = arg_4_0:createNewBuffs(var_0_15, arg_4_0, var_0_14)

		arg_4_0:addBuffs(var_4_0)

		if arg_4_0.skinKongzhiCount == var_0_16 then
			arg_4_0.skinKongzhiCount = 0
			arg_4_0.skinDurationCount = var_0_17

			local var_4_1 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
			local var_4_2 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

			arg_4_0:createSkillByID(var_4_1, var_4_2, var_0_4:attackIndex(var_4_1))
		end
	end
end

return var_0_3
