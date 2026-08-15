local var_0_0 = class("PlayoffsScheduleMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.hero
local var_0_5 = import("app.model.Hero")
local var_0_6 = xyd.tables.playoffTimeTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.season = arg_1_0.regionArena:getSeasonCount()
	arg_1_0.PlayoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)

	if arg_1_0.PlayoffsModel.playoff_info.stage >= 8 and arg_1_0.regionArena.isClose and arg_1_0.regionArena.isClose == 0 then
		arg_1_0.season = arg_1_0.regionArena:getSeasonCount() - 1
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
	arg_3_0:init()
end

function var_0_0.init(arg_4_0)
	arg_4_0:initPanel()
	arg_4_0:registerListener()
	arg_4_0:checkHaveDec()
end

function var_0_0.initPanel(arg_5_0)
	if arg_5_0.PlayoffsModel.playoff_info.stage >= 7 then
		for iter_5_0 = 1, #arg_5_0.PlayoffsModel.battle_status["7"] do
			local var_5_0 = tostring(arg_5_0.PlayoffsModel.battle_status["7"][iter_5_0])

			arg_5_0:nodeByName("icon_winner"):setTouchSwallowEnabled(false)
			arg_5_0:nodeByName("icon_winner"):setTouchEnabled(true)
			xyd.setPlayerAvatar(arg_5_0:nodeByName("icon_winner"), {
				avatar_id = arg_5_0.PlayoffsModel.players_info[var_5_0].avatar_id,
				avatar_frame_id = arg_5_0.PlayoffsModel.players_info[var_5_0].avatar_frame_id
			})
			arg_5_0:nodeByName("icon_winner"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
				if arg_6_0.name == "ended" then
					print("7=========" .. iter_5_0)
					xyd.WindowManager:get():openWindow("playoffs_player_info", var_5_0)
				end

				return true
			end)
		end
	end

	if arg_5_0.PlayoffsModel.playoff_info.stage >= 6 then
		for iter_5_1 = 1, #arg_5_0.PlayoffsModel.battle_status["6"] do
			local var_5_1 = tostring(arg_5_0.PlayoffsModel.battle_status["6"][iter_5_1])

			arg_5_0:nodeByName("icon3_" .. iter_5_1):setTouchSwallowEnabled(false)
			arg_5_0:nodeByName("icon3_" .. iter_5_1):setTouchEnabled(true)
			xyd.setPlayerAvatar(arg_5_0:nodeByName("icon3_" .. iter_5_1), {
				avatar_id = arg_5_0.PlayoffsModel.players_info[var_5_1].avatar_id,
				avatar_frame_id = arg_5_0.PlayoffsModel.players_info[var_5_1].avatar_frame_id
			})
			arg_5_0:nodeByName("icon3_" .. iter_5_1):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
				if arg_7_0.name == "ended" then
					print("6=========" .. iter_5_1)
					xyd.WindowManager:get():openWindow("playoffs_player_info", var_5_1)
				end

				return true
			end)
		end
	end

	if arg_5_0.PlayoffsModel.playoff_info.stage >= 5 then
		for iter_5_2 = 1, #arg_5_0.PlayoffsModel.battle_status["5"] do
			local var_5_2 = tostring(arg_5_0.PlayoffsModel.battle_status["5"][iter_5_2])

			arg_5_0:nodeByName("icon2_" .. iter_5_2):setTouchSwallowEnabled(false)
			arg_5_0:nodeByName("icon2_" .. iter_5_2):setTouchEnabled(true)
			xyd.setPlayerAvatar(arg_5_0:nodeByName("icon2_" .. iter_5_2), {
				avatar_id = arg_5_0.PlayoffsModel.players_info[var_5_2].avatar_id,
				avatar_frame_id = arg_5_0.PlayoffsModel.players_info[var_5_2].avatar_frame_id
			})
			arg_5_0:nodeByName("icon2_" .. iter_5_2):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
				if arg_8_0.name == "ended" then
					xyd.WindowManager:get():openWindow("playoffs_player_info", var_5_2)
				end

				return true
			end)
		end
	end

	if arg_5_0.PlayoffsModel.playoff_info.stage >= 4 then
		for iter_5_3 = 1, #arg_5_0.PlayoffsModel.battle_status["4"] do
			local var_5_3 = tostring(arg_5_0.PlayoffsModel.battle_status["4"][iter_5_3])

			arg_5_0:nodeByName("icon1_" .. iter_5_3):setTouchSwallowEnabled(false)
			arg_5_0:nodeByName("icon1_" .. iter_5_3):setTouchEnabled(true)
			xyd.setPlayerAvatar(arg_5_0:nodeByName("icon1_" .. iter_5_3), {
				avatar_id = arg_5_0.PlayoffsModel.players_info[var_5_3].avatar_id,
				avatar_frame_id = arg_5_0.PlayoffsModel.players_info[var_5_3].avatar_frame_id
			})
			arg_5_0:nodeByName("icon1_" .. iter_5_3):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
				if arg_9_0.name == "ended" then
					xyd.WindowManager:get():openWindow("playoffs_player_info", var_5_3)
				end

				return true
			end)
		end
	end

	if arg_5_0.PlayoffsModel.playoff_info.stage >= 3 then
		-- block empty
	end
end

