local var_0_0 = class("PersonDisplayWordsTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.personDisplayDesc_ = {}
	arg_1_0.range_ = {}
	arg_1_0.isRandom_ = {}
	arg_1_0.rangeRandomNums_ = {}
	arg_1_0.robotRandomList_ = {}

	import("app.common.tables.TableParser").parse("person_display_words.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = var_2_0
		arg_1_0.personDisplayDesc_[var_2_0] = arg_2_0.person_display_desc
		arg_1_0.range_[var_2_0] = arg_2_0.range
		arg_1_0.isRandom_[var_2_0] = tonumber(arg_2_0.is_random)
		arg_1_0.rangeRandomNums_[var_2_0] = xyd.splitToNumber(arg_2_0.range_random_nums, "|")

		if tonumber(arg_2_0.is_random) == 1 then
			table.insert(arg_1_0.robotRandomList_, {
				id = var_2_0,
				data = arg_1_0.rangeRandomNums_[var_2_0]
			})
		end
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.personDisplayDesc(arg_4_0, arg_4_1)
	return arg_4_0.personDisplayDesc_[arg_4_1] or ""
end

function var_0_0.range(arg_5_0, arg_5_1)
	return arg_5_0.range_[arg_5_1] or ""
end

function var_0_0.getRobotRandomList(arg_6_0)
	local var_6_0 = math.random(1, 4)
	local var_6_1 = arg_6_0:getRandomIds(var_6_0, #arg_6_0.robotRandomList_)
	local var_6_2 = {}

	for iter_6_0, iter_6_1 in pairs(var_6_1) do
		local var_6_3 = arg_6_0.robotRandomList_[iter_6_0].data

		var_6_2[arg_6_0.robotRandomList_[iter_6_0].id] = math.random(var_6_3[1], var_6_3[2])
	end

	return var_6_2
end

function var_0_0.getRandomIds(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_2 < arg_7_1 then
		arg_7_2 = arg_7_1
	end

	local var_7_0 = {}

	for iter_7_0 = 1, arg_7_1 do
		local var_7_1 = true
		local var_7_2 = 1

		while var_7_1 do
			local var_7_3 = math.random(1, arg_7_2)

			if not var_7_0[var_7_3] then
				var_7_0[var_7_3] = true
				var_7_1 = false
			end

			var_7_2 = var_7_2 + 1

			if var_7_2 > 100 then
				break
			end
		end
	end

	return var_7_0
end

return var_0_0
