local var_0_0 = class("ShopBuyDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")

var_0_0.ICON = "icon"
var_0_0.TXT_NAME = "txt_name"
var_0_0.TXT_HAS = "txt_has"
var_0_0.SELL_LABEL = "sell_label"
var_0_0.SELL_PRICE = "sell_price"
var_0_0.SELL_NUM_LABEL = "sell_num_label"
var_0_0.TXT_NUM = "txt_num"
var_0_0.TXT_MAX = "txt_max"
var_0_0.TOTAL_LABEL = "total_label"
var_0_0.TOTAL_PRICE = "total_price"
var_0_0.TXT_SELL = "txt_sell"
var_0_0.IMG_CURRENCY1 = "img_currency1"
var_0_0.IMG_CURRENCY2 = "img_currency2"
var_0_0.DECREASE_BUTTON = "decrease_button"
var_0_0.INCREASE_BUTTON = "increase_button"
var_0_0.MAX_BUTTON = "max_button"
var_0_0.SELL_BUTTON = "sell_button"

local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.params = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.imgIcon = arg_2_0:nodeByName(var_0_0.ICON)

	arg_2_0.imgIcon:removeAllChildren()

	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.shop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_2_0.backpack_ = arg_2_0.player_:getBackpack()
	arg_2_0.currentNum = 1
	arg_2_0.handler = {}

	arg_2_0:layout()
	arg_2_0:initChatBox()
end

function var_0_0.layout(arg_3_0)
	xyd.setItemBorder(arg_3_0.imgIcon, arg_3_0.itemID)

	local var_3_0 = xyd.tables.item:name(arg_3_0.itemID)

	arg_3_0:nodeByName(var_0_0.TXT_NAME):setString(var_3_0)
	arg_3_0:nodeByName("has_txt"):setString(var_0_2:translation("ITEM_OWN"))
	arg_3_0:nodeByName("jian_txt"):setString(var_0_2:translation("ITEM_OWN_SUFFIX"))

	local var_3_1 = arg_3_0.backpack_:getItemNumByID(arg_3_0.itemID)

	arg_3_0:nodeByName("num_txt"):setString(tostring(var_3_1))

	local var_3_2, var_3_3 = arg_3_0:nodeByName("num_txt"):getPosition()

	arg_3_0:nodeByName("jian_txt"):x(var_3_2 + arg_3_0:nodeByName("num_txt"):getContentSize().width + 5)
	arg_3_0:nodeByName(var_0_0.SELL_NUM_LABEL):setString(var_0_2:translation("SELL_NUM"))
	arg_3_0:nodeByName(var_0_0.SELL_LABEL):setString(var_0_2:translation("SHOP_BUY_PRICE"))
	arg_3_0:nodeByName(var_0_0.TOTAL_LABEL):setString(var_0_2:translation("SHOP_BUY_TOTAL_PRICE"))
	arg_3_0:nodeByName(var_0_0.TXT_MAX):setString(var_0_2:translation("MAX"))
	arg_3_0:nodeByName(var_0_0.SELL_PRICE):setString(arg_3_0.params.sellPrice)

	local var_3_4
	local var_3_5
	local var_3_6 = xyd.tables.ecoType:getEcoPathByID(39)
	local var_3_7 = xyd.AssetLoader:get():loadSprite(var_3_6)
	local var_3_8 = xyd.AssetLoader:get():loadSprite(var_3_6)

	arg_3_0:nodeByName(var_0_0.IMG_CURRENCY1):removeAllChildren()

	if var_3_7 then
		xyd.displaySpriteOnContainer(var_3_7, arg_3_0:nodeByName(var_0_0.IMG_CURRENCY1), false)
	end

	arg_3_0:nodeByName(var_0_0.IMG_CURRENCY2):removeAllChildren()

	if var_3_8 then
		xyd.displaySpriteOnContainer(var_3_8, arg_3_0:nodeByName(var_0_0.IMG_CURRENCY2), false)
	end

	arg_3_0:nodeByName("sell"):setVisible(true)
	arg_3_0:nodeByName("sell"):setString(var_0_2:translation("SHOP_SURE_BUY_TEXT"))
	arg_3_0:nodeByName("sure_decompose_text"):setVisible(false)

	local var_3_9 = arg_3_0.player_.tutorCoin
	local var_3_10 = xyd.tables.shop:limitTimes(arg_3_0.params.shopType)[arg_3_0.params.index] - arg_3_0.params.buyTimes
	local var_3_11 = arg_3_0.backpack_:getItemNumByID(arg_3_0.itemID)
	local var_3_12 = xyd.tables.item:stack(arg_3_0.itemID)

	if var_3_12 > 0 then
		var_3_10 = math.min(var_3_10, var_3_12 - var_3_11)
	end

	arg_3_0.totalNum = math.min(math.floor(arg_3_0.player_.tutorCoin / arg_3_0.params.sellPrice), var_3_10)
	arg_3_0.currentNum = math.min(arg_3_0.currentNum, arg_3_0.totalNum)

	arg_3_0:updateNum()
