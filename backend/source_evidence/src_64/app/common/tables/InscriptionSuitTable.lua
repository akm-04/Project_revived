local var_0_0 = class("InscriptionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.type_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.name_ = {}
	arg_1_0.attr_ = {}
	arg_1_0.attr_num_ = {}
	arg_1_0.fighting_capacity_ = {}
	arg_1_0.attrValByKey_ = {}
	arg_1_0.recommend_ = {}
	arg_1_0.nameShow_ = {}
	arg_1_0.typeToSuitIds = {}

	import("app.common.tables.TableParser").parse("inscription_suit.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.type_[var_2_0] = arg_2_0.type
		arg_1_0.itemID_[var_2_0] = xyd.splitToNumber(arg_2_0.item_id, "|")
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.attr_[var_2_0] = xyd.splitToNumber(arg_2_0.attr, "|")
		arg_1_0.attr_num_[var_2_0] = xyd.splitToNumber(arg_2_0.attr_num, "|")
		arg_1_0.fighting_capacity_[var_2_0] = tonumber(arg_2_0.fighting_capacity)
		arg_1_0.recommend_[var_2_0] = xyd.splitToNumber(arg_2_0.recommend, "|")
		arg_1_0.nameShow_[var_2_0] = arg_2_0.name_show

		if not arg_1_0.typeToSuitIds[arg_1_0.type_[var_2_0]] then
			arg_1_0.typeToSuitIds[arg_1_0.type_[var_2_0]] = {}
		end

		table.insert(arg_1_0.typeToSuitIds[arg_1_0.type_[var_2_0]], var_2_0)

		arg_1_0.attrValByKey_[var_2_0] = {}

		for iter_2_0, iter_2_1 in ipairs(arg_1_0.attr_[var_2_0]) do
			if not arg_1_0.attr_num_[var_2_0][iter_2_0] then
				error("item attr id does not match attr " .. var_2_0)
			end

			arg_1_0.attrValByKey_[var_2_0][iter_2_1] = arg_1_0.attr_num_[var_2_0][iter_2_0]
		end
	end)
end

function var_0_0.itemID(arg_3_0, arg_3_1)
	return arg_3_0.itemID_[arg_3_1] or 0
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.ids(arg_5_0)
	return arg_5_0.ids_ or 0
end

function var_0_0.type(arg_6_0, arg_6_1)
	return arg_6_0.type_[arg_6_1] or 0
end

function var_0_0.attr(arg_7_0, arg_7_1)
	return arg_7_0.attr_[arg_7_1] or {}
end

function var_0_0.attr_num(arg_8_0, arg_8_1)
	return arg_8_0.attr_num_[arg_8_1] or {}
end

function var_0_0.attrs(arg_9_0, arg_9_1)
	return arg_9_0.attrValByKey_[arg_9_1] or {}
end

function var_0_0.fightingCapacity(arg_10_0, arg_10_1)
	return arg_10_0.fighting_capacity_[arg_10_1] or 0
end

function var_0_0.recommend(arg_11_0, arg_11_1)
	return arg_11_0.recommend_[arg_11_1] or {}
end

function var_0_0.nameShow(arg_12_0, arg_12_1)
	return arg_12_0.nameShow_[arg_12_1] or ""
end

function var_0_0.getSuitIdsByType(arg_13_0, arg_13_1)
	return arg_13_0.typeToSuitIds[tostring(arg_13_1)] or {}
end

return var_0_0
