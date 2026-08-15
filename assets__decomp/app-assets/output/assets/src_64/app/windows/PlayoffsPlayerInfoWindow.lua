local var_0_0 = class("PlayoffsPlayerInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.playoffTimeTable
local var_0_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.PlayoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.player_id = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()

	if xyd.WindowManager.get():getWindow("playoffs_match_list") then
		xyd.WindowManager.get():closeWindow("playoffs_match_list")
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("REGION_ARENA_TEXT_20"))
	arg_4_0:nodeByName("server_label"):setString(var_0_1:translation("REGION_ARENA_TIP10"))
	arg_4_0:nodeByName("guild_label"):setString(var_0_1:translation("PLAYOFFS_PLAYER_INFO_TEXT1"))
	arg_4_0:nodeByName("manifesto_label"):setString(var_0_1:translation("PLAYOFFS_PLAYER_INFO_TEXT2"))
	arg_4_0:nodeByName("manifesto"):setString(arg_4_0.PlayoffsModel.players_info[tostring(arg_4_0.player_id)].dec)
	arg_4_0:nodeByName("server"):setString("(S" .. arg_4_0.PlayoffsModel.players_info[tostring(arg_4_0.player_id)].region .. ")" .. arg_4_0.PlayoffsModel.players_info[tostring(arg_4_0.player_id)].region_name)
	arg_4_0:nodeByName("player_name"):setString(arg_4_0.PlayoffsModel.players_info[tostring(arg_4_0.player_id)].player_name)
	arg_4_0:nodeByName("guild"):setString(arg_4_0.PlayoffsModel.players_info[tostring(arg_4_0.player_id)].guild_name)

	local var_4_0 = arg_4_0.PlayoffsModel.players_info[tostring(arg_4_0.player_id)]

	xyd.setPlayerAvatar(arg_4_0:nodeByName("player_icon"), {
		avatar_id = var_4_0.avatar_id,
		avatar_frame_id = var_4_0.avatar_frame_id,
		playerInfo = var_4_0
	})

	if var_4_0.conquer_lev and var_4_0.conquer_lev > 0 then
		xyd.setLev(arg_4_0:nodeByName("dengjiquan"), {
			conquerLev = var_4_0.conquer_lev
		})
	else
		xyd.setLev(arg_4_0:nodeByName("dengjiquan"), {
			lev = var_4_0.lev
		})
	end

	arg_4_0:nodeByName("renqi"):setString(var_0_1:translation("PLAYOFFS_GROUP_TEXT1") .. arg_4_0.PlayoffsModel.players_info[tostring(arg_4_0.player_id)].fans)
	arg_4_0:initDetailContainer()
	arg_4_0:nodeByName("text_record"):setString(var_0_1:translation("REGION_ARENA_TEXT_21"))
	arg_4_0:nodeByName("record_button"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.PlayoffsModel:getRecordList(arg_4_0.player_id, 3, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					local var_6_0 = {
						params = arg_6_1,
						player_id = arg_4_0.player_id
					}

					xyd.WindowManager:get():openWindow("playoffs_record", var_6_0)
				end
			end)
		end
	end)

	if arg_4_0.PlayoffsModel.support_info.support_player == var_0_5.playerID or arg_4_0.PlayoffsModel.playoff_info.stage >= 8 or arg_4_0.PlayoffsModel.playoff_info.stage >= 6 and arg_4_0.PlayoffsModel.playoff_info.sub_stage >= 1 then
		arg_4_0:nodeByName("support_button"):setVisible(false)
	end

	arg_4_0:nodeByName("text_support"):setString(var_0_1:translation("REGION_ARENA_TEXT_22"))
	arg_4_0:nodeByName("support_button"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			if arg_4_0.PlayoffsModel.support_info.support_player == tonumber(arg_4_0.player_id) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PLAYOFFS_SUPPORT_TEXT9")
				})
			elseif arg_4_0.PlayoffsModel.support_info.support_player == var_0_5.playerID then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PLAYOFFS_SUPPORT_TEXT10")
				})
			else
				local var_7_0 = {
					support_player = arg_4_0.player_id
				}

				arg_4_0.PlayoffsModel:support(var_7_0, function(arg_8_0)
					if arg_8_0 == xyd.error.OK then
						arg_4_0:nodeByName("renqi"):setString(var_0_1:translation("PLAYOFFS_GROUP_TEXT1") .. arg_4_0.PlayoffsModel.players_info[tostring(arg_4_0.player_id)].fans)
						arg_4_0:initDetailContainer()
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("PLAYOFFS_SUPPORT_TEXT8")
						})

						if xyd.WindowManager.get():getWindow("playoffs_group_detail") then
							xyd.WindowManager.get():getWindow("playoffs_group_detail"):updateFans()
						end
					end
				end)
			end
		end
	end)
	arg_4_0:nodeByName("text_schedule"):setString(var_0_1:translation("REGION_ARENA_TEXT_23"))
	arg_4_0:nodeByName("schedule_button"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_4_0.PlayoffsModel.playoff_info.stage >= 8 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PLAYOFFS_OVER")
				})
			elseif arg_4_0.PlayoffsModel.playoff_info.stage <= 2 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PLAYOFFS_NOT_OPEN")
				})
			else
				arg_4_0.PlayoffsModel:getMatchList(function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						local var_10_0 = arg_4_0.PlayoffsModel:matchList(tostring(arg_4_0.player_id))

						var_10_0.is_all = false

						xyd.WindowManager.get():openWindow("playoffs_match_list", var_10_0)
					end
				end)
			end
		end
	end)
	arg_4_0:nodeByName("text_history"):setString(var_0_1:translation("REGION_ARENA_TEXT_24"))
	arg_4_0:nodeByName("history_button"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0.PlayoffsModel:getBattleScoresInfo(arg_4_0.player_id, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					local var_12_0 = {
						herosInfo = arg_12_1.partner_info,
						totalFight = arg_12_1.arena_info.total_fight,
						winFight = arg_12_1.arena_info.win_times,
						kingPoint = arg_12_1.arena_info.point
					}

					var_12_0.is_other = true

					xyd.WindowManager.get():openWindow("battle_scores", var_12_0)
				end
			end)
		end
	end)

	if tonumber(var_0_5.playerID) == tonumber(arg_4_0.player_id) then
		arg_4_0:nodeByName("change_button"):setVisible(true)
		arg_4_0:nodeByName("text_change"):setString(var_0_1:translation("REGION_ARENA_TEXT_25"))
		arg_4_0:nodeByName("change_button"):addTouchEventListener(function(arg_13_0, arg_13_1)
			xyd.buttonScaleAnim(arg_13_0, arg_13_1)
			xyd.WindowManager.get():openWindow("playoffs_declaration")
		end)
	end
