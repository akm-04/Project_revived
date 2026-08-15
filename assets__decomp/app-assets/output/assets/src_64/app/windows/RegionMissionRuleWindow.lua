local var_0_0 = class("RegionMissionRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.RULE_CONTAINER = "rule_container"
var_0_0.RANK_CONTAINER = "rank_container"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
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
	arg_4_0.closeButton = arg_4_0:nodeByName("close")

	arg_4_0.closeButton:setLocalZOrder(10)
	arg_4_0:addScrollView()
	arg_4_0:update()
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevX_ = arg_5_1.x
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" and 5 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
		arg_5_0.scrollViewMoved_ = true
	end

	local var_5_0 = arg_5_0.scrollView:getScrollNode()
	local var_5_1 = 0
	local var_5_2 = -(var_5_0:getCascadeBoundingBox().height - var_5_0:getContentSize().height)

	if var_5_1 < var_5_0:getPositionX() then
		arg_5_0.scrollView:scrollTo(0, var_5_1)
	elseif var_5_2 > var_5_0:getPositionX() then
		arg_5_0.scrollView:scrollTo(0, var_5_2)
	end
end

function var_0_0.addScrollView(arg_6_0)
	local var_6_0 = cc.Node:create()

	arg_6_0.scrollView:addScrollNode(var_6_0)

	arg_6_0.rankContainer = arg_6_0:nodeByName(var_0_0.RANK_CONTAINER)

	arg_6_0.ruleContainer:removeChild(arg_6_0.rankContainer)
	arg_6_0.rankContainer:addTo(var_6_0)
end

function var_0_0.update(arg_7_0)
	arg_7_0:addDetail()

	local var_7_0 = arg_7_0.rankContainer:getContentSize().height
	local var_7_1 = arg_7_0.scrollView:getViewRect()

	arg_7_0.scrollView.scrollWidth = var_7_1.width
	arg_7_0.scrollView.scrollHeight = var_7_0

	arg_7_0.scrollView:scrollTo(0, 0)
end

function var_0_0.addSection(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = arg_8_2,
		y = arg_8_3,
		color = cc.c3b(68, 69, 77),
		dimensions = cc.size(700, 0),
		text = arg_8_4
	}
	local var_8_1 = 0
	local var_8_2 = xyd.AssetLoader.get():loadLabel(var_8_0)

	var_8_2:addTo(arg_8_1)
	var_8_2:setAnchorPoint(cc.p(0, 1))

	return (var_8_2:getStringNumLines())
end

function var_0_0.addDetail(arg_9_0)
	local var_9_0 = arg_9_0:nodeByName("rank_container")

	var_9_0:removeAllChildren()

	local var_9_1 = arg_9_0:addSection(var_9_0, 26, 0, var_0_1:translation("REGION_ARENA_RULE3"))
end

return var_0_0
