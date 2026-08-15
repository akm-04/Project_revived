local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("IncubusMonsterTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.leftMonster_ = {}
	arg_1_0.rightMonster_ = {}
	arg_1_0.leftBoss_ = {}
	arg_1_0.rightBoss_ = {}
	arg_1_0.time_ = {}

	import("app.common.tables.TableParser").parse("incubus_monster.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.leftMonster_[var_2_0] = var_0_1.splitToNumber(arg_2_0.l_monster, "|")
		arg_1_0.rightMonster_[var_2_0] = var_0_1.splitToNumber(arg_2_0.r_monster, "|")
		arg_1_0.leftBoss_[var_2_0] = tonumber(arg_2_0.l_boss) or 0
		arg_1_0.rightBoss_[var_2_0] = tonumber(arg_2_0.r_boss) or 0
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
	end)
	import("app.common.tables.TableParser").parse("bloodline_incubus_monster.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.id)

		arg_1_0.leftMonster_[var_3_0] = var_0_1.splitToNumber(arg_3_0.l_monster, "|")
		arg_1_0.rightMonster_[var_3_0] = var_0_1.splitToNumber(arg_3_0.r_monster, "|")
		arg_1_0.time_[var_3_0] = tonumber(arg_3_0.time)
	end)
end

function var_0_2.getType(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_2.leftMonster(arg_5_0, arg_5_1)
	return arg_5_0.leftMonster_[arg_5_1] or {}
end

function var_0_2.rightMonster(arg_6_0, arg_6_1)
	return arg_6_0.rightMonster_[arg_6_1] or {}
end

function var_0_2.leftBoss(arg_7_0, arg_7_1)
	return arg_7_0.leftBoss_[arg_7_1] or 0
end

function var_0_2.rightBoss(arg_8_0, arg_8_1)
	return arg_8_0.rightBoss_[arg_8_1] or 0
end

function var_0_2.getTime(arg_9_0, arg_9_1)
	return arg_9_0.time_[arg_9_1] or 0
end

return var_0_2
