local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Buzhi", var_0_1.ctx.battle.requireFighter("Buzhi"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40011501

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("unit_info")
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_0 = arg_2_0:createAttackUnits({
				arg_2_0
			}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_2_0, iter_2_1 in ipairs(var_2_0) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end

		arg_2_1.target:addBuffs(arg_2_0:newBuff({
			var_0_6
		}, arg_2_1.target, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)))
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if not arg_3_0:isDeath() then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("unit_info")) do
			local var_3_0 = iter_3_1.target
			local var_3_1 = var_3_0:getBuffByID(var_0_6)

			if var_3_1 and var_3_1.fighter == arg_3_0 and iter_3_1.attackType == var_0_2.AttackType.AP then
				var_3_0:removeBuffs(var_3_1)

				break
			end
		end
	end
end

return var_0_3
