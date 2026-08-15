local var_0_0 = class("SocialSystemWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = class("ScrollView", cc.ui.UIListView)

function var_0_2.ctor(arg_1_0, arg_1_1)
	var_0_2.super.ctor(arg_1_0, arg_1_1)
end

function var_0_2.scrollAuto(arg_2_0)
	return
end

local var_0_3 = 8
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
local var_0_5 = {
	CHARGE_NUM = 4,
	LEVEL = 3,
	PLAYER_NUM = 1,
	HERO_NUM = 2
}
local var_0_6 = {
	HasInvited = 2,
	Mission = 1
}
local var_0_7 = {
	DoneMission = 3,
	GetMission = 1,
	OnDoingMission = 2,
	RecallAward = 4
}
local var_0_8 = {
	TEACHER = 3,
	FRIEND = 1,
	INDIEGOGO = 2
}

function var_0_0.ctor(arg_3_0, arg_3_1, arg_3_2)
	var_0_0.super.ctor(arg_3_0, arg_3_1, arg_3_2)

	arg_3_0.arena = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_3_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_3_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_3_0.invite = xyd.ModelManager.get():loadModel(xyd.ModelType.INVITE_FRIENDS_INFOS)
	arg_3_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_3_0.adventureEvent = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	arg_3_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_3_0.inviteState = var_0_6.Mission
	arg_3_0.recallState = var_0_7.GetMission
	arg_3_0.windowState = var_0_4.FriendList
	arg_3_0.data = {}
	arg_3_0.list = {}
	arg_3_0.recallData = {}
	arg_3_0.topMenuType = nil

	if not arg_3_2 or not arg_3_2.not_clear_library_history then
		local var_3_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)

		if var_3_0.retainHistoryTmp then
			var_3_0.retainHistoryTmp = nil
		end
	end

	if arg_3_2 and arg_3_2.goToClass then
		arg_3_0.goToClass = arg_3_2.goToClass
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super:willOpen(arg_4_1)
	arg_4_0:setLeftButtonClick()
	arg_4_0:setRightButtonClick()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.ECONOMY_AFTER, function(arg_5_0)
		if arg_4_0 and not tolua.isnull(arg_4_0) then
			arg_4_0:nodeByName("coin_num_txt"):setString(arg_4_0.selfPlayer.friendshipCoin)
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.REFRESH_CLASS_MISSION_RED, function(arg_6_0)
		if arg_4_0 and not tolua.isnull(arg_4_0) then
			local var_6_0 = arg_6_0.hasRed

			if arg_4_0.socialSystem:checkHasTeacherApplyRed() then
				var_6_0 = true
			end

			arg_4_0:updateClassPoint(var_6_0)
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.REFRESH_MASTER_APPLY_RED, function(arg_7_0)
		if arg_4_0 and not tolua.isnull(arg_4_0) then
			local var_7_0 = arg_4_0.socialSystem:checkHasTeacherApplyRed()

			if arg_4_0.socialSystem:sortClassMissionList() then
				var_7_0 = true
			end

			arg_4_0:updateClassPoint(var_7_0)
		end
	end)
	arg_4_0:layout()
	arg_4_0.invite:loadInviteInfos(function(arg_8_0)
		if arg_8_0 == xyd.error.OK and arg_4_0 and not tolua.isnull(arg_4_0) then
			arg_4_0:swapInviteState(var_0_6.Mission)
		end
	end)
end

function var_0_0.updateClassPoint(arg_9_0, arg_9_1)
	if arg_9_1 then
		arg_9_0:nodeByName("red_point_teacher"):setVisible(true)
	else
		arg_9_0:nodeByName("red_point_teacher"):setVisible(false)
	end
end

function var_0_0.updateReadNoticeBtnShow(arg_10_0)
	arg_10_0.isDeleteAllNotice = false

	if arg_10_0.socialSystem.noticelist then
		for iter_10_0 = 1, #arg_10_0.socialSystem.noticelist do
			if arg_10_0.socialSystem.noticelist[iter_10_0].notice_type == xyd.FriendNoticeType.GIFT and arg_10_0.socialSystem.receiveGiftCount < xyd.tables.misc.giftGetLimit then
				arg_10_0:nodeByName("one_key_delete_all_text"):setVisible(false)
				arg_10_0:nodeByName("one_key_get_all_text"):setVisible(true)

				return
			end
		end
	end

	arg_10_0:nodeByName("one_key_delete_all_text"):setVisible(true)
	arg_10_0:nodeByName("one_key_get_all_text"):setVisible(false)

	arg_10_0.isDeleteAllNotice = true
end

function var_0_0.setLeftButtonClick(arg_11_0)
	for iter_11_0 = 1, var_0_3 - 1 do
		arg_11_0:nodeByName("subBtn" .. iter_11_0):addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				arg_11_0:swapWindowState(iter_11_0)
			end
		end)
	end
end

function var_0_0.swapWindowState(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	if arg_13_2 then
		arg_13_0.currentFriend = arg_13_2

		arg_13_0:hideSocialSystem(true)
		arg_13_0:updateTopBtnType(var_0_8.FRIEND)

		arg_13_0.teacherState = arg_13_3
		arg_13_0.inTeacher = true
	else
		arg_13_0.inTeacher = false
	end

	if arg_13_1 then
		arg_13_0.windowState = arg_13_1
	end

	local var_13_0 = arg_13_0.windowState

	if var_13_0 == var_0_4.FriendShip then
		arg_13_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.FRIENDSHIP_EXCHANGE)
	end

	if var_13_0 == var_0_4.FriendList or var_13_0 == var_0_4.ApplyYList or var_13_0 == var_0_4.NoticeMsg or var_13_0 == var_0_4.BlackList then
		arg_13_0:nodeByName("bottom_bg"):setVisible(true)
	else
		arg_13_0:nodeByName("bottom_bg"):setVisible(false)
	end

	arg_13_0:updateLeftButtonState()
	arg_13_0:updateShowBaseOnState()
	arg_13_0:updateRightList()
end

function var_0_0.swapInviteState(arg_14_0, arg_14_1)
	if arg_14_1 then
		arg_14_0.inviteState = arg_14_1
	end

	arg_14_0:initInviteData()
	arg_14_0:initInviteFriendsByState()
	arg_14_0.listView:reload()
	arg_14_0:updateNPCTips()
end

function var_0_0.swapRecallState(arg_15_0, arg_15_1)
	if arg_15_1 then
		arg_15_0.recallState = arg_15_1
	end

	arg_15_0:initRecallData()
	arg_15_0:initRecallFriendsByState()
	arg_15_0.recallList:reload()
	arg_15_0:updateNPCTips()
end

function var_0_0.initRecallData(arg_16_0)
	local var_16_0 = arg_16_0.socialSystem:getRecallFriendLists()

	arg_16_0:nodeByName("recall_blank_tips"):setVisible(false)
	arg_16_0:nodeByName("recall_blank_tips"):setString(var_0_1:translation("FRIEND_RECALL_TIP_6"))

	if arg_16_0.recallState == var_0_7.GetMission then
		arg_16_0.recallData = var_16_0.canRecall
	elseif arg_16_0.recallState == var_0_7.OnDoingMission then
		arg_16_0.recallData = var_16_0.onDoing
	elseif arg_16_0.recallState == var_0_7.DoneMission then
		arg_16_0.recallData = var_16_0.doneRecall
	elseif arg_16_0.recallState == var_0_7.RecallAward then
		arg_16_0.recallData = {}
		arg_16_0.recallData.canAward = var_16_0.canAward
		arg_16_0.recallData.cannotAward = var_16_0.cannotAward
		arg_16_0.recallData.awarded = var_16_0.awarded
	end
end

