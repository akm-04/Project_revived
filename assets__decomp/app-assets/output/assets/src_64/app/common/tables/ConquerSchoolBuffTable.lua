local var_0_0 = class("ConquerSchoolBuffTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.buff_ = {}
	arg_1_0.buffDesc_ = {}
	arg_1_0.buffIcon_ = {}

	import("app.common.tables.TableParser").parse("conquer_school_buff.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.buff_[var_2_0] = xyd.splitToNumber(arg_2_0.buff, "|")
		arg_1_0.buffDesc_[var_2_0] = arg_2_0.buff_desc
		arg_1_0.buffIcon_[var_2_0] = arg_2_0.buff_icon
	end)
end

function var_0_0.buff(arg_3_0, arg_3_1)
	return arg_3_0.buff_[arg_3_1] or {}
end

function var_0_0.buffDesc(arg_4_0, arg_4_1)
	return arg_4_0.buffDesc_[arg_4_1] or ""
end

function var_0_0.buffIcon(arg_5_0, arg_5_1)
	return arg_5_0.buffIcon_[arg_5_1] or ""
end

return var_0_0
