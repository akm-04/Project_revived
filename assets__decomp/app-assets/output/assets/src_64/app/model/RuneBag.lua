local var_0_0 = class("RuneBag")

local function var_0_1(arg_1_0, arg_1_1)
	if arg_1_0:getSlot() ~= arg_1_1:getSlot() then
		return arg_1_0:getSlot() < arg_1_1:getSlot()
	elseif arg_1_0:getStar() ~= arg_1_1:getStar() then
		return arg_1_0:getStar() < arg_1_1:getStar()
	elseif arg_1_0:getRarity() ~= arg_1_1:getRarity() then
		return arg_1_0:getRarity() < arg_1_1:getRarity()
	else
		return arg_1_0:getRuneID() < arg_1_1:getRuneID()
	end
end

function var_0_0.ctor(arg_2_0)
	arg_2_0.list_ = {}
	arg_2_0.size_ = 0
	arg_2_0.newList_ = {}

	local var_2_0 = xyd.tables.runeset:getSetIDList()

	for iter_2_0, iter_2_1 in pairs(var_2_0) do
		arg_2_0.list_[iter_2_1] = {}
	end
end

function var_0_0.populate(arg_3_0, arg_3_1)
	arg_3_0.size_ = 0

	for iter_3_0, iter_3_1 in pairs(arg_3_0.list_) do
		iter_3_1 = {}
	end

	for iter_3_2, iter_3_3 in pairs(arg_3_1.list) do
		local var_3_0 = import("app.model.Rune"):new()

		var_3_0:populate(iter_3_3)

		local var_3_1 = var_3_0:getSetID()

		table.insert(arg_3_0.list_[var_3_1], var_3_0)

		arg_3_0.size_ = arg_3_0.size_ + 1
	end

	for iter_3_4, iter_3_5 in pairs(arg_3_0.list_) do
		table.sort(iter_3_5, var_0_1)
	end
end

function var_0_0.addRune(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1:getSetID()

	table.insert(arg_4_0.list_[var_4_0], arg_4_1)

	if arg_4_1.isNew then
		arg_4_0.newList_[var_4_0] = true
	end

	table.sort(arg_4_0.list_[var_4_0], var_0_1)

	arg_4_0.size_ = arg_4_0.size_ + 1
end

function var_0_0.addRuneWithRuneInfo(arg_5_0, arg_5_1)
	local var_5_0 = import("app.model.Rune").new()

	var_5_0:populate(arg_5_1)

	var_5_0.isNew = true

	arg_5_0:addRune(var_5_0)

	return var_5_0
end

function var_0_0.getRune(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in pairs(arg_6_0.list_) do
		for iter_6_2, iter_6_3 in pairs(iter_6_1) do
			if iter_6_3:getRuneID() == arg_6_1 then
				return iter_6_3
			end
		end
	end

	return nil
end

function var_0_0.removeRune(arg_7_0, arg_7_1)
	local var_7_0
	local var_7_1

	for iter_7_0, iter_7_1 in pairs(arg_7_0.list_) do
		for iter_7_2, iter_7_3 in pairs(iter_7_1) do
			if iter_7_3:getRuneID() == arg_7_1 then
				var_7_0, var_7_1 = iter_7_0, iter_7_2
			end
		end
	end

	if var_7_0 then
		arg_7_0.size_ = arg_7_0.size_ - 1

		return table.remove(arg_7_0.list_[var_7_0], var_7_1)
	end
end

return var_0_0
