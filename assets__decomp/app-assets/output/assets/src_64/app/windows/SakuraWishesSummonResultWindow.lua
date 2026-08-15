local var_0_0 = class("SakuraWishesSummonResultWindow", import("app.windows.SummonResultWindow"))
local var_0_1 = xyd.WindowName.summonWnd
local var_0_2 = xyd.WindowName.summonResultWnd
local var_0_3 = xyd.tables.misc
local var_0_4 = xyd.tables.translation
local var_0_5 = import("app.common.ui.SpineEffect")
local var_0_6 = import("app.model.Hero")
local var_0_7 = import("app.model.Pet")
local var_0_8 = import("framework.scheduler")

var_0_0.summonType = {
	Ten = 200,
	One = 100
}

local var_0_9 = 150

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.sakuraWishesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA_WISHES)
end

function var_0_0.layout(arg_2_0)
	arg_2_0.tmpNode = {}

	arg_2_0:getBackAnimation()
	arg_2_0:getAgainBtn()
	arg_2_0:getSkipBtn()
	arg_2_0:getCloseBtn()
	arg_2_0:setItems()
	arg_2_0:recordPosition()
	arg_2_0:setInitPosition()
	arg_2_0:getDesText():setVisible(false)

	local var_2_0, var_2_1, var_2_2, var_2_3 = arg_2_0:getPriceIcon()

	var_2_0:setVisible(true)
	var_2_1:setVisible(false)
	var_2_2:setVisible(false)
	var_2_3:setVisible(false)

	arg_2_0.ticketSprite = xyd.AssetLoader.get():loadSprite("windows/sakura_wishes/main/ticket.png")

	arg_2_0.ticketSprite:addTo(arg_2_0:nodeByName("price"))
	arg_2_0.ticketSprite:setAnchorPoint(cc.p(0.5, 0.5))
	arg_2_0.ticketSprite:scale(0.5)
	arg_2_0.ticketSprite:setPosition(arg_2_0:nodeByName("crystal"):getPosition())
	arg_2_0.ticketSprite:setVisible(false)
	arg_2_0:getBottomContainer():setVisible(false)
	arg_2_0:nodeByName("button_hundred"):setVisible(false)
	arg_2_0:nodeByName("price_hundred"):setVisible(false)
	arg_2_0:nodeByName("left_star"):setVisible(false)
	arg_2_0:nodeByName("right_star"):setVisible(false)
	arg_2_0:nodeByName("discount"):setVisible(false)
	arg_2_0:nodeByName("3"):setVisible(false)
	arg_2_0:nodeByName("5"):setVisible(false)
	arg_2_0:nodeByName("discount"):setVisible(false)
	arg_2_0:nodeByName("3"):setVisible(false)
	arg_2_0:nodeByName("5"):setVisible(false)

	arg_2_0.threeDiscountNum = arg_2_0.selfPlayer:getBackpack():getItemNumByID(threeDiscountID)
	arg_2_0.fiveDiscountNum = arg_2_0.selfPlayer:getBackpack():getItemNumByID(fiveDiscountID)

	if #arg_2_0.items_ == 1 then
		arg_2_0:getPriceText():setString(xyd.tables.misc.chestUSPrice[1])
	else
		arg_2_0:getPriceText():setString(xyd.tables.misc.chestUSPrice[2])
	end

	arg_2_0:nodeByName("return"):getChildByName("txt"):setString(var_0_4:translation("SUMMON_EXIT"))
	arg_2_0:updateCrystalShow(arg_2_0.items_)
	arg_2_0:playSakuraEffect()
end

