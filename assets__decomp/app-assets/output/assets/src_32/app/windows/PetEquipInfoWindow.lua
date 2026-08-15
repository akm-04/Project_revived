local var_0_0 = class("PetEquipInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = require("framework.scheduler")
local var_0_3 = class("ScrollView", cc.ui.UIScrollView)
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.attr
local var_0_7 = xyd.tables.hero
local var_0_8 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0.hero
	local var_4_1 = arg_4_0:nodeByName("list")

	arg_4_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 440, 550),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_1):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0:updateEquipInfoContainer()
	arg_4_0.list:reload()
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" and 5 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateEquipInfoContainer(arg_6_0)
	local var_6_0 = arg_6_0.hero

	arg_6_0.houseTitle = arg_6_0:nodeByName("house_title")
	arg_6_0.equipTitle = arg_6_0:nodeByName("equip_title")

	arg_6_0:nodeByName("house_txt"):setString(var_0_5:translation("PET_MAIN_TXT13"))
	arg_6_0:nodeByName("equip_txt"):setString(var_0_5:translation("PET_MAIN_TXT14"))
	arg_6_0.houseTitle:removeFromParent()
	arg_6_0.equipTitle:removeFromParent()

	local var_6_1 = xyd.tables.hero:getPetHomeID(var_6_0:getTableID())

	dump(var_6_1)

	if var_6_1 and next(var_6_1) and var_6_1[1] ~= 0 then
		local var_6_2 = arg_6_0.list:newItem()
		local var_6_3 = display.newNode()

		var_6_3:setContentSize(440, arg_6_0.houseTitle:getHeight())
		arg_6_0.houseTitle:addTo(var_6_3)
		arg_6_0.houseTitle:setAnchorPoint(0.5, 0)
		arg_6_0.houseTitle:pos(220, 0)
		var_6_2:addContent(var_6_3)
		var_6_2:setItemSize(440, arg_6_0.houseTitle:getHeight())
		arg_6_0.list:addItem(var_6_2)

		for iter_6_0 = 1, #var_6_1 do
			local var_6_4 = arg_6_0.list:newItem()
			local var_6_5 = display.newNode()
			local var_6_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/skin_info.csb")

			var_6_6:size(var_6_6:getChildByName("background"):getContentSize())
			var_6_6:removeChild(var_6_6:getChildByName("background"))
			var_6_6:addTo(var_6_5)
			var_6_6:align(display.BOTTOM_CENTER, 220, 5)
			arg_6_0:updateHomeSkinInfo(var_6_6, var_6_1[iter_6_0])
			var_6_5:size(440, var_6_6:getHeight() + 10)
			var_6_4:addContent(var_6_5)
			var_6_4:setItemSize(440, var_6_6:getHeight() + 10)
			arg_6_0.list:addItem(var_6_4)
		end
	end

	local var_6_7 = arg_6_0.list:newItem()
	local var_6_8 = display.newNode()

	var_6_8:setContentSize(440, arg_6_0.equipTitle:getHeight())
	arg_6_0.equipTitle:addTo(var_6_8)
	arg_6_0.equipTitle:setAnchorPoint(0.5, 0)
	arg_6_0.equipTitle:pos(220, 0)
	var_6_7:addContent(var_6_8)
	var_6_7:setItemSize(440, arg_6_0.equipTitle:getHeight())
	arg_6_0.list:addItem(var_6_7)

	local var_6_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/equip_info.csb")

	var_6_9:setName("node1")

	local var_6_10 = var_6_9:getChildByName("container"):getContentSize()

	var_6_9:setContentSize(var_6_10)

	if var_6_0:getColor() == xyd.tables.misc.maxPetColor - 1 then
		local var_6_11 = arg_6_0.list:newItem()
		local var_6_12 = display.newNode()

		arg_6_0:setEquipNode(var_6_0:getColor() + 1, var_6_9)
		var_6_9:addTo(var_6_12)
		var_6_9:setAnchorPoint(cc.p(0, 0))
		var_6_12:setContentSize(var_6_9:getContentSize())
		var_6_11:addContent(var_6_12)
		var_6_11:setItemSize(var_6_12:getWidth(), var_6_12:getHeight() + 5)
		arg_6_0.list:addItem(var_6_11)
	elseif var_6_0:getColor() < xyd.tables.misc.maxPetColor - 1 then
		local var_6_13 = arg_6_0.list:newItem()
		local var_6_14 = display.newNode()
		local var_6_15 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/equip_info.csb")

		var_6_15:size(var_6_9:getContentSize())
		var_6_15:setName("node2")
		arg_6_0:setEquipNode(var_6_0:getColor() + 1, var_6_9)
		var_6_9:addTo(var_6_14)
		var_6_9:setAnchorPoint(cc.p(0, 0))
		var_6_14:setContentSize(var_6_9:getContentSize())
		var_6_13:addContent(var_6_14)
		var_6_13:setItemSize(var_6_14:getWidth(), var_6_14:getHeight() + 5)
		arg_6_0.list:addItem(var_6_13)

		local var_6_16 = arg_6_0.list:newItem()
		local var_6_17 = display.newNode()

		arg_6_0:setEquipNode(var_6_0:getColor() + 2, var_6_15)
		var_6_15:addTo(var_6_17)
		var_6_15:setAnchorPoint(cc.p(0, 0))
		var_6_17:setContentSize(440, 220)
		var_6_16:addContent(var_6_17)
		var_6_16:setItemSize(var_6_17:getWidth(), var_6_17:getHeight() + 5)
		arg_6_0.list:addItem(var_6_16)
	end

	arg_6_0.list:reload()
