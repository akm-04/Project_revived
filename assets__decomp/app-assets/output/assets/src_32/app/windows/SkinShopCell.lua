local var_0_0 = class("ShopCell", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.misc
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.avartarMall
local var_0_5 = xyd.tables.translation
local var_0_6 = import("app.model.Hero")
local var_0_7 = 50001180
local var_0_8 = {
	CRYSTAL = 2,
	BUY = 1,
	ITEM = 4,
	OLD_TICKET_SKIN = 5,
	OLD_SUIPIAN = 10,
	OLD_TICKET = 9,
	DEFAULT = 11,
	OLD_SUIPIAN_CRYSTAL = 8,
	SKIN_TICKET = 3,
	OLD_TICKET_CRYSTAL = 7,
	OLD_SUIPIAN_SKIN = 6
}

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_2_0.skin = arg_2_1.skin
end

function var_0_0.getData(arg_3_0)
	local var_3_0 = arg_3_0.skin

	arg_3_0.itemId = var_3_0.item
	arg_3_0.id = var_3_0.id
	arg_3_0.name = var_3_0.name
	arg_3_0.partner = var_3_0.partner
	arg_3_0.prePrice = var_0_4:price(arg_3_0.id)
	arg_3_0.nowPrice = var_3_0.nowprice
	arg_3_0.showDiscount = var_3_0.showDiscountTip
	arg_3_0.ownSkill = var_3_0.skillornot
	arg_3_0.ownSkin = var_3_0.ownSkin
	arg_3_0.saleType = var_3_0.saletype
	arg_3_0.suipianNum = arg_3_0.selfPlayer.skinFragment
	arg_3_0.ecoNum = arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_0_7)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:getData()
	arg_4_0:initContainer()

	if arg_4_0.saleType ~= var_0_8.ITEM and arg_4_0.saleType ~= var_0_8.OLD_TICKET_SKIN and arg_4_0.saleType ~= var_0_8.OLD_SUIPIAN_SKIN and arg_4_0.saleType ~= var_0_8.OLD_TICKET_CRYSTAL and arg_4_0.saleType ~= var_0_8.OLD_SUIPIAN_CRYSTAL then
		if arg_4_0.saleType == var_0_8.BUY then
			arg_4_0.priceContainer = arg_4_0:contentView():nodeByName("price_container1")
			arg_4_0.saleContainer = arg_4_0:contentView():nodeByName("sale_container1_1")

			arg_4_0.priceContainer:setVisible(true)
			arg_4_0.saleContainer:setVisible(true)
			arg_4_0.saleContainer:getChildByName("price_pre"):setVisible(false)
			arg_4_0.saleContainer:getChildByName("red_line"):setVisible(false)

			if arg_4_0.showDiscount == true then
				arg_4_0.saleContainer:getChildByName("price_pre"):setVisible(true)
				arg_4_0.saleContainer:getChildByName("red_line"):setVisible(true)
				arg_4_0.saleContainer:getChildByName("price_now"):setPositionY(arg_4_0.saleContainer:getChildByName("price_now"):getPositionY() + 4)
				arg_4_0.saleContainer:getChildByName("price_pre"):setString(arg_4_0.prePrice[arg_4_0.saleType] .. var_0_5:translation("SKIN_SHOP_CELL_TXT2"))
				arg_4_0.saleContainer:getChildByName("price_now"):setString(arg_4_0.nowPrice[arg_4_0.saleType] .. var_0_5:translation("SKIN_SHOP_CELL_TXT2"))
			else
				arg_4_0.saleContainer:getChildByName("price_now"):setString(arg_4_0.nowPrice[arg_4_0.saleType] .. var_0_5:translation("SKIN_SHOP_CELL_TXT2"))
			end
		else
			arg_4_0.priceContainer = arg_4_0:contentView():nodeByName("price_container1")
			arg_4_0.saleContainer = arg_4_0:contentView():nodeByName("sale_container1_2")

			arg_4_0.priceContainer:setVisible(true)
			arg_4_0.saleContainer:setVisible(true)
			arg_4_0.saleContainer:getChildByName("price_now"):setString(arg_4_0.nowPrice[arg_4_0.saleType])

			if arg_4_0.saleType == var_0_8.CRYSTAL then
				arg_4_0.saleContainer:getChildByName("skin_ticket"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("diamond"):setVisible(true)
			elseif arg_4_0.saleType == var_0_8.SKIN_TICKET then
				arg_4_0.saleContainer:getChildByName("skin_ticket"):setVisible(true)
				arg_4_0.saleContainer:getChildByName("diamond"):setVisible(false)
			end

			local var_4_0 = arg_4_0.saleContainer:getChildByName("price_now"):getContentSize()

			arg_4_0.saleContainer:getChildByName("skin_ticket"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now"):getPositionX() + var_4_0.width * 0.6)
			arg_4_0.saleContainer:getChildByName("diamond"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now"):getPositionX() + var_4_0.width * 0.6)
		end
	else
		arg_4_0.priceContainer = arg_4_0:contentView():nodeByName("price_container2")
		arg_4_0.saleContainer = arg_4_0:contentView():nodeByName("sale_container2")

		arg_4_0.priceContainer:setVisible(true)
		arg_4_0.saleContainer:setVisible(true)
		arg_4_0.saleContainer:getChildByName("diamond"):setVisible(false)
		arg_4_0.saleContainer:getChildByName("old_suipian"):setVisible(false)
		arg_4_0.saleContainer:getChildByName("old_ticket"):setVisible(false)
		arg_4_0.saleContainer:getChildByName("skin_ticket"):setVisible(false)

		if arg_4_0.saleType == var_0_8.ITEM then
			arg_4_0.saleContainer:getChildByName("diamond"):setVisible(true)
			arg_4_0.saleContainer:getChildByName("skin_ticket"):setVisible(true)
			arg_4_0.saleContainer:getChildByName("price_now1"):setString(arg_4_0.nowPrice[2])
			arg_4_0.saleContainer:getChildByName("price_now2"):setString(arg_4_0.nowPrice[3])

			local var_4_1 = arg_4_0.saleContainer:getChildByName("price_now1"):getContentSize()
			local var_4_2 = arg_4_0.saleContainer:getChildByName("price_now2"):getContentSize()

			arg_4_0.saleContainer:getChildByName("diamond"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now1"):getPositionX() + var_4_1.width * 0.5 + 1)
			arg_4_0.saleContainer:getChildByName("skin_ticket"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now2"):getPositionX() + var_4_2.width * 0.5 + 1)
		elseif arg_4_0.saleType == var_0_8.OLD_TICKET_SKIN then
			arg_4_0.saleContainer:getChildByName("old_ticket"):setVisible(true)
			arg_4_0.saleContainer:getChildByName("skin_ticket"):setVisible(true)
			arg_4_0.saleContainer:getChildByName("price_now1"):setString(arg_4_0.nowPrice[9])
			arg_4_0.saleContainer:getChildByName("price_now2"):setString(arg_4_0.nowPrice[3])

			local var_4_3 = arg_4_0.saleContainer:getChildByName("price_now1"):getContentSize()
			local var_4_4 = arg_4_0.saleContainer:getChildByName("price_now2"):getContentSize()

			arg_4_0.saleContainer:getChildByName("old_ticket"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now1"):getPositionX() + var_4_3.width * 0.5 + 1)
			arg_4_0.saleContainer:getChildByName("skin_ticket"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now2"):getPositionX() + var_4_4.width * 0.5 + 1)

			if arg_4_0.ecoNum == 0 then
				arg_4_0.saleContainer:getChildByName("price_line"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("price_now1"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("old_ticket"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("price_now2"):setPositionX(62.5)
				arg_4_0.saleContainer:getChildByName("skin_ticket"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now2"):getPositionX() + var_4_4.width * 0.5 + 1)
			end
		elseif arg_4_0.saleType == var_0_8.OLD_SUIPIAN_SKIN then
			arg_4_0.saleContainer:getChildByName("old_suipian"):setVisible(true)
			arg_4_0.saleContainer:getChildByName("skin_ticket"):setVisible(true)
			arg_4_0.saleContainer:getChildByName("price_now1"):setString(arg_4_0.nowPrice[10])
			arg_4_0.saleContainer:getChildByName("price_now2"):setString(arg_4_0.nowPrice[3])

			local var_4_5 = arg_4_0.saleContainer:getChildByName("price_now1"):getContentSize()
			local var_4_6 = arg_4_0.saleContainer:getChildByName("price_now2"):getContentSize()

			arg_4_0.saleContainer:getChildByName("old_suipian"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now1"):getPositionX() + var_4_5.width * 0.5 + 1)
			arg_4_0.saleContainer:getChildByName("skin_ticket"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now2"):getPositionX() + var_4_6.width * 0.5 + 1)

			if arg_4_0.suipianNum == 0 then
				arg_4_0.saleContainer:getChildByName("price_line"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("price_now1"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("old_suipian"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("price_now2"):setPositionX(62.5)
				arg_4_0.saleContainer:getChildByName("skin_ticket"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now2"):getPositionX() + var_4_6.width * 0.5 + 1)
			end
		elseif arg_4_0.saleType == var_0_8.OLD_TICKET_CRYSTAL then
			arg_4_0.saleContainer:getChildByName("old_ticket"):setVisible(true)
			arg_4_0.saleContainer:getChildByName("diamond"):setVisible(true)
			arg_4_0.saleContainer:getChildByName("price_now1"):setString(arg_4_0.nowPrice[9])
			arg_4_0.saleContainer:getChildByName("price_now2"):setString(arg_4_0.nowPrice[2])

			local var_4_7 = arg_4_0.saleContainer:getChildByName("price_now1"):getContentSize()
			local var_4_8 = arg_4_0.saleContainer:getChildByName("price_now2"):getContentSize()

			arg_4_0.saleContainer:getChildByName("old_ticket"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now1"):getPositionX() + var_4_7.width * 0.5 + 1)
			arg_4_0.saleContainer:getChildByName("diamond"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now2"):getPositionX() + var_4_8.width * 0.5 + 1)

			if arg_4_0.ecoNum == 0 then
				arg_4_0.saleContainer:getChildByName("price_line"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("price_now1"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("old_ticket"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("price_now2"):setPositionX(62.5)
				arg_4_0.saleContainer:getChildByName("diamond"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now2"):getPositionX() + var_4_8.width * 0.5 + 1)
			end
		elseif arg_4_0.saleType == var_0_8.OLD_SUIPIAN_CRYSTAL then
			arg_4_0.saleContainer:getChildByName("old_suipian"):setVisible(true)
			arg_4_0.saleContainer:getChildByName("diamond"):setVisible(true)
			arg_4_0.saleContainer:getChildByName("price_now1"):setString(arg_4_0.nowPrice[10])
			arg_4_0.saleContainer:getChildByName("price_now2"):setString(arg_4_0.nowPrice[2])

			local var_4_9 = arg_4_0.saleContainer:getChildByName("price_now1"):getContentSize()
			local var_4_10 = arg_4_0.saleContainer:getChildByName("price_now2"):getContentSize()

			arg_4_0.saleContainer:getChildByName("old_suipian"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now1"):getPositionX() + var_4_9.width * 0.5 + 1)
			arg_4_0.saleContainer:getChildByName("diamond"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now2"):getPositionX() + var_4_10.width * 0.5 + 1)

			if arg_4_0.suipianNum == 0 then
				arg_4_0.saleContainer:getChildByName("price_line"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("price_now1"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("old_suipian"):setVisible(false)
				arg_4_0.saleContainer:getChildByName("price_now2"):setPositionX(62.5)
				arg_4_0.saleContainer:getChildByName("diamond"):setPositionX(arg_4_0.saleContainer:getChildByName("price_now2"):getPositionX() + var_4_10.width * 0.5 + 1)
			end
		end
	end

	if arg_4_0.ownSkin == 1 then
		if arg_4_0.priceContainer then
			arg_4_0.priceContainer:setVisible(false)
		end

		arg_4_0:contentView():nodeByName("skin_shadow_container"):setVisible(true)
		arg_4_0:contentView():nodeByName("had_txt"):setString(var_0_5:translation("SKIN_SHOP_CELL_TXT1"))
	else
		if arg_4_0.priceContainer then
			arg_4_0.priceContainer:setVisible(true)
		end

		arg_4_0:contentView():nodeByName("skin_shadow_container"):setVisible(false)
	end
end

function var_0_0.initContainer(arg_5_0)
	arg_5_0:contentView():nodeByName("price_container1"):setVisible(false)
	arg_5_0:contentView():nodeByName("price_container2"):setVisible(false)
	arg_5_0:contentView():nodeByName("sale_container1_1"):setVisible(false)
	arg_5_0:contentView():nodeByName("sale_container1_2"):setVisible(false)
	arg_5_0:contentView():nodeByName("sale_container2"):setVisible(false)
	arg_5_0:contentView():nodeByName("skin_shadow_container"):setVisible(false)

	arg_5_0.iconImg = arg_5_0:contentView():nodeByName("card_container")

	local var_5_0 = arg_5_0.itemId
	local var_5_1 = var_0_2:skinPartner(var_5_0)
	local var_5_2 = var_0_2:skinModel(var_5_0)
	local var_5_3 = var_0_6.new()

	var_5_3 = arg_5_0.selfPlayer:getHeroIgnoreAwaken(var_5_1) or var_5_3:populateWithTableID(var_5_1)

	local var_5_4 = xyd.SpriteLoader.new(xyd.tables.model:card(var_5_2), nil, nil, xyd.DefaultImageType.HERO_CARD)

	var_5_4:setScale(0.4)

	local var_5_5 = arg_5_0.iconImg:getContentSize()
	local var_5_6 = cc.ClippingNode:create()
	local var_5_7 = display.newScale9Sprite("images/line_mask.png", 0, 0, var_5_5)

	var_5_7:setAnchorPoint(0, 0)
	var_5_6:setStencil(var_5_7)
	var_5_6:addChild(var_5_4)
	var_5_4:setAnchorPoint(0.5, 0.5)
	var_5_4:setPosition(var_5_5.width / 2, var_5_5.height / 2)
	var_5_6:addTo(arg_5_0.iconImg)

	local var_5_8 = xyd.tables.item:name(var_5_0)

	arg_5_0:contentView():nodeByName("name"):setString(var_5_8)

	if arg_5_0.showDiscount == false then
		arg_5_0:contentView():nodeByName("new_container"):setVisible(false)
	end
end

function var_0_0.isHasSkin(arg_6_0, arg_6_1)
	local var_6_0 = true

	if arg_6_0.selfPlayer:getBackpack():getItemNumByID(arg_6_1) <= 0 then
		var_6_0 = false
	end

	return var_6_0
end

function var_0_0.contentView(arg_7_0)
	if arg_7_0.contentView_ == nil then
		arg_7_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_7_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/skin_shop_window/skin_shop_cell.csb"))
		arg_7_0.contentView_:addTo(arg_7_0)
		arg_7_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_7_0.contentView_
end

return var_0_0
