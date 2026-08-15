local var_0_0 = class("ActivityNewCandleRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

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

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 10 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, 700, 400),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("title"):setString(var_0_1:translation("ACTIVITY_SERVER_CANDLE_RULE_TITLE"))
	arg_4_0:nodeByName("close_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("left_hua"):setPositionX(arg_4_0:nodeByName("left_hua"):getPositionX() - 60)
	arg_4_0:nodeByName("right_hua"):setPositionX(arg_4_0:nodeByName("right_hua"):getPositionX() + 60)

	local var_4_0 = arg_4_0:createRuleLabel()

	for iter_4_0 = 1, #var_4_0 do
		local var_4_1 = display.newNode()
		local var_4_2 = arg_4_0.list:newItem()
		local var_4_3 = display.newNode()

		var_4_0[iter_4_0]:addTo(var_4_3)
		var_4_0[iter_4_0]:setAnchorPoint(cc.p(0, 0))
		var_4_0[iter_4_0]:setPosition(0, 0)
		var_4_3:setContentSize(700, var_4_0[iter_4_0]:getContentSize().height)
		var_4_3:addTo(var_4_1)
		var_4_1:setContentSize(700, var_4_0[iter_4_0]:getContentSize().height + 20)
		var_4_2:addContent(var_4_1)
		var_4_2:setItemSize(700, var_4_0[iter_4_0]:getContentSize().height + 20)
		arg_4_0.list:addItem(var_4_2)
	end

	local var_4_4 = display.newNode()
	local var_4_5 = xyd.createLabel(24, cc.c3b(240, 190, 14, 255))

	var_4_5:setString(var_0_1:translation("ACTIVITY_SERVER_CHARGE_TEXT_1"))
	var_4_4:setContentSize(700, 40)
	var_4_5:setAnchorPoint(cc.p(0, 0.5))
	var_4_5:addTo(var_4_4)
	var_4_5:setPositionY(25)

	local var_4_6 = arg_4_0.list:newItem()

	var_4_6:addContent(var_4_4)
	var_4_6:setItemSize(var_4_4:getContentSize().width, var_4_4:getContentSize().height)
	arg_4_0.list:addItem(var_4_6)

	local var_4_7 = display.newNode()
	local var_4_8 = xyd.createLabel(24, cc.c4b(220, 220, 200, 255))

	var_4_8:setString(var_0_1:translation("ACTIVITY_SERVER_CHARGE_TEXT_2"))
	var_4_7:setContentSize(700, 30)
	var_4_8:setAnchorPoint(cc.p(0, 0.5))
	var_4_8:addTo(var_4_7)
	var_4_8:setPositionY(15)

	local var_4_9 = arg_4_0.list:newItem()

	var_4_9:addContent(var_4_7)
	var_4_9:setItemSize(var_4_7:getContentSize().width, var_4_7:getContentSize().height)
	arg_4_0.list:addItem(var_4_9)

	local var_4_10 = xyd.tables.activityCandleRangeReward
	local var_4_11 = var_4_10:ids()

	for iter_4_1 = 1, #var_4_11 do
		local var_4_12 = display.newNode()

		var_4_12:setContentSize(700, 50)

		local var_4_13
		local var_4_14 = var_4_10:range(var_4_11[iter_4_1])
		local var_4_15 = var_4_10:range(var_4_11[iter_4_1 - 1])

		if var_4_14 - var_4_15 > 1 then
			var_4_13 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_4_15 + 1, var_4_14)
		else
			var_4_13 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_4_14)
		end

		local var_4_16 = xyd.createLabel(22, cc.c4b(220, 220, 200, 255))

		var_4_16:setString(var_4_13)
		var_4_16:setAnchorPoint(cc.p(0, 0.5))
		var_4_16:addTo(var_4_12)
		var_4_16:setPosition(cc.p(0, var_4_12:getContentSize().height / 2))

		local var_4_17 = var_4_10:itemIds(var_4_11[iter_4_1])
		local var_4_18 = var_4_10:itemNums(var_4_11[iter_4_1])
		local var_4_19 = xyd.getFormatItemsByIdNums(var_4_17, var_4_18)
		local var_4_20 = var_4_10:crystal(var_4_11[iter_4_1])

		if var_4_20 and var_4_20 > 0 then
			local var_4_21 = {
				item_id = xyd.tables.asset:getIdByBackendName("crystal"),
				item_num = var_4_20
			}

			table.insert(var_4_19, var_4_21)
		end

		local var_4_22 = xyd.getItemsWithNum(var_4_19, 150, cc.c3b(220, 220, 200), 40)

		var_4_22:setAnchorPoint(cc.p(0, 0.5))
		var_4_22:addTo(var_4_12)
		var_4_22:setPosition(cc.p(200, var_4_12:getContentSize().height / 2))

		local var_4_23 = arg_4_0.list:newItem()

		var_4_23:addContent(var_4_12)
		var_4_23:setItemSize(var_4_12:getContentSize().width, var_4_12:getContentSize().height + 10)
		arg_4_0.list:addItem(var_4_23)
	end

	local var_4_24 = display.newNode()
	local var_4_25 = xyd.createLabel(24, cc.c3b(240, 190, 14, 255))

	var_4_25:setString(var_0_1:translation("ACTIVITY_SERVER_CHARGE_TEXT_3"))
	var_4_24:setContentSize(700, 40)
	var_4_25:setAnchorPoint(cc.p(0, 0.5))
	var_4_25:addTo(var_4_24)
	var_4_25:setPositionY(25)

	local var_4_26 = arg_4_0.list:newItem()

	var_4_26:addContent(var_4_24)
	var_4_26:setItemSize(var_4_24:getContentSize().width, var_4_24:getContentSize().height)
	arg_4_0.list:addItem(var_4_26)

	local var_4_27 = display.newNode()
	local var_4_28 = xyd.createLabel(24, cc.c4b(220, 220, 200, 255))

	var_4_28:setString(var_0_1:translation("ACTIVITY_SERVER_CHARGE_TEXT_4"))
	var_4_27:setContentSize(700, 30)
	var_4_28:setAnchorPoint(cc.p(0, 0.5))
	var_4_28:addTo(var_4_27)
	var_4_28:setPositionY(15)

	local var_4_29 = arg_4_0.list:newItem()

	var_4_29:addContent(var_4_27)
	var_4_29:setItemSize(var_4_27:getContentSize().width, var_4_27:getContentSize().height)
	arg_4_0.list:addItem(var_4_29)

	local var_4_30 = xyd.tables.activityCandlePersonReward
	local var_4_31 = var_4_30:ids()

	for iter_4_2 = 1, #var_4_31 do
		local var_4_32 = display.newNode()

		var_4_32:setContentSize(700, 50)

		local var_4_33 = string.format(var_0_1:translation("ACTIVITY_SERVER_AWARD_TEXT_1"), var_4_30:point(var_4_31[iter_4_2]))
		local var_4_34 = xyd.createLabel(22, cc.c4b(220, 220, 200, 255))

		var_4_34:setString(var_4_33)
		var_4_34:setAnchorPoint(cc.p(0, 0.5))
		var_4_34:addTo(var_4_32)
		var_4_34:setPosition(cc.p(0, var_4_32:getContentSize().height / 2))

		local var_4_35 = var_4_30:gift(var_4_31[iter_4_2])
		local var_4_36 = xyd.getFormatItemsByGiftId(var_4_35)
		local var_4_37 = xyd.getItemsWithNum(var_4_36, 150, cc.c3b(220, 220, 200), 40)

		var_4_37:setAnchorPoint(cc.p(0, 0.5))
		var_4_37:addTo(var_4_32)
		var_4_37:setPosition(cc.p(120, var_4_32:getContentSize().height / 2))

		local var_4_38 = arg_4_0.list:newItem()

		var_4_38:addContent(var_4_32)
		var_4_38:setItemSize(var_4_32:getContentSize().width, var_4_32:getContentSize().height + 10)
		arg_4_0.list:addItem(var_4_38)
	end

	arg_4_0.list:reload()
