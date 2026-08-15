local var_0_0 = class("ShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.model
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.avartarMall
local var_0_6 = xyd.tables.skinSkill
local var_0_7 = xyd.tables.avartarMallActivity
local var_0_8 = xyd.tables.ecoType
local var_0_9 = xyd.tables.misc
local var_0_10 = xyd.AssetLoader.get()
local var_0_11 = 24
local var_0_12 = 99999999
local var_0_13 = 1
local var_0_14 = var_0_9.skinTicketId
local var_0_15 = var_0_8:getEcoPath("crystal")
local var_0_16 = var_0_8:getEcoPath("skin_coin")
local var_0_17 = var_0_8:getEcoPath("skin_fragment")
local var_0_18 = "windows/skin_shop_window/detail/old_skin_coin.png"
local var_0_19 = {
	FILTER = 1,
	SEARCH = 2
}
local var_0_20 = {
	CRYSTAL = 2,
	BUY = 1,
	ITEM = 4,
	OLD_TICKET_SKIN = 5,
	OLD_SUIPIAN = 10,
	ALL = 11,
	OLD_TICKET = 9,
	OLD_SUIPIAN_CRYSTAL = 8,
	SKIN_TICKET = 3,
	OLD_TICKET_CRYSTAL = 7,
	OLD_SUIPIAN_SKIN = 6
}
local var_0_21 = {
	DOWN = 3,
	UP = 2,
	DEFAULT = 1
}
local var_0_22 = {
	STRENGTH = 1,
	WISE = 2,
	AGILE = 3
}
local var_0_23 = {
	BACK = 4,
	FRONT = 2,
	MIDDLE = 3
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.searchTxt = ""
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.skinShop = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.sortType = var_0_21.DEFAULT
	arg_1_0.saleType = var_0_20.ALL
	arg_1_0.curState = var_0_19.FILTER
	arg_1_0.advancedFilter = false
	arg_1_0.posFilter = true
	arg_1_0.ownFilter = false
	arg_1_0.skillFilter = false
	arg_1_0.ownSkin = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		isEcoBar = 0
	})
	arg_2_0:addEcoSidebar()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.coinTip = xyd.AssetLoader.get():loadNodeFromJson("windows/skin_shop_window/detail/coin_tip.csb")

	arg_3_0.coinTip:setPosition(1260, 660)
	arg_3_0.coinTip:setVisible(false)
	arg_3_0:nodeByName("background"):addChild(arg_3_0.coinTip)

	local var_3_0 = arg_3_0.coinTip:getChildByName("container")
	local var_3_1 = var_3_0:getContentSize()
	local var_3_2 = xyd.createLabel(22, cc.c3b(255, 255, 255))

	var_3_2:setAnchorPoint(0, 1)
	var_3_2:setWidth(var_3_1.width - 30)
	var_3_2:setLineHeight(28)
	var_3_2:setString(var_0_4:translation("SKIN_SHOP_SKIN_COIN_TIP"))

	local var_3_3 = var_3_2:getContentSize()

	var_3_0:setContentSize(var_3_1.width, var_3_3.height + 30)
	var_3_2:setPosition((var_3_1.width - var_3_3.width) / 2, var_3_3.height + 15)
	var_3_0:addChild(var_3_2)
	arg_3_0:getSkinInfo()
	arg_3_0:initAllTxt()

	arg_3_0.container = arg_3_0:nodeByName("list_container")

	arg_3_0:getDiscountActivityInfo()
	arg_3_0:initFilter()
	arg_3_0:initSearchBox()
	arg_3_0:addButton()
	arg_3_0:updateSkinList()
end

function var_0_0.getSkinInfo(arg_4_0)
	arg_4_0:updateEco()
end

function var_0_0.addEcoSidebar(arg_5_0)
	arg_5_0:nodeByName("eco_sidebar"):removeAllChildren()

	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_widgets/eco_display_sidebar.csb")

	var_5_0:setPosition(-120, 0)
	arg_5_0:nodeByName("eco_sidebar"):addChild(var_5_0)

	local var_5_1 = var_5_0:getChildByName("background")
	local var_5_2 = var_5_1:getChildByName("eco_1")
	local var_5_3 = xyd.AssetLoader.get():loadSprite(var_0_16)

	var_5_3:setPosition(var_5_2:getChildByName("pos_icon_1"):getPosition())
	var_5_2:addChild(var_5_3)

	arg_5_0.skinCoinTxt = var_5_2:getChildByName("txt_eco_val_1")

	arg_5_0.skinCoinTxt:setString(xyd.num2ThousandsStr(arg_5_0.selfPlayer.skinCoin))
	var_5_2:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_5_0.coinTip:setVisible(true)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			arg_5_0.coinTip:setVisible(false)
		elseif arg_6_1 == ccui.TouchEventType.canceled then
			arg_5_0.coinTip:setVisible(false)
		end
	end)

	local var_5_4 = var_5_1:getChildByName("eco_2")
	local var_5_5 = xyd.AssetLoader.get():loadSprite(var_0_15)

	var_5_5:setPosition(var_5_4:getChildByName("pos_icon_2"):getPosition())
	var_5_4:addChild(var_5_5)

	arg_5_0.crystalTxt = var_5_4:getChildByName("txt_eco_val_2")

	arg_5_0.crystalTxt:setString(xyd.num2ThousandsStr(arg_5_0.selfPlayer.crystal))

	local var_5_6 = 2

	if arg_5_0.selfPlayer.skinFragment > 0 then
		var_5_6 = var_5_6 + 1

		local var_5_7 = var_5_1:getChildByName("eco_" .. var_5_6)
		local var_5_8 = xyd.AssetLoader.get():loadSprite(var_0_17)

		var_5_8:setPosition(var_5_7:getChildByName("pos_icon_" .. var_5_6):getPosition())
		var_5_7:addChild(var_5_8)

		arg_5_0.fragmentTxt = var_5_7:getChildByName("txt_eco_val_" .. var_5_6)

		arg_5_0.fragmentTxt:setString(xyd.num2ThousandsStr(arg_5_0.selfPlayer.skinFragment))
	else
		arg_5_0.fragmentTxt = nil
	end

	if arg_5_0.backpack:getItemNumByID(var_0_14) > 0 then
		var_5_6 = var_5_6 + 1

		local var_5_9 = var_5_1:getChildByName("eco_" .. var_5_6)
		local var_5_10 = xyd.AssetLoader.get():loadSprite(var_0_18)

		var_5_10:setPosition(var_5_9:getChildByName("pos_icon_" .. var_5_6):getPosition())
		var_5_9:addChild(var_5_10)

		arg_5_0.oldCoinTxt = var_5_9:getChildByName("txt_eco_val_" .. var_5_6)

		arg_5_0.oldCoinTxt:setString(xyd.num2ThousandsStr(arg_5_0.backpack:getItemNumByID(var_0_14)))
	else
		arg_5_0.oldCoinTxt = nil
	end

	if var_5_6 < 4 then
		for iter_5_0 = var_5_6 + 1, 4 do
			var_5_1:getChildByName("eco_" .. iter_5_0):setVisible(false)
		end
	end
