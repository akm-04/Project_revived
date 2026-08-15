local var_0_0 = class("ActivityBaseMapWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2 or {})
	arg_1_0:baseDefine()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.ACT_ITEM_CHANGE, handler(arg_3_0, arg_3_0.onActivityItemChange))
end

function var_0_0.baseDefine(arg_4_0)
	arg_4_0.linePath = "windows/map_window/new/line.png"
	arg_4_0.rewardEffect = "skeletons/ui_effect/campaign_map/reward_hint"
end

function var_0_0.addAssetWindow(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = import("app.common.ui.EcoSidebar").new(xyd.WidgetName.ecoSidebar, {})

	var_5_0:addTo(arg_5_0)
	var_5_0:setAnchorPoint(0, 0)
	var_5_0:setPosition(arg_5_1, arg_5_2)
end

function var_0_0.createMap(arg_6_0)
	arg_6_0:nodeByName("map"):removeAllChildren()

	local var_6_0 = clone(arg_6_0.campaignTable:startPoints())
	local var_6_1 = 1

	while var_6_1 <= #var_6_0 do
		local var_6_2 = var_6_0[var_6_1]
		local var_6_3 = arg_6_0.campaignTable:lastCampaignId(var_6_2)
		local var_6_4 = arg_6_0.campaignTable:posX(var_6_2)
		local var_6_5 = arg_6_0.campaignTable:posY(var_6_2)
		local var_6_6 = arg_6_0.campaignTable:campaignType(var_6_2)
		local var_6_7

		if var_6_6 == 3 then
			var_6_7 = arg_6_0:createHardPoint(var_6_2)
		else
			var_6_7 = arg_6_0:createCheckPoint(var_6_2)
		end

		var_6_7:addTo(arg_6_0:nodeByName("map"))
		var_6_7:pos(var_6_4, var_6_5)

		if var_6_3 ~= 0 then
			arg_6_0:createRoad(var_6_3, var_6_2, false)
		end

		local var_6_8 = arg_6_0.campaignTable:nextCampaignId(var_6_2)

		for iter_6_0 = 1, #var_6_8 do
			if var_6_8[iter_6_0] == 0 then
				break
			end

			if arg_6_0.mapDetail[var_6_8[iter_6_0]] and next(arg_6_0.mapDetail[var_6_8[iter_6_0]]) then
				table.insert(var_6_0, var_6_8[iter_6_0])
			end
		end

		local var_6_9 = arg_6_0.campaignTable:itemCampaignId(var_6_2)
		local var_6_10 = arg_6_0.campaignTable:nextHardCampaignId(var_6_9)

		for iter_6_1 = 1, #var_6_10 do
			if var_6_10[iter_6_1] == 0 then
				break
			end

			if arg_6_0.mapDetail[var_6_10[iter_6_1]] and next(arg_6_0.mapDetail[var_6_10[iter_6_1]]) then
				table.insert(var_6_0, var_6_10[iter_6_1])
			end
		end

		var_6_1 = var_6_1 + 1
	end

	if arg_6_0.onBattleEnd then
		arg_6_0:onFightResult()
	end
end

function var_0_0.firstEnterAction(arg_7_0)
	local var_7_0 = clone(arg_7_0.campaignTable:startPoints())

	for iter_7_0 = 1, #var_7_0 do
		local var_7_1 = arg_7_0:nodeByName("map"):getChildByName("point" .. var_7_0[iter_7_0])

		var_7_1:getChildByName("bg"):setScale(0)
		var_7_1:getChildByName("bg"):setOpacity(0)
		var_7_1:getChildByName("bg"):setRotation(0)
		var_7_1:getChildByName("bg"):setTouchEnabled(false)
		var_7_1:getChildByName("arrow"):setVisible(false)

		local var_7_2 = 0.03333333333333333

		var_7_1:getChildByName("bg"):runAction(cc.Sequence:create({
			cc.Spawn:create({
				cc.FadeIn:create(var_7_2 * 2),
				cc.Sequence:create({
					cc.ScaleTo:create(var_7_2, 0.21),
					cc.ScaleTo:create(var_7_2 * 3, 1.155),
					cc.DelayTime:create(var_7_2 * 3),
					cc.ScaleTo:create(var_7_2 * 2, 1),
					cc.RotateTo:create(var_7_2 * 2, -18),
					cc.RotateTo:create(var_7_2 * 3, 9),
					cc.RotateTo:create(var_7_2 * 3, 0),
					cc.RotateTo:create(var_7_2 * 2, -14),
					cc.RotateTo:create(var_7_2 * 5, 9),
					cc.RotateTo:create(var_7_2 * 3, 0)
				})
			}),
			cc.CallFunc:create(function()
				var_7_1:getChildByName("bg"):setTouchEnabled(true)
				var_7_1:getChildByName("arrow"):setVisible(true)
			end)
		}))
	end
end

function var_0_0.createProgressBar(arg_9_0, arg_9_1)
	local var_9_0 = cc.ProgressTimer:create(xyd.AssetLoader:get():loadSprite(arg_9_0.linePath))

	var_9_0:setAnchorPoint(cc.p(0, 0.5))
	var_9_0:setMidpoint(cc.p(0, 0))
	var_9_0:setBarChangeRate(cc.p(1, 0))
	var_9_0:setType(display.PROGRESS_TIMER_BAR)

	var_9_0.maxPercentage = math.min(arg_9_1 / var_9_0:getContentSize().width)

	return var_9_0
end

function var_0_0.createRoad(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_0.campaignTable:posX(arg_10_1)
	local var_10_1 = arg_10_0.campaignTable:posY(arg_10_1)
	local var_10_2 = arg_10_0.campaignTable:posX(arg_10_2)
	local var_10_3 = arg_10_0.campaignTable:posY(arg_10_2)
	local var_10_4 = math.sqrt(math.pow(var_10_0 - var_10_2, 2) + math.pow(var_10_1 - var_10_3, 2))
	local var_10_5 = arg_10_0:createProgressBar(var_10_4)

	var_10_5:addTo(arg_10_0:nodeByName("map"), -1)
	var_10_5:pos(var_10_0, var_10_1)

	local var_10_6 = math.atan2(var_10_3 - var_10_1, var_10_2 - var_10_0) / math.pi * -180

	var_10_5:setRotation(var_10_6)

	if arg_10_3 then
		var_10_5:runAction(cc.ProgressTo:create(1, var_10_5.maxPercentage * 100))
	else
		var_10_5:setPercentage(var_10_5.maxPercentage * 100)
	end
end

function var_0_0.updateItemBag(arg_11_0)
	local var_11_0 = arg_11_0:nodeByName("bag")

	if not var_11_0 or tolua.isnull(var_11_0) then
		return
	end

	for iter_11_0 = 1, #arg_11_0.bagItems do
		var_11_0:getChildByName("item" .. iter_11_0):removeAllChildren()
		xyd.setItemAndAddTips(var_11_0:getChildByName("item" .. iter_11_0), arg_11_0.bagItems[iter_11_0])

		local var_11_1 = arg_11_0.backpack:getItemNumByID(arg_11_0.bagItems[iter_11_0])

		var_11_0:getChildByName("num" .. iter_11_0):setString("X " .. var_11_1)
	end
end

function var_0_0.bonusSetup(arg_12_0, arg_12_1)
	arg_12_0:nodeByName("bonus"):setLocalZOrder(99)
	arg_12_0:nodeByName("bonus"):setTouchEnabled(true)
	arg_12_0:nodeByName("bonus_detail"):setLocalZOrder(100)
	arg_12_0:nodeByName("bonus_detail"):setVisible(false)

	local var_12_0 = display.newNode()
	local var_12_1 = arg_12_0:nodeByName("bonus_detail"):getContentSize()
	local var_12_2, var_12_3 = arg_12_0:nodeByName("bonus_detail"):getPosition()

	var_12_0:setContentSize(var_12_1.width, var_12_1.height)
	var_12_0:setAnchorPoint(0, 0)
	var_12_0:setPosition(var_12_2, var_12_3)
	var_12_0:addTo(arg_12_0:nodeByName("container"))
	var_12_0:setLocalZOrder(99)
	var_12_0:setTouchEnabled(true)
	var_12_0:setTouchSwallowEnabled(true)
	var_12_0:setVisible(false)

	arg_12_0.bonusLayer = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	arg_12_0.bonusLayer:pos(0, 0):addTo(arg_12_0:nodeByName("container"))
	arg_12_0.bonusLayer:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_12_0.bonusLayer:setTouchEnabled(true)
	arg_12_0.bonusLayer:setTouchSwallowEnabled(true)
	arg_12_0.bonusLayer:setVisible(false)
	arg_12_0.bonusLayer:setLocalZOrder(98)
	arg_12_0.bonusLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "ended" then
			arg_12_0.bonusLayer:setVisible(false)
			arg_12_0:nodeByName("bonus_detail"):setVisible(false)
			var_12_0:setVisible(false)
		end

		return true
	end)
	arg_12_0:bonusUpdate()
	arg_12_0:nodeByName("bonus"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			return true
		elseif arg_14_0.name == "ended" then
			if arg_12_0.bonusTable:starNums(arg_12_0.bonusID) <= arg_12_0.stars and arg_12_0.starAward[arg_12_0.bonusID] == 0 then
				xyd.Backend.get():request(arg_12_1, {
					award_id = arg_12_0.bonusID
				}, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						if arg_15_1.awards and next(arg_15_1.awards) then
							xyd.WindowManager.get():openWindow("alert_award", {
								awards = arg_15_1.awards
							})

							local var_15_0 = arg_15_1.awards
							local var_15_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

							for iter_15_0 = 1, #var_15_0 do
								if var_15_0[iter_15_0].table_id > 0 then
									local var_15_2 = {
										itemID = var_15_0[iter_15_0].table_id,
										itemNum = var_15_0[iter_15_0].item_num
									}

									var_15_1:getBackpack():addItem(var_15_2)
								end
							end
						end

						arg_12_0.starAward[arg_12_0.bonusID] = 1

						arg_12_0:bonusUpdate()
						arg_12_0:updateItemBag()
					end
				end)
			elseif arg_12_0.starAward[#arg_12_0.starAward] == 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("MAP_GOT_ALL_REWARD")
				})
			else
				local var_14_0 = arg_12_0.bonusLayer:isVisible()

				arg_12_0.bonusLayer:setVisible(not var_14_0)
				arg_12_0:nodeByName("bonus_detail"):setVisible(not var_14_0)
				var_12_0:setVisible(not var_14_0)
				var_12_0:setTouchSwallowEnabled(true)
			end
		end
	end)
