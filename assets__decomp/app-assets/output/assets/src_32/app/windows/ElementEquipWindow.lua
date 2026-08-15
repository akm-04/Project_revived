local var_0_0 = class("ElementEquipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.elementEquip
local var_0_4 = xyd.tables.elementStrth
local var_0_5 = xyd.tables.item
local var_0_6 = xyd.tables.translation
local var_0_7 = 4
local var_0_8 = {
	xyd.ItemType.ELEMENT_EQUIP
}
local var_0_9 = {
	left = 1,
	right = 2
}
local var_0_10 = {
	inBackpack = 3,
	equipping = 1,
	binding = 2
}
local var_0_11 = {
	strth = 2,
	decompose = 3,
	equip = 1
}
local var_0_12 = {
	takeoff = 2,
	equip = 1,
	change = 3
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.elementEquip = xyd.ModelManager.get():loadModel(xyd.ModelType.ELEMENT_EQUIP)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.pos = arg_1_2.pos
	arg_1_0.selectElement = 0
	arg_1_0.rightShowType = var_0_11.equip
	arg_1_0.isSpShow = true
	arg_1_0.selectEffect = {}
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
		arg_4_0.equipLV = arg_4_0.equipsLV[arg_4_0.pos]
		arg_4_0.equippingType_ = var_0_10.equipping

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
	arg_4_0:updateLeftContainer()
	arg_4_0:updateSelectButton()
	arg_4_0:initTopContainer()
	arg_4_0:initButton()
end

function var_0_0.initStringShow(arg_5_0)
	arg_5_0:nodeByName("txt_have"):setString(var_0_6:translation("ITEM_OWN"))
	arg_5_0:nodeByName("txt_jian"):setString(var_0_6:translation("ITEM_OWN_SUFFIX"))
	arg_5_0:nodeByName("txt_equip"):setString(var_0_6:translation("ITEM_EQUIP"))
	arg_5_0:nodeByName("txt_takeoff"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT2"))
	arg_5_0:nodeByName("txt_change"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT5"))
	arg_5_0:nodeByName("txt_strth"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT3"))
	arg_5_0:nodeByName("txt_decompose"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT4"))
	arg_5_0:nodeByName("txt_null"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT6"))
	arg_5_0:nodeByName("txt_top"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT7"))
	arg_5_0:nodeByName("txt_now"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT8"))
	arg_5_0:nodeByName("txt_next"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT9"))
	arg_5_0:nodeByName("txt_comsume"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT10"))
	arg_5_0:nodeByName("txt_dec_recourse"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT11"))
	arg_5_0:nodeByName("txt_all"):setString(var_0_6:translation("BUTTON_TEXT_1"))
	arg_5_0:nodeByName("txt_fire"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT12"))
	arg_5_0:nodeByName("txt_water"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT13"))
	arg_5_0:nodeByName("txt_lighting"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT14"))
	arg_5_0:nodeByName("beibao_txt"):setString(var_0_6:translation("HERO_BUTTON_TUJIAN"))
	arg_5_0:nodeByName("beibao_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
	arg_5_0:nodeByName("txt_max"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT18"))
	arg_5_0:nodeByName("txt_btn_sp"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT29"))
end

function var_0_0.updateItems(arg_6_0)
	arg_6_0.equipsInBackpack = arg_6_0.backpack:getItemsByTypes(var_0_8)

	table.sort(arg_6_0.equipsInBackpack, function(arg_7_0, arg_7_1)
		return arg_7_0.itemID < arg_7_1.itemID
	end)

	arg_6_0.bindingEquips = {}

	local var_6_0, var_6_1 = arg_6_0.hero:getElementBindingEquips()

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
end

function var_0_0.updateLeftContainer(arg_9_0)
	local var_9_0, var_9_1 = arg_9_0.hero:getElementEquips()
	local var_9_2 = false
	local var_9_3 = false

	if arg_9_0.equipsInBackpack and next(arg_9_0.equipsInBackpack) then
		for iter_9_0 = 1, #arg_9_0.equipsInBackpack do
			if var_9_2 and var_9_3 then
				break
			end

			local var_9_4 = arg_9_0.equipsInBackpack[iter_9_0].itemID

			if var_0_3:equipType(var_9_4) == xyd.ElementEquipType.NORMAL then
				var_9_3 = true
			elseif var_0_3:equipType(var_9_4) == xyd.ElementEquipType.CORE then
				var_9_2 = true
			elseif var_0_3:equipType(var_9_4) == xyd.ElementEquipType.SP_CORE and var_0_3:partnerID(var_9_4) == arg_9_0.hero:getFirstTableID() then
				var_9_2 = true
			end
		end
	end

	if arg_9_0.bindingEquips and next(arg_9_0.bindingEquips) then
		for iter_9_1 = 1, #arg_9_0.bindingEquips do
			if var_9_2 and var_9_3 then
				break
			end

			local var_9_5 = var_0_3:itemID(arg_9_0.bindingEquips[iter_9_1].id)

			if var_0_3:equipType(var_9_5) == xyd.ElementEquipType.NORMAL then
				var_9_3 = true
			else
				var_9_2 = true
			end
		end
	end

	for iter_9_2 = 1, xyd.MAX_ELEMENT_ITEM_NUM do
		local var_9_6 = arg_9_0:nodeByName("left_container_" .. iter_9_2)

		var_9_6:removeAllChildren()

		local function var_9_7()
			if arg_9_0.pos == iter_9_2 then
				arg_9_0:returnEquipRightShow()

				return
			end

			if arg_9_0.pos == 1 and iter_9_2 ~= 1 or arg_9_0.pos ~= 1 and iter_9_2 == 1 then
				arg_9_0.pos = iter_9_2

				if arg_9_0.equips and arg_9_0.equips[iter_9_2] ~= 0 then
					arg_9_0.equipID = arg_9_0.equips[iter_9_2]
					arg_9_0.equipLV = arg_9_0.equipsLV[iter_9_2]
					arg_9_0.equippingType_ = var_0_10.equipping

					arg_9_0:findEquippingRightPos()
				else
					arg_9_0.equipID = nil
					arg_9_0.equipLV = nil
					arg_9_0.equippingType_ = nil
					arg_9_0.rightPos = nil
				end

				arg_9_0:updateRightContainer()
				arg_9_0:updateMiddleContainer()
				arg_9_0:addSelectEffect(var_0_9.left, arg_9_0:nodeByName("left_container_" .. arg_9_0.pos))
			else
				arg_9_0.pos = iter_9_2

				if arg_9_0.equips and arg_9_0.equips[iter_9_2] ~= 0 then
					arg_9_0.equipID = arg_9_0.equips[iter_9_2]
					arg_9_0.equipLV = arg_9_0.equipsLV[iter_9_2]
					arg_9_0.equippingType_ = var_0_10.equipping

					arg_9_0:findEquippingRightPos()
				else
					arg_9_0.equipID = nil
					arg_9_0.equipLV = nil
					arg_9_0.equippingType_ = nil
					arg_9_0.rightPos = nil
				end

				arg_9_0:updateRightContainer()
				arg_9_0:updateMiddleContainer()
				arg_9_0:addSelectEffect(var_0_9.left, arg_9_0:nodeByName("left_container_" .. arg_9_0.pos))
			end

			arg_9_0:returnEquipRightShow()
		end

		if var_9_0 and var_9_0[iter_9_2] ~= 0 then
			local var_9_8 = var_0_3:itemID(var_9_0[iter_9_2])

			arg_9_0:setElementEquipBorder(var_9_6, var_9_8, var_9_1[iter_9_2], var_9_7, var_0_10.equipping)
		elseif iter_9_2 == 1 then
			arg_9_0:setElementEquipBorder(var_9_6, nil, nil, var_9_7, var_0_10.equipping, iter_9_2, var_9_2)
		else
			arg_9_0:setElementEquipBorder(var_9_6, nil, nil, var_9_7, var_0_10.equipping, iter_9_2, var_9_3)
		end
	end

	arg_9_0:addSelectEffect(var_0_9.left, arg_9_0:nodeByName("left_container_" .. arg_9_0.pos))
end

function var_0_0.updateMiddleContainer(arg_11_0)
	if not arg_11_0.equipID then
		arg_11_0:nodeByName("detail"):setVisible(false)
		arg_11_0:nodeByName("txt_null"):setVisible(true)

		if arg_11_0.pos == 1 and arg_11_0.coreEquipShowItem and next(arg_11_0.coreEquipShowItem) or arg_11_0.pos ~= 1 and arg_11_0.normalEquipShowItem and next(arg_11_0.normalEquipShowItem) then
			arg_11_0:nodeByName("txt_null"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT28"))
		else
			arg_11_0:nodeByName("txt_null"):setString(var_0_6:translation("ELEMENT_EQUIP_TEXT6"))
		end

		return
	else
		arg_11_0:nodeByName("detail"):setVisible(true)
		arg_11_0:nodeByName("txt_null"):setVisible(false)

		local var_11_0 = var_0_3:itemID(arg_11_0.equipID)
		local var_11_1 = arg_11_0:nodeByName("middle_item_container")

		var_11_1:removeAllChildren()
		arg_11_0:setElementEquipBorder(var_11_1, var_11_0, arg_11_0.equipLV, nil, arg_11_0.equippingType_)

		local var_11_2 = arg_11_0.backpack:getItemNumByID(var_11_0)

		arg_11_0:nodeByName("txt_num"):setString(var_11_2)
		arg_11_0:nodeByName("txt_desc"):setString(var_0_5:desc2(var_11_0))
		arg_11_0:nodeByName("txt_name"):setString(var_0_5:name(var_11_0))

		local var_11_3 = arg_11_0:createDescStr(var_11_0, arg_11_0.equipLV)

		arg_11_0.descList:removeAllItems()

		local var_11_4 = arg_11_0.descList:newItem()
		local var_11_5 = arg_11_0:nodeByName("attr_container"):getContentSize()
		local var_11_6 = xyd.createLabel(22, cc.c3b(52, 54, 55))

		var_11_6:setString(var_11_3)
		var_11_6:setWidth(var_11_5.width - 20)
		var_11_6:setAnchorPoint(0, 0)
		var_11_4:addContent(var_11_6)
		var_11_4:setItemSize(var_11_5.width, var_11_6:getContentSize().height)
		arg_11_0.descList:addItem(var_11_4)
		arg_11_0.descList:reload()

		if arg_11_0.equippingType_ == var_0_10.equipping then
			if not arg_11_0.equips or arg_11_0.equips[arg_11_0.pos] == 0 then
				arg_11_0:setEquipBtn(var_0_12.equip)
			elseif arg_11_0.equips and arg_11_0.equips[arg_11_0.pos] == arg_11_0.equipID then
				arg_11_0:setEquipBtn(var_0_12.takeoff)
			else
				arg_11_0:setEquipBtn(var_0_12.change)
			end
		elseif arg_11_0.equips and arg_11_0.equips[arg_11_0.pos] and arg_11_0.equips[arg_11_0.pos] ~= 0 then
			arg_11_0:setEquipBtn(var_0_12.change)
		else
			arg_11_0:setEquipBtn(var_0_12.equip)
		end

		if arg_11_0.equippingType_ == var_0_10.inBackpack then
			arg_11_0:nodeByName("btn_strth"):setVisible(false)
			arg_11_0:nodeByName("btn_equip"):setPosition(153.5, 89)
			arg_11_0:nodeByName("btn_decompose"):setPosition(350, 89)
		else
			arg_11_0:nodeByName("btn_strth"):setVisible(true)
			arg_11_0:nodeByName("btn_equip"):setPosition(93.5, 89)
			arg_11_0:nodeByName("btn_decompose"):setPosition(410, 89)
		end
	end
end

function var_0_0.updateRightContainer(arg_12_0, arg_12_1)
	arg_12_0:updateEquipContainer(arg_12_1)
	arg_12_0:updateStrthContainer()
	arg_12_0:updateDecomposeContainer()
end

function var_0_0.setElementEquipBorder(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7, arg_13_8)
	local var_13_0 = arg_13_1:getContentSize()
	local var_13_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/element_equip.csb")
	local var_13_2 = var_13_1:getChildByName("background"):getContentSize()
	local var_13_3 = var_13_1:getChildByName("gray_label")

	var_13_1:setScale(var_13_0.width / var_13_2.width)
	var_13_1:setPosition(0, 0)
	var_13_1:addTo(arg_13_1)

	if arg_13_2 then
		var_13_1:getChildByName("bg1"):setVisible(false)
		var_13_1:getChildByName("bg2"):setVisible(false)
		var_13_3:setVisible(false)
		var_13_1:getChildByName("green_plus"):setVisible(false)
		var_13_1:getChildByName("yellow_plus"):setVisible(false)

		local var_13_4 = var_13_1:getChildByName("icon")
		local var_13_5 = var_13_1:getChildByName("bg_element_lv")

		if arg_13_5 and arg_13_5 == var_0_10.inBackpack then
			local var_13_6 = arg_13_0.backpack:getItemNumByID(arg_13_2)

			xyd.setSpecialItemBorderNewUI(var_13_4, arg_13_2, nil, nil, var_13_6)
		else
			xyd.setSpecialItemBorderNewUI(var_13_4, arg_13_2)
		end

		if arg_13_3 and arg_13_3 ~= 0 then
			var_13_5:setVisible(true)
			var_13_5:getChildByName("txt_lv"):setString(arg_13_3)
			var_13_5:getChildByName("txt_lv"):enableOutline(cc.c4b(84, 110, 123, 255), 2)
		end

		local var_13_7 = var_0_3:element(arg_13_2)
		local var_13_8 = var_0_3:equipType(arg_13_2)
		local var_13_9

		if var_13_8 == xyd.ElementEquipType.SP_CORE then
			var_13_9 = var_13_1:getChildByName("icon" .. var_13_7 .. "_2")
		else
			var_13_9 = var_13_1:getChildByName("icon" .. var_13_7 .. "_1")
		end

		var_13_9:setVisible(true)

		if arg_13_5 and arg_13_5 == var_0_10.equipping and arg_13_0.hero:getElementEquipActiveRate(arg_13_2) > 1 then
			arg_13_0:addActiveEffeft(var_13_9, var_13_7, 1, true)
		elseif arg_13_5 and arg_13_5 == var_0_10.equipping and var_13_8 == xyd.ElementEquipType.SP_CORE then
			arg_13_0:addActiveEffeft(var_13_9, var_13_7, 1, true)
		end
	else
		var_13_1:getChildByName("bg1"):setVisible(arg_13_6 == 1)
		var_13_1:getChildByName("bg2"):setVisible(arg_13_6 ~= 1)

		if arg_13_7 then
			var_13_3:setString(var_0_6:translation("ELEMENT_EQUIP_TEXT17"))
			var_13_3:enableOutline(cc.c4b(84, 110, 123, 255), 2)
			var_13_1:getChildByName("yellow_plus"):setVisible(false)
		else
			var_13_3:setVisible(false)
			var_13_1:getChildByName("green_plus"):setVisible(false)
		end
	end

	if arg_13_5 and arg_13_8 then
		if arg_13_5 == var_0_10.equipping then
			var_13_1:getChildByName("element_type2"):setVisible(true)
		elseif arg_13_5 == var_0_10.binding then
			var_13_1:getChildByName("element_type1"):setVisible(true)
		end
	end

	if not arg_13_4 then
		return
	else
		var_13_1:setContentSize(var_13_1:getChildByName("background"):getContentSize())
		var_13_1:setTouchEnabled(true)
		var_13_1:setTouchSwallowEnabled(false)
		var_13_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
			if arg_14_0.name == "began" then
				var_13_1:getChildByName("green_plus"):setScale(0.9)

				return true
			elseif arg_14_0.name == "ended" then
				var_13_1:getChildByName("green_plus"):setScale(1)
				arg_13_4(arg_14_0)
			end
		end)
	end
end

function var_0_0.initTopContainer(arg_15_0)
	arg_15_0:nodeByName("txt_title"):setString(xyd.tables.window:title(arg_15_0.name))

	local var_15_0 = var_0_1.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_15_0:addTo(arg_15_0:nodeByName("top_container"))
	var_15_0:setAnchorPoint(0.5, 0.5)
	var_15_0:setPosition(46, -26)
	var_15_0:addTouchEvent(function(arg_16_0)
		if arg_16_0.name == "ended" then
			if arg_15_0.rightShowType == var_0_11.equip then
				arg_15_0:close()
			else
				arg_15_0:updateRightShow(var_0_11.equip)
			end
		end
	end)
	xyd.nodeEventSample(arg_15_0:nodeByName("btn_rule"), nil, function(arg_17_0)
		local var_17_0 = {}

		var_17_0.title_name = "ELEMENT_EQUIP_RULE_TITLE"
		var_17_0.rule = "ELEMENT_EQUIP_RULE_TEXT"
		var_17_0.style = xyd.RuleStyle.BLUE

		xyd.WindowManager.get():openWindow("new_text_rule", var_17_0)
	end)
end

function var_0_0.updateEquipContainer(arg_18_0, arg_18_1)
	arg_18_0:initShowItem()

	arg_18_0.equipContainer_ = {}

	if arg_18_0.pos == 1 then
		if arg_18_0.coreEquipShowItem and next(arg_18_0.coreEquipShowItem) then
			if arg_18_1 then
				arg_18_0.equipID = arg_18_0.coreEquipShowItem[1].id
				arg_18_0.equipLV = arg_18_0.coreEquipShowItem[1].lv
				arg_18_0.equippingType_ = arg_18_0.coreEquipShowItem[1].type
				arg_18_0.rightPos = 1
			end

			arg_18_0.equipList:reload()
		else
			if arg_18_1 then
				arg_18_0.equipID = nil
				arg_18_0.equipLV = nil
				arg_18_0.equippingType_ = nil
				arg_18_0.rightPos = nil
			end

			arg_18_0.equipList:reload()
		end
	elseif arg_18_0.normalEquipShowItem and next(arg_18_0.normalEquipShowItem) then
		if arg_18_1 then
			arg_18_0.equipID = arg_18_0.normalEquipShowItem[1].id
			arg_18_0.equipLV = arg_18_0.normalEquipShowItem[1].lv
			arg_18_0.equippingType_ = arg_18_0.normalEquipShowItem[1].type
			arg_18_0.rightPos = 1
		end

		arg_18_0.equipList:reload()
	else
		if arg_18_1 then
			arg_18_0.equipID = nil
			arg_18_0.equipLV = nil
			arg_18_0.equippingType_ = nil
			arg_18_0.rightPos = nil
		end

		arg_18_0.equipList:reload()
	end

	if arg_18_0.rightPos and arg_18_0.rightPos ~= 0 then
		arg_18_0:addSelectEffect(var_0_9.right, arg_18_0.equipContainer_[arg_18_0.rightPos], 0.85)
	end
end

function var_0_0.updateStrthContainer(arg_19_0)
	if not arg_19_0.equipID then
		return
	end

	local var_19_0 = var_0_3:itemID(arg_19_0.equipID)
	local var_19_1 = var_0_3:strthDscSuffix(var_19_0)
	local var_19_2 = arg_19_0:nodeByName("strth_equip_container")

	var_19_2:removeAllChildren()
	arg_19_0:setElementEquipBorder(var_19_2, var_19_0, arg_19_0.equipLV, nil, arg_19_0.equippingType_)
	arg_19_0:nodeByName("txt_now_lv"):setString(arg_19_0.equipLV)

	local var_19_3 = var_0_3:strth(var_19_0, arg_19_0.equipLV)

	arg_19_0:nodeByName("txt_strth_attr_now"):setString(var_19_3 .. var_19_1)
	arg_19_0:nodeByName("txt_strth_attr"):setString(var_0_3:strthDsc(var_19_0))

	if arg_19_0.equipLV < 10 then
		arg_19_0:nodeByName("strth_next_container"):setVisible(true)
		arg_19_0:nodeByName("txt_max"):setVisible(false)
		arg_19_0:nodeByName("txt_now"):setPositionX(114)
		arg_19_0:nodeByName("txt_now_lv"):setPositionX(198)
		arg_19_0:nodeByName("txt_strth_attr_now"):setPositionX(175)
		arg_19_0:nodeByName("txt_next_lv"):setString(arg_19_0.equipLV + 1)
		arg_19_0:nodeByName("txt_strth_attr_next"):setString(var_0_3:strth(var_19_0, arg_19_0.equipLV + 1) .. var_19_1)
		arg_19_0.strthList:reload()
	else
		arg_19_0:nodeByName("strth_next_container"):setVisible(false)
		arg_19_0:nodeByName("txt_max"):setVisible(true)
		arg_19_0:nodeByName("txt_now"):setPositionX(230)
		arg_19_0:nodeByName("txt_now_lv"):setPositionX(324)
		arg_19_0:nodeByName("txt_strth_attr_now"):setPositionX(250)
	end
end

function var_0_0.updateDecomposeContainer(arg_20_0)
	if not arg_20_0.equipID then
		return
	end

	local var_20_0 = var_0_3:itemID(arg_20_0.equipID)
	local var_20_1 = arg_20_0:nodeByName("dec_equip_container")

	var_20_1:removeAllChildren()
	arg_20_0:setElementEquipBorder(var_20_1, var_20_0, arg_20_0.equipLV, nil, arg_20_0.equippingType_)
	arg_20_0.decList:reload()
end

function var_0_0.initButton(arg_21_0)
	arg_21_0:nodeByName("btn_equip"):addTouchEventListener(function(arg_22_0, arg_22_1)
		xyd.buttonScaleAnim(arg_22_0, arg_22_1)

		if arg_22_1 == ccui.TouchEventType.ended then
			if arg_21_0.equippingType_ == var_0_10.equipping then
				if arg_21_0.equips and arg_21_0.equips[arg_21_0.pos] == arg_21_0.equipID then
					local var_22_0 = var_0_6:translation("ELEMENT_EQUIP_TEXT24")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_22_0, function()
						arg_21_0.elementEquip:takeOffElementItem(arg_21_0.hero, arg_21_0.pos, function(arg_24_0, arg_24_1)
							if arg_24_0 == xyd.error.OK then
								arg_21_0.equippingType_ = var_0_10.binding

								arg_21_0:updateItems()
								arg_21_0:updateRightContainer(true)
								arg_21_0:updateLeftContainer()
								arg_21_0:updateMiddleContainer()
							end
						end)
					end)
				else
					local var_22_1 = var_0_6:translation("ELEMENT_EQUIP_TEXT30")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_22_1
					})
				end
			else
				local var_22_2 = var_0_3:itemID(arg_21_0.equipID)
				local var_22_3 = var_0_3:partnerID(var_22_2)

				if var_22_3 ~= 0 and var_22_3 ~= arg_21_0.hero:getFirstTableID() then
					local var_22_4 = var_0_6:translation("ELEMENT_EQUIP_TEXT20")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_22_4
					})

					return
				end

				if arg_21_0.equippingType_ == var_0_10.inBackpack and arg_21_0.bindingEquips and next(arg_21_0.bindingEquips) then
					for iter_22_0 = 1, #arg_21_0.bindingEquips do
						if arg_21_0.equipID == arg_21_0.bindingEquips[iter_22_0].id then
							local var_22_5 = var_0_6:translation("ELEMENT_EQUIP_TEXT26")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_22_5
							})

							return
						end
					end
				end

				local function var_22_6()
					arg_21_0.elementEquip:equipElementItem(arg_21_0.hero, arg_21_0.equipID, arg_21_0.pos, function(arg_26_0, arg_26_1)
						if arg_26_0 == xyd.error.OK then
							if arg_21_0.equippingType_ == var_0_10.inBackpack then
								arg_21_0.equippingType_ = var_0_10.equipping

								local var_26_0 = {
									itemID = var_22_2
								}

								var_26_0.itemNum = 1

								arg_21_0.backpack:removeItem(var_26_0)
								arg_21_0:updateItems()

								if arg_21_0.backpack:getItemNumByID(var_22_2) == 0 then
									arg_21_0:updateRightContainer(true)
								else
									arg_21_0:findEquippingRightPos()
									arg_21_0:updateRightContainer()
								end

								arg_21_0:updateLeftContainer()
								arg_21_0:updateMiddleContainer()
							elseif arg_21_0.equippingType_ == var_0_10.binding then
								arg_21_0.equippingType_ = var_0_10.equipping

								arg_21_0:updateItems()
								arg_21_0:findEquippingRightPos()
								arg_21_0:updateRightContainer()
								arg_21_0:updateLeftContainer()
								arg_21_0:updateMiddleContainer()
							end
						end
					end)
				end

				local var_22_7

				if arg_21_0.equips and arg_21_0.equips[arg_21_0.pos] and arg_21_0.equips[arg_21_0.pos] ~= 0 then
					if arg_21_0.equippingType_ == var_0_10.binding then
						var_22_7 = var_0_6:translation("ELEMENT_EQUIP_TEXT22")
					elseif arg_21_0.equippingType_ == var_0_10.inBackpack then
						var_22_7 = var_0_6:translation("ELEMENT_EQUIP_TEXT23")
					end

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_22_7, var_22_6)
				elseif arg_21_0.equippingType_ == var_0_10.binding then
					var_22_6()
				elseif arg_21_0.equippingType_ == var_0_10.inBackpack then
					local var_22_8 = var_0_6:translation("ELEMENT_EQUIP_TEXT23")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_22_8, var_22_6)
				end
			end
		end
	end)
	arg_21_0:nodeByName("btn_strth"):addTouchEventListener(function(arg_27_0, arg_27_1)
		xyd.buttonScaleAnim(arg_27_0, arg_27_1)

		if arg_27_1 == ccui.TouchEventType.ended then
			arg_21_0:updateRightShow(var_0_11.strth)
		end
	end)
	arg_21_0:nodeByName("btn_decompose"):addTouchEventListener(function(arg_28_0, arg_28_1)
		xyd.buttonScaleAnim(arg_28_0, arg_28_1)

		if arg_28_1 == ccui.TouchEventType.ended then
			arg_21_0:updateRightShow(var_0_11.decompose)
		end
	end)
	arg_21_0:nodeByName("btn_right_strth"):addTouchEventListener(function(arg_29_0, arg_29_1)
		xyd.buttonScaleAnim(arg_29_0, arg_29_1)

		if arg_29_1 == ccui.TouchEventType.ended then
			local function var_29_0()
				arg_21_0.elementEquip:strengthenElementItem(arg_21_0.hero, arg_21_0.equipID, function()
					local var_31_0 = var_0_3:itemID(arg_21_0.equipID)
					local var_31_1 = var_0_3:equipType(var_31_0)
					local var_31_2 = var_0_4:strthMtrs(arg_21_0.equipLV, var_31_1)
					local var_31_3 = var_0_4:strthMtrsNums(arg_21_0.equipLV, var_31_1)

					for iter_31_0 = 1, #var_31_2 do
						local var_31_4 = {
							itemID = var_31_2[iter_31_0],
							itemNum = var_31_3[iter_31_0]
						}

						arg_21_0.backpack:removeItem(var_31_4)
					end

					arg_21_0.equipLV = arg_21_0.equipLV + 1

					arg_21_0:updateItems()
					arg_21_0:updateRightContainer()
					arg_21_0:updateMiddleContainer()
					arg_21_0:updateLeftContainer()
				end)
			end

			local var_29_1 = var_0_3:itemID(arg_21_0.equipID)
			local var_29_2 = var_0_3:equipType(var_29_1)
			local var_29_3 = var_0_4:strthMtrs(arg_21_0.equipLV, var_29_2)
			local var_29_4 = var_0_4:strthMtrsNums(arg_21_0.equipLV, var_29_2)
			local var_29_5

			for iter_29_0 = 1, #var_29_3 do
				if arg_21_0.backpack:getItemNumByID(var_29_3[iter_29_0]) < var_29_4[iter_29_0] then
					local var_29_6 = var_0_6:translation("ELEMENT_EQUIP_TEXT27")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_29_6
					})

					return
				end

				if var_0_5:quality(var_29_3[iter_29_0]) > xyd.ItemQuality.Purple then
					var_29_5 = var_29_4[iter_29_0]
				end
			end

			if var_29_5 then
				local var_29_7 = string.format(var_0_6:translation("ELEMENT_EQUIP_TEXT21"), var_29_5)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_29_7, var_29_0)
			else
				var_29_0()
			end
		end
	end)
	arg_21_0:nodeByName("btn_right_decompose"):addTouchEventListener(function(arg_32_0, arg_32_1)
		xyd.buttonScaleAnim(arg_32_0, arg_32_1)

		if arg_32_1 == ccui.TouchEventType.ended then
			if arg_21_0.equippingType_ == var_0_10.inBackpack then
				local var_32_0 = var_0_6:translation("ELEMENT_EQUIP_TEXT19")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_32_0, function()
					arg_21_0.elementEquip:decomposeBackpackElementItem(arg_21_0.equipID, function(arg_34_0, arg_34_1)
						if arg_34_0 == xyd.error.OK then
							local var_34_0 = var_0_3:itemID(arg_21_0.equipID)
							local var_34_1 = var_0_3:equipType(var_34_0)
							local var_34_2 = {
								itemID = var_34_0
							}

							var_34_2.itemNum = 1

							arg_21_0.backpack:removeItem(var_34_2)

							local var_34_3 = var_0_4:decMtrs(arg_21_0.equipLV, var_34_1)
							local var_34_4 = var_0_4:decMtrsNums(arg_21_0.equipLV, var_34_1)
							local var_34_5 = {}

							for iter_34_0 = 1, #var_34_3 do
								local var_34_6 = {
									table_id = var_34_3[iter_34_0],
									item_num = var_34_4[iter_34_0]
								}

								table.insert(var_34_5, var_34_6)
							end

							arg_21_0.selfPlayer:handleRewards(var_34_5)

							if arg_21_0.backpack:getItemNumByID(var_34_0) == 0 then
								arg_21_0:updateRightShow(var_0_11.equip)
								arg_21_0:updateItems()
								arg_21_0:updateRightContainer(true)
								arg_21_0:updateMiddleContainer()
								arg_21_0:updateLeftContainer()
							else
								arg_21_0:updateItems()
								arg_21_0:updateRightContainer()
								arg_21_0:updateMiddleContainer()
								arg_21_0:updateLeftContainer()
							end
						end
					end)
				end)
			else
				local var_32_1 = var_0_6:translation("ELEMENT_EQUIP_TEXT19")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_32_1, function()
					arg_21_0.elementEquip:decomposeHeroElementItem(arg_21_0.hero, arg_21_0.equipID, function(arg_36_0, arg_36_1)
						if arg_36_0 == xyd.error.OK then
							local var_36_0 = var_0_3:itemID(arg_21_0.equipID)
							local var_36_1 = var_0_3:equipType(var_36_0)
							local var_36_2 = var_0_4:decMtrs(arg_21_0.equipLV, var_36_1)
							local var_36_3 = var_0_4:decMtrsNums(arg_21_0.equipLV, var_36_1)
							local var_36_4 = {}

							for iter_36_0 = 1, #var_36_2 do
								local var_36_5 = {
									table_id = var_36_2[iter_36_0],
									item_num = var_36_3[iter_36_0]
								}

								table.insert(var_36_4, var_36_5)
							end

							arg_21_0.selfPlayer:handleRewards(var_36_4)
							arg_21_0:updateRightShow(var_0_11.equip)
							arg_21_0:updateItems()
							arg_21_0:updateRightContainer(true)
							arg_21_0:updateMiddleContainer()
							arg_21_0:updateLeftContainer()
						end
					end)
				end)
			end
		end
	end)
	arg_21_0:nodeByName("btn_all"):addTouchEventListener(function(arg_37_0, arg_37_1)
		if arg_37_1 == ccui.TouchEventType.ended then
			if arg_21_0.selectElement == 0 then
				arg_21_0:updateSelectButton()

				return
			end

			arg_21_0.selectElement = 0

			arg_21_0:updateSelectButton()
			arg_21_0:updateRightContainer(true)
			arg_21_0:updateMiddleContainer()
			arg_21_0:returnEquipRightShow()
		end
	end)
	arg_21_0:nodeByName("btn_fire"):addTouchEventListener(function(arg_38_0, arg_38_1)
		if arg_38_1 == ccui.TouchEventType.ended then
			if arg_21_0.selectElement == xyd.ElementType.FIRE then
				arg_21_0:updateSelectButton()

				return
			end

			arg_21_0.selectElement = xyd.ElementType.FIRE

			arg_21_0:updateSelectButton()
			arg_21_0:updateRightContainer(true)
			arg_21_0:updateMiddleContainer()
			arg_21_0:returnEquipRightShow()
		end
	end)
	arg_21_0:nodeByName("btn_water"):addTouchEventListener(function(arg_39_0, arg_39_1)
		if arg_39_1 == ccui.TouchEventType.ended then
			if arg_21_0.selectElement == xyd.ElementType.WATER then
				arg_21_0:updateSelectButton()

				return
			end

			arg_21_0.selectElement = xyd.ElementType.WATER

			arg_21_0:updateSelectButton()
			arg_21_0:updateRightContainer(true)
			arg_21_0:updateMiddleContainer()
			arg_21_0:returnEquipRightShow()
		end
	end)
	arg_21_0:nodeByName("btn_lighting"):addTouchEventListener(function(arg_40_0, arg_40_1)
		if arg_40_1 == ccui.TouchEventType.ended then
			if arg_21_0.selectElement == xyd.ElementType.THUNDER then
				arg_21_0:updateSelectButton()

				return
			end

			arg_21_0.selectElement = xyd.ElementType.THUNDER

			arg_21_0:updateSelectButton()
			arg_21_0:updateRightContainer(true)
			arg_21_0:updateMiddleContainer()
			arg_21_0:returnEquipRightShow()
		end
	end)

	local var_21_0 = arg_21_0:nodeByName("btn_beibao")

	var_21_0:setTouchEnabled(true)
	arg_21_0:nodeByName("btn_beibao"):addTouchEventListener(function(arg_41_0, arg_41_1)
		if arg_41_1 == ccui.TouchEventType.began then
			var_21_0:scale(0.8)
		elseif arg_41_1 == ccui.TouchEventType.ended then
			var_21_0:scale(1)

			local var_41_0 = {
				pos = 1,
				hero = arg_21_0.hero
			}

			xyd.WindowManager.get():openWindow("element_equip_tujian", var_41_0)
			xyd.WindowManager.get():closeWindow("element_equip")
		end
	end)
	arg_21_0:nodeByName("bg_select_off"):setTouchEnabled(true)
	arg_21_0:nodeByName("bg_select_off"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_42_0)
		if arg_42_0.name == "began" then
			return true
		elseif arg_42_0.name == "ended" then
			arg_21_0:nodeByName("bg_select_off"):setVisible(false)
			arg_21_0:nodeByName("bg_select_on"):setVisible(true)

			arg_21_0.isSpShow = false

			arg_21_0:updateRightContainer(true)
			arg_21_0:updateMiddleContainer()
		end
	end)
	arg_21_0:nodeByName("bg_select_on"):setTouchEnabled(true)
	arg_21_0:nodeByName("bg_select_on"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_43_0)
		if arg_43_0.name == "began" then
			return true
		elseif arg_43_0.name == "ended" then
			arg_21_0:nodeByName("bg_select_on"):setVisible(false)
			arg_21_0:nodeByName("bg_select_off"):setVisible(true)

			arg_21_0.isSpShow = true

			arg_21_0:updateRightContainer(true)
			arg_21_0:updateMiddleContainer()
		end
	end)
end

function var_0_0.updateSelectButton(arg_44_0)
	arg_44_0:nodeByName("btn_all"):setBrightStyle(arg_44_0.selectElement == 0 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	arg_44_0:nodeByName("btn_fire"):setBrightStyle(arg_44_0.selectElement == xyd.ElementType.FIRE and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	arg_44_0:nodeByName("btn_water"):setBrightStyle(arg_44_0.selectElement == xyd.ElementType.WATER and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	arg_44_0:nodeByName("btn_lighting"):setBrightStyle(arg_44_0.selectElement == xyd.ElementType.THUNDER and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
end

function var_0_0.equipListDelegate(arg_45_0, arg_45_1, arg_45_2, arg_45_3)
	local var_45_0

	if arg_45_0.pos == 1 then
		var_45_0 = #arg_45_0.coreEquipShowItem
	else
		var_45_0 = #arg_45_0.normalEquipShowItem
	end

	if arg_45_2 == cc.ui.UIListView.COUNT_TAG then
		return math.ceil(var_45_0 / var_0_7)
	elseif arg_45_2 == cc.ui.UIListView.CELL_TAG then
		local var_45_1 = arg_45_0.equipList:dequeueItem()

		if not var_45_1 then
			var_45_1 = arg_45_0.equipList:newItem()
		else
			var_45_1:removeAllChildren()
		end

		local var_45_2 = arg_45_0:createEquipShowContent(arg_45_3)

		var_45_1:addContent(var_45_2)

		local var_45_3 = var_45_2:getContentSize()

		var_45_1:setContentSize(var_45_3)
		var_45_1:setItemSize(var_45_3.width, var_45_3.height + 20)

		return var_45_1
	end
end

function var_0_0.createEquipShowContent(arg_46_0, arg_46_1)
	local var_46_0 = display.newNode()
	local var_46_1 = 52
	local var_46_2 = 47
	local var_46_3 = 108

	var_46_0:setContentSize(arg_46_0.equipList:getViewRect().width, 94)

	for iter_46_0 = 1, var_0_7 do
		local var_46_4 = (arg_46_1 - 1) * var_0_7 + iter_46_0
		local var_46_5

		if arg_46_0.pos == 1 then
			if not arg_46_0.coreEquipShowItem[var_46_4] then
				break
			end

			var_46_5 = arg_46_0.coreEquipShowItem[var_46_4]
		else
			if not arg_46_0.normalEquipShowItem[var_46_4] then
				break
			end

			var_46_5 = arg_46_0.normalEquipShowItem[var_46_4]
		end

		local var_46_6 = display.newNode()
		local var_46_7 = var_0_3:itemID(var_46_5.id)

		var_46_6:setContentSize(94, 94)
		table.insert(arg_46_0.equipContainer_, var_46_6)

		local function var_46_8()
			if not arg_46_0.scrollViewMoved_ then
				arg_46_0.equipID = var_46_5.id
				arg_46_0.equipLV = var_46_5.lv
				arg_46_0.equippingType_ = var_46_5.type
				arg_46_0.rightPos = var_46_4

				arg_46_0:addSelectEffect(var_0_9.right, var_46_6, 0.85)
				arg_46_0:updateMiddleContainer()
				arg_46_0:updateStrthContainer()
				arg_46_0:updateDecomposeContainer()
			end
		end

		arg_46_0:setElementEquipBorder(var_46_6, var_46_7, var_46_5.lv, var_46_8, var_46_5.type, nil, nil, true)
		var_46_6:setAnchorPoint(0.5, 0.5)
		var_46_6:addTo(var_46_0)
		var_46_6:setPosition(var_46_1, var_46_2)

		var_46_1 = var_46_1 + var_46_3
	end

	return var_46_0
end

function var_0_0.strthListDelegate(arg_48_0, arg_48_1, arg_48_2, arg_48_3)
	if not arg_48_0.equipID then
		return 0
	end

	local var_48_0 = var_0_3:itemID(arg_48_0.equipID)
	local var_48_1 = var_0_3:equipType(var_48_0)
	local var_48_2 = var_0_4:strthMtrs(arg_48_0.equipLV, var_48_1)
	local var_48_3 = var_0_4:strthMtrsNums(arg_48_0.equipLV, var_48_1)

	if arg_48_2 == cc.ui.UIListView.COUNT_TAG then
		return #var_48_2
	elseif arg_48_2 == cc.ui.UIListView.CELL_TAG then
		local var_48_4 = arg_48_0.strthList:dequeueItem()

		if not var_48_4 then
			var_48_4 = arg_48_0.strthList:newItem()
		else
			var_48_4:removeAllChildren()
		end

		local var_48_5 = display.newNode()
		local var_48_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/compose/element_equip_strth_item.csb")
		local var_48_7 = var_48_6:getChildByName("container")
		local var_48_8 = var_48_7:getContentSize()
		local var_48_9 = display.newNode()
		local var_48_10 = var_48_7:getChildByName("item_container")

		var_48_9:setContentSize(var_48_10:getContentSize())
		var_48_9:addTo(var_48_10)
		var_48_9:setAnchorPoint(0, 0)
		var_48_9:setPosition(0, 0)
		var_48_5:setContentSize(var_48_8)
		xyd.setItemBorder(var_48_9, var_48_2[arg_48_3])

		local var_48_11 = {
			id = var_48_2[arg_48_3],
			lev = var_0_5:level(var_48_2[arg_48_3])
		}

		if var_0_5:type(var_48_2[arg_48_3]) == -1 then
			var_48_11.tipsType = 0
			var_48_11.desc1 = xyd.tables.hero:getDes(var_48_2[arg_48_3])
		else
			var_48_11.tipsType = 1
			var_48_11.desc1 = var_0_5:desc1(var_48_2[arg_48_3])
			var_48_11.desc2 = var_0_5:desc2(var_48_2[arg_48_3])
		end

		var_48_11.hasNum = arg_48_0.backpack:getItemNumByID(var_48_2[arg_48_3])
		var_48_11.name = var_0_5:name(var_48_2[arg_48_3])

		arg_48_0:addTips(var_48_9, var_48_11)

		local var_48_12 = arg_48_0.backpack:getItemNumByID(var_48_2[arg_48_3])

		if var_48_12 >= var_48_3[arg_48_3] then
			var_48_7:getChildByName("txt_num"):setColor(cc.c3b(52, 54, 55))
		else
			var_48_7:getChildByName("txt_num"):setColor(cc.c3b(228, 104, 124))
		end

		var_48_7:getChildByName("txt_num"):setString(var_48_3[arg_48_3] .. "/" .. var_48_12)
		var_48_6:addTo(var_48_5)
		var_48_4:addContent(var_48_5)
		var_48_4:setContentSize(var_48_8)
		var_48_4:setItemSize(var_48_8.width, var_48_8.height + 5)

		return var_48_4
	end
end

function var_0_0.decListDelegate(arg_49_0, arg_49_1, arg_49_2, arg_49_3)
	if not arg_49_0.equipID then
		return 0
	end

	local var_49_0 = var_0_3:itemID(arg_49_0.equipID)
	local var_49_1 = var_0_3:equipType(var_49_0)
	local var_49_2 = var_0_4:decMtrs(arg_49_0.equipLV, var_49_1)
	local var_49_3 = var_0_4:decMtrsNums(arg_49_0.equipLV, var_49_1)

	if arg_49_2 == cc.ui.UIListView.COUNT_TAG then
		return #var_49_2
	elseif arg_49_2 == cc.ui.UIListView.CELL_TAG then
		local var_49_4 = arg_49_0.decList:dequeueItem()

		if not var_49_4 then
			var_49_4 = arg_49_0.decList:newItem()
		else
			var_49_4:removeAllChildren()
		end

		local var_49_5 = display.newNode()
		local var_49_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/compose/element_equip_dec_item.csb")
		local var_49_7 = var_49_6:getChildByName("container")
		local var_49_8 = var_49_7:getContentSize()
		local var_49_9 = display.newNode()
		local var_49_10 = var_49_7:getChildByName("item_container")

		var_49_9:setContentSize(var_49_10:getContentSize())
		var_49_9:addTo(var_49_10)
		var_49_9:setAnchorPoint(0, 0)
		var_49_9:setPosition(0, 0)
		var_49_5:setContentSize(var_49_8)
		xyd.setItemBorder(var_49_9, var_49_2[arg_49_3])
		var_49_7:getChildByName("txt_num"):setString("x" .. var_49_3[arg_49_3])

		local var_49_11 = {
			id = var_49_2[arg_49_3],
			lev = var_0_5:level(var_49_2[arg_49_3])
		}

		if var_0_5:type(var_49_2[arg_49_3]) == -1 then
			var_49_11.tipsType = 0
			var_49_11.desc1 = xyd.tables.hero:getDes(var_49_2[arg_49_3])
		else
			var_49_11.tipsType = 1
			var_49_11.desc1 = var_0_5:desc1(var_49_2[arg_49_3])
			var_49_11.desc2 = var_0_5:desc2(var_49_2[arg_49_3])
		end

		var_49_11.hasNum = arg_49_0.backpack:getItemNumByID(var_49_2[arg_49_3])
		var_49_11.name = var_0_5:name(var_49_2[arg_49_3])

		arg_49_0:addTips(var_49_9, var_49_11)

		local var_49_12 = var_0_6:translation("ELEMENT_EQUIP_TEXT25")
		local var_49_13 = arg_49_0.backpack:getItemNumByID(var_49_2[arg_49_3])

		var_49_7:getChildByName("txt_all"):setString(string.format(var_49_12, var_49_13))
		var_49_6:addTo(var_49_5)
		var_49_4:addContent(var_49_5)
		var_49_4:setContentSize(var_49_8)
		var_49_4:setItemSize(var_49_8.width, var_49_8.height)

		return var_49_4
	end
end

function var_0_0.initShowItem(arg_50_0)
	arg_50_0.coreEquipShowItem = {}
	arg_50_0.normalEquipShowItem = {}

	if arg_50_0.equips and arg_50_0.equips[1] ~= 0 then
		local var_50_0 = var_0_3:itemID(arg_50_0.equips[1])
		local var_50_1 = var_0_3:element(var_50_0)
		local var_50_2 = {
			id = arg_50_0.equips[1],
			lv = arg_50_0.equipsLV[1],
			type = var_0_10.equipping
		}

		if arg_50_0.selectElement == 0 or arg_50_0.selectElement == var_50_1 then
			table.insert(arg_50_0.coreEquipShowItem, var_50_2)
		end
	end

	for iter_50_0 = 2, xyd.MAX_ELEMENT_ITEM_NUM do
		if arg_50_0.equips and arg_50_0.equips[iter_50_0] ~= 0 then
			local var_50_3 = var_0_3:itemID(arg_50_0.equips[iter_50_0])
			local var_50_4 = var_0_3:element(var_50_3)
			local var_50_5 = {
				id = arg_50_0.equips[iter_50_0],
				lv = arg_50_0.equipsLV[iter_50_0],
				type = var_0_10.equipping,
				pos = iter_50_0
			}

			if arg_50_0.selectElement == 0 or arg_50_0.selectElement == var_50_4 then
				table.insert(arg_50_0.normalEquipShowItem, var_50_5)
			end
		end
	end

	if arg_50_0.bindingEquips and next(arg_50_0.bindingEquips) then
		local var_50_6 = #arg_50_0.coreEquipShowItem

		for iter_50_1 = 1, #arg_50_0.bindingEquips do
			local var_50_7 = false

			for iter_50_2 = 1, xyd.MAX_ELEMENT_ITEM_NUM do
				if arg_50_0.equips and arg_50_0.equips[iter_50_2] == arg_50_0.bindingEquips[iter_50_1].id then
					var_50_7 = true
				end
			end

			if not var_50_7 then
				local var_50_8 = var_0_3:itemID(arg_50_0.bindingEquips[iter_50_1].id)
				local var_50_9 = var_0_3:equipType(var_50_8)
				local var_50_10 = var_0_3:element(var_50_8)

				if var_50_9 == xyd.ElementEquipType.NORMAL then
					local var_50_11 = {
						id = arg_50_0.bindingEquips[iter_50_1].id,
						lv = arg_50_0.bindingEquips[iter_50_1].lv,
						type = var_0_10.binding
					}

					if arg_50_0.selectElement == 0 or arg_50_0.selectElement == var_50_10 then
						table.insert(arg_50_0.normalEquipShowItem, var_50_11)
					end
				else
					local var_50_12 = {
						id = arg_50_0.bindingEquips[iter_50_1].id,
						lv = arg_50_0.bindingEquips[iter_50_1].lv,
						type = var_0_10.binding
					}

					if arg_50_0.selectElement == 0 or arg_50_0.selectElement == var_50_10 then
						if arg_50_0.bindingEquips[iter_50_1].partner_id == 0 then
							table.insert(arg_50_0.coreEquipShowItem, var_50_12)
						else
							var_50_6 = var_50_6 + 1

							table.insert(arg_50_0.coreEquipShowItem, var_50_6, var_50_12)
						end
					end
				end
			end
		end
	end

	if arg_50_0.equipsInBackpack and next(arg_50_0.equipsInBackpack) then
		local var_50_13 = #arg_50_0.coreEquipShowItem

		for iter_50_3 = 1, #arg_50_0.equipsInBackpack do
			local var_50_14 = arg_50_0.equipsInBackpack[iter_50_3].itemID
			local var_50_15 = var_0_3:equipType(var_50_14)
			local var_50_16 = var_0_3:element(var_50_14)

			if var_50_15 == xyd.ElementEquipType.NORMAL then
				local var_50_17 = {
					id = var_0_3:id(var_50_14)
				}

				var_50_17.lv = 0
				var_50_17.type = var_0_10.inBackpack

				if arg_50_0.selectElement == 0 or arg_50_0.selectElement == var_50_16 then
					table.insert(arg_50_0.normalEquipShowItem, var_50_17)
				end
			elseif var_50_15 == xyd.ElementEquipType.CORE then
				local var_50_18 = {
					id = var_0_3:id(arg_50_0.equipsInBackpack[iter_50_3].itemID)
				}

				var_50_18.lv = 0
				var_50_18.type = var_0_10.inBackpack

				if arg_50_0.selectElement == 0 or arg_50_0.selectElement == var_50_16 then
					table.insert(arg_50_0.coreEquipShowItem, var_50_18)
				end
			elseif var_50_15 == xyd.ElementEquipType.SP_CORE then
				local var_50_19 = var_0_3:partnerID(var_50_14)
				local var_50_20 = {
					id = var_0_3:id(arg_50_0.equipsInBackpack[iter_50_3].itemID)
				}

				var_50_20.lv = 0
				var_50_20.type = var_0_10.inBackpack

				if (var_50_19 == arg_50_0.hero:getFirstTableID() or arg_50_0.isSpShow) and (arg_50_0.selectElement == 0 or arg_50_0.selectElement == var_50_16) then
					var_50_13 = var_50_13 + 1

					table.insert(arg_50_0.coreEquipShowItem, var_50_13, var_50_20)
				end
			end
		end
	end
end

function var_0_0.setEquipBtn(arg_51_0, arg_51_1)
	arg_51_0:nodeByName("txt_equip"):setVisible(arg_51_1 == var_0_12.equip)
	arg_51_0:nodeByName("txt_takeoff"):setVisible(arg_51_1 == var_0_12.takeoff)
	arg_51_0:nodeByName("txt_change"):setVisible(arg_51_1 == var_0_12.change)
end

function var_0_0.addSelectEffect(arg_52_0, arg_52_1, arg_52_2, arg_52_3)
	if not tolua.isnull(arg_52_0.selectEffect[arg_52_1]) and arg_52_0.selectEffect[arg_52_1] then
		transition.stopTarget(arg_52_0.selectEffect[arg_52_1])
		arg_52_0.selectEffect[arg_52_1]:removeSelf()

		arg_52_0.selectEffect[arg_52_1] = nil
	end

	arg_52_0.selectEffect[arg_52_1] = xyd.AssetLoader:get():loadSprite("windows/hero/bg_select.png")

	arg_52_0.selectEffect[arg_52_1]:setAnchorPoint(0.5, 0.5)
	arg_52_0.selectEffect[arg_52_1]:addTo(arg_52_2)
	arg_52_0.selectEffect[arg_52_1]:setPosition(arg_52_2:getContentSize().width / 2, arg_52_2:getContentSize().height / 2)
	arg_52_0.selectEffect[arg_52_1]:setScale(arg_52_3 or 1)

	local var_52_0 = cc.ScaleBy:create(0.3, 1.04)
	local var_52_1 = transition.sequence({
		var_52_0,
		var_52_0:reverse()
	})
	local var_52_2 = cc.RepeatForever:create(var_52_1)

	arg_52_0.selectEffect[arg_52_1]:runAction(var_52_2)
end

function var_0_0.addActiveEffeft(arg_53_0, arg_53_1, arg_53_2, arg_53_3, arg_53_4)
	local var_53_0 = arg_53_3 or 1
	local var_53_1 = "skeletons/ui_effect/element_equip/element_" .. arg_53_2

	if arg_53_4 then
		var_53_1 = var_53_1 .. "xiao"
	end

	local var_53_2 = xyd.createEffect(var_53_1, var_53_0)
	local var_53_3 = arg_53_1:getContentSize()

	var_53_2:addTo(arg_53_1)
	var_53_2:setPosition(var_53_3.width / 2, var_53_3.height / 2)
	var_53_2:play(nil, true)
end

function var_0_0.updateRightShow(arg_54_0, arg_54_1)
	arg_54_0.rightShowType = arg_54_1

	arg_54_0:nodeByName("equip_container"):setVisible(arg_54_0.rightShowType == var_0_11.equip)
	arg_54_0:nodeByName("strth_container"):setVisible(arg_54_0.rightShowType == var_0_11.strth)
	arg_54_0:nodeByName("decompose_container"):setVisible(arg_54_0.rightShowType == var_0_11.decompose)
end

function var_0_0.createDescStr(arg_55_0, arg_55_1, arg_55_2)
	local var_55_0

	if arg_55_0.equippingType_ == var_0_10.equipping then
		var_55_0 = arg_55_0.hero:getElementEquipActiveRate(arg_55_1)
	else
		var_55_0 = 1
	end

	local var_55_1 = var_0_3:equipType(arg_55_1)
	local var_55_2 = var_0_3:base(arg_55_1)
	local var_55_3 = var_0_3:strth(arg_55_1, arg_55_2)
	local var_55_4 = (var_55_2 + var_55_3) * var_55_0
	local var_55_5

	if var_55_1 == xyd.ElementEquipType.NORMAL then
		local var_55_6 = (var_55_2 + var_55_3) * (var_55_0 - 1)

		var_55_5 = string.format(var_0_3:equipDsc(arg_55_1), var_55_4, var_55_2, var_55_3, var_55_6)
	else
		var_55_5 = string.format(var_0_3:equipDsc(arg_55_1), var_55_4, var_55_2, var_55_3)
	end

	local var_55_7 = xyd.split(var_55_5, "|")
	local var_55_8 = ""

	for iter_55_0 = 1, #var_55_7 do
		if iter_55_0 > 1 then
			var_55_8 = var_55_8 .. "\n"
		end

		var_55_8 = var_55_8 .. var_55_7[iter_55_0]
	end

	return var_55_8
end

function var_0_0.scrollListener(arg_56_0, arg_56_1)
	if arg_56_1.name == "began" then
		arg_56_0.scrollViewMoved_ = false
		arg_56_0.prevY_ = arg_56_1.y
	elseif arg_56_1.name == "moved" and 20 <= math.abs(arg_56_1.y - arg_56_0.prevY_) then
		arg_56_0.scrollViewMoved_ = true
	end
end

function var_0_0.findEquippingRightPos(arg_57_0)
	if not arg_57_0.equips or arg_57_0.equips[arg_57_0.pos] == 0 then
		arg_57_0.rightPos = nil

		return
	end

	local var_57_0 = var_0_3:itemID(arg_57_0.equips[arg_57_0.pos])
	local var_57_1 = var_0_3:element(var_57_0)

	if arg_57_0.selectElement ~= 0 and arg_57_0.selectElement ~= var_57_1 then
		arg_57_0.rightPos = nil

		return
	end

	if arg_57_0.pos == 1 then
		local var_57_2 = var_0_3:itemID(arg_57_0.equips[arg_57_0.pos])
		local var_57_3 = var_0_3:element(var_57_2)

		if arg_57_0.selectElement == 0 or arg_57_0.selectElement == var_57_3 then
			arg_57_0.rightPos = 1
		else
			arg_57_0.rightPos = nil
		end
	else
		local var_57_4 = 0

		for iter_57_0 = 2, arg_57_0.pos do
			if arg_57_0.equips[iter_57_0] ~= 0 then
				local var_57_5 = var_0_3:itemID(arg_57_0.equips[iter_57_0])
				local var_57_6 = var_0_3:element(var_57_5)

				if arg_57_0.selectElement == 0 or arg_57_0.selectElement == var_57_6 then
					var_57_4 = var_57_4 + 1
				end
			end

			arg_57_0.rightPos = var_57_4
		end
	end
end

function var_0_0.returnEquipRightShow(arg_58_0)
	if arg_58_0.rightShowType == var_0_11.equip then
		return
	else
		arg_58_0:updateRightShow(var_0_11.equip)
	end
end

return var_0_0
