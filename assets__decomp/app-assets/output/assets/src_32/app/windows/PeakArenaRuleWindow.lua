local var_0_0 = class("PeakPeakArenaRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.RULE_CONTAINER = "rule_container"
var_0_0.RANK_CONTAINER = "rank_container"
var_0_0.AWARD_CONTAINER = "award_container"
var_0_0.DETAIL_CONTAINER = "detail_container"
var_0_0.RANK_CONTAINER1 = "rank_container1"
var_0_0.AWARD_CONTAINER1 = "award_container1"
var_0_0.TEXT_RANK = "text_rank"
var_0_0.TEXT_CRYSTAL = "text_crystal"
var_0_0.TEXT_GOLD = "text_gold"
var_0_0.TEXT_SHELL = "text_shell"
var_0_0.TEXT_ITEM1 = "text_item1"
var_0_0.TEXT_ITEM2 = "text_item2"
var_0_0.IMAGE_SHELL = "shell"
var_0_0.IMAGE_ITEM1 = "item1"
var_0_0.IMAGE_ITEM2 = "item2"
var_0_0.IMAGE_CRYSTAL = "crystal"
var_0_0.IMAGE_GOLD = "gold"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.myRank = arg_1_2.myRank
	arg_1_0.rank = arg_1_2.rank
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
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("TOP_PEAKARENARULEWINDOW_TEXT1"))

	arg_4_0.ruleContainer = arg_4_0:nodeByName(var_0_0.RULE_CONTAINER)

	local var_4_0 = arg_4_0.ruleContainer:getContentSize()

	arg_4_0.scrollView = cc.ui.UIScrollView.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height)
	}):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0):addTo(arg_4_0.ruleContainer)
	arg_4_0.closeButton = arg_4_0:nodeByName("close")

	arg_4_0.closeButton:setLocalZOrder(10)
	arg_4_0:addScrollView()
	arg_4_0:updateRank()
end

function var_0_0.willClose(arg_5_0)
	return
end

function var_0_0.didClose(arg_6_0)
	return
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 5 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end

	local var_7_0 = arg_7_0.scrollView:getScrollNode()
	local var_7_1 = 0
	local var_7_2 = -(var_7_0:getCascadeBoundingBox().height - var_7_0:getContentSize().height)

	if var_7_1 < var_7_0:getPositionX() then
		arg_7_0.scrollView:scrollTo(0, var_7_1)
	elseif var_7_2 > var_7_0:getPositionX() then
		arg_7_0.scrollView:scrollTo(0, var_7_2)
	end
end

function var_0_0.addScrollView(arg_8_0)
	local var_8_0 = cc.Node:create()

	arg_8_0.scrollView:addScrollNode(var_8_0)

	arg_8_0.rankContainer = arg_8_0:nodeByName(var_0_0.RANK_CONTAINER)
	arg_8_0.awardContainer = arg_8_0:nodeByName(var_0_0.AWARD_CONTAINER)
	arg_8_0.rankContainer1 = arg_8_0:nodeByName(var_0_0.RANK_CONTAINER1)
	arg_8_0.awardContainer1 = arg_8_0:nodeByName(var_0_0.AWARD_CONTAINER1)
	arg_8_0.detailContainer = arg_8_0:nodeByName(var_0_0.DETAIL_CONTAINER)

	arg_8_0.ruleContainer:removeChild(arg_8_0.rankContainer)
	arg_8_0.ruleContainer:removeChild(arg_8_0.awardContainer)
	arg_8_0.ruleContainer:removeChild(arg_8_0.rankContainer1)
	arg_8_0.ruleContainer:removeChild(arg_8_0.awardContainer1)
	arg_8_0.ruleContainer:removeChild(arg_8_0.detailContainer)
	arg_8_0.rankContainer:addTo(var_8_0)
	arg_8_0.awardContainer:addTo(var_8_0)
	arg_8_0.rankContainer1:addTo(var_8_0)
	arg_8_0.awardContainer1:addTo(var_8_0)
	arg_8_0.detailContainer:addTo(var_8_0)
end

