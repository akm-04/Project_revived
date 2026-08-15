local var_0_0 = class("TeamMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)
	arg_1_0:setTouchEnabled(false)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super:willClose(arg_3_1)
	xyd.WindowManager.get():closeWindow("team_join")
	xyd.WindowManager.get():closeWindow("team_create")
	xyd.WindowManager.get():closeWindow("team_find")
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
	var_0_0.super:didOpen(arg_4_1)
	xyd.WindowManager.get():openWindow("team_join")
	arg_4_0:nodeByName("title"):setString(var_0_2:translation("SHE_TUAN_TEXT_22"))
	arg_4_0:nodeByName("join_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_39"))
	arg_4_0:nodeByName("create_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_40"))
	arg_4_0:nodeByName("find_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_41"))

	arg_4_0.btnIndex = 1

	arg_4_0:updateHighlight()
	arg_4_0:nodeByName("join_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_4_0.btnIndex = 1

			xyd.WindowManager.get():openWindow("team_join")
		end

		arg_4_0:updateHighlight()
	end)
	arg_4_0:nodeByName("create_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_4_0.btnIndex = 2

			xyd.WindowManager.get():openWindow("team_create")
		end

		arg_4_0:updateHighlight()
	end)
	arg_4_0:nodeByName("find_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_4_0.btnIndex = 3

			xyd.WindowManager.get():openWindow("team_find")
		end

		arg_4_0:updateHighlight()
	end)
	arg_4_0:nodeByName("back_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("back_btn"), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_8_0, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
			xyd.WindowManager.get():closeWindow("team_join")
			xyd.WindowManager.get():closeWindow("team_create")
			xyd.WindowManager.get():closeWindow("team_find")
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.TEAM_MAIN_UPDATE_LAYER, handler(arg_4_0, arg_4_0.updateLayer))
end

function var_0_0.updateLayer(arg_9_0, arg_9_1)
	arg_9_0.btnIndex = arg_9_1.params

	arg_9_0:updateHighlight()
end

function var_0_0.updateHighlight(arg_10_0)
	if arg_10_0.btnIndex == 1 then
		arg_10_0:nodeByName("join_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_10_0:nodeByName("create_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_10_0:nodeByName("find_btn"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_10_0.btnIndex == 2 then
		arg_10_0:nodeByName("create_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_10_0:nodeByName("join_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_10_0:nodeByName("find_btn"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_10_0.btnIndex == 3 then
		arg_10_0:nodeByName("find_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_10_0:nodeByName("create_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_10_0:nodeByName("join_btn"):setBrightStyle(ccui.BrightStyle.normal)
	end
end

return var_0_0
