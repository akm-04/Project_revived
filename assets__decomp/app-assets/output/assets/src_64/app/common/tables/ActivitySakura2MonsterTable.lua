local var_0_0 = class("ActivitySakura2MonsterTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.level_ = {}
	arg_1_0.star_ = {}

	import("app.common.tables.TableParser").parse("activity_sakura2_monster.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.color)

		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.star_[var_2_0] = tonumber(arg_2_0.star)
	end)
end

function var_0_0.level(arg_3_0, arg_3_1)
	return arg_3_0.level_[arg_3_1] or 0
end

function var_0_0.star(arg_4_0, arg_4_1)
	return arg_4_0.star_[arg_4_1] or 0
end

function var_0_0.getColorByLevel(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.level_) do
		if arg_5_1 <= iter_5_1 then
			return iter_5_0
		end
	end

	return #arg_5_0.level_
end

return var_0_0
