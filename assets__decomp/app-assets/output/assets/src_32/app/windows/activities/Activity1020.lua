local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
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
	var_2_0:setPosition(0, 0)

	local var_2_1 = var_2_0:getChildByName("container")

	var_2_1:getChildByName("left_time_txt"):setString(var_0_1:translation("TEAM_DRINK_LEFT_TIME"))

	local var_2_2 = "skeletons/ui_effect/activity_effect_hero/activity_effect_hero"
	local var_2_3 = var_2_1:getChildByName("zhangchunhua")

	var_2_3:setLocalZOrder(10)
	var_2_1:getChildByName("condition_3"):setLocalZOrder(10)

	local var_2_4 = var_2_2 .. ".json"
	local var_2_5 = var_2_2 .. ".atlas"
	local var_2_6 = var_0_2.new(var_2_4, var_2_5, 1)

	var_2_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_2_6:setLocalZOrder(var_2_1:getChildByName("1020_bg"):getLocalZOrder())
	var_2_6:setPosition(var_2_3:getPositionX(), var_2_3:getPositionY())
	var_2_6:addTo(var_2_1)
	var_2_6:play(nil, true)
	var_2_1:getChildByName("activity_desc"):setString(xyd.tables.activities:desc(arg_2_0.activity.table_id))

	local var_2_7 = var_2_1:getChildByName("award_btn")

	if xyd.ServerTime.get():getServerTime() >= arg_2_0.activity.details.end_time then
		var_2_7:setVisible(true)

		if arg_2_0.activity.details.is_awarded == 1 then
			var_2_7:setTouchEnabled(false)
			var_2_7:setBright(false)
			var_2_1:getChildByName("already_get_gray"):setVisible(true)
			var_2_7:getChildByName("get_reward_txt"):setVisible(false)
		else
			var_2_7:setTouchEnabled(true)
			var_2_7:setBright(true)
			var_2_1:getChildByName("already_get_gray"):setVisible(false)
			var_2_7:getChildByName("get_reward_txt"):setVisible(true)
		end
	else
		var_2_7:setVisible(false)
		var_2_1:getChildByName("already_get_gray"):setVisible(false)
	end

	var_2_7:addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			local var_3_0 = arg_2_0.idx

			arg_2_0.activitiesModel:getActivityReward(arg_2_0.activity.table_id, nil, function(arg_4_0, arg_4_1)
				if arg_4_0 == xyd.error.OK then
					xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_4_1.awards)

					if var_2_7 and not tolua.isnull(var_2_7) then
						var_2_7:setVisible(true)
						var_2_7:setTouchEnabled(false)
						var_2_7:setBright(false)
						var_2_7:getChildByName("get_reward_txt"):setVisible(false)
					end

					if var_2_1 and not tolua.isnull(var_2_1) then
						var_2_1:getChildByName("already_get_gray"):setVisible(true)
					end

					local var_4_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

					if arg_2_0.activity then
						var_4_0:clearRedMarkState(arg_2_0.activity.table_id, 2)
					end

					local var_4_1 = var_4_0:getActivitiesList()

					if var_3_0 and var_4_1[var_3_0] and var_4_1[var_3_0].details then
						var_4_1[var_3_0].details.is_awarded = 1

						local var_4_2 = xyd.WindowManager.get():getWindow("activities")

						if var_4_2 and var_4_2.rightItems then
							var_4_2:updateRightCell(var_4_1[var_3_0].table_id)
						end
					end
				end
			end)
		end
	end)

	local function var_2_8()
		if not arg_2_0.activity then
			return
		end

		local var_5_0 = arg_2_0.activity.details.end_time - xyd.ServerTime.get():getServerTime()
		local var_5_1 = string.format(var_0_1:translation("ACTIVITY_LEFT_TIME"), math.floor(var_5_0 / 86400), math.floor(var_5_0 % 86400 / 3600), math.floor(var_5_0 % 86400 % 3600 / 60))
		local var_5_2 = xyd.WindowManager.get():getWindow("activities")

		if var_5_2 and var_5_2.count == arg_2_0.idx then
			if var_5_0 <= 0 then
				var_2_1:getChildByName("left_time"):setString(var_0_1:translation("SEVEN_GOAL_FINISHED"))

				if arg_2_0.handle then
					var_0_3.unscheduleGlobal(arg_2_0.handle)
				end
			else
				var_2_1:getChildByName("left_time"):setString(var_5_1)
			end
		elseif arg_2_0.handles and arg_2_0.handles[arg_2_0.activity.table_id] then
			var_0_3.unscheduleGlobal(arg_2_0.handles[arg_2_0.activity.table_id])
		end
	end

	var_2_8()

	arg_2_0.handle = var_0_3.scheduleGlobal(var_2_8, 5)

	for iter_2_0 = 1, 3 do
		var_2_1:getChildByName("condition_" .. iter_2_0):setString(xyd.tables.activityLevelUp:name(iter_2_0))

		local var_2_9 = var_2_1:getChildByName("btn_" .. iter_2_0)

		var_2_9:setLocalZOrder(10)
		var_2_9:addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				local var_6_0 = {
					giftCode = xyd.tables.activityLevelUp:gift(iter_2_0),
					lev = xyd.tables.activityLevelUp:level(iter_2_0),
					count = iter_2_0
				}

				xyd.WindowManager.get():openWindow("seven_goals_awards", var_6_0)
			end
		end)
	end
end

function var_0_0.release(arg_7_0)
	if arg_7_0.handle then
		var_0_3.unscheduleGlobal(arg_7_0.handle)
	end

	var_0_0.super:release()
end

return var_0_0
