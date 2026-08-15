local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.misc
local var_0_4 = {
	MAKING = 1,
	CAN_GET = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1212/1212.csb")

	var_2_0:addTo(arg_2_0.parent)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.container:getChildByName("txt_word_1"):setString(var_0_1:translation("ACTIVITY_TOMORROW_SUBTITLE"))
	arg_3_0.container:getChildByName("txt_word_2"):setString(var_0_1:translation("ACTIVITY_TOMORROW_INFO"))
	arg_3_0.container:getChildByName("txt_word_3"):setString(var_0_1:translation("ACTIVITY_TOMORROW_COUNTDOWN_2"))
	arg_3_0.container:getChildByName("txt_time"):setString(var_0_1:translation("ACTIVITY_TOMORROW_COUNTDOWN_1"))
	arg_3_0.container:getChildByName("btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			if arg_3_0.state == var_0_4.MAKING then
				local var_4_0 = var_0_1:translation("ACTIVITY_TOMORROW_BTNDISABLE")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_4_0
				})
			elseif arg_3_0.state == var_0_4.CAN_GET then
				arg_3_0.activitiesModel:getActivityReward(arg_3_0.activity.table_id, nil, function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						arg_3_0.selfPlayer:handleRewards(arg_5_1.awards)

						local var_5_0 = xyd.WindowManager.get():getWindow("walfare_activities")

						if var_5_0 and not tolua.isnull(var_5_0) then
							var_5_0:updateActivitiesShow()
						end
					end
				end)
			end
		end
	end)

	local var_3_0 = xyd.ServerTime.get():getServerTime()
	local var_3_1 = arg_3_0.activity.details.create_time + var_0_3:getValue("tomorrow_countdown")

	if var_3_0 < var_3_1 then
		local var_3_2 = arg_3_0:secondsToString(var_3_1 - var_3_0)

		arg_3_0.container:getChildByName("time"):setString(var_3_2)
		arg_3_0:startTimer()

		arg_3_0.state = var_0_4.MAKING
		arg_3_0.activitiesModel.walfareRedMarkMap[arg_3_0.activity.table_id] = false

		arg_3_0.activitiesModel:refreshWalfareRedMark()
	else
		arg_3_0.state = var_0_4.CAN_GET
	end

	arg_3_0:update()
end

function var_0_0.update(arg_6_0)
	local var_6_0 = arg_6_0.container:getChildByName("btn")

	var_6_0:setBright(arg_6_0.state == var_0_4.CAN_GET)

	if arg_6_0.state == var_0_4.MAKING then
		var_6_0:getChildByName("txt_btn"):setString(var_0_1:translation("ACTIVITY_TOMORROW_BTNLABEL_1"))
	elseif arg_6_0.state == var_0_4.CAN_GET then
		var_6_0:getChildByName("txt_btn"):setString(var_0_1:translation("ACTIVITY_TOMORROW_BTNLABEL_2"))
	end

	arg_6_0.container:getChildByName("txt_time"):setVisible(arg_6_0.state == var_0_4.MAKING)
	arg_6_0.container:getChildByName("time"):setVisible(arg_6_0.state == var_0_4.MAKING)
	arg_6_0.container:getChildByName("txt_word_3"):setVisible(arg_6_0.state == var_0_4.CAN_GET)
end

function var_0_0.startTimer(arg_7_0)
	if arg_7_0.handle then
		var_0_2.unscheduleGlobal(arg_7_0.handle)

		arg_7_0.handle = nil
	end

	local var_7_0 = arg_7_0.activity.details.create_time + var_0_3:getValue("tomorrow_countdown")

	arg_7_0.handle = var_0_2.scheduleGlobal(function()
		local var_8_0 = xyd.ServerTime.get():getServerTime()

		if var_8_0 < var_7_0 then
			local var_8_1 = arg_7_0:secondsToString(var_7_0 - var_8_0)

			arg_7_0.container:getChildByName("time"):setString(var_8_1)
		else
			var_0_2.unscheduleGlobal(arg_7_0.handle)

			arg_7_0.handle = nil
			arg_7_0.state = var_0_4.CAN_GET

			arg_7_0:update()
		end
	end, 1)
end

function var_0_0.secondsToString(arg_9_0, arg_9_1)
	local var_9_0 = math.floor(arg_9_1 % 86400 / 3600)
	local var_9_1 = math.floor(arg_9_1 % 3600 / 60)
	local var_9_2 = math.floor(arg_9_1 % 60)
	local var_9_3 = "%02d:%02d:%02d"

	return string.format(var_9_3, var_9_0, var_9_1, var_9_2)
end

function var_0_0.release(arg_10_0)
	if arg_10_0.handle then
		var_0_2.unscheduleGlobal(arg_10_0.handle)

		arg_10_0.handle = nil
	end
end

return var_0_0
