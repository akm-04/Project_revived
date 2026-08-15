local var_0_0 = class("SakuraWishes2MainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.arenaMode
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.common.ui.SpineEffect")
local var_0_6 = import("app.model.Pet")
local var_0_7 = import("framework.scheduler")
local var_0_8 = xyd.tables.activitySakuraWishes2Table
local var_0_9 = tonumber(var_0_2:getValue("activity_chest_us2_ticket"))
local var_0_10 = xyd.splitToNumber(var_0_2:getValue("chest_us2_price"), "|")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activityInfo = arg_1_2
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.sakuraWishesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA_WISHES2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.willClose(arg_4_0, arg_4_1)
	if not arg_4_0.isAnimated then
		arg_4_0.super.willOpen(arg_4_0, arg_4_1)

		if arg_4_0.handle then
			var_0_7.unscheduleGlobal(arg_4_0.handle)
		end
	end

	if arg_4_0.shiningHandle then
		var_0_7.unscheduleGlobal(arg_4_0.shiningHandle)
	end
end

function var_0_0.addSuperBlockLayer(arg_5_0)
	local function var_5_0(arg_6_0, arg_6_1)
		return true
	end

	local function var_5_1(arg_7_0, arg_7_1)
		if not arg_5_0.noSuperTouch then
			arg_5_0:stopSuperEffect()
		end

		return true
	end

	if not arg_5_0.superBlockLayer_ then
		local var_5_2 = cc.c4b(0, 0, 0, 200)

		arg_5_0.superBlockLayer_ = display.newColorLayer(var_5_2)

		local var_5_3 = arg_5_0:convertToWorldSpace(cc.p(0, 0))

		arg_5_0.superBlockLayer_:pos(-var_5_3.x, -var_5_3.y):addTo(arg_5_0, 50)

		arg_5_0.superLayerListener = cc.EventListenerTouchOneByOne:create()

		arg_5_0.superLayerListener:setSwallowTouches(false)
		arg_5_0.superLayerListener:registerScriptHandler(var_5_0, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_5_0.superLayerListener:registerScriptHandler(var_5_1, cc.Handler.EVENT_TOUCH_ENDED)
		arg_5_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_5_0.superLayerListener, arg_5_0.superBlockLayer_)

		arg_5_0.noSuperTouch = false
	else
		arg_5_0.noSuperTouch = false

		arg_5_0.superBlockLayer_:setVisible(true)
	end
end

function var_0_0.stopSuperEffect(arg_8_0)
	arg_8_0.sakuraWishesEffect1_:stop()
	arg_8_0.sakuraWishesEffect1_:setVisible(false)
	arg_8_0.sakuraWishesEffect2_:stop()
	arg_8_0.sakuraWishesEffect2_:setVisible(false)
	arg_8_0:stopAllActions()
	arg_8_0:removeSuperBlockLayer()
	arg_8_0:finishSuperEffect(arg_8_0.tempResponse)
end

function var_0_0.removeSuperBlockLayer(arg_9_0)
	if arg_9_0.superBlockLayer_ then
		arg_9_0.superBlockLayer_:setVisible(false)

		arg_9_0.noSuperTouch = true
	end
end

function var_0_0.layout(arg_10_0)
	arg_10_0:nodeByName("count_down_label"):setString("")
	arg_10_0:nodeByName("count_down_time"):setString("")
	arg_10_0:updateV9Count(arg_10_0.activityInfo.details.extra)
	arg_10_0:nodeByName("one_crystal"):setString(var_0_10[1])
	arg_10_0:nodeByName("ten_crystal"):setString(var_0_10[2])
	arg_10_0:nodeByName("one_crystal"):enableOutline(cc.c4b(37, 83, 31, 255), 2)
	arg_10_0:nodeByName("ten_crystal"):enableOutline(cc.c4b(37, 83, 31, 255), 2)
	arg_10_0:nodeByName("ticket_num_one"):enableOutline(cc.c4b(37, 83, 31, 255), 2)
	arg_10_0:nodeByName("ticket_num_ten"):enableOutline(cc.c4b(37, 83, 31, 255), 2)
	arg_10_0:nodeByName("txt_one"):setString(var_0_1:translation("ACTIVITY_CHEST_US2_TIP1"))
	arg_10_0:nodeByName("txt_one_ticket"):setString(var_0_1:translation("ACTIVITY_CHEST_US2_TIP1"))
	arg_10_0:nodeByName("txt_ten"):setString(var_0_1:translation("ACTIVITY_CHEST_US2_TIP2"))
	arg_10_0:nodeByName("txt_ten_ticket"):setString(var_0_1:translation("ACTIVITY_CHEST_US2_TIP2"))
	arg_10_0:updateBtnShow()
	arg_10_0:nodeByName("list_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			xyd.WindowManager.get():openWindow("sakura_wishes_list_new")
			xyd.playButtonSound()
		end
	end)
	arg_10_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("rule_btn"), arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			local var_12_0 = {}

			var_12_0.title_name = "SAKURA_WISHES_RULE_TITLE"
			var_12_0.rule = "SAKURA_WISHES_RULE_TXT"

			xyd.WindowManager.get():openWindow("new_text_rule", var_12_0)
			xyd.playButtonSound()
		end
	end)
	arg_10_0:nodeByName("btn_ten"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("btn_ten"), arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("ACTIVITY_CHEST_US_CONSUME"), var_0_10[2], 10), function()
				if arg_10_0.selfPlayer.crystal < var_0_10[2] then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_15_0 = {}

						var_15_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_15_0)
					end)
				else
					arg_10_0.sakuraWishesModel:summonTen(function(arg_16_0, arg_16_1)
						if arg_16_0 == xyd.error.OK then
							arg_10_0:summonCallBack(arg_16_0, arg_16_1)
						end
					end)
				end
			end, nil, 0)
			xyd.playButtonSound()
			xyd.playButtonSound()
		end
	end)
	arg_10_0:nodeByName("btn_one"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("btn_one"), arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("ACTIVITY_CHEST_US_CONSUME"), var_0_10[1], 1), function()
				if arg_10_0.selfPlayer.crystal < var_0_10[1] then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_19_0 = {}

						var_19_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_19_0)
					end)
				else
					arg_10_0.sakuraWishesModel:summonOne(function(arg_20_0, arg_20_1)
						if arg_20_0 == xyd.error.OK then
							arg_10_0:summonCallBack(arg_20_0, arg_20_1)
						end
					end)
				end
			end, nil, 0)
			xyd.playButtonSound()
		end
	end)
	arg_10_0:nodeByName("btn_ticket_one"):addTouchEventListener(function(arg_21_0, arg_21_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("btn_ticket_one"), arg_21_1)

		if arg_21_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ACTIVITY_CHEST_US_TICKET"), function()
				arg_10_0.sakuraWishesModel:summonOneTicket(function(arg_23_0, arg_23_1)
					if arg_23_0 == xyd.error.OK then
						arg_10_0.backpack:addItemsByID(var_0_9, -1)

						if arg_10_0.backpack:getItemNumByID(var_0_9) <= 0 then
							local var_23_0 = {}

							var_23_0.itemNum = 0
							var_23_0.itemID = var_0_9

							arg_10_0.backpack:removeItem(var_23_0)
						end

						arg_10_0:updateBtnShow()
						arg_10_0:summonCallBack(arg_23_0, arg_23_1)
					end
				end)
			end)
			xyd.playButtonSound()
		end
	end)
	arg_10_0:nodeByName("btn_ticket_ten"):addTouchEventListener(function(arg_24_0, arg_24_1)
		xyd.buttonScaleAnim(arg_24_0, arg_24_1)

		if arg_24_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ACTIVITY_CHEST_US_TICKET2"), function()
				arg_10_0.sakuraWishesModel:summonTenTicket(function(arg_26_0, arg_26_1)
					if arg_26_0 == xyd.error.OK then
						arg_10_0.backpack:addItemsByID(var_0_9, -10)

						if arg_10_0.backpack:getItemNumByID(var_0_9) <= 0 then
							local var_26_0 = {}

							var_26_0.itemNum = 0
							var_26_0.itemID = var_0_9

							arg_10_0.backpack:removeItem(var_26_0)
						end

						arg_10_0:updateBtnShow()
						arg_10_0:summonCallBack(arg_26_0, arg_26_1)
					end
				end)
			end, nil, nil, arg_10_0.colorMode)
			xyd.playButtonSound()
		end
	end)
	arg_10_0:closeButton():addTouchEventListener(function(arg_27_0, arg_27_1)
		xyd.buttonScaleAnim(arg_10_0:closeButton(), arg_27_1)

		if arg_27_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			local var_27_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_27_0, false)
			xyd.WindowManager.get():closeWindow(arg_10_0)
		end
	end)
	arg_10_0:updateRarestNameLabel()
	arg_10_0:addCountDownScheduler()
