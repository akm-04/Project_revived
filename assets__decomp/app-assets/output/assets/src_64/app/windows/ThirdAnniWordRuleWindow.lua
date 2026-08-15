local var_0_0 = class("ThirdAnniWordRulewindow", import("app.windows.NewTextRuleWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.thirdAnniWordRank
local var_0_3 = xyd.tables.gift

function var_0_0.layout(arg_1_0)
	var_0_0.super.layout(arg_1_0)

	local var_1_0 = var_0_2:id()

	table.sort(var_1_0)

	local var_1_1 = 0

	for iter_1_0 = 1, #var_1_0 do
		local var_1_2 = arg_1_0.list:newItem()
		local var_1_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd/rule/reward_item.csb")
		local var_1_4 = var_1_3:getChildByName("container")
		local var_1_5 = var_1_4:getContentSize()
		local var_1_6 = var_1_0[iter_1_0]
		local var_1_7 = var_0_2:gift(var_1_6)
		local var_1_8 = var_0_3:items(var_1_7)
		local var_1_9 = var_0_3:itemNum(var_1_7)
		local var_1_10 = var_0_2:range(var_1_6)

		if var_1_10 == var_1_1 + 1 then
			var_1_4:getChildByName("desc"):setString(string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_1_10))
		else
			var_1_4:getChildByName("desc"):setString(string.format(var_0_1:translation("THIRD_ANNI_WORD_RANK_TXT"), var_1_10))
		end

		for iter_1_1 = 1, #var_1_8 do
			xyd.setItemAndAddTips(var_1_4:getChildByName("item" .. iter_1_1), var_1_8[iter_1_1])
			var_1_4:getChildByName("item" .. iter_1_1):getChildByName("num"):setString("X" .. var_1_9[iter_1_1])
		end

		for iter_1_2 = #var_1_8 + 1, 3 do
			var_1_4:getChildByName("item" .. iter_1_2):setVisible(false)
		end

		var_1_1 = var_1_10

		var_1_3:setContentSize(var_1_5.width, var_1_5.height)
		var_1_2:addContent(var_1_3)
		var_1_2:setItemSize(var_1_5.width, var_1_5.height)
		arg_1_0.list:addItem(var_1_2)
	end

	arg_1_0.list:reload()
end

return var_0_0
