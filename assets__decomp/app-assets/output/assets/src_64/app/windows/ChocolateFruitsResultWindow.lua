local var_0_0 = class("ChocolateFruitsResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "skeletons/ui_effect/chocolate_fruit/diglett_gameover"
local var_0_3 = {
	Unlimit = 2,
	Normal = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.chocolate = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.btType = arg_1_2.bt_type
	arg_1_0.score = arg_1_2.score
	arg_1_0.waveNums = arg_1_2.wave_nums
	arg_1_0.awards = arg_1_2.awards or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)

	local var_4_0 = xyd.WindowManager.get():getWindow("chocolate_fruits_main")

	if var_4_0 then
		var_4_0:updateEcos()
	end
end

function var_0_0.initEffect(arg_5_0)
	local var_5_0 = xyd.createEffect(var_0_2)

	var_5_0:addTo(arg_5_0:nodeByName("effect_pos"))
	var_5_0:play(function()
		if var_5_0 and not tolua.isnull(var_5_0) then
			var_5_0:play(nil, false, nil, "texiao02")
		end
	end, false, nil, "texiao01")
end

function var_0_0.layout(arg_7_0)
	arg_7_0:setButtonClick()

	if arg_7_0.btType == 2 then
		arg_7_0:nodeByName("unlimit_container"):setVisible(true)
		arg_7_0:nodeByName("limit_container"):setVisible(false)
		arg_7_0:hideDouebleBtn()
		arg_7_0:nodeByName("score_text8"):setString(var_0_1:translation("GET_POINT_TEXT") .. " " .. arg_7_0.score)
		arg_7_0:nodeByName("score_text1"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT6"))
		arg_7_0:nodeByName("score_text2"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT7"))
		arg_7_0:nodeByName("score_text3"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT8"))
		arg_7_0:nodeByName("score_text4"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT9"))
		arg_7_0:nodeByName("score_text5"):setString(arg_7_0.waveNums or 0)
		arg_7_0:nodeByName("close_limit"):setVisible(true)
		arg_7_0:nodeByName("restart_btn_limit"):setVisible(true)
		arg_7_0:nodeByName("close"):setVisible(false)
		arg_7_0:nodeByName("restart_btn"):setVisible(false)

		local var_7_0 = math.floor(arg_7_0.chocolate.fruit.challenge_times / xyd.tables.misc.activityAnniversaryDiglettChallengeTimes)

		arg_7_0:nodeByName("score_text7"):setString(var_7_0)

		if var_7_0 > 0 then
			-- block empty
		else
			arg_7_0:nodeByName("restart_btn"):setBright(false)
			arg_7_0:nodeByName("restart_btn"):setTouchEnabled(false)
			arg_7_0:nodeByName("restart_btn_limit"):setBright(false)
			arg_7_0:nodeByName("restart_btn_limit"):setTouchEnabled(false)
		end

		local var_7_1 = arg_7_0.awards[1]

		if var_7_1 and var_7_1.item_num > 0 then
			xyd.setItemAndAddTips(arg_7_0:nodeByName("icon_container"), var_7_1.table_id)
			arg_7_0:nodeByName("icon_container"):setScale(0.8)
			arg_7_0:nodeByName("score_text6"):setString("X" .. var_7_1.item_num)
		else
			arg_7_0:nodeByName("score_text3"):setVisible(false)
			arg_7_0:nodeByName("icon_container"):setVisible(false)

			for iter_7_0, iter_7_1 in pairs({
				1,
				2,
				3,
				5,
				6
			}) do
				arg_7_0:nodeByName("score_text" .. iter_7_1):setVisible(false)
			end

			xyd.setPositionBy(arg_7_0:nodeByName("score_text8"), cc.p(80, -80))
		end
	else
		arg_7_0:nodeByName("unlimit_container"):setVisible(false)
		arg_7_0:nodeByName("limit_container"):setVisible(true)
		arg_7_0:nodeByName("score_text"):setString(var_0_1:translation("GET_POINT_TEXT"))
		arg_7_0:nodeByName("score_txt"):setString(arg_7_0.score)
		arg_7_0:nodeByName("double_txt"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT5"))
		arg_7_0:nodeByName("close_limit"):setVisible(false)
		arg_7_0:nodeByName("restart_btn_limit"):setVisible(false)
		arg_7_0:nodeByName("close"):setVisible(true)
		arg_7_0:nodeByName("restart_btn"):setVisible(true)

		local var_7_2 = xyd.tables.misc.activityChocolateFruitDiamondCost
		local var_7_3 = arg_7_0.backpack:getItemNumByID(xyd.tables.misc.activityChocolateFruitItem)
		local var_7_4 = string.format(var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT3"), var_7_2)

		if var_7_3 > 0 then
			var_7_4 = var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT4")

			arg_7_0:nodeByName("yuanbao"):setVisible(false)
			xyd.setItemAndAddTips(arg_7_0:nodeByName("item_icon"), xyd.tables.misc.activityChocolateFruitItem)
		end

		arg_7_0:nodeByName("cost_txt"):setString(var_7_4)

		if arg_7_0.score <= 0 then
			arg_7_0:hideDouebleBtn()
		end
	end
end

function var_0_0.setButtonClick(arg_8_0)
	arg_8_0:nodeByName("close"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("close"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow("chocolate_fruits_catch")
			xyd.WindowManager.get():closeWindow(arg_8_0)
		end
	end)
	arg_8_0:nodeByName("restart_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("restart_btn"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.btType == 1 then
				arg_8_0.chocolate:startFruit()
			else
				arg_8_0.chocolate:startUnlimitFruit()
			end
		end
	end)
	arg_8_0:nodeByName("close_limit"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("close_limit"), arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow("chocolate_fruits_catch")
			xyd.WindowManager.get():closeWindow(arg_8_0)
		end
	end)
	arg_8_0:nodeByName("restart_btn_limit"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("restart_btn_limit"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.btType == 1 then
				arg_8_0.chocolate:startFruit()
			else
				arg_8_0.chocolate:startUnlimitFruit()
			end
		end
	end)
	arg_8_0:nodeByName("double_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("double_btn"), arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = xyd.tables.misc.activityChocolateFritDoubleCost

			if var_13_0 > arg_8_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_14_0 = {}

					var_14_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_14_0)
				end, nil, nil, arg_8_0.colorMode)

				return
			end

			local var_13_1 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_TEN_TIMES_COST_TIP"), var_13_0)

			local function var_13_2()
				local var_15_0 = {}

				arg_8_0.chocolate:chocolateFruitMul(var_15_0, function(arg_16_0, arg_16_1)
					if arg_16_0 == xyd.error.OK then
						arg_8_0:showDoubleResult()
					end
				end)
			end

			local var_13_3 = {
				rcallBefore = 0,
				title = var_0_1:translation("TIP"),
				txt = var_13_1,
				rcallback = var_13_2,
				colorMode = xyd.ColorMode.ACTIVITY,
				align = xyd.ui_align.CENTER,
				valign = xyd.ui_valign.CENTER
			}

			xyd.WindowManager.get():openWindow("alert_green", var_13_3)
		end
	end)
end

function var_0_0.showDoubleResult(arg_17_0)
	local var_17_0 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_DOUBLE_GET_TIP"), arg_17_0.score * 10)
	local var_17_1 = {
		title = var_0_1:translation("TIP"),
		align = xyd.ui_align.CENTER,
		valign = xyd.ui_valign.CENTER
	}

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_17_0, function()
		arg_17_0:hideDouebleBtn()
		arg_17_0:nodeByName("score_txt"):setString(arg_17_0.score * 10)
	end, var_17_1, nil, xyd.ColorMode.ACTIVITY)
end

function var_0_0.hideDouebleBtn(arg_19_0)
	arg_19_0:nodeByName("double_btn"):setVisible(false)
	arg_19_0:nodeByName("double_txt"):setVisible(false)

	local var_19_0 = cc.p(184, 0)

	xyd.setPositionBy(arg_19_0:nodeByName("close"), var_19_0)
	xyd.setPositionBy(arg_19_0:nodeByName("restart_btn"), var_19_0)
	xyd.setPositionBy(arg_19_0:nodeByName("cost_txt"), var_19_0)
	xyd.setPositionBy(arg_19_0:nodeByName("yuanbao"), var_19_0)
	xyd.setPositionBy(arg_19_0:nodeByName("item_icon"), var_19_0)
end

return var_0_0
