local var_0_0 = class("AdvancedTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 50
local var_0_3 = 140

function var_0_0.open(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_0 or {}

	var_1_0.callback = arg_1_1

	return xyd.WindowManager.get():openWindow("advanced_tip", var_1_0)
end

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	var_0_0.super.ctor(arg_2_0, arg_2_1, arg_2_2)

	arg_2_0.heroName = arg_2_2.heroName
	arg_2_0.items = arg_2_2.items
	arg_2_0.isList = false
	arg_2_0.isPet = arg_2_2.isPet
	arg_2_0.callback = arg_2_2.callback
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
end

function var_0_0.close(arg_4_0)
	xyd.WindowManager.get():closeWindow("advanced_tip", arg_4_0)
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
		xyd.buttonScaleAnim(arg_5_0:confirmButton_(), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_FIVE then
				xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_SIX)
				xyd.StoryData.get():persist()
				xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):sendOperationLog(xyd.StatID.ID_JINJIE_6)
			end

			var_0_0.close(function()
				var_5_0(true)
			end)
		end
	end)
	arg_5_0:rejectButton_():addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_5_0:rejectButton_(), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			var_0_0.close(function()
				var_5_0(false)
			end)
		end
	end)
	arg_5_0:addBlockLayer()
	arg_5_0:playGuide()
end

function var_0_0.didClose(arg_11_0, arg_11_1)
	var_0_0.super.didClose(arg_11_0, arg_11_1)

	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 20 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_13_0)
	arg_13_0:nodeByName("title"):setString(var_0_1:translation("AVANCE_TIP"))
	arg_13_0:nodeByName("txt_sure"):setString(string.format(var_0_1:translation("ALERT_POWER_UP1"), arg_13_0.heroName))

	local var_13_0 = #arg_13_0.items

	arg_13_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 425, 260),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_13_0:nodeByName("item_list")):onScroll(handler(arg_13_0, arg_13_0.scrollListener))

	arg_13_0.list:setAnchorPoint(cc.p(0, 0))
	arg_13_0.list:setPosition(0, 0)

	local var_13_1 = math.ceil(var_13_0 / 3)

	for iter_13_0 = 1, var_13_1 do
		local var_13_2 = 3

		if iter_13_0 == var_13_1 then
			var_13_2 = var_13_0 % 3

			if var_13_2 == 0 then
				var_13_2 = 3
			end
		end

		local var_13_3 = display.newNode()
		local var_13_4 = arg_13_0.list:newItem()

		for iter_13_1 = 1, var_13_2 do
			local var_13_5 = arg_13_0.items[(iter_13_0 - 1) * 3 + iter_13_1]
			local var_13_6 = cc.Node:create()

			var_13_6:setContentSize(var_0_2, var_0_2)

			if var_13_5.table_id > 0 then
				xyd.setItemBorder(var_13_6, var_13_5.table_id)
			else
				local var_13_7 = xyd.AssetLoader:get():loadSprite("images/jinbi.png")

				var_13_7:setScale(0.8)
				xyd.displaySpriteOnContainer(var_13_7, var_13_6, false)
			end

			var_13_3:addChild(var_13_6)
			var_13_6:setAnchorPoint(cc.p(0, 0))

			local var_13_8 = {
				size = 22,
				color = cc.c4b(54, 54, 54, 255)
			}
			local var_13_9 = xyd.AssetLoader:get():loadLabel(var_13_8)

			var_13_9:setString("X " .. var_13_5.item_num)
			var_13_3:addChild(var_13_9)
			var_13_9:setAnchorPoint(cc.p(0, 0))
			var_13_6:setPosition((iter_13_1 - 1) * var_0_3 + 25, 0)
			var_13_9:setPosition((iter_13_1 - 1) * var_0_3 + 85, 0)
		end

		var_13_3:setContentSize(3 * var_0_3, 13 + var_0_2)
		var_13_4:addContent(var_13_3)
		var_13_4:setItemSize(3 * var_0_3, 13 + var_0_2)
		arg_13_0.list:addItem(var_13_4)
	end

	arg_13_0.list:reload()
	arg_13_0:createLabels()
end

function var_0_0.createLabels(arg_14_0)
	arg_14_0:nodeByName("message"):removeAllChildren()

	local var_14_0 = 0
	local var_14_1 = 0
	local var_14_2 = {}
	local var_14_3 = {}

	if not arg_14_0.isPet then
		table.insert(var_14_3, var_0_1:translation("ALERT_POWER_UP2"))
	end

	for iter_14_0 = 1, #var_14_3 do
		local var_14_4 = {
			size = 24,
			color = cc.c3b(238, 127, 16)
		}
		local var_14_5 = xyd.AssetLoader:get():loadLabel(var_14_4)

		var_14_5:setString(var_14_3[iter_14_0])
		var_14_5:setMaxLineWidth(arg_14_0:nodeByName("message"):getContentSize().width)
		var_14_5:setAnchorPoint(cc.p(0, 0))
		var_14_5:addTo(arg_14_0:nodeByName("message"))

		var_14_0 = var_14_0 + var_14_5:getContentSize().height

		table.insert(var_14_2, var_14_5)
	end

	local var_14_6 = (arg_14_0:nodeByName("message"):getContentSize().height + var_14_0) / 2

	for iter_14_1 = 1, #var_14_2 do
		var_14_6 = var_14_6 - var_14_2[iter_14_1]:getContentSize().height

		var_14_2[iter_14_1]:setPosition(var_14_1, var_14_6)
	end
end

function var_0_0.confirmButton_(arg_15_0)
	return arg_15_0:nodeByName("btn_sure")
end

function var_0_0.rejectButton_(arg_16_0)
	return arg_16_0:nodeByName("btn_cancel")
end

function var_0_0.playGuide(arg_17_0)
	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_FIVE then
		if xyd.WindowManager.get():isWindowOpen("guide") then
			xyd.WindowManager.get():closeWindow("guide")
		end

		local var_17_0 = arg_17_0:confirmButton_()
		local var_17_1 = var_17_0:getPositionX()
		local var_17_2 = var_17_0:getPositionY()

		xyd.WindowManager.get():openWindow("guide")

		local var_17_3 = xyd.WindowManager.get():getWindow("guide")
		local var_17_4 = var_17_3:convertToNodeSpace(var_17_0:getParent():convertToWorldSpace(cc.p(var_17_1, var_17_2)))

		var_17_3:addNode()
		var_17_3:setStencil(var_17_0:getContentSize().width, var_17_0:getContentSize().height, var_17_4.x, var_17_4.y, 3, {
			position = {
				900,
				300
			}
		})
	end
end

return var_0_0
