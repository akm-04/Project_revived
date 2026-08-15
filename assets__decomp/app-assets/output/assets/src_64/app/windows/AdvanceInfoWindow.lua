local var_0_0 = class("AdvanceInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = require("framework.scheduler")
local var_0_3 = class("ScrollView", cc.ui.UIScrollView)
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.attr
local var_0_7 = xyd.tables.hero
local var_0_8 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0.hero
	local var_4_1 = arg_4_0:nodeByName("list")

	arg_4_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 440, 512),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_1):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:reload()
	arg_4_0:updateEquipInfoContainer()
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" and 5 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateEquipInfoContainer(arg_6_0)
	local var_6_0 = arg_6_0.hero
	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/advance_item.csb")

	var_6_1:setName("node1")

	local var_6_2 = var_6_1:getChildByName("container"):getContentSize()

	var_6_1:setContentSize(var_6_2)

	if var_6_0:getColor() == xyd.selfPlayer.maxHeroColor - 1 then
		local var_6_3 = arg_6_0.list:newItem()
		local var_6_4 = display.newNode()

		arg_6_0:setEquipNode(var_6_0:getColor() + 1, var_6_1)
		var_6_1:addTo(var_6_4)
		var_6_1:setAnchorPoint(cc.p(0, 0))
		var_6_4:setContentSize(var_6_1:getContentSize())
		var_6_3:addContent(var_6_4)
		var_6_3:setItemSize(var_6_4:getWidth(), var_6_4:getHeight() + 5)
		arg_6_0.list:addItem(var_6_3)
	elseif var_6_0:getColor() < xyd.selfPlayer.maxHeroColor - 1 then
		local var_6_5 = arg_6_0.list:newItem()
		local var_6_6 = display.newNode()
		local var_6_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/advance_item.csb")

		var_6_7:size(var_6_1:getContentSize())
		var_6_7:setName("node2")
		arg_6_0:setEquipNode(var_6_0:getColor() + 1, var_6_1)
		var_6_1:addTo(var_6_6)
		var_6_1:setAnchorPoint(cc.p(0, 0))
		var_6_6:setContentSize(var_6_1:getContentSize())
		var_6_5:addContent(var_6_6)
		var_6_5:setItemSize(var_6_6:getWidth(), var_6_6:getHeight() + 5)
		arg_6_0.list:addItem(var_6_5)

		local var_6_8 = arg_6_0.list:newItem()
		local var_6_9 = display.newNode()

		arg_6_0:setEquipNode(var_6_0:getColor() + 2, var_6_7)
		var_6_7:addTo(var_6_9)
		var_6_7:setAnchorPoint(cc.p(0, 0))
		var_6_9:setContentSize(430, 285)
		var_6_8:addContent(var_6_9)
		var_6_8:setItemSize(var_6_9:getWidth(), var_6_9:getHeight() + 5)
		arg_6_0.list:addItem(var_6_8)
	end

	arg_6_0.list:reload()
end

function var_0_0.setEquipNode(arg_7_0, arg_7_1, arg_7_2)
	if tolua.isnull(arg_7_0) or tolua.isnull(arg_7_2) then
		return
	end

	local var_7_0 = arg_7_0.hero
	local var_7_1 = arg_7_2:getChildByName("container")
	local var_7_2 = xyd.AssetLoader:get():loadSprite("windows/hero/quality_" .. arg_7_1 .. ".png")

	var_7_2:addTo(var_7_1:getChildByName("color"))
	var_7_2:scale(0.75)

	for iter_7_0 = 1, xyd.MAX_ITEM_NUM do
		local var_7_3 = var_7_0:getEquipByIndexShow(iter_7_0, arg_7_1)

		if var_7_3:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_7_3:getTableID()) == 0 then
			local var_7_4 = var_7_1:getChildByName("icon" .. iter_7_0)

			var_7_4:removeAllChildren()

			local var_7_5 = display.newNode()

			var_7_5:size(var_7_4:getContentSize())
			var_7_4:addChild(var_7_5)
			xyd.setItemBorder(var_7_5, var_7_3:getTableID())
			var_7_5:setTouchEnabled(true)
			var_7_5:setTouchSwallowEnabled(false)

			if var_7_3:isInBackpack() or var_7_3:isHasMaterial() then
				local var_7_6 = xyd.AssetLoader:get():loadSprite("windows/hero/icon_green_point.png")

				var_7_6:setPosition(var_7_4:getContentSize().width / 14 * 13, var_7_4:getContentSize().height / 14 * 13)
				var_7_4:addChild(var_7_6)
			end

			var_7_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
				if arg_8_0.name == "ended" and not arg_7_0.scrollViewMoved_ then
					arg_7_0:showItemDetail(iter_7_0, arg_7_1, true)
				end

				return true
			end)
		else
			local var_7_7 = var_7_1:getChildByName("icon" .. iter_7_0)

			if var_7_1:getChildByName("awake_hide") then
				var_7_1:getChildByName("awake_hide"):setVisible(true)
				var_7_1:getChildByName("icon_question"):setVisible(true)
			end
		end
	end

	return var_7_1
end

function var_0_0.showItemDetail(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0
	local var_9_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.equipConfirmWnd, {
		hero = arg_9_0.hero,
		item_index = arg_9_1,
		color = arg_9_2,
		state = arg_9_3
	})
end

return var_0_0