function var_0_0.updateCrystalShow(arg_3_0, arg_3_1)
	if #arg_3_1 == 1 then
		arg_3_0:nodeByName("3"):setVisible(false)

		if arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityChestUSTicket) > 0 then
			arg_3_0:getPriceText():setString(1)
			arg_3_0:nodeByName("crystal"):setVisible(false)
			arg_3_0.ticketSprite:setVisible(true)
		else
			arg_3_0:getPriceText():setString(xyd.tables.misc.chestUSPrice[1])
			arg_3_0:nodeByName("crystal"):setVisible(true)
			arg_3_0.ticketSprite:setVisible(false)
		end
	else
		arg_3_0.ticketSprite:setVisible(false)
		arg_3_0:nodeByName("crystal"):setVisible(true)
		arg_3_0:nodeByName("5"):setVisible(false)
		arg_3_0:getPriceText():setString(xyd.tables.misc.chestUSPrice[2])
	end
end

function var_0_0.getAgainBtn(arg_4_0)
	if not arg_4_0.againBtn_ then
		arg_4_0.againBtn_ = arg_4_0:nodeByName("button_again")

		local var_4_0 = #arg_4_0.items_

		if #arg_4_0.items_ == 6 then
			var_4_0 = 1
		end

		if var_4_0 == 1 then
			arg_4_0.againBtn_:getChildByName("txt"):setString(var_0_4:translation("SUMMON_BUY_AGAIN1"))
		else
			arg_4_0.againBtn_:getChildByName("txt"):setString(var_0_4:translation("SUMMON_BUY_AGAIN10"))
		end

		xyd.nodeEventSample(arg_4_0.againBtn_, nil, function(arg_5_0)
			xyd.playButtonSound()

			if not arg_4_0.isAnimated then
				local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
				local var_5_1 = 0

				if #arg_4_0.items_ == 1 then
					var_5_1 = xyd.tables.misc.chestUSPrice[1]
				else
					var_5_1 = xyd.tables.misc.chestUSPrice[2]
				end

				if var_5_1 > var_5_0.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
						local var_6_0 = {}

						var_6_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
					end, nil, nil, arg_4_0.colorMode)
				else
					arg_4_0:summonAgain()
				end
			end
		end)
	end

	return arg_4_0.againBtn_
end

function var_0_0.checkShowExtraReward(arg_7_0)
	return
end

function var_0_0.updateItemIcon(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	arg_8_0.super.updateItemIcon(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
end

function var_0_0.getSkipBtn(arg_9_0)
	if not arg_9_0.skipBtn_ then
		arg_9_0.skipBtn_ = arg_9_0:nodeByName("skip")
	end

	xyd.nodeEventSample(arg_9_0.skipBtn_, nil, function(arg_10_0)
		xyd.playButtonSound()

		arg_9_0.isSkipAnimation = true

		arg_9_0:setSkipBtnVisible(false)
	end)
	arg_9_0:setSkipBtnVisible(false)

	return arg_9_0.skipBtn_
end

function var_0_0.summonAgain(arg_11_0, arg_11_1)
	local var_11_0

	if #arg_11_0.items_ ~= 1 then
		var_11_0 = arg_11_0.sakuraWishesModel.summonTen
	elseif arg_11_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityChestUSTicket) > 0 then
		var_11_0 = arg_11_0.sakuraWishesModel.summonOneTicket
	else
		var_11_0 = arg_11_0.sakuraWishesModel.summonOne
	end

	collectgarbage("collect")
	var_11_0(nil, function(arg_12_0, arg_12_1)
		if arg_12_0 ~= xyd.error.OK then
			return
		end

		local var_12_0 = {}

		arg_11_0.selfPlayer:handleRewardsWithoutShow(arg_12_1.awards)

		for iter_12_0, iter_12_1 in pairs(arg_12_1.awards) do
			if tonumber(iter_12_0) then
				table.insert(var_12_0, iter_12_1)
			end
		end

		for iter_12_2, iter_12_3 in pairs(var_12_0) do
			arg_11_0.selfPlayer:heroUpdateEvent_({
				name = xyd.event.HERO_UPDATE,
				params = iter_12_3
			}, true)
		end

		arg_11_0:refresh(var_12_0)

		if var_11_0 == arg_11_0.sakuraWishesModel.summonOneTicket then
			arg_11_0.selfPlayer:getBackpack():addItemsByID(xyd.tables.misc.activityChestUSTicket, -1)

			if arg_11_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityChestUSTicket) <= 0 then
				local var_12_1 = {}

				var_12_1.itemNum = 0
				var_12_1.itemID = xyd.tables.misc.activityChestUSTicket

				arg_11_0.selfPlayer:getBackpack():removeItem(var_12_1)
			end

			if xyd.WindowManager.get():getWindow("sakura_wishes_main") then
				xyd.WindowManager.get():getWindow("sakura_wishes_main"):updateBtnShow()
			end
		end

		arg_11_0:updateCrystalShow(var_12_0)

		if xyd.WindowManager.get():getWindow("sakura_wishes_main") then
			xyd.WindowManager.get():getWindow("sakura_wishes_main"):updateV9Count(arg_12_1.extra)
		end
	end)

	arg_11_0.isAnimated = true

	if arg_11_1 then
		arg_11_0.isAnimated = false
	end
