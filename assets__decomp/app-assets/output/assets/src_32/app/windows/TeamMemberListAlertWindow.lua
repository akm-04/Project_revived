local var_0_0 = class("TeamMemberListAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.job = arg_1_2.job
	arg_1_0.pname = arg_1_2.pname
	arg_1_0.lev = arg_1_2.lev
	arg_1_0.avatar_id = arg_1_2.avatar_id
	arg_1_0.avatar_frame_id = arg_1_2.avatar_frame_id
	arg_1_0.seven_huoyue = arg_1_2.seven_huoyue
	arg_1_0.last_time = arg_1_2.last_time
	arg_1_0.player_id = arg_1_2.player_id
	arg_1_0.conquer_lev = arg_1_2.conquer_lev
	arg_1_0.conquer_loop_id = arg_1_2.conquer_loop_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_2_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	if arg_3_0.job == 0 then
		arg_3_0:nodeByName("job_text"):setString(var_0_3:translation("TEAM_MEMBER"))
	elseif arg_3_0.job == 1 then
		arg_3_0:nodeByName("job_text"):setString(var_0_3:translation("TEAM_PRESIDENT"))
	else
		arg_3_0:nodeByName("job_text"):setString(var_0_3:translation("TEAM_VICE_PRESIDENT"))
	end

	arg_3_0:nodeByName("seven_words"):setString(var_0_3:translation("TEAM_MEMBER_SEVEN_DAYS_ACTIVE"))
	arg_3_0:nodeByName("time_words"):setString(var_0_3:translation("TEAM_MEMBER_LAST_ENTER_TIME"))
	arg_3_0:nodeByName("level_text"):setString(arg_3_0.lev)
	arg_3_0:nodeByName("name_text"):setString(arg_3_0.pname)
	arg_3_0:nodeByName("seven_text"):setString(arg_3_0.seven_huoyue)

	local var_3_0 = ""
	local var_3_1 = xyd.ServerTime.get():getServerTime()
	local var_3_2 = os.date("%M", var_3_1)
	local var_3_3 = os.date("%H", var_3_1)
	local var_3_4 = os.date("%S", var_3_1)
	local var_3_5 = var_3_1 - var_3_2 * 60 - var_3_3 * 3600 - var_3_4
	local var_3_6 = os.date("%M", arg_3_0.last_time)
	local var_3_7 = os.date("%H", arg_3_0.last_time)
	local var_3_8 = os.date("%S", arg_3_0.last_time)
	local var_3_9 = var_3_5 - arg_3_0.last_time

	if var_3_9 <= 0 then
		var_3_0 = var_0_3:translation("TODAY") .. var_3_7 .. ":" .. var_3_6
	elseif var_3_9 <= 86400 then
		var_3_0 = var_0_3:translation("YESTERDAY") .. var_3_7 .. ":" .. var_3_6
	elseif var_3_9 <= 172800 then
		var_3_0 = var_0_3:translation("THE_DAY_BEFORE_YESTERDAY") .. var_3_7 .. ":" .. var_3_6
	else
		var_3_0 = string.format(var_0_3:translation("TEAM_MEMBER_N_DAYS_NOT_ONLINE"), math.ceil(var_3_9 / 86400))
	end

	local var_3_10 = var_0_2.new({
		size = 496
	})

	var_3_10:addTo(arg_3_0:nodeByName("line"))
	var_3_10:setAnchorPoint(0, 0.5)
	arg_3_0:nodeByName("time_text"):setString(var_3_0)

	local var_3_11 = {
		player_id = arg_3_0.player_id
	}

	xyd.setPlayerAvatar(arg_3_0:nodeByName("icon_container"), {
		showLevel = false,
		avatar_id = arg_3_0.avatar_id,
		avatar_frame_id = arg_3_0.avatar_frame_id,
		playerInfo = var_3_11
	})

	if arg_3_0.conquer_lev and arg_3_0.conquer_lev > 0 then
		local var_3_12 = {
			x = -1.5,
			y = 2.5
		}

		xyd.setConquerLev(arg_3_0.conquer_lev, arg_3_0:nodeByName("level_text"), arg_3_0:nodeByName("level_bg"), var_3_12, false, 0.75, nil, arg_3_0.conquer_loop_id)
	end

	arg_3_0:nodeByName("region"):setString("S" .. xyd.getPlayerRegion(arg_3_0.player_id))
	arg_3_0:nodeByName("add_friend_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("add_friend_btn"), eventType)

		if arg_4_1 == ccui.TouchEventType.ended then
			if arg_3_0.socialSystem:isInFriendList(arg_3_0.player_id) or arg_3_0.socialSystem:isInBlackList(arg_3_0.player_id) or arg_3_0.player_id == arg_3_0.selfPlayer.playerID then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("CANT_ADD_FRIEND")
				})

				return
			else
				if arg_3_0.socialSystem:getFriendsCount() >= xyd.tables.misc.friendNumberLimit then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("FRIEND_NUM_LIMIT_TIPS")
					})

					return
				end

				local var_4_0 = {
					data = {
						player_id = arg_3_0.player_id
					}
				}

				xyd.WindowManager.get():openWindow("input_authentic_msg", var_4_0)
			end
		end
	end)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
	var_0_0.super:didOpen(arg_5_1)
end

return var_0_0