end

function var_0_0.updateEco(arg_7_0)
	local var_7_0 = arg_7_0.crystalTxt:getString()
	local var_7_1 = xyd.num2ThousandsStr(arg_7_0.selfPlayer.crystal)

	if var_7_0 ~= var_7_1 then
		arg_7_0.crystalTxt:setString(var_7_1)

		local var_7_2 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_7_3 = cc.Spawn:create(var_7_2)

		arg_7_0.crystalTxt:runAction(var_7_3)
	end

	local var_7_4 = arg_7_0.skinCoinTxt:getString()
	local var_7_5 = xyd.num2ThousandsStr(arg_7_0.selfPlayer.skinCoin)

	if var_7_4 ~= var_7_5 then
		arg_7_0.skinCoinTxt:setString(var_7_5)

		local var_7_6 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_7_7 = cc.Spawn:create(var_7_6)

		arg_7_0.skinCoinTxt:runAction(var_7_7)
	end

	if arg_7_0.fragmentTxt then
		local var_7_8 = arg_7_0.fragmentTxt:getString()
		local var_7_9 = xyd.num2ThousandsStr(arg_7_0.selfPlayer.skinFragment)

		if var_7_8 ~= var_7_9 then
			arg_7_0.fragmentTxt:setString(var_7_9)

			local var_7_10 = transition.sequence({
				cc.ScaleTo:create(0.3, 1.5),
				cc.ScaleTo:create(0.3, 1)
			})
			local var_7_11 = cc.Spawn:create(var_7_10)

			arg_7_0.fragmentTxt:runAction(var_7_11)
		end
	end

	if arg_7_0.oldCoinTxt then
		local var_7_12 = arg_7_0.oldCoinTxt:getString()
		local var_7_13 = xyd.num2ThousandsStr(arg_7_0.backpack:getItemNumByID(var_0_14))

		if var_7_12 ~= var_7_13 then
			arg_7_0.oldCoinTxt:setString(var_7_13)

			local var_7_14 = transition.sequence({
				cc.ScaleTo:create(0.3, 1.5),
				cc.ScaleTo:create(0.3, 1)
			})
			local var_7_15 = cc.Spawn:create(var_7_14)

			arg_7_0.oldCoinTxt:runAction(var_7_15)
		end
	end
end

function var_0_0.initFilter(arg_8_0)
	arg_8_0.heroTypeFilter = {}
	arg_8_0.heroDistanceTypeFilter = {}
	arg_8_0.heroTypeFilter[var_0_22.STRENGTH] = true
	arg_8_0.heroTypeFilter[var_0_22.WISE] = true
	arg_8_0.heroTypeFilter[var_0_22.AGILE] = true
	arg_8_0.heroDistanceTypeFilter[var_0_23.FRONT] = true
	arg_8_0.heroDistanceTypeFilter[var_0_23.MIDDLE] = true
	arg_8_0.heroDistanceTypeFilter[var_0_23.BACK] = true
end

function var_0_0.initSearchBox(arg_9_0)
	local var_9_0 = "windows/skin_shop_window/input_box.png"

	arg_9_0.searchBox = ccui.EditBox:create(arg_9_0:nodeByName("input_box"):getContentSize(), var_9_0)

	arg_9_0.searchBox:setAnchorPoint(0, 0)
	arg_9_0.searchBox:pos(0, 0):addTo(arg_9_0:nodeByName("input_box"))
	arg_9_0.searchBox:setFont(var_0_10.FONT_NAME, var_0_11)
	arg_9_0.searchBox:setFontColor(cc.c3b(0, 0, 0))
	arg_9_0.searchBox:setMaxLength(8)
	arg_9_0.searchBox:setInputMode(6)
	arg_9_0.searchBox:registerScriptEditBoxHandler(handler(arg_9_0, arg_9_0.searchBoxHandler))
	arg_9_0.searchBox:setInputFlag(3)
	arg_9_0.searchBox:setLocalZOrder(1)
	arg_9_0:nodeByName("txt_input"):setLocalZOrder(2)
	arg_9_0:nodeByName("cancel_txt"):setVisible(false)
	arg_9_0:nodeByName("search_btn"):setVisible(true)
	arg_9_0:nodeByName("arrow"):setVisible(false)