function var_0_0.initRecallFriendsByState(arg_17_0)
	arg_17_0:nodeByName("get_recall_btn"):setBrightStyle(ccui.BrightStyle.normal)
	arg_17_0:nodeByName("doing_recall_btn"):setBrightStyle(ccui.BrightStyle.normal)
	arg_17_0:nodeByName("recall_award_btn"):setBrightStyle(ccui.BrightStyle.normal)
	arg_17_0:nodeByName("done_recall_btn"):setBrightStyle(ccui.BrightStyle.normal)

	if arg_17_0.recallState == var_0_7.GetMission then
		arg_17_0:nodeByName("get_recall_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_17_0.recallState == var_0_7.OnDoingMission then
		arg_17_0:nodeByName("doing_recall_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_17_0.recallState == var_0_7.DoneMission then
		arg_17_0:nodeByName("done_recall_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_17_0.recallState == var_0_7.RecallAward then
		arg_17_0:nodeByName("recall_award_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.initChatDataBaseOnState(arg_18_0)
	if arg_18_0.windowState == var_0_4.FriendList then
		arg_18_0.data = arg_18_0.socialSystem.friendlist

		arg_18_0:sortFriendListByState()
	elseif arg_18_0.windowState == var_0_4.ApplyYList then
		arg_18_0.data = arg_18_0.socialSystem.requestlist

		table.sort(arg_18_0.data, function(arg_19_0, arg_19_1)
			return arg_19_0.request_time > arg_19_1.request_time
		end)
	elseif arg_18_0.windowState == var_0_4.NoticeMsg then
		arg_18_0.data = arg_18_0.socialSystem.noticelist

		arg_18_0:sortNoticeData()
	elseif arg_18_0.windowState == var_0_4.BlackList then
		arg_18_0.data = arg_18_0.socialSystem.blacklist
	elseif arg_18_0.windowState == var_0_4.InviteFriend then
		arg_18_0.data = {}
	end
end

function var_0_0.sortNoticeData(arg_20_0)
	table.sort(arg_20_0.data, function(arg_21_0, arg_21_1)
		if arg_21_0.notice_type == xyd.FriendNoticeType.GUILD_INVITE and arg_21_1.notice_type == xyd.FriendNoticeType.GUILD_INVITE then
			return arg_21_0.notice_time < arg_21_1.notice_time
		elseif arg_21_0.notice_type == xyd.FriendNoticeType.GUILD_INVITE then
			return true
		elseif arg_21_1.notice_type == xyd.FriendNoticeType.GUILD_INVITE then
			return false
		else
			return arg_21_0.notice_time > arg_21_1.notice_time
		end
	end)
end

function var_0_0.sortFriendListByState(arg_22_0)
	local var_22_0 = arg_22_0.socialSystem:getFriendInvertedOrder()

	table.sort(arg_22_0.data, function(arg_23_0, arg_23_1)
		if var_22_0 == 1 then
			return arg_23_0.last_time < arg_23_1.last_time
		end

		local var_23_0 = xyd.db.newMessagesTime:getTime(arg_22_0.selfPlayer.playerID, arg_23_0.player_id)
		local var_23_1 = xyd.db.newMessagesTime:getTime(arg_22_0.selfPlayer.playerID, arg_23_1.player_id)

		if arg_23_0.is_online == arg_23_1.is_online and (var_23_0 > 0 or var_23_1 > 0) then
			return var_23_1 < var_23_0
		end

		if arg_23_0.is_online ~= arg_23_1.is_online then
			return arg_23_0.is_online > arg_23_1.is_online
		end

		local var_23_2 = xyd.db.newMessagesCount:getCount(arg_22_0.selfPlayer.playerID, arg_23_0.player_id)
		local var_23_3 = xyd.db.newMessagesCount:getCount(arg_22_0.selfPlayer.playerID, arg_23_1.player_id)

		if var_23_2 ~= var_23_3 then
			return var_23_3 <= var_23_2
		else
			return arg_23_0.last_time > arg_23_1.last_time
		end
	end)
end

function var_0_0.updateRightList(arg_24_0, arg_24_1)
	if arg_24_1 then
		arg_24_0:initChatDataBaseOnState()
		arg_24_0.rightUpperList:refreshList()
	else
		arg_24_0:initChatDataBaseOnState()
		arg_24_0.rightUpperList:reload()
	end

	arg_24_0:updateNPCTips()

	if arg_24_0.orgPositonY and arg_24_0.windowState == var_0_4.FriendList then
		arg_24_0:scrollToOrgPositonY()
	end

	if arg_24_0.windowState == var_0_4.NoticeMsg then
		arg_24_0.socialSystem:setIsHasNewNoticeState(0)
	end

	arg_24_0:updateRedMark()
	arg_24_0.socialSystem:refreshRedMark()
end

function var_0_0.updateNPCTips(arg_25_0)
	if arg_25_0:nodeByName("btn_friend"):isTouchEnabled() then
		arg_25_0:nodeByName("NPC"):setVisible(false)

		return
	end

	local var_25_0 = arg_25_0:nodeByName("NPC")

	var_25_0:setPositionY(355)

	local var_25_1 = xyd.split(var_0_1:translation("SOCIAL_SYSTEM_NPC_TIPS"), ",")

	if #arg_25_0.data <= 0 and arg_25_0.windowState ~= var_0_4.InviteFriend and arg_25_0.getWindowBackFromTeacher ~= true and arg_25_0.windowState ~= var_0_4.Chating and arg_25_0.windowState ~= var_0_4.FriendShip and arg_25_0.windowState ~= var_0_4.RecallFriend then
		arg_25_0:nodeByName("NPC"):setVisible(true)
		arg_25_0:nodeByName("tips_txt"):setString(string.format(var_0_1:translation("SOCIAL_SYSTEM_NPC_TEXT"), var_25_1[arg_25_0.windowState] or ""))
	elseif #arg_25_0.list <= 0 and arg_25_0.windowState == var_0_4.InviteFriend and arg_25_0.inviteState == var_0_6.HasInvited then
		arg_25_0:nodeByName("NPC"):setVisible(true)
		arg_25_0:nodeByName("tips_txt"):setString(var_0_1:translation("SOCIAL_SYSTEM_NPC_TIPS_2"))
		var_25_0:setPositionY(325)
	elseif #arg_25_0.recallData <= 0 and arg_25_0.windowState == var_0_4.RecallFriend and arg_25_0.recallState == var_0_7.GetMission then
		arg_25_0:nodeByName("NPC"):setVisible(true)
		arg_25_0:nodeByName("tips_txt"):setString(var_0_1:translation("SOCIAL_SYSTEM_NPC_TIPS_3"))
		var_25_0:setPositionY(325)
	else
		arg_25_0:nodeByName("NPC"):setVisible(false)
	end
end

function var_0_0.setOrgPositonY(arg_26_0)
	arg_26_0.orgPositonY = arg_26_0.rightUpperList:getScrollNode():getPositionY()
end

function var_0_0.scrollToOrgPositonY(arg_27_0)
	arg_27_0.rightUpperList:getScrollNode():setPositionY(arg_27_0.orgPositonY)

	arg_27_0.orgPositonY = nil
end

function var_0_0.updateRedMark(arg_28_0)
	local var_28_0 = false

	for iter_28_0 = 1, var_0_3 - 1 do
		arg_28_0:nodeByName("subBtn" .. iter_28_0):getChildByName("red_point"):setVisible(false)
	end

	if arg_28_0.socialSystem:isFriendListRedMarkShow() then
		arg_28_0:nodeByName("subBtn1"):getChildByName("red_point"):setVisible(true)

		var_28_0 = true
	end

	if arg_28_0.socialSystem:isApplyListRedMarkShow() then
		arg_28_0:nodeByName("subBtn2"):getChildByName("red_point"):setVisible(true)

		var_28_0 = true
	end

	if arg_28_0.socialSystem:isNoticeListRedMarkShow() then
		arg_28_0:nodeByName("subBtn3"):getChildByName("red_point"):setVisible(true)

		var_28_0 = true
	end

	if arg_28_0.invite:isInviteRedMarkShow() then
		arg_28_0:nodeByName("subBtn5"):getChildByName("red_point"):setVisible(true)

		var_28_0 = true
	end

	if arg_28_0.socialSystem:isRecallRedPointShow() then
		arg_28_0:nodeByName("subBtn7"):getChildByName("red_point"):setVisible(true)

		var_28_0 = true
	end

	arg_28_0:nodeByName("get_recall_btn"):getChildByName("red_point"):setVisible(false)

	if arg_28_0.socialSystem:isGetRecallRedPointShow() then
		arg_28_0:nodeByName("get_recall_btn"):getChildByName("red_point"):setVisible(true)

		var_28_0 = true
	end

	arg_28_0:nodeByName("recall_award_btn"):getChildByName("red_point"):setVisible(false)

	if arg_28_0.socialSystem:isRecallAwardRedPointShow() then
		arg_28_0:nodeByName("recall_award_btn"):getChildByName("red_point"):setVisible(true)

		var_28_0 = true
	end

	if var_28_0 then
		arg_28_0:nodeByName("red_point_friend"):setVisible(true)
	else
		arg_28_0:nodeByName("red_point_friend"):setVisible(false)
	end
end

function var_0_0.updateLeftButtonState(arg_29_0)
	for iter_29_0 = 1, var_0_3 - 1 do
		if arg_29_0.windowState == iter_29_0 then
			arg_29_0:nodeByName("subBtn" .. iter_29_0):setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_29_0:nodeByName("subBtn" .. iter_29_0):setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.updateShowBaseOnState(arg_30_0)
	for iter_30_0 = 1, var_0_3 do
		if arg_30_0.windowState == iter_30_0 then
			arg_30_0:nodeByName("bottom" .. iter_30_0):setVisible(true)
		else
			arg_30_0:nodeByName("bottom" .. iter_30_0):setVisible(false)
		end
	end
end

function var_0_0.setRightButtonClick(arg_31_0)
	arg_31_0:nodeByName("add_friend_btn"):addTouchEventListener(function(arg_32_0, arg_32_1)
		xyd.buttonScaleAnim(arg_32_0, arg_32_1)

		if arg_32_1 == ccui.TouchEventType.ended then
			arg_31_0.socialSystem:getRecommendFriends({}, function(arg_33_0, arg_33_1)
				if arg_33_0 == xyd.error.OK then
					local var_33_0 = {
						data = arg_33_1.list or {}
					}

					xyd.WindowManager.get():openWindow("add_friend_wnd", var_33_0)
				end
			end)
		end
	end)
	arg_31_0:nodeByName("ignore_all_btn"):addTouchEventListener(function(arg_34_0, arg_34_1)
		xyd.buttonScaleAnim(arg_34_0, arg_34_1)

		if arg_34_1 == ccui.TouchEventType.ended then
			if #arg_31_0.socialSystem.requestlist <= 0 then
				local var_34_0 = var_0_1:translation("SOCIAL_SYSTEM_TEXT_10")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_34_0
				})

				return
			end

			local var_34_1 = {
				player_ids = arg_31_0:getPlayerIds(arg_31_0.socialSystem.requestlist)
			}

			arg_31_0.socialSystem:ignoreFriendRequest(var_34_1, function(arg_35_0, arg_35_1)
				if arg_35_0 == xyd.error.OK then
					arg_31_0.socialSystem.requestlist = {}
					arg_31_0.data = {}

					arg_31_0:updateRightList()
				end
			end)
		end
	end)
	arg_31_0:nodeByName("refuse_all_btn"):addTouchEventListener(function(arg_36_0, arg_36_1)
		xyd.buttonScaleAnim(arg_36_0, arg_36_1)

		if arg_36_1 == ccui.TouchEventType.ended then
			if #arg_31_0.socialSystem.requestlist <= 0 then
				local var_36_0 = var_0_1:translation("SOCIAL_SYSTEM_TEXT_10")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_36_0
				})

				return
			end

			if arg_31_0.socialSystem:getFriendsCount() >= xyd.tables.misc.friendNumberLimit then
				local var_36_1 = var_0_1:translation("FRIEND_NUM_LIMIT_TIPS")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_36_1
				})

				return
			end

			local var_36_2 = {
				player_ids = arg_31_0:getPlayerIds(arg_31_0.socialSystem.requestlist)
			}

			arg_31_0.socialSystem:acceptAllFriendRequest(var_36_2, function(arg_37_0, arg_37_1)
				if arg_37_0 == xyd.error.OK then
					dump(arg_37_1)

					for iter_37_0 = #arg_31_0.socialSystem.requestlist, 1, -1 do
						if arg_37_1[tostring(arg_31_0.socialSystem.requestlist[iter_37_0].player_id)] then
							table.remove(arg_31_0.socialSystem.requestlist, iter_37_0)
						end
					end

					for iter_37_1, iter_37_2 in pairs(arg_37_1) do
						table.insert(arg_31_0.socialSystem.friendlist, iter_37_2)
					end

					if #arg_31_0.socialSystem.requestlist > 0 then
						if #arg_31_0.socialSystem.friendlist == xyd.tables.misc.friendNumberLimit then
							local var_37_0 = var_0_1:translation("FRIEND_NUM_LIMIT_TIPS")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_37_0
							})
						else
							local var_37_1 = var_0_1:translation("SOCIAL_SYSTEM_TEXT_9")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_37_1
							})
						end
					end

					arg_31_0:updateRightList()
				end
			end)
		end
	end)
	arg_31_0:nodeByName("add_btn"):addTouchEventListener(function(arg_38_0, arg_38_1)
		xyd.buttonScaleAnim(arg_38_0, arg_38_1)

		if arg_38_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("add_blacklist_wnd")
		end
	end)
	arg_31_0:nodeByName("get_all_btn"):addTouchEventListener(function(arg_39_0, arg_39_1)
		xyd.buttonScaleAnim(arg_39_0, arg_39_1)

		if arg_39_1 == ccui.TouchEventType.ended then
			if #arg_31_0.socialSystem.noticelist == 0 then
				return
			end

			if arg_31_0.isDeleteAllNotice == false and arg_31_0.socialSystem.receiveGiftCount >= xyd.tables.misc.giftGetLimit then
				local var_39_0 = var_0_1:translation("REACH_RECEIVE_GIFT_LIMIT_TEXT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_39_0
				})

				return
			end

			local var_39_1 = {}

			for iter_39_0 = 1, #arg_31_0.socialSystem.noticelist do
				if arg_31_0.isDeleteAllNotice == false and arg_31_0.socialSystem.noticelist[iter_39_0].notice_type == xyd.FriendNoticeType.GIFT and arg_31_0.socialSystem.receiveGiftCount + #var_39_1 < xyd.tables.misc.giftGetLimit then
					table.insert(var_39_1, arg_31_0.socialSystem.noticelist[iter_39_0].notice_id)
				elseif arg_31_0.isDeleteAllNotice == true and arg_31_0.socialSystem.noticelist[iter_39_0].notice_type ~= xyd.FriendNoticeType.GIFT then
					table.insert(var_39_1, arg_31_0.socialSystem.noticelist[iter_39_0].notice_id)
				end
			end

			local var_39_2 = {
				notice_ids = var_39_1
			}

			arg_31_0.socialSystem:readNotice(var_39_2, function(arg_40_0, arg_40_1)
				if arg_40_0 == xyd.error.OK then
					if arg_40_1 and arg_40_1.awards then
						arg_31_0.selfPlayer:handleRewards(arg_40_1.awards)
					end

					for iter_40_0 = #arg_31_0.socialSystem.noticelist, 1, -1 do
						if arg_31_0.socialSystem.noticelist[iter_40_0].notice_type == xyd.FriendNoticeType.GIFT then
							arg_31_0.socialSystem.receiveGiftCount = arg_31_0.socialSystem.receiveGiftCount + 1
						end

						if arg_31_0:isIn(arg_40_1.ids, arg_31_0.socialSystem.noticelist[iter_40_0].notice_id) then
							table.remove(arg_31_0.socialSystem.noticelist, iter_40_0)
						end
					end

					arg_31_0:updateRightList()
					arg_31_0:updateReadNoticeBtnShow()
				end
			end)
		end
	end)
	arg_31_0:nodeByName("clear_btn"):addTouchEventListener(function(arg_41_0, arg_41_1)
		xyd.buttonScaleAnim(arg_41_0, arg_41_1)

		if arg_41_1 == ccui.TouchEventType.ended then
			if #arg_31_0.socialSystem.blacklist == 0 then
				return
			end

			arg_31_0.socialSystem:clearBlackList({}, function(arg_42_0)
				if arg_42_0 == xyd.error.OK then
					arg_31_0.socialSystem.blacklist = {}
					arg_31_0.data = {}

					arg_31_0:updateRightList()
				end
			end)
		end
	end)
	arg_31_0:nodeByName("select"):setTouchSwallowEnabled(false)
	arg_31_0:nodeByName("select_box"):setTouchEnabled(true)
	arg_31_0:nodeByName("select_box"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_43_0)
		if arg_43_0.name == "began" then
			arg_31_0:nodeByName("select_box"):setScale(0.9)

			return true
		elseif arg_43_0.name == "ended" then
			arg_31_0:nodeByName("select_box"):setScale(1)
			arg_31_0.socialSystem:setFriendInvertedOrder()
			arg_31_0:updateFriendListSortType()
		end
	end)
	arg_31_0:setInviteFriendsButtonClick()
	arg_31_0:setRecallFriendsButtonClick()
