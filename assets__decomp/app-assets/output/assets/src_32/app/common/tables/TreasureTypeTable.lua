local var_0_0 = class("TreasureTypeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.product_type_ = {}
	arg_1_0.chest_ = {}
	arg_1_0.req_type_ = {}
	arg_1_0.req_ = {}
	arg_1_0.fight_id_ = {}

	import("app.common.tables.TableParser").parse("treasure_type.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.product_type_[var_2_0] = tonumber(arg_2_0.product_type)
		arg_1_0.chest_[var_2_0] = xyd.splitToNumber(arg_2_0.chest, "|")
		arg_1_0.req_type_[var_2_0] = tonumber(arg_2_0.req_type)
		arg_1_0.req_[var_2_0] = tonumber(arg_2_0.req)
		arg_1_0.fight_id_[var_2_0] = tonumber(arg_2_0.fight_id)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.productType(arg_4_0, arg_4_1)
	return arg_4_0.product_type_[arg_4_1] or 0
end

function var_0_0.chest(arg_5_0, arg_5_1)
	if arg_5_0.chest_[arg_5_1][1] and arg_5_0.chest_[arg_5_1][1] == 0 then
		return {}
	end

	return arg_5_0.chest_[arg_5_1] or {}
end

function var_0_0.reqType(arg_6_0, arg_6_1)
	return arg_6_0.req_type_[arg_6_1] or 1
end

function var_0_0.req(arg_7_0, arg_7_1)
	return arg_7_0.req_[arg_7_1] or 0
end

function var_0_0.fightId(arg_8_0, arg_8_1)
	return arg_8_0.fight_id_[arg_8_1] or 0
end

return var_0_0
