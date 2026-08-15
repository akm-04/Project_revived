local var_0_0 = class("EquipConfirmWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.attr
local var_0_5 = xyd.tables.hero
local var_0_6 = 27

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
			xyd.WindowManager.get():closeWindow(arg_3_0)
		else
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:playGuide()
end

function var_0_0.didClose(arg_5_0)
	return
end

function var_0_0.willClose(arg_6_0)
	return
end

function var_0_0.layout(arg_7_0)
	local var_7_0 = arg_7_0.hero
	local var_7_1 = arg_7_0.item
	local var_7_2 = arg_7_0:nodeByName("icon")

	var_7_2:removeAllChildren()
	arg_7_0:nodeByName("txt_equipment_backpack"):setString(var_0_2:translation("ITEM_EQUIPMENT_BACKPACK"))

	if arg_7_0.inscript_id then
		xyd.setItemBorder(var_7_2, arg_7_0.inscript_id)
		arg_7_0:nodeByName("label_name"):setString(xyd.tables.item:name(arg_7_0.inscript_id))
		arg_7_0:nodeByName("label_desc"):setString(xyd.tables.item:desc2(arg_7_0.inscript_id))
		arg_7_0:nodeByName("label_own1"):setString(var_0_2:translation("ITEM_OWN"))
		arg_7_0:nodeByName("label_own2"):setString(var_0_2:translation("ITEM_OWN_SUFFIX"))

		arg_7_0.levelDesStr = "ITEM_EREQUIRED_LEVEL"
		arg_7_0.levelDesStr = ""

		arg_7_0:nodeByName("label_tips2"):setVisible(false)
		arg_7_0:nodeByName("label_attr"):setString(xyd.tables.translation:translation("PHYSICAL_ATTACK"))
		arg_7_0:nodeByName("label_attr"):setVisible(false)
		arg_7_0:nodeByName("label_attr_value1"):setVisible(false)
		arg_7_0:nodeByName("label_attr_value2"):setVisible(false)
	else
		xyd.setItemBorder(var_7_2, var_7_1:getTableID())
		arg_7_0:nodeByName("label_name"):setString(var_7_1:getName())
		arg_7_0:nodeByName("label_desc"):setString(var_7_1:getDesc())
		arg_7_0:nodeByName("label_own1"):setString(var_0_2:translation("ITEM_OWN"))
		arg_7_0:nodeByName("label_own2"):setString(var_0_2:translation("ITEM_OWN_SUFFIX"))

		arg_7_0.levelDesStr = "ITEM_EREQUIRED_LEVEL"

		if arg_7_0.isPet and arg_7_0.isPet == true then
			arg_7_0.levelDesStr = "ITEM_EREQUIRED_PET_LEVEL"

			arg_7_0:nodeByName("label_tips1"):setString(var_0_2:translation("ITEM_BIND_TIP_PET"))
		else
			arg_7_0:nodeByName("label_tips1"):setString(var_0_2:translation("ITEM_BIND_TIP"))
		end

		arg_7_0:nodeByName("label_tips2"):setString(string.format(var_0_2:translation(arg_7_0.levelDesStr), var_7_1:getLevel()))
		arg_7_0:nodeByName("label_attr"):setString(xyd.tables.translation:translation("PHYSICAL_ATTACK"))
		arg_7_0:nodeByName("label_attr"):setVisible(false)
		arg_7_0:nodeByName("label_attr_value1"):setVisible(false)
		arg_7_0:nodeByName("label_attr_value2"):setVisible(false)
	end

	if arg_7_0.inscript_id then
		arg_7_0:updateInscirption()
	else
		arg_7_0:getBtn()
		arg_7_0:update()
	end

	arg_7_0:nodeByName("compose_formula"):setString(var_0_3:translation("HERO_MAIN_TEXT_27"))
	arg_7_0:nodeByName("text_compose"):setString(var_0_3:translation("HERO_MAIN_TEXT_28"))
	arg_7_0:nodeByName("gain_way"):setString(var_0_3:translation("HERO_MAIN_TEXT_29"))
	arg_7_0:nodeByName("text_equip"):setString(var_0_3:translation("HERO_MAIN_TEXT_30"))
	arg_7_0:nodeByName("text_ok"):setString(var_0_3:translation("HERO_MAIN_TEXT_31"))
	xyd.nodeEventSample(arg_7_0:nodeByName("btn_equipment_backpack"), nil, function()
		xyd.WindowManager.get():openWindow("equipment_backpack")
	end)
end

function var_0_0.updateInscirption(arg_9_0)
	arg_9_0:nodeByName("label_own_value"):setString(arg_9_0.selfPlayer:getBackpack():getItemNumByID(arg_9_0.inscript_id))

	local var_9_0, var_9_1 = arg_9_0:nodeByName("label_own_value"):getPosition()

	arg_9_0:nodeByName("label_own2"):x(var_9_0 + arg_9_0:nodeByName("label_own_value"):getContentSize().width + 5)

	labels_ = {}

	local var_9_2 = {}
	local var_9_3 = tempnum
	local var_9_4 = tempsuffix

	var_9_2.name, tempnum, tempsuffix = arg_9_0.inscription_:getInscriptionAttrLabelText(arg_9_0.inscript_id)
	var_9_2.value = tempnum
	var_9_2.suffix = tempsuffix

	table.insert(labels_, var_9_2)

	if xyd.tables.item:inscriptSuitId(arg_9_0.inscript_id) ~= 0 then
		local var_9_5 = {
			name = xyd.tables.inscriptionSuit:name(xyd.tables.item:inscriptSuitId(arg_9_0.inscript_id))
		}

		var_9_5.value = nil
		var_9_5.color = cc.c4b(160, 28, 28, 255)

		table.insert(labels_, var_9_5)

		local var_9_6 = {
			name = var_0_4:name(xyd.tables.inscriptionSuit:attr(xyd.tables.item:inscriptSuitId(arg_9_0.inscript_id))[1]),
			value = xyd.tables.inscriptionSuit:attr_num(xyd.tables.item:inscriptSuitId(arg_9_0.inscript_id))[1]
		}

		table.insert(labels_, var_9_6)
	end

	if not arg_9_0.list or tolua.isnull(arg_9_0.list) then
		arg_9_0.list = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, 375, 120),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_9_0:nodeByName("list")):onScroll(handler(arg_9_0, arg_9_0.scrollListener))
	end

	arg_9_0:nodeByName("label_desc"):y(arg_9_0:nodeByName("word_back"):getY() - arg_9_0:nodeByName("word_back"):getHeight() - 15)
	arg_9_0:createLabels(labels_)
	arg_9_0:nodeByName("button"):setVisible(false)
	arg_9_0:nodeByName("text_ok"):hide()
	arg_9_0:nodeByName("text_compose"):hide()
	arg_9_0:nodeByName("text_equip"):hide()
	arg_9_0:nodeByName("gain_way"):hide()
	arg_9_0:nodeByName("compose_formula"):hide()
	arg_9_0:nodeByName("label_tips1"):setVisible(false)
	arg_9_0:nodeByName("label_tips2"):setVisible(false)
