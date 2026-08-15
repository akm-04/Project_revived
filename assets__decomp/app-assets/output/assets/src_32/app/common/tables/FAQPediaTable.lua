local var_0_0 = class("FAQPediaTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.lev_ = {}
	arg_1_0.types_ = {}
	arg_1_0.contents_ = {}

	import("app.common.tables.TableParser").parse("guide_page", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.lev_[var_2_0] = tonumber(arg_2_0.start_level)
		arg_1_0.types_[var_2_0] = xyd.splitToNumber(arg_2_0.type, "|")
		arg_1_0.contents_[var_2_0] = xyd.split(arg_2_0.content, "|")

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.getIds(arg_3_0, arg_3_1)
	return arg_3_0.ids_
end

function var_0_0.getName(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.getLev(arg_5_0, arg_5_1)
	return arg_5_0.lev_[arg_5_1] or 0
end

function var_0_0.getAllLev(arg_6_0)
	return arg_6_0.lev_
end

function var_0_0.getTypes(arg_7_0, arg_7_1)
	return arg_7_0.types_[arg_7_1] or {}
end

function var_0_0.getContents(arg_8_0, arg_8_1)
	return arg_8_0.contents_[arg_8_1] or {}
end

return var_0_0
