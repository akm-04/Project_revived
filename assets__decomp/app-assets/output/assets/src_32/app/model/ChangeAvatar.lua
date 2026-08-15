local var_0_0 = class("ChangeAvatar", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_1_0:getAvatarOrder()
end

function var_0_0.changeAvatar(arg_2_0, arg_2_1, arg_2_2)
	xyd.Backend.get():request(xyd.mid.SET_AVATAR_ID, arg_2_1, function(arg_3_0, arg_3_1)
		arg_2_2(arg_3_0, arg_3_1)
	end, {}, false, true)
end

function var_0_0.buyAvatar(arg_4_0, arg_4_1, arg_4_2)
	xyd.Backend.get():request(xyd.mid.BUY_AVATAR, arg_4_1, function(arg_5_0)
		arg_4_2(arg_5_0)
	end)
end

function var_0_0.editAvatarFrame(arg_6_0, arg_6_1, arg_6_2)
	xyd.Backend.get():request(xyd.mid.EDIT_AVATAR_RRAME, arg_6_1, function(arg_7_0)
		arg_6_2(arg_7_0)
	end)
end

function var_0_0.setAvatarOrder(arg_8_0, arg_8_1)
	arg_8_0.avatarOrderStr = tostring(arg_8_1[1])

	for iter_8_0 = 2, #arg_8_1 do
		arg_8_0.avatarOrderStr = arg_8_0.avatarOrderStr .. "@" .. arg_8_1[iter_8_0]
	end

	local var_8_0 = {
		playerID = arg_8_0.selfPlayer.playerID,
		name = xyd.state.CHANGE_AVATAR_ORDER,
		state = arg_8_0.avatarOrderStr
	}

	xyd.db.stateVariable:setState(var_8_0)
end

function var_0_0.getAvatarOrder(arg_9_0)
	local var_9_0 = xyd.db.stateVariable:getState(arg_9_0.selfPlayer.playerID, xyd.state.CHANGE_AVATAR_ORDER)

	if var_9_0 == 0 then
		arg_9_0.avatarOrderStr = "1@1@1@1@1"
	else
		arg_9_0.avatarOrderStr = var_9_0
	end

	arg_9_0.avatarOrder = xyd.splitToNumber(arg_9_0.avatarOrderStr, "@")
end

return var_0_0
