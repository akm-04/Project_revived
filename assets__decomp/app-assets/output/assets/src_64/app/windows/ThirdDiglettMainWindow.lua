local var_0_0 = class("ThirdDiglettMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	Unlimit = 2,
	Normal = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.thirdAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)

	arg_1_0.thirdAnniversary:loadInfo()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.REfRESH_THIRD_DIGLETT_TIMES, function(arg_3_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:updateUnlimitTimes()
		end
	end)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("normal_mode_text"):setString(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_NORMAL_TEXT"))
	arg_5_0:nodeByName("unlimit_mode_text"):setString(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_UNLIMIT_TEXT"))
	arg_5_0:nodeByName("tip_txt1"):setString(string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_NORMAL_TIP"), xyd.tables.misc.activityAnniversaryDiglettCost))
	arg_5_0:nodeByName("rule_txt"):setString(var_0_1:translation("RULE_STATEMENT"))
	arg_5_0:nodeByName("rank_txt"):setString(var_0_1:translation("RANKING_LIST"))
	arg_5_0:nodeByName("exchange_txt"):setString(var_0_1:translation("EXCHANGE_AWARD"))
	arg_5_0:nodeByName("challege_txt1"):setString(var_0_1:translation("CHALLENGE"))
	arg_5_0:nodeByName("challege_txt2"):setString(var_0_1:translation("CHALLENGE"))
	arg_5_0:updateUnlimitTimes()
	arg_5_0:setButtonClick()
end

function var_0_0.updateUnlimitTimes(arg_6_0, ...)
	local var_6_0 = math.floor(arg_6_0.thirdAnniversary.diglettInfo.challenge_times / xyd.tables.misc.activityAnniversaryDiglettChallengeTimes)

	arg_6_0:nodeByName("tip_txt2"):setString(string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_UNLIMIT_TIP"), var_6_0))
end

function var_0_0.setButtonClick(arg_7_0)
	arg_7_0:nodeByName("exchange_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName("exchange_btn"), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("third_diglett_shop")
		end
	end)
	arg_7_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName("rule_btn"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_9_0 = {
				title_name = "ACTIVITY_DIGLETT_RULE_TITLE",
				rule = "ACTIVITY_DIGLETT_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("third_diglett_rule", var_9_0)
		end
	end)
	arg_7_0:nodeByName("challege_btn1"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName("challege_btn1"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_7_0.thirdAnniversary:startDiglettHammer()
		end
	end)
	arg_7_0:nodeByName("challege_btn2"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName("challege_btn2"), arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if math.floor(arg_7_0.thirdAnniversary.diglettInfo.challenge_times / xyd.tables.misc.activityAnniversaryDiglettChallengeTimes) < 1 then
				local var_11_0 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_UNLIMIT_NOTIME_TIP"), xyd.tables.misc.activityAnniversaryDiglettChallengeTimes)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_0
				})

				return
			end

			local var_11_1 = {
				bt_type = var_0_2.Unlimit
			}

			arg_7_0.thirdAnniversary:thirdAnniDiglettStart(var_11_1, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("third_diglett_hammer", arg_12_1)
				end
			end)
		end
	end)
	arg_7_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName("rank_btn"), arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = {}

			arg_7_0.thirdAnniversary:thirdAnniDiglettRank(var_13_0, function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					local var_14_0 = {
						data = arg_14_1
					}

					var_14_0._type = 1

					xyd.WindowManager.get():openWindow("third_diglett_rank", var_14_0)
				end
			end)
		end
	end)
end

return var_0_0
