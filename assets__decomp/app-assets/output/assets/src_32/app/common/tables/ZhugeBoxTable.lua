local var_0_0 = class("ZhugeBoxTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.rarity_ = {}
	arg_1_0.ids_[xyd.ZhugeBoxType.WHITE] = {}
	arg_1_0.ids_[xyd.ZhugeBoxType.BLACK] = {}
	arg_1_0.ids_[xyd.ZhugeBoxType.WHITE2] = {}
	arg_1_0.itemID_[xyd.ZhugeBoxType.WHITE] = {}
	arg_1_0.itemID_[xyd.ZhugeBoxType.BLACK] = {}
	arg_1_0.itemID_[xyd.ZhugeBoxType.WHITE2] = {}
	arg_1_0.itemNum_[xyd.ZhugeBoxType.WHITE] = {}
	arg_1_0.itemNum_[xyd.ZhugeBoxType.BLACK] = {}
	arg_1_0.itemNum_[xyd.ZhugeBoxType.WHITE2] = {}
	arg_1_0.rarity_[xyd.ZhugeBoxType.WHITE] = {}
	arg_1_0.rarity_[xyd.ZhugeBoxType.BLACK] = {}
	arg_1_0.rarity_[xyd.ZhugeBoxType.WHITE2] = {}

	import("app.common.tables.TableParser").parse("zhuge_box1", handler(arg_1_0, arg_1_0.initBox1))
	import("app.common.tables.TableParser").parse("zhuge_box2", handler(arg_1_0, arg_1_0.initBox2))
	import("app.common.tables.TableParser").parse("zhuge_box3", handler(arg_1_0, arg_1_0.initBox3))
end

function var_0_0.initBox1(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	table.insert(arg_2_0.ids_[xyd.ZhugeBoxType.WHITE], var_2_0)

	arg_2_0.itemID_[xyd.ZhugeBoxType.WHITE][var_2_0] = xyd.splitToNumber(arg_2_1.item_id, "|")
	arg_2_0.itemNum_[xyd.ZhugeBoxType.WHITE][var_2_0] = tonumber(arg_2_1.item_num)
	arg_2_0.rarity_[xyd.ZhugeBoxType.WHITE][var_2_0] = tonumber(arg_2_1.rarity)
end

function var_0_0.initBox2(arg_3_0, arg_3_1)
	local var_3_0 = tonumber(arg_3_1.id)

	table.insert(arg_3_0.ids_[xyd.ZhugeBoxType.BLACK], var_3_0)

	arg_3_0.itemID_[xyd.ZhugeBoxType.BLACK][var_3_0] = xyd.splitToNumber(arg_3_1.item_id, "|")
	arg_3_0.itemNum_[xyd.ZhugeBoxType.BLACK][var_3_0] = tonumber(arg_3_1.item_num)
	arg_3_0.rarity_[xyd.ZhugeBoxType.BLACK][var_3_0] = tonumber(arg_3_1.rarity)
end

function var_0_0.initBox3(arg_4_0, arg_4_1)
	local var_4_0 = tonumber(arg_4_1.id)

	table.insert(arg_4_0.ids_[xyd.ZhugeBoxType.WHITE2], var_4_0)

	arg_4_0.itemID_[xyd.ZhugeBoxType.WHITE2][var_4_0] = xyd.splitToNumber(arg_4_1.item_id, "|")
	arg_4_0.itemNum_[xyd.ZhugeBoxType.WHITE2][var_4_0] = tonumber(arg_4_1.item_num)
	arg_4_0.rarity_[xyd.ZhugeBoxType.WHITE2][var_4_0] = tonumber(arg_4_1.rarity)
end

function var_0_0.ids(arg_5_0, arg_5_1)
	return arg_5_0.ids_[arg_5_1] or {}
end

function var_0_0.itemID(arg_6_0, arg_6_1, arg_6_2)
	return arg_6_0.itemID_[arg_6_1][arg_6_2] or 0
end

function var_0_0.itemNum(arg_7_0, arg_7_1, arg_7_2)
	return arg_7_0.itemNum_[arg_7_1][arg_7_2] or 0
end

function var_0_0.rarity(arg_8_0, arg_8_1, arg_8_2)
	return arg_8_0.rarity_[arg_8_1][arg_8_2] or 0
end

return var_0_0
