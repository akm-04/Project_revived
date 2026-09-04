local var_0_0 = class("SpiritStrthTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.exp_ = {}
	arg_1_0.maxExp_ = {}

	import("app.common.tables.TableParser").parse("spirit_strth.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.star)
		local var_2_1 = tonumber(arg_2_0.lv)

		if not arg_1_0.exp_[var_2_0] then
			arg_1_0.exp_[var_2_0] = {}
			arg_1_0.maxExp_[var_2_0] = {}
		end

		arg_1_0.exp_[var_2_0][var_2_1] = tonumber(arg_2_0.exp)

		if var_2_1 > 1 then
			arg_1_0.maxExp_[var_2_0][var_2_1] = tonumber(arg_2_0.exp) + arg_1_0.maxExp_[var_2_0][var_2_1 - 1]
		else
			arg_1_0.maxExp_[var_2_0][var_2_1] = tonumber(arg_2_0.exp)
		end
	end)
end

function var_0_0.currentLevAndExp(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_0.maxExp_[arg_3_1]
	local var_3_1 = 0
	local var_3_2 = 0

	for iter_3_0, iter_3_1 in ipairs(var_3_0) do
		if iter_3_1 <= arg_3_2 then
			var_3_1 = iter_3_0
		else
			if iter_3_0 > 1 then
				var_3_2 = arg_3_2 - var_3_0[iter_3_0 - 1]

				break
			end

			var_3_2 = arg_3_2

			break
		end
	end

	return var_3_1, var_3_2
end

function var_0_0.exp(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_2 > xyd.HunqiMaxLev then
		arg_4_2 = xyd.HunqiMaxLev
	end

	return arg_4_0.exp_[arg_4_1][arg_4_2]
end

function var_0_0.maxExp(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_2 > xyd.HunqiMaxLev then
		arg_5_2 = xyd.HunqiMaxLev
	end

	return arg_5_0.maxExp_[arg_5_1][arg_5_2]
end

return var_0_0