end

function var_0_0.updateFriendListSortType(arg_44_0)
	arg_44_0:nodeByName("sort_type_desc"):setString(var_0_1:translation("FRIEND_INVERTED_ORDER"))

	if arg_44_0.socialSystem:getFriendInvertedOrder() == 1 then
		arg_44_0:nodeByName("select"):setVisible(true)
	else
		arg_44_0:nodeByName("select"):setVisible(false)
	end

	arg_44_0:updateRightList()
end

function var_0_0.isIn(arg_45_0, arg_45_1, arg_45_2)
	for iter_45_0, iter_45_1 in pairs(arg_45_1) do
		if arg_45_2 == iter_45_1 then
			return true
		end
	end

	return false
end

function var_0_0.getPlayerIds(arg_46_0, arg_46_1)
	local var_46_0 = {}

	for iter_46_0 = 1, #arg_46_1 do
		table.insert(var_46_0, arg_46_1[iter_46_0].player_id)
	end

	return var_46_0
end

function var_0_0.setInviteFriendsButtonClick(arg_47_0)
	arg_47_0:nodeByName("input_btn"):addTouchEventListener(function(arg_48_0, arg_48_1)
		if arg_48_1 == ccui.TouchEventType.ended then
			if arg_47_0.windowState ~= var_0_6.Mission then
				arg_47_0:swapInviteState(var_0_6.Mission)
			end

			if arg_47_0.invite:getInvitorID() > 0 then
				local var_48_0 = string.format(var_0_1:translation("HAS_BEEN_INVITED"), arg_47_0.invite:getInvitorName())

				xyd.WindowManager.get():openWindow("toast", {
					message = var_48_0
				})

				return
			end

			if arg_47_0.selfPlayer.lev < xyd.tables.misc.inviteLevLimit then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(xyd.tables.translation:translation("TIP_CODE")), function()
					xyd.WindowManager.get():openWindow("input_invite_code")
				end, nil, nil, arg_47_0.colorMode)
			else
				local var_48_1 = var_0_1:translation("INVITE_LEV_LIMIT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_48_1
				})
			end
		end
	end)
	arg_47_0:nodeByName("invite_btn"):addTouchEventListener(function(arg_50_0, arg_50_1)
		if arg_50_1 == ccui.TouchEventType.ended then
			if arg_47_0.windowState ~= var_0_6.Mission then
				arg_47_0:swapInviteState(var_0_6.Mission)
			end

			xyd.WindowManager.get():openWindow("copy_code")
		end
	end)
	arg_47_0:nodeByName("has_invited_btn"):addTouchEventListener(function(arg_51_0, arg_51_1)
		if arg_51_1 == ccui.TouchEventType.ended and arg_47_0.inviteState ~= var_0_6.HasInvited then
			arg_47_0:swapInviteState(var_0_6.HasInvited)
		end
	end)
end

function var_0_0.setRecallFriendsButtonClick(arg_52_0)
	arg_52_0:nodeByName("get_recall_btn"):addTouchEventListener(function(arg_53_0, arg_53_1)
		if arg_53_1 == ccui.TouchEventType.ended then
			arg_52_0:swapRecallState(var_0_7.GetMission)
		end
	end)
	arg_52_0:nodeByName("doing_recall_btn"):addTouchEventListener(function(arg_54_0, arg_54_1)
		if arg_54_1 == ccui.TouchEventType.ended then
			arg_52_0:swapRecallState(var_0_7.OnDoingMission)
		end
	end)
	arg_52_0:nodeByName("done_recall_btn"):addTouchEventListener(function(arg_55_0, arg_55_1)
		if arg_55_1 == ccui.TouchEventType.ended then
			arg_52_0:swapRecallState(var_0_7.DoneMission)
		end
	end)
	arg_52_0:nodeByName("recall_award_btn"):addTouchEventListener(function(arg_56_0, arg_56_1)
		if arg_56_1 == ccui.TouchEventType.ended then
			arg_52_0:swapRecallState(var_0_7.RecallAward)
		end
	end)
end

function var_0_0.initInviteData(arg_57_0)
	if arg_57_0.inviteState == var_0_6.Mission then
		arg_57_0.list = arg_57_0:resortMissionList(arg_57_0.invite:getInviteMissions())
	elseif arg_57_0.inviteState == var_0_6.HasInvited then
		arg_57_0.list = arg_57_0.invite:getInviteFriends()
	end
end

function var_0_0.resortMissionList(arg_58_0, arg_58_1)
	local var_58_0 = {}
	local var_58_1 = 0

	for iter_58_0 = 1, #arg_58_1 do
		if arg_58_1[iter_58_0].can_award then
			var_58_1 = var_58_1 + 1

			table.insert(var_58_0, var_58_1, arg_58_1[iter_58_0])
		else
			table.insert(var_58_0, #var_58_0 + 1, arg_58_1[iter_58_0])
		end
	end

	return var_58_0
end

function var_0_0.initInviteFriendsByState(arg_59_0)
	if arg_59_0.selfPlayer.lev < xyd.tables.misc.inviteLevLimit and arg_59_0.invite:getInvitorID() <= 0 then
		arg_59_0:nodeByName("input_btn"):setBright(true)
	else
		arg_59_0:nodeByName("input_btn"):setBright(false)
		arg_59_0:nodeByName("input_btn"):setTouchEnabled(false)
	end

	if arg_59_0.inviteState == var_0_6.Mission then
		arg_59_0:nodeByName("has_invited_btn"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_59_0.inviteState == var_0_6.HasInvited then
		arg_59_0:nodeByName("has_invited_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.didOpen(arg_60_0, arg_60_1)
	var_0_0.super:didOpen(arg_60_1)
	arg_60_0:addBgEffect(2, arg_60_0:nodeByName("background_2"))
end

function var_0_0.layout(arg_61_0)
	arg_61_0:nodeByName("name_bg"):setTouchEnabled(true)
	arg_61_0:nodeByName("name_bg"):setTouchSwallowEnabled(true)

	arg_61_0.inviteList = arg_61_0:nodeByName("list")
	arg_61_0.recallScroll = arg_61_0:nodeByName("recall_scroll")
	arg_61_0.rightUpperScroll = arg_61_0:nodeByName("right_upper_scroll")

	local var_61_0 = arg_61_0.rightUpperScroll:getContentSize()

	arg_61_0.rightUpperList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 5, var_61_0.width, var_61_0.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_61_0.rightUpperScroll):onScroll(handler(arg_61_0, arg_61_0.scrollListener))

	arg_61_0.rightUpperList:setBounceable(true)
	arg_61_0.rightUpperList:setDelegate(handler(arg_61_0, arg_61_0.rightUpperListDelegate))
	arg_61_0.rightUpperList:reload()

	local var_61_1 = arg_61_0.inviteList:getContentSize()

	arg_61_0.listView = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 5, var_61_1.width, var_61_1.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_61_0.inviteList):onScroll(handler(arg_61_0, arg_61_0.scrollListener))

	arg_61_0.listView:setBounceable(true)
	arg_61_0.listView:setDelegate(handler(arg_61_0, arg_61_0.listViewDelegate))
	arg_61_0.listView:reload()

	local var_61_2 = arg_61_0.recallScroll:getContentSize()

	arg_61_0.recallList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 5, var_61_2.width, var_61_2.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_61_0.recallScroll):onScroll(handler(arg_61_0, arg_61_0.scrollListener))

	arg_61_0.recallList:setBounceable(true)
	arg_61_0.recallList:setDelegate(handler(arg_61_0, arg_61_0.recallListDelegate))
	arg_61_0.recallList:reload()
	arg_61_0.socialSystem:loadFriends({}, function(arg_62_0, arg_62_1)
		if arg_62_0 == xyd.error.OK then
			arg_61_0:swapWindowState()
			arg_61_0:swapRecallState(arg_61_0.recallState)
		end
	end)
	arg_61_0:initFriendShip()
	arg_61_0:swapWindowState()
	arg_61_0:updateReadNoticeBtnShow()
	arg_61_0:initTopBtn()
	arg_61_0:initText()
	arg_61_0:nodeByName("limit_text"):setString(var_0_1:translation("FRIEND_NUM_LIMIT_TEXT"))

	local var_61_3 = false

	if arg_61_0.socialSystem.classMissionList then
		for iter_61_0 = 1, 2 do
			for iter_61_1, iter_61_2 in pairs(arg_61_0.socialSystem.classMissionList[iter_61_0]) do
				if iter_61_2.is_complete == 1 and iter_61_2.is_awarded == 0 then
					var_61_3 = true

					break
				end
			end

			if var_61_3 then
				break
			end
		end

		if arg_61_0.socialSystem:checkHasTeacherApplyRed() then
			var_61_3 = true
		end

		if var_61_3 then
			arg_61_0:nodeByName("red_point_teacher"):setVisible(true)
		else
			arg_61_0:nodeByName("red_point_teacher"):setVisible(false)
		end
	end

	if arg_61_0.goToClass then
		arg_61_0:gotoTeacher()

		arg_61_0.goToClass = false
	end

	arg_61_0:updateFriendListSortType()
end

function var_0_0.initFriendShip(arg_63_0)
	local var_63_0 = 3

	arg_63_0:nodeByName("coin_num_txt"):setString(arg_63_0.selfPlayer.friendshipCoin)
	arg_63_0:nodeByName("select_exchange_item_text"):setString(var_0_1:translation("SELECT_EXCHANGE_ITEM_TEXT"))

	for iter_63_0 = 1, var_63_0 do
		arg_63_0:nodeByName("item_pos" .. iter_63_0):removeAllChildren(true)

		local var_63_1 = arg_63_0:createExchangeItem(iter_63_0)

		var_63_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_63_1:addTo(arg_63_0:nodeByName("item_pos" .. iter_63_0))
	end
end