end

function var_0_0.update(arg_10_0)
	arg_10_0:nodeByName("label_own_value"):setString(arg_10_0.item:getSelfNum())

	local var_10_0, var_10_1 = arg_10_0:nodeByName("label_own_value"):getPosition()

	arg_10_0:nodeByName("label_own2"):x(var_10_0 + arg_10_0:nodeByName("label_own_value"):getContentSize().width + 5)

	local var_10_2 = arg_10_0.item
	local var_10_3 = arg_10_0.hero
	local var_10_4 = var_10_2:getAttr()
	local var_10_5 = var_10_2:getFumoAttr()
	local var_10_6 = {}

	if var_10_4[1] and var_10_4[2] and var_10_4[3] and var_10_4[1] == var_10_4[2] and var_10_4[2] == var_10_4[3] then
		local var_10_7 = {
			name = var_0_4:name(1) .. "," .. var_0_4:name(2) .. "," .. var_0_4:name(3),
			value = var_10_4[1],
			fumo = var_10_5[1]
		}

		table.insert(var_10_6, var_10_7)

		for iter_10_0, iter_10_1 in pairs(var_10_4) do
			if iter_10_0 > 3 then
				local var_10_8 = {
					name = var_0_4:name(iter_10_0),
					value = iter_10_1,
					fumo = var_10_5[iter_10_0]
				}

				table.insert(var_10_6, var_10_8)
			end
		end
	else
		for iter_10_2, iter_10_3 in pairs(var_10_4) do
			local var_10_9 = {
				name = var_0_4:name(iter_10_2),
				value = iter_10_3,
				fumo = var_10_5[iter_10_2]
			}

			table.insert(var_10_6, var_10_9)
		end
	end

	if xyd.tables.item:isAwakenItem(arg_10_0.item:getTableID()) > 0 or xyd.tables.item:isAwakeTwiceItem(arg_10_0.item:getTableID()) > 0 then
		arg_10_0:setPracticeAttr(var_10_3, var_10_6)
	end

	local var_10_10 = arg_10_0:nodeByName("list"):getHeight()

	arg_10_0:nodeByName("word_back"):height(var_10_10 + 20)

	if not arg_10_0.list or tolua.isnull(arg_10_0.list) then
		arg_10_0.list = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, 375, var_10_10),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_10_0:nodeByName("list")):onScroll(handler(arg_10_0, arg_10_0.scrollListener))
	end

	arg_10_0:nodeByName("label_desc"):y(arg_10_0:nodeByName("word_back"):getY() - arg_10_0:nodeByName("word_back"):getHeight() - 15)
	arg_10_0:createLabels(var_10_6)

	local var_10_11 = arg_10_0.item:getCompose()

	arg_10_0:nodeByName("text_ok"):hide()
	arg_10_0:nodeByName("text_compose"):hide()
	arg_10_0:nodeByName("text_equip"):hide()
	arg_10_0:nodeByName("gain_way"):hide()
	arg_10_0:nodeByName("compose_formula"):hide()

	if arg_10_0.isForShow then
		if var_10_2:isCollected() or var_10_2:isInBackpack() then
			arg_10_0:nodeByName("text_ok"):show()

			arg_10_0.state_ = "quit"
		elseif (#var_10_11 < 1 or var_10_11[1] == 0) and not var_10_2:isInBackpack() then
			arg_10_0:nodeByName("gain_way"):show()

			arg_10_0.state_ = "gain_way"
		else
			arg_10_0:nodeByName("compose_formula"):show()

			arg_10_0.state_ = "compose"
		end

		if var_10_3:getLevel() >= var_10_2:getLevel() then
			arg_10_0:nodeByName("label_tips1"):setString(string.format(var_0_2:translation(arg_10_0.levelDesStr), var_10_2:getLevel()))
			arg_10_0:nodeByName("label_tips1"):setVisible(true)
			arg_10_0:nodeByName("label_tips2"):setVisible(false)
		else
			arg_10_0:nodeByName("label_tips2"):setString(string.format(var_0_2:translation(arg_10_0.levelDesStr), var_10_2:getLevel()))
			arg_10_0:nodeByName("label_tips1"):setVisible(false)
			arg_10_0:nodeByName("label_tips2"):setVisible(true)
		end
	else
		if var_10_2:isCollected() then
			arg_10_0:nodeByName("text_ok"):show()

			arg_10_0.state_ = "quit"
		elseif (#var_10_11 < 1 or var_10_11[1] == 0) and not var_10_2:isInBackpack() then
			arg_10_0:nodeByName("gain_way"):show()

			arg_10_0.state_ = "gain_way"
		elseif var_10_2:isInBackpack() then
			arg_10_0:nodeByName("text_equip"):show()

			arg_10_0.state_ = "equip"
		else
			arg_10_0:nodeByName("compose_formula"):show()

			arg_10_0.state_ = "compose"
		end

		if var_10_2:isCollected() then
			arg_10_0:nodeByName("label_tips1"):setString(string.format(var_0_2:translation(arg_10_0.levelDesStr), var_10_2:getLevel()))
			arg_10_0:nodeByName("label_tips1"):setVisible(true)
			arg_10_0:nodeByName("label_tips2"):setVisible(false)
		elseif var_10_3:getLevel() >= var_10_2:getLevel() then
			arg_10_0:nodeByName("label_tips1"):setVisible(true)
			arg_10_0:nodeByName("label_tips2"):setVisible(false)
		elseif var_10_3:getLevel() < var_10_2:getLevel() then
			arg_10_0:nodeByName("label_tips2"):setVisible(true)
			arg_10_0:nodeByName("label_tips1"):setVisible(false)
		end
	end

	local var_10_12 = xyd.WindowManager.get():getWindow("hero_main")

	if var_10_12 then
		var_10_12:updateEquipInfoContainer()
		var_10_12:updateEquip()
		var_10_12:CheckOneClick()
	end
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 5 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

function var_0_0.setPracticeAttr(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = {}

	arg_12_0.practiceTitleIndex = #arg_12_2

	table.insert(arg_12_2, var_12_0)

	local var_12_1 = arg_12_1:getPractice()

	if var_12_1[1] ~= 0 or var_12_1[2] ~= 0 or var_12_1[3] ~= 0 then
		var_12_0.name = var_0_3:translation("WASH_ATTRIBUTE")

		local var_12_2 = {}

		table.insert(var_12_2, var_0_2:translation("LILIANG_ADD"))
		table.insert(var_12_2, var_0_2:translation("ZHILI_ZENGJIA"))
		table.insert(var_12_2, var_0_2:translation("MINJIE_ZENGJIA"))

		if arg_12_0.hero:isAwaken() and (arg_12_0.item.tableID_ == xyd.tables.hero:awakenItemID(arg_12_0.hero.tableID_) or arg_12_0.item.tableID_ == xyd.tables.hero:awakeTwiceItem(arg_12_0.hero.tableID_)) then
			for iter_12_0 = 1, #var_12_1 do
				local var_12_3 = {
					name = var_12_2[iter_12_0],
					value = tonumber(var_12_1[iter_12_0])
				}

				table.insert(arg_12_2, var_12_3)
			end
		end
	else
		var_12_0.name = var_0_3:translation("WASH_AFTER_GET")
	end

	var_12_0.value = 0

	local var_12_4 = var_0_5:getPracticeNeeds(arg_12_1:getTableID())
	local var_12_5 = var_0_5:getPracticeAttrType(arg_12_1:getTableID())
	local var_12_6 = var_0_5:getPracticeAttrValue(arg_12_1:getTableID())

	if #var_12_4 ~= 3 or #var_12_5 ~= 3 or #var_12_6 ~= 3 then
		return
	end

	local var_12_7 = {}

	function hasSameAttr(arg_13_0)
		if not next(var_12_7) then
			return nil
		end

		for iter_13_0, iter_13_1 in pairs(var_12_7) do
			if iter_13_1.name == arg_13_0 then
				return iter_13_0
			end
		end

		return nil
	end

	for iter_12_1 = 1, #var_12_4 do
		if var_12_1[iter_12_1] >= var_12_4[iter_12_1] then
			local var_12_8 = hasSameAttr(xyd.tables.attr:name(var_12_5[iter_12_1]))

			if var_12_8 then
				var_12_7[var_12_8].value = var_12_7[var_12_8].value + var_12_6[iter_12_1]
			else
				local var_12_9 = {
					name = xyd.tables.attr:name(var_12_5[iter_12_1]),
					value = var_12_6[iter_12_1]
				}

				table.insert(var_12_7, var_12_9)
			end
		end
	end

	for iter_12_2, iter_12_3 in pairs(var_12_7) do
		table.insert(arg_12_2, iter_12_3)
	end
end

function var_0_0.createLabels(arg_14_0, arg_14_1)
	local var_14_0, var_14_1 = arg_14_0:nodeByName("label_attr"):getPosition()

	arg_14_0.list:removeAllItems()

	local var_14_2 = 0

	for iter_14_0, iter_14_1 in ipairs(arg_14_1) do
		local var_14_3 = arg_14_0.list:newItem()
		local var_14_4 = display.newNode()
		local var_14_5 = arg_14_0:nodeByName("label_attr"):clone()

		if iter_14_1.name == var_0_4:name(xyd.AttributeType.HALF_MP) then
			var_14_2 = var_14_2 + 1
			iter_14_1.name = string.sub(iter_14_1.name, 1, 21) .. "\n" .. string.sub(iter_14_1.name, 22, #iter_14_1.name)
		end

		var_14_5:setString(iter_14_1.name)
		var_14_5:setVisible(true)
		var_14_5:y(var_14_1 - (iter_14_0 - 1 + var_14_2) * var_0_6)
		var_14_5:addTo(var_14_4)

		local var_14_6 = arg_14_0:nodeByName("label_attr_value1"):clone()
		local var_14_7 = ""

		if iter_14_1.value then
			var_14_7 = iter_14_1.value < 0 and "" or "+"
		end

		if iter_14_1.value then
			var_14_6:setString(var_14_7 .. iter_14_1.value .. (iter_14_1.suffix or ""))
		else
			var_14_6:setString("")
		end

		if iter_14_1.color then
			var_14_6:setColor(iter_14_1.color)
			var_14_5:setColor(iter_14_1.color)
		end

		var_14_6:setVisible(true)
		var_14_6:y(var_14_1 - (iter_14_0 - 1 + var_14_2) * var_0_6):x(var_14_0 + var_14_5:getContentSize().width)
		var_14_6:addTo(var_14_4)

		if iter_14_1.fumo and iter_14_1.fumo > 0 then
			local var_14_8, var_14_9 = var_14_6:getPosition()
			local var_14_10 = arg_14_0:nodeByName("label_attr_value2"):clone()
			local var_14_11 = iter_14_1.fumo < 0 and "" or "+"

			var_14_10:setString(var_14_11 .. iter_14_1.fumo)
			var_14_10:setVisible(true)
			var_14_10:y(var_14_1 - (iter_14_0 - 1 + var_14_2) * var_0_6):x(var_14_8 + var_14_6:getWidth())
			var_14_10:addTo(var_14_4)
		end

		if arg_14_0.practiceTitleIndex ~= nil and iter_14_0 == arg_14_0.practiceTitleIndex + 1 then
			var_14_5:setColor(cc.c3b(9, 50, 223))
			var_14_5:y(var_14_1 - (iter_14_0 - 1 + var_14_2) * var_0_6 - 20)
			var_14_6:setVisible(false)
		end

		if arg_14_0.practiceTitleIndex ~= nil and iter_14_0 > arg_14_0.practiceTitleIndex + 1 then
			var_14_6:setColor(cc.c3b(0, 151, 0))
			var_14_5:setColor(cc.c3b(0, 151, 0))
			var_14_5:y(var_14_1 - (iter_14_0 - 1 + var_14_2) * var_0_6 - 20)
			var_14_6:y(var_14_1 - (iter_14_0 - 1 + var_14_2) * var_0_6 - 20):x(var_14_0 + var_14_5:getContentSize().width)
		end

		var_14_4:setPosition(-40, -328)
		var_14_4:setTouchEnabled(false)
		var_14_4:setTouchSwallowEnabled(true)
		var_14_3:addChild(var_14_4)
		var_14_3:setItemSize(375, 30)
		arg_14_0.list:addItem(var_14_3)
	end
end

function var_0_0.getBtn(arg_15_0)
	if not arg_15_0.btn_ then
		arg_15_0.btn_ = arg_15_0:nodeByName("button")

		arg_15_0.btn_:addTouchEventListener(function(arg_16_0, arg_16_1)
			xyd.buttonScaleAnim(arg_15_0.btn_, arg_16_1)

			if arg_16_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end

				if arg_15_0.guideID == xyd.GuideStoryType.GUIDE_EQUIP_THREE then
					arg_15_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_HERO_ITEM_EQUIP)
				end

				if not arg_15_0.state_ or arg_15_0.state_ == "quit" then
					if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_FOUR then
						xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_FIVE)
						arg_15_0:playGuide()
						xyd.WindowManager.get():getWindow("hero_main"):playGuide()
					end

					if xyd.WindowManager.get():getWindow("item_compose") then
						xyd.WindowManager.get():closeWindow("item_compose")
						xyd.WindowManager.get():closeWindow(arg_15_0)
					else
						xyd.WindowManager.get():closeWindow(arg_15_0)
					end
				elseif arg_15_0.state_ == "equip" then
					if arg_15_0.hero and arg_15_0.hero:getLevel() >= arg_15_0.item:getLevel() then
						arg_15_0:equipItems()

						if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_FOUR then
							xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_FIVE)
							arg_15_0:playGuide()
							xyd.WindowManager.get():getWindow("hero_main"):playGuide()
						end
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = string.format(var_0_2:translation(arg_15_0.levelDesStr), arg_15_0.item:getLevel())
						})
					end
				elseif arg_15_0.state_ == "compose" then
					local var_16_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
						item = arg_15_0.item
					})

					cc.EventProxy.new(var_16_0, var_16_0):addEventListener(xyd.event.ITEM_CHANGED, function(arg_17_0)
						arg_15_0:update()
					end)
				elseif arg_15_0.state_ == "gain_way" then
					local var_16_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
						isCompose = false,
						item = arg_15_0.item
					})
				end
			end
		end)
	end

	return arg_15_0.btn_
