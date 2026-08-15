local var_0_0 = class("SummonResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.WindowName.summonWnd
local var_0_2 = xyd.WindowName.summonResultWnd
local var_0_3 = import("app.common.ui.TipsLayer")
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.model.Item")
local var_0_6 = xyd.tables.misc
local var_0_7 = import("app.common.ui.SpineEffect")
local var_0_8 = xyd.tables.translation
local var_0_9 = 50001024
local var_0_10 = 50001039
local var_0_11 = 50001046
local var_0_12 = 50001047

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summonType = arg_1_2.lastType
	arg_1_0.items_ = arg_1_2.items or {}
	arg_1_0.listItems_ = {}
	arg_1_0.summonIndex = arg_1_2.summonIndex
	arg_1_0.extraReward = arg_1_2.extraReward or {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.heros = {}
	arg_1_0.extraAward = arg_1_2.extraAward
	arg_1_0.sakuraItems = arg_1_2.sakuraItems
	arg_1_0.stickItems = arg_1_2.stick_items
	arg_1_0.free = arg_1_2.free
	arg_1_0.isAnimated = true
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.listView_ = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list"):getWidth(), arg_2_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listView_:setDelegate(handler(arg_2_0, arg_2_0.sourceDelegate))
	arg_2_0.listView_:setBounceable(true)
	arg_2_0:nodeByName("list"):setVisible(false)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 180))

	if arg_3_0.extraAward and next(arg_3_0.extraAward) then
		local var_3_0 = {}

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.extraAward) do
			for iter_3_2 = 1, iter_3_1.item_num do
				local var_3_1 = var_0_5.new()

				var_3_1:populate({
					table_id = iter_3_1.item_id
				})
				table.insert(var_3_0, var_3_1)
			end

			arg_3_0.selfPlayer:getBackpack():addItemsByID(iter_3_1.item_id, iter_3_1.item_num)
		end

		local var_3_2 = var_0_8:translation("CHRISTMAS_SUMMON_AWARD_TEXT1")
		local var_3_3 = var_0_8:translation("CHRISTMAS_SUMMON_AWARD_TEXT2")
		local var_3_4 = var_0_8:translation("CHRISTMAS_SUMMON_AWARD_TEXT3")
		local var_3_5 = {
			var_3_2,
			var_3_3,
			var_3_4
		}
		local var_3_6 = xyd.WindowManager.get():openWindow("battle_award_items", {
			items = var_3_0,
			labels = var_3_5
		})

		cc.EventProxy.new(var_3_6, var_3_6):addEventListener(xyd.event.ALERT_AWARD_CLOSE, function()
			arg_3_0:showAnimation()
		end)
	else
		arg_3_0:showAnimation()
	end

	local var_3_7 = xyd.WindowManager.get():getWindow(xyd.WindowName.backpackWnd)

	if var_3_7 and var_3_7:isVisible() then
		arg_3_0.haveHide = true

		var_3_7:hide()
	end
end

function var_0_0.didClose(arg_5_0)
	arg_5_0.listView_:reload()

	local var_5_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.summonWnd)

	if var_5_0 then
		local var_5_1 = xyd.StoryData.get():getGuideID()

		var_5_0:setVisible(true)

		if var_5_1 == xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_ONE or var_5_1 == xyd.GuideStoryType.GUIDE_SUMMON_END then
			var_5_0:guideBack()
		end
	end
end

function var_0_0.willClose(arg_6_0)
	local var_6_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.backpackWnd)

	if var_6_0 and arg_6_0.haveHide then
		var_6_0:show()
	end
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

