local var_0_0 = class("HeroRecommendTypeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.nameIcon1_ = {}
	arg_1_0.nameIcon2_ = {}
	arg_1_0.icon_ = {}

	import("app.common.tables.TableParser").parse("hero_recommend_type.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.nameIcon1_[var_2_0] = arg_2_0.name_icon1
		arg_1_0.nameIcon2_[var_2_0] = arg_2_0.name_icon2
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.nameIcon1(arg_4_0, arg_4_1)
	return arg_4_0.nameIcon1_[arg_4_1] or ""
end

function var_0_0.nameIcon2(arg_5_0, arg_5_1)
	return arg_5_0.nameIcon2_[arg_5_1] or ""
end

function var_0_0.icon(arg_6_0, arg_6_1)
	return arg_6_0.icon_[arg_6_1] or ""
end

return var_0_0
