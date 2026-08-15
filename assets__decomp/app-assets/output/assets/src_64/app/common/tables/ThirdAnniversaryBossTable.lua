local var_0_0 = class("ThirdAnniversaryBossTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.battleID_ = {}
	arg_1_0.stage1_ = {}
	arg_1_0.stage2_ = {}
	arg_1_0.stage3_ = {}

	import("app.common.tables.TableParser").parse("activity_anniversary_boss.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.battleID_[var_2_0] = tonumber(arg_2_0.battle_id)
		arg_1_0.stage1_[var_2_0] = tonumber(arg_2_0.stage_one_monster)
		arg_1_0.stage2_[var_2_0] = tonumber(arg_2_0.stage_two_monster)
		arg_1_0.stage3_[var_2_0] = tonumber(arg_2_0.stage_three_monster)
	end)
end

function var_0_0.battleID(arg_3_0, arg_3_1)
	return arg_3_0.battleID_[arg_3_1] or 0
end

function var_0_0.stage1(arg_4_0, arg_4_1)
	return arg_4_0.stage1_[arg_4_1] or 0
end

function var_0_0.stage2(arg_5_0, arg_5_1)
	return arg_5_0.stage2_[arg_5_1] or 0
end

function var_0_0.stage3(arg_6_0, arg_6_1)
	return arg_6_0.stage3_[arg_6_1] or 0
end

return var_0_0
