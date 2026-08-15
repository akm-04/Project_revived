local var_0_0 = class("ArenaModeRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.RULE_CONTAINER = "rule_container"
var_0_0.RANK_CONTAINER = "rank_container"
var_0_0.AWARD_CONTAINER = "award_container"
var_0_0.DETAIL_CONTAINER = "detail_container"
var_0_0.TEXT_RANK = "text_rank"
var_0_0.TEXT_CRYSTAL = "text_crystal"
var_0_0.TEXT_GOLD = "text_gold"
var_0_0.IMAGE_SHELL = "shell"
var_0_0.IMAGE_GOLD = "gold"

local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.arenaModeReward

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.modeType = arg_1_2.modeType
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

	local var_4_0 = arg_4_0.ruleContainer:getContentSize()

	arg_4_0.scrollView = cc.ui.UIScrollView.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height)
	}):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0):addTo(arg_4_0.ruleContainer)

	arg_4_0:addScrollView()
	arg_4_0:updateRank()

	arg_4_0.closeButton = arg_4_0:nodeByName("close_btn")

	xyd.nodeEventSample(arg_4_0.closeButton, nil, function(arg_5_0)
		xyd.WindowManager.get():closeWindow(arg_4_0)
	end)
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 5 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end

	local var_6_0 = arg_6_0.scrollView:getScrollNode()
	local var_6_1 = 0
	local var_6_2 = -(var_6_0:getCascadeBoundingBox().height - var_6_0:getContentSize().height)

	if var_6_1 < var_6_0:getPositionX() then
		arg_6_0.scrollView:scrollTo(0, var_6_1)
	elseif var_6_2 > var_6_0:getPositionX() then
		arg_6_0.scrollView:scrollTo(0, var_6_2)
	end
end

function var_0_0.addScrollView(arg_7_0)
	local var_7_0 = cc.Node:create()

	arg_7_0.scrollView:addScrollNode(var_7_0)

	arg_7_0.rankContainer = arg_7_0:nodeByName(var_0_0.RANK_CONTAINER)
	arg_7_0.awardContainer = arg_7_0:nodeByName(var_0_0.AWARD_CONTAINER)
	arg_7_0.detailContainer = arg_7_0:nodeByName(var_0_0.DETAIL_CONTAINER)

	arg_7_0.ruleContainer:removeChild(arg_7_0.rankContainer)
	arg_7_0.ruleContainer:removeChild(arg_7_0.awardContainer)
	arg_7_0.ruleContainer:removeChild(arg_7_0:nodeByName("high_rank_container"))
	arg_7_0.ruleContainer:removeChild(arg_7_0.detailContainer)
	arg_7_0.rankContainer:addTo(var_7_0)
	arg_7_0.awardContainer:addTo(var_7_0)
	arg_7_0.detailContainer:addTo(var_7_0)
end

function var_0_0.updateRank(arg_8_0)
	local var_8_0 = var_0_2:getID(arg_8_0.rank)

	arg_8_0:addRewardItem(arg_8_0.awardContainer, true, var_8_0, 0, 0)

	local var_8_1 = var_0_2:range(var_8_0)
	local var_8_2 = var_0_2:range(var_8_0 + 1)
	local var_8_3 = var_0_2:range(var_8_0 - 1)
	local var_8_4

	if var_8_2 == 0 then
		var_8_4 = string.format(var_0_1:translation("RULE_RANK_TEXT"), arg_8_0.rank, var_8_1, 50000)
	elseif var_8_1 == var_8_3 + 1 then
		var_8_4 = string.format(var_0_1:translation("RULE_RANK_TEXT2"), arg_8_0.rank, arg_8_0.rank)
	else
		var_8_4 = string.format(var_0_1:translation("RULE_RANK_TEXT"), arg_8_0.rank, var_8_3, var_8_1)
	end

	arg_8_0:addSection(arg_8_0.rankContainer, 8, 0, var_8_4)
	arg_8_0:addDetail()

	local var_8_5 = arg_8_0.awardContainer:getContentSize().height
	local var_8_6 = arg_8_0.rankContainer:getContentSize().height
	local var_8_7 = arg_8_0.detailContainer:getContentSize().height

	arg_8_0.rankContainer:setPosition(cc.p(0, var_8_5 + var_8_7))
	arg_8_0.awardContainer:setPosition(cc.p(0, var_8_7))
	arg_8_0.detailContainer:setPosition(cc.p(0, 0))

	local var_8_8 = arg_8_0.scrollView:getViewRect()

	arg_8_0.scrollView.scrollWidth = var_8_8.width
	arg_8_0.scrollView.scrollHeight = var_8_6 + var_8_5 + var_8_7

	arg_8_0.scrollView:scrollTo(0, var_8_8.height - var_8_6 - var_8_5 - var_8_7 - 20)
