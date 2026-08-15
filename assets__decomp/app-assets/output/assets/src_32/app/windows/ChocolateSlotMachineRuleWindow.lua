local var_0_0 = class("ChocolateSlotMachineRuleWindow", import("app.windows.NewTextRuleWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityChocolateSlotGift
local var_0_3 = xyd.tables.gift

function var_0_0.layout(arg_1_0)
	var_0_0.super.layout(arg_1_0)

	local var_1_0 = var_0_2:id()

	table.sort(var_1_0)

	for iter_1_0 = 1, #var_1_0 do
		local var_1_1 = arg_1_0.list:newItem()
		local var_1_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/chocolate/slot_machine/pop/reward_item.csb")
		local var_1_3 = var_1_2:getChildByName("container")
		local var_1_4 = var_1_3:getContentSize()
		local var_1_5 = var_1_0[iter_1_0]
		local var_1_6 = var_0_2:level(var_1_5)
		local var_1_7 = var_0_2:show(var_1_5)
		local var_1_8 = var_0_2:gift(var_1_5)
		local var_1_9 = var_0_3:items(var_1_8)
		local var_1_10 = var_0_3:itemNum(var_1_8)

		if var_1_6 == 1 then
			var_1_3:getChildByName("desc"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP21"))
		elseif var_1_6 == 2 then
			var_1_3:getChildByName("desc"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP22"))
		elseif var_1_6 == 3 then
			var_1_3:getChildByName("desc"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP23"))
		else
			var_1_3:getChildByName("desc"):setVisible(false)
		end

		for iter_1_1 = 1, 3 do
			for iter_1_2 = 1, 3 do
				var_1_3:getChildByName("item" .. iter_1_1 .. iter_1_2):setVisible(var_1_7[iter_1_1] == iter_1_2)
			end
		end

		local var_1_11 = var_1_3:getChildByName("item4")

		if not var_1_7[3] then
			var_1_3:getChildByName("item21"):getChildByName("num"):setString("=")
			var_1_3:getChildByName("item22"):getChildByName("num"):setString("=")
			var_1_3:getChildByName("item23"):getChildByName("num"):setString("=")

			var_1_11 = var_1_3:getChildByName("item34")
		end

		xyd.setItemAndAddTips(var_1_11, var_1_9[1], var_1_10[1])
		var_1_2:setContentSize(var_1_4.width, var_1_4.height)
		var_1_1:addContent(var_1_2)
		var_1_1:setItemSize(var_1_4.width, var_1_4.height)
		arg_1_0.list:addItem(var_1_1)
	end

	arg_1_0.list:reload()
end

return var_0_0
