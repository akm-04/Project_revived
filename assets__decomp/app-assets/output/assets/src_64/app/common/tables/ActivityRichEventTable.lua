local var_0_0 = class("ActivityRichEventTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.event_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.value_ = {}
	arg_1_0.canUseCard_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.descUnhappend_ = {}

	import("app.common.tables.TableParser").parse("activity_rich_event.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.event_[var_2_0] = arg_2_0.event
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.value_[var_2_0] = tonumber(arg_2_0.value)
		arg_1_0.canUseCard_[var_2_0] = tonumber(arg_2_0.can_use_card)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.descUnhappend_[var_2_0] = arg_2_0.desc_unhappend
	end)
end

function var_0_0.event(arg_3_0, arg_3_1)
	return arg_3_0.event_[arg_3_1] or ""
end

function var_0_0.rate(arg_4_0, arg_4_1)
	return arg_4_0.rate_[arg_4_1] or 0
end

function var_0_0.value(arg_5_0, arg_5_1)
	return arg_5_0.value_[arg_5_1] or 0
end

function var_0_0.canUseCard(arg_6_0, arg_6_1)
	return arg_6_0.canUseCard_[arg_6_1] or 0
end

function var_0_0.desc(arg_7_0, arg_7_1)
	return arg_7_0.desc_[arg_7_1] or ""
end

function var_0_0.descUnhappend(arg_8_0, arg_8_1)
	return arg_8_0.descUnhappend_[arg_8_1] or ""
end

return var_0_0
