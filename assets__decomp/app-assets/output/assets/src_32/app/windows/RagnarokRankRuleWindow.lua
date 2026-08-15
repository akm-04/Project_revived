local var_0_0 = class("RagnarokRankRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.ruleStyle
local var_0_3 = xyd.tables.ragnarokRank
local var_0_4 = 814
local var_0_5 = 547

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.titleName = arg_1_2.title_name
	arg_1_0.rule = arg_1_2.rule
	arg_1_0.style = arg_1_2.style or xyd.RuleStyle.YELLOW
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
	local var_4_0 = var_0_2:res(arg_4_0.style)
	local var_4_1 = var_0_2:capInsets(arg_4_0.style)
	local var_4_2 = display.newScale9Sprite(var_4_0, 0, 0, cc.size(var_0_4, var_0_5), cc.rect(var_4_1[1], var_4_1[2], var_4_1[3], var_4_1[4]))
	local var_4_3 = arg_4_0:nodeByName("container")

	var_4_2:addTo(var_4_3, -1)
	var_4_2:setPosition(var_4_3:getWidth() / 2, var_4_3:getHeight() / 2)

	arg_4_0.container = arg_4_0:nodeByName("detail_container")

	local var_4_4 = arg_4_0.container:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_4_4.width + 20, var_4_4.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_4_0.container):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0:nodeByName("title_text"):setString(var_0_1:translation(arg_4_0.titleName))
	arg_4_0:nodeByName("title_text"):setColor(xyd.convertHex2RGB(var_0_2:titleColor(arg_4_0.style)))
	arg_4_0:initRule()
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevX_ = arg_5_1.x
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" and 5 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.initRule(arg_6_0)
	local var_6_0 = xyd.split(var_0_1:translation(arg_6_0.rule), "\n")

	for iter_6_0 = 1, #var_6_0 do
		local var_6_1 = display.newNode()
		local var_6_2 = arg_6_0.list:newItem()
		local var_6_3 = display.newNode()
		local var_6_4 = {
			size = 22,
			color = xyd.convertHex2RGB(var_0_2:textColor(arg_6_0.style)),
			dimensions = cc.size(714, 0),
			text = var_6_0[iter_6_0]
		}
		local var_6_5 = xyd.AssetLoader.get():loadLabel(var_6_4)

		var_6_5:addTo(var_6_3)
		var_6_5:setAnchorPoint(cc.p(0, 0))
		var_6_5:setPosition(cc.p(0, 0))

		local var_6_6 = var_6_5:getContentSize().height

		var_6_3:setContentSize(734, var_6_6)
		var_6_3:addTo(var_6_1)
		var_6_1:setContentSize(734, var_6_6 + 20)
		var_6_2:addContent(var_6_1)
		var_6_2:setItemSize(734, var_6_6 + 20)
		arg_6_0.list:addItem(var_6_2)
	end

	arg_6_0:updateRewardItem("RAGNAROK_BOSS_RANK_5", var_0_3:carryRange(), var_0_3:carryGift())
	arg_6_0:updateRewardItem("RAGNAROK_BOSS_RANK_6", var_0_3:scoreRange(), var_0_3:scoreGift())
	arg_6_0.list:reload()
end

function var_0_0.updateRewardItem(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = arg_7_0.list:newItem()
	local var_7_1 = {
		size = 24,
		color = cc.c3b(210, 84, 16)
	}
	local var_7_2 = xyd.AssetLoader.get():loadLabel(var_7_1)

	var_7_2:setMaxLineWidth(714)
	var_7_2:setString(var_0_1:translation(arg_7_1))
	var_7_0:addContent(var_7_2)
	var_7_0:setItemSize(734, var_7_2:getContentSize().height + 40)
	arg_7_0.list:addItem(var_7_0)

	for iter_7_0 = 1, #arg_7_2 do
		local var_7_3 = arg_7_0.list:newItem()
		local var_7_4 = display.newNode()

		var_7_4:setContentSize(734, 80)

		local var_7_5 = arg_7_2[iter_7_0 - 1]
		local var_7_6 = arg_7_2[iter_7_0]
		local var_7_7 = {
			size = 24,
			color = cc.c3b(54, 52, 55)
		}
		local var_7_8 = xyd.AssetLoader.get():loadLabel(var_7_7)

		if not var_7_5 or var_7_6 - var_7_5 == 1 then
			local var_7_9 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_7_6)

			var_7_8:setString(var_7_9)
		else
			local var_7_10 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_7_5 + 1, var_7_6)

			var_7_8:setString(var_7_10)
		end

		var_7_8:addTo(var_7_4)
		var_7_8:setAnchorPoint(cc.p(0, 0.5))
		var_7_8:setPosition(100, 40)

		local var_7_11 = arg_7_3[iter_7_0]
		local var_7_12 = xyd.tables.gift:items(var_7_11)
		local var_7_13 = xyd.tables.gift:itemNum(var_7_11)
		local var_7_14 = 0

		for iter_7_1 = 1, #var_7_12 do
			local var_7_15 = display.newNode()

			var_7_15:setContentSize(60, 60)
			xyd.setItemAndAddTips(var_7_15, var_7_12[iter_7_1])
			var_7_15:addTo(var_7_4)
			var_7_15:setAnchorPoint(cc.p(0.5, 0.5))
			var_7_15:setPosition(350 + var_7_14 * 130, 40)

			local var_7_16 = {
				size = 24,
				color = cc.c3b(54, 52, 55)
			}
			local var_7_17 = xyd.AssetLoader.get():loadLabel(var_7_16)

			var_7_17:setString("x" .. var_7_13[iter_7_1])
			var_7_17:addTo(var_7_4)
			var_7_17:setAnchorPoint(cc.p(0, 0.5))
			var_7_17:setPosition(390 + var_7_14 * 130, 40)

			var_7_14 = var_7_14 + 1
		end

		local var_7_18 = xyd.tables.gift:crystal(var_7_11)

		if var_7_18 and var_7_18 > 0 then
			local var_7_19 = display.newNode()

			var_7_19:setContentSize(60, 60)
			xyd.setItemAndAddTips(var_7_19, -1)
			var_7_19:addTo(var_7_4)
			var_7_19:setAnchorPoint(cc.p(0.5, 0.5))
			var_7_19:setPosition(350 + var_7_14 * 130, 40)

			local var_7_20 = {
				size = 24,
				color = cc.c3b(54, 52, 55)
			}
			local var_7_21 = xyd.AssetLoader.get():loadLabel(var_7_20)

			var_7_21:setString("x" .. var_7_18)
			var_7_21:addTo(var_7_4)
			var_7_21:setAnchorPoint(cc.p(0, 0.5))
			var_7_21:setPosition(390 + var_7_14 * 130, 40)

			local var_7_22 = var_7_14 + 1
		end

		var_7_3:addContent(var_7_4)
		var_7_3:setItemSize(734, 80)
		arg_7_0.list:addItem(var_7_3)
	end
end

return var_0_0
