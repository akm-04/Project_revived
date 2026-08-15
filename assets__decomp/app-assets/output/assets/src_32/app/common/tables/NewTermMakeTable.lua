local var_0_0 = class("NewTermMakeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.combination_ = {}

	import("app.common.tables.TableParser").parse("activity_lianyi_make.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.combination_[var_2_0] = xyd.splitToNumber(arg_2_0.combination, "|")
	end)
end

function var_0_0.getIDByItems(arg_3_0, arg_3_1)
	for iter_3_0, iter_3_1 in pairs(arg_3_0.combination_) do
		local var_3_0 = clone(iter_3_1)

		for iter_3_2, iter_3_3 in pairs(arg_3_1) do
			for iter_3_4, iter_3_5 in pairs(var_3_0) do
				if iter_3_3 == iter_3_5 then
					table.remove(var_3_0, iter_3_4)

					break
				end
			end
		end

		if #var_3_0 == 0 then
			return iter_3_0
		end
	end
end

function var_0_0.combination(arg_4_0, arg_4_1)
	return arg_4_0.combination_[arg_4_1] or {
		0,
		0,
		0
	}
end

return var_0_0