function var_0_0.createExchangeItem(arg_64_0, arg_64_1)
	local var_64_0 = display.newNode()
	local var_64_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/friendship_exchange/exchange_item.csb")
	local var_64_2 = var_64_1:getChildByName("container")
	local var_64_3 = xyd.tables.friendShopItem
	local var_64_4 = var_64_3:showItem(arg_64_1)

	var_64_2:getChildByName("name_txt"):setString(xyd.tables.item:name(var_64_4))
	var_64_2:getChildByName("price_txt"):setString(var_64_3:price(arg_64_1))
	xyd.setItemAndAddTips(var_64_2:getChildByName("icon_container"), var_64_4)
	var_64_2:getChildByName("exchange_btn"):getChildByName("exchange_text"):setString(var_0_1:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT2"))
	var_64_2:getChildByName("exchange_btn"):addTouchEventListener(function(arg_65_0, arg_65_1)
		xyd.buttonScaleAnim(arg_65_0, arg_65_1)

		if arg_65_1 == ccui.TouchEventType.ended then
			local var_65_0 = {
				id = arg_64_1,
				itemID = var_64_4
			}

			xyd.WindowManager.get():openWindow("friend_sure_exchange", var_65_0)
		end
	end)
	var_64_1:addTo(var_64_0)
	var_64_1:setAnchorPoint(cc.p(0, 0))
	var_64_0:setContentSize(var_64_2:getContentSize())
	var_64_1:setName("source")

	return var_64_0
end

function var_0_0.rightUpperListDelegate(arg_66_0, arg_66_1, arg_66_2, arg_66_3)
	if cc.ui.UIListView.COUNT_TAG == arg_66_2 then
		if arg_66_0.windowState == var_0_4.ApplyYList then
			arg_66_0:nodeByName("limit_txt"):setString(arg_66_0.socialSystem:getFriendsCount() .. "/" .. xyd.tables.misc.friendNumberLimit)
		end

		arg_66_0.data = arg_66_0.data or {}

		return #arg_66_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_66_2 then
		local var_66_0 = arg_66_0.rightUpperList:dequeueItem() or arg_66_0.rightUpperList:newItem()

		var_66_0:removeAllChildren(true)

		local var_66_1

		if arg_66_0.windowState == var_0_4.FriendList then
			var_66_1 = arg_66_0:createFriendItemContent(arg_66_0.data[arg_66_3], arg_66_3)
		elseif arg_66_0.windowState == var_0_4.ApplyYList then
			var_66_1 = arg_66_0:createApplyItemContent(arg_66_0.data[arg_66_3], arg_66_3)
		elseif arg_66_0.windowState == var_0_4.NoticeMsg then
			var_66_1 = arg_66_0:createNoticeItemContent(arg_66_0.data[arg_66_3], arg_66_3)
		elseif arg_66_0.windowState == var_0_4.BlackList then
			var_66_1 = arg_66_0:createBlackItemContent(arg_66_0.data[arg_66_3], arg_66_3)
		else
			var_66_1 = arg_66_0:createChatTitleContent()
		end

		if var_66_1.reportParams then
			arg_66_0:addRecordShareTouch(var_66_1)
		end

		local var_66_2 = var_66_1:getWidth()
		local var_66_3 = var_66_1:getHeight()

		var_66_0:setItemSize(var_66_2, var_66_3)
		var_66_0:addContent(var_66_1)

		return var_66_0
	end
end

function var_0_0.createChatTitleContent(arg_67_0)
	local var_67_0 = display.newNode()

	var_67_0:setContentSize(789, 80)

	return var_67_0
end

function var_0_0.addRecordShareTouch(arg_68_0, arg_68_1)
	local var_68_0 = arg_68_1.reportParams
	local var_68_1 = arg_68_1:getChildByName("source"):getChildByName("container"):getChildByName("message_node"):getChildByName("chat_msg")

	var_68_1:setTouchEnabled(true)
	var_68_1:setTouchSwallowEnabled(false)
	var_68_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_69_0)
		if arg_69_0.name == "ended" and not arg_68_0.scrollViewMoved_ then
			if var_68_0.record_id then
				local var_69_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)

				var_69_0:getPeakRecordsDetail({
					player_id = var_68_0.player_id,
					record_id = var_68_0.record_id
				}, function(arg_70_0)
					local var_70_0 = var_68_0.player_id == var_68_0.attackInfo.player_id
					local var_70_1 = {
						reportKeys = arg_70_0.report_keys,
						isWin = var_68_0.isWin,
						isAttack = var_70_0,
						wins = arg_70_0.wins,
						attackInfo = var_68_0.attackInfo,
						defendInfo = var_68_0.defendInfo,
						attackTeam = var_69_0:formatTeams(arg_70_0.attack_formations, var_68_0.attackInfo.conquer_lev),
						defendTeam = var_69_0:formatTeams(arg_70_0.defense_formations, var_68_0.defendInfo.conquer_lev)
					}

					xyd.WindowManager.get():openWindow("peak_arena_report", var_70_1)
				end)
			else
				local var_69_1 = {
					fighter_id = var_68_0.player_id,
					id = var_68_0.id
				}

				xyd.Backend.get():request(xyd.mid.LOAD_ARENA_FIGHT_RECORDS, var_69_1, function(arg_71_0, arg_71_1)
					if arg_71_0 == xyd.error.OK then
						local var_71_0 = arg_71_1.records

						if var_71_0.report and next(var_71_0.report) then
							local var_71_1 = {
								report = var_71_0.report,
								attackerName = var_71_0.attack_name,
								attackerLev = var_71_0.attack_lev,
								attackerAvatar = var_71_0.attack_avatar,
								attackerAvatarFrame = var_71_0.attack_avatar_frame,
								defenderName = var_71_0.defend_name,
								defenderLev = var_71_0.defend_lev,
								defenderAvatar = var_71_0.defend_avatar,
								defenderAvatarFrame = var_71_0.defend_avatar_frame,
								isAttack = var_71_0.is_attack,
								win = var_71_0.win
							}

							xyd.WindowManager.get():openWindow("arena_share", var_71_1)
						else
							if xyd.WindowManager.get():getWindow("toast") ~= nil then
								xyd.WindowManager.get():closeWindow("toast")
							end

							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
							})

							return
						end
					end
				end)
			end
		end

		return true
	end)
end

function var_0_0.createFriendItemContent(arg_72_0, arg_72_1, arg_72_2)
	local var_72_0 = display.newNode()
	local var_72_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/manage_friend/friend_item.csb")
	local var_72_2 = var_72_1:getChildByName("container")
	local var_72_3 = var_72_2:getChildByName("name_bg")
	local var_72_4 = {
		avatar_id = arg_72_1.avatar_id,
		avatar_frame_id = arg_72_1.avatar_frame_id
	}

	if arg_72_1.is_online == 0 then
		var_72_4.isGray = true
	end

	var_72_4.playerInfo = arg_72_1

	xyd.setPlayerAvatar(var_72_2:getChildByName("avtar_container"), var_72_4)
	arg_72_0.socialSystem:setNameBg(var_72_3, arg_72_1)
	var_72_2:getChildByName("newmsg_tip"):getChildByName("right_txt"):setString(var_0_1:translation("HAVE_NEW_MESSAGE_TEXT") .. "]")

	if xyd.db.newMessagesCount:getCount(arg_72_0.selfPlayer.playerID, arg_72_1.player_id) > 0 then
		var_72_2:getChildByName("newmsg_tip"):setVisible(true)
		var_72_2:getChildByName("friend_state_txt"):setVisible(false)
	else
		var_72_2:getChildByName("newmsg_tip"):setVisible(false)
		var_72_2:getChildByName("friend_state_txt"):setVisible(true)
		arg_72_0.socialSystem:setOnlineState(var_72_2:getChildByName("friend_state_txt"), arg_72_1)
	end

	var_72_1:addTo(var_72_0)
	var_72_1:setAnchorPoint(cc.p(0, 0))
	var_72_0:setContentSize(var_72_2:getContentSize())
	var_72_1:setName("source")
	var_72_2:getChildByName("chat_btn"):setTouchEnabled(true)
	var_72_2:getChildByName("chat_btn"):addTouchEventListener(function(arg_73_0, arg_73_1)
		xyd.buttonScaleAnim(arg_73_0, arg_73_1)

		if arg_73_1 == ccui.TouchEventType.ended and arg_72_0.scrollViewMoved_ == false then
			local var_73_0 = {
				currentFriend = arg_72_1
			}

			xyd.WindowManager.get():openWindow("social_system_chat_window", var_73_0)
		end
	end)
	var_72_2:getChildByName("delete_btn"):addTouchEventListener(function(arg_74_0, arg_74_1)
		xyd.buttonScaleAnim(arg_74_0, arg_74_1)

		if arg_74_1 == ccui.TouchEventType.ended then
			local function var_74_0()
				arg_72_0.socialSystem:removeFriend(arg_72_1.player_id)
				arg_72_0:updateRightList()
			end

			local var_74_1 = {
				callback = var_74_0,
				data = arg_72_1
			}

			xyd.WindowManager.get():openWindow("sure_delete_friend", var_74_1)
		end
	end)
	var_72_2:getChildByName("compare_btn"):addTouchEventListener(function(arg_76_0, arg_76_1)
		xyd.buttonScaleAnim(arg_76_0, arg_76_1)

		if arg_76_1 == ccui.TouchEventType.ended then
			if arg_72_0.selfPlayer.lev < xyd.tables.misc.friendBattleLevel or arg_72_1.lev < xyd.tables.misc.friendBattleLevel then
				local var_76_0 = string.format(var_0_1:translation("UNDER_FRIEND_BATTLE_LEV"), xyd.tables.misc.friendBattleLevel)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_76_0
				})

				return
			end

			local var_76_1 = {
				friend_id = arg_72_1.player_id
			}

			xyd.WindowManager.get():openWindow("social_system_select_mode", var_76_1)
		end
	end)

	if arg_72_1.is_sent == true then
		var_72_2:getChildByName("send_gift_btn"):setBright(false)
		var_72_2:getChildByName("send_gift_btn"):setTouchEnabled(false)
	end

	var_72_2:getChildByName("send_gift_btn"):addTouchEventListener(function(arg_77_0, arg_77_1)
		xyd.buttonScaleAnim(arg_77_0, arg_77_1)

		if arg_77_1 == ccui.TouchEventType.ended then
			if arg_72_0.socialSystem.sendGiftCount >= xyd.tables.misc.giftSendLimit then
				local var_77_0 = var_0_1:translation("REACH_SEND_GIFT_LIMIT_TEXT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_77_0
				})

				return
			end

			local var_77_1 = {
				player_id = arg_72_1.player_id
			}

			arg_72_0.socialSystem:sendSocialGift(var_77_1, function(arg_78_0, arg_78_1)
				if arg_78_0 == xyd.error.OK then
					arg_72_0.socialSystem.sendGiftCount = arg_72_0.socialSystem.sendGiftCount + 1
					arg_72_1.is_sent = true

					if var_72_2 and not tolua.isnull(var_72_2) then
						var_72_2:getChildByName("send_gift_btn"):setBright(false)
						var_72_2:getChildByName("send_gift_btn"):setTouchEnabled(false)
					end

					local var_78_0 = string.format(var_0_1:translation("SEND_SOCIAL_GIFT_SUCCEED"), arg_72_0.invite:getInvitorName())

					xyd.WindowManager.get():openWindow("toast", {
						message = var_78_0
					})
				end
			end)
		end
	end)

	return var_72_0
end

function var_0_0.createApplyItemContent(arg_79_0, arg_79_1, arg_79_2)
	local var_79_0 = display.newNode()
	local var_79_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/manage_friend/apply_list_item.csb")
	local var_79_2 = var_79_1:getChildByName("container")
	local var_79_3 = var_79_2:getChildByName("name_bg")
	local var_79_4 = {
		avatar_id = arg_79_1.avatar_id,
		avatar_frame_id = arg_79_1.avatar_frame_id,
		playerInfo = arg_79_1
	}

	xyd.setPlayerAvatar(var_79_2:getChildByName("avtar_container"), var_79_4)
	arg_79_0.socialSystem:setNameBg(var_79_3, arg_79_1)
	var_79_1:addTo(var_79_0)
	var_79_1:setAnchorPoint(cc.p(0, 0))

	local var_79_5 = {
		size = 20,
		color = cc.c3b(93, 32, 32)
	}
	local var_79_6 = xyd.AssetLoader.get():loadLabel(var_79_5)

	var_79_6:setMaxLineWidth(274)
	var_79_6:setLineBreakWithoutSpace(true)
	var_79_6:setString(arg_79_1.request_msg)
	var_79_6:setAnchorPoint(cc.p(0, 0.5))
	var_79_6:addTo(var_79_2)
	var_79_6:setPosition(var_79_2:getChildByName("request_msg_point"):getPosition())
	var_79_0:setContentSize(var_79_2:getContentSize())
	var_79_1:setName("source")
	var_79_2:getChildByName("agree_btn"):addTouchEventListener(function(arg_80_0, arg_80_1)
		xyd.buttonScaleAnim(arg_80_0, arg_80_1)

		if arg_80_1 == ccui.TouchEventType.ended then
			if arg_79_0.socialSystem:getFriendsCount() >= xyd.tables.misc.friendNumberLimit then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("FRIEND_NUM_LIMIT_TIPS")
				})

				return
			end

			local var_80_0 = {
				player_id = arg_79_1.player_id
			}

			arg_79_0.socialSystem:acceptFriendRequest(var_80_0, function(arg_81_0, arg_81_1)
				if arg_81_0 == xyd.error.OK then
					table.remove(arg_79_0.data, arg_79_2)
					table.insert(arg_79_0.socialSystem.friendlist, arg_81_1)
					arg_79_0:updateRightList()
				end
			end)
		end
	end)
	var_79_2:getChildByName("refuse_btn"):addTouchEventListener(function(arg_82_0, arg_82_1)
		xyd.buttonScaleAnim(arg_82_0, arg_82_1)

		if arg_82_1 == ccui.TouchEventType.ended then
			local var_82_0 = {
				player_ids = {}
			}

			table.insert(var_82_0.player_ids, arg_79_1.player_id)
			arg_79_0.socialSystem:denyFriendRequest(var_82_0, function(arg_83_0, arg_83_1)
				if arg_83_0 == xyd.error.OK then
					table.remove(arg_79_0.data, arg_79_2)
					arg_79_0:updateRightList()
				end
			end)
		end
	end)
	var_79_2:getChildByName("ignore_btn"):addTouchEventListener(function(arg_84_0, arg_84_1)
		xyd.buttonScaleAnim(arg_84_0, arg_84_1)

		if arg_84_1 == ccui.TouchEventType.ended then
			local var_84_0 = {
				player_ids = {
					arg_79_1.player_id
				}
			}

			arg_79_0.socialSystem:ignoreFriendRequest(var_84_0, function(arg_85_0, arg_85_1)
				if arg_85_0 == xyd.error.OK then
					table.insert(arg_79_0.socialSystem.blacklist, arg_79_1)
					table.remove(arg_79_0.data, arg_79_2)
					arg_79_0:updateRightList()
				end
			end)
		end
	end)

	return var_79_0
