local var_0_0 = class("IllusionRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.illusionAward

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.rank = arg_1_2.rank
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.rankContainer = arg_2_0:nodeByName("rank_container")
	arg_2_0.awardContainer = arg_2_0:nodeByName("award_container")
	arg_2_0.detailContainer = arg_2_0:nodeByName("detail_container")

	local var_2_0, var_2_1 = arg_2_0.detailContainer:getPosition()

	if arg_2_0.rank == 0 then
		arg_2_0.rankContainer:setVisible(false)
		arg_2_0.awardContainer:setVisible(false)
		arg_2_0.detailContainer:setPosition(var_2_0, var_2_1)
	else
		arg_2_0.detailContainer:setPosition(var_2_0, var_2_1 - 90)
	end

	arg_2_0:addScrollView()
	arg_2_0:updateRank()
	xyd.nodeEventSample(arg_2_0:nodeByName("close_btn"), nil, function()
		audio.playSound(xyd.tables.sound:getSound("ui_close_window"), false)
		xyd.WindowManager.get():closeWindow(arg_2_0)
	end)
	arg_2_0:nodeByName("title"):setString(var_0_1:translation("PARADISE_RULE_TITLE"))
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.addScrollView(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("container")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.scrollView = cc.ui.UIScrollView.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height)
	}):addTo(var_5_0):setBounceable(true):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	local var_5_2 = cc.Node:create()

	arg_5_0.scrollView:addScrollNode(var_5_2)
	var_5_0:removeChild(arg_5_0.rankContainer)
	var_5_0:removeChild(arg_5_0.awardContainer)
	var_5_0:removeChild(arg_5_0.detailContainer)
	arg_5_0.rankContainer:addTo(var_5_2)
	arg_5_0.awardContainer:addTo(var_5_2)
	arg_5_0.detailContainer:addTo(var_5_2)
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

function var_0_0.updateRank(arg_7_0)
	local var_7_0 = string.format(var_0_1:translation("PARADISE_RULE_RANK_TEXT"), arg_7_0.rank)

	arg_7_0:addSection(arg_7_0.rankContainer, 15, 0, var_7_0)

	local var_7_1 = var_0_2:getID(arg_7_0.rank)

	arg_7_0:addAwardItem(arg_7_0.awardContainer, true, var_7_1, 15, 0)
	arg_7_0:addDetail()
end

function var_0_0.addAwardItem(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
	local var_8_0 = 0

	if not arg_8_2 then
		local var_8_1
		local var_8_2 = var_0_2:range(arg_8_3)

		if arg_8_3 == 1 then
			var_8_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_8_2)
		else
			local var_8_3 = xyd.tables.arenaReward:range(arg_8_3 - 1)

			if var_8_2 - var_8_3 > 1 then
				var_8_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_8_3 + 1, var_8_2)
			else
				var_8_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_8_2)
			end
		end

		local var_8_4 = {
			size = 22,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = arg_8_4,
			y = arg_8_5,
			color = cc.c3b(68, 69, 77),
			dimensions = cc.size(780, 0),
			text = var_8_1
		}
		local var_8_5 = xyd.AssetLoader.get():loadLabel(var_8_4)

		var_8_5:addTo(arg_8_1)
		var_8_5:setAnchorPoint(cc.p(0, 0))

		var_8_0 = 150
	end

	local var_8_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/rule/illusion_rule_award.csb")

	var_8_6:addTo(arg_8_1)
	var_8_6:setPosition(arg_8_4 + var_8_0, arg_8_5 - 15)
	var_8_6:setAnchorPoint(cc.p(0, 0))

	local var_8_7 = var_8_6:getChildByName("container")

	var_8_7:getChildByName("IllusionCoin_icon"):getChildByName("IllusionCoin_num"):setString("x" .. var_0_2:illusionCoin(arg_8_3))

	local var_8_8 = var_0_2:item(arg_8_3)
	local var_8_9 = var_0_2:itemNum(arg_8_3)

	if #var_8_8 == 0 or var_8_8[1] == 0 then
		var_8_7:getChildByName("item1"):setVisible(false)
		var_8_7:getChildByName("item2"):setVisible(false)
	elseif #var_8_8 == 1 then
		local var_8_10 = var_8_7:getChildByName("item1")

		var_8_10:getChildByName("item1_num"):setString("x" .. var_8_9[1])
		xyd.setItemBorder(var_8_10, var_8_8[1])
		var_8_7:getChildByName("item2"):setVisible(false)
	elseif #var_8_8 == 2 then
		local var_8_11 = var_8_7:getChildByName("item1")

		var_8_11:getChildByName("item1_num"):setString("x" .. var_8_9[1])
		xyd.setItemBorder(var_8_11, var_8_8[1])

		local var_8_12 = var_8_7:getChildByName("item2")

		var_8_12:getChildByName("item2_num"):setString("x" .. var_8_9[2])
		xyd.setItemBorder(var_8_12, var_8_8[2])
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
		dimensions = cc.size(730, 0),
		text = arg_9_4
	}
	local var_9_1 = 0
	local var_9_2 = xyd.AssetLoader.get():loadLabel(var_9_0)

	var_9_2:addTo(arg_9_1)
	var_9_2:setAnchorPoint(cc.p(0, 0))

	return (var_9_2:getStringNumLines())
end

function var_0_0.addDetail(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("detail_container")
	local var_10_1 = var_10_0:getChildByName("rule_txt")
	local var_10_2 = var_10_0:getChildByName("award_txt")

	var_10_0:removeAllChildren()

	local var_10_3 = 0
	local var_10_4 = var_10_3 + arg_10_0:addSection(var_10_0, 50, var_10_3, "……") * 26 + 20
	local var_10_5 = var_0_2:ids()

	for iter_10_0 = 15, 1, -1 do
		local var_10_6 = var_10_5[iter_10_0]

		arg_10_0:addAwardItem(var_10_0, false, var_10_6, 26, var_10_4)

		var_10_4 = var_10_4 + 60
	end

	local var_10_7 = var_10_4 + arg_10_0:addSection(var_10_0, 15, var_10_4, var_0_1:translation("PARADISE_RULE_TEXT_8")) * 26 + 20

	var_10_2:addTo(var_10_0)
	var_10_2:setString(var_0_1:translation("PARADISE_RULE_TEXT_7"))
	var_10_2:setPosition(cc.p(15, var_10_7))

	local var_10_8 = var_10_7 + 40
	local var_10_9 = var_10_8 + arg_10_0:addSection(var_10_0, 15, var_10_8, var_0_1:translation("PARADISE_RULE_TEXT")) * 26 + 20

	var_10_0:height(var_10_9)
end

return var_0_0
