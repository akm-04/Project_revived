local var_0_0 = class("SuperSelectLevelWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.petCampaign
local var_0_3 = 4
local var_0_4 = 120
local var_0_5 = 220

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.petCampaign = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)
	arg_1_0.itemNum = var_0_2:getMaxLimitFloor(xyd.PetCampaignFloorType.SUPER)
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateListView(arg_3_0, arg_3_1)
	local var_3_0
	local var_3_1 = arg_3_0.listView_:dequeueItem()

	if not var_3_1 then
		var_3_1 = arg_3_0.listView_:newItem()
	else
		var_3_1:removeAllChildren(true)
	end

	local var_3_2 = arg_3_0:nodeByName("list"):getWidth()
	local var_3_3 = var_0_4

	var_3_1:setItemSize(var_3_2, var_3_3)

	local var_3_4 = display.newNode()

	var_3_4:setContentSize(var_3_2, var_3_3)

	local var_3_5 = false

	if not var_3_5 then
		local var_3_6 = 0

		for iter_3_0 = var_0_3 - 1, 0, -1 do
			local var_3_7 = arg_3_1 * var_0_3 - iter_3_0

			if var_3_7 <= arg_3_0.itemNum and var_3_7 > 0 then
				local var_3_8 = display.newNode()
				local var_3_9 = "windows/pet/petCampaign/super_select/level_item.csb"
				local var_3_10 = xyd.AssetLoader.get():loadNodeFromJson(var_3_9)
				local var_3_11 = var_3_10:getChildByName("container")
				local var_3_12 = var_3_11:getContentSize()
				local var_3_13

				if var_3_7 > arg_3_0.petCampaign.max_floor then
					var_3_13 = xyd.AssetLoader.get():loadLabel(nil, "super_select_gray")

					local var_3_14 = "windows/pet/petCampaign/super_select/select_btn.png"
					local var_3_15 = display.newFilteredSprite(var_3_14, "GRAY", {
						0.2,
						0.3,
						0.5,
						0.1
					})

					var_3_15:setAnchorPoint(cc.p(0, 0))
					var_3_11:getChildByName("btn"):addChild(var_3_15)
					var_3_11:getChildByName("word_gray1"):setVisible(true)
					var_3_11:getChildByName("word_gray2"):setVisible(true)
				else
					var_3_13 = xyd.AssetLoader.get():loadLabel(nil, "super_select")

					var_3_11:getChildByName("word_gray1"):setVisible(false)
					var_3_11:getChildByName("word_gray2"):setVisible(false)
					var_3_11:getChildByName("btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
						if arg_4_1 == ccui.TouchEventType.ended and arg_3_0.scrollViewMoved_ == false then
							xyd.EventDispatcher.get():dispatchEvent({
								name = xyd.event.SKY_CHANGE_FLOOR,
								params = var_3_7
							})
							xyd.WindowManager.get():closeWindow(arg_3_0)
						end
					end)
				end

				var_3_13:setString(var_3_7)
				var_3_13:addTo(var_3_11:getChildByName("num"))
				var_3_13:setAnchorPoint(cc.p(0.5, 0.5))
				var_3_10:setContentSize(var_3_12)
				var_3_8:setContentSize(var_3_12)
				var_3_10:setName("layout")
				var_3_10:setPosition(cc.p(0, 0))
				var_3_8:addChild(var_3_10)
				var_3_4:addChild(var_3_8)
				var_3_8:setPosition(var_3_6 * var_0_5, 0)

				var_3_6 = var_3_6 + 1
			end
		end
	end

	var_3_1:addContent(var_3_4)

	return var_3_1
end

function var_0_0.sourceDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return (math.ceil(arg_5_0.itemNum / var_0_3))
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		return arg_5_0:updateListView(arg_5_3)
	end
end

function var_0_0.willOpen(arg_6_0, arg_6_1)
	var_0_0.super.willOpen(arg_6_0, arg_6_1)

	arg_6_0.listView_ = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_6_0:nodeByName("list"):getWidth(), arg_6_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_6_0:nodeByName("list")):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.listView_:setDelegate(handler(arg_6_0, arg_6_0.sourceDelegate))
	arg_6_0.listView_:setBounceable(true)
	arg_6_0.listView_:reload()
	arg_6_0:layout()
end

function var_0_0.layout(arg_7_0)
	arg_7_0:addBlockLayer()
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super.didOpen(arg_8_0, arg_8_1)
end

function var_0_0.willClose(arg_9_0)
	var_0_0.super.willClose(arg_9_0, params)
end

return var_0_0
