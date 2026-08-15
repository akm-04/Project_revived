local var_0_0 = class("RegionArenaLevelTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.level = {}
	arg_1_0.levelStar = {}
	arg_1_0.star = {}
	arg_1_0.levelMap = {}
	arg_1_0.levelStarType = {}
	arg_1_0.name = {}

	import("app.common.tables.TableParser").parse("region_arena_level.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.star[var_2_0] = tonumber(arg_2_0.star)
		arg_1_0.level[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.levelStar[var_2_0] = tonumber(arg_2_0.level_star)
		arg_1_0.name[var_2_0] = arg_2_0.name

		local var_2_1 = false

		for iter_2_0, iter_2_1 in pairs(arg_1_0.levelStarType) do
			if iter_2_1 == arg_1_0.levelStar[var_2_0] then
				var_2_1 = true

				break
			end
		end

		if not var_2_1 then
			table.insert(arg_1_0.levelStarType, arg_1_0.levelStar[var_2_0])
		end
	end)

	local function var_1_0(arg_3_0)
		if arg_3_0 >= arg_1_0.star[#arg_1_0.star] then
			return arg_1_0.level[#arg_1_0.level]
		elseif arg_3_0 <= arg_1_0.star[1] then
			return arg_1_0.level[1]
		else
			for iter_3_0, iter_3_1 in pairs(arg_1_0.star) do
				if arg_3_0 <= iter_3_1 and arg_3_0 > arg_1_0.star[iter_3_0 - 1] then
					return arg_1_0.level[iter_3_0]
				end
			end

			return 1
		end
	end

	for iter_1_0 = 0, arg_1_0.star[#arg_1_0.star] do
		local var_1_1 = iter_1_0
		local var_1_2 = var_1_0(var_1_1)

		arg_1_0.levelMap[var_1_1] = var_1_2
	end
end

function var_0_0.getlevel(arg_4_0, arg_4_1)
	return arg_4_0.level[arg_4_1] or 0
end

function var_0_0.getStar(arg_5_0, arg_5_1)
	return arg_5_0.star[arg_5_1] or 0
end

function var_0_0.getlevelStar(arg_6_0, arg_6_1)
	return arg_6_0.levelStar[arg_6_1] or 0
end

function var_0_0.getPlayerArenaLevel(arg_7_0, arg_7_1)
	return arg_7_0.levelMap[arg_7_1] or 1
end

function var_0_0.getLevelStarType(arg_8_0)
	return arg_8_0.levelStarType or {}
end

function var_0_0.getName(arg_9_0, arg_9_1)
	return arg_9_0.name[arg_9_1] or ""
end

return var_0_0
