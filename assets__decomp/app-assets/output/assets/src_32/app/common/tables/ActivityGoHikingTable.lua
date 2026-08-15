local var_0_0 = class("ActivityGoHikingTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gift_id_ = {}
	arg_1_0.reward_times_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.dir_ = {}
	arg_1_0.desc_ = {}

	import("app.common.tables.TableParser").parse("activity_sakura_outing.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_id_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.reward_times_[var_2_0] = tonumber(arg_2_0.reward_times)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.dir_[var_2_0] = tonumber(arg_2_0.dir)
		arg_1_0.desc_[var_2_0] = arg_2_0.des
	end)
end

function var_0_0.getDesc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or nil
end

function var_0_0.giftid(arg_4_0, arg_4_1)
	return arg_4_0.gift_id_[arg_4_1] or 0
end

function var_0_0.rewardTimes(arg_5_0, arg_5_1)
	return arg_5_0.reward_times_[arg_5_1] or 0
end

function var_0_0.getIcon(arg_6_0, arg_6_1)
	return arg_6_0.icon_[arg_6_1] or nil
end

function var_0_0.dir(arg_7_0, arg_7_1)
	return arg_7_0.dir_[arg_7_1] or 0
end

function var_0_0.tableLength(arg_8_0)
	return #arg_8_0.gift_id_
end

return var_0_0