function var_0_0.updateRank(arg_9_0)
	local var_9_0 = xyd.tables.peakArenaReward:getID(arg_9_0.myRank)

	arg_9_0:addRewardItem(arg_9_0.awardContainer, true, var_9_0, 0, 0)

	local var_9_1 = string.format(xyd.tables.translation:translation("PEAK_RULE_RANK_TEXT"), arg_9_0.myRank)

	arg_9_0:addSection(arg_9_0.rankContainer, 26, -10, var_9_1)
	arg_9_0:addDetail()

	local var_9_2 = arg_9_0.awardContainer:getContentSize().height
	local var_9_3 = arg_9_0.rankContainer:getContentSize().height
	local var_9_4 = arg_9_0.detailContainer:getContentSize().height

	arg_9_0.rankContainer:setPosition(cc.p(0, var_9_2 + var_9_4))
	arg_9_0.awardContainer:setPosition(cc.p(0, var_9_4))
	arg_9_0.detailContainer:setPosition(cc.p(0, 0))

	local var_9_5 = arg_9_0.scrollView:getViewRect()

	arg_9_0.scrollView.scrollWidth = var_9_5.width
	arg_9_0.scrollView.scrollHeight = var_9_3 + var_9_2 + var_9_4

	arg_9_0.scrollView:scrollTo(0, var_9_5.height - var_9_3 - var_9_2 - var_9_4)
end

