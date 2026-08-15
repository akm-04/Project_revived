local var_0_0 = class("FireworkShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityFireworkShop
local var_0_3 = xyd.tables.item
local var_0_4 = 85
local var_0_5 = 150
local var_0_6 = 10

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.exchangeTicket = arg_1_2.exchange_ticket or 0
	arg_1_0.exchangeTimes = xyd.splitToNumber(arg_1_2.exchange_times, "|")
	arg_1_0.fireworkModel = xyd.ModelManager.get():loadModel(xyd.ModelType.FIREWORK)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevX_ = arg_3_1.x
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 5 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_top_1"):setString(var_0_1:translation("FIREWORK_TEXT_2"))
	arg_4_0:nodeByName("text_top_2"):setString(arg_4_0.exchangeTicket)

	local var_4_0 = arg_4_0:nodeByName("detail_container")
	local var_4_1 = var_4_0:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		}
	}):addTo(var_4_0):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0:initItemList()
end

function var_0_0.sortItems(arg_5_0, arg_5_1)
	local var_5_0 = {}
	local var_5_1 = {}

	for iter_5_0 = 1, #arg_5_1 do
		local var_5_2 = arg_5_1[iter_5_0]
		local var_5_3 = arg_5_0.exchangeTimes[var_5_2]
		local var_5_4 = var_0_2:buyLimit(var_5_2)

		if var_5_4 ~= -1 and var_5_4 == var_5_3 then
			table.insert(var_5_1, var_5_2)
		else
			table.insert(var_5_0, var_5_2)
		end
	end

	for iter_5_1 = 1, #var_5_1 do
		table.insert(var_5_0, var_5_1[iter_5_1])
	end

	return var_5_0
end

function var_0_0.initItemList(arg_6_0)
	local var_6_0 = arg_6_0:sortItems(var_0_2:ids())

	for iter_6_0 = 1, #var_6_0 do
		local var_6_1 = var_6_0[iter_6_0]
		local var_6_2 = arg_6_0.list:newItem()
		local var_6_3 = display.newNode()
		local var_6_4 = arg_6_0:nodeByName("detail_container"):getContentSize()

		var_6_3:setContentSize(var_6_4.width, var_0_5)
		arg_6_0:initItemCell(var_6_3, var_6_1)
		var_6_2:setItemSize(var_6_4.width, var_0_5)
		var_6_2:addContent(var_6_3)
		arg_6_0.list:addItem(var_6_2)
	end

	arg_6_0.list:reload()
end

