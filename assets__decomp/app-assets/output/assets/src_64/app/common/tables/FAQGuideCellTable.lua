local var_0_0 = class("FAQGuideCellTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.content_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.num_ = {}
	arg_1_0.order_ = {}

	import("app.common.tables.TableParser").parse("guide_love", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.content_[var_2_0] = arg_2_0.content
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.order_[tonumber(arg_2_0.order)] = var_2_0

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.getName(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.getContent(arg_5_0, arg_5_1)
	return arg_5_0.content_[arg_5_1] or ""
end

function var_0_0.getIcon(arg_6_0, arg_6_1)
	return arg_6_0.icon_[arg_6_1] or ""
end

function var_0_0.getNum(arg_7_0, arg_7_1)
	return arg_7_0.num_[arg_7_1] or 0
end

function var_0_0.getOrder(arg_8_0, arg_8_1)
	return arg_8_0.order_[arg_8_1] or 0
end

function var_0_0.getAllNum(arg_9_0)
	return arg_9_0.num_ or {}
end

return var_0_0
