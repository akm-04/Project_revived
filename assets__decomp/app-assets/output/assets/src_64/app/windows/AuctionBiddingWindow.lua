local var_0_0 = class("BiddingItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/auction_room/bidding_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	arg_4_0:contentView():nodeByName("date"):setString(xyd.date("%c", arg_4_1.time))

	local var_4_0 = string.format(var_0_1:translation("AUCTION_OFFER_TIPS5"), arg_4_1.region, arg_4_1.player_name, tonumber(arg_4_1.price))
	local var_4_1 = xyd.createMultiColorTxt(var_4_0, xyd.color.WHITE, 22)

	var_4_1:setAnchorPoint(0, 0.5)
	var_4_1:setPosition(arg_4_0:contentView():nodeByName("text_node"):getPosition())
	var_4_1:addTo(arg_4_0)
end

local var_0_2 = class("AuctionBiddingWindow", import("app.common.ui.BaseWindow"))
local var_0_3 = xyd.tables.translation
local var_0_4 = import("framework.scheduler")
local var_0_5 = xyd.tables.item
local var_0_6 = xyd.AssetLoader.get()
local var_0_7 = 1
local var_0_8 = 2
local var_0_9 = 24
local var_0_10 = 1.01

function var_0_2.ctor(arg_5_0, arg_5_1, arg_5_2)
	var_0_2.super.ctor(arg_5_0, arg_5_1, arg_5_2)

	arg_5_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_5_0.auction = xyd.ModelManager.get():loadModel(xyd.ModelType.AUCTION)
	arg_5_0.auctionType = arg_5_2.auction_type
	arg_5_0.itemPos = arg_5_2.item_pos
	arg_5_0.auctionInfo = arg_5_2.auction_info
	arg_5_0.myPrice = math.ceil(arg_5_0.auctionInfo.now_price * var_0_10) or 0
	arg_5_0.biddingInfos = arg_5_2.bidding_infos
end

function var_0_2.willOpen(arg_6_0, arg_6_1)
	arg_6_0:nodeByName("txt_confirm"):setString(var_0_1:translation("SURE"))
	arg_6_0:nodeByName("confirm_gray"):setString(var_0_1:translation("SURE"))
	arg_6_0:nodeByName("txt_cancel"):setString(var_0_1:translation("CANCEL"))
	var_0_2.super:willOpen(arg_6_0, arg_6_1)
end

function var_0_2.didOpen(arg_7_0, arg_7_1)
	var_0_2.super:didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayer()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.AUCTION_REFRESH, function(arg_8_0)
		arg_7_0.auctionInfo = arg_7_0.auction.auctionList[arg_7_0.itemPos]
		arg_7_0.myPrice = math.ceil(arg_7_0.auctionInfo.now_price * var_0_10) or 0

		arg_7_0:layout()
	end)
	arg_7_0:layout()
end

