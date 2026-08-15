local var_0_0 = class("AuctionRoomWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.item
local var_0_4 = 1
local var_0_5 = 2
local var_0_6 = 2
local var_0_7 = 86400
local var_0_8 = 9
local var_0_9 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.auction = xyd.ModelManager.get():loadModel(xyd.ModelType.AUCTION)
	arg_1_0.auctionType = var_0_5
	arg_1_0.loaded = arg_1_2 and arg_1_2.loaded
	arg_1_0.refreshCoolDown = 0
	arg_1_0.switchCoolDown = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		show_rule = true
	})
	arg_2_0:nodeByName("txt_all_region"):setString(var_0_1:translation("AUCTION_TIP_TEXT3"))
	arg_2_0:nodeByName("txt_local_region"):setString(var_0_1:translation("AUCTION_TIP_TEXT4"))
	arg_2_0:nodeByName("txt_refresh"):setString(var_0_1:translation("AUCTION_TIP_TEXT5"))
	arg_2_0:nodeByName("txt_refresh_gray"):setString(var_0_1:translation("AUCTION_TIP_TEXT5"))
	var_0_0.super:willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()

	local function var_3_0()
		local var_4_0 = xyd.ServerTime.get():getSecondsOfDay()
		local var_4_1

		if var_4_0 <= xyd.tables.misc.auctionStartTime then
			var_4_1 = xyd.tables.misc.auctionStartTime - var_4_0
			stringToShow = "AUCTION_TIME_OPEN"

			arg_3_0:nodeByName("refresh_btn"):setBright(false)
			arg_3_0:nodeByName("refresh_btn"):setTouchEnabled(false)
			arg_3_0:nodeByName("txt_refresh_gray"):setVisible(true)
			arg_3_0:nodeByName("txt_refresh"):setVisible(false)
		elseif var_4_0 <= xyd.tables.misc.auctionEndTime then
			var_4_1 = xyd.tables.misc.auctionEndTime - var_4_0
			stringToShow = "AUCTION_TIME_CLOSE"

			arg_3_0:nodeByName("refresh_btn"):setBright(true)
			arg_3_0:nodeByName("refresh_btn"):setTouchEnabled(true)
			arg_3_0:nodeByName("txt_refresh_gray"):setVisible(false)
			arg_3_0:nodeByName("txt_refresh"):setVisible(true)
		else
			var_4_1 = xyd.tables.misc.auctionStartTime + var_0_7 - var_4_0
			stringToShow = "AUCTION_TIME_OPEN"

			arg_3_0:nodeByName("refresh_btn"):setBright(false)
			arg_3_0:nodeByName("refresh_btn"):setTouchEnabled(false)
			arg_3_0:nodeByName("txt_refresh_gray"):setVisible(true)
			arg_3_0:nodeByName("txt_refresh"):setVisible(false)
		end

		arg_3_0:nodeByName("rest_time"):setString(var_0_1:translation(stringToShow) .. xyd.secondsToString(var_4_1))

		if arg_3_0.refreshTooFast and arg_3_0.refreshCoolDown < var_0_8 then
			arg_3_0.refreshCoolDown = arg_3_0.refreshCoolDown + 1
		else
			arg_3_0.refreshCoolDown = 0
			arg_3_0.refreshTooFast = false
		end

		if arg_3_0.switchTooFast and arg_3_0.switchCoolDown < var_0_9 then
			arg_3_0.switchCoolDown = arg_3_0.switchCoolDown + 1
		else
			arg_3_0.switchCoolDown = 0
			arg_3_0.switchTooFast = false
		end
	end

	var_3_0()

	arg_3_0.handle = var_0_2.scheduleGlobal(var_3_0, 0.3)
end

function var_0_0.updateTimeLabel(arg_5_0)
	local var_5_0 = xyd.ServerTime.get():getSecondsOfDay()
	local var_5_1

	if var_5_0 <= xyd.tables.misc.auctionStartTime then
		var_5_1 = xyd.tables.misc.auctionStartTime - var_5_0
		stringToShow = "AUCTION_TIME_OPEN"
	elseif var_5_0 <= xyd.tables.misc.auctionEndTime then
		var_5_1 = xyd.tables.misc.auctionEndTime - var_5_0
		stringToShow = "AUCTION_TIME_CLOSE"
	else
		var_5_1 = xyd.tables.misc.auctionStartTime + var_0_7 - var_5_0
		stringToShow = "AUCTION_TIME_OPEN"
	end

	arg_5_0:nodeByName("rest_time"):setString(var_0_1:translation(stringToShow) .. xyd.secondsToString(var_5_1))
