local var_0_0 = class("LibraryGiftTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.item_ = {}

	import("app.common.tables.TableParser").parse("library_gift", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.type)

		arg_1_0.item_[var_2_0] = xyd.splitToNumber(arg_2_0.item, "|")
	end)
end

function var_0_0.getitemsByType(arg_3_0, arg_3_1)
	return arg_3_0.item_[arg_3_1]
end

function var_0_0.getAllItems(arg_4_0)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in pairs(arg_4_0.item_) do
		for iter_4_2 = 1, #iter_4_1 do
			table.insert(var_4_0, iter_4_1[iter_4_2])
		end
	end

	return var_4_0
end

function var_0_0.getItemLikeType(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.item_) do
		for iter_5_2 = 1, #iter_5_1 do
			if iter_5_1[iter_5_2] == arg_5_1 then
				return iter_5_0
			end
		end
	end
end

return var_0_0
