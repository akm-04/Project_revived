local var_0_0 = class("MultiskinBuyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.point = arg_1_2.point
	arg_1_0.id = arg_1_2.sell_id
	arg_1_0.skinItem = xyd.tables.activityMultiskinSell:skinItem(arg_1_0.id)
	arg_1_0.discountId = arg_1_2.discount_id
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setButtonClick()

	local var_3_0 = xyd.tables.activityMultiskinSell:titleText(arg_3_0.id)

	if var_3_0 and var_3_0 ~= "" then
		local var_3_1 = xyd.AssetLoader.get():loadSprite(var_3_0)

		arg_3_0:nodeByName("title"):setSpriteFrame(var_3_1:getSpriteFrame())
	end

	local var_3_2 = xyd.tables.skinSkill:getModelID(arg_3_0.skinItem)
	local var_3_3 = xyd.tables.model:transparentCard(var_3_2)
	local var_3_4 = xyd.SpriteLoader.new(var_3_3, nil, extra_params, xyd.DefaultImageType.HOME_CARD)

	var_3_4:setAnchorPoint(cc.p(0, 0))
	var_3_4:addTo(arg_3_0:nodeByName("card_pos"))
	var_3_4:setScale(1)

	arg_3_0.descScroll = arg_3_0:nodeByName("desc_scroll")

	local var_3_5 = arg_3_0.descScroll:getContentSize()

	arg_3_0.descList = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_3_5.width, var_3_5.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.descScroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.descList:setBounceable(true)
	arg_3_0:updateSkillInfo()
	arg_3_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("buy_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = xyd.tables.activityMultiskinSell:price(arg_4_0.id)

			if arg_4_0.discountId then
				var_5_0 = math.ceil(var_5_0 * xyd.tables.activityMultiskinDiscount:discount(arg_4_0.discountId) / 10)
			end

			if var_5_0 > arg_4_0.point then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("MULTISKIN_POINT_NOT_ENOUGH_TIP")
				})

				return
			end

			local var_5_1
			local var_5_2 = xyd.tables.item:name(arg_4_0.skinItem)

			if arg_4_0.discountId then
				local var_5_3 = xyd.tables.activityMultiskinDiscount:discount(arg_4_0.discountId)

				var_5_1 = string.format(var_0_1:translation("MULTISKIN_COST_TIP1"), var_5_3, var_5_0, var_5_2)
			else
				var_5_1 = string.format(var_0_1:translation("MULTISKIN_COST_TIP2"), var_5_0, var_5_2)
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_1, function()
				arg_4_0.activitiesModel:getActivityReward2(xyd.Activities.Multiskin, arg_4_0.id, arg_4_0.discountId, function(arg_7_0, arg_7_1)
					if arg_7_0 == xyd.error.OK then
						if arg_4_0.discountId then
							local var_7_0 = {
								itemID = arg_4_0.discountId
							}

							var_7_0.itemNum = 1

							arg_4_0.backpack:removeItem(var_7_0)
						end

						if arg_7_1.awards then
							arg_4_0.selfPlayer:handleRewards(arg_7_1.awards)

							if arg_4_0.callback then
								arg_4_0.callback(arg_7_1)
							end

							xyd.WindowManager.get():closeWindow(arg_4_0)
						end
					end
				end)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
end

function var_0_0.updateSkillInfo(arg_8_0)
	arg_8_0.descList:removeAllItems()

	local var_8_0 = arg_8_0:createSkillDescLabel()
	local var_8_1 = arg_8_0.descList:dequeueItem()

	if not var_8_1 then
		var_8_1 = arg_8_0.descList:newItem()
	else
		var_8_1:removeAllChildren(true)
	end

	local var_8_2 = arg_8_0:createSkillDescLabel()
	local var_8_3 = var_8_2:getWidth()
	local var_8_4 = var_8_2:getHeight()

	var_8_1:setItemSize(var_8_3, var_8_4)
	var_8_1:addContent(var_8_2)
	arg_8_0.descList:addItem(var_8_1)
	arg_8_0.descList:reload()
end

function var_0_0.createSkillDescLabel(arg_9_0)
	local var_9_0 = display.newNode()
	local var_9_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1139/zaoxing_text.png")
	local var_9_2 = xyd.tables.skinSkill:getSkillID(arg_9_0.skinItem)
	local var_9_3 = xyd.tables.skill:desc(var_9_2) or ""
	local var_9_4 = {
		font = "fonts/main_font.ttf",
		size = 22,
		color = cc.c3b(255, 255, 255)
	}
	local var_9_5 = xyd.AssetLoader.get():loadLabel(var_9_4)

	var_9_5:setMaxLineWidth(500)
	var_9_5:setString("                       " .. var_9_3)
	var_9_5:enableOutline(cc.c4b(108, 63, 57, 255), 2)
	var_9_5:setAnchorPoint(cc.p(0, 0))
	var_9_5:addTo(var_9_0)
	var_9_5:setPositionX(5)
	var_9_0:setContentSize(520, var_9_5:getContentSize().height + 5)
	var_9_1:addTo(var_9_0)
	var_9_1:setAnchorPoint(cc.p(0, 1))
	var_9_1:setPosition(5, var_9_5:getContentSize().height + 5)

	return var_9_0
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevX_ = arg_10_1.x
	elseif arg_10_1.name == "moved" and 5 <= math.abs(arg_10_1.x - arg_10_0.prevX_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

return var_0_0
