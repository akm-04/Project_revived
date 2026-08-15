local var_0_0 = class("BackpackSortWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.filterType = arg_1_2.filterType
	arg_1_0.filterOrder = arg_1_2.filterOrder
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("default_btn"):getChildByName("click_on"):setVisible(false)
	arg_3_0:nodeByName("quality_btn"):getChildByName("click_on"):setVisible(false)
	arg_3_0:nodeByName("own_num_btn"):getChildByName("click_on"):setVisible(false)
	arg_3_0:nodeByName("time_btn"):getChildByName("click_on"):setVisible(false)
	arg_3_0:nodeByName("in_order_btn"):getChildByName("click_on"):setVisible(false)
	arg_3_0:nodeByName("inverted_order_btn"):getChildByName("click_on"):setVisible(false)

	if arg_3_0.filterType == 1 then
		arg_3_0:nodeByName("default_btn"):getChildByName("click_on"):setVisible(true)
	elseif arg_3_0.filterType == 2 then
		arg_3_0:nodeByName("quality_btn"):getChildByName("click_on"):setVisible(true)
	elseif arg_3_0.filterType == 3 then
		arg_3_0:nodeByName("own_num_btn"):getChildByName("click_on"):setVisible(true)
	elseif arg_3_0.filterType == 5 then
		arg_3_0:nodeByName("time_btn"):getChildByName("click_on"):setVisible(true)
	end

	if arg_3_0.filterOrder then
		arg_3_0:nodeByName("in_order_btn"):getChildByName("click_on"):setVisible(true)
	else
		arg_3_0:nodeByName("inverted_order_btn"):getChildByName("click_on"):setVisible(true)
	end

	arg_3_0:nodeByName("default_btn"):setTouchEnabled(true)
	arg_3_0:nodeByName("default_btn"):setTouchSwallowEnabled(true)
	arg_3_0:nodeByName("default_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			arg_3_0:nodeByName("default_btn"):getChildByName("click_on"):setVisible(true)
			arg_3_0:nodeByName("quality_btn"):getChildByName("click_on"):setVisible(false)
			arg_3_0:nodeByName("own_num_btn"):getChildByName("click_on"):setVisible(false)
			arg_3_0:nodeByName("time_btn"):getChildByName("click_on"):setVisible(false)

			arg_3_0.filterType = xyd.BackPackFilterType.DEFAULT
		end
	end)
	arg_3_0:nodeByName("quality_btn"):setTouchEnabled(true)
	arg_3_0:nodeByName("quality_btn"):setTouchSwallowEnabled(true)
	arg_3_0:nodeByName("quality_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" then
			arg_3_0:nodeByName("default_btn"):getChildByName("click_on"):setVisible(false)
			arg_3_0:nodeByName("quality_btn"):getChildByName("click_on"):setVisible(true)
			arg_3_0:nodeByName("own_num_btn"):getChildByName("click_on"):setVisible(false)
			arg_3_0:nodeByName("time_btn"):getChildByName("click_on"):setVisible(false)

			arg_3_0.filterType = xyd.BackPackFilterType.QUALITY
		end
	end)
	arg_3_0:nodeByName("own_num_btn"):setTouchEnabled(true)
	arg_3_0:nodeByName("own_num_btn"):setTouchSwallowEnabled(true)
	arg_3_0:nodeByName("own_num_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			arg_3_0:nodeByName("default_btn"):getChildByName("click_on"):setVisible(false)
			arg_3_0:nodeByName("quality_btn"):getChildByName("click_on"):setVisible(false)
			arg_3_0:nodeByName("own_num_btn"):getChildByName("click_on"):setVisible(true)
			arg_3_0:nodeByName("time_btn"):getChildByName("click_on"):setVisible(false)

			arg_3_0.filterType = xyd.BackPackFilterType.NUM
		end
	end)
	arg_3_0:nodeByName("time_btn"):setTouchEnabled(true)
	arg_3_0:nodeByName("time_btn"):setTouchSwallowEnabled(true)
	arg_3_0:nodeByName("time_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			arg_3_0:nodeByName("default_btn"):getChildByName("click_on"):setVisible(false)
			arg_3_0:nodeByName("quality_btn"):getChildByName("click_on"):setVisible(false)
			arg_3_0:nodeByName("own_num_btn"):getChildByName("click_on"):setVisible(false)
			arg_3_0:nodeByName("time_btn"):getChildByName("click_on"):setVisible(true)

			arg_3_0.filterType = xyd.BackPackFilterType.TIME
		end
	end)
	arg_3_0:nodeByName("in_order_btn"):setTouchEnabled(true)
	arg_3_0:nodeByName("in_order_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" then
			arg_3_0:nodeByName("in_order_btn"):getChildByName("click_on"):setVisible(true)
			arg_3_0:nodeByName("inverted_order_btn"):getChildByName("click_on"):setVisible(false)

			arg_3_0.filterOrder = true
		end
	end)
	arg_3_0:nodeByName("inverted_order_btn"):setTouchEnabled(true)
	arg_3_0:nodeByName("inverted_order_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			return true
		elseif arg_9_0.name == "ended" then
			arg_3_0:nodeByName("in_order_btn"):getChildByName("click_on"):setVisible(false)
			arg_3_0:nodeByName("inverted_order_btn"):getChildByName("click_on"):setVisible(true)

			arg_3_0.filterOrder = false
		end
	end)
	arg_3_0:nodeByName("confirm_button"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = {
				filterType = arg_3_0.filterType,
				filterOrder = arg_3_0.filterOrder
			}
			local var_10_1 = xyd.WindowManager.get():getWindow("backpack")

			if var_10_1 and not tolua.isnull(var_10_1) then
				var_10_1:changeSort()
				var_10_1:getSortOrder(var_10_0)
			end

			local var_10_2 = xyd.WindowManager.get():getWindow("equipment_backpack")

			if var_10_2 and not tolua.isnull(var_10_2) then
				var_10_2:changeSort()
				var_10_2:getSortOrder(var_10_0)
			end

			local var_10_3 = xyd.WindowManager.get():getWindow("fish_gambling_pledge")

			if var_10_3 and not tolua.isnull(var_10_3) then
				var_10_3:changeSort()
				var_10_3:getSortOrder(var_10_0)
			end

			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

return var_0_0