end

function var_0_0.createRuleLabel(arg_6_0)
	local var_6_0 = var_0_1:translation("ACTIVITY_SERVER_CANDLE_RULE_TEXT")
	local var_6_1 = xyd.luaStringSplit(var_6_0, "|")
	local var_6_2 = {}

	for iter_6_0 = 1, #var_6_1 do
		local var_6_3 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_6_4 = xyd.AssetLoader.get():loadLabel(var_6_3)

		var_6_4:setMaxLineWidth(700)
		var_6_4:setLineHeight(49)
		var_6_4:setString(var_6_1[iter_6_0])
		table.insert(var_6_2, var_6_4)
	end

	return var_6_2
end

function var_0_0.rewardFormat1(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0 = arg_7_1:getContentSize().height
	local var_7_1 = margin or var_7_0 / 4

	if #arg_7_2 == 1 and arg_7_2[1] == 0 then
		arg_7_2 = {}
	end

	for iter_7_0 = 1, #arg_7_2 do
		local var_7_2 = display.newNode()

		var_7_2:setContentSize(var_7_0, var_7_0)

		if xyd.tables.item:type(arg_7_2[iter_7_0]) == -1 then
			xyd.setAvatarBorder(arg_7_2[iter_7_0], var_7_2, 1, xyd.tables.hero:initialStar(arg_7_2[iter_7_0]))
		else
			xyd.setItemBorder(var_7_2, arg_7_2[iter_7_0], false, false, arg_7_3[iter_7_0])
		end

		var_7_2:addTo(arg_7_1)
		var_7_2:setAnchorPoint(cc.p(0, 0))
		var_7_2:setPosition((iter_7_0 - 1) * (var_7_0 + var_7_1), 0)

		local var_7_3 = {
			id = arg_7_2[iter_7_0],
			lev = xyd.tables.item:level(arg_7_2[iter_7_0])
		}

		if xyd.tables.item:type(arg_7_2[iter_7_0]) == -1 then
			var_7_3.tipsType = 0
			var_7_3.desc1 = xyd.tables.hero:getDes(arg_7_2[iter_7_0])
		elseif specialItem then
			var_7_3.tipsType = 1
			var_7_3.id = -3
		else
			var_7_3.tipsType = 1
			var_7_3.desc1 = xyd.tables.item:desc1(arg_7_2[iter_7_0])
			var_7_3.desc2 = xyd.tables.item:desc2(arg_7_2[iter_7_0])
		end

		var_7_3.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_7_2[iter_7_0])
		var_7_3.name = xyd.tables.item:name(arg_7_2[iter_7_0])

		arg_7_0:addTips(var_7_2, var_7_3)
	end

	return arg_7_1