end

function var_0_0.createBlackItemContent(arg_86_0, arg_86_1, arg_86_2)
	local var_86_0 = display.newNode()
	local var_86_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/blacklist_wnd/blacklist_item.csb")
	local var_86_2 = var_86_1:getChildByName("container")
	local var_86_3 = var_86_2:getChildByName("name_bg")
	local var_86_4 = {
		avatar_id = arg_86_1.avatar_id,
		avatar_frame_id = arg_86_1.avatar_frame_id,
		playerInfo = arg_86_1
	}

	xyd.setPlayerAvatar(var_86_2:getChildByName("avtar_container"), var_86_4)
	arg_86_0.socialSystem:setNameBg(var_86_3, arg_86_1)
	arg_86_0.socialSystem:setOnlineState(var_86_2:getChildByName("friend_state_txt"), arg_86_1)
	var_86_1:addTo(var_86_0)
	var_86_1:setAnchorPoint(cc.p(0, 0))
	var_86_0:setContentSize(var_86_2:getContentSize())
	var_86_1:setName("source")
	var_86_2:getChildByName("btn"):getChildByName("remove_text"):setString(var_0_1:translation("REMOVE"))
	var_86_2:getChildByName("btn"):getChildByName("set_black_text"):setVisible(false)
	var_86_2:getChildByName("btn"):addTouchEventListener(function(arg_87_0, arg_87_1)
		xyd.buttonScaleAnim(arg_87_0, arg_87_1)

		if arg_87_1 == ccui.TouchEventType.ended then
			local var_87_0 = {
				player_id = arg_86_1.player_id
			}

			arg_86_0.socialSystem:removeBlackList(var_87_0, function(arg_88_0, arg_88_1)
				if arg_88_0 == xyd.error.OK then
					table.remove(arg_86_0.socialSystem.blacklist, arg_86_2)
					arg_86_0:updateRightList()
				end
			end)
		end
	end)

	return var_86_0
end

function var_0_0.createGuildInviteItemContent(arg_89_0, arg_89_1, arg_89_2)
	local var_89_0 = display.newNode()
	local var_89_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/manage_friend/guild_invite_item.csb")
	local var_89_2 = var_89_1:getChildByName("container")
	local var_89_3 = var_89_2:getChildByName("name_bg")
	local var_89_4 = arg_89_1.player_info
	local var_89_5 = {
		avatar_id = var_89_4.avatar_id,
		avatar_frame_id = var_89_4.avatar_frame_id,
		playerInfo = var_89_4
	}

	xyd.setPlayerAvatar(var_89_2:getChildByName("avtar_container"), var_89_5)
	arg_89_0.socialSystem:setNameBg(var_89_3, var_89_4)

	local var_89_6 = xyd.createLabel(24, cc.c3b(93, 32, 32))

	var_89_6:addTo(var_89_2:getChildByName("notice_pos"))
	var_89_6:setString(var_0_1:translation("GUILD_INVITE_TEXT1"))

	local var_89_7 = var_89_6:getContentSize().width + 10
	local var_89_8 = xyd.createLabel(24, cc.c3b(255, 170, 0))

	var_89_8:addTo(var_89_2:getChildByName("notice_pos"))
	var_89_8:setString(arg_89_1.guild_name)
	var_89_8:setPositionX(var_89_7)

	local var_89_9 = var_89_7 + var_89_8:getContentSize().width + 10
	local var_89_10 = xyd.createLabel(24, cc.c3b(93, 32, 32))

	var_89_10:addTo(var_89_2:getChildByName("notice_pos"))
	var_89_10:setString(var_0_1:translation("GUILD"))
	var_89_10:setPositionX(var_89_9)
	var_89_8:setTouchEnabled(true)
	var_89_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_90_0)
		if arg_90_0.name == "began" then
			return true
		elseif arg_90_0.name == "moved" then
			return true
		elseif arg_90_0.name == "ended" then
			local var_90_0 = {
				player_id = var_89_4.player_id
			}

			arg_89_0.guild:getGuildInfo(var_90_0, function(arg_91_0, arg_91_1)
				if arg_91_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("guild_detail", arg_91_1)
				end
			end)
		end
	end)
	var_89_2:getChildByName("agree_btn"):getChildByName("agree_text"):setString(var_0_1:translation("AGREE"))
	var_89_2:getChildByName("agree_btn"):addTouchEventListener(function(arg_92_0, arg_92_1)
		xyd.buttonScaleAnim(arg_92_0, arg_92_1)

		if arg_92_1 == ccui.TouchEventType.ended then
			if arg_89_0.guild.guild_id and arg_89_0.guild.guild_id > 0 then
				arg_89_0:readNotice(arg_89_1, arg_89_2, true)

				local var_92_0 = var_0_1:translation("INVITE_GUILD_SAND_TIPS3")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_92_0
				})

				return
			end

			local var_92_1 = {
				guild_id = tonumber(arg_89_1.guild_id)
			}

			arg_89_0.guild:acceptInviteToGuild(var_92_1, function(arg_93_0, arg_93_1)
				if arg_93_0 == xyd.error.OK then
					for iter_93_0 = #arg_89_0.data, 1, -1 do
						if arg_89_0.data[iter_93_0].notice_type == xyd.FriendNoticeType.GUILD_INVITE then
							table.remove(arg_89_0.data, iter_93_0)
						end
					end

					arg_89_0:updateRightList()
					arg_89_0:updateReadNoticeBtnShow()

					local var_93_0 = string.format(var_0_1:translation("INVITE_GUILD_SAND_TIPS2"), arg_89_1.guild_name)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_93_0
					})
				end
			end)
		end
	end)
	var_89_2:getChildByName("refuse_btn"):getChildByName("refuse_text"):setString(var_0_1:translation("REFUSE"))
	var_89_2:getChildByName("refuse_btn"):addTouchEventListener(function(arg_94_0, arg_94_1)
		xyd.buttonScaleAnim(arg_94_0, arg_94_1)

		if arg_94_1 == ccui.TouchEventType.ended then
			arg_89_0:readNotice(arg_89_1, arg_89_2)
		end
	end)
	var_89_1:addTo(var_89_0)
	var_89_1:setAnchorPoint(cc.p(0, 0))
	var_89_0:setContentSize(var_89_2:getContentSize())
	var_89_1:setName("source")

	return var_89_0
end

function var_0_0.readNotice(arg_95_0, arg_95_1, arg_95_2, arg_95_3)
	local var_95_0 = {
		notice_ids = {
			arg_95_1.notice_id
		}
	}

	if arg_95_3 then
		var_95_0.notice_ids = {}

		for iter_95_0 = #arg_95_0.data, 1, -1 do
			if arg_95_0.data[iter_95_0].notice_type == xyd.FriendNoticeType.GUILD_INVITE then
				table.insert(var_95_0.notice_ids, arg_95_0.data[iter_95_0].notice_id)
			end
		end
	end

	arg_95_0.socialSystem:readNotice(var_95_0, function(arg_96_0, arg_96_1)
		if arg_96_0 == xyd.error.OK then
			table.remove(arg_95_0.data, arg_95_2)

			for iter_96_0 = #arg_95_0.socialSystem.noticelist, 1, -1 do
				if arg_95_0:isIn(arg_96_1.ids, arg_95_0.socialSystem.noticelist[iter_96_0].notice_id) then
					table.remove(arg_95_0.socialSystem.noticelist, iter_96_0)
				end
			end

			arg_95_0:updateRightList()
			arg_95_0:updateReadNoticeBtnShow()
		end
	end)
end

