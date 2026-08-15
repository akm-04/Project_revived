local var_0_0 = class("SevenDayLoginTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.rate_ = {}
	arg_1_0.giftId_ = {}
	arg_1_0.content_ = {}
	arg_1_0.isRarest_ = {}

	import("app.common.tables.TableParser").parse("sign_7day.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.award_gift_id)
	end)
end

function var_0_0.giftId(arg_3_0, arg_3_1)
	return arg_3_0.giftId_[arg_3_1] or 0
end

return var_0_0
