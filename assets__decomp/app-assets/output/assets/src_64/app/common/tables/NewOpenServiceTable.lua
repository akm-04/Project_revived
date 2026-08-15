local var_0_0 = class("NewOpenServiceTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.day_ = {}
	arg_1_0.type_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.req_ = {}

	import("app.common.tables.TableParser").parse("activity_openserver_new.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.day_[var_2_0] = tonumber(arg_2_0.day)
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.req_[var_2_0] = tonumber(arg_2_0.req)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1]
end

function var_0_0._type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1]
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1]
end

function var_0_0.req(arg_6_0, arg_6_1)
	return arg_6_0.req_[arg_6_1]
end

function var_0_0.day(arg_7_0, arg_7_1)
	return arg_7_0.day_[arg_7_1]
end

return var_0_0
