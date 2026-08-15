local var_0_0 = class("ActivityKiteQuestionTable ")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.image_ = {}
	arg_1_0.scale_ = {}

	import("app.common.tables.TableParser").parse("activity_kite_location.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.image_[var_2_0] = arg_2_0.image
		arg_1_0.scale_[var_2_0] = arg_2_0.scale
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.image(arg_4_0, arg_4_1)
	return arg_4_0.image_[arg_4_1] or " "
end

function var_0_0.scale(arg_5_0, arg_5_1)
	return arg_5_0.scale_[arg_5_1] or " "
end

function var_0_0.allcount(arg_6_0)
	return #arg_6_0.name_
end

return var_0_0
