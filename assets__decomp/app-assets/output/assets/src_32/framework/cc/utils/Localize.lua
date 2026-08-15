local var_0_0 = {
	strings = {}
}

function var_0_0.loadStrings(arg_1_0)
	var_0_0.strings = arg_1_0
end

function var_0_0.query(arg_2_0, arg_2_1)
	arg_2_1 = arg_2_1 or arg_2_0

	local var_2_0 = device.language

	if not var_0_0.strings[var_2_0] or not var_0_0.strings[var_2_0][arg_2_0] then
		return arg_2_1
	end

	return var_0_0.strings[var_2_0][arg_2_0]
end

function var_0_0.filename(arg_3_0)
	local var_3_0 = io.pathinfo(arg_3_0)

	return var_3_0.dirname .. var_3_0.basename .. "_" .. device.language .. var_3_0.extname
end

cc = cc or {}
cc.utils = cc.utils or {}
cc.utils.Localize = var_0_0

return var_0_0
