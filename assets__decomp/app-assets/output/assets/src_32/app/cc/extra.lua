local var_0_0 = cc or {}

function var_0_0.vertex4f(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
	return {
		x = arg_1_0,
		y = arg_1_1,
		z = arg_1_2,
		w = arg_1_3
	}
end

function var_0_0.v3Fromc3(arg_2_0)
	return {
		x = arg_2_0.r,
		y = arg_2_0.g,
		z = arg_2_0.b
	}
end

function var_0_0.v4Fromc4(arg_3_0)
	return {
		x = arg_3_0.r,
		y = arg_3_0.g,
		z = arg_3_0.b,
		w = arg_3_0.a
	}
end
