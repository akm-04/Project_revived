local var_0_0 = class("NewTermMakeChooseAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = import("framework.scheduler")
local var_0_4 = 3
local var_0_5 = 90
local var_0_6 = xyd.tables.misc.newTermMaterials

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.index = arg_1_2.index
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	for iter_4_0 = 1, var_0_4 do
		local var_4_0 = var_0_6[iter_4_0]

		arg_4_0:nodeByName("icon_" .. iter_4_0):setAnchorPoint(0.5, 0.5)
		arg_4_0:nodeByName("icon_" .. iter_4_0):setContentSize(var_0_5, var_0_5)
		xyd.setItemBorder(arg_4_0:nodeByName("icon_" .. iter_4_0), var_4_0)
		arg_4_0:nodeByName("name_" .. iter_4_0):setString(xyd.tables.item:name(var_4_0))
		arg_4_0:nodeByName("icon_" .. iter_4_0):setTouchEnabled(true)
		arg_4_0:nodeByName("icon_" .. iter_4_0):setTouchSwallowEnabled(false)
		arg_4_0:nodeByName("icon_" .. iter_4_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "ended" then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.NEW_TERM_CHOOSE_MATERIALS,
					params = {
						index = arg_4_0.index,
						itemID = var_4_0
					}
				})
				xyd.WindowManager.get():closeWindow(arg_4_0)
			end

			return true
		end)
	end
end

function var_0_0.willClose(arg_6_0)
	if arg_6_0.handle then
		var_0_3.unscheduleGlobal(arg_6_0.handle)

		arg_6_0.handle = nil
	end
end

return var_0_0
