local var_0_0 = class("ShopConfirmWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.itemId = arg_1_2.item_id
	arg_1_0.itemNum = arg_1_2.item_num
	arg_1_0.index = arg_1_2.index
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("ok_text"):setString(var_0_1:translation("OK"))
	arg_4_0:nodeByName("close_text"):setString(var_0_1:translation("CANCEL"))
	arg_4_0:nodeByName("title"):setString(var_0_1:translation("TIP"))
	arg_4_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.callback()
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)

	local var_4_0 = string.format(var_0_1:translation("TRAVEL_SHOP_BAG_TIP_" .. arg_4_0.index), arg_4_0.itemNum, xyd.tables.item:name(arg_4_0.itemId))
	local var_4_1 = xyd.createMultiLineMultiColorTxt(var_4_0, cc.c3b(68, 69, 77), 24, false)

	var_4_1:setAnchorPoint(cc.p(0, 1))
	var_4_1:addTo(arg_4_0:nodeByName("tips_pos"))
end

return var_0_0
