local var_0_0 = class("ArenaRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.RULE_CONTAINER = "rule_container"
var_0_0.RANK_CONTAINER = "rank_container"
var_0_0.AWARD_CONTAINER = "award_container"
var_0_0.HIGH_RANK_CONTAINER = "high_rank_container"
var_0_0.DETAIL_CONTAINER = "detail_container"
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
var_0_0.N5 = "n5"
var_0_0.N4 = "n4"
var_0_0.N3 = "n3"
var_0_0.N2 = "n2"
var_0_0.N1 = "n1"

local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SplitLine")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.bestRank = arg_1_2.bestRank or arg_1_2.rank
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
	arg_4_0.ruleContainer = arg_4_0:nodeByName(var_0_0.RULE_CONTAINER)

	arg_4_0:nodeByName("text_rank"):setString(var_0_1:translation("ARENA_RULE_TEXT_2"))
	arg_4_0:nodeByName("title"):setString(var_0_1:translation("ARENA_RULE_WINDOW_TITLE"))

	local var_4_0 = arg_4_0.ruleContainer:getContentSize()

	arg_4_0.scrollView = cc.ui.UIScrollView.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height)
	}):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0):addTo(arg_4_0.ruleContainer)

	arg_4_0:addScrollView()
	arg_4_0:updateRank()
	arg_4_0:updateBestRank()

	arg_4_0.closeButton = arg_4_0:nodeByName("close_btn")

	xyd.nodeEventSample(arg_4_0.closeButton, nil, function(arg_5_0)
		xyd.WindowManager.get():closeWindow(arg_4_0)
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

	arg_9_0.rankContainer = arg_9_0:nodeByName(var_0_0.RANK_CONTAINER)
	arg_9_0.awardContainer = arg_9_0:nodeByName(var_0_0.AWARD_CONTAINER)
	arg_9_0.highRankContainer = arg_9_0:nodeByName(var_0_0.HIGH_RANK_CONTAINER)
	arg_9_0.detailContainer = arg_9_0:nodeByName(var_0_0.DETAIL_CONTAINER)

	arg_9_0.ruleContainer:removeChild(arg_9_0.rankContainer)
	arg_9_0.ruleContainer:removeChild(arg_9_0.awardContainer)
	arg_9_0.ruleContainer:removeChild(arg_9_0.highRankContainer)
	arg_9_0.ruleContainer:removeChild(arg_9_0.detailContainer)
	arg_9_0.rankContainer:addTo(var_9_0)
	arg_9_0.awardContainer:addTo(var_9_0)
	arg_9_0.highRankContainer:addTo(var_9_0)
	arg_9_0.detailContainer:addTo(var_9_0)
end

function var_0_0.updateRank(arg_10_0)
	local var_10_0 = xyd.tables.arenaReward:getID(arg_10_0.rank)

	arg_10_0:addRewardItem(arg_10_0.awardContainer, true, var_10_0, 0, 0)

	local var_10_1 = xyd.tables.arenaReward:range(var_10_0)
	local var_10_2 = xyd.tables.arenaReward:range(var_10_0 + 1)
	local var_10_3 = xyd.tables.arenaReward:range(var_10_0 - 1)
	local var_10_4

	if var_10_2 == 0 then
		var_10_4 = string.format(xyd.tables.translation:translation("RULE_RANK_TEXT"), arg_10_0.rank, var_10_1, 50000)
	elseif var_10_1 == var_10_3 + 1 then
		var_10_4 = string.format(xyd.tables.translation:translation("RULE_RANK_TEXT2"), arg_10_0.rank, arg_10_0.rank)
	else
		var_10_4 = string.format(xyd.tables.translation:translation("RULE_RANK_TEXT"), arg_10_0.rank, var_10_3, var_10_1)
	end

	arg_10_0:addSection(arg_10_0.rankContainer, 8, 0, var_10_4)
	arg_10_0:addDetail()

	local var_10_5 = arg_10_0.awardContainer:getContentSize().height
	local var_10_6 = arg_10_0.rankContainer:getContentSize().height
	local var_10_7 = arg_10_0.highRankContainer:getContentSize().height
	local var_10_8 = arg_10_0.detailContainer:getContentSize().height

	arg_10_0.rankContainer:setPosition(cc.p(0, var_10_5 + var_10_8 + var_10_7))
	arg_10_0.awardContainer:setPosition(cc.p(0, var_10_8 + var_10_7))
	arg_10_0.highRankContainer:setPosition(cc.p(0, var_10_8))
	arg_10_0.detailContainer:setPosition(cc.p(0, 0))

	local var_10_9 = {
		size = 720,
		offset = 5,
		align = xyd.SplitLineAlign.CENTER
	}
	local var_10_10 = var_0_2.new(var_10_9)

	var_10_10:addTo(arg_10_0.highRankContainer)
	var_10_10:setPosition(360, -15)

	local var_10_11 = arg_10_0.scrollView:getViewRect()

	arg_10_0.scrollView.scrollWidth = var_10_11.width
	arg_10_0.scrollView.scrollHeight = var_10_6 + var_10_5 + var_10_7 + var_10_8

	arg_10_0.scrollView:scrollTo(0, var_10_11.height - var_10_6 - var_10_5 - var_10_7 - var_10_8 - 20)
end

function var_0_0.updateBestRank(arg_11_0)
	local var_11_0, var_11_1 = arg_11_0:nodeByName("best_rank_pos"):getPosition()

	arg_11_0.rankLabel = xyd.colorNumLabel(arg_11_0.bestRank, "yellow1")

	local var_11_2 = arg_11_0:nodeByName("high_rank_container")

	arg_11_0.rankLabel:addTo(var_11_2)
	arg_11_0.rankLabel:setPosition(var_11_0, var_11_1)
	arg_11_0.rankLabel:setAnchorPoint(cc.p(0, 0.5))
end

function var_0_0.addRewardItem(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5)
	local var_12_0 = 0

	if not arg_12_2 then
		local var_12_1
		local var_12_2 = xyd.tables.arenaReward:range(arg_12_3)

		if arg_12_3 == 1 then
			var_12_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_12_2)
		else
			local var_12_3 = xyd.tables.arenaReward:range(arg_12_3 - 1)

			if var_12_2 - var_12_3 > 1 then
				var_12_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_12_3, var_12_2)
			else
				var_12_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_12_2)
			end
		end

		local var_12_4 = {
			size = 22,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = arg_12_4,
			y = arg_12_5,
			color = cc.c3b(68, 69, 77),
			dimensions = cc.size(780, 0),
			text = var_12_1
		}
		local var_12_5 = xyd.AssetLoader.get():loadLabel(var_12_4)

		var_12_5:addTo(arg_12_1)
		var_12_5:setAnchorPoint(cc.p(0, 0))

		var_12_0 = 70
	end

	local var_12_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rule/rule_reward_item.csb")

	var_12_6:addTo(arg_12_1)
	print("offsetX:" .. var_12_0)
	var_12_6:setPosition(arg_12_4 + var_12_0, arg_12_5 - 15)
	var_12_6:setAnchorPoint(cc.p(0, 0))

	local var_12_7 = xyd.tables.arenaReward:dailyCrystal(arg_12_3)
	local var_12_8 = xyd.tables.arenaReward:dailyMana(arg_12_3)
	local var_12_9 = xyd.tables.arenaReward:dailyArenaCoin(arg_12_3)
	local var_12_10 = xyd.tables.arenaReward:dailyItem(arg_12_3)
	local var_12_11 = xyd.tables.arenaReward:dailyItemNum(arg_12_3)
	local var_12_12 = math.min(#var_12_10, #var_12_11)
	local var_12_13 = var_12_12

	for iter_12_0 = 1, var_12_12 do
		if var_12_10[iter_12_0] <= 0 then
			var_12_13 = iter_12_0 - 1

			break
		end
	end

	local var_12_14 = var_12_6:getChildByName("container")

	if var_12_7 > 0 then
		var_12_14:getChildByName(var_0_0.TEXT_CRYSTAL):setString(var_12_7)
	else
		var_12_14:getChildByName(var_0_0.TEXT_CRYSTAL):setVisible(false)
		var_12_14:getChildByName(var_0_0.IMAGE_CRYSTAL):setVisible(false)
	end

	if var_12_8 > 0 then
		var_12_14:getChildByName(var_0_0.TEXT_GOLD):setString(var_12_8)
	else
		var_12_14:getChildByName(var_0_0.TEXT_GOLD):setVisible(false)
		var_12_14:getChildByName(var_0_0.IMAGE_GOLD):setVisible(false)
	end

	if var_12_9 > 0 then
		var_12_14:getChildByName(var_0_0.TEXT_SHELL):setString("x" .. var_12_9)
	else
		var_12_14:getChildByName(var_0_0.TEXT_SHELL):setVisible(false)
		var_12_14:getChildByName(var_0_0.IMAGE_SHELL):setVisible(false)
	end

	if var_12_13 == 1 then
		var_12_14:getChildByName(var_0_0.TEXT_ITEM1):setString("x" .. var_12_11[1])
		xyd.setItemBorder(var_12_14:getChildByName(var_0_0.IMAGE_ITEM1), var_12_10[1])
		var_12_14:getChildByName(var_0_0.IMAGE_ITEM2):setVisible(false)
		var_12_14:getChildByName(var_0_0.TEXT_ITEM2):setVisible(false)
	elseif var_12_13 == 2 then
		var_12_14:getChildByName(var_0_0.TEXT_ITEM1):setString("x" .. var_12_11[1])
		var_12_14:getChildByName(var_0_0.TEXT_ITEM2):setString("x" .. var_12_11[2])
		xyd.setItemBorder(var_12_14:getChildByName(var_0_0.IMAGE_ITEM1), var_12_10[1])
		xyd.setItemBorder(var_12_14:getChildByName(var_0_0.IMAGE_ITEM2), var_12_10[2])
	else
		var_12_14:getChildByName(var_0_0.IMAGE_ITEM1):setVisible(false)
		var_12_14:getChildByName(var_0_0.TEXT_ITEM1):setVisible(false)
		var_12_14:getChildByName(var_0_0.IMAGE_ITEM2):setVisible(false)
		var_12_14:getChildByName(var_0_0.TEXT_ITEM2):setVisible(false)
	end
end

function var_0_0.addSection(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = arg_13_2,
		y = arg_13_3,
		color = cc.c3b(68, 69, 77),
		dimensions = cc.size(710, 0),
		text = arg_13_4
	}
	local var_13_1 = 0
	local var_13_2 = xyd.AssetLoader.get():loadLabel(var_13_0)

	var_13_2:addTo(arg_13_1)
	var_13_2:setAnchorPoint(cc.p(0, 0))

	return (var_13_2:getStringNumLines())
end

function var_0_0.addDetail(arg_14_0)
	local var_14_0 = arg_14_0:nodeByName("detail_container")
	local var_14_1 = var_14_0:getChildByName("text_rule1")
	local var_14_2 = var_14_0:getChildByName("text_rule2")
	local var_14_3 = var_14_0:getChildByName("text_rule3")

	var_14_0:removeAllChildren()

	local var_14_4 = 0
	local var_14_5 = var_14_4 + arg_14_0:addSection(var_14_0, 50, var_14_4, "……") * 26 + 20
	local var_14_6 = xyd.tables.arenaReward:ids()

	for iter_14_0 = 6, 1, -1 do
		local var_14_7 = var_14_6[iter_14_0]

		arg_14_0:addRewardItem(var_14_0, false, var_14_7, 8, var_14_5)

		var_14_5 = var_14_5 + 60
	end

	local var_14_8 = var_14_5 + arg_14_0:addSection(var_14_0, 8, var_14_5, var_0_1:translation("ARENA_RULE_TEXT_8")) * 26 + 20

	var_14_3:addTo(var_14_0)
	var_14_3:setString(var_0_1:translation("ARENA_RULE_TEXT_7"))
	var_14_3:setPosition(cc.p(8, var_14_8))

	local var_14_9 = var_14_8 + 40
	local var_14_10 = var_14_9 + arg_14_0:addSection(var_14_0, 8, var_14_9, var_0_1:translation("ARENA_RULE_TEXT_6")) * 26 + 20

	var_14_2:addTo(var_14_0)
	var_14_2:setString(var_0_1:translation("ARENA_RULE_TEXT_5"))
	var_14_2:setPosition(cc.p(8, var_14_10))

	local var_14_11 = var_14_10 + 40
	local var_14_12 = var_14_11 + arg_14_0:addSection(var_14_0, 8, var_14_11, var_0_1:translation("ARENA_RULE_TEXT_4")) * 29 + 20

	var_14_1:addTo(var_14_0)
	var_14_1:setString(var_0_1:translation("ARENA_RULE_TEXT_3"))
	var_14_1:setPosition(cc.p(8, var_14_12))
	var_14_0:height(var_14_12 + 40)
end

return var_0_0
