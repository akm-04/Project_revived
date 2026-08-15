local var_0_0 = class("ApplyConfirmWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.oldItemID = arg_1_2.oldItemID
	arg_1_0.newItemID = arg_1_2.newItemID
	arg_1_0.rank = arg_1_2.rank
	arg_1_0.type = arg_1_2.type
	arg_1_0.callback1 = arg_1_2.callback1
	arg_1_0.callback2 = arg_1_2.callback2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("title"):setString(var_0_1:translation("CONFIRM_APPLY_TITLE"))
	arg_2_0:nodeByName("desc11"):setString(var_0_1:translation("APPLY_CONFIRM_DESC1"))
	arg_2_0:nodeByName("desc13"):setString(var_0_1:translation("APPLY_CONFIRM_DESC2"))
	arg_2_0:nodeByName("desc21"):setString(var_0_1:translation("APPLY_CONFIRM_DESC3"))
	arg_2_0:nodeByName("desc23"):setString(var_0_1:translation("APPLY_CONFIRM_DESC4"))
	arg_2_0:nodeByName("desc31"):setString(var_0_1:translation("APPLY_CONFIRM_DESC5"))
	arg_2_0:nodeByName("desc33"):setString(var_0_1:translation("APPLY_CONFIRM_DESC6"))
	arg_2_0:nodeByName("desc34"):setString(var_0_1:translation("SHE_TUAN_TEXT_59"))
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = xyd.tables.item:name(arg_3_0.oldItemID)
	local var_3_1 = xyd.tables.item:name(arg_3_0.newItemID)

	arg_3_0:nodeByName("desc12"):setString(var_3_0)
	arg_3_0:nodeByName("desc14"):setString(arg_3_0.rank)
	arg_3_0:nodeByName("desc22"):setString(var_3_0)
	arg_3_0:nodeByName("desc32"):setString(var_3_1)

	if arg_3_0.type == 1 then
		arg_3_0:nodeByName("desc24"):setString("？")
		arg_3_0:nodeByName("desc31"):setVisible(false)
		arg_3_0:nodeByName("desc32"):setVisible(false)
		arg_3_0:nodeByName("desc33"):setVisible(false)
	end

	arg_3_0:nodeByName("desc12"):setPositionX(arg_3_0:nodeByName("desc11"):getPositionX() + arg_3_0:nodeByName("desc11"):getContentSize().width + 3)
	arg_3_0:nodeByName("desc13"):setPositionX(arg_3_0:nodeByName("desc12"):getPositionX() + arg_3_0:nodeByName("desc12"):getContentSize().width + 3)
	arg_3_0:nodeByName("desc14"):setPositionX(arg_3_0:nodeByName("desc13"):getPositionX() + arg_3_0:nodeByName("desc13"):getContentSize().width + 3)
	arg_3_0:nodeByName("desc15"):setPositionX(arg_3_0:nodeByName("desc14"):getPositionX() + arg_3_0:nodeByName("desc14"):getContentSize().width + 1)
	arg_3_0:nodeByName("desc22"):setPositionX(arg_3_0:nodeByName("desc21"):getPositionX() + arg_3_0:nodeByName("desc21"):getContentSize().width + 3)
	arg_3_0:nodeByName("desc23"):setPositionX(arg_3_0:nodeByName("desc22"):getPositionX() + arg_3_0:nodeByName("desc22"):getContentSize().width + 3)
	arg_3_0:nodeByName("desc24"):setPositionX(arg_3_0:nodeByName("desc23"):getPositionX() + arg_3_0:nodeByName("desc23"):getContentSize().width + 1)
	arg_3_0:nodeByName("desc32"):setPositionX(arg_3_0:nodeByName("desc31"):getPositionX() + arg_3_0:nodeByName("desc31"):getContentSize().width + 3)
	arg_3_0:nodeByName("desc33"):setPositionX(arg_3_0:nodeByName("desc32"):getPositionX() + arg_3_0:nodeByName("desc32"):getContentSize().width + 3)
	arg_3_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("ok_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0.callback1()
			xyd.WindowManager.get():closeWindow(arg_3_0.name)
		end
	end)
	arg_3_0:nodeByName("txt_close"):setString(var_0_1:translation("SHE_TUAN_TEXT_16"))
	arg_3_0:nodeByName("txt_sure"):setString(var_0_1:translation("SHE_TUAN_TEXT_15"))
	arg_3_0:nodeByName("btn_close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("btn_close"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0.callback2()
			xyd.WindowManager.get():closeWindow(arg_3_0.name)
		end
	end)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
