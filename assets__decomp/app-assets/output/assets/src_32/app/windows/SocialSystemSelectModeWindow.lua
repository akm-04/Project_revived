local var_0_0 = class("SocialSystemSelectModeWindow", import("app.common.ui.BaseWindow"))
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
	arg_1_0.friendID = arg_1_2.friend_id
	arg_1_0.mode = var_0_2.Common
	arg_1_0.gameType = var_0_3.ONE_TIME
	arg_1_0.boutNums = 1
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
	arg_4_0:nodeByName("mode_text"):setString(var_0_1:translation("MODE_TEXT"))
	arg_4_0:nodeByName("select_mode_text"):setString(var_0_1:translation("SELECT_MODE_TEXT"))
	arg_4_0:nodeByName("bout_num_text"):setString(var_0_1:translation("BOUT_NUM_TEXT"))
	arg_4_0:nodeByName("common_mode_text"):setString(var_0_1:translation("COMMON_MODE_TEXT"))
	arg_4_0:nodeByName("cross_mode_text"):setString(var_0_1:translation("CROSS_MODE_TEXT"))
	arg_4_0:nodeByName("best_of_one_text"):setString(var_0_1:translation("BEST_OF_ONE_TEXT"))
	arg_4_0:nodeByName("best_of_three_text"):setString(var_0_1:translation("BEST_OF_THREE_TEXT"))
	arg_4_0:nodeByName("ok_text"):setString(var_0_1:translation("OK"))
	arg_4_0:nodeByName("cancle_text"):setString(var_0_1:translation("CANCEL"))
	arg_4_0:nodeByName("common_mode_btn"):getChildByName("choose"):setVisible(true)
	arg_4_0:nodeByName("best_of_one_btn"):getChildByName("choose"):setVisible(true)
	arg_4_0:nodeByName("common_mode_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.mode = var_0_2.Common

			arg_4_0:nodeByName("common_mode_btn"):getChildByName("choose"):setVisible(true)
			arg_4_0:nodeByName("cross_mode_btn"):getChildByName("choose"):setVisible(false)
		end
	end)
	arg_4_0:nodeByName("cross_mode_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			arg_4_0.mode = var_0_2.Cross

			arg_4_0:nodeByName("common_mode_btn"):getChildByName("choose"):setVisible(false)
			arg_4_0:nodeByName("cross_mode_btn"):getChildByName("choose"):setVisible(true)
		end
	end)
	arg_4_0:nodeByName("best_of_one_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			arg_4_0.gameType = var_0_3.ONE_TIME

			arg_4_0:nodeByName("best_of_one_btn"):getChildByName("choose"):setVisible(true)
			arg_4_0:nodeByName("best_of_three_btn"):getChildByName("choose"):setVisible(false)
		end
	end)
	arg_4_0:nodeByName("best_of_three_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_4_0.gameType = var_0_3.THREE_TIMES

			arg_4_0:nodeByName("best_of_one_btn"):getChildByName("choose"):setVisible(false)
			arg_4_0:nodeByName("best_of_three_btn"):getChildByName("choose"):setVisible(true)
		end
	end)
	arg_4_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0 = {
				player_id = arg_4_0.friendID,
				model = arg_4_0.mode,
				game_type = arg_4_0.gameType
			}

			arg_4_0.socialSystem:compare(var_9_0, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("social_system_waiting", var_9_0)
				end
			end)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

return var_0_0
