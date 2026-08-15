local var_0_0 = class("ObjectBranchTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.nameIcon_ = {}
	arg_1_0.bookIcon_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.winName_ = {}
	arg_1_0.isOpen_ = {}

	import("app.common.tables.TableParser").parse("object_branch.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.nameIcon_[var_2_0] = arg_2_0.name_icon
		arg_1_0.bookIcon_[var_2_0] = arg_2_0.book_icon
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.winName_[var_2_0] = arg_2_0.win_name
		arg_1_0.isOpen_[var_2_0] = tonumber(arg_2_0.is_open)
	end)
end

function var_0_0.nameIcon(arg_3_0, arg_3_1)
	return arg_3_0.nameIcon_[arg_3_1] or ""
end

function var_0_0.bookIcon(arg_4_0, arg_4_1)
	return arg_4_0.bookIcon_[arg_4_1] or ""
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or ""
end

function var_0_0.winName(arg_6_0, arg_6_1)
	return arg_6_0.winName_[arg_6_1] or ""
end

function var_0_0.isOpen(arg_7_0, arg_7_1)
	return arg_7_0.isOpen_[arg_7_1] or 0
end

function var_0_0.getBranchCounts(arg_8_0)
	return #arg_8_0.isOpen_
end

return var_0_0
