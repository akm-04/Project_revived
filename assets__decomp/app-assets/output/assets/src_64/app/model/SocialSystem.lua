local var_0_0 = class("SocialSystem", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = {
	ApplyYList = 2,
	BlackList = 4,
	FriendShip = 6,
	RecallFriend = 7,
	Chating = 8,
	NoticeMsg = 3,
	InviteFriend = 5,
	FriendList = 1
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.invite = xyd.ModelManager.get():loadModel(xyd.ModelType.INVITE_FRIENDS_INFOS)
	arg_1_0.messageManager = xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER)
	arg_1_0.isHasRedMark = false
	arg_1_0.blacklist = {}
	arg_1_0.friendlist = {}
	arg_1_0.requestlist = {}
	arg_1_0.noticelist = {}
	arg_1_0.currentBattleRound_ = 0
	arg_1_0.totalRound = 0
	arg_1_0.battleReport_ = {}
	arg_1_0.reportInvalid_ = {}
	arg_1_0.hasNext = false
	arg_1_0.isSelfChallenger = false
	arg_1_0.mode = 0
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.RELOAD, handler(arg_2_0, arg_2_0.reloadEvent_))
	arg_2_0:registerEvent(xyd.event.FRIEND_CHAT_MESSAGE, handler(arg_2_0, arg_2_0.onFriendChatMessage_))
	arg_2_0:registerEvent(xyd.event.UPDATE_MASTER_MISSION, handler(arg_2_0, arg_2_0.reloadMissionEvent_))
	arg_2_0:registerEvent(xyd.event.REFRESH_MASTER, handler(arg_2_0, arg_2_0.refreshMasterEvent_))
end

function var_0_0.reloadEvent_(arg_3_0, arg_3_1)
	if arg_3_1.params then
		local var_3_0

		if arg_3_1.params.friend_list == 1 then
			var_3_0 = xyd.FriendInfoType.FRIEND
		elseif arg_3_1.params.friend_req == 1 then
			var_3_0 = xyd.FriendInfoType.REQUEST
		elseif arg_3_1.params.friend_notice == 1 then
			var_3_0 = xyd.FriendInfoType.NOTICE

			arg_3_0:setIsHasNewNoticeState(1)
		end

		if arg_3_1.params.player_id > 0 then
			arg_3_0:setPlayerOnlineState(arg_3_1.params.player_id, 1)
		end

		local var_3_1 = {
			list_type = var_3_0
		}

		arg_3_0:loadFriendInfo(var_3_1, function(arg_4_0, arg_4_1)
			if arg_4_0 == xyd.error.OK then
				local var_4_0 = xyd.WindowManager.get():getWindow("social_system")

				if var_4_0 and not tolua.isnull(var_4_0) then
					if var_4_0.windowState == var_0_4.FriendList and var_3_0 == xyd.FriendInfoType.FRIEND or var_4_0.windowState == var_0_4.ApplyYList and var_3_0 == xyd.FriendInfoType.REQUEST or var_4_0.windowState == var_0_4.NoticeMsg then
						var_4_0:updateRightList()
					else
						var_4_0:updateRedMark()
					end

					if var_3_0 == xyd.FriendInfoType.NOTICE then
						var_4_0:updateReadNoticeBtnShow()
					end
				else
					arg_3_0:refreshRedMark()
					arg_3_0:refreshNoticeCount()
				end
			end
		end)
	end
end

function var_0_0.setPlayerOnlineState(arg_5_0, arg_5_1, arg_5_2)
	if not arg_5_1 then
		return
	end

	for iter_5_0 = 1, #arg_5_0.friendlist do
		if arg_5_0.friendlist[iter_5_0].player_id == arg_5_1 then
			arg_5_0.friendlist[iter_5_0].is_online = arg_5_2
		end
	end
end

function var_0_0.refreshRedMark(arg_6_0)
	local var_6_0 = arg_6_0:isHasRedMarkShow()

	if var_6_0 ~= arg_6_0.isHasRedMark then
		arg_6_0.isHasRedMark = var_6_0

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
			params = {
				index = 3
			}
		})
	end
end

