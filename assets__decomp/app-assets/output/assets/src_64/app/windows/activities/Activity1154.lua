local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = 374
local var_0_4 = "skeletons/ui_effect/activity_anniversary/anniversary_candle"
local var_0_5 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0.container:getChildByName("text_title"):setString(var_0_1:translation("ACTIVITY_SERVER_CANDLE_WISH_TIPS_1"))
	arg_2_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("activity_new_candle_rule")
		end
	end)
	arg_2_0.container:getChildByName("rank_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.Backend.get():request(xyd.mid.ACTIVITY_NEW_CANDLE_RANK, arg_2_1, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					arg_5_1.self_score = arg_2_0.details.base_info.wish_times

					xyd.WindowManager.get():openWindow("activity_new_candle_rank", arg_5_1)
				end
			end)
		end
	end)
	arg_2_0:initCandles()
end

function var_0_0.openCandleWishWindow(arg_6_0, arg_6_1)
	local var_6_0 = {
		idx = arg_6_1,
		activity = arg_6_0.activity,
		callback = function(arg_7_0)
			arg_6_0:initCandles()
		end
	}

	xyd.WindowManager.get():openWindow("activity_new_wish_candle", var_6_0)
end

function var_0_0.initCandles(arg_8_0)
	local var_8_0 = arg_8_0.details.wish_info
	local var_8_1 = arg_8_0.container:getChildByName("candle_container")

	var_8_1:removeAllChildren()

	local var_8_2 = 10

	for iter_8_0 = 1, #var_8_0 do
		local var_8_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1067/candle_item.csb")

		var_8_3:addTo(var_8_1)
		var_8_3:setAnchorPoint(cc.p(0, 0))
		var_8_3:setPosition(cc.p(var_8_2, 0))

		var_8_2 = var_8_2 + 116

		var_8_3:setName("candle_" .. iter_8_0)
		arg_8_0:updateCandle(iter_8_0, var_8_0[iter_8_0].wish_times)

		local var_8_4 = var_8_3:getChildByName("container")
		local var_8_5 = {
			size = 22,
			outlineColor = cc.c4b(0, 0, 0, 255),
			text = xyd.tables.activityServerCandle:name(iter_8_0),
			color = cc.c3b(255, 255, 255),
			dimensions = cc.size(117, 0),
			align = cc.ui.TEXT_ALIGN_CENTER
		}
		local var_8_6 = xyd.AssetLoader.get():loadLabel(var_8_5)

		var_8_6:enableOutline(cc.c4b(0, 0, 0, 255), 2)
		var_8_6:setPosition(cc.p(55.56, 33.81))
		var_8_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_4:addChild(var_8_6)
		var_8_4:getChildByName("btn_click"):addTouchEventListener(function(arg_9_0, arg_9_1)
			if arg_9_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_8_0:openCandleWishWindow(iter_8_0)
			end
		end)
		var_8_4:getChildByName("candle_click"):setTouchEnabled(true)
		var_8_4:getChildByName("candle_click"):addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_8_0:openCandleWishWindow(iter_8_0)
			end
		end)
	end
end

function var_0_0.updateCandle(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = xyd.tables.misc.activityServerCandleTotal
	local var_11_1 = arg_11_0.container:getChildByName("candle_container"):getChildByName("candle_" .. arg_11_1):getChildByName("container")
	local var_11_2 = arg_11_0.container:getChildByName("candle_container"):getChildByName("candle_" .. arg_11_1):getChildByName("container")
	local var_11_3 = 0

	if var_11_0 <= arg_11_2 then
		var_11_2:getChildByName("blue_candle_body"):setVisible(true)
		var_11_2:getChildByName("blue_candle_top"):setVisible(true)
		var_11_2:getChildByName("red_candle_top"):setVisible(false)
	else
		var_11_2:getChildByName("blue_candle_body"):setVisible(false)
		var_11_2:getChildByName("blue_candle_top"):setVisible(false)

		local var_11_4 = var_11_2:getChildByName("red_candle_top")

		var_11_4:setVisible(true)
		var_11_4:setAnchorPoint(cc.p(0.5, 0.5))

		local var_11_5 = arg_11_2 / var_11_0

		var_11_2:getChildByName("candle_click"):setScaleY(var_11_5)

		local var_11_6 = 1
		local var_11_7 = cc.ProgressTimer:create(cc.Sprite:create("windows/activities/1067/red_candle_body.png"))

		var_11_7:addTo(var_11_2)
		var_11_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_11_7:setPosition(var_11_2:getChildByName("blue_candle_body"):getPosition())
		var_11_7:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		var_11_7:setMidpoint(cc.p(0, 0))
		var_11_7:setBarChangeRate(cc.p(0, 1))

		local var_11_8 = 0.85 * arg_11_2 / var_11_0
		local var_11_9 = var_11_7:getSprite()
		local var_11_10, var_11_11 = var_11_4:getPosition()

		var_11_3 = (0.85 - var_11_8) * var_11_9:getContentSize().height

		var_11_7:setPercentage((var_11_8 + 0.15) * 100)
		var_11_4:setPosition(var_11_4:getPositionX(), var_11_4:getPositionY() - var_11_3)
		var_11_4:setLocalZOrder(100)
	end

	local var_11_12, var_11_13 = var_11_2:getChildByName("flame"):getPosition()

	arg_11_0:showFlame(var_11_2:getChildByName("flame"))
	var_11_2:getChildByName("flame"):setPosition(var_11_12, var_11_13 - var_11_3)
end

function var_0_0.showFlame(arg_12_0, arg_12_1)
	local var_12_0 = 1
	local var_12_1 = var_0_4 .. ".json"
	local var_12_2 = var_0_4 .. ".atlas"
	local var_12_3 = var_0_2.new(var_12_1, var_12_2, 0.8)

	var_12_3:addTo(arg_12_1)
	var_12_3:play(nil, true)
	var_12_3:setPosition(cc.p(41, 0))
	var_12_3:setAnchorPoint(cc.p(0.5, 0))
end

return var_0_0