end

function var_0_0.setEquipNode(arg_7_0, arg_7_1, arg_7_2)
	if tolua.isnull(arg_7_0) or tolua.isnull(arg_7_2) then
		return
	end

	local var_7_0 = arg_7_0.hero
	local var_7_1 = arg_7_2:getChildByName("container")
	local var_7_2 = xyd.AssetLoader:get():loadSprite("windows/hero/quality_" .. arg_7_1 .. ".png")

	var_7_2:addTo(var_7_1:getChildByName("color"))
	var_7_2:scale(0.75)

	for iter_7_0 = 1, 3 do
		local var_7_3 = var_7_0:getEquipByIndex(iter_7_0, arg_7_1)

		if var_7_3:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_7_3:getTableID()) == 0 then
			local var_7_4 = var_7_1:getChildByName("icon" .. iter_7_0)

			var_7_4:removeAllChildren()

			local var_7_5 = display.newNode()

			var_7_5:size(var_7_4:getContentSize())
			var_7_4:addChild(var_7_5)
			xyd.setItemBorder(var_7_5, var_7_3:getTableID())
			var_7_5:setTouchEnabled(true)
			var_7_5:setTouchSwallowEnabled(false)

			if var_7_3:isInBackpack() or var_7_3:isHasMaterial() then
				local var_7_6 = xyd.AssetLoader:get():loadSprite("windows/hero/icon_green_point.png")

				var_7_6:setPosition(var_7_4:getContentSize().width / 14 * 13, var_7_4:getContentSize().height / 14 * 13)
				var_7_4:addChild(var_7_6)
			end

			var_7_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
				if arg_8_0.name == "ended" and not arg_7_0.scrollViewMoved_ then
					arg_7_0:showItemDetail(iter_7_0, arg_7_1, true)
				end

				return true
			end)
		else
			local var_7_7 = var_7_1:getChildByName("icon" .. iter_7_0)

			if var_7_1:getChildByName("awake_hide") then
				var_7_1:getChildByName("awake_hide"):setVisible(true)
				var_7_1:getChildByName("icon_question"):setVisible(true)
			end
		end
	end

	return var_7_1
end

function var_0_0.showItemDetail(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0
	local var_9_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.equipConfirmWnd, {
		hero = arg_9_0.hero,
		item_index = arg_9_1,
		color = arg_9_2,
		state = arg_9_3
	})
end

