local var_0_0 = class("ChocolateSlotMachineAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.model.Hero")
local var_0_4 = import("app.model.Item")
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.activityChocolateSlot

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.awards = arg_1_2.awards
	arg_1_0.times = arg_1_2.times
	arg_1_0.details = arg_1_2.details
	arg_1_0.double = {}
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.container = arg_3_0:nodeByName("container")
	arg_3_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list"):getWidth(), arg_3_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.listView_:setBounceable(true)
	arg_3_0.listView_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.listView_:reload()
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("close"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return arg_5_0.times
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0 = arg_5_0.listView_:dequeueItem()

		if not var_5_0 then
			var_5_0 = arg_5_0.listView_:newItem()
		else
			var_5_0:removeAllChildren(true)
		end

		local var_5_1 = arg_5_0:createListContent(arg_5_3)
		local var_5_2 = var_5_1:getWidth()
		local var_5_3 = var_5_1:getHeight()

		var_5_0:setItemSize(var_5_2, var_5_3)
		var_5_0:addContent(var_5_1)

		return var_5_0
	end
end

function var_0_0.createListContent(arg_6_0, arg_6_1)
	local var_6_0 = display.newNode()
	local var_6_1

	if arg_6_0.details[arg_6_1].is_raised == 1 then
		var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/chocolate/slot_machine/pop/award_item_double.csb")
	else
		var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/chocolate/slot_machine/pop/award_item.csb")
	end

	local var_6_2 = var_6_1:getChildByName("container")
	local var_6_3 = var_6_2:getChildByName("item_scroll")

	var_6_2:getChildByName("txt_normal"):setString(string.format(var_0_5:translation("ACTIVITY_CHOCOLATE_SLOT_TIP7"), arg_6_1))
	var_6_2:getChildByName("txt_special"):setString(string.format(var_0_5:translation("ACTIVITY_CHOCOLATE_SLOT_TIP7"), arg_6_1))
	var_6_2:getChildByName("txt2"):setString(var_0_5:translation("ACTIVITY_CHOCOLATE_SLOT_TIP4"))
	var_6_2:getChildByName("txt3"):setString(var_0_5:translation("ACTIVITY_CHOCOLATE_SLOT_TIP6"))

	if arg_6_0.details[arg_6_1].is_raised == 1 then
		var_6_2:getChildByName("txt4"):setString(var_0_5:translation("ACTIVITY_CHOCOLATE_SLOT_TIP5"))
		var_6_2:getChildByName("txt4"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end

	local var_6_4 = arg_6_0.details[arg_6_1].idx
	local var_6_5 = var_0_6:content(var_6_4)
	local var_6_6 = var_0_6:isRarest(var_6_4)

	var_6_2:getChildByName("txt_normal"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_6_2:getChildByName("txt_special"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_6_2:getChildByName("bg_normal"):setVisible(var_6_6 == 0)
	var_6_2:getChildByName("txt_normal"):setVisible(var_6_6 == 0)
	var_6_2:getChildByName("normal_di"):setVisible(var_6_6 == 0)
	var_6_2:getChildByName("normal_star1"):setVisible(var_6_6 == 0)
	var_6_2:getChildByName("normal_star2"):setVisible(var_6_6 == 0)
	var_6_2:getChildByName("bg_special"):setVisible(var_6_6 == 1)
	var_6_2:getChildByName("txt_special"):setVisible(var_6_6 == 1)
	var_6_2:getChildByName("special_di"):setVisible(var_6_6 == 1)
	var_6_2:getChildByName("special_star1"):setVisible(var_6_6 == 1)
	var_6_2:getChildByName("special_star2"):setVisible(var_6_6 == 1)

	for iter_6_0 = 1, 3 do
		var_6_2:getChildByName("apple" .. iter_6_0):setVisible(false)
		var_6_2:getChildByName("orange" .. iter_6_0):setVisible(false)
		var_6_2:getChildByName("mapple" .. iter_6_0):setVisible(false)
	end

	for iter_6_1 = 1, 3 do
		if var_6_5[iter_6_1] == 1 then
			var_6_2:getChildByName("apple" .. iter_6_1):setVisible(true)
		elseif var_6_5[iter_6_1] == 2 then
			var_6_2:getChildByName("orange" .. iter_6_1):setVisible(true)
		elseif var_6_5[iter_6_1] == 3 then
			var_6_2:getChildByName("mapple" .. iter_6_1):setVisible(true)
		end
	end

	local var_6_7 = 0
	local var_6_8 = #arg_6_0.awards[arg_6_1]

	for iter_6_2 = 1, var_6_8 do
		local var_6_9 = 1
		local var_6_10 = display.newNode()

		var_6_10:setContentSize(70, 70)
		var_6_10:setLocalZOrder(100)

		if arg_6_0.awards[arg_6_1][iter_6_2].is_partner then
			arg_6_0:updateHeroIcon(arg_6_1, arg_6_0.awards[arg_6_1][iter_6_2], var_6_10)
			arg_6_0:addTip(var_6_10, arg_6_0.awards[arg_6_1][iter_6_2].table_id, true)
		else
			arg_6_0:updateItemIcon(arg_6_1, arg_6_0.awards[arg_6_1][iter_6_2], var_6_10)
			arg_6_0:addTip(var_6_10, arg_6_0.awards[arg_6_1][iter_6_2].table_id)
		end

		var_6_10:setTouchEnabled(true)
		var_6_10:setTouchSwallowEnabled(false)
		var_6_10:setAnchorPoint(cc.p(0.5, 0.5))

		local var_6_11 = xyd.tables.avatar.icon_[arg_6_0.awards[arg_6_1][iter_6_2]]

		var_6_10:setPosition(var_6_7 * 70 + 45, 35)

		var_6_7 = var_6_7 + 1

		var_6_3:addChild(var_6_10)
	end

	if arg_6_0.details[arg_6_1].is_raised == 1 then
		local var_6_12 = 0
		local var_6_13 = #arg_6_0.awards[arg_6_1]

		for iter_6_3 = 1, var_6_13 do
			local var_6_14 = 1
			local var_6_15 = display.newNode()

			var_6_15:setContentSize(70, 70)
			var_6_15:setLocalZOrder(100)

			if arg_6_0.awards[arg_6_1][iter_6_3].is_partner then
				arg_6_0:updateHeroIcon(arg_6_1, arg_6_0.awards[arg_6_1][iter_6_3], var_6_15)
				arg_6_0:addTip(var_6_15, arg_6_0.awards[arg_6_1][iter_6_3].table_id, true)
			else
				arg_6_0:updateItemIcon(arg_6_1, arg_6_0.awards[arg_6_1][iter_6_3], var_6_15)
				arg_6_0:addTip(var_6_15, arg_6_0.awards[arg_6_1][iter_6_3].table_id)
			end

			var_6_15:setTouchEnabled(true)
			var_6_15:setTouchSwallowEnabled(false)
			var_6_15:setAnchorPoint(cc.p(0.5, 0.5))

			local var_6_16 = xyd.tables.avatar.icon_[arg_6_0.awards[arg_6_1][iter_6_3]]

			var_6_15:setPosition(var_6_12 * 70 + 45, 35)

			var_6_12 = var_6_12 + 1

			var_6_2:getChildByName("item_scroll2"):addChild(var_6_15)
		end
	end

	var_6_1:addTo(var_6_0)
	var_6_1:setAnchorPoint(cc.p(0, 0))
	var_6_0:setContentSize(var_6_2:getContentSize())
	var_6_1:setName("source")

	return var_6_0
end

function var_0_0.setItem(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = "images/avatars/" .. arg_7_1 .. ".png"
	local var_7_1 = arg_7_3
	local var_7_2
	local var_7_3 = xyd.AssetLoader.get():loadSprite(var_7_0)
	local var_7_4 = arg_7_2:getContentSize()

	var_7_3 = var_7_3 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	local var_7_5 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_7_6 = cc.ClippingNode:create()

	var_7_6:setStencil(var_7_5)
	var_7_6:setInverted(false)
	var_7_6:setAlphaThreshold(0)
	var_7_6:addChild(var_7_3)
	var_7_3:align(display.CENTER, var_7_4.width / 2, var_7_4.height / 2)
	var_7_3:scale(var_7_4.width / var_7_3:getWidth())
	var_7_5:addTo(arg_7_2, -1)
	var_7_5:align(display.CENTER, var_7_4.width / 2, var_7_4.height / 2)
	var_7_5:scale((var_7_4.width - 3) / var_7_5:getWidth())
	arg_7_2:addChild(var_7_6)

	if var_7_1 < 0 then
		local var_7_7 = xyd.getAvatarBorder(xyd.EquipQuality.ORANGE)
		local var_7_8 = clone(var_7_7:getContentSize())

		xyd.displaySpriteOnContainer(var_7_7, arg_7_2, true)
		var_7_7:setName("border")

		if var_7_1 == -1 then
			local var_7_9 = xyd.getAvatarBorder(0)

			xyd.displaySpriteOnContainer(var_7_9, arg_7_2, true)
			var_7_9:scale(var_7_4.width / var_7_9:getWidth() + 0.04)
		end
	else
		local var_7_10 = xyd.getAvatarBorder(var_7_1)
		local var_7_11 = clone(var_7_10:getContentSize())

		xyd.displaySpriteOnContainer(var_7_10, arg_7_2, true)
		var_7_10:setName("border")
	end
end

function var_0_0.updateItemIcon(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = var_0_4.new()
	local var_8_1 = {
		item_id = arg_8_1,
		table_id = arg_8_2.table_id
	}

	var_8_0:populate(var_8_1)

	local var_8_2

	if arg_8_3 then
		var_8_2 = arg_8_3
	else
		var_8_2 = arg_8_0:getSummonItem(arg_8_1)
	end

	var_8_2:removeAllChildren()
	xyd.setItemBorder(var_8_2, arg_8_2.table_id, false)

	local var_8_3 = false
	local var_8_4 = var_8_2:getContentSize()

	if var_8_3 then
		local var_8_5 = xyd.getItemEffect(5)

		if not var_8_5 then
			return
		end

		var_8_2:addChild(var_8_5)
		var_8_5:setLocalZOrder(-100)
		var_8_5:setPosition(var_8_4.width / 2, var_8_4.height / 2)
		var_8_5:play(nil, true)
	end

	if not arg_8_3 then
		local var_8_6 = display.newNode()

		var_8_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_6:setPosition(var_8_2:getPosition())
		var_8_6:setContentSize(var_8_2:getContentSize())
		var_8_6:setLocalZOrder(100)
		var_8_6:addTo(arg_8_0:nodeByName("main"))
		table.insert(arg_8_0.tmpNode, var_8_6)

		if arg_8_0.summonType == xyd.SummonType.Stone then
			local var_8_7 = #arg_8_0.tmpNode
			local var_8_8 = arg_8_0:nodeByName("node_pos" .. var_8_7)

			var_8_6:pos(var_8_8:getPosition())
		end

		arg_8_0:addTip(var_8_6, var_8_1.table_id)
	end

	if not arg_8_3 then
		var_8_2:setVisible(false)
	end

	if arg_8_2.item_num == nil then
		arg_8_2.item_num = 1
	end

	local var_8_9 = {
		size = 22,
		y = 5,
		text = tonumber(arg_8_2.item_num),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_8_2:getContentSize().width - 10
	}

	if arg_8_2.item_num > 1 then
		local var_8_10 = xyd.AssetLoader.get():loadLabel(var_8_9)

		var_8_10:addTo(var_8_2)
		var_8_10:setAnchorPoint(1, 0)
		var_8_10:enableOutline(cc.c4b(0, 0, 0, 255), 2)
	end
end

function var_0_0.updateHeroIcon(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = clone(arg_9_0.selfPlayer.heros_)
	local var_9_1
	local var_9_2

	if arg_9_3 then
		var_9_2 = arg_9_3
	else
		var_9_2 = arg_9_0:getSummonItem(arg_9_1)
	end

	var_9_2:removeAllChildren()
	xyd.setAvatarBorder(arg_9_2.table_id, var_9_2, false, 0)

	if not arg_9_3 then
		local var_9_3 = display.newNode()

		var_9_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_3:setPosition(var_9_2:getPosition())
		var_9_3:setContentSize(var_9_2:getContentSize())
		var_9_3:setLocalZOrder(100)
		var_9_3:addTo(arg_9_0:nodeByName("main"))
		table.insert(arg_9_0.tmpNode, var_9_3)

		if arg_9_0.summonType == xyd.SummonType.Stone then
			local var_9_4 = #arg_9_0.tmpNode
			local var_9_5 = arg_9_0:nodeByName("node_pos" .. var_9_4)

			var_9_3:pos(var_9_5:getPosition())
		end

		arg_9_0:addTip(var_9_3, arg_9_2.table_id, true)
	end

	if not arg_9_3 then
		var_9_2:setVisible(false)
	end
end

function var_0_0.addTip(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = {
		id = arg_10_2
	}

	if arg_10_3 then
		var_10_0.name = xyd.tables.hero:name(arg_10_2)
		var_10_0.desc = xyd.tables.hero:getDes(arg_10_2)
	else
		var_10_0.hasNum = arg_10_0.selfPlayer:getBackpack():getItemNumByID(arg_10_2)
	end

	arg_10_1:setTouchEnabled(true)
	arg_10_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			local var_11_0

			if not xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_11_1 = xyd.WindowManager.get():openWindow("new_item_tips", var_10_0)

				xyd.adaptToWorldPosition(arg_10_1, var_11_1)
			end

			return true
		elseif arg_11_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 20 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

return var_0_0
