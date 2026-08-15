local var_0_0 = class("ThirdDiglettRuleWindow", import("app.windows.NewTextRuleWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.thirdAnniWordRank
local var_0_3 = xyd.tables.gift

function var_0_0.layout(arg_1_0)
	var_0_0.super.layout(arg_1_0)

	local var_1_0 = xyd.tables.activityDiglettRank:ids()

	for iter_1_0 = 1, #var_1_0 do
		local var_1_1 = var_1_0[iter_1_0]
		local var_1_2 = display.newNode()
		local var_1_3 = arg_1_0.list:newItem()

		var_1_2:setContentSize(520, 80)
		arg_1_0:addAwardItem(var_1_2, var_1_1)
		var_1_3:addContent(var_1_2)
		var_1_3:setItemSize(520, var_1_2:getContentSize().height)
		arg_1_0.list:addItem(var_1_3)
	end

	arg_1_0.list:reload()
end

function var_0_0.addAwardItem(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = 0
	local var_2_1
	local var_2_2 = xyd.tables.activityDiglettRank:range(arg_2_2)

	if arg_2_2 == 1 then
		var_2_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_2_2)
	else
		local var_2_3 = xyd.tables.activityDiglettRank:range(arg_2_2 - 1)

		if var_2_2 - var_2_3 > 1 then
			var_2_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_2_3 + 1, var_2_2)
		else
			var_2_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_2_2)
		end
	end

	local var_2_4 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = x,
		y = y,
		color = cc.c3b(139, 68, 68),
		dimensions = cc.size(520, 0),
		text = var_2_1
	}
	local var_2_5 = xyd.AssetLoader.get():loadLabel(var_2_4)

	var_2_5:addTo(arg_2_1)
	var_2_5:setAnchorPoint(cc.p(0, 0))
	var_2_5:setPosition(0, 20)

	local var_2_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/third_anniversary_boss/rank_award_item.csb")

	var_2_6:addTo(arg_2_1)
	var_2_6:setPosition(40, 0)
	var_2_6:setAnchorPoint(cc.p(0, 0))

	local var_2_7 = var_2_6:getChildByName("container")
	local var_2_8 = xyd.tables.gift:items(xyd.tables.activityDiglettRank:gift(arg_2_2))
	local var_2_9 = xyd.tables.gift:itemNum(xyd.tables.activityDiglettRank:gift(arg_2_2))

	for iter_2_0 = 1, 3 do
		xyd.setPositionBy(var_2_7:getChildByName("item" .. tostring(iter_2_0)), cc.p(55 * iter_2_0 - (iter_2_0 - 1) * 70, 0))
		xyd.setPositionBy(var_2_7:getChildByName("item" .. tostring(iter_2_0) .. "_num"), cc.p(55 * iter_2_0 - (iter_2_0 - 1) * 70, 0))
	end

	if #var_2_8 == 0 or var_2_8[1] == 0 then
		var_2_7:getChildByName("item1"):setVisible(false)
		var_2_7:getChildByName("item2"):setVisible(false)
		var_2_7:getChildByName("item3"):setVisible(false)
		var_2_7:getChildByName("item1_num"):setVisible(false)
		var_2_7:getChildByName("item2_num"):setVisible(false)
		var_2_7:getChildByName("item3_num"):setVisible(false)
	elseif #var_2_8 == 1 then
		local var_2_10 = var_2_7:getChildByName("item3")

		var_2_7:getChildByName("item3_num"):setString("x" .. var_2_9[1])
		xyd.setItemAndAddTips(var_2_10, var_2_8[1])
		var_2_7:getChildByName("item2"):setVisible(false)
		var_2_7:getChildByName("item1"):setVisible(false)
		var_2_7:getChildByName("item2_num"):setVisible(false)
		var_2_7:getChildByName("item1_num"):setVisible(false)
	elseif #var_2_8 == 2 then
		local var_2_11 = var_2_7:getChildByName("item3")

		var_2_7:getChildByName("item3_num"):setString("x" .. var_2_9[1])
		xyd.setItemAndAddTips(var_2_11, var_2_8[1])

		local var_2_12 = var_2_7:getChildByName("item2")

		var_2_7:getChildByName("item2_num"):setString("x" .. var_2_9[2])
		xyd.setItemAndAddTips(var_2_12, var_2_8[2])
		var_2_7:getChildByName("item1"):setVisible(false)
		var_2_7:getChildByName("item1_num"):setVisible(false)
	elseif #var_2_8 == 3 then
		local var_2_13 = var_2_7:getChildByName("item3")

		var_2_7:getChildByName("item3_num"):setString("x" .. var_2_9[1])
		xyd.setItemAndAddTips(var_2_13, var_2_8[1])

		local var_2_14 = var_2_7:getChildByName("item2")

		var_2_7:getChildByName("item2_num"):setString("x" .. var_2_9[2])
		xyd.setItemAndAddTips(var_2_14, var_2_8[2])

		local var_2_15 = var_2_7:getChildByName("item1")

		var_2_7:getChildByName("item1_num"):setString("x" .. var_2_9[3])
		xyd.setItemAndAddTips(var_2_15, var_2_8[3])
	end
end

return var_0_0
