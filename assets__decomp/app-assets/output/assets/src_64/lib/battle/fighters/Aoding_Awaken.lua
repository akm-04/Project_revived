local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Aoding", var_0_1.ctx.battle.requireFighter("Aoding"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 60010258
local var_0_6 = 10002307
local var_0_7 = 40012499
local var_0_8 = {
	40012743,
	40012744,
	40012751
}
local var_0_9 = 400
local var_0_10 = 40012745

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.lastEnergyTarget = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = var_0_5
		local var_2_1 = arg_2_0:createAttackUnits({
			arg_2_0
		}, var_2_0)

		for iter_2_0, iter_2_1 in ipairs(var_2_1) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

function var_0_3.buffRemoveAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_7 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = var_0_6
		local var_3_1 = arg_3_0:createAttackUnits({
			arg_3_0
		}, var_3_0)

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_4_1.skillID == arg_4_0:getEnergySkillID() then
		local var_4_0 = arg_4_0:createNewBuffs(var_0_8, arg_4_1.target, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		arg_4_1.target:addBuffs(var_4_0)

		if arg_4_0.lastEnergyTarget and arg_4_0.lastEnergyTarget == arg_4_1.target then
			local var_4_1 = arg_4_1.target

			for iter_4_0, iter_4_1 in ipairs(arg_4_0.targetTeam_) do
				if iter_4_1 ~= arg_4_0 and not iter_4_1:isAffected() and not iter_4_1:isDeath() and math.abs(iter_4_1:getX() - var_4_1:getX()) < var_0_9 / 2 then
					local var_4_2 = arg_4_0:createNewBuffs({
						var_0_10
					}, iter_4_1, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

					iter_4_1:addBuffs(var_4_2)
				end
			end
		else
			arg_4_0.lastEnergyTarget = arg_4_1.target
		end
	end
end

return var_0_3
