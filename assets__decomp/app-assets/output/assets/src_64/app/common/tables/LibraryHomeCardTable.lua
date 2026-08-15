local var_0_0 = class("LibraryHomeCardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.xx_ = {}
	arg_1_0.yy_ = {}
	arg_1_0.headx_ = {}
	arg_1_0.heady_ = {}
	arg_1_0.breastx_ = {}
	arg_1_0.breasty_ = {}
	arg_1_0.live2dx_ = {}
	arg_1_0.live2dy_ = {}
	arg_1_0.dynamicHeadX_ = {}
	arg_1_0.dynamicHeadY_ = {}
	arg_1_0.dynamicBreastX_ = {}
	arg_1_0.dynamicBreastY_ = {}

	import("app.common.tables.TableParser").parse("library_homecard.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.xx_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.yy_[var_2_0] = tonumber(arg_2_0.y)
		arg_1_0.headx_[var_2_0] = tonumber(arg_2_0.head_x)
		arg_1_0.heady_[var_2_0] = tonumber(arg_2_0.head_y)
		arg_1_0.breastx_[var_2_0] = tonumber(arg_2_0.breast_x)
		arg_1_0.breasty_[var_2_0] = tonumber(arg_2_0.breast_y)
		arg_1_0.live2dx_[var_2_0] = tonumber(arg_2_0.live2d_x)
		arg_1_0.live2dy_[var_2_0] = tonumber(arg_2_0.live2d_y)
		arg_1_0.dynamicHeadX_[var_2_0] = tonumber(arg_2_0.dynamic_head_x)
		arg_1_0.dynamicHeadY_[var_2_0] = tonumber(arg_2_0.dynamic_head_y)
		arg_1_0.dynamicBreastX_[var_2_0] = tonumber(arg_2_0.dynamic_breast_x)
		arg_1_0.dynamicBreastY_[var_2_0] = tonumber(arg_2_0.dynamic_breast_y)
	end)
end

function var_0_0.x(arg_3_0, arg_3_1)
	return arg_3_0.xx_[arg_3_1] or 0
end

function var_0_0.y(arg_4_0, arg_4_1)
	return arg_4_0.yy_[arg_4_1] or 0
end

function var_0_0.headx(arg_5_0, arg_5_1)
	return arg_5_0.headx_[arg_5_1]
end

function var_0_0.heady(arg_6_0, arg_6_1)
	return arg_6_0.heady_[arg_6_1]
end

function var_0_0.breastx(arg_7_0, arg_7_1)
	return arg_7_0.breastx_[arg_7_1]
end

function var_0_0.breasty(arg_8_0, arg_8_1)
	return arg_8_0.breasty_[arg_8_1]
end

function var_0_0.live2dx(arg_9_0, arg_9_1)
	return arg_9_0.live2dx_[arg_9_1] or 0
end

function var_0_0.live2dy(arg_10_0, arg_10_1)
	return arg_10_0.live2dy_[arg_10_1] or 0
end

function var_0_0.dynamicHeadX(arg_11_0, arg_11_1)
	return arg_11_0.dynamicHeadX_[arg_11_1] or 0
end

function var_0_0.dynamicHeadY(arg_12_0, arg_12_1)
	return arg_12_0.dynamicHeadY_[arg_12_1] or 0
end

function var_0_0.dynamicBreastX(arg_13_0, arg_13_1)
	return arg_13_0.dynamicBreastX_[arg_13_1] or 0
end

function var_0_0.dynamicBreastY(arg_14_0, arg_14_1)
	return arg_14_0.dynamicBreastY_[arg_14_1] or 0
end

function var_0_0.ids(arg_15_0)
	return arg_15_0.ids_
end

return var_0_0