function var_0_0.setItem(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = "images/avatars/" .. arg_8_1 .. ".png"
	local var_8_1 = arg_8_3
	local var_8_2
	local var_8_3 = xyd.AssetLoader.get():loadSprite(var_8_0)
	local var_8_4 = arg_8_2:getContentSize()

	var_8_3 = var_8_3 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	local var_8_5 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_8_6 = cc.ClippingNode:create()

	var_8_6:setStencil(var_8_5)
	var_8_6:setInverted(false)
	var_8_6:setAlphaThreshold(0)
	var_8_6:addChild(var_8_3)
	var_8_3:align(display.CENTER, var_8_4.width / 2, var_8_4.height / 2)
	var_8_3:scale(var_8_4.width / var_8_3:getWidth())
	var_8_5:addTo(arg_8_2, -1)
	var_8_5:align(display.CENTER, var_8_4.width / 2, var_8_4.height / 2)
	var_8_5:scale((var_8_4.width - 3) / var_8_5:getWidth())
	arg_8_2:addChild(var_8_6)

	if var_8_1 < 0 then
		local var_8_7 = xyd.getAvatarBorder(xyd.EquipQuality.ORANGE)
		local var_8_8 = clone(var_8_7:getContentSize())

		xyd.displaySpriteOnContainer(var_8_7, arg_8_2, true)
		var_8_7:setName("border")

		if var_8_1 == -1 then
			local var_8_9 = xyd.getAvatarBorder(0)

			xyd.displaySpriteOnContainer(var_8_9, arg_8_2, true)
			var_8_9:scale(var_8_4.width / var_8_9:getWidth() + 0.04)
		end
	else
		local var_8_10 = xyd.getAvatarBorder(var_8_1)
		local var_8_11 = clone(var_8_10:getContentSize())

		xyd.displaySpriteOnContainer(var_8_10, arg_8_2, true)
		var_8_10:setName("border")
	end
end

function var_0_0.sourceDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return math.ceil(#arg_9_0.listItems_ / 5)
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		return arg_9_0:updateListView(arg_9_2, arg_9_3)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_9_2 then
		-- block empty
	end
end

function var_0_0.updateListView(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0
	local var_10_1 = arg_10_0.listView_:dequeueItem()

	if not var_10_1 then
		var_10_1 = arg_10_0.listView_:newItem()
	else
		var_10_1:removeAllChildren(true)
	end

	local var_10_2 = arg_10_0:nodeByName("list"):getWidth()
	local var_10_3 = 180

	var_10_1:setItemSize(var_10_2, var_10_3)

	local var_10_4 = display.newNode()

	var_10_4:setContentSize(var_10_2, var_10_3)

	local var_10_5 = arg_10_0.listItems_
	local var_10_6 = arg_10_2
	local var_10_7 = 0

	for iter_10_0 = 4, 0, -1 do
		local var_10_8 = var_10_6 * 5 - iter_10_0

		if var_10_8 <= #var_10_5 and var_10_8 > 0 then
			local var_10_9 = 1
			local var_10_10 = display.newNode()

			var_10_10:setContentSize(120, 120)
			var_10_10:setLocalZOrder(100)

			if arg_10_0.items_[var_10_8].is_partner then
				arg_10_0:updateHeroIcon(var_10_8, arg_10_0.items_[var_10_8], var_10_10)
				arg_10_0:addTips(var_10_10, arg_10_0.items_[var_10_8].table_id)
			else
				arg_10_0:updateItemIcon(var_10_8, arg_10_0.items_[var_10_8], var_10_10)
				arg_10_0:addTips(var_10_10, arg_10_0.items_[var_10_8].table_id)
			end

			var_10_10:setTouchEnabled(true)
			var_10_10:setTouchSwallowEnabled(false)
			var_10_10:setAnchorPoint(cc.p(0.5, 0.5))

			local var_10_11 = xyd.tables.avatar.icon_[var_10_5[var_10_8]]

			var_10_4:addChild(var_10_10)
			var_10_10:setPosition(var_10_7 * 140 + 70, 120)

			var_10_7 = var_10_7 + 1
		end
	end

	var_10_1:addContent(var_10_4)

	return var_10_1
end

function var_0_0.summonHeroEvent(arg_11_0, arg_11_1)
	if not arg_11_1.item_index then
		return
	end

	if arg_11_1.is_skip_animation then
		arg_11_0.isSkipAnimation = arg_11_1.is_skip_animation

		arg_11_0:setSkipBtnVisible()
	end

	if not tolua.isnull(arg_11_0) then
		arg_11_0:showAnimation(arg_11_1.item_index, true)
	end
end

function var_0_0.refresh(arg_12_0, arg_12_1, arg_12_2)
	for iter_12_0, iter_12_1 in ipairs(arg_12_0.tmpNode) do
		iter_12_1:removeSelf()
	end

	arg_12_0.tmpNode = {}

	if #arg_12_1 > 10 then
		local var_12_0 = transition.sequence({
			cc.ScaleTo:create(0.2, 1.1),
			cc.ScaleTo:create(0.2, 0)
		})

		arg_12_0.isAnimated = true

		arg_12_0:nodeByName("main"):runActionOnce(var_12_0, false, function()
			arg_12_0:nodeByName("main"):setScale(1)
			arg_12_0:nodeByName("list"):setVisible(true)

			arg_12_0.items_ = {}

			local var_13_0 = {}

			for iter_13_0, iter_13_1 in pairs(arg_12_1) do
				if var_13_0[iter_13_1.table_id] then
					var_13_0[iter_13_1.table_id].item_num = iter_13_1.item_num + var_13_0[iter_13_1.table_id].item_num
				else
					var_13_0[iter_13_1.table_id] = {}
					var_13_0[iter_13_1.table_id] = iter_13_1
				end
			end

			local var_13_1 = 1

			for iter_13_2, iter_13_3 in pairs(var_13_0) do
				arg_12_0.items_[var_13_1] = {}
				arg_12_0.items_[var_13_1] = iter_13_3
				var_13_1 = var_13_1 + 1
			end

			arg_12_0.listItems_ = arg_12_0.items_

			arg_12_0:setItems(true)

			arg_12_0.isAnimated = false
		end)
	else
		arg_12_0.scrollViewMoved_ = false

		arg_12_0:nodeByName("list"):setVisible(false)

		arg_12_0.listItems_ = {}
		arg_12_0.items_ = arg_12_1

		arg_12_0:setItems()
	end

	arg_12_0:setInitPosition()

	if #arg_12_1 <= 10 then
		local var_12_1 = transition.sequence({
			cc.ScaleTo:create(0.2, 1.1),
			cc.ScaleTo:create(0.2, 0)
		})

		arg_12_0:nodeByName("main"):runActionOnce(var_12_1, false, function()
			arg_12_0:nodeByName("main"):setScale(1)
			arg_12_0:getBottomContainer():setVisible(false)

			if arg_12_2.items and next(arg_12_2.items) then
				local var_14_0 = {}

				for iter_14_0, iter_14_1 in ipairs(arg_12_2.items) do
					for iter_14_2 = 1, iter_14_1.item_num do
						local var_14_1 = var_0_5.new()

						var_14_1:populate({
							table_id = iter_14_1.item_id
						})
						table.insert(var_14_0, var_14_1)
					end

					arg_12_0.selfPlayer:getBackpack():addItemsByID(iter_14_1.item_id, iter_14_1.item_num)
				end

				local var_14_2 = var_0_8:translation("CHRISTMAS_SUMMON_AWARD_TEXT1")
				local var_14_3 = var_0_8:translation("CHRISTMAS_SUMMON_AWARD_TEXT2")
				local var_14_4 = var_0_8:translation("CHRISTMAS_SUMMON_AWARD_TEXT3")
				local var_14_5 = {
					var_14_2,
					var_14_3,
					var_14_4
				}
				local var_14_6 = xyd.WindowManager.get():openWindow("battle_award_items", {
					items = var_14_0,
					labels = var_14_5
				})

				cc.EventProxy.new(var_14_6, var_14_6):addEventListener(xyd.event.ALERT_AWARD_CLOSE, function()
					arg_12_0:showAnimation()
				end)
			else
				arg_12_0:showAnimation()
			end
		end)
	else
		arg_12_0:checkShowExtraReward()
	end
end

function var_0_0.layout(arg_16_0)
	arg_16_0.tmpNode = {}

	arg_16_0:getBackAnimation()
	arg_16_0:getAgainBtn()
	arg_16_0:getSkipBtn()
	arg_16_0:getCloseBtn()
	arg_16_0:setItems()
	arg_16_0:recordPosition()
	arg_16_0:setInitPosition()
	arg_16_0:getDesText():setString(var_0_8:translation("SUMMON_RESULT_TITTLE" .. arg_16_0.summonType))

	local var_16_0, var_16_1, var_16_2, var_16_3 = arg_16_0:getPriceIcon()

	var_16_0:setVisible(arg_16_0.summonType == xyd.SummonType.Crystal or arg_16_0.summonType == xyd.SummonType.Stone or arg_16_0.summonType == xyd.SummonType.CrystalDiscountOne or arg_16_0.summonType == xyd.SummonType.CrystalDiscountTen)
	var_16_1:setVisible(arg_16_0.summonType == xyd.SummonType.Mana)
	var_16_2:setVisible(arg_16_0.summonType == xyd.SummonType.CouponType1)
	var_16_3:setVisible(arg_16_0.summonType == xyd.SummonType.CouponType2)
	arg_16_0:getBottomContainer():setVisible(false)
	arg_16_0:nodeByName("button_hundred"):setVisible(false)
	arg_16_0:nodeByName("price_hundred"):setVisible(false)
	arg_16_0:nodeByName("3"):setVisible(false)
	arg_16_0:nodeByName("5"):setVisible(false)
	arg_16_0:nodeByName("discount"):setVisible(false)
	arg_16_0:nodeByName("title"):enableOutline(cc.c4b(204, 115, 56, 255), 2)

	arg_16_0.threeDiscountNum = arg_16_0.selfPlayer:getBackpack():getItemNumByID(var_0_11)
	arg_16_0.fiveDiscountNum = arg_16_0.selfPlayer:getBackpack():getItemNumByID(var_0_12)

	if tonumber(arg_16_0.summonType) == xyd.SummonType.Mana then
		if #arg_16_0.items_ == 1 then
			arg_16_0:getPriceText():setString(xyd.tables.summon:mana(xyd.SummonType.Mana))
		else
			arg_16_0:getPriceText():setString(xyd.tables.summon:manaTen(xyd.SummonType.Mana))
			arg_16_0:nodeByName("num_h"):setString(xyd.tables.summon:manaHundred(xyd.SummonType.Mana))
			arg_16_0:nodeByName("button_hundred"):setVisible(true)
			arg_16_0:nodeByName("price_hundred"):setVisible(true)
			arg_16_0:nodeByName("price"):setPosition(408, 47)
			arg_16_0:nodeByName("button_again"):setPosition(665.5, 44.5)
			arg_16_0:nodeByName("return"):setPosition(865.5, 44.5)
			arg_16_0:nodeByName("button_hundred"):setTouchSwallowEnabled(true)
			xyd.nodeEventSample(arg_16_0:nodeByName("button_hundred"), nil, function(arg_17_0)
				xyd.playButtonSound()

				if not arg_16_0.isAnimated then
					local var_17_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

					if xyd.tables.summon:manaHundred(xyd.SummonType.Mana) > var_17_0.mana then
						xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_8:translation("JINBI_ABSENCE"), function()
							local var_18_0 = xyd.FunctionID.ID_GOLD_HAND

							if var_17_0:isFuncOpen(var_18_0) == true then
								xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
							else
								local var_18_1 = xyd.tables.functionOpen:level(var_18_0)
								local var_18_2 = string.format(var_0_8:translation("FUNCTION_OPEN_TIP_LEVEL"), var_18_1)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_18_2
								})
							end
						end, nil, nil, arg_16_0.colorMode)
					else
						arg_16_0:summonAgain(true)
					end
				end
			end)
		end
	elseif tonumber(arg_16_0.summonType) == xyd.SummonType.Crystal then
		if #arg_16_0.items_ == 1 then
			if arg_16_0.threeDiscountNum <= 0 then
				arg_16_0:nodeByName("3"):setVisible(false)
				arg_16_0:nodeByName("discount"):setVisible(false)
				arg_16_0:getPriceText():setString(xyd.tables.summon:crystal(xyd.SummonType.Crystal))
			else
				arg_16_0.summonType = xyd.SummonType.CrystalDiscountOne

				arg_16_0:nodeByName("3"):setVisible(true)
				arg_16_0:nodeByName("discount"):setVisible(true)
				arg_16_0:getPriceText():setString(xyd.tables.summon:crystal(xyd.SummonType.CrystalDiscountOne))
			end
		elseif arg_16_0.fiveDiscountNum <= 0 then
			arg_16_0:nodeByName("5"):setVisible(false)
			arg_16_0:nodeByName("discount"):setVisible(false)
			arg_16_0:getPriceText():setString(xyd.tables.summon:crystalTen(xyd.SummonType.Crystal))
		else
			arg_16_0.summonType = xyd.SummonType.CrystalDiscountTen

			arg_16_0:nodeByName("5"):setVisible(true)
			arg_16_0:nodeByName("discount"):setVisible(true)
			arg_16_0:getPriceText():setString(xyd.tables.summon:crystal(xyd.SummonType.CrystalDiscountTen))
		end
	elseif tonumber(arg_16_0.summonType) == xyd.SummonType.Stone then
		arg_16_0:getPriceText():setString(xyd.tables.summon:stone(xyd.SummonType.Stone))
	elseif tonumber(arg_16_0.summonType) == xyd.SummonType.CouponType1 or tonumber(arg_16_0.summonType) == xyd.SummonType.CouponType2 then
		arg_16_0:getPriceText():setString(1)
	elseif tonumber(arg_16_0.summonType) == xyd.SummonType.CrystalDiscountOne then
		if arg_16_0.threeDiscountNum <= 0 then
			arg_16_0:setCrystal1Btn()
		else
			arg_16_0:nodeByName("3"):setVisible(true)
			arg_16_0:nodeByName("discount"):setVisible(true)
			arg_16_0:getPriceText():setString(xyd.tables.summon:crystal(xyd.SummonType.CrystalDiscountOne))
		end
	elseif tonumber(arg_16_0.summonType) == xyd.SummonType.CrystalDiscountTen then
		if arg_16_0.fiveDiscountNum <= 0 then
			arg_16_0:setCrystal10Btn()
		else
			arg_16_0:nodeByName("5"):setVisible(true)
			arg_16_0:nodeByName("discount"):setVisible(true)
			arg_16_0:getPriceText():setString(xyd.tables.summon:crystal(xyd.SummonType.CrystalDiscountTen))
		end
	elseif tonumber(arg_16_0.summonType) == xyd.SummonType.Ufocatcher then
		arg_16_0:nodeByName("price"):setVisible(false)
		arg_16_0:nodeByName("button_again"):setVisible(false)
		arg_16_0:nodeByName("return"):setPosition(arg_16_0:nodeByName("button_again"):getPosition())
	end

	arg_16_0.blockLayer1 = display.newNode()

	arg_16_0.blockLayer1:setContentSize(1280, 168)
	arg_16_0.blockLayer1:setAnchorPoint(0, 0)
	arg_16_0.blockLayer1:addTo(arg_16_0:nodeByName("layer_pos"))
	arg_16_0.blockLayer1:setPosition(0, 0)
	arg_16_0.blockLayer1:setTouchEnabled(true)
	arg_16_0.blockLayer1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "ended" and not arg_16_0.isAnimated then
			local var_19_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_19_0, false)

			if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_END then
				if arg_16_0.items_[1].table_id == 10001002 then
					arg_16_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_LEAVE1)
				elseif arg_16_0.items_[1].table_id == 10001003 then
					arg_16_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_LEAVE2)
				end
			end

			xyd.WindowManager.get():closeWindow(arg_16_0)
		end

		return true
	end)

	arg_16_0.blockLayer2 = display.newNode()

	arg_16_0.blockLayer2:setContentSize(1280, 128)
	arg_16_0.blockLayer2:setAnchorPoint(0, 1)
	arg_16_0.blockLayer2:addTo(arg_16_0:nodeByName("layer_pos"))
	arg_16_0.blockLayer2:setPosition(0, 720)
	arg_16_0.blockLayer2:setTouchEnabled(true)
	arg_16_0.blockLayer2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "ended" and not arg_16_0.isAnimated then
			local var_20_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_20_0, false)

			if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_END then
				if arg_16_0.items_[1].table_id == 10001002 then
					arg_16_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_LEAVE1)
				elseif arg_16_0.items_[1].table_id == 10001003 then
					arg_16_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_LEAVE2)
				end
			end

			xyd.WindowManager.get():closeWindow(arg_16_0)
		end

		return true
	end)
	arg_16_0:nodeByName("return"):getChildByName("txt"):setString(var_0_8:translation("SUMMON_EXIT"))
	arg_16_0:nodeByName("button_hundred"):getChildByName("txt"):setString(var_0_8:translation("SUMMON_HUNDRED"))
