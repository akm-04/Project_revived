local var_0_0 = class("RuleRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.redPacketsRankAward

function var_0_0.willOpen(arg_1_0, arg_1_1)
	arg_1_0.ruleContainer = arg_1_0:nodeByName("rule_container")

	local var_1_0 = arg_1_0.ruleContainer:getContentSize()

	arg_1_0.scrollView = cc.ui.UIScrollView.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_1_0.width, var_1_0.height)
	}):onScroll(handler(arg_1_0, arg_1_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0):addTo(arg_1_0.ruleContainer)

	arg_1_0:addScrollView()
	arg_1_0:updateAward()
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 5 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.addScrollView(arg_4_0)
	local var_4_0 = cc.Node:create()

	arg_4_0.scrollView:addScrollNode(var_4_0)

	arg_4_0.detailContainer = arg_4_0:nodeByName("detail_container")

	arg_4_0.ruleContainer:removeChild(arg_4_0.detailContainer)
	arg_4_0.detailContainer:addTo(var_4_0)
end

function var_0_0.updateAward(arg_5_0)
	arg_5_0:addDetail()

	local var_5_0 = arg_5_0.detailContainer:getContentSize().height

	arg_5_0.detailContainer:setPosition(cc.p(0, 0))

	local var_5_1 = arg_5_0.scrollView:getViewRect()

	arg_5_0.scrollView.scrollWidth = var_5_1.width
	arg_5_0.scrollView.scrollHeight = var_5_0

	arg_5_0.scrollView:scrollTo(0, var_5_1.height - var_5_0 - 20)
end

function var_0_0.addRewardItem(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = 0
	local var_6_1 = var_0_2:rank(arg_6_2)
	local var_6_2 = string.format(var_0_1:translation("RED_ENVELOPE_RULE_REWARD_RANK"), var_6_1[1], var_6_1[2])
	local var_6_3 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = arg_6_3,
		y = arg_6_4,
		color = cc.c3b(220, 220, 200),
		dimensions = cc.size(780, 0),
		text = var_6_2
	}
	local var_6_4 = xyd.AssetLoader.get():loadLabel(var_6_3)

	var_6_4:addTo(arg_6_1)
	var_6_4:setAnchorPoint(cc.p(0, 0))

	local var_6_5 = 100
	local var_6_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/red_envelope/rank_award_item.csb")

	var_6_6:addTo(arg_6_1)
	var_6_6:setPosition(arg_6_3 + var_6_5, arg_6_4 - 15)
	var_6_6:setAnchorPoint(cc.p(0, 0))

	local var_6_7 = xyd.tables.gift:crystal(giftID)
	local var_6_8 = xyd.tables.gift:mana(giftID)
	local var_6_9 = var_0_2:itemId(arg_6_2)
	local var_6_10 = var_0_2:itemNum(arg_6_2)
	local var_6_11 = var_6_6:getChildByName("container")

	for iter_6_0, iter_6_1 in ipairs(var_6_9) do
		xyd.setItemBorder(var_6_11:getChildByName("item" .. iter_6_0), iter_6_1)
		var_6_11:getChildByName("text_item" .. iter_6_0):setString("x" .. var_6_10[iter_6_0])
	end
end

function var_0_0.addSection(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = arg_7_2,
		y = arg_7_3,
		color = cc.c3b(220, 220, 200),
		dimensions = cc.size(730, 0),
		text = arg_7_4
	}
	local var_7_1 = 0
	local var_7_2 = xyd.AssetLoader.get():loadLabel(var_7_0)

	var_7_2:addTo(arg_7_1)
	var_7_2:setAnchorPoint(cc.p(0, 0))

	return (var_7_2:getStringNumLines())
end

function var_0_0.addDetail(arg_8_0)
	local var_8_0 = arg_8_0.detailContainer
	local var_8_1 = var_8_0:getChildByName("text_rule2")

	var_8_0:removeAllChildren()

	local var_8_2 = 0

	for iter_8_0 = var_0_2:count(), 1, -1 do
		arg_8_0:addRewardItem(var_8_0, iter_8_0, 26, var_8_2)

		var_8_2 = var_8_2 + 60
	end

	var_8_1:addTo(var_8_0)
	var_8_1:setString(var_0_1:translation("RED_ENVELOPE_RULE_REWARD_TEXT"))
	var_8_1:setPosition(cc.p(26, var_8_2))

	local var_8_3 = var_8_2 + 40

	lines = arg_8_0:addSection(var_8_0, 26, var_8_3, var_0_1:translation("RED_ENVELOPE_RULE_TEXT"))

	local var_8_4 = var_8_3 + lines * 26 + 20

	var_8_0:height(var_8_4)
end

return var_0_0
