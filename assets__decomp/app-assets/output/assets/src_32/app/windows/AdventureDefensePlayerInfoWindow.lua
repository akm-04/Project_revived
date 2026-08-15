local var_0_0 = class("AdventureDefensePlayerInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Pet")
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.adventureEvent
local var_0_5 = {
	CAN_ADD = 1,
	IN_BLACK = 3,
	IN_FRIEND = 2,
	FULL_FRIEND = 4
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_1_0.playerInfo = arg_1_2.player_info
	arg_1_0.playerInfo.callback = nil
	arg_1_0.playerInfo.playerInfo = arg_1_0.playerInfo
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName("btn_add_friend"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = arg_3_0:checkCanAddFriend(arg_3_0.playerInfo.player_id)

			if var_4_0 == var_0_5.CAN_ADD then
				local var_4_1 = {
					player_id = arg_3_0.playerInfo.player_id
				}

				arg_3_0.socialSystem:requestFriend(var_4_1, function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_3:translation("SEND_FRIEND_APPLY_SUCCEED")
						})
						arg_3_0:nodeByName("btn_add_friend"):setTouchEnabled(false)
						arg_3_0:nodeByName("btn_add_friend"):setBright(false)
					end
				end)
			else
				local var_4_2
				local var_4_3 = arg_3_0.playerInfo.player_name

				if var_4_0 == var_0_5.IN_FRIEND then
					var_4_2 = string.format(var_0_3:translation("SOMEONE_IN_FRIEND"), var_4_3)
				elseif var_4_0 == var_0_5.IN_BLACK then
					var_4_2 = string.format(var_0_3:translation("SOMEONE_IN_BLACK"), var_4_3)
				elseif var_4_0 == var_0_5.FULL_FRIEND then
					var_4_2 = var_0_3:translation("FRIEND_NUM_LIMIT_TIPS")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_4_2
				})
			end
		end
	end)
	arg_3_0:nodeByName("btn_kick"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			if arg_3_0.adventureEvent:checkisBattle(arg_3_0.playerInfo.player_id) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("ADVENTURE_MONSTER_CANNOT_KICK")
				})
			else
				local var_6_0 = string.format(var_0_3:translation("ILLUSION_TEAM_TIPS_7"), arg_3_0.playerInfo.player_name)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
					local var_7_0 = {
						player_id = arg_3_0.playerInfo.player_id,
						table_id = xyd.AdventureEventType.DEFENSE
					}

					arg_3_0.adventureEvent:kickMember(var_7_0, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							xyd.WindowManager.get():closeWindow(arg_3_0.name)
						end
					end)
				end, nil, nil, arg_3_0.colorMode)
			end
		end
	end)
end

function var_0_0.checkCanAddFriend(arg_9_0, arg_9_1)
	if arg_9_0.socialSystem:isInFriendList(arg_9_1) then
		return var_0_5.IN_FRIEND
	elseif arg_9_0.socialSystem:isInBlackList(arg_9_1) then
		return var_0_5.IN_BLACK
	elseif #arg_9_0.socialSystem.friendlist >= xyd.tables.misc.maxFriendNum then
		return var_0_5.FULL_FRIEND
	else
		return var_0_5.CAN_ADD
	end
end

function var_0_0.didClose(arg_10_0, arg_10_1)
	var_0_0.super:didClose(arg_10_1)
end

function var_0_0.layout(arg_11_0)
	arg_11_0:nodeByName("text_name"):setString(arg_11_0.playerInfo.player_name)

	local var_11_0 = arg_11_0.playerInfo

	xyd.setPlayerAvatar(arg_11_0:nodeByName("avatar"), var_11_0)

	if arg_11_0.playerInfo.conquer_lev and arg_11_0.playerInfo.conquer_lev > 0 then
		local var_11_1 = {
			x = -3,
			y = 2
		}

		xyd.setConquerLev(arg_11_0.playerInfo.conquer_lev, arg_11_0:nodeByName("text_lev"), arg_11_0:nodeByName("dengjiquan"), var_11_1, false, 0.9, "conquer_bg", arg_11_0.playerInfo.conquer_loop_id)
	else
		if arg_11_0:nodeByName("conquer_bg") then
			arg_11_0:removeChildByName("conquer_bg")
		end

		arg_11_0:nodeByName("dengjiquan"):setVisible(true)
		arg_11_0:nodeByName("text_lev"):setString(arg_11_0.playerInfo.lev)
	end

	arg_11_0:nodeByName("text_region"):setString("S" .. xyd.getPlayerRegion(arg_11_0.playerInfo.player_id))
	arg_11_0:nodeByName("text_guild_name"):setString(arg_11_0.playerInfo.guild_name)
end

return var_0_0
