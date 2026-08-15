local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.illusion = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(33, 23)

	local var_2_1 = var_2_0:getChildByName("bg")

	arg_2_0:layout(var_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_0:updateTimeCount(arg_3_1)
	arg_3_1:getChildByName("btn_bet"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_4_0:setScale(0.9)
		elseif arg_4_1 == ccui.TouchEventType.moved then
			arg_4_0:setScale(1)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			arg_4_0:setScale(1)

			if arg_3_0.activity.is_open == 1 and xyd.ServerTime.get():getServerTime() >= arg_3_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_3_0.activity.end_time then
				arg_3_0.illusion:getBetInfo(function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("illusion_bet")
						xyd.WindowManager.get():closeWindow("activities")
					end
				end)
			else
				if xyd.ServerTime.get():getServerTime() < arg_3_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_3_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
end

function var_0_0.updateTimeCount(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1:getChildByName("text_time")

	if arg_6_0.handle_ then
		var_0_2.unscheduleGlobal(arg_6_0.handle_)
	end

	local var_6_1

	if arg_6_0.details.paradise_info.count < 1 or xyd.ServerTime.get():getServerTime() < arg_6_0.activity.start_time or xyd.ServerTime.get():getServerTime() >= arg_6_0.activity.end_time then
		var_6_1 = 0
	else
		local var_6_2 = xyd.ServerTime.get():getSecondsOfDay()

		if var_6_2 < xyd.tables.misc.dayStartTime then
			var_6_1 = xyd.tables.misc.dayStartTime - var_6_2
		else
			var_6_1 = 86400 - var_6_2 + xyd.tables.misc.dayStartTime
		end
	end

	if var_6_1 <= 0 then
		var_6_1 = 0
	end

	var_6_0:setString(var_0_1:translation("ACTIVITY_GAMBLE_TEXT10") .. xyd.secondsToString(var_6_1, {
		toText = false
	}))

	arg_6_0.handle_ = var_0_2.scheduleGlobal(function()
		if var_6_0 and not tolua.isnull(var_6_0) then
			var_6_1 = var_6_1 - 1

			if var_6_1 <= 0 then
				var_6_1 = 0
			end

			var_6_0:setString(var_0_1:translation("ACTIVITY_GAMBLE_TEXT10") .. xyd.secondsToString(var_6_1, {
				toText = false
			}))

			if var_6_1 == 0 then
				arg_6_0.illusion.isBetOpen = false

				if arg_6_0.handle_ then
					var_0_2.unscheduleGlobal(arg_6_0.handle_)

					arg_6_0.handle_ = nil
				end
			end
		elseif arg_6_0.handle_ then
			var_0_2.unscheduleGlobal(arg_6_0.handle_)

			arg_6_0.handle_ = nil
		end
	end, 1)
end

return var_0_0
