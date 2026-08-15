local function var_0_0(arg_1_0)
	if arg_1_0 - math.floor(arg_1_0) > 0 then
		error("trying to use bitwise operation on non-integer!")
	end
end

local function var_0_1(arg_2_0)
	var_0_0(arg_2_0)

	if arg_2_0 < 0 then
		return var_0_1(bit.bnot(math.abs(arg_2_0)) + 1)
	end

	local var_2_0 = {}
	local var_2_1 = 1

	while arg_2_0 > 0 do
		local var_2_2 = math.mod(arg_2_0, 2)

		if var_2_2 == 1 then
			var_2_0[var_2_1] = 1
		else
			var_2_0[var_2_1] = 0
		end

		arg_2_0 = (arg_2_0 - var_2_2) / 2
		var_2_1 = var_2_1 + 1
	end

	return var_2_0
end

local function var_0_2(arg_3_0)
	local var_3_0 = table.getn(arg_3_0)
	local var_3_1 = 0
	local var_3_2 = 1

	for iter_3_0 = 1, var_3_0 do
		var_3_1 = var_3_1 + arg_3_0[iter_3_0] * var_3_2
		var_3_2 = var_3_2 * 2
	end

	return var_3_1
end

local function var_0_3(arg_4_0, arg_4_1)
	local var_4_0 = {}
	local var_4_1 = {}

	if table.getn(arg_4_0) > table.getn(arg_4_1) then
		var_4_0 = arg_4_0
		var_4_1 = arg_4_1
	else
		var_4_0 = arg_4_1
		var_4_1 = arg_4_0
	end

	for iter_4_0 = table.getn(var_4_1) + 1, table.getn(var_4_0) do
		var_4_1[iter_4_0] = 0
	end
end

local function var_0_4(arg_5_0, arg_5_1)
	local var_5_0 = var_0_1(arg_5_0)
	local var_5_1 = var_0_1(arg_5_1)

	var_0_3(var_5_0, var_5_1)

	local var_5_2 = {}
	local var_5_3 = math.max(table.getn(var_5_0), table.getn(var_5_1))

	for iter_5_0 = 1, var_5_3 do
		if var_5_0[iter_5_0] == 0 and var_5_1[iter_5_0] == 0 then
			var_5_2[iter_5_0] = 0
		else
			var_5_2[iter_5_0] = 1
		end
	end

	return var_0_2(var_5_2)
end

local function var_0_5(arg_6_0, arg_6_1)
	local var_6_0 = var_0_1(arg_6_0)
	local var_6_1 = var_0_1(arg_6_1)

	var_0_3(var_6_0, var_6_1)

	local var_6_2 = {}
	local var_6_3 = math.max(table.getn(var_6_0), table.getn(var_6_1))

	for iter_6_0 = 1, var_6_3 do
		if var_6_0[iter_6_0] == 0 or var_6_1[iter_6_0] == 0 then
			var_6_2[iter_6_0] = 0
		else
			var_6_2[iter_6_0] = 1
		end
	end

	return var_0_2(var_6_2)
end

local function var_0_6(arg_7_0)
	local var_7_0 = var_0_1(arg_7_0)
	local var_7_1 = math.max(table.getn(var_7_0), 32)

	for iter_7_0 = 1, var_7_1 do
		if var_7_0[iter_7_0] == 1 then
			var_7_0[iter_7_0] = 0
		else
			var_7_0[iter_7_0] = 1
		end
	end

	return var_0_2(var_7_0)
end

local function var_0_7(arg_8_0, arg_8_1)
	local var_8_0 = var_0_1(arg_8_0)
	local var_8_1 = var_0_1(arg_8_1)

	var_0_3(var_8_0, var_8_1)

	local var_8_2 = {}
	local var_8_3 = math.max(table.getn(var_8_0), table.getn(var_8_1))

	for iter_8_0 = 1, var_8_3 do
		if var_8_0[iter_8_0] ~= var_8_1[iter_8_0] then
			var_8_2[iter_8_0] = 1
		else
			var_8_2[iter_8_0] = 0
		end
	end

	return var_0_2(var_8_2)
end

local function var_0_8(arg_9_0, arg_9_1)
	var_0_0(arg_9_0)

	local var_9_0 = 0

	if arg_9_0 < 0 then
		arg_9_0 = var_0_6(math.abs(arg_9_0)) + 1
		var_9_0 = 2147483648
	end

	for iter_9_0 = 1, arg_9_1 do
		arg_9_0 = arg_9_0 / 2
		arg_9_0 = var_0_4(math.floor(arg_9_0), var_9_0)
	end

	return math.floor(arg_9_0)
end

local function var_0_9(arg_10_0, arg_10_1)
	var_0_0(arg_10_0)

	if arg_10_0 < 0 then
		arg_10_0 = var_0_6(math.abs(arg_10_0)) + 1
	end

	for iter_10_0 = 1, arg_10_1 do
		arg_10_0 = arg_10_0 / 2
	end

	return math.floor(arg_10_0)
end

local function var_0_10(arg_11_0, arg_11_1)
	var_0_0(arg_11_0)

	if arg_11_0 < 0 then
		arg_11_0 = var_0_6(math.abs(arg_11_0)) + 1
	end

	for iter_11_0 = 1, arg_11_1 do
		arg_11_0 = arg_11_0 * 2
	end

	return var_0_5(arg_11_0, 4294967295)
end

local function var_0_11(arg_12_0, arg_12_1)
	local var_12_0 = var_0_4(var_0_6(arg_12_0), var_0_6(arg_12_1))
	local var_12_1 = var_0_4(arg_12_0, arg_12_1)

	return (var_0_5(var_12_1, var_12_0))
end

bit = {
	bnot = var_0_6,
	band = var_0_5,
	bor = var_0_4,
	bxor = var_0_7,
	brshift = var_0_8,
	blshift = var_0_10,
	bxor2 = var_0_11,
	blogic_rshift = var_0_9,
	tobits = var_0_1,
	tonumb = var_0_2
}
