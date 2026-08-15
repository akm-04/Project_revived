local var_0_0 = class("RegionArenaRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.RULE_CONTAINER = "rule_container"
var_0_0.RANK_CONTAINER = "rank_container"
var_0_0.TEXT_GOLD = "text_gold"
var_0_0.TEXT_SHELL = "text_shell"
var_0_0.TEXT_ITEM1 = "text_item1"
var_0_0.TEXT_ITEM2 = "text_item2"
var_0_0.IMAGE_SHELL = "shell"
var_0_0.IMAGE_ITEM1 = "item1"
var_0_0.IMAGE_ITEM2 = "item2"
var_0_0.IMAGE_GOLD = "gold"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.rank = arg_1_2.rank or 0
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

	local var_4_1 = import("app.common.ui.SplitLine")
	local var_4_2 = arg_4_0:nodeByName("line")

	var_4_1.new({
		size = var_4_2:getWidth()
	}):addTo(var_4_2)

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

function var_0_0.addRewardItem(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = 0
	local var_8_1 = xyd.tables.peakArenaReward:range(arg_8_2)
	local var_8_2

	if xyd.tables.regionArenaAward:getLevel(arg_8_2) == xyd.tables.regionArenaLevel.level[#xyd.tables.regionArenaLevel.level] then
		var_8_2 = var_0_1:translation("REGION_ARENA_RULE6")
	else
		var_8_2 = "Lv." .. xyd.tables.regionArenaAward:getLevel(arg_8_2)
	end

	local var_8_3 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = arg_8_3,
		y = arg_8_4,
		color = cc.c3b(68, 69, 77),
		dimensions = cc.size(780, 0),
		text = var_8_2
	}
	local var_8_4 = xyd.AssetLoader.get():loadLabel(var_8_3)

	var_8_4:addTo(arg_8_1)
	var_8_4:setAnchorPoint(cc.p(0, 0))

	local var_8_5 = 100
	local var_8_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/rule_reward_item.csb")

	var_8_6:addTo(arg_8_1)
	var_8_6:setPosition(arg_8_3 + var_8_5, arg_8_4 - 15)
	var_8_6:setAnchorPoint(cc.p(0, 1))

	local var_8_7 = xyd.tables.regionArenaAward:getRegionMana(arg_8_2)
	local var_8_8 = xyd.tables.regionArenaAward:getRegionCoin(arg_8_2)
	local var_8_9 = xyd.tables.regionArenaAward:getRegionItem(arg_8_2)
	local var_8_10 = xyd.tables.regionArenaAward:getRegionItemNum(arg_8_2)
	local var_8_11 = math.min(#var_8_9, #var_8_10)
	local var_8_12 = var_8_11

	for iter_8_0 = 1, var_8_11 do
		if var_8_9[iter_8_0] <= 0 then
			var_8_12 = iter_8_0 - 1

			break
		end
	end

	local var_8_13 = var_8_6:getChildByName("container")

	if var_8_7 > 0 then
		var_8_13:getChildByName(var_0_0.TEXT_GOLD):setString(var_8_7)
	else
		var_8_13:getChildByName(var_0_0.TEXT_GOLD):setVisible(false)
		var_8_13:getChildByName(var_0_0.IMAGE_GOLD):setVisible(false)
	end

	if var_8_8 > 0 then
		var_8_13:getChildByName(var_0_0.TEXT_SHELL):setString("x" .. var_8_8)
	else
		var_8_13:getChildByName(var_0_0.TEXT_SHELL):setVisible(false)
		var_8_13:getChildByName(var_0_0.IMAGE_SHELL):setVisible(false)
	end

	if var_8_12 == 1 then
		var_8_13:getChildByName(var_0_0.TEXT_ITEM1):setString("x" .. var_8_10[1])
		xyd.setItemBorder(var_8_13:getChildByName(var_0_0.IMAGE_ITEM1), var_8_9[1])
		var_8_13:getChildByName(var_0_0.IMAGE_ITEM2):setVisible(false)
		var_8_13:getChildByName(var_0_0.TEXT_ITEM2):setVisible(false)
	elseif var_8_12 == 2 then
		var_8_13:getChildByName(var_0_0.TEXT_ITEM1):setString("x" .. var_8_10[1])
		var_8_13:getChildByName(var_0_0.TEXT_ITEM2):setString("x" .. var_8_10[2])
		xyd.setItemBorder(var_8_13:getChildByName(var_0_0.IMAGE_ITEM1), var_8_9[1])
		xyd.setItemBorder(var_8_13:getChildByName(var_0_0.IMAGE_ITEM2), var_8_9[2])
	else
		var_8_13:getChildByName(var_0_0.IMAGE_ITEM1):setVisible(false)
		var_8_13:getChildByName(var_0_0.TEXT_ITEM1):setVisible(false)
		var_8_13:getChildByName(var_0_0.IMAGE_ITEM2):setVisible(false)
		var_8_13:getChildByName(var_0_0.TEXT_ITEM2):setVisible(false)
	end
end

function var_0_0.addSection(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = arg_9_2,
		y = arg_9_3,
		color = cc.c3b(68, 69, 77),
		dimensions = cc.size(700, 0),
		text = arg_9_4
	}
	local var_9_1 = 0
	local var_9_2 = xyd.AssetLoader.get():loadLabel(var_9_0)

	var_9_2:addTo(arg_9_1)
	var_9_2:setAnchorPoint(cc.p(0, 1))

	return (var_9_2:getStringNumLines())
end

function var_0_0.addDetail(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("rank_container")
	local var_10_1 = arg_10_0:nodeByName("rank_desc")
	local var_10_2 = var_10_0:getChildByName("text_rule1")
	local var_10_3 = var_10_0:getChildByName("text_rule2")

	var_10_3:setVisible(false)
	var_10_1:setString(string.format(var_0_1:translation("REGION_ARENA_RULE1"), tostring(arg_10_0.rank)))

	local var_10_4 = var_10_2:getPositionY() - 30

	var_10_2:setString(var_0_1:translation("REGION_ARENA_RULE2"))

	local var_10_5 = var_10_4 - arg_10_0:addSection(var_10_0, 26, var_10_4, var_0_1:translation("REGION_ARENA_RULE3")) * 26 - 20

	var_10_3:setPositionY(var_10_5)

	local var_10_6 = var_10_5 - 190
	local var_10_7 = xyd.tables.peakArenaReward:ids()

	for iter_10_0 = 1, 6 do
		local var_10_8 = var_10_7[iter_10_0]

		arg_10_0:addRewardItem(var_10_0, var_10_8, 26, var_10_6)

		var_10_6 = var_10_6 - 60
	end

	local var_10_9 = arg_10_0:addSection(var_10_0, 50, var_10_6, "……")
end

return var_0_0
