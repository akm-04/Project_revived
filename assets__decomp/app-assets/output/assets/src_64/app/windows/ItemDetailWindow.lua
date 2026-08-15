local var_0_0 = class("ItemDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.attr
local var_0_4 = 35

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.item = arg_1_2.item
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.playerLev = arg_1_0.selfPlayer.lev
	arg_1_0.backpack_ = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:addBlockLayer(nil, false, false, function()
		if xyd.WindowManager.get():getWindow("item_compose") then
			xyd.WindowManager.get():closeWindow("item_compose")
			xyd.WindowManager.get():closeWindow(arg_2_0)
		else
			xyd.WindowManager.get():closeWindow(arg_2_0)
		end
	end)
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)

	arg_4_0.panelAttr_ = arg_4_0:nodeByName("word_back")

	arg_4_0:layout()
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0.item
	local var_5_1 = arg_5_0:nodeByName("icon")

	var_5_1:removeAllChildren()
	xyd.setItemBorder(var_5_1, var_5_0:getTableID())
	arg_5_0:nodeByName("label_name"):setString(var_5_0:getName())
	arg_5_0:nodeByName("label_desc"):hide()
	arg_5_0:nodeByName("label_own1"):setString(var_0_1:translation("ITEM_OWN"))
	arg_5_0:nodeByName("label_own2"):setString(var_0_1:translation("ITEM_OWN_SUFFIX"))
	arg_5_0:nodeByName("label_tips1"):setString(var_0_1:translation("ITEM_BIND_TIP"))
	arg_5_0:nodeByName("label_tips2"):setString(string.format(var_0_1:translation("ITEM_EREQUIRED_LEVEL"), var_5_0:getLevel()))
	arg_5_0:nodeByName("label_attr"):hide()
	arg_5_0:nodeByName("label_attr_value1"):hide()
	arg_5_0:nodeByName("label_attr_value2"):hide()

	arg_5_0.flag = true

	arg_5_0:getBtn()
	arg_5_0:update()
end

function var_0_0.update(arg_6_0)
	if arg_6_0.flag == false then
		arg_6_0:nodeByName("word_back"):removeAllChildren()
	end

	arg_6_0:nodeByName("label_own_value"):setString(arg_6_0.item:getSelfNum())

	local var_6_0, var_6_1 = arg_6_0:nodeByName("label_own_value"):getPosition()

	arg_6_0:nodeByName("label_own2"):x(var_6_0 + arg_6_0:nodeByName("label_own_value"):getContentSize().width + 5)

	local var_6_2 = arg_6_0.item

	if arg_6_0.labelDesc_ then
		arg_6_0.labelDesc_:removeSelf()
	end

	local var_6_3 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = arg_6_0:nodeByName("label_desc"):getX(),
		y = arg_6_0:nodeByName("word_back"):getY() - 30,
		color = cc.c3b(51, 48, 43),
		text = var_6_2:getSubDesc(),
		dimensions = cc.size(280, 200)
	}

	arg_6_0.labelDesc_ = xyd.AssetLoader.get():loadLabel(var_6_3)

	arg_6_0.labelDesc_:addTo(arg_6_0)
	arg_6_0.labelDesc_:align(display.CENTER_TOP)
	arg_6_0:nodeByName("word_back"):height(arg_6_0.labelDesc_:getStringNumLines() * 26 + 60)

	local var_6_4 = arg_6_0.item:getCompose()

	arg_6_0:nodeByName("text_ok"):hide()
	arg_6_0:nodeByName("text_compose"):hide()
	arg_6_0:nodeByName("text_equip"):hide()
	arg_6_0:nodeByName("gain_way"):hide()
	arg_6_0:nodeByName("compose_formula"):hide()
	arg_6_0:nodeByName("label_tips1"):hide()
	arg_6_0:nodeByName("label_tips2"):hide()
	arg_6_0:nodeByName("text_light"):hide()
	arg_6_0:nodeByName("label_desc"):show()
	arg_6_0:nodeByName("label_desc"):setString(var_0_2:desc2(var_6_2:getTableID()))
	arg_6_0:delegateItemDesc()

	if arg_6_0.playerLev < var_6_2:getLevel() then
		arg_6_0:nodeByName("label_tips2"):show()
		arg_6_0:nodeByName("label_tips2"):setString(string.format(var_0_1:translation("ITEM_EREQUIRED_LEVEL"), var_6_2:getLevel()))
	else
		arg_6_0:nodeByName("label_tips1"):show()
		arg_6_0:nodeByName("label_tips1"):setString(string.format(var_0_1:translation("ITEM_EREQUIRED_LEVEL"), var_6_2:getLevel()))
	end

	if #var_6_4 < 1 or var_6_4[1] == 0 then
		arg_6_0:nodeByName("gain_way"):show()

		arg_6_0.state_ = "gain_way"
	else
		arg_6_0:nodeByName("compose_formula"):show()

		arg_6_0.state_ = "compose"
	end
