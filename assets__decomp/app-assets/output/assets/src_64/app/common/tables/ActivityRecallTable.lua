local var_0_0 = class("ActivityRecallTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.req_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.show_ = {}
	arg_1_0.missionType_ = {}

	import("app.common.tables.TableParser").parse("activity_recall.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.req_[var_2_0] = xyd.splitToNumber(arg_2_0.req, "|")
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.show_[var_2_0] = tonumber(arg_2_0.show)
		arg_1_0.missionType_[var_2_0] = tonumber(arg_2_0.mission_type)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.req(arg_4_0, arg_4_1)
	return arg_4_0.req_[arg_4_1] or {}
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.show(arg_6_0, arg_6_1)
	return arg_6_0.show_[arg_6_1] or 0
end

function var_0_0.missionType(arg_7_0, arg_7_1)
	return arg_7_0.missionType_[arg_7_1] or 0
end

function var_0_0.getIds(arg_8_0, arg_8_1)
	local var_8_0 = table.keys(arg_8_0.desc_)
	local var_8_1 = {}

	for iter_8_0, iter_8_1 in pairs(var_8_0) do
		if arg_8_0:missionType(iter_8_1) == arg_8_1 then
			table.insert(var_8_1, iter_8_1)
		end
	end

	return var_8_1
end

return var_0_0