function var_0_0.updateHomeSkinInfo(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_1:getChildByName("skin_name")
	local var_10_1 = arg_10_1:getChildByName("icon")
	local var_10_2 = arg_10_1:getChildByName("locked")
	local var_10_3 = arg_10_1:getChildByName("skin_buy")
	local var_10_4 = arg_10_1:getChildByName("txt")
	local var_10_5 = arg_10_1:getChildByName("buy_gray")
	local var_10_6 = xyd.tables.item:name(arg_10_2)

	var_10_0:setString(var_10_6)
	var_10_0:enableOutline(cc.c4b(92, 54, 89, 255), 2)
	var_10_2:setVisible(false)
	var_10_5:setVisible(false)
	var_10_1:removeAllChildren()
	var_10_3:removeAllNodeEventListeners()

	if arg_10_0.selfPlayer:getBackpack():getItemNumByID(arg_10_2) > 0 or arg_10_0.hero:checkHomeStyleIsUsed(arg_10_2) then
		if arg_10_0.hero:isHomeSkinOn() then
			xyd.setItemBorder(var_10_1, arg_10_2)
			var_10_4:setString(var_0_5:translation("CANCEL"))
			xyd.nodeEventSample(var_10_3, nil, function()
				local var_11_0 = {
					pet_id = arg_10_0.hero:getPetID()
				}

				xyd.Backend.get():request(xyd.mid.CANCEL_PET_STYLE, var_11_0, function(arg_12_0, arg_12_1)
					if arg_12_0 == xyd.error.OK then
						arg_10_0.hero:setHomeSkinID(0)
						arg_10_0:updateHomeSkinInfo(arg_10_1, arg_10_2)
						arg_10_0:changePetHomeStyle()
					end
				end)
			end)
		else
			xyd.setItemBorder(var_10_1, arg_10_2, nil, true)
			var_10_2:setVisible(true)

			if arg_10_0.hero:checkHomeStyleIsUsed(arg_10_2) then
				var_10_2:getChildByName("icon"):setVisible(false)
			end

			var_10_4:setString(var_0_5:translation("EVENT_CENTRE_BOARD_USE_LABEL"))
			xyd.nodeEventSample(var_10_3, nil, function()
				local var_13_0 = {}

				if arg_10_0.hero:checkHomeStyleIsUsed(arg_10_2) then
					var_13_0.pet_id = arg_10_0.hero:getPetID()
					var_13_0.style_id = arg_10_2

					xyd.Backend.get():request(xyd.mid.USE_PET_STYLE, var_13_0, function(arg_14_0, arg_14_1)
						if arg_14_0 == xyd.error.OK then
							arg_10_0.hero:setHomeSkinID(arg_14_1.active_style)
							arg_10_0:updateHomeSkinInfo(arg_10_1, arg_10_2)
							arg_10_0:changePetHomeStyle()
						end
					end)
				else
					var_13_0.item_id = arg_10_2

					xyd.Backend.get():request(xyd.mid.GET_PET_STYLE_FORM_ITEM, var_13_0, function(arg_15_0, arg_15_1)
						if arg_15_0 == xyd.error.OK then
							arg_10_0.hero:setHomeSkinID(arg_15_1.active_style)
							arg_10_0.hero:setHomeStyles(arg_15_1.pet_styles)

							local var_15_0 = {
								itemID = arg_10_2
							}

							var_15_0.itemNum = 1

							arg_10_0.selfPlayer:getBackpack():removeItem(var_15_0)
							arg_10_0:updateHomeSkinInfo(arg_10_1, arg_10_2)
							arg_10_0:changePetHomeStyle()
						end
					end)
				end
			end)
		end
	else
		xyd.setItemBorder(var_10_1, arg_10_2)
		var_10_5:setVisible(true)
		var_10_4:setString(var_0_5:translation("MAP_BUY"))
		var_10_2:setVisible(true)
		var_10_3:setVisible(false)
	end
end

function var_0_0.changePetHomeStyle(arg_16_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.PET_UPDATE_HOME_STYLE
	})
end

return var_0_0
