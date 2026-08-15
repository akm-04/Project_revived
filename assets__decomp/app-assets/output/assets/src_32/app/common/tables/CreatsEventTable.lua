local var_0_0 = class("CreatsEventTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.eventDesc_ = {}
	arg_1_0.eventContent_ = {}

	import("app.common.tables.TableParser").parse("creats_event.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.eventDesc_[var_2_0] = arg_2_0.event_desc
		arg_1_0.eventContent_[var_2_0] = arg_2_0.event_content
	end)
end

function var_0_0.eventDesc(arg_3_0, arg_3_1)
	return arg_3_0.eventDesc_[arg_3_1] or ""
end

function var_0_0.eventContent(arg_4_0, arg_4_1)
	return arg_4_0.eventContent_[arg_4_1] or ""
end

return var_0_0