function var_0_0.layout(arg_10_0)
	local var_10_0 = xyd.tables.regionArenaLevel:getPlayerArenaLevel(arg_10_0.regionArena:getStar())
	local var_10_1

	if arg_10_0.season <= 10 then
		var_10_1 = var_0_1:translation("NUM_" .. arg_10_0.season)
	else
		var_10_1 = tostring(arg_10_0.season)
	end

	arg_10_0:nodeByName("text_title"):setString(string.format(var_0_1:translation("PLAYOFFS_SEASON"), var_10_1))
end

function var_0_0.registerListener(arg_11_0)
	if arg_11_0.PlayoffsModel.playoff_info.stage >= 2 then
		arg_11_0:nodeByName("apply_list"):setVisible(false)
		arg_11_0:nodeByName("apply_button"):setVisible(false)
		arg_11_0:nodeByName("text_status"):setString(var_0_6:project(arg_11_0.PlayoffsModel.playoff_info.stage))
	else
		arg_11_0:nodeByName("text_status"):setString(var_0_6:project(arg_11_0.PlayoffsModel.playoff_info.stage))
	end

	local var_11_0 = xyd.tables.regionArenaLevel:getPlayerArenaLevel(arg_11_0.regionArena:getStar())

	arg_11_0:nodeByName("text_match_list"):setString(var_0_1:translation("REGION_ARENA_TEXT_17"))
	arg_11_0:nodeByName("match_list_button"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			if arg_11_0.PlayoffsModel.playoff_info.stage >= 2 then
				arg_11_0.PlayoffsModel:getMatchList(function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						local var_13_0 = arg_11_0.PlayoffsModel:matchList()

						var_13_0.is_all = true

						if arg_11_0.PlayoffsModel.playoff_info.stage <= 2 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("PLAYOFFS_NOT_OPEN")
							})
						elseif arg_11_0.PlayoffsModel.playoff_info.stage >= 8 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("PLAYOFFS_OVER")
							})
						else
							xyd.WindowManager.get():openWindow("playoffs_match_list", var_13_0)
						end
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PLAYOFFS_NOT_OPEN")
				})
			end
		end
	end)
	arg_11_0:nodeByName("text_rule"):setString(var_0_1:translation("REGION_ARENA_TEXT_5"))
	arg_11_0:nodeByName("rule_button"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("playoffs_rule")
		end
	end)
	arg_11_0:nodeByName("text_apply"):setString(var_0_1:translation("REGION_ARENA_TEXT_18"))
	arg_11_0:nodeByName("apply_button"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			if arg_11_0.PlayoffsModel.playoff_info.stage == 1 then
				if arg_11_0.PlayoffsModel.player_info.is_signed == 0 then
					xyd.WindowManager.get():openWindow("playoffs_match_time")
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("PLAYOFFS_ALREADY_SIGNED")
					})
				end
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PLAYOFFS_NOT_SIGNED")
				})
			end
		end
	end)
	arg_11_0:nodeByName("text_apply_list"):setString(var_0_1:translation("REGION_ARENA_TEXT_19"))
	arg_11_0:nodeByName("apply_list"):addTouchEventListener(function(arg_16_0, arg_16_1)
		xyd.buttonScaleAnim(arg_16_0, arg_16_1)

		if arg_16_1 == ccui.TouchEventType.ended then
			local var_16_0 = {}

			xyd.Backend.get():request(xyd.mid.PLAYOFFS_GET_SIGN_LIST, var_16_0, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("playoffs_apply_list", arg_17_1)
				end
			end)
		end
	end)

	for iter_11_0 = 1, 8 do
		arg_11_0:nodeByName("group" .. iter_11_0):setTouchEnabled(true)
		arg_11_0:nodeByName("group" .. iter_11_0):setTouchSwallowEnabled(false)
		arg_11_0:nodeByName("group" .. iter_11_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
			if arg_18_0.name == "ended" then
				if arg_11_0.PlayoffsModel.playoff_info.stage >= 2 then
					arg_11_0.PlayoffsModel:getGroupDetail(iter_11_0, function(arg_19_0, arg_19_1)
						if arg_19_0 == xyd.error.OK then
							local var_19_0 = {
								group_detail = arg_19_1,
								groupid = iter_11_0
							}

							xyd.WindowManager.get():openWindow("playoffs_group_detail", var_19_0)
						end
					end)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("PLAYOFFS_NOT_OPEN")
					})
				end
			elseif arg_18_0.name == "began" then
				return true
			end

			return true
		end)
	end

	arg_11_0:nodeByName("schedule_list"):setTouchSwallowEnabled(false)
	arg_11_0:nodeByName("schedule_list"):setTouchEnabled(true)
	arg_11_0:nodeByName("schedule_list"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		print(arg_20_0.name)

		if arg_20_0.name == "ended" then
			xyd.WindowManager.get():openWindow("playoffs_schedule")
		elseif arg_20_0.name == "began" then
			return true
		end

		return true
	end)
end

function var_0_0.checkHaveDec(arg_21_0)
	if arg_21_0.PlayoffsModel.playoff_info.stage >= 2 and arg_21_0.PlayoffsModel:hasJoin() and arg_21_0.PlayoffsModel.player_info.have_dec_flag == 0 then
		xyd.WindowManager.get():openWindow("playoffs_declaration")
	end
end

return var_0_0
