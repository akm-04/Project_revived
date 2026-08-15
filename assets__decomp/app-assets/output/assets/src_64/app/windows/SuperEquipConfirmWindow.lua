local var_0_0 = class("SuperEquipConfirmWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.attr
local var_0_6 = xyd.tables.hero
local var_0_7 = 27

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.id = arg_1_2.item_index
	arg_1_0.hero = arg_1_2.hero

	if arg_1_0.hero then
		arg_1_0.item = arg_1_0.hero:getEquipByIndexShow(arg_1_0.id, arg_1_2.color)
	end

	arg_1_0.isForShow = arg_1_2.state
	arg_1_0.isPet = arg_1_2.is_pet
	arg_1_0.inscript_id = arg_1_2.inscript_id
	arg_1_0.guideID = xyd.StoryData.get():getGuideID()
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.inscription_ = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
	arg_1_0.totalEnhanced = 0
	arg_1_0.isPlayingEffect = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(nil, false, false, function()
		if xyd.WindowManager.get():getWindow("item_compose") then
			xyd.WindowManager.get():closeWindow("item_compose")
		end

		if xyd.WindowManager.get():getWindow("super_equip_enhance") then
			xyd.WindowManager.get():closeWindow("super_equip_enhance")
		end

		xyd.WindowManager.get():closeWindow(arg_3_0)
	end)
end

function var_0_0.didClose(arg_5_0)
	return
end

function var_0_0.willClose(arg_6_0)
	if arg_6_0.totalEnhanced > 0 then
		local var_6_0 = xyd.WindowManager.get():getWindow("hero_main")

		if var_6_0 then
			var_6_0:playEnhance(arg_6_0.item, arg_6_0.totalEnhanced)
		end
	end
end

function var_0_0.layout(arg_7_0)
	local var_7_0 = arg_7_0.hero
	local var_7_1 = arg_7_0.item

	xyd.setItemBorder(arg_7_0:nodeByName("enhance_item"), arg_7_0.item:getTableID())
	arg_7_0:nodeByName("label_name"):setString(var_7_1:getName())
	arg_7_0:nodeByName("label_own1"):setString(var_0_3:translation("ITEM_OWN"))
	arg_7_0:nodeByName("label_own2"):setString(var_0_3:translation("ITEM_OWN_SUFFIX"))

	arg_7_0.levelDesStr = "ITEM_EREQUIRED_LEVEL"

	arg_7_0:nodeByName("text_enhance_need"):setString(var_0_3:translation("TAITAN_EQUIPMENT_EVOLUTION_NEED"))
	arg_7_0:nodeByName("word_compose"):setString(var_0_3:translation("HERO_MAIN_TEXT_33"))
	arg_7_0:nodeByName("word_enhance"):setString(var_0_3:translation("HERO_MAIN_TEXT_54"))
	arg_7_0:nodeByName("compose_formula"):setString(var_0_3:translation("HERO_MAIN_TEXT_27"))
	arg_7_0:nodeByName("gain_way"):setString(var_0_3:translation("HERO_MAIN_TEXT_29"))
	arg_7_0:nodeByName("text_ok"):setString(var_0_3:translation("HERO_MAIN_TEXT_31"))
	arg_7_0:nodeByName("text_equip"):setString(var_0_3:translation("HERO_MAIN_TEXT_30"))
	arg_7_0:nodeByName("text_compose"):setString(var_0_3:translation("HERO_MAIN_TEXT_28"))
	arg_7_0:nodeByName("label_attr"):setString(xyd.tables.translation:translation("PHYSICAL_ATTACK"))
	arg_7_0:nodeByName("label_attr"):setVisible(false)
	arg_7_0:nodeByName("label_attr_value1"):setVisible(false)
	arg_7_0:nodeByName("label_attr_value2"):setVisible(false)
	arg_7_0:getBtn()
	arg_7_0:update()
end

function var_0_0.update(arg_8_0)
	local var_8_0 = arg_8_0:nodeByName("icon")

	var_8_0:removeAllChildren()
	xyd.setItemBorder(var_8_0, arg_8_0.item:getTableID(), nil, nil, nil, nil, nil, arg_8_0.hero:getEquipLevel(arg_8_0.id))

	local var_8_1 = "skeletons/ui_effect/super_partner/equip_lvup.json"
	local var_8_2 = "skeletons/ui_effect/super_partner/equip_lvup.atlas"

	arg_8_0.effect = var_0_2.new(var_8_1, var_8_2, 1)

	arg_8_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_8_0.effect:addTo(var_8_0)
	arg_8_0.effect:setPosition(var_8_0:getContentSize().width / 2, var_8_0:getContentSize().height / 2)

	local var_8_3 = xyd.tables.superEquipEnhance:needNum(math.ceil((arg_8_0.hero:getEquipLevel(arg_8_0.id) + 1) / 10))
	local var_8_4 = arg_8_0.item:getSelfNum()

	arg_8_0:nodeByName("enhance_need_num"):setString(var_8_3 .. "/" .. var_8_4)

	if var_8_3 <= var_8_4 then
		arg_8_0:nodeByName("enhance_need_num"):setColor(cc.c4b(253, 146, 11, 255))
	else
		arg_8_0:nodeByName("enhance_need_num"):setColor(cc.c4b(177, 8, 8, 255))
	end

	arg_8_0:nodeByName("label_own_value"):setString(arg_8_0.item:getSelfNum())

	local var_8_5, var_8_6 = arg_8_0:nodeByName("label_own_value"):getPosition()

	arg_8_0:nodeByName("label_own2"):x(var_8_5 + arg_8_0:nodeByName("label_own_value"):getContentSize().width + 5)

	local var_8_7 = arg_8_0.item
	local var_8_8 = arg_8_0.hero
	local var_8_9 = var_8_7:getAttr()
	local var_8_10 = var_8_7:getEnhanceEquipAttr()
	local var_8_11 = {}

	if var_8_9[1] and var_8_9[2] and var_8_9[3] and var_8_9[1] == var_8_9[2] and var_8_9[2] == var_8_9[3] then
		local var_8_12 = {
			name = var_0_5:name(1) .. "," .. var_0_5:name(2) .. "," .. var_0_5:name(3),
			value = var_8_9[1],
			fumo = var_8_10[1]
		}

		table.insert(var_8_11, var_8_12)

		for iter_8_0, iter_8_1 in pairs(var_8_9) do
			if iter_8_0 > 3 then
				local var_8_13 = {
					name = var_0_5:name(iter_8_0),
					value = iter_8_1,
					fumo = var_8_10[iter_8_0]
				}

				table.insert(var_8_11, var_8_13)
			end
		end
	else
		for iter_8_2, iter_8_3 in pairs(var_8_9) do
			local var_8_14 = {
				name = var_0_5:name(iter_8_2),
				value = iter_8_3,
				fumo = var_8_10[iter_8_2]
			}

			table.insert(var_8_11, var_8_14)
		end
	end

	if xyd.tables.item:isAwakenItem(arg_8_0.item:getTableID()) > 0 or xyd.tables.item:isAwakeTwiceItem(arg_8_0.item:getTableID()) > 0 then
		arg_8_0:setPracticeAttr(var_8_8, var_8_11)
	end

	local var_8_15 = arg_8_0:nodeByName("list"):getHeight()

	if not arg_8_0.list or tolua.isnull(arg_8_0.list) then
		arg_8_0.list = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, 375, 120),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_8_0:nodeByName("list")):onScroll(handler(arg_8_0, arg_8_0.scrollListener))
	end

	arg_8_0:createLabels(var_8_11)

	if not arg_8_0.listName or tolua.isnull(arg_8_0.listName) then
		local var_8_16 = arg_8_0:nodeByName("label_desc"):getContentSize()

		arg_8_0.listName = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, var_8_16.width, var_8_16.height),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL
		}):addTo(arg_8_0:nodeByName("label_desc")):onScroll(handler(arg_8_0, arg_8_0.scrollListener2))
	end

	arg_8_0:updateDesc()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_8_0):addEventListener(xyd.event.EQUIP_ENHANCE_CHANGE, function(arg_9_0)
		local var_9_0 = arg_9_0.params.item
		local var_9_1 = arg_8_0.hero
		local var_9_2 = var_9_0:getAttr()
		local var_9_3 = var_9_0:getEnhanceEquipAttr()
		local var_9_4 = {}

		if var_9_2[1] and var_9_2[2] and var_9_2[3] and var_9_2[1] == var_9_2[2] and var_9_2[2] == var_9_2[3] then
			local var_9_5 = {
				name = var_0_5:name(1) .. "," .. var_0_5:name(2) .. "," .. var_0_5:name(3),
				value = var_9_2[1],
				fumo = var_9_3[1]
			}

			table.insert(var_9_4, var_9_5)

			for iter_9_0, iter_9_1 in pairs(var_9_2) do
				if iter_9_0 > 3 then
					local var_9_6 = {
						name = var_0_5:name(iter_9_0),
						value = iter_9_1,
						fumo = var_9_3[iter_9_0]
					}

					table.insert(var_9_4, var_9_6)
				end
			end
		else
			for iter_9_2, iter_9_3 in pairs(var_9_2) do
				local var_9_7 = {
					name = var_0_5:name(iter_9_2),
					value = iter_9_3,
					fumo = var_9_3[iter_9_2]
				}

				table.insert(var_9_4, var_9_7)
			end
		end

		if xyd.tables.item:isAwakenItem(arg_8_0.item:getTableID()) > 0 or xyd.tables.item:isAwakeTwiceItem(arg_8_0.item:getTableID()) > 0 then
			arg_8_0:setPracticeAttr(var_9_1, var_9_4)
		end

		local var_9_8 = arg_8_0:nodeByName("list"):getHeight()

		if not arg_8_0.list or tolua.isnull(arg_8_0.list) then
			arg_8_0.list = cc.ui.UIListView.new({
				async = false,
				viewRect = cc.rect(0, 0, 375, 120),
				direction = cc.ui.UIListView.DIRECTION_VERTICAL,
				alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
			}):addTo(arg_8_0:nodeByName("list")):onScroll(handler(arg_8_0, arg_8_0.scrollListener))
		end

		if var_9_0:getEquipLevel() == arg_8_0.item:getEquipLevel() then
			arg_8_0:createLabels(var_9_4)
		else
			arg_8_0:createLabels(var_9_4, true)
		end
	end)

	if var_8_7:isCollected() then
		arg_8_0:nodeByName("button"):hide()
		arg_8_0:nodeByName("text_ok"):hide()
		arg_8_0:nodeByName("text_compose"):hide()
		arg_8_0:nodeByName("text_equip"):hide()
		arg_8_0:nodeByName("gain_way"):hide()
		arg_8_0:nodeByName("compose_formula"):hide()
		arg_8_0:nodeByName("btn_compose"):show()
		arg_8_0:nodeByName("btn_enhance"):show()
		arg_8_0:nodeByName("bg_line"):show()
		arg_8_0:nodeByName("enhance_item"):show()
		arg_8_0:nodeByName("text_enhance_need"):show()
		arg_8_0:nodeByName("enhance_need_num"):show()
	else
		local var_8_17 = arg_8_0.item:getCompose()

		arg_8_0:nodeByName("text_ok"):hide()
		arg_8_0:nodeByName("text_compose"):hide()
		arg_8_0:nodeByName("text_equip"):hide()
		arg_8_0:nodeByName("gain_way"):hide()
		arg_8_0:nodeByName("compose_formula"):hide()
		arg_8_0:nodeByName("btn_compose"):hide()
		arg_8_0:nodeByName("btn_enhance"):hide()
		arg_8_0:nodeByName("bg_line"):hide()
		arg_8_0:nodeByName("enhance_item"):hide()
		arg_8_0:nodeByName("text_enhance_need"):hide()
		arg_8_0:nodeByName("enhance_need_num"):hide()

		if var_8_7:isCollected() then
			arg_8_0:nodeByName("text_ok"):show()

			arg_8_0.state_ = "quit"
		elseif (#var_8_17 < 1 or var_8_17[1] == 0) and not var_8_7:isInBackpack() then
			arg_8_0:nodeByName("gain_way"):show()

			arg_8_0.state_ = "gain_way"
		elseif var_8_7:isInBackpack() then
			arg_8_0:nodeByName("text_equip"):show()

			arg_8_0.state_ = "equip"
		else
			arg_8_0:nodeByName("compose_formula"):show()

			arg_8_0.state_ = "compose"
		end
	end

	local var_8_18 = xyd.WindowManager.get():getWindow("hero_main")

	if var_8_18 then
		var_8_18:updateEquipInfoContainer()
		var_8_18:updateEquip()
		var_8_18:CheckOneClick()
		var_8_18:updateSuperHero()
	end
end

function var_0_0.updateDesc(arg_10_0)
	arg_10_0.listName:removeAllItems()

	local var_10_0 = display.newNode()
	local var_10_1 = arg_10_0.listName:newItem()
	local var_10_2 = display.newNode()
	local var_10_3 = {
		size = 24,
		color = cc.c3b(51, 48, 43),
		dimensions = cc.size(380, 0),
		text = arg_10_0.item:getDesc()
	}
	local var_10_4 = xyd.AssetLoader.get():loadLabel(var_10_3)

	var_10_4:addTo(var_10_2)
	var_10_4:setAnchorPoint(cc.p(0, 0))
	var_10_4:setPosition(cc.p(6, 0))

	local var_10_5 = var_10_4:getContentSize().height

	var_10_2:setContentSize(380, var_10_5)
	var_10_2:addTo(var_10_0)
	var_10_0:setContentSize(380, var_10_5)
	var_10_1:addContent(var_10_0)
	var_10_1:setItemSize(380, var_10_5)
	arg_10_0.listName:addItem(var_10_1)
	arg_10_0.listName:reload()
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 5 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

function var_0_0.scrollListener2(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 5 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.setPracticeAttr(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {}

	arg_13_0.practiceTitleIndex = #arg_13_2

	table.insert(arg_13_2, var_13_0)

	local var_13_1 = arg_13_1:getPractice()

	if var_13_1[1] ~= 0 or var_13_1[2] ~= 0 or var_13_1[3] ~= 0 then
		var_13_0.name = var_0_4:translation("WASH_ATTRIBUTE")

		local var_13_2 = {}

		table.insert(var_13_2, var_0_3:translation("LILIANG_ADD"))
		table.insert(var_13_2, var_0_3:translation("ZHILI_ZENGJIA"))
		table.insert(var_13_2, var_0_3:translation("MINJIE_ZENGJIA"))

		if arg_13_0.hero:isAwaken() and (arg_13_0.item.tableID_ == xyd.tables.hero:awakenItemID(arg_13_0.hero.tableID_) or arg_13_0.item.tableID_ == xyd.tables.hero:awakeTwiceItem(arg_13_0.hero.tableID_)) then
			for iter_13_0 = 1, #var_13_1 do
				local var_13_3 = {
					name = var_13_2[iter_13_0],
					value = tonumber(var_13_1[iter_13_0])
				}

				table.insert(arg_13_2, var_13_3)
			end
		end
	else
		var_13_0.name = var_0_4:translation("WASH_AFTER_GET")
	end

	var_13_0.value = 0

	local var_13_4 = var_0_6:getPracticeNeeds(arg_13_1:getTableID())
	local var_13_5 = var_0_6:getPracticeAttrType(arg_13_1:getTableID())
	local var_13_6 = var_0_6:getPracticeAttrValue(arg_13_1:getTableID())

	if #var_13_4 ~= 3 or #var_13_5 ~= 3 or #var_13_6 ~= 3 then
		return
	end

	local var_13_7 = {}

	function hasSameAttr(arg_14_0)
		if not next(var_13_7) then
			return nil
		end

		for iter_14_0, iter_14_1 in pairs(var_13_7) do
			if iter_14_1.name == arg_14_0 then
				return iter_14_0
			end
		end

		return nil
	end

	for iter_13_1 = 1, #var_13_4 do
		if var_13_1[iter_13_1] >= var_13_4[iter_13_1] then
			local var_13_8 = hasSameAttr(xyd.tables.attr:name(var_13_5[iter_13_1]))

			if var_13_8 then
				var_13_7[var_13_8].value = var_13_7[var_13_8].value + var_13_6[iter_13_1]
			else
				local var_13_9 = {
					name = xyd.tables.attr:name(var_13_5[iter_13_1]),
					value = var_13_6[iter_13_1]
				}

				table.insert(var_13_7, var_13_9)
			end
		end
	end

	for iter_13_2, iter_13_3 in pairs(var_13_7) do
		table.insert(arg_13_2, iter_13_3)
	end
end

function var_0_0.createLabels(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0, var_15_1 = arg_15_0:nodeByName("label_attr"):getPosition()

	arg_15_0.list:removeAllItems()

	local var_15_2 = 0

	for iter_15_0, iter_15_1 in ipairs(arg_15_1) do
		local var_15_3 = arg_15_0.list:newItem()
		local var_15_4 = display.newNode()
		local var_15_5 = arg_15_0:nodeByName("label_attr"):clone()

		if iter_15_1.name == var_0_5:name(xyd.AttributeType.HALF_MP) then
			var_15_2 = var_15_2 + 1
			iter_15_1.name = string.sub(iter_15_1.name, 1, 21) .. "\n" .. string.sub(iter_15_1.name, 22, #iter_15_1.name)
		end

		var_15_5:setString(iter_15_1.name)
		var_15_5:setVisible(true)
		var_15_5:y(var_15_1 - (iter_15_0 - 1 + var_15_2) * var_0_7)
		var_15_5:addTo(var_15_4)

		local var_15_6 = arg_15_0:nodeByName("label_attr_value1"):clone()
		local var_15_7 = ""

		if iter_15_1.value then
			var_15_7 = iter_15_1.value < 0 and "" or "+"
		end

		if iter_15_1.value then
			var_15_6:setString(var_15_7 .. iter_15_1.value .. (iter_15_1.suffix or ""))
		else
			var_15_6:setString("")
		end

		if iter_15_1.color then
			var_15_6:setColor(iter_15_1.color)
			var_15_5:setColor(iter_15_1.color)
		end

		var_15_6:setVisible(true)
		var_15_6:y(var_15_1 - (iter_15_0 - 1 + var_15_2) * var_0_7):x(var_15_0 + var_15_5:getContentSize().width)
		var_15_6:addTo(var_15_4)

		if iter_15_1.fumo and iter_15_1.fumo > 0 then
			local var_15_8, var_15_9 = var_15_6:getPosition()
			local var_15_10 = arg_15_0:nodeByName("label_attr_value2"):clone()
			local var_15_11 = iter_15_1.fumo < 0 and "" or "+"

			var_15_10:setString(var_15_11 .. iter_15_1.fumo)

			if arg_15_2 then
				var_15_10:setColor(cc.c3b(177, 8, 8))
			end

			var_15_10:setVisible(true)
			var_15_10:y(var_15_1 - (iter_15_0 - 1 + var_15_2) * var_0_7):x(var_15_8 + var_15_6:getWidth())
			var_15_10:addTo(var_15_4)
		end

		if arg_15_0.practiceTitleIndex ~= nil and iter_15_0 == arg_15_0.practiceTitleIndex + 1 then
			var_15_5:setColor(cc.c3b(9, 50, 223))
			var_15_5:y(var_15_1 - (iter_15_0 - 1 + var_15_2) * var_0_7 - 20)
			var_15_6:setVisible(false)
		end

		if arg_15_0.practiceTitleIndex ~= nil and iter_15_0 > arg_15_0.practiceTitleIndex + 1 then
			var_15_6:setColor(cc.c3b(0, 151, 0))
			var_15_5:setColor(cc.c3b(0, 151, 0))
			var_15_5:y(var_15_1 - (iter_15_0 - 1 + var_15_2) * var_0_7 - 20)
			var_15_6:y(var_15_1 - (iter_15_0 - 1 + var_15_2) * var_0_7 - 20):x(var_15_0 + var_15_5:getContentSize().width)
		end

		var_15_4:setPosition(-40, -335)
		var_15_4:setTouchEnabled(false)
		var_15_4:setTouchSwallowEnabled(true)
		var_15_3:addChild(var_15_4)
		var_15_3:setItemSize(375, 30)
		arg_15_0.list:addItem(var_15_3)
	end
end

function var_0_0.getBtn(arg_16_0)
	if not arg_16_0.btn_ then
		arg_16_0.btn_ = arg_16_0:nodeByName("button")

		arg_16_0.btn_:addTouchEventListener(function(arg_17_0, arg_17_1)
			xyd.buttonScaleAnim(arg_16_0.btn_, arg_17_1)

			if arg_17_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end

				if arg_16_0.guideID == xyd.GuideStoryType.GUIDE_EQUIP_THREE then
					arg_16_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_HERO_ITEM_EQUIP)
				end

				if not arg_16_0.state_ or arg_16_0.state_ == "quit" then
					if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_FOUR then
						xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_FIVE)
						arg_16_0:playGuide()
						xyd.WindowManager.get():getWindow("hero_main"):playGuide()
					end

					if xyd.WindowManager.get():getWindow("item_compose") then
						xyd.WindowManager.get():closeWindow("item_compose")
						xyd.WindowManager.get():closeWindow(arg_16_0)
					else
						xyd.WindowManager.get():closeWindow(arg_16_0)
					end
				elseif arg_16_0.state_ == "equip" then
					if arg_16_0.hero and arg_16_0.hero:getLevel() >= arg_16_0.item:getLevel() then
						arg_16_0:equipItems()

						if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_FOUR then
							xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_FIVE)
							arg_16_0:playGuide()
							xyd.WindowManager.get():getWindow("hero_main"):playGuide()
						end
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = string.format(var_0_3:translation(arg_16_0.levelDesStr), arg_16_0.item:getLevel())
						})
					end
				elseif arg_16_0.state_ == "compose" then
					local var_17_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
						item = arg_16_0.item
					})

					cc.EventProxy.new(var_17_0, var_17_0):addEventListener(xyd.event.ITEM_CHANGED, function(arg_18_0)
						arg_16_0:update()
					end)
				end
			elseif arg_16_0.state_ == "gain_way" then
				local var_17_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
					isCompose = false,
					item = arg_16_0.item
				})
			end
		end)
	end

	arg_16_0:nodeByName("btn_compose"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_16_0:nodeByName("btn_compose"), arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			if arg_16_0.isPlayingEffect then
				return
			end

			local var_19_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
				item = arg_16_0.item
			})

			cc.EventProxy.new(var_19_0, var_19_0):addEventListener(xyd.event.ITEM_CHANGED, function(arg_20_0)
				arg_16_0:update()
			end)
		end
	end)
	arg_16_0:nodeByName("btn_enhance"):addTouchEventListener(function(arg_21_0, arg_21_1)
		xyd.buttonScaleAnim(arg_16_0:nodeByName("btn_enhance"), arg_21_1)

		if arg_21_1 == ccui.TouchEventType.ended then
			local var_21_0 = xyd.WindowManager.get():openWindow("super_equip_enhance", {
				item = arg_16_0.item,
				hero = arg_16_0.hero,
				index = arg_16_0.id
			})

			cc.EventProxy.new(var_21_0, var_21_0):addEventListener(xyd.event.EQUIP_ENHANCED, function(arg_22_0)
				arg_16_0:update()
			end)
		end
	end)

	return arg_16_0.btn_
