local var_0_0 = class("RegionAlertAwakeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "alert"
local var_0_3 = 18
local var_0_4 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.message = arg_1_2.message
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:nodeByName("text_title"):setString(var_0_1:translation("TIP"))
	arg_2_0:nodeByName("text_ok"):setString(var_0_1:translation("OK"))
	arg_2_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(pSender, eventName)

		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_2_0:close(true)
		end
	end)
	arg_2_0:nodeByName("text_cancle"):setString(var_0_1:translation("CANCEL"))
	arg_2_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(pSender, eventName)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_2_0:close(false)
		end
	end)
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("icon")

	xyd.setSkillBorder(var_5_0, arg_5_0.message.skillID, var_0_4)

	local var_5_1 = {
		size = 22,
		color = cc.c3b(152, 83, 53)
	}
	local var_5_2 = xyd.AssetLoader:get():loadLabel(var_5_1)

	var_5_2:setString(arg_5_0.message.skillDesc)

	local var_5_3 = arg_5_0:nodeByName("message"):getContentSize().width
	local var_5_4 = arg_5_0:nodeByName("message"):getContentSize().height

	var_5_2:setMaxLineWidth(var_5_3)
	var_5_2:setAnchorPoint(cc.p(0, 0.5))
	var_5_2:setPosition(0, var_5_4 / 2)
	var_5_2:addTo(arg_5_0:nodeByName("message"))

	local var_5_5 = import("app.common.ui.SplitLine")
	local var_5_6 = arg_5_0:nodeByName("line")

	var_5_5.new({
		size = var_5_6:getWidth()
	}):addTo(var_5_6)
	arg_5_0:nodeByName("text_1"):setString(string.format(var_0_1:translation("REGION_SHOP_TIPS_2"), arg_5_0.message.heroName))
	arg_5_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.didClose(arg_6_0)
	arg_6_0.super.didClose()
end

function var_0_0.close(arg_7_0, arg_7_1)
	if arg_7_0.callback then
		arg_7_0.callback(arg_7_1)
		xyd.WindowManager.get():closeWindow(arg_7_0)
	end
end

return var_0_0