end

function var_0_0.getSummonItem(arg_21_0, arg_21_1)
	return arg_21_0:nodeByName("item" .. arg_21_1)
end

function var_0_0.setItems(arg_22_0, arg_22_1)
	arg_22_0.listView_:reload()
	collectgarbage("collect")

	if arg_22_1 then
		for iter_22_0 = 0, 10 do
			arg_22_0:getSummonItem(iter_22_0):removeAllChildren()
		end
	elseif #arg_22_0.items_ == 1 then
		for iter_22_1 = 1, 10 do
			arg_22_0:getSummonItem(iter_22_1):setVisible(false)
		end

		if arg_22_0.items_[1].is_partner then
			arg_22_0:updateHeroIcon(0, arg_22_0.items_[1])
		else
			arg_22_0:updateItemIcon(0, arg_22_0.items_[1])
		end
	else
		arg_22_0:getSummonItem(0):setVisible(false)

		for iter_22_2, iter_22_3 in pairs(arg_22_0.items_) do
			if iter_22_3.is_partner then
				arg_22_0:updateHeroIcon(iter_22_2, iter_22_3)
			else
				arg_22_0:updateItemIcon(iter_22_2, iter_22_3)
			end
		end
	end

	arg_22_0:setSkipBtnVisible(true)
end

