local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.activityCultivate
local var_0_5 = xyd.tables.activityCultivateCharge

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backPack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.currrentDay = arg_1_0.details.day

	if arg_1_0.details.hero <= 0 then
		arg_1_0.currrentDay = 1
	end

	if arg_1_0.currrentDay > 7 then
		arg_1_0.currrentDay = 7
	elseif arg_1_0.currrentDay < 1 then
		arg_1_0.currrentDay = 1
	end
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
		var_2_0:setPosition(0, 0)

		arg_2_0.scroll = arg_2_0.container:getChildByName("scroll")

		local var_2_1 = arg_2_0.scroll:getContentSize()

		arg_2_0.awardedList = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_2_0.scroll):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

		arg_2_0.awardedList:setDelegate(handler(arg_2_0, arg_2_0.delegate))
		arg_2_0.awardedList:setBounceable(false)
		arg_2_0.awardedList:reload()
		arg_2_0.container:getChildByName("rule_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.began then
				arg_2_0.container:getChildByName("rule_btn"):setScale(0.9)
			elseif arg_3_1 == ccui.TouchEventType.moved then
				arg_2_0.container:getChildByName("rule_btn"):setScale(1)
			elseif arg_3_1 == ccui.TouchEventType.ended then
				arg_2_0.container:getChildByName("rule_btn"):setScale(1)
				xyd.playButtonSound()

				local var_3_0 = {
					title_name = "ACTIVITY_CULTIVATE_RULE_TITLE",
					rule = "ACTIVITY_CULTIVATE_RULE_TEXT"
				}

				xyd.WindowManager.get():openWindow("new_text_rule", var_3_0)
			end
		end)
		arg_2_0:update()
	end
end