end

function var_0_0.updateBtnShow(arg_28_0)
	arg_28_0:nodeByName("ticket_num_one"):setVisible(false)
	arg_28_0:nodeByName("ticket_num_ten"):setVisible(false)
	arg_28_0:nodeByName("ticket_one"):setVisible(false)
	arg_28_0:nodeByName("ticket_ten"):setVisible(false)
	arg_28_0:nodeByName("btn_ticket_one"):setVisible(false)
	arg_28_0:nodeByName("btn_ticket_ten"):setVisible(false)
end

function var_0_0.summonCallBack(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = {}

	arg_29_0.selfPlayer:handleRewardsWithoutShow(arg_29_2.awards)

	for iter_29_0, iter_29_1 in pairs(arg_29_2.awards) do
		if tonumber(iter_29_0) then
			table.insert(var_29_0, iter_29_1)
		end
	end

	local var_29_1 = {
		items = var_29_0
	}

	var_29_1.lastType = 100
	var_29_1.extraAward = arg_29_2.items
	var_29_1.modeType = xyd.ModelType.SAKURA_WISHES2

	for iter_29_2, iter_29_3 in pairs(var_29_0) do
		arg_29_0.selfPlayer:heroUpdateEvent_({
			name = xyd.event.HERO_UPDATE,
			params = iter_29_3
		}, true)
	end

	xyd.WindowManager.get():openWindow("sakura_wishes_summon_result", var_29_1)
	arg_29_0:updateV9Count(arg_29_2.extra)
end

function var_0_0.updateV9Count(arg_30_0, arg_30_1)
	if arg_30_0.selfPlayer.vip < 0 then
		arg_30_0:nodeByName("box_v9"):setVisible(true)
		arg_30_0:nodeByName("box"):setVisible(false)
		arg_30_0:nodeByName("num"):setVisible(false)
		arg_30_0:nodeByName("num_bg"):setVisible(false)
	else
		arg_30_0:nodeByName("box_v9"):setVisible(false)
		arg_30_0:nodeByName("box"):setVisible(true)
		arg_30_0:nodeByName("num"):setVisible(true)
		arg_30_0:nodeByName("num_bg"):setVisible(true)
	end

	arg_30_0:nodeByName("num"):setString(arg_30_1 .. "/" .. var_0_2:getValue("chest_us2_max_num"))

	if arg_30_1 >= tonumber(var_0_2:getValue("chest_us2_max_num")) then
		arg_30_0:nodeByName("box_v9"):setVisible(false)
		arg_30_0:nodeByName("box"):setVisible(false)
		arg_30_0:nodeByName("num"):setVisible(false)
		arg_30_0:nodeByName("num_bg"):setVisible(false)

		local var_30_0 = "skeletons/ui_effect/sakura_wishes/chest_us"
		local var_30_1 = var_30_0 .. ".json"
		local var_30_2 = var_30_0 .. ".atlas"
		local var_30_3

		if arg_30_0.boxV9Effect then
			arg_30_0.boxV9Effect:stop()
			arg_30_0.boxV9Effect:removeFromParent()

			arg_30_0.boxV9Effect = nil
		end

		local var_30_4 = var_0_5.new(var_30_1, var_30_2, 1)

		var_30_4:setContentSize(1, 1)
		var_30_4:setAnchorPoint(cc.p(0.5, 0.5))
		var_30_4:addTo(arg_30_0)
		var_30_4:setPosition(arg_30_0:nodeByName("box_v9"):getPosition())
		var_30_4:play(nil, true)

		arg_30_0.boxV9Effect = var_30_4

		if not arg_30_0.boxV9ClickNode and arg_30_0.boxV9Effect and not tolua.isnull(arg_30_0.boxV9Effect) then
			arg_30_0.boxV9ClickNode = display.newNode()

			arg_30_0.boxV9ClickNode:setContentSize(85, 95)
			arg_30_0.boxV9ClickNode:setAnchorPoint(0.5, 0.5)
			arg_30_0.boxV9ClickNode:setPosition(arg_30_0:nodeByName("box_v9"):getPosition())
			arg_30_0.boxV9ClickNode:addTo(arg_30_0)
			arg_30_0.boxV9ClickNode:setTouchEnabled(true)
			arg_30_0.boxV9ClickNode:setTouchSwallowEnabled(false)
			arg_30_0.boxV9ClickNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_31_0)
				if arg_31_0.name == "ended" then
					if arg_30_1 < tonumber(var_0_2:getValue("chest_us2_max_num")) then
						return
					end

					arg_30_0.sakuraWishesModel:summonSuperRare(function(arg_32_0, arg_32_1)
						if arg_32_0 == xyd.error.OK then
							if arg_30_0.boxV9Effect then
								arg_30_0.boxV9Effect:stop()
								arg_30_0.boxV9Effect:removeFromParent()

								arg_30_0.boxV9Effect = nil
							end

							arg_30_0.tempResponse = arg_32_1

							local var_32_0 = arg_32_1.awards[1]

							if var_32_0.is_partner then
								arg_30_0.newCard = arg_30_0:getCard(var_32_0.table_id)
							elseif var_32_0.to_stone then
								arg_30_0.newCard = arg_30_0:getCard(xyd.tables.item:heroID(var_32_0.table_id))
							else
								arg_30_0.newCard = arg_30_0:getCard(xyd.tables.item:skinPartner(var_32_0.table_id), xyd.tables.item:skinModel(var_32_0.table_id))
							end

							arg_30_0:playSuperEffect(arg_32_1)
						end
					end)
				end

				return true
			end)
		elseif arg_30_0.boxV9ClickNode then
			arg_30_0.boxV9ClickNode:setVisible(true)
		end
	else
		if arg_30_0.boxV9ClickNode then
			arg_30_0.boxV9ClickNode:setVisible(false)
		end

		if arg_30_0.boxV9Effect and not tolua.isnull(arg_30_0.boxV9Effect) then
			arg_30_0.boxV9Effect:setVisible(false)
		end

		arg_30_0:nodeByName("box_v9"):setTouchEnabled(true)
		arg_30_0:nodeByName("box_v9"):setTouchSwallowEnabled(false)
		arg_30_0:nodeByName("box_v9"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_33_0)
			if arg_33_0.name == "ended" then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ACTIVITY_CHEST_US_VIP")
				})
			end

			return true
		end)
	end
