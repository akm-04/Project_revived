local var_0_0 = class("ActivityExchangeShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.activityTurntableExchange
local var_0_4 = 1
local var_0_5 = 2
local var_0_6 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_1_2 and arg_1_2.lucky_star then
		arg_1_0.lucky_star = arg_1_2.lucky_star
	end

	if arg_1_2 and arg_1_2.callback then
		arg_1_0.useLuckyStar = arg_1_2.callback
	end

	arg_1_0.startTime = arg_1_2.startTime
	arg_1_0.endTime = arg_1_2.endTime
	arg_1_0.serverTime = arg_1_2.serverTime or 0
	arg_1_0.is_open = arg_1_2.is_open
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setInfos()
	arg_4_0:setPictures()
	arg_4_0:registerListener()
end

function var_0_0.registerListener(arg_5_0)
	for iter_5_0 = 1, 3 do
		arg_5_0:nodeByName("button" .. iter_5_0):addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.began then
				-- block empty
			elseif arg_6_1 == ccui.TouchEventType.canceled then
				-- block empty
			elseif arg_6_1 == ccui.TouchEventType.ended then
				arg_5_0:buyItemById(iter_5_0)
			end
		end)
	end
end

function var_0_0.checkActivity(arg_7_0)
	if arg_7_0.startTime > arg_7_0.serverTime then
		local var_7_0 = var_0_1:translation("ACTIVITY_NO_OPEN")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_7_0
		})
	elseif arg_7_0.endTime < arg_7_0.serverTime then
		local var_7_1 = var_0_1:translation("ACTIVITY_FINISHED")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_7_1
		})
	end
end

function var_0_0.setInfos(arg_8_0)
	arg_8_0:nodeByName("num_"):setString(arg_8_0.lucky_star)
	arg_8_0:nodeByName("num_txt"):setString(var_0_1:translation("NUM_TXT"))

	for iter_8_0 = 1, 3 do
		arg_8_0:nodeByName("num" .. iter_8_0):setString(var_0_3:cost(iter_8_0))
	end
end

function var_0_0.buyItemById(arg_9_0, arg_9_1)
	if arg_9_0.is_open == 0 then
		arg_9_0:checkActivity()

		return
	end

	if arg_9_0.lucky_star <= 0 then
		local var_9_0 = var_0_1:translation("LUCKY_STAR_NOT_ENOUGH")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_9_0
		})

		return
	end

	local var_9_1 = {
		exchange_id = arg_9_1
	}

	xyd.Backend.get():request(xyd.mid.EXCHANGE_ROLL_ITEM, var_9_1, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.selfPlayer:handleRewards(arg_10_1.awards)

			arg_9_0.lucky_star = arg_9_0.lucky_star - var_0_3:cost(arg_9_1)

			if arg_9_0.useLuckyStar then
				arg_9_0.useLuckyStar(var_0_3:cost(arg_9_1))
			end

			arg_9_0:setInfos()
		end
	end)
end

function var_0_0.setPictures(arg_11_0)
	for iter_11_0 = 1, 3 do
		local var_11_0 = "windows/activities/spring_dial/shop/" .. iter_11_0 .. ".png"
		local var_11_1 = xyd.AssetLoader.get():loadSprite(var_11_0)
		local var_11_2 = arg_11_0:nodeByName("icon_" .. iter_11_0):getContentSize().width
		local var_11_3 = arg_11_0:nodeByName("icon_" .. iter_11_0):getContentSize().height

		var_11_1:setPosition(var_11_2 / 2, var_11_3 / 2)
		var_11_1:setAnchorPoint(cc.p(0.5, 0.5))
		arg_11_0:nodeByName("icon_" .. iter_11_0):addChild(var_11_1)
	end
end

function var_0_0.willClose(arg_12_0, arg_12_1)
	return
end

function var_0_0.didClose(arg_13_0, arg_13_1)
	return
end

return var_0_0
