local var_0_0 = class("FourthAnniPaintingGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_anni_4th_painting_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.getGift(arg_3_0, arg_3_1)
	return arg_3_0.gift_[arg_3_1] or 0
end

return var_0_0