end

function var_0_0.delegateItemDesc(arg_7_0)
	local var_7_0 = arg_7_0.item
	local var_7_1 = xyd.tables.item:attrs(var_7_0:getTableID())
	local var_7_2 = {}

	if var_7_1[1] and var_7_1[2] and var_7_1[3] and var_7_1[1] == var_7_1[2] and var_7_1[2] == var_7_1[3] then
		local var_7_3 = {
			name = var_0_3:name(1) .. "，" .. var_0_3:name(2) .. "，" .. var_0_3:name(3),
			value = var_7_1[1]
		}

		table.insert(var_7_2, var_7_3)

		for iter_7_0, iter_7_1 in pairs(var_7_1) do
			if iter_7_0 > 3 then
				local var_7_4 = {
					name = var_0_3:name(iter_7_0),
					value = iter_7_1
				}

				table.insert(var_7_2, var_7_4)
			end
		end
	else
		for iter_7_2, iter_7_3 in pairs(var_7_1) do
			local var_7_5 = {
				name = var_0_3:name(iter_7_2),
				value = iter_7_3
			}

			table.insert(var_7_2, var_7_5)
		end
	end

	arg_7_0:nodeByName("word_back"):height((#var_7_2 + 1) * var_0_4)
	arg_7_0:nodeByName("label_desc"):y(arg_7_0:nodeByName("word_back"):getY() - arg_7_0:nodeByName("word_back"):getHeight() - 10)
	arg_7_0:nodeByName("label_attr"):hide()
	arg_7_0:nodeByName("label_attr_value1"):hide()
	arg_7_0:nodeByName("label_attr_value2"):hide()

	local var_7_6 = arg_7_0:nodeByName("list"):getHeight()

	arg_7_0:nodeByName("word_back"):height(var_7_6 + 20)

	if not arg_7_0.list or tolua.isnull(arg_7_0.list) then
		arg_7_0.list = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, 300, 150),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_7_0:nodeByName("list")):onScroll(handler(arg_7_0, arg_7_0.scrollListener))
	end

	arg_7_0:nodeByName("label_desc"):y(arg_7_0:nodeByName("word_back"):getY() - arg_7_0:nodeByName("word_back"):getHeight() - 15)
	arg_7_0:createLabels(var_7_2)
end

