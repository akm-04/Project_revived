local var_0_0 = class("ActivityFusionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.materialID_ = {}
	arg_1_0.materialNum_ = {}
	arg_1_0.elementNum_ = {}

	import("app.common.tables.TableParser").parse("activity_fusion.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.materialID_[var_2_0] = xyd.splitToNumber(arg_2_0.material_id, "|")
		arg_1_0.materialNum_[var_2_0] = xyd.splitToNumber(arg_2_0.material_num, "|")
		arg_1_0.elementNum_[var_2_0] = tonumber(arg_2_0.element_num)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.icon(arg_4_0, arg_4_1)
	return arg_4_0.icon_[arg_4_1] or ""
end

function var_0_0.materialIDs(arg_5_0, arg_5_1)
	return arg_5_0.materialID_[arg_5_1] or {}
end

function var_0_0.materialNums(arg_6_0, arg_6_1)
	return arg_6_0.materialNum_[arg_6_1] or {}
end

function var_0_0.elementNum(arg_7_0, arg_7_1)
	return arg_7_0.elementNum_[arg_7_1] or 0
end

return var_0_0