function var_0_2.layout(arg_9_0)
	arg_9_0:nodeByName("title"):setString(var_0_1:translation("AUCTION_BIDDING_TITLE"))
	arg_9_0:nodeByName("no_auction_tips"):setString(var_0_1:translation("AUCTION_BIDDING_NO_AUCTION"))
	arg_9_0:nodeByName("highest_price"):setString(arg_9_0.auctionInfo.now_price)
	arg_9_0:nodeByName("highest_label"):setString(var_0_1:translation("AUCTION_OFFER_MAX"))
	arg_9_0:nodeByName("my_price_label"):setString(var_0_1:translation("AUCTION_MY_OFFER"))

	if arg_9_0.auctionInfo.now_buyer == 0 then
		arg_9_0:nodeByName("highest_name"):setString(var_0_1:translation("AUCTION_START_OFFER"))
	else
		arg_9_0:nodeByName("highest_name"):setString(arg_9_0.auctionInfo.buyer_info.player_name)
	end

	arg_9_0:nodeByName("yuanbao1"):removeAllChildren()
	arg_9_0:nodeByName("yuanbao2"):removeAllChildren()

	if arg_9_0.auctionInfo.is_done == 1 then
		arg_9_0:nodeByName("confirm_btn"):setBright(false)
		arg_9_0:nodeByName("confirm_btn"):setTouchEnabled(false)
		arg_9_0:nodeByName("refresh_btn"):setBright(false)
		arg_9_0:nodeByName("refresh_btn"):setTouchEnabled(false)
		arg_9_0:nodeByName("confirm_gray"):setVisible(true)
		arg_9_0:nodeByName("txt_confirm"):setVisible(false)
	else
		arg_9_0:nodeByName("confirm_btn"):setBright(true)
		arg_9_0:nodeByName("confirm_btn"):setTouchEnabled(true)
		arg_9_0:nodeByName("refresh_btn"):setBright(true)
		arg_9_0:nodeByName("refresh_btn"):setTouchEnabled(true)
		arg_9_0:nodeByName("confirm_gray"):setVisible(false)
		arg_9_0:nodeByName("txt_confirm"):setVisible(true)
	end

	local var_9_0
	local var_9_1

	if arg_9_0.auctionInfo.currency_type == xyd.currencyType.MANA then
		var_9_0 = xyd.AssetLoader:get():loadSprite("images/jinbi.png")
		var_9_1 = xyd.AssetLoader:get():loadSprite("images/jinbi.png")
	elseif arg_9_0.auctionInfo.currency_type == xyd.currencyType.CRYSTAL then
		var_9_0 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
		var_9_1 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
	end

	var_9_0:setScale(0.8)
	var_9_1:setScale(0.8)
	xyd.displaySpriteOnContainer(var_9_0, arg_9_0:nodeByName("yuanbao1"), false)
	xyd.displaySpriteOnContainer(var_9_1, arg_9_0:nodeByName("yuanbao2"), false)
	arg_9_0:nodeByName("my_price"):setString(tostring(arg_9_0.myPrice))

	local var_9_2 = false

	arg_9_0:nodeByName("minus_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.began then
			local var_10_0 = 0

			local function var_10_1()
				var_10_0 = var_10_0 + 0.01

				if var_10_0 > 0.1 then
					if not var_9_2 then
						var_9_2 = true
					end

					arg_9_0.myPrice = arg_9_0.myPrice - 1

					if arg_9_0.myPrice < math.ceil(arg_9_0.auctionInfo.now_price * var_0_10) then
						arg_9_0.myPrice = math.ceil(arg_9_0.auctionInfo.now_price * var_0_10)

						local var_11_0 = var_0_1:translation("AUCTION_OFFER_TIPS1")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_11_0
						})
					end

					arg_9_0:nodeByName("my_price"):setString(tostring(arg_9_0.myPrice))
				end
			end

			var_9_2 = false
			arg_9_0.plusClickHandle = var_0_4.scheduleGlobal(var_10_1, 0.01)
		elseif arg_10_1 == ccui.TouchEventType.ended or arg_10_1 == ccui.TouchEventType.canceled then
			if arg_9_0.plusClickHandle then
				var_0_4.unscheduleGlobal(arg_9_0.plusClickHandle)
			end

			if not var_9_2 then
				arg_9_0.myPrice = arg_9_0.myPrice - 1

				if arg_9_0.myPrice < math.ceil(arg_9_0.auctionInfo.now_price * var_0_10) then
					arg_9_0.myPrice = math.ceil(arg_9_0.auctionInfo.now_price * var_0_10)

					local var_10_2 = var_0_1:translation("AUCTION_OFFER_TIPS1")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_10_2
					})
				end

				arg_9_0:nodeByName("my_price"):setString(tostring(arg_9_0.myPrice))
			end
		end

		return true
	end)
	arg_9_0:nodeByName("plus_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.began then
			local var_12_0 = 0

			local function var_12_1()
				var_12_0 = var_12_0 + 0.01

				if var_12_0 > 0.1 then
					if not var_9_2 then
						var_9_2 = true
					end

					if arg_9_0.myPrice then
						arg_9_0.myPrice = arg_9_0.myPrice + 1

						arg_9_0:nodeByName("my_price"):setString(tostring(arg_9_0.myPrice))
					end
				end
			end

			var_9_2 = false
			arg_9_0.plusClickHandle = var_0_4.scheduleGlobal(var_12_1, 0.01)
		elseif arg_12_1 == ccui.TouchEventType.ended or arg_12_1 == ccui.TouchEventType.canceled then
			if arg_9_0.plusClickHandle then
				var_0_4.unscheduleGlobal(arg_9_0.plusClickHandle)
			end

			if not var_9_2 then
				arg_9_0.myPrice = arg_9_0.myPrice + 1

				arg_9_0:nodeByName("my_price"):setString(tostring(arg_9_0.myPrice))
			end
		end

		return true
	end)
	arg_9_0:nodeByName("confirm_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			if arg_9_0.auctionInfo.is_done == 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("AUCTION_OFFER_TIPS3")
				})

				return true
			end

			local var_14_0 = {
				auction_type = arg_9_0.auctionType,
				auction_pos = arg_9_0.itemPos,
				price = arg_9_0.myPrice
			}

			if arg_9_0.auctionInfo.currency_type == xyd.currencyType.MANA and arg_9_0.myPrice > arg_9_0.selfPlayer.mana then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("JINBI_ABSENCE"), function()
					local var_15_0 = xyd.FunctionID.ID_GOLD_HAND

					if arg_9_0.selfPlayer:isFuncOpen(var_15_0) == true then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
					else
						local var_15_1 = xyd.tables.functionOpen:level(var_15_0)
						local var_15_2 = string.format(var_0_3:translation("FUNCTION_OPEN_TIP_LEVEL"), var_15_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_15_2
						})
					end
				end, nil, nil, arg_9_0.colorMode)
			elseif arg_9_0.auctionInfo.currency_type == xyd.currencyType.CRYSTAL and arg_9_0.myPrice > arg_9_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
					local var_16_0 = {}

					xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
				end, nil, nil, arg_9_0.colorMode)
			else
				local var_14_1 = var_0_3:translation("AUCTION_OFFER_TIPS4")

				if arg_9_0.auctionInfo.now_buyer == arg_9_0.selfPlayer.playerID then
					var_14_1 = var_0_3:translation("AUCTION_OFFER_TIPS2")
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_1, function()
					arg_9_0.auction:bidding(var_14_0, function(arg_18_0, arg_18_1)
						if arg_18_0 == xyd.error.OK then
							xyd.EventDispatcher.get():dispatchEvent({
								name = xyd.event.AUCTION_BIDDING_SUCCESS
							})
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_3:translation("AUCTION_OFFER_SUCCESS")
							})
							xyd.WindowManager.get():closeWindow(arg_9_0)
						end
					end)
				end, nil, nil, arg_9_0.colorMode)
			end
		end
	end)
	arg_9_0:nodeByName("refresh_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_19_0, arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			if xyd.WindowManager.get():getWindow("auction_room").refreshTooFast then
				local var_19_0 = var_0_3:translation("REFRESH_TOO_FAST")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_19_0
				})

				return false
			end

			arg_9_0.auction:refreshAuctions({
				auction_type = arg_9_0.auctionType
			})
		end
	end)
	arg_9_0:nodeByName("input_bg"):setTouchEnabled(true)
	arg_9_0:nodeByName("input_bg"):setTouchSwallowEnabled(false)
	arg_9_0:nodeByName("my_price"):setTouchSwallowEnabled(false)
	arg_9_0:initInputBox(arg_9_0:nodeByName("input_bg"))
	arg_9_0:nodeByName("return_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		xyd.buttonScaleAnim(arg_20_0, arg_20_1)

		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_9_0)
		end
	end)
	arg_9_0:layoutBiddingInfos()
