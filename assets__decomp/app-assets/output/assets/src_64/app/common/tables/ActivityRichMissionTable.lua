local var_0_0 = class("ActivityRichMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.req_ = {}

	import("app.common.tables.TableParser").parse("activity_rich_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.req_[var_2_0] = xyd.splitToNumber(arg_2_0.req, "|")
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.req(arg_4_0, arg_4_1)
	return arg_4_0.req_[arg_4_1] or {}
end

function var_0_0.ids(arg_5_0)
	return table.keys(arg_5_0.desc_)
end

return var_0_0