end

function var_0_0.buy(arg_4_0)
	if arg_4_0.currentNum <= 0 then
		return
	end

	local var_4_0 = {
		index = arg_4_0.params.index,
		shop_type = arg_4_0.params.shopType,
		num = arg_4_0.currentNum
	}

	if arg_4_0.shopType == xyd.ShopType.MAGIC then
		var_4_0.client_price = arg_4_0.sellPrice
	end

	arg_4_0.shop_:buy(var_4_0, function(arg_5_0)
		if arg_5_0 == xyd.error.OK then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.SHOP_DIALOG,
				messageType = xyd.ShopMessageType.BUY
			})

			if arg_4_0.shopType == xyd.ShopType.SKIN and arg_4_0.backpack_:getItemNumByID(xyd.tables.misc.skinTicketId) > 0 then
				local var_5_0 = {
					itemID = xyd.tables.misc.skinTicketId
				}

				var_5_0.itemNum = 1

				arg_4_0.backpack_:removeItem(var_5_0)
			end

			if arg_4_0.shopType == xyd.ShopType.SKIN or arg_4_0.shopType == xyd.ShopType.ULTRA_SKIN then
				local var_5_1 = xyd.WindowManager.get():getWindow("skin_shop")

				if var_5_1 then
					var_5_1.shopList:refreshList()
				end
			end

			if arg_4_0.shopType == xyd.ShopType.MAGIC then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.REFRESH_MAGIC_GIFT
				})
			end

			if arg_4_0.shopType == xyd.ShopType.COURSE then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.REFRESH_COURSE_BOOK
				})
			end

			xyd.WindowManager.get():closeWindow(arg_4_0.name or "shop_detail_window")
			xyd.WindowManager.get():closeWindow("skin_shop_detail_window")
		end
	end)
end

function var_0_0.isCanResolveRoomKey(arg_6_0, arg_6_1)
	return xyd.isInTable(xyd.tables.misc.houseKeyBlueId, arg_6_1) or xyd.isInTable(xyd.tables.misc.housekeyGreenId, arg_6_1)
end

function var_0_0.updateNum(arg_7_0)
	arg_7_0:nodeByName(var_0_0.TXT_NUM):setString(arg_7_0.currentNum .. "/" .. arg_7_0.totalNum)
	arg_7_0:nodeByName(var_0_0.TOTAL_PRICE):setString(arg_7_0.currentNum * arg_7_0.params.sellPrice)
end

function var_0_0.addCurrentNum(arg_8_0)
	if arg_8_0.currentNum + 1 >= arg_8_0.totalNum then
		arg_8_0.currentNum = arg_8_0.totalNum
	else
		arg_8_0.currentNum = arg_8_0.currentNum + 1
	end

	arg_8_0:nodeByName(var_0_0.TXT_NUM):setString(arg_8_0.currentNum .. "/" .. arg_8_0.totalNum)
	arg_8_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_9_0)
	if arg_9_0.currentNum - 1 <= 0 then
		arg_9_0.currentNum = 1
	else
		arg_9_0.currentNum = arg_9_0.currentNum - 1
	end

	arg_9_0.currentNum = math.min(arg_9_0.currentNum, arg_9_0.totalNum)

	arg_9_0:nodeByName(var_0_0.TXT_NUM):setString(arg_9_0.currentNum .. "/" .. arg_9_0.totalNum)
	arg_9_0:updateNum()
end

