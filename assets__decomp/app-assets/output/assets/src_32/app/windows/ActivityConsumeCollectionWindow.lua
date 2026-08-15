local var_0_0 = class("CollectionItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.item
local var_0_2 = xyd.tables.hero

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow").new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1168/collection/item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	for iter_4_0 = 1, 4 do
		local var_4_0 = arg_4_1[iter_4_0].itemID

		if not var_4_0 or var_4_0 == 0 then
			arg_4_0.contentView_:nodeByName("bg_item" .. iter_4_0):setVisible(false)
		else
			local var_4_1 = arg_4_0.contentView_:nodeByName("item" .. iter_4_0)

			var_4_1:removeAllChildren()

			local var_4_2 = cc.Node:create()

			var_4_2:setContentSize(var_4_1:getContentSize())
			var_4_2:setAnchorPoint(cc.p(0, 0))
			var_4_2:setPosition(0, 0)
			xyd.setItemBorder(var_4_2, var_4_0, false, false, arg_4_1[iter_4_0].itemNum)
			var_4_2:setVisible(true)
			var_4_1:addChild(var_4_2)

			local var_4_3 = {
				id = var_4_0
			}

			xyd.addTips(var_4_2, var_4_3)
			arg_4_0.contentView_:nodeByName("name_txt" .. iter_4_0):setString(var_0_1:name(arg_4_1[iter_4_0].itemID))

			if arg_4_1[iter_4_0].rarity > 1 then
				arg_4_0.contentView_:nodeByName("rare" .. iter_4_0):setVisible(true)

				if arg_4_1[iter_4_0].rarity == 2 then
					arg_4_0.contentView_:nodeByName("rare" .. iter_4_0):loadTexture("windows/activities/1168/collection/rare_icon.png")
				end
			else
				arg_4_0.contentView_:nodeByName("rare" .. iter_4_0):setVisible(false)
			end

			local function var_4_4()
				local var_5_0 = "windows/activities/1168/collection/icon_star.png"

				return xyd.AssetLoader.get():loadSprite(var_5_0)
			end

			if xyd.tables.item:type(var_4_0) == -1 then
				local var_4_5 = xyd.tables.hero:initialStar(var_4_0)
				local var_4_6 = display.newNode()
				local var_4_7 = var_4_4()
				local var_4_8 = var_4_7:getWidth()
				local var_4_9 = var_4_8 + (var_4_5 - 1) * 35
				local var_4_10 = var_4_7:getHeight()

				var_4_6:setContentSize(var_4_9, var_4_10)
				var_4_6:setAnchorPoint(0.5, 0.5)
				var_4_7:addTo(var_4_6, 10)
				var_4_7:setAnchorPoint(0.5, 0.5)
				var_4_7:setPosition(var_4_8 / 2, var_4_10 / 2 + 2)

				for iter_4_1 = 1, var_4_5 - 1 do
					local var_4_11 = var_4_4()

					var_4_11:addTo(var_4_6, 10 - iter_4_1)
					var_4_11:setAnchorPoint(0.5, 0.5)
					var_4_11:setPosition(var_4_8 / 2 + iter_4_1 * 35, var_4_10 / 2 + 2)
				end

				arg_4_0.contentView_:nodeByName("bg_item" .. iter_4_0):addChild(var_4_6)
				var_4_6:setPosition(cc.p(101, 65))
			end
		end
	end
end

local var_0_3 = class("ActivityConsumeCollectionWindow", import("app.common.ui.BaseWindow"))
local var_0_4 = xyd.tables.activityConsumePool
local var_0_5 = xyd.tables.gift
local var_0_6 = 4

function var_0_3.ctor(arg_6_0, arg_6_1, arg_6_2)
	var_0_3.super.ctor(arg_6_0, arg_6_1, arg_6_2)
end

function var_0_3.willOpen(arg_7_0, arg_7_1)
	var_0_3.super:willOpen(arg_7_1)
	arg_7_0:layout()
end

function var_0_3.layout(arg_8_0)
	local var_8_0 = arg_8_0:nodeByName("scroll"):getContentSize()

	arg_8_0:nodeByName("scroll"):removeAllChildren()

	arg_8_0.scrollView = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_8_0.width, var_8_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_8_0:nodeByName("scroll")):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0:updateItem()
end

function var_0_3.didOpen(arg_9_0, arg_9_1)
	arg_9_0:addBlockLayer()
end

function var_0_3.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevX_ = arg_10_1.x
	elseif arg_10_1.name == "moved" and 6 <= math.abs(arg_10_1.x - arg_10_0.prevX_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

function var_0_3.updateItem(arg_11_0)
	local var_11_0 = math.ceil(var_0_4:count() / var_0_6)

	for iter_11_0 = 1, var_11_0 do
		local var_11_1 = arg_11_0.scrollView:newItem()
		local var_11_2 = var_0_0.new()
		local var_11_3 = {
			{},
			{},
			{},
			{}
		}
		local var_11_4 = (iter_11_0 - 1) * var_0_6

		for iter_11_1 = 1, var_0_6 do
			local var_11_5 = var_0_4:gift(var_11_4 + iter_11_1)
			local var_11_6 = var_0_5:items(var_11_5)
			local var_11_7 = var_0_5:itemNum(var_11_5)
			local var_11_8 = var_11_6[1]
			local var_11_9 = var_11_7[1]

			var_11_3[iter_11_1].itemID = var_11_8
			var_11_3[iter_11_1].itemNum = var_11_9
			var_11_3[iter_11_1].isRarest = var_0_4:isRarest(var_11_4 + iter_11_1)
			var_11_3[iter_11_1].rarity = var_0_4:rarity(var_11_4 + iter_11_1)
		end

		var_11_2:setParams(var_11_3)

		local var_11_10 = var_11_2:contentView():nodeByName("container"):getContentSize()

		var_11_2:setContentSize(var_11_10.width, var_11_10.height)
		var_11_1:addContent(var_11_2)
		var_11_1:setItemSize(var_11_10.width, var_11_10.height)
		arg_11_0.scrollView:addItem(var_11_1)
	end

	arg_11_0.scrollView:reload()
end

return var_0_3
