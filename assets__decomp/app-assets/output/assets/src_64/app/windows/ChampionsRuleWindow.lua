local var_0_0 = class("ChampionsRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.RULE_CONTAINER = "rule_container"
var_0_0.RANK_CONTAINER = "rank_container"
var_0_0.AWARD_CONTAINER = "award_container"
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

local var_0_1 = 3
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.championsLeagueRankAward
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.crossArenaScheduleTable
local var_0_6 = import("app.common.ui.SplitLine")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.champions = xyd.ModelManager.get():loadModel(xyd.ModelType.CHAMPIONS_LEAGUE)
	arg_1_0.group = arg_1_2.group or 1
	arg_1_0.rank = arg_1_2.rank or 1
	arg_1_0.stage = arg_1_2.stage or 1
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

	arg_4_0:nodeByName("title"):setString(var_0_2:translation("CROSS_ARENA_RULE_TITLE"))

	local var_4_0 = arg_4_0.ruleContainer:getContentSize()

	arg_4_0.scrollView = cc.ui.UIScrollView.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_4_0.width + 10, var_4_0.height)
	}):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0):addTo(arg_4_0.ruleContainer)

	arg_4_0:addScrollView()
	arg_4_0:updateRank()

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
	arg_9_0.detailContainer = arg_9_0:nodeByName(var_0_0.DETAIL_CONTAINER)

	arg_9_0.ruleContainer:removeChild(arg_9_0.rankContainer)
	arg_9_0.ruleContainer:removeChild(arg_9_0.awardContainer)
	arg_9_0.ruleContainer:removeChild(arg_9_0.detailContainer)
	arg_9_0.rankContainer:addTo(var_9_0)
	arg_9_0.awardContainer:addTo(var_9_0)
	arg_9_0.detailContainer:addTo(var_9_0)
end

function var_0_0.updateRank(arg_10_0)
	if arg_10_0.stage == 1 then
		local var_10_0 = var_0_3:getItemsIdByInfo(arg_10_0.group, arg_10_0.rank)

		arg_10_0:addMyRankRewardItem(arg_10_0.awardContainer, var_10_0)

		local var_10_1 = xyd.tables.translation:translation("CHAMPIONS_RULE_TEXT_" .. arg_10_0.group)
		local var_10_2 = string.format(xyd.tables.translation:translation("CHAMPIONS_RULE_TEXT_4"), var_10_1, arg_10_0.rank)

		arg_10_0:addSection(arg_10_0.rankContainer, 8, 0, var_10_2)
		arg_10_0:addDetail()

		local var_10_3 = arg_10_0.awardContainer:getContentSize().height
		local var_10_4 = arg_10_0.rankContainer:getContentSize().height
		local var_10_5 = arg_10_0.detailContainer:getContentSize().height

		arg_10_0.rankContainer:setPosition(cc.p(0, var_10_3 + var_10_5))
		arg_10_0.awardContainer:setPosition(cc.p(0, var_10_5))
		arg_10_0.detailContainer:setPosition(cc.p(0, -40))

		local var_10_6 = {
			size = 710,
			offset = 5,
			align = xyd.SplitLineAlign.CENTER
		}
		local var_10_7 = var_0_6.new(var_10_6)

		var_10_7:addTo(arg_10_0.awardContainer)
		var_10_7:setPosition(360, -65)

		local var_10_8 = xyd.ServerTime.get():getServerTime()
		local var_10_9 = 0
		local var_10_10 = 0

		if arg_10_0.champions.seasonCount then
			var_10_9 = var_0_5:time(arg_10_0.champions.seasonCount)
			var_10_10 = var_0_5:time(arg_10_0.champions.seasonCount + 1) - 3
		end

		local var_10_11 = math.floor(var_10_9 / 10000)
		local var_10_12 = math.floor(var_10_9 % 10000 / 100)
		local var_10_13 = var_10_9 % 100
		local var_10_14 = var_10_11 .. "Y" .. var_10_12 .. "M" .. var_10_13 .. "D"
		local var_10_15 = math.floor(var_10_10 / 10000)
		local var_10_16 = math.floor(var_10_10 % 10000 / 100)
		local var_10_17 = var_10_10 % 100
		local var_10_18 = var_10_15 .. "Y" .. var_10_16 .. "M" .. var_10_17 .. "D"
		local var_10_19 = {
			size = 22,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			color = cc.c3b(79, 42, 12),
			text = xyd.tables.translation:translation("CHAMPIONS_RULE_TEXT_9") .. var_10_14 .. "-" .. var_10_18
		}
		local var_10_20 = xyd.AssetLoader.get():loadLabel(var_10_19)

		var_10_20:addTo(arg_10_0.awardContainer)
		var_10_20:setAnchorPoint(cc.p(0, 0))
		var_10_20:setPosition(5, -40)

		local var_10_21 = arg_10_0.scrollView:getViewRect()

		arg_10_0.scrollView.scrollWidth = var_10_21.width
		arg_10_0.scrollView.scrollHeight = var_10_4 + var_10_3 + var_10_5 + 40

		arg_10_0.scrollView:scrollTo(0, var_10_21.height - var_10_4 - var_10_3 - var_10_5 - 40)
	else
		arg_10_0:addDetail()

		local var_10_22 = arg_10_0.awardContainer:getContentSize().height
		local var_10_23 = arg_10_0.detailContainer:getContentSize().height

		arg_10_0.awardContainer:setPosition(cc.p(0, var_10_23))
		arg_10_0.detailContainer:setPosition(cc.p(0, 0))

		local var_10_24 = {
			size = 720,
			offset = 5,
			align = xyd.SplitLineAlign.CENTER
		}
		local var_10_25 = var_0_6.new(var_10_24)

		var_10_25:addTo(arg_10_0.awardContainer)
		var_10_25:setPosition(360, 0)

		local var_10_26 = arg_10_0.scrollView:getViewRect()

		arg_10_0.scrollView.scrollWidth = var_10_26.width
		arg_10_0.scrollView.scrollHeight = var_10_22 + var_10_23

		arg_10_0.scrollView:scrollTo(0, var_10_26.height - var_10_22 - var_10_23 - 20)
	end