end

function var_0_0.layout(arg_6_0)
	if arg_6_0.loaded then
		arg_6_0:layoutItems(arg_6_0.auction.auctionList)

		arg_6_0.loaded = false
	else
		arg_6_0.auction:getAuctionInfoByType({
			auction_type = arg_6_0.auctionType
		}, function(arg_7_0, arg_7_1)
			if arg_7_0 == xyd.error.OK then
				arg_6_0:layoutItems(arg_6_0.auction.auctionList)
			end
		end)
	end

	arg_6_0:addSpriteListener()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_6_0):addEventListener(xyd.event.AUCTION_REFRESH_ONTIME, function(arg_8_0)
		arg_6_0.auction:refreshAuctions({
			auction_type = arg_6_0.auctionType
		})
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_6_0):addEventListener(xyd.event.AUCTION_REFRESH, function(arg_9_0)
		arg_6_0.refreshTooFast = true

		arg_6_0:layoutItems(arg_6_0.auction.auctionList)
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_6_0):addEventListener(xyd.event.AUCTION_BIDDING_SUCCESS, function(arg_10_0)
		arg_6_0:layoutItems(arg_6_0.auction.auctionList)
	end)
	arg_6_0:nodeByName("switch_btn"):setVisible(false)
	arg_6_0:nodeByName("switch_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			if arg_6_0.switchTooFast then
				local var_11_0 = var_0_1:translation("SWITCH_TOO_FAST")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_0
				})

				return false
			end

			arg_6_0.auctionType = arg_6_0.auctionType % var_0_6 + 1

			arg_6_0.auction:getAuctionInfoByType({
				auction_type = arg_6_0.auctionType
			}, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					arg_6_0.switchTooFast = true

					arg_6_0:layoutItems(arg_6_0.auction.auctionList)
				end
			end)
		end
	end)
	arg_6_0:nodeByName("refresh_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			if arg_6_0.refreshTooFast then
				local var_13_0 = var_0_1:translation("REFRESH_TOO_FAST")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_13_0
				})

				return false
			end

			arg_6_0.auction:refreshAuctions({
				auction_type = arg_6_0.auctionType
			})
		end
	end)
	xyd.nodeEventSample(arg_6_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function()
		local var_14_0 = {}

		var_14_0.title_name = "AUCTION_RULES_TITLE"
		var_14_0.rule = "AUCTION_RULES"

		xyd.WindowManager.get():openWindow("new_text_rule", var_14_0)
	end)
end

local function var_0_10(arg_15_0, arg_15_1, arg_15_2)
	arg_15_2:getAuctionLog({
		auction_type = arg_15_1,
		auction_pos = arg_15_0
	}, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			local var_16_0 = {
				auction_type = arg_15_1,
				item_pos = arg_15_0,
				auction_info = arg_15_2.auctionList[arg_15_0],
				bidding_infos = arg_16_1.log_list or {}
			}

			xyd.WindowManager.get():openWindow("auction_bidding", var_16_0)
		end
	end)
end