function var_0_0.createLabels(arg_8_0, arg_8_1)
	local var_8_0, var_8_1 = arg_8_0:nodeByName("label_attr"):getPosition()

	arg_8_0.list:removeAllItems()

	local var_8_2 = 0

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_3 = arg_8_0.list:newItem()
		local var_8_4 = display.newNode()
		local var_8_5 = arg_8_0:nodeByName("label_attr"):clone()

		if iter_8_1.name == var_0_3:name(xyd.AttributeType.HALF_MP) then
			var_8_2 = var_8_2 + 1
			iter_8_1.name = string.sub(iter_8_1.name, 1, 21) .. "\n" .. string.sub(iter_8_1.name, 22, #iter_8_1.name)
		end

		var_8_5:setString(iter_8_1.name)
		var_8_5:setVisible(true)
		var_8_5:y(var_8_1 - (iter_8_0 - 1 + var_8_2) * var_0_4)
		var_8_5:addTo(var_8_4)

		local var_8_6 = arg_8_0:nodeByName("label_attr_value1"):clone()
		local var_8_7 = iter_8_1.value < 0 and "" or "+"

		var_8_6:setString(var_8_7 .. iter_8_1.value)
		var_8_6:setVisible(true)
		var_8_6:y(var_8_1 - (iter_8_0 - 1 + var_8_2) * var_0_4):x(var_8_0 + var_8_5:getContentSize().width)
		var_8_6:addTo(var_8_4)

		if iter_8_1.fumo and iter_8_1.fumo > 0 then
			local var_8_8, var_8_9 = var_8_6:getPosition()
			local var_8_10 = arg_8_0:nodeByName("label_attr_value2"):clone()
			local var_8_11 = iter_8_1.fumo < 0 and "" or "+"

			var_8_10:setString(var_8_11 .. iter_8_1.fumo)
			var_8_10:setVisible(true)
			var_8_10:y(var_8_1 - (iter_8_0 - 1 + var_8_2) * var_0_4):x(var_8_8 + var_8_6:getWidth())
			var_8_10:addTo(var_8_4)
		end

		if arg_8_0.practiceTitleIndex ~= nil and iter_8_0 == arg_8_0.practiceTitleIndex + 1 then
			var_8_5:setColor(cc.c3b(9, 50, 223))
			var_8_5:y(var_8_1 - (iter_8_0 - 1 + var_8_2) * var_0_4 - 20)
			var_8_6:setVisible(false)
		end

		if arg_8_0.practiceTitleIndex ~= nil and iter_8_0 > arg_8_0.practiceTitleIndex + 1 then
			var_8_6:setColor(cc.c3b(0, 151, 0))
			var_8_5:setColor(cc.c3b(0, 151, 0))
			var_8_5:y(var_8_1 - (iter_8_0 - 1 + var_8_2) * var_0_4 - 20)
			var_8_6:y(var_8_1 - (iter_8_0 - 1 + var_8_2) * var_0_4 - 20):x(var_8_0 + var_8_5:getContentSize().width)
		end

		var_8_4:setPosition(-40, -240)
		var_8_4:setTouchEnabled(false)
		var_8_4:setTouchSwallowEnabled(true)
		var_8_3:addChild(var_8_4)
		var_8_3:setItemSize(300, 30)
		arg_8_0.list:addItem(var_8_3)
	end
end

function var_0_0.getBtn(arg_9_0)
	local var_9_0 = arg_9_0.item

	if not arg_9_0.btn_ then
		arg_9_0.btn_ = arg_9_0:nodeByName("button")

		arg_9_0.btn_:addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_9_0.state_ == "compose" then
					local var_10_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
						item = arg_9_0.item
					})

					arg_9_0.flag = false

					cc.EventProxy.new(var_10_0, var_10_0):addEventListener(xyd.event.ITEM_CHANGED, function(arg_11_0)
						arg_9_0:update()
					end)
				elseif arg_9_0.state_ == "gain_way" then
					local var_10_1 = xyd.WindowManager.get():openWindow(xyd.WindowName.itemComposeWnd, {
						isCompose = false,
						item = arg_9_0.item
					})
				end
			end
		end)
	end

	return arg_9_0.btn_
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevX_ = arg_12_1.x
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" then
		local var_12_0 = 20

		if var_12_0 <= math.abs(arg_12_1.x - arg_12_0.prevX_) or var_12_0 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
			arg_12_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.didClose(arg_13_0)
	return
end

return var_0_0
