local var_0_0 = class("AcademyArenaHeroTable")
local var_0_1 = xyd.tables.hero

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.isSX_ = {}
	arg_1_0.lev_ = {}
	arg_1_0.color_ = {}
	arg_1_0.commonCost_ = {}
	arg_1_0.sxCost_ = {}

	import("app.common.tables.TableParser").parse("supremacy_partner.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.partner_id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.isSX_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.lev_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.color_[var_2_0] = tonumber(arg_2_0.quality)
		arg_1_0.commonCost_[var_2_0] = tonumber(arg_2_0.common_cost)
		arg_1_0.sxCost_[var_2_0] = tonumber(arg_2_0.sx_cost)
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.isSX(arg_5_0, arg_5_1)
	return (arg_5_0.isSX_[arg_5_1] or 0) > 0
end

function var_0_0.lev(arg_6_0, arg_6_1)
	return arg_6_0.lev_[arg_6_1] or 0
end

function var_0_0.color(arg_7_0, arg_7_1)
	return arg_7_0.color_[arg_7_1] or 0
end

function var_0_0.commonCost(arg_8_0, arg_8_1)
	return arg_8_0.commonCost_[arg_8_1] or 0
end

function var_0_0.sxCost(arg_9_0, arg_9_1)
	return arg_9_0.sxCost_[arg_9_1] or 0
end

return var_0_0
