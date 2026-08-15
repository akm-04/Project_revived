local var_0_0 = class("LibraryCGTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.content_ = {}
	arg_1_0.unlock_ = {}
	arg_1_0.unlockTypes_ = {}
	arg_1_0.item_ = {}
	arg_1_0.num_ = {}
	arg_1_0.cg_ = {}

	import("app.common.tables.TableParser").parse("library_cg", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.content_[var_2_0] = arg_2_0.content
		arg_1_0.unlock_[var_2_0] = xyd.splitToNumber(arg_2_0.unlock, "|")
		arg_1_0.unlockTypes_[var_2_0] = xyd.splitToNumber(arg_2_0.unlock_type, "|")
		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.cg_[var_2_0] = arg_2_0.cg

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.getIDs(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.getName(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.getContent(arg_5_0, arg_5_1)
	return arg_5_0.content_[arg_5_1] or ""
end

function var_0_0.getUnlockIDs(arg_6_0, arg_6_1)
	return arg_6_0.unlock_[arg_6_1] or {}
end

function var_0_0.getUnlockTypes(arg_7_0, arg_7_1)
	return arg_7_0.unlockTypes_[arg_7_1] or {}
end

function var_0_0.getItem(arg_8_0, arg_8_1)
	return arg_8_0.item_[arg_8_1]
end

function var_0_0.getNum(arg_9_0, arg_9_1)
	return arg_9_0.num_[arg_9_1] or 0
end

function var_0_0.getCG(arg_10_0, arg_10_1)
	return arg_10_0.cg_[arg_10_1] or ""
end

return var_0_0
