local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.activityTwentyFourMission
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc:getValue("activity_twenty_four_mission_id")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
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

	arg_2_0.container = var_2_0:getChildByName("background")
	arg_2_0.index = arg_2_0.activity.details.base_info.cur_mission
	arg_2_0.missionList = arg_2_0.activity.details.mission_list

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:initText()
	arg_3_0:initBtn()

	local var_3_0 = arg_3_0.container:getChildByName("award_container")
	local var_3_1 = var_0_1:giftCode(arg_3_0.index)

	arg_3_0:rewardFormat(var_3_0, var_3_1)

	if arg_3_0.index == var_0_3 then
		local var_3_2 = var_3_0:getContentSize().height
		local var_3_3 = display.newNode()

		var_3_3:setContentSize(var_3_2, var_3_2)
		xyd.setItemAndAddTips(var_3_3, var_3_1)
		var_3_3:addTo(var_3_0)
		var_3_3:setAnchorPoint(cc.p(0, 0))
		var_3_3:setPosition(0, 0)
	end

	if arg_3_0.missionList[var_0_3].is_award ~= 0 then
		arg_3_0:hideProgress()
	end
end

function var_0_0.initText(arg_4_0)
	local var_4_0 = var_0_1:num(arg_4_0.index)

	arg_4_0.container:getChildByName("total_progress_text"):setString(var_0_2:translation("ACTIVITY_TWENTY_FOUR_TEXT_1"))
	arg_4_0.container:getChildByName("total_progress"):setString(arg_4_0.index .. "/" .. var_0_3)
	arg_4_0.container:getChildByName("mission_text"):setString(string.format(var_0_1:content(arg_4_0.index), var_4_0))
	arg_4_0.container:getChildByName("mission_progress"):setString(arg_4_0.missionList[arg_4_0.index].count .. "/" .. var_4_0)
	arg_4_0.container:getChildByName("mission_list_btn"):getChildByName("mission_list_text"):setString(var_0_2:translation("ACTIVITY_TWENTY_FOUR_TEXT_2"))
	arg_4_0.container:getChildByName("award_list_btn"):getChildByName("award_list_text"):setString(var_0_2:translation("ACTIVITY_TWENTY_FOUR_TEXT_3"))
end

function var_0_0.initBtn(arg_5_0)
	arg_5_0:initLingquBtn()
	arg_5_0.container:getChildByName("mission_list_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_5_0.container:getChildByName("mission_list_btn"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("activity_twenty_four_mission_list")
		end
	end)
	arg_5_0.container:getChildByName("award_list_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_5_0.container:getChildByName("award_list_btn"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("activity_twenty_four_mission_award")
		end
	end)
	arg_5_0.container:getChildByName("rule_btn"):setTouchEnabled(true)
	arg_5_0.container:getChildByName("rule_btn"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "RULE_STATEMENT",
				rule = "ACTIVITY_TWENTY_FOUR_RULE"
			})
		end

		return true
	end)
end

function var_0_0.initLingquBtn(arg_9_0)
	local var_9_0 = arg_9_0.container:getChildByName("lingqu_btn")
	local var_9_1 = false

	if arg_9_0.missionList[arg_9_0.index].count >= var_0_1:num(arg_9_0.index) then
		var_9_1 = true
	end

	local var_9_2
	local var_9_3

	if arg_9_0.index == 2 then
		var_9_2 = "time_travel"
		var_9_3 = xyd.FunctionClick.TIME_TRAVEL
	elseif arg_9_0.index == 4 or arg_9_0.index == 10 then
		var_9_2 = "fumo"
		var_9_3 = xyd.FunctionID.ID_FUMO
	elseif arg_9_0.index == 9 then
		var_9_2 = "march"
		var_9_3 = xyd.FunctionID.ID_MARCH
	end

	local var_9_4 = arg_9_0.selfPlayer:isFuncOpen(var_9_3)

	if var_9_1 then
		if arg_9_0.index ~= var_0_3 then
			var_9_0:getChildByName("lingqu_text"):setString(var_0_2:translation("OBTAIN"))
		else
			var_9_0:getChildByName("lingqu_text"):setString(var_0_2:translation("ACTIVITY_TWENTY_FOUR_TEXT_7"))
		end
	elseif var_9_4 then
		var_9_0:getChildByName("lingqu_text"):setString(var_0_2:translation("ACTIVITY_TWENTY_FOUR_TEXT_8"))
	else
		var_9_0:getChildByName("lingqu_text"):setString(var_0_2:translation("OBTAIN"))
		var_9_0:setBright(false)
		var_9_0:setTouchEnabled(false)
	end

	var_9_0:addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(var_9_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if var_9_1 then
				if arg_9_0.index ~= var_0_3 then
					arg_9_0.activitiesModel:getActivityReward2(xyd.Activities.TwentyFourMission, arg_9_0.index, nil, function(arg_11_0, arg_11_1)
						if arg_11_0 == xyd.error.OK and arg_11_1.awards then
							arg_9_0.selfPlayer:handleRewards(arg_11_1.awards)
							dump(arg_11_1)

							arg_9_0.index = arg_11_1.base_info.cur_mission
							arg_9_0.activity.details.base_info.cur_mission = arg_11_1.base_info.cur_mission

							arg_9_0:layout()

							local var_11_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
							local var_11_1 = {
								activity_id = xyd.Activities.TwentyFourMission
							}

							arg_9_0.activitiesModel:loadSingleActivity(var_11_1, function(arg_12_0, arg_12_1)
								if arg_12_0 == xyd.error.OK then
									var_11_0:refreshRedMark()

									local var_12_0 = xyd.WindowManager.get():getWindow("activities")

									if var_12_0 and not tolua.isnull(var_12_0) then
										var_12_0:rightLayout()
									end
								end
							end)
						end
					end)
				else
					local var_10_0 = {
						canAward = true,
						activity = arg_9_0
					}

					xyd.WindowManager.get():openWindow("activity_twenty_four_mission_award", var_10_0)
				end
			elseif var_9_4 then
				if var_9_2 == "march" then
					local var_10_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

					if var_10_1.mapInfo == nil then
						var_10_1:loadMarchInfo({}, function(arg_13_0)
							if arg_13_0 == xyd.error.OK then
								xyd.WindowManager.get():openWindow(var_9_2)
							end
						end)
					else
						xyd.WindowManager.get():openWindow(var_9_2)
					end
				elseif var_9_2 == "summon" then
					arg_9_0.selfPlayer:loadSummonInfo(nil, function()
						xyd.WindowManager.get():openWindow("summon")
					end, true)
				else
					xyd.WindowManager.get():openWindow(var_9_2)
				end

				local var_10_2 = xyd.WindowManager.get():getWindow("activities")

				if var_10_2 then
					xyd.WindowManager.get():closeWindow(var_10_2)
				end
			end
		end
	end)
end

function var_0_0.hideProgress(arg_15_0)
	arg_15_0.container:getChildByName("lingqu_btn"):setVisible(false)
	arg_15_0.container:getChildByName("mission_progress"):setVisible(false)
	arg_15_0.container:getChildByName("has_get"):setVisible(true)
end

return var_0_0
