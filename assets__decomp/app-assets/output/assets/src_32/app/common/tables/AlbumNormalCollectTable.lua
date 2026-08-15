local var_0_0 = class("AlbumNormalCollectTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.attrType_ = {}
	arg_1_0.maxAttr_ = {}
	arg_1_0.qualityStages_ = {}
	arg_1_0.qualityAttr_ = {}
	arg_1_0.starStages_ = {}
	arg_1_0.starAttr_ = {}

	import("app.common.tables.TableParser").parse("collect_normal.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.attrType_[var_2_0] = tonumber(arg_2_0.attr)
		arg_1_0.maxAttr_[var_2_0] = tonumber(arg_2_0.max_num)
		arg_1_0.qualityStages_[var_2_0] = xyd.splitToNumber(arg_2_0.quality, "|")
		arg_1_0.qualityAttr_[var_2_0] = xyd.splitToNumber(arg_2_0.num, "|")
		arg_1_0.starStages_[var_2_0] = xyd.splitToNumber(arg_2_0.star, "|")
		arg_1_0.starAttr_[var_2_0] = xyd.splitToNumber(arg_2_0.star_attr, "|")

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1]
end

function var_0_0.attrType(arg_5_0, arg_5_1)
	return arg_5_0.attrType_[arg_5_1] or 0
end

function var_0_0.maxAttr(arg_6_0, arg_6_1)
	return arg_6_0.maxAttr_[arg_6_1] or 0
end

function var_0_0.qualityStages(arg_7_0, arg_7_1)
	return arg_7_0.qualityStages_[arg_7_1] or {}
end

function var_0_0.qualityAttr(arg_8_0, arg_8_1)
	return arg_8_0.qualityAttr_[arg_8_1] or {}
end

function var_0_0.starStages(arg_9_0, arg_9_1)
	return arg_9_0.starStages_[arg_9_1] or {}
end

function var_0_0.starAttr(arg_10_0, arg_10_1)
	return arg_10_0.starAttr_[arg_10_1] or {}
end

return var_0_0
