local var_0_0 = class("ExchangeItemWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Item")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.item = arg_1_2.item
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack_ = arg_1_0.player_:getBackpack()
	arg_1_0.select_ = nil
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0)
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
	arg_3_0:updateData()
	arg_3_0:updateTittle()
	arg_3_0:layout()
	arg_3_0:getBtn()
end

function var_0_0.willClose(arg_4_0)
	var_0_0.super.willClose(arg_4_0)
end

function var_0_0.didClose(arg_5_0)
	var_0_0.super.didClose(arg_5_0)
end

function var_0_0.updateData(arg_6_0)
	arg_6_0.exchangeIDs_ = var_0_3:canExchangeItem(arg_6_0.item:getTableID())
	arg_6_0.exchanges_ = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.exchangeIDs_) do
		local var_6_0 = var_0_1.new()

		var_6_0:populate({
			table_id = iter_6_1
		})
		table.insert(arg_6_0.exchanges_, var_6_0)
	end
end

function var_0_0.layout(arg_7_0)
	local var_7_0 = display.newNode()

	var_7_0:size(100, 100)
	var_7_0:addTo(arg_7_0)
	var_7_0:align(display.CENTER, 0, arg_7_0:getHeight())
	xyd.setItemBorder(var_7_0, arg_7_0.item:getTableID())

	local var_7_1 = {
		id = arg_7_0.item:getTableID()
	}

	var_7_1.showNum = true
	var_7_1.itemHeroList = itemHeroList
	var_7_1.hasNum = arg_7_0.player_:getBackpack():getItemNumByID(arg_7_0.item:getTableID())

	local var_7_2 = var_7_0:getX()
	local var_7_3 = var_7_0:getY() + 70

	var_7_0:setTouchEnabled(true)
	var_7_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			if arg_7_0.scrollViewMoved_ then
				return true
			end

			if not xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_8_0 = xyd.WindowManager.get():openWindow("new_item_tips", var_7_1)

				xyd.adaptToWorldPosition(var_7_0, var_8_0)
			end

			return true
		elseif arg_8_0.name == "ended" then
			if arg_7_0.scrollViewMoved_ then
				return true
			end

			local var_8_1 = xyd.WindowManager.get():getWindow("new_item_tips")

			xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)

	local var_7_4 = arg_7_0:nodeByName("container")

	arg_7_0.touchList_ = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_7_4:getWidth(), var_7_4:getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_VCENTER
	}):addTo(var_7_4):onScroll(handler(arg_7_0, arg_7_0.scrollListener))

	arg_7_0.touchList_:align(display.LEFT_BOTTOM, 0, 0)

	for iter_7_0 = 1, arg_7_0:delegate(nil, cc.ui.UIListView.COUNT_TAG) do
		local var_7_5 = arg_7_0:delegate(nil, cc.ui.UIListView.CELL_TAG, iter_7_0)

		arg_7_0.touchList_:addItem(var_7_5)
	end

	arg_7_0.touchList_:reload()
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" and 20 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #arg_10_0.exchanges_
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1
		local var_10_2 = arg_10_0.touchList_:dequeueItem()

		if not var_10_2 then
			var_10_2 = arg_10_0.touchList_:newItem()
		else
			var_10_2:removeAllChildren()
		end

		local var_10_3 = arg_10_0:nodeByName("container")
		local var_10_4 = display.newNode()

		var_10_4:setTouchSwallowEnabled(false)
		var_10_4:size(var_10_3:getHeight(), var_10_3:getHeight())
		xyd.setItemBorder(var_10_4, arg_10_0.exchangeIDs_[arg_10_3])
		var_10_4:align(display.LEFT_BOTTOM, 0, 0)

		local var_10_5 = (var_10_3:getWidth() - (var_10_4:getWidth() + 10) * #arg_10_0.exchanges_) / 2

		if var_10_5 > 0 then
			local var_10_6 = {
				top = 0,
				bottom = 0,
				right = 0,
				left = var_10_5
			}

			var_10_2:setMargin(var_10_6)
		end

		var_10_2:setItemSize(var_10_4:getWidth() + 10, var_10_4:getHeight())
		var_10_2:addContent(var_10_4)

		local var_10_7 = arg_10_0:getPlusType(arg_10_0.exchangeIDs_[arg_10_3])
		local var_10_8 = {
			id = arg_10_0.exchangeIDs_[arg_10_3]
		}

		var_10_8.showNum = true
		var_10_8.itemHeroList = var_10_7

		local var_10_9 = var_10_4:getX() + var_10_3:getX()
		local var_10_10 = var_10_4:getY() + var_10_3:getY()
		local var_10_11 = var_10_4:getHeight()

		var_10_4.item = arg_10_0.exchanges_[arg_10_3]

		var_10_4:setTouchEnabled(true)
		var_10_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
			if arg_11_0.name == "began" then
				if arg_10_0.scrollViewMoved_ then
					return true
				end

				if not xyd.WindowManager.get():getWindow("new_item_tips") then
					var_10_8.hasNum = arg_10_0.player_:getBackpack():getItemNumByID(arg_10_0.exchangeIDs_[arg_10_3])

					local var_11_0 = xyd.WindowManager.get():openWindow("new_item_tips", var_10_8)

					xyd.adaptToWorldPosition(var_10_4, var_11_0)
				end

				return true
			elseif arg_11_0.name == "ended" then
				if arg_10_0.scrollViewMoved_ then
					return true
				end

				if arg_10_0.select_ ~= var_10_4 then
					if arg_10_0.select_ and arg_10_0.select_.chosenSp and not tolua.isnull(arg_10_0.select_.chosenSp) then
						arg_10_0.select_.chosenSp:removeSelf()

						arg_10_0.select_.chosenSp = nil
					end

					local var_11_1 = xyd.AssetLoader.get():loadSprite("windows/compose/chosen.png")

					var_11_1:addTo(var_10_4, 10):align(display.RIGHT_BOTTOM, var_10_4:getWidth(), 0)

					var_10_4.chosenSp = var_11_1
				end

				arg_10_0.select_ = var_10_4

				local var_11_2 = xyd.WindowManager.get():getWindow("new_item_tips")

				xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)

		return var_10_2
	end
