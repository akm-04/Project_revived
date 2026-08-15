local var_0_0 = class("ActivityDecodeRewardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.numRequired_ = {}
	arg_1_0.content_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.num_ = {}

	import("app.common.tables.TableParser").parse("activity_decode_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.numRequired_[var_2_0] = xyd.splitToNumber(arg_2_0.num_required, "|")
		arg_1_0.content_[var_2_0] = xyd.splitToNumber(arg_2_0.content, "|")
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.num_[var_2_0] = xyd.splitToNumber(arg_2_0.num, "|")
	end)
end

function var_0_0.numRequired(arg_3_0, arg_3_1)
	return arg_3_0.numRequired_[arg_3_1] or {}
end

function var_0_0.content(arg_4_0, arg_4_1)
	return arg_4_0.content_[arg_4_1] or {}
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or ""
end

function var_0_0.num(arg_6_0, arg_6_1)
	return arg_6_0.num_[arg_6_1] or {}
end

return var_0_0