end

function var_0_0.refresh(arg_13_0, arg_13_1)
	arg_13_0.super.refresh(arg_13_0, arg_13_1, {})
end

function var_0_0.getCard(arg_14_0, arg_14_1)
	local var_14_0 = var_0_6.new()

	var_14_0:populateWithTableID(arg_14_1)

	local var_14_1 = xyd.getHeroCard(var_14_0, 1)

	var_14_1:addTo(arg_14_0:nodeByName("main"), 70)
	var_14_1:setPosition(390, 280)
	var_14_1:setTouchSwallowEnabled(true)
	var_14_1:setScale(0.65)
	var_14_1:setVisible(false)

	return var_14_1
end

function var_0_0.playCardLight(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)
	local var_15_0 = cc.Director:getInstance():getWinSize()
	local var_15_1 = arg_15_0.newCard:getChildByName("container"):getChildByName("cardFront"):getWidth() / 2

	erase = cc.DrawNode:create()

	erase:drawDot(cc.p(0, 0), var_15_1, cc.c4f(0, 0, 0, 0))
	erase:retain()

	local var_15_2 = cc.RenderTexture:create(var_15_0.width, var_15_0.height)

	var_15_2:setPosition(var_15_0.width / 2, var_15_0.height / 2)
	var_15_2:retain()
	var_15_2:addTo(arg_15_0:nodeByName("main"), 80)
	var_15_2:begin()
	arg_15_0.sakuraWishesEffect1_:visit()
	var_15_2:endToLua()
	arg_15_0.sakuraWishesEffect1_:setVisible(false)

	local var_15_3 = arg_15_0:convertToWorldSpace(cc.p(0, 0))
	local var_15_4, var_15_5 = xyd.convertWorldPos(var_15_3.x, var_15_3.y)
	local var_15_6 = arg_15_1
	local var_15_7 = arg_15_4.y + var_15_4
	local var_15_8 = arg_15_4.x + var_15_5
	local var_15_9 = arg_15_5.y
	local var_15_10 = arg_15_3

	arg_15_0.newCard:setVisible(true)

	arg_15_0.delayHandle = var_0_8.performWithDelayGlobal(function()
		arg_15_0.shiningHandle = var_0_8.scheduleGlobal(function()
			erase:setPosition(var_15_8, var_15_7)
			arg_15_0.sakuraWishesEffect2_:setPosition(var_15_8 + 40, var_15_7 + 200)
			arg_15_0.sakuraWishesEffect2_:setVisible(true)
			erase:setBlendFunc(gl.ONE, gl.ZERO)
			var_15_2:begin()
			erase:visit()
			var_15_2:endToLua()

			var_15_7 = var_15_7 + var_15_10
			var_15_9 = var_15_9 + var_15_10

			if var_15_6 <= arg_15_1 / 2 and var_15_6 > arg_15_1 / 4 then
				var_15_10 = var_15_10 + 5
			elseif var_15_6 <= arg_15_1 / 4 then
				var_15_10 = var_15_10 + 30
			end

			if var_15_9 >= arg_15_6.y then
				var_15_2:setVisible(false)

				if arg_15_0.shiningHandle then
					var_0_8.unscheduleGlobal(arg_15_0.shiningHandle)
				end
			end
		end, arg_15_2)
	end, arg_15_7)
