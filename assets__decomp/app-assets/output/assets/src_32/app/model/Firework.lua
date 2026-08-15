local var_0_0 = class("Firework", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.loaded_ = false
	arg_1_0.activity = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadActivityInfo(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0.activity = arg_3_0.activities:getActivityInfo(xyd.Activities.FIREWORK)

	if arg_3_2 then
		arg_3_2()
	end
end

function var_0_0.takePhoto(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_1 or {}

	xyd.Backend.get():request(xyd.mid.FIREWORK_TAKE_PHOTO, var_4_0, function(arg_5_0, arg_5_1, arg_5_2)
		if arg_4_2 then
			arg_4_2(arg_5_0, arg_5_1)
		end
	end)
end

function var_0_0.sendFirework(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_1 or {}

	xyd.Backend.get():request(xyd.mid.FIREWORK_SEND, var_6_0, function(arg_7_0, arg_7_1, arg_7_2)
		if arg_6_2 then
			arg_6_2(arg_7_0, arg_7_1)
		end
	end)
end

return var_0_0