function var_0_0.updateItemIcon(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	local var_23_0 = var_0_5.new()
	local var_23_1 = {
		item_id = arg_23_1,
		table_id = arg_23_2.table_id
	}

	var_23_0:populate(var_23_1)

	local var_23_2

	if arg_23_3 then
		var_23_2 = arg_23_3
	else
		var_23_2 = arg_23_0:getSummonItem(arg_23_1)
	end

	var_23_2:removeAllChildren()
	xyd.setItemBorder(var_23_2, arg_23_2.table_id, true)

	if not arg_23_3 then
		local var_23_3 = display.newNode()

		var_23_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_23_3:setPosition(var_23_2:getPosition())
		var_23_3:setContentSize(var_23_2:getContentSize())
		var_23_3:setLocalZOrder(100)
		var_23_3:addTo(arg_23_0:nodeByName("main"))
		table.insert(arg_23_0.tmpNode, var_23_3)

		if arg_23_0.summonType == xyd.SummonType.Stone then
			local var_23_4 = #arg_23_0.tmpNode
			local var_23_5 = arg_23_0:nodeByName("node_pos" .. var_23_4)

			var_23_3:pos(var_23_5:getPosition())
		end

		arg_23_0:addTips(var_23_3, var_23_1.table_id)
	end

	local var_23_6 = {
		size = 22,
		y = -30,
		text = var_23_0:getName(),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_23_2:getContentSize().width / 2
	}
	local var_23_7 = xyd.AssetLoader.get():loadLabel(var_23_6)

	var_23_7:setScaleX(0.8)
	var_23_7:setScaleY(0.9)
	var_23_7:addTo(var_23_2)
	var_23_7:setAnchorPoint(0.5, 0)

	if not arg_23_3 then
		var_23_2:setVisible(false)
	end

	local var_23_8 = {
		size = 22,
		y = 5,
		text = tonumber(arg_23_2.item_num),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_23_2:getContentSize().width - 10
	}

	if arg_23_2.item_num > 1 then
		local var_23_9 = xyd.AssetLoader.get():loadLabel(var_23_8)

		var_23_9:addTo(var_23_2)
		var_23_9:setAnchorPoint(1, 0)
		var_23_9:enableOutline(cc.c4b(0, 0, 0, 255), 2)
	end
end

function var_0_0.addTips(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = {
		id = arg_24_2
	}

	xyd.addTips(arg_24_1, var_24_0)
end

function var_0_0.updateHeroIcon(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	local var_25_0 = clone(arg_25_0.selfPlayer.heros_)
	local var_25_1

	for iter_25_0, iter_25_1 in pairs(var_25_0) do
		if tonumber(arg_25_2.table_id) == iter_25_1:getTableID() then
			var_25_1 = iter_25_1

			table.insert(arg_25_0.heros, var_25_1)

			break
		end
	end

	local var_25_2

	if arg_25_3 then
		var_25_2 = arg_25_3
	else
		var_25_2 = arg_25_0:getSummonItem(arg_25_1)
	end

	var_25_2:removeAllChildren()
	xyd.setAvatarBorder(var_25_1, var_25_2, true)

	if not arg_25_3 then
		local var_25_3 = display.newNode()

		var_25_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_25_3:setPosition(var_25_2:getPosition())
		var_25_3:setContentSize(var_25_2:getContentSize())
		var_25_3:setLocalZOrder(100)
		var_25_3:addTo(arg_25_0:nodeByName("main"))
		table.insert(arg_25_0.tmpNode, var_25_3)

		if arg_25_0.summonType == xyd.SummonType.Stone then
			local var_25_4 = #arg_25_0.tmpNode
			local var_25_5 = arg_25_0:nodeByName("node_pos" .. var_25_4)

			var_25_3:pos(var_25_5:getPosition())
		end

		arg_25_0:addTips(var_25_3, arg_25_2.table_id)
	end

	local var_25_6 = {
		size = 22,
		y = -30,
		text = var_25_1:getName(),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_25_2:getContentSize().width / 2
	}
	local var_25_7 = xyd.AssetLoader.get():loadLabel(var_25_6)

	var_25_7:setScaleX(0.8)
	var_25_7:setScaleY(0.9)
	var_25_7:addTo(var_25_2)
	var_25_7:setAnchorPoint(0.5, 0)

	if not arg_25_3 then
		var_25_2:setVisible(false)
	end
end

function var_0_0.getBackAnimation(arg_26_0)
	return
end

function var_0_0.getItemEffect(arg_27_0)
	if arg_27_0.summonType ~= xyd.SummonType.Stone then
		return
	end

	local var_27_0 = "skeletons/ui_effect/common_effect_bag2/common_effect_bag2"
	local var_27_1 = var_27_0 .. ".json"
	local var_27_2 = var_27_0 .. ".atlas"

	return (var_0_7.new(var_27_1, var_27_2, 1))
end

function var_0_0.getAgainBtn(arg_28_0)
	if not arg_28_0.againBtn_ then
		arg_28_0.againBtn_ = arg_28_0:nodeByName("button_again")

		arg_28_0.againBtn_:setTouchSwallowEnabled(true)

		local var_28_0 = #arg_28_0.items_

		if #arg_28_0.items_ == 6 then
			var_28_0 = 1
		end

		if var_28_0 == 1 then
			arg_28_0.againBtn_:getChildByName("txt"):setString(var_0_8:translation("SUMMON_BUY_AGAIN1"))
		else
			arg_28_0.againBtn_:getChildByName("txt"):setString(var_0_8:translation("SUMMON_BUY_AGAIN10"))
		end

		xyd.nodeEventSample(arg_28_0.againBtn_, nil, function(arg_29_0)
			xyd.playButtonSound()

			if not arg_28_0.isAnimated then
				local var_29_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

				if tonumber(arg_28_0.summonType) == xyd.SummonType.Mana then
					local var_29_1 = 0

					if #arg_28_0.items_ == 1 then
						var_29_1 = xyd.tables.summon:mana(xyd.SummonType.Mana)
					else
						var_29_1 = xyd.tables.summon:manaTen(xyd.SummonType.Mana)
					end

					if var_29_1 > var_29_0.mana then
						xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_8:translation("JINBI_ABSENCE"), function()
							local var_30_0 = xyd.FunctionID.ID_GOLD_HAND

							if var_29_0:isFuncOpen(var_30_0) == true then
								xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
							else
								local var_30_1 = xyd.tables.functionOpen:level(var_30_0)
								local var_30_2 = string.format(var_0_8:translation("FUNCTION_OPEN_TIP_LEVEL"), var_30_1)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_30_2
								})
							end
						end, nil, nil, arg_28_0.colorMode)
					else
						arg_28_0:summonAgain()
					end
				elseif tonumber(arg_28_0.summonType) == xyd.SummonType.Crystal then
					local var_29_2 = 0

					if #arg_28_0.items_ == 1 then
						var_29_2 = xyd.tables.summon:crystal(xyd.SummonType.Crystal)
					else
						var_29_2 = xyd.tables.summon:crystalTen(xyd.SummonType.Crystal)
					end

					if var_29_2 > var_29_0.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_8:translation("ZUANSHI_ABSENCE"), function()
							local var_31_0 = {}

							var_31_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_31_0)
						end, nil, nil, arg_28_0.colorMode)
					else
						arg_28_0:summonAgain()
					end
				elseif tonumber(arg_28_0.summonType) == xyd.SummonType.Stone then
					if xyd.tables.summon:stone(xyd.SummonType.Stone) > var_29_0.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_8:translation("ZUANSHI_ABSENCE"), function()
							local var_32_0 = {}

							var_32_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_32_0)
						end, nil, nil, arg_28_0.colorMode)
					else
						arg_28_0:summonAgain()
					end
				elseif tonumber(arg_28_0.summonType) == xyd.SummonType.CouponType1 or tonumber(arg_28_0.summonType) == xyd.SummonType.CouponType2 then
					local var_29_3

					if tonumber(arg_28_0.summonType) == xyd.SummonType.CouponType1 then
						var_29_3 = arg_28_0.selfPlayer:getBackpack():getItemNumByID(var_0_9) > 0
					else
						var_29_3 = arg_28_0.selfPlayer:getBackpack():getItemNumByID(var_0_10) > 0
					end

					if not var_29_3 then
						local var_29_4 = var_0_8:translation("COUPON_ABSENCE")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_29_4
						})
					else
						arg_28_0:summonAgain()
					end
				elseif tonumber(arg_28_0.summonType) == xyd.SummonType.CrystalDiscountOne then
					crystal = xyd.tables.summon:crystal(xyd.SummonType.CrystalDiscountOne)

					if var_29_0.crystal < crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_8:translation("ZUANSHI_ABSENCE"), function()
							local var_33_0 = {}

							var_33_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_33_0)
						end, nil, nil, arg_28_0.colorMode)
					else
						arg_28_0:summonAgain()
					end
				elseif tonumber(arg_28_0.summonType) == xyd.SummonType.CrystalDiscountTen then
					crystal = xyd.tables.summon:crystal(xyd.SummonType.CrystalDiscountTen)

					if var_29_0.crystal < crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_8:translation("ZUANSHI_ABSENCE"), function()
							local var_34_0 = {}

							var_34_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_34_0)
						end, nil, nil, arg_28_0.colorMode)
					else
						arg_28_0:summonAgain()
					end
				end
			end
		end)
	end

	return arg_28_0.againBtn_