end

function var_0_0.equipItems(arg_23_0)
	local var_23_0 = arg_23_0.id
	local var_23_1 = arg_23_0.hero

	var_23_1:equipItems(var_23_0, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK or tonumber(arg_24_1.error_code or 0) == 30001 then
			if not arg_23_0 or tolua.isnull(arg_23_0) then
				return
			end

			if arg_24_1.fumo_levels then
				local var_24_0 = 6
				local var_24_1 = arg_24_1.fumo_levels

				if var_24_1 and next(var_24_1) then
					var_23_1.fumoLev_ = {}

					for iter_24_0 = 1, var_24_0 do
						table.insert(var_23_1.fumoLev_, tonumber(var_24_1[iter_24_0]))
					end
				end
			end

			if arg_24_1.fumos then
				local var_24_2 = 6
				local var_24_3 = arg_24_1.fumos

				var_23_1.fumo_ = {}

				for iter_24_1 = 1, var_24_2 do
					table.insert(var_23_1.fumo_, tonumber(var_24_3[iter_24_1]))
				end
			end

			if arg_24_1.restore_items and #arg_24_1.restore_items > 0 then
				for iter_24_2 = 1, #arg_24_1.restore_items do
					local var_24_4 = {
						itemID = arg_24_1.restore_items[iter_24_2].table_id,
						itemNum = arg_24_1.restore_items[iter_24_2].item_num
					}

					arg_23_0.selfPlayer:getBackpack():addItem(var_24_4)
				end

				xyd.WindowManager.get():openWindow("alert_award", {
					awards = arg_24_1.restore_items,
					name = var_0_4:translation("FUMO_RESTORE_NAME")
				})
			end

			var_23_1.totalEquipList_ = nil
			var_23_1.awakeTwiceItem = nil

			arg_23_0:dispatchEvent({
				name = xyd.event.HERO_EQUIP_CHANGED,
				item_index = arg_23_0.id
			})
		end
	end)
end

return var_0_0