function var_0_0.initItemCell(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = var_0_2:desc(arg_7_2)
	local var_7_1
	local var_7_2 = var_0_2:gift(arg_7_2)
	local var_7_3 = xyd.tables.gift:items(var_7_2)[1]
	local var_7_4 = var_0_2:ticket(arg_7_2)
	local var_7_5 = var_0_2:buyLimit(arg_7_2)
	local var_7_6 = arg_7_0.exchangeTimes[arg_7_2]
	local var_7_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/firework/firework_shop/firework_shop_item.csb")
	local var_7_8 = var_7_7:getChildByName("container")
	local var_7_9 = cc.p(var_7_8:getChildByName("node_item"):getPosition())
	local var_7_10 = cc.p(var_7_8:getChildByName("node_desc"):getPosition())
	local var_7_11 = display.newNode()

	var_7_11:setContentSize(var_0_4, var_0_4)
	var_7_11:setAnchorPoint(cc.p(0.5, 0.5))

	if var_7_3 == 0 then
		local var_7_12 = xyd.tables.gift:crystal(var_7_2)

		xyd.setItemBorder(var_7_11, -1, false, false, var_7_12)

		var_7_1 = var_0_1:translation("CRYSTAL") .. "x" .. var_7_12
	else
		local var_7_13 = xyd.tables.gift:itemNum(var_7_2)[1]

		xyd.setItemBorder(var_7_11, var_7_3, false, false, var_7_13, false, true)

		var_7_1 = var_0_3:name(var_7_3) .. "x" .. var_7_13
	end

	if var_7_5 ~= -1 then
		var_7_1 = var_7_1 .. string.format(var_0_1:translation("FIREWORK_TEXT_14"), var_7_5)
	end

	if var_7_5 == var_7_6 then
		var_7_8:getChildByName("btn_exchange"):getChildByName("text_exchange"):setVisible(false)
		var_7_8:getChildByName("btn_exchange"):getChildByName("text_exchange_gray"):setVisible(true)
		var_7_8:getChildByName("btn_exchange"):setBright(false)
	else
		var_7_8:getChildByName("btn_exchange"):getChildByName("text_exchange"):setVisible(true)
		var_7_8:getChildByName("btn_exchange"):getChildByName("text_exchange_gray"):setVisible(false)
	end

	var_7_8:getChildByName("text_name"):setString(var_7_1)
	var_7_8:getChildByName("text_coin_num"):setString("x" .. var_7_4)
	var_7_11:setPosition(cc.p(var_7_9))
	var_7_11:addTo(var_7_8)

	local var_7_14 = {
		size = 18,
		color = cc.c3b(106, 105, 119),
		text = var_7_0,
		dimensions = cc.size(450, 0)
	}
	local var_7_15 = xyd.AssetLoader.get():loadLabel(var_7_14)

	var_7_15:setAnchorPoint(cc.p(0, 0.5))
	var_7_15:setPosition(cc.p(var_7_10.x, var_7_10.y))
	var_7_15:addTo(var_7_8)
	arg_7_1:addChild(var_7_7)
	var_7_7:setPositionX(8)
	var_7_8:getChildByName("btn_exchange"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			var_7_8:getChildByName("btn_exchange"):setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			var_7_8:getChildByName("btn_exchange"):setScale(1)

			if var_7_5 ~= -1 and var_7_5 == var_7_6 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("FIREWORK_TEXT_16")
				})

				return
			elseif var_7_4 > arg_7_0.exchangeTicket then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("FIREWORK_TEXT_17")
				})

				return
			else
				arg_7_0.activitiesModel:getActivityReward2(xyd.Activities.FIREWORK, arg_7_2, 1, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						arg_7_0.player:handleRewards(arg_9_1.awards)
						arg_7_0:updateInfo(arg_7_2, var_7_4)

						var_7_6 = var_7_6 + 1

						if var_7_6 == var_7_5 then
							var_7_8:getChildByName("btn_exchange"):getChildByName("text_exchange"):setVisible(false)
							var_7_8:getChildByName("btn_exchange"):getChildByName("text_exchange_gray"):setVisible(true)
							var_7_8:getChildByName("btn_exchange"):setBright(false)
						end
					end
				end)
			end
		end
	end)
end

function var_0_0.updateInfo(arg_10_0, arg_10_1, arg_10_2)
	arg_10_0.exchangeTicket = arg_10_0.exchangeTicket - arg_10_2
	arg_10_0.fireworkModel.activity.details.exchange_ticket = arg_10_0.exchangeTicket
	arg_10_0.exchangeTimes[arg_10_1] = arg_10_0.exchangeTimes[arg_10_1] + 1

	local var_10_0 = xyd.luaStringMerge(arg_10_0.exchangeTimes, "|")

	arg_10_0.fireworkModel.activity.details.exchange_times = var_10_0

	arg_10_0:nodeByName("text_top_2"):setString(arg_10_0.exchangeTicket)

	local var_10_1 = xyd.WindowManager.get():getWindow("firework_main")

	if var_10_1 then
		var_10_1:layout()
	end
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
	arg_11_0:addBlockLayer()
end

function var_0_0.willClose(arg_12_0)
	if xyd.WindowManager.get():getWindow("firework_main") and arg_12_0.callback then
		arg_12_0.callback()
	end
end

return var_0_0