function var_0_0.createNoticeItemContent(arg_97_0, arg_97_1, arg_97_2)
	if arg_97_1.notice_type == xyd.FriendNoticeType.GUILD_INVITE then
		return arg_97_0:createGuildInviteItemContent(arg_97_1, arg_97_2)
	end

	local var_97_0 = display.newNode()
	local var_97_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/manage_friend/notice_msg_item.csb")
	local var_97_2 = var_97_1:getChildByName("container")
	local var_97_3 = var_97_2:getChildByName("name_bg")
	local var_97_4 = arg_97_1.player_info
	local var_97_5 = {
		avatar_id = var_97_4.avatar_id,
		avatar_frame_id = var_97_4.avatar_frame_id,
		playerInfo = var_97_4
	}

	xyd.setPlayerAvatar(var_97_2:getChildByName("avtar_container"), var_97_5)
	arg_97_0.socialSystem:setNameBg(var_97_3, var_97_4)

	if arg_97_1.notice_type == xyd.FriendNoticeType.GIFT then
		var_97_2:getChildByName("notice_txt"):setVisible(false)
		var_97_2:getChildByName("get_btn"):getChildByName("get_text"):setString(var_0_1:translation("GET"))
		var_97_2:getChildByName("notice_with_icon"):getChildByName("right_txt"):setString(var_0_1:translation("HAVE_SENDED_GIFT_TEXT") .. "]")
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.INDIEGOGO then
		var_97_2:getChildByName("notice_with_icon"):setVisible(false)
		var_97_2:getChildByName("get_btn"):getChildByName("get_text"):setString(var_0_1:translation("CHECK"))
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.ILLUSION or arg_97_1.notice_type == xyd.FriendNoticeType.OCCULT or arg_97_1.notice_type == xyd.FriendNoticeType.ADVENTURE_ILLUSION or arg_97_1.notice_type == xyd.FriendNoticeType.ADVENTURE_DEFENSE or arg_97_1.notice_type == xyd.FriendNoticeType.RAGNAROK then
		var_97_2:getChildByName("notice_with_icon"):setVisible(false)
		var_97_2:getChildByName("get_btn"):getChildByName("get_text"):setString(var_0_1:translation("JOIN"))
	else
		var_97_2:getChildByName("notice_with_icon"):setVisible(false)
		var_97_2:getChildByName("get_btn"):getChildByName("get_text"):setString(var_0_1:translation("DELETE"))
	end

	if arg_97_1.notice_type == xyd.FriendNoticeType.ACCEPT then
		var_97_2:getChildByName("notice_txt"):setString(var_0_1:translation("FRIEND_ACCEPT_TEXT"))
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.DENY then
		var_97_2:getChildByName("notice_txt"):setString(var_0_1:translation("FRIEND_DENY_TEXT"))
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.DELETE then
		var_97_2:getChildByName("notice_txt"):setString(var_0_1:translation("FRIEND_DELETE_TEXT"))
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.GIFT then
		var_97_2:getChildByName("notice_txt"):setString(var_0_1:translation("FRIEND_GIFT_TEXT"))
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.INDIEGOGO then
		local var_97_6 = xyd.tables.indiegogoTable:name(tonumber(arg_97_1.table_id))

		var_97_2:getChildByName("notice_txt"):setString(var_0_1:translation("INDIEGOGO_INVITE") .. var_97_6)
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.ILLUSION then
		local var_97_7 = xyd.tables.illusionCampaign:name(tonumber(arg_97_1.paradise_id))
		local var_97_8 = arg_97_1.player_info.lev
		local var_97_9 = string.format(var_0_1:translation("ILLUSION_TEAM_TIPS_11"), var_97_7, var_97_8)

		var_97_2:getChildByName("notice_txt"):setString(var_97_9)
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.OCCULT then
		local var_97_10 = xyd.tables.creatsChapterSelect:chapterName(tonumber(arg_97_1.chapter_id))
		local var_97_11 = string.format(var_0_1:translation("CREATS_TIPS_13"), var_97_10, arg_97_1.force or 0)

		var_97_2:getChildByName("notice_txt"):setString(var_97_11)
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.ADVENTURE_ILLUSION then
		local var_97_12 = xyd.tables.illusionCampaign:name(tonumber(xyd.tables.misc.adventureIllusionBoss))
		local var_97_13 = arg_97_1.player_info.lev
		local var_97_14 = string.format(var_0_1:translation("ADVENTURE_PARADISE_TEAM_TIP"), var_97_12, var_97_13)

		var_97_2:getChildByName("notice_txt"):setString(var_97_14)
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.ADVENTURE_DEFENSE then
		local var_97_15 = arg_97_1.player_info.lev
		local var_97_16 = string.format(var_0_1:translation("ADVENTURE_MONSTER_TEAM_TIP"), var_97_15)

		var_97_2:getChildByName("notice_txt"):setString(var_97_16)
	elseif arg_97_1.notice_type == xyd.FriendNoticeType.RAGNAROK then
		local var_97_17 = var_0_1:translation("RAGNAROK_BOSS_1")
		local var_97_18 = arg_97_1.player_info.lev
		local var_97_19 = string.format(var_0_1:translation("RAGNAROK_BOSS_TEAM_24"), var_97_17, var_97_18)

		var_97_2:getChildByName("notice_txt"):setString(var_97_19)
	end

	var_97_2:getChildByName("get_btn"):addTouchEventListener(function(arg_98_0, arg_98_1)
		xyd.buttonScaleAnim(arg_98_0, arg_98_1)

		if arg_98_1 == ccui.TouchEventType.ended then
			if arg_97_1.notice_type == xyd.FriendNoticeType.GIFT and arg_97_0.socialSystem.receiveGiftCount >= xyd.tables.misc.giftGetLimit then
				local var_98_0 = var_0_1:translation("REACH_RECEIVE_GIFT_LIMIT_TEXT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_98_0
				})

				return
			end

			local var_98_1 = {
				notice_ids = {
					arg_97_1.notice_id
				}
			}

			arg_97_0.socialSystem:readNotice(var_98_1, function(arg_99_0, arg_99_1)
				if arg_99_0 == xyd.error.OK then
					if arg_99_1 and arg_99_1.awards then
						arg_97_0.selfPlayer:handleRewards(arg_99_1.awards)
					end

					if arg_97_1.notice_type == xyd.FriendNoticeType.GIFT then
						arg_97_0.socialSystem.receiveGiftCount = arg_97_0.socialSystem.receiveGiftCount + 1
					end

					table.remove(arg_97_0.data, arg_97_2)
					arg_97_0:updateRightList()
					arg_97_0:updateReadNoticeBtnShow()

					if arg_97_1.notice_type == xyd.FriendNoticeType.INDIEGOGO then
						arg_97_0:checkFundInfoIsExit(arg_97_1.fund_id)
					elseif arg_97_1.notice_type == xyd.FriendNoticeType.ILLUSION then
						arg_97_0:clickIllusionItem(arg_97_1)
					elseif arg_97_1.notice_type == xyd.FriendNoticeType.OCCULT then
						arg_97_0:clickOccultItem(arg_97_1)
					elseif arg_97_1.notice_type == xyd.FriendNoticeType.ADVENTURE_ILLUSION then
						arg_97_0:clickAdventureIllusionItem(arg_97_1)
					elseif arg_97_1.notice_type == xyd.FriendNoticeType.ADVENTURE_DEFENSE then
						arg_97_0:clickAdventureDefenseItem(arg_97_1)
					elseif arg_97_1.notice_type == xyd.FriendNoticeType.RAGNAROK then
						arg_97_0:clickRagnarokItem(arg_97_1)
					end
				end
			end)
		end
	end)
	var_97_1:addTo(var_97_0)
	var_97_1:setAnchorPoint(cc.p(0, 0))
	var_97_0:setContentSize(var_97_2:getContentSize())
	var_97_1:setName("source")

	return var_97_0
end

function var_0_0.recallListDelegate(arg_100_0, arg_100_1, arg_100_2, arg_100_3)
	if cc.ui.UIListView.COUNT_TAG == arg_100_2 then
		if arg_100_0.recallState ~= var_0_7.RecallAward then
			return #arg_100_0.recallData
		else
			return #arg_100_0.recallData.canAward + #arg_100_0.recallData.cannotAward + #arg_100_0.recallData.awarded
		end
	elseif cc.ui.UIListView.CELL_TAG == arg_100_2 then
		local var_100_0 = arg_100_0.recallList:dequeueItem()

		if not var_100_0 then
			var_100_0 = arg_100_0.recallList:newItem()
		else
			var_100_0:removeAllChildren(true)
		end

		local var_100_1

		if arg_100_0.recallState ~= var_0_7.RecallAward then
			var_100_1 = arg_100_0:createFriendRecallContent(arg_100_3)
		else
			var_100_1 = arg_100_0:createRecallAwardContent(arg_100_3)
		end

		local var_100_2 = var_100_1:getWidth()
		local var_100_3 = var_100_1:getHeight()

		var_100_0:setItemSize(var_100_2, var_100_3)
		var_100_0:addContent(var_100_1)

		return var_100_0
	end
end

function var_0_0.createRecallAwardContent(arg_101_0, arg_101_1)
	local var_101_0 = display.newNode()
	local var_101_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/friend_recall/recall_award_item.csb")
	local var_101_2 = var_101_1:getChildByName("container")

	var_101_2:getChildByName("process_txt"):setVisible(false)
	var_101_2:getChildByName("reach_goal_text"):setVisible(false)
	var_101_2:getChildByName("has_gotten_text"):setVisible(false)

	local var_101_3

	if arg_101_1 <= #arg_101_0.recallData.canAward then
		var_101_2:getChildByName("item_bg2"):setVisible(false)

		var_101_3 = arg_101_0.recallData.canAward[arg_101_1]
		var_101_3 = tonumber(var_101_3)

		var_101_2:getChildByName("reach_goal_text"):setVisible(true)
		var_101_1:setTouchEnabled(true)
		var_101_1:setTouchSwallowEnabled(false)
		var_101_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_102_0)
			if arg_102_0.name == "began" then
				return true
			elseif arg_102_0.name == "moved" then
				return true
			elseif arg_102_0.name == "ended" and not arg_101_0.scrollViewMoved_ then
				local var_102_0 = {
					award_id = var_101_3
				}

				arg_101_0.socialSystem:getRecallAward(var_102_0, function(arg_103_0, arg_103_1)
					if arg_103_0 == xyd.error.OK then
						if arg_103_1 and arg_103_1.awards then
							arg_101_0.selfPlayer:handleRewards(arg_103_1.awards)
						end

						if arg_101_0 and not tolua.isnull(arg_101_0) then
							arg_101_0:updateFriendRecallList()
						end
					end
				end)
			end
		end)
	elseif arg_101_1 <= #arg_101_0.recallData.canAward + #arg_101_0.recallData.cannotAward then
		local var_101_4, var_101_5, var_101_6 = arg_101_0.socialSystem:summaryDoneFriendsInfo()

		var_101_3 = arg_101_0.recallData.cannotAward[arg_101_1 - #arg_101_0.recallData.canAward]
		var_101_3 = tonumber(var_101_3)

		var_101_2:getChildByName("process_txt"):setVisible(true)

		local var_101_7

		if xyd.tables.friendRecall:type(var_101_3) == 1 then
			var_101_7 = arg_101_0.socialSystem:getRecallFriendNum()
		elseif xyd.tables.friendRecall:type(var_101_3) == 2 then
			var_101_7 = var_101_4
		elseif xyd.tables.friendRecall:type(var_101_3) == 3 then
			var_101_7 = var_101_6
		elseif xyd.tables.friendRecall:type(var_101_3) == 4 then
			var_101_7 = var_101_5
		end

		var_101_2:getChildByName("process_txt"):setString(var_101_7 .. "/" .. xyd.tables.friendRecall:condition(var_101_3))
	else
		var_101_3 = arg_101_0.recallData.awarded[arg_101_1 - #arg_101_0.recallData.canAward - #arg_101_0.recallData.cannotAward]
		var_101_3 = tonumber(var_101_3)

		var_101_2:getChildByName("has_gotten_text"):setVisible(true)
	end

	var_101_2:getChildByName("item_title"):setString(xyd.tables.friendRecall:desc(var_101_3))

	local var_101_8 = xyd.tables.friendRecall:gift(var_101_3)
	local var_101_9 = xyd.tables.gift:items(var_101_8)
	local var_101_10 = xyd.tables.gift:itemNum(var_101_8)

	var_101_2:getChildByName("reward_pos"):getChildByName("award_num"):setString("x" .. xyd.tables.gift:crystal(var_101_8))

	if #var_101_9 > 0 and var_101_9[1] ~= 0 then
		for iter_101_0 = 1, #var_101_9 do
			local var_101_11 = var_101_2:getChildByName("reward_pos"):getChildByName("award_num")
			local var_101_12 = var_101_11:getPositionX() + var_101_11:getContentSize().width + 5
			local var_101_13 = arg_101_0:createRewardContent(var_101_9[iter_101_0], var_101_10[iter_101_0])

			var_101_13:setAnchorPoint(cc.p(0, 0))
			var_101_13:addTo(var_101_2:getChildByName("reward_pos"))
			var_101_13:setPosition(var_101_12 + var_101_13:getContentSize().width * (iter_101_0 - 1), 2)
		end
	end

	var_101_1:addTo(var_101_0)
	var_101_1:setAnchorPoint(cc.p(0, 0))
	var_101_0:setContentSize(var_101_2:getContentSize())
	var_101_1:setName("source")

	return var_101_0
end

function var_0_0.createFriendRecallContent(arg_104_0, arg_104_1)
	local var_104_0 = arg_104_0.recallData[arg_104_1]
	local var_104_1 = display.newNode()
	local var_104_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/friend_recall/recall_mission_item.csb")
	local var_104_3 = var_104_2:getChildByName("container")

	if var_104_0.player_name then
		var_104_3:getChildByName("item_title"):setString(string.format(var_0_1:translation("FRIEND_RECALL_TASK"), var_104_0.player_name))

		if var_104_0.player_id then
			var_104_3:getChildByName("region_txt"):setString("S" .. xyd.getPlayerRegion(var_104_0.player_id))
		elseif var_104_0.friend_id then
			var_104_3:getChildByName("region_txt"):setString("S" .. xyd.getPlayerRegion(var_104_0.friend_id))
		end
	end

	var_104_3:getChildByName("get_btn"):setVisible(false)
	var_104_3:getChildByName("on_doing_text"):setVisible(false)
	var_104_3:getChildByName("has_reached_text"):setVisible(false)

	if arg_104_0.recallState == var_0_7.GetMission then
		var_104_3:getChildByName("get_btn"):setVisible(true)
		var_104_3:getChildByName("bottom_desc_txt"):setString(var_0_1:translation("FRIEND_RECALL_TIP_4"))
		var_104_3:getChildByName("get_btn"):addTouchEventListener(function(arg_105_0, arg_105_1)
			xyd.buttonScaleAnim(arg_105_0, arg_105_1)

			if arg_105_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if #arg_104_0.socialSystem.socialSystemInfo.doing_recall >= xyd.tables.misc.friendRecallTaskLimit then
					local var_105_0 = string.format(var_0_1:translation("FRIEND_RECALL_LIMIT"), xyd.tables.misc.friendRecallTaskLimit)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_105_0
					})

					return
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(xyd.tables.translation:translation("FRIEND_RECALL_TIP_3")), function()
					local var_106_0 = {
						friend_id = var_104_0.player_id
					}

					arg_104_0.socialSystem:recallFriend(var_106_0, function(arg_107_0, arg_107_1)
						if arg_107_0 == xyd.error.OK and arg_104_0 and not tolua.isnull(arg_104_0) then
							arg_104_0:updateFriendRecallList()
						end
					end)
				end, nil, nil, arg_104_0.colorMode)
			end
		end)
	elseif arg_104_0.recallState == var_0_7.OnDoingMission then
		var_104_3:getChildByName("on_doing_text"):setVisible(true)

		local var_104_4 = xyd.tables.misc.friendRecallTaskDays * 24 * 3600 - (xyd.ServerTime.get():getServerTime() - var_104_0.recalling_time)
		local var_104_5 = xyd.secondsToString(var_104_4)
		local var_104_6 = string.format(var_0_1:translation("ACTIVITY_FUSION_LEFT_TIME"), var_104_5)

		var_104_3:getChildByName("bottom_desc_txt"):setString(var_104_6)
	elseif arg_104_0.recallState == var_0_7.DoneMission then
		var_104_3:getChildByName("item_bg2"):setVisible(false)
		var_104_3:getChildByName("has_reached_text"):setVisible(true)
		var_104_3:getChildByName("bottom_desc_txt"):setString(var_0_1:translation("FRIEND_RECALL_TIP_5"))
	end

	var_104_2:addTo(var_104_1)
	var_104_2:setAnchorPoint(cc.p(0, 0))
	var_104_1:setContentSize(var_104_3:getContentSize())
	var_104_2:setName("source")

	return var_104_1
