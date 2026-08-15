local var_0_0 = class("SingleDayTaskWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.singleDay = xyd.ModelManager.get():loadModel(xyd.ModelType.SINGLE_DAY)
	arg_1_0.day = arg_1_2.day
	arg_1_0.missionCount = arg_1_2.mission_count
	arg_1_0.details = arg_1_0.singleDay.details

	arg_1_0:updateVarialbes()
end

function var_0_0.updateVarialbes(arg_2_0)
	arg_2_0.myInfo = arg_2_0.details.self_daily_infos[arg_2_0.day]
	arg_2_0.myMissionID = xyd.splitToNumber(arg_2_0.myInfo.my_missions, "|")[arg_2_0.missionCount]
	arg_2_0.myDispatchTime = xyd.splitToNumber(arg_2_0.myInfo.missions_dispatch_time, "|")[arg_2_0.missionCount]
	arg_2_0.myProgress = xyd.splitToNumber(arg_2_0.myInfo.missions_progress, "|")[arg_2_0.missionCount]

	if arg_2_0.details.fellow_daily_infos then
		arg_2_0.fellowInfo = arg_2_0.details.fellow_daily_infos[arg_2_0.day]
		arg_2_0.fellowMissionID = xyd.splitToNumber(arg_2_0.fellowInfo.my_missions, "|")[arg_2_0.missionCount]
		arg_2_0.fellowDispatchTime = xyd.splitToNumber(arg_2_0.fellowInfo.missions_dispatch_time, "|")[arg_2_0.missionCount]
		arg_2_0.fellowProgress = xyd.splitToNumber(arg_2_0.fellowInfo.missions_progress, "|")[arg_2_0.missionCount]
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.layout(arg_5_0)
	if arg_5_0.myMissionID == 0 then
		arg_5_0:nodeByName("select_task_text"):setString(var_0_1:translation("SELECT_TASK_TEXT1"))
		arg_5_0:nodeByName("select_task_player"):setVisible(false)
		arg_5_0:nodeByName("select_task_text1"):setVisible(false)
	else
		arg_5_0:nodeByName("select_task_player"):setVisible(true)
		arg_5_0:nodeByName("select_task_text1"):setVisible(true)
		arg_5_0:nodeByName("select_task_text"):setString(var_0_1:translation("TASK_SELECTED_TEXT"))

		local var_5_0 = arg_5_0.myDispatchTime

		if arg_5_0.myDispatchTime ~= 0 then
			arg_5_0:nodeByName("select_task_player"):setString(arg_5_0.selfPlayer.playerName)
		else
			var_5_0 = arg_5_0.fellowDispatchTime

			arg_5_0:nodeByName("select_task_player"):setString(arg_5_0.details.fellow_base_info.player_name)
		end

		local var_5_1 = math.floor(var_5_0 % 86400 / 3600)

		if var_5_1 < 10 then
			var_5_1 = 0 .. var_5_1
		end

		local var_5_2 = math.floor(var_5_0 % 3600 / 60)

		if var_5_2 < 10 then
			var_5_2 = 0 .. var_5_2
		end

		arg_5_0:nodeByName("select_task_text1"):setString(string.format(var_0_1:translation("FINISHED_AT_TIME"), var_5_1 .. ":" .. var_5_2))
		arg_5_0:nodeByName("select_task_player"):setPositionX(arg_5_0:nodeByName("select_task_text"):getPositionX() + arg_5_0:nodeByName("select_task_text"):getContentSize().width + 5)
		arg_5_0:nodeByName("select_task_text1"):setPositionX(arg_5_0:nodeByName("select_task_player"):getPositionX() + arg_5_0:nodeByName("select_task_player"):getContentSize().width + 5)
	end

	arg_5_0:nodeByName("get_agreement_text"):setString(var_0_1:translation("COMPlETE_GET_AGREEMENT"))
	arg_5_0:nodeByName("get_agreement_txt"):setString(xyd.tables.activitySingle:privity(arg_5_0.day)[arg_5_0.missionCount])
	arg_5_0:nodeByName("get_agreement_txt"):setPositionX(arg_5_0:nodeByName("get_agreement_text"):getPositionX() + arg_5_0:nodeByName("get_agreement_text"):getContentSize().width + 10)

	local var_5_3 = xyd.tables.activitySingleMission
	local var_5_4 = xyd.splitToNumber(xyd.tables.activitySingle:mission(arg_5_0.day)[arg_5_0.missionCount], ",")

	for iter_5_0 = 1, 2 do
		local var_5_5 = var_5_4[iter_5_0]
		local var_5_6 = xyd.tables.activitySingleMission:req(var_5_5)[arg_5_0.day]
		local var_5_7 = arg_5_0:nodeByName("task_container" .. iter_5_0)

		var_5_7:getChildByName("already_achieved"):setVisible(false)
		var_5_7:getChildByName("select_btn"):setVisible(false)

		if var_5_5 == arg_5_0.myMissionID then
			var_5_7:getChildByName("select_btn"):setVisible(false)
			var_5_7:getChildByName("task_text"):setString(var_0_1:translation("MY_MISSION_TEXT"))
			var_5_7:getChildByName("progress_txt"):setString(arg_5_0.myProgress .. "/" .. var_5_6)

			if var_5_6 <= arg_5_0.myProgress then
				var_5_7:getChildByName("already_achieved"):setVisible(true)
			end
		elseif var_5_5 == arg_5_0.fellowMissionID then
			var_5_7:getChildByName("select_btn"):setVisible(false)
			var_5_7:getChildByName("task_text"):setString(var_0_1:translation("FELLOW_MISSION_TEXT"))
			var_5_7:getChildByName("progress_txt"):setString(arg_5_0.fellowProgress .. "/" .. var_5_6)

			if var_5_6 <= arg_5_0.fellowProgress then
				var_5_7:getChildByName("already_achieved"):setVisible(true)
			end
		else
			var_5_7:getChildByName("select_btn"):setVisible(true)
			var_5_7:getChildByName("task_text"):setString(var_0_1:translation("TASK_TEXT") .. iter_5_0)
			var_5_7:getChildByName("progress_txt"):setString(0 .. "/" .. var_5_6)
		end

		var_5_7:getChildByName("desc_txt"):setString(string.format(var_5_3:desc(var_5_5), var_5_3:req(var_5_5)[arg_5_0.day]))
		var_5_7:getChildByName("select_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_6_0 = {
					mission_count = arg_5_0.missionCount,
					mission_id = var_5_5
				}

				arg_5_0.singleDay:openMission(var_6_0, function(arg_7_0, arg_7_1)
					if arg_7_0 == xyd.error.OK then
						arg_5_0.details.self_daily_infos[arg_5_0.day] = arg_7_1.self_daily_info
						arg_5_0.details.fellow_daily_infos[arg_5_0.day] = arg_7_1.fellow_daily_info

						arg_5_0:updateVarialbes()
						arg_5_0:layout()

						local var_7_0 = xyd.WindowManager.get():getWindow("single_day")

						if var_7_0 and not tolua.isnull(var_7_0) then
							var_7_0:update()
						end

						if arg_7_1.is_selected and arg_7_1.is_selected == 1 then
							local var_7_1 = string.format(var_0_1:translation("TASK_SELECTED_BY_FELLOW"), arg_5_0.details.fellow_base_info.player_name)

							xyd.WindowManager.get():openWindow("toast", {
								message = var_7_1
							})
						end
					end
				end)
			end
		end)
	end
end

return var_0_0
