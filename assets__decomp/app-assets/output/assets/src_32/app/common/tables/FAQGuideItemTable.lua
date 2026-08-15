local var_0_0 = class("FAQGuideItemTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.functionId_ = {}
	arg_1_0.content_ = {}
	arg_1_0.window_ = {}

	import("app.common.tables.TableParser").parse("guide_guide_3", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.functionId_[var_2_0] = tonumber(arg_2_0.function_id)
		arg_1_0.content_[var_2_0] = arg_2_0.content
		arg_1_0.window_[var_2_0] = arg_2_0.windows_name

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.getName(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.getFunctionId(arg_5_0, arg_5_1)
	return arg_5_0.functionId_[arg_5_1] or 0
end

function var_0_0.getContent(arg_6_0, arg_6_1)
	return arg_6_0.content_[arg_6_1] or ""
end

function var_0_0.getWindowName(arg_7_0, arg_7_1)
	return arg_7_0.window_[arg_7_1] or ""
end

return var_0_0
