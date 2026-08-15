local var_0_0 = class("NewTextRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.TITLE = "title_text"
var_0_0.DETAIL_CONTAINER = "detail_container"

local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.ruleStyle
local var_0_3 = 814
local var_0_4 = 547

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.titleName = arg_1_2.title_name
	arg_1_0.rule = arg_1_2.rule
	arg_1_0.style = arg_1_2.style or xyd.RuleStyle.YELLOW
	arg_1_0.giftIds = arg_1_2.giftIds or nil
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

	if arg_7_0.giftIds then
		arg_7_0:updateRewardItem()
	end

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
	var_8_2:setString(var_0_1:translation("OUTING_RULE_CIRCLE_TITLE"))
	var_8_0:addContent(var_8_2)
	var_8_0:setItemSize(714, var_8_2:getContentSize().height + 20)
	arg_8_0.list:addItem(var_8_0)

	for iter_8_0 = #arg_8_0.giftIds, 1, -1 do
		local var_8_3 = arg_8_0.list:newItem()
		local var_8_4 = display.newNode()

		var_8_4:setContentSize(714, 80)

		local var_8_5 = 0
		local var_8_6 = {
			size = 24,
			color = cc.c3b(54, 52, 55)
		}
		local var_8_7 = xyd.AssetLoader.get():loadLabel(var_8_6)
		local var_8_8

		if iter_8_0 then
			var_8_8 = string.format(var_0_1:translation("OUTING_RULE_CIRCLE_ITEM"), iter_8_0)
		else
			var_8_8 = string.format(var_0_1:translation("OUTING_RULE_CIRCLE_FULL"))
		end

		var_8_7:setString(var_8_8)
		var_8_7:addTo(var_8_4)
		var_8_7:setAnchorPoint(cc.p(0, 0.5))
		var_8_7:setPosition(var_8_5, 40)

		local var_8_9 = var_8_5 + 150
		local var_8_10 = arg_8_0.giftIds[iter_8_0]
		local var_8_11 = xyd.tables.gift:crystal(var_8_10)

		if var_8_11 >= 0 then
			local var_8_12 = "images/icon/eco/icon_crystal.png"
			local var_8_13 = xyd.AssetLoader.get():loadSprite(var_8_12)

			var_8_13:setScale(0.8)
			var_8_13:addTo(var_8_4)
			var_8_13:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_13:setPosition(var_8_9, 40)

			local var_8_14 = {
				size = 24,
				color = cc.c3b(54, 52, 55)
			}
			local var_8_15 = xyd.AssetLoader.get():loadLabel(var_8_14)

			var_8_15:setString("x" .. var_8_11)
			var_8_15:addTo(var_8_4)
			var_8_15:setAnchorPoint(cc.p(0, 0.5))
			var_8_15:setPosition(var_8_9 + 20, 40)

			var_8_9 = var_8_9 + 100
		end

		local var_8_16 = xyd.tables.gift:mana(var_8_10)

		if var_8_16 >= 0 then
			local var_8_17 = "images/icon/eco/icon_coin.png"
			local var_8_18 = xyd.AssetLoader.get():loadSprite(var_8_17)

			var_8_18:setScale(0.8)
			var_8_18:addTo(var_8_4)
			var_8_18:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_18:setPosition(var_8_9, 40)

			local var_8_19 = {
				size = 24,
				color = cc.c3b(54, 52, 55)
			}
			local var_8_20 = xyd.AssetLoader.get():loadLabel(var_8_19)

			var_8_20:setString("x" .. var_8_16)
			var_8_20:addTo(var_8_4)
			var_8_20:setAnchorPoint(cc.p(0, 0.5))
			var_8_20:setPosition(var_8_9 + 20, 40)

			var_8_9 = var_8_9 + 160
		end

		local var_8_21 = xyd.tables.gift:items(var_8_10)
		local var_8_22 = xyd.tables.gift:itemNum(var_8_10)

		for iter_8_1 = 1, #var_8_21 do
			local var_8_23 = display.newNode()

			var_8_23:setContentSize(60, 60)
			xyd.setItemAndAddTips(var_8_23, var_8_21[iter_8_1])
			var_8_23:addTo(var_8_4)
			var_8_23:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_23:setPosition(var_8_9, 40)

			local var_8_24 = {
				size = 24,
				color = cc.c3b(54, 52, 55)
			}
			local var_8_25 = xyd.AssetLoader.get():loadLabel(var_8_24)

			var_8_25:setString("x" .. var_8_22[iter_8_1])
			var_8_25:addTo(var_8_4)
			var_8_25:setAnchorPoint(cc.p(0, 0.5))
			var_8_25:setPosition(var_8_9 + 40, 40)

			var_8_9 = var_8_9 + 120
		end

		var_8_3:addContent(var_8_4)
		var_8_3:setItemSize(714, 80)
		arg_8_0.list:addItem(var_8_3)
	end
end

return var_0_0
