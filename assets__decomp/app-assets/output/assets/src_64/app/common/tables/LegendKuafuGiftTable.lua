local var_0_0 = class("LegendKuafuGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.rank_ = {}
	arg_1_0.crystal_ = {}
	arg_1_0.mana_ = {}

	import("app.common.tables.TableParser").parse("legend_kuafu_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.rank_[var_2_0] = tonumber(arg_2_0.rank)
		arg_1_0.crystal_[var_2_0] = tonumber(arg_2_0.crystal)
		arg_1_0.mana_[var_2_0] = tonumber(arg_2_0.mana)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.rank(arg_4_0, arg_4_1)
	return arg_4_0.rank_[arg_4_1] or 0
end

function var_0_0.crystal(arg_5_0, arg_5_1)
	return arg_5_0.crystal_[arg_5_1] or 0
end

function var_0_0.mana(arg_6_0, arg_6_1)
	return arg_6_0.mana_[arg_6_1] or 0
end

function var_0_0.getID(arg_7_0, arg_7_1)
	local var_7_0 = 0

	if arg_7_1 > arg_7_0.rank_[#arg_7_0.rank_] then
		return var_7_0
	end

	for iter_7_0 = #arg_7_0.rank_, 1, -1 do
		if arg_7_1 >= arg_7_0.rank_[iter_7_0] then
			return iter_7_0
		end
	end

	return var_7_0
end

function var_0_0.getMaxID(arg_8_0)
	return arg_8_0.ids_[#arg_8_0.ids_]
end

return var_0_0
