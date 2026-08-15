local var_0_0 = class("TwoYearsCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.item_ = {}

	import("app.common.tables.TableParser").parse("activity_anni2_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.item(arg_4_0, arg_4_1)
	return arg_4_0.item_[arg_4_1] or 0
end

return var_0_0
