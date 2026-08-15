local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiuwei", var_0_1.ctx.battle.requireFighter("ProphesyBoss"))
local var_0_4 = var_0_2.tables.dbuff

function var_0_3.addBuffs(arg_1_0, arg_1_1)
	local var_1_0 = {}

	for iter_1_0, iter_1_1 in ipairs(arg_1_1) do
		if var_0_4:attr(iter_1_1:getTableID()) ~= var_0_2.AttributeType.SPEED and var_0_4:attr(iter_1_1:getTableID()) ~= var_0_2.AttributeType.ACK_SPEED and not iter_1_1:isFear() and not iter_1_1:isApUnable() and not iter_1_1:isAdUnable() and not iter_1_1:isExcuteAdCircle() and not iter_1_1:isAttackFriend() then
			table.insert(var_1_0, iter_1_1)
		end
	end

	var_0_3.super.addBuffs(arg_1_0, var_1_0)
end

function var_0_3.applyUnitBuffs(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6)
	var_0_3.super.applyUnitBuffs(arg_2_0, arg_2_1, arg_2_2)
end

function var_0_3.checkSkillBreak(arg_3_0, arg_3_1)
	return
end

function var_0_3.checkKilling(arg_4_0, arg_4_1)
	return
end

function var_0_3.isAdBreakImmortal(arg_5_0)
	return true
end

return var_0_3
