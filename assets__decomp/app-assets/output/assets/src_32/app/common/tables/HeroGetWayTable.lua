local var_0_0 = class("HeroGetWayTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.window_ = {}
	arg_1_0.funcId_ = {}
	arg_1_0.shopType_ = {}

	import("app.common.tables.TableParser").parse("hero_get_way.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.window_[var_2_0] = arg_2_0.window
		arg_1_0.funcId_[var_2_0] = tonumber(arg_2_0.func_id)
		arg_1_0.shopType_[var_2_0] = tonumber(arg_2_0.shop_type)
	end)
end

function var_0_0.getName(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.getDesc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.getIcon(arg_5_0, arg_5_1)
	return arg_5_0.icon_[arg_5_1] or ""
end

function var_0_0.getWindow(arg_6_0, arg_6_1)
	return arg_6_0.window_[arg_6_1] or ""
end

function var_0_0.getFuncId(arg_7_0, arg_7_1)
	return arg_7_0.funcId_[arg_7_1]
end

function var_0_0.shopType(arg_8_0, arg_8_1)
	return arg_8_0.shopType_[arg_8_1] or 0
end

function var_0_0.getTotalWay(arg_9_0)
	return #arg_9_0.name_
end

return var_0_0
