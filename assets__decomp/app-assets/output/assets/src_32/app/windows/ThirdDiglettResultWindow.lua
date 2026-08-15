local var_0_0 = class("ThirdDiglettResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "skeletons/ui_effect/third_anniversary/diglett_gameover"
local var_0_3 = {
	Unlimit = 2,
	Normal = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.thirdAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.btType = arg_1_2.bt_type
	arg_1_0.score = arg_1_2.score
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("score_text"):setString(var_0_1:translation("GET_POINT_TEXT"))
	arg_4_0:nodeByName("score_txt"):setString(arg_4_0.score)
	arg_4_0:setButtonClick()

	if arg_4_0.btType == 2 then
		arg_4_0:nodeByName("restart_btn"):setVisible(false)
		arg_4_0:nodeByName("double_btn"):setVisible(false)
		arg_4_0:nodeByName("close"):setPositionX(arg_4_0:nodeByName("restart_btn"):getPositionX())
		arg_4_0:nodeByName("score_text"):setString(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_UNLIMIT_TIMES"))
		arg_4_0:nodeByName("score_txt"):setString(xyd.secondsToString(arg_4_0.score))
	end

	if arg_4_0.btType == 1 and arg_4_0.score <= 0 then
		arg_4_0:hideDouebleBtn()
	end
end

function var_0_0.setButtonClick(arg_5_0)
	arg_5_0:nodeByName("close"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow("third_diglett_hammer")
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
	arg_5_0:nodeByName("restart_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.thirdAnniversary:startDiglettHammer()
		end
	end)
	arg_5_0:nodeByName("double_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_8_0 = xyd.tables.misc.activityAnniversaryDiglettCost * 9

			if var_8_0 > arg_5_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_9_0 = {}

					var_9_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
				end, nil, nil, arg_5_0.colorMode)

				return
			end

			local var_8_1 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_TEN_TIMES_COST_TIP"), var_8_0)

			local function var_8_2()
				local var_10_0 = {}

				arg_5_0.thirdAnniversary:thirdAnniDiglettDouble(var_10_0, function(arg_11_0, arg_11_1)
					if arg_11_0 == xyd.error.OK then
						arg_5_0:showDoubleResult()
					end
				end)
			end

			local var_8_3 = {
				rcallBefore = 0,
				title = var_0_1:translation("TIP"),
				txt = var_8_1,
				rcallback = var_8_2,
				colorMode = xyd.ColorMode.ACTIVITY,
				align = xyd.ui_align.CENTER,
				valign = xyd.ui_valign.CENTER
			}

			xyd.WindowManager.get():openWindow("alert_green", var_8_3)
		end
	end)
end

function var_0_0.showDoubleResult(arg_12_0)
	local var_12_0 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_DOUBLE_GET_TIP"), arg_12_0.score * 10)

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_12_0, function()
		arg_12_0:hideDouebleBtn()
		arg_12_0:nodeByName("score_txt"):setString(arg_12_0.score * 10)
	end, alertParams, nil, xyd.ColorMode.ACTIVITY)
end

function var_0_0.hideDouebleBtn(arg_14_0)
	arg_14_0:nodeByName("double_btn"):setVisible(false)

	local var_14_0 = 138

	arg_14_0:nodeByName("close"):setPositionX(arg_14_0:nodeByName("close"):getPositionX() + var_14_0)
	arg_14_0:nodeByName("restart_btn"):setPositionX(arg_14_0:nodeByName("restart_btn"):getPositionX() + var_14_0)
end

return var_0_0
