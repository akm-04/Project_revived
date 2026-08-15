local var_0_0 = class("FlappyBirdRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.TITLE = "title_text"
var_0_0.DETAIL_CONTAINER = "detail_container"

local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.ruleStyle
local var_0_3 = 814
local var_0_4 = 547
local var_0_5 = xyd.tables.flappyBirdAward

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.titleName = arg_1_2.title_name
	arg_1_0.rule = arg_1_2.rule
	arg_1_0.style = arg_1_2.style or xyd.RuleStyle.BLUE

	if arg_1_2.split then
		arg_1_0.split = arg_1_2.split
	end

	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.willClose(arg_4_0)
	if arg_4_0.callback then
		arg_4_0.callback()
	end
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = var_0_2:res(arg_5_0.style)
	local var_5_1 = var_0_2:capInsets(arg_5_0.style)
	local var_5_2 = display.newScale9Sprite(var_5_0, 0, 0, cc.size(var_0_3, var_0_4), cc.rect(var_5_1[1], var_5_1[2], var_5_1[3], var_5_1[4]))
	local var_5_3 = arg_5_0:nodeByName("container")

	var_5_2:addTo(var_5_3, -1)
	var_5_2:setPosition(var_5_3:getWidth() / 2, var_5_3:getHeight() / 2)

	arg_5_0.container = arg_5_0:nodeByName(var_0_0.DETAIL_CONTAINER)

	local var_5_4 = arg_5_0.container:getContentSize()

	arg_5_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_5_4.width, var_5_4.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_5_0.container):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0:nodeByName(var_0_0.TITLE):setString(var_0_1:translation(arg_5_0.titleName))
	arg_5_0:nodeByName(var_0_0.TITLE):setColor(xyd.convertHex2RGB(var_0_2:titleColor(arg_5_0.style)))
	arg_5_0:initRule()
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 5 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.initRule(arg_7_0)
	local var_7_0

	if not arg_7_0.split then
		var_7_0 = xyd.split(var_0_1:translation(arg_7_0.rule), "\n")
	else
		var_7_0 = xyd.split(var_0_1:translation(arg_7_0.rule), arg_7_0.split)
	end

	for iter_7_0 = 1, #var_7_0 do
		local var_7_1 = display.newNode()
		local var_7_2 = arg_7_0.list:newItem()
		local var_7_3 = display.newNode()
		local var_7_4 = {
			size = 22,
			color = xyd.convertHex2RGB(var_0_2:textColor(arg_7_0.style)),
			dimensions = cc.size(714, 0),
			text = var_7_0[iter_7_0]
		}
		local var_7_5 = xyd.AssetLoader.get():loadLabel(var_7_4)

		var_7_5:addTo(var_7_3)
		var_7_5:setAnchorPoint(cc.p(0, 0))
		var_7_5:setPosition(cc.p(0, 0))

		local var_7_6 = var_7_5:getContentSize().height

		var_7_3:setContentSize(714, var_7_6)
		var_7_3:addTo(var_7_1)
		var_7_1:setContentSize(714, var_7_6 + 20)
		var_7_2:addContent(var_7_1)
		var_7_2:setItemSize(714, var_7_6 + 20)
		arg_7_0.list:addItem(var_7_2)
	end

	arg_7_0:updateRewardItem()
	arg_7_0.list:reload()
end

function var_0_0.updateRewardItem(arg_8_0)
	local var_8_0 = arg_8_0.list:newItem()
	local var_8_1 = {
		size = 24,
		color = cc.c3b(210, 84, 16)
	}
	local var_8_2 = xyd.AssetLoader.get():loadLabel(var_8_1)

	var_8_2:setMaxLineWidth(714)
	var_8_2:setLineHeight(49)
	var_8_2:setString(var_0_1:translation("RANK_AWARD"))
	var_8_0:addContent(var_8_2)
	var_8_0:setItemSize(714, var_8_2:getContentSize().height + 20)
	arg_8_0.list:addItem(var_8_0)

	local var_8_3 = var_0_5:RewardCount()

	for iter_8_0 = 1, var_8_3 do
		local var_8_4 = arg_8_0.list:newItem()
		local var_8_5 = display.newNode()

		var_8_5:setContentSize(714, 80)

		local var_8_6 = var_0_5:range(iter_8_0 - 1)
		local var_8_7 = var_0_5:range(iter_8_0)
		local var_8_8 = {
			size = 24,
			color = cc.c3b(54, 52, 55)
		}
		local var_8_9 = xyd.AssetLoader.get():loadLabel(var_8_8)

		if var_8_6 == 0 or var_8_7 - var_8_6 == 1 then
			local var_8_10 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_8_7)

			var_8_9:setString(var_8_10)
		else
			local var_8_11 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_8_6 + 1, var_8_7)

			var_8_9:setString(var_8_11)
		end

		var_8_9:addTo(var_8_5)
		var_8_9:setAnchorPoint(cc.p(0, 0.5))
		var_8_9:setPosition(100, 40)

		local var_8_12 = var_0_5:gift(iter_8_0)
		local var_8_13 = xyd.tables.gift:items(var_8_12)
		local var_8_14 = xyd.tables.gift:itemNum(var_8_12)

		for iter_8_1 = 1, #var_8_13 do
			local var_8_15 = display.newNode()

			var_8_15:setContentSize(60, 60)
			xyd.setItemAndAddTips(var_8_15, var_8_13[iter_8_1])
			var_8_15:addTo(var_8_5)
			var_8_15:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_15:setPosition(350 + (iter_8_1 - 1) * 130, 40)

			local var_8_16 = {
				size = 24,
				color = cc.c3b(54, 52, 55)
			}
			local var_8_17 = xyd.AssetLoader.get():loadLabel(var_8_16)

			var_8_17:setString("x" .. var_8_14[iter_8_1])
			var_8_17:addTo(var_8_5)
			var_8_17:setAnchorPoint(cc.p(0, 0.5))
			var_8_17:setPosition(390 + (iter_8_1 - 1) * 130, 40)
		end

		var_8_4:addContent(var_8_5)
		var_8_4:setItemSize(714, 80)
		arg_8_0.list:addItem(var_8_4)
	end
end

return var_0_0