end

function var_0_0.bonusUpdate(arg_16_0)
	for iter_16_0 = 1, #arg_16_0.starAward do
		if arg_16_0.starAward[iter_16_0] == 0 or arg_16_0.starAward[iter_16_0] == "0" then
			arg_16_0.bonusID = iter_16_0

			break
		elseif iter_16_0 == #arg_16_0.starAward then
			arg_16_0.bonusID = iter_16_0
		end
	end

	local var_16_0 = arg_16_0.bonusTable:starNums(arg_16_0.bonusID)
	local var_16_1 = arg_16_0:nodeByName("bonus")

	var_16_1:getChildByName("txt"):setString(arg_16_0.stars .. "/" .. var_16_0)

	local var_16_2 = math.min(arg_16_0.stars / var_16_0, 1) * 100

	var_16_1:getChildByName("bar"):setPercent(var_16_2)

	if not arg_16_0.bonusEffect or tolua.isnull(arg_16_0.bonusEffect) then
		arg_16_0.bonusEffect = xyd.createEffect(arg_16_0.rewardEffect)

		arg_16_0.bonusEffect:addTo(var_16_1)
		arg_16_0.bonusEffect:setPosition(-8.5, 29.5)
		arg_16_0.bonusEffect:setTouchSwallowEnabled(false)
		arg_16_0.bonusEffect:setVisible(false)
		arg_16_0.bonusEffect:play(nil, true)
	end

	if var_16_0 <= arg_16_0.stars and arg_16_0.starAward[arg_16_0.bonusID] == 0 then
		var_16_1:getChildByName("star2"):setVisible(false)
		arg_16_0.bonusEffect:setVisible(true)
	else
		var_16_1:getChildByName("star2"):setVisible(true)
		arg_16_0.bonusEffect:setVisible(false)
	end

	local var_16_3 = arg_16_0:nodeByName("bonus_detail")

	var_16_3:getChildByName("reach_txt"):setString(var_0_1:translation("STAR_BONUS_DES_1"))
	var_16_3:getChildByName("get_txt"):setString(var_0_1:translation("STAR_BONUS_DES_2"))
	var_16_3:getChildByName("num_pos"):removeAllChildren()

	local var_16_4 = var_16_0
	local var_16_5 = {}

	if var_16_4 == 0 then
		var_16_5 = {
			0
		}
	end

	while var_16_4 > 0 do
		table.insert(var_16_5, var_16_4 % 10)

		var_16_4 = math.floor(var_16_4 / 10)
	end

	local var_16_6 = #var_16_5

	for iter_16_1 = #var_16_5, 1, -1 do
		local var_16_7 = xyd.AssetLoader.get():loadSprite(arg_16_0.bonusNumPath .. var_16_5[iter_16_1] .. ".png")

		var_16_7:setAnchorPoint(0.5, 0)
		var_16_7:addTo(var_16_3:getChildByName("num_pos"))
		var_16_7:pos((#var_16_5 - iter_16_1) * 30 - 15 * (#var_16_5 - 1), 0)
	end

	local var_16_8 = arg_16_0.bonusTable:awardIDs(arg_16_0.bonusID)
	local var_16_9 = arg_16_0.bonusTable:awardNums(arg_16_0.bonusID)

	var_16_3:getChildByName("item1"):removeAllChildren()
	var_16_3:getChildByName("item2"):removeAllChildren()
	xyd.setItemAndAddTips(var_16_3:getChildByName("item1"), var_16_8[1])
	xyd.setItemAndAddTips(var_16_3:getChildByName("item2"), var_16_8[2])
	var_16_3:getChildByName("num1"):setString("X " .. var_16_9[1])
	var_16_3:getChildByName("num2"):setString("X " .. var_16_9[2])
end

function var_0_0.downArrowAction(arg_17_0, arg_17_1)
	local var_17_0 = transition.sequence({
		cc.MoveBy:create(1, cc.p(0, -35)),
		cc.MoveBy:create(1, cc.p(0, 35))
	})
	local var_17_1 = cc.RepeatForever:create(var_17_0)

	arg_17_1:runAction(var_17_1)
end

function var_0_0.onFightResult(arg_18_0)
	local var_18_0 = arg_18_0.battleResult.campaign_id
	local var_18_1 = arg_18_0.battleResult.star
	local var_18_2 = arg_18_0.campaignTable:campaignType(var_18_0)
	local var_18_3 = arg_18_0:nodeByName("map"):getChildByName("point" .. var_18_0)
	local var_18_4 = arg_18_0.mapDetail[var_18_0]

	arg_18_0.stars = arg_18_0.stars - var_18_4.star
	var_18_4.count = var_18_4.count + 1
	var_18_4.star = math.max(var_18_1, var_18_4.star)

	if var_18_2 ~= xyd.ActivityCampaignType.STORY then
		arg_18_0.stars = arg_18_0.stars + var_18_4.star
	end

	if var_18_2 == xyd.ActivityCampaignType.STORY then
		if var_18_1 == 0 then
			return
		end

		arg_18_0:runStoryPointFinishAction(var_18_0)
	elseif var_18_2 == xyd.ActivityCampaignType.ITEM then
		local var_18_5 = var_18_3:getChildByName("bg")

		var_18_5:getChildByName("icon"):setVisible(var_18_4.count == 0)
		var_18_5:getChildByName("star1"):setVisible(var_18_4.star == 1)
		var_18_5:getChildByName("star2"):setVisible(var_18_4.star == 2)
		var_18_5:getChildByName("star3"):setVisible(var_18_4.star == 3)

		local var_18_6 = arg_18_0.campaignTable:nextHardCampaignId(var_18_0)

		if var_18_1 > 0 and var_18_6 ~= 0 and not arg_18_0.mapDetail[var_18_6] then
			arg_18_0:runHardPointTurnOnAction(var_18_0)
		end
	elseif var_18_2 == xyd.ActivityCampaignType.HARD then
		local var_18_7 = var_18_3:getChildByName("bg"):getChildByName("unlock")

		var_18_7:setVisible(true)
		var_18_7:getChildByName("star1"):setVisible(var_18_4.star == 1)
		var_18_7:getChildByName("star2"):setVisible(var_18_4.star == 2)
		var_18_7:getChildByName("star3"):setVisible(var_18_4.star == 3)
	end

	arg_18_0:bonusUpdate()
	arg_18_0:updateItemBag()
end

function var_0_0.runStoryPointFinishAction(arg_19_0, arg_19_1)
	local var_19_0 = xyd.tables.misc:getValue("activity_map_point_disappear_time")
	local var_19_1 = xyd.tables.misc:getValue("activity_map_point_show_time")
	local var_19_2 = arg_19_0:nodeByName("map"):getChildByName("point" .. arg_19_1)

	var_19_2:getChildByName("arrow"):setVisible(false)
	var_19_2:getChildByName("bg"):setTouchEnabled(false)
	var_19_2:getChildByName("bg"):runAction(cc.Sequence:create({
		cc.ScaleTo:create(var_19_0, 0),
		cc.CallFunc:create(function()
			if var_19_2 and not tolua.isnull(var_19_2) then
				var_19_2:removeSelf()
			end
		end)
	}))

	local var_19_3, var_19_4 = var_19_2:getPosition()
	local var_19_5 = arg_19_0.campaignTable:itemCampaignId(arg_19_1)

	arg_19_0.mapDetail[var_19_5] = {
		count = 0,
		star = 0
	}

	local var_19_6 = arg_19_0:createCheckPoint(arg_19_1)

	var_19_6:addTo(arg_19_0:nodeByName("map"))
	var_19_6:setPosition(var_19_3, var_19_4)
	var_19_6:setVisible(false)
	var_19_6:getChildByName("bg"):setScale(0)
	var_19_6:getChildByName("bg"):setTouchEnabled(false)
	var_19_6:getChildByName("bg"):runAction(cc.Sequence:create({
		cc.DelayTime:create(var_19_0),
		cc.CallFunc:create(function()
			var_19_6:setVisible(true)
		end),
		cc.ScaleTo:create(var_19_1, 1),
		cc.CallFunc:create(function()
			var_19_6:getChildByName("bg"):setTouchEnabled(true)

			if arg_19_0.campaignTable:isGuide(arg_19_1) == 1 then
				arg_19_0:showGuideWindow(arg_19_1, function()
					arg_19_0:displayNextPoints(arg_19_1)
				end)
			else
				arg_19_0:displayNextPoints(arg_19_1)
			end
		end)
	}))
end

function var_0_0.showGuideWindow(arg_24_0, arg_24_1, arg_24_2)
	if arg_24_0.campaignTable:isGuide(arg_24_1) ~= 1 then
		return
	end

	if arg_24_0.guideLayer and not tolua.isnull(arg_24_0.guideLayer) then
		arg_24_0.guideLayer:removeSelf()
	end

	arg_24_0.guideLayer = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	arg_24_0.guideLayer:pos(0, 0):addTo(arg_24_0:nodeByName("container"))
	arg_24_0.guideLayer:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_24_0.guideLayer:setTouchEnabled(true)
	arg_24_0.guideLayer:setTouchSwallowEnabled(true)
	arg_24_0.guideLayer:setVisible(true)
	arg_24_0.guideLayer:setLocalZOrder(101)
	arg_24_0.guideLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
		if arg_25_0.name == "ended" then
			if arg_24_0.guideWnd and not tolua.isnull(arg_24_0.guideWnd) then
				arg_24_0.guideWnd:removeSelf()

				arg_24_0.guideWnd = nil
			end

			if arg_24_0.guideLayer and not tolua.isnull(arg_24_0.guideLayer) then
				arg_24_0.guideLayer:removeSelf()

				arg_24_0.guideLayer = nil
			end

			if arg_24_2 then
				arg_24_2()
			end
		end

		return true
	end)

	if arg_24_0.guideWnd and not tolua.isnull(arg_24_0.guideWnd) then
		arg_24_0.guideWnd:removeSelf()
	end

	arg_24_0.guideWnd = xyd.AssetLoader.get():loadNodeFromJson(arg_24_0.guideWndPath)

	local var_24_0 = arg_24_0.campaignTable:contentLocation(arg_24_1)
	local var_24_1 = arg_24_0.campaignTable:npcLocation(arg_24_1)
	local var_24_2 = arg_24_0.campaignTable:clipLocation(arg_24_1)
	local var_24_3 = arg_24_0.campaignTable:npcRes(arg_24_1)
	local var_24_4 = arg_24_0.campaignTable:scaling(arg_24_1)

	arg_24_0.guideWnd:getChildByName("txt"):setString(arg_24_0.campaignTable:content(arg_24_1))
	arg_24_0.guideWnd:addTo(arg_24_0:nodeByName("container"), 102)
	arg_24_0.guideWnd:pos(var_24_0[1], var_24_0[2])
	arg_24_0.guideWnd:setTouchSwallowEnabled(false)

	local var_24_5

	if arg_24_0.campaignTable:isDynamic(arg_24_1) then
		local var_24_6 = xyd.EffectLoader.new(var_24_3, 3, var_24_4, {
			x = var_24_1[1],
			y = var_24_1[2]
		})
		local var_24_7 = xyd.AssetLoader.get():loadSprite(arg_24_0.npcClipPath)

		var_24_7:setAnchorPoint(0.5, 1)
		var_24_7:pos(var_24_2[1], var_24_2[2])

		local var_24_8 = cc.ClippingNode:create()

		var_24_8:setStencil(var_24_7)
		var_24_8:setInverted(true)
		var_24_8:setAlphaThreshold(0)
		var_24_8:addTo(arg_24_0.guideWnd, -1)
		var_24_8:addChild(var_24_6)
	else
		local var_24_9 = xyd.SpriteLoader.new(var_24_3 .. ".png", nil, nil, xyd.DefaultImageType.HOME_CARD)

		var_24_9:setAnchorPoint(0, 0)
		var_24_9:setScale(var_24_4)
		var_24_9:pos(var_24_1[1], var_24_1[2])
		var_24_9:addTo(arg_24_0.guideWnd, -1)
	end
end

function var_0_0.displayNextPoints(arg_26_0, arg_26_1)
	local var_26_0 = xyd.tables.misc:getValue("activity_map_point_show_time")
	local var_26_1 = xyd.tables.misc:getValue("activity_map_road_show_time")
	local var_26_2 = xyd.tables.misc:getValue("activity_map_point_shake_time")
	local var_26_3 = arg_26_0.campaignTable:nextCampaignId(arg_26_1)

	for iter_26_0 = 1, #var_26_3 do
		local var_26_4 = var_26_3[iter_26_0]

		if var_26_4 == 0 then
			return
		end

		arg_26_0.mapDetail[var_26_4] = {
			count = 0,
			is_open = 1,
			star = 0
		}

		local var_26_5 = arg_26_0:createCheckPoint(var_26_4)
		local var_26_6 = arg_26_0.campaignTable:posX(var_26_4)
		local var_26_7 = arg_26_0.campaignTable:posY(var_26_4)

		var_26_5:setVisible(false)
		var_26_5:getChildByName("bg"):setScale(0)
		var_26_5:getChildByName("bg"):setOpacity(0)
		var_26_5:getChildByName("bg"):setRotation(0)
		var_26_5:getChildByName("bg"):setTouchEnabled(false)
		var_26_5:addTo(arg_26_0:nodeByName("map"))
		var_26_5:pos(var_26_6, var_26_7)
		arg_26_0:createRoad(arg_26_1, var_26_4, true)

		local var_26_8 = 0.03333333333333333

		var_26_5:getChildByName("bg"):runAction(cc.Sequence:create({
			cc.DelayTime:create(var_26_1),
			cc.CallFunc:create(function()
				var_26_5:setVisible(true)
				var_26_5:getChildByName("arrow"):setVisible(false)
			end),
			cc.Spawn:create({
				cc.FadeIn:create(var_26_8 * 2),
				cc.Sequence:create({
					cc.ScaleTo:create(var_26_8, 0.21),
					cc.ScaleTo:create(var_26_8 * 3, 1.155),
					cc.DelayTime:create(var_26_8 * 3),
					cc.ScaleTo:create(var_26_8 * 2, 1),
					cc.RotateTo:create(var_26_8 * 2, -18),
					cc.RotateTo:create(var_26_8 * 3, 9),
					cc.RotateTo:create(var_26_8 * 3, 0),
					cc.RotateTo:create(var_26_8 * 2, -14),
					cc.RotateTo:create(var_26_8 * 5, 9),
					cc.RotateTo:create(var_26_8 * 3, 0)
				})
			}),
			cc.CallFunc:create(function()
				var_26_5:getChildByName("bg"):setTouchEnabled(true)
				var_26_5:getChildByName("arrow"):setVisible(true)
			end)
		}))
	end
end

function var_0_0.runHardPointTurnOnAction(arg_29_0, arg_29_1)
	if arg_29_0.campaignTable:isGuide(arg_29_1) == 1 then
		arg_29_0:showGuideWindow(arg_29_1, function()
			arg_29_0:displayNextHardPoint(arg_29_1)
		end)
	else
		arg_29_0:displayNextHardPoint(arg_29_1)
	end
end

function var_0_0.displayNextHardPoint(arg_31_0, arg_31_1)
	local var_31_0 = xyd.tables.misc:getValue("activity_map_point_show_time")
	local var_31_1 = xyd.tables.misc:getValue("activity_map_road_show_time")
	local var_31_2 = xyd.tables.misc:getValue("activity_map_point_shake_time")
	local var_31_3 = arg_31_0.campaignTable:nextHardCampaignId(arg_31_1)

	for iter_31_0 = 1, #var_31_3 do
		local var_31_4 = var_31_3[iter_31_0]

		if var_31_4 == 0 or arg_31_0.mapDetail[var_31_4] then
			return
		end

		arg_31_0.mapDetail[var_31_4] = {
			count = 0,
			is_open = 0,
			star = 0
		}

		local var_31_5 = arg_31_0:createHardPoint(var_31_4)
		local var_31_6 = arg_31_0.campaignTable:posX(var_31_4)
		local var_31_7 = arg_31_0.campaignTable:posY(var_31_4)

		var_31_5:setVisible(false)
		var_31_5:getChildByName("bg"):setScale(0)
		var_31_5:getChildByName("bg"):setOpacity(0)
		var_31_5:getChildByName("bg"):setRotation(0)
		var_31_5:getChildByName("bg"):setTouchEnabled(false)
		var_31_5:addTo(arg_31_0:nodeByName("map"))
		var_31_5:pos(var_31_6, var_31_7)
		arg_31_0:createRoad(arg_31_1, var_31_4, true)

		local var_31_8 = 0.03333333333333333

		var_31_5:getChildByName("bg"):runAction(cc.Sequence:create({
			cc.DelayTime:create(var_31_1),
			cc.CallFunc:create(function()
				var_31_5:setVisible(true)

				local var_32_0 = var_31_5:getChildByName("bg"):getChildByName("locked")

				if not var_32_0:getChildByName("bar") then
					return
				end

				var_32_0:getChildByName("clip"):setTouchEnabled(false)
				var_32_0:getChildByName("bar"):setOpacity(0)
				var_32_0:getChildByName("bar_bg"):setOpacity(0)
				var_32_0:getChildByName("bar_num"):setOpacity(0)
				var_32_0:getChildByName("bar"):runAction(cc.Sequence:create({
					cc.DelayTime:create(0.3),
					cc.FadeIn:create(0.6)
				}))
				var_32_0:getChildByName("bar_bg"):runAction(cc.Sequence:create({
					cc.DelayTime:create(0.3),
					cc.FadeIn:create(0.6)
				}))
				var_32_0:getChildByName("bar_num"):runAction(cc.Sequence:create({
					cc.DelayTime:create(0.3),
					cc.FadeIn:create(0.6)
				}))
			end),
			cc.Spawn:create({
				cc.FadeIn:create(var_31_8 * 2),
				cc.Sequence:create({
					cc.ScaleTo:create(var_31_8, 0.21),
					cc.ScaleTo:create(var_31_8 * 3, 1.155),
					cc.DelayTime:create(var_31_8 * 3),
					cc.ScaleTo:create(var_31_8 * 2, 1),
					cc.RotateTo:create(var_31_8 * 2, -18),
					cc.RotateTo:create(var_31_8 * 3, 9),
					cc.RotateTo:create(var_31_8 * 3, 0),
					cc.RotateTo:create(var_31_8 * 2, -14),
					cc.RotateTo:create(var_31_8 * 5, 9),
					cc.RotateTo:create(var_31_8 * 3, 0)
				})
			}),
			cc.CallFunc:create(function()
				var_31_5:getChildByName("bg"):setTouchEnabled(true)
				var_31_5:getChildByName("bg"):getChildByName("locked"):getChildByName("clip"):setTouchEnabled(true)
			end)
		}))
	end
end

function var_0_0.hardPointChange(arg_34_0, arg_34_1)
	local var_34_0 = arg_34_0:nodeByName("map"):getChildByName("point" .. arg_34_1)

	var_34_0:getChildByName("bg"):setTouchEnabled(false)
	var_34_0:getChildByName("bg"):getChildByName("locked"):getChildByName("clip"):setTouchEnabled(false)

	local var_34_1 = 0.03333333333333333
	local var_34_2

	var_34_0:getChildByName("bg"):runAction(cc.Sequence:create({
		cc.RotateTo:create(var_34_1 * 2, -18),
		cc.RotateTo:create(var_34_1 * 3, 9),
		cc.RotateTo:create(var_34_1 * 3, 0),
		cc.RotateTo:create(var_34_1 * 2, -14),
		cc.RotateTo:create(var_34_1 * 5, 9),
		cc.RotateTo:create(var_34_1 * 3, 0),
		cc.CallFunc:create(function()
			var_34_2 = xyd.createEffect(arg_34_0.hardPointChangeEffect)

			var_34_2:play()
			var_34_2:addTo(var_34_0:getChildByName("bg"))
			var_34_2:pos(var_34_0:getChildByName("bg"):getWidth() / 2, var_34_0:getChildByName("bg"):getHeight() / 2)
		end),
		cc.DelayTime:create(0.8),
		cc.CallFunc:create(function()
			var_34_2:removeSelf()
			var_34_0:getChildByName("bg"):getChildByName("effect1"):removeSelf()
			var_34_0:getChildByName("bg"):setTouchEnabled(true)
			var_34_0:getChildByName("bg"):getChildByName("locked"):setVisible(false)
			var_34_0:getChildByName("bg"):getChildByName("unlock"):setVisible(true)
			var_34_0:getChildByName("bg"):getChildByName("unlock"):getChildByName("star1"):setVisible(false)
			var_34_0:getChildByName("bg"):getChildByName("unlock"):getChildByName("star2"):setVisible(false)
			var_34_0:getChildByName("bg"):getChildByName("unlock"):getChildByName("star3"):setVisible(false)
		end)
	}))
end

function var_0_0.willClose(arg_37_0, arg_37_1)
	var_0_0.super.willClose(arg_37_1)

	local var_37_0 = xyd.WindowManager.get():getWindow("asset_wnd")

	if var_37_0 and not tolua.isnull(var_37_0) then
		xyd.WindowManager.get():closeWindow("asset_wnd")
	end
end

function var_0_0.onActivityItemChange(arg_38_0, arg_38_1)
	local var_38_0 = arg_38_1.params and arg_38_1.params[tostring(arg_38_0.activityID)]

	if not var_38_0 then
		return
	end

	for iter_38_0, iter_38_1 in pairs(arg_38_0.mapDetail) do
		local var_38_1 = arg_38_0.campaignTable:inCampItem(iter_38_0)
		local var_38_2 = arg_38_0.campaignTable:inCampNum(iter_38_0) >= 0 and tostring(var_38_1) or "-" .. tostring(var_38_1)

		if var_38_0[var_38_2] and iter_38_1.is_open == 0 then
			arg_38_0:updateHardPoint(iter_38_0, var_38_0[var_38_2])
		end
	end

	arg_38_0.mapInfo.act_item_change_ = arg_38_1
	arg_38_0.activityItemInfo = var_38_0
end

function var_0_0.updateHardPoint(arg_39_0, arg_39_1, arg_39_2)
	return
end

return var_0_0