end

function var_0_0.getCloseBtn(arg_35_0)
	if not arg_35_0.closeBtn_ then
		arg_35_0.closeBtn_ = arg_35_0:nodeByName("return")
	end

	arg_35_0.closeBtn_:setTouchSwallowEnabled(true)
	xyd.nodeEventSample(arg_35_0.closeBtn_, nil, function(arg_36_0)
		local var_36_0 = xyd.tables.sound:getSound("ui_close_window")

		audio.playSound(var_36_0, false)

		if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_END then
			if arg_35_0.items_[1].table_id == 10001002 then
				arg_35_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_LEAVE1)
			elseif arg_35_0.items_[1].table_id == 10001003 then
				arg_35_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_LEAVE2)
			end
		end

		xyd.WindowManager.get():closeWindow(arg_35_0)
	end)

	return arg_35_0.closeBtn_
end

function var_0_0.getSkipBtn(arg_37_0)
	if not arg_37_0.skipBtn_ then
		arg_37_0.skipBtn_ = arg_37_0:nodeByName("skip")
	end

	arg_37_0.skipBtn_:setLocalZOrder(100)
	xyd.nodeEventSample(arg_37_0.skipBtn_, nil, function(arg_38_0)
		xyd.playButtonSound()

		arg_37_0.isSkipAnimation = true

		arg_37_0:setSkipBtnVisible(false)
	end)
	arg_37_0:setSkipBtnVisible(true)

	return arg_37_0.skipBtn_
