local var_0_0 = class("InscriptionEquipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 4
local var_0_3 = 7

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.inscription = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
	arg_1_0.typeBtns = {}
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.inscriptionType = arg_1_2.inscript_type
	arg_1_0.currentLevel = var_0_3
	arg_1_0.itemID = arg_1_0.hero:getInscriptItem(arg_1_0.inscriptionType)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayerClickClose()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("INSCRIPTION_TEXT_10"))
	arg_4_0:nodeByName("txt_unset"):setString(var_0_1:translation("INSCRIPTION_TEXT_11"))
	arg_4_0:nodeByName("not_equiped_text"):setString(var_0_1:translation("NOT_SET_INSCRIPTION_TIP"))
	arg_4_0:nodeByName("not_equiped_text"):enableOutline(cc.c4b(126, 162, 182, 255), 2)

	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.inscriptionList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.inscriptionList:setDelegate(handler(arg_4_0, arg_4_0.inscriptionListDelegate))
	arg_4_0.inscriptionList:setBounceable(true)
	arg_4_0.inscriptionList:setTouchType(false)
	arg_4_0:updateInscriptionList()
	arg_4_0:updateNoInscriptionTips()

	arg_4_0.typeScroll = arg_4_0:nodeByName("type_scroll")

	local var_4_1 = arg_4_0.typeScroll:getContentSize()

	arg_4_0.typeList = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.typeScroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.typeList:setBounceable(false)
	arg_4_0.typeList:setTouchType(false)
	arg_4_0:typeListLayout()
	arg_4_0:updateTypeItemsBrightStyle()
	arg_4_0:updateCurrentEquip()
	arg_4_0:setButtonClick()
end

function var_0_0.updateNoInscriptionTips(arg_5_0)
	local var_5_0 = arg_5_0.inscription:levelName(arg_5_0.currentLevel)
	local var_5_1 = xyd.tables.inscription:getItemIDsBaseOnTypeAndLevel(arg_5_0.inscriptionType, arg_5_0.currentLevel)
	local var_5_2 = xyd.tables.inscription:name(var_5_1[1])

	if #arg_5_0.listItems == 0 then
		arg_5_0:nodeByName("no_inscription"):setVisible(true)
		arg_5_0:nodeByName("no_inscription_txt_1"):setString(var_0_1:translation("NO_INSCRIPTION_TIP"))
		arg_5_0:nodeByName("no_inscription_txt_2"):setString(var_5_2)
	else
		arg_5_0:nodeByName("no_inscription"):setVisible(false)
	end
end

function var_0_0.updateCurrentEquip(arg_6_0)
	local var_6_0 = arg_6_0.hero:getInscriptItem(arg_6_0.inscriptionType)

	if not var_6_0 then
		arg_6_0:nodeByName("equiped_container"):setVisible(false)
		arg_6_0:nodeByName("not_equiped_text"):setVisible(true)

		return
	else
		arg_6_0:nodeByName("equiped_container"):setVisible(true)
		arg_6_0:nodeByName("not_equiped_text"):setVisible(false)
	end

	arg_6_0.inscription:setInscriptionInfo(arg_6_0:nodeByName("equiped_container"), var_6_0, true)
end

function var_0_0.setButtonClick(arg_7_0)
	arg_7_0:nodeByName("unequip_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			if arg_7_0.selfPlayer.crystal >= xyd.tables.misc.removeInscriptionCost then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("SURE_COST_EQUIP_INSCRIPTION_TIP1"), xyd.tables.misc.removeInscriptionCost), function()
					arg_7_0:doRemoveInscription()
				end, nil, nil, arg_7_0.colorMode)
			else
				arg_7_0:notEnoughMoney()
			end
		end
	end)
	arg_7_0:nodeByName("inscription_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			if xyd.WindowManager.get():isWindowOpen("inscription") then
				xyd.WindowManager.get():closeWindow("hero_main")
				xyd.WindowManager.get():closeWindow("inscription_suit")
			else
				xyd.WindowManager.get():openWindow("inscription")
			end

			xyd.WindowManager.get():closeWindow(arg_7_0)
		end
	end)
end

function var_0_0.inscriptionListDelegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return #arg_11_0.listItems
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_0
		local var_11_1 = arg_11_0.inscriptionList:dequeueItem()

		if not var_11_1 then
			var_11_1 = arg_11_0.inscriptionList:newItem()
		else
			var_11_1:removeAllChildren(false)
		end

		local var_11_2 = arg_11_0:createListContent(arg_11_0.listItems[arg_11_3].itemID)
		local var_11_3 = var_11_2:getWidth()
		local var_11_4 = var_11_2:getHeight()

		var_11_1:setItemSize(var_11_3, var_11_4)
		var_11_1:addContent(var_11_2)

		return var_11_1
	end
end

