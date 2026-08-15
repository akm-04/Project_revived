local var_0_0 = class("TwoYearsInviteWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 200
local var_0_3 = 660
local var_0_4 = 450
local var_0_5 = 1
local var_0_6 = 0

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.twoYearsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)
	arg_1_0.showItemPos = 0
	arg_1_0.showDetail = var_0_6
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:initListView()
	arg_3_0:updateInviteList()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.TWO_YEARS_HEROES_REFRESH, function(arg_4_0)
		if arg_3_0 and not tolua.isnull(arg_3_0) then
			arg_3_0.showItemPos = 0
			arg_3_0.showDetail = var_0_6

			arg_3_0.listView_:removeAllItems()
			arg_3_0:updateInviteList()
		end
	end)
end

function var_0_0.addClipper(arg_5_0)
	local var_5_0 = cc.ClippingNode:create()
	local var_5_1 = cc.rect(0, 0, 510, 444)
	local var_5_2 = display.newClippingRectangleNode(var_5_1)

	arg_5_0.node:setLocalZOrder(-1000)
	var_5_2:addChild(arg_5_0.node)
	var_5_2:addTo(arg_5_0:nodeByName("invite_list"))
end

function var_0_0.initListView(arg_6_0)
	arg_6_0.node = display.newNode()
	arg_6_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_6_0:nodeByName("invite_list"):getWidth(), arg_6_0:nodeByName("invite_list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_6_0:nodeByName("invite_list")):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.listView_:setDelegate(handler(arg_6_0, arg_6_0.delegate))
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrolling = false
		arg_7_0.prevX_ = arg_7_1.x
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
		arg_7_0.scrolling = true
	end
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0, var_8_1 = arg_8_0.twoYearsModel:getHeroList()
	local var_8_2 = #var_8_0
	local var_8_3 = #var_8_1

	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return var_8_2 + var_8_3 + arg_8_0.showDetail + 1
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_4 = arg_8_1:dequeueItem()

		if not var_8_4 then
			var_8_4 = arg_8_1:newItem()
		else
			var_8_4:removeAllChildren(true)
		end

		local var_8_5 = 0
		local var_8_6 = import("app.windows.TwoYearsInviteItem").new()

		if arg_8_3 <= var_8_2 then
			local var_8_7 = var_8_0[arg_8_3]

			var_8_6:setParams(var_8_7, arg_8_3, 1)
			var_8_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
				if arg_9_0.name == "began" then
					return true
				elseif arg_9_0.name == "ended" and not arg_8_0.scrolling then
					-- block empty
				end

				return false
			end)
		elseif arg_8_3 <= var_8_2 + var_8_3 + arg_8_0.showDetail then
			if arg_8_3 == arg_8_0.showItemPos + arg_8_0.showDetail then
				var_8_6 = import("app.windows.TwoYearsQuestDetailItem").new()

				local var_8_8 = var_8_1[arg_8_0.showItemPos - var_8_2]

				if var_8_8 then
					var_8_6:setParams(var_8_8)
					var_8_4:setLocalZOrder(100000)
				end
			else
				local var_8_9

				if arg_8_0.showDetail == var_0_5 then
					if arg_8_3 <= arg_8_0.showItemPos then
						var_8_9 = var_8_1[arg_8_3 - var_8_2]
					else
						var_8_9 = var_8_1[arg_8_3 - var_8_2 - arg_8_0.showDetail]
					end
				else
					var_8_9 = var_8_1[arg_8_3 - var_8_2]
				end

				var_8_6:setParams(var_8_9, arg_8_3, 2)
				var_8_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
					if arg_10_0.name == "began" then
						return true
					elseif arg_10_0.name == "ended" and not arg_8_0.scrolling then
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.TWO_YEARS_ITEM_NOTIFY,
							params = {
								oldPos = arg_8_0.showItemPos,
								newPos = arg_8_3
							}
						})

						if var_8_4.ItemIndex_ == arg_8_0.showItemPos then
							arg_8_0.showItemPos = 0
							arg_8_0.showDetail = var_0_6
						else
							if arg_8_0.showItemPos < arg_8_3 then
								arg_8_0.showItemPos = arg_8_3 - arg_8_0.showDetail
							else
								arg_8_0.showItemPos = arg_8_3
							end

							arg_8_0.showDetail = var_0_5
						end

						local var_10_0 = arg_8_0.listView_.container:getPositionX()

						arg_8_0.listView_:reload()
						arg_8_0.listView_:scrollTo(var_10_0, 0)
					end

					return false
				end)
			end
		else
			var_8_6:setParams(nil, arg_8_3, false)
			var_8_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
				if arg_11_0.name == "began" then
					return true
				elseif arg_11_0.name == "ended" and not arg_8_0.scrolling then
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.TWO_YEARS_ITEM_NOTIFY,
						params = {
							is_refresh = true,
							oldPos = arg_8_0.showItemPos,
							newPos = arg_8_3
						}
					})
				end

				return false
			end)
		end

		var_8_4:addContent(var_8_6)

		var_8_4.ItemIndex_ = arg_8_3

		var_8_4:setItemSize(var_8_6:getContentSize().width, var_8_6:getContentSize().height)

		return var_8_4
	end
end

function var_0_0.updateInviteList(arg_12_0)
	arg_12_0.listView_:reload()
end

function var_0_0.willClose(arg_13_0)
	return
end

return var_0_0