end

function var_0_0.getPlusType(arg_12_0, arg_12_1)
	local var_12_0 = {}

	for iter_12_0, iter_12_1 in pairs(arg_12_0.player_.heros_) do
		if iter_12_1:getItemHeroHasNotEquip(arg_12_1) then
			local var_12_1 = {}

			if xyd.tables.item:level(arg_12_1) > iter_12_1:getLevel() then
				var_12_1 = {
					plusType = 0,
					hero = iter_12_1
				}
			else
				var_12_1 = {
					plusType = 1,
					hero = iter_12_1
				}
			end

			table.insert(var_12_0, var_12_1)
		end
	end

	return var_12_0
end

function var_0_0.getBtn(arg_13_0)
	if not arg_13_0.btn_ then
		arg_13_0.btn_ = arg_13_0:nodeByName("button_ok")

		arg_13_0.btn_:addTouchEventListener(function(arg_14_0, arg_14_1)
			if arg_14_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_13_0.backpack_:getItemNumByID(arg_13_0.item:getTableID()) < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("EXCHANGE_ITEM_ABSENCE")
					})

					return
				end

				if not arg_13_0.select_ then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("EXCHANGE_CHOOSE_TIP")
					})

					return
				end

				local var_14_0 = arg_13_0.select_.item:getTableID()

				arg_13_0:exchange(var_14_0)
			end
		end)
	end

	return arg_13_0.btn_
end

function var_0_0.exchange(arg_15_0, arg_15_1)
	xyd.Backend.get():request(xyd.mid.EXCHANGE_ITEM, {
		item_id = arg_15_1
	}, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0.backpack_:addItemsByID(arg_15_1, 1)
			arg_15_0.backpack_:removeItem({
				itemNum = 1,
				itemID = arg_15_0.item:getTableID()
			})
			arg_15_0:updateTittle()

			local var_16_0 = xyd.WindowManager.get():getWindow("backpack")

			if var_16_0 then
				var_16_0:refreshDisplayOption()
				var_16_0:updateItemDetail(var_16_0.itemID)
			end

			local var_16_1 = xyd.WindowManager.get():getWindow("christmas_activity")

			if var_16_1 then
				var_16_1:update()
			end

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_2:translation("EXCHANGE_SUCCESS")
			})
		end
	end)
end

function var_0_0.updateTittle(arg_17_0)
	arg_17_0:nodeByName("tittle"):setString(string.format(var_0_2:translation("EXCHANG_ITEM_TITTLE"), arg_17_0.item:getName(), arg_17_0.backpack_:getItemNumByID(arg_17_0.item:getTableID())))
end

return var_0_0
