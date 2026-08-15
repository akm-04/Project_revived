local var_0_0 = class("SkinCardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.xx_ = {}
	arg_1_0.yy_ = {}

	import("app.common.tables.TableParser").parse("skin_home_card.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.xx_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.yy_[var_2_0] = tonumber(arg_2_0.y)
	end)
end

function var_0_0.x(arg_3_0, arg_3_1)
	return arg_3_0.xx_[arg_3_1] or 0
end

function var_0_0.y(arg_4_0, arg_4_1)
	return arg_4_0.yy_[arg_4_1] or 0
end

function var_0_0.ids(arg_5_0)
	return arg_5_0.ids_
end

return var_0_0