end

function var_0_0.setSkipBtnVisible(arg_39_0, arg_39_1)
	if not arg_39_0 or not arg_39_0.skipBtn_ or tolua.isnull(arg_39_0.skipBtn_) then
		return
	end

	if not arg_39_0:isCanSkipType() or arg_39_0.isSkipAnimation then
		arg_39_0.skipBtn_:setVisible(false)

		return
	end

	arg_39_0.skipBtn_:setVisible(arg_39_1)
end

function var_0_0.isCanSkipType(arg_40_0)
	if #arg_40_0.items_ > 1 and #arg_40_0.items_ <= 10 then
		return true
	end
end

function var_0_0.recordPosition(arg_41_0)
	arg_41_0.position = {}

	if #arg_41_0.items_ == 1 then
		local var_41_0, var_41_1 = arg_41_0:getSummonItem(0):getPosition()

		arg_41_0.position[0] = {
			x = var_41_0,
			y = var_41_1
		}
	else
		for iter_41_0, iter_41_1 in pairs(arg_41_0.items_) do
			local var_41_2, var_41_3 = arg_41_0:getSummonItem(iter_41_0):getPosition()

			arg_41_0.position[iter_41_0] = {
				x = var_41_2,
				y = var_41_3
			}
		end
	end
end

function var_0_0.showAnimation(arg_42_0, arg_42_1, arg_42_2)
	local var_42_0
	local var_42_1
	local var_42_2 = arg_42_1 or 0

	if arg_42_0.position[var_42_2] then
		if var_42_2 == 0 then
			var_42_1 = arg_42_0.items_[1]
		else
			var_42_1 = arg_42_0.items_[var_42_2]
		end

		if var_42_1.is_partner and not arg_42_2 then
			local var_42_3 = {
				toStone = false,
				item_index = var_42_2,
				partnerID = var_42_1.table_id
			}

			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_END then
				var_42_3.isStillGuide = true
			end

			local var_42_4 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_42_3)

			cc.EventProxy.new(var_42_4, var_42_4):addEventListener(xyd.event.SUMMON_HERO_CLOSE, handler(arg_42_0, arg_42_0.summonHeroEvent))

			return
		elseif var_42_1.to_stone and not arg_42_2 and not arg_42_0.isSkipAnimation then
			local var_42_5 = {
				item_index = var_42_2,
				partnerID = xyd.tables.item:heroID(var_42_1.table_id),
				toStone = tonumber(var_42_1.item_num),
				can_skip = arg_42_0:isCanSkipType()
			}

			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_END then
				var_42_5.isStillGuide = true
			end

			local var_42_6 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_42_5)

			cc.EventProxy.new(var_42_6, var_42_6):addEventListener(xyd.event.SUMMON_HERO_CLOSE, handler(arg_42_0, arg_42_0.summonHeroEvent))

			return
		elseif var_42_1.is_pet and not arg_42_2 and not arg_42_0.isSkipAnimation then
			local var_42_7 = {
				item_index = var_42_2,
				partnerID = xyd.tables.item:heroID(var_42_1.table_id),
				toStone = tonumber(var_42_1.item_num),
				isPet = var_42_1.is_pet,
				can_skip = arg_42_0:isCanSkipType()
			}

			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_SUMMON_END then
				var_42_7.isStillGuide = true
			end

			local var_42_8 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_42_7)

			cc.EventProxy.new(var_42_8, var_42_8):addEventListener(xyd.event.SUMMON_HERO_CLOSE, handler(arg_42_0, arg_42_0.summonHeroEvent))

			return
		end

		local var_42_9 = arg_42_0:getSummonItem(var_42_2)

		var_42_9:setVisible(true)

		if arg_42_0.summonType == xyd.SummonType.Stone then
			local var_42_10 = var_0_6.stoneSummonDuration

			if arg_42_0.isSkipAnimation then
				var_42_10 = 0
			end

			transition.scaleTo(var_42_9, {
				scale = 1,
				time = var_42_10,
				onComplete = function()
					if var_42_2 == #arg_42_0.items_ then
						arg_42_0.isAnimated = false

						arg_42_0:getBottomContainer():setVisible(true)
						arg_42_0:setSkipBtnVisible(false)
						arg_42_0:checkShowExtraReward()

						return
					end

					var_42_2 = var_42_2 + 1

					arg_42_0:showAnimation(var_42_2)
				end
			})

			local var_42_11 = xyd.tables.sound:getSound("draw_item_sound")

			audio.playSound(var_42_11)

			local var_42_12 = arg_42_0:getItemEffect()

			var_42_12:addTo(arg_42_0:nodeByName("main"))
			var_42_12:pos(arg_42_0:nodeByName("node_pos" .. var_42_2):getPosition())
			var_42_12:play(function()
				var_42_12:setVisible(false)
			end)
			var_42_12:setScale(0)
			transition.scaleTo(var_42_12, {
				scale = 1,
				time = var_42_10
			})
		else
			local var_42_13 = var_0_6.summonTenDuration

			if arg_42_0.isSkipAnimation then
				var_42_13 = 0
			end

			if #arg_42_0.items_ == 1 then
				var_42_13 = var_0_6.summonDuration
			else
				local var_42_14 = xyd.tables.sound:getSound("draw_item_ten")

				audio.playSound(var_42_14)
			end

			local var_42_15 = cc.Spawn:create(cc.MoveTo:create(var_42_13, cc.p(arg_42_0.position[var_42_2].x, arg_42_0.position[var_42_2].y)), cc.ScaleTo:create(var_42_13, 1), cc.RotateBy:create(var_42_13, 360))

			transition.execute(var_42_9, var_42_15, {
				delay = delay,
				onComplete = function()
					if #arg_42_0.items_ == 1 or #arg_42_0.items_ == var_42_2 then
						arg_42_0.isAnimated = false

						arg_42_0:getBottomContainer():setVisible(true)
						arg_42_0:playGuide()
						arg_42_0:checkShowExtraReward()
						arg_42_0:setSkipBtnVisible(false)

						return
					end

					var_42_2 = var_42_2 + 1

					arg_42_0:showAnimation(var_42_2)
				end
			})
		end
	elseif var_42_2 < #arg_42_0.items_ then
		var_42_2 = var_42_2 + 1

		arg_42_0:showAnimation(var_42_2)
	end
