local var_0_0 = class("ActivityWufuGiftTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.gift

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.giftID = arg_1_2.gift_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.items = var_0_1:items(arg_2_0.giftID)
	arg_2_0.nums = var_0_1:itemNum(arg_2_0.giftID)

	local var_2_0 = #arg_2_0.items

	for iter_2_0 = 1, 3 do
		arg_2_0:nodeByName("item" .. iter_2_0):setVisible(false)
		arg_2_0:nodeByName("num" .. iter_2_0):setVisible(false)
	end

	for iter_2_1 = 1, var_2_0 do
		arg_2_0:nodeByName("item" .. iter_2_1 + 3 - var_2_0):setVisible(true)
		arg_2_0:nodeByName("num" .. iter_2_1 + 3 - var_2_0):setVisible(true)
		xyd.setItemBorder(arg_2_0:nodeByName("item" .. iter_2_1 + 3 - var_2_0), arg_2_0.items[iter_2_1])
		arg_2_0:nodeByName("num" .. iter_2_1 + 3 - var_2_0):setString("X " .. arg_2_0.nums[iter_2_1])
	end

	local var_2_1 = arg_2_0:nodeByName("container"):getContentSize()

	arg_2_0:nodeByName("container"):setContentSize(var_2_1.width, var_2_1.height - 70 * (3 - var_2_0))
end

return var_0_0