end

function var_0_0.initAllTxt(arg_10_0)
	arg_10_0:nodeByName("txt_input"):setString(var_0_4:translation("SKIN_SHOP_TXT1"))
	arg_10_0:nodeByName("select_txt1"):setString(var_0_4:translation("SKIN_SHOP_TXT2"))
	arg_10_0:nodeByName("cancel_txt"):setString(var_0_4:translation("CANCEL"))
	arg_10_0:nodeByName("init_rand_txt"):setString(var_0_4:translation("SKIN_SHOP_TXT3"))
	arg_10_0:nodeByName("price_rand_txt"):setString(var_0_4:translation("SKIN_SHOP_TXT4"))
	arg_10_0:nodeByName("init_select_txt"):setString(var_0_4:translation("SKIN_SHOP_TXT5"))
	arg_10_0:nodeByName("all_txt"):setString(var_0_4:translation("SKIN_SHOP_TXT6"))
	arg_10_0:nodeByName("zuanshi_txt"):setString(var_0_4:translation("SKIN_SHOP_TXT7"))
	arg_10_0:nodeByName("skin_txt"):setString(var_0_4:translation("SKIN_SHOP_TXT8"))
	arg_10_0:nodeByName("item_txt"):setString(var_0_4:translation("SKIN_SHOP_TXT9"))
	arg_10_0:nodeByName("buy_txt"):setString(var_0_4:translation("SKIN_SHOP_TXT10"))
	arg_10_0:nodeByName("select_txt2"):setString(var_0_4:translation("SKIN_SHOP_TXT11"))
	arg_10_0:nodeByName("select_txt3"):setString(var_0_4:translation("SKIN_SHOP_TXT12"))
	arg_10_0:nodeByName("select_txt4"):setString(var_0_4:translation("SKIN_SHOP_TXT13"))
	arg_10_0:nodeByName("select_txt5"):setString(var_0_4:translation("SKIN_SHOP_TXT13"))
	arg_10_0:nodeByName("txt_front"):setString(var_0_4:translation("SKIN_SHOP_TXT14"))
	arg_10_0:nodeByName("txt_mid"):setString(var_0_4:translation("SKIN_SHOP_TXT15"))
	arg_10_0:nodeByName("txt_behind"):setString(var_0_4:translation("SKIN_SHOP_TXT16"))
	arg_10_0:nodeByName("txt_strength"):setString(var_0_4:translation("SKIN_SHOP_TXT17"))
	arg_10_0:nodeByName("txt_angle"):setString(var_0_4:translation("SKIN_SHOP_TXT18"))
	arg_10_0:nodeByName("txt_wise"):setString(var_0_4:translation("SKIN_SHOP_TXT19"))
	arg_10_0:nodeByName("select_txt7"):setString(var_0_4:translation("SKIN_SHOP_TXT20"))
	arg_10_0:nodeByName("select_txt6"):setString(var_0_4:translation("SKIN_SHOP_TXT21"))
	arg_10_0:nodeByName("have_got_txt"):setString(var_0_4:translation("SKIN_SHOP_TXT22"))
end

function var_0_0.updateTxtColor(arg_11_0)
	if arg_11_0.sortType == var_0_21.DEFAULT then
		arg_11_0:nodeByName("rand_sprite"):setVisible(false)
		arg_11_0:nodeByName("price_rand_txt"):setColor(cc.c4b(255, 255, 255, 255))
		arg_11_0:nodeByName("init_rand_txt"):setColor(cc.c4b(239, 196, 68, 255))
	else
		arg_11_0:nodeByName("rand_sprite"):setVisible(true)
		arg_11_0:nodeByName("init_rand_txt"):setColor(cc.c4b(255, 255, 255, 255))
		arg_11_0:nodeByName("price_rand_txt"):setColor(cc.c4b(239, 196, 68, 255))

		if arg_11_0.sortType == var_0_21.UP then
			arg_11_0:nodeByName("rand_sprite"):setFlippedY(false)
		else
			arg_11_0:nodeByName("rand_sprite"):setFlippedY(true)
		end
	end

	arg_11_0:nodeByName("all_txt"):setColor(cc.c4b(85, 81, 90, 255))
	arg_11_0:nodeByName("zuanshi_txt"):setColor(cc.c4b(85, 81, 90, 255))
	arg_11_0:nodeByName("skin_txt"):setColor(cc.c4b(85, 81, 90, 255))
	arg_11_0:nodeByName("item_txt"):setColor(cc.c4b(85, 81, 90, 255))
	arg_11_0:nodeByName("buy_txt"):setColor(cc.c4b(85, 81, 90, 255))

	if arg_11_0.saleType == var_0_20.ALL then
		arg_11_0:nodeByName("all_txt"):setColor(cc.c4b(255, 144, 0, 255))
	elseif arg_11_0.saleType == var_0_20.CRYSTAL then
		arg_11_0:nodeByName("zuanshi_txt"):setColor(cc.c4b(255, 144, 0, 255))
	elseif arg_11_0.saleType == var_0_20.SKIN_TICKET then
		arg_11_0:nodeByName("skin_txt"):setColor(cc.c4b(255, 144, 0, 255))
	elseif arg_11_0.saleType == var_0_20.ITEM then
		arg_11_0:nodeByName("item_txt"):setColor(cc.c4b(255, 144, 0, 255))
	elseif arg_11_0.saleType == var_0_20.BUY then
		arg_11_0:nodeByName("buy_txt"):setColor(cc.c4b(255, 144, 0, 255))
	end