end

function var_0_0.equipItems(arg_18_0)
	local var_18_0 = arg_18_0.id
	local var_18_1 = arg_18_0.hero

	var_18_1:equipItems(var_18_0, function(arg_19_0, arg_19_1)
		if arg_19_0 == xyd.error.OK or tonumber(arg_19_1.error_code or 0) == 30001 then
			if not arg_18_0 or tolua.isnull(arg_18_0) then
				return
			end

			if arg_19_1.fumo_levels then
				local var_19_0 = 6
				local var_19_1 = arg_19_1.fumo_levels

				if var_19_1 and next(var_19_1) then
					var_18_1.fumoLev_ = {}

					for iter_19_0 = 1, var_19_0 do
						table.insert(var_18_1.fumoLev_, tonumber(var_19_1[iter_19_0]))
					end
				end
			end

			if arg_19_1.fumos then
				local var_19_2 = 6
				local var_19_3 = arg_19_1.fumos

				var_18_1.fumo_ = {}

				for iter_19_1 = 1, var_19_2 do
					table.insert(var_18_1.fumo_, tonumber(var_19_3[iter_19_1]))
				end
			end

			if arg_19_1.restore_items and #arg_19_1.restore_items > 0 then
				for iter_19_2 = 1, #arg_19_1.restore_items do
					local var_19_4 = {
						itemID = arg_19_1.restore_items[iter_19_2].table_id,
						itemNum = arg_19_1.restore_items[iter_19_2].item_num
					}

					arg_18_0.selfPlayer:getBackpack():addItem(var_19_4)
				end

				xyd.WindowManager.get():openWindow("alert_award", {
					awards = arg_19_1.restore_items,
					name = var_0_3:translation("FUMO_RESTORE_NAME")
				})
			end

			var_18_1.totalEquipList_ = nil
			var_18_1.awakeTwiceItem = nil

			arg_18_0:dispatchEvent({
				name = xyd.event.HERO_EQUIP_CHANGED,
				item_index = arg_18_0.id
			})
		end
	end)
end

function var_0_0.playGuide(arg_20_0)
	arg_20_0.guideID = xyd.StoryData.get():getGuideID()

	if arg_20_0.guideID == xyd.GuideStoryType.GUIDE_EQUIP_THREE then
		local var_20_0 = arg_20_0:nodeByName("button")
		local var_20_1 = var_20_0:getPositionX()
		local var_20_2 = var_20_0:getPositionY()

		xyd.WindowManager.get():openWindow("guide")

		local var_20_3 = xyd.WindowManager.get():getWindow("guide")
		local var_20_4 = var_20_3:convertToNodeSpace(var_20_0:getParent():convertToWorldSpace(cc.p(var_20_1, var_20_2)))

		var_20_3:addNode()
		var_20_3:setStencil(var_20_0:getContentSize().width, var_20_0:getContentSize().height, var_20_4.x, var_20_4.y, 3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_FOUR)
	end
end

return var_0_0
