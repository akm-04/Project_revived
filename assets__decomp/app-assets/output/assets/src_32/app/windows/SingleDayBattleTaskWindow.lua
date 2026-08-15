local var_0_0 = class("SingleDayBattleTaskWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = {
	FELLOW_MISSION = 2,
	SELF_MISSION = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.singleDay = xyd.ModelManager.get():loadModel(xyd.ModelType.SINGLE_DAY)
	arg_1_0.day = arg_1_2.day
	arg_1_0.missionCount = arg_1_2.mission_count
	arg_1_0.details = arg_1_0.singleDay.details

	arg_1_0:updateVarialbes()

	arg_1_0.bossModels = {}
end

function var_0_0.updateVarialbes(arg_2_0)
	arg_2_0.myInfo = arg_2_0.details.self_daily_infos[arg_2_0.day]
	arg_2_0.myMissionID = xyd.splitToNumber(arg_2_0.myInfo.my_missions, "|")[arg_2_0.missionCount]
	arg_2_0.myDispatchTime = xyd.splitToNumber(arg_2_0.myInfo.missions_dispatch_time, "|")[arg_2_0.missionCount]
	arg_2_0.myProgress = xyd.splitToNumber(arg_2_0.myInfo.missions_progress, "|")[arg_2_0.missionCount]
	arg_2_0.myMissionStatus = xyd.splitToNumber(arg_2_0.myInfo.missions_status, "|")[arg_2_0.missionCount]
	arg_2_0.myMissionTacit = xyd.splitToNumber(arg_2_0.myInfo.missions_tacit, "|")[arg_2_0.missionCount]
	arg_2_0.myChallengeTacit = arg_2_0.myInfo.my_challenge_tacit
	arg_2_0.myChallengeDamage = arg_2_0.myInfo.my_challenge_damage

	if arg_2_0.details.fellow_daily_infos then
		arg_2_0.fellowInfo = arg_2_0.details.fellow_daily_infos[arg_2_0.day]
		arg_2_0.fellowMissionID = xyd.splitToNumber(arg_2_0.fellowInfo.my_missions, "|")[arg_2_0.missionCount]
		arg_2_0.fellowDispatchTime = xyd.splitToNumber(arg_2_0.fellowInfo.missions_dispatch_time, "|")[arg_2_0.missionCount]
		arg_2_0.fellowProgress = xyd.splitToNumber(arg_2_0.fellowInfo.missions_progress, "|")[arg_2_0.missionCount]
		arg_2_0.fellowMissionStatus = xyd.splitToNumber(arg_2_0.fellowInfo.missions_status, "|")[arg_2_0.missionCount]
		arg_2_0.fellowMissionTacit = xyd.splitToNumber(arg_2_0.fellowInfo.missions_tacit, "|")[arg_2_0.missionCount]
		arg_2_0.fellowChallengeTacit = arg_2_0.fellowInfo.my_challenge_tacit
		arg_2_0.fellowChallengeDamage = arg_2_0.fellowInfo.my_challenge_damage
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

		arg_5_0:nodeByName("select_task_text1"):setString(string.format(var_0_1:translation("FINISHED_AT_TIME"), var_5_1 .. ":" .. var_5_2))
		arg_5_0:nodeByName("select_task_player"):setPositionX(arg_5_0:nodeByName("select_task_text"):getPositionX() + arg_5_0:nodeByName("select_task_text"):getContentSize().width + 5)
		arg_5_0:nodeByName("select_task_text1"):setPositionX(arg_5_0:nodeByName("select_task_player"):getPositionX() + arg_5_0:nodeByName("select_task_player"):getContentSize().width + 5)
	end

	local var_5_3 = xyd.tables.activitySingleMission
	local var_5_4 = xyd.splitToNumber(xyd.tables.activitySingle:mission(arg_5_0.day)[arg_5_0.missionCount], ",")

	if arg_5_0.bossModels then
		for iter_5_0 = #arg_5_0.bossModels, 1, -1 do
			arg_5_0.bossModels[iter_5_0]:removeSelf()
			table.remove(arg_5_0.bossModels, iter_5_0)
		end
	end

	for iter_5_1 = 1, 2 do
		local var_5_5 = var_5_4[iter_5_1]
		local var_5_6 = var_5_3:battleId(var_5_5)
		local var_5_7 = arg_5_0:nodeByName("task_container_" .. iter_5_1)
		local var_5_8 = xyd.tables.battle:fight1(var_5_6)[1]
		local var_5_9 = var_5_3:bossName(var_5_5)

		var_5_7:getChildByName("boss_name_" .. iter_5_1):setString(var_5_9)
		var_5_7:getChildByName("boss_name_" .. iter_5_1):enableOutline(cc.c4b(30, 77, 148, 255), 1)
		var_5_7:getChildByName("already_achieved_" .. iter_5_1):setVisible(false)

		if var_5_5 == arg_5_0.myMissionID then
			arg_5_0:initHero(var_5_7, var_5_8, iter_5_1, var_5_6, var_5_5, var_0_3.SELF_MISSION)
			arg_5_0:changeItemStatus(var_5_7, iter_5_1, true)
			arg_5_0:changeItemText(var_5_7, iter_5_1, arg_5_0.myChallengeDamage, arg_5_0.myChallengeTacit, arg_5_0.myMissionStatus, var_0_3.SELF_MISSION)
		elseif var_5_5 == arg_5_0.fellowMissionID then
			arg_5_0:initHero(var_5_7, var_5_8, iter_5_1, var_5_6, var_5_5, var_0_3.FELLOW_MISSION)
			arg_5_0:changeItemStatus(var_5_7, iter_5_1, true)
			arg_5_0:changeItemText(var_5_7, iter_5_1, arg_5_0.fellowChallengeDamage, arg_5_0.fellowChallengeTacit, arg_5_0.fellowMissionStatus, var_0_3.FELLOW_MISSION)
		else
			arg_5_0:initHero(var_5_7, var_5_8, iter_5_1, var_5_6, var_5_5)
			arg_5_0:changeItemStatus(var_5_7, iter_5_1, false)
			var_5_7:getChildByName("task_text_" .. iter_5_1):setString(var_0_1:translation("CHALLENAGE_BOSS"))
		end

		var_5_7:getChildByName("select_btn_" .. iter_5_1):addTouchEventListener(function(arg_6_0, arg_6_1)
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

function var_0_0.changeItemStatus(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	arg_8_1:getChildByName("text_harm_" .. arg_8_2):setVisible(arg_8_3)
	arg_8_1:getChildByName("text_harm_num_" .. arg_8_2):setVisible(arg_8_3)
	arg_8_1:getChildByName("text_tacit_" .. arg_8_2):setVisible(arg_8_3)
	arg_8_1:getChildByName("text_tacit_num_" .. arg_8_2):setVisible(arg_8_3)
	arg_8_1:getChildByName("select_btn_" .. arg_8_2):setVisible(not arg_8_3)
end

function var_0_0.changeItemText(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6)
	if arg_9_6 == var_0_3.SELF_MISSION then
		arg_9_1:getChildByName("task_text_" .. arg_9_2):setString(var_0_1:translation("CHALLENAGE_BOSS_SELF"))
	else
		arg_9_1:getChildByName("task_text_" .. arg_9_2):setString(var_0_1:translation("CHALLENAGE_BOSS_FELLOW"))
	end

	arg_9_1:getChildByName("text_harm_" .. arg_9_2):setString(var_0_1:translation("CHALLENAGE_BOSS_HARM"))
	arg_9_1:getChildByName("text_tacit_" .. arg_9_2):setString(var_0_1:translation("CHALLENAGE_BOSS_TACIT"))
	arg_9_1:getChildByName("text_harm_num_" .. arg_9_2):setString(arg_9_3)
	arg_9_1:getChildByName("text_tacit_num_" .. arg_9_2):setString(arg_9_4)

	if arg_9_5 == 1 or arg_9_3 > 0 then
		arg_9_1:getChildByName("already_achieved_" .. arg_9_2):setVisible(true)
		arg_9_1:getChildByName("already_achieved_" .. arg_9_2):setLocalZOrder(10)

		if arg_9_3 == 0 then
			arg_9_1:getChildByName("text_harm_num_" .. arg_9_2):setVisible(false)
			arg_9_1:getChildByName("text_harm_" .. arg_9_2):setVisible(false)
			arg_9_1:getChildByName("text_tacit_" .. arg_9_2):setPositionY(arg_9_1:getChildByName("text_tacit_" .. arg_9_2):getPositionY() + 10)
			arg_9_1:getChildByName("text_tacit_num_" .. arg_9_2):setPositionY(arg_9_1:getChildByName("text_tacit_num_" .. arg_9_2):getPositionY() + 10)
		end
	end
end

function var_0_0.initHero(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6)
	local var_10_0 = var_0_2.new()

	var_10_0:populateWithTableID(arg_10_2)

	local var_10_1 = var_10_0:getHeroModel()

	arg_10_1:addChild(var_10_1)
	var_10_1:setScale(0.75)

	local var_10_2 = cc.p(arg_10_1:getChildByName("node_hero_" .. arg_10_3):getPosition())

	var_10_1:setAnchorPoint(cc.p(0, 0.5))
	var_10_1:setPosition(cc.p(var_10_2))

	if arg_10_6 == var_0_3.SELF_MISSION and arg_10_0.myMissionID ~= 0 and arg_10_0.myMissionStatus == 0 and arg_10_0.myChallengeDamage == 0 then
		local var_10_3 = display.newNode()
		local var_10_4 = arg_10_1:getContentSize()

		var_10_3:setContentSize(var_10_4.width, var_10_4.height)
		var_10_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_10_3:addTo(arg_10_1)
		var_10_3:setPosition(cc.p(var_10_2))
		var_10_3:setTouchEnabled(true)
		var_10_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
			if arg_11_0.name == "began" then
				var_10_1:setScale(0.7)

				return true
			elseif arg_11_0.name == "ended" then
				var_10_1:setScale(0.75)

				local var_11_0 = {
					battleID = arg_10_4,
					missionID = arg_10_5
				}

				xyd.WindowManager.get():openWindow("single_day_battle_pre", var_11_0)
			end
		end)
	end

	table.insert(arg_10_0.bossModels, var_10_1)
end

return var_0_0
