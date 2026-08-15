local var_0_0 = class("OccultCampaignRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 760

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 10 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(15, 0, var_0_2 + 15, 430),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:createSubHeaderLabel("CREATS_RULE2")
	arg_4_0:createRuleLabels("CREATS_RULE3")
	arg_4_0:createSubHeaderLabel("CREATS_RULE4")
	arg_4_0:createRuleLabels("CREATS_RULE5")
	arg_4_0:createSubHeaderLabel("CREATS_RULE6")
	arg_4_0:createRuleLabels("CREATS_RULE7")
	arg_4_0.list:reload()
end

function var_0_0.createRuleLabels(arg_6_0, arg_6_1)
	local var_6_0 = var_0_1:translation(arg_6_1)
	local var_6_1 = xyd.luaStringSplit(var_6_0, "|")
	local var_6_2 = {}

	for iter_6_0 = 1, #var_6_1 do
		local var_6_3 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_6_4 = xyd.AssetLoader.get():loadLabel(var_6_3)

		var_6_4:setMaxLineWidth(var_0_2)
		var_6_4:setLineHeight(49)
		var_6_4:setString(var_6_1[iter_6_0])
		table.insert(var_6_2, var_6_4)
	end

	for iter_6_1 = 1, #var_6_2 do
		local var_6_5 = display.newNode()
		local var_6_6 = arg_6_0.list:newItem()
		local var_6_7 = display.newNode()

		var_6_2[iter_6_1]:addTo(var_6_7)
		var_6_2[iter_6_1]:setAnchorPoint(cc.p(0, 0))
		var_6_2[iter_6_1]:setPosition(0, 0)
		var_6_7:setContentSize(var_0_2, var_6_2[iter_6_1]:getContentSize().height)
		var_6_7:addTo(var_6_5)
		var_6_5:setContentSize(var_0_2, var_6_2[iter_6_1]:getContentSize().height + 20)
		var_6_6:addContent(var_6_5)
		var_6_6:setItemSize(var_0_2, var_6_2[iter_6_1]:getContentSize().height + 20)
		arg_6_0.list:addItem(var_6_6)
	end
end

function var_0_0.createSubHeaderLabel(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()
	local var_7_1 = arg_7_0.list:newItem()
	local var_7_2 = display.newNode()
	local var_7_3 = var_0_1:translation(arg_7_1)
	local var_7_4 = {
		size = 24,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = x,
		y = y,
		color = cc.c3b(255, 168, 65),
		dimensions = cc.size(780, 0),
		text = var_7_3
	}
	local var_7_5 = xyd.AssetLoader.get():loadLabel(var_7_4)

	var_7_5:addTo(var_7_2)
	var_7_2:setContentSize(var_0_2, var_7_5:getContentSize().height)
	var_7_5:setAnchorPoint(cc.p(0, 0))
	var_7_2:addTo(var_7_0)
	var_7_0:setContentSize(var_0_2, var_7_5:getContentSize().height + 20)
	var_7_1:addContent(var_7_0)
	var_7_1:setItemSize(var_0_2, var_7_5:getContentSize().height + 20)
	arg_7_0.list:addItem(var_7_1)

	return var_7_5
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
