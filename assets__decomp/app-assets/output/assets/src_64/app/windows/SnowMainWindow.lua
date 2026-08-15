local var_0_0 = class("SnowMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 86400

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.snowActivity = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
	arg_1_0.activity = arg_1_0.snowActivity:getActivity()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:createImgEvent()
	arg_3_0:updateTimeCount()
end

function var_0_0.createImgEvent(arg_4_0)
	xyd.imgEvent(arg_4_0:nodeByName("img_snow"), function()
		xyd.WindowManager.get():openWindow("snow_info")
	end)
	xyd.imgEvent(arg_4_0:nodeByName("img_battle"), function()
		xyd.WindowManager.get():openWindow("snow_battle")
	end)
	xyd.imgEvent(arg_4_0:nodeByName("img_gacha"), function()
		xyd.WindowManager.get():openWindow("snow_gacha")
	end)
	xyd.imgEvent(arg_4_0:nodeByName("btn_rank"), function()
		arg_4_0.snowActivity:getRankInfo(function(arg_9_0, arg_9_1)
			if arg_9_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("snow_rank", arg_9_1)
			end
		end)
	end)
	xyd.imgEvent(arg_4_0:nodeByName("btn_rule"), function()
		local var_10_0 = {
			title_name = "ACTIVITY_SNOWMAN_RULE_TITLE",
			rule = "ACTIVITY_SNOWMAN_RULE_TEXT"
		}

		xyd.WindowManager.get():openWindow("text_rule", var_10_0)
	end)
	xyd.imgEvent(arg_4_0:nodeByName("img_close"), function()
		xyd.WindowManager.get():closeWindow(arg_4_0)
	end)
end

function var_0_0.updateTimeCount(arg_12_0)
	if arg_12_0.handle_ then
		var_0_1.unscheduleGlobal(arg_12_0.handle_)
	end

	local var_12_0 = xyd.ServerTime.get():getServerTime()
	local var_12_1 = arg_12_0.activity.end_time - var_12_0
	local var_12_2 = arg_12_0:nodeByName("text_time")
	local var_12_3 = var_0_2:translation("ACTIVITY_END_TIME")

	if var_12_1 < 0 then
		var_12_2:setString(var_12_3 .. "00:00:00")

		return
	end

	local function var_12_4(arg_13_0)
		if arg_13_0 > var_0_3 then
			return xyd.secondsToString1(arg_13_0, 2)
		end

		return xyd.secondsToString(arg_13_0)
	end

	var_12_2:setString(var_12_3 .. var_12_4(var_12_1))

	arg_12_0.handle_ = var_0_1.scheduleGlobal(function()
		if arg_12_0 and not tolua.isnull(arg_12_0) then
			var_12_1 = var_12_1 - 1

			var_12_2:setString(var_12_3 .. var_12_4(var_12_1))

			if var_12_1 == 0 and arg_12_0.handle_ then
				var_0_1.unscheduleGlobal(arg_12_0.handle_)

				arg_12_0.handle_ = nil
			end
		elseif arg_12_0.handle_ then
			var_0_1.unscheduleGlobal(arg_12_0.handle_)

			arg_12_0.handle_ = nil
		end
	end, 1)
end

return var_0_0
