local var_0_0 = class("Activity1234AllAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityChenshouTravelBonus

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.activityId = arg_1_2.table_id
	arg_1_0.awardItems = arg_1_2.details.whole_awarded
	arg_1_0.awardCount = arg_1_2.details.whole_charge_count
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.willClose(arg_4_0)
	if arg_4_0.callback then
		arg_4_0.callback()
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_buy"):setString(var_0_1:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_9"))
	arg_5_0:nodeByName("num_buy"):setString(arg_5_0.awardCount)

	local var_5_0 = arg_5_0:nodeByName("list"):getContentSize()

	arg_5_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0:nodeByName("list")):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.list:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0.list:reload()
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #var_0_2:getIds()
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0 = arg_6_0.list:dequeueItem()

		if var_6_0 then
			var_6_0:removeAllChildren()
		else
			var_6_0 = arg_6_0.list:newItem()
		end

		local var_6_1 = display.newNode()

		var_6_1:setContentSize(841, 115)
		var_6_1:setAnchorPoint(cc.p(0.5, 0.5))
		arg_6_0:createItemContent(arg_6_3):addTo(var_6_1)
		var_6_0:addContent(var_6_1)
		var_6_0:setItemSize(841, 115)

		return var_6_0
	end
end

function var_0_0.createItemContent(arg_7_0, arg_7_1)
	local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1234/box_item.csb")
	local var_7_1 = var_7_0:getChildByName("container")
	local var_7_2 = var_7_1:getContentSize()

	var_7_0:setContentSize(var_7_2)
	var_7_1:getChildByName("txt_tips"):setString(string.format(var_0_1:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_10"), var_0_2:reqNum(arg_7_1)))
	arg_7_0:rewardFormat(var_7_1:getChildByName("list_gift"), var_0_2:gift(arg_7_1))

	local var_7_3 = var_7_1:getChildByName("btn_get")

	if arg_7_0.awardCount < var_0_2:reqNum(arg_7_1) then
		var_7_3:getChildByName("txt_get"):setString(var_0_1:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_6"))
	elseif arg_7_0.awardItems[arg_7_1] == 0 then
		var_7_3:getChildByName("txt_get"):setString(var_0_1:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_5"))
	else
		var_7_3:getChildByName("txt_get"):setString(var_0_1:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_7"))
		var_7_3:getChildByName("txt_get"):setColor(cc.c3b(52, 54, 55))
		var_7_3:setTouchEnabled(false)
		var_7_3:setBright(false)
	end

	var_7_3:addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(var_7_3, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_7_0.awardCount >= var_0_2:reqNum(arg_7_1) and arg_7_0.awardItems[arg_7_1] == 0 then
				arg_7_0.activitiesModel:getActivityReward2(arg_7_0.activityId, arg_7_1, 2, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						arg_7_0.player:handleRewards(arg_9_1.awards)
						arg_7_0.activitiesModel:refreshRedMark()

						arg_7_0.awardItems[arg_7_1] = 1

						var_7_3:getChildByName("txt_get"):setString(var_0_1:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_7"))
						var_7_3:getChildByName("txt_get"):setColor(cc.c3b(52, 54, 55))
						var_7_3:setTouchEnabled(false)
						var_7_3:setBright(false)
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_14")
				})
			end
		end
	end)

	return var_7_0
end

function var_0_0.rewardFormat(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0 = arg_10_1:getContentSize().height
	local var_10_1 = arg_10_4 or var_10_0 / 4
	local var_10_2 = xyd.tables.gift:items(arg_10_2)

	if #var_10_2 == 1 and var_10_2[1] == 0 then
		var_10_2 = {}
	end

	local var_10_3 = xyd.tables.gift:itemNum(arg_10_2)
	local var_10_4 = #var_10_2

	for iter_10_0 = 1, #var_10_2 do
		local var_10_5 = display.newNode()

		var_10_5:setContentSize(var_10_0, var_10_0)

		if xyd.tables.item:type(var_10_2[iter_10_0]) == -1 then
			xyd.setAvatarBorderNewUI(var_10_2[iter_10_0], var_10_5, 1, xyd.tables.hero:initialStar(var_10_2[iter_10_0]))
		else
			xyd.setItemBorder(var_10_5, var_10_2[iter_10_0], false, false, var_10_3[iter_10_0])
		end

		var_10_5:addTo(arg_10_1)
		var_10_5:setAnchorPoint(cc.p(0, 0))
		var_10_5:setPosition((iter_10_0 - 1) * (var_10_0 + var_10_1), 0)

		local var_10_6 = {
			id = var_10_2[iter_10_0],
			lev = xyd.tables.item:level(var_10_2[iter_10_0])
		}

		if xyd.tables.item:type(var_10_2[iter_10_0]) == -1 then
			var_10_6.tipsType = 0
			var_10_6.desc1 = xyd.tables.hero:getDes(var_10_2[iter_10_0])
		elseif specialItem then
			var_10_6.tipsType = 1
			var_10_6.id = -3
		else
			var_10_6.tipsType = 1
			var_10_6.desc1 = xyd.tables.item:desc1(var_10_2[iter_10_0])
			var_10_6.desc2 = xyd.tables.item:desc2(var_10_2[iter_10_0])
		end

		var_10_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_10_2[iter_10_0])
		var_10_6.name = xyd.tables.item:name(var_10_2[iter_10_0])

		arg_10_0:addTips(var_10_5, var_10_6)
	end

	local var_10_7 = xyd.tables.gift:skinFragment(arg_10_2)

	if var_10_7 and var_10_7 > 0 then
		local var_10_8 = display.newNode()

		var_10_8:setContentSize(var_10_0, var_10_0)
		xyd.setItemBorder(var_10_8, -101, false, false, var_10_7)
		var_10_8:addTo(arg_10_1)
		var_10_8:setAnchorPoint(cc.p(0, 0))
		var_10_8:setPosition(var_10_4 * (var_10_0 + var_10_1), 0)

		local var_10_9 = {}

		var_10_9.id = -101
		var_10_9.tipsType = 1

		arg_10_0:addTips(var_10_8, var_10_9)

		var_10_4 = var_10_4 + 1
	end

	local var_10_10 = xyd.tables.gift:crystal(arg_10_2)

	if var_10_10 and var_10_10 > 0 then
		local var_10_11 = display.newNode()

		var_10_11:setContentSize(var_10_0, var_10_0)
		xyd.setItemBorder(var_10_11, -1, false, false, var_10_10)
		var_10_11:addTo(arg_10_1)
		var_10_11:setAnchorPoint(cc.p(0, 0))
		var_10_11:setPosition(var_10_4 * (var_10_0 + var_10_1), 0)

		local var_10_12 = {}

		var_10_12.id = -1
		var_10_12.tipsType = 1

		arg_10_0:addTips(var_10_11, var_10_12)

		var_10_4 = var_10_4 + 1
	end

	local var_10_13 = xyd.tables.gift:mana(arg_10_2)

	if var_10_13 and var_10_13 > 0 then
		local var_10_14 = display.newNode()

		var_10_14:setContentSize(var_10_0, var_10_0)
		xyd.setItemBorder(var_10_14, -2, false, false, var_10_13)
		var_10_14:addTo(arg_10_1)
		var_10_14:setAnchorPoint(cc.p(0, 0))
		var_10_14:setPosition(var_10_4 * (var_10_0 + var_10_1), 0)

		local var_10_15 = {}

		var_10_15.id = -2
		var_10_15.tipsType = 1

		arg_10_0:addTips(var_10_14, var_10_15)

		local var_10_16 = var_10_4 + 1
	end

	return arg_10_1
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevX_ = arg_11_1.x
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 5 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

return var_0_0
