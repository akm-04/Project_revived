local var_0_0 = class("SkinShopDetailAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.chargeList
local var_0_5 = xyd.tables.avartarMall
local var_0_6 = xyd.tables.ecoType
local var_0_7 = xyd.tables.misc.skinTicketId
local var_0_8 = var_0_6:getEcoPath("crystal")
local var_0_9 = var_0_6:getEcoPath("skin_coin")
local var_0_10 = var_0_6:getEcoPath("skin_fragment")
local var_0_11 = "windows/skin_shop_window/detail/old_skin_coin.png"
local var_0_12 = {
	crystal = 2,
	fragment = 10,
	oldCoin = 9,
	coin = 3
}
local var_0_13 = {
	left = 1,
	right = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.index = arg_1_2.idx
	arg_1_0.itemID = arg_1_2.item_id
	arg_1_0.saleType = arg_1_2.sale_type
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.isDiscount = arg_1_2.is_discount

	if arg_1_0.isDiscount then
		arg_1_0.price = arg_1_2.discount
	else
		arg_1_0.price = arg_1_2.price
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_2:translation("AVARTAR_MALLPAY_CONFIRM"))
	arg_4_0:nodeByName("txt_confirm"):setString(var_0_2:translation("AVARTAR_MALLPAY"))
	arg_4_0:nodeByName("txt_close_tip"):setString(var_0_2:translation("SKIN_COLLIDER_TEXT"))
	var_0_1.new({
		size = 490
	}):addTo(arg_4_0:nodeByName("pos_line"))

	local var_4_0 = var_0_3:name(arg_4_0.itemID)

	arg_4_0:nodeByName("txt_name"):setString(var_4_0 .. var_0_2:translation("AVARTAR_MALL_POSE"))

	if arg_4_0.saleType == 1 then
		arg_4_0.chargePrice = arg_4_0.price[1]

		arg_4_0:nodeByName("btn_left"):setVisible(false)
		arg_4_0:nodeByName("btn_right"):setVisible(false)
		arg_4_0:nodeByName("btn_buy"):setVisible(true)
		arg_4_0:nodeByName("txt_cost"):setString(arg_4_0.chargePrice .. var_0_2:translation("AVARTAR_MALLCURRENCY_NTS"))
	elseif arg_4_0.saleType == 2 then
		arg_4_0.leftSubType = var_0_12.crystal

		arg_4_0:updateBtnShow({
			var_0_8
		})
	elseif arg_4_0.saleType == 3 then
		arg_4_0.leftSubType = var_0_12.coin

		arg_4_0:updateBtnShow({
			var_0_9
		})
	elseif arg_4_0.saleType == 4 then
		arg_4_0.leftSubType = var_0_12.crystal
		arg_4_0.rightSubType = var_0_12.coin

		arg_4_0:updateBtnShow({
			var_0_8,
			var_0_9
		})
	elseif arg_4_0.saleType == 5 then
		if arg_4_0.backpack:getItemNumByID(var_0_7) > 0 then
			arg_4_0.leftSubType = var_0_12.oldCoin
			arg_4_0.rightSubType = var_0_12.coin

			arg_4_0:updateBtnShow({
				var_0_11,
				var_0_9
			})
		else
			arg_4_0.leftSubType = var_0_12.coin

			arg_4_0:updateBtnShow({
				var_0_9
			}, 2)
		end
	elseif arg_4_0.saleType == 6 then
		if arg_4_0.selfPlayer.skinFragment > 0 then
			arg_4_0.leftSubType = var_0_12.fragment
			arg_4_0.rightSubType = var_0_12.coin

			arg_4_0:updateBtnShow({
				var_0_10,
				var_0_9
			})
		else
			arg_4_0.leftSubType = var_0_12.coin

			arg_4_0:updateBtnShow({
				var_0_9
			}, 2)
		end
	elseif arg_4_0.saleType == 7 then
		if arg_4_0.backpack:getItemNumByID(var_0_7) > 0 then
			arg_4_0.leftSubType = var_0_12.oldCoin
			arg_4_0.rightSubType = var_0_12.crystal

			arg_4_0:updateBtnShow({
				var_0_11,
				var_0_8
			})
		else
			arg_4_0.leftSubType = var_0_12.crystal

			arg_4_0:updateBtnShow({
				var_0_8
			}, 2)
		end
	elseif arg_4_0.saleType == 8 then
		if arg_4_0.selfPlayer.skinFragment > 0 then
			arg_4_0.leftSubType = var_0_12.fragment
			arg_4_0.rightSubType = var_0_12.crystal

			arg_4_0:updateBtnShow({
				var_0_10,
				var_0_8
			})
		else
			arg_4_0.leftSubType = var_0_12.crystal

			arg_4_0:updateBtnShow({
				var_0_8
			}, 2)
		end
	end

	arg_4_0:initBtn()
	arg_4_0:addContent(var_4_0)
end

function var_0_0.updateBtnShow(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_2 or 1

	if #arg_5_1 == 1 then
		arg_5_0.leftPrice = arg_5_0.price[var_5_0]

		arg_5_0:nodeByName("btn_right"):setVisible(false)
		arg_5_0:nodeByName("txt_left_cost"):setString(arg_5_0.leftPrice)
		arg_5_0:nodeByName("btn_left"):setPositionX(295)
		arg_5_0:nodeByName("icon_left"):setTexture(arg_5_1[1])
	else
		arg_5_0.leftPrice = arg_5_0.price[1]
		arg_5_0.rightPrice = arg_5_0.price[2]

		arg_5_0:nodeByName("txt_left_cost"):setString(arg_5_0.leftPrice)
		arg_5_0:nodeByName("txt_right_cost"):setString(arg_5_0.rightPrice)
		arg_5_0:nodeByName("icon_left"):setTexture(arg_5_1[1])
		arg_5_0:nodeByName("icon_right"):setTexture(arg_5_1[2])
	end
end

function var_0_0.initBtn(arg_6_0)
	arg_6_0:nodeByName("btn_left"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			arg_6_0:checkAndBuy(arg_6_0.leftSubType, arg_6_0.leftPrice, var_0_13.left)
		end
	end)
	arg_6_0:nodeByName("btn_right"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_6_0:checkAndBuy(arg_6_0.rightSubType, arg_6_0.rightPrice, var_0_13.right)
		end
	end)
	arg_6_0:nodeByName("btn_buy"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			arg_6_0:purchaseGiftBag()
		end
	end)
end

function var_0_0.checkAndBuy(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if arg_10_1 == var_0_12.crystal and arg_10_2 > arg_10_0.selfPlayer.crystal then
		local var_10_0 = var_0_2:translation("ZUANSHI_ABSENCE")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_0, function()
			xyd.WindowManager.get():openWindow("vip_recharge")
		end, nil, nil, arg_10_0.colorMode)

		return
	elseif arg_10_1 == var_0_12.coin and arg_10_2 > arg_10_0.selfPlayer.skinCoin then
		local var_10_1 = var_0_2:translation("AVARTAR_MALLCURRENCY_SKINPOINT_NOTENOUGH")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_10_1
		})
		xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):setSceneCondition(17, 1)

		return
	elseif arg_10_1 == var_0_12.oldCoin and arg_10_2 > arg_10_0.backpack:getItemNumByID(var_0_7) then
		local var_10_2 = var_0_2:translation("AVARTAR_MALLCURRENCY_OLDSKINCOIN_NOTENOUGH")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_10_2
		})

		return
	elseif arg_10_1 == var_0_12.fragment and arg_10_2 > arg_10_0.selfPlayer.skinFragment then
		if arg_10_0.rightPrice and arg_10_0.rightSubType and arg_10_0.rightSubType == var_0_12.coin then
			local var_10_3 = (arg_10_2 - arg_10_0.selfPlayer.skinFragment) / arg_10_2
			local var_10_4 = math.floor(arg_10_0.rightPrice * var_10_3)
			local var_10_5 = string.format(var_0_2:translation("SKIN_SHOP_PAY_SEDCOIN"), var_10_4)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_5, function()
				if arg_10_0.selfPlayer.skinCoin >= var_10_4 then
					arg_10_0:buy({
						id = arg_10_0.index,
						sub_type = arg_10_1
					}, arg_10_3)
				else
					local var_12_0 = var_0_2:translation("AVARTAR_MALLCURRENCY_SKINPOINT_NOTENOUGH")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_12_0
					})
				end
			end, nil, nil, arg_10_0.colorMode)

			return
		end

		local var_10_6 = var_0_2:translation("AVARTAR_MALLCURRENCY_SKINFRAGMENT_NOTENOUGH")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_10_6
		})

		return
	end

	arg_10_0:buy({
		id = arg_10_0.index,
		sub_type = arg_10_1
	}, arg_10_3)
