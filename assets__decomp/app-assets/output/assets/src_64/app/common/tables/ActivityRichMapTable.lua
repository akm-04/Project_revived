local var_0_0 = class("ActivityRichMapTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.point_ = {}
	arg_1_0.icon1_ = {}
	arg_1_0.icon2_ = {}
	arg_1_0.icon3_ = {}
	arg_1_0.posType_ = {}
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}

	import("app.common.tables.TableParser").parse("activity_rich_map.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.point)
		arg_1_0.icon1_[var_2_0] = arg_2_0.icon1
		arg_1_0.icon2_[var_2_0] = arg_2_0.icon2
		arg_1_0.icon3_[var_2_0] = arg_2_0.icon3
		arg_1_0.posType_[var_2_0] = tonumber(arg_2_0.pos_type)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or 0
end

function var_0_0.point(arg_4_0, arg_4_1)
	return arg_4_0.point_[arg_4_1] or 0
end

function var_0_0.icon1(arg_5_0, arg_5_1)
	return arg_5_0.icon1_[arg_5_1] or ""
end

function var_0_0.icon2(arg_6_0, arg_6_1)
	return arg_6_0.icon2_[arg_6_1] or ""
end

function var_0_0.icon3(arg_7_0, arg_7_1)
	return arg_7_0.icon3_[arg_7_1] or ""
end

function var_0_0.posType(arg_8_0, arg_8_1)
	return arg_8_0.posType_[arg_8_1] or 1
end

function var_0_0.posType(arg_9_0, arg_9_1)
	return arg_9_0.posType_[arg_9_1] or 0
end

function var_0_0.name(arg_10_0, arg_10_1)
	return arg_10_0.name_[arg_10_1] or ""
end

function var_0_0.desc(arg_11_0, arg_11_1)
	return arg_11_0.desc_[arg_11_1] or ""
end

function var_0_0.getIconByLev(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_2 or 1

	if var_12_0 == 1 then
		return arg_12_0:icon1(arg_12_1)
	elseif var_12_0 == 2 then
		return arg_12_0:icon2(arg_12_1)
	elseif var_12_0 == 3 then
		return arg_12_0:icon3(arg_12_1)
	end
end

return var_0_0
