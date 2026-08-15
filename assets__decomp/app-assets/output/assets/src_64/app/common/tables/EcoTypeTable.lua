local var_0_0 = class("EcoTypeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.res_ = {}
	arg_1_0.codeName_ = {}
	arg_1_0.gain_type_ = {}
	arg_1_0.des_ = {}

	import("app.common.tables.TableParser").parse("eco_type.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)
		local var_2_1 = arg_2_0.code_name

		arg_1_0.res_[var_2_1] = arg_2_0.res
		arg_1_0.codeName_[var_2_0] = var_2_1
		arg_1_0.gain_type_[var_2_1] = string.gsub(arg_2_0.gain_type, "|", "\n")
		arg_1_0.des_[var_2_1] = arg_2_0.desc
	end)
end

function var_0_0.getEcoPath(arg_3_0, arg_3_1)
	return arg_3_0.res_[arg_3_1]
end

function var_0_0.getEcoPathByID(arg_4_0, arg_4_1)
	return arg_4_0.res_[arg_4_0.codeName_[arg_4_1]]
end

function var_0_0.getGainDes(arg_5_0, arg_5_1)
	return arg_5_0.gain_type_[arg_5_1]
end

function var_0_0.getDes(arg_6_0, arg_6_1)
	return arg_6_0.des_[arg_6_1]
end

return var_0_0
