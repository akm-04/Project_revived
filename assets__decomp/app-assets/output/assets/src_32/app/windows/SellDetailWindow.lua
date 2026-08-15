local var_0_0 = class("SellDetailWindow", import("app.common.ui.BaseWindow"))
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
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.imgIcon = arg_2_0:nodeByName(var_0_0.ICON)

	arg_2_0.imgIcon:removeAllChildren()

	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.currentNum = 1
	arg_2_0.itemType = xyd.tables.item:type(arg_2_0.itemID)
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

	local var_3_1 = arg_3_0.player_:getBackpack():getItemNumByID(arg_3_0.itemID)

	arg_3_0:nodeByName("num_txt"):setString(tostring(var_3_1))

	local var_3_2, var_3_3 = arg_3_0:nodeByName("num_txt"):getPosition()

	arg_3_0:nodeByName("jian_txt"):x(var_3_2 + arg_3_0:nodeByName("num_txt"):getContentSize().width + 5)
	arg_3_0:nodeByName(var_0_0.SELL_NUM_LABEL):setString(var_0_2:translation("SELL_NUM"))
	arg_3_0:nodeByName(var_0_0.SELL_LABEL):setString(var_0_2:translation("SELL_UNIT_PRICE"))
	arg_3_0:nodeByName(var_0_0.TOTAL_LABEL):setString(var_0_2:translation("SELL_TOTAL_PRICE"))
	arg_3_0:nodeByName(var_0_0.TXT_MAX):setString(var_0_2:translation("MAX"))

	arg_3_0.unitPrice = xyd.tables.item:mana(arg_3_0.itemID)

	local var_3_4 = false

	if arg_3_0.unitPrice == 0 and xyd.tables.item:crystal(arg_3_0.itemID) ~= 0 then
		arg_3_0.unitPrice = xyd.tables.item:crystal(arg_3_0.itemID)
		var_3_4 = true
	end

	arg_3_0:nodeByName(var_0_0.SELL_PRICE):setString(arg_3_0.unitPrice)

	local var_3_5
	local var_3_6

	if not var_3_4 then
		var_3_5 = xyd.AssetLoader:get():loadSprite("windows/common/jinbi1.png")
		var_3_6 = xyd.AssetLoader:get():loadSprite("windows/common/jinbi1.png")
	else
		var_3_5 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
		var_3_6 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
	end

	arg_3_0:nodeByName(var_0_0.IMG_CURRENCY1):removeAllChildren()

	if var_3_5 then
		xyd.displaySpriteOnContainer(var_3_5, arg_3_0:nodeByName(var_0_0.IMG_CURRENCY1), false)
	end

	arg_3_0:nodeByName(var_0_0.IMG_CURRENCY2):removeAllChildren()

	if var_3_6 then
		xyd.displaySpriteOnContainer(var_3_6, arg_3_0:nodeByName(var_0_0.IMG_CURRENCY2), false)
	end

	if arg_3_0.itemType == xyd.ItemType.INSCRIPTION then
		arg_3_0:nodeByName("sell"):setVisible(false)
		arg_3_0:nodeByName("sure_decompose_text"):setVisible(true)
		arg_3_0:nodeByName(var_0_0.IMG_CURRENCY1):removeAllChildren()
		arg_3_0:nodeByName(var_0_0.IMG_CURRENCY2):removeAllChildren()

		local var_3_7 = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
		local var_3_8 = xyd.tables.item:inscriptId(arg_3_0.itemID)

		arg_3_0.unitPrice = xyd.tables.inscription:resolveNum(var_3_8)

		local var_3_9 = var_3_7:getMaterialIcon(xyd.tables.inscription:resolveMaterial(var_3_8))
		local var_3_10 = var_3_7:getMaterialIcon(xyd.tables.inscription:resolveMaterial(var_3_8))

		xyd.displaySpriteOnContainer(var_3_9, arg_3_0:nodeByName(var_0_0.IMG_CURRENCY1), false)
		xyd.displaySpriteOnContainer(var_3_10, arg_3_0:nodeByName(var_0_0.IMG_CURRENCY2), false)
		arg_3_0:nodeByName(var_0_0.SELL_PRICE):setString(arg_3_0.unitPrice)
		arg_3_0:nodeByName(var_0_0.SELL_LABEL):setString(var_0_2:translation("RESOLVE_INSCRIOPTION_TXT1"))
		arg_3_0:nodeByName(var_0_0.TOTAL_LABEL):setString(var_0_2:translation("RESOLVE_INSCRIOPTION_TXT2"))
	elseif arg_3_0:isCanResolveRoomKey(arg_3_0.itemID) then
		arg_3_0:nodeByName("sell"):setVisible(false)
		arg_3_0:nodeByName("sure_decompose_text"):setVisible(true)
		arg_3_0:nodeByName(var_0_0.IMG_CURRENCY1):removeAllChildren()
		arg_3_0:nodeByName(var_0_0.IMG_CURRENCY2):removeAllChildren()

		if xyd.isInTable(xyd.tables.misc.houseKeyBlueId, arg_3_0.itemID) then
			arg_3_0.unitPrice = xyd.tables.misc.houseKeyBlue
		else
			arg_3_0.unitPrice = xyd.tables.misc.houseKeyGreen
		end

		local var_3_11 = xyd.AssetLoader:get():loadSprite("windows/dorm/expand/cement.png")
		local var_3_12 = xyd.AssetLoader:get():loadSprite("windows/dorm/expand/cement.png")

		var_3_11:setScale(0.5)
		var_3_12:setScale(0.5)
		xyd.displaySpriteOnContainer(var_3_11, arg_3_0:nodeByName(var_0_0.IMG_CURRENCY1), false)
		xyd.displaySpriteOnContainer(var_3_12, arg_3_0:nodeByName(var_0_0.IMG_CURRENCY2), false)
		arg_3_0:nodeByName(var_0_0.SELL_PRICE):setString(arg_3_0.unitPrice)
		arg_3_0:nodeByName(var_0_0.SELL_LABEL):setString(var_0_2:translation("RESOLVE_INSCRIOPTION_TXT1"))
		arg_3_0:nodeByName(var_0_0.TOTAL_LABEL):setString(var_0_2:translation("RESOLVE_INSCRIOPTION_TXT2"))
	else
		arg_3_0:nodeByName("sell"):setVisible(true)
		arg_3_0:nodeByName("sure_decompose_text"):setVisible(false)
	end

	arg_3_0.totalNum = arg_3_0.player_:getBackpack():getItemNumByID(arg_3_0.itemID)

	arg_3_0:updateNum()