end

function var_0_0.updateFriendRecallList(arg_108_0)
	arg_108_0:initRecallData()
	arg_108_0:updateRedMark()
	arg_108_0.recallList:reload()
end

function var_0_0.createRewardContent(arg_109_0, arg_109_1, arg_109_2)
	local var_109_0 = display.newNode()
	local var_109_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/friend_recall/reward_item.csb")
	local var_109_2 = var_109_1:getChildByName("container")

	var_109_2:getChildByName("icon_container"):setTouchSwallowEnabled(true)
	xyd.setItemAndAddTips(var_109_2:getChildByName("icon_container"), arg_109_1)
	var_109_2:getChildByName("item_num_txt"):setString(arg_109_2)
	var_109_1:addTo(var_109_0)
	var_109_1:setAnchorPoint(cc.p(0, 0))
	var_109_1:setPosition(0, 0)
	var_109_0:setContentSize(var_109_2:getContentSize())
	var_109_1:setName("source")

	return var_109_0
end

function var_0_0.listViewDelegate(arg_110_0, arg_110_1, arg_110_2, arg_110_3)
	if cc.ui.UIListView.COUNT_TAG == arg_110_2 then
		return #arg_110_0.list
	elseif cc.ui.UIListView.CELL_TAG == arg_110_2 then
		local var_110_0 = arg_110_0.listView:dequeueItem()

		if not var_110_0 then
			var_110_0 = arg_110_0.listView:newItem()
		else
			var_110_0:removeAllChildren(true)
		end

		local var_110_1

		if arg_110_0.inviteState == var_0_6.Mission then
			var_110_1 = arg_110_0:createMissionContent(arg_110_3)
		elseif arg_110_0.inviteState == var_0_6.HasInvited then
			var_110_1 = arg_110_0:createInvitedContent(arg_110_3)
		end

		local var_110_2 = var_110_1:getWidth()
		local var_110_3 = var_110_1:getHeight()

		var_110_0:setItemSize(var_110_2, var_110_3)
		var_110_0:addContent(var_110_1)

		return var_110_0
	end
end

function var_0_0.createMissionContent(arg_111_0, arg_111_1)
	local var_111_0 = display.newNode()
	local var_111_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/invite_friends/invite_mission_item.csb")
	local var_111_2 = var_111_1:getChildByName("container")

	var_111_2:getChildByName("reward_txt"):setString(var_0_1:translation("REWARD") .. var_0_1:translation("COLON"))
	var_111_2:getChildByName("item_title"):setString(xyd.tables.inviteMission:desc(arg_111_0.list[arg_111_1].mission_id))

	if arg_111_0.list[arg_111_1].can_award then
		var_111_2:getChildByName("item_doing"):setVisible(false)
		var_111_2:getChildByName("item_done"):setVisible(true)
		var_111_2:getChildByName("get_goal"):setVisible(true)
	else
		var_111_2:getChildByName("item_doing"):setVisible(true)
		var_111_2:getChildByName("item_done"):setVisible(false)
		var_111_2:getChildByName("get_goal"):setVisible(false)
	end

	local var_111_3 = xyd.tables.inviteMission:condition(arg_111_0.list[arg_111_1].mission_id)
	local var_111_4 = arg_111_0:getMissionProgress(arg_111_0.list[arg_111_1].mission_id)

	var_111_2:getChildByName("process_txt"):setString(tostring(var_111_4) .. "/" .. tostring(var_111_3[1]))
	var_111_2:getChildByName("award_num"):setString("X" .. tostring(xyd.tables.inviteMission:diamond(arg_111_0.list[arg_111_1].mission_id)))
	var_111_1:setTouchEnabled(true)
	var_111_1:setTouchSwallowEnabled(false)
	var_111_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_112_0)
		if arg_112_0.name == "began" then
			return true
		elseif arg_112_0.name == "moved" then
			return true
		elseif arg_112_0.name == "ended" and not arg_111_0.scrollViewMoved_ then
			if arg_111_0.list[arg_111_1].can_award then
				local var_112_0 = {
					mission_id = arg_111_0.list[arg_111_1].mission_id
				}

				arg_111_0.invite:getMissionReward(var_112_0, function(arg_113_0, arg_113_1)
					if arg_113_0 == xyd.error.OK then
						local var_113_0 = arg_113_1.awards
						local var_113_1 = arg_113_1.new_missions

						xyd.WindowManager.get():openWindow("alert_award", {
							awards = var_113_0
						})

						arg_111_0.list = arg_111_0:resortMissionList(arg_111_0.invite:getInviteMissions())

						local var_113_2 = xyd.tables.inviteMission:condition(arg_111_0.list[arg_111_1].mission_id)
						local var_113_3 = arg_111_0:getMissionProgress(arg_111_0.list[arg_111_1].mission_id)

						if var_111_2 and not tolua.isnull(var_111_2) then
							var_111_2:getChildByName("process_txt"):setString(tostring(var_113_3) .. "/" .. tostring(var_113_2[1]))
							var_111_2:getChildByName("award_num"):setString("X" .. tostring(xyd.tables.inviteMission:diamond(arg_111_0.list[arg_111_1].mission_id)))
						end

						arg_111_0.listView:reload()
					end
				end)
			else
				local var_112_1 = var_0_1:translation("MISSION_NOT_COMPLETE")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_112_1
				})
			end
		end
	end)
	var_111_1:addTo(var_111_0)
	var_111_1:setAnchorPoint(cc.p(0, 0))
	var_111_0:setContentSize(var_111_2:getContentSize())
	var_111_1:setName("source")

	return var_111_0
end

function var_0_0.createInvitedContent(arg_114_0, arg_114_1)
	local var_114_0 = display.newNode()
	local var_114_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/invite_friends/invite_friends_item.csb")
	local var_114_2 = var_114_1:getChildByName("container")

	var_114_2:getChildByName("has_charge_txt"):setString(var_0_1:translation("ALREADY_CHARGE"))
	var_114_2:getChildByName("player_name"):setString(arg_114_0.list[arg_114_1].player_name)
	var_114_2:getChildByName("sever_name"):setString(arg_114_0.list[arg_114_1].region_name)
	var_114_2:getChildByName("charged_num"):setString(arg_114_0.list[arg_114_1].charge)
	xyd.setAvatarClip(var_114_2:getChildByName("avatar_container"), arg_114_0.list[arg_114_1].avatar_id, 1)
	var_114_1:addTo(var_114_0)
	var_114_1:setAnchorPoint(cc.p(0, 0))
	var_114_0:setContentSize(var_114_2:getContentSize())
	var_114_1:setName("source")

	return var_114_0
end

function var_0_0.updateAvatar(arg_115_0, arg_115_1, arg_115_2)
	arg_115_1:getChildByName("avatar_kuang"):setLocalZOrder(1)
	xyd.setAvatarClip(arg_115_1:getChildByName("avatar_container"), arg_115_2, 1)
end

function var_0_0.getMissionProgress(arg_116_0, arg_116_1)
	local var_116_0 = xyd.tables.inviteMission:condition(arg_116_1)
	local var_116_1 = xyd.tables.inviteMission:type(arg_116_1)
	local var_116_2 = arg_116_0.invite:getInviteFriends()
	local var_116_3 = 0

	for iter_116_0, iter_116_1 in ipairs(var_116_2) do
		if var_116_1 == var_0_5.PLAYER_NUM then
			var_116_3 = var_116_3 + 1
		elseif var_116_1 == var_0_5.HERO_NUM then
			if iter_116_1.partner_num >= var_116_0[#var_116_0] then
				var_116_3 = var_116_3 + 1
			end
		elseif var_116_1 == var_0_5.LEVEL then
			if iter_116_1.lev >= var_116_0[#var_116_0] then
				var_116_3 = var_116_3 + 1
			end
		elseif var_116_1 == var_0_5.CHARGE_NUM and iter_116_1.charge >= var_116_0[#var_116_0] then
			var_116_3 = var_116_3 + 1
		end
	end

	return var_116_3
end

function var_0_0.scrollListener(arg_117_0, arg_117_1)
	if arg_117_1.name == "began" then
		arg_117_0.scrollViewMoved_ = false
		arg_117_0.prevY_ = arg_117_1.y
	elseif arg_117_1.name == "moved" and 10 <= math.abs(arg_117_1.y - arg_117_0.prevY_) then
		arg_117_0.scrollViewMoved_ = true
	end
end

function var_0_0.didClose(arg_118_0, arg_118_1)
	arg_118_0.socialSystem:refreshRedMark()
	arg_118_0.socialSystem:refreshNoticeCount()
end

function var_0_0.willClose(arg_119_0, arg_119_1)
	if xyd.WindowManager.get():getWindow("indiegogo") then
		xyd.WindowManager.get():closeWindow("indiegogo")
	end

	if xyd.WindowManager.get():getWindow("teacher") then
		xyd.WindowManager.get():closeWindow("teacher")
	end
end

function var_0_0.initTopBtn(arg_120_0)
	arg_120_0:nodeByName("red_point_friend"):setVisible(false)
	arg_120_0:nodeByName("btn_friend"):addTouchEventListener(function(arg_121_0, arg_121_1)
		if arg_121_1 == ccui.TouchEventType.ended and arg_120_0.topMenuType ~= var_0_8.FRIEND then
			arg_120_0:gotoFriend()
		end
	end)
	arg_120_0:nodeByName("btn_indiegogo"):addTouchEventListener(function(arg_122_0, arg_122_1)
		if arg_122_1 == ccui.TouchEventType.ended and arg_120_0.topMenuType ~= var_0_8.INDIEGOGO then
			if arg_120_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_INDIEGOGO) then
				arg_120_0:gotoIndiegogo()
			else
				local var_122_0 = var_0_1:translation("FUNCTION_OPEN_TIP_OTHER")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_122_0
				})
			end
		end
	end)
	arg_120_0:nodeByName("red_point_teacher"):setVisible(false)
	arg_120_0:nodeByName("btn_teacher"):addTouchEventListener(function(arg_123_0, arg_123_1)
		if arg_123_1 == ccui.TouchEventType.ended and arg_120_0.topMenuType ~= var_0_8.TEACHER then
			if arg_120_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_MY_CLASS) then
				local var_123_0 = arg_120_0.teacherState

				arg_120_0:gotoTeacher(var_123_0)
			else
				local var_123_1 = var_0_1:translation("TEACHER_OPEN_TIPS")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_123_1
				})
			end
		end
	end)
	arg_120_0:updateTopBtnType(var_0_8.FRIEND)
