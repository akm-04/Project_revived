local var_0_0 = class("ChocolateFruitsMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	Unlimit = 2,
	Normal = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.chocolate = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)

	arg_1_0.chocolate:chocolateInfo()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.REfRESH_CHOCOLATE_FRUIT_TIMES, function(arg_3_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:updateUnlimitTimes()
		end
	end)

	arg_2_0.stage = arg_2_0.chocolate:getStage()

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.updateEcos(arg_5_0)
	local var_5_0 = arg_5_0.backpack:getItemNumByID(xyd.tables.misc.activityChocolateFruitItem)
	local var_5_1 = arg_5_0.backpack:getItemNumByID(xyd.tables.misc.activityChocolatePoolResetItem)

	arg_5_0:nodeByName("crystal_num"):setString(xyd.num2ThousandsStr(arg_5_0.selfPlayer.crystal))
	arg_5_0:nodeByName("ticket_num"):setString(xyd.num2ThousandsStr(var_5_0))
	arg_5_0:nodeByName("reset_num"):setString(xyd.num2ThousandsStr(var_5_1))
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("normal_mode_text"):setString(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_NORMAL_TEXT"))
	arg_6_0:nodeByName("unlimit_mode_text"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT10"))
	arg_6_0:nodeByName("rule_txt"):setString(var_0_1:translation("RULE_STATEMENT"))
	arg_6_0:nodeByName("rank_txt"):setString(var_0_1:translation("RANKING_LIST"))
	arg_6_0:nodeByName("exchange_txt"):setString(var_0_1:translation("EXCHANGE_AWARD"))
	arg_6_0:nodeByName("challege_txt1"):setString(var_0_1:translation("CHALLENGE"))
	arg_6_0:nodeByName("challege_txt2"):setString(var_0_1:translation("CHALLENGE"))
	arg_6_0:updateUnlimitTimes()
	arg_6_0:setButtonClick()
	arg_6_0:updateEcos()
end

function var_0_0.updateUnlimitTimes(arg_7_0)
	local var_7_0 = math.floor(arg_7_0.chocolate.fruit.challenge_times / xyd.tables.misc.activityAnniversaryDiglettChallengeTimes)
	local var_7_1 = arg_7_0.chocolate.fruit.challenge_times - var_7_0 * xyd.tables.misc.activityAnniversaryDiglettChallengeTimes

	if var_7_0 == 0 then
		arg_7_0:nodeByName("tip_txt2"):setString(string.format(var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT11"), 5 - var_7_1))
	else
		arg_7_0:nodeByName("tip_txt2"):setString(string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_UNLIMIT_TIP"), var_7_0))
	end

	local var_7_2 = arg_7_0.backpack:getItemNumByID(xyd.tables.misc.activityChocolateFruitItem)
	local var_7_3

	if var_7_2 <= 0 then
		var_7_3 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_NORMAL_TIP"), xyd.tables.misc.activityChocolateFruitDiamondCost)
	else
		var_7_3 = var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT1")
	end

	arg_7_0:nodeByName("tip_txt1"):setString(var_7_3)
end

function var_0_0.setButtonClick(arg_8_0)
	arg_8_0:nodeByName("exchange_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("exchange_btn"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("chocolate_fruits_shop")
		end
	end)
	arg_8_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("rule_btn"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_10_0 = {}

			var_10_0.title_name = "ACTIVITY_CHOCOLATE_FRUIT_RULE_TITLE"
			var_10_0.rule = "ACTIVITY_CHOCOLATE_FRUIT_RULE"

			xyd.WindowManager.get():openWindow("new_text_rule", var_10_0)
		end
	end)
	arg_8_0:nodeByName("challege_btn1"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("challege_btn1"), arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_8_0.stage = arg_8_0.chocolate:getStage()

			if arg_8_0.stage == 1 then
				arg_8_0.chocolate:startFruit()
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SAKURA_CLOSED")
				})
			end
		end
	end)
	arg_8_0:nodeByName("challege_btn2"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("challege_btn2"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_8_0.stage = arg_8_0.chocolate:getStage()

			if arg_8_0.stage == 1 then
				arg_8_0.chocolate:startUnlimitFruit()
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SAKURA_CLOSED")
				})
			end
		end
	end)
	arg_8_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("rank_btn"), arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = {}

			arg_8_0.chocolate:chocolateFruitRank(var_13_0, function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					local var_14_0 = {
						data = arg_14_1
					}

					var_14_0._type = 1

					xyd.WindowManager.get():openWindow("chocolate_fruits_rank", var_14_0)
				end
			end)
		end
	end)
end

return var_0_0
