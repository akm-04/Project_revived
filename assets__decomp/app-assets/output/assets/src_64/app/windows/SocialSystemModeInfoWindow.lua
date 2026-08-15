local var_0_0 = class("SocialSystemModeInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	Common = 1,
	Cross = 2
}
local var_0_3 = {
	THREE_TIMES = 2,
	ONE_TIME = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.params = arg_1_2
	arg_1_0.friendID = arg_1_2.player_info.player_id
	arg_1_0.friendName = arg_1_2.player_info.player_name or "XX"
	arg_1_0.mode = arg_1_2.model
	arg_1_0.game_type = arg_1_2.game_type
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("mode_text"):setString(var_0_1:translation("MODE_TEXT"))
	arg_4_0:nodeByName("bout_num_text"):setString(var_0_1:translation("BOUT_NUM_TEXT"))
	arg_4_0:nodeByName("friend_invite_text"):setString(string.format(var_0_1:translation("FRIEND_INVITE_TEXT"), arg_4_0.friendName))

	if arg_4_0.mode == var_0_2.Common then
		arg_4_0:nodeByName("mode_txt"):setString(var_0_1:translation("COMMON_MODE_TEXT"))
	else
		arg_4_0:nodeByName("mode_txt"):setString(var_0_1:translation("CROSS_MODE_TEXT"))
	end

	if arg_4_0.game_type == var_0_3.ONE_TIME then
		arg_4_0:nodeByName("bout_num_txt"):setString(var_0_1:translation("BEST_OF_ONE_TEXT"))
	else
		arg_4_0:nodeByName("bout_num_txt"):setString(var_0_1:translation("BEST_OF_THREE_TEXT"))
	end

	arg_4_0:nodeByName("accept_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {
				player_id = arg_4_0.friendID,
				model = arg_4_0.mode,
				game_type = arg_4_0.game_type
			}

			arg_4_0.socialSystem:acceptFrientFight(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					-- block empty
				end
			end)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("reject_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {
				player_id = arg_4_0.friendID
			}

			arg_4_0.socialSystem:rejectFriendFight(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
end

return var_0_0
