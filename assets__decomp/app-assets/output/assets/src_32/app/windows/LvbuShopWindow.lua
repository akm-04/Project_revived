local var_0_0 = class("LvbuShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.activityLvbuShopFengxian
local var_0_4 = xyd.tables.activityLvbuShopLvbusp
local var_0_5 = 3
local var_0_6 = 10

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()

	arg_1_0:filterItems()

	arg_1_0.stage = arg_1_0:getFengxianBuyStage()
end

function var_0_0.getFengxianBuyStage(arg_2_0)
	local var_2_0 = arg_2_0.selfPlayer:getHeroIgnoreAwaken(xyd.tables.misc.lvbuTableID)
	local var_2_1 = 0
	local var_2_2 = var_0_3:ids()

	if var_2_0 then
		local var_2_3 = var_2_0:getStar()
		local var_2_4 = 0

		if var_2_0:isAwakeTwice() then
			var_2_4 = 2
		elseif var_2_0:isAwaken() then
			var_2_4 = 1
		end

		for iter_2_0 = #var_2_2, 1, -1 do
			local var_2_5 = var_2_2[iter_2_0]
			local var_2_6 = var_0_3:awakenTimes(var_2_5)
			local var_2_7 = var_0_3:star(var_2_5)

			if var_2_6 <= var_2_4 and var_2_7 <= var_2_3 and (var_2_5 ~= 4 or not (arg_2_0.lvbuFestival.details.fengxian_times < var_0_3:buyLimit(var_2_5 - 1))) then
				var_2_1 = var_2_5

				break
			end
		end
	end

	return var_2_1
end

function var_0_0.filterItems(arg_3_0)
	arg_3_0.listInfo = clone(xyd.tables.lvbuShopItem:getItems(true))
	arg_3_0.canBuyInfo = clone(arg_3_0.listInfo)

	local var_3_0 = arg_3_0.selfPlayer:getHeroIgnoreAwaken(xyd.tables.misc.lvbuTableID)
	local var_3_1 = arg_3_0.selfPlayer:getHeroIgnoreAwaken(xyd.tables.misc.lvlingqiTableID)
	local var_3_2 = arg_3_0.selfPlayer:getHeroIgnoreAwaken(xyd.tables.misc.fengxianTableId)

	for iter_3_0 = #arg_3_0.canBuyInfo, 1, -1 do
		if iter_3_0 ~= arg_3_0.canBuyInfo[iter_3_0] then
			-- block empty
		elseif iter_3_0 == 15 then
			if arg_3_0.backpack:getItemNumByID(230001008) <= 0 then
				table.remove(arg_3_0.canBuyInfo, iter_3_0)
			end
		elseif iter_3_0 == 14 and (not var_3_2 or var_3_2:getStar() < 5) then
			table.remove(arg_3_0.canBuyInfo, iter_3_0)
		elseif iter_3_0 == 11 and (not var_3_1 or not var_3_1:isAwaken()) then
			table.remove(arg_3_0.canBuyInfo, iter_3_0)
		elseif iter_3_0 == 10 then
			if arg_3_0.backpack:getItemNumByID(230001005) <= 0 then
				table.remove(arg_3_0.canBuyInfo, iter_3_0)
			end
		elseif iter_3_0 == 9 and var_3_0:getStar() < 3 then
			table.remove(arg_3_0.canBuyInfo, iter_3_0)
		elseif iter_3_0 == 8 and var_3_0:getStar() < 5 then
			table.remove(arg_3_0.canBuyInfo, iter_3_0)
		elseif iter_3_0 == 5 then
			if not var_3_0:isAwaken() then
				table.remove(arg_3_0.canBuyInfo, iter_3_0)
			end
		elseif iter_3_0 == 4 and var_3_0:getStar() < 5 then
			table.remove(arg_3_0.canBuyInfo, iter_3_0)
		end
	end

	if arg_3_0.listInfo[#arg_3_0.listInfo] == 13 then
		table.remove(arg_3_0.listInfo, #arg_3_0.listInfo)
		table.insert(arg_3_0.listInfo, 1, 13)
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super:willOpen(arg_4_1)
	arg_4_0:layout()
	arg_4_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 150))
end

function var_0_0.willClose(arg_5_0, arg_5_1)
	var_0_0.super:willClose(arg_5_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.LVBU_DOOR_BRANCH_FESIBLE
	})
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("item_container")
	local var_6_1 = var_6_0:getContentSize()

	arg_6_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_1.width, var_6_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_6_0):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.list:setDelegate(handler(arg_6_0, arg_6_0.delegate))
	arg_6_0.list:reload()
	xyd.nodeEventSample(arg_6_0:nodeByName("btn_close"), nil, function()
		xyd.WindowManager.get():closeWindow(arg_6_0)
	end)
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevX_ = arg_8_1.x
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" then
		local var_8_0 = 3

		if var_8_0 <= math.abs(arg_8_1.y - arg_8_0.prevY_) or var_8_0 <= math.abs(arg_8_1.x - arg_8_0.prevX_) then
			arg_8_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return (math.ceil(#arg_9_0.listInfo / var_0_5))
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0 = arg_9_0.list:dequeueItem()

		if not var_9_0 then
			var_9_0 = arg_9_0.list:newItem()
		else
			var_9_0:removeAllChildren(true)
		end

		local var_9_1 = 820
		local var_9_2 = 329

		var_9_0:setItemSize(var_9_1, var_9_2)

		local var_9_3 = display.newNode()

		var_9_3:setContentSize(var_9_0:getContentSize())

		for iter_9_0 = 1, 3 do
			if (arg_9_3 - 1) * var_0_5 + iter_9_0 <= #arg_9_0.listInfo then
				arg_9_0:createExchangeItem(var_9_3, arg_9_3, iter_9_0)
			end
		end

		var_9_0:addContent(var_9_3)

		return var_9_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_9_2 then
		-- block empty
	end
end

function var_0_0.isHaveLvbu5star(arg_10_0)
	for iter_10_0, iter_10_1 in pairs(arg_10_0.selfPlayer.heros_) do
		local var_10_0 = iter_10_1:getTableID()

		if iter_10_1:isAwaken() then
			var_10_0 = xyd.tables.hero:beforeAwaken(var_10_0)
		end

		if var_10_0 == xyd.tables.misc.lvbuTableID and iter_10_1:getStar() >= 5 then
			return true
		end
	end

	return false
end

function var_0_0.createExchangeItem(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = (arg_11_2 - 1) * var_0_5 + arg_11_3
	local var_11_1 = arg_11_0.listInfo[var_11_0]
	local var_11_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/exchange_item/exchange_item_lvbu.csb")
	local var_11_3 = var_11_2:getChildByName("container")
	local var_11_4 = xyd.tables.lvbuShopItem
	local var_11_5 = var_11_4:showItem(var_11_1)

	var_11_3:getChildByName("name_txt"):setString(xyd.tables.item:name(var_11_5))
	var_11_3:getChildByName("price_txt"):setString(var_11_4:price(var_11_1))
	xyd.setItemAndAddTips(var_11_3:getChildByName("icon_container"), var_11_5)

	local var_11_6 = arg_11_0:getFengxianBuyStage()
	local var_11_7 = arg_11_0:getLvbuspBuyStage()

	xyd.nodeEventSample(var_11_3:getChildByName("exchange_btn"), nil, function()
		local var_12_0 = arg_11_0:getFengxianBuyStage()

		arg_11_0.scrollNodePosY = arg_11_0.list.scrollNode:getPositionY()

		function buy()
			local var_13_0 = {
				id = var_11_1,
				itemID = var_11_5,
				fengxianStage = var_12_0,
				lvbuspStage = var_11_7
			}

			xyd.WindowManager.get():openWindow("lvbu_sure_exchange", var_13_0)
		end

		if var_11_1 == 2 then
			local var_12_1 = arg_11_0.lvbuFestival.details.lvbusp_times
			local var_12_2 = var_0_4:buyLimit(var_11_7)

			if var_11_7 <= 1 and var_12_2 <= var_12_1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:tips(var_11_7 + 1)
				})

				return
			end
		end

		buy()
	end)
	var_11_3:getChildByName("limit_stamp"):setVisible(false)
	var_11_3:getChildByName("cover"):getChildByName("unlock_text1"):enableOutline(cc.c4b(152, 93, 46, 255), 2)
	var_11_3:getChildByName("cover"):getChildByName("unlock_text2"):enableOutline(cc.c4b(46, 25, 58, 255), 2)
	var_11_3:getChildByName("exchange_btn"):getChildByName("exchange_txt"):setString(var_0_1:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT2"))
	var_11_3:getChildByName("cover"):setVisible(false)
	var_11_3:getChildByName("cover"):setTouchSwallowEnabled(true)

	if not xyd.isInTable(arg_11_0.canBuyInfo, var_11_1) then
		var_11_3:getChildByName("cover"):setVisible(true)
		var_11_3:getChildByName("cover"):getChildByName("unlock_text1"):setString(var_0_1:translation("OPEN_CONDITION_TEXT"))
		var_11_3:getChildByName("cover"):getChildByName("unlock_text2"):setString(var_11_4:unlock(var_11_1))
		var_11_3:getChildByName("exchange_btn"):setTouchEnabled(false)
	elseif var_11_0 == 2 then
		local var_11_8 = arg_11_0.lvbuFestival.details.lvbusp_times
		local var_11_9 = var_0_4:buyLimit(var_11_7)

		if var_11_7 <= 1 and var_11_9 <= var_11_8 then
			var_11_3:getChildByName("cover"):setVisible(true)
			var_11_3:getChildByName("cover"):getChildByName("unlock_text1"):setString(var_0_1:translation("OPEN_CONDITION_TEXT"))
			var_11_3:getChildByName("cover"):getChildByName("unlock_text2"):setString(var_0_4:tips(var_11_7 + 1))
			var_11_3:getChildByName("exchange_btn"):setTouchEnabled(false)
		end
	end

	local var_11_10 = arg_11_0.selfPlayer:getHeroIgnoreAwaken(xyd.tables.misc.lvbuTableID):getStar()

	if var_11_1 == 2 and var_11_10 < 4 then
		var_11_3:getChildByName("limit_stamp"):setVisible(false)
		var_11_3:getChildByName("price_txt"):setString(var_0_4:price(math.max(1, var_11_7)))
	elseif var_11_1 == 2 and var_11_10 == 4 then
		var_11_3:getChildByName("limit_stamp"):setVisible(false)
		var_11_3:getChildByName("price_txt"):setString(var_0_4:price(var_11_7))
	else
		var_11_3:getChildByName("limit_stamp"):setVisible(false)
	end

	var_11_2:addTo(arg_11_1)
	var_11_2:setAnchorPoint(cc.p(0, 0))
	var_11_2:setPosition((arg_11_3 - 1) * (var_11_3:getWidth() + var_0_6), 0)
	var_11_2:setName("source")

	return arg_11_1
end

function var_0_0.getLvbuspBuyStage(arg_14_0)
	local var_14_0 = arg_14_0.selfPlayer:getHeroIgnoreAwaken(xyd.tables.misc.lvbuTableID)
	local var_14_1 = 0
	local var_14_2 = var_0_4:ids()

	if var_14_0 then
		local var_14_3 = var_14_0:getStar()
		local var_14_4 = 0

		if var_14_0:isAwakeTwice() then
			var_14_4 = 2
		elseif var_14_0:isAwaken() then
			var_14_4 = 1
		end

		for iter_14_0 = #var_14_2, 1, -1 do
			local var_14_5 = var_14_2[iter_14_0]
			local var_14_6 = var_0_4:awakenTimes(var_14_5)
			local var_14_7 = var_0_4:star(var_14_5)

			if var_14_6 <= var_14_4 and var_14_7 <= var_14_3 then
				var_14_1 = var_14_5

				break
			end
		end
	end

	return var_14_1
end

return var_0_0
