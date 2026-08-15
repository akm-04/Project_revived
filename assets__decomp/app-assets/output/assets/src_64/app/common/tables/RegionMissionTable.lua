local var_0_0 = class("RegionMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.taskReq_ = {}
	arg_1_0.taskNum_ = {}
	arg_1_0.kingCoin_ = {}
	arg_1_0.weight_ = {}
	arg_1_0.icon_ = {}

	import("app.common.tables.TableParser").parse("region_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.taskReq_[var_2_0] = tonumber(arg_2_0.task_req)
		arg_1_0.taskNum_[var_2_0] = tonumber(arg_2_0.task_num)
		arg_1_0.kingCoin_[var_2_0] = tonumber(arg_2_0.king_coin)
		arg_1_0.weight_[var_2_0] = tonumber(arg_2_0.weight)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.taskReq(arg_4_0, arg_4_1)
	return arg_4_0.taskReq_[arg_4_1] or 0
end

function var_0_0.taskNum(arg_5_0, arg_5_1)
	return arg_5_0.taskNum_[arg_5_1] or 0
end

function var_0_0.icon(arg_6_0, arg_6_1)
	return arg_6_0.icon_[arg_6_1] or ""
end

function var_0_0.kingCoin(arg_7_0, arg_7_1)
	return arg_7_0.kingCoin_[arg_7_1] or ""
end

function var_0_0.weight(arg_8_0, arg_8_1)
	return arg_8_0.weight_[arg_8_1] or ""
end

return var_0_0
