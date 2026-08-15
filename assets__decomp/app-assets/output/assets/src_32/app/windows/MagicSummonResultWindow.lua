local var_0_0 = class("MagicSummonResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.WindowName.summonWnd
local var_0_2 = xyd.WindowName.summonResultWnd
local var_0_3 = import("app.common.ui.TipsLayer")
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.model.Item")
local var_0_6 = xyd.tables.misc
local var_0_7 = import("app.common.ui.SpineEffect")
local var_0_8 = xyd.tables.translation
local var_0_9 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.items_ = arg_1_2.items or {}
	arg_1_0.listItems_ = arg_1_2.items or {}
	arg_1_0.heros = {}
	arg_1_0.times = arg_1_2.times
	arg_1_0.summonParams = arg_1_2.summonParams
	arg_1_0.stickItems = arg_1_2.stick_items
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 220), true)
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 20 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.setItem(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = "images/avatars/" .. arg_5_1 .. ".png"
	local var_5_1 = arg_5_3
	local var_5_2
	local var_5_3 = xyd.AssetLoader.get():loadSprite(var_5_0)
	local var_5_4 = arg_5_2:getContentSize()

	var_5_3 = var_5_3 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	local var_5_5 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_5_6 = cc.ClippingNode:create()

	var_5_6:setStencil(var_5_5)
	var_5_6:setInverted(false)
	var_5_6:setAlphaThreshold(0)
	var_5_6:addChild(var_5_3)
	var_5_3:align(display.CENTER, var_5_4.width / 2, var_5_4.height / 2)
	var_5_3:scale(var_5_4.width / var_5_3:getWidth())
	var_5_5:addTo(arg_5_2, -1)
	var_5_5:align(display.CENTER, var_5_4.width / 2, var_5_4.height / 2)
	var_5_5:scale((var_5_4.width - 3) / var_5_5:getWidth())
	arg_5_2:addChild(var_5_6)

	if var_5_1 < 0 then
		local var_5_7 = xyd.getAvatarBorder(xyd.EquipQuality.ORANGE)
		local var_5_8 = clone(var_5_7:getContentSize())

		xyd.displaySpriteOnContainer(var_5_7, arg_5_2, true)
		var_5_7:setName("border")

		if var_5_1 == -1 then
			local var_5_9 = xyd.getAvatarBorder(0)

			xyd.displaySpriteOnContainer(var_5_9, arg_5_2, true)
			var_5_9:scale(var_5_4.width / var_5_9:getWidth() + 0.04)
		end
	else
		local var_5_10 = xyd.getAvatarBorder(var_5_1)
		local var_5_11 = clone(var_5_10:getContentSize())

		xyd.displaySpriteOnContainer(var_5_10, arg_5_2, true)
		var_5_10:setName("border")
	end
end

function var_0_0.sourceDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return math.ceil(#arg_6_0.listItems_ / 5)
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		return arg_6_0:updateListView(arg_6_2, arg_6_3)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_6_2 then
		-- block empty
	end
end

function var_0_0.updateListView(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0
	local var_7_1 = arg_7_0.listView_:dequeueItem()

	if not var_7_1 then
		var_7_1 = arg_7_0.listView_:newItem()
	else
		var_7_1:removeAllChildren(true)
	end

	local var_7_2 = arg_7_0:nodeByName("list"):getWidth()
	local var_7_3 = 160

	var_7_1:setItemSize(var_7_2, var_7_3)

	local var_7_4 = display.newNode()

	var_7_4:setContentSize(var_7_2, var_7_3)

	local var_7_5 = arg_7_0.listItems_
	local var_7_6 = arg_7_2
	local var_7_7 = 0

	for iter_7_0 = 4, 0, -1 do
		local var_7_8 = var_7_6 * 5 - iter_7_0

		if var_7_8 <= #var_7_5 and var_7_8 > 0 then
			local var_7_9 = 1
			local var_7_10 = display.newNode()

			var_7_10:setContentSize(120, 120)
			var_7_10:setLocalZOrder(100)

			if arg_7_0.items_[var_7_8].is_partner then
				arg_7_0:updateHeroIcon(var_7_8, arg_7_0.items_[var_7_8], var_7_10)
				arg_7_0:addTips(var_7_10, arg_7_0.items_[var_7_8].table_id)
			else
				arg_7_0:updateItemIcon(var_7_8, arg_7_0.items_[var_7_8], var_7_10)
				arg_7_0:addTips(var_7_10, arg_7_0.items_[var_7_8].table_id)
			end

			var_7_10:setTouchEnabled(true)
			var_7_10:setTouchSwallowEnabled(false)
			var_7_10:setAnchorPoint(cc.p(0.5, 0.5))

			local var_7_11 = xyd.tables.avatar.icon_[var_7_5[var_7_8]]

			var_7_4:addChild(var_7_10)
			var_7_10:setPosition(var_7_7 * 140 + 70, 100)

			var_7_7 = var_7_7 + 1

			if not arg_7_0.items_[var_7_8].isPlayed and var_7_8 <= 15 then
				arg_7_0:playItemEffect(var_7_10, arg_7_2, iter_7_0)

				arg_7_0.items_[var_7_8].isPlayed = true
			end
		end
	end

	var_7_1:addContent(var_7_4)

	return var_7_1
end

function var_0_0.playItemEffect(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = arg_8_2 * 5 - arg_8_3
	local var_8_1 = xyd.tables.sound:getSound("draw_item_sound")

	audio.playSound(var_8_1)

	local var_8_2 = var_0_6.summonTenDuration
	local var_8_3 = cc.p(arg_8_1:getPosition())

	arg_8_1:setVisible(false)
	arg_8_1:setPosition(cc.p(350, 120 * (arg_8_2 + 1)))

	local var_8_4 = cc.Spawn:create(cc.CallFunc:create(function()
		arg_8_1:setVisible(true)
	end), cc.MoveTo:create(var_8_2, var_8_3), cc.ScaleTo:create(var_8_2, 1), cc.RotateBy:create(var_8_2, 360))
	local var_8_5 = var_8_0

	if var_8_5 > 10 then
		var_8_5 = 11
		var_8_4 = cc.Spawn:create(cc.CallFunc:create(function()
			arg_8_1:setVisible(true)
			arg_8_1:setPosition(var_8_3)
		end))
	end

	transition.execute(arg_8_1, var_8_4, {
		delay = var_8_5 * var_8_2,
		onComplete = function()
			if var_8_0 == #arg_8_0.items_ or var_8_0 > 10 then
				arg_8_0:nodeByName("bottom_container"):setVisible(true)
				arg_8_0.listView_.touchNode_:setTouchEnabled(true)
				arg_8_0:checkShowExtraReward()
			end
		end
	})
end

function var_0_0.layout(arg_12_0)
	arg_12_0.listView_ = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_12_0:nodeByName("list"):getWidth(), arg_12_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_12_0:nodeByName("list")):onScroll(handler(arg_12_0, arg_12_0.scrollListener))

	arg_12_0.listView_:setDelegate(handler(arg_12_0, arg_12_0.sourceDelegate))
	arg_12_0.listView_:setBounceable(true)
	arg_12_0:nodeByName("bottom_container"):setVisible(false)
	arg_12_0.listView_.touchNode_:setTouchEnabled(false)
	arg_12_0.listView_:reload()
	arg_12_0:nodeByName("title"):setString(var_0_8:translation("SUMMON_RESULT_TITTLE33"))

	if arg_12_0.times > 1 then
		arg_12_0:getPriceText():setString(xyd.tables.summon:crystalTen(xyd.SummonType.Magic))
	else
		arg_12_0:getPriceText():setString(xyd.tables.summon:crystal(xyd.SummonType.Magic))
	end

	arg_12_0:getAgainBtn()
	arg_12_0:nodeByName("skip"):setVisible(false)
	arg_12_0:nodeByName("price_hundred"):setVisible(false)
	arg_12_0:nodeByName("button_hundred"):setVisible(false)
	arg_12_0:nodeByName("price"):getChildByName("gold"):setVisible(false)
	arg_12_0:nodeByName("price"):getChildByName("free1"):setVisible(false)
	arg_12_0:nodeByName("price"):getChildByName("free10"):setVisible(false)
	arg_12_0:nodeByName("button_again"):getChildByName("discount"):setVisible(false)
	arg_12_0:nodeByName("button_again"):getChildByName("3"):setVisible(false)
	arg_12_0:nodeByName("button_again"):getChildByName("5"):setVisible(false)
	arg_12_0:nodeByName("return"):getChildByName("txt"):setString(var_0_9:translation("SUMMON_EXIT"))
	xyd.nodeEventSample(arg_12_0:nodeByName("return"), nil, function()
		arg_12_0:close()
	end)
end

function var_0_0.updateItemIcon(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = var_0_5.new()
	local var_14_1 = {
		item_id = arg_14_1,
		table_id = arg_14_2.table_id
	}

	var_14_0:populate(var_14_1)

	local var_14_2

	if arg_14_3 then
		var_14_2 = arg_14_3
	else
		var_14_2 = arg_14_0:getSummonItem(arg_14_1)
	end

	var_14_2:removeAllChildren()
	xyd.setItemBorder(var_14_2, arg_14_2.table_id, true)

	if not arg_14_3 then
		local var_14_3 = display.newNode()

		var_14_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_14_3:setPosition(var_14_2:getPosition())
		var_14_3:setContentSize(var_14_2:getContentSize())
		var_14_3:setLocalZOrder(100)
		var_14_3:addTo(arg_14_0:nodeByName("main"))
		table.insert(arg_14_0.tmpNode, var_14_3)

		if arg_14_0.summonType == xyd.SummonType.Stone then
			local var_14_4 = #arg_14_0.tmpNode
			local var_14_5 = arg_14_0:nodeByName("node_pos" .. var_14_4)

			var_14_3:pos(var_14_5:getPosition())
		end

		arg_14_0:addTips(var_14_3, var_14_1.table_id)
	end

	local var_14_6 = {
		size = 22,
		y = -30,
		text = var_14_0:getName(),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_14_2:getContentSize().width / 2
	}
	local var_14_7 = xyd.AssetLoader.get():loadLabel(var_14_6)

	var_14_7:addTo(var_14_2)
	var_14_7:setAnchorPoint(0.5, 0)

	if not arg_14_3 then
		var_14_2:setVisible(false)
	end

	local var_14_8 = {
		size = 22,
		y = 5,
		text = tonumber(arg_14_2.item_num),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_14_2:getContentSize().width - 10
	}

	if arg_14_2.item_num > 1 then
		local var_14_9 = xyd.AssetLoader.get():loadLabel(var_14_8)

		var_14_9:addTo(var_14_2)
		var_14_9:setAnchorPoint(1, 0)
		var_14_9:enableOutline(cc.c4b(0, 0, 0, 255), 2)
	end
end

function var_0_0.addTips(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = {
		id = arg_15_2
	}

	xyd.addTips(arg_15_1, var_15_0)
end

function var_0_0.updateHeroIcon(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	local var_16_0 = clone(arg_16_0.selfPlayer.heros_)
	local var_16_1

	for iter_16_0, iter_16_1 in pairs(var_16_0) do
		if tonumber(arg_16_2.table_id) == iter_16_1:getTableID() then
			var_16_1 = iter_16_1

			table.insert(arg_16_0.heros, var_16_1)

			break
		end
	end

	local var_16_2

	if arg_16_3 then
		var_16_2 = arg_16_3
	else
		var_16_2 = arg_16_0:getSummonItem(arg_16_1)
	end

	var_16_2:removeAllChildren()
	xyd.setAvatarBorder(var_16_1, var_16_2, true)

	if not arg_16_3 then
		local var_16_3 = display.newNode()

		var_16_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_16_3:setPosition(var_16_2:getPosition())
		var_16_3:setContentSize(var_16_2:getContentSize())
		var_16_3:setLocalZOrder(100)
		var_16_3:addTo(arg_16_0:nodeByName("main"))
		table.insert(arg_16_0.tmpNode, var_16_3)

		if arg_16_0.summonType == xyd.SummonType.Stone then
			local var_16_4 = #arg_16_0.tmpNode
			local var_16_5 = arg_16_0:nodeByName("node_pos" .. var_16_4)

			var_16_3:pos(var_16_5:getPosition())
		end

		arg_16_0:addTips(var_16_3, arg_16_2.table_id)
	end

	local var_16_6 = {
		size = 22,
		y = -30,
		text = var_16_1:getName(),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_16_2:getContentSize().width / 2
	}
	local var_16_7 = xyd.AssetLoader.get():loadLabel(var_16_6)

	var_16_7:addTo(var_16_2)
	var_16_7:setAnchorPoint(0.5, 0)

	if not arg_16_3 then
		var_16_2:setVisible(false)
	end
end

function var_0_0.getItemEffect(arg_17_0)
	local var_17_0 = "skeletons/ui_effect/common_effect_bag2/common_effect_bag2"
	local var_17_1 = var_17_0 .. ".json"
	local var_17_2 = var_17_0 .. ".atlas"

	return (var_0_7.new(var_17_1, var_17_2, 1))
end

function var_0_0.getAgainBtn(arg_18_0)
	arg_18_0.againBtn_ = arg_18_0:nodeByName("button_again")

	if arg_18_0.times == 1 then
		arg_18_0.againBtn_:getChildByName("txt"):setString(var_0_9:translation("SUMMON_BUY_AGAIN1"))
	else
		arg_18_0.againBtn_:getChildByName("txt"):setString(var_0_9:translation("SUMMON_BUY_AGAIN10"))
	end

	xyd.nodeEventSample(arg_18_0.againBtn_, nil, function()
		xyd.playButtonSound()
		arg_18_0:summonAgain()
	end)
end

function var_0_0.summonAgain(arg_20_0)
	local var_20_0 = xyd.tables.summon:crystal(xyd.SummonType.Magic)

	if arg_20_0.times > 1 then
		var_20_0 = xyd.tables.summon:crystalTen(xyd.SummonType.Magic)
	end

	if var_20_0 > arg_20_0.selfPlayer.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_9:translation("ZUANSHI_ABSENCE"), function()
			local var_21_0 = {}

			var_21_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_21_0)
		end, nil, nil, arg_20_0.colorMode)

		return
	end

	arg_20_0.selfPlayer:magicSummonHero(arg_20_0.summonParams, handler(arg_20_0, arg_20_0.summonCallback))

	arg_20_0.isAnimated = true
end

function var_0_0.summonCallback(arg_22_0, arg_22_1, arg_22_2)
	if arg_22_1 ~= xyd.error.OK then
		return
	end

	local var_22_0 = {}

	for iter_22_0, iter_22_1 in pairs(arg_22_2.result) do
		if tonumber(iter_22_0) then
			table.insert(var_22_0, iter_22_1)
		end
	end

	arg_22_0.items_ = var_22_0
	arg_22_0.listItems_ = arg_22_0.items_

	if arg_22_2.stick_items then
		arg_22_0.stickItems = arg_22_2.stick_items
	end

	arg_22_0:nodeByName("bottom_container"):setVisible(false)
	arg_22_0.listView_.touchNode_:setTouchEnabled(false)
	arg_22_0.listView_:reload()
end

function var_0_0.checkShowExtraReward(arg_23_0)
	if arg_23_0.stickItems then
		local var_23_0 = {}

		var_23_0.awards = var_23_0.awards or {}

		for iter_23_0, iter_23_1 in pairs(arg_23_0.stickItems) do
			local var_23_1 = tonumber(iter_23_1.item_id)
			local var_23_2 = tonumber(iter_23_1.item_num)
			local var_23_3 = {
				table_id = var_23_1,
				item_num = var_23_2
			}

			table.insert(var_23_0.awards, var_23_3)
		end

		if var_23_0 and var_23_0.awards and next(var_23_0.awards) then
			xyd.WindowManager.get():openWindow("alert_award", var_23_0)
		end
	end
end

function var_0_0.getPriceText(arg_24_0)
	return arg_24_0:nodeByName("price"):getChildByName("num")
end

return var_0_0