function var_0_0.format(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_1:getContentSize().height
	local var_4_1 = margin or var_4_0 / 4
	local var_4_2 = xyd.tables.gift:items(arg_4_2)

	if #var_4_2 == 1 and var_4_2[1] == 0 then
		var_4_2 = {}
	end

	local var_4_3 = xyd.tables.gift:itemNum(arg_4_2)
	local var_4_4 = #var_4_2

	for iter_4_0 = 1, #var_4_2 do
		local var_4_5 = display.newNode()

		var_4_5:setContentSize(var_4_0, var_4_0)

		local var_4_6 = xyd.AssetLoader.get():loadSprite("images/icon/black_bg.png")

		if var_4_6 then
			local var_4_7 = var_4_5:getWidth()
			local var_4_8 = var_4_5:getHeight()
			local var_4_9 = var_4_7 / var_4_6:getWidth()

			var_4_6:setScale(var_4_9)
			var_4_6:addTo(var_4_5)
			var_4_6:setAnchorPoint(cc.p(0, 0))
			var_4_6:setPosition(0, 0)

			local var_4_10 = xyd.getBorder(0, false)

			xyd.displaySpriteOnContainer(var_4_10, var_4_5, true)
		end

		var_4_5:addTo(arg_4_1)
		var_4_5:setAnchorPoint(cc.p(0, 0))
		var_4_5:setPosition((iter_4_0 - 1) * (var_4_0 + var_4_1), 0)
	end

	return arg_4_1
end

function var_0_0.updateTimeText(arg_5_0, arg_5_1)
	if arg_5_0 and arg_5_0.container and not tolua.isnull(arg_5_0.container) then
		arg_5_0.container:getChildByName("time_txt1"):setString(var_0_1:translation("COUNT_DOWN"))
		arg_5_0.container:getChildByName("time_txt3"):setString(var_0_1:translation("END_TEXT"))

		local var_5_0 = math.floor(arg_5_1 / 86400)
		local var_5_1 = (var_5_0 .. xyd.tables.translation:translation("UNIT_DAY")) .. xyd.timeFormatAsHMS(arg_5_1 - var_5_0 * 86400)

		arg_5_0.container:getChildByName("time_txt2"):setString(var_5_1)
	end
end

function var_0_0.updateTimeShow(arg_6_0, arg_6_1)
	if arg_6_0 and arg_6_0.container and not tolua.isnull(arg_6_0.container) then
		arg_6_0.container:getChildByName("time_bg"):setVisible(arg_6_1)
		arg_6_0.container:getChildByName("star"):setVisible(arg_6_1)
		arg_6_0.container:getChildByName("time_txt1"):setVisible(arg_6_1)
		arg_6_0.container:getChildByName("time_txt2"):setVisible(arg_6_1)
		arg_6_0.container:getChildByName("time_txt3"):setVisible(arg_6_1)
	end
end

function var_0_0.update(arg_7_0)
	arg_7_0:updateAwardScroll()
	arg_7_0:updateBottomAwardShow()
	arg_7_0:createScheduler()
	arg_7_0.container:getChildByName("state_pos"):removeAllChildren(true)

	local var_7_0 = "windows/activities/1156/text1.png"
	local var_7_1

	if arg_7_0.details.hero <= 0 then
		var_7_1 = {
			size = 22,
			color = cc.c3b(90, 90, 139),
			dimensions = cc.size(390, 0),
			text = var_0_1:translation("ACTIVITY_CULTIVATE_STATE_TEXT1")
		}

		arg_7_0.container:getChildByName("bg_3"):setVisible(false)
	elseif xyd.isInTable(arg_7_0.details.awards, 0) then
		var_7_1 = {
			size = 22,
			color = cc.c3b(255, 255, 255),
			dimensions = cc.size(390, 0),
			text = var_0_1:translation("ACTIVITY_CULTIVATE_STATE_TEXT2")
		}

		arg_7_0.container:getChildByName("bg_3"):setVisible(true)
	else
		var_7_1 = {
			size = 22,
			color = cc.c3b(255, 255, 255),
			dimensions = cc.size(390, 0),
			text = var_0_1:translation("ACTIVITY_CULTIVATE_STATE_TEXT3")
		}

		arg_7_0.container:getChildByName("bg_3"):setVisible(true)
	end

	local var_7_2 = xyd.AssetLoader.get():loadLabel(var_7_1)

	var_7_2:addTo(arg_7_0.container:getChildByName("state_pos"))
	var_7_2:setAnchorPoint(cc.p(0.5, 0))
	var_7_2:setPosition(cc.p(0, 0))
	var_7_2:setAlignment(1, 2)
	arg_7_0:updateHeroCard()
end

function var_0_0.updateBottomAwardShow(arg_8_0)
	local var_8_0 = arg_8_0.container:getChildByName("bottom_container")
	local var_8_1 = arg_8_0.container:getChildByName("cost_container")
	local var_8_2 = var_0_4:getIdByDay(arg_8_0.currrentDay)

	if #var_8_2 < 2 then
		local var_8_3 = 2

		var_8_0:getChildByName("award_container" .. var_8_3):setVisible(false)
		var_8_0:getChildByName("award_pos" .. var_8_3):setVisible(false)
		var_8_0:getChildByName("buy_btn" .. var_8_3):setVisible(false)
		var_8_0:getChildByName("award_container" .. 1):setPositionY(65)
		var_8_0:getChildByName("award_pos" .. 1):setPositionY(65)
		var_8_0:getChildByName("buy_btn" .. 1):setPositionY(65)
	else
		local var_8_4 = 2

		var_8_0:getChildByName("award_container" .. var_8_4):setVisible(true)
		var_8_0:getChildByName("award_pos" .. var_8_4):setVisible(true)
		var_8_0:getChildByName("buy_btn" .. var_8_4):setVisible(true)
		var_8_0:getChildByName("award_container" .. 1):setPositionY(95)
		var_8_0:getChildByName("award_pos" .. 1):setPositionY(95)
		var_8_0:getChildByName("buy_btn" .. 1):setPositionY(95)
	end

	local var_8_5 = arg_8_0.details.consume6

	if arg_8_0.currrentDay == 7 then
		var_8_5 = arg_8_0.details.consume7
	end

	local var_8_6 = var_0_4:condition(var_8_2[1])

	if arg_8_0.details.awards[var_8_2[1]] == 1 then
		var_8_6 = var_0_4:condition(var_8_2[2])
	end

	var_8_1:getChildByName("cost_txt"):setString(string.format(var_0_1:translation("ACTIVITY_CULTIVATE_COST_TEXT"), var_8_5, var_8_6))

	for iter_8_0 = 1, #var_8_2 do
		local var_8_7 = var_8_2[iter_8_0]
		local var_8_8 = var_0_4:gift(var_8_7)
		local var_8_9 = var_0_4:type(var_8_7)

		var_8_0:getChildByName("award_pos" .. iter_8_0):removeAllChildren(true)
		var_8_0:getChildByName("award_container" .. iter_8_0):removeAllChildren(true)

		local var_8_10 = display.newNode()
		local var_8_11 = {
			size = 22,
			color = cc.c3b(255, 255, 255),
			text = var_0_1:translation("ACTIVITY_1156_TEXT_" .. var_0_4:text1(var_8_7))
		}
		local var_8_12 = xyd.AssetLoader.get():loadLabel(var_8_11)

		var_8_12:addTo(var_8_0:getChildByName("award_pos" .. iter_8_0))
		var_8_12:setAnchorPoint(cc.p(1, 0.5))
		var_8_12:setPosition(cc.p(0, 0))
		var_8_12:enableOutline(cc.c4b(89, 89, 139, 255), 2)

		local var_8_13 = display.newNode()
		local var_8_14 = {
			size = 22,
			color = cc.c3b(132, 54, 75),
			text = var_0_1:translation("ACTIVITY_1156_TEXT_" .. var_0_4:text2(var_8_7))
		}
		local var_8_15 = xyd.AssetLoader.get():loadLabel(var_8_14)

		var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0):removeAllChildren()
		var_8_15:addTo(var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0))
		var_8_15:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_15:setPosition(cc.p(0, 0))
		var_8_0:getChildByName("buy_btn" .. iter_8_0):setTouchEnabled(true)
		var_8_0:getChildByName("buy_btn" .. iter_8_0):setBright(true)

		local var_8_16 = var_0_4:stoneNums(var_8_7)

		if arg_8_0.details.awards[var_8_2[1]] == 0 and iter_8_0 == 2 then
			arg_8_0:format(var_8_0:getChildByName("award_container" .. iter_8_0), var_8_8)
			var_8_0:getChildByName("award_pos" .. iter_8_0):removeAllChildren(true)

			local var_8_17 = {
				size = 22,
				text = "?",
				color = cc.c3b(255, 255, 255)
			}
			local var_8_18 = xyd.AssetLoader.get():loadLabel(var_8_17)

			var_8_18:addTo(var_8_0:getChildByName("award_pos" .. iter_8_0))
			var_8_18:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_18:setPosition(cc.p(0, 0))
			var_8_18:enableOutline(cc.c4b(175, 49, 0, 255), 2)
			var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0):removeAllChildren()

			local var_8_19 = {
				size = 22,
				text = "?",
				color = cc.c3b(105, 105, 105)
			}
			local var_8_20 = xyd.AssetLoader.get():loadLabel(var_8_19)

			var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0):removeAllChildren()
			var_8_20:addTo(var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0))
			var_8_20:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_20:setPosition(cc.p(0, 0))
		else
			arg_8_0:rewardFormat(var_8_0:getChildByName("award_container" .. iter_8_0), var_8_8)

			if var_8_16 > 0 then
				arg_8_0:addStoneReward(var_8_0:getChildByName("award_container" .. iter_8_0), var_8_8, var_8_16)
			end
		end

		if var_8_9 == 1 or arg_8_0.details.awards[var_8_2[1]] == 1 and arg_8_0.details.awards[var_8_2[2]] == 1 then
			var_8_1:setVisible(false)
		else
			var_8_1:setVisible(true)
		end

		if var_8_9 == 1 and arg_8_0.details.awards[var_8_7] == 1 then
			var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0):removeAllChildren()

			local var_8_21 = {
				size = 22,
				color = cc.c3b(105, 105, 105),
				text = var_0_1:translation("ACTIVITY_1156_TEXT_already_buy_text")
			}
			local var_8_22 = xyd.AssetLoader.get():loadLabel(var_8_21)

			var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0):removeAllChildren()
			var_8_22:addTo(var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0))
			var_8_22:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_22:setPosition(cc.p(0, 0))
			var_8_0:getChildByName("buy_btn" .. iter_8_0):setTouchEnabled(false)
			var_8_0:getChildByName("buy_btn" .. iter_8_0):setBright(false)
		elseif var_8_9 == 2 and arg_8_0.details.awards[var_8_7] == 1 then
			var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0):removeAllChildren()

			local var_8_23 = {
				size = 22,
				color = cc.c3b(105, 105, 105),
				text = var_0_1:translation("ACTIVITY_1156_TEXT_gotten_text")
			}
			local var_8_24 = xyd.AssetLoader.get():loadLabel(var_8_23)

			var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0):removeAllChildren()
			var_8_24:addTo(var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0))
			var_8_24:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_24:setPosition(cc.p(0, 0))
			var_8_0:getChildByName("buy_btn" .. iter_8_0):setTouchEnabled(false)
			var_8_0:getChildByName("buy_btn" .. iter_8_0):setBright(false)
		end

		local var_8_25 = var_0_4:condition(var_8_7)

		if iter_8_0 == 2 and arg_8_0.details.awards[var_8_2[1]] == 0 or arg_8_0.details.awards[var_8_7] == 1 or arg_8_0.details.hero <= 0 then
			var_8_0:getChildByName("buy_btn" .. iter_8_0):setBright(false)
			var_8_0:getChildByName("buy_btn" .. iter_8_0):setTouchEnabled(false)
		elseif var_8_9 == 2 and arg_8_0.details.awards[var_8_7] == 0 and var_8_5 < var_8_25 then
			var_8_0:getChildByName("buy_btn" .. iter_8_0):setBright(false)
			var_8_0:getChildByName("buy_btn" .. iter_8_0):setTouchEnabled(false)

			local var_8_26 = {
				size = 22,
				color = cc.c3b(105, 105, 105),
				text = var_0_1:translation("ACTIVITY_1156_TEXT_get_text")
			}
			local var_8_27 = xyd.AssetLoader.get():loadLabel(var_8_26)

			var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0):removeAllChildren()
			var_8_27:addTo(var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0))
			var_8_27:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_27:setPosition(cc.p(0, 0))
		end

		if arg_8_0.details.hero <= 0 then
			local var_8_28 = display.newNode()
			local var_8_29 = {
				size = 22,
				color = cc.c3b(105, 105, 105),
				text = var_0_1:translation("ACTIVITY_1156_TEXT_" .. var_0_4:text2(var_8_7))
			}
			local var_8_30 = xyd.AssetLoader.get():loadLabel(var_8_29)

			var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0):removeAllChildren()
			var_8_30:addTo(var_8_0:getChildByName("buy_btn" .. iter_8_0):getChildByName("buy_text" .. iter_8_0))
			var_8_30:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_30:setPosition(cc.p(0, 0))
		end

		var_8_0:getChildByName("buy_btn" .. iter_8_0):addTouchEventListener(function(arg_9_0, arg_9_1)
			if arg_9_1 == ccui.TouchEventType.began then
				var_8_0:getChildByName("buy_btn" .. iter_8_0):setScale(0.9)
			elseif arg_9_1 == ccui.TouchEventType.moved then
				var_8_0:getChildByName("buy_btn" .. iter_8_0):setScale(1)
			elseif arg_9_1 == ccui.TouchEventType.ended then
				var_8_0:getChildByName("buy_btn" .. iter_8_0):setScale(1)
				xyd.playButtonSound()

				if arg_8_0.details.hero <= 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = xyd.tables.translation:translation("ACTIVITY_CULTIVATE_SELECT_HERO_TIP")
					})

					return
				end

				if var_8_9 == 1 then
					arg_8_0:purchaseGiftBag(var_8_7)
				else
					arg_8_0.activitiesModel:getActivityReward(arg_8_0.activity.table_id, var_8_7, function(arg_10_0, arg_10_1)
						if arg_10_0 == xyd.error.OK then
							arg_8_0.selfPlayer:handleRewards(arg_10_1.awards)

							if arg_10_1.base_info then
								arg_8_0.activities[arg_8_0.idx].details = arg_10_1.base_info
								arg_8_0.details = arg_10_1.base_info
							end

							arg_8_0:refreshRedPoint()
							arg_8_0:update()
						end
					end)
				end
			end
		end)
	end