end

function var_0_0.checkShowExtraReward(arg_46_0)
	arg_46_0.extraAwardItems = arg_46_0.sakuraItems or {}

	if arg_46_0.extraReward and next(arg_46_0.extraReward) and arg_46_0.extraReward.item_num > 0 then
		table.insert(arg_46_0.extraAwardItems, arg_46_0.extraReward)
	end

	if arg_46_0.extraAwardItems and next(arg_46_0.extraAwardItems) then
		local var_46_0 = {
			extraAwardItems = arg_46_0.extraAwardItems
		}

		xyd.WindowManager.get():openWindow("summon_extra_pet", var_46_0)
	end

	local var_46_1 = {}

	if arg_46_0.stickItems and next(arg_46_0.stickItems) then
		var_46_1.awards = var_46_1.awards or {}

		for iter_46_0 = 1, #arg_46_0.stickItems do
			local var_46_2 = {
				table_id = arg_46_0.stickItems[iter_46_0].item_id,
				item_num = arg_46_0.stickItems[iter_46_0].item_num
			}

			table.insert(var_46_1.awards, var_46_2)
		end
	end

	if var_46_1 and var_46_1.awards and next(var_46_1.awards) then
		xyd.WindowManager.get():openWindow("alert_award", var_46_1)
	end
end

function var_0_0.summonAgain(arg_47_0, arg_47_1)
	local var_47_0 = {
		summon_type = arg_47_0.summonType
	}

	if arg_47_1 then
		var_47_0.summon_index = xyd.SummonType.ManaHundred
	elseif var_47_0.summon_type == xyd.SummonType.Mana and #arg_47_0.items_ == 1 then
		var_47_0.summon_index = xyd.SummonType.ManaOne
	elseif var_47_0.summon_type == xyd.SummonType.Mana then
		var_47_0.summon_index = xyd.SummonType.ManaTen
	elseif var_47_0.summon_type == xyd.SummonType.Crystal and #arg_47_0.items_ == 1 then
		var_47_0.summon_index = xyd.SummonType.CrystalOne
	elseif var_47_0.summon_type == xyd.SummonType.Crystal then
		var_47_0.summon_index = xyd.SummonType.CrystalTen
	elseif var_47_0.summon_type == xyd.SummonType.Stone then
		if arg_47_0.summonIndex and arg_47_0.summonIndex > 0 then
			var_47_0.summon_index = arg_47_0.summonIndex
		else
			var_47_0.summon_index = xyd.SummonType.StoneOne
		end
	elseif var_47_0.summon_type == xyd.SummonType.CouponType1 or var_47_0.summon_type == xyd.SummonType.CouponType2 then
		var_47_0.summon_index = xyd.SummonType.CouponOne
	elseif var_47_0.summon_type == xyd.SummonType.CrystalDiscountOne or var_47_0.summon_type == xyd.SummonType.CrystalDiscountTen then
		var_47_0.summon_index = xyd.SummonType.CrystalDiscountIndex
	end

	collectgarbage("collect")
	arg_47_0.selfPlayer:summonHero(var_47_0, handler(arg_47_0, arg_47_0.summonCallback))

	arg_47_0.isAnimated = true

	if arg_47_1 then
		arg_47_0.isAnimated = false
	end
end