end

function var_0_0.addMyRankRewardItem(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = #arg_11_2.ids
	local var_11_1 = 10

	if arg_11_2.crystal and arg_11_2.crystal > 0 then
		local var_11_2 = xyd.AssetLoader.get():loadSprite("images/icon/eco/yuanbao.png")

		var_11_2:setScale(0.8)
		var_11_2:addTo(arg_11_1)
		var_11_2:setAnchorPoint(cc.p(0, 0.5))
		var_11_2:setPosition(var_11_1, 15)

		var_11_1 = var_11_1 + 60

		local var_11_3 = {
			size = 24,
			color = cc.c3b(54, 52, 55)
		}
		local var_11_4 = xyd.AssetLoader.get():loadLabel(var_11_3)

		var_11_4:setString("x" .. arg_11_2.crystal)
		var_11_4:addTo(arg_11_1)
		var_11_4:setAnchorPoint(cc.p(0, 0.5))
		var_11_4:setPosition(var_11_1, 15)

		var_11_1 = var_11_1 + 110
	end

	for iter_11_0 = 1, var_11_0 do
		if arg_11_2.ids[iter_11_0] == 50002072 then
			local var_11_5 = "windows/champions_league/icon_cube.png"
			local var_11_6 = xyd.AssetLoader.get():loadSprite(var_11_5)

			var_11_6:setScale(0.8)
			var_11_6:addTo(arg_11_1)
			var_11_6:setAnchorPoint(cc.p(0, 0.5))
			var_11_6:setPosition(var_11_1, 15)
		else
			local var_11_7 = display.newNode()

			var_11_7:setContentSize(50, 50)
			var_11_7:setAnchorPoint(cc.p(0, 0.5))
			var_11_7:setPosition(var_11_1, 15)
			xyd.setItemAndAddTips(var_11_7, arg_11_2.ids[iter_11_0])
			var_11_7:addTo(arg_11_1)
		end

		var_11_1 = var_11_1 + 60

		local var_11_8 = {
			size = 24,
			color = cc.c3b(54, 52, 55)
		}
		local var_11_9 = xyd.AssetLoader.get():loadLabel(var_11_8)

		var_11_9:setString("x" .. arg_11_2.nums[iter_11_0])
		var_11_9:addTo(arg_11_1)
		var_11_9:setAnchorPoint(cc.p(0, 0.5))
		var_11_9:setPosition(var_11_1, 10)

		var_11_1 = var_11_1 + 90
	end
end

function var_0_0.addRewardItem(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	local var_12_0
	local var_12_1
	local var_12_2 = var_0_3:getItems(1)

	if arg_12_2 == 1 then
		var_12_1 = string.format(var_0_2:translation("ARENA_RULE_ITEM_TITLE_1"), arg_12_2)
	else
		local var_12_3 = var_12_2.range[arg_12_2 - 1]
		local var_12_4 = var_12_2.range[arg_12_2]

		if var_12_4 - var_12_3 > 1 then
			var_12_1 = string.format(var_0_2:translation("ARENA_RULE_ITEM_TITLE_2"), var_12_3 + 1, var_12_4)
		else
			var_12_1 = string.format(var_0_2:translation("ARENA_RULE_ITEM_TITLE_1"), var_12_4)
		end
	end

	local var_12_5 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = arg_12_3,
		y = arg_12_4,
		color = cc.c3b(68, 69, 77),
		dimensions = cc.size(780, 0),
		text = var_12_1
	}
	local var_12_6 = xyd.AssetLoader.get():loadLabel(var_12_5)

	var_12_6:addTo(arg_12_1)
	var_12_6:setAnchorPoint(cc.p(0, 0))

	local var_12_7 = var_0_3:getItems(arg_12_0.group)
	local var_12_8 = var_12_7.ids[arg_12_2]
	local var_12_9 = var_12_7.nums[arg_12_2]
	local var_12_10 = #var_12_8
	local var_12_11 = 470 - (var_12_10 + 1) * 70
	local var_12_12 = var_12_7.crystal[arg_12_2]

	if var_12_12 and var_12_12 > 0 then
		local var_12_13 = xyd.AssetLoader.get():loadSprite("images/icon/eco/yuanbao.png")

		var_12_13:setScale(0.8)
		var_12_13:addTo(arg_12_1)
		var_12_13:setAnchorPoint(cc.p(0, 0.5))
		var_12_13:setPosition(var_12_11, arg_12_4 + 15)

		var_12_11 = var_12_11 + 60

		local var_12_14 = {
			size = 24,
			color = cc.c3b(54, 52, 55)
		}
		local var_12_15 = xyd.AssetLoader.get():loadLabel(var_12_14)

		var_12_15:setString("x" .. var_12_12)
		var_12_15:addTo(arg_12_1)
		var_12_15:setAnchorPoint(cc.p(0, 0.5))
		var_12_15:setPosition(var_12_11, arg_12_4 + 15)

		var_12_11 = var_12_11 + 110
	else
		var_12_11 = var_12_11 + 170
	end

	for iter_12_0 = 1, var_12_10 do
		if var_12_8[iter_12_0] == 50002072 then
			local var_12_16 = "windows/champions_league/icon_cube.png"
			local var_12_17 = xyd.AssetLoader.get():loadSprite(var_12_16)

			var_12_17:setScale(0.8)
			var_12_17:addTo(arg_12_1)
			var_12_17:setAnchorPoint(cc.p(0, 0.5))
			var_12_17:setPosition(var_12_11, arg_12_4 + 15)

			var_12_11 = var_12_11 + 60
		else
			local var_12_18 = display.newNode()

			var_12_18:setContentSize(50, 50)
			var_12_18:setAnchorPoint(cc.p(0, 0.5))
			var_12_18:setPosition(var_12_11, arg_12_4 + 15)
			xyd.setItemAndAddTips(var_12_18, var_12_8[iter_12_0])
			var_12_18:addTo(arg_12_1)

			var_12_11 = var_12_11 + 60
		end

		local var_12_19 = {
			size = 24,
			color = cc.c3b(54, 52, 55)
		}
		local var_12_20 = xyd.AssetLoader.get():loadLabel(var_12_19)

		var_12_20:setString("x" .. var_12_9[iter_12_0])
		var_12_20:addTo(arg_12_1)
		var_12_20:setAnchorPoint(cc.p(0, 0.5))
		var_12_20:setPosition(var_12_11, arg_12_4 + 15)

		var_12_11 = var_12_11 + 80
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
	local var_14_2 = var_14_0:getChildByName("text_rule3")

	var_14_0:removeAllChildren()

	local var_14_3 = 0
	local var_14_4 = var_14_3 + arg_14_0:addSection(var_14_0, 50, var_14_3, "……") * 26 + 20
	local var_14_5 = xyd.tables.arenaReward:ids()

	for iter_14_0 = 10, 1, -1 do
		local var_14_6 = var_14_5[iter_14_0]

		arg_14_0:addRewardItem(var_14_0, var_14_6, 8, var_14_4)

		var_14_4 = var_14_4 + 60
	end

	arg_14_0:addSection(var_14_0, 400, var_14_4, var_0_2:translation("CHAMPIONS_RULE_TEXT_" .. arg_14_0.group))

	local var_14_7 = var_14_4 + 46 + 40
	local var_14_8 = var_14_7 + arg_14_0:addSection(var_14_0, 8, var_14_7, var_0_2:translation("CHAMPIONS_RULE_TEXT_8")) * 22 + 20

	var_14_2:addTo(var_14_0)
	var_14_2:setString(var_0_2:translation("CHAMPIONS_RULE_TEXT_7"))
	var_14_2:setPosition(cc.p(8, var_14_8))

	local var_14_9 = var_14_8 + 40
	local var_14_10 = var_14_9 + arg_14_0:addSection(var_14_0, 8, var_14_9, var_0_2:translation("CHAMPIONS_RULE_TEXT_6")) * 30 + 20

	var_14_1:addTo(var_14_0)
	var_14_1:setString(var_0_2:translation("CHAMPIONS_RULE_TEXT_5"))
	var_14_1:setPosition(cc.p(8, var_14_10))
	var_14_0:height(var_14_10 + 40)
end

return var_0_0
