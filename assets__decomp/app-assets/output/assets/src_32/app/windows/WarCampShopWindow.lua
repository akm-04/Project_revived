local var_0_0 = class("WarCampShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.warCampShop
local var_0_3 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.camp_ = arg_1_0.warCamp_:getCampType()
	arg_1_0.page = 1
	arg_1_0.itemIdx = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayerWithNoTouchEvent()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super:willClose(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.camp_ == xyd.WarCampSelectType.LEFT then
		arg_4_0:nodeByName("bg_1"):setVisible(true)
		arg_4_0:nodeByName("bg_2"):setVisible(false)
		arg_4_0:nodeByName("dialog_bg_2"):setVisible(false)
		arg_4_0:nodeByName("coin_num_2"):setVisible(false)
		arg_4_0:nodeByName("close_2"):setVisible(false)
	else
		arg_4_0:nodeByName("bg_1"):setVisible(false)
		arg_4_0:nodeByName("bg_2"):setVisible(true)
		arg_4_0:nodeByName("dialog_bg_1"):setVisible(false)
		arg_4_0:nodeByName("coin_num_1"):setVisible(false)
	end

	for iter_4_0 = 1, 2 do
		if iter_4_0 == arg_4_0.camp_ then
			arg_4_0:nodeByName("change_item_btn_" .. iter_4_0):setVisible(true)
			arg_4_0:nodeByName("change_hero_btn_" .. iter_4_0):setVisible(true)
			arg_4_0:nodeByName("change_item_btn_" .. iter_4_0):setBright(true)
			arg_4_0:nodeByName("change_hero_btn_" .. iter_4_0):setBright(false)
			arg_4_0:nodeByName("change_item_btn_" .. iter_4_0):addTouchEventListener(function(arg_5_0, arg_5_1)
				if arg_5_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					arg_4_0.page = 2

					arg_4_0:nodeByName("change_item_btn_" .. iter_4_0):setBright(false)
					arg_4_0:nodeByName("change_hero_btn_" .. iter_4_0):setBright(true)
					arg_4_0:changePage()
				end
			end)
			arg_4_0:nodeByName("change_hero_btn_" .. iter_4_0):addTouchEventListener(function(arg_6_0, arg_6_1)
				if arg_6_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					arg_4_0.page = 1

					arg_4_0:nodeByName("change_item_btn_" .. iter_4_0):setBright(true)
					arg_4_0:nodeByName("change_hero_btn_" .. iter_4_0):setBright(false)
					arg_4_0:changePage()
				end
			end)
		else
			arg_4_0:nodeByName("change_item_btn_" .. iter_4_0):setVisible(false)
			arg_4_0:nodeByName("change_hero_btn_" .. iter_4_0):setVisible(false)
		end
	end

	arg_4_0:nodeByName("close_2"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("sprite_coin"):setTexture("windows/war_camp/img_score_" .. arg_4_0.camp_ .. ".png")
	arg_4_0:nodeByName("sprite_coin"):setScale(0.5)

	arg_4_0.arrowLeft = arg_4_0:nodeByName("arrow_left")

	arg_4_0.arrowLeft:addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_4_0.arrowLeft, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_4_0.itemIdx = arg_4_0.itemIdx - 1

			arg_4_0:initShopList(arg_4_0.page)
		end
	end)

	arg_4_0.arrowRight = arg_4_0:nodeByName("arrow_right")

	arg_4_0.arrowRight:addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_4_0.arrowRight, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			arg_4_0.itemIdx = arg_4_0.itemIdx + 1

			arg_4_0:initShopList(arg_4_0.page)
		end
	end)
	arg_4_0:initShopList(arg_4_0.page)
	arg_4_0:updateMyScore()
end

function var_0_0.changePage(arg_10_0)
	arg_10_0.itemIdx = 0

	arg_10_0:initShopList(arg_10_0.page)
end

function var_0_0.updateMyScore(arg_11_0)
	local var_11_0 = arg_11_0.warCamp_:getScore()

	if arg_11_0.camp_ == xyd.WarCampSelectType.LEFT then
		arg_11_0:nodeByName("coin_num_1"):setString(var_11_0)
	else
		arg_11_0:nodeByName("coin_num_2"):setString(var_11_0)
	end
end

function var_0_0.initShopList(arg_12_0, arg_12_1)
	local var_12_0 = var_0_2:ids(arg_12_1)

	for iter_12_0 = 1, 2 do
		local var_12_1 = var_12_0[arg_12_0.itemIdx * 2 + iter_12_0]

		arg_12_0:nodeByName("item_pos" .. iter_12_0):removeAllChildren()

		local var_12_2 = var_0_2:itemID(var_12_1)
		local var_12_3 = 0

		if arg_12_0.warCamp_:getCampType() == xyd.WarCampSelectType.LEFT then
			var_12_3 = var_0_2:sellPriceDemon(var_12_1)
		else
			var_12_3 = var_0_2:sellPriceAngel(var_12_1)
		end

		local var_12_4 = arg_12_0:createExchangeItem(var_12_1, var_12_2, var_12_3)
		local var_12_5 = var_12_4:getContentSize()

		var_12_4:addTo(arg_12_0:nodeByName("item_pos" .. iter_12_0))
		var_12_4:setPosition(-var_12_5.width / 2, 0)
	end

	arg_12_0.arrowLeft:setVisible(arg_12_0.itemIdx > 0)
	arg_12_0.arrowRight:setVisible(arg_12_0.itemIdx * 2 + 2 < #var_12_0)
end

function var_0_0.createExchangeItem(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = display.newNode()
	local var_13_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/war_camp/shop/exchange_item.csb")
	local var_13_2 = var_13_1:getChildByName("container")

	var_13_2:getChildByName("name_txt"):setString(xyd.tables.item:name(arg_13_2))
	var_13_2:getChildByName("name_txt"):enableOutline(cc.c4b(118, 66, 15, 255), 2)
	var_13_2:getChildByName("price_txt"):setString(arg_13_3)

	local var_13_3 = var_0_2:limitNum(arg_13_1)

	local function var_13_4()
		if not arg_13_0 or tolua.isnull(arg_13_0) then
			return
		end

		if var_13_3 ~= -1 then
			local var_14_0 = arg_13_0.warCamp_.baseInfo.buy_times[arg_13_1]
			local var_14_1 = string.format(var_0_1:translation("STICK_BLESS_BUY_LIMIT"), var_14_0, var_13_3)

			var_13_2:getChildByName("buy_time_txt"):setString(var_14_1)
		end
	end

	var_13_4()
	xyd.setItemAndAddTips(var_13_2:getChildByName("icon_container"), arg_13_2)
	var_13_2:getChildByName("exchange_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			local var_15_0 = {
				id = arg_13_1,
				itemID = arg_13_2,
				singleCost = arg_13_3
			}

			if var_13_3 ~= -1 then
				var_15_0.remainTimes = var_0_2:limitNum(arg_13_1) - arg_13_0.warCamp_.baseInfo.buy_times[arg_13_1]
				var_15_0.callback = var_13_4
			end

			xyd.WindowManager.get():openWindow("war_camp_shop_buy", var_15_0)
		end
	end)
	var_13_2:getChildByName("img_coin"):setTexture("windows/war_camp/img_score_" .. arg_13_0.camp_ .. ".png")
	var_13_2:getChildByName("img_coin"):setScale(0.5)
	var_13_1:addTo(var_13_0)
	var_13_1:setAnchorPoint(cc.p(0, 0))
	var_13_0:setContentSize(var_13_2:getContentSize())
	var_13_1:setName("source")

	return var_13_0
end

return var_0_0
