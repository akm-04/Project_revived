local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 5

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activity.redMark = arg_1_0.activitiesModel:getRedMarkMap(arg_1_0.activity.table_id)

	if arg_1_0.activity.redMark and arg_1_0:isCanEat() then
		arg_1_0.activity.redMark.state = 1
	end
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")

		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(-5, 5)
		arg_2_0.container:getChildByName("rule_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.ended then
				xyd.WindowManager.get():openWindow("zongzi_rule")
			end
		end)
		arg_2_0:update()
	end
end

function var_0_0.isCanEat(arg_4_0)
	local var_4_0 = arg_4_0.activity
	local var_4_1 = xyd.ServerTime.get():getServerTime()

	if var_4_1 < var_4_0.start_time or var_4_1 > var_4_0.end_time then
		return false
	end

	arg_4_0.waitTimes = xyd.splitToNumber(xyd.tables.activityZongZiTable:times(arg_4_0.activity.details.day_count), "|")

	local var_4_2

	if arg_4_0.activity.details.gift_count == 1 then
		return true
	elseif arg_4_0.activity.details.gift_count > 5 then
		return false
	else
		var_4_2 = arg_4_0.activity.details.award_time + arg_4_0.waitTimes[arg_4_0.activity.details.gift_count] - var_4_1
	end

	if var_4_2 > 0 then
		return false
	else
		return true
	end
end

function var_0_0.update(arg_5_0)
	arg_5_0.container:getChildByName("box_right"):setVisible(false)
	arg_5_0.container:getChildByName("box_left"):setVisible(true)
	arg_5_0.container:getChildByName("box_right"):getChildByName("eat_txt"):setString(var_0_2:translation("CAN_EAT"))
	arg_5_0:setTouchBtn(false)

	local var_5_0 = arg_5_0.activity
	local var_5_1 = xyd.ServerTime.get():getServerTime()

	if var_5_1 < var_5_0.start_time and var_5_0.is_open == 0 then
		arg_5_0:addMsgLabel(var_0_2:translation("SAKURA_NOT_OPEN"))

		return
	elseif var_5_1 > var_5_0.end_time and var_5_0.is_open == 0 then
		arg_5_0:addMsgLabel(var_0_2:translation("ACTIVITY_FINISHED"))

		return
	end

	arg_5_0.waitTimes = xyd.splitToNumber(xyd.tables.activityZongZiTable:times(arg_5_0.activity.details.day_count), "|")

	local var_5_2

	if arg_5_0.activity.details.gift_count == 1 then
		var_5_2 = 0
	elseif arg_5_0.activity.details.gift_count > 5 then
		local var_5_3 = var_0_2:translation("HAVE_EATEN")

		arg_5_0:addMsgLabel(var_5_3)

		return
	else
		var_5_2 = arg_5_0.activity.details.award_time + arg_5_0.waitTimes[arg_5_0.activity.details.gift_count] - var_5_1
	end

	if var_5_2 > 0 then
		arg_5_0:addWateTimeLabel(var_5_2)

		return
	else
		arg_5_0.container:getChildByName("box_right"):setVisible(true)
		arg_5_0.container:getChildByName("box_left"):setVisible(false)
		arg_5_0:setTouchBtn(true)
	end
end

function var_0_0.setTouchBtn(arg_6_0, arg_6_1)
	arg_6_0.canEat = arg_6_1

	for iter_6_0 = 1, var_0_3 do
		arg_6_0.container:getChildByName("zongzi" .. iter_6_0):removeAllChildren()
		arg_6_0.container:getChildByName("zongzi" .. iter_6_0):setTouchEnabled(true)
		arg_6_0.container:getChildByName("zongzi" .. iter_6_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				return true
			elseif arg_7_0.name == "ended" then
				if arg_6_0.canEat ~= true then
					local var_7_0 = var_0_2:translation("ZONGZI_NOTYET")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_7_0
					})

					return
				else
					if xyd.WindowManager.get():isWindowOpen("toast") then
						xyd.WindowManager.get():closeWindow("toast")
					end

					arg_6_0:getZongzi(iter_6_0)
				end
			end
		end)

		if arg_6_0.activity.details.rewarded_pos[iter_6_0] ~= 0 then
			arg_6_0.container:getChildByName("zongzi" .. iter_6_0):setVisible(false)
		else
			arg_6_0.container:getChildByName("zongzi" .. iter_6_0):setVisible(true)
		end
	end
end

