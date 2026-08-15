local var_0_0 = class("ActivityChocolatePoolAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.dropboxId_ = {}
	arg_1_0.itemId_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.dropRate_ = {}
	arg_1_0.extractTimes_ = {}
	arg_1_0.poolLists = {}
	arg_1_0.item = {}
	arg_1_0.ids = {}

	for iter_1_0 = 1, 10 do
		table.insert(arg_1_0.item, {})
	end

	for iter_1_1 = 1, 10 do
		table.insert(arg_1_0.ids, {})
	end

	import("app.common.tables.TableParser").parse("activity_chocolate_pool_award.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.dropboxId_[var_2_0] = tonumber(arg_2_0.dropbox_id)
		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.dropRate_[var_2_0] = tonumber(arg_2_0.drop_rate)
		arg_1_0.extractTimes_[var_2_0] = tonumber(arg_2_0.extract_times)

		table.insert(arg_1_0.poolLists, arg_1_0.dropboxId_[var_2_0])

		local var_2_1 = arg_1_0.dropboxId_[var_2_0] - 1000

		table.insert(arg_1_0.item[var_2_1], arg_1_0.itemId_[var_2_0])
		table.insert(arg_1_0.ids[var_2_1], var_2_0)
	end)
end

function var_0_0.poolList(arg_3_0)
	return arg_3_0.poolLists or {}
end

function var_0_0.items(arg_4_0, arg_4_1)
	return arg_4_0.item[arg_4_1] or {}
end

function var_0_0.getids(arg_5_0, arg_5_1)
	return arg_5_0.ids[arg_5_1] or {}
end

function var_0_0.dropboxId(arg_6_0, arg_6_1)
	return arg_6_0.dropboxId_[arg_6_1] or 0
end

function var_0_0.itemId(arg_7_0, arg_7_1)
	return arg_7_0.itemId_[arg_7_1] or 0
end

function var_0_0.itemNum(arg_8_0, arg_8_1)
	return arg_8_0.itemNum_[arg_8_1] or 0
end

function var_0_0.dropRate(arg_9_0, arg_9_1)
	return arg_9_0.dropRate_[arg_9_1] or 0
end

function var_0_0.extractTimes(arg_10_0, arg_10_1)
	return arg_10_0.extractTimes_[arg_10_1] or 0
end

return var_0_0