end

function var_0_0.isCanResolveRoomKey(arg_4_0, arg_4_1)
	return xyd.isInTable(xyd.tables.misc.houseKeyBlueId, arg_4_1) or xyd.isInTable(xyd.tables.misc.housekeyGreenId, arg_4_1)
end

function var_0_0.updateNum(arg_5_0)
	arg_5_0:nodeByName(var_0_0.TXT_NUM):setString(arg_5_0.currentNum .. "/" .. arg_5_0.totalNum)
	arg_5_0:nodeByName(var_0_0.TOTAL_PRICE):setString(arg_5_0.currentNum * arg_5_0.unitPrice)
end

function var_0_0.addCurrentNum(arg_6_0)
	if arg_6_0.currentNum + 1 >= arg_6_0.totalNum then
		arg_6_0.currentNum = arg_6_0.totalNum
	else
		arg_6_0.currentNum = arg_6_0.currentNum + 1
	end

	arg_6_0:nodeByName(var_0_0.TXT_NUM):setString(arg_6_0.currentNum .. "/" .. arg_6_0.totalNum)
	arg_6_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_7_0)
	if arg_7_0.currentNum - 1 <= 0 then
		arg_7_0.currentNum = 1
	else
		arg_7_0.currentNum = arg_7_0.currentNum - 1
	end

	arg_7_0:nodeByName(var_0_0.TXT_NUM):setString(arg_7_0.currentNum .. "/" .. arg_7_0.totalNum)
	arg_7_0:updateNum()
end

