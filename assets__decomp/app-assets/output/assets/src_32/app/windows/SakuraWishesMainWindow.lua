local var_0_0 = class("SakuraWishesMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.arenaMode
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.common.ui.SpineEffect")
local var_0_6 = import("app.model.Pet")
local var_0_7 = import("framework.scheduler")
local var_0_8 = xyd.tables.activitySakuraWishesTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activityInfo = arg_1_2
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.sakuraWishesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA_WISHES)
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
	arg_10_0:nodeByName("one_crystal"):setString(xyd.tables.misc.chestUSPrice[1])
	arg_10_0:nodeByName("ten_crystal"):setString(xyd.tables.misc.chestUSPrice[2])
	arg_10_0:nodeByName("ticket_num"):setString(arg_10_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityChestUSTicket))
	arg_10_0:nodeByName("one_crystal"):enableOutline(cc.c4b(37, 83, 31, 255), 2)
	arg_10_0:nodeByName("ten_crystal"):enableOutline(cc.c4b(37, 83, 31, 255), 2)
	arg_10_0:nodeByName("ticket_num"):enableOutline(cc.c4b(37, 83, 31, 255), 2)
	arg_10_0:nodeByName("txt_one"):setString(var_0_1:translation("ACTIVITY_CHEST_US2_TIP1"))
	arg_10_0:nodeByName("txt_one_ticket"):setString(var_0_1:translation("ACTIVITY_CHEST_US2_TIP1"))
	arg_10_0:nodeByName("txt_ten"):setString(var_0_1:translation("ACTIVITY_CHEST_US2_TIP2"))
	arg_10_0:updateBtnShow()
	arg_10_0:nodeByName("list_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			xyd.WindowManager.get():openWindow("sakura_wishes_list")
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
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("ACTIVITY_CHEST_US_CONSUME"), xyd.tables.misc.chestUSPrice[2], 10), function()
				if arg_10_0.selfPlayer.crystal < xyd.tables.misc.chestUSPrice[2] then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_15_0 = {}

						var_15_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_15_0)
					end, nil, nil, arg_10_0.colorMode)
				else
					arg_10_0.sakuraWishesModel:summonTen(function(arg_16_0, arg_16_1)
						arg_10_0:summonCallBack(arg_16_0, arg_16_1)
					end)
				end
			end, nil, 0, arg_10_0.colorMode)
			xyd.playButtonSound()
			xyd.playButtonSound()
		end
	end)
	arg_10_0:nodeByName("btn_one"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("btn_one"), arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("ACTIVITY_CHEST_US_CONSUME"), xyd.tables.misc.chestUSPrice[1], 1), function()
				if arg_10_0.selfPlayer.crystal < xyd.tables.misc.chestUSPrice[1] then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_19_0 = {}

						var_19_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_19_0)
					end, nil, nil, arg_10_0.colorMode)
				else
					arg_10_0.sakuraWishesModel:summonOne(function(arg_20_0, arg_20_1)
						arg_10_0:summonCallBack(arg_20_0, arg_20_1)
					end)
				end
			end, nil, 0, arg_10_0.colorMode)
			xyd.playButtonSound()
		end
	end)
	arg_10_0:nodeByName("btn_ticket"):addTouchEventListener(function(arg_21_0, arg_21_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName("btn_ticket"), arg_21_1)

		if arg_21_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ACTIVITY_CHEST_US_TICKET"), function()
				arg_10_0.sakuraWishesModel:summonOneTicket(function(arg_23_0, arg_23_1)
					arg_10_0.selfPlayer:getBackpack():addItemsByID(xyd.tables.misc.activityChestUSTicket, -1)

					if arg_10_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityChestUSTicket) <= 0 then
						local var_23_0 = {}

						var_23_0.itemNum = 0
						var_23_0.itemID = xyd.tables.misc.activityChestUSTicket

						arg_10_0.selfPlayer:getBackpack():removeItem(var_23_0)
					end

					arg_10_0:updateBtnShow()
					arg_10_0:summonCallBack(arg_23_0, arg_23_1)
				end)
			end, nil, nil, arg_10_0.colorMode)
			xyd.playButtonSound()
		end
	end)
	arg_10_0:closeButton():addTouchEventListener(function(arg_24_0, arg_24_1)
		xyd.buttonScaleAnim(arg_10_0:closeButton(), arg_24_1)

		if arg_24_1 == ccui.TouchEventType.ended and not arg_10_0.isAnimated then
			local var_24_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_24_0, false)
			xyd.WindowManager.get():closeWindow(arg_10_0)
		end
	end)
	arg_10_0:updateRarestNameLabel()
	arg_10_0:addCountDownScheduler()
