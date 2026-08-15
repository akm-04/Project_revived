local var_0_0 = class("SureDeleteFriendWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.data = arg_1_2.data
	arg_1_0.friendID = arg_1_0.data.player_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("ok_text"):setString(var_0_1:translation("OK"))
	arg_4_0:nodeByName("close_text"):setString(var_0_1:translation("CANCEL"))
	arg_4_0:nodeByName("title"):setString(var_0_1:translation("TIP"))
	arg_4_0:nodeByName("tips_txt"):setString(var_0_1:translation("SURE_DELETE_FRIEND_TEXT"))

	if arg_4_0.data.conquer_lev and arg_4_0.data.conquer_lev > 0 then
		xyd.setConquerLev(arg_4_0.data.conquer_lev, arg_4_0:nodeByName("lev_txt"), arg_4_0:nodeByName("dengjiquan"), nil, nil, nil, nil, arg_4_0.data.conquer_loop_id)
	else
		arg_4_0:nodeByName("lev_txt"):setString(arg_4_0.data.lev)
	end

	arg_4_0:nodeByName("name_txt"):setString(arg_4_0.data.player_name)
	arg_4_0.socialSystem:setOnlineState(arg_4_0:nodeByName("friend_state_txt"), arg_4_0.data)
	arg_4_0:nodeByName("region_txt"):setString("S" .. xyd.getPlayerRegion(arg_4_0.data.player_id))

	local var_4_0 = {
		avatar_id = arg_4_0.data.avatar_id,
		avatar_frame_id = arg_4_0.data.avatar_frame_id
	}

	xyd.setPlayerAvatar(arg_4_0:nodeByName("avtar_container"), var_4_0)
	arg_4_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {
				player_id = arg_4_0.friendID
			}

			arg_4_0.socialSystem:deleteFriend(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					xyd.db.friendMessages:deleteFriendMessage(arg_4_0.selfPlayer.playerID, arg_4_0.friendID)
					arg_4_0.callback()
					xyd.WindowManager.get():closeWindow(arg_4_0)
				else
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
end

return var_0_0
