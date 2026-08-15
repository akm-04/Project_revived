local var_0_0 = class("GoldCatchItemTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.pos_ = {}

	import("app.common.tables.TableParser").parse("gold_catch_item.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.pos_[var_2_0] = xyd.splitToNumber(arg_2_0.pos, "|")
	end)
end

function var_0_0.pos(arg_3_0, arg_3_1)
	return arg_3_0.pos_[arg_3_1] or {}
end

function var_0_0.getPos(arg_4_0)
	return arg_4_0.pos_ or {}
end

return var_0_0
