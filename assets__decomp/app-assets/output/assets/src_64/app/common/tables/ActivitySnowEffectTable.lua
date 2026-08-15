local var_0_0 = class("ActivitySnowEffectTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.reqType_ = {}
	arg_1_0.req_ = {}
	arg_1_0.reqDesc_ = {}
	arg_1_0.buff_ = {}

	import("app.common.tables.TableParser").parse("activity_snowman_effect.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.reqType_[var_2_0] = tonumber(arg_2_0.req_type)
		arg_1_0.req_[var_2_0] = tonumber(arg_2_0.req)
		arg_1_0.reqDesc_[var_2_0] = arg_2_0.req_desc
		arg_1_0.buff_[var_2_0] = tonumber(arg_2_0.buff)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.reqType(arg_5_0, arg_5_1)
	return arg_5_0.reqType_[arg_5_1] or 0
end

function var_0_0.req(arg_6_0, arg_6_1)
	return arg_6_0.req_[arg_6_1] or 0
end

function var_0_0.reqDesc(arg_7_0, arg_7_1)
	return arg_7_0.reqDesc_[arg_7_1] or ""
end

function var_0_0.buff(arg_8_0, arg_8_1)
	return arg_8_0.buff_[arg_8_1] or 0
end

return var_0_0