function var_0_0.setOnlineState(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_2.is_online == 1 then
		arg_7_1:setString(var_0_1:translation("FRIEND_ONLINE_TEXT"))
		arg_7_1:setColor(cc.c3b(32, 193, 62))
	else
		local var_7_0 = xyd.ServerTime.get():getServerTime() - arg_7_2.last_time

		if var_7_0 < 60 then
			var_7_0 = 60
		end

		local var_7_1 = arg_7_0:getFriendStateTextBySeconds(var_7_0)

		arg_7_1:setString(var_7_1)
		arg_7_1:setColor(xyd.color.GRAY)
	end
end

function var_0_0.getFriendStateTextBySeconds(arg_8_0, arg_8_1)
	local var_8_0 = math.floor(arg_8_1 / 86400 / 30)

	arg_8_1 = arg_8_1 % 2592000

	local var_8_1 = math.floor(arg_8_1 / 86400)
	local var_8_2 = math.floor(arg_8_1 % 86400 / 3600)
	local var_8_3 = math.floor(arg_8_1 % 3600 / 60)

	if var_8_3 < 1 then
		var_8_3 = 1
	end

	local var_8_4 = var_0_1:translation("LAST_TIME_ONLINE_TEXT")
	local var_8_5 = var_0_1:translation("BEFORE")

	if var_8_0 > 0 then
		return var_8_4 .. var_8_0 .. var_0_1:translation("UNIT_MONTH") .. var_8_5
	elseif var_8_1 > 0 then
		return var_8_4 .. var_8_1 .. var_0_1:translation("UNIT_DAY") .. var_8_5
	elseif var_8_2 > 0 then
		return var_8_4 .. var_8_2 .. var_0_1:translation("UNIT_HOUR") .. var_8_5
	else
		return var_8_4 .. var_8_3 .. var_0_1:translation("UNIT_MINUTE") .. var_8_5
	end
end

function var_0_0.onFriendChatMessage_(arg_9_0, arg_9_1)
	if arg_9_1.params then
		local var_9_0 = {
			id = xyd.generateUUID() or "",
			friendID = arg_9_1.params.friend_id,
			playerID = arg_9_0.selfPlayer.playerID
		}
		local var_9_1 = json.decode(arg_9_1.params.message)

		var_9_0.message = var_9_1.message
		var_9_0.msgType = var_9_1.msgType
		var_9_0.selectType = var_9_1.selectType or xyd.FriendMsgSelectType.SOCIAL_SYSTEM

		if var_9_0.selectType == xyd.FriendMsgSelectType.ILLUSION or var_9_0.selectType == xyd.FriendMsgSelectType.OCCULT or var_9_0.selectType == xyd.FriendMsgSelectType.ADVENTURE_ILLUSION or var_9_0.selectType == xyd.FriendMsgSelectType.ADVENTURE_DEFENSE or var_9_0.selectType == xyd.FriendMsgSelectType.RAGNAROK then
			return
		end

		var_9_0.time = arg_9_1.params.time
		var_9_0.isOwnSend = 0
		var_9_0.roomID = var_9_1.roomID

		local var_9_2 = var_9_0

		xyd.db.friendMessages:addFriendMessage(var_9_0)
		arg_9_0:setPlayerOnlineState(arg_9_1.params.friend_id, 1)

		local var_9_3 = {
			friendID = arg_9_1.params.friend_id
		}

		var_9_3.count = 1
		var_9_3.playerID = arg_9_0.selfPlayer.playerID

		xyd.db.newMessagesCount:increaseCount(var_9_3)

		var_9_3.time = arg_9_1.params.time

		if var_9_3.time > xyd.db.newMessagesTime:getTime(var_9_3.playerID, var_9_3.friendID) then
			xyd.db.newMessagesTime:setTime(var_9_3)
		end

		local var_9_4 = xyd.WindowManager.get():getWindow("social_system")

		if var_9_4 and not tolua.isnull(var_9_4) then
			if var_9_4.windowState == var_0_4.FriendList then
				var_9_4:updateRightList(true)
			else
				var_9_4:updateRedMark()
			end
		else
			arg_9_0:refreshRedMark()
		end

		local var_9_5 = xyd.WindowManager.get():getWindow("social_system_chat_window")

		if var_9_5 and not tolua.isnull(var_9_5) and var_9_5.currentFriend.player_id == var_9_3.friendID then
			table.insert(var_9_5.data, var_9_2)
			var_9_5:addMsgItem(var_9_2)
		end
	end
end

function var_0_0.loadFriends(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_FRIENDS, var_10_0, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK and arg_11_1 then
			xyd.ServerTime.get():resetServerTime(arg_11_1.server_time)

			arg_10_0.socialSystemInfo = arg_11_1
			arg_10_0.blacklist = arg_10_0.socialSystemInfo.blacklist

			for iter_11_0, iter_11_1 in ipairs(arg_10_0.blacklist) do
				arg_10_0.messageManager:blockPlayer(iter_11_1.player_id)
			end

			arg_10_0.friendlist = arg_10_0.socialSystemInfo.friend_list
			arg_10_0.noticelist = arg_10_0.socialSystemInfo.notice_list
			arg_10_0.requestlist = arg_10_0.socialSystemInfo.request_list
			arg_10_0.offlinemessagelist = arg_10_0.socialSystemInfo.offline_msg_list
			arg_10_0.sendGiftCount = arg_10_0.socialSystemInfo.send_gift_count
			arg_10_0.receiveGiftCount = arg_10_0.socialSystemInfo.receive_gift_count

			if arg_10_0.offlinemessagelist then
				for iter_11_2 = 1, #arg_10_0.offlinemessagelist do
					local var_11_0 = arg_10_0.offlinemessagelist[iter_11_2]
					local var_11_1 = {
						id = xyd.generateUUID() or "",
						friendID = var_11_0.player_id,
						playerID = arg_10_0.selfPlayer.playerID
					}
					local var_11_2 = json.decode(var_11_0.message)

					var_11_1.message = var_11_2.message
					var_11_1.msgType = var_11_2.msgType
					var_11_1.time = var_11_0.time
					var_11_1.isOwnSend = 0

					xyd.db.friendMessages:addFriendMessage(var_11_1)

					local var_11_3 = {
						id = xyd.generateUUID() or "",
						friendID = var_11_0.player_id
					}

					var_11_3.count = 1
					var_11_3.playerID = arg_10_0.selfPlayer.playerID

					xyd.db.newMessagesCount:increaseCount(var_11_3)

					var_11_3.time = var_11_0.time

					if var_11_3.time > xyd.db.newMessagesTime:getTime(var_11_3.playerID, var_11_3.friendID) then
						xyd.db.newMessagesTime:setTime(var_11_3)
					end
				end

				arg_10_0.offlinemessagelist = {}
			end

			arg_10_0:refreshRedMark()
		end

		if arg_10_2 then
			arg_10_2(arg_11_0, arg_11_1)
		end
	end)
end

function var_0_0.loadFriendInfo(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_FRIEND_INFO, var_12_0, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK and arg_13_1 then
			if var_12_0.list_type == xyd.FriendInfoType.FRIEND then
				arg_12_0.friendlist = arg_13_1
			elseif var_12_0.list_type == xyd.FriendInfoType.REQUEST then
				arg_12_0.requestlist = arg_13_1
			elseif var_12_0.list_type == xyd.FriendInfoType.BLACKLIST then
				arg_12_0.blacklist = arg_13_1
			elseif var_12_0.list_type == xyd.FriendInfoType.NOTICE then
				arg_12_0.noticelist = arg_13_1
			end
		end

		arg_12_0:refreshRedMark()

		if arg_12_2 then
			arg_12_2(arg_13_0, arg_13_1)
		end
	end)
end

function var_0_0.isInFriendList(arg_14_0, arg_14_1)
	if arg_14_0.friendlist then
		for iter_14_0 = 1, #arg_14_0.friendlist do
			if arg_14_0.friendlist[iter_14_0].player_id == arg_14_1 then
				return true
			end
		end
	end

	return false
end

function var_0_0.removeFriend(arg_15_0, arg_15_1)
	if arg_15_0.friendlist then
		for iter_15_0 = 1, #arg_15_0.friendlist do
			if arg_15_0.friendlist[iter_15_0].player_id == arg_15_1 then
				table.remove(arg_15_0.friendlist, iter_15_0)

				return
			end
		end
	end
end

function var_0_0.isInBlackList(arg_16_0, arg_16_1)
	if arg_16_0.blacklist then
		for iter_16_0 = 1, #arg_16_0.blacklist do
			if arg_16_0.blacklist[iter_16_0].player_id == arg_16_1 then
				return true
			end
		end
	end

	return false
end

function var_0_0.getFriendInfo(arg_17_0, arg_17_1)
	if arg_17_0.friendlist then
		for iter_17_0 = 1, #arg_17_0.friendlist do
			if arg_17_0.friendlist[iter_17_0].player_id == arg_17_1 then
				return arg_17_0.friendlist[iter_17_0]
			end
		end
	end
end

function var_0_0.removeItemByPlayerID(arg_18_0, arg_18_1, arg_18_2)
	for iter_18_0 = 1, #arg_18_1 do
		if arg_18_1[iter_18_0].player_id == arg_18_2 then
			table.remove(arg_18_1, iter_18_0)

			return
		end
	end
end

function var_0_0.getFriendsCount(arg_19_0)
	if arg_19_0.friendlist then
		return #arg_19_0.friendlist
	end

	return 0
end

function var_0_0.requestFriend(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_1 or {}

	xyd.Backend.get():request(xyd.mid.REQUEST_FRIEND, var_20_0, function(arg_21_0, arg_21_1)
		if arg_20_2 then
			arg_20_2(arg_21_0, arg_21_1)
		end
	end)
end

function var_0_0.denyFriendRequest(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_1 or {}

	xyd.Backend.get():request(xyd.mid.DENY_FRIEND_REQUEST, var_22_0, function(arg_23_0, arg_23_1)
		if arg_22_2 then
			arg_22_2(arg_23_0, arg_23_1)
		end
	end)
end

function var_0_0.ignoreFriendRequest(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_1 or {}

	xyd.Backend.get():request(xyd.mid.IGNORE_FRIEND_REQUEST, var_24_0, function(arg_25_0, arg_25_1)
		if arg_24_2 then
			arg_24_2(arg_25_0, arg_25_1)
		end
	end)
end

function var_0_0.acceptAllFriendRequest(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = arg_26_1 or {}

	xyd.Backend.get():request(xyd.mid.ACCEPT_ALL_FRIEND_REQUEST, var_26_0, function(arg_27_0, arg_27_1)
		if arg_26_2 then
			arg_26_2(arg_27_0, arg_27_1)
		end
	end)
end

function var_0_0.acceptFriendRequest(arg_28_0, arg_28_1, arg_28_2)
	local var_28_0 = arg_28_1 or {}

	xyd.Backend.get():request(xyd.mid.ACCEPT_FRIEND_REQUEST, var_28_0, function(arg_29_0, arg_29_1)
		if arg_28_2 then
			arg_28_2(arg_29_0, arg_29_1)
		end
	end)
end

function var_0_0.rejectFriendFight(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = arg_30_1 or {}

	xyd.Backend.get():request(xyd.mid.REJECT_FRIEND_FIGHT, var_30_0, function(arg_31_0, arg_31_1)
		if arg_30_2 then
			arg_30_2(arg_31_0, arg_31_1)
		end
	end)
end

function var_0_0.deleteFriend(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = arg_32_1 or {}

	xyd.Backend.get():request(xyd.mid.DELETE_FRIEND, var_32_0, function(arg_33_0, arg_33_1)
		if arg_32_2 then
			arg_32_2(arg_33_0, arg_33_1)
		end
	end)
end

function var_0_0.sendSocialGift(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = arg_34_1 or {}

	xyd.Backend.get():request(xyd.mid.SEND_SOCIAL_GIFT, var_34_0, function(arg_35_0, arg_35_1)
		if arg_35_1 and arg_35_1.master_info then
			arg_34_0:freshBaseInfo(arg_35_1.master_info)
		end

		if arg_34_2 then
			arg_34_2(arg_35_0, arg_35_1)
		end
	end)
end

function var_0_0.readNotice(arg_36_0, arg_36_1, arg_36_2)
	local var_36_0 = arg_36_1 or {}

	xyd.Backend.get():request(xyd.mid.READ_NOTICE, var_36_0, function(arg_37_0, arg_37_1)
		if arg_36_2 then
			arg_36_2(arg_37_0, arg_37_1)
		end
	end)
end

function var_0_0.addBlackList(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0 = arg_38_1 or {}

	xyd.Backend.get():request(xyd.mid.ADD_BLACK_LIST, var_38_0, function(arg_39_0, arg_39_1)
		if arg_38_2 then
			arg_38_2(arg_39_0, arg_39_1)
		end
	end)
end

function var_0_0.removeBlackList(arg_40_0, arg_40_1, arg_40_2)
	local var_40_0 = arg_40_1 or {}

	xyd.Backend.get():request(xyd.mid.REMOVE_BLACK_LIST, var_40_0, function(arg_41_0, arg_41_1)
		if arg_40_2 then
			arg_40_2(arg_41_0, arg_41_1)
		end
	end)
end

function var_0_0.clearBlackList(arg_42_0, arg_42_1, arg_42_2)
	local var_42_0 = arg_42_1 or {}

	xyd.Backend.get():request(xyd.mid.CLEAR_BLACK_LIST, var_42_0, function(arg_43_0, arg_43_1)
		if arg_42_2 then
			arg_42_2(arg_43_0, arg_43_1)
		end
	end)
end

function var_0_0.cancelRequestFriend(arg_44_0, arg_44_1, arg_44_2)
	local var_44_0 = arg_44_1 or {}

	xyd.Backend.get():request(xyd.mid.CANCEL_REQUEST_FRIEND, var_44_0, function(arg_45_0, arg_45_1)
		if arg_44_2 then
			arg_44_2(arg_45_0, arg_45_1)
		end
	end)
end

function var_0_0.searchPlayer(arg_46_0, arg_46_1, arg_46_2)
	local var_46_0 = arg_46_1 or {}

	xyd.Backend.get():request(xyd.mid.SEARCH_PLAYER, var_46_0, function(arg_47_0, arg_47_1)
		if arg_46_2 then
			arg_46_2(arg_47_0, arg_47_1)
		end
	end)
end

function var_0_0.chatToFriend(arg_48_0, arg_48_1, arg_48_2)
	local var_48_0 = arg_48_1 or {}

	xyd.Backend.get():request(xyd.mid.CHAT_TO_FRIEND, var_48_0, function(arg_49_0, arg_49_1)
		if arg_48_2 then
			arg_48_2(arg_49_0, arg_49_1)
		end
	end)
end

function var_0_0.chatToFriends(arg_50_0, arg_50_1, arg_50_2)
	local var_50_0 = arg_50_1.data
	local var_50_1 = arg_50_1.player_ids
	local var_50_2 = arg_50_1.select_type
	local var_50_3 = arg_50_1.room_id

	for iter_50_0 = 1, #var_50_1 do
		local var_50_4 = {
			player_id = tonumber(var_50_1[iter_50_0])
		}
		local var_50_5 = {
			message = var_50_0.text,
			msgType = var_50_0.msgType,
			selectType = var_50_2,
			roomID = var_50_3
		}

		var_50_4.msg = json.encode(var_50_5)

		arg_50_0:chatToFriend(var_50_4, function(arg_51_0, arg_51_1)
			if arg_51_0 == xyd.error.OK then
				-- block empty
			end

			arg_51_1.index = iter_50_0

			if arg_50_2 then
				arg_50_2(arg_51_0, arg_51_1)
			end
		end)
	end
end

function var_0_0.getRecommendFriends(arg_52_0, arg_52_1, arg_52_2)
	local var_52_0 = arg_52_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_RECOMMEND_FRIENDS, var_52_0, function(arg_53_0, arg_53_1)
		if arg_52_2 then
			arg_52_2(arg_53_0, arg_53_1)
		end
	end)
end

function var_0_0.removeOnefromBlack(arg_54_0, arg_54_1)
	for iter_54_0 = 1, #arg_54_0.blacklist do
		if arg_54_0.blacklist[iter_54_0].player_id == arg_54_1 then
			table.remove(arg_54_0.blacklist, iter_54_0)

			break
		end
	end
end

function var_0_0.isFriendListRedMarkShow(arg_55_0)
	if arg_55_0.friendlist then
		for iter_55_0 = 1, #arg_55_0.friendlist do
			local var_55_0 = xyd.db.newMessagesCount:getCount(arg_55_0.selfPlayer.playerID, arg_55_0.friendlist[iter_55_0].player_id)

			if var_55_0 and var_55_0 > 0 then
				return true
			end
		end
	end

	return false
end

function var_0_0.isApplyListRedMarkShow(arg_56_0)
	if arg_56_0.requestlist and #arg_56_0.requestlist > 0 then
		return true
	end

	return false
end

function var_0_0.isNoticeListRedMarkShow(arg_57_0)
	local var_57_0 = tonumber(xyd.db.stateVariable:getState(arg_57_0.selfPlayer.playerID, xyd.state.IS_HAS_NEW_NOTICE))

	if arg_57_0.noticelist and #arg_57_0.noticelist > 0 and var_57_0 == 1 then
		return true
	end

	return false
end

function var_0_0.setIsHasNewNoticeState(arg_58_0, arg_58_1)
	local var_58_0 = {
		playerID = arg_58_0.selfPlayer.playerID,
		name = xyd.state.IS_HAS_NEW_NOTICE,
		state = tostring(arg_58_1)
	}

	xyd.db.stateVariable:setState(var_58_0)
end

function var_0_0.setFriendInvertedOrder(arg_59_0, arg_59_1)
	if not arg_59_1 then
		arg_59_1 = arg_59_0:getFriendInvertedOrder()
		arg_59_1 = arg_59_1 == 1 and 0 or 1
	end

	local var_59_0 = {
		playerID = arg_59_0.selfPlayer.playerID,
		name = xyd.state.FRIEND_INVERTED_ORDER,
		state = tostring(arg_59_1)
	}

	xyd.db.stateVariable:setState(var_59_0)

	arg_59_0.sortOrder = arg_59_1
end

function var_0_0.getFriendInvertedOrder(arg_60_0)
	if arg_60_0.sortOrder then
		return arg_60_0.sortOrder
	end

	return tonumber(xyd.db.stateVariable:getState(arg_60_0.selfPlayer.playerID, xyd.state.FRIEND_INVERTED_ORDER)) or 0
end

function var_0_0.isHasRedMarkShow(arg_61_0)
	if not arg_61_0.socialSystemInfo then
		return false
	end

	if arg_61_0:isNoticeListRedMarkShow() or arg_61_0:isApplyListRedMarkShow() or arg_61_0:isFriendListRedMarkShow() or arg_61_0.invite:isInviteRedMarkShow() or arg_61_0:isRecallRedPointShow() or arg_61_0:sortClassMissionList() or arg_61_0:checkHasTeacherApplyRed() then
		return true
	else
		return false
	end
end

function var_0_0.setNameBg(arg_62_0, arg_62_1, arg_62_2)
	if arg_62_2.conquer_lev and arg_62_2.conquer_lev > 0 then
		xyd.setConquerLev(arg_62_2.conquer_lev, arg_62_1:getChildByName("lev_txt"), arg_62_1:getChildByName("dengjiquan"), nil, nil, nil, nil, arg_62_2.conquer_loop_id)
	else
		local var_62_0, var_62_1 = arg_62_1:getChildByName("dengjiquan"):getPosition()

		arg_62_1:getChildByName("dengjiquan"):setPosition(var_62_0 + 2, var_62_1 - 2)
		arg_62_1:getChildByName("lev_txt"):setString(arg_62_2.lev)
	end

	arg_62_1:getChildByName("name_txt"):setString(arg_62_2.player_name)
	arg_62_1:getChildByName("region_txt"):setString("S" .. xyd.getPlayerRegion(arg_62_2.player_id))
end

function var_0_0.refreshNoticeCount(arg_63_0)
	local var_63_0 = {
		playerID = arg_63_0.selfPlayer.playerID,
		name = xyd.state.NOTICE_COUNT,
		state = tostring(#arg_63_0.noticelist)
	}

	xyd.db.stateVariable:setState(var_63_0)
end

function var_0_0.compare(arg_64_0, arg_64_1, arg_64_2)
	local var_64_0 = arg_64_1 or {}

	xyd.Backend.get():request(xyd.mid.INVITE_FRIEND_FIGHT, var_64_0, function(arg_65_0, arg_65_1)
		if arg_64_2 then
			arg_64_2(arg_65_0, arg_65_1)
		end
	end)
end

function var_0_0.acceptFrientFight(arg_66_0, arg_66_1, arg_66_2)
	local var_66_0 = arg_66_1 or {}

	xyd.Backend.get():request(xyd.mid.ACCEPT_FRIEND_FIGHT, var_66_0, function(arg_67_0, arg_67_1)
		if arg_66_2 then
			arg_66_2(arg_67_0, arg_67_1)
		end
	end)
end

function var_0_0.exchangeItems(arg_68_0, arg_68_1, arg_68_2)
	local var_68_0 = arg_68_1 or {}

	xyd.Backend.get():request(xyd.mid.EXCHANGE_ITEMS, var_68_0, function(arg_69_0, arg_69_1)
		if arg_68_2 then
			arg_68_2(arg_69_0, arg_69_1)
		end
	end)
end

function var_0_0.startBattle(arg_70_0, arg_70_1, arg_70_2)
	arg_70_0.currentBattleRound_ = 1
	arg_70_0.record_id = arg_70_1
	arg_70_0.isSelfChallenger = false
	arg_70_0.mode = 0

	arg_70_0:getBattleReportFromBack(arg_70_2)
end

function var_0_0.getBattleReportFromBack(arg_71_0, arg_71_1, arg_71_2, arg_71_3)
	local var_71_0 = {}

	if not stage then
		var_71_0 = {
			record_id = arg_71_0.record_id,
			index = arg_71_0.currentBattleRound_
		}
	else
		var_71_0 = {
			record_id = arg_71_2,
			index = arg_71_3
		}
	end

	xyd.Backend.get():request(xyd.mid.FRIEND_FIGHT_RECORD, var_71_0, function(arg_72_0, arg_72_1)
		if arg_72_0 == xyd.error.OK and arg_71_1 then
			if not stage then
				arg_71_0.totalRound = tonumber(arg_72_1.record_info.battle_count)
			end

			if arg_71_0.selfPlayer.playerID == arg_72_1.record_info.A_player_id then
				arg_71_0.isSelfChallenger = true
			else
				arg_71_0.isSelfChallenger = false
			end

			arg_71_1(arg_72_1)
		end
	end)
end

function var_0_0.setCurrentBattleRound(arg_73_0, arg_73_1)
	arg_73_0.currentBattleRound_ = arg_73_1
end

function var_0_0.getCurrentBattleRound(arg_74_0)
	return arg_74_0.currentBattleRound_
end

function var_0_0.setBattleResult(arg_75_0, arg_75_1)
	if arg_75_1 >= arg_75_0.totalRound then
		arg_75_0.hasNext = false

		return false
	else
		arg_75_0.hasNext = true

		return true
	end
end

function var_0_0.clear(arg_76_0)
	arg_76_0.currentBattleRound_ = 0
	arg_76_0.hasNext = false
	arg_76_0.totalRound = 0
end

function var_0_0.getBattleResult(arg_77_0)
	return arg_77_0.hasNext
end

function var_0_0.handleFriendMessageDB(arg_78_0)
	for iter_78_0, iter_78_1 in ipairs(arg_78_0.friendlist) do
		xyd.db.friendMessages:deleteRecordsIfOverlimit(arg_78_0.selfPlayer.playerID, iter_78_1.player_id, xyd.tables.misc.offlineMessageNumber)
	end
end

function var_0_0.loadFundingList(arg_79_0, arg_79_1, arg_79_2)
	local var_79_0 = arg_79_1 or {}

	xyd.Backend.get():request(xyd.mid.INDIEGOGO_GET_FUNDING_LIST, var_79_0, function(arg_80_0, arg_80_1, arg_80_2)
		if arg_79_2 then
			arg_79_2(arg_80_0, arg_80_1)
		end
	end)
end

function var_0_0.loadFundingInfo(arg_81_0, arg_81_1, arg_81_2)
	local var_81_0 = arg_81_1 or {}

	xyd.Backend.get():request(xyd.mid.INDIEGOGO_GET_FUNDING_INFO, var_81_0, function(arg_82_0, arg_82_1, arg_82_2)
		if arg_81_2 then
			arg_81_2(arg_82_0, arg_82_1)
		end
	end)
end

function var_0_0.getInfoByID(arg_83_0, arg_83_1, arg_83_2)
	local var_83_0 = arg_83_1 or {}

	xyd.Backend.get():request(xyd.mid.INDIEGOGO_GET_INFO_BY_ID, var_83_0, function(arg_84_0, arg_84_1, arg_84_2)
		if arg_83_2 then
			arg_83_2(arg_84_0, arg_84_1)
		end
	end)
end

function var_0_0.releaseFunding(arg_85_0, arg_85_1, arg_85_2)
	local var_85_0 = arg_85_1 or {}

	xyd.Backend.get():request(xyd.mid.INDIEGOGO_RELEASE_FUNDING, var_85_0, function(arg_86_0, arg_86_1, arg_86_2)
		if arg_85_2 then
			arg_85_2(arg_86_0, arg_86_1)
		end
	end)
end

function var_0_0.investFunding(arg_87_0, arg_87_1, arg_87_2)
	local var_87_0 = arg_87_1 or {}

	xyd.Backend.get():request(xyd.mid.INDIEGOGO_INVEST_FUNDING, var_87_0, function(arg_88_0, arg_88_1, arg_88_2)
		if arg_87_2 then
			arg_87_2(arg_88_0, arg_88_1)
		end
	end)
end

function var_0_0.recallFriend(arg_89_0, arg_89_1, arg_89_2)
	local var_89_0 = arg_89_1 or {}

	xyd.Backend.get():request(xyd.mid.recall_friend, var_89_0, function(arg_90_0, arg_90_1)
		if arg_90_0 == xyd.error.OK then
			arg_89_0.socialSystemInfo.doing_recall = arg_90_1.doing_recall

			table.insert(arg_89_0.socialSystemInfo.got_recall, var_89_0.friend_id)
		end

		if arg_89_2 then
			arg_89_2(arg_90_0, arg_90_1)
		end
	end)
end

function var_0_0.getRecallAward(arg_91_0, arg_91_1, arg_91_2)
	local var_91_0 = arg_91_1 or {}

	xyd.Backend.get():request(xyd.mid.get_recall_award, var_91_0, function(arg_92_0, arg_92_1)
		if arg_92_0 == xyd.error.OK then
			arg_91_0.socialSystemInfo.recall_awarded = arg_92_1.recall_awarded
		end

		if arg_91_2 then
			arg_91_2(arg_92_0, arg_92_1)
		end
	end)
end

function var_0_0.getRecallFriendLists(arg_93_0)
	local var_93_0 = {
		canRecall = arg_93_0:getCanRecallList()
	}

	var_93_0.canAward, var_93_0.cannotAward = arg_93_0:getRecallAwardLists()
	var_93_0.onDoing = arg_93_0.socialSystemInfo.doing_recall
	var_93_0.doneRecall = arg_93_0.socialSystemInfo.done_recall
	var_93_0.awarded = arg_93_0.socialSystemInfo.recall_awarded

	return var_93_0
end

function var_0_0.getCanRecallList(arg_94_0)
	local var_94_0 = {}

	for iter_94_0 = 1, #arg_94_0.friendlist do
		if arg_94_0:isCanRecall(arg_94_0.friendlist[iter_94_0]) then
			table.insert(var_94_0, clone(arg_94_0.friendlist[iter_94_0]))
		end
	end

	return var_94_0
end

function var_0_0.isCanRecall(arg_95_0, arg_95_1)
	if not arg_95_0:isInGotRecallList(arg_95_1.player_id) and arg_95_0:isOfflineOverTimeLimit(arg_95_1.last_time) and arg_95_1.recalling_friend == 0 then
		return true
	end

	return false
end

function var_0_0.isInGotRecallList(arg_96_0, arg_96_1)
	local var_96_0 = arg_96_0.socialSystemInfo.got_recall

	for iter_96_0 = 1, #var_96_0 do
		if tonumber(var_96_0[iter_96_0]) == tonumber(arg_96_1) then
			return true
		end
	end

	return false
end

function var_0_0.isOfflineOverTimeLimit(arg_97_0, arg_97_1)
	if xyd.ServerTime.get():getServerTime() - arg_97_1 > 86400 * xyd.tables.misc.friendRecallDays then
		return true
	else
		return false
	end
end

function var_0_0.getRecallAwardLists(arg_98_0)
	local var_98_0, var_98_1, var_98_2 = arg_98_0:summaryDoneFriendsInfo()
	local var_98_3 = arg_98_0:getRecallFriendNum()
	local var_98_4 = {}
	local var_98_5 = {}
	local var_98_6 = xyd.tables.friendRecall:getIdsByType(1)

	for iter_98_0 = 1, #var_98_6 do
		if not arg_98_0:isInAwardedList(var_98_6[iter_98_0]) and var_98_3 >= xyd.tables.friendRecall:condition(var_98_6[iter_98_0]) then
			table.insert(var_98_4, var_98_6[iter_98_0])
		elseif not arg_98_0:isInAwardedList(var_98_6[iter_98_0]) then
			table.insert(var_98_5, var_98_6[iter_98_0])
		end
	end

	local var_98_7 = xyd.tables.friendRecall:getIdsByType(2)

	for iter_98_1 = 1, #var_98_7 do
		if not arg_98_0:isInAwardedList(var_98_7[iter_98_1]) and var_98_0 >= xyd.tables.friendRecall:condition(var_98_7[iter_98_1]) then
			table.insert(var_98_4, var_98_7[iter_98_1])
		elseif not arg_98_0:isInAwardedList(var_98_7[iter_98_1]) then
			table.insert(var_98_5, var_98_7[iter_98_1])
		end
	end

	local var_98_8 = xyd.tables.friendRecall:getIdsByType(3)

	for iter_98_2 = 1, #var_98_8 do
		if not arg_98_0:isInAwardedList(var_98_8[iter_98_2]) and var_98_2 >= xyd.tables.friendRecall:condition(var_98_8[iter_98_2]) then
			table.insert(var_98_4, var_98_8[iter_98_2])
		elseif not arg_98_0:isInAwardedList(var_98_8[iter_98_2]) then
			table.insert(var_98_5, var_98_8[iter_98_2])
		end
	end

	local var_98_9 = xyd.tables.friendRecall:getIdsByType(4)

	for iter_98_3 = 1, #var_98_9 do
		if not arg_98_0:isInAwardedList(var_98_9[iter_98_3]) and var_98_1 >= xyd.tables.friendRecall:condition(var_98_9[iter_98_3]) then
			table.insert(var_98_4, var_98_9[iter_98_3])
		elseif not arg_98_0:isInAwardedList(var_98_9[iter_98_3]) then
			table.insert(var_98_5, var_98_9[iter_98_3])
		end
	end

	return var_98_4, var_98_5
end

function var_0_0.isInAwardedList(arg_99_0, arg_99_1)
	local var_99_0 = arg_99_0.socialSystemInfo.recall_awarded

	for iter_99_0 = 1, #var_99_0 do
		if arg_99_1 == tonumber(var_99_0[iter_99_0]) then
			return true
		end
	end

	return false
end

function var_0_0.getRecallFriendNum(arg_100_0)
	return #arg_100_0.socialSystemInfo.done_recall
end

function var_0_0.summaryDoneFriendsInfo(arg_101_0)
	local var_101_0 = 0
	local var_101_1 = 0
	local var_101_2 = 0

	if not arg_101_0.socialSystemInfo or not arg_101_0.socialSystemInfo.done_recall then
		return var_101_0, var_101_1, var_101_2
	end

	local var_101_3 = arg_101_0.socialSystemInfo.done_recall

	for iter_101_0 = 1, #var_101_3 do
		if var_101_3[iter_101_0].lev <= 90 and var_101_0 < var_101_3[iter_101_0].cur_lev then
			var_101_0 = var_101_3[iter_101_0].cur_lev
		end

		if var_101_3[iter_101_0].lev > 50 and var_101_2 < var_101_3[iter_101_0].cur_partner_num - var_101_3[iter_101_0].partner_num then
			var_101_2 = var_101_3[iter_101_0].cur_partner_num - var_101_3[iter_101_0].partner_num
		end

		if var_101_1 < var_101_3[iter_101_0].cur_charge - var_101_3[iter_101_0].charge then
			var_101_1 = var_101_3[iter_101_0].cur_charge - var_101_3[iter_101_0].charge
		end
	end

	return var_101_0, var_101_1, var_101_2
end

function var_0_0.isInRecallAwardedList(arg_102_0, arg_102_1)
	local var_102_0 = arg_102_0.socialSystemInfo.recall_awarded

	for iter_102_0 = 1, #var_102_0 do
		if var_102_0[iter_102_0] == arg_102_1 then
			return true
		end
	end

	return false
end

function var_0_0.isRecallRedPointShow(arg_103_0)
	if not arg_103_0.socialSystemInfo then
		return false
	end

	if arg_103_0:isGetRecallRedPointShow() or arg_103_0:isRecallAwardRedPointShow() then
		return true
	end

	return false
end

function var_0_0.isGetRecallRedPointShow(arg_104_0)
	if not arg_104_0.socialSystemInfo then
		return false
	end

	local var_104_0 = arg_104_0:getRecallFriendLists()

	if #var_104_0.onDoing < 3 and #var_104_0.canRecall > 0 then
		return true
	end

	return false
end

function var_0_0.isRecallAwardRedPointShow(arg_105_0)
	if not arg_105_0.socialSystemInfo then
		return false
	end

	if #arg_105_0:getRecallFriendLists().canAward > 0 then
		return true
	end

	return false
end

function var_0_0.setBattleParams(arg_106_0, arg_106_1, arg_106_2, arg_106_3)
	if arg_106_3 then
		arg_106_0.mode = arg_106_3
	end

	local var_106_0 = arg_106_1.battle_report
	local var_106_1 = {
		enemyHeros = {},
		selfHeros = {},
		battleReport = arg_106_1.report[1].content
	}
	local var_106_2 = xyd.split(arg_106_1.record_info["team_" .. arg_106_2], "|")
	local var_106_3 = xyd.splitToNumber(arg_106_1.record_info["pet_id_" .. arg_106_2], "|")
	local var_106_4 = {}
	local var_106_5 = {}
	local var_106_6
	local var_106_7

	for iter_106_0 = 1, #xyd.splitToNumber(var_106_2[1], ":") do
		local var_106_8 = var_0_2.new()
		local var_106_9 = arg_106_1.A_partners_info[tostring(xyd.splitToNumber(var_106_2[1], ":")[iter_106_0])]

		var_106_8:initUnCollected(var_106_9.table_id, nil, {
			star = var_106_9.star,
			color = var_106_9.color
		})
		var_106_8:setSkinInfo(tonumber(var_106_9.current_skin_id), var_106_9.skin_ids)

		var_106_8.illusionSkinId_ = var_106_9.illusion_skin_id

		table.insert(var_106_4, var_106_8)
	end

	if tonumber(var_106_3[1]) ~= 0 then
		local var_106_10 = var_0_3.new()
		local var_106_11 = arg_106_1.A_pet_info[tostring(var_106_3[1])]

		var_106_10:initUnCollected(var_106_11.table_id, nil, {
			color = var_106_11.color,
			star = var_106_11.star
		})
		xyd.formatRegionArenaPetsAwake({
			var_106_10
		})

		var_106_6 = var_106_10
	end

	for iter_106_1 = 1, #xyd.splitToNumber(var_106_2[2], ":") do
		local var_106_12 = var_0_2.new()
		local var_106_13 = arg_106_1.B_partners_info[tostring(xyd.splitToNumber(var_106_2[2], ":")[iter_106_1])]

		var_106_12:initUnCollected(var_106_13.table_id, nil, {
			star = var_106_13.star,
			color = var_106_13.color
		})
		var_106_12:setSkinInfo(tonumber(var_106_13.current_skin_id), var_106_13.skin_ids)

		var_106_12.illusionSkinId_ = var_106_13.illusion_skin_id

		table.insert(var_106_5, var_106_12)
	end

	if tonumber(var_106_3[2]) ~= 0 then
		local var_106_14 = var_0_3.new()
		local var_106_15 = arg_106_1.B_pet_info[tostring(var_106_3[2])]

		var_106_14:initUnCollected(var_106_15.table_id, nil, {
			color = var_106_15.color,
			star = var_106_15.star
		})
		xyd.formatRegionArenaPetsAwake({
			var_106_14
		})

		var_106_7 = var_106_14
	end

	if arg_106_0.selfPlayer.playerID == arg_106_1.record_info.A_player_id then
		var_106_1.enemyID = arg_106_1.record_info.B_player_id
		var_106_1.enemyServerName = arg_106_1.B_player_info.region_name
		var_106_1.enemyGuildName = arg_106_1.B_player_info.guild_name
		var_106_1.enemyRegion = arg_106_1.B_player_info.region
		var_106_1.selfPlayerID = arg_106_1.record_info.A_player_id
		var_106_1.selfPlayerName = arg_106_0.selfPlayer.playerName
		var_106_1.selfGuildName = arg_106_1.A_player_info.guild_name
		var_106_1.selfRegion = arg_106_1.A_player_info.region
		var_106_1.selfRegionName = arg_106_1.A_player_info.region_name
		var_106_1.selfHeros = var_106_4
		var_106_1.enemyHeros = var_106_5
		var_106_1.selfPet = var_106_6
		var_106_1.enemyPet = var_106_7

		if arg_106_0.mode and arg_106_0.mode == 2 then
			xyd.formatRegionArenaHerosAwake(var_106_1.selfHeros)

			if arg_106_1.A_pet_info then
				xyd.formatRegionArenaPetsAwake({
					var_106_1.selfPet
				})
			end
		end

		if arg_106_0.mode and arg_106_0.mode == 2 then
			xyd.formatRegionArenaHerosAwake(var_106_1.enemyHeros)

			if arg_106_1.B_pet_info then
				xyd.formatRegionArenaPetsAwake({
					var_106_1.enemyPet
				})
			end
		end
	else
		var_106_1.enemyID = arg_106_1.record_info.A_player_id
		var_106_1.enemyServerName = arg_106_1.A_player_info.region_name
		var_106_1.enemyGuildName = arg_106_1.A_player_info.guild_name
		var_106_1.enemyRegion = arg_106_1.A_player_info.region
		var_106_1.selfPlayerID = arg_106_1.record_info.B_player_id
		var_106_1.selfPlayerName = arg_106_0.selfPlayer.playerName
		var_106_1.selfGuildName = arg_106_1.B_player_info.guild_name
		var_106_1.selfRegion = arg_106_1.B_player_info.region
		var_106_1.selfRegionName = arg_106_1.B_player_info.region_name
		var_106_1.selfHeros = var_106_5
		var_106_1.enemyHeros = var_106_4
		var_106_1.selfPet = var_106_7
		var_106_1.enemyPet = var_106_6

		if arg_106_0.mode and arg_106_0.mode == 2 then
			xyd.formatRegionArenaHerosAwake(var_106_1.selfHeros)

			if arg_106_1.B_pet_info then
				xyd.formatRegionArenaPetsAwake({
					var_106_1.selfPet
				})
			end
		end

		if arg_106_0.mode and arg_106_0.mode == 2 then
			xyd.formatRegionArenaHerosAwake(var_106_1.enemyHeros)

			if arg_106_1.A_pet_info then
				xyd.formatRegionArenaPetsAwake({
					var_106_1.enemyPet
				})
			end
		end
	end

	arg_106_0:loadFriends()

	var_106_1.enemyName = arg_106_0:getFriendInfo(var_106_1.enemyID).player_name
	var_106_1.delay = 1
	var_106_1.isBackendBattle = 1
	var_106_1.oldStar = 45
	var_106_1.is_friend = true

	return var_106_1
end

function var_0_0.getClassInfo(arg_107_0, arg_107_1)
	xyd.Backend.get():request(xyd.mid.GET_CLASS_INFO, {}, function(arg_108_0, arg_108_1)
		if arg_108_0 == xyd.error.OK then
			arg_107_0.classApplyList = {}
			arg_107_0.classMissionList = {}

			if arg_108_1 then
				arg_107_0:freshClassInfo(arg_108_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.REFRESH_CLASS_MISSION_RED,
				hasRed = arg_107_0:sortClassMissionList()
			})
		end

		if arg_107_1 then
			arg_107_1(arg_108_0, arg_108_1)
		end
	end)
end

function var_0_0.sortClassMissionList(arg_109_0)
	arg_109_0.classMissionFinishNum = {
		0,
		0
	}

	local var_109_0 = false

	if not arg_109_0.classMissionList then
		return var_109_0
	end

	for iter_109_0 = 1, 2 do
		local var_109_1 = {}
		local var_109_2 = {}

		for iter_109_1, iter_109_2 in pairs(arg_109_0.classMissionList[iter_109_0]) do
			if xyd.tables.teacherMission:isHide(iter_109_2.table_id) == 0 then
				if iter_109_2.is_complete == 1 and iter_109_2.is_awarded == 0 then
					arg_109_0.classMissionFinishNum[iter_109_0] = arg_109_0.classMissionFinishNum[iter_109_0] + 1
					var_109_0 = true

					table.insert(var_109_1, iter_109_2)
				elseif iter_109_2.is_complete == 0 and iter_109_2.is_awarded == 0 then
					table.insert(var_109_2, iter_109_2)
				end
			end
		end

		arg_109_0.classMissionList[iter_109_0] = var_109_1

		for iter_109_3, iter_109_4 in pairs(var_109_2) do
			table.insert(arg_109_0.classMissionList[iter_109_0], iter_109_4)
		end
	end

	return var_109_0
end

function var_0_0.reloadMissionEvent_(arg_110_0, arg_110_1)
	if arg_110_1.params then
		local var_110_0 = false
		local var_110_1 = 1

		for iter_110_0 = 1, 2 do
			for iter_110_1, iter_110_2 in pairs(arg_110_0.classMissionList[iter_110_0]) do
				if arg_110_1.params.table_id == iter_110_2.table_id then
					arg_110_0.classMissionList[iter_110_0][iter_110_1] = arg_110_1.params
					var_110_1 = iter_110_0

					break
				end
			end
		end

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REFRESH_CLASS_MISSION_RED,
			classType = var_110_1,
			hasRed = arg_110_0:sortClassMissionList()
		})
	end
end

function var_0_0.refreshMasterEvent_(arg_111_0, arg_111_1)
	if arg_111_1.params then
		arg_111_0:freshClassInfo(arg_111_1.params)

		local var_111_0 = xyd.WindowManager.get():getWindow("teacher")

		if var_111_0 then
			var_111_0:freshInfos()
		end
	end
end

function var_0_0.freshClassInfo(arg_112_0, arg_112_1)
	if not arg_112_1 then
		return
	end

	if arg_112_1.base_info then
		arg_112_0:freshBaseInfo(arg_112_1.base_info)
	end

	if arg_112_1.apply_list then
		arg_112_0.classApplyList = arg_112_1.apply_list
	end

	if arg_112_1.mission_list then
		arg_112_0.classMissionList = arg_112_1.mission_list
	end
end

function var_0_0.checkHasTeacherApplyRed(arg_113_0)
	if arg_113_0.classApplyList and #arg_113_0.classApplyList > 0 then
		for iter_113_0, iter_113_1 in pairs(arg_113_0.classApplyList) do
			if iter_113_1.relation_type == 1 then
				if arg_113_0.teacherInfo and arg_113_0.teacherInfo.idInfo and arg_113_0.teacherInfo.idInfo.player_id then
					return false
				else
					return true
				end
			elseif arg_113_0.studentInfo and arg_113_0.studentInfo.idInfo and arg_113_0.studentInfo.idInfo.player_id then
				return false
			else
				return true
			end
		end
	else
		return false
	end

	return false
end

function var_0_0.freshBaseInfo(arg_114_0, arg_114_1)
	arg_114_0.teacherInfo = {}
	arg_114_0.studentInfo = {}

	if arg_114_1 == nil or not arg_114_1.accept_time then
		return
	end

	arg_114_0.teacherInfo.acceptTime = arg_114_1.accept_time[1]
	arg_114_0.studentInfo.acceptTime = arg_114_1.accept_time[2]
	arg_114_0.teacherInfo.brokeTime = arg_114_1.broke_time[1]
	arg_114_0.studentInfo.brokeTime = arg_114_1.broke_time[2]
	arg_114_0.teacherInfo.applyTimes = arg_114_1.daily_apply_times[1]
	arg_114_0.studentInfo.applyTimes = arg_114_1.daily_apply_times[2]
	arg_114_0.teacherInfo.intimacyAdd = arg_114_1.daily_intimacy_add[1]
	arg_114_0.studentInfo.intimacyAdd = arg_114_1.daily_intimacy_add[2]
	arg_114_0.teacherInfo.intimacy = arg_114_1.intimacies[1]
	arg_114_0.studentInfo.intimacy = arg_114_1.intimacies[2]
	arg_114_0.teacherInfo.idInfo = arg_114_1.relations[1]
	arg_114_0.studentInfo.idInfo = arg_114_1.relations[2]
end

function var_0_0.getStartTeacherInfo(arg_115_0, arg_115_1)
	local var_115_0 = arg_115_1.params

	arg_115_0.classApplyList = {}
	arg_115_0.classMissionList = {}

	if var_115_0 then
		arg_115_0:freshClassInfo(var_115_0)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_CLASS_MISSION_RED,
		hasRed = arg_115_0:sortClassMissionList()
	})
end

function var_0_0.getFindingList(arg_116_0, arg_116_1, arg_116_2)
	local var_116_0 = arg_116_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_CLASS_FINDING_LIST, var_116_0, function(arg_117_0, arg_117_1)
		if arg_116_2 then
			arg_116_2(arg_117_0, arg_117_1)
		end
	end)
end

function var_0_0.ApplyRelation(arg_118_0, arg_118_1, arg_118_2)
	local var_118_0 = arg_118_1 or {}

	xyd.Backend.get():request(xyd.mid.APPLY_RELATION, var_118_0, function(arg_119_0, arg_119_1)
		if arg_119_0 == xyd.error.OK and arg_119_1 then
			arg_118_0:freshClassInfo(arg_119_1)
		end

		if arg_118_2 then
			arg_118_2(arg_119_0, arg_119_1)
		end
	end)
end

function var_0_0.acceptTeachApply(arg_120_0, arg_120_1, arg_120_2)
	local var_120_0 = arg_120_1 or {}

	xyd.Backend.get():request(xyd.mid.ACCEPT_TEACH_APPLY, var_120_0, function(arg_121_0, arg_121_1)
		if arg_121_0 == xyd.error.OK and arg_121_1 then
			arg_120_0:freshClassInfo(arg_121_1)
		end

		if arg_120_2 then
			arg_120_2(arg_121_0, arg_121_1)
		end
	end)
end

function var_0_0.denyTeachApply(arg_122_0, arg_122_1, arg_122_2)
	local var_122_0 = arg_122_1 or {}

	xyd.Backend.get():request(xyd.mid.DENY_TEACH_APPLY, var_122_0, function(arg_123_0, arg_123_1)
		if arg_122_2 then
			arg_122_2(arg_123_0, arg_123_1)
		end
	end)
end

function var_0_0.terminateRelation(arg_124_0, arg_124_1, arg_124_2)
	local var_124_0 = arg_124_1 or {}

	xyd.Backend.get():request(xyd.mid.TERMINATE_RELATION, var_124_0, function(arg_125_0, arg_125_1)
		if arg_125_0 == xyd.error.OK and arg_125_1 then
			arg_124_0:freshClassInfo(arg_125_1)
		end

		if arg_124_2 then
			arg_124_2(arg_125_0, arg_125_1)
		end
	end)
end

function var_0_0.getClassAward(arg_126_0, arg_126_1, arg_126_2)
	local var_126_0 = arg_126_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_CLASS_MISSION_AWARD, var_126_0, function(arg_127_0, arg_127_1)
		if arg_126_2 then
			arg_126_2(arg_127_0, arg_127_1)
		end
	end)
end

return var_0_0
