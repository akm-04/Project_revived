local var_0_0 = class("AvartarMallActivityTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.discountType_ = {}
	arg_1_0.actId_ = {}
	arg_1_0.info_ = {}

	import("app.common.tables.TableParser").parse("avartar_mall_activity.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.discount_type)

		arg_1_0.discountType_[var_2_0] = tonumber(arg_2_0.discount_type)
		arg_1_0.actId_[var_2_0] = tonumber(arg_2_0.act_id)
		arg_1_0.info_[var_2_0] = arg_2_0.info
	end)
end

function var_0_0.discountType(arg_3_0, arg_3_1)
	return arg_3_0.discountType_[arg_3_1] or 0
end

function var_0_0.actId(arg_4_0, arg_4_1)
	return arg_4_0.actId_[arg_4_1] or 0
end

function var_0_0.info(arg_5_0, arg_5_1)
	return arg_5_0.info_[arg_5_1] or ""
end

return var_0_0
