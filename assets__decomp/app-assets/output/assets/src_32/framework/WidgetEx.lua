function ccui.Widget.setTouchEnabled(arg_1_0, arg_1_1)
	local var_1_0 = tolua.getcfunction(arg_1_0, "setTouchEnabled")

	if arg_1_0._LuaListeners and arg_1_0._LuaListeners[cc.NODE_TOUCH_EVENT] then
		cc.Node.setTouchEnabled(arg_1_0, arg_1_1)
		var_1_0(arg_1_0, false)
	else
		var_1_0(arg_1_0, arg_1_1)
	end
end
