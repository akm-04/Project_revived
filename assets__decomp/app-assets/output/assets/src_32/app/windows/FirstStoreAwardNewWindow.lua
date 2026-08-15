local var_0_0 = class("FirstStoreAwardNewWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = 90001001
local var_0_4 = 90001067
local var_0_5 = 980

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.params = arg_1_2
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.page = 1

	if arg_1_0.params.hasUnlimitGift == 1 then
		arg_1_0.page = 2
	end

	arg_1_0.isFirst = true
	arg_1_0.count = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setButtonClick()
	arg_3_0:updatePageShow()
	arg_3_0:nodeByName("title_bg2"):setVisible(false)
	arg_3_0:rewardLayer(arg_3_0:nodeByName("item_scroll"), var_0_4)
	arg_3_0:rewardFormat(arg_3_0:nodeByName("hero_container"), var_0_4)
	arg_3_0:nodeByName("hero1"):getChildByName("word1"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT2"))
	arg_3_0:nodeByName("hero1"):getChildByName("word2"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT4"))
	arg_3_0:nodeByName("hero2"):getChildByName("word1"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT1"))
	arg_3_0:nodeByName("hero2"):getChildByName("word2"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT3"))
	arg_3_0:nodeByName("hero3"):getChildByName("word1"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT2"))
	arg_3_0:nodeByName("hero3"):getChildByName("word2"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT5"))

	for iter_3_0 = 1, 3 do
		arg_3_0:nodeByName("get_btn" .. iter_3_0):getChildByName("view_text"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT6"))
		arg_3_0:nodeByName("get_btn" .. iter_3_0):getChildByName("get_text"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT7"))
		arg_3_0:nodeByName("get_btn" .. iter_3_0):getChildByName("already_get_text"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT8"))
	end

	arg_3_0:nodeByName("charge_btn"):getChildByName("getaward"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT7"))
	arg_3_0:nodeByName("charge_btn"):getChildByName("rechar"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT9"))
	arg_3_0:nodeByName("charge_btn"):getChildByName("alreadyget"):setString(var_0_1:translation("FIRST_STORE_AWARD_TEXT8"))
	arg_3_0:updateProgress()
	arg_3_0:playWindowAction()
end

function var_0_0.playWindowAction(arg_4_0)
	local var_4_0, var_4_1 = arg_4_0:nodeByName("hero2"):getPosition()
	local var_4_2, var_4_3 = arg_4_0:nodeByName("hero1"):getPosition()
	local var_4_4, var_4_5 = arg_4_0:nodeByName("hero3"):getPosition()
	local var_4_6, var_4_7 = arg_4_0:nodeByName("titile_bg1"):getPosition()
	local var_4_8 = cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_4_0:setTouchEnabled(false)
			arg_4_0:nodeByName("hero1"):setVisible(false)
			arg_4_0:nodeByName("hero3"):setVisible(false)
			arg_4_0:nodeByName("titile_bg1"):setVisible(false)
			arg_4_0:nodeByName("hero2"):setPositionY(var_4_1 + 20)
			arg_4_0:nodeByName("hero1"):setPositionY(var_4_3 + 20)
			arg_4_0:nodeByName("hero3"):setPositionY(var_4_5 + 20)
			arg_4_0:nodeByName("titile_bg1"):setPositionX(var_4_6 - 20)
		end),
		cc.Spawn:create({
			cc.MoveTo:create(0.2, cc.p(var_4_0, var_4_1))
		}),
		cc.CallFunc:create(function()
			local var_6_0 = cc.Sequence:create({
				cc.CallFunc:create(function()
					arg_4_0:nodeByName("hero1"):setVisible(true)
				end),
				cc.Spawn:create({
					cc.MoveTo:create(0.2, cc.p(var_4_2, var_4_3))
				}),
				cc.CallFunc:create(function()
					local var_8_0 = cc.Sequence:create({
						cc.CallFunc:create(function()
							arg_4_0:nodeByName("hero3"):setVisible(true)
						end),
						cc.Spawn:create({
							cc.MoveTo:create(0.2, cc.p(var_4_4, var_4_5))
						}),
						cc.CallFunc:create(function()
							local var_10_0 = cc.Sequence:create({
								cc.CallFunc:create(function()
									arg_4_0:nodeByName("titile_bg1"):setVisible(true)
								end),
								cc.Spawn:create({
									cc.MoveTo:create(0.2, cc.p(var_4_6, var_4_7))
								}),
								cc.CallFunc:create(function()
									arg_4_0:setTouchEnabled(true)
								end)
							})

							arg_4_0:nodeByName("titile_bg1"):runActionOnce(var_10_0)
						end)
					})

					arg_4_0:nodeByName("hero3"):runActionOnce(var_8_0)
				end)
			})

			arg_4_0:nodeByName("hero1"):runActionOnce(var_6_0)
		end)
	})

	arg_4_0:nodeByName("hero2"):runActionOnce(var_4_8)
end

function var_0_0.updatePageShow(arg_13_0)
	if arg_13_0.page == 1 then
		arg_13_0:nodeByName("page_left"):setVisible(false)
		arg_13_0:nodeByName("page_right"):setVisible(true)
		arg_13_0:nodeByName("three_select"):setVisible(true)
		arg_13_0:nodeByName("zhilong_container"):setVisible(false)
		arg_13_0:nodeByName("charge_btn"):setPosition(-358, -130)
	else
		arg_13_0:nodeByName("page_left"):setVisible(true)
		arg_13_0:nodeByName("page_right"):setVisible(false)
		arg_13_0:nodeByName("three_select"):setVisible(false)
		arg_13_0:nodeByName("zhilong_container"):setVisible(true)
		arg_13_0:nodeByName("charge_btn"):setPosition(-295, -30)
	end

	arg_13_0:updateBtnState()
end

function var_0_0.setButtonClick(arg_14_0)
	arg_14_0:nodeByName("page_left"):setTouchEnabled(true)
	arg_14_0:nodeByName("page_left"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			arg_14_0:nodeByName("page_left"):setScale(0.9)

			return true
		elseif arg_15_0.name == "moved" then
			arg_14_0:nodeByName("page_left"):setScale(1)
		elseif arg_15_0.name == "ended" then
			xyd.playButtonSound()
			arg_14_0:nodeByName("page_left"):setScale(1)

			arg_14_0.page = 1

			arg_14_0:updatePageShow()
		end
	end)
	arg_14_0:nodeByName("page_right"):setTouchEnabled(true)
	arg_14_0:nodeByName("page_right"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			arg_14_0:nodeByName("page_right"):setScale(0.9)

			return true
		elseif arg_16_0.name == "moved" then
			arg_14_0:nodeByName("page_right"):setScale(1)
		elseif arg_16_0.name == "ended" then
			xyd.playButtonSound()
			arg_14_0:nodeByName("page_right"):setScale(1)

			arg_14_0.page = 2

			arg_14_0:updatePageShow()
		end
	end)

	for iter_14_0 = 1, 3 do
		arg_14_0:nodeByName("get_btn" .. tostring(iter_14_0)):addTouchEventListener(function(arg_17_0, arg_17_1)
			if arg_17_1 == ccui.TouchEventType.began then
				arg_14_0:nodeByName("get_btn" .. tostring(iter_14_0)):setScale(0.9)
			elseif arg_17_1 == ccui.TouchEventType.moved then
				arg_14_0:nodeByName("get_btn" .. tostring(iter_14_0)):setScale(1)
			elseif arg_17_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_14_0:nodeByName("get_btn" .. tostring(iter_14_0)):setScale(1)

				local function var_17_0()
					arg_14_0.params.hasUnlimitGift = 1

					if arg_14_0.params.details.is_awarded == 0 then
						arg_14_0.page = 2
					end

					arg_14_0:updatePageShow()
					arg_14_0:refreshActivityMain()
				end

				local var_17_1 = {
					index = iter_14_0,
					UnlimitTableId = arg_14_0.UnlimitTableId,
					callback = var_17_0,
					can_award = arg_14_0.params.hasUnlimitGift == 0 and arg_14_0.params.details.charge > 0
				}

				xyd.WindowManager.get():openWindow("firststore_confirm", var_17_1)
			end
		end)
	end

	arg_14_0:nodeByName("charge_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.began then
			arg_14_0:nodeByName("charge_btn"):setScale(0.9)
		elseif arg_19_1 == ccui.TouchEventType.moved then
			arg_14_0:nodeByName("charge_btn"):setScale(1)
		elseif arg_19_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_14_0:nodeByName("charge_btn"):setScale(1)

			if arg_14_0.page == 2 and arg_14_0.hasAwardGift == 0 and arg_14_0.params.details.charge >= var_0_5 then
				local var_19_0 = arg_14_0.params.details.award_id

				arg_14_0.activitiesModel:getActivityReward(xyd.Activities.FirstStoreAward, var_19_0, function(arg_20_0, arg_20_1)
					arg_14_0.selfPlayer:handleRewards(arg_20_1.awards)
					arg_14_0:refreshActivityMain()
				end)

				arg_14_0.params.details.is_awarded = 1

				if arg_14_0.params.hasUnlimitGift == 0 then
					arg_14_0.page = 1
				end

				arg_14_0:updatePageShow()
			else
				local var_19_1 = {
					chargeState = xyd.ChargeState.diamond
				}

				xyd.WindowManager.get():openWindow("vip_recharge", var_19_1)
			end
		end
	end)
	arg_14_0:nodeByName("close"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.began then
			arg_14_0:nodeByName("close"):setScale(0.9)
		elseif arg_21_1 == ccui.TouchEventType.moved then
			arg_14_0:nodeByName("close"):setScale(1)
		elseif arg_21_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_14_0:nodeByName("close"):setScale(1)
			xyd.WindowManager.get():closeWindow(arg_14_0)
		end
	end)
end

function var_0_0.refreshActivityMain(arg_22_0)
	local var_22_0 = true

	if arg_22_0.hasUnlimitGift == 1 and arg_22_0.hasAwardGift == 1 then
		var_22_0 = false
	end

	local var_22_1 = false

	if arg_22_0.hasUnlimitGift == 0 and arg_22_0.params.details.charge > 0 or arg_22_0.hasAwardGift == 0 and arg_22_0.params.details.charge >= var_0_5 then
		var_22_1 = true
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_CHARGE_ACTIVITY_MAIN,
		params = {
			isShow = var_22_0,
			hasPoint = var_22_1
		}
	})
end

function var_0_0.updateBtnState(arg_23_0)
	arg_23_0.hasUnlimitGift = arg_23_0.params.hasUnlimitGift
	arg_23_0.UnlimitTableId = arg_23_0.params.UnlimitTableId
	arg_23_0.hasAwardGift = arg_23_0.params.details.is_awarded

	if arg_23_0.hasUnlimitGift == 0 then
		if arg_23_0.params.details.charge == 0 then
			for iter_23_0 = 1, 3 do
				local var_23_0 = arg_23_0:nodeByName("get_btn" .. tostring(iter_23_0))

				var_23_0:setBright(true)
				var_23_0:setTouchEnabled(true)
				var_23_0:getChildByName("get_text"):setVisible(false)
				var_23_0:getChildByName("view_text"):setVisible(true)
				var_23_0:getChildByName("already_get_text"):setVisible(false)
			end
		else
			for iter_23_1 = 1, 3 do
				local var_23_1 = arg_23_0:nodeByName("get_btn" .. tostring(iter_23_1))

				var_23_1:setBright(true)
				var_23_1:setTouchEnabled(true)
				var_23_1:getChildByName("get_text"):setVisible(true)
				var_23_1:getChildByName("view_text"):setVisible(false)
				var_23_1:getChildByName("already_get_text"):setVisible(false)
			end
		end
	elseif arg_23_0.hasUnlimitGift == 1 then
		for iter_23_2 = 1, 3 do
			local var_23_2 = arg_23_0:nodeByName("get_btn" .. tostring(iter_23_2))

			var_23_2:setBright(false)
			var_23_2:setTouchEnabled(false)
			var_23_2:getChildByName("get_text"):setVisible(false)
			var_23_2:getChildByName("view_text"):setVisible(false)
			var_23_2:getChildByName("already_get_text"):setVisible(true)
		end
	end

	if arg_23_0.hasAwardGift == 0 then
		if arg_23_0.params.details.charge < var_0_5 then
			arg_23_0:nodeByName("charge_btn"):setBright(true)
			arg_23_0:nodeByName("getaward"):setVisible(false)
			arg_23_0:nodeByName("rechar"):setVisible(true)
			arg_23_0:nodeByName("alreadyget"):setVisible(false)
		else
			arg_23_0:nodeByName("charge_btn"):setBright(true)
			arg_23_0:nodeByName("getaward"):setVisible(true)
			arg_23_0:nodeByName("rechar"):setVisible(false)
			arg_23_0:nodeByName("alreadyget"):setVisible(false)
		end
	else
		arg_23_0:nodeByName("charge_btn"):setBright(false)
		arg_23_0:nodeByName("getaward"):setVisible(false)
		arg_23_0:nodeByName("rechar"):setVisible(false)
		arg_23_0:nodeByName("alreadyget"):setVisible(true)
	end

	if arg_23_0.page == 1 then
		arg_23_0:nodeByName("charge_btn"):setBright(true)
		arg_23_0:nodeByName("getaward"):setVisible(false)
		arg_23_0:nodeByName("rechar"):setVisible(true)
		arg_23_0:nodeByName("alreadyget"):setVisible(false)
	end
end

function var_0_0.rewardFormat(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_1:getContentSize().height
	local var_24_1 = var_24_0 / 4 - 5
	local var_24_2 = xyd.tables.gift:items(arg_24_2)

	if #var_24_2 == 1 and var_24_2[1] == 0 then
		var_24_2 = {}
	end

	local var_24_3 = xyd.tables.gift:itemNum(arg_24_2)
	local var_24_4 = display.newNode()

	var_24_4:setContentSize(var_24_0, var_24_0)

	for iter_24_0 = 1, #var_24_2 do
		if xyd.tables.item:type(var_24_2[iter_24_0]) == -1 then
			xyd.setAvatarBorder(var_24_2[iter_24_0], var_24_4, 1, xyd.tables.hero:initialStar(var_24_2[iter_24_0]))
			var_24_4:addTo(arg_24_1)
			var_24_4:setAnchorPoint(cc.p(0, 0))
			var_24_4:setVisible(false)
			var_24_4:setPosition(0, 0)

			local var_24_5 = {
				id = var_24_2[iter_24_0],
				lev = xyd.tables.item:level(var_24_2[iter_24_0])
			}

			if xyd.tables.item:type(var_24_2[iter_24_0]) == -1 then
				var_24_5.tipsType = 0
				var_24_5.desc1 = xyd.tables.hero:getDes(var_24_2[iter_24_0])
			elseif specialItem then
				var_24_5.tipsType = 1
				var_24_5.id = -3
			else
				var_24_5.tipsType = 1
				var_24_5.desc1 = xyd.tables.item:desc1(var_24_2[iter_24_0])
				var_24_5.desc2 = xyd.tables.item:desc2(var_24_2[iter_24_0])
			end

			var_24_5.name = xyd.tables.item:name(var_24_2[iter_24_0])

			arg_24_0:addTips(var_24_4, var_24_5)
			var_0_2.performWithDelayGlobal(function()
				var_24_4:setVisible(true)

				local var_25_0, var_25_1 = arg_24_0:nodeByName("title_bg2"):getPosition()
				local var_25_2 = cc.Sequence:create({
					cc.CallFunc:create(function()
						arg_24_0:setTouchEnabled(false)
						arg_24_0:nodeByName("title_bg2"):setVisible(true)
						arg_24_0:nodeByName("title_bg2"):setPositionX(var_25_0 - 30)
					end),
					cc.Spawn:create({
						cc.MoveTo:create(0.3, cc.p(var_25_0, var_25_1))
					}),
					cc.CallFunc:create(function()
						arg_24_0:setTouchEnabled(true)
					end)
				})

				arg_24_0:nodeByName("title_bg2"):runActionOnce(var_25_2)
			end, 0.06 * (arg_24_0.count + 1))
		end
	end

	return arg_24_1
end

function var_0_0.rewardLayer(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	local var_28_0 = arg_28_1:getContentSize().height
	local var_28_1 = var_28_0 / 4 - 5
	local var_28_2 = xyd.tables.gift:items(arg_28_2)

	if #var_28_2 == 1 and var_28_2[1] == 0 then
		var_28_2 = {}
	end

	local var_28_3 = xyd.tables.gift:itemNum(arg_28_2)
	local var_28_4 = #var_28_2
	local var_28_5 = 0

	arg_28_0.count = #var_28_2

	for iter_28_0 = 1, #var_28_2 do
		if xyd.tables.item:type(var_28_2[iter_28_0]) ~= -1 then
			local var_28_6 = display.newNode()

			var_28_6:setContentSize(var_28_0, var_28_0)

			local var_28_7 = xyd.tables.item:type(var_28_2[iter_28_0])

			xyd.setItemBorder(var_28_6, var_28_2[iter_28_0], false, false, var_28_3[iter_28_0])
			var_28_6:addTo(arg_28_1)
			var_28_6:setAnchorPoint(cc.p(0, 0))
			var_28_6:setVisible(false)
			var_28_6:setPosition((iter_28_0 - var_28_5 - 1) * (var_28_0 + var_28_1), 0)

			local var_28_8 = {
				id = var_28_2[iter_28_0],
				lev = xyd.tables.item:level(var_28_2[iter_28_0])
			}

			if xyd.tables.item:type(var_28_2[iter_28_0]) == -1 then
				var_28_8.tipsType = 0
				var_28_8.desc1 = xyd.tables.hero:getDes(var_28_2[iter_28_0])
			elseif specialItem then
				var_28_8.tipsType = 1
				var_28_8.id = -3
			else
				var_28_8.tipsType = 1
				var_28_8.desc1 = xyd.tables.item:desc1(var_28_2[iter_28_0])
				var_28_8.desc2 = xyd.tables.item:desc2(var_28_2[iter_28_0])
			end

			var_28_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_28_2[iter_28_0])
			var_28_8.name = xyd.tables.item:name(var_28_2[iter_28_0])

			arg_28_0:addTips(var_28_6, var_28_8)
			var_0_2.performWithDelayGlobal(function()
				var_28_6:setVisible(true)
			end, 0.06 * iter_28_0)
		else
			var_28_5 = var_28_5 + 1
		end
	end

	local var_28_9 = var_28_4 - var_28_5
	local var_28_10 = xyd.tables.gift:crystal(arg_28_2)

	if var_28_10 and var_28_10 > 0 then
		local var_28_11 = display.newNode()

		var_28_11:setContentSize(var_28_0, var_28_0)
		xyd.setItemBorder(var_28_11, -1, false, false, var_28_10)
		var_28_11:addTo(arg_28_1)
		var_28_11:setAnchorPoint(cc.p(0, 0))
		var_28_11:setPosition(var_28_9 * (var_28_0 + var_28_1), 0)

		local var_28_12 = {}

		var_28_12.id = -1
		var_28_12.tipsType = 1

		arg_28_0:addTips(var_28_11, var_28_12)

		var_28_9 = var_28_9 + 1
	end

	local var_28_13 = xyd.tables.gift:mana(arg_28_2)

	if var_28_13 and var_28_13 > 0 then
		local var_28_14 = display.newNode()

		var_28_14:setContentSize(var_28_0, var_28_0)
		xyd.setItemBorder(var_28_14, -2, false, false, var_28_13)
		var_28_14:addTo(arg_28_1)
		var_28_14:setAnchorPoint(cc.p(0, 0))
		var_28_14:setPosition(var_28_9 * (var_28_0 + var_28_1), 0)

		local var_28_15 = {}

		var_28_15.id = -2
		var_28_15.tipsType = 1

		arg_28_0:addTips(var_28_14, var_28_15)

		var_28_9 = var_28_9 + 1
	end

	local var_28_16 = xyd.tables.gift:drops(arg_28_2)
	local var_28_17 = false

	if var_28_16 and next(var_28_16) then
		var_28_17 = #var_28_16 ~= 1 or var_28_16[1] ~= 0
	end

	if var_28_17 and arg_28_3 and arg_28_3.table_id == xyd.Activities.OnlineReward then
		local var_28_18 = display.newNode()

		var_28_18:addTo(arg_28_1)
		var_28_18:setAnchorPoint(cc.p(0.5, 0.5))
		var_28_18:setPosition(var_28_9 * (var_28_0 + var_28_1), 0)
		var_28_18:setContentSize(var_28_0, var_28_0)

		local var_28_19 = xyd.AssetLoader.get():loadSprite("images/icon/black_bg.png")

		if var_28_19 then
			local var_28_20 = var_28_18:getWidth()
			local var_28_21 = var_28_18:getHeight()
			local var_28_22 = var_28_20 / var_28_19:getWidth()

			var_28_19:setScale(var_28_22)
			var_28_19:addTo(var_28_18)
			var_28_19:setAnchorPoint(cc.p(0.5, 0.5))
			var_28_19:setPosition(var_28_20 / 2, var_28_21 / 2)

			local var_28_23 = xyd.getBorder(0, false)

			xyd.displaySpriteOnContainer(var_28_23, var_28_18, true)
		end

		local var_28_24 = {}

		var_28_24.id = -3
		var_28_24.tipsType = 1

		arg_28_0:addTips(var_28_18, var_28_24)

		local var_28_25 = var_28_9 + 1
	end

	return arg_28_1
end

function var_0_0.updateProgress(arg_30_0)
	local var_30_0 = 0
	local var_30_1 = arg_30_0.params.details.charge >= var_0_5 and 100 or math.min(arg_30_0.params.details.charge / var_0_5 * 100, 100)

	arg_30_0:nodeByName("progress_txt"):setString(tostring(arg_30_0.params.details.charge) .. "/" .. var_0_5)
	arg_30_0:nodeByName("progress_bar"):setPercent(var_30_1)
	arg_30_0:nodeByName("progress_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
end

return var_0_0