function var_0_0.didOpen(arg_10_0)
	arg_10_0:addBlockLayer()

	local var_10_0 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_10_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_10_0:setScale(1, 1)
	var_10_0:addTo(arg_10_0:nodeByName(var_0_0.DECREASE_BUTTON))
	var_10_0:setName("jiandian")

	local var_10_1 = false

	var_10_0:onButtonPressed(function(arg_11_0)
		var_10_0:setScale(0.9)

		local var_11_0 = 0

		local function var_11_1()
			var_11_0 = var_11_0 + 0.03

			if arg_10_0.decreaseCurrentNum then
				arg_10_0:decreaseCurrentNum()
			end
		end

		local function var_11_2()
			var_11_0 = var_11_0 + 0.1

			if var_11_0 > 0.5 and var_11_0 <= 4 then
				var_10_1 = true

				if arg_10_0.decreaseCurrentNum then
					arg_10_0:decreaseCurrentNum()
				end
			elseif var_11_0 > 4 then
				arg_10_0.handler[2] = var_0_1.scheduleGlobal(var_11_1, 0.03)

				var_0_1.unscheduleGlobal(arg_10_0.handler[1])
			else
				var_10_1 = false
			end
		end

		var_10_1 = false
		arg_10_0.handler[1] = var_0_1.scheduleGlobal(var_11_2, 0.1)
	end)
	var_10_0:onButtonRelease(function(arg_14_0)
		var_10_0:setScale(1)

		if arg_10_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_10_0.handler[1])
		end

		if arg_10_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_10_0.handler[2])
		end

		if var_10_1 == false and arg_10_0.decreaseCurrentNum then
			arg_10_0:decreaseCurrentNum()
		end
	end)

	local var_10_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_10_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_10_2:setScale(1, 1)
	var_10_2:addTo(arg_10_0:nodeByName(var_0_0.INCREASE_BUTTON))
	var_10_2:setName("jiadian")

	local var_10_3 = false

	var_10_2:onButtonPressed(function(arg_15_0)
		var_10_2:setScale(0.9)

		local var_15_0 = 0

		local function var_15_1()
			var_15_0 = var_15_0 + 0.03

			if arg_10_0.addCurrentNum then
				arg_10_0:addCurrentNum()
			end
		end

		local function var_15_2()
			var_15_0 = var_15_0 + 0.1

			if var_15_0 > 0.5 and var_15_0 <= 4 then
				var_10_3 = true

				if arg_10_0.addCurrentNum then
					arg_10_0:addCurrentNum()
				end
			elseif var_15_0 > 4 then
				arg_10_0.handler[2] = var_0_1.scheduleGlobal(var_15_1, 0.03)

				var_0_1.unscheduleGlobal(arg_10_0.handler[1])
			else
				var_10_3 = false
			end
		end

		var_10_3 = false
		arg_10_0.handler[1] = var_0_1.scheduleGlobal(var_15_2, 0.1)
	end)
	var_10_2:onButtonRelease(function(arg_18_0)
		var_10_2:setScale(1)

		if arg_10_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_10_0.handler[1])
		end

		if arg_10_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_10_0.handler[2])
		end

		if var_10_3 == false and arg_10_0.addCurrentNum then
			arg_10_0:addCurrentNum()
		end
	end)
	arg_10_0:nodeByName(var_0_0.MAX_BUTTON):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName(var_0_0.MAX_BUTTON), arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_10_0.currentNum = arg_10_0.totalNum

			arg_10_0:updateNum()
		end
	end)
	arg_10_0:nodeByName(var_0_0.SELL_BUTTON):addTouchEventListener(function(arg_20_0, arg_20_1)
		xyd.buttonScaleAnim(arg_10_0:nodeByName(var_0_0.SELL_BUTTON), arg_20_1)

		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_10_0:buy()
		end
	end)
end

function var_0_0.didClose(arg_21_0)
	if arg_21_0.handler then
		if arg_21_0.handler[1] then
			var_0_1.unscheduleGlobal(arg_21_0.handler[1])
		end

		if arg_21_0.handler[2] then
			var_0_1.unscheduleGlobal(arg_21_0.handler[2])
		end
	end
end

function var_0_0.initChatBox(arg_22_0)
	local var_22_0 = xyd.AssetLoader.get()
	local var_22_1 = 24
	local var_22_2 = arg_22_0:nodeByName("num_panel")
	local var_22_3 = "windows/login/transparent.png"
	local var_22_4 = var_22_0:loadSprite(var_22_3)

	arg_22_0.chatBox_ = ccui.EditBox:create(var_22_2:getContentSize(), var_22_3)

	arg_22_0.chatBox_:setAnchorPoint(0, 0)
	arg_22_0.chatBox_:pos(0, 0):addTo(var_22_2)
	arg_22_0.chatBox_:setFont(var_22_0.FONT_NAME, var_22_1)
	arg_22_0.chatBox_:setPlaceholderFont(var_22_0.FONT_NAME, var_22_1)
	arg_22_0.chatBox_:setPlaceHolder(var_0_2:translation("CHAT_INPUT_MESSAGE"))
	arg_22_0.chatBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_22_0.chatBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_22_0.chatBox_:registerScriptEditBoxHandler(handler(arg_22_0, arg_22_0.inputboxEventHandler))
	arg_22_0.chatBox_:setInputFlag(3)
end

function var_0_0.inputboxEventHandler(arg_23_0, arg_23_1)
	if arg_23_1 == "return" then
		local var_23_0 = arg_23_0.chatBox_:getText()

		arg_23_0.chatBox_:setText("")

		local var_23_1 = xyd.getTextLen(var_23_0)
		local var_23_2 = math.floor(tonumber(var_23_0) or 0)

		if var_23_0 ~= "" then
			if var_23_2 then
				if var_23_2 <= arg_23_0.totalNum and var_23_2 > 0 then
					arg_23_0.currentNum = var_23_2

					arg_23_0:nodeByName(var_0_0.TXT_NUM):setString(arg_23_0.currentNum .. "/" .. arg_23_0.totalNum)
					arg_23_0:updateNum()
				else
					local var_23_3 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_23_3
					})

					return
				end

				return
			else
				local var_23_4 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_23_4
				})

				return
			end
		else
			return
		end
	elseif arg_23_1 == "began" then
		arg_23_0.chatBox_:setText("")
	end
end

return var_0_0