end

function var_0_0.initText(arg_124_0)
	arg_124_0:nodeByName("title"):setString(var_0_1:translation("ADDRESS_BOOS"))
	arg_124_0:nodeByName("teacher_txt"):setString(var_0_1:translation("MY_CLASS_OPEN"))
	arg_124_0:nodeByName("indiegogo_txt"):setString(var_0_1:translation("INDIEGOGO_OPEN"))
	arg_124_0:nodeByName("friend_txt"):setString(var_0_1:translation("MY_FRIEND"))
	arg_124_0:nodeByName("get_recall_text"):setString(var_0_1:translation("RECALL_TEXT_1"))
	arg_124_0:nodeByName("doing_recall_text"):setString(var_0_1:translation("RECALL_TEXT_2"))
	arg_124_0:nodeByName("recall_award_text"):setString(var_0_1:translation("RECALL_TEXT_3"))
	arg_124_0:nodeByName("done_recall_text"):setString(var_0_1:translation("RECALL_TEXT_4"))
	arg_124_0:nodeByName("input_code_text"):setString(var_0_1:translation("INVITE_TEXT_1"))
	arg_124_0:nodeByName("invite_text"):setString(var_0_1:translation("INVITE_TEXT_2"))
	arg_124_0:nodeByName("has_invited_text"):setString(var_0_1:translation("INVITE_TEXT_3"))
	arg_124_0:nodeByName("black_add_text"):setString(var_0_1:translation("ADD"))
	arg_124_0:nodeByName("black_clear_text"):setString(var_0_1:translation("CLEAR"))
	arg_124_0:nodeByName("one_key_get_all_text"):setString(var_0_1:translation("ONE_KEY_GET"))
	arg_124_0:nodeByName("one_key_delete_all_text"):setString(var_0_1:translation("ONE_KEY_DELETE"))
	arg_124_0:nodeByName("ignore_all_text"):setString(var_0_1:translation("IGNORE_ALL"))
	arg_124_0:nodeByName("refuse_all_text"):setString(var_0_1:translation("SOCIAL_SYSTEM_TEXT_8"))
	arg_124_0:nodeByName("add_friend_text"):setString(var_0_1:translation("ADD_FRIEND"))
	arg_124_0:nodeByName("myfriend_text"):setString(var_0_1:translation("SOCIAL_SYSTEM_TEXT_1"))
	arg_124_0:nodeByName("apply_list_text"):setString(var_0_1:translation("SOCIAL_SYSTEM_TEXT_2"))
	arg_124_0:nodeByName("notice_text"):setString(var_0_1:translation("SOCIAL_SYSTEM_TEXT_3"))
	arg_124_0:nodeByName("blacklist_text"):setString(var_0_1:translation("SOCIAL_SYSTEM_TEXT_4"))
	arg_124_0:nodeByName("invite_friend_text"):setString(var_0_1:translation("SOCIAL_SYSTEM_TEXT_5"))
	arg_124_0:nodeByName("friend_recall_text"):setString(var_0_1:translation("SOCIAL_SYSTEM_TEXT_6"))
	arg_124_0:nodeByName("friendship_exchange_text"):setString(var_0_1:translation("SOCIAL_SYSTEM_TEXT_7"))
end

function var_0_0.updateTopBtnType(arg_125_0, arg_125_1)
	arg_125_0.topMenuType = arg_125_1

	arg_125_0:nodeByName("btn_friend"):setBrightStyle(ccui.BrightStyle.normal)
	arg_125_0:nodeByName("btn_friend"):setTouchEnabled(true)
	arg_125_0:nodeByName("btn_indiegogo"):setBrightStyle(ccui.BrightStyle.normal)
	arg_125_0:nodeByName("btn_indiegogo"):setTouchEnabled(true)
	arg_125_0:nodeByName("btn_teacher"):setBrightStyle(ccui.BrightStyle.normal)
	arg_125_0:nodeByName("btn_teacher"):setTouchEnabled(true)

	if arg_125_1 == var_0_8.FRIEND then
		arg_125_0:nodeByName("btn_friend"):setTouchEnabled(false)
		arg_125_0:nodeByName("btn_friend"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_125_1 == var_0_8.INDIEGOGO then
		arg_125_0:nodeByName("btn_indiegogo"):setTouchEnabled(false)
		arg_125_0:nodeByName("btn_indiegogo"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_125_1 == var_0_8.TEACHER then
		arg_125_0:nodeByName("btn_teacher"):setTouchEnabled(false)
		arg_125_0:nodeByName("btn_teacher"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.gotoIndiegogo(arg_126_0, arg_126_1, arg_126_2)
	arg_126_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.INDIEGOGO)
	arg_126_0.socialSystem:loadFundingInfo({}, function(arg_127_0, arg_127_1)
		if arg_127_0 == xyd.error.OK then
			local var_127_0 = arg_127_1

			var_127_0.isGotoCheck = arg_126_1
			var_127_0.fundID = arg_126_2

			xyd.playButtonSound()
			arg_126_0:hideSocialSystem(false)
			arg_126_0:updateTopBtnType(var_0_8.INDIEGOGO)

			if xyd.WindowManager.get():getWindow("teacher") then
				xyd.WindowManager.get():closeWindow("teacher")
			end

			xyd.WindowManager.get():openWindow("indiegogo", var_127_0)
		end
	end)
end

function var_0_0.gotoFriend(arg_128_0)
	xyd.playButtonSound()

	if xyd.WindowManager.get():getWindow("indiegogo") then
		xyd.WindowManager.get():closeWindow("indiegogo")
	end

	if xyd.WindowManager.get():getWindow("teacher") then
		xyd.WindowManager.get():closeWindow("teacher")
	end

	arg_128_0:hideSocialSystem(true)
	arg_128_0:updateTopBtnType(var_0_8.FRIEND)
	arg_128_0:swapWindowState(arg_128_0.windowState)
end

function var_0_0.gotoTeacher(arg_129_0, arg_129_1)
	local function var_129_0()
		local var_130_0 = {}

		if arg_129_1 then
			var_130_0.functionId = arg_129_1
		end

		xyd.WindowManager.get():openWindow("teacher", var_130_0)

		if xyd.WindowManager.get():getWindow("indiegogo") then
			xyd.WindowManager.get():closeWindow("indiegogo")
		end

		if arg_129_0 and not tolua.isnull(arg_129_0) then
			arg_129_0:hideSocialSystem(false)
			arg_129_0:updateTopBtnType(var_0_8.TEACHER)
		end
	end

	if arg_129_0.inTeacher then
		var_129_0()
	elseif arg_129_0.hasRefreshClass then
		var_129_0()
	else
		arg_129_0.socialSystem:getClassInfo(function(arg_131_0, arg_131_1)
			if arg_131_0 == xyd.error.OK then
				xyd.playButtonSound()

				arg_129_0.hasRefreshClass = true

				var_129_0()
			end
		end)
	end
end

function var_0_0.hideSocialSystem(arg_132_0, arg_132_1)
	for iter_132_0 = 1, var_0_3 - 1 do
		arg_132_0:nodeByName("subBtn" .. iter_132_0):setVisible(arg_132_1)
	end

	for iter_132_1 = 1, var_0_3 do
		arg_132_0:nodeByName("bottom" .. iter_132_1):setVisible(arg_132_1)
	end

	arg_132_0.rightUpperList:setVisible(arg_132_1)
	arg_132_0:nodeByName("NPC"):setVisible(arg_132_1)
	arg_132_0:nodeByName("bottom_bg"):setVisible(arg_132_1)
end

function var_0_0.checkFundInfoIsExit(arg_133_0, arg_133_1)
	local var_133_0 = {
		fund_id = arg_133_1
	}

	arg_133_0.socialSystem:getInfoByID(var_133_0, function(arg_134_0, arg_134_1)
		if arg_134_0 == xyd.error.OK then
			arg_133_0:gotoIndiegogo(true, arg_133_1)
		else
			local var_134_0 = var_0_1:translation("INDIEGOGO_HAVE_OVER")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_134_0
			})
		end
	end)
end

function var_0_0.clickIllusionItem(arg_135_0, arg_135_1)
	if arg_135_1.notice_type == xyd.FriendNoticeType.ILLUSION then
		if arg_135_1.room_id then
			local var_135_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)

			if var_135_0:checkCanJoinRoom(arg_135_1.room_id) then
				var_135_0:enterRoom(arg_135_1.room_id, function(arg_136_0, arg_136_1)
					if arg_136_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("illusion_prepare")
						xyd.WindowManager.get():closeWindow(arg_135_0)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ILLUSION_TEAM_TIPS_10")
						})
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
				})
			end
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("ILLUSION_TEAM_TIPS_10")
			})
		end
	end
end

function var_0_0.clickAdventureDefenseItem(arg_137_0, arg_137_1)
	if arg_137_1.notice_type == xyd.FriendNoticeType.ADVENTURE_DEFENSE then
		if arg_137_1.room_id then
			local var_137_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

			if var_137_0:checkCanJoinDefenseRoom(arg_137_1.room_id) then
				var_137_0:joinDefenseRoom({
					room_id = tonumber(arg_137_1.room_id),
					table_id = xyd.AdventureEventType.DEFENSE
				}, function(arg_138_0, arg_138_1)
					local var_138_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

					if arg_138_0 == xyd.error.OK and var_138_0.teamDefenseInfo and var_138_0.teamDefenseInfo.room_info then
						xyd.WindowManager.get():openWindow("adventure_defense", {
							table_id = xyd.AdventureEventType.DEFENSE
						})
						xyd.WindowManager.get():closeWindow(arg_137_0)
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
				})
			end
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("ILLUSION_TEAM_TIPS_10")
			})
		end
	end
end

function var_0_0.clickRagnarokItem(arg_139_0, arg_139_1)
	if arg_139_1.notice_type == xyd.FriendNoticeType.RAGNAROK then
		if arg_139_1.room_id then
			local var_139_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)

			if not var_139_0:checkTicket() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("RAGNAROK_BOSS_TEAM_26")
				})

				return
			end

			if var_139_0:checkCanJoinRoom(arg_139_1.room_id) then
				var_139_0:enterRoom(arg_139_1.room_id, 0, function(arg_140_0, arg_140_1)
					local var_140_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)

					if arg_140_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("ragnarok_prepare")
						xyd.WindowManager.get():closeWindow(arg_139_0)
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("RAGNAROK_BOSS_TEAM_5")
				})
			end
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("RAGNAROK_BOSS_TEAM_27")
			})
		end
	end
end

function var_0_0.clickAdventureIllusionItem(arg_141_0, arg_141_1)
	if arg_141_1.notice_type == xyd.FriendNoticeType.ADVENTURE_ILLUSION then
		if arg_141_1.room_id then
			local var_141_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

			if var_141_0:checkCanJoinRoom(arg_141_1.room_id) then
				var_141_0:joinRoom({
					room_id = tonumber(arg_141_1.room_id),
					table_id = xyd.AdventureEventType.ILLUSION
				}, function(arg_142_0, arg_142_1)
					if arg_142_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("adventure_illusion_prepare", {
							table_id = xyd.AdventureEventType.ILLUSION
						})
						xyd.WindowManager.get():closeWindow(arg_141_0)
					elseif arg_142_1.error_code and arg_142_1.error_code == 35029 then
						local var_142_0 = xyd.tables.message:getContent(arg_142_1.error_code)

						if var_142_0 and var_142_0 ~= "" then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_142_0
							})
						end
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ILLUSION_TEAM_TIPS_10")
						})
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
				})
			end
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("ILLUSION_TEAM_TIPS_10")
			})
		end
	end
end

function var_0_0.clickOccultItem(arg_143_0, arg_143_1)
	if arg_143_0.occult:checkCanJoinRoom(arg_143_1.room_id) then
		local var_143_0 = {
			room_id = tonumber(arg_143_1.room_id)
		}

		arg_143_0.occult:joinRoom(var_143_0, function(arg_144_0, arg_144_1)
			if arg_144_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("occult_prepare")
				xyd.WindowManager.get():closeWindow(arg_143_0)
			end
		end)
	else
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
		})
	end
end

return var_0_0
