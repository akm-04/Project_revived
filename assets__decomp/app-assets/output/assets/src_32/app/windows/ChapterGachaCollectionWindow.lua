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

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1187/gacha_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	for iter_4_0 = 1, 3 do
		local var_4_0 = arg_4_1[iter_4_0].itemID

		if var_4_0 == 0 then
			arg_4_0.contentView_:nodeByName("bg_item" .. iter_4_0):setVisible(false)
		else
			local var_4_1 = arg_4_0.contentView_:nodeByName("item" .. iter_4_0)

			var_4_1:removeAllChildren()

			local var_4_2 = cc.Node:create()

			var_4_2:setContentSize(var_4_1:getContentSize())
			var_4_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_4_2:setPosition(45, 45)
			xyd.setItemBorder(var_4_2, var_4_0, false, false, arg_4_1[iter_4_0].itemNum)
			var_4_2:setVisible(true)
			var_4_1:addChild(var_4_2)

			local var_4_3 = {
				id = var_4_0
			}

			xyd.addTips(var_4_2, var_4_3)
			arg_4_0.contentView_:nodeByName("name_txt" .. iter_4_0):setString(var_0_1:name(arg_4_1[iter_4_0].itemID))
			arg_4_0.contentView_:nodeByName("rare" .. iter_4_0):setVisible(false)
			arg_4_0.contentView_:nodeByName("star1" .. iter_4_0):setVisible(false)
			arg_4_0.contentView_:nodeByName("star2" .. iter_4_0):setVisible(false)
			arg_4_0.contentView_:nodeByName("star3" .. iter_4_0):setVisible(false)
		end
	end
end

local var_0_3 = class("ChapterGachaCollectionWindow", import("app.common.ui.BaseWindow"))
local var_0_4 = xyd.tables.activityGachaCollection
local var_0_5 = 3

function var_0_3.ctor(arg_5_0, arg_5_1, arg_5_2)
	var_0_3.super.ctor(arg_5_0, arg_5_1, arg_5_2)

	arg_5_0.chapter = arg_5_2.chapter
end

function var_0_3.willOpen(arg_6_0, arg_6_1)
	var_0_3.super:willOpen(arg_6_1)
	arg_6_0:layout()
end

function var_0_3.layout(arg_7_0)
	arg_7_0:nodeByName("scroll_container"):removeAllChildren()

	arg_7_0.scrollView = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 600, 520),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_7_0:nodeByName("scroll_container")):onScroll(handler(arg_7_0, arg_7_0.scrollListener))

	arg_7_0:updateItem()
end

function var_0_3.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
end

function var_0_3.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" and 6 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

function var_0_3.updateItem(arg_10_0)
	local var_10_0 = xyd.tables.chapter:rewardDisplay(arg_10_0.chapter)
	local var_10_1 = xyd.tables.chapter:rewardDisplayNums(arg_10_0.chapter)
	local var_10_2 = math.ceil(#var_10_0 / var_0_5)

	for iter_10_0 = 1, var_10_2 do
		local var_10_3 = arg_10_0.scrollView:newItem()
		local var_10_4 = var_0_0.new()
		local var_10_5 = {
			{},
			{},
			{}
		}
		local var_10_6 = (iter_10_0 - 1) * var_0_5

		for iter_10_1 = 1, 3 do
			var_10_5[iter_10_1].itemID = var_10_0[var_10_6 + iter_10_1] or 0
			var_10_5[iter_10_1].itemNum = var_10_1[iter_10_0 + iter_10_1] or 0
		end

		var_10_4:setParams(var_10_5)

		local var_10_7 = var_10_4:contentView():nodeByName("container"):getContentSize()

		var_10_4:setContentSize(var_10_7.width, var_10_7.height)
		var_10_3:addContent(var_10_4)
		var_10_3:setItemSize(var_10_7.width, var_10_7.height)
		arg_10_0.scrollView:addItem(var_10_3)
	end

	arg_10_0.scrollView:reload()
end

return var_0_3
