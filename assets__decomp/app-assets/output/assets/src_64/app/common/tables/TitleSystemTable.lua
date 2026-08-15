local var_0_0 = class("TitleSystemTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.type_ = {}
	arg_1_0.bg_ = {}
	arg_1_0.textImg_ = {}
	arg_1_0.time_ = {}
	arg_1_0.isShow_ = {}
	arg_1_0.isDynamic_ = {}
	arg_1_0.dynamicPath_ = {}
	arg_1_0.ids_ = {}

	import("app.common.tables.TableParser").parse("title_system.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.bg_[var_2_0] = arg_2_0.bg_img
		arg_1_0.textImg_[var_2_0] = arg_2_0.text_img
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.isShow_[var_2_0] = tonumber(arg_2_0.is_show)
		arg_1_0.isDynamic_[var_2_0] = tonumber(arg_2_0.is_dynamic)
		arg_1_0.dynamicPath_[var_2_0] = arg_2_0.dynamic_path

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.type(arg_5_0, arg_5_1)
	return arg_5_0.type_[arg_5_1] or 0
end

function var_0_0.bg(arg_6_0, arg_6_1)
	return arg_6_0.bg_[arg_6_1] or "0"
end

function var_0_0.textImg(arg_7_0, arg_7_1)
	return arg_7_0.textImg_[arg_7_1] or "0"
end

function var_0_0.time(arg_8_0, arg_8_1)
	return arg_8_0.time_[arg_8_1] or 0
end

function var_0_0.isShow(arg_9_0, arg_9_1)
	return arg_9_0.isShow_[arg_9_1] or 0
end

function var_0_0.isDynamic(arg_10_0, arg_10_1)
	return arg_10_0.isDynamic_[arg_10_1] or 0
end

function var_0_0.dynamicPath(arg_11_0, arg_11_1)
	return arg_11_0.dynamicPath_[arg_11_1] or ""
end

function var_0_0.getIDs(arg_12_0)
	local var_12_0 = {}

	for iter_12_0, iter_12_1 in pairs(arg_12_0.ids_) do
		if arg_12_0:isShow(iter_12_1) == 1 then
			table.insert(var_12_0, iter_12_1)
		end
	end

	return var_12_0
end

return var_0_0
