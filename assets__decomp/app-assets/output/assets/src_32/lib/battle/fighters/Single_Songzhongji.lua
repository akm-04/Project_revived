local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Songzhongji", var_0_1.ctx.battle.requireFighter("SingleBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = {
	10010169
}
local var_0_7 = 550

function var_0_3.selectTargetByTypeD1(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = {}

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.sideTeam_) do
		if not iter_1_1:isDeath() and not iter_1_1:isAffected() and iter_1_1.hero_:getDistance() <= var_0_7 then
			table.insert(var_1_0, iter_1_1)
		end
	end

	return var_1_0
end

function var_0_3.applyBuffHarms(arg_2_0)
	return
end

function var_0_3.checkSkillBreak(arg_3_0, arg_3_1)
	return
end

function var_0_3.addBuffs(arg_4_0, arg_4_1)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		if not iter_4_1:isFear() and not iter_4_1:isApUnable() and not iter_4_1:isAdUnable() and not iter_4_1:isExcuteAdCircle() and not iter_4_1:isAttackFriend() then
			table.insert(var_4_0, iter_4_1)
		end
	end

	var_0_3.super.addBuffs(arg_4_0, var_4_0)
end

return var_0_3