function var_0_0.didOpen(arg_8_0)
	arg_8_0:addBlockLayer()

	local var_8_0 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_8_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_0:setScale(1, 1)
	var_8_0:addTo(arg_8_0:nodeByName(var_0_0.DECREASE_BUTTON))
	var_8_0:setName("jiandian")

	local var_8_1 = false

	var_8_0:onButtonPressed(function(arg_9_0)
		var_8_0:setScale(0.9)

		local var_9_0 = 0

		local function var_9_1()
			var_9_0 = var_9_0 + 0.03

			if arg_8_0.decreaseCurrentNum then
				arg_8_0:decreaseCurrentNum()
			end
		end

		local function var_9_2()
			var_9_0 = var_9_0 + 0.1

			if var_9_0 > 0.5 and var_9_0 <= 4 then
				var_8_1 = true

				if arg_8_0.decreaseCurrentNum then
					arg_8_0:decreaseCurrentNum()
				end
			elseif var_9_0 > 4 then
				arg_8_0.handler[2] = var_0_1.scheduleGlobal(var_9_1, 0.03)

				var_0_1.unscheduleGlobal(arg_8_0.handler[1])
			else
				var_8_1 = false
			end
		end

		var_8_1 = false
		arg_8_0.handler[1] = var_0_1.scheduleGlobal(var_9_2, 0.1)
	end)
	var_8_0:onButtonRelease(function(arg_12_0)
		var_8_0:setScale(1)

		if arg_8_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[1])
		end

		if arg_8_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[2])
		end

		if var_8_1 == false and arg_8_0.decreaseCurrentNum then
			arg_8_0:decreaseCurrentNum()
		end
	end)

	local var_8_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_8_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_2:setScale(1, 1)
	var_8_2:addTo(arg_8_0:nodeByName(var_0_0.INCREASE_BUTTON))
	var_8_2:setName("jiadian")

	local var_8_3 = false

	var_8_2:onButtonPressed(function(arg_13_0)
		var_8_2:setScale(0.9)

		local var_13_0 = 0

		local function var_13_1()
			var_13_0 = var_13_0 + 0.03

			if arg_8_0.addCurrentNum then
				arg_8_0:addCurrentNum()
			end
		end

		local function var_13_2()
			var_13_0 = var_13_0 + 0.1

			if var_13_0 > 0.5 and var_13_0 <= 4 then
				var_8_3 = true

				if arg_8_0.addCurrentNum then
					arg_8_0:addCurrentNum()
				end
			elseif var_13_0 > 4 then
				arg_8_0.handler[2] = var_0_1.scheduleGlobal(var_13_1, 0.03)

				var_0_1.unscheduleGlobal(arg_8_0.handler[1])
			else
				var_8_3 = false
			end
		end

		var_8_3 = false
		arg_8_0.handler[1] = var_0_1.scheduleGlobal(var_13_2, 0.1)
	end)
	var_8_2:onButtonRelease(function(arg_16_0)
		var_8_2:setScale(1)

		if arg_8_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[1])
		end

		if arg_8_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[2])
		end

		if var_8_3 == false and arg_8_0.addCurrentNum then
			arg_8_0:addCurrentNum()
		end
	end)
	arg_8_0:nodeByName(var_0_0.MAX_BUTTON):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName(var_0_0.MAX_BUTTON), arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_8_0.currentNum = arg_8_0.totalNum

			arg_8_0:updateNum()
		end
	end)
	arg_8_0:nodeByName(var_0_0.SELL_BUTTON):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName(var_0_0.SELL_BUTTON), arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_18_0()
				if not arg_8_0 or tolua.isnull(arg_8_0) then
					return
				end

				if arg_8_0.itemType == xyd.ItemType.INSCRIPTION then
					local var_19_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
					local var_19_1 = {
						item_id = arg_8_0.itemID,
						resolve_num = arg_8_0.currentNum
					}

					var_19_0:resolve(var_19_1, function(arg_20_0, arg_20_1)
						if arg_20_0 == xyd.error.OK then
							local var_20_0 = xyd.WindowManager.get():getWindow("backpack")

							if var_20_0 and not tolua.isnull(var_20_0) then
								var_20_0:updateItemDetail(arg_8_0.itemID)
								var_20_0:refreshDisplayOptionAfterSell()
							end

							local var_20_1 = xyd.WindowManager.get():getWindow("equipment_backpack")

							if var_20_1 and not tolua.isnull(var_20_1) then
								var_20_1:updateItemDetail(arg_8_0.itemID)
								var_20_1:refreshDisplayOptionAfterSell()
							end

							xyd.WindowManager.get():closeWindow(arg_8_0.name)
						end
					end)
				elseif arg_8_0:isCanResolveRoomKey(arg_8_0.itemID) then
					local var_19_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
					local var_19_3 = {
						item_id = arg_8_0.itemID,
						item_num = arg_8_0.currentNum
					}

					var_19_2:exchangeDormKey(var_19_3, function(arg_21_0, arg_21_1)
						if arg_21_0 == xyd.error.OK then
							local var_21_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

							if arg_21_1.awards then
								var_21_0:handleRewards(arg_21_1.awards)
							end

							xyd.EventDispatcher.get():dispatchEvent({
								name = xyd.event.SELL_DORM_KEY_EVENT
							})

							local var_21_1 = xyd.WindowManager.get():getWindow("backpack")

							if var_21_1 and not tolua.isnull(var_21_1) then
								var_21_1:updateItemDetail(arg_8_0.itemID)
								var_21_1:refreshDisplayOptionAfterSell()
							end

							local var_21_2 = xyd.WindowManager.get():getWindow("equipment_backpack")

							if var_21_2 and not tolua.isnull(var_21_2) then
								var_21_2:updateItemDetail(arg_8_0.itemID)
								var_21_2:refreshDisplayOptionAfterSell()
							end

							xyd.WindowManager.get():closeWindow(arg_8_0.name)
						end
					end)
				else
					arg_8_0.player_:sellItem({
						item_id = arg_8_0.itemID,
						item_num = arg_8_0.currentNum
					}, function(arg_22_0)
						if arg_22_0 == xyd.error.OK then
							local var_22_0 = xyd.WindowManager.get():getWindow("backpack")

							if var_22_0 and not tolua.isnull(var_22_0) then
								var_22_0:updateItemDetail(arg_8_0.itemID)
								var_22_0:refreshDisplayOptionAfterSell()
							end

							local var_22_1 = xyd.WindowManager.get():getWindow("equipment_backpack")

							if var_22_1 and not tolua.isnull(var_22_1) then
								var_22_1:updateItemDetail(arg_8_0.itemID)
								var_22_1:refreshDisplayOptionAfterSell()
							end

							xyd.WindowManager.get():closeWindow(arg_8_0.name)
						end
					end)
				end
			end

			local var_18_1 = {
				rcallBefore = 0,
				title = var_0_2:translation("TIP"),
				txt = var_0_2:translation("SELL_CONFIRM_AGAIN"),
				rcallback = var_18_0
			}

			xyd.WindowManager.get():openWindow("alert_green", var_18_1)
		end
	end)
