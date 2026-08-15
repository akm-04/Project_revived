local var_0_0 = class("SidebarTabButton", import("app.common.ui.BaseNode"))

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0)

	arg_1_0.state = arg_1_1.state or xyd.TabButtonType.NULL
	arg_1_0.onCall = arg_1_1.onCall
	arg_1_0.offCall = arg_1_1.offCall
	arg_1_0.title = arg_1_1.title

	arg_1_0:init()
	arg_1_0:update()
end

function var_0_0.init(arg_2_0)
	arg_2_0:loadRes("windows/common_widgets/tab_btn.csb")

	local var_2_0 = arg_2_0:nodeByName("bg_btn_state")

	arg_2_0.clickNode = display.newNode()

	arg_2_0.clickNode:addTo(arg_2_0:background())
	arg_2_0.clickNode:setContentSize(var_2_0:getWidth() + 20, var_2_0:getHeight() + 20)
	arg_2_0.clickNode:setAnchorPoint(0.5, 0.5)
	arg_2_0.clickNode:setPosition(var_2_0:getPosition())
	arg_2_0.clickNode:setTouchEnabled(true)

	if arg_2_0.title then
		arg_2_0:setTitle(arg_2_0.title)
	end

	arg_2_0:onRegister()
end

function var_0_0.update(arg_3_0)
	if arg_3_0.state == xyd.TabButtonType.NULL then
		return
	end

	if arg_3_0.state == xyd.TabButtonType.ON then
		arg_3_0:nodeByName("btn_state_off"):setVisible(false)
		arg_3_0:nodeByName("btn_state_on"):setVisible(true)

		if arg_3_0.onCall then
			arg_3_0.onCall()
		end
	elseif arg_3_0.state == xyd.TabButtonType.OFF then
		arg_3_0:nodeByName("btn_state_off"):setVisible(true)
		arg_3_0:nodeByName("btn_state_on"):setVisible(false)

		if arg_3_0.offCall then
			arg_3_0.offCall()
		end
	end
end

function var_0_0.onRegister(arg_4_0)
	arg_4_0.clickNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" then
			xyd.playTabButtonSound()
			arg_4_0:switch()
		end
	end)
end

function var_0_0.switch(arg_6_0, arg_6_1)
	if not arg_6_1 then
		arg_6_0.state = 3 - arg_6_0.state
	else
		arg_6_0.state = arg_6_1
	end

	arg_6_0:update()
end

function var_0_0.setOnCall(arg_7_0, arg_7_1)
	arg_7_0.onCall = arg_7_1
end

function var_0_0.setOffCall(arg_8_0, arg_8_1)
	arg_8_0.offCall = arg_8_1
end

function var_0_0.setTitle(arg_9_0, arg_9_1)
	arg_9_0:nodeByName("txt_btn_name"):setString(arg_9_1)
	arg_9_0:nodeByName("txt_btn_name"):setColor(cc.c4b(36, 147, 169, 255))
end

return var_0_0
