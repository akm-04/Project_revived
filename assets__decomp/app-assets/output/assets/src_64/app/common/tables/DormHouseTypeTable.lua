local var_0_0 = class("DormHouseTypeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.heroNum_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.newIcon_ = {}

	import("app.common.tables.TableParser").parse("dorm_house_type.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.heroNum_[var_2_0] = tonumber(arg_2_0.hero_num)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.newIcon_[var_2_0] = arg_2_0.new_icon
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.heroNum(arg_4_0, arg_4_1)
	return arg_4_0.heroNum_[arg_4_1] or 0
end

function var_0_0.icon(arg_5_0, arg_5_1)
	return arg_5_0.icon_[arg_5_1] or ""
end

function var_0_0.newIcon(arg_6_0, arg_6_1)
	return arg_6_0.newIcon_[arg_6_1] or ""
end

return var_0_0
