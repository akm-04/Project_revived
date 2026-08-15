local var_0_0 = class("LuckybagPresentWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.bagTable = xyd.tables.AnniLuckybagTable
	arg_1_0.itemTable = xyd.tables.item
	arg_1_0.fudai_id = arg_1_2.type
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)
	arg_3_0:updateBoardList()
end

function var_0_0.updateBoardList(arg_4_0)
	local var_4_0 = arg_4_0.bagTable:getDisplayItemIds(arg_4_0.fudai_id)
	local var_4_1 = arg_4_0.bagTable:getDisplayItemCount(arg_4_0.fudai_id)
	local var_4_2 = arg_4_0.bagTable:getItemRare(arg_4_0.fudai_id)
	local var_4_3 = 4
	local var_4_4 = math.ceil(#var_4_0 / 4)

	local function var_4_5(arg_5_0, arg_5_1, arg_5_2)
		local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd/lucky_bag/present_item.csb")
		local var_5_1 = var_5_0:getChildByName("container")

		if not arg_5_2 or arg_5_2 ~= 1 then
			var_5_1:getChildByName("chaoxiyou"):setVisible(false)
		end

		xyd.setItemAndAddTips(var_5_1:getChildByName("item"), arg_5_0, arg_5_1)
		var_5_1:getChildByName("item_txt"):setString(arg_4_0.itemTable:name(arg_5_0))

		return var_5_0
	end

	for iter_4_0 = 1, var_4_4 do
		local var_4_6 = arg_4_0.list:newItem()
		local var_4_7 = display.newNode()

		var_4_7:setContentSize(910, 205)

		local var_4_8 = var_4_7:getContentSize()

		for iter_4_1 = 1, var_4_3 do
			local var_4_9 = var_4_0[(iter_4_0 - 1) * 4 + iter_4_1]

			if var_4_9 and var_4_9 > 0 then
				local var_4_10 = var_4_1[(iter_4_0 - 1) * 4 + iter_4_1]
				local var_4_11 = var_4_2[(iter_4_0 - 1) * 4 + iter_4_1]
				local var_4_12 = var_4_5(var_4_9, var_4_10, var_4_11)

				var_4_7:addChild(var_4_12)
				var_4_12:setPosition((iter_4_1 - 1) * 231, 10)
			end
		end

		var_4_7:setAnchorPoint(cc.p(0, 0))
		var_4_7:setPosition(0, 0)
		var_4_6:addContent(var_4_7)
		var_4_6:setItemSize(var_4_8.width, var_4_8.height)
		arg_4_0.list:addItem(var_4_6)
	end

	arg_4_0.list:reload()
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 20 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

return var_0_0
