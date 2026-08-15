local var_0_0 = class("activityAnni4thCampaignProcessTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.process_ = {}
	arg_1_0.giftId_ = {}

	import("app.common.tables.TableParser").parse("activity_anni4_campaign_process.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.process_[var_2_0] = tonumber(arg_2_0.process)
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.process(arg_4_0, arg_4_1)
	return arg_4_0.process_[arg_4_1] or 0
end

function var_0_0.giftId(arg_5_0, arg_5_1)
	return arg_5_0.giftId_[arg_5_1] or 0
end

return var_0_0
