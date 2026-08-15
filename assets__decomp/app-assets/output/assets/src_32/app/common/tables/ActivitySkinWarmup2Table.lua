local var_0_0 = class("ActivitySkinWarmup2Table")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.reqType_ = {}
	arg_1_0.req_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.discount_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_skin_warmup2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.reqType_[var_2_0] = tonumber(arg_2_0.req_type)
		arg_1_0.req_[var_2_0] = tonumber(arg_2_0.req)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.discount_[var_2_0] = tonumber(arg_2_0.discount)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or 0
end

function var_0_0.reqType(arg_4_0, arg_4_1)
	return arg_4_0.reqType_[arg_4_1] or 0
end

function var_0_0.req(arg_5_0, arg_5_1)
	return arg_5_0.req_[arg_5_1] or 0
end

function var_0_0.desc(arg_6_0, arg_6_1)
	return arg_6_0.desc_[arg_6_1] or ""
end

function var_0_0.discount(arg_7_0, arg_7_1)
	return arg_7_0.discount_[arg_7_1] or 0
end

function var_0_0.gift(arg_8_0, arg_8_1)
	return arg_8_0.gift_[arg_8_1] or 0
end

function var_0_0.getIds(arg_9_0)
	return table.keys(arg_9_0.type_)
end

return var_0_0