end

function var_0_0.playSakuraEffect(arg_18_0)
	local var_18_0 = "skeletons/ui_effect/sakura_wishes/yinghuaparticle_texture"

	arg_18_0.sakuraEffect = cc.ParticleSystemQuad:create(var_18_0 .. ".plist")

	arg_18_0.sakuraEffect:setPosition(430, 660)
	arg_18_0.sakuraEffect:setRotation(15)
	arg_18_0.sakuraEffect:addTo(arg_18_0:nodeByName("main"), 1)
	arg_18_0.sakuraEffect:setVisible(true)
end

function var_0_0.playSuperEffect(arg_19_0, arg_19_1)
	arg_19_0:addSuperBlockLayer()

	arg_19_0.tempParams = arg_19_1

	local var_19_0 = {}

	arg_19_0.sakuraWishesEffect1_:clearTracks()
	arg_19_0.sakuraWishesEffect2_:clearTracks()
	table.insert(var_19_0, cc.CallFunc:create(function()
		arg_19_0.sakuraWishesEffect1_:setVisible(true)
		arg_19_0.sakuraWishesEffect1_:play(function()
			arg_19_0.isAnimated = true

			local var_21_0 = arg_19_0.newCard:getChildByName("container"):getChildByName("cardFront"):getHeight()

			arg_19_0:playCardLight(var_21_0, 0.03, 14, {
				x = 360,
				y = -60
			}, {
				x = 350,
				y = -60
			}, {
				x = 360,
				y = 278
			}, 0.05)
		end, nil)
	end))
	table.insert(var_19_0, cc.DelayTime:create(3))
	table.insert(var_19_0, cc.CallFunc:create(function()
		arg_19_0.sakuraWishesEffect2_:play(function()
			arg_19_0:finishSuperEffect(arg_19_1)
		end, nil)
	end))
	arg_19_0:runAction(transition.sequence(var_19_0))
end

function var_0_0.finishSuperEffect(arg_24_0, arg_24_1)
	arg_24_0.isAnimated = false

	local var_24_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, arg_24_1)

	cc.EventProxy.new(var_24_0, var_24_0):addEventListener(xyd.event.SUMMON_HERO_CLOSE, handler(arg_24_0, arg_24_0.summonHeroEvent))
	arg_24_0.sakuraWishesEffect1_:stop()
	arg_24_0.sakuraWishesEffect2_:stop()
	arg_24_0.sakuraWishesEffect1_:setVisible(false)
	arg_24_0.sakuraWishesEffect2_:setVisible(false)
	arg_24_0.newCard:setVisible(false)
	arg_24_0:removeSuperBlockLayer()
end

function var_0_0.removeSuperBlockLayer(arg_25_0)
	if arg_25_0.superBlockLayer_ then
		arg_25_0.superBlockLayer_:setVisible(false)

		arg_25_0.noSuperTouch = true
	end
end