end

function var_0_0.updateDeclaration(arg_14_0, arg_14_1)
	arg_14_0:nodeByName("manifesto"):setString(arg_14_1)
end

function var_0_0.initDetailContainer(arg_15_0)
	local var_15_0 = tostring(arg_15_0.player_id)

	if var_0_5.playerID == arg_15_0.player_id then
		arg_15_0:nodeByName("detail_container"):setVisible(true)
		arg_15_0:nodeByName("detail_container_nosupport"):setVisible(false)
		arg_15_0:nodeByName("text_player_name"):setString("(S" .. arg_15_0.PlayoffsModel.players_info[var_15_0].region .. ")" .. arg_15_0.PlayoffsModel.players_info[tostring(arg_15_0.player_id)].player_name)
	elseif arg_15_0.PlayoffsModel.support_info.support_player ~= 0 then
		arg_15_0:nodeByName("detail_container"):setVisible(true)
		arg_15_0:nodeByName("detail_container_nosupport"):setVisible(false)
		arg_15_0:nodeByName("text_player_name"):setString("(S" .. arg_15_0.PlayoffsModel.players_info[tostring(arg_15_0.PlayoffsModel.support_info.support_player)].region .. ")" .. arg_15_0.PlayoffsModel.players_info[tostring(arg_15_0.PlayoffsModel.support_info.support_player)].player_name)
	else
		arg_15_0:nodeByName("detail_container"):setVisible(false)
		arg_15_0:nodeByName("detail_container_nosupport"):setVisible(true)
	end

	arg_15_0:nodeByName("text_1"):setString(string.format(var_0_1:translation("PLAYOFFS_SUPPORT_TEXT1"), var_0_4:project(arg_15_0.PlayoffsModel.support_info.support_player_stage)))
	arg_15_0:nodeByName("text_2"):setString(string.format(var_0_1:translation("PLAYOFFS_SUPPORT_TEXT2"), arg_15_0:calculateGold()))

	for iter_15_0 = 3, 7 do
		arg_15_0:nodeByName("text_" .. iter_15_0):setString(var_0_1:translation("PLAYOFFS_SUPPORT_TEXT" .. iter_15_0))
	end
end

function var_0_0.calculateGold(arg_16_0)
	local var_16_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	return var_16_0.lev * var_16_0.lev * 5000 - 580000 * var_16_0.lev + 18000000
end

return var_0_0