function var_0_0.summonCallback(arg_48_0, arg_48_1, arg_48_2)
	arg_48_0.isSkipAnimation = false

	if arg_48_1 ~= xyd.error.OK then
		return
	end

	local var_48_0 = {}

	for iter_48_0, iter_48_1 in pairs(arg_48_2.result) do
		if tonumber(iter_48_0) then
			table.insert(var_48_0, iter_48_1)
		end
	end

	if arg_48_0.summonType == xyd.SummonType.CrystalDiscountOne then
		arg_48_0.threeDiscountNum = arg_48_0.threeDiscountNum - 1

		arg_48_0.selfPlayer:getBackpack():removeItem({
			itemNum = 1,
			itemID = var_0_11
		})

		local var_48_1 = xyd.WindowManager.get():getWindow("backpack")

		if var_48_1 then
			var_48_1:refreshDisplayOption()
			var_48_1:updateItemDetail(var_48_1.itemID)
		end

		if arg_48_0.threeDiscountNum == 0 then
			arg_48_0:setCrystal1Btn()
		end
	elseif arg_48_0.summonType == xyd.SummonType.CrystalDiscountTen then
		arg_48_0.fiveDiscountNum = arg_48_0.fiveDiscountNum - 1

		arg_48_0.selfPlayer:getBackpack():removeItem({
			itemNum = 1,
			itemID = var_0_12
		})

		local var_48_2 = xyd.WindowManager.get():getWindow("backpack")

		if var_48_2 then
			var_48_2:refreshDisplayOption()
			var_48_2:updateItemDetail(var_48_2.itemID)
		end

		if arg_48_0.fiveDiscountNum == 0 then
			arg_48_0:setCrystal10Btn()
		end
	end

	if arg_48_0.summonType == xyd.SummonType.CouponType1 then
		arg_48_0.selfPlayer:getBackpack():removeItem({
			itemNum = 1,
			itemID = var_0_9
		})

		local var_48_3 = xyd.WindowManager.get():getWindow("backpack")

		if var_48_3 then
			var_48_3:refreshDisplayOption()
			var_48_3:updateItemDetail(var_48_3.itemID)
		end
	elseif arg_48_0.summonType == xyd.SummonType.CouponType2 then
		arg_48_0.selfPlayer:getBackpack():removeItem({
			itemNum = 1,
			itemID = var_0_10
		})

		local var_48_4 = xyd.WindowManager.get():getWindow("backpack")

		if var_48_4 then
			var_48_4:refreshDisplayOption()
			var_48_4:updateItemDetail(var_48_4.itemID)
		end
	end

	arg_48_0.extraReward = arg_48_2.extra_reward
	arg_48_0.sakuraItems = arg_48_2.sakura_items
	arg_48_0.stickItems = arg_48_2.stick_items

	arg_48_0:refresh(var_48_0, arg_48_2)
end

function var_0_0.getPriceIcon(arg_49_0)
	local var_49_0 = arg_49_0:nodeByName("crystal")
	local var_49_1 = arg_49_0:nodeByName("gold")
	local var_49_2 = arg_49_0:nodeByName("free1")
	local var_49_3 = arg_49_0:nodeByName("free10")

	return var_49_0, var_49_1, var_49_2, var_49_3
end

function var_0_0.getBottomContainer(arg_50_0)
	return arg_50_0:nodeByName("bottom_container")
end

function var_0_0.getPriceText(arg_51_0)
	return arg_51_0:nodeByName("num")
end

function var_0_0.getDesText(arg_52_0)
	return arg_52_0:nodeByName("title")
end

function var_0_0.setInitPosition(arg_53_0)
	if arg_53_0.summonType == xyd.SummonType.Stone then
		for iter_53_0 = 0, 10 do
			arg_53_0:getSummonItem(iter_53_0):setVisible(false)
		end

		for iter_53_1 = 1, #arg_53_0.items_ do
			local var_53_0 = arg_53_0:nodeByName("node_pos" .. iter_53_1)

			arg_53_0:getSummonItem(iter_53_1):setScale(0)
			arg_53_0:getSummonItem(iter_53_1):pos(var_53_0:getPosition())
		end

		return
	end

	local var_53_1, var_53_2 = arg_53_0:getDesText():getPosition()

	for iter_53_2 = 0, 10 do
		arg_53_0:getSummonItem(iter_53_2):setScale(0)
		arg_53_0:getSummonItem(iter_53_2):setPosition(cc.p(var_53_1, var_53_2))
		arg_53_0:getSummonItem(iter_53_2):setVisible(false)
	end
end

function var_0_0.playGuide(arg_54_0)
	local var_54_0 = xyd.StoryData.get():getGuideID()

	if var_54_0 < xyd.GuideStoryType.GUIDE_SUMMON_END then
		local var_54_1 = arg_54_0:nodeByName("return")
		local var_54_2, var_54_3 = var_54_1:getPosition()
		local var_54_4 = arg_54_0:convertToNodeSpace(var_54_1:getParent():convertToWorldSpace(cc.p(var_54_2, var_54_3)))
		local var_54_5 = var_54_1:getPositionX()
		local var_54_6 = var_54_1:getPositionY()

		xyd.WindowManager.get():openWindow("guide")

		local var_54_7 = xyd.WindowManager.get():getWindow("guide")
		local var_54_8 = var_54_7:convertToNodeSpace(var_54_1:getParent():convertToWorldSpace(cc.p(var_54_5, var_54_6)))

		var_54_7:addNode()
		var_54_7:setStencil(var_54_1:getContentSize().width, var_54_1:getContentSize().height, var_54_8.x, var_54_8.y, 3)
	end

	if var_54_0 < xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_TWO then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_ONE, true)
	else
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_END)
	end

	if var_54_0 < xyd.GuideStoryType.GUIDE_EQUIP_END then
		xyd.StoryData.get():persist()
	end
end

function var_0_0.setCrystal1Btn(arg_55_0)
	arg_55_0.summonType = xyd.SummonType.Crystal
	arg_55_0.againBtn_ = nil

	local var_55_0 = xyd.WindowManager.get():getWindow("summon")

	arg_55_0:nodeByName("3"):setVisible(false)
	arg_55_0:nodeByName("discount"):setVisible(false)
	arg_55_0:getPriceText():setString(xyd.tables.summon:crystal(xyd.SummonType.Crystal))

	if var_55_0 then
		var_55_0:setPrice()
	end

	arg_55_0:getAgainBtn()
end

function var_0_0.setCrystal10Btn(arg_56_0)
	arg_56_0.summonType = xyd.SummonType.Crystal
	arg_56_0.againBtn_ = nil

	local var_56_0 = xyd.WindowManager.get():getWindow("summon")

	arg_56_0:nodeByName("5"):setVisible(false)
	arg_56_0:nodeByName("discount"):setVisible(false)
	arg_56_0:getPriceText():setString(xyd.tables.summon:crystalTen(xyd.SummonType.Crystal))

	if var_56_0 then
		var_56_0:setPrice()
	end

	arg_56_0:getAgainBtn()
end

return var_0_0
