local var_0_0 = class("ActivityBalloonDropboxTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.dropboxId_ = {}
	arg_1_0.itemId_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.dropRate_ = {}

	import("app.common.tables.TableParser").parse("activity_balloon_dropbox.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.dropboxId_[var_2_0] = tonumber(arg_2_0.dropbox_id)
		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.dropRate_[var_2_0] = tonumber(arg_2_0.drop_rate)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.dropboxId(arg_4_0, arg_4_1)
	return arg_4_0.dropboxId_[arg_4_1] or 0
end

function var_0_0.itemId(arg_5_0, arg_5_1)
	return arg_5_0.itemId_[arg_5_1] or 0
end

function var_0_0.itemNum(arg_6_0, arg_6_1)
	return arg_6_0.itemNum_[arg_6_1] or 0
end

function var_0_0.dropRate(arg_7_0, arg_7_1)
	return arg_7_0.dropRate_[arg_7_1] or 0
end

return var_0_0
