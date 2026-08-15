local var_0_0 = class("AcademyArenaMapTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.type_ = {}
	arg_1_0.cost_ = {}
	arg_1_0.ceiling_ = {}
	arg_1_0.adj_ = {}
	arg_1_0.move_ = {}
	arg_1_0.manor_ = {}
	arg_1_0.name_ = {}
	arg_1_0.description_ = {}
	arg_1_0.occupy_ = {}
	arg_1_0.score_ = {}
	arg_1_0.buff_ = {}
	arg_1_0.earth_ = {}

	import("app.common.tables.TableParser").parse("supremacy_map.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.action_cost)
		arg_1_0.ceiling_[var_2_0] = tonumber(arg_2_0.garrison_ceiling)
		arg_1_0.adj_[var_2_0] = xyd.splitToNumber(arg_2_0.adjacent, "|")
		arg_1_0.move_[var_2_0] = xyd.splitToNumber(arg_2_0.move, "|")
		arg_1_0.manor_[var_2_0] = tonumber(arg_2_0.manor)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.description_[var_2_0] = arg_2_0.description
		arg_1_0.occupy_[var_2_0] = tonumber(arg_2_0.occupy)
		arg_1_0.score_[var_2_0] = tonumber(arg_2_0.score)
		arg_1_0.buff_[var_2_0] = tonumber(arg_2_0.buff)
		arg_1_0.earth_[var_2_0] = tonumber(arg_2_0.earth)
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.cost(arg_5_0, arg_5_1)
	return arg_5_0.cost_[arg_5_1] or 0
end

function var_0_0.ceiling(arg_6_0, arg_6_1)
	return arg_6_0.ceiling_[arg_6_1] or {}
end

function var_0_0.adj(arg_7_0, arg_7_1)
	return arg_7_0.adj_[arg_7_1] or {}
end

function var_0_0.move(arg_8_0, arg_8_1)
	return arg_8_0.move_[arg_8_1] or {}
end

function var_0_0.manor(arg_9_0, arg_9_1)
	return arg_9_0.manor_[arg_9_1] or ""
end

function var_0_0.name(arg_10_0, arg_10_1)
	return arg_10_0.name_[arg_10_1] or ""
end

function var_0_0.description(arg_11_0, arg_11_1)
	return arg_11_0.description_[arg_11_1] or ""
end

function var_0_0.occupy(arg_12_0, arg_12_1)
	return (arg_12_0.occupy_[arg_12_1] or 0) > 0
end

function var_0_0.score(arg_13_0, arg_13_1)
	return arg_13_0.score_[arg_13_1] or 0
end

function var_0_0.buff(arg_14_0, arg_14_1)
	return arg_14_0.buff_[arg_14_1] or 0
end

function var_0_0.earth(arg_15_0, arg_15_1)
	return (arg_15_0.earth_[arg_15_1] or 0) > 0
end

return var_0_0