function var_0_0.addSuperBlockLayer(arg_26_0)
	local function var_26_0(arg_27_0, arg_27_1)
		return true
	end

	local function var_26_1(arg_28_0, arg_28_1)
		if not arg_26_0.noSuperTouch then
			arg_26_0:stopSuperEffect()
		end

		return true
	end

	if not arg_26_0.superBlockLayer_ then
		local var_26_2 = cc.c4b(0, 0, 0, 0)

		arg_26_0.superBlockLayer_ = display.newColorLayer(var_26_2)

		local var_26_3 = arg_26_0:convertToWorldSpace(cc.p(0, 0))

		arg_26_0.superBlockLayer_:pos(-var_26_3.x, -var_26_3.y):addTo(arg_26_0, 50)
		arg_26_0.superBlockLayer_:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)

		arg_26_0.superLayerListener = cc.EventListenerTouchOneByOne:create()

		arg_26_0.superLayerListener:setSwallowTouches(false)
		arg_26_0.superLayerListener:registerScriptHandler(var_26_0, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_26_0.superLayerListener:registerScriptHandler(var_26_1, cc.Handler.EVENT_TOUCH_ENDED)
		arg_26_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_26_0.superLayerListener, arg_26_0.superBlockLayer_)

		arg_26_0.noSuperTouch = false
	else
		arg_26_0.noSuperTouch = false

		arg_26_0.superBlockLayer_:setVisible(true)
	end
end

function var_0_0.stopSuperEffect(arg_29_0)
	arg_29_0.sakuraWishesEffect1_:stop()
	arg_29_0.sakuraWishesEffect1_:setVisible(false)
	arg_29_0.sakuraWishesEffect2_:stop()
	arg_29_0.sakuraWishesEffect2_:setVisible(false)
	arg_29_0:stopAllActions()
	arg_29_0:removeSuperBlockLayer()
	arg_29_0:finishSuperEffect(arg_29_0.tempParams)
end

