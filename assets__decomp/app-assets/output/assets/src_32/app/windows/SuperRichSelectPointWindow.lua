local var_0_0 = class("SuperRichSelectPointWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "windows/zillionaire/select_point/"
local var_0_3 = 6
local var_0_4 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.selectPoint = 1
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("top_text"):setString(var_0_1:translation("SUPER_RICH_SELECT_POINT_TEXT"))
	arg_4_0:setButtonClick()
	arg_4_0:updateItems()
end

function var_0_0.setButtonClick(arg_5_0)
	local var_5_0

	arg_5_0:nodeByName("hide_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			local var_6_0 = 0

			local function var_6_1()
				var_6_0 = var_6_0 + 0.1

				if var_6_0 > 0.5 then
					arg_5_0:nodeByName("container"):setOpacity(0)
				end
			end

			var_5_0 = var_0_4.scheduleGlobal(var_6_1, 0.1)
		elseif arg_6_1 == ccui.TouchEventType.ended or arg_6_1 == ccui.TouchEventType.canceled then
			if var_5_0 then
				var_0_4.unscheduleGlobal(var_5_0)

				var_5_0 = nil
			end

			arg_5_0:nodeByName("container"):setOpacity(255)
		end
	end)
	arg_5_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.callback(arg_5_0.selectPoint)
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
end

function var_0_0.updateItems(arg_9_0)
	arg_9_0:nodeByName("pos"):removeAllChildren(true)

	arg_9_0.items = {}

	for iter_9_0 = 1, var_0_3 do
		local var_9_0 = arg_9_0:createItem(iter_9_0)

		var_9_0:setTouchEnabled(true)

		var_9_0.point = iter_9_0

		var_9_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
			if arg_10_0.name == "began" then
				return true
			elseif arg_10_0.name == "ended" then
				arg_9_0.selectPoint = iter_9_0

				arg_9_0:updateSelectShow()
			end
		end)
		var_9_0:addTo(arg_9_0:nodeByName("pos"))
		var_9_0:setPosition((iter_9_0 - 1) % 3 * 140 - 20, -math.floor((iter_9_0 - 1) / 3) * 130 - 120)
		table.insert(arg_9_0.items, var_9_0)
	end

	arg_9_0:updateSelectShow()
end

function var_0_0.updateSelectShow(arg_11_0)
	for iter_11_0, iter_11_1 in pairs(arg_11_0.items) do
		local var_11_0 = iter_11_1:getChildByName("container")

		if arg_11_0.selectPoint == iter_11_1.point then
			var_11_0:getChildByName("box_1"):setVisible(false)
			var_11_0:getChildByName("box_2"):setVisible(true)
		else
			var_11_0:getChildByName("box_1"):setVisible(true)
			var_11_0:getChildByName("box_2"):setVisible(false)
		end
	end
end

function var_0_0.createItem(arg_12_0, arg_12_1)
	local var_12_0 = xyd.AssetLoader.get():loadNodeFromJson(var_0_2 .. "dice_item.csb")
	local var_12_1 = var_12_0:getChildByName("container")

	var_12_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_12_1:getChildByName("box_1"):setVisible(true)
	var_12_1:getChildByName("box_2"):setVisible(false)
	xyd.AssetLoader.get():loadSprite(var_0_2 .. arg_12_1 .. ".png"):addTo(var_12_1:getChildByName("item_pos"))

	return var_12_0
end

return var_0_0
