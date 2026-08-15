local var_0_0 = class("CommendWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layOut()
end

function var_0_0.layOut(arg_3_0)
	local var_3_0 = xyd.tables.misc.commendReward

	arg_3_0:nodeByName("award_num"):setString(var_3_0)
	arg_3_0:nodeByName("text1"):setString(var_0_1:translation("COMMENT_DES_1"))
	arg_3_0:nodeByName("text2"):setString(var_0_1:translation("COMMENT_DES_2"))
	arg_3_0:nodeByName("ok"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended and arg_3_0.player.isComment == 0 then
			local var_4_0 = {}

			xyd.Backend.get():request(xyd.mid.GET_COMMENT_AWARD, var_4_0, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					arg_3_0.player.isComment = 1

					local var_5_0 = arg_5_1.awards

					cc.Application:getInstance():openURL(xyd.versionUpdateURL)

					local function var_5_1()
						xyd.WindowManager.get():closeWindow("comment")
					end

					local var_5_2 = {
						awards = var_5_0
					}

					var_0_2.performWithDelayGlobal(function()
						xyd.WindowManager.get():openWindow("alert_award", var_5_2, var_5_1)
					end, 2)
				end
			end)
		end
	end)
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
