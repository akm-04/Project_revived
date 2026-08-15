local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseWenchou", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model

function var_0_3.updateHp(arg_1_0, arg_1_1, arg_1_2)
	if not arg_1_0.opposeNpc then
		var_0_3.super.updateHp(arg_1_0, arg_1_1, arg_1_2)

		return
	end

	if arg_1_1 > arg_1_0:getHp() then
		arg_1_0.opposeNpc:removePurpleBuff()
	end

	var_0_3.super.updateHp(arg_1_0, arg_1_1, arg_1_2)

	if arg_1_0:getHp() >= arg_1_0:getHpLimit() then
		arg_1_0.opposeNpc:addHarmBuff()
	end
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count % 10 == 0 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if not iter_2_1:isDeath() and iter_2_1:getSummonType() == var_0_2.summonMonsterType.None and iter_2_1 ~= arg_2_0 then
				return
			end
		end

		arg_2_0:updateHp(0)
		arg_2_0:die()
	end
end

return var_0_3
