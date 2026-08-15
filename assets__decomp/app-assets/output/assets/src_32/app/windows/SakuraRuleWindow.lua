local var_0_0 = class("SakuraRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

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
		viewRect = cc.rect(0, 0, 700, 400),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("title"):setString(var_0_1:translation("ACTIVITY_SAKURA2_RULE_TITLE"))
	arg_4_0:nodeByName("close_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)

	local var_4_0 = arg_4_0:nodeByName("title"):getContentSize().width

	arg_4_0:nodeByName("left_hua"):setPositionX(arg_4_0:nodeByName("left_hua"):getPositionX() - (var_4_0 / 2 - 100))
	arg_4_0:nodeByName("right_hua"):setPositionX(arg_4_0:nodeByName("right_hua"):getPositionX() + (var_4_0 / 2 - 100))

	local var_4_1 = arg_4_0:createRuleLabel()
	local var_4_2 = display.newNode()
	local var_4_3 = arg_4_0.list:newItem()
	local var_4_4 = display.newNode()

	var_4_1:addTo(var_4_4)
	var_4_1:setAnchorPoint(cc.p(0, 0))
	var_4_1:setPosition(0, 0)
	var_4_4:setContentSize(700, var_4_1:getContentSize().height)
	var_4_4:addTo(var_4_2)
	var_4_2:setContentSize(700, var_4_1:getContentSize().height + 20)
	var_4_3:addContent(var_4_2)
	var_4_3:setItemSize(700, var_4_1:getContentSize().height + 20)
	arg_4_0.list:addItem(var_4_3)
	arg_4_0.list:reload()
end

function var_0_0.createRuleLabel(arg_6_0)
	local var_6_0 = var_0_1:translation("ACTIVITY_SAKURA2_RULE_TEXT")
	local var_6_1 = {
		size = 24,
		color = cc.c3b(255, 255, 255)
	}
	local var_6_2 = xyd.AssetLoader.get():loadLabel(var_6_1)

	var_6_2:setMaxLineWidth(700)
	var_6_2:setLineHeight(49)
	var_6_2:setString(var_6_0)

	return var_6_2
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
