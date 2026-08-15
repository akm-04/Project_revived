local var_0_0 = class("ActivityCardMatchShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.activityCardMatchShop

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.shopIds = var_0_3:ids()
	arg_1_0.details = arg_1_2.details
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.exchangeTimes = arg_1_0.details.exchange_times
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.willClose(arg_4_0)
	var_0_0.super.willClose()

	if arg_4_0.callback then
		arg_4_0.callback()
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_title"):setString(var_0_1:translation("ACTIVITY_1161_TEXT_4"))

	local var_5_0 = arg_5_0:nodeByName("scroll")
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
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.list:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0.list:reload()
	arg_5_0:updateAsset()
end

function var_0_0.updateAsset(arg_6_0)
	arg_6_0:nodeByName("special_num_txt"):setString(arg_6_0.details.scores)
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" then
		local var_7_0 = 3

		if var_7_0 <= math.abs(arg_7_1.y - arg_7_0.prevY_) or var_7_0 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
			arg_7_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #arg_8_0.shopIds
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0 = arg_8_0.list:dequeueItem()

		if not var_8_0 then
			var_8_0 = arg_8_0.list:newItem()
		else
			var_8_0:removeAllChildren(true)
		end

		local var_8_1 = 275
		local var_8_2 = 397

		var_8_0:setItemSize(var_8_1, var_8_2)

		local var_8_3 = display.newNode()

		var_8_3:setContentSize(var_8_1, var_8_2)
		arg_8_0:createExchangeItem(var_8_3, arg_8_3)
		var_8_0:addContent(var_8_3)

		return var_8_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_8_2 then
		-- block empty
	end
end

function var_0_0.createExchangeItem(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_0.shopIds[arg_9_2]
	local var_9_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1161/exchange_item.csb")
	local var_9_2 = var_9_1:getChildByName("container")
	local var_9_3 = var_0_3:itemId(var_9_0)
	local var_9_4 = var_0_3:itemNum(var_9_0)
	local var_9_5 = var_0_3:buyLimit(var_9_0)

	var_9_2:getChildByName("name_txt"):setString(xyd.tables.item:name(var_9_3))
	var_9_2:getChildByName("price_txt"):setString(var_0_3:sellPrice(var_9_0))
	var_9_2:getChildByName("exchange_text"):setString(var_0_1:translation("ACTIVITY_1161_TEXT_2"))

	if var_9_5 > 0 then
		var_9_2:getChildByName("limit_txt"):setVisible(true)
		var_9_2:getChildByName("limit_num_txt"):setVisible(true)
	else
		var_9_2:getChildByName("limit_txt"):setVisible(false)
		var_9_2:getChildByName("limit_num_txt"):setVisible(false)
	end

	;(function()
		var_9_2:getChildByName("limit_txt"):setString(var_0_1:translation("ACTIVITY_CARD_MATCH_TEXT7"))
		var_9_2:getChildByName("limit_num_txt"):setString(arg_9_0.exchangeTimes[var_9_0] .. "/" .. var_0_3:buyLimit(var_9_0))
	end)()
	xyd.setItemAndAddTips(var_9_2:getChildByName("icon_container"), var_9_3, var_9_4)
	var_9_2:getChildByName("sure_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			if var_0_3:buyLimit(var_9_0) > 0 and arg_9_0.details.exchange_times[arg_9_2] >= var_0_3:buyLimit(var_9_0) then
				local var_11_0 = var_0_1:translation("ACTIVITY_CARD_MATCH_TEXT4")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_0
				})

				return
			end

			arg_9_0.activities:getActivityReward(xyd.Activities.CARD_MATCH, arg_9_2, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					arg_9_0.selfPlayer:handleRewards(arg_12_1.awards)

					if arg_12_1.scores then
						arg_9_0.details.scores = arg_12_1.scores
					end

					arg_9_0.details.exchange_times[arg_9_2] = (arg_9_0.details.exchange_times[arg_9_2] or 0) + 1

					arg_9_0:updateAsset()
					arg_9_0.list:refreshList()
				end

				if callback then
					callback(arg_12_0, arg_12_1)
				end
			end)
		end
	end)
	var_9_1:addTo(arg_9_1)
	var_9_1:setAnchorPoint(cc.p(0, 0))
	arg_9_1:setContentSize(var_9_2:getContentSize())
	var_9_1:setName("source")

	return arg_9_1
end

return var_0_0
