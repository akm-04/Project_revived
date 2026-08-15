local var_0_0 = class("NewYearBlessingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	CAN_ADD = 1,
	IN_BLACK = 3,
	IN_FRIEND = 2,
	FULL_FRIEND = 4
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.message = arg_1_2.pray_msg
	arg_1_0.playerInfo = arg_1_2.pray_player
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 225))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_top"):setString(var_0_1:translation("NEW_YEAR_BLESSING_TIPS_7"))
	arg_4_0:nodeByName("text_blessing"):setString(arg_4_0.message)
	arg_4_0:nodeByName("text_lev"):setString(arg_4_0.playerInfo.lev)
	arg_4_0:nodeByName("text_name"):setString(arg_4_0.playerInfo.player_name)
	arg_4_0:nodeByName("text_region"):setString("S" .. arg_4_0.playerInfo.region)
	arg_4_0:initAvatar()
	arg_4_0:nodeByName("btn_send"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {}

			xyd.WindowManager.get():openWindow("input_new_year_blessing", var_5_0)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("btn_add_friend"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = arg_4_0:checkCanAddFriend()

			if var_6_0 == var_0_2.CAN_ADD then
				local var_6_1 = {
					player_id = arg_4_0.playerInfo.player_id
				}
				local var_6_2 = {
					data = var_6_1
				}

				xyd.WindowManager.get():openWindow("input_authentic_msg", var_6_2)
				xyd.WindowManager.get():closeWindow(arg_4_0)
			else
				local var_6_3

				if var_6_0 == var_0_2.IN_FRIEND then
					var_6_3 = string.format(var_0_1:translation("SOMEONE_IN_FRIEND"), arg_4_0.playerInfo.player_name)
				elseif var_6_0 == var_0_2.IN_BLACK then
					var_6_3 = string.format(var_0_1:translation("SOMEONE_IN_BLACK"), arg_4_0.playerInfo.player_name)
				elseif var_6_0 == var_0_2.FULL_FRIEND then
					var_6_3 = var_0_1:translation("FRIEND_NUM_LIMIT_TIPS")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_3
				})
			end
		end
	end)
end

function var_0_0.checkCanAddFriend(arg_7_0)
	if arg_7_0.socialSystem:isInFriendList(arg_7_0.playerInfo.player_id) then
		return var_0_2.IN_FRIEND
	elseif arg_7_0.socialSystem:isInBlackList(arg_7_0.playerInfo.player_id) then
		return var_0_2.IN_BLACK
	elseif #arg_7_0.socialSystem.friendlist >= xyd.tables.misc.maxFriendNum then
		return var_0_2.FULL_FRIEND
	else
		return var_0_2.CAN_ADD
	end
end

function var_0_0.initAvatar(arg_8_0)
	xyd.setAvatarClip(arg_8_0:nodeByName("avatar"), arg_8_0.playerInfo.avatar_id, 1)

	local var_8_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_8_0.playerInfo.avatar_frame_id and arg_8_0.playerInfo.avatar_frame_id ~= 0 then
		var_8_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_8_0.playerInfo.avatar_frame_id] .. ".png"
	end

	local var_8_1 = xyd.AssetLoader.get():loadSprite(var_8_0)
	local var_8_2 = arg_8_0:nodeByName("avatar_frame"):getContentSize()

	var_8_1:addTo(arg_8_0:nodeByName("avatar_frame"))
	var_8_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_1:setScale(0.75)
	var_8_1:setPosition(var_8_2.width / 2 - 1, var_8_2.height / 2 - 3)
end

function var_0_0.sendNewYearBlessing(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.ADD_NEWYEAR_WISH, var_9_0, function(arg_10_0, arg_10_1)
		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

return var_0_0