function var_0_0.showAnimation(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0
	local var_30_1
	local var_30_2 = arg_30_1 or 0

	if not arg_30_0.sakuraWishesEffect1_ then
		local var_30_3 = "skeletons/ui_effect/sakura_wishes/kapai1new"
		local var_30_4 = var_30_3 .. ".json"
		local var_30_5 = var_30_3 .. ".atlas"

		arg_30_0.sakuraWishesEffect1_ = var_0_5.new(var_30_4, var_30_5, 1)

		arg_30_0.sakuraWishesEffect1_:pos(390, 280)
		arg_30_0.sakuraWishesEffect1_:setAnchorPoint(cc.p(0.5, 0.5))
		arg_30_0.sakuraWishesEffect1_:addTo(arg_30_0:nodeByName("main"), 100)
		arg_30_0.sakuraWishesEffect1_:setVisible(false)
	end

	if not arg_30_0.sakuraWishesEffect2_ then
		local var_30_6 = "skeletons/ui_effect/sakura_wishes/chest_us_kapa"
		local var_30_7 = var_30_6 .. ".json"
		local var_30_8 = var_30_6 .. ".atlas"

		arg_30_0.sakuraWishesEffect2_ = var_0_5.new(var_30_7, var_30_8, 1)

		arg_30_0.sakuraWishesEffect2_:pos(390, 280)
		arg_30_0.sakuraWishesEffect2_:setAnchorPoint(cc.p(0.5, 0.5))
		arg_30_0.sakuraWishesEffect2_:addTo(arg_30_0:nodeByName("main"), 101)
		arg_30_0.sakuraWishesEffect2_:setVisible(false)
	end

	arg_30_0.sakuraWishesEffect2_:setVisible(false)

	if arg_30_0.position[var_30_2] then
		if var_30_2 == 0 then
			var_30_1 = arg_30_0.items_[1]
		else
			var_30_1 = arg_30_0.items_[var_30_2]
		end

		if var_30_1.is_partner then
			arg_30_0.newCard = arg_30_0:getCard(var_30_1.table_id)
		elseif var_30_1.to_stone then
			arg_30_0.newCard = arg_30_0:getCard(xyd.tables.item:heroID(var_30_1.table_id))
		end

		if var_30_1.is_partner and not arg_30_2 then
			local var_30_9 = {
				toStone = false,
				item_index = var_30_2,
				partnerID = var_30_1.table_id
			}

			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_END then
				var_30_9.isStillGuide = true
			end

			arg_30_0:playSuperEffect(var_30_9)

			return
		elseif var_30_1.to_stone and not arg_30_2 then
			local var_30_10 = {
				item_index = var_30_2,
				partnerID = xyd.tables.item:heroID(var_30_1.table_id),
				toStone = tonumber(var_30_1.item_num)
			}

			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_END then
				var_30_10.isStillGuide = true
			end

			arg_30_0:playSuperEffect(var_30_10)

			return
		elseif var_30_1.is_pet and not arg_30_2 then
			local var_30_11 = {
				item_index = var_30_2,
				partnerID = xyd.tables.item:heroID(var_30_1.table_id),
				toStone = tonumber(var_30_1.item_num),
				isPet = var_30_1.is_pet
			}

			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_END then
				var_30_11.isStillGuide = true
			end

			local var_30_12 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_30_11)

			cc.EventProxy.new(var_30_12, var_30_12):addEventListener(xyd.event.SUMMON_HERO_CLOSE, handler(arg_30_0, arg_30_0.summonHeroEvent))

			return
		end

		local var_30_13 = arg_30_0:getSummonItem(var_30_2)

		var_30_13:setVisible(true)

		if arg_30_0.summonType == xyd.SummonType.Stone then
			transition.scaleTo(var_30_13, {
				scale = 1,
				time = var_0_3.stoneSummonDuration,
				onComplete = function()
					if var_30_2 == #arg_30_0.items_ then
						arg_30_0.isAnimated = false

						arg_30_0:getBottomContainer():setVisible(true)
						arg_30_0:checkShowExtraReward()

						return
					end

					var_30_2 = var_30_2 + 1

					arg_30_0:showAnimation(var_30_2)
				end
			})

			local var_30_14 = xyd.tables.sound:getSound("draw_item_sound")

			audio.playSound(var_30_14)

			local var_30_15 = arg_30_0:getItemEffect()

			var_30_15:addTo(arg_30_0:nodeByName("main"))
			var_30_15:pos(arg_30_0:nodeByName("node_pos" .. var_30_2):getPosition())
			var_30_15:play(function()
				var_30_15:setVisible(false)
			end)
			var_30_15:setScale(0)
			transition.scaleTo(var_30_15, {
				scale = 1,
				time = var_0_3.stoneSummonDuration
			})
		else
			local var_30_16 = var_0_3.summonTenDuration

			if #arg_30_0.items_ == 1 then
				var_30_16 = var_0_3.summonDuration
			else
				local var_30_17 = xyd.tables.sound:getSound("draw_item_ten")

				audio.playSound(var_30_17)
			end

			local var_30_18 = cc.Spawn:create(cc.MoveTo:create(var_30_16, cc.p(arg_30_0.position[var_30_2].x, arg_30_0.position[var_30_2].y)), cc.ScaleTo:create(var_30_16, 1), cc.RotateBy:create(var_30_16, 360))

			transition.execute(var_30_13, var_30_18, {
				delay = var_0_3.summonDelay,
				onComplete = function()
					if #arg_30_0.items_ == 1 then
						arg_30_0.isAnimated = false

						arg_30_0:getBottomContainer():setVisible(true)
						arg_30_0:playGuide()
						arg_30_0:checkShowExtraReward()

						return
					elseif var_30_2 == #arg_30_0.items_ then
						arg_30_0.isAnimated = false

						arg_30_0:getBottomContainer():setVisible(true)
						arg_30_0:playGuide()
						arg_30_0:checkShowExtraReward()

						return
					end

					var_30_2 = var_30_2 + 1

					arg_30_0:showAnimation(var_30_2)
				end
			})
		end
	elseif var_30_2 < #arg_30_0.items_ then
		var_30_2 = var_30_2 + 1

		arg_30_0:showAnimation(var_30_2)
	end
end

function var_0_0.summonHeroEvent(arg_34_0, arg_34_1)
	if not arg_34_1.item_index then
		return
	end

	if not tolua.isnull(arg_34_0) then
		arg_34_0:showAnimation(arg_34_1.item_index, true)
	end
end

return var_0_0
