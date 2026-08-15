local var_0_0 = class("BaseModel", cc.mvc.ModelBase)

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	return
end

function var_0_0.registerEvent(arg_3_0, arg_3_1, arg_3_2)
	xyd.EventDispatcher.get():addEventListener(arg_3_1, arg_3_2)
end

return var_0_0
