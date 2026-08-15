local var_0_0 = class("TextRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.TITLE = "title_text"
var_0_0.DETAIL_CONTAINER = "detail_container"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.titleName = arg_1_2.title_name
	arg_1_0.rule = arg_1_2.rule

	if arg_1_2.split then
		arg_1_0.split = arg_1_2.split
	end

	arg_1_0.callback = arg_1_2.callback
	arg_1_0.hasOtherItem = arg_1_2.hasOtherItem
	arg_1_0.otherItemType = arg_1_2.otherItemType
	arg_1_0.awardTable = arg_1_2.award
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
	arg_5_0.container = arg_5_0:nodeByName(var_0_0.DETAIL_CONTAINER)

	local var_5_0 = arg_5_0.container:getContentSize()

	arg_5_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_5_0.container):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0:nodeByName(var_0_0.TITLE):setString(var_0_1:translation(arg_5_0.titleName))
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
			size = 24,
			color = cc.c3b(255, 255, 255),
			dimensions = cc.size(720, 0),
			text = var_7_0[iter_7_0]
		}
		local var_7_5 = xyd.AssetLoader.get():loadLabel(var_7_4)

		var_7_5:addTo(var_7_3)
		var_7_5:setAnchorPoint(cc.p(0, 0))
		var_7_5:setPosition(cc.p(0, 0))

		local var_7_6 = var_7_5:getContentSize().height

		var_7_3:setContentSize(720, var_7_6)
		var_7_3:addTo(var_7_1)
		var_7_1:setContentSize(720, var_7_6 + 20)
		var_7_2:addContent(var_7_1)
		var_7_2:setItemSize(720, var_7_6 + 20)
		arg_7_0.list:addItem(var_7_2)
	end

	if arg_7_0.hasOtherItem then
		arg_7_0:createOtherItem()
	end

	arg_7_0.list:reload()
end

function var_0_0.createOtherItem(arg_8_0)
	if arg_8_0.otherItemType == xyd.TextRuleItemType.Popularity then
		arg_8_0:createPopularityItem()
	elseif arg_8_0.otherItemType == xyd.TextRuleItemType.Award then
		arg_8_0:updateRewardItem()
	end
end

function var_0_0.createPopularityItem(arg_9_0)
	local var_9_0 = arg_9_0.list:newItem()
	local var_9_1 = display.newNode()
	local var_9_2 = {
		100006,
		100007
	}

	for iter_9_0 = 1, #var_9_2 do
		local var_9_3 = var_9_2[iter_9_0]
		local var_9_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_main/list_title.csb")
		local var_9_5 = var_9_4:getChildByName("container")
		local var_9_6 = var_9_5:getContentSize()

		var_9_4:addTo(var_9_1)
		var_9_4:setPosition(cc.p((iter_9_0 - 1) * (var_9_6.width + 100) + 50, 0))
		var_9_1:setContentSize(arg_9_0.list.viewRect_.width, var_9_6.height)

		local var_9_7 = xyd.tables.titleSystemTable:bg(var_9_3)
		local var_9_8 = xyd.AssetLoader:get():loadSprite(var_9_7)

		var_9_8:setAnchorPoint(0, 0)
		var_9_8:addTo(var_9_5:getChildByName("bg"), -1)
		var_9_5:getChildByName("lock"):setVisible(false)
		var_9_5:getChildByName("timecount_bg"):setVisible(false)
		var_9_5:getChildByName("bg"):getChildByName("txt_img"):setVisible(true)

		local var_9_9 = xyd.AssetLoader:get():loadSprite("images/title_system/unknown.png")

		var_9_9:setAnchorPoint(0.5, 0.5)
		var_9_9:addTo(var_9_5:getChildByName("bg"):getChildByName("txt_img"))
		var_9_5:getChildByName("title_name"):setString(xyd.tables.titleSystemTable:name(var_9_3))
	end

	var_9_0:addContent(var_9_1)
	var_9_0:setItemSize(arg_9_0.list.viewRect_.width, var_9_1:getContentSize().height)
	arg_9_0.list:addItem(var_9_0)
