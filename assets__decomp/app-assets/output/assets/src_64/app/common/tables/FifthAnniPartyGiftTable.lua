local var_0_0 = class("FifthAnniPartyGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemId_ = {}
	arg_1_0.point_ = {}

	import("app.common.tables.TableParser").parse("fifth_anni_party_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.point)
	end)
end

function var_0_0.all(arg_3_0)
	return #arg_3_0.itemId_
end

function var_0_0.itemId(arg_4_0, arg_4_1)
	return arg_4_0.itemId_[arg_4_1] or 0
end

function var_0_0.point(arg_5_0, arg_5_1)
	return arg_5_0.point_[arg_5_1] or 0
end

return var_0_0