end

function var_0_0.updateTxtNum(arg_12_0)
	local var_12_0 = 0
	local var_12_1 = #arg_12_0.ownSkin

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.ownSkin) do
		if iter_12_1 == 1 then
			var_12_0 = var_12_0 + 1
		end
	end

	arg_12_0:nodeByName("have_got_txt_num"):setString(var_12_0 .. "/" .. #arg_12_0.ownSkin)
end

function var_0_0.searchBoxHandler(arg_13_0, arg_13_1)
	if arg_13_1 == "return" then
		arg_13_0.searchTxt = arg_13_0.searchBox:getText()

		arg_13_0:updateInputTxt()
		arg_13_0.searchBox:setText("")
	elseif arg_13_1 == "began" then
		arg_13_0.searchTxt = ""

		arg_13_0:updateInputTxt()
		arg_13_0.searchBox:setText(text)
	end
end

function var_0_0.updateInputTxt(arg_14_0)
	if arg_14_0.searchTxt and arg_14_0.searchTxt == "" then
		arg_14_0:nodeByName("txt_input"):setString(var_0_4:translation("SKIN_SHOP_TXT1"))
	else
		arg_14_0:nodeByName("txt_input"):setString(arg_14_0.searchTxt)
	end
end

function var_0_0.addButton(arg_15_0)
	arg_15_0:nodeByName("search_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.began then
			-- block empty
		elseif arg_16_1 == ccui.TouchEventType.ended then
			if arg_15_0.searchTxt and arg_15_0.searchTxt == "" then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_4:translation("HERO_SEARCH_TIPS")
				})
			else
				arg_15_0.heroName = arg_15_0.searchTxt
				arg_15_0.curState = var_0_19.SEARCH
				arg_15_0.advancedFilter = false

				arg_15_0:updateState()
			end
		end
	end)
	arg_15_0:nodeByName("cancel_txt"):setTouchEnabled(true)
	arg_15_0:nodeByName("cancel_txt"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.began then
			arg_15_0.curState = var_0_19.FILTER

			arg_15_0:updateState()

			arg_15_0.searchTxt = ""

			arg_15_0.searchBox:setText("")
			arg_15_0:updateInputTxt()
		end
	end)
	arg_15_0:nodeByName("init_rand_txt"):setTouchEnabled(true)
	arg_15_0:nodeByName("init_rand_txt"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.began and arg_15_0.sortType ~= var_0_21.DEFAULT then
			arg_15_0.sortType = var_0_21.DEFAULT

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("price_rand_txt"):setTouchEnabled(true)
	arg_15_0:nodeByName("price_rand_txt"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.began then
			if arg_15_0.sortType == var_0_21.DEFAULT or arg_15_0.sortType == var_0_21.DOWN then
				arg_15_0.sortType = var_0_21.UP
			else
				arg_15_0.sortType = var_0_21.DOWN
			end

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("advanced_btn"):setTouchEnabled(true)
	arg_15_0:nodeByName("advanced_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "began" then
			arg_15_0.advancedFilter = not arg_15_0.advancedFilter

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("pos_select_btn"):setTouchEnabled(true)
	arg_15_0:nodeByName("pos_select_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
		if arg_21_0.name == "began" then
			arg_15_0.posFilter = not arg_15_0.posFilter

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("own_skin_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		if arg_22_0.name == "began" then
			arg_15_0.ownFilter = not arg_15_0.ownFilter

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("own_skill_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if arg_23_0.name == "began" then
			arg_15_0.skillFilter = not arg_15_0.skillFilter

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:setSelectCoiditionTouch(true)
	arg_15_0:nodeByName("all_txt"):addTouchEventListener(function(arg_24_0, arg_24_1)
		if arg_24_1 == ccui.TouchEventType.began and arg_15_0.saleType ~= var_0_20.ALL then
			arg_15_0.saleType = var_0_20.ALL

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("zuanshi_txt"):addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.began and arg_15_0.saleType ~= var_0_20.CRYSTAL then
			arg_15_0.saleType = var_0_20.CRYSTAL

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("skin_txt"):addTouchEventListener(function(arg_26_0, arg_26_1)
		if arg_26_1 == ccui.TouchEventType.began and arg_15_0.saleType ~= var_0_20.SKIN_TICKET then
			arg_15_0.saleType = var_0_20.SKIN_TICKET

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("item_txt"):addTouchEventListener(function(arg_27_0, arg_27_1)
		if arg_27_1 == ccui.TouchEventType.began and arg_15_0.saleType ~= var_0_20.ITEM then
			arg_15_0.saleType = var_0_20.ITEM

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("buy_txt"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.began and arg_15_0.saleType ~= var_0_20.BUY then
			arg_15_0.saleType = var_0_20.BUY

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:setPosFilterTouch(true)
	arg_15_0:nodeByName("select_front"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
		if arg_29_0.name == "began" then
			arg_15_0.heroDistanceTypeFilter[var_0_23.FRONT] = not arg_15_0.heroDistanceTypeFilter[var_0_23.FRONT]

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("select_mid"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
		if arg_30_0.name == "began" then
			arg_15_0.heroDistanceTypeFilter[var_0_23.MIDDLE] = not arg_15_0.heroDistanceTypeFilter[var_0_23.MIDDLE]

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("select_behind"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_31_0)
		if arg_31_0.name == "began" then
			arg_15_0.heroDistanceTypeFilter[var_0_23.BACK] = not arg_15_0.heroDistanceTypeFilter[var_0_23.BACK]

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("select_strength"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_32_0)
		if arg_32_0.name == "began" then
			arg_15_0.heroTypeFilter[var_0_22.STRENGTH] = not arg_15_0.heroTypeFilter[var_0_22.STRENGTH]

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("select_aglie"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_33_0)
		if arg_33_0.name == "began" then
			arg_15_0.heroTypeFilter[var_0_22.AGILE] = not arg_15_0.heroTypeFilter[var_0_22.AGILE]

			arg_15_0:updateSkinList()
		end
	end)
	arg_15_0:nodeByName("select_wise"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_34_0)
		if arg_34_0.name == "began" then
			arg_15_0.heroTypeFilter[var_0_22.WISE] = not arg_15_0.heroTypeFilter[var_0_22.WISE]

			arg_15_0:updateSkinList()
		end
	end)
end

function var_0_0.setSelectCoiditionTouch(arg_35_0, arg_35_1)
	arg_35_0:nodeByName("all_txt"):setTouchEnabled(arg_35_1)
	arg_35_0:nodeByName("zuanshi_txt"):setTouchEnabled(arg_35_1)
	arg_35_0:nodeByName("skin_txt"):setTouchEnabled(arg_35_1)
	arg_35_0:nodeByName("item_txt"):setTouchEnabled(arg_35_1)
	arg_35_0:nodeByName("buy_txt"):setTouchEnabled(arg_35_1)
end

function var_0_0.setAdvancedFilterTouch(arg_36_0, arg_36_1)
	arg_36_0:nodeByName("pos_select_btn"):setTouchEnabled(arg_36_1)
	arg_36_0:nodeByName("own_skin_btn"):setTouchEnabled(arg_36_1)
	arg_36_0:nodeByName("own_skill_btn"):setTouchEnabled(arg_36_1)
end

function var_0_0.setPosFilterTouch(arg_37_0, arg_37_1)
	arg_37_0:nodeByName("select_front"):setTouchEnabled(arg_37_1)
	arg_37_0:nodeByName("select_mid"):setTouchEnabled(arg_37_1)
	arg_37_0:nodeByName("select_behind"):setTouchEnabled(arg_37_1)
	arg_37_0:nodeByName("select_strength"):setTouchEnabled(arg_37_1)
	arg_37_0:nodeByName("select_aglie"):setTouchEnabled(arg_37_1)
	arg_37_0:nodeByName("select_wise"):setTouchEnabled(arg_37_1)
end

function var_0_0.updateShow(arg_38_0)
	arg_38_0:updateTxtColor()
	arg_38_0:updateTxtNum()

	if arg_38_0.advancedFilter == true then
		arg_38_0:nodeByName("advanced_btn"):getChildByName("on_point"):setVisible(true)
		arg_38_0:nodeByName("advanced_btn"):getChildByName("off_point"):setVisible(false)
		arg_38_0:setAdvancedFilterTouch(true)
		arg_38_0:setPosFilterTouch(arg_38_0.posFilter)
		arg_38_0:nodeByName("advanced_hide"):setVisible(false)
	else
		arg_38_0:nodeByName("advanced_btn"):getChildByName("on_point"):setVisible(false)
		arg_38_0:nodeByName("advanced_btn"):getChildByName("off_point"):setVisible(true)
		arg_38_0:setAdvancedFilterTouch(false)
		arg_38_0:setPosFilterTouch(false)
		arg_38_0:nodeByName("advanced_hide"):setVisible(true)
	end

	if arg_38_0.posFilter == true then
		arg_38_0:nodeByName("pos_select_btn"):getChildByName("on_point"):setVisible(true)
		arg_38_0:nodeByName("pos_select_btn"):getChildByName("off_point"):setVisible(false)
		arg_38_0:nodeByName("pos_select_hide"):setVisible(false)
	else
		arg_38_0:nodeByName("pos_select_btn"):getChildByName("on_point"):setVisible(false)
		arg_38_0:nodeByName("pos_select_btn"):getChildByName("off_point"):setVisible(true)
		arg_38_0:nodeByName("pos_select_hide"):setVisible(true)
	end

	if arg_38_0.ownFilter == true then
		arg_38_0:nodeByName("own_skin_btn"):getChildByName("on_point"):setVisible(true)
		arg_38_0:nodeByName("own_skin_btn"):getChildByName("off_point"):setVisible(false)
	else
		arg_38_0:nodeByName("own_skin_btn"):getChildByName("on_point"):setVisible(false)
		arg_38_0:nodeByName("own_skin_btn"):getChildByName("off_point"):setVisible(true)
	end

	if arg_38_0.skillFilter == true then
		arg_38_0:nodeByName("own_skill_btn"):getChildByName("on_point"):setVisible(true)
		arg_38_0:nodeByName("own_skill_btn"):getChildByName("off_point"):setVisible(false)
	else
		arg_38_0:nodeByName("own_skill_btn"):getChildByName("on_point"):setVisible(false)
		arg_38_0:nodeByName("own_skill_btn"):getChildByName("off_point"):setVisible(true)
	end

	if arg_38_0.heroDistanceTypeFilter[var_0_23.FRONT] == true then
		arg_38_0:nodeByName("select_front"):getChildByName("gou"):setVisible(true)
	else
		arg_38_0:nodeByName("select_front"):getChildByName("gou"):setVisible(false)
	end

	if arg_38_0.heroDistanceTypeFilter[var_0_23.MIDDLE] == true then
		arg_38_0:nodeByName("select_mid"):getChildByName("gou"):setVisible(true)
	else
		arg_38_0:nodeByName("select_mid"):getChildByName("gou"):setVisible(false)
	end

	if arg_38_0.heroDistanceTypeFilter[var_0_23.BACK] == true then
		arg_38_0:nodeByName("select_behind"):getChildByName("gou"):setVisible(true)
	else
		arg_38_0:nodeByName("select_behind"):getChildByName("gou"):setVisible(false)
	end

	if arg_38_0.heroTypeFilter[var_0_22.STRENGTH] == true then
		arg_38_0:nodeByName("select_strength"):getChildByName("gou"):setVisible(true)
	else
		arg_38_0:nodeByName("select_strength"):getChildByName("gou"):setVisible(false)
	end

	if arg_38_0.heroTypeFilter[var_0_22.AGILE] == true then
		arg_38_0:nodeByName("select_aglie"):getChildByName("gou"):setVisible(true)
	else
		arg_38_0:nodeByName("select_aglie"):getChildByName("gou"):setVisible(false)
	end

	if arg_38_0.heroTypeFilter[var_0_22.WISE] == true then
		arg_38_0:nodeByName("select_wise"):getChildByName("gou"):setVisible(true)
	else
		arg_38_0:nodeByName("select_wise"):getChildByName("gou"):setVisible(false)
	end
end

function var_0_0.updateSkinList(arg_39_0)
	arg_39_0:getSkinsData()
	arg_39_0:updateShow()

	if not arg_39_0.list then
		arg_39_0.list = cc.ui.UIListView.new({
			framingDuration = 0.2,
			framing = true,
			viewRect = cc.rect(0, 0, arg_39_0.container:getWidth(), 640),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_39_0.container):onScroll(handler(arg_39_0, arg_39_0.scrollListener))

		arg_39_0.list:setAnchorPoint(0, 0)
		arg_39_0.list:setPosition(0, 0)
		arg_39_0.list:setDelegate(handler(arg_39_0, arg_39_0.delegate))
		arg_39_0.list:reload()
		collectgarbage("collect")
	else
		arg_39_0.list:reload()
		collectgarbage("collect")
	end
end

function var_0_0.delegate(arg_40_0, arg_40_1, arg_40_2, arg_40_3)
	if cc.ui.UIListView.COUNT_TAG == arg_40_2 then
		return math.ceil(#arg_40_0.data / 5)
	elseif cc.ui.UIListView.CELL_TAG == arg_40_2 then
		local var_40_0
		local var_40_1 = arg_40_1:dequeueItem()

		if not var_40_1 then
			var_40_1 = arg_40_1:newItem()
		else
			var_40_1:removeAllChildren(false)
		end

		local var_40_2 = {}
		local var_40_3 = 1

		for iter_40_0 = 5 * arg_40_3 - 4, 5 * arg_40_3 do
			if not arg_40_0.data[iter_40_0] then
				break
			end

			var_40_2[var_40_3] = arg_40_0.data[iter_40_0]
			var_40_3 = var_40_3 + 1
		end

		local var_40_4 = {
			top = 0,
			left = 0,
			bottom = 6,
			right = 0
		}
		local var_40_5 = arg_40_0:createListCell(var_40_2, arg_40_3)
		local var_40_6 = var_40_5:getWidth()
		local var_40_7 = var_40_5:getHeight()

		var_40_1:setMargin(var_40_4)
		var_40_1:setItemSize(var_40_6, var_40_7)
		var_40_1:addContent(var_40_5)

		return var_40_1
	end
end

function var_0_0.createListCell(arg_41_0, arg_41_1, arg_41_2)
	local var_41_0 = import("app.windows.SkinShopCell")
	local var_41_1 = display.newNode()
	local var_41_2 = 5
	local var_41_3 = 205 * #arg_41_1 + (#arg_41_1 - 1) * var_41_2
	local var_41_4 = 286

	var_41_1:setContentSize(var_41_3, var_41_4)

	for iter_41_0, iter_41_1 in ipairs(arg_41_1) do
		local var_41_5 = var_41_0.new({
			skin = iter_41_1
		})

		var_41_5:layout()
		var_41_5:setAnchorPoint(0.5, 0.5)
		var_41_5:addTo(var_41_1)
		var_41_5:setPosition(191 * (iter_41_0 - 1), 0)
		var_41_5:contentView():nodeByName("card_bg"):setTouchEnabled(true)
		var_41_5:contentView():nodeByName("card_bg"):setTouchSwallowEnabled(false)
		var_41_5:contentView():nodeByName("card_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_42_0)
			if arg_42_0.name == "began" then
				var_41_5.contentView_:nodeByName("touch_container"):setScale(0.9)

				return true
			elseif arg_42_0.name == "ended" then
				var_41_5.contentView_:nodeByName("touch_container"):setScale(1)
				xyd.playButtonSound()

				local function var_42_0()
					if arg_41_0.fragmentTxt and arg_41_0.selfPlayer.skinFragment == 0 or arg_41_0.oldCoinTxt and arg_41_0.backpack:getItemNumByID(var_0_14) == 0 then
						arg_41_0:addEcoSidebar()
					end

					arg_41_0:updateEco()
					arg_41_0:updateSkinList()
				end

				if not arg_41_0.scrollViewMoved_ then
					local var_42_1 = {}
					local var_42_2 = 5 * arg_41_2 - 5 + iter_41_0

					var_42_1.id = arg_41_0.data[var_42_2].id
					var_42_1.ownSkin = arg_41_0.ownSkin[var_42_2]
					var_42_1.callback = var_42_0

					xyd.WindowManager.get():openWindow("skin_shop_detail_window", var_42_1)
				end
			end
		end)
		xyd.setItemAnimation(var_41_5, iter_41_0)
	end

	return var_41_1
end

function var_0_0.scrollListener(arg_44_0, arg_44_1)
	if arg_44_1.name == "began" then
		arg_44_0.scrollViewMoved_ = false
		arg_44_0.prevY_ = arg_44_1.y
	elseif arg_44_1.name == "moved" then
		if 20 <= math.abs(arg_44_1.y - arg_44_0.prevY_) then
			arg_44_0.scrollViewMoved_ = true
		end

		arg_44_0.scrollY = arg_44_0.list:getScrollNode():getPositionY()
	elseif arg_44_1.name == "scrollEnd" then
		arg_44_0.scrollY = arg_44_0.list:getScrollNode():getPositionY()
	end
end

function var_0_0.updateState(arg_45_0)
	if arg_45_0.curState == var_0_19.FILTER then
		arg_45_0.heroName = nil

		arg_45_0:updateSkinList()
		arg_45_0:nodeByName("cancel_txt"):setVisible(false)
		arg_45_0:nodeByName("search_btn"):setVisible(true)
	elseif arg_45_0.curState == var_0_19.SEARCH then
		arg_45_0:updateSkinList()
		arg_45_0:nodeByName("cancel_txt"):setVisible(true)
		arg_45_0:nodeByName("search_btn"):setVisible(false)
	end
end

function var_0_0.getSkinsData(arg_46_0)
	local var_46_0 = {}

	for iter_46_0, iter_46_1 in ipairs(arg_46_0.selfPlayer.heros_) do
		local var_46_1 = xyd.getOriginHeroId(iter_46_1:getTableID())

		if not var_46_0[var_46_1] then
			var_46_0[var_46_1] = iter_46_1
		end
	end

	arg_46_0.data = {}

	local var_46_2 = var_0_5:getAllSkins()

	for iter_46_2, iter_46_3 in ipairs(var_46_2) do
		iter_46_3.partner = var_0_6:getHeroID(iter_46_3.item)
		iter_46_3.skillID = var_0_6:getSkillID(iter_46_3.item)

		if arg_46_0.selfPlayer:hasSkin(iter_46_3.item) then
			arg_46_0.ownSkin[iter_46_2] = 1
		else
			arg_46_0.ownSkin[iter_46_2] = 0
		end

		iter_46_3.ownSkin = arg_46_0.ownSkin[iter_46_2]

		local var_46_3 = iter_46_3.partner
		local var_46_4 = xyd.getOriginHeroId(var_46_3)
		local var_46_5

		if var_46_0[var_46_4] then
			var_46_5 = var_46_0[var_46_4]

			if arg_46_0.heroName and not xyd.searchHeroByName(arg_46_0.heroName, var_46_5) then
				var_46_5 = nil
			end
		elseif var_46_3 < xyd.AWAKEN_HERO_START_ID and not xyd.isSuperHero(var_46_3) then
			var_46_5 = var_0_2.new()

			var_46_5:initUnCollected(var_46_3)

			if arg_46_0.heroName and not xyd.searchHeroByName(arg_46_0.heroName, var_46_5) then
				var_46_5 = nil
			end
		end

		if var_46_5 then
			local var_46_6 = false

			if arg_46_0.advancedFilter then
				if not var_46_6 and arg_46_0.posFilter then
					local var_46_7 = var_46_5:getDistanceType()

					if arg_46_0.heroDistanceTypeFilter[var_46_7] == false then
						var_46_6 = true
					end

					local var_46_8 = var_46_5:getHeroType()

					if arg_46_0.heroTypeFilter[var_46_8] == false then
						var_46_6 = true
					end
				end

				if not var_46_6 and arg_46_0.ownFilter and iter_46_3.ownSkin == 1 then
					var_46_6 = true
				end

				if not var_46_6 and arg_46_0.skillFilter and iter_46_3.skillID == 0 then
					var_46_6 = true
				end
			end

			if arg_46_0.saleType ~= var_0_20.ALL then
				if not var_46_6 and iter_46_3.saletype == var_0_20.ITEM then
					if arg_46_0.saleType == var_0_20.BUY then
						var_46_6 = true
					end
				elseif not var_46_6 and iter_46_3.saletype == var_0_20.OLD_TICKET_SKIN then
					if arg_46_0.saleType == var_0_20.BUY or arg_46_0.saleType == var_0_20.CRYSTAL or arg_46_0.saleType == var_0_20.ITEM then
						var_46_6 = true
					end
				elseif not var_46_6 and iter_46_3.saletype == var_0_20.OLD_SUIPIAN_SKIN then
					if arg_46_0.saleType == var_0_20.BUY or arg_46_0.saleType == var_0_20.CRYSTAL or arg_46_0.saleType == var_0_20.ITEM then
						var_46_6 = true
					end
				elseif not var_46_6 and iter_46_3.saletype == var_0_20.OLD_TICKET_CRYSTAL then
					if arg_46_0.saleType == var_0_20.BUY or arg_46_0.saleType == var_0_20.SKIN_TICKET or arg_46_0.saleType == var_0_20.ITEM then
						var_46_6 = true
					end
				elseif not var_46_6 and iter_46_3.saletype == var_0_20.OLD_SUIPIAN_CRYSTAL then
					if arg_46_0.saleType == var_0_20.BUY or arg_46_0.saleType == var_0_20.SKIN_TICKET or arg_46_0.saleType == var_0_20.ITEM then
						var_46_6 = true
					end
				elseif not var_46_6 and iter_46_3.saletype ~= arg_46_0.saleType then
					var_46_6 = true
				end
			end

			iter_46_3.nowprice = {}

			if arg_46_0.discountActivity[iter_46_3.saletype] and iter_46_3.discountActivity == 1 then
				for iter_46_4 = 1, 10 do
					if iter_46_3.discount[iter_46_4] then
						iter_46_3.nowprice[iter_46_4] = iter_46_3.discount[iter_46_4]
					end
				end

				iter_46_3.showDiscountTip = true
			else
				for iter_46_5 = 1, 10 do
					if iter_46_3.price[iter_46_5] then
						iter_46_3.nowprice[iter_46_5] = iter_46_3.price[iter_46_5]
					end
				end

				iter_46_3.showDiscountTip = false
			end

			if not var_46_6 then
				table.insert(arg_46_0.data, iter_46_3)
			end
		end
	end

	arg_46_0:sortData()
end

function var_0_0.getDiscountActivityInfo(arg_47_0)
	arg_47_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_47_0.discountActivity = {}
	arg_47_0.discountActivity[var_0_20.BUY] = arg_47_0:judgeDiscountActivity(var_0_7:actId(var_0_20.BUY))
	arg_47_0.discountActivity[var_0_20.CRYSTAL] = arg_47_0:judgeDiscountActivity(var_0_7:actId(var_0_20.CRYSTAL))
	arg_47_0.discountActivity[var_0_20.SKIN_TICKET] = arg_47_0:judgeDiscountActivity(var_0_7:actId(var_0_20.SKIN_TICKET))
	arg_47_0.discountActivity[var_0_20.ITEM] = arg_47_0:judgeDiscountActivity(var_0_7:actId(var_0_20.ITEM))
end

function var_0_0.judgeDiscountActivity(arg_48_0, arg_48_1)
	if arg_48_0.activities:isActivityOpen(arg_48_1) then
		return true
	end

	return false
end

function var_0_0.sortData(arg_49_0)
	if arg_49_0.sortType == var_0_21.UP then
		table.sort(arg_49_0.data, function(arg_50_0, arg_50_1)
			if arg_50_0.ownSkin ~= arg_50_1.ownSkin then
				return (arg_50_0.ownSkin or 0) < (arg_50_1.ownSkin or 0)
			elseif arg_50_0.price[arg_49_0.saleType] or arg_50_1.price[arg_49_0.saleType] then
				return (arg_50_0.price[arg_49_0.saleType] or var_0_12) < (arg_50_1.price[arg_49_0.saleType] or var_0_12)
			elseif arg_50_0.price[1] or arg_50_1.price[1] and arg_49_0.saleType ~= 1 then
				return (arg_50_0.price[1] or var_0_12) < (arg_50_1.price[1] or var_0_12)
			elseif arg_50_0.price[2] or arg_50_1.price[2] and arg_49_0.saleType ~= 2 then
				return (arg_50_0.price[2] or var_0_12) < (arg_50_1.price[2] or var_0_12)
			elseif arg_50_0.price[3] or arg_50_1.price[3] and arg_49_0.saleType ~= 3 then
				return (arg_50_0.price[3] or var_0_12) < (arg_50_1.price[3] or var_0_12)
			elseif arg_50_0.price[4] or arg_50_1.price[4] and arg_49_0.saleType ~= 4 then
				return (arg_50_0.price[4] or var_0_12) < (arg_50_1.price[4] or var_0_12)
			else
				return arg_50_0.id > arg_50_1.id
			end
		end)
	elseif arg_49_0.sortType == var_0_21.DOWN then
		table.sort(arg_49_0.data, function(arg_51_0, arg_51_1)
			if arg_51_0.ownSkin ~= arg_51_1.ownSkin then
				return (arg_51_0.ownSkin or 0) < (arg_51_1.ownSkin or 0)
			elseif arg_51_0.price[arg_49_0.saleType] or arg_51_1.price[arg_49_0.saleType] then
				return (arg_51_0.price[arg_49_0.saleType] or var_0_13) > (arg_51_1.price[arg_49_0.saleType] or var_0_13)
			elseif arg_51_0.price[1] or arg_51_1.price[1] and arg_49_0.saleType ~= 1 then
				return (arg_51_0.price[1] or var_0_13) > (arg_51_1.price[1] or var_0_13)
			elseif arg_51_0.price[2] or arg_51_1.price[2] and arg_49_0.saleType ~= 2 then
				return (arg_51_0.price[2] or var_0_13) > (arg_51_1.price[2] or var_0_13)
			elseif arg_51_0.price[3] or arg_51_1.price[3] and arg_49_0.saleType ~= 3 then
				return (arg_51_0.price[3] or var_0_13) > (arg_51_1.price[3] or var_0_13)
			elseif arg_51_0.price[4] or arg_51_1.price[4] and arg_49_0.saleType ~= 4 then
				return (arg_51_0.price[4] or var_0_13) > (arg_51_1.price[4] or var_0_13)
			else
				return arg_51_0.id > arg_51_1.id
			end
		end)
	else
		table.sort(arg_49_0.data, function(arg_52_0, arg_52_1)
			if arg_52_0.ownSkin ~= arg_52_1.ownSkin then
				return (arg_52_0.ownSkin or 0) < (arg_52_1.ownSkin or 0)
			else
				return arg_52_0.id > arg_52_1.id
			end
		end)
	end
end

return var_0_0
