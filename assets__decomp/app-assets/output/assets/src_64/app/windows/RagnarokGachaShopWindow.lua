local var_0_0 = class("RagnarokGachaShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.ragnarokShop2
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.misc:getValue("activity_ragnarok_shop_item2")
local var_0_5 = 10001258

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
			var_0_4
		},
		ecoIcons = {
			"windows/activities/1203/reward_odin/coin.png"
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
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	local var_3_1 = xyd.tables.hero:modelID(var_0_5)
	local var_3_2 = xyd.HeroAnimation.new(nil, var_3_1, 1, {})

	var_3_2:addTo(arg_3_0:nodeByName("pos_hero"))
	var_3_2:idle(true)
	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.list:reload()
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #var_0_2:items()
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0 = arg_4_0.list:dequeueItem()

		if var_4_0 then
			var_4_0:removeAllChildren()
		else
			var_4_0 = arg_4_0.list:newItem()
		end

		local var_4_1 = arg_4_0:createItemContent(arg_4_3)
		local var_4_2 = var_4_1:getContentSize()

		var_4_0:addContent(var_4_1)
		var_4_0:setContentSize(var_4_2)
		var_4_0:setItemSize(var_4_2.width + 24, var_4_2.height)

		return var_4_0
	end
end

function var_0_0.createItemContent(arg_5_0, arg_5_1)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/reward_odin/shop_item.csb")
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

	if arg_5_0:checkIsLock(arg_5_1) then
		local var_5_8 = var_5_1:getChildByName("lock")
		local var_5_9 = {
			size = 26,
			text = var_0_2:conditionDesc(arg_5_1),
			align = cc.TEXT_ALIGNMENT_CENTRE,
			valign = cc.VERTICAL_TEXT_ALIGNMENT_CENTRE,
			dimensions = cc.size(200, 0)
		}
		local var_5_10 = xyd.AssetLoader.get():loadLabel(var_5_9)

		var_5_8:setVisible(true)
		var_5_10:setAnchorPoint(0.5, 0.5)
		var_5_10:setLineHeight(40)
		var_5_10:enableOutline(cc.c4b(106, 82, 144, 255), 2)
		var_5_8:getChildByName("pos_txt"):addChild(var_5_10)
	else
		xyd.nodeEventSample(var_5_1:getChildByName("btn_buy"), nil, function()
			if arg_5_0.scrollViewMoved_ then
				return
			end

			local var_6_0 = arg_5_0.backpack:getItemNumByID(var_0_4)
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

			xyd.WindowManager.get():openWindow("ragnarok_gacha_shop_detail", var_6_2)
		end)
	end

	return var_5_0
end

function var_0_0.checkIsLock(arg_7_0, arg_7_1)
	if var_0_2:condition(arg_7_1) == 0 then
		return false
	end
end

function var_0_0.buyCallback(arg_8_0, arg_8_1)
	arg_8_0.exchangeTimes = arg_8_1.exchange_times

	arg_8_0.list:refreshList()

	local var_8_0 = {
		true
	}

	arg_8_0:nodeByName("eco_sidebar"):update(var_8_0)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" and 20 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

return var_0_0
