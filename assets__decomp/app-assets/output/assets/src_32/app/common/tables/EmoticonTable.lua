local var_0_0 = class("EmoticonTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.image_ = {}
	arg_1_0.words_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.lockDesc_ = {}
	arg_1_0.isShow_ = {}
	arg_1_0.isDynamic_ = {}
	arg_1_0.path_ = {}

	import("app.common.tables.TableParser").parse("emoticon.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.isDynamic_[var_2_0] = tonumber(arg_2_0.is_dynamic)
		arg_1_0.image_[var_2_0] = arg_2_0.image
		arg_1_0.words_[var_2_0] = arg_2_0.words
		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.lockDesc_[var_2_0] = arg_2_0.lock_desc
		arg_1_0.isShow_[var_2_0] = tonumber(arg_2_0.is_show)
		arg_1_0.path_[var_2_0] = arg_2_0.path

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.allCounts(arg_3_0)
	return #arg_3_0.image_
end

function var_0_0.getIds(arg_4_0)
	return arg_4_0.ids_
end

function var_0_0.image(arg_5_0, arg_5_1)
	return arg_5_0.image_[arg_5_1] or ""
end

function var_0_0.words(arg_6_0, arg_6_1)
	return arg_6_0.words_[arg_6_1] or ""
end

function var_0_0.itemID(arg_7_0, arg_7_1)
	return arg_7_0.itemID_[arg_7_1] or 0
end

function var_0_0.lockDesc(arg_8_0, arg_8_1)
	return arg_8_0.lockDesc_[arg_8_1] or ""
end

function var_0_0.isShow(arg_9_0, arg_9_1)
	return arg_9_0.isShow_[arg_9_1] or 0
end

function var_0_0.isDynamic(arg_10_0, arg_10_1)
	return arg_10_0.isDynamic_[arg_10_1] or 0
end

function var_0_0.path(arg_11_0, arg_11_1)
	return arg_11_0.path_[arg_11_1] or ""
end

return var_0_0
