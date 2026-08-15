local var_0_0 = class("WishingPoolPresentWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.gift = xyd.tables.gift
	arg_1_0.itemTable = xyd.tables.item
	arg_1_0.giftID = arg_1_2.giftID
	arg_1_0.times = arg_1_2.times
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt"):setString(string.format(var_0_2:translation("ANNIVERSARY_WISHING_TIMES"), arg_3_0.times))
	arg_3_0:nodeByName("txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_3_0:nodeByName("txt_ok"):setString(var_0_2:translation("SURE"))

	local var_3_0 = arg_3_0:nodeByName("line"):getContentSize()
	local var_3_1 = var_0_1.new({
		size = var_3_0.width
	})

	var_3_1:addTo(arg_3_0:nodeByName("line"))
	var_3_1:setAnchorPoint(0.5, 0.5)
	var_3_1:setPosition(cc.p(var_3_0.width / 2, 2))

	local var_3_2 = arg_3_0:nodeByName("container")
	local var_3_3 = var_3_2:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_3.width, var_3_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_3_2):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0:updateBoardList()
end

function var_0_0.updateBoardList(arg_4_0)
	local var_4_0 = arg_4_0.gift:items(arg_4_0.giftID)
	local var_4_1 = arg_4_0.gift:itemNum(arg_4_0.giftID)
	local var_4_2 = #var_4_0

	for iter_4_0 = 1, var_4_2 do
		local var_4_3 = arg_4_0.list:newItem()
		local var_4_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd/wishing_pool/wishing_present_item.csb")
		local var_4_5 = var_4_4:getChildByName("container")
		local var_4_6 = var_4_5:getContentSize()

		xyd.setItemBorder(var_4_5:getChildByName("item"), var_4_0[iter_4_0], nil, nil, var_4_1[iter_4_0])
		var_4_5:getChildByName("txt_present"):setString(arg_4_0.itemTable:name(var_4_0[iter_4_0]))
		var_4_4:setAnchorPoint(cc.p(0.5, 0.5))
		var_4_4:setPosition(0, 0)
		var_4_3:addContent(var_4_4)
		var_4_3:setItemSize(var_4_6.width, var_4_6.height)
		arg_4_0.list:addItem(var_4_3)
	end

	arg_4_0.list:reload()
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevX_ = arg_5_1.x
	elseif arg_5_1.name == "moved" and 20 <= math.abs(arg_5_1.x - arg_5_0.prevX_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

return var_0_0
