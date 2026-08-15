local var_0_0 = class("SingleDayPartnerDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.singleDay = xyd.ModelManager.get():loadModel(xyd.ModelType.SINGLE_DAY)
	arg_1_0.details = arg_1_0.singleDay.details
	arg_1_0.myBaseInfo = arg_1_0.details.self_base_info
	arg_1_0.fellow = arg_1_0.details.fellow_base_info
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = {
		avatar_id = arg_4_0.fellow.avatar_id,
		avatar_frame_id = arg_4_0.fellow.avatar_frame_id
	}

	xyd.setPlayerAvatar(arg_4_0:nodeByName("avtar_container"), var_4_0)
	arg_4_0:nodeByName("name_txt"):setString(arg_4_0.fellow.player_name)
	arg_4_0:nodeByName("region_txt"):setString("S" .. xyd.getPlayerRegion(arg_4_0.fellow.player_id))
	arg_4_0:nodeByName("region_txt"):setPositionX(arg_4_0:nodeByName("name_txt"):getPositionX() + arg_4_0:nodeByName("name_txt"):getContentSize().width + 20)
	arg_4_0.socialSystem:setOnlineState(arg_4_0:nodeByName("friend_state_txt"), arg_4_0.fellow)

	if arg_4_0.fellow.guild_id and arg_4_0.fellow.guild_id ~= 0 then
		arg_4_0:nodeByName("guild_txt"):setString(arg_4_0.fellow.guild_name)
	else
		arg_4_0:nodeByName("guild_txt"):setString(var_0_1:translation("GUILD_CHAT_ALERT"))
	end

	arg_4_0:nodeByName("complete_task_txt"):setString(arg_4_0.fellow.mission_count)
	arg_4_0:nodeByName("cooprate_task_txt"):setString(arg_4_0.fellow.fellow_mission_count)
	arg_4_0:nodeByName("agreement_txt"):setString(math.ceil(arg_4_0.myBaseInfo.shared_tacit))
	arg_4_0:nodeByName("guild_text"):setString(var_0_1:translation("FROM_GUILD"))
	arg_4_0:nodeByName("complete_task_text"):setString(var_0_1:translation("COMPLETE_TASK_NUM_TEXT"))
	arg_4_0:nodeByName("cooprate_task_text"):setString(var_0_1:translation("COOPERATE_TASK_NUM_TEXT"))
	arg_4_0:nodeByName("agreement_text"):setString(var_0_1:translation("SHARED_AGREEMENT_TEXT"))
	arg_4_0:nodeByName("cost_txt"):setString(string.format(var_0_1:translation("REMOVE_FELLOW_COST"), arg_4_0:getCost()))

	if arg_4_0.myBaseInfo.remove_apply ~= xyd.RemoveApplyState.Rejected then
		arg_4_0:nodeByName("force_remove_btn"):setVisible(false)
		arg_4_0:nodeByName("cost_txt"):setVisible(false)
		arg_4_0:nodeByName("remove_btn"):setPositionX(arg_4_0:nodeByName("container"):getContentSize().width / 2)
	end

	if arg_4_0.myBaseInfo.remove_apply == xyd.RemoveApplyState.Sending or arg_4_0.myBaseInfo.remove_apply == xyd.RemoveApplyState.Rejected then
		arg_4_0:nodeByName("remove_btn"):setBright(false)
		arg_4_0:nodeByName("remove_btn"):setTouchEnabled(false)
		arg_4_0:nodeByName("remove_fellow_text"):setVisible(false)
	else
		arg_4_0:nodeByName("remove_btn"):setBright(true)
		arg_4_0:nodeByName("remove_btn"):setTouchEnabled(true)
		arg_4_0:nodeByName("remove_fellow_text"):setVisible(true)
	end

	arg_4_0:nodeByName("chat_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.socialSystem:isInFriendList(arg_4_0.fellow.player_id) then
				local var_5_0 = xyd.WindowManager.get():openWindow("social_system")

				var_5_0.currentFriend = arg_4_0.fellow

				var_5_0:swapWindowState(6)
			else
				local var_5_1 = xyd.WindowManager.get():openWindow("chat")

				if var_5_1 then
					var_5_1:updatePersonLabel(arg_4_0.fellow.player_name)

					var_5_1.toPlayerID = arg_4_0.fellow.player_id
				end
			end

			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("remove_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("FELLOW_APPLY_SURE2"), function()
				local var_7_0 = {}

				var_7_0.op_type = 1

				arg_4_0.singleDay:removeFellow(var_7_0, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_4_0.details.self_base_info = arg_8_1.self_base_info

						arg_4_0:nodeByName("remove_btn"):setBright(false)
						arg_4_0:nodeByName("remove_btn"):setTouchEnabled(false)
						arg_4_0:nodeByName("remove_fellow_text"):setVisible(false)

						local var_8_0 = xyd.WindowManager.get():getWindow("single_day")

						if var_8_0 and not tolua.isnull(var_8_0) then
							var_8_0:update()
						end
					end
				end)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
	arg_4_0:nodeByName("force_remove_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.selfPlayer.crystal < arg_4_0:getCost() then
				local var_9_0 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
					local var_10_0 = {}

					var_10_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
				end, nil, nil, arg_4_0.colorMode)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					string.format(var_0_1:translation("FORCE_REMOVE_FELLOW_SURE"), arg_4_0:getCost()),
					var_0_1:translation("FELLOW_APPLY_SURE2")
				}, function()
					local var_11_0 = {}

					var_11_0.op_type = 2

					arg_4_0.singleDay:removeFellow(var_11_0, function(arg_12_0, arg_12_1)
						if arg_12_0 == xyd.error.OK then
							arg_4_0.details.self_base_info = arg_12_1.self_base_info
							arg_4_0.details.self_daily_infos = arg_12_1.self_daily_infos

							local var_12_0 = xyd.WindowManager.get():getWindow("single_day")

							if var_12_0 and not tolua.isnull(var_12_0) then
								var_12_0:update()
							end

							xyd.WindowManager.get():closeWindow(arg_4_0)
						end
					end)
				end, nil, nil, arg_4_0.colorMode)
			end
		end
	end)
end

function var_0_0.getCost(arg_13_0)
	return math.ceil(xyd.tables.misc.singleRemovePartnerParams1 + xyd.tables.misc.singleRemovePartnerParams2 * arg_13_0.myBaseInfo.tacit)
end

return var_0_0
