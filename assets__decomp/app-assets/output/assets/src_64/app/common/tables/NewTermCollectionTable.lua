local var_0_0 = class("NewTermCollectionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.collectionGift_ = {}
	arg_1_0.text_ = {}

	import("app.common.tables.TableParser").parse("activity_lianyi_collection.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.item_id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.collectionGift_[var_2_0] = tonumber(arg_2_0.collection_gift)
		arg_1_0.text_[var_2_0] = arg_2_0.text
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1]
end

function var_0_0.collectionGift(arg_5_0, arg_5_1)
	return arg_5_0.collectionGift_[arg_5_1]
end

function var_0_0.text(arg_6_0, arg_6_1)
	return arg_6_0.text_[arg_6_1]
end

return var_0_0