end

function var_0_0.purchaseGiftBag(arg_11_0, arg_11_1)
	local var_11_0 = var_0_5:chargeId(arg_11_1)
	local var_11_1 = var_0_5:iosProductId(arg_11_1)
	local var_11_2 = true

	if device.platform == "android" then
		xyd.androidPurchase({
			var_11_0
		}, {}, var_11_0, false, var_0_5:charge(arg_11_1), var_0_5:name(arg_11_1))
	elseif device.platform == "ios" then
		xyd.sdkPurchase(var_11_1, var_11_2, var_11_0, {}, {}, {
			var_11_0
		})
	end

	xyd.WindowManager.get():closeWindow("activities")
end

function var_0_0.addStoneReward(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = xyd.getFormatItemsByGiftId(arg_12_2)
	local var_12_1
	local var_12_2 = arg_12_1:getContentSize().height
	local var_12_3 = display.newNode()

	var_12_3:setContentSize(var_12_2, var_12_2)

	if arg_12_0.details.hero > 0 then
		var_12_1 = xyd.tables.hero:stoneID(arg_12_0.details.hero)

		xyd.setItemBorder(var_12_3, var_12_1, false, false, arg_12_3)
	else
		xyd.setItemBorder(var_12_3, -102, nil, nil, arg_12_3)

		local var_12_4 = {}

		var_12_4.id = -102
		var_12_4.tipsType = 1

		arg_12_0:addTips(var_12_3, var_12_4)
	end

	var_12_3:addTo(arg_12_1)
	var_12_3:setAnchorPoint(cc.p(0, 0))
	var_12_3:setPosition(#var_12_0 * (var_12_2 * 5 / 4), 0)

	if arg_12_0.details.hero <= 0 then
		return
	end

	local var_12_5 = {
		id = var_12_1,
		lev = xyd.tables.item:level(var_12_1)
	}

	if xyd.tables.item:type(var_12_1) == -1 then
		var_12_5.tipsType = 0
		var_12_5.desc1 = xyd.tables.hero:getDes(var_12_1)
	else
		var_12_5.tipsType = 1
		var_12_5.desc1 = xyd.tables.item:desc1(var_12_1)
		var_12_5.desc2 = xyd.tables.item:desc2(var_12_1)
	end

	var_12_5.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_12_1)
	var_12_5.name = xyd.tables.item:name(var_12_1)

	arg_12_0:addTips(var_12_3, var_12_5)
end

function var_0_0.updateHeroCard(arg_13_0)
	arg_13_0.container:getChildByName("card_pos"):removeAllChildren(true)

	if arg_13_0.details.hero and arg_13_0.details.hero > 0 then
		local var_13_0 = arg_13_0.selfPlayer:getHeroIgnoreAwaken(arg_13_0.details.hero)
		local var_13_1 = xyd.tables.hero:skinItem(var_13_0:getFirstTableID())
		local var_13_2

		if var_13_1 and next(var_13_1) then
			local var_13_3 = xyd.tables.item:skinModel(var_13_1[1])

			var_13_2 = xyd.AssetLoader.get():loadSprite(xyd.tables.model:transparentCard(var_13_3))
		else
			var_13_2 = xyd.AssetLoader.get():loadSprite(xyd.tables.model:transparentCard(var_13_0:getModelID()))
		end

		var_13_2:setAnchorPoint(cc.p(0.5, 0))
		var_13_2:setScale(1)
		var_13_2:addTo(arg_13_0.container:getChildByName("card_pos"))
	end
end

function var_0_0.updateAwardScroll(arg_14_0)
	arg_14_0.awardedList:refreshList()
end

function var_0_0.delegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return 7
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		local var_15_0 = arg_15_0.awardedList:dequeueItem()

		if not var_15_0 then
			var_15_0 = arg_15_0.awardedList:newItem()
		else
			var_15_0:removeAllChildren(true)
		end

		local var_15_1 = arg_15_0:createListContent(arg_15_3)
		local var_15_2 = var_15_1:getWidth()
		local var_15_3 = var_15_1:getHeight()

		var_15_0:setItemSize(var_15_2, var_15_3 + 12)
		var_15_0:addContent(var_15_1)

		return var_15_0
	end
end

function var_0_0.createListContent(arg_16_0, arg_16_1)
	local var_16_0 = display.newNode()
	local var_16_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1156/day_item.csb")
	local var_16_2 = var_16_1:getChildByName("container")
	local var_16_3 = display.newNode()
	local var_16_4 = {
		size = 22,
		color = cc.c3b(255, 255, 255),
		text = var_0_1:translation("ACTIVITY_1156_TEXT" .. arg_16_1)
	}
	local var_16_5 = xyd.AssetLoader.get():loadLabel(var_16_4)

	var_16_5:addTo(var_16_3)
	var_16_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_16_5:setPosition(cc.p(0, 0))
	var_16_3:addTo(var_16_2:getChildByName("text_pos"))
	var_16_2:getChildByName("btn_not_open"):setVisible(false)
	var_16_2:getChildByName("btn_going"):setVisible(false)
	var_16_2:getChildByName("btn_complete"):setVisible(false)

	local var_16_6 = true

	if arg_16_0.currrentDay == arg_16_1 then
		var_16_2:getChildByName("btn_going"):setVisible(true)
		var_16_2:getChildByName("text_pos"):setPositionX(123)
	elseif arg_16_1 > arg_16_0.details.day or arg_16_0.details.hero <= 0 then
		var_16_6 = false

		var_16_2:getChildByName("btn_not_open"):setVisible(true)
		var_16_2:getChildByName("text_pos"):setPositionX(153)
	else
		var_16_2:getChildByName("btn_complete"):setVisible(true)
		var_16_2:getChildByName("text_pos"):setPositionX(153)
	end

	var_16_1:setTouchEnabled(true)
	var_16_1:setTouchSwallowEnabled(false)
	var_16_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
		if arg_17_0.name == "began" then
			return var_16_6
		elseif arg_17_0.name == "ended" then
			if arg_16_0.scrollViewMoved_ then
				return
			end

			arg_16_0.currrentDay = arg_16_1

			xyd.playButtonSound()
			arg_16_0:update()
		end
	end)
	var_16_1:addTo(var_16_0)
	var_16_1:setAnchorPoint(cc.p(0, 0))
	var_16_0:setContentSize(var_16_2:getContentSize())
	var_16_1:setName("source")

	return var_16_0
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevX_ = arg_18_1.x
	elseif arg_18_1.name == "moved" and 5 <= math.abs(arg_18_1.x - arg_18_0.prevX_) then
		arg_18_0.scrollViewMoved_ = true
	end
