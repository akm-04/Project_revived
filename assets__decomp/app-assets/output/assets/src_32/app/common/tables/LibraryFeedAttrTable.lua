local var_0_0 = class("LibraryFeedAttrTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.attrType_ = {}
	arg_1_0.incrSpan_ = {}
	arg_1_0.decrSpan_ = {}
	arg_1_0.attrLimit_ = {}

	import("app.common.tables.TableParser").parse("library_feed_attr.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.attrType_[var_2_0] = tonumber(arg_2_0.attr_type)
		arg_1_0.incrSpan_[var_2_0] = xyd.splitToNumber(arg_2_0.incr_span, "|")
		arg_1_0.decrSpan_[var_2_0] = xyd.splitToNumber(arg_2_0.decr_span, "|")
		arg_1_0.attrLimit_[var_2_0] = tonumber(arg_2_0.attr_limit)
	end)
end

function var_0_0.attrType(arg_3_0, arg_3_1)
	return arg_3_0.attrType_[arg_3_1] or 0
end

function var_0_0.incrSpan(arg_4_0, arg_4_1)
	return arg_4_0.incrSpan_[arg_4_1] or {}
end

function var_0_0.decrSpan(arg_5_0, arg_5_1)
	return arg_5_0.decrSpan_[arg_5_1] or {}
end

function var_0_0.attrLimit(arg_6_0, arg_6_1)
	return arg_6_0.attrLimit_[arg_6_1] or 0
end

return var_0_0
