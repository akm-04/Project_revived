local var_0_0 = class("ActivitiesTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.days_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.res_ = {}
	arg_1_0.title_ = {}
	arg_1_0.cutOffTime_ = {}
	arg_1_0.isShow_ = {}
	arg_1_0.tableName_ = {}
	arg_1_0.seque_ = {}
	arg_1_0.levelReq_ = {}
	arg_1_0.walfareShow_ = {}

	import("app.common.tables.TableParser").parse("activity.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.desc_[var_2_0] = string.gsub(arg_1_0.desc_[var_2_0], "|", "\n")
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.days_[var_2_0] = tonumber(arg_2_0.days)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.res_[var_2_0] = arg_2_0.res
		arg_1_0.title_[var_2_0] = arg_2_0.title
		arg_1_0.cutOffTime_[var_2_0] = tonumber(arg_2_0["cut-off_time"])
		arg_1_0.isShow_[var_2_0] = tonumber(arg_2_0.is_show)
		arg_1_0.tableName_[var_2_0] = arg_2_0.table_class_name
		arg_1_0.seque_[var_2_0] = tonumber(arg_2_0.seque)
		arg_1_0.levelReq_[var_2_0] = tonumber(arg_2_0.level_req)
		arg_1_0.walfareShow_[var_2_0] = tonumber(arg_2_0.walfare_show)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.days(arg_6_0, arg_6_1)
	return arg_6_0.days_[arg_6_1] or 0
end

function var_0_0.icon(arg_7_0, arg_7_1)
	return arg_7_0.icon_[arg_7_1] or ""
end

function var_0_0.res(arg_8_0, arg_8_1)
	return arg_8_0.res_[arg_8_1] or ""
end

function var_0_0.title(arg_9_0, arg_9_1)
	return arg_9_0.title_[arg_9_1] or ""
end

function var_0_0.cutOffTime(arg_10_0, arg_10_1)
	return arg_10_0.cutOffTime_[arg_10_1] or 0
end

function var_0_0.isShow(arg_11_0, arg_11_1)
	return arg_11_0.isShow_[arg_11_1] or 1
end

function var_0_0.tableName(arg_12_0, arg_12_1)
	if arg_12_0.tableName_[arg_12_1] == "0" then
		return ""
	else
		return arg_12_0.tableName_[arg_12_1] or ""
	end
end

function var_0_0.seque(arg_13_0, arg_13_1)
	return arg_13_0.seque_[arg_13_1] or 1
end

function var_0_0.levelReq(arg_14_0, arg_14_1)
	return arg_14_0.levelReq_[arg_14_1] or 0
end

function var_0_0.walfareShow(arg_15_0, arg_15_1)
	return arg_15_0.walfareShow_[arg_15_1] or 0
end

return var_0_0
