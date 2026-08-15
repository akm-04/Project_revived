local var_0_0 = class("LotteryChangeConsumeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = require("framework.scheduler")
local var_0_4 = xyd.tables.activityLotteryConsumeShop

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.listInfo = {}
	arg_1_0.score = arg_1_2.score
	arg_1_0.details = arg_1_2.details
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	return
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)

	if arg_4_0.handle_ then
		var_0_3.unscheduleGlobal(arg_4_0.handle_)

		arg_4_0.handle_ = nil
	end
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("list_container")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.list:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0:updateListInfo()
	arg_5_0.list:reload()
	arg_5_0:updateScore()
	arg_5_0:nodeByName("close"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_6_0:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.moved then
			arg_6_0:setScale(1)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			arg_6_0:setScale(1)
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
end

function var_0_0.updateScore(arg_7_0)
	arg_7_0:nodeByName("change_title"):setString(var_0_1:translation("LETOU_SHOP"))
	arg_7_0:nodeByName("score"):setString(var_0_1:translation("LOTTERY_CONSUME_TEXT6") .. arg_7_0.score)
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevX_ = arg_8_1.x
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" then
		local var_8_0 = 3

		if var_8_0 <= math.abs(arg_8_1.y - arg_8_0.prevY_) or var_8_0 <= math.abs(arg_8_1.x - arg_8_0.prevX_) then
			arg_8_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.updateListInfo(arg_9_0)
	arg_9_0.listInfo = var_0_4:getIds()
end

function var_0_0.delegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #arg_10_0.listInfo
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0 = arg_10_0.list:dequeueItem()

		if not var_10_0 then
			var_10_0 = arg_10_0.list:newItem()
		else
			var_10_0:removeAllChildren(true)
		end

		local var_10_1 = 851
		local var_10_2 = 150

		var_10_0:setItemSize(var_10_1, var_10_2)

		local var_10_3 = display.newNode()

		var_10_3:setContentSize(var_10_1, 134)
		arg_10_0:initCell(var_10_3, arg_10_3)
		var_10_0:addContent(var_10_3)

		return var_10_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_10_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_11_0, arg_11_1, arg_11_2)
	if arg_11_2 > #arg_11_0.listInfo then
		return
	end

	local var_11_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1148/lottery_change_item.csb")

	var_11_0:setPosition(0, 0)
	arg_11_1:addChild(var_11_0)

	local var_11_1 = var_11_0:getChildByName("bg")
	local var_11_2 = var_0_4:item(arg_11_0.listInfo[arg_11_2])

	xyd.setItemBorder(var_11_1:getChildByName("item"), var_11_2, false, false, var_0_4:itemNum(arg_11_0.listInfo[arg_11_2]))
	var_11_0:getChildByName("bg"):getChildByName("btn_change"):getChildByName("text_change"):setString(var_0_1:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT2"))

	if var_0_4:vipLimit(arg_11_0.listInfo[arg_11_2]) > 0 then
		local var_11_3 = xyd.AssetLoader.get():loadSprite("windows/activities/1148/v" .. var_0_4:vipLimit(arg_11_0.listInfo[arg_11_2]) .. ".png")

		var_11_3:setAnchorPoint(cc.p(0, 1))
		var_11_3:addTo(var_11_1:getChildByName("item"))
		var_11_3:setPosition(0, var_11_1:getChildByName("item"):getContentSize().height)
	end

	if var_0_4:buyLimit(arg_11_0.listInfo[arg_11_2]) > 0 then
		var_11_1:getChildByName("item_name"):setString(xyd.tables.item:name(var_11_2) .. " X " .. var_0_4:itemNum(arg_11_0.listInfo[arg_11_2]) .. string.format(var_0_1:translation("LOTTERY_CONSUME_TEXT7"), var_0_4:buyLimit(arg_11_0.listInfo[arg_11_2]), arg_11_0.details.base_info.buy_times[arg_11_2] or 0))
	else
		var_11_1:getChildByName("item_name"):setString(xyd.tables.item:name(var_11_2) .. " X " .. var_0_4:itemNum(arg_11_0.listInfo[arg_11_2]))
	end

	var_11_1:getChildByName("text_dec"):setString(xyd.tables.item:desc1(var_11_2))

	local var_11_4 = var_0_4:buyLimit(arg_11_0.listInfo[arg_11_2])

	if (var_11_4 - (arg_11_0.details.base_info.buy_times[arg_11_2] or 0) > 0 or var_11_4 <= 0) and arg_11_0.selfPlayer.vip >= var_0_4:vipLimit(arg_11_0.listInfo[arg_11_2]) then
		var_11_1:getChildByName("btn_change"):setTouchEnabled(true)
		var_11_1:getChildByName("btn_change"):setBright(true)
		var_11_1:getChildByName("btn_change"):getChildByName("text_change"):setVisible(true)
	else
		var_11_1:getChildByName("btn_change"):setTouchEnabled(false)
		var_11_1:getChildByName("btn_change"):setBright(false)
		var_11_1:getChildByName("btn_change"):getChildByName("text_change"):setVisible(false)
	end

	var_11_1:getChildByName("score"):setString(var_0_4:pt(arg_11_0.listInfo[arg_11_2]) .. var_0_1:translation("LOTTERY_CONSUME_TEXT8"))
	var_11_1:getChildByName("btn_change"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.began then
			arg_12_0:setScale(0.9)
		elseif arg_12_1 == ccui.TouchEventType.moved then
			arg_12_0:setScale(1)
		elseif arg_12_1 == ccui.TouchEventType.ended then
			arg_12_0:setScale(1)

			if arg_11_0.score < var_0_4:pt(arg_11_0.listInfo[arg_11_2]) then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("LOTTERY_CONSUME_TEXT9")
				})
			else
				local var_12_0 = string.format(var_0_1:translation("LOTTERY_CONSUME_TEXT10"), var_0_4:pt(arg_11_0.listInfo[arg_11_2]), var_0_2:name(var_11_2))

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_0, function()
					xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivityReward(xyd.Activities.LotteryConsume, arg_11_2, function(arg_14_0, arg_14_1)
						if arg_14_0 == xyd.error.OK then
							arg_11_0.selfPlayer:handleRewards(arg_14_1.awards)

							arg_11_0.details.base_info.buy_times = arg_14_1.base_info.buy_times
							arg_11_0.score = arg_14_1.base_info.point

							arg_11_0:updateScore()
							arg_11_0.list:refreshList()

							local var_14_0 = xyd.WindowManager.get():getWindow("activities")

							if var_14_0 and var_14_0.openedActivities[xyd.Activities.LotteryConsume] then
								var_14_0.openedActivities[xyd.Activities.LotteryConsume].details.base_info = arg_14_1.base_info

								var_14_0.openedActivities[xyd.Activities.LotteryConsume]:updateWnd()
							end
						end
					end)
				end, nil, nil, arg_11_0.colorMode)
			end
		end
	end)

	local var_11_5 = display.newNode()

	var_11_5:setContentSize(var_11_1:getChildByName("item"):getContentSize())
	var_11_5:addTo(var_11_1:getChildByName("item"))
	var_11_5:setAnchorPoint(cc.p(0, 0))

	local var_11_6 = {
		id = var_11_2,
		lev = xyd.tables.item:level(var_11_2)
	}

	if xyd.tables.item:type(var_11_2) == -1 then
		var_11_6.tipsType = 0
		var_11_6.desc1 = xyd.tables.hero:getDes(var_11_2)
	elseif specialItem then
		var_11_6.tipsType = 1
		var_11_6.id = -3
	else
		var_11_6.tipsType = 1
		var_11_6.desc1 = xyd.tables.item:desc1(var_11_2)
		var_11_6.desc2 = xyd.tables.item:desc2(var_11_2)
	end

	var_11_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_11_2)
	var_11_6.name = xyd.tables.item:name(var_11_2)

	arg_11_0:addTips(var_11_5, var_11_6)
