local var_0_0 = class("SellWindow", import("app.common.ui.BaseWindow"))

var_0_0.SELL_BUTTON = "btn_sell"
var_0_0.CANCEL_BUTTON = "close"
var_0_0.TOTAL_PRICE = "txt_pricesum"
var_0_0.IMG_CURRENCY = "img_currency"
var_0_0.TITLE = "text_title"
var_0_0.WILLGET = "text_willget"
var_0_0.WILLGET1 = "text_willget_1"

local var_0_1 = 60
local var_0_2 = 350
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack_ = arg_1_0.player_:getBackpack()
end

function var_0_0.initSellWindow(arg_2_0, arg_2_1)
	if arg_2_1 > 3 then
		arg_2_1 = 3
	end

	arg_2_0:nodeByName(var_0_0.TITLE):setPositionY(arg_2_0:nodeByName(var_0_0.TITLE):getPositionY() + (var_0_1 + 20) * (arg_2_1 - 1) / 2)
	arg_2_0:nodeByName("mid_area"):setContentSize(arg_2_0:nodeByName("mid_area"):getContentSize().width, (var_0_1 + 20) * arg_2_1)
	arg_2_0:nodeByName("close"):setPositionY(arg_2_0:nodeByName("close"):getPositionY() + (var_0_1 + 20) * (arg_2_1 - 1) / 2)
	arg_2_0:nodeByName("bottom"):setPositionY(arg_2_0:nodeByName("bottom"):getPositionY() - (var_0_1 + 20) * (arg_2_1 - 1) / 2)
	arg_2_0:nodeByName("detail_bg"):setContentSize(arg_2_0:nodeByName("detail_bg"):getContentSize().width, arg_2_0:nodeByName("detail_bg"):getContentSize().height + (var_0_1 + 20) * (arg_2_1 - 1))

	local var_2_0 = {
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("mid_area"):getContentSize().width - 30, (var_0_1 + 20) * arg_2_1),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_2_0.listview = cc.ui.UIListView.new(var_2_0):addTo(arg_2_0:nodeByName("mid_area")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 20 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	arg_4_0:nodeByName(var_0_0.TITLE):setString(var_0_3:translation("SELL_TITLE"))
	arg_4_0:nodeByName(var_0_0.WILLGET):setString(var_0_3:translation("SELL_WILLGET"))
	arg_4_0:nodeByName(var_0_0.WILLGET1):setString(var_0_3:translation("SELL_WILLGET"))
	arg_4_0:nodeByName("panel_bottom_energy"):setVisible(false)

	if arg_4_1.itemType == "ENERGY" then
		arg_4_0:nodeByName(var_0_0.TITLE):setString(var_0_3:translation("USE_MAGIC"))
		arg_4_0:nodeByName("panel_bottom_energy"):setVisible(true)
		arg_4_0:nodeByName("panel_bottom"):setVisible(false)
	end

	local var_4_0 = 0
	local var_4_1 = 0
	local var_4_2 = 0
	local var_4_3 = 0
	local var_4_4 = arg_4_1.items
	local var_4_5 = #var_4_4
	local var_4_6 = math.ceil(var_4_5 / 2)

	arg_4_0:initSellWindow(var_4_6)

	for iter_4_0 = 1, var_4_6 do
		local var_4_7 = 2

		if iter_4_0 == var_4_6 then
			var_4_7 = var_4_5 % 2

			if var_4_7 == 0 then
				var_4_7 = 2
			end
		end

		local var_4_8 = display.newNode()
		local var_4_9 = arg_4_0.listview:newItem()

		for iter_4_1 = 1, var_4_7 do
			local var_4_10 = var_4_4[(iter_4_0 - 1) * 2 + iter_4_1]
			local var_4_11 = xyd.tables.item:name(var_4_10.item_id)
			local var_4_12 = xyd.tables.item:mana(var_4_10.item_id)
			local var_4_13 = xyd.tables.item:magicEnergy(var_4_10.item_id)
			local var_4_14 = xyd.tables.item:magicDust(var_4_10.item_id)
			local var_4_15 = xyd.tables.item:magicLiquid(var_4_10.item_id)
			local var_4_16 = var_4_10.item_num

			if arg_4_1.itemType == "MANA" then
				var_4_0 = var_4_0 + var_4_16 * var_4_12
			elseif arg_4_1.itemType == "ENERGY" then
				if var_4_13 ~= nil and var_4_13 ~= 0 then
					var_4_3 = var_4_3 + var_4_13 * var_4_16
				elseif var_4_14 ~= nil and var_4_14 ~= 0 then
					var_4_1 = var_4_1 + var_4_14 * var_4_16
				elseif var_4_15 ~= nil and var_4_15 ~= 0 then
					var_4_2 = var_4_2 + var_4_15 * var_4_16
				end
			end

			local var_4_17 = cc.Node:create()

			var_4_17:setContentSize(var_0_1, var_0_1)
			xyd.setItemBorder(var_4_17, var_4_10.item_id)
			var_4_8:addChild(var_4_17)
			var_4_17:setAnchorPoint(cc.p(0, 0))

			local var_4_18 = {
				size = 30,
				color = cc.c4b(255, 255, 255, 255)
			}
			local var_4_19 = xyd.AssetLoader:get():loadLabel(var_4_18)

			var_4_19:setString(var_4_11)
			var_4_8:addChild(var_4_19)
			var_4_19:setAnchorPoint(cc.p(0, 0))

			local var_4_20 = {
				size = 22,
				color = cc.c4b(255, 255, 255, 255)
			}
			local var_4_21 = xyd.AssetLoader:get():loadLabel(var_4_20)

			var_4_21:setString("X " .. var_4_16)
			var_4_8:addChild(var_4_21)
			var_4_21:setAnchorPoint(cc.p(0, 0))
			var_4_17:setPosition((iter_4_1 - 1) * var_0_2 + 50, 0)
			var_4_19:setPosition((iter_4_1 - 1) * var_0_2 + 115, 13)
			var_4_21:setPosition((iter_4_1 - 1) * var_0_2 + var_4_19:getContentSize().width + 130, 13)
		end

		var_4_8:setContentSize(arg_4_0:nodeByName("mid_area"):getContentSize().width, var_0_1)
		var_4_8:setAnchorPoint(cc.p(0, 1))
		var_4_9:addContent(var_4_8)
		var_4_9:setItemSize(arg_4_0:nodeByName("mid_area"):getContentSize().width, var_0_1 + 20)
		arg_4_0.listview:addItem(var_4_9)
	end

	arg_4_0.listview:reload()

	if arg_4_1.itemType == "MANA" then
		arg_4_0:nodeByName(var_0_0.TOTAL_PRICE):setString(var_4_0)
		arg_4_0:nodeByName("btn_sell"):setPositionY(arg_4_0:nodeByName("btn_sell"):getPositionY() + 50)
		arg_4_0:nodeByName("detail_bg"):setPositionY(arg_4_0:nodeByName("detail_bg"):getPositionY() + 25)
		arg_4_0:nodeByName("detail_bg"):setContentSize(arg_4_0:nodeByName("detail_bg"):getContentSize().width, arg_4_0:nodeByName("detail_bg"):getContentSize().height - 50)
	elseif arg_4_1.itemType == "ENERGY" then
		local var_4_22 = {}

		if var_4_3 ~= 0 then
			var_4_22.energy = var_4_3
		end

		if var_4_1 ~= 0 then
			var_4_22.dust = var_4_1
		end

		if var_4_2 ~= 0 then
			var_4_22.liquid = var_4_2
		end

		local var_4_23 = 1

		for iter_4_2, iter_4_3 in pairs(var_4_22) do
			local var_4_24 = cc.Sprite:create("images/icon/eco/magic_" .. iter_4_2 .. "_small.png")

			arg_4_0:nodeByName("node" .. var_4_23):addChild(var_4_24)
			var_4_24:setPosition(cc.p(0, 0))
			arg_4_0:nodeByName("txt_" .. var_4_23):setString(iter_4_3)

			var_4_23 = var_4_23 + 1
		end

		if var_4_23 <= 3 then
			arg_4_0:nodeByName("btn_sell"):setPositionY(arg_4_0:nodeByName("btn_sell"):getPositionY() + 50)
			arg_4_0:nodeByName("detail_bg"):setPositionY(arg_4_0:nodeByName("detail_bg"):getPositionY() + 25)
			arg_4_0:nodeByName("detail_bg"):setContentSize(arg_4_0:nodeByName("detail_bg"):getContentSize().width, arg_4_0:nodeByName("detail_bg"):getContentSize().height - 50)
		end
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
	arg_5_0:nodeByName(var_0_0.SELL_BUTTON):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_5_1.itemType == "MANA" then
				arg_5_0.player_:sellItems(arg_5_1, function(arg_7_0)
					if arg_7_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow("sell")
					end
				end)
			elseif arg_5_1.itemType == "ENERGY" then
				arg_5_0.player_:useMagicItems(arg_5_1, function(arg_8_0)
					if arg_8_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow("sell")
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.REFRESH_MAGIC_RES
						})
					end
				end)
			end
		end
	end)
end

return var_0_0
