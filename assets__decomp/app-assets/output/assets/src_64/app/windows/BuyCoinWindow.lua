local var_0_0 = class("BuyCoinWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.details = arg_1_2.details
	arg_1_0.coin_num_txt = arg_1_2.coin_num_txt
	arg_1_0.sellTable = xyd.tables.activityScratchLuckyCoin
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.scratchCard = xyd.ModelManager.get():loadModel(xyd.ModelType.SCRATCH_CARD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.sellList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 749, 480),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("scroll")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 225))
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)
end

function var_0_0.layout(arg_5_0)
	arg_5_0.sellList:setTouchSwallowEnabled(false)
	arg_5_0:nodeByName("scroll"):setTouchSwallowEnabled(false)

	for iter_5_0 = 1, arg_5_0.sellTable:allcount() do
		local var_5_0 = arg_5_0.sellList:newItem()
		local var_5_1 = arg_5_0:createListContent(iter_5_0)

		var_5_0:addContent(var_5_1)
		var_5_0:setItemSize(var_5_1:getContentSize().width, var_5_1:getContentSize().height)
		arg_5_0.sellList:addItem(var_5_0)
	end

	arg_5_0.sellList:reload()
end

function var_0_0.createListContent(arg_6_0, arg_6_1)
	local var_6_0 = display.newNode()
	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1055/buy_coin_wnd/item.csb")
	local var_6_2 = var_6_1:getChildByName("container")

	var_6_2:getChildByName("coin_num_txt"):setString(arg_6_0.sellTable:getName(arg_6_1))
	var_6_2:getChildByName("price_txt"):setString(arg_6_0.sellTable:getSellPrice(arg_6_1))

	if arg_6_1 == 1 then
		var_6_2:getChildByName("price_txt"):setVisible(false)
		var_6_2:getChildByName("mana_icon"):setVisible(false)
	end

	local var_6_3 = arg_6_0:creatTxtContent(arg_6_1)

	var_6_2:addChild(var_6_3)
	var_6_3:setPosition(var_6_2:getChildByName("desc_pos"):getPosition())

	local var_6_4 = var_6_2:getChildByName("buy_btn")

	arg_6_0:setBuyBtnTxt(var_6_4, arg_6_1)

	local var_6_5 = "windows/activities/1055/coin_" .. arg_6_1 .. ".png"

	xyd.setSpriteBorder(var_6_2:getChildByName("icon_container"), var_6_5)

	local var_6_6 = xyd.getBorder(0, false)

	xyd.displaySpriteOnContainer(var_6_6, var_6_2:getChildByName("icon_container"), true)
	var_6_0:setAnchorPoint(cc.p(0, 0))
	var_6_0:setPosition(0, 0)
	var_6_1:addTo(var_6_0)
	var_6_1:setAnchorPoint(cc.p(0, 0))
	var_6_0:setContentSize(var_6_2:getContentSize())
	var_6_1:setName("source")
	var_6_4:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended and arg_6_0.scrollViewMoved_ == false then
			if arg_6_1 == 1 and arg_6_0.details.is_has_free_coin == 0 then
				return
			elseif arg_6_1 == 1 and arg_6_0.details.is_has_free_coin == 1 then
				local var_7_0 = {
					id = arg_6_1
				}

				arg_6_0:freeToGetLuckyCoin(var_6_4, var_7_0)
			else
				local var_7_1 = arg_6_0.sellTable:getSellPrice(arg_6_1)
				local var_7_2 = arg_6_0.sellTable:getLuckyCoinNum(arg_6_1)

				if var_7_1 > arg_6_0.player.crystal then
					local var_7_3 = var_0_1:translation("ZUANSHI_ABSENCE")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_3, function()
						xyd.WindowManager.get():openWindow("vip_recharge")
					end, nil, nil, arg_6_0.colorMode)
				else
					local var_7_4 = string.format(var_0_1:translation("COST_TO_BUY_LUCKYCOINS"), var_7_1, var_7_2)

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_4, function()
						local var_9_0 = {
							id = arg_6_1
						}

						arg_6_0:costToBuyLuckyCoins(var_9_0)
					end, nil, nil, arg_6_0.colorMode)
				end
			end
		end
	end)

	return var_6_0
end

function var_0_0.freeToGetLuckyCoin(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_2.id

	arg_10_0.scratchCard:buyLuckyCoins(arg_10_2, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK and arg_10_0 then
			arg_10_0.details.is_has_free_coin = 0

			arg_10_0:setBuyBtnTxt(arg_10_1, var_10_0)
			arg_10_0.coin_num_txt:setString(arg_11_1.economy_.lucky_coin)

			local var_11_0 = arg_10_0.sellTable:getLuckyCoinNum(var_10_0)
			local var_11_1 = string.format(var_0_1:translation("HAVE_GET_NLUCKYCOINS"), var_11_0)

			xyd.WindowManager.get():openWindow("toast", {
				message = var_11_1
			})
		end
	end)
end

function var_0_0.costToBuyLuckyCoins(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_1.id

	arg_12_0.scratchCard:buyLuckyCoins(arg_12_1, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK and arg_12_0 then
			arg_12_0.coin_num_txt:setString(arg_13_1.economy_.lucky_coin)

			local var_13_0 = arg_12_0.sellTable:getLuckyCoinNum(var_12_0)
			local var_13_1 = string.format(var_0_1:translation("HAVE_GET_NLUCKYCOINS"), var_13_0)

			xyd.WindowManager.get():openWindow("toast", {
				message = var_13_1
			})
		end
	end)
end

function var_0_0.setBuyBtnTxt(arg_14_0, arg_14_1, arg_14_2)
	arg_14_1:getChildByName("buy_txt"):setVisible(false)
	arg_14_1:getChildByName("get_txt"):setVisible(false)
	arg_14_1:getChildByName("have_get_txt"):setVisible(false)

	if arg_14_2 == 1 then
		if arg_14_0.details.is_has_free_coin == 1 then
			arg_14_1:getChildByName("get_txt"):setVisible(true)
		else
			arg_14_1:getChildByName("have_get_txt"):setVisible(true)
		end
	else
		arg_14_1:getChildByName("buy_txt"):setVisible(true)
	end
end

function var_0_0.scrollListener(arg_15_0, arg_15_1)
	if arg_15_1.name == "began" then
		arg_15_0.scrollViewMoved_ = false
		arg_15_0.prevX_ = arg_15_1.x
	elseif arg_15_1.name == "moved" and 20 <= math.abs(arg_15_1.x - arg_15_0.prevX_) then
		arg_15_0.scrollViewMoved_ = true
	end
end

function var_0_0.creatTxtContent(arg_16_0, arg_16_1)
	local var_16_0 = {
		size = 18,
		color = cc.c3b(0, 0, 0)
	}
	local var_16_1 = xyd.AssetLoader.get():loadLabel(var_16_0)

	var_16_1:setMaxLineWidth(450)
	var_16_1:setString(arg_16_0.sellTable:getDesc(arg_16_1))

	local var_16_2 = display.newNode()
	local var_16_3 = display.newNode()

	var_16_1:addTo(var_16_3)
	var_16_1:setAnchorPoint(cc.p(0, 0))
	var_16_1:setPosition(0, 0)
	var_16_3:setContentSize(450, var_16_1:getContentSize().height)
	var_16_3:addTo(var_16_2)
	var_16_2:setContentSize(450, var_16_1:getContentSize().height + 20)

	return var_16_2
end

return var_0_0
