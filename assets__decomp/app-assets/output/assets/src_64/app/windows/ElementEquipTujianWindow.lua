local var_0_0 = class("ElementEquipWindowTujian", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.elementEquip
local var_0_4 = xyd.tables.elementStrth
local var_0_5 = xyd.tables.item
local var_0_6 = xyd.tables.translation
local var_0_7 = xyd.tables.item
local var_0_8 = 4
local var_0_9 = {
	xyd.ItemType.ELEMENT_EQUIP
}
local var_0_10 = {
	left = 1,
	right = 2
}
local var_0_11 = {
	inBackpack = 3,
	equipping = 1,
	binding = 2
}
local var_0_12 = {
	strth = 2,
	decompose = 3,
	equip = 1
}
local var_0_13 = {
	takeoff = 2,
	equip = 1,
	change = 3
}
local var_0_14 = {}
local var_0_15 = xyd.tables.elementEquip:all_itemid()
local var_0_16 = {}
local var_0_17 = xyd.tables.elementEquip:all_id()

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.elementEquip = xyd.ModelManager.get():loadModel(xyd.ModelType.ELEMENT_EQUIP)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.pos = arg_1_2.pos
	arg_1_0.selectElement = 0
	arg_1_0.rightShowType = var_0_12.equip
	arg_1_0.isSpShow = true
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.maxSuperCampaign = arg_1_0.selfPlayer.super_campaign_id
	arg_1_0.maxNormalCampaign = arg_1_0.selfPlayer.normal_campaign_id
	arg_1_0.selectEffect = {}
	arg_1_0.equipLV = 1
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:updateItems()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	for iter_4_0 = 1, 3 do
		var_0_2.new({
			size = 432
		}):addTo(arg_4_0:nodeByName("pos_line" .. iter_4_0))
	end

	local var_4_0 = arg_4_0:nodeByName("list_equip"):getContentSize()

	arg_4_0.equipList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list_equip")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.equipList:setDelegate(handler(arg_4_0, arg_4_0.equipListDelegate))

	local var_4_1 = arg_4_0:nodeByName("list_comsume"):getContentSize()

	arg_4_0.strthList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list_comsume")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.strthList:setDelegate(handler(arg_4_0, arg_4_0.strthListDelegate))

	local var_4_2 = arg_4_0:nodeByName("list_dec_recourse"):getContentSize()

	arg_4_0.decList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_2.width, var_4_2.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list_dec_recourse")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.decList:setDelegate(handler(arg_4_0, arg_4_0.decListDelegate))

	local var_4_3 = arg_4_0:nodeByName("attr_container"):getContentSize()

	arg_4_0.descList = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_4_3.width, var_4_3.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_4_0:nodeByName("attr_container"))

	if arg_4_0.equips and arg_4_0.equips[arg_4_0.pos] ~= 0 then
		arg_4_0.equipID = arg_4_0.equips[arg_4_0.pos]
		arg_4_0.equipLV = 1
		arg_4_0.equippingType_ = var_0_11.equipping

		arg_4_0:findEquippingRightPos()
	else
		arg_4_0.equipID = nil
		arg_4_0.equipLV = nil
		arg_4_0.equippingType_ = nil
		arg_4_0.rightPos = nil
	end

	arg_4_0:initStringShow()
	arg_4_0:updateRightContainer()
	arg_4_0:updateMiddleContainer()
	arg_4_0:updateSelectButton()
	arg_4_0:initTopContainer()
	arg_4_0:initButton()
end

