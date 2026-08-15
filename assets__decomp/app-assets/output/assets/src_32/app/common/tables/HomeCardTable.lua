local var_0_0 = class("HomeCardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.xx_ = {}
	arg_1_0.yy_ = {}
	arg_1_0.isShowBeforeLoading_ = {}
	arg_1_0.beforeLoadingIds_ = {}

	import("app.common.tables.TableParser").parse("home_card.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.xx_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.yy_[var_2_0] = tonumber(arg_2_0.y)
		arg_1_0.isShowBeforeLoading_[var_2_0] = tonumber(arg_2_0.is_show_before_loading) or 0

		if arg_1_0:isShowBeforeLoading(var_2_0) then
			table.insert(arg_1_0.beforeLoadingIds_, var_2_0)
		end
	end)
end

function var_0_0.x(arg_3_0, arg_3_1)
	return arg_3_0.xx_[arg_3_1] or 0
end

function var_0_0.y(arg_4_0, arg_4_1)
	return arg_4_0.yy_[arg_4_1] or 0
end

function var_0_0.ids(arg_5_0)
	return arg_5_0.ids_
end

function var_0_0.isShowBeforeLoading(arg_6_0, arg_6_1)
	return arg_6_0.isShowBeforeLoading_[arg_6_1] == 1
end

function var_0_0.beforeLoadingIds(arg_7_0)
	return arg_7_0.beforeLoadingIds_
end

return var_0_0