function var_0_0.addWateTimeLabel(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1
	local var_8_1 = arg_8_0.container:getChildByName("box_left")
	local var_8_2 = var_8_1:getChildByName("message_node")
	local var_8_3 = xyd.timeFormatAsHMS(var_8_0)
	local var_8_4 = {
		size = 22,
		color = cc.c3b(220, 138, 0)
	}
	local var_8_5 = xyd.AssetLoader.get():loadLabel(var_8_4)

	var_8_5:setString(var_0_2:translation("SHOULD_WAIT"))

	local var_8_6 = {
		size = 22,
		color = cc.c3b(44, 157, 114)
	}
	local var_8_7 = xyd.AssetLoader.get():loadLabel(var_8_6)

	var_8_7:setString(var_8_3)

	local var_8_8 = xyd.AssetLoader.get():loadLabel(var_8_4)

	var_8_8:setString(var_0_2:translation("EAT_ZONGZi"))
	var_8_2:removeAllChildren()

	local var_8_9 = var_8_5:getContentSize().width
	local var_8_10 = var_8_7:getContentSize().width
	local var_8_11 = var_8_8:getContentSize().width
	local var_8_12 = var_8_2:getContentSize().height / 2

	var_8_5:addTo(var_8_2)
	var_8_5:setPosition(cc.p(10, var_8_12))
	var_8_7:addTo(var_8_2)
	var_8_7:setPosition(cc.p(20 + var_8_9, var_8_12))
	var_8_8:addTo(var_8_2)
	var_8_8:setPosition(cc.p(30 + var_8_9 + var_8_10, var_8_12))
	var_8_1:getChildByName("duihua_bg"):width(80 + var_8_9 + var_8_10 + var_8_11)
	var_8_1:getChildByName("message_node"):width(40 + var_8_9 + var_8_10 + var_8_11)

	if arg_8_0.handle then
		var_0_1.unscheduleGlobal(arg_8_0.handle)

		arg_8_0.handle = nil
	end

	arg_8_0:createTimeCount(var_8_0, var_8_7)
end

function var_0_0.addMsgLabel(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_0.container:getChildByName("box_left")
	local var_9_1 = var_9_0:getChildByName("message_node")

	var_9_1:removeAllChildren()

	local var_9_2 = {
		size = 22,
		color = cc.c3b(220, 138, 0)
	}
	local var_9_3 = xyd.AssetLoader.get():loadLabel(var_9_2)

	var_9_3:setString(arg_9_1)
	var_9_3:addTo(var_9_1)

	local var_9_4 = var_9_1:getContentSize().height / 2
	local var_9_5 = var_9_3:getContentSize().width

	var_9_0:getChildByName("duihua_bg"):width(55 + var_9_5)
	var_9_0:getChildByName("message_node"):width(10 + var_9_5)
	var_9_3:setPosition(cc.p(10, var_9_4))
end

function var_0_0.getZongzi(arg_10_0, arg_10_1)
	arg_10_0.activitiesModel:getActivityReward(arg_10_0.activity.table_id, arg_10_1, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK and arg_11_1.award.awards then
			local var_11_0 = {
				awards = arg_11_1.award.awards,
				zongzi_id = arg_11_1.zongzi_id
			}

			xyd.WindowManager.get():openWindow("eat_result", var_11_0)

			arg_10_0.activity.details = arg_11_1.activity_info

			arg_10_0:update()
			arg_10_0.activitiesModel:clearRedMarkState(arg_10_0.activity.table_id, 2)

			local var_11_1 = xyd.WindowManager.get():getWindow("activities")

			if var_11_1 then
				var_11_1:rightLayout()
			end
		end
	end)
end

function var_0_0.createTimeCount(arg_12_0, arg_12_1, arg_12_2)
	arg_12_0.handle = var_0_1.scheduleGlobal(function()
		arg_12_1 = arg_12_1 - 1

		if arg_12_1 <= 0 then
			var_0_1.unscheduleGlobal(arg_12_0.handle)
			arg_12_0:update()
		else
			local var_13_0 = xyd.timeFormatAsHMS(arg_12_1)

			if not tolua.isnull(arg_12_2) then
				arg_12_2:setString(var_13_0)
			else
				var_0_1.unscheduleGlobal(arg_12_0.handle)
			end
		end
	end, 1)
end

function var_0_0.release(arg_14_0, arg_14_1)
	var_0_0.super:release(arg_14_1)

	if arg_14_0.handle then
		var_0_1.unscheduleGlobal(arg_14_0.handle)

		arg_14_0.handle = nil
	end
end

return var_0_0
