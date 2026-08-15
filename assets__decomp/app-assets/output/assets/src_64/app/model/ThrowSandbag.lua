local var_0_0 = class("ThrowSandbag", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.inviteFriendID = 0
	arg_1_0.gameFriendID = 0
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.SANDBAG_INFO, nil, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.baseInfo = arg_4_1.base_info
			arg_3_0.friendInfos = arg_4_1.friend_infos
			arg_3_0.inviteFriendID = 0

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.beginGame(arg_5_0, arg_5_1, arg_5_2)
	xyd.Backend.get():request(xyd.mid.SANDBAG_ENTER, arg_5_1, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			for iter_6_0, iter_6_1 in ipairs(arg_5_0.friendInfos) do
				if iter_6_1.player_info.player_id == arg_5_0.inviteFriendID then
					iter_6_1.invited_time = iter_6_1.invited_time + 1

					break
				end
			end

			arg_5_0.gameFriendID = arg_5_0.inviteFriendID
			arg_5_0.inviteFriendID = 0
			arg_5_0.baseInfo.daily_count = arg_5_0.baseInfo.daily_count + 1
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.startGame(arg_7_0, arg_7_1, arg_7_2)
	xyd.Backend.get():request(xyd.mid.SANDBAG_START, arg_7_1, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK and arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.sendResult(arg_9_0, arg_9_1, arg_9_2)
	xyd.Backend.get():request(xyd.mid.SANDBAG_RESULT, arg_9_1, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK and arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end

		arg_9_0.gameFriendID = 0
	end)
end

function var_0_0.refreshFriendList(arg_11_0, arg_11_1, arg_11_2)
	xyd.Backend.get():request(xyd.mid.SANDBAG_FRIEND_INFO, arg_11_1, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.friendInfos = arg_12_1

			if arg_11_2 then
				arg_11_2(arg_12_0, arg_12_1)
			end
		end
	end)
end

return var_0_0