end

function var_0_0.getCard(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = var_0_4.new()

	var_34_0:populateWithTableID(arg_34_1)

	local var_34_1

	if not arg_34_2 then
		var_34_1 = xyd.getHeroCard(var_34_0, 1)
	else
		var_34_0.isSkinOn_ = 1
		var_34_0.skinId_ = arg_34_2
		var_34_1 = xyd.getHeroCard(var_34_0, 2)
	end

	var_34_1:addTo(arg_34_0, 70)
	var_34_1:setPosition(640, 360)
	var_34_1:setTouchSwallowEnabled(true)
	var_34_1:setScale(0.65)
	var_34_1:setVisible(false)

	return var_34_1
end

function var_0_0.playSuperEffect(arg_35_0, arg_35_1)
	arg_35_0:addSuperBlockLayer()
	arg_35_0.superLayerListener:setSwallowTouches(true)

	arg_35_0.isAnimated = true

	if not arg_35_0.sakuraWishesEffect1_ then
		local var_35_0 = "skeletons/ui_effect/sakura_wishes/kapai1new"
		local var_35_1 = var_35_0 .. ".json"
		local var_35_2 = var_35_0 .. ".atlas"

		arg_35_0.sakuraWishesEffect1_ = var_0_5.new(var_35_1, var_35_2, 1)

		arg_35_0.sakuraWishesEffect1_:pos(640, 360)
		arg_35_0.sakuraWishesEffect1_:setAnchorPoint(cc.p(0.5, 0.5))
		arg_35_0.sakuraWishesEffect1_:addTo(arg_35_0, 100)
		arg_35_0.sakuraWishesEffect1_:setVisible(false)
	end

	if not arg_35_0.sakuraWishesEffect2_ then
		local var_35_3 = "skeletons/ui_effect/sakura_wishes/chest_us_kapa"
		local var_35_4 = var_35_3 .. ".json"
		local var_35_5 = var_35_3 .. ".atlas"

		arg_35_0.sakuraWishesEffect2_ = var_0_5.new(var_35_4, var_35_5, 1)

		arg_35_0.sakuraWishesEffect2_:pos(640, 360)
		arg_35_0.sakuraWishesEffect2_:setAnchorPoint(cc.p(0.5, 0.5))
		arg_35_0.sakuraWishesEffect2_:addTo(arg_35_0, 101)
		arg_35_0.sakuraWishesEffect2_:setVisible(false)
	end

	local var_35_6 = {}

	arg_35_0.sakuraWishesEffect1_:clearTracks()
	arg_35_0.sakuraWishesEffect2_:clearTracks()
	table.insert(var_35_6, cc.CallFunc:create(function()
		arg_35_0.sakuraWishesEffect1_:setVisible(true)
		arg_35_0.sakuraWishesEffect1_:play(function()
			arg_35_0.isAnimated = true

			local var_37_0 = arg_35_0.newCard:getChildByName("container"):getChildByName("cardFront"):getHeight()

			arg_35_0:playCardLight(var_37_0, 0.02, 14, {
				x = 610,
				y = -60
			}, {
				x = 600,
				y = -60
			}, {
				x = 610,
				y = 360
			}, 0.05)
		end, nil)
	end))
	table.insert(var_35_6, cc.DelayTime:create(3))
	table.insert(var_35_6, cc.CallFunc:create(function()
		arg_35_0.sakuraWishesEffect2_:play(function()
			arg_35_0:finishSuperEffect(arg_35_1)
		end, nil)
	end))
	arg_35_0:runAction(transition.sequence(var_35_6))
end

function var_0_0.finishSuperEffect(arg_40_0, arg_40_1)
	arg_40_0.isAnimated = false

	if arg_40_0.sakuraWishesEffect1_ and not tolua.isnull(arg_40_0.sakuraWishesEffect1_) then
		arg_40_0.sakuraWishesEffect1_:setVisible(false)
		arg_40_0.sakuraWishesEffect2_:setVisible(false)
	end

	arg_40_0.newCard:setVisible(false)
	arg_40_0.selfPlayer:handleRewards(arg_40_1.awards)
	arg_40_0:updateV9Count(arg_40_1.extra)
	arg_40_0:removeSuperBlockLayer()

	arg_40_0.isAnimated = false
	arg_40_0.tempResponse = nil

	arg_40_0.superLayerListener:setSwallowTouches(false)
end

function var_0_0.playCardLight(arg_41_0, arg_41_1, arg_41_2, arg_41_3, arg_41_4, arg_41_5, arg_41_6, arg_41_7)
	local var_41_0 = arg_41_0.newCard:getChildByName("container"):getChildByName("cardFront"):getWidth() / 2
	local var_41_1 = cc.DrawNode:create()

	var_41_1:drawDot(cc.p(0, 0), var_41_0, cc.c4f(0, 0, 0, 0))
	var_41_1:retain()

	local var_41_2 = cc.RenderTexture:create(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)

	var_41_2:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)
	var_41_2:addTo(arg_41_0, 80)
	var_41_2:begin()
	arg_41_0.sakuraWishesEffect1_:visit()
	var_41_2:endToLua()
	arg_41_0.sakuraWishesEffect1_:setVisible(false)

	local var_41_3 = arg_41_1
	local var_41_4 = arg_41_4.y
	local var_41_5 = arg_41_4.x
	local var_41_6 = arg_41_5.y
	local var_41_7 = arg_41_3

	arg_41_0.newCard:setVisible(true)

	arg_41_0.delayHandle = var_0_7.performWithDelayGlobal(function()
		arg_41_0.shiningHandle = var_0_7.scheduleGlobal(function()
			var_41_1:setPosition(var_41_5, var_41_4)
			arg_41_0.sakuraWishesEffect2_:setPosition(var_41_5 + 40, var_41_4 + 200)
			arg_41_0.sakuraWishesEffect2_:setVisible(true)
			var_41_1:setBlendFunc(gl.ONE, gl.ZERO)
			var_41_2:begin()
			var_41_1:visit()
			var_41_2:endToLua()

			var_41_4 = var_41_4 + var_41_7
			var_41_6 = var_41_6 + var_41_7

			if var_41_3 <= arg_41_1 / 2 and var_41_3 > arg_41_1 / 4 then
				var_41_7 = var_41_7 + 5
			elseif var_41_3 <= arg_41_1 / 4 then
				var_41_7 = var_41_7 + 30
			end

			if var_41_6 >= arg_41_6.y then
				var_41_2:setVisible(false)
				var_41_1:release()

				if arg_41_0.shiningHandle then
					var_0_7.unscheduleGlobal(arg_41_0.shiningHandle)

					arg_41_0.shiningHandle = nil
				end
			end
		end, arg_41_2)
	end, arg_41_7)