end

function var_0_0.updateRewardItem(arg_10_0)
	local var_10_0 = arg_10_0.list:newItem()
	local var_10_1 = {
		size = 24,
		color = cc.c3b(210, 84, 16)
	}
	local var_10_2 = xyd.AssetLoader.get():loadLabel(var_10_1)

	var_10_2:setMaxLineWidth(700)
	var_10_2:setLineHeight(49)
	var_10_2:setString(var_0_1:translation("RANK_AWARD"))
	var_10_0:addContent(var_10_2)
	var_10_0:setItemSize(700, var_10_2:getContentSize().height + 20)
	arg_10_0.list:addItem(var_10_0)

	local var_10_3 = arg_10_0.awardTable:RewardCount()

	for iter_10_0 = 1, var_10_3 do
		local var_10_4 = arg_10_0.list:newItem()
		local var_10_5 = display.newNode()

		var_10_5:setContentSize(700, 80)

		local var_10_6 = arg_10_0.awardTable:range(iter_10_0)
		local var_10_7 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_10_8 = xyd.AssetLoader.get():loadLabel(var_10_7)

		if var_10_6[1] == var_10_6[2] then
			local var_10_9 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_10_6[1])

			var_10_8:setString(var_10_9)
		else
			local var_10_10 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_10_6[1], var_10_6[2])

			var_10_8:setString(var_10_10)
		end

		var_10_8:addTo(var_10_5)
		var_10_8:setAnchorPoint(cc.p(0, 0.5))
		var_10_8:setPosition(0, 40)

		local var_10_11 = "images/icon/eco/icon_crystal.png"
		local var_10_12 = xyd.AssetLoader.get():loadSprite(var_10_11)

		var_10_12:setScale(0.8)
		var_10_12:addTo(var_10_5)
		var_10_12:setAnchorPoint(cc.p(0.5, 0.5))
		var_10_12:setPosition(200, 40)

		local var_10_13 = arg_10_0.awardTable:diamond(iter_10_0)

		if var_10_13 >= 0 then
			local var_10_14 = {
				size = 24,
				color = cc.c3b(255, 255, 255)
			}
			local var_10_15 = xyd.AssetLoader.get():loadLabel(var_10_14)

			var_10_15:setString("x" .. var_10_13)
			var_10_15:addTo(var_10_5)
			var_10_15:setAnchorPoint(cc.p(0, 0.5))
			var_10_15:setPosition(220, 40)
		end

		local var_10_16 = arg_10_0.awardTable:item(iter_10_0)
		local var_10_17 = arg_10_0.awardTable:itemNum(iter_10_0)

		for iter_10_1 = 1, #var_10_16 do
			local var_10_18 = display.newNode()

			var_10_18:setContentSize(60, 60)
			xyd.setItemAndAddTips(var_10_18, var_10_16[iter_10_1])
			var_10_18:addTo(var_10_5)
			var_10_18:setAnchorPoint(cc.p(0.5, 0.5))
			var_10_18:setPosition(350 + (iter_10_1 - 1) * 130, 40)

			local var_10_19 = {
				size = 24,
				color = cc.c3b(255, 255, 255)
			}
			local var_10_20 = xyd.AssetLoader.get():loadLabel(var_10_19)

			var_10_20:setString("x" .. var_10_17[iter_10_1])
			var_10_20:addTo(var_10_5)
			var_10_20:setAnchorPoint(cc.p(0, 0.5))
			var_10_20:setPosition(390 + (iter_10_1 - 1) * 130, 40)
		end

		var_10_4:addContent(var_10_5)
		var_10_4:setItemSize(700, 80)
		arg_10_0.list:addItem(var_10_4)
	end
end

return var_0_0
