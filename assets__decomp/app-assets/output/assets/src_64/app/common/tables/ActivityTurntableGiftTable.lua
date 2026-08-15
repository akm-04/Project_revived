local var_0_0 = class("ActivityTurntableGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.giftIcon_ = {}

	import("app.common.tables.TableParser").parse("activity_turntable_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = string.gsub(arg_2_0.desc, "|", "\n")
		arg_1_0.giftIcon_[var_2_0] = arg_2_0.gift_icon
	end)
end

function var_0_0.giftNums(arg_3_0)
	return #arg_3_0.name_
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.giftIcon(arg_5_0, arg_5_1)
	return arg_5_0.giftIcon_[arg_5_1] or ""
end

return var_0_0