end

function var_0_2.layoutBiddingInfos(arg_21_0)
	if arg_21_0.listView_ and not tolua.isnull(arg_21_0.listView_) then
		arg_21_0.listView_:removeAllItems()
	else
		arg_21_0.listView_ = cc.ui.UIListView.new({
			touchOnContent = true,
			viewRect = cc.rect(0, 0, 340, 280),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_21_0:nodeByName("info_list"))

		arg_21_0.listView_:setTouchSwallowEnabled(true)
	end

	for iter_21_0 = 1, #arg_21_0.biddingInfos do
		local var_21_0 = arg_21_0.listView_:newItem()
		local var_21_1 = display.newNode()
		local var_21_2 = var_0_0.new()

		var_21_2:setParams(arg_21_0.biddingInfos[iter_21_0])
		var_21_1:addChild(var_21_2)
		var_21_0:addContent(var_21_1)
		var_21_1:setContentSize(340, 75)
		var_21_0:setItemSize(340, 75)
		arg_21_0.listView_:addItem(var_21_0)
	end

	if #arg_21_0.biddingInfos == 0 then
		arg_21_0:nodeByName("no_auction_tips"):setVisible(true)
	else
		arg_21_0:nodeByName("no_auction_tips"):setVisible(false)
	end

	arg_21_0.listView_:reload()
end

function var_0_2.initInputBox(arg_22_0, arg_22_1)
	local var_22_0 = "windows/auction_room/input_bg.png"

	arg_22_0.price_box = ccui.EditBox:create(arg_22_1:getContentSize(), var_22_0)

	arg_22_0.price_box:setAnchorPoint(0, 0)
	arg_22_0.price_box:pos(0, 0)
	arg_22_1:addChild(arg_22_0.price_box, -100)
	arg_22_0.price_box:setFont(var_0_6.FONT_NAME, var_0_9)
	arg_22_0.price_box:setPlaceholderFont(var_0_6.FONT_NAME, var_0_9)
	arg_22_0.price_box:setPlaceHolder(var_0_3:translation("CHAT_INPUT_MESSAGE"))
	arg_22_0.price_box:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_22_0.price_box:setFontColor(cc.c3b(0, 0, 0))
	arg_22_0.price_box:setMaxLength(14)
	arg_22_0.price_box:setInputMode(2)
	arg_22_0.price_box:registerScriptEditBoxHandler(handler(arg_22_0, arg_22_0.channelboxEventHandler))
	arg_22_0.price_box:setInputFlag(3)

	arg_22_0.inputFlag = true
end

function var_0_2.channelboxEventHandler(arg_23_0, arg_23_1)
	print(arg_23_1)

	if arg_23_1 == "return" then
		print("channel return")

		local var_23_0 = math.floor(tonumber(arg_23_0.price_box:getText()) or 0)

		if var_23_0 and var_23_0 >= math.ceil(arg_23_0.auctionInfo.now_price * var_0_10) then
			arg_23_0.myPrice = var_23_0
		elseif var_23_0 then
			local var_23_1 = var_0_1:translation("AUCTION_OFFER_TIPS1")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_23_1
			})

			arg_23_0.myPrice = math.ceil(arg_23_0.auctionInfo.now_price * var_0_10)
		end

		arg_23_0:nodeByName("my_price"):setString(tostring(arg_23_0.myPrice))
		arg_23_0.price_box:setText("")

		arg_23_0.inputFlag = false
	end
end

return var_0_2
