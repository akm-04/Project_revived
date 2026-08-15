local var_0_0 = class("DropboxTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemID_ = {}
	arg_1_0.itemNum_ = {}

	import("app.common.tables.TableParser").parse("dropbox.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.dropbox_id)

		if not arg_1_0.itemID_[var_2_0] then
			arg_1_0.itemID_[var_2_0] = {}
		end

		table.insert(arg_1_0.itemID_[var_2_0], tonumber(arg_2_0.item_id))

		if not arg_1_0.itemNum_[var_2_0] then
			arg_1_0.itemNum_[var_2_0] = {}
		end

		table.insert(arg_1_0.itemNum_[var_2_0], tonumber(arg_2_0.item_num))
	end)
end

function var_0_0.itemIDs(arg_3_0, arg_3_1)
	return arg_3_0.itemID_[arg_3_1] or {}
end

function var_0_0.itemNums(arg_4_0, arg_4_1)
	return arg_4_0.itemNum_[arg_4_1] or {}
end

return var_0_0
