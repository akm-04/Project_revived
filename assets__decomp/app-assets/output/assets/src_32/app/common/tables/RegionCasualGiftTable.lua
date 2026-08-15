local var_0_0 = class("RegionCasualGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.rank = {}
	arg_1_0.mana = {}
	arg_1_0.crystal = {}
	arg_1_0.ids = {}

	import("app.common.tables.TableParser").parse("relax_match_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids, var_2_0)

		arg_1_0.rank[var_2_0] = tonumber(arg_2_0.rank)
		arg_1_0.mana[var_2_0] = tonumber(arg_2_0.mana)
		arg_1_0.crystal[var_2_0] = tonumber(arg_2_0.crystal)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids or {}
end

function var_0_0.getMaxID(arg_4_0)
	return #arg_4_0.ids
end

function var_0_0.getRank(arg_5_0, arg_5_1)
	return arg_5_0.rank[arg_5_1] or 0
end

function var_0_0.getMana(arg_6_0, arg_6_1)
	return arg_6_0.mana[arg_6_1] or 0
end

function var_0_0.getCrystal(arg_7_0, arg_7_1)
	return arg_7_0.crystal[arg_7_1] or 0
end

return var_0_0