function var_0_0.createListContent(arg_12_0, arg_12_1)
	local var_12_0 = display.newNode()
	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/inscription/equip/inscription_item.csb")
	local var_12_2 = var_12_1:getChildByName("container")

	xyd.setItemBorder(var_12_2:getChildByName("icon_container"), arg_12_1, nil, nil, nil)
	var_12_2:getChildByName("name_txt"):setString(xyd.tables.item:name(arg_12_1))
	arg_12_0.inscription:setInscriptionInfo(var_12_2, arg_12_1, true)

	local var_12_3 = var_12_2:getChildByName("set_btn")

	var_12_3:getChildByName("txt_set"):setString(var_0_1:translation("INSCRIPTION_TEXT_12"))
	var_12_3:addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended and not arg_12_0.scrollViewMoved_ then
			local var_13_0 = {
				item_id = arg_12_1,
				partner_id = arg_12_0.hero:getHeroID()
			}

			if arg_12_0.itemID and arg_12_0.selfPlayer.crystal >= xyd.tables.misc.removeInscriptionCost then
				var_13_0.replace_item_id = arg_12_0.itemID

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("SURE_COST_EQUIP_INSCRIPTION_TIP2"), xyd.tables.misc.removeInscriptionCost), function()
					arg_12_0:doInsertInscription(var_13_0)
				end, nil, nil, arg_12_0.colorMode)
			elseif arg_12_0.itemID and arg_12_0.selfPlayer.crystal < xyd.tables.misc.removeInscriptionCost then
				arg_12_0:notEnoughMoney()
			else
				arg_12_0:doInsertInscription(var_13_0)
			end
		end
	end)
	var_12_1:addTo(var_12_0)
	var_12_1:setAnchorPoint(cc.p(0, 0))
	var_12_0:setContentSize(var_12_2:getContentSize().width, var_12_2:getContentSize().height + 5)
	var_12_1:setPositionY(2.5)
	var_12_1:setName("source")

	return var_12_0
end

function var_0_0.notEnoughMoney(arg_15_0)
	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
		local var_16_0 = {}

		var_16_0.windowState = true

		xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
	end, nil, nil, arg_15_0.colorMode)
end

function var_0_0.doRemoveInscription(arg_17_0)
	local var_17_0 = {
		item_id = arg_17_0.itemID,
		partner_id = arg_17_0.hero:getHeroID()
	}

	arg_17_0.inscription:remove(var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			arg_17_0.hero:setInscriptItems(arg_18_1.inscript_items)

			arg_17_0.itemID = nil

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.FRESH_EQUIPED_INSCRIPTION
			})
			arg_17_0:updateCurrentEquip()
			arg_17_0:updateInscriptionList()
			arg_17_0:updateNoInscriptionTips()
		end
	end)
end

function var_0_0.doInsertInscription(arg_19_0, arg_19_1)
	arg_19_0.inscription:insert(arg_19_1, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			arg_19_0.hero:setInscriptItems(arg_20_1.inscript_items)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.FRESH_EQUIPED_INSCRIPTION
			})
			xyd.WindowManager.get():closeWindow(arg_19_0)
		end
	end)
end

function var_0_0.typeListLayout(arg_21_0)
	for iter_21_0 = 1, var_0_3 do
		local var_21_0
		local var_21_1 = arg_21_0.typeList:dequeueItem()

		if not var_21_1 then
			var_21_1 = arg_21_0.typeList:newItem()
		else
			var_21_1:removeAllChildren(false)
		end

		local var_21_2 = arg_21_0:createTypeListContent(var_0_3 - iter_21_0 + 1)
		local var_21_3 = var_21_2:getWidth()
		local var_21_4 = var_21_2:getHeight()

		var_21_1:setItemSize(var_21_3, var_21_4)
		var_21_1:addContent(var_21_2)
		arg_21_0.typeList:addItem(var_21_1)
	end

	arg_21_0.typeList:reload()
end

function var_0_0.createTypeListContent(arg_22_0, arg_22_1)
	local var_22_0 = display.newNode()
	local var_22_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/inscription/equip/type_item.csb")
	local var_22_2 = var_22_1:getChildByName("container")

	var_22_2:getChildByName("txt_name"):setString(var_0_1:translation("INSCRIPTION_TYPE_" .. arg_22_1))

	arg_22_0.typeBtns[arg_22_1] = var_22_2:getChildByName("type_btn")

	var_22_2:getChildByName("type_btn"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended and not arg_22_0.scrollViewMoved_ then
			arg_22_0.currentLevel = arg_22_1

			arg_22_0:updateInscriptionList()
			arg_22_0:updateNoInscriptionTips()
			arg_22_0:updateTypeItemsBrightStyle()
		end
	end)
	var_22_1:addTo(var_22_0)
	var_22_1:setAnchorPoint(cc.p(0, 0))
	var_22_0:setContentSize(var_22_2:getContentSize())
	var_22_1:setName("source")

	return var_22_0
end

function var_0_0.updateInscriptionList(arg_24_0)
	arg_24_0.listItems = arg_24_0.inscription:getInscriptionItemsBaseOnTypeAndLevel(arg_24_0.inscriptionType, arg_24_0.currentLevel, arg_24_0.hero)

	arg_24_0.inscriptionList:reload()
end

function var_0_0.updateTypeItemsBrightStyle(arg_25_0)
	for iter_25_0 = 1, #arg_25_0.typeBtns do
		if iter_25_0 == arg_25_0.currentLevel then
			arg_25_0.typeBtns[iter_25_0]:setTouchEnabled(false)
			arg_25_0.typeBtns[iter_25_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_25_0.typeBtns[iter_25_0]:setTouchEnabled(true)
			arg_25_0.typeBtns[iter_25_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.scrollListener(arg_26_0, arg_26_1)
	if arg_26_1.name == "began" then
		arg_26_0.scrollViewMoved_ = false
		arg_26_0.prevY_ = arg_26_1.y
	elseif arg_26_1.name == "moved" and 5 <= math.abs(arg_26_1.y - arg_26_0.prevY_) then
		arg_26_0.scrollViewMoved_ = true
	end
end

return var_0_0
