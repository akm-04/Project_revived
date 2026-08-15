local var_0_0 = class("ObjectBookColorTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.color_ = {}
	arg_1_0.proficiency_ = {}
	arg_1_0.totalProficiency_ = {}
	arg_1_0.bookReturn_ = {}
	arg_1_0.bookNumb_ = {}

	import("app.common.tables.TableParser").parse("object_book_color.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.color_[var_2_0] = tonumber(arg_2_0.color)
		arg_1_0.proficiency_[var_2_0] = tonumber(arg_2_0.proficiency)
		arg_1_0.totalProficiency_[var_2_0] = tonumber(arg_2_0.total_proficiency)
		arg_1_0.bookReturn_[var_2_0] = xyd.splitToNumber(arg_2_0.book_return, "|")
		arg_1_0.bookNumb_[var_2_0] = xyd.splitToNumber(arg_2_0.book_numb, "|")
	end)
end

function var_0_0.color(arg_3_0, arg_3_1)
	return arg_3_0.color_[arg_3_1] or 0
end

function var_0_0.proficiency(arg_4_0, arg_4_1)
	return arg_4_0.proficiency_[arg_4_1] or 0
end

function var_0_0.totalProficiency(arg_5_0, arg_5_1)
	return arg_5_0.totalProficiency_[arg_5_1] or 0
end

function var_0_0.bookReturn(arg_6_0, arg_6_1)
	return arg_6_0.bookReturn_[arg_6_1] or {}
end

function var_0_0.bookNumb(arg_7_0, arg_7_1)
	return arg_7_0.bookNumb_[arg_7_1] or {}
end

function var_0_0.getColorByProficiency(arg_8_0, arg_8_1)
	for iter_8_0 = 1, #arg_8_0.totalProficiency_ do
		if arg_8_1 < arg_8_0.totalProficiency_[iter_8_0] then
			return iter_8_0 - 1
		end
	end

	return arg_8_0:maxColorLev()
end

function var_0_0.maxColorLev(arg_9_0)
	return #arg_9_0.totalProficiency_
end

function var_0_0.maxTotalProficiency(arg_10_0)
	return arg_10_0.totalProficiency_[arg_10_0:maxColorLev()]
end

return var_0_0