end

function var_0_0.didClose(arg_23_0)
	if arg_23_0.handler then
		if arg_23_0.handler[1] then
			var_0_1.unscheduleGlobal(arg_23_0.handler[1])
		end

		if arg_23_0.handler[2] then
			var_0_1.unscheduleGlobal(arg_23_0.handler[2])
		end
	end
end

function var_0_0.initChatBox(arg_24_0)
	local var_24_0 = xyd.AssetLoader.get()
	local var_24_1 = 24
	local var_24_2 = arg_24_0:nodeByName("num_panel")
	local var_24_3 = "windows/login/transparent.png"
	local var_24_4 = var_24_0:loadSprite(var_24_3)

	arg_24_0.chatBox_ = ccui.EditBox:create(var_24_2:getContentSize(), var_24_3)

	arg_24_0.chatBox_:setAnchorPoint(0, 0)
	arg_24_0.chatBox_:pos(0, 0):addTo(var_24_2)
	arg_24_0.chatBox_:setFont(var_24_0.FONT_NAME, var_24_1)
	arg_24_0.chatBox_:setPlaceholderFont(var_24_0.FONT_NAME, var_24_1)
	arg_24_0.chatBox_:setPlaceHolder(var_0_2:translation("CHAT_INPUT_MESSAGE"))
	arg_24_0.chatBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_24_0.chatBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_24_0.chatBox_:registerScriptEditBoxHandler(handler(arg_24_0, arg_24_0.inputboxEventHandler))
	arg_24_0.chatBox_:setInputFlag(3)
end

function var_0_0.inputboxEventHandler(arg_25_0, arg_25_1)
	if arg_25_1 == "return" then
		local var_25_0 = arg_25_0.chatBox_:getText()

		arg_25_0.chatBox_:setText("")

		local var_25_1 = xyd.getTextLen(var_25_0)
		local var_25_2 = math.floor(tonumber(var_25_0) or 0)

		arg_25_0:nodeByName("txt_num"):setVisible(true)

		if var_25_0 ~= "" then
			if var_25_2 then
				if var_25_2 <= arg_25_0.totalNum and var_25_2 > 0 then
					arg_25_0.currentNum = var_25_2

					arg_25_0:nodeByName(var_0_0.TXT_NUM):setString(arg_25_0.currentNum .. "/" .. arg_25_0.totalNum)
					arg_25_0:updateNum()
				else
					local var_25_3 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_25_3
					})

					return
				end

				return
			else
				local var_25_4 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_25_4
				})

				return
			end
		else
			return
		end
	elseif arg_25_1 == "began" then
		arg_25_0.chatBox_:setText("")
		arg_25_0:nodeByName("txt_num"):setVisible(false)
	end
end

return var_0_0
