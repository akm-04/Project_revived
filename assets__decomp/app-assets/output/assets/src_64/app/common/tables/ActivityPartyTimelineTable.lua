local var_0_0 = class("ActivityPartyTimelineTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.partnerId_ = {}
	arg_1_0.missionIds_ = {}

	import("app.common.tables.TableParser").parse("activity_party_timeline.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.partnerId_[var_2_0] = tonumber(arg_2_0.partner_id)
		arg_1_0.missionIds_[var_2_0] = xyd.splitToNumber(arg_2_0.mission_ids, "|")
	end)
end

function var_0_0.partnerId(arg_3_0, arg_3_1)
	return arg_3_0.partnerId_[arg_3_1] or 0
end

function var_0_0.missionIds(arg_4_0, arg_4_1)
	return arg_4_0.missionIds_[arg_4_1] or {}
end

function var_0_0.getPartners(arg_5_0)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_0.partnerId_) do
		if iter_5_1 > 0 and not xyd.isInTable(var_5_0, iter_5_1) then
			table.insert(var_5_0, iter_5_1)
		end
	end

	return var_5_0
end

return var_0_0