end

function var_0_0.rewardFormat(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = arg_8_1:getContentSize().height
	local var_8_1 = arg_8_4 or var_8_0 / 4
	local var_8_2 = xyd.tables.gift:items(arg_8_2)

	if #var_8_2 == 1 and var_8_2[1] == 0 then
		var_8_2 = {}
	end

	local var_8_3 = xyd.tables.gift:itemNum(arg_8_2)
	local var_8_4 = #var_8_2

	for iter_8_0 = 1, #var_8_2 do
		-- block empty
	end

	local var_8_5 = xyd.tables.gift:skinFragment(arg_8_2)

	if var_8_5 and var_8_5 > 0 then
		local var_8_6 = display.newNode()

		var_8_6:setContentSize(var_8_0, var_8_0)
		xyd.setItemBorder(var_8_6, -101, false, false, var_8_5)
		var_8_6:addTo(arg_8_1)
		var_8_6:setAnchorPoint(cc.p(0, 0))
		var_8_6:setPosition(var_8_4 * (var_8_0 + var_8_1), 0)

		local var_8_7 = {}

		var_8_7.id = -101
		var_8_7.tipsType = 1

		arg_8_0:addTips(var_8_6, var_8_7)

		var_8_4 = var_8_4 + 1
	end

	local var_8_8 = xyd.tables.gift:crystal(arg_8_2)

	if var_8_8 and var_8_8 > 0 then
		local var_8_9 = display.newNode()

		var_8_9:setContentSize(var_8_0, var_8_0)
		xyd.setItemBorder(var_8_9, -1, false, false, var_8_8)
		var_8_9:addTo(arg_8_1)
		var_8_9:setAnchorPoint(cc.p(0, 0))
		var_8_9:setPosition(var_8_4 * (var_8_0 + var_8_1), 0)

		local var_8_10 = {}

		var_8_10.id = -1
		var_8_10.tipsType = 1

		arg_8_0:addTips(var_8_9, var_8_10)

		var_8_4 = var_8_4 + 1
	end

	local var_8_11 = xyd.tables.gift:mana(arg_8_2)

	if var_8_11 and var_8_11 > 0 then
		local var_8_12 = display.newNode()

		var_8_12:setContentSize(var_8_0, var_8_0)
		xyd.setItemBorder(var_8_12, -2, false, false, var_8_11)
		var_8_12:addTo(arg_8_1)
		var_8_12:setAnchorPoint(cc.p(0, 0))
		var_8_12:setPosition(var_8_4 * (var_8_0 + var_8_1), 0)

		local var_8_13 = {}

		var_8_13.id = -2
		var_8_13.tipsType = 1

		arg_8_0:addTips(var_8_12, var_8_13)

		local var_8_14 = var_8_4 + 1
	end

	return arg_8_1
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