end

function var_0_0.updateBtnShow(arg_25_0)
	if arg_25_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityChestUSTicket) > 0 then
		arg_25_0:nodeByName("ticket_num"):setString(arg_25_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityChestUSTicket))
		arg_25_0:nodeByName("ticket_num"):setVisible(true)
		arg_25_0:nodeByName("ticket"):setVisible(true)
		arg_25_0:nodeByName("btn_ticket"):setVisible(true)
		arg_25_0:nodeByName("one_crystal"):setVisible(false)
		arg_25_0:nodeByName("yuanbao"):setVisible(false)
		arg_25_0:nodeByName("btn_one"):setVisible(false)
	else
		arg_25_0:nodeByName("ticket_num"):setVisible(false)
		arg_25_0:nodeByName("ticket"):setVisible(false)
		arg_25_0:nodeByName("btn_ticket"):setVisible(false)
		arg_25_0:nodeByName("one_crystal"):setVisible(true)
		arg_25_0:nodeByName("yuanbao"):setVisible(true)
		arg_25_0:nodeByName("btn_one"):setVisible(true)
	end
end

function var_0_0.summonCallBack(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = {}

	arg_26_0.selfPlayer:handleRewardsWithoutShow(arg_26_2.awards)

	for iter_26_0, iter_26_1 in pairs(arg_26_2.awards) do
		if tonumber(iter_26_0) then
			table.insert(var_26_0, iter_26_1)
		end
	end

	local var_26_1 = {
		items = var_26_0
	}

	var_26_1.lastType = 100
	var_26_1.extraAward = arg_26_2.items

	for iter_26_2, iter_26_3 in pairs(var_26_0) do
		arg_26_0.selfPlayer:heroUpdateEvent_({
			name = xyd.event.HERO_UPDATE,
			params = iter_26_3
		}, true)
	end

	xyd.WindowManager.get():openWindow("sakura_wishes_summon_result", var_26_1)
	arg_26_0:updateV9Count(arg_26_2.extra)
end

function var_0_0.updateV9Count(arg_27_0, arg_27_1)
	if arg_27_0.selfPlayer.vip < 9 then
		arg_27_0:nodeByName("box_v9"):setVisible(true)
		arg_27_0:nodeByName("box"):setVisible(false)
		arg_27_0:nodeByName("num"):setVisible(false)
		arg_27_0:nodeByName("num_bg"):setVisible(false)
	else
		arg_27_0:nodeByName("box_v9"):setVisible(false)
		arg_27_0:nodeByName("box"):setVisible(true)
		arg_27_0:nodeByName("num"):setVisible(true)
		arg_27_0:nodeByName("num_bg"):setVisible(true)
	end

	arg_27_0:nodeByName("num"):setString(arg_27_1 .. "/" .. xyd.tables.misc.chestUSMaxNum)

	if arg_27_1 >= xyd.tables.misc.chestUSMaxNum then
		arg_27_0:nodeByName("box_v9"):setVisible(false)
		arg_27_0:nodeByName("box"):setVisible(false)
		arg_27_0:nodeByName("num"):setVisible(false)
		arg_27_0:nodeByName("num_bg"):setVisible(false)

		local var_27_0 = "skeletons/ui_effect/sakura_wishes/chest_us"
		local var_27_1 = var_27_0 .. ".json"
		local var_27_2 = var_27_0 .. ".atlas"
		local var_27_3

		if arg_27_0.boxV9Effect then
			arg_27_0.boxV9Effect:stop()
			arg_27_0.boxV9Effect:removeFromParent()

			arg_27_0.boxV9Effect = nil
		end

		local var_27_4 = var_0_5.new(var_27_1, var_27_2, 1)

		var_27_4:setContentSize(1, 1)
		var_27_4:setAnchorPoint(cc.p(0.5, 0.5))
		var_27_4:addTo(arg_27_0)
		var_27_4:setPosition(arg_27_0:nodeByName("box_v9"):getPosition())
		var_27_4:play(nil, true)

		arg_27_0.boxV9Effect = var_27_4

		if not arg_27_0.boxV9ClickNode and arg_27_0.boxV9Effect and not tolua.isnull(arg_27_0.boxV9Effect) then
			arg_27_0.boxV9ClickNode = display.newNode()

			arg_27_0.boxV9ClickNode:setContentSize(85, 95)
			arg_27_0.boxV9ClickNode:setAnchorPoint(0.5, 0.5)
			arg_27_0.boxV9ClickNode:setPosition(arg_27_0:nodeByName("box_v9"):getPosition())
			arg_27_0.boxV9ClickNode:addTo(arg_27_0)
			arg_27_0.boxV9ClickNode:setTouchEnabled(true)
			arg_27_0.boxV9ClickNode:setTouchSwallowEnabled(false)
			arg_27_0.boxV9ClickNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
				if arg_28_0.name == "ended" then
					if arg_27_1 < xyd.tables.misc.chestUSMaxNum then
						return
					end

					arg_27_0.sakuraWishesModel:summonSuperRare(function(arg_29_0, arg_29_1)
						if arg_27_0.boxV9Effect then
							arg_27_0.boxV9Effect:stop()
							arg_27_0.boxV9Effect:removeFromParent()

							arg_27_0.boxV9Effect = nil
						end

						arg_27_0.tempResponse = arg_29_1

						local var_29_0 = arg_29_1.awards[1]

						if var_29_0.is_partner then
							arg_27_0.newCard = arg_27_0:getCard(var_29_0.table_id)
						elseif var_29_0.to_stone then
							arg_27_0.newCard = arg_27_0:getCard(xyd.tables.item:heroID(var_29_0.table_id))
						else
							arg_27_0.newCard = arg_27_0:getCard(xyd.tables.item:skinPartner(var_29_0.table_id), xyd.tables.item:skinModel(var_29_0.table_id))
						end

						arg_27_0:playSuperEffect(arg_29_1)
					end)
				end

				return true
			end)
		elseif arg_27_0.boxV9ClickNode then
			arg_27_0.boxV9ClickNode:setVisible(true)
		end
	else
		if arg_27_0.boxV9ClickNode then
			arg_27_0.boxV9ClickNode:setVisible(false)
		end

		if arg_27_0.boxV9Effect and not tolua.isnull(arg_27_0.boxV9Effect) then
			arg_27_0.boxV9Effect:setVisible(false)
		end

		arg_27_0:nodeByName("box_v9"):setTouchEnabled(true)
		arg_27_0:nodeByName("box_v9"):setTouchSwallowEnabled(false)
		arg_27_0:nodeByName("box_v9"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
			if arg_30_0.name == "ended" then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ACTIVITY_CHEST_US_VIP")
				})
			end

			return true
		end)
	end
