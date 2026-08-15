local var_0_0 = class("FourthAnniPaintRuleWindow", import("app.windows.NewTextRuleWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.ruleStyle
local var_0_3 = 814
local var_0_4 = 547

function var_0_0.updateRewardItem(arg_1_0)
	local var_1_0 = arg_1_0.list:newItem()
	local var_1_1 = {
		size = 24,
		color = cc.c3b(210, 84, 16)
	}
	local var_1_2 = xyd.AssetLoader.get():loadLabel(var_1_1)

	var_1_2:setMaxLineWidth(708)
	var_1_2:setLineHeight(49)
	var_1_2:setString(var_0_1:translation("RANK_AWARD"))
	var_1_0:addContent(var_1_2)
	var_1_0:setItemSize(708, var_1_2:getContentSize().height + 20)
	arg_1_0.list:addItem(var_1_0)

	local var_1_3 = arg_1_0.awardTable:RewardCount()

	for iter_1_0 = 1, var_1_3 do
		local var_1_4 = arg_1_0.list:newItem()
		local var_1_5 = display.newNode()

		var_1_5:setContentSize(714, 80)

		local var_1_6 = 0
		local var_1_7 = arg_1_0.awardTable:range(iter_1_0)
		local var_1_8 = {
			size = 24,
			color = cc.c3b(54, 52, 55)
		}
		local var_1_9 = xyd.AssetLoader.get():loadLabel(var_1_8)

		if var_1_7[1] == var_1_7[2] then
			local var_1_10 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_1_7[1])

			var_1_9:setString(var_1_10)
		else
			local var_1_11 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_1_7[1], var_1_7[2])

			var_1_9:setString(var_1_11)
		end

		var_1_9:addTo(var_1_5)
		var_1_9:setAnchorPoint(cc.p(0, 0.5))
		var_1_9:setPosition(var_1_6, 40)

		local var_1_12 = var_1_6 + 280
		local var_1_13 = arg_1_0.awardTable:item(iter_1_0)
		local var_1_14 = arg_1_0.awardTable:itemNum(iter_1_0)

		for iter_1_1 = 1, #var_1_13 do
			local var_1_15 = display.newNode()

			var_1_15:setContentSize(60, 60)
			xyd.setItemAndAddTips(var_1_15, var_1_13[iter_1_1])
			var_1_15:addTo(var_1_5)
			var_1_15:setAnchorPoint(cc.p(0.5, 0.5))
			var_1_15:setPosition(var_1_12 + (iter_1_1 - 1) * 130, 40)

			local var_1_16 = {
				size = 24,
				color = cc.c3b(54, 52, 55)
			}
			local var_1_17 = xyd.AssetLoader.get():loadLabel(var_1_16)

			var_1_17:setString("x" .. var_1_14[iter_1_1])
			var_1_17:addTo(var_1_5)
			var_1_17:setAnchorPoint(cc.p(0, 0.5))
			var_1_17:setPosition(var_1_12 + 40 + (iter_1_1 - 1) * 130, 40)
		end

		var_1_4:addContent(var_1_5)
		var_1_4:setItemSize(714, 80)
		arg_1_0.list:addItem(var_1_4)
	end
end

return var_0_0