end

function var_0_0.addRewardItem(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	local var_9_0 = 0

	if not arg_9_2 then
		local var_9_1
		local var_9_2 = var_0_2:range(arg_9_3)

		if arg_9_3 == 1 then
			var_9_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_9_2)
		else
			local var_9_3 = var_0_2:range(arg_9_3 - 1)

			if var_9_2 - var_9_3 > 1 then
				var_9_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_9_3, var_9_2)
			else
				var_9_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_9_2)
			end
		end

		local var_9_4 = {
			size = 22,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = arg_9_4,
			y = arg_9_5,
			color = cc.c3b(68, 69, 77),
			dimensions = cc.size(780, 0),
			text = var_9_1
		}
		local var_9_5 = xyd.AssetLoader.get():loadLabel(var_9_4)

		var_9_5:addTo(arg_9_1)
		var_9_5:setAnchorPoint(cc.p(0, 0))

		var_9_0 = 70
	end

	local var_9_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rule/mode_rule_reward_item.csb")

	var_9_6:addTo(arg_9_1)
	print("offsetX:" .. var_9_0)
	var_9_6:setPosition(arg_9_4 + var_9_0, arg_9_5 - 5)
	var_9_6:setAnchorPoint(cc.p(0, 0))

	local var_9_7 = var_0_2:dailyMana(arg_9_3)
	local var_9_8 = var_0_2:dailyItem(arg_9_3)
	local var_9_9 = var_0_2:dailyItemNum(arg_9_3)
	local var_9_10 = var_9_6:getChildByName("container")

	if var_9_7 > 0 then
		var_9_10:getChildByName("text_gold"):setString(var_9_7)
	else
		var_9_10:getChildByName("text_gold"):setVisible(false)
		var_9_10:getChildByName("gold"):setVisible(false)
	end

	for iter_9_0, iter_9_1 in ipairs(var_9_8) do
		xyd.setItemBorder(var_9_10:getChildByName("item" .. iter_9_0), iter_9_1)
		var_9_10:getChildByName("text_item" .. iter_9_0):setString("x" .. var_9_9[iter_9_0])
	end
end

function var_0_0.addSection(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = arg_10_2,
		y = arg_10_3,
		color = cc.c3b(68, 69, 77),
		dimensions = cc.size(710, 0),
		text = arg_10_4
	}
	local var_10_1 = 0
	local var_10_2 = xyd.AssetLoader.get():loadLabel(var_10_0)

	var_10_2:addTo(arg_10_1)
	var_10_2:setAnchorPoint(cc.p(0, 0))

	return (var_10_2:getStringNumLines())
end

function var_0_0.addDetail(arg_11_0)
	local var_11_0 = arg_11_0.detailContainer
	local var_11_1 = var_11_0:getChildByName("text_rule1")
	local var_11_2 = var_11_0:getChildByName("text_rule2")
	local var_11_3 = var_11_0:getChildByName("text_rule3")

	var_11_0:removeAllChildren()

	local var_11_4 = 0
	local var_11_5 = var_11_4 + arg_11_0:addSection(var_11_0, 50, var_11_4, "……") * 26 + 20
	local var_11_6 = var_0_2:ids()

	for iter_11_0 = 6, 1, -1 do
		local var_11_7 = var_11_6[iter_11_0]

		arg_11_0:addRewardItem(var_11_0, false, var_11_7, 8, var_11_5)

		var_11_5 = var_11_5 + 60
	end

	local var_11_8 = var_11_5 + arg_11_0:addSection(var_11_0, 8, var_11_5, var_0_1:translation("ARENA_RULE_TEXT_8")) * 26 + 20

	var_11_3:addTo(var_11_0)
	var_11_3:setString(var_0_1:translation("ARENA_RULE_TEXT_7"))
	var_11_3:setPosition(cc.p(8, var_11_8))

	local var_11_9 = var_11_8 + 40

	var_11_2:removeSelf()

	local var_11_10 = var_11_9 + arg_11_0:addSection(var_11_0, 8, var_11_9, xyd.tables.arenaMode:rule(arg_11_0.modeType)) * 26 + 20

	var_11_1:addTo(var_11_0)
	var_11_1:setString(string.format(var_0_1:translation("ARENA_MODE_RULE_TITLE"), xyd.tables.arenaMode:title(arg_11_0.modeType)))
	var_11_1:setPosition(cc.p(8, var_11_10))
	var_11_0:height(var_11_10 + 40)
end

return var_0_0
