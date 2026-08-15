local var_0_0 = class("RagnarokShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.ragnarokShop
local var_0_3 = xyd.tables.item
local var_0_4 = 3
local var_0_5 = xyd.tables.misc:getValue("activity_ragnarok_shop_item")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.exchangeTimes = arg_1_2.exchange_times
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	local var_2_0 = {
		ecoCount = 1,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_5
		},
		ecoIcons = {
			"windows/activities/1203/ragnarok/icon/icon_apple.png"
		}
	}

	arg_2_0:addTopSidebar(var_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list"):getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list:reload()
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		local var_4_0 = var_0_2:items()

		return math.ceil(#var_4_0 / var_0_4)
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_1 = arg_4_0.list:dequeueItem()

		if var_4_1 then
			var_4_1:removeAllChildren()
		else
			var_4_1 = arg_4_0.list:newItem()
		end

		local var_4_2 = display.newNode()

		var_4_2:setContentSize(815, 324)
		var_4_2:setAnchorPoint(cc.p(0.5, 0.5))

		for iter_4_0 = 1, var_0_4 do
			if arg_4_3 * var_0_4 - 3 + iter_4_0 > #var_0_2:items() then
				break
			end

			local var_4_3 = arg_4_0:createItemContent(arg_4_3 * var_0_4 - 3 + iter_4_0)

			var_4_3:addTo(var_4_2)
			var_4_3:setPosition(265 * (iter_4_0 - 1), 0)
		end

		var_4_1:addContent(var_4_2)
		var_4_1:setItemSize(815, 324)

		return var_4_1
	end
end

function var_0_0.createItemContent(arg_5_0, arg_5_1)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/ragnarok/shop_item.csb")
	local var_5_1 = var_5_0:getChildByName("container")
	local var_5_2 = var_5_1:getContentSize()

	var_5_0:setContentSize(var_5_2)

	local var_5_3 = var_0_2:itemID(arg_5_1)
	local var_5_4 = var_0_2:num(arg_5_1)
	local var_5_5 = var_0_2:limitNum(arg_5_1)
	local var_5_6 = var_0_2:price(arg_5_1)
	local var_5_7

	xyd.setItemAndAddTips(var_5_1:getChildByName("item"), var_5_3, var_5_4)
	var_5_1:getChildByName("txt_limit"):setString(var_0_1:translation("RAGNAROK_BOSS_SHOP_2"))
	var_5_1:getChildByName("btn_buy"):getChildByName("txt_buy"):setString(var_0_1:translation("RAGNAROK_BOSS_SHOP_3"))
	var_5_1:getChildByName("txt_name"):setString(var_0_3:name(var_5_3))
	var_5_1:getChildByName("txt_price"):setString(var_5_6)

	if var_5_5 < 0 then
		var_5_1:getChildByName("txt_limit_num"):setVisible(false)
		var_5_1:getChildByName("txt_limit"):setVisible(false)
	else
		var_5_7 = var_5_5 - arg_5_0.exchangeTimes[arg_5_1]

		var_5_1:getChildByName("txt_limit_num"):setString(var_5_7)
		var_5_1:getChildByName("txt_limit"):enableOutline(cc.c4b(165, 76, 200, 255), 2)
		var_5_1:getChildByName("txt_limit_num"):enableOutline(cc.c4b(165, 76, 200, 255), 2)
	end

	var_5_1:getChildByName("btn_buy"):setTouchSwallowEnabled(false)
	xyd.nodeEventSample(var_5_1:getChildByName("btn_buy"), nil, function()
		if arg_5_0.scrollViewMoved_ then
			return
		end

		local var_6_0 = arg_5_0.backpack:getItemNumByID(var_0_5)
		local var_6_1 = math.floor(var_6_0 / var_5_6)

		if var_5_7 and var_5_7 >= 0 then
			var_6_1 = math.min(var_6_1, var_5_7)
		else
			var_5_7 = -1
		end

		local var_6_2 = {
			id = arg_5_1,
			item_id = var_5_3,
			item_num = var_5_4,
			max_num = var_6_1,
			price = var_5_6,
			left_num = var_5_7,
			callback = handler(arg_5_0, arg_5_0.buyCallback)
		}

		xyd.WindowManager.get():openWindow("ragnarok_shop_detail", var_6_2)
	end)

	return var_5_0
end

function var_0_0.buyCallback(arg_7_0, arg_7_1)
	arg_7_0.exchangeTimes = arg_7_1.exchange_times

	arg_7_0.list:refreshList(nil, true)

	local var_7_0 = {
		true
	}

	arg_7_0:nodeByName("eco_sidebar"):update(var_7_0)
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 20 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

return var_0_0
