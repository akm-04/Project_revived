local var_0_0 = class("OneKeyEquipTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 50
local var_0_3 = 140

function var_0_0.open(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_0 or {}

	var_1_0.callback = arg_1_1

	print()

	return xyd.WindowManager.get():openWindow("onekeyequip_tip", var_1_0)
end

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	var_0_0.super.ctor(arg_2_0, arg_2_1, arg_2_2)

	arg_2_0.heroName = arg_2_2.heroName
	arg_2_0.items = arg_2_2.items
	arg_2_0.isList = false
	arg_2_0.callback = arg_2_2.callback
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
end

function var_0_0.close(arg_4_0)
	xyd.WindowManager.get():closeWindow("onekeyequip_tip", arg_4_0)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super.didOpen(arg_5_0, arg_5_1)

	local function var_5_0(arg_6_0)
		if arg_5_0.callback ~= nil then
			arg_5_0.callback(arg_6_0)
		end

		arg_5_0.callback = nil
	end

	arg_5_0:confirmButton_():addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.buttonScaleAnim(arg_5_0:confirmButton_(), arg_7_1)
			xyd.playButtonSound()
			var_0_0.close(function()
				var_5_0(true)
			end)
		end
	end)
	arg_5_0:rejectButton_():addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.buttonScaleAnim(arg_5_0:rejectButton_(), arg_9_1)
			xyd.playButtonSound()
			var_0_0.close(function()
				var_5_0(false)
			end)
		end
	end)
	arg_5_0:addBlockLayer()
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 20 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_12_0)
	arg_12_0:nodeByName("txt_sure"):setString(string.format(var_0_1:translation("EQUIP_TIP_MESSAGE1"), arg_12_0.heroName))
	arg_12_0:nodeByName("txt_cancel"):setString(var_0_1:translation("HERO_MAIN_TEXT_39"))
	arg_12_0:nodeByName("txt_yes"):setString(var_0_1:translation("HERO_MAIN_TEXT_31"))
	arg_12_0:nodeByName("title"):setString(var_0_1:translation("ONEKEYEQUIP_TIP"))

	local var_12_0 = #arg_12_0.items

	arg_12_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 425, 260),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_12_0:nodeByName("item_list")):onScroll(handler(arg_12_0, arg_12_0.scrollListener))

	arg_12_0.list:setAnchorPoint(cc.p(0, 0))
	arg_12_0.list:setPosition(0, 0)

	local var_12_1 = math.ceil(var_12_0 / 3)

	for iter_12_0 = 1, var_12_1 do
		local var_12_2 = 3

		if iter_12_0 == var_12_1 then
			var_12_2 = var_12_0 % 3

			if var_12_2 == 0 then
				var_12_2 = 3
			end
		end

		local var_12_3 = display.newNode()
		local var_12_4 = arg_12_0.list:newItem()

		for iter_12_1 = 1, var_12_2 do
			local var_12_5 = arg_12_0.items[(iter_12_0 - 1) * 3 + iter_12_1]
			local var_12_6 = cc.Node:create()

			var_12_6:setContentSize(var_0_2, var_0_2)

			if var_12_5.table_id > 0 then
				xyd.setItemBorder(var_12_6, var_12_5.table_id)
			else
				local var_12_7 = xyd.AssetLoader:get():loadSprite("images/jinbi.png")

				var_12_7:setScale(0.8)
				xyd.displaySpriteOnContainer(var_12_7, var_12_6, false)
			end

			var_12_3:addChild(var_12_6)
			var_12_6:setAnchorPoint(cc.p(0, 0))

			local var_12_8 = {
				size = 20,
				color = cc.c4b(54, 54, 54, 255)
			}
			local var_12_9 = xyd.AssetLoader:get():loadLabel(var_12_8)

			var_12_9:setString("X " .. var_12_5.item_num)
			var_12_3:addChild(var_12_9)
			var_12_9:setAnchorPoint(cc.p(0, 0))
			var_12_6:setPosition((iter_12_1 - 1) * var_0_3, 0)
			var_12_9:setPosition((iter_12_1 - 1) * var_0_3 + 60, 0)
		end

		var_12_3:setContentSize(3 * var_0_3, 13 + var_0_2)
		var_12_4:addContent(var_12_3)
		var_12_4:setItemSize(3 * var_0_3, 13 + var_0_2)
		arg_12_0.list:addItem(var_12_4)
	end

	arg_12_0.list:reload()
	arg_12_0:createLabels()
end

function var_0_0.createLabels(arg_13_0)
	arg_13_0:nodeByName("message"):removeAllChildren()

	local var_13_0 = 0
	local var_13_1 = 0
	local var_13_2 = {}
	local var_13_3 = {
		var_0_1:translation("EQUIP_TIP_MESSAGE2")
	}

	for iter_13_0 = 1, #var_13_3 do
		local var_13_4 = {
			size = 24,
			color = cc.c3b(238, 127, 16)
		}
		local var_13_5 = xyd.AssetLoader:get():loadLabel(var_13_4)

		var_13_5:setString(var_13_3[iter_13_0])
		var_13_5:setMaxLineWidth(arg_13_0:nodeByName("message"):getContentSize().width)
		var_13_5:setAnchorPoint(cc.p(0, 0))
		var_13_5:addTo(arg_13_0:nodeByName("message"))

		var_13_0 = var_13_0 + var_13_5:getContentSize().height

		table.insert(var_13_2, var_13_5)
	end

	local var_13_6 = (arg_13_0:nodeByName("message"):getContentSize().height + var_13_0) / 2

	for iter_13_1 = 1, #var_13_2 do
		var_13_6 = var_13_6 - var_13_2[iter_13_1]:getContentSize().height

		var_13_2[iter_13_1]:setPosition(var_13_1, var_13_6)
	end
end

function var_0_0.confirmButton_(arg_14_0)
	return arg_14_0:nodeByName("btn_sure")
end

function var_0_0.rejectButton_(arg_15_0)
	return arg_15_0:nodeByName("btn_cancel")
end

return var_0_0