function var_0_0.layoutItems(arg_17_0)
	if arg_17_0.auctionType == var_0_4 then
		arg_17_0:nodeByName("txt_all_region"):setVisible(false)
		arg_17_0:nodeByName("txt_local_region"):setVisible(true)
	elseif arg_17_0.auctionType == var_0_5 then
		arg_17_0:nodeByName("txt_all_region"):setVisible(true)
		arg_17_0:nodeByName("txt_local_region"):setVisible(false)
	end

	for iter_17_0 = 1, #arg_17_0.auction.auctionList do
		local var_17_0 = arg_17_0:nodeByName("item" .. iter_17_0)

		if arg_17_0.auction.auctionList[iter_17_0].is_done == 1 and arg_17_0.auction.auctionList[iter_17_0].now_buyer ~= 0 then
			var_17_0:getChildByName("done"):setVisible(true)
			var_17_0:getChildByName("mask"):setVisible(true)
		else
			var_17_0:getChildByName("done"):setVisible(false)
			var_17_0:getChildByName("mask"):setVisible(false)
		end

		if arg_17_0.auction.auctionList[iter_17_0].now_buyer == arg_17_0.selfPlayer.playerID then
			var_17_0:getChildByName("info_txt"):setVisible(false)
			var_17_0:getChildByName("already_bidding"):setVisible(true)
		else
			var_17_0:getChildByName("info_txt"):setVisible(true)
			var_17_0:getChildByName("already_bidding"):setVisible(false)
		end

		var_17_0:getChildByName("price_bg"):getChildByName("price_now"):setString(arg_17_0.auction.auctionList[iter_17_0].now_price)
		var_17_0:getChildByName("item_icon"):setContentSize(108, 108)
		var_17_0:getChildByName("item_icon"):setAnchorPoint(0, 0)
		var_17_0:getChildByName("item_icon"):removeAllChildren()
		var_17_0:getChildByName("currency_icon"):removeAllChildren()
		xyd.setItemBorder(var_17_0:getChildByName("item_icon"), arg_17_0.auction.auctionList[iter_17_0].item_id)
		var_17_0:getChildByName("item_icon"):setTouchEnabled(true)
		var_17_0:getChildByName("item_icon"):setTouchSwallowEnabled(true)
		var_17_0:getChildByName("item_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
			if arg_18_0.name == "began" then
				touchBeganY = arg_18_0.y

				if not xyd.WindowManager.get():getWindow("new_item_tips") then
					local var_18_0 = {
						id = arg_17_0.auction.auctionList[iter_17_0].item_id
					}

					var_18_0.hasNum = 0
					var_18_0.showNum = false

					local var_18_1 = xyd.WindowManager.get():openWindow("new_item_tips", var_18_0)

					xyd.adaptToWorldPosition(var_17_0:getChildByName("item_icon"), var_18_1)
				end

				return true
			elseif arg_18_0.name == "moved" then
				local var_18_2 = arg_18_0.y

				if math.abs(var_18_2 - touchBeganY) > 30 then
					xyd.WindowManager.get():closeWindow("new_item_tips")
				end
			elseif arg_18_0.name == "ended" then
				wnd = xyd.WindowManager.get():closeWindow("new_item_tips")

				local var_18_3 = var_17_0:getChildByName("item_icon"):convertToWorldSpace(cc.p(0, 0))

				if arg_18_0.y - var_18_3.y < 0 or arg_18_0.y - var_18_3.y > 113 or arg_18_0.x - var_18_3.x < 0 or arg_18_0.x - var_18_3.x > 113 then
					return
				end
			end

			return false
		end)
		var_17_0:getChildByName("item_name"):setString(var_0_3:name(arg_17_0.auction.auctionList[iter_17_0].item_id))

		local var_17_1

		if arg_17_0.auction.auctionList[iter_17_0].currency_type == xyd.currencyType.MANA then
			var_17_1 = xyd.AssetLoader:get():loadSprite("images/jinbi.png")
		elseif arg_17_0.auction.auctionList[iter_17_0].currency_type == xyd.currencyType.CRYSTAL then
			var_17_1 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
		end

		xyd.displaySpriteOnContainer(var_17_1, var_17_0:getChildByName("currency_icon"), false)
		var_17_0:getChildByName("info_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
			if arg_19_1 == ccui.TouchEventType.ended then
				var_0_10(iter_17_0, arg_17_0.auctionType, arg_17_0.auction)
			end

			return true
		end)
		var_17_0:setTouchEnabled(true)
		var_17_0:setTouchSwallowEnabled(false)
	end
end

function var_0_0.addSpriteListener(arg_20_0)
	for iter_20_0 = 1, #arg_20_0.auction.auctionList do
		arg_20_0:nodeByName("item" .. iter_20_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
			if arg_21_0.name == "ended" then
				var_0_10(iter_20_0, arg_20_0.auctionType, arg_20_0.auction)
			end

			return true
		end)
	end
end

function var_0_0.willClose(arg_22_0)
	if arg_22_0.handle then
		var_0_2.unscheduleGlobal(arg_22_0.handle)

		arg_22_0.handle = nil
	end
end

return var_0_0
