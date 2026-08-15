local var_0_0 = class("ActivityBalloonRefreshPriceTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.price_ = {}

	import("app.common.tables.TableParser").parse("activity_balloon_refresh_price.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.times)

		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
	end)
end

function var_0_0.price(arg_3_0, arg_3_1)
	return arg_3_0.price_[arg_3_1] or -1
end

return var_0_0
