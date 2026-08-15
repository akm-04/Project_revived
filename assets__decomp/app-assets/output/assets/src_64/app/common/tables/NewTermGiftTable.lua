local var_0_0 = class("NewTermGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.connection_ = {}
	arg_1_0.charm_ = {}

	import("app.common.tables.TableParser").parse("activity_lianyi_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.item_id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.connection_[var_2_0] = tonumber(arg_2_0.connection)
		arg_1_0.charm_[var_2_0] = tonumber(arg_2_0.charm)
	end)
end

function var_0_0.giftIDs(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.charm(arg_4_0, arg_4_1)
	return arg_4_0.charm_[arg_4_1]
end

function var_0_0.connection(arg_5_0, arg_5_1)
	return arg_5_0.connection_[arg_5_1]
end

return var_0_0
