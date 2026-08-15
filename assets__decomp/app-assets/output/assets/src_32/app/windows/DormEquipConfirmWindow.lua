local var_0_0 = class("DormEquipConfirmWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.attr
local var_0_5 = xyd.tables.hero
local var_0_6 = 27

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.id = arg_1_2.index
	arg_1_0.houseId = arg_1_2.house_id
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.callback = arg_1_2.callback

	if arg_1_0.hero then
		arg_1_0.item = arg_1_0.hero:getDormEquipItemByIndex(arg_1_0.id)

		if xyd.isInTable(arg_1_0.hero:getHouseEquips(), arg_1_0.item:getTableID()) then
			arg_1_0.item.collected_ = true
		end
	end

	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
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
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0.hero
	local var_5_1 = arg_5_0.item
	local var_5_2 = arg_5_0:nodeByName("icon")

	var_5_2:removeAllChildren()
	xyd.setItemBorder(var_5_2, var_5_1:getTableID())
	arg_5_0:nodeByName("label_name"):setString(var_5_1:getName())
	arg_5_0:nodeByName("label_desc"):setString(var_5_1:getDesc())
	arg_5_0:nodeByName("label_own1"):setString(var_0_2:translation("ITEM_OWN"))
	arg_5_0:nodeByName("label_own2"):setString(var_0_2:translation("ITEM_OWN_SUFFIX"))

	arg_5_0.levelDesStr = "ITEM_EREQUIRED_LEVEL"

	arg_5_0:nodeByName("label_tips1"):setString(var_0_2:translation("ITEM_BIND_TIP"))
	arg_5_0:nodeByName("label_tips2"):setString(string.format(var_0_2:translation(arg_5_0.levelDesStr), var_5_1:getLevel()))
	arg_5_0:nodeByName("label_attr"):setString(xyd.tables.translation:translation("PHYSICAL_ATTACK"))
	arg_5_0:nodeByName("label_attr"):setVisible(false)
	arg_5_0:nodeByName("label_attr_value1"):setVisible(false)
	arg_5_0:nodeByName("label_attr_value2"):setVisible(false)
	arg_5_0:nodeByName("compose_formula"):setString(var_0_3:translation("HERO_MAIN_TEXT_27"))
	arg_5_0:nodeByName("text_compose"):setString(var_0_3:translation("HERO_MAIN_TEXT_28"))
	arg_5_0:nodeByName("gain_way"):setString(var_0_3:translation("HERO_MAIN_TEXT_29"))
	arg_5_0:nodeByName("text_equip"):setString(var_0_3:translation("HERO_MAIN_TEXT_30"))
	arg_5_0:nodeByName("text_ok"):setString(var_0_3:translation("HERO_MAIN_TEXT_31"))
	arg_5_0:nodeByName("btn_equipment_backpack"):setVisible(false)
	arg_5_0:nodeByName("txt_equipment_backpack"):setVisible(false)
	arg_5_0:getBtn()
	arg_5_0:update()
end

function var_0_0.update(arg_6_0)
	arg_6_0:nodeByName("label_own_value"):setString(arg_6_0.item:getSelfNum())

	local var_6_0, var_6_1 = arg_6_0:nodeByName("label_own_value"):getPosition()

	arg_6_0:nodeByName("label_own2"):x(var_6_0 + arg_6_0:nodeByName("label_own_value"):getContentSize().width + 5)

	local var_6_2 = arg_6_0.item
	local var_6_3 = arg_6_0.hero
	local var_6_4 = var_6_2:getAttr()
	local var_6_5 = var_6_2:getFumoAttr()
	local var_6_6 = {}

	if var_6_4[1] and var_6_4[2] and var_6_4[3] and var_6_4[1] == var_6_4[2] and var_6_4[2] == var_6_4[3] then
		local var_6_7 = {
			name = var_0_4:name(1) .. "," .. var_0_4:name(2) .. "," .. var_0_4:name(3),
			value = var_6_4[1],
			fumo = var_6_5[1]
		}

		table.insert(var_6_6, var_6_7)

		for iter_6_0, iter_6_1 in pairs(var_6_4) do
			if iter_6_0 > 3 then
				local var_6_8 = {
					name = var_0_4:name(iter_6_0),
					value = iter_6_1,
					fumo = var_6_5[iter_6_0]
				}

				table.insert(var_6_6, var_6_8)
			end
		end
	else
		for iter_6_2, iter_6_3 in pairs(var_6_4) do
			local var_6_9 = {
				name = var_0_4:name(iter_6_2),
				value = iter_6_3,
				fumo = var_6_5[iter_6_2]
			}

			table.insert(var_6_6, var_6_9)
		end
	end

	if xyd.tables.item:isAwakenItem(arg_6_0.item:getTableID()) > 0 or xyd.tables.item:isAwakeTwiceItem(arg_6_0.item:getTableID()) > 0 then
		arg_6_0:setPracticeAttr(var_6_3, var_6_6)
	end

	local var_6_10 = arg_6_0:nodeByName("list"):getHeight()

	arg_6_0:nodeByName("word_back"):height(var_6_10 + 20)

	if not arg_6_0.list or tolua.isnull(arg_6_0.list) then
		arg_6_0.list = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, 375, 120),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_6_0:nodeByName("list")):onScroll(handler(arg_6_0, arg_6_0.scrollListener))
	end

	arg_6_0:nodeByName("label_desc"):y(arg_6_0:nodeByName("word_back"):getY() - arg_6_0:nodeByName("word_back"):getHeight() - 15)
	arg_6_0:createLabels(var_6_6)

	local var_6_11 = arg_6_0.item:getCompose()

	arg_6_0:nodeByName("text_ok"):hide()
	arg_6_0:nodeByName("text_compose"):hide()
	arg_6_0:nodeByName("text_equip"):hide()
	arg_6_0:nodeByName("gain_way"):hide()
	arg_6_0:nodeByName("compose_formula"):hide()

	if var_6_2:isCollected() then
		arg_6_0:nodeByName("text_ok"):show()

		arg_6_0.state_ = "quit"
	elseif (#var_6_11 < 1 or var_6_11[1] == 0) and not var_6_2:isInBackpack() then
		arg_6_0:nodeByName("gain_way"):show()

		arg_6_0.state_ = "gain_way"
	elseif arg_6_0.id > arg_6_0.hero:getStar() then
		arg_6_0:nodeByName("text_ok"):show()

		arg_6_0.state_ = "quit"
	elseif var_6_2:isInBackpack() then
		arg_6_0:nodeByName("text_equip"):show()

		arg_6_0.state_ = "equip"
	else
		arg_6_0:nodeByName("compose_formula"):show()

		arg_6_0.state_ = "compose"
	end

	if var_6_2:isCollected() then
		arg_6_0:nodeByName("label_tips1"):setString(string.format(var_0_2:translation(arg_6_0.levelDesStr), var_6_2:getLevel()))
		arg_6_0:nodeByName("label_tips1"):setVisible(true)
		arg_6_0:nodeByName("label_tips2"):setVisible(false)
	elseif arg_6_0.id > arg_6_0.hero:getStar() then
		arg_6_0:nodeByName("label_tips2"):setString(string.format(var_0_2:translation("EQUIP_STAR_CONDITiON_TIP"), arg_6_0.id))
		arg_6_0:nodeByName("label_tips2"):setVisible(true)
		arg_6_0:nodeByName("label_tips1"):setVisible(false)
	elseif var_6_3:getLevel() >= var_6_2:getLevel() then
		arg_6_0:nodeByName("label_tips1"):setVisible(true)
		arg_6_0:nodeByName("label_tips2"):setVisible(false)
	elseif var_6_3:getLevel() < var_6_2:getLevel() then
		arg_6_0:nodeByName("label_tips2"):setVisible(true)
		arg_6_0:nodeByName("label_tips1"):setVisible(false)
	end
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 5 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

function var_0_0.setPracticeAttr(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}

	arg_8_0.practiceTitleIndex = #arg_8_2

	table.insert(arg_8_2, var_8_0)

	local var_8_1 = arg_8_1:getPractice()

	if var_8_1[1] ~= 0 or var_8_1[2] ~= 0 or var_8_1[3] ~= 0 then
		var_8_0.name = var_0_3:translation("WASH_ATTRIBUTE")

		local var_8_2 = {}

		table.insert(var_8_2, var_0_2:translation("LILIANG_ADD"))
		table.insert(var_8_2, var_0_2:translation("ZHILI_ZENGJIA"))
		table.insert(var_8_2, var_0_2:translation("MINJIE_ZENGJIA"))

		if arg_8_0.hero:isAwaken() and (arg_8_0.item.tableID_ == xyd.tables.hero:awakenItemID(arg_8_0.hero.tableID_) or arg_8_0.item.tableID_ == xyd.tables.hero:awakeTwiceItem(arg_8_0.hero.tableID_)) then
			for iter_8_0 = 1, #var_8_1 do
				local var_8_3 = {
					name = var_8_2[iter_8_0],
					value = tonumber(var_8_1[iter_8_0])
				}

				table.insert(arg_8_2, var_8_3)
			end
		end
	else
		var_8_0.name = var_0_3:translation("WASH_AFTER_GET")
	end

	var_8_0.value = 0

	local var_8_4 = var_0_5:getPracticeNeeds(arg_8_1:getTableID())
	local var_8_5 = var_0_5:getPracticeAttrType(arg_8_1:getTableID())
	local var_8_6 = var_0_5:getPracticeAttrValue(arg_8_1:getTableID())

	if #var_8_4 ~= 3 or #var_8_5 ~= 3 or #var_8_6 ~= 3 then
		return
	end

	local var_8_7 = {}

	function hasSameAttr(arg_9_0)
		if not next(var_8_7) then
			return nil
		end

		for iter_9_0, iter_9_1 in pairs(var_8_7) do
			if iter_9_1.name == arg_9_0 then
				return iter_9_0
			end
		end

		return nil
	end

	for iter_8_1 = 1, #var_8_4 do
		if var_8_1[iter_8_1] >= var_8_4[iter_8_1] then
			local var_8_8 = hasSameAttr(xyd.tables.attr:name(var_8_5[iter_8_1]))

			if var_8_8 then
				var_8_7[var_8_8].value = var_8_7[var_8_8].value + var_8_6[iter_8_1]
			else
				local var_8_9 = {
					name = xyd.tables.attr:name(var_8_5[iter_8_1]),
					value = var_8_6[iter_8_1]
				}

				table.insert(var_8_7, var_8_9)
			end
		end
	end

	for iter_8_2, iter_8_3 in pairs(var_8_7) do
		table.insert(arg_8_2, iter_8_3)
	end
end

function var_0_0.createLabels(arg_10_0, arg_10_1)
	local var_10_0, var_10_1 = arg_10_0:nodeByName("label_attr"):getPosition()

	arg_10_0.list:removeAllItems()

	local var_10_2 = 0

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		local var_10_3 = arg_10_0.list:newItem()
		local var_10_4 = display.newNode()
		local var_10_5 = arg_10_0:nodeByName("label_attr"):clone()

		if iter_10_1.name == var_0_4:name(xyd.AttributeType.HALF_MP) then
			var_10_2 = var_10_2 + 1
			iter_10_1.name = string.sub(iter_10_1.name, 1, 21) .. "\n" .. string.sub(iter_10_1.name, 22, #iter_10_1.name)
		end

		var_10_5:setString(iter_10_1.name)
		var_10_5:setVisible(true)
		var_10_5:y(var_10_1 - (iter_10_0 - 1 + var_10_2) * var_0_6)
		var_10_5:addTo(var_10_4)

		local var_10_6 = arg_10_0:nodeByName("label_attr_value1"):clone()
		local var_10_7 = ""

		if iter_10_1.value then
			var_10_7 = iter_10_1.value < 0 and "" or "+"
		end

		if iter_10_1.value then
			var_10_6:setString(var_10_7 .. iter_10_1.value .. (iter_10_1.suffix or ""))
		else
			var_10_6:setString("")
		end

		if iter_10_1.color then
			var_10_6:setColor(iter_10_1.color)
			var_10_5:setColor(iter_10_1.color)
		end

		var_10_6:setVisible(true)
		var_10_6:y(var_10_1 - (iter_10_0 - 1 + var_10_2) * var_0_6):x(var_10_0 + var_10_5:getContentSize().width)
		var_10_6:addTo(var_10_4)

		if iter_10_1.fumo and iter_10_1.fumo > 0 then
			local var_10_8, var_10_9 = var_10_6:getPosition()
			local var_10_10 = arg_10_0:nodeByName("label_attr_value2"):clone()
			local var_10_11 = iter_10_1.fumo < 0 and "" or "+"

			var_10_10:setString(var_10_11 .. iter_10_1.fumo)
			var_10_10:setVisible(true)
			var_10_10:y(var_10_1 - (iter_10_0 - 1 + var_10_2) * var_0_6):x(var_10_8 + var_10_6:getWidth())
			var_10_10:addTo(var_10_4)
		end

		if arg_10_0.practiceTitleIndex ~= nil and iter_10_0 == arg_10_0.practiceTitleIndex + 1 then
			var_10_5:setColor(cc.c3b(9, 50, 223))
			var_10_5:y(var_10_1 - (iter_10_0 - 1 + var_10_2) * var_0_6 - 20)
			var_10_6:setVisible(false)
		end

		if arg_10_0.practiceTitleIndex ~= nil and iter_10_0 > arg_10_0.practiceTitleIndex + 1 then
			var_10_6:setColor(cc.c3b(0, 151, 0))
			var_10_5:setColor(cc.c3b(0, 151, 0))
			var_10_5:y(var_10_1 - (iter_10_0 - 1 + var_10_2) * var_0_6 - 20)
			var_10_6:y(var_10_1 - (iter_10_0 - 1 + var_10_2) * var_0_6 - 20):x(var_10_0 + var_10_5:getContentSize().width)
		end

		var_10_4:setPosition(-40, -328)
		var_10_4:setTouchEnabled(false)
		var_10_4:setTouchSwallowEnabled(true)
		var_10_3:addChild(var_10_4)
		var_10_3:setItemSize(375, 30)
		arg_10_0.list:addItem(var_10_3)
	end
end

function var_0_0.getBtn(arg_11_0)
	if not arg_11_0.btn_ then
		arg_11_0.btn_ = arg_11_0:nodeByName("button")

		arg_11_0.btn_:addTouchEventListener(function(arg_12_0, arg_12_1)
			xyd.buttonScaleAnim(arg_11_0.btn_, arg_12_1)

			if arg_12_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if not arg_11_0.state_ or arg_11_0.state_ == "quit" then
					if xyd.WindowManager.get():getWindow("item_compose") then
						xyd.WindowManager.get():closeWindow("item_compose")
						xyd.WindowManager.get():closeWindow(arg_11_0)
					else
						xyd.WindowManager.get():closeWindow(arg_11_0)
					end
				elseif arg_11_0.state_ == "equip" then
					if arg_11_0.hero and arg_11_0.hero:getLevel() >= arg_11_0.item:getLevel() then
						arg_11_0:equipItems()
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = string.format(var_0_2:translation(arg_11_0.levelDesStr), arg_11_0.item:getLevel())
						})
					end
				elseif arg_11_0.state_ == "compose" then
					local var_12_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
						item = arg_11_0.item
					})

					cc.EventProxy.new(var_12_0, var_12_0):addEventListener(xyd.event.ITEM_CHANGED, function(arg_13_0)
						arg_11_0:update()
						arg_11_0.callback()
					end)
				end
			elseif arg_11_0.state_ == "gain_way" then
				local var_12_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
					isCompose = false,
					item = arg_11_0.item
				})
			end
		end)
	end

	return arg_11_0.btn_
end

function var_0_0.equipItems(arg_14_0)
	local var_14_0 = {
		house_id = arg_14_0.houseId,
		index = arg_14_0.id
	}

	arg_14_0.dorm:houseEquip(var_14_0, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			arg_14_0.hero:setHouseEquip(var_14_0.index, arg_14_0.item.tableID_)
			arg_14_0.callback()

			local var_15_0 = {
				itemID = arg_14_0.item.tableID_
			}

			var_15_0.itemNum = 1

			arg_14_0.backpack:removeItem(var_15_0)
			xyd.WindowManager.get():closeWindow("item_compose")
			xyd.WindowManager.get():closeWindow(arg_14_0)
		end
	end)
end

return var_0_0
