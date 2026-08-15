local var_0_0 = class("ActivityVoteTimelineTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.longDes_ = {}
	arg_1_0.des_ = {}
	arg_1_0.time_ = {}
	arg_1_0.isChooseFav_ = {}
	arg_1_0.isShowSuper_ = {}

	import("app.common.tables.TableParser").parse("activity_vote_timeline", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.longDes_[var_2_0] = arg_2_0.long_des
		arg_1_0.des_[var_2_0] = arg_2_0.des
		arg_1_0.time_[var_2_0] = xyd.splitToNumber(arg_2_0.time, "|")
		arg_1_0.isChooseFav_[var_2_0] = tonumber(arg_2_0.is_choose_fav)
		arg_1_0.isShowSuper_[var_2_0] = tonumber(arg_2_0.is_show_super)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.longDes(arg_5_0, arg_5_1)
	return arg_5_0.longDes_[arg_5_1] or ""
end

function var_0_0.des(arg_6_0, arg_6_1)
	return arg_6_0.des_[arg_6_1] or ""
end

function var_0_0.time(arg_7_0, arg_7_1)
	return arg_7_0.time_[arg_7_1] or {}
end

function var_0_0.isChooseFav(arg_8_0, arg_8_1)
	return arg_8_0.isChooseFav_[arg_8_1] or 0
end

function var_0_0.isShowSuper(arg_9_0, arg_9_1)
	return arg_9_0.isShowSuper_[arg_9_1] or 0
end

function var_0_0.getStage(arg_10_0, arg_10_1)
	for iter_10_0 = 1, #arg_10_0.ids_ do
		local var_10_0 = arg_10_0.ids_[iter_10_0]
		local var_10_1 = arg_10_0:time(var_10_0)

		if #var_10_1 == 2 and arg_10_1 > var_10_1[1] and arg_10_1 <= var_10_1[2] then
			return var_10_0
		end
	end

	return 0
end

return var_0_0