end

function var_0_0.updateTimeCount(arg_15_0)
	local var_15_0 = arg_15_0:nodeByName("time")

	if arg_15_0.handle_ then
		var_0_3.unscheduleGlobal(arg_15_0.handle_)
	end

	local var_15_1
	local var_15_2 = not arg_15_0.activities:isActivityOpen(xyd.Activities.ZhangheDoll) and 0 or arg_15_0.activity.end_time - xyd.ServerTime.get():getServerTime()

	if var_15_2 <= 0 then
		var_15_2 = 0

		return
	end

	var_15_0:setString(string.format(var_0_1:translation("ACTIVITY_ZHANGHE_DOLL_TEXT1"), xyd.secondsToString(var_15_2, {
		toText = false
	})))

	arg_15_0.handle_ = var_0_3.scheduleGlobal(function()
		if var_15_0 and not tolua.isnull(var_15_0) then
			var_15_2 = var_15_2 - 1

			var_15_0:setString(string.format(var_0_1:translation("ACTIVITY_ZHANGHE_DOLL_TEXT1"), xyd.secondsToString(var_15_2, {
				toText = false
			})))

			if var_15_2 == 0 and arg_15_0.handle_ then
				var_0_3.unscheduleGlobal(arg_15_0.handle_)

				arg_15_0.handle_ = nil
			end
		elseif arg_15_0.handle_ then
			var_0_3.unscheduleGlobal(arg_15_0.handle_)

			arg_15_0.handle_ = nil
		end
	end, 1)
end

return var_0_0