end

function var_0_0.updateRarestNameLabel(arg_44_0)
	local var_44_0 = var_0_8:ids()
	local var_44_1 = 0

	for iter_44_0, iter_44_1 in pairs(var_44_0) do
		if var_0_8:isRarest(iter_44_1) ~= 0 then
			arg_44_0:nodeByName("hero_name" .. var_44_1):setVisible(true)
			arg_44_0:nodeByName("rate_up" .. var_44_1):setVisible(true)
			arg_44_0:nodeByName("name_bg" .. var_44_1):setVisible(true)
			arg_44_0:nodeByName("hero_name" .. var_44_1):setString(xyd.tables.item:name(var_0_8:item(iter_44_1)))
			arg_44_0:nodeByName("hero_name" .. var_44_1):enableOutline(cc.c4b(171, 93, 33, 255), 2)

			var_44_1 = var_44_1 + 1
		end
	end
end

function var_0_0.addCountDownScheduler(arg_45_0)
	if arg_45_0.handle then
		var_0_7.unscheduleGlobal(arg_45_0.handle)

		arg_45_0.handle = nil
	end

	local var_45_0 = arg_45_0.activityInfo.end_time
	local var_45_1 = arg_45_0.activityInfo.start_time
	local var_45_2 = var_45_0 - xyd.ServerTime.get():getServerTime()

	arg_45_0:updateCountDownLabel(var_45_2)

	if var_45_2 > 0 and var_45_1 < xyd.ServerTime.get():getServerTime() then
		arg_45_0.handle = var_0_7.scheduleGlobal(function()
			arg_45_0:updateCountDownLabel(var_45_2)

			var_45_2 = var_45_2 - 1

			if var_45_2 <= 0 then
				var_0_7.unscheduleGlobal(arg_45_0.handle)

				arg_45_0.handle = nil
			end
		end, 1)
	else
		arg_45_0:nodeByName("count_down_label"):setString(var_0_1:translation("ACTIVITY_NO_OPEN"))
		arg_45_0:nodeByName("count_down_time"):setString("")
	end
end

function var_0_0.updateCountDownLabel(arg_47_0, arg_47_1)
	arg_47_0:nodeByName("count_down_label"):setString(var_0_1:translation("TEAM_DRINK_LEFT_TIME"))
	arg_47_0:nodeByName("count_down_time"):setString(xyd.timeFormatAsHMS(arg_47_1))
end

function var_0_0.checkActivityOpen(arg_48_0)
	local var_48_0 = xyd.ServerTime.get():getServerTime()

	if var_48_0 > arg_48_0.activityInfo.end_time or var_48_0 < arg_48_0.activityInfo.start_time then
		return false
	else
		return true
	end
end

return var_0_0
