local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")

		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(3.5, 5)

		arg_2_0.scroll = arg_2_0.container:getChildByName("scroll")

		local var_2_1 = arg_2_0.scroll:getContentSize()

		arg_2_0.awardedList = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_2_0.scroll)

		arg_2_0.awardedList:setBounceable(false)
		arg_2_0.awardedList:setTouchType(false)

		arg_2_0.awardedIdx = {}

		arg_2_0:update()
	end
end

function var_0_0.update(arg_3_0)
	arg_3_0:updateAwardScroll()
end

function var_0_0.updateAwardScroll(arg_4_0)
	arg_4_0.awardedList:removeAllItems()

	for iter_4_0 = 1, #arg_4_0.activity.details.is_awarded do
		local var_4_0
		local var_4_1 = arg_4_0.awardedList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.awardedList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListContent(iter_4_0)
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3, var_4_4)
		var_4_1:addContent(var_4_2)
		arg_4_0.awardedList:addItem(var_4_1)
		arg_4_0.awardedList:reload()
	end
end

function var_0_0.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = display.newNode()
	local var_5_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1133/activity_item.csb")
	local var_5_2 = var_5_1:getChildByName("container")
	local var_5_3 = xyd.tables.activityMoegirlsGift

	arg_5_0:rewardFormat(var_5_2:getChildByName("reward_container"), var_5_3:gift(arg_5_1))

	local var_5_4 = var_5_2:getChildByName("item_title_container")
	local var_5_5 = {
		color = cc.c3b(255, 255, 255)
	}

	var_5_5.size = 24

	local var_5_6 = xyd.AssetLoader.get():loadLabel(var_5_5)

	var_5_6:addTo(var_5_4)
	var_5_6:setAnchorPoint(cc.p(0, 0))
	var_5_6:setPosition(10, 3)
	var_5_6:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	var_5_6:setString(var_5_3:name(arg_5_1))

	local var_5_7 = arg_5_0.activity.details
	local var_5_8 = var_5_2:getChildByName("btn")
	local var_5_9 = var_5_2:getChildByName("yilingqu")
	local var_5_10 = var_5_2:getChildByName("lingqu")
	local var_5_11 = var_5_2:getChildByName("get_gray")
	local var_5_12 = var_5_2:getChildByName("expired")
	local var_5_13 = var_5_2:getChildByName("not_begin")
	local var_5_14 = {
		btn = var_5_8,
		alreadyObtain = var_5_9,
		obtain_bright = var_5_10,
		obtain_gray = var_5_11,
		expired = var_5_12,
		notBegin = var_5_13
	}
	local var_5_15 = xyd.ServerTime.get():getServerTime()

	if var_5_7.is_awarded[arg_5_1] == 0 then
		arg_5_0:setBtnGetState(1, var_5_14)
	else
		arg_5_0:setBtnGetState(0, var_5_14)
	end

	var_5_2:getChildByName("btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and arg_5_0.scrollViewMoved_ ~= true then
			if arg_5_0.selfPlayer.crystal < xyd.tables.misc.moegirlsActivityCost then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_7_0 = {}

					var_7_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
				end, nil, nil, xyd.ColorMode.ACTIVITY)

				return
			end

			local var_6_0 = string.format(var_0_1:translation("BUY_GIFT_BOX_TIP"), xyd.tables.misc.moegirlsActivityCost)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
				arg_5_0.activitiesModel:getActivityReward(arg_5_0.activity.table_id, arg_5_1, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						var_5_7.is_awarded[arg_5_1] = 1

						if arg_9_1.awards then
							arg_5_0.selfPlayer:handleRewards(arg_9_1.awards)
						end

						arg_5_0:updateAwardScroll()
					end
				end)
			end, nil, nil, xyd.ColorMode.ACTIVITY)
		end
	end)
	var_5_1:addTo(var_5_0)
	var_5_1:setAnchorPoint(cc.p(0, 0))
	var_5_0:setContentSize(var_5_2:getContentSize().width + 2, var_5_2:getContentSize().height + 4)
	var_5_1:setPosition(cc.p(1, 2))
	var_5_1:setName("source")

	return var_5_0
end

return var_0_0
