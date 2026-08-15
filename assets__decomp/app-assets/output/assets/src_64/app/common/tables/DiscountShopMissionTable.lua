local var_0_0 = class("DiscountShopMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.task_num_ = {}
	arg_1_0.gift_ = {}

	local var_1_0 = 1

	import("app.common.tables.TableParser").parse("activity_sp_shop_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_1_0] = var_2_0
		var_1_0 = var_1_0 + 1
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.task_num_[var_2_0] = tonumber(arg_2_0.task_num)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.Desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.taskNum(arg_5_0, arg_5_1)
	return arg_5_0.task_num_[arg_5_1] or ""
end

function var_0_0.gift(arg_6_0, arg_6_1)
	return arg_6_0.gift_[arg_6_1] or ""
end

return var_0_0
