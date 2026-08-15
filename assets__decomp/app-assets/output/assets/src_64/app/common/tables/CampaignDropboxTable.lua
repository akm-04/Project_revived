local var_0_0 = class("CampaignDropboxTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.dropItem_ = {}
	arg_1_0.dropRate_ = {}

	import("app.common.tables.TableParser").parse("campaign_dropbox.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.dropbox_id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.dropItem_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.dropRate_[var_2_0] = tonumber(arg_2_0.increase_rate)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.dropItem(arg_4_0, arg_4_1)
	return arg_4_0.dropItem_[arg_4_1] or 0
end

function var_0_0.dropRate(arg_5_0, arg_5_1)
	return arg_5_0.dropRate_[arg_5_1] or 0
end

return var_0_0
