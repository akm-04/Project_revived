local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = 374
local var_0_4 = "skeletons/ui_effect/activity_anniversary/anniversary_candle"
local var_0_5 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.tableID = arg_1_0.activity.table_id
	arg_1_0.startTime = arg_1_0.activity.start_time
	arg_1_0.endTime = arg_1_0.activity.end_time
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

	arg_2_0.container:getChildByName("text_title"):setString(var_0_1:translation("WISH_CANDLE_TIPS_7"))
	arg_2_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_3_0 = {}

			var_3_0.title_name = "ANNIVERSARY_CANDLE_RULE_TITLE"
			var_3_0.rule = "ANNIVERSARY_CANDLE_RULE_TEXT"

			xyd.WindowManager.get():openWindow("text_rule", var_3_0)
		end
	end)
	arg_2_0:loadCandleInfo()
end

function var_0_0.loadCandleInfo(arg_4_0)
	xyd.Backend.get():request(xyd.mid.LOAD_CANDLE_INFO, {}, function(arg_5_0, arg_5_1)
		arg_4_0.actInfo = arg_5_1.act_info
		arg_4_0.wishInfo = arg_5_1.wish_info

		arg_4_0:initCandles()
	end)
end

function var_0_0.openCandleWishWindow(arg_6_0, arg_6_1)
	xyd.Backend.get():request(xyd.mid.LOAD_CANDLE_INFO, {}, function(arg_7_0, arg_7_1)
		arg_6_0.actInfo = arg_7_1.act_info
		arg_6_0.wishInfo = arg_7_1.wish_info
		arg_6_0.serverTime = arg_7_1.server_time

		local var_7_0 = {
			idx = arg_6_1,
			activity_id = xyd.tables.activityCandle:activityID(arg_6_1),
			wish_info = arg_6_0.wishInfo[arg_6_1]
		}
		local var_7_1

		for iter_7_0, iter_7_1 in pairs(arg_6_0.actInfo) do
			if iter_7_1.table_id == var_7_0.activity_id then
				var_7_1 = iter_7_1

				break
			end
		end

		var_7_0.act_info = var_7_1
		var_7_0.table_id = arg_6_0.tableID
		var_7_0.server_time = arg_6_0.serverTime
		var_7_0.start_time = arg_6_0.startTime
		var_7_0.end_time = arg_6_0.endTime

		function var_7_0.callback(arg_8_0)
			arg_6_0.actInfo = arg_8_0.act_info
			arg_6_0.wishInfo = arg_8_0.wish_info

			arg_6_0:initCandles()
		end

		xyd.WindowManager.get():openWindow("wish_candle", var_7_0)
	end)
end

function var_0_0.initCandles(arg_9_0)
	local var_9_0 = arg_9_0.wishInfo
	local var_9_1 = arg_9_0.container:getChildByName("candle_container")

	var_9_1:removeAllChildren()

	local var_9_2 = 10

	for iter_9_0 = 1, #var_9_0 do
		local var_9_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1067/candle_item.csb")

		var_9_3:addTo(var_9_1)
		var_9_3:setAnchorPoint(cc.p(0, 0))
		var_9_3:setPosition(cc.p(var_9_2, 0))

		var_9_2 = var_9_2 + 116

		var_9_3:setName("candle_" .. iter_9_0)
		arg_9_0:updateCandle(iter_9_0, var_9_0[iter_9_0].wish_times)

		local var_9_4 = var_9_3:getChildByName("container")
		local var_9_5 = {
			size = 22,
			outlineColor = cc.c4b(0, 0, 0, 255),
			text = xyd.tables.activityCandle:name(iter_9_0),
			color = cc.c3b(255, 255, 255),
			dimensions = cc.size(117, 0),
			align = cc.ui.TEXT_ALIGN_CENTER
		}
		local var_9_6 = xyd.AssetLoader.get():loadLabel(var_9_5)

		var_9_6:enableOutline(cc.c4b(0, 0, 0, 255), 2)
		var_9_6:setPosition(cc.p(55.56, 33.81))
		var_9_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_4:addChild(var_9_6)
		var_9_4:getChildByName("btn_click"):addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_9_0:openCandleWishWindow(iter_9_0)
			end
		end)
		var_9_4:getChildByName("candle_click"):setTouchEnabled(true)
		var_9_4:getChildByName("candle_click"):addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_9_0:openCandleWishWindow(iter_9_0)
			end
		end)
	end
end

function var_0_0.updateCandle(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = xyd.tables.misc.candleTotal
	local var_12_1 = arg_12_0.container:getChildByName("candle_container"):getChildByName("candle_" .. arg_12_1):getChildByName("container")
	local var_12_2 = arg_12_0.container:getChildByName("candle_container"):getChildByName("candle_" .. arg_12_1):getChildByName("container")
	local var_12_3 = 0

	if var_12_0 <= arg_12_2 then
		var_12_2:getChildByName("blue_candle_body"):setVisible(true)
		var_12_2:getChildByName("blue_candle_top"):setVisible(true)
		var_12_2:getChildByName("red_candle_top"):setVisible(false)
	else
		var_12_2:getChildByName("blue_candle_body"):setVisible(false)
		var_12_2:getChildByName("blue_candle_top"):setVisible(false)

		local var_12_4 = var_12_2:getChildByName("red_candle_top")

		var_12_4:setVisible(true)
		var_12_4:setAnchorPoint(cc.p(0.5, 0.5))

		local var_12_5 = arg_12_2 / var_12_0

		var_12_2:getChildByName("candle_click"):setScaleY(var_12_5)

		local var_12_6 = 1
		local var_12_7 = cc.ProgressTimer:create(cc.Sprite:create("windows/activities/1067/red_candle_body.png"))

		var_12_7:addTo(var_12_2)
		var_12_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_12_7:setPosition(var_12_2:getChildByName("blue_candle_body"):getPosition())
		var_12_7:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		var_12_7:setMidpoint(cc.p(0, 0))
		var_12_7:setBarChangeRate(cc.p(0, 1))

		local var_12_8 = 0.85 * arg_12_2 / var_12_0
		local var_12_9 = var_12_7:getSprite()
		local var_12_10, var_12_11 = var_12_4:getPosition()

		var_12_3 = (0.85 - var_12_8) * var_12_9:getContentSize().height

		var_12_7:setPercentage((var_12_8 + 0.15) * 100)
		var_12_4:setPosition(var_12_4:getPositionX(), var_12_4:getPositionY() - var_12_3)
		var_12_4:setLocalZOrder(100)
	end

	local var_12_12, var_12_13 = var_12_2:getChildByName("flame"):getPosition()

	arg_12_0:showFlame(var_12_2:getChildByName("flame"))
	var_12_2:getChildByName("flame"):setPosition(var_12_12, var_12_13 - var_12_3)
end

function var_0_0.showFlame(arg_13_0, arg_13_1)
	local var_13_0 = 1
	local var_13_1 = var_0_4 .. ".json"
	local var_13_2 = var_0_4 .. ".atlas"
	local var_13_3 = var_0_2.new(var_13_1, var_13_2, 0.8)

	var_13_3:addTo(arg_13_1)
	var_13_3:play(nil, true)
	var_13_3:setPosition(cc.p(41, 0))
	var_13_3:setAnchorPoint(cc.p(0.5, 0))
end

return var_0_0
