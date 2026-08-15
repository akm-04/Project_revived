local var_0_0 = class("ActivitySkinConsumeSetTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.consume_ = {}
	arg_1_0.exclude_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.vipLimit_ = {}

	import("app.common.tables.TableParser").parse("activity_skin_consume_set.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.consume_[var_2_0] = tonumber(arg_2_0.consume)
		arg_1_0.exclude_[var_2_0] = xyd.splitToNumber(arg_2_0.exclude, "|")
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.vipLimit_[var_2_0] = tonumber(arg_2_0.vip_limit)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.consume(arg_4_0, arg_4_1)
	return arg_4_0.consume_[arg_4_1] or 0
end

function var_0_0.exclude(arg_5_0, arg_5_1)
	return arg_5_0.exclude_[arg_5_1] or {}
end

function var_0_0.gift(arg_6_0, arg_6_1)
	return arg_6_0.gift_[arg_6_1] or 0
end

function var_0_0.vipLimit(arg_7_0, arg_7_1)
	return arg_7_0.vipLimit_[arg_7_1] or 0
end

return var_0_0