function var_0_0.addRewardItem(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
	local var_10_0 = 0

	if not arg_10_2 then
		local var_10_1
		local var_10_2 = xyd.tables.peakArenaReward:range(arg_10_3)

		if arg_10_3 == 1 then
			var_10_1 = string.format(var_0_1:translation("PEAK_ARENA_RULE_ITEM_TITLE_1"), var_10_2)
		else
			local var_10_3 = xyd.tables.peakArenaReward:range(arg_10_3 - 1)

			if var_10_2 - var_10_3 > 1 then
				var_10_1 = string.format(var_0_1:translation("PEAK_ARENA_RULE_ITEM_TITLE_2"), var_10_3, var_10_2)
			else
				var_10_1 = string.format(var_0_1:translation("PEAK_ARENA_RULE_ITEM_TITLE_1"), var_10_2)
			end
		end

		local var_10_4 = {
			size = 22,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = arg_10_4,
			y = arg_10_5,
			color = cc.c3b(68, 69, 77),
			dimensions = cc.size(780, 0),
			text = var_10_1
		}
		local var_10_5 = xyd.AssetLoader.get():loadLabel(var_10_4)

		var_10_5:addTo(arg_10_1)
		var_10_5:setAnchorPoint(cc.p(0, 0))

		var_10_0 = 100
	end

	local var_10_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/rule/rule_reward_item.csb")

	var_10_6:addTo(arg_10_1)
	print("offsetX:" .. var_10_0)
	var_10_6:setPosition(arg_10_4 + var_10_0, arg_10_5 - 15)
	var_10_6:setAnchorPoint(cc.p(0, 0))

	local var_10_7 = xyd.tables.peakArenaReward:dailyCrystal(arg_10_3)
	local var_10_8 = xyd.tables.peakArenaReward:dailyMana(arg_10_3)
	local var_10_9 = xyd.tables.peakArenaReward:dailyArenaCoin(arg_10_3)
	local var_10_10 = xyd.tables.peakArenaReward:dailyItem(arg_10_3)
	local var_10_11 = xyd.tables.peakArenaReward:dailyItemNum(arg_10_3)
	local var_10_12 = math.min(#var_10_10, #var_10_11)
	local var_10_13 = var_10_12

	for iter_10_0 = 1, var_10_12 do
		if var_10_10[iter_10_0] <= 0 then
			var_10_13 = iter_10_0 - 1

			break
		end
	end

	local var_10_14 = var_10_6:getChildByName("container")

	if var_10_7 > 0 then
		var_10_14:getChildByName(var_0_0.TEXT_CRYSTAL):setString(var_10_7)
	else
		var_10_14:getChildByName(var_0_0.TEXT_CRYSTAL):setVisible(false)
		var_10_14:getChildByName(var_0_0.IMAGE_CRYSTAL):setVisible(false)
	end

	if var_10_8 > 0 then
		var_10_14:getChildByName(var_0_0.TEXT_GOLD):setString(var_10_8)
	else
		var_10_14:getChildByName(var_0_0.TEXT_GOLD):setVisible(false)
		var_10_14:getChildByName(var_0_0.IMAGE_GOLD):setVisible(false)
	end

	if var_10_9 > 0 then
		var_10_14:getChildByName(var_0_0.TEXT_SHELL):setString("x" .. var_10_9)
	else
		var_10_14:getChildByName(var_0_0.TEXT_SHELL):setVisible(false)
		var_10_14:getChildByName(var_0_0.IMAGE_SHELL):setVisible(false)
	end

	if var_10_13 == 1 then
		var_10_14:getChildByName(var_0_0.TEXT_ITEM1):setString("x" .. var_10_11[1])
		xyd.setItemBorder(var_10_14:getChildByName(var_0_0.IMAGE_ITEM1), var_10_10[1])
		var_10_14:getChildByName(var_0_0.IMAGE_ITEM2):setVisible(false)
		var_10_14:getChildByName(var_0_0.TEXT_ITEM2):setVisible(false)
	elseif var_10_13 == 2 then
		var_10_14:getChildByName(var_0_0.TEXT_ITEM1):setString("x" .. var_10_11[1])
		var_10_14:getChildByName(var_0_0.TEXT_ITEM2):setString("x" .. var_10_11[2])
		xyd.setItemBorder(var_10_14:getChildByName(var_0_0.IMAGE_ITEM1), var_10_10[1])
		xyd.setItemBorder(var_10_14:getChildByName(var_0_0.IMAGE_ITEM2), var_10_10[2])
	else
		var_10_14:getChildByName(var_0_0.IMAGE_ITEM1):setVisible(false)
		var_10_14:getChildByName(var_0_0.TEXT_ITEM1):setVisible(false)
		var_10_14:getChildByName(var_0_0.IMAGE_ITEM2):setVisible(false)
		var_10_14:getChildByName(var_0_0.TEXT_ITEM2):setVisible(false)
	end
end

function var_0_0.addRewardItem1(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5)
	local var_11_0 = 0

	if not arg_11_2 then
		local var_11_1
		local var_11_2 = xyd.tables.legendKuafuGift:rank(arg_11_3)

		if arg_11_3 == 1 then
			var_11_1 = string.format(var_0_1:translation("PEAK_ARENA_RULE_ITEM_TITLE_1"), var_11_2)
		else
			local var_11_3 = xyd.tables.peakArenaReward:range(arg_11_3 - 1)

			if var_11_2 - var_11_3 > 1 then
				var_11_1 = string.format(var_0_1:translation("PEAK_ARENA_RULE_ITEM_TITLE_2"), var_11_3, var_11_2)
			else
				var_11_1 = string.format(var_0_1:translation("PEAK_ARENA_RULE_ITEM_TITLE_1"), var_11_2)
			end
		end

		local var_11_4 = {
			size = 22,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = arg_11_4,
			y = arg_11_5,
			color = cc.c3b(68, 69, 77),
			dimensions = cc.size(780, 0),
			text = var_11_1
		}
		local var_11_5 = xyd.AssetLoader.get():loadLabel(var_11_4)

		var_11_5:addTo(arg_11_1)
		var_11_5:setAnchorPoint(cc.p(0, 0))

		var_11_0 = 100
	end

	local var_11_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/rule/rule_reward_item.csb")

	var_11_6:addTo(arg_11_1)
	print("offsetX:" .. var_11_0)
	var_11_6:setPosition(arg_11_4 + var_11_0, arg_11_5 - 15)
	var_11_6:setAnchorPoint(cc.p(0, 0))

	local var_11_7 = xyd.tables.legendKuafuGift:crystal(arg_11_3)
	local var_11_8 = xyd.tables.legendKuafuGift:mana(arg_11_3)
	local var_11_9 = var_11_6:getChildByName("container")

	if var_11_7 > 0 then
		var_11_9:getChildByName(var_0_0.TEXT_CRYSTAL):setString(var_11_7)
	else
		var_11_9:getChildByName(var_0_0.TEXT_CRYSTAL):setVisible(false)
		var_11_9:getChildByName(var_0_0.IMAGE_CRYSTAL):setVisible(false)
	end

	if var_11_8 > 0 then
		var_11_9:getChildByName(var_0_0.TEXT_GOLD):setString(var_11_8)
	else
		var_11_9:getChildByName(var_0_0.TEXT_GOLD):setVisible(false)
		var_11_9:getChildByName(var_0_0.IMAGE_GOLD):setVisible(false)
	end

	var_11_9:getChildByName(var_0_0.TEXT_SHELL):setVisible(false)
	var_11_9:getChildByName(var_0_0.IMAGE_SHELL):setVisible(false)
	var_11_9:getChildByName(var_0_0.IMAGE_ITEM1):setVisible(false)
	var_11_9:getChildByName(var_0_0.TEXT_ITEM1):setVisible(false)
	var_11_9:getChildByName(var_0_0.IMAGE_ITEM2):setVisible(false)
	var_11_9:getChildByName(var_0_0.TEXT_ITEM2):setVisible(false)
end

function var_0_0.addSection(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	local var_12_0 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = arg_12_2,
		y = arg_12_3,
		color = cc.c3b(68, 69, 77),
		dimensions = cc.size(730, 0),
		text = arg_12_4
	}
	local var_12_1 = 0
	local var_12_2 = xyd.AssetLoader.get():loadLabel(var_12_0)

	var_12_2:addTo(arg_12_1)
	var_12_2:setAnchorPoint(cc.p(0, 0))
	var_12_2:setLineHeight(30)

	return (var_12_2:getStringNumLines())
end

function var_0_0.addDetail(arg_13_0)
	local var_13_0 = arg_13_0:nodeByName("detail_container")
	local var_13_1 = var_13_0:getChildByName("text_rule1")
	local var_13_2 = var_13_0:getChildByName("text_rule2")
	local var_13_3 = var_13_0:getChildByName("text_rule3")

	var_13_0:removeAllChildren()

	local var_13_4 = 0
	local var_13_5 = var_13_4 + arg_13_0:addSection(var_13_0, 50, var_13_4, "……") * 30 + 30
	local var_13_6 = xyd.tables.peakArenaReward:ids()

	for iter_13_0 = 6, 1, -1 do
		local var_13_7 = var_13_6[iter_13_0]

		arg_13_0:addRewardItem(var_13_0, false, var_13_7, 26, var_13_5)

		var_13_5 = var_13_5 + 60
	end

	local var_13_8 = var_13_5 + arg_13_0:addSection(var_13_0, 26, var_13_5, var_0_1:translation("PEAK_ARENA_RULE_TEXT_8")) * 30 + 30

	var_13_3:addTo(var_13_0)
	var_13_3:setString(var_0_1:translation("PEAK_ARENA_RULE_TEXT_7"))
	var_13_3:setPosition(cc.p(26, var_13_8))

	local var_13_9 = var_13_8 + 40
	local var_13_10 = var_13_9 + arg_13_0:addSection(var_13_0, 26, var_13_9, var_0_1:translation("LEGEND_ARENA_RULE_TEXT")) * 30 + 30

	var_13_2:addTo(var_13_0)
	var_13_2:setString(var_0_1:translation("LEGEND_ARENA_RULE_TITLE"))
	var_13_2:setPosition(cc.p(26, var_13_10))

	local var_13_11 = var_13_10 + 40
	local var_13_12 = var_13_11 + arg_13_0:addSection(var_13_0, 26, var_13_11, var_0_1:translation("PEAK_ARENA_RULE_TEXT_4")) * 30 + 30

	var_13_1:addTo(var_13_0)
	var_13_1:setString(var_0_1:translation("PEAK_ARENA_RULE_TEXT_3"))
	var_13_1:setPosition(cc.p(26, var_13_12))
	var_13_0:height(var_13_12 + 40)
end

return var_0_0