end

function var_0_0.getCard(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = var_0_4.new()

	var_31_0:populateWithTableID(arg_31_1)

	local var_31_1

	if not arg_31_2 then
		var_31_1 = xyd.getHeroCard(var_31_0, 1)
	else
		var_31_0.isSkinOn_ = 1
		var_31_0.skinId_ = arg_31_2
		var_31_1 = xyd.getHeroCard(var_31_0, 2)
	end

	var_31_1:addTo(arg_31_0, 70)
	var_31_1:setPosition(640, 360)
	var_31_1:setTouchSwallowEnabled(true)
	var_31_1:setScale(0.65)
	var_31_1:setVisible(false)

	return var_31_1
end

function var_0_0.playSuperEffect(arg_32_0, arg_32_1)
	arg_32_0:addSuperBlockLayer()
	arg_32_0.superLayerListener:setSwallowTouches(true)

	arg_32_0.isAnimated = true

	if not arg_32_0.sakuraWishesEffect1_ then
		local var_32_0 = "skeletons/ui_effect/sakura_wishes/kapai1new"
		local var_32_1 = var_32_0 .. ".json"
		local var_32_2 = var_32_0 .. ".atlas"

		arg_32_0.sakuraWishesEffect1_ = var_0_5.new(var_32_1, var_32_2, 1)

		arg_32_0.sakuraWishesEffect1_:pos(640, 360)
		arg_32_0.sakuraWishesEffect1_:setAnchorPoint(cc.p(0.5, 0.5))
		arg_32_0.sakuraWishesEffect1_:addTo(arg_32_0, 100)
		arg_32_0.sakuraWishesEffect1_:setVisible(false)
	end

	if not arg_32_0.sakuraWishesEffect2_ then
		local var_32_3 = "skeletons/ui_effect/sakura_wishes/chest_us_kapa"
		local var_32_4 = var_32_3 .. ".json"
		local var_32_5 = var_32_3 .. ".atlas"

		arg_32_0.sakuraWishesEffect2_ = var_0_5.new(var_32_4, var_32_5, 1)

		arg_32_0.sakuraWishesEffect2_:pos(640, 360)
		arg_32_0.sakuraWishesEffect2_:setAnchorPoint(cc.p(0.5, 0.5))
		arg_32_0.sakuraWishesEffect2_:addTo(arg_32_0, 101)
		arg_32_0.sakuraWishesEffect2_:setVisible(false)
	end

	local var_32_6 = {}

	arg_32_0.sakuraWishesEffect1_:clearTracks()
	arg_32_0.sakuraWishesEffect2_:clearTracks()
	table.insert(var_32_6, cc.CallFunc:create(function()
		arg_32_0.sakuraWishesEffect1_:setVisible(true)
		arg_32_0.sakuraWishesEffect1_:play(function()
			arg_32_0.isAnimated = true

			local var_34_0 = arg_32_0.newCard:getChildByName("container"):getChildByName("cardFront"):getHeight()

			arg_32_0:playCardLight(var_34_0, 0.03, 14, {
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
	table.insert(var_32_6, cc.DelayTime:create(3))
	table.insert(var_32_6, cc.CallFunc:create(function()
		arg_32_0.sakuraWishesEffect2_:play(function()
			arg_32_0:finishSuperEffect(arg_32_1)
		end, nil)
	end))
	arg_32_0:runAction(transition.sequence(var_32_6))
end

function var_0_0.finishSuperEffect(arg_37_0, arg_37_1)
	arg_37_0.isAnimated = false

	if arg_37_0.sakuraWishesEffect1_ and not tolua.isnull(arg_37_0.sakuraWishesEffect1_) then
		arg_37_0.sakuraWishesEffect1_:setVisible(false)
		arg_37_0.sakuraWishesEffect2_:setVisible(false)
	end

	arg_37_0.newCard:setVisible(false)
	arg_37_0.selfPlayer:handleRewards(arg_37_1.awards)
	arg_37_0:updateV9Count(arg_37_1.extra)
	arg_37_0:removeSuperBlockLayer()

	arg_37_0.isAnimated = false
	arg_37_0.tempResponse = nil

	arg_37_0.superLayerListener:setSwallowTouches(false)
end

function var_0_0.playCardLight(arg_38_0, arg_38_1, arg_38_2, arg_38_3, arg_38_4, arg_38_5, arg_38_6, arg_38_7)
	local var_38_0 = cc.Director:getInstance():getWinSize()
	local var_38_1 = arg_38_0.newCard:getChildByName("container"):getChildByName("cardFront"):getWidth() / 2

	erase = cc.DrawNode:create()

	erase:drawDot(cc.p(0, 0), var_38_1, cc.c4f(0, 0, 0, 0))
	erase:retain()

	local var_38_2 = cc.RenderTexture:create(var_38_0.width, var_38_0.height)

	var_38_2:setPosition(640, 360)
	var_38_2:retain()
	var_38_2:addTo(arg_38_0, 80)
	var_38_2:begin()
	arg_38_0.sakuraWishesEffect1_:visit()
	var_38_2:endToLua()
	arg_38_0.sakuraWishesEffect1_:setVisible(false)

	local var_38_3 = arg_38_0:convertToWorldSpace(cc.p(0, 0))
	local var_38_4 = arg_38_1
	local var_38_5 = arg_38_4.y + var_38_3.y
	local var_38_6 = arg_38_4.x + var_38_3.x
	local var_38_7 = arg_38_5.y
	local var_38_8 = arg_38_3

	arg_38_0.newCard:setVisible(true)

	arg_38_0.delayHandle = var_0_7.performWithDelayGlobal(function()
		arg_38_0.shiningHandle = var_0_7.scheduleGlobal(function()
			erase:setPosition(var_38_6, var_38_5)
			arg_38_0.sakuraWishesEffect2_:setPosition(var_38_6 + 40, var_38_5 + 200)
			arg_38_0.sakuraWishesEffect2_:setVisible(true)
			erase:setBlendFunc(gl.ONE, gl.ZERO)
			var_38_2:begin()
			erase:visit()
			var_38_2:endToLua()

			var_38_5 = var_38_5 + var_38_8
			var_38_7 = var_38_7 + var_38_8

			if var_38_4 <= arg_38_1 / 2 and var_38_4 > arg_38_1 / 4 then
				var_38_8 = var_38_8 + 5
			elseif var_38_4 <= arg_38_1 / 4 then
				var_38_8 = var_38_8 + 30
			end

			if var_38_7 >= arg_38_6.y then
				var_38_2:setVisible(false)

				if arg_38_0.shiningHandle then
					var_0_7.unscheduleGlobal(arg_38_0.shiningHandle)
				end
			end
		end, arg_38_2)
	end, arg_38_7)
end

function var_0_0.updateRarestNameLabel(arg_41_0)
	local var_41_0 = var_0_8:ids()
	local var_41_1 = 0

	for iter_41_0, iter_41_1 in pairs(var_41_0) do
		if var_0_8:isRarest(iter_41_1) ~= 0 then
			arg_41_0:nodeByName("hero_name" .. var_41_1):setVisible(true)
			arg_41_0:nodeByName("rate_up" .. var_41_1):setVisible(true)
			arg_41_0:nodeByName("name_bg" .. var_41_1):setVisible(true)
			arg_41_0:nodeByName("hero_name" .. var_41_1):setString(xyd.tables.item:name(var_0_8:item(iter_41_1)))
			arg_41_0:nodeByName("hero_name" .. var_41_1):enableOutline(cc.c4b(171, 93, 33, 255), 2)

			var_41_1 = var_41_1 + 1
		end
	end
end

function var_0_0.addCountDownScheduler(arg_42_0)
	if arg_42_0.handle then
		var_0_7.unscheduleGlobal(arg_42_0.handle)

		arg_42_0.handle = nil
	end

	local var_42_0 = arg_42_0.activityInfo.end_time
	local var_42_1 = arg_42_0.activityInfo.start_time
	local var_42_2 = var_42_0 - xyd.ServerTime.get():getServerTime()

	arg_42_0:updateCountDownLabel(var_42_2)

	if var_42_2 > 0 and var_42_1 < xyd.ServerTime.get():getServerTime() then
		arg_42_0.handle = var_0_7.scheduleGlobal(function()
			arg_42_0:updateCountDownLabel(var_42_2)

			var_42_2 = var_42_2 - 1

			if var_42_2 <= 0 then
				var_0_7.unscheduleGlobal(arg_42_0.handle)

				arg_42_0.handle = nil
			end
		end, 1)
	else
		arg_42_0:nodeByName("count_down_label"):setString(var_0_1:translation("ACTIVITY_NO_OPEN"))
		arg_42_0:nodeByName("count_down_time"):setString("")
	end
end

function var_0_0.updateCountDownLabel(arg_44_0, arg_44_1)
	arg_44_0:nodeByName("count_down_label"):setString(var_0_1:translation("TEAM_DRINK_LEFT_TIME"))
	arg_44_0:nodeByName("count_down_time"):setString(xyd.timeFormatAsHMS(arg_44_1))
end

function var_0_0.checkActivityOpen(arg_45_0)
	local var_45_0 = xyd.ServerTime.get():getServerTime()

	if var_45_0 > arg_45_0.activityInfo.end_time or var_45_0 < arg_45_0.activityInfo.start_time then
		return false
	else
		return true
	end
end

return var_0_0
