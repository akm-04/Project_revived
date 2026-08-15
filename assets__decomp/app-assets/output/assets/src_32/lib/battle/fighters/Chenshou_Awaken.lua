local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chenshou", var_0_1.ctx.battle.requireFighter("Chenshou"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.AwakeSkillID = 10002266
	else
		arg_2_0.AwakeSkillID = 60010221
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if arg_3_0:isDeath() then
		return
	end

	for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("attack_info")) do
		if iter_3_1.rootID_ == iter_3_1.fighter_:getEnergySkillID() and iter_3_1.fighter_:getTeamType() ~= arg_3_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_0 = arg_3_0:createAttackUnits({
				arg_3_0
			}, arg_3_0.AwakeSkillID)

			for iter_3_2, iter_3_3 in ipairs(var_3_0) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end
	end
end

return var_0_3
