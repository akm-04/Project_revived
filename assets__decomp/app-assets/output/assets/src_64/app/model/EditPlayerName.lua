local var_0_0 = class("EditPlayerName", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.nameList = {}
end

function var_0_0.onRegister(arg_2_0)
	print("on registering EditPlayerName")
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.GENERATE_PLAYER_NAME, handler(arg_2_0, arg_2_0.onGeneratePlayerName_))
end

function var_0_0.onGeneratePlayerName_(arg_3_0, arg_3_1)
	arg_3_0.nameList = arg_3_1.params.player_name_list
end

function var_0_0.editPlayerName(arg_4_0, arg_4_1, arg_4_2)
	xyd.Backend.get():request(xyd.mid.EDIT_PLAYER_NAME, arg_4_1, function(arg_5_0, arg_5_1)
		arg_4_2(arg_5_0, arg_5_1)
	end, {}, false, true)
end

function var_0_0.getGenerateName(arg_6_0, arg_6_1)
	xyd.Backend.get():request(xyd.mid.GENERATE_PLAYER_NAME, nil, function(arg_7_0)
		arg_6_1(arg_7_0)
	end, {}, false, true)
end

return var_0_0
