local var_0_0 = class("EnFaqTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.question_ = {}
	arg_1_0.answer_ = {}
	arg_1_0.key_ = {}
	arg_1_0.relation_ = {}
	arg_1_0.recommends_ = {}
	arg_1_0.fKeysNext_ = {}
	arg_1_0.keys_ = {}

	import("app.common.tables.TableParser").parse("en_faq.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.question_[var_2_0] = arg_2_0.question
		arg_1_0.answer_[var_2_0] = xyd.split(arg_2_0.answer, "|")
		arg_1_0.key_[var_2_0] = xyd.split(arg_2_0.key, "|")
		arg_1_0.relation_[var_2_0] = xyd.splitToNumber(arg_2_0.relation, "|")

		for iter_2_0, iter_2_1 in pairs(arg_1_0.key_[var_2_0]) do
			local var_2_1 = string.lower(iter_2_1)
			local var_2_2 = xyd.split(var_2_1, " ")
			local var_2_3 = {}
			local var_2_4 = ""

			for iter_2_2, iter_2_3 in pairs(var_2_2) do
				if iter_2_3 ~= "" then
					table.insert(var_2_3, iter_2_3)

					if var_2_4 ~= "" then
						var_2_4 = var_2_4 .. " "
					end

					var_2_4 = var_2_4 .. iter_2_3
				end
			end

			arg_1_0.keys_[var_2_4] = var_2_0

			local var_2_5 = var_2_3[1]

			if not arg_1_0.fKeysNext_[var_2_5] then
				arg_1_0.fKeysNext_[var_2_5] = {}
			end

			table.insert(arg_1_0.fKeysNext_[var_2_5], #var_2_3 - 1)
		end

		if tonumber(arg_2_0.recommend) == 1 then
			table.insert(arg_1_0.recommends_, var_2_0)
		end
	end)
end

function var_0_0.question(arg_3_0, arg_3_1)
	return arg_3_0.question_[arg_3_1] or ""
end

function var_0_0.answer(arg_4_0, arg_4_1)
	local var_4_0 = ""
	local var_4_1 = arg_4_0.answer_[arg_4_1] or {}

	for iter_4_0, iter_4_1 in pairs(var_4_1) do
		if var_4_0 ~= "" then
			var_4_0 = var_4_0 .. "\n"
		end

		var_4_0 = var_4_0 .. iter_4_1
	end

	return var_4_0
end

function var_0_0.key(arg_5_0, arg_5_1)
	return arg_5_0.key_[arg_5_1] or {}
end

function var_0_0.relation(arg_6_0, arg_6_1)
	return arg_6_0.relation_[arg_6_1] or {}
end

function var_0_0.getIdByWords(arg_7_0, arg_7_1)
	local var_7_0 = xyd.split(arg_7_1, " ")
	local var_7_1 = {}

	for iter_7_0, iter_7_1 in pairs(var_7_0) do
		if iter_7_1 ~= "" then
			table.insert(var_7_1, iter_7_1)
		end
	end

	local var_7_2 = {}

	for iter_7_2, iter_7_3 in pairs(var_7_1) do
		if iter_7_3 ~= "" and arg_7_0.fKeysNext_[iter_7_3] then
			for iter_7_4, iter_7_5 in pairs(arg_7_0.fKeysNext_[iter_7_3]) do
				local var_7_3 = ""

				for iter_7_6 = 0, iter_7_5 do
					if var_7_3 ~= "" then
						var_7_3 = var_7_3 .. " "
					end

					if var_7_1[iter_7_2 + iter_7_6] then
						var_7_3 = var_7_3 .. var_7_1[iter_7_2 + iter_7_6]
					else
						break
					end
				end

				if arg_7_0.keys_[var_7_3] then
					var_7_2[arg_7_0.keys_[var_7_3]] = true
				end
			end
		end
	end

	local var_7_4 = {}

	for iter_7_7, iter_7_8 in pairs(var_7_2) do
		if iter_7_8 then
			table.insert(var_7_4, iter_7_7)
		end
	end

	return var_7_4
end

function var_0_0.recommends(arg_8_0)
	return arg_8_0.recommends_ or {}
end

return var_0_0
