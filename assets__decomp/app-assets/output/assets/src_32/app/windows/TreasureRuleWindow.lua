local var_0_0 = class("TreasureRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.RULE_CONTAINER = "rule_container"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("container")

	arg_2_0:setContentSize(var_2_0:getContentSize())
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.ruleContainer = arg_4_0:nodeByName(var_0_0.RULE_CONTAINER)

	local var_4_0 = arg_4_0.ruleContainer:getContentSize()

	arg_4_0.scrollView = cc.ui.UIScrollView.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height)
	}):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0):addTo(arg_4_0.ruleContainer)

	arg_4_0:addScrollView()

	arg_4_0.closeButton = arg_4_0:nodeByName("close")

	arg_4_0.closeButton:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.willClose(arg_6_0)
	return
end

function var_0_0.didClose(arg_7_0)
	return
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevX_ = arg_8_1.x
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 5 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.scrollViewMoved_ = true
	end

	local var_8_0 = arg_8_0.scrollView:getScrollNode()
	local var_8_1 = 0
	local var_8_2 = -(var_8_0:getCascadeBoundingBox().height - var_8_0:getContentSize().height)

	if var_8_1 < var_8_0:getPositionX() then
		arg_8_0.scrollView:scrollTo(0, var_8_1)
	elseif var_8_2 > var_8_0:getPositionX() then
		arg_8_0.scrollView:scrollTo(0, var_8_2)
	end
end

function var_0_0.addScrollView(arg_9_0)
	local var_9_0 = cc.Node:create()

	arg_9_0.scrollView:addScrollNode(var_9_0)

	arg_9_0.rulText = arg_9_0:nodeByName("rule_text")

	arg_9_0.ruleContainer:removeChild(arg_9_0.rulText)
	arg_9_0.rulText:addTo(var_9_0)
end

return var_0_0
