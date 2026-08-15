local var_0_0 = import(".BasicLayoutProtocol")
local var_0_1 = class("LayoutProtocol", var_0_0)

function var_0_1.ctor(arg_1_0)
	var_0_1.super.ctor(arg_1_0, "LayoutProtocol")
end

function var_0_1.setLayoutSize(arg_2_0, arg_2_1, arg_2_2)
	var_0_1.super.setLayoutSize(arg_2_0, arg_2_1, arg_2_2)
	arg_2_0:setLayout(arg_2_0.layout_)

	return arg_2_0.target_
end

function var_0_1.setLayout(arg_3_0, arg_3_1)
	arg_3_0.layout_ = arg_3_1

	if arg_3_1 then
		arg_3_1:apply(arg_3_0.target_)
	end

	return arg_3_0.target_
end

function var_0_1.getLayout(arg_4_0)
	return arg_4_0.layout_
end

function var_0_1.exportMethods(arg_5_0)
	var_0_1.super.exportMethods(arg_5_0)
	arg_5_0:exportMethods_({
		"setLayout",
		"getLayout"
	})

	return arg_5_0.target_
end

return var_0_1