function var_0_0.initStringShow(arg_5_0)
	arg_5_0:nodeByName("txt_have"):setString(var_0_6:translation("ITEM_OWN"))
	arg_5_0:nodeByName("txt_jian"):setString(var_0_6:translation("ITEM_OWN_SUFFIX"))
	arg_5_0:nodeByName("txt_null"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT6"))
	arg_5_0:nodeByName("txt_top"):setString(var_0_6:translation("ELEMENT_EQUIP_TUJIAN"))
	arg_5_0:nodeByName("txt_now"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT8"))
	arg_5_0:nodeByName("txt_next"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT9"))
	arg_5_0:nodeByName("txt_comsume"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT10"))
	arg_5_0:nodeByName("txt_dec_recourse"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT11"))
	arg_5_0:nodeByName("txt_all"):setString(var_0_6:translation("BUTTON_TEXT_1"))
	arg_5_0:nodeByName("txt_fire"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT12"))
	arg_5_0:nodeByName("txt_water"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT13"))
	arg_5_0:nodeByName("txt_lighting"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT14"))
	arg_5_0:nodeByName("beibao_txt"):setString(var_0_6:translation("BACKPACK"))
	arg_5_0:nodeByName("beibao_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
	arg_5_0:nodeByName("txt_max"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT18"))
	arg_5_0:nodeByName("txt_btn_sp"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT31"))
	arg_5_0:nodeByName("txt_tujing"):setString(var_0_6:translation("GET_WAY_TEXT"))
	arg_5_0:nodeByName("txt_back"):setString(var_0_6:translation("FAQ_RETURN"))
	arg_5_0:nodeByName("txt_top_tujin"):setString(var_0_6:translation("GET_WAY_TEXT"))
end

function var_0_0.updateItems(arg_6_0)
	arg_6_0.equipsInBackpack = arg_6_0.backpack:getItemsByTypes(var_0_9)

	table.sort(arg_6_0.equipsInBackpack, function(arg_7_0, arg_7_1)
		return arg_7_0.itemID < arg_7_1.itemID
	end)

	arg_6_0.bindingEquips = {}

	local var_6_0 = var_0_17
	local var_6_1 = 1

	if var_6_0 then
		for iter_6_0 = 1, #var_6_0 do
			local var_6_2 = var_0_3:itemID(var_6_0[iter_6_0])
			local var_6_3 = {
				id = var_6_0[iter_6_0],
				lv = var_6_1[iter_6_0],
				partner_id = var_0_3:partnerID(var_6_2)
			}

			table.insert(arg_6_0.bindingEquips, var_6_3)
		end
	end

	table.sort(arg_6_0.bindingEquips, function(arg_8_0, arg_8_1)
		return arg_8_0.id < arg_8_1.id
	end)

	arg_6_0.equips, arg_6_0.equipsLV = arg_6_0.hero:getElementEquips()

	local var_6_4 = {}
	local var_6_5 = 1

	for iter_6_1, iter_6_2 in pairs(var_0_17) do
		var_6_4[var_6_5] = var_6_5
		var_6_5 = var_6_5 + 1
	end

	arg_6_0.equips = var_6_4
end

function var_0_0.updateMiddleContainer(arg_9_0)
	if not arg_9_0.equipID then
		arg_9_0:nodeByName("detail"):setVisible(false)
	else
		arg_9_0:nodeByName("detail"):setVisible(true)
		arg_9_0:nodeByName("txt_null"):setVisible(false)

		local var_9_0 = var_0_3:itemID(arg_9_0.equipID)
		local var_9_1 = arg_9_0:nodeByName("middle_item_container")

		var_9_1:removeAllChildren()
		arg_9_0:setElementEquipBorder(var_9_1, var_9_0, nil, nil, arg_9_0.equippingType_)
		arg_9_0:showGainWay(var_9_0)

		local var_9_2 = arg_9_0.backpack:getItemNumByID(var_9_0)

		arg_9_0:nodeByName("txt_num"):setString(var_9_2)
		arg_9_0:nodeByName("txt_desc"):setString(var_0_5:desc2(var_9_0))
		arg_9_0:nodeByName("txt_name"):setString(var_0_5:name(var_9_0))
		arg_9_0:nodeByName("label_title"):setString(var_0_5:name(var_9_0))

		local var_9_3 = arg_9_0:createDescStr(var_9_0, arg_9_0.equipLV)

		arg_9_0.descList:removeAllItems()

		local var_9_4 = arg_9_0.descList:newItem()
		local var_9_5 = arg_9_0:nodeByName("attr_container"):getContentSize()
		local var_9_6 = xyd.createLabel(22, cc.c3b(52, 54, 55))

		var_9_6:setString(var_9_3)
		var_9_6:setWidth(var_9_5.width - 20)
		var_9_6:setAnchorPoint(0, 0)
		var_9_4:addContent(var_9_6)
		var_9_4:setItemSize(var_9_5.width, var_9_6:getContentSize().height)
		arg_9_0.descList:addItem(var_9_4)
		arg_9_0.descList:reload()
	end
end

function var_0_0.updateRightContainer(arg_10_0, arg_10_1)
	arg_10_0:updateEquipContainer(arg_10_1)
	arg_10_0:updateStrthContainer()
	arg_10_0:updateDecomposeContainer()
end

function var_0_0.setElementEquipBorder(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7, arg_11_8)
	local var_11_0 = arg_11_1:getContentSize()
	local var_11_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/element_equip.csb")
	local var_11_2 = var_11_1:getChildByName("background"):getContentSize()
	local var_11_3 = var_11_1:getChildByName("gray_label")

	var_11_1:setScale(var_11_0.width / var_11_2.width)
	var_11_1:setPosition(0, 0)
	var_11_1:addTo(arg_11_1)

	if arg_11_2 then
		var_11_1:getChildByName("bg1"):setVisible(false)
		var_11_1:getChildByName("bg2"):setVisible(false)
		var_11_3:setVisible(false)
		var_11_1:getChildByName("green_plus"):setVisible(false)
		var_11_1:getChildByName("yellow_plus"):setVisible(false)

		local var_11_4 = var_11_1:getChildByName("icon")
		local var_11_5 = var_11_1:getChildByName("bg_element_lv")

		if arg_11_5 and arg_11_5 == var_0_11.inBackpack then
			local var_11_6 = arg_11_0.backpack:getItemNumByID(arg_11_2)

			xyd.setSpecialItemBorderNewUI(var_11_4, arg_11_2, nil, nil, nil)
		else
			xyd.setSpecialItemBorderNewUI(var_11_4, arg_11_2)
		end

		if arg_11_3 and arg_11_3 ~= 0 then
			var_11_5:setVisible(true)
			var_11_5:getChildByName("txt_lv"):setString(arg_11_3)
			var_11_5:getChildByName("txt_lv"):enableOutline(cc.c4b(84, 110, 123, 255), 2)
		end

		local var_11_7 = var_0_3:element(arg_11_2)
		local var_11_8 = var_0_3:equipType(arg_11_2)
		local var_11_9

		if var_11_8 == xyd.ElementEquipType.SP_CORE then
			var_11_9 = var_11_1:getChildByName("icon" .. var_11_7 .. "_2")
		else
			var_11_9 = var_11_1:getChildByName("icon" .. var_11_7 .. "_1")
		end

		var_11_9:setVisible(true)
	else
		var_11_1:getChildByName("bg1"):setVisible(arg_11_6 == 1)
		var_11_1:getChildByName("bg2"):setVisible(arg_11_6 ~= 1)

		if arg_11_7 then
			var_11_3:setString(var_0_6:translation("ELEMENT_EQUIP_TEXT17"))
			var_11_3:enableOutline(cc.c4b(84, 110, 123, 255), 2)
			var_11_1:getChildByName("yellow_plus"):setVisible(false)
		else
			var_11_3:setVisible(false)
			var_11_1:getChildByName("green_plus"):setVisible(false)
		end
	end

	if arg_11_5 and arg_11_8 then
		if arg_11_5 == var_0_11.equipping then
			var_11_1:getChildByName("element_type2"):setVisible(true)
		elseif arg_11_5 == var_0_11.binding then
			var_11_1:getChildByName("element_type1"):setVisible(true)
		end
	end

	if not arg_11_4 then
		return
	else
		var_11_1:setContentSize(var_11_1:getChildByName("background"):getContentSize())
		var_11_1:setTouchEnabled(true)
		var_11_1:setTouchSwallowEnabled(false)
		var_11_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "began" then
				var_11_1:getChildByName("green_plus"):setScale(0.9)

				return true
			elseif arg_12_0.name == "ended" then
				var_11_1:getChildByName("green_plus"):setScale(1)
				arg_11_4(arg_12_0)
			end
		end)
	end
end

function var_0_0.initTopContainer(arg_13_0)
	arg_13_0:nodeByName("txt_title"):setString(xyd.tables.window:title(arg_13_0.name))

	local var_13_0 = var_0_1.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_13_0:addTo(arg_13_0:nodeByName("top_container"))
	var_13_0:setAnchorPoint(0.5, 0.5)
	var_13_0:setPosition(46, -26)
	var_13_0:addTouchEvent(function(arg_14_0)
		if arg_14_0.name == "ended" then
			if arg_13_0.rightShowType == var_0_12.equip then
				arg_13_0:close()
			else
				arg_13_0:updateRightShow(var_0_12.equip)
			end
		end
	end)
	xyd.nodeEventSample(arg_13_0:nodeByName("btn_rule"), nil, function(arg_15_0)
		local var_15_0 = {}

		var_15_0.title_name = "ELEMENT_EQUIP_RULE_TITLE"
		var_15_0.rule = "ELEMENT_EQUIP_RULE_TEXT"
		var_15_0.style = xyd.RuleStyle.BLUE

		xyd.WindowManager.get():openWindow("new_text_rule", var_15_0)
	end)
end

function var_0_0.updateEquipContainer(arg_16_0, arg_16_1)
	arg_16_0:initShowItem()

	arg_16_0.equipContainer_ = {}

	if arg_16_0.pos == 1 then
		if arg_16_0.coreEquipShowItem and next(arg_16_0.coreEquipShowItem) then
			if arg_16_1 then
				arg_16_0.equipID = arg_16_0.coreEquipShowItem[1].id
				arg_16_0.equipLV = 1
				arg_16_0.equippingType_ = arg_16_0.coreEquipShowItem[1].type
				arg_16_0.rightPos = 1
			end

			arg_16_0.equipList:reload()
		else
			if arg_16_1 then
				arg_16_0.equipID = nil
				arg_16_0.equipLV = nil
				arg_16_0.equippingType_ = nil
				arg_16_0.rightPos = nil
			end

			arg_16_0.equipList:reload()
		end
	elseif arg_16_0.normalEquipShowItem and next(arg_16_0.normalEquipShowItem) then
		if arg_16_1 then
			arg_16_0.equipID = arg_16_0.normalEquipShowItem[1].id
			arg_16_0.equipLV = 1
			arg_16_0.equippingType_ = arg_16_0.normalEquipShowItem[1].type
			arg_16_0.rightPos = 1
		end

		arg_16_0.equipList:reload()
	else
		if arg_16_1 then
			arg_16_0.equipID = nil
			arg_16_0.equipLV = nil
			arg_16_0.equippingType_ = nil
			arg_16_0.rightPos = nil
		end

		arg_16_0.equipList:reload()
	end

	if arg_16_0.rightPos and arg_16_0.rightPos ~= 0 then
		arg_16_0:addSelectEffect(var_0_10.right, arg_16_0.equipContainer_[arg_16_0.rightPos], 0.85)
	end
end

function var_0_0.updateStrthContainer(arg_17_0)
	if not arg_17_0.equipID then
		return
	end

	local var_17_0 = var_0_3:itemID(arg_17_0.equipID)
	local var_17_1 = var_0_3:strthDscSuffix(var_17_0)
	local var_17_2 = arg_17_0:nodeByName("strth_equip_container")

	var_17_2:removeAllChildren()
	arg_17_0:setElementEquipBorder(var_17_2, var_17_0, arg_17_0.equipLV, nil, arg_17_0.equippingType_)
	arg_17_0:nodeByName("txt_now_lv"):setString(arg_17_0.equipLV)

	local var_17_3 = var_0_3:strth(var_17_0, arg_17_0.equipLV)

	arg_17_0:nodeByName("txt_strth_attr_now"):setString(var_17_3 .. var_17_1)
	arg_17_0:nodeByName("txt_strth_attr"):setString(var_0_3:strthDsc(var_17_0))

	if arg_17_0.equipLV < 10 then
		arg_17_0:nodeByName("strth_next_container"):setVisible(true)
		arg_17_0:nodeByName("txt_max"):setVisible(false)
		arg_17_0:nodeByName("txt_now"):setPositionX(114)
		arg_17_0:nodeByName("txt_now_lv"):setPositionX(198)
		arg_17_0:nodeByName("txt_strth_attr_now"):setPositionX(175)
		arg_17_0:nodeByName("txt_next_lv"):setString(arg_17_0.equipLV + 1)
		arg_17_0:nodeByName("txt_strth_attr_next"):setString(var_0_3:strth(var_17_0, arg_17_0.equipLV + 1) .. var_17_1)
		arg_17_0.strthList:reload()
	else
		arg_17_0:nodeByName("strth_next_container"):setVisible(false)
		arg_17_0:nodeByName("txt_max"):setVisible(true)
		arg_17_0:nodeByName("txt_now"):setPositionX(230)
		arg_17_0:nodeByName("txt_now_lv"):setPositionX(324)
		arg_17_0:nodeByName("txt_strth_attr_now"):setPositionX(250)
	end
end

function var_0_0.updateDecomposeContainer(arg_18_0)
	if not arg_18_0.equipID then
		return
	end

	local var_18_0 = var_0_3:itemID(arg_18_0.equipID)
	local var_18_1 = arg_18_0:nodeByName("dec_equip_container")

	var_18_1:removeAllChildren()
	arg_18_0:setElementEquipBorder(var_18_1, var_18_0, arg_18_0.equipLV, nil, arg_18_0.equippingType_)
	arg_18_0.decList:reload()
end

function var_0_0.initButton(arg_19_0)
	arg_19_0:nodeByName("btn_tujing"):setTouchEnabled(true)
	arg_19_0:nodeByName("btn_tujing"):setVisible(true)
	arg_19_0:nodeByName("btn_back"):setTouchEnabled(false)
	arg_19_0:nodeByName("btn_back"):setVisible(false)
	arg_19_0:nodeByName("bg_name"):setVisible(false)
	arg_19_0:nodeByName("bg_top_getway"):setVisible(false)
	arg_19_0:nodeByName("gain_container"):setVisible(false)
	arg_19_0:nodeByName("btn_tujing"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.began then
			arg_19_0:nodeByName("btn_tujing"):scale(0.8)
		elseif arg_20_1 == ccui.TouchEventType.ended then
			arg_19_0:nodeByName("btn_tujing"):setTouchEnabled(false)
			arg_19_0:nodeByName("btn_tujing"):setVisible(false)
			arg_19_0:nodeByName("btn_back"):setTouchEnabled(true)
			arg_19_0:nodeByName("btn_back"):setVisible(true)
			arg_19_0:nodeByName("btn_tujing"):scale(1)
			arg_19_0:nodeByName("bg_attr"):setVisible(false)
			arg_19_0:nodeByName("txt_desc"):setVisible(false)
			arg_19_0:nodeByName("txt_name"):setVisible(false)
			arg_19_0:nodeByName("txt_have"):setVisible(false)
			arg_19_0:nodeByName("txt_num"):setVisible(false)
			arg_19_0:nodeByName("txt_jian"):setVisible(false)
			arg_19_0:nodeByName("pos_line1"):setVisible(false)
			arg_19_0:nodeByName("bg_top_getway"):setVisible(true)
			arg_19_0:nodeByName("bg_name"):setVisible(true)

			local var_20_0, var_20_1 = arg_19_0:nodeByName("middle_item_container"):getPosition()

			arg_19_0:nodeByName("middle_item_container"):setPosition(var_20_0 - 10, var_20_1 + 13)
			arg_19_0:nodeByName("middle_item_container"):scale(0.6)
			arg_19_0:nodeByName("gain_container"):setVisible(true)
		end
	end)
	arg_19_0:nodeByName("btn_back"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.began then
			arg_19_0:nodeByName("btn_back"):scale(0.8)
		elseif arg_21_1 == ccui.TouchEventType.ended then
			arg_19_0:nodeByName("btn_back"):scale(1)
			arg_19_0:nodeByName("btn_tujing"):setTouchEnabled(true)
			arg_19_0:nodeByName("btn_tujing"):setVisible(true)
			arg_19_0:nodeByName("btn_back"):setTouchEnabled(false)
			arg_19_0:nodeByName("btn_back"):setVisible(false)
			arg_19_0:nodeByName("bg_attr"):setVisible(true)
			arg_19_0:nodeByName("txt_desc"):setVisible(true)
			arg_19_0:nodeByName("bg_top_getway"):setVisible(false)
			arg_19_0:nodeByName("txt_name"):setVisible(true)
			arg_19_0:nodeByName("txt_have"):setVisible(true)
			arg_19_0:nodeByName("txt_num"):setVisible(true)
			arg_19_0:nodeByName("txt_jian"):setVisible(true)
			arg_19_0:nodeByName("pos_line1"):setVisible(true)
			arg_19_0:nodeByName("bg_name"):setVisible(false)

			local var_21_0, var_21_1 = arg_19_0:nodeByName("middle_item_container"):getPosition()

			arg_19_0:nodeByName("middle_item_container"):setPosition(var_21_0 + 10, var_21_1 - 13)
			arg_19_0:nodeByName("middle_item_container"):scale(1)
			arg_19_0:nodeByName("gain_container"):setVisible(false)
		end
	end)
	arg_19_0:nodeByName("btn_all"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended then
			if arg_19_0.selectElement == 0 then
				arg_19_0:updateSelectButton()

				return
			end

			arg_19_0.selectElement = 0

			arg_19_0:updateSelectButton()
			arg_19_0:updateRightContainer(true)
			arg_19_0:updateMiddleContainer()
			arg_19_0:returnEquipRightShow()
		end
	end)
	arg_19_0:nodeByName("btn_fire"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			if arg_19_0.selectElement == xyd.ElementType.FIRE then
				arg_19_0:updateSelectButton()

				return
			end

			arg_19_0.selectElement = xyd.ElementType.FIRE

			arg_19_0:updateSelectButton()
			arg_19_0:updateRightContainer(true)
			arg_19_0:updateMiddleContainer()
			arg_19_0:returnEquipRightShow()
		end
	end)
	arg_19_0:nodeByName("btn_water"):addTouchEventListener(function(arg_24_0, arg_24_1)
		if arg_24_1 == ccui.TouchEventType.ended then
			if arg_19_0.selectElement == xyd.ElementType.WATER then
				arg_19_0:updateSelectButton()

				return
			end

			arg_19_0.selectElement = xyd.ElementType.WATER

			arg_19_0:updateSelectButton()
			arg_19_0:updateRightContainer(true)
			arg_19_0:updateMiddleContainer()
			arg_19_0:returnEquipRightShow()
		end
	end)
	arg_19_0:nodeByName("btn_lighting"):addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.ended then
			if arg_19_0.selectElement == xyd.ElementType.THUNDER then
				arg_19_0:updateSelectButton()

				return
			end

			arg_19_0.selectElement = xyd.ElementType.THUNDER

			arg_19_0:updateSelectButton()
			arg_19_0:updateRightContainer(true)
			arg_19_0:updateMiddleContainer()
			arg_19_0:returnEquipRightShow()
		end
	end)

	local var_19_0 = arg_19_0:nodeByName("btn_beibao")

	var_19_0:setTouchEnabled(true)
	arg_19_0:nodeByName("btn_beibao"):addTouchEventListener(function(arg_26_0, arg_26_1)
		if arg_26_1 == ccui.TouchEventType.began then
			var_19_0:scale(0.8)
		elseif arg_26_1 == ccui.TouchEventType.ended then
			var_19_0:scale(1)

			local var_26_0 = {
				hero = arg_19_0.hero,
				pos = arg_19_0.pos
			}

			xyd.WindowManager.get():closeWindow("element_equip_tujian")
			xyd.WindowManager.get():openWindow("element_equip", var_26_0)
		end
	end)
	arg_19_0:nodeByName("bg_select_off"):setTouchEnabled(true)
	arg_19_0:nodeByName("bg_select_off"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
		if arg_27_0.name == "began" then
			return true
		elseif arg_27_0.name == "ended" then
			arg_19_0:nodeByName("bg_select_off"):setVisible(false)
			arg_19_0:nodeByName("bg_select_on"):setVisible(true)

			arg_19_0.isSpShow = false

			arg_19_0:updateRightContainer(true)
			arg_19_0:updateMiddleContainer()
		end
	end)
	arg_19_0:nodeByName("bg_select_on"):setTouchEnabled(true)
	arg_19_0:nodeByName("bg_select_on"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
		if arg_28_0.name == "began" then
			return true
		elseif arg_28_0.name == "ended" then
			arg_19_0:nodeByName("bg_select_on"):setVisible(false)
			arg_19_0:nodeByName("bg_select_off"):setVisible(true)

			arg_19_0.isSpShow = true

			arg_19_0:updateRightContainer(true)
			arg_19_0:updateMiddleContainer()
		end
	end)
end

function var_0_0.updateSelectButton(arg_29_0)
	arg_29_0:nodeByName("btn_all"):setBrightStyle(arg_29_0.selectElement == 0 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	arg_29_0:nodeByName("btn_fire"):setBrightStyle(arg_29_0.selectElement == xyd.ElementType.FIRE and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	arg_29_0:nodeByName("btn_water"):setBrightStyle(arg_29_0.selectElement == xyd.ElementType.WATER and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	arg_29_0:nodeByName("btn_lighting"):setBrightStyle(arg_29_0.selectElement == xyd.ElementType.THUNDER and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
end

function var_0_0.equipListDelegate(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	local var_30_0

	if arg_30_0.pos == 1 then
		var_30_0 = #arg_30_0.coreEquipShowItem
	else
		var_30_0 = #arg_30_0.normalEquipShowItem
	end

	if arg_30_2 == cc.ui.UIListView.COUNT_TAG then
		return math.ceil(var_30_0 / var_0_8)
	elseif arg_30_2 == cc.ui.UIListView.CELL_TAG then
		local var_30_1 = arg_30_0.equipList:dequeueItem()

		if not var_30_1 then
			var_30_1 = arg_30_0.equipList:newItem()
		else
			var_30_1:removeAllChildren()
		end

		local var_30_2 = arg_30_0:createEquipShowContent(arg_30_3)

		var_30_1:addContent(var_30_2)

		local var_30_3 = var_30_2:getContentSize()

		var_30_1:setContentSize(var_30_3)
		var_30_1:setItemSize(var_30_3.width, var_30_3.height + 20)

		return var_30_1
	end
end

function var_0_0.createEquipShowContent(arg_31_0, arg_31_1)
	local var_31_0 = display.newNode()
	local var_31_1 = 52
	local var_31_2 = 47
	local var_31_3 = 108

	var_31_0:setContentSize(arg_31_0.equipList:getViewRect().width, 94)

	for iter_31_0 = 1, var_0_8 do
		local var_31_4 = (arg_31_1 - 1) * var_0_8 + iter_31_0
		local var_31_5 = {}

		if arg_31_0.pos == 1 then
			if not arg_31_0.coreEquipShowItem[var_31_4] then
				break
			end

			var_31_5 = arg_31_0.coreEquipShowItem[var_31_4]
		else
			if not arg_31_0.normalEquipShowItem[var_31_4] then
				break
			end

			var_31_5 = arg_31_0.normalEquipShowItem[var_31_4]
		end

		local var_31_6 = display.newNode()
		local var_31_7 = var_0_3:itemID(var_31_5.id)

		var_31_6:setContentSize(94, 94)
		table.insert(arg_31_0.equipContainer_, var_31_6)

		local function var_31_8()
			if not arg_31_0.scrollViewMoved_ then
				arg_31_0.equipID = var_31_5.id
				arg_31_0.equipLV = var_31_5.lv
				arg_31_0.equippingType_ = var_31_5.type
				arg_31_0.rightPos = var_31_4

				arg_31_0:addSelectEffect(var_0_10.right, var_31_6, 0.85)
				arg_31_0:updateMiddleContainer()
				arg_31_0:updateStrthContainer()
				arg_31_0:updateDecomposeContainer()
			end
		end

		arg_31_0:setElementEquipBorder(var_31_6, var_31_7, nil, var_31_8, nil, nil, nil, true)
		var_31_6:setAnchorPoint(0.5, 0.5)
		var_31_6:addTo(var_31_0)
		var_31_6:setPosition(var_31_1, var_31_2)

		var_31_1 = var_31_1 + var_31_3
	end

	return var_31_0
end

function var_0_0.strthListDelegate(arg_33_0, arg_33_1, arg_33_2, arg_33_3)
	if not arg_33_0.equipID then
		return 0
	end

	local var_33_0 = var_0_3:itemID(arg_33_0.equipID)
	local var_33_1 = var_0_3:equipType(var_33_0)
	local var_33_2 = var_0_4:strthMtrs(1, var_33_1)
	local var_33_3 = var_0_4:strthMtrsNums(1, var_33_1)

	if arg_33_2 == cc.ui.UIListView.COUNT_TAG then
		return #var_33_2
	elseif arg_33_2 == cc.ui.UIListView.CELL_TAG then
		local var_33_4 = arg_33_0.strthList:dequeueItem()

		if not var_33_4 then
			var_33_4 = arg_33_0.strthList:newItem()
		else
			var_33_4:removeAllChildren()
		end

		local var_33_5 = display.newNode()
		local var_33_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/compose/element_equip_strth_item.csb")
		local var_33_7 = var_33_6:getChildByName("container")
		local var_33_8 = var_33_7:getContentSize()
		local var_33_9 = display.newNode()
		local var_33_10 = var_33_7:getChildByName("item_container")

		var_33_9:setContentSize(var_33_10:getContentSize())
		var_33_9:addTo(var_33_10)
		var_33_9:setAnchorPoint(0, 0)
		var_33_9:setPosition(0, 0)
		var_33_5:setContentSize(var_33_8)
		xyd.setItemBorder(var_33_9, var_33_2[arg_33_3])

		local var_33_11 = {
			id = var_33_2[arg_33_3],
			lev = var_0_5:level(var_33_2[arg_33_3])
		}

		if var_0_5:type(var_33_2[arg_33_3]) == -1 then
			var_33_11.tipsType = 0
			var_33_11.desc1 = xyd.tables.hero:getDes(var_33_2[arg_33_3])
		else
			var_33_11.tipsType = 1
			var_33_11.desc1 = var_0_5:desc1(var_33_2[arg_33_3])
			var_33_11.desc2 = var_0_5:desc2(var_33_2[arg_33_3])
		end

		var_33_11.hasNum = arg_33_0.backpack:getItemNumByID(var_33_2[arg_33_3])
		var_33_11.name = var_0_5:name(var_33_2[arg_33_3])

		arg_33_0:addTips(var_33_9, var_33_11)

		local var_33_12 = arg_33_0.backpack:getItemNumByID(var_33_2[arg_33_3])

		if var_33_12 >= var_33_3[arg_33_3] then
			var_33_7:getChildByName("txt_num"):setColor(cc.c3b(52, 54, 55))
		else
			var_33_7:getChildByName("txt_num"):setColor(cc.c3b(228, 104, 124))
		end

		var_33_7:getChildByName("txt_num"):setString(var_33_3[arg_33_3] .. "/" .. var_33_12)
		var_33_6:addTo(var_33_5)
		var_33_4:addContent(var_33_5)
		var_33_4:setContentSize(var_33_8)
		var_33_4:setItemSize(var_33_8.width, var_33_8.height + 5)

		return var_33_4
	end
end

function var_0_0.decListDelegate(arg_34_0, arg_34_1, arg_34_2, arg_34_3)
	if not arg_34_0.equipID then
		return 0
	end

	local var_34_0 = var_0_3:itemID(arg_34_0.equipID)
	local var_34_1 = var_0_3:equipType(var_34_0)
	local var_34_2 = var_0_4:decMtrs(1, var_34_1)
	local var_34_3 = var_0_4:decMtrsNums(1, var_34_1)

	if arg_34_2 == cc.ui.UIListView.COUNT_TAG then
		return #var_34_2
	elseif arg_34_2 == cc.ui.UIListView.CELL_TAG then
		local var_34_4 = arg_34_0.decList:dequeueItem()

		if not var_34_4 then
			var_34_4 = arg_34_0.decList:newItem()
		else
			var_34_4:removeAllChildren()
		end

		local var_34_5 = display.newNode()
		local var_34_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/compose/element_equip_dec_item.csb")
		local var_34_7 = var_34_6:getChildByName("container")
		local var_34_8 = var_34_7:getContentSize()
		local var_34_9 = display.newNode()
		local var_34_10 = var_34_7:getChildByName("item_container")

		var_34_9:setContentSize(var_34_10:getContentSize())
		var_34_9:addTo(var_34_10)
		var_34_9:setAnchorPoint(0, 0)
		var_34_9:setPosition(0, 0)
		var_34_5:setContentSize(var_34_8)
		xyd.setItemBorder(var_34_9, var_34_2[arg_34_3])
		var_34_7:getChildByName("txt_num"):setString("x" .. var_34_3[arg_34_3])

		local var_34_11 = {
			id = var_34_2[arg_34_3],
			lev = var_0_5:level(var_34_2[arg_34_3])
		}

		if var_0_5:type(var_34_2[arg_34_3]) == -1 then
			var_34_11.tipsType = 0
			var_34_11.desc1 = xyd.tables.hero:getDes(var_34_2[arg_34_3])
		else
			var_34_11.tipsType = 1
			var_34_11.desc1 = var_0_5:desc1(var_34_2[arg_34_3])
			var_34_11.desc2 = var_0_5:desc2(var_34_2[arg_34_3])
		end

		var_34_11.hasNum = arg_34_0.backpack:getItemNumByID(var_34_2[arg_34_3])
		var_34_11.name = var_0_5:name(var_34_2[arg_34_3])

		arg_34_0:addTips(var_34_9, var_34_11)

		local var_34_12 = var_0_6:translation("ELEMENT_EQUIP_TEXT25")
		local var_34_13 = arg_34_0.backpack:getItemNumByID(var_34_2[arg_34_3])

		var_34_7:getChildByName("txt_all"):setString(string.format(var_34_12, var_34_13))
		var_34_6:addTo(var_34_5)
		var_34_4:addContent(var_34_5)
		var_34_4:setContentSize(var_34_8)
		var_34_4:setItemSize(var_34_8.width, var_34_8.height)

		return var_34_4
	end
end

function var_0_0.initShowItem(arg_35_0)
	arg_35_0.coreEquipShowItem = {}
	arg_35_0.normalEquipShowItem = {}

	for iter_35_0 = 1, #arg_35_0.equips do
		if arg_35_0.equips and arg_35_0.equips[iter_35_0] ~= 0 and arg_35_0.isSpShow and var_0_3:isHide(var_0_3:itemID(arg_35_0.equips[iter_35_0])) == 0 then
			local var_35_0 = var_0_3:itemID(arg_35_0.equips[iter_35_0])
			local var_35_1 = var_0_3:element(var_35_0)
			local var_35_2 = {
				id = arg_35_0.equips[iter_35_0]
			}

			var_35_2.lv = 1
			var_35_2.type = var_0_11.equipping

			if arg_35_0.selectElement == 0 or arg_35_0.selectElement == var_35_1 then
				table.insert(arg_35_0.coreEquipShowItem, var_35_2)
			end
		end
	end

	if arg_35_0.isSpShow == false then
		for iter_35_1 = 1, #arg_35_0.equips do
			if arg_35_0.equips and arg_35_0.equips[iter_35_1] and var_0_3:partnerID(var_0_3:itemID(arg_35_0.equips[iter_35_1])) == 0 and var_0_3:isHide(var_0_3:itemID(arg_35_0.equips[iter_35_1])) == 0 or arg_35_0.equips and arg_35_0.equips[iter_35_1] and var_0_3:partnerID(var_0_3:itemID(arg_35_0.equips[iter_35_1])) == arg_35_0.hero.tableID_ and var_0_3:isHide(var_0_3:itemID(arg_35_0.equips[iter_35_1])) == 0 then
				local var_35_3 = var_0_3:itemID(arg_35_0.equips[iter_35_1])
				local var_35_4 = var_0_3:element(var_35_3)
				local var_35_5 = {
					id = arg_35_0.equips[iter_35_1]
				}

				var_35_5.lv = 1
				var_35_5.type = var_0_11.equipping
				var_35_5.pos = iter_35_1

				if arg_35_0.selectElement == 0 or arg_35_0.selectElement == var_35_4 then
					table.insert(arg_35_0.coreEquipShowItem, var_35_5)
				end
			end
		end
	end

	for iter_35_2 = 1, #arg_35_0.equips do
		if arg_35_0.equips and arg_35_0.equips[iter_35_2] ~= 0 and arg_35_0.isSpShow and var_0_3:isHide(var_0_3:itemID(arg_35_0.equips[iter_35_2])) == 0 then
			local var_35_6 = var_0_3:itemID(arg_35_0.equips[iter_35_2])
			local var_35_7 = var_0_3:element(var_35_6)
			local var_35_8 = {
				id = arg_35_0.equips[iter_35_2]
			}

			var_35_8.lv = 1
			var_35_8.type = var_0_11.equipping
			var_35_8.pos = iter_35_2

			if arg_35_0.selectElement == 0 or arg_35_0.selectElement == var_35_7 then
				table.insert(arg_35_0.normalEquipShowItem, var_35_8)
			end
		end
	end

	if arg_35_0.isSpShow == false then
		for iter_35_3 = 1, #arg_35_0.equips do
			if arg_35_0.equips and arg_35_0.equips[iter_35_3] and var_0_3:partnerID(var_0_3:itemID(arg_35_0.equips[iter_35_3])) == 0 and var_0_3:isHide(var_0_3:itemID(arg_35_0.equips[iter_35_3])) == 0 or arg_35_0.equips and arg_35_0.equips[iter_35_3] and var_0_3:partnerID(var_0_3:itemID(arg_35_0.equips[iter_35_3])) == arg_35_0.hero.tableID_ and var_0_3:isHide(var_0_3:itemID(arg_35_0.equips[iter_35_3])) == 0 then
				local var_35_9 = var_0_3:itemID(arg_35_0.equips[iter_35_3])
				local var_35_10 = var_0_3:element(var_35_9)
				local var_35_11 = {
					id = arg_35_0.equips[iter_35_3]
				}

				var_35_11.lv = 1
				var_35_11.type = var_0_11.equipping
				var_35_11.pos = iter_35_3

				if arg_35_0.selectElement == 0 or arg_35_0.selectElement == var_35_10 then
					table.insert(arg_35_0.normalEquipShowItem, var_35_11)
				end
			end
		end
	end
end

function var_0_0.addSelectEffect(arg_36_0, arg_36_1, arg_36_2, arg_36_3)
	if not tolua.isnull(arg_36_0.selectEffect[arg_36_1]) and arg_36_0.selectEffect[arg_36_1] then
		transition.stopTarget(arg_36_0.selectEffect[arg_36_1])
		arg_36_0.selectEffect[arg_36_1]:removeSelf()

		arg_36_0.selectEffect[arg_36_1] = nil
	end

	arg_36_0.selectEffect[arg_36_1] = xyd.AssetLoader:get():loadSprite("windows/hero/bg_select.png")

	arg_36_0.selectEffect[arg_36_1]:setAnchorPoint(0.5, 0.5)
	arg_36_0.selectEffect[arg_36_1]:addTo(arg_36_2)
	arg_36_0.selectEffect[arg_36_1]:setPosition(arg_36_2:getContentSize().width / 2, arg_36_2:getContentSize().height / 2)
	arg_36_0.selectEffect[arg_36_1]:setScale(arg_36_3 or 1)

	local var_36_0 = cc.ScaleBy:create(0.3, 1.04)
	local var_36_1 = transition.sequence({
		var_36_0,
		var_36_0:reverse()
	})
	local var_36_2 = cc.RepeatForever:create(var_36_1)

	arg_36_0.selectEffect[arg_36_1]:runAction(var_36_2)
end

function var_0_0.updateRightShow(arg_37_0, arg_37_1)
	arg_37_0.rightShowType = arg_37_1

	arg_37_0:nodeByName("equip_container"):setVisible(arg_37_0.rightShowType == var_0_12.equip)
	arg_37_0:nodeByName("strth_container"):setVisible(arg_37_0.rightShowType == var_0_12.strth)
	arg_37_0:nodeByName("decompose_container"):setVisible(arg_37_0.rightShowType == var_0_12.decompose)
end

function var_0_0.createDescStr(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0

	if arg_38_0.equippingType_ == var_0_11.equipping then
		var_38_0 = arg_38_0.hero:getElementEquipActiveRate(arg_38_1)
	else
		var_38_0 = 1
	end

	local var_38_1 = var_0_3:equipType(arg_38_1)
	local var_38_2 = var_0_3:base(arg_38_1)
	local var_38_3 = var_0_3:strth(arg_38_1, arg_38_2)
	local var_38_4 = (var_38_2 + var_38_3) * var_38_0
	local var_38_5

	if var_38_1 == xyd.ElementEquipType.NORMAL then
		local var_38_6 = (var_38_2 + var_38_3) * (var_38_0 - 1)

		var_38_5 = string.format(var_0_3:equipDsc(arg_38_1), var_38_4, var_38_2, var_38_3, var_38_6)
	else
		var_38_5 = string.format(var_0_3:equipDsc(arg_38_1), var_38_4, var_38_2, var_38_3)
	end

	local var_38_7 = xyd.split(var_38_5, "|")
	local var_38_8 = ""

	for iter_38_0 = 1, #var_38_7 do
		if iter_38_0 > 1 then
			var_38_8 = var_38_8 .. "\n"
		end

		var_38_8 = var_38_8 .. var_38_7[iter_38_0]
	end

	return var_38_8
end

function var_0_0.scrollListener(arg_39_0, arg_39_1)
	if arg_39_1.name == "began" then
		arg_39_0.scrollViewMoved_ = false
		arg_39_0.prevY_ = arg_39_1.y
	elseif arg_39_1.name == "moved" and 20 <= math.abs(arg_39_1.y - arg_39_0.prevY_) then
		arg_39_0.scrollViewMoved_ = true
	end
end

function var_0_0.findEquippingRightPos(arg_40_0)
	if not arg_40_0.equips or arg_40_0.equips[arg_40_0.pos] == 0 then
		arg_40_0.rightPos = nil

		return
	end

	local var_40_0 = var_0_3:itemID(arg_40_0.equips[arg_40_0.pos])
	local var_40_1 = var_0_3:element(var_40_0)

	if arg_40_0.selectElement ~= 0 and arg_40_0.selectElement ~= var_40_1 then
		arg_40_0.rightPos = nil

		return
	end

	if arg_40_0.pos == 1 then
		local var_40_2 = var_0_3:itemID(arg_40_0.equips[arg_40_0.pos])
		local var_40_3 = var_0_3:element(var_40_2)

		if arg_40_0.selectElement == 0 or arg_40_0.selectElement == var_40_3 then
			arg_40_0.rightPos = 1
		else
			arg_40_0.rightPos = nil
		end
	else
		local var_40_4 = 0

		for iter_40_0 = 2, arg_40_0.pos do
			if arg_40_0.equips[iter_40_0] ~= 0 then
				local var_40_5 = var_0_3:itemID(arg_40_0.equips[iter_40_0])
				local var_40_6 = var_0_3:element(var_40_5)

				if arg_40_0.selectElement == 0 or arg_40_0.selectElement == var_40_6 then
					var_40_4 = var_40_4 + 1
				end
			end

			arg_40_0.rightPos = var_40_4
		end
	end
end

function var_0_0.returnEquipRightShow(arg_41_0)
	if arg_41_0.rightShowType == var_0_12.equip then
		return
	else
		arg_41_0:updateRightShow(var_0_12.equip)
	end
end

function var_0_0.showGainWay(arg_42_0, arg_42_1)
	if not arg_42_0.gainListView_ then
		arg_42_0.gainListView_ = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, arg_42_0:nodeByName("gain_container"):getWidth(), arg_42_0:nodeByName("gain_container"):getHeight()),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_42_0:nodeByName("gain_container")):onScroll(handler(arg_42_0, arg_42_0.scrollListener))
	else
		arg_42_0.gainListView_:removeAllItems()
	end

	local var_42_0 = var_0_7:map(arg_42_1)

	if var_0_7:isAwakenPiece(arg_42_1) == 1 and type(var_42_0) == "table" then
		local var_42_1 = var_42_0[1]

		for iter_42_0 = 1, #var_42_0 do
			local var_42_2 = 0

			if arg_42_0.selfPlayer.worldMaps_[var_42_0[iter_42_0]] then
				var_42_2 = arg_42_0.selfPlayer.worldMaps_[var_42_0[iter_42_0]].star or 0
			end

			if var_42_1 <= var_42_0[iter_42_0] and var_42_2 == 3 then
				var_42_1 = var_42_0[iter_42_0]
			end
		end

		var_42_0 = {
			var_42_1
		}
	end

	for iter_42_1 = #var_42_0, 1, -1 do
		if var_42_0[iter_42_1] == 0 then
			table.remove(var_42_0, iter_42_1)
		end
	end

	for iter_42_2 = 1, #var_42_0 do
		local var_42_3 = display.newNode()
		local var_42_4 = arg_42_0.gainListView_:newItem()
		local var_42_5 = import("app.windows.GainWayItem").new()
		local var_42_6 = xyd.tables.campaign:relateCampaign(var_42_0[iter_42_2])
		local var_42_7 = xyd.tables.campaign:campaignType(var_42_0[iter_42_2])
		local var_42_8

		if var_42_7 - 1 == xyd.CampaignType.SUPER and not arg_42_0.isActivityItem then
			var_42_8 = xyd.tables.campaign:icon(var_42_6)
		else
			var_42_8 = xyd.tables.campaign:icon(var_42_0[iter_42_2])
		end

		if not var_42_8 then
			return
		end

		local var_42_9 = {
			campaignName = xyd.tables.campaign:campaignName(var_42_0[iter_42_2]),
			chapter = xyd.tables.campaign:chapter(var_42_0[iter_42_2]),
			icon = var_42_8,
			campaignType = var_42_7,
			campaignID = var_42_0[iter_42_2],
			isActivityItem = arg_42_0.isActivityItem
		}

		if var_42_7 == xyd.CampaignType.PET and xyd.tables.campaign:getFloorType(var_42_0[iter_42_2]) == 2 then
			var_42_9.petFloor = xyd.tables.campaign:getFloor(var_42_0[iter_42_2])
		end

		var_42_5:setParams(var_42_9)
		var_42_5:setPosition(0, 0)
		var_42_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_42_5:ignoreAnchorPointForPosition(false)
		var_42_5:addTo(var_42_3)
		var_42_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_43_0)
			if arg_43_0.name == "began" then
				var_42_5.contentView_:nodeByName("gain_way_node"):setScale(0.9)
			end

			if arg_43_0.name == "moved" and arg_42_0.scrollViewMoved_ then
				var_42_5.contentView_:nodeByName("gain_way_node"):setScale(1)
			end

			if arg_43_0.name == "ended" and not arg_42_0.scrollViewMoved_ then
				var_42_5.contentView_:nodeByName("gain_way_node"):setScale(1)

				if not arg_42_0.isActivityItem then
					if var_42_7 == 3 and arg_42_0.maxSuperCampaign >= var_42_0[iter_42_2] or var_42_7 == 2 and arg_42_0.maxNormalCampaign >= var_42_0[iter_42_2] then
						arg_42_0.guild:loadGuildMap(function(arg_44_0)
							local var_44_0 = {
								isStoneCampaign = true,
								chapter = xyd.tables.campaign:chapter(var_42_0[iter_42_2]),
								campaignID = var_42_0[iter_42_2],
								campaignType = xyd.tables.campaign:campaignType(var_42_0[iter_42_2]) - 1,
								itemComposeID = arg_42_1,
								needItemComposeNum = arg_42_0.composeNeedNum
							}

							xyd.WindowManager.get():openWindow("map_window", var_44_0)
						end)
					elseif var_42_7 == xyd.CampaignType.PET then
						if xyd.WindowManager.get():getWindow("pet_campaign") then
							xyd.WindowManager.get():closeWindow("pet_campaign")
						end

						local var_43_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)

						var_43_0:getCampaignInfo(function(arg_45_0)
							if arg_45_0 == xyd.error.OK then
								var_43_0:setStateBaseOnCampaignID(var_42_0[iter_42_2])

								if var_43_0.openSuper then
									xyd.WindowManager.get():openWindow("pet_campaign", {
										now_floor = var_42_9.petFloor
									})
								else
									xyd.WindowManager.get():openWindow("pet_campaign")
								end
							end
						end)
					elseif var_42_7 == xyd.CampaignType.CLOUD_LADDER or var_42_7 == xyd.CampaignType.CLOUD_ROAD or var_42_7 == xyd.CampaignType.CLOUD_TEMPLE then
						if arg_42_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CLOUD_CITY) == true then
							xyd.WindowManager.get():openWindow("cloud_city")
						end
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_6:translation("CHAPTER_NOT_AVAILABLE")
						})
					end
				else
					arg_42_0:activityItemGainWay(xyd.tables.campaign:campaignType(var_42_0[iter_42_2]) - 1, arg_42_1)
				end
			end

			return true
		end)
		var_42_4:addContent(var_42_3)
		var_42_3:setContentSize(434, 117)
		var_42_4:setItemSize(434, 122)
		arg_42_0.gainListView_:addItem(var_42_4)
	end

	local var_42_10 = xyd.tables.item:gainType(arg_42_1)

	for iter_42_3 = 1, #var_42_10 do
		id = var_42_10[iter_42_3]

		if id ~= 0 then
			local var_42_11 = arg_42_0.gainListView_:newItem()
			local var_42_12 = arg_42_0:creatWayContent(id)

			var_42_11:addContent(var_42_12)
			var_42_12:setContentSize(434, 117)
			var_42_11:setItemSize(434, 122)
			arg_42_0.gainListView_:addItem(var_42_11)
		end
	end

	arg_42_0.gainListView_:reload()
end

function var_0_0.creatWayContent(arg_46_0, arg_46_1)
	local var_46_0 = xyd.tables.heroGetWayTable
	local var_46_1 = display.newNode()
	local var_46_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/compose/gain_way_item.csb")
	local var_46_3 = var_46_2:getChildByName("gain_way_node")

	var_46_3:getChildByName("super_txt"):setVisible(false)
	var_46_3:getChildByName("left_times"):setVisible(false)

	local var_46_4 = var_46_0:getIcon(arg_46_1)
	local var_46_5 = xyd.AssetLoader:get():loadSprite(var_46_4)

	var_46_5:setAnchorPoint(cc.p(0.5, 0.5))

	local var_46_6 = var_46_3:getChildByName("campaign_icon"):getContentSize().width / 2

	var_46_5:addTo(var_46_3:getChildByName("campaign_icon"))
	var_46_5:setPosition(cc.p(var_46_6, var_46_6))
	var_46_5:setScale(0.7)
	var_46_3:getChildByName("campaign_num"):setString(var_46_0:getName(arg_46_1))
	var_46_3:getChildByName("campaign_name"):setString(var_46_0:getDesc(arg_46_1))
	var_46_2:addTo(var_46_1)
	var_46_2:setAnchorPoint(cc.p(0, 0))
	var_46_2:setName("source")
	var_46_2:setTouchEnabled(true)
	var_46_2:setTouchSwallowEnabled(false)
	var_46_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_47_0)
		if arg_47_0.name == "began" then
			var_46_3:setScale(0.9)

			return true
		elseif arg_47_0.name == "moved" and arg_46_0.scrollViewMoved_ then
			var_46_3:setScale(1)
		elseif arg_47_0.name == "ended" and not arg_46_0.scrollViewMoved_ then
			var_46_3:setScale(1)
			xyd.navigateToHeroGetWay(arg_46_1)
		end
	end)

	return var_46_1
end

function var_0_0.activityItemGainWay(arg_48_0, arg_48_1, arg_48_2)
	local var_48_0
	local var_48_1

	if arg_48_1 == xyd.CampaignType.SUPER then
		local var_48_2 = arg_48_0.maxSuperCampaign
		local var_48_3 = arg_48_0.selfPlayer.super_chapter_id
		local var_48_4 = {
			chapter_type = arg_48_1
		}

		xyd.WindowManager.get():openWindow("map_window", var_48_4)
	elseif arg_48_1 == xyd.CampaignType.NORMAL then
		local var_48_5 = arg_48_0.maxNormalCampaign
		local var_48_6 = arg_48_0.selfPlayer.normal_chapter_id
		local var_48_7 = {
			chapter_type = arg_48_1
		}

		xyd.WindowManager.get():openWindow("map_window", var_48_7)
	elseif arg_48_1 == xyd.CampaignType.MARCH then
		local var_48_8 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

		if var_48_8.mapInfo == nil then
			var_48_8:loadMarchInfo({}, function(arg_49_0)
				if arg_49_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("march")
				end
			end)
		else
			xyd.WindowManager.get():openWindow("march")
		end
	elseif arg_48_1 == xyd.CampaignType.ARENA then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_50_0, arg_50_1)
			if arg_50_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("arena")
			end
		end)
	elseif arg_48_1 == xyd.CampaignType.SUPER_ARENA then
		xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA):loadPeakArena(function(arg_51_0)
			if arg_51_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("peak_arena")
			end
		end)
	elseif arg_48_1 == xyd.CampaignType.WU or arg_48_1 == xyd.CampaignType.SHU or arg_48_1 == xyd.CampaignType.WEI then
		xyd.WindowManager.get():openWindow("trial")
	elseif arg_48_1 == xyd.CampaignType.WUMIAN or arg_48_1 == xyd.CampaignType.MOMIAN then
		xyd.WindowManager.get():openWindow("time_trial")
	end
end

return var_0_0