end

function var_0_0.addContent(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0.itemID
	local var_13_1 = xyd.tables.skinSkill:getSkillID(var_13_0)
	local var_13_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/skin_shop_window/detail/skin_item.csb")
	local var_13_3 = var_13_2:getChildByName("container")
	local var_13_4 = var_0_3:skinModel(var_13_0)

	var_13_3:getChildByName("bg_skin_item2"):hide()
	var_13_3:getChildByName("select"):hide()
	var_13_3:getChildByName("bg_item_top2"):hide()
	var_13_3:getChildByName("txt_type"):setString(var_0_2:translation("AVARTAR_STATE_MALL"))
	var_13_3:getChildByName("bg_skill"):getChildByName("txt_skill"):setString(var_0_2:translation("AVARTAR_MALL_SKILL"))

	local var_13_5 = xyd.SpriteLoader.new(xyd.tables.model:card(var_13_4), nil, nil, xyd.DefaultImageType.HERO_CARD)
	local var_13_6 = var_13_3:getChildByName("card"):getContentSize()
	local var_13_7 = cc.ClippingNode:create()
	local var_13_8 = display.newScale9Sprite("images/line_mask.png", 0, 0, var_13_6)

	var_13_8:setAnchorPoint(0, 0)
	var_13_7:setStencil(var_13_8)
	var_13_5:setScale(0.4)
	var_13_3:getChildByName("card"):addChild(var_13_7)
	var_13_5:setAnchorPoint(0.5, 0.5)
	var_13_5:setPosition(var_13_6.width / 2, var_13_6.height / 2)
	var_13_7:addChild(var_13_5)
	var_13_7:setName("clip")
	var_13_3:getChildByName("txt_name"):setString(arg_13_1)
	var_13_3:getChildByName("bg_skill"):setVisible(var_13_1 and var_13_1 > 0)
	var_13_2:setScale(0.8)
	var_13_2:addTo(arg_13_0:nodeByName("card"))
end

function var_0_0.buy(arg_14_0, arg_14_1, arg_14_2)
	xyd.Backend.get():request(xyd.mid.SKIN_SHOP_BUY, arg_14_1, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			if arg_14_0.hero and arg_15_1.skin_ids then
				arg_14_0.selfPlayer:showRewards(arg_15_1.awards)
				arg_14_0.hero:setSkinInfo(arg_14_0.hero.skinId_, arg_15_1.skin_ids)

				local var_15_0 = xyd.tables.skinSkill:getSkillID(arg_14_0.itemID)

				if var_15_0 and var_15_0 > 0 then
					xyd.db.skinSkillRedMark:updateSkinSkillRedMark(arg_14_0.selfPlayer.playerID, arg_14_0.hero:getHeroID(), 1)
				end
			else
				arg_14_0.selfPlayer:handleRewards(arg_15_1.awards)
			end

			if arg_14_1.sub_type == var_0_12.oldCoin then
				local var_15_1 = {
					itemID = var_0_7
				}

				if arg_14_2 == var_0_13.left then
					var_15_1.itemNum = arg_14_0.leftPrice
				elseif arg_14_2 == var_0_13.right then
					var_15_1.itemNum = arg_14_0.rightPrice
				end

				arg_14_0.backpack:removeItem(var_15_1)
			end

			local var_15_2 = xyd.WindowManager.get():getWindow("hero_main")

			if var_15_2 and not tolua.isnull(var_15_2) then
				var_15_2:updateEquipInfoContainer()
			end

			arg_14_0.callback()
			arg_14_0:close()
		end
	end)
end

function var_0_0.purchaseGiftBag(arg_16_0)
	local var_16_0 = true
	local var_16_1
	local var_16_2
	local var_16_3

	if arg_16_0.isDiscount then
		var_16_1 = var_0_5:discountChargeid(arg_16_0.index)
		var_16_2 = arg_16_0.price[1]
		var_16_3 = var_0_5:discountIosProductId(arg_16_0.index)
	else
		var_16_1 = var_0_5:chargeid(arg_16_0.index)
		var_16_2 = arg_16_0.price[1]
		var_16_3 = var_0_5:iosProductId(arg_16_0.index)
	end

	if device.platform == "android" then
		xyd.androidPurchase({
			var_16_1
		}, {}, var_16_1, false, var_16_2, var_0_5:name(arg_16_0.index))
	elseif device.platform == "ios" then
		xyd.sdkPurchase(var_16_3, var_16_0, var_16_1, {}, {}, {
			var_16_1
		})
	end

	local var_16_4 = xyd.WindowManager.get():getWindow("hero_main")

	if var_16_4 and not tolua.isnull(var_16_4) then
		var_16_4:updateEquipInfoContainer()
	end

	arg_16_0.callback()
	arg_16_0:close()
end

return var_0_0