end

function var_0_0.createScheduler(arg_19_0)
	if arg_19_0.handle then
		var_0_3.unscheduleGlobal(arg_19_0.handle)

		arg_19_0.handle = nil
	end

	if arg_19_0.details.hero <= 0 or arg_19_0.details.day > 7 then
		arg_19_0:updateTimeShow(false)

		return
	else
		arg_19_0:updateTimeShow(true)
	end

	local var_19_0 = (18000 - xyd.ServerTime.get():getSecondsOfDay()) % 86400
	local var_19_1 = (7 - arg_19_0.details.day) * 86400 + var_19_0

	arg_19_0:updateTimeText(var_19_1)

	arg_19_0.handle = var_0_3.scheduleGlobal(function()
		if not arg_19_0 or var_19_1 < 0 then
			if arg_19_0.handle then
				var_0_3.unscheduleGlobal(arg_19_0.handle)

				arg_19_0.handle = nil

				if arg_19_0 then
					arg_19_0:updateTimeShow(false)
				end
			end

			return
		end

		var_19_1 = var_19_1 - 1

		arg_19_0:updateTimeText(var_19_1)
	end, 1)
end

function var_0_0.release(arg_21_0)
	if arg_21_0.handle then
		var_0_3.unscheduleGlobal(arg_21_0.handle)
	end

	var_0_0.super:release()
end

return var_0_0
