local var_0_0 = class("NewRegionAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.rank = {}
	arg_1_0.score = {}
	arg_1_0.score2 = {}
	arg_1_0.crystal = {}
	arg_1_0.token = {}
	arg_1_0.ids = {}
	arg_1_0.token2 = {}

	import("app.common.tables.TableParser").parse("new_arena_award.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids, var_2_0)

		arg_1_0.rank[var_2_0] = tonumber(arg_2_0.rank)
		arg_1_0.score[var_2_0] = tonumber(arg_2_0.score)
		arg_1_0.score2[var_2_0] = tonumber(arg_2_0.score2)
		arg_1_0.crystal[var_2_0] = tonumber(arg_2_0.crystal)
		arg_1_0.token[var_2_0] = tonumber(arg_2_0.token)
		arg_1_0.token2[var_2_0] = tonumber(arg_2_0.token2)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids or {}
end

function var_0_0.getRank(arg_4_0, arg_4_1)
	return arg_4_0.rank[arg_4_1] or 0
end

function var_0_0.getScore(arg_5_0, arg_5_1)
	return arg_5_0.score[arg_5_1] or 0
end

function var_0_0.getScore2(arg_6_0, arg_6_1)
	return arg_6_0.score2[arg_6_1] or 0
end

function var_0_0.getCrystal(arg_7_0, arg_7_1)
	return arg_7_0.crystal[arg_7_1] or {}
end

function var_0_0.getToken(arg_8_0, arg_8_1)
	return arg_8_0.token[arg_8_1] or {}
end

function var_0_0.getToken2(arg_9_0, arg_9_1)
	return arg_9_0.token2[arg_9_1] or {}
end

return var_0_0
