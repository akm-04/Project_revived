local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	arg_2_0:layout(var_2_0:getChildByName("container"))
end

function var_0_0.layout(arg_3_0, arg_3_1)
	xyd.nodeEventSample(arg_3_1:getChildByName("btn_fishing"), nil, function()
		xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_GET_INFO, nil, function(arg_5_0, arg_5_1)
			if arg_5_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("activity_fishing_main", arg_5_1)
			end
		end)
	end)
	xyd.nodeEventSample(arg_3_1:getChildByName("btn_battle"), nil, function()
		local var_6_0 = params or {}

		xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_GET_INFO, var_6_0, function(arg_7_0, arg_7_1)
			if arg_7_0 == xyd.error.OK then
				local var_7_0 = {}
				local var_7_1 = arg_7_1

				xyd.WindowManager.get():openWindow("fish_gambling_main", var_7_1)
			end

			if callback then
				callback(arg_7_0, arg_7_1)
			end
		end)
	end)
end

return var_0_0
