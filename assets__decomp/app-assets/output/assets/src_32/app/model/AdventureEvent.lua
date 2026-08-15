local var_0_0 = class("AdventureEvent", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.adventureEvent
local var_0_3 = 1000

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.adventureEventInfo = {}
	arg_1_0.invitedList = {}
	arg_1_0.invitedDefenseList = {}
	arg_1_0.teamInfo = {}
	arg_1_0.teamDefenseInfo = {}
	arg_1_0.teamStatus = {}
	arg_1_0.roomMap = {}
	arg_1_0.startEarliestTime = -1
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.initAdventureEventInfos(arg_3_0, arg_3_1)
	local var_3_0 = var_0_2:getEventTableIds()
	local var_3_1 = {}
	local var_3_2 = {}

	for iter_3_0, iter_3_1 in pairs(var_3_0) do
		if arg_3_1.adventure_list and arg_3_1.adventure_list.list and arg_3_1.adventure_list.list[iter_3_1] then
			table.insert(arg_3_0.adventureEventInfo, {
				id = iter_3_1,
				event_info = arg_3_1.adventure_list.list[iter_3_1]
			})
		else
			table.insert(arg_3_0.adventureEventInfo, {
				id = iter_3_1,
				event_info = {}
			})
		end
	end

	arg_3_0:sortEvent()
end

function var_0_0.sortEvent(arg_4_0)
	table.sort(arg_4_0.adventureEventInfo, function(arg_5_0, arg_5_1)
		if arg_5_0.event_info.end_time and not arg_5_1.event_info.end_time then
			return true
		end

		if arg_5_1.event_info.end_time and not arg_5_0.event_info.end_time then
			return false
		end

		if arg_5_0.event_info.end_time and arg_5_1.event_info.end_time then
			return arg_5_0.event_info.end_time < arg_5_1.event_info.end_time
		end

		return arg_5_0.id < arg_5_1.id
	end)
end

function var_0_0.adventureEventFinish(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in pairs(arg_6_0.adventureEventInfo) do
		if iter_6_1.id == arg_6_1 then
			iter_6_1.event_info = {}
		end
	end

	arg_6_0:sortEvent()
end

function var_0_0.adventureEventOccur(arg_7_0, arg_7_1)
	for iter_7_0, iter_7_1 in pairs(arg_7_0.adventureEventInfo) do
		if iter_7_1.id == arg_7_1.eventId then
			iter_7_1.event_info = arg_7_1.eventInfo
		end
	end

	arg_7_0:sortEvent()
end

function var_0_0.getAdventureEventInfo(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_ADVENTURE_INFO, var_8_0, function(arg_9_0, arg_9_1)
		if arg_8_2 then
			arg_8_2(arg_9_0, arg_9_1)
		end
	end)
end

function var_0_0.startAdventureBattleFight(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_1 or {}

	xyd.Backend.get():request(xyd.mid.START_PVP_FIGHT, var_10_0, function(arg_11_0, arg_11_1)
		if arg_10_2 then
			arg_10_2(arg_11_0, arg_11_1)
		end
	end)
end

function var_0_0.buyAdventureCard(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1 or {}

	xyd.Backend.get():request(xyd.mid.BUY_ADVENTURE_CARD, var_12_0, function(arg_13_0, arg_13_1)
		if arg_12_2 then
			arg_12_2(arg_13_0, arg_13_1)
		end
	end)
end

function var_0_0.reloadAdventureEventInfo(arg_14_0, arg_14_1)
	arg_14_0.adventureEventInfo = {}

	xyd.Backend.get():request(xyd.mid.GET_ADVENTURE_LIST, nil, function(arg_15_0, arg_15_1)
		if arg_14_1 then
			arg_14_0:initAdventureEventInfos(arg_15_1)
			arg_14_1(arg_15_0, arg_15_1)
		end
	end)
end

function var_0_0.buyAdventureItem(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1 or {}

	xyd.Backend.get():request(xyd.mid.BUY_ADVENTURE_ITEM, var_16_0, function(arg_17_0, arg_17_1)
		if arg_16_2 then
			arg_16_2(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.getStartEarliestTime(arg_18_0)
	if arg_18_0.adventureEventInfo and arg_18_0.adventureEventInfo[1] and arg_18_0.adventureEventInfo[1].event_info then
		if arg_18_0.adventureEventInfo[1].event_info.end_time then
			return {
				eventId = arg_18_0.adventureEventInfo[1].id,
				time = arg_18_0.adventureEventInfo[1].event_info.end_time
			}
		else
			return {
				time = -1,
				eventId = arg_18_0.adventureEventInfo[1].id
			}
		end
	else
		return {
			time = -1,
			eventId = -1
		}
	end
end

function var_0_0.updateCardContainer(arg_19_0, arg_19_1, arg_19_2, arg_19_3, arg_19_4)
	local var_19_0
	local var_19_1
	local var_19_2

	if arg_19_1 then
		local var_19_3 = arg_19_1:getSkinDatas()

		arg_19_3 = arg_19_3 or arg_19_0:getInitSkinIndex(arg_19_1)

		local var_19_4, var_19_5

		var_19_0, var_19_4, var_19_5 = arg_19_0:getCardIDInfoBaseOnCardState(arg_19_1, arg_19_3)
	end

	if arg_19_4 then
		var_19_0 = arg_19_4
	end

	local var_19_6 = xyd.SpriteLoader.new(xyd.tables.model:transparentCard(var_19_0), nil, nil, xyd.DefaultImageType.HOME_CARD, arg_19_2)

	if not var_19_6 then
		return
	end

	arg_19_2:removeAllChildren()
	arg_19_2:addChild(var_19_6)
	var_19_6:setAnchorPoint(cc.p(0.5, 0))
	var_19_6:setPosition(cc.p(arg_19_2:getContentSize().width / 2, 0))
	var_19_6:scale(arg_19_2:getContentSize().height / var_19_6:getContentSize().height)
	var_19_6:setTouchEnabled(false)
	var_19_6:setName("card")

	return var_19_0
end

function var_0_0.getCardIDInfoBaseOnCardState(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_1:getSkinDatas()

	arg_20_2 = arg_20_2 or arg_20_0:getInitSkinIndex(arg_20_1)

	local var_20_1 = var_20_0[arg_20_2] or var_20_0[1]
	local var_20_2 = xyd.tables.libraryHomeCard:x(var_20_1.modelID)
	local var_20_3 = xyd.tables.libraryHomeCard:y(var_20_1.modelID)

	return var_20_1.modelID, var_20_2, var_20_3
end

function var_0_0.getInitSkinIndex(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_1:getSkinDatas()

	if not arg_21_1.illusionSkinId_ then
		return skinIndex
	end

	if arg_21_1.illusionSkinId_ <= 1 then
		return arg_21_1.illusionSkinId_ + 1
	else
		for iter_21_0 = 2, #var_21_0 do
			local var_21_1 = var_21_0[iter_21_0]

			if var_21_1.isHave and var_21_1.cardState == xyd.CardStatus.SKIN_CARD and arg_21_1.illusionSkinId_ == var_21_1.modelID then
				return iter_21_0
			end
		end
	end

	return skinIndex
end

function var_0_0.getInitialCardState(arg_22_0, arg_22_1)
	cardState = xyd.CardStatus.NORMAL_CARD

	if arg_22_1:isAwaken() then
		cardState = xyd.CardStatus.AWAKE_CARD
	end

	if arg_22_1.isSkinOn_ == 1 then
		cardState = xyd.CardStatus.SKIN_CARD
	end

	return cardState
end

function var_0_0.clear(arg_23_0)
	arg_23_0.invitedList = {}
	arg_23_0.damageResult = {}
end

function var_0_0.clearDefense(arg_24_0)
	arg_24_0.invitedDefenseList = {}
end

function var_0_0.updateTeamInfo(arg_25_0, arg_25_1)
	arg_25_0.teamInfo = arg_25_1.room_info
end

function var_0_0.getRoomID(arg_26_0)
	return arg_26_0.teamInfo.room_id or 0
end

function var_0_0.getPlayerInfo(arg_27_0, arg_27_1)
	if not arg_27_0.teamInfo.members[arg_27_1] then
		return nil
	end

	local var_27_0 = arg_27_0.teamInfo.members[arg_27_1]

	return arg_27_0:getPlayerInfoByID(var_27_0)
end

function var_0_0.getPlayerInfoByID(arg_28_0, arg_28_1)
	if not arg_28_1 then
		return nil
	end

	for iter_28_0, iter_28_1 in pairs(arg_28_0.teamInfo.member_infos) do
		if iter_28_1.player_id == arg_28_1 then
			return iter_28_1
		end
	end

	return nil
end

function var_0_0.updateDefenseTeamInfo(arg_29_0, arg_29_1)
	arg_29_0.teamDefenseInfo = arg_29_1

	if arg_29_1 and arg_29_1.room_info then
		for iter_29_0, iter_29_1 in pairs(arg_29_1.room_info.members) do
			arg_29_0.roomMap[tostring(iter_29_1)] = 1
		end
	end
end

function var_0_0.clearDefenseTeamInfo(arg_30_0, arg_30_1)
	arg_30_0.teamDefenseInfo = {}
	arg_30_0.roomMap = {}
	arg_30_0.invitedDefenseList = {}
end

function var_0_0.updateDefenseRoomInfo(arg_31_0, arg_31_1)
	if not arg_31_0.teamDefenseInfo.room_info or arg_31_1.room_info.room_id == arg_31_0.teamDefenseInfo.room_info.room_id then
		arg_31_0.teamDefenseInfo.room_info = arg_31_1.room_info

		if arg_31_1.pos_status then
			arg_31_0.teamDefenseInfo.pos_statuses[arg_31_1.monster_pos] = arg_31_1.pos_status
		end

		if arg_31_1.monster_status then
			arg_31_0.teamDefenseInfo.monster_statuses = arg_31_1.monster_status
		end
	end
end

function var_0_0.updateDefensePosInfo(arg_32_0, arg_32_1)
	if arg_32_0.teamDefenseInfo.room_info and arg_32_1.room_id == arg_32_0.teamDefenseInfo.room_info.room_id then
		arg_32_0.teamDefenseInfo.pos_statuses[arg_32_1.monster_pos] = arg_32_1.pos_status

		if arg_32_1.monster_status then
			arg_32_0.teamDefenseInfo.monster_statuses = arg_32_1.monster_status
		end
	end
end

function var_0_0.getDefenseRoomID(arg_33_0)
	return arg_33_0.teamDefenseInfo.room_info.room_id or 0
end

function var_0_0.getDefensePlayerInfo(arg_34_0, arg_34_1)
	if not arg_34_0.teamDefenseInfo.room_info and not arg_34_0.teamDefenseInfo.room_info.members[arg_34_1] then
		return nil
	end

	local var_34_0 = arg_34_0.teamDefenseInfo.room_info.members[arg_34_1]

	return arg_34_0:getDefensePlayerInfoByID(var_34_0)
end

function var_0_0.getDefensePlayerInfoByID(arg_35_0, arg_35_1)
	if not arg_35_1 then
		return nil
	end

	for iter_35_0, iter_35_1 in pairs(arg_35_0.teamDefenseInfo.room_info.member_infos) do
		if iter_35_1.player_id == arg_35_1 then
			return iter_35_1
		end
	end

	return nil
end

function var_0_0.checkIsDefenseMaster(arg_36_0, arg_36_1)
	if arg_36_1 == arg_36_0.teamDefenseInfo.room_info.owner then
		return true
	end

	return false
end

function var_0_0.checkIsMaster(arg_37_0, arg_37_1)
	if arg_37_1 == arg_37_0.teamInfo.owner then
		return true
	end

	return false
end

function var_0_0.getIllusionRoomLev(arg_38_0)
	return arg_38_0:getPlayerInfoByID(arg_38_0.teamInfo.owner).lev
end

function var_0_0.kickMember(arg_39_0, arg_39_1, arg_39_2)
	local var_39_0 = arg_39_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_ILLUSION_KICK_MEMBER, var_39_0, function(arg_40_0, arg_40_1)
		if arg_40_0 == xyd.error.OK then
			-- block empty
		end

		if arg_39_2 then
			arg_39_2(arg_40_0, arg_40_1)
		end
	end)
end

function var_0_0.createTeamRoom(arg_41_0, arg_41_1, arg_41_2)
	arg_41_0:clear()

	local var_41_0 = arg_41_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_ILLUSION_CREATE_TEAM_ROOM, var_41_0, function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK and arg_42_1 and next(arg_42_1) then
			arg_41_0:updateTeamInfo(arg_42_1)
		end

		if arg_41_2 then
			arg_41_2(arg_42_0, arg_42_1)
		end
	end)
end

function var_0_0.exitRoom(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_ILLUSION_EXIT_ROOM, var_43_0, function(arg_44_0, arg_44_1)
		if arg_44_0 == xyd.error.OK then
			arg_43_0:resetInvited()
			arg_43_0:resetDefenseInvited()
			arg_43_0:resetRoomMap()
		end

		if arg_43_2 then
			arg_43_2(arg_44_0, arg_44_1)
		end
	end)
end

function var_0_0.joinRoom(arg_45_0, arg_45_1, arg_45_2)
	arg_45_0:clear()

	local var_45_0 = arg_45_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_ILLUSION_JOIN_ROOM, var_45_0, function(arg_46_0, arg_46_1)
		if arg_46_0 == xyd.error.OK then
			arg_45_0:updateTeamInfo(arg_46_1)
		else
			arg_45_0.everRoomIDs[var_45_0.room_id] = nil
		end

		if arg_45_2 then
			arg_45_2(arg_46_0, arg_46_1)
		end
	end)
end

function var_0_0.checkCanJoinRoom(arg_47_0, arg_47_1)
	local var_47_0 = tonumber(arg_47_1)

	if not arg_47_0.everRoomIDs then
		arg_47_0.everRoomIDs = {}
	end

	local var_47_1 = xyd.ServerTime.get():getServerTime()

	if not arg_47_0.everRoomIDs[var_47_0] then
		arg_47_0.everRoomIDs[var_47_0] = var_47_1

		return true
	elseif arg_47_0.everRoomIDs[var_47_0] > 0 then
		if var_47_1 - arg_47_0.everRoomIDs[var_47_0] > 30 then
			arg_47_0.everRoomIDs[var_47_0] = var_47_1

			return true
		else
			return false
		end
	end

	return true
end

function var_0_0.joinDefenseRoom(arg_48_0, arg_48_1, arg_48_2)
	arg_48_0:clearDefense()

	local var_48_0 = arg_48_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_ILLUSION_JOIN_ROOM, var_48_0, function(arg_49_0, arg_49_1)
		if arg_49_0 == xyd.error.OK then
			arg_48_0:updateDefenseTeamInfo(arg_49_1)
		else
			arg_48_0.everDefenseRoomIDs[var_48_0.room_id] = nil
		end

		if arg_48_2 then
			arg_48_2(arg_49_0, arg_49_1)
		end

		if arg_49_0 == xyd.error.OK then
			local var_49_0 = xyd.WindowManager.get():getWindow("adventure_defense")

			if var_49_0 and not tolua.isnull(var_49_0) then
				var_49_0.chatWnd:chatToFriends(string.format(var_0_1:translation("ADVENTURE_DEFENSE_ENTER_ROOM"), arg_48_0.selfPlayer.playerName), xyd.FriendMsgType.COMMON)
			end
		elseif arg_49_1.error_code and arg_49_1.error_code == 35029 then
			local var_49_1 = xyd.tables.message:getContent(arg_49_1.error_code)

			if var_49_1 and var_49_1 ~= "" then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_49_1
				})
			end
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("ILLUSION_TEAM_TIPS_10")
			})
		end
	end)
end

function var_0_0.checkCanJoinDefenseRoom(arg_50_0, arg_50_1)
	local var_50_0 = tonumber(arg_50_1)

	if not arg_50_0.everDefenseRoomIDs then
		arg_50_0.everDefenseRoomIDs = {}
	end

	local var_50_1 = xyd.ServerTime.get():getServerTime()

	if not arg_50_0.everDefenseRoomIDs[var_50_0] then
		arg_50_0.everDefenseRoomIDs[var_50_0] = var_50_1

		return true
	elseif arg_50_0.everDefenseRoomIDs[var_50_0] > 0 then
		if var_50_1 - arg_50_0.everDefenseRoomIDs[var_50_0] > 30 then
			arg_50_0.everDefenseRoomIDs[var_50_0] = var_50_1

			return true
		else
			return false
		end
	end

	return true
end

function var_0_0.inviteFriend(arg_51_0, arg_51_1, arg_51_2)
	local var_51_0 = arg_51_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_ILLUSION_INVITE_FRIEND, var_51_0, function(arg_52_0, arg_52_1)
		if arg_52_0 == xyd.error.OK then
			-- block empty
		end

		if arg_51_2 then
			arg_51_2(arg_52_0, arg_52_1)
		end
	end)
end

function var_0_0.addInvitedList(arg_53_0, arg_53_1)
	table.insert(arg_53_0.invitedList, arg_53_1)
end

function var_0_0.checkIsInvited(arg_54_0, arg_54_1)
	for iter_54_0 = 1, #arg_54_0.invitedList do
		if arg_54_0.invitedList[iter_54_0] == arg_54_1 then
			return true
		end
	end

	return false
end

function var_0_0.resetInvited(arg_55_0)
	arg_55_0.invitedList = {}
end

function var_0_0.resetRoomMap(arg_56_0)
	arg_56_0.roomMap = {}
end

function var_0_0.addDefenseInvitedList(arg_57_0, arg_57_1)
	table.insert(arg_57_0.invitedDefenseList, arg_57_1)
end

function var_0_0.updateDefenseInvitedList(arg_58_0, arg_58_1)
	for iter_58_0 = 1, #arg_58_0.invitedDefenseList do
		if arg_58_0.invitedDefenseList[iter_58_0] == arg_58_1 then
			arg_58_0.invitedDefenseList[iter_58_0] = nil
		end
	end
end

function var_0_0.checkIsDefenseInvited(arg_59_0, arg_59_1)
	for iter_59_0 = 1, #arg_59_0.invitedDefenseList do
		if arg_59_0.invitedDefenseList[iter_59_0] == arg_59_1 then
			return true
		end
	end

	return false
end

function var_0_0.resetDefenseInvited(arg_60_0)
	arg_60_0.invitedDefenseList = {}
end

function var_0_0.startChallenge(arg_61_0, arg_61_1, arg_61_2)
	local var_61_0 = arg_61_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_ILLUSION_ENTER_TEAM_FIGHT, var_61_0, function(arg_62_0, arg_62_1)
		if arg_62_0 == xyd.error.OK then
			-- block empty
		end

		if arg_61_2 then
			arg_61_2(arg_62_0, arg_62_1)
		end
	end)
end

function var_0_0.prepareTeamFight(arg_63_0, arg_63_1, arg_63_2)
	local var_63_0 = arg_63_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_ILLUSION_PREPARE_TEAM_FIGHT, var_63_0, function(arg_64_0, arg_64_1)
		if arg_64_0 == xyd.error.OK then
			arg_63_0:initialTeamStatus()
		end

		if arg_63_2 then
			arg_63_2(arg_64_0, arg_64_1)
		end
	end)
end

function var_0_0.initialTeamStatus(arg_65_0)
	arg_65_0.teamStatus = {}
end

function var_0_0.getPlayerStatus(arg_66_0, arg_66_1)
	return arg_66_0.teamStatus[tostring(arg_66_1)] or false
end

function var_0_0.setPlayerStatus(arg_67_0, arg_67_1, arg_67_2)
	arg_67_0.teamStatus[tostring(arg_67_1)] = arg_67_2
end

function var_0_0.isHeroSelected(arg_68_0, arg_68_1)
	local var_68_0

	if arg_68_0.teamInfo and arg_68_0.teamInfo.members and next(arg_68_0.teamInfo.members) then
		var_68_0 = arg_68_0.teamInfo.members
	else
		return false
	end

	if arg_68_1.isPet_ then
		local var_68_1

		if arg_68_0.teamFightInfos and arg_68_0.teamFightInfos[tostring(arg_68_0.teamInfo.owner)] and next(arg_68_0.teamFightInfos[tostring(arg_68_0.teamInfo.owner)]) then
			local var_68_2 = arg_68_0.teamFightInfos[tostring(arg_68_0.teamInfo.owner)].pet

			if var_68_2 and next(var_68_2) and var_68_2.table_id == arg_68_1:getTableID() then
				return true
			end

			return false
		else
			return false
		end
	else
		for iter_68_0 = 1, #var_68_0 do
			if arg_68_0.teamFightInfos and arg_68_0.teamFightInfos[tostring(var_68_0[iter_68_0])] and next(arg_68_0.teamFightInfos[tostring(var_68_0[iter_68_0])]) then
				local var_68_3 = arg_68_0.teamFightInfos[tostring(var_68_0[iter_68_0])].formation

				if var_68_3 and next(var_68_3) then
					for iter_68_1 = 1, #var_68_3 do
						if var_68_3[iter_68_1] and next(var_68_3[iter_68_1]) and var_68_3[iter_68_1].table_id == arg_68_1:getTableID() then
							return true
						end
					end
				end
			end
		end

		return false
	end
end

function var_0_0.teamFight(arg_69_0, arg_69_1, arg_69_2)
	local var_69_0 = arg_69_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_ILLUSION_TEAM_FIGHT, var_69_0, function(arg_70_0, arg_70_1)
		if arg_70_0 == xyd.error.OK then
			-- block empty
		end

		if arg_69_2 then
			arg_69_2(arg_70_0, arg_70_1)
		end
	end)
end

function var_0_0.pickTeamFight(arg_71_0, arg_71_1, arg_71_2)
	local var_71_0 = arg_71_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_ILLUSION_PICK_TEAM_FIGHT, var_71_0, function(arg_72_0, arg_72_1)
		if arg_72_0 == xyd.error.OK then
			-- block empty
		end

		if arg_71_2 then
			arg_71_2(arg_72_0, arg_72_1)
		end
	end)
end

function var_0_0.getReport(arg_73_0, arg_73_1, arg_73_2)
	local var_73_0 = arg_73_1 or {}

	xyd.Backend.get():request(xyd.mid.ILLUSION_GET_REPORT, var_73_0, function(arg_74_0, arg_74_1)
		if arg_74_0 == xyd.error.OK then
			-- block empty
		end

		if arg_73_2 then
			arg_73_2(arg_74_0, arg_74_1)
		end
	end)
end

function var_0_0.prepareRoomFight(arg_75_0, arg_75_1, arg_75_2)
	local var_75_0 = arg_75_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_DEFENSE_PREPARE_ROOM_FIGHT, var_75_0, function(arg_76_0, arg_76_1)
		if arg_76_0 == xyd.error.OK then
			-- block empty
		end

		if arg_75_2 then
			arg_75_2(arg_76_0, arg_76_1)
		end
	end)
end

function var_0_0.fightRoomResult(arg_77_0, arg_77_1, arg_77_2)
	local var_77_0 = arg_77_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_DEFENSE_FIGHT_ROOM_RESULT, var_77_0, function(arg_78_0, arg_78_1)
		if arg_78_0 == xyd.error.OK then
			-- block empty
		end

		if arg_77_2 then
			arg_77_2(arg_78_0, arg_78_1)
		end
	end)
end

function var_0_0.quitRoomFight(arg_79_0, arg_79_1, arg_79_2)
	local var_79_0 = arg_79_1 or {}

	xyd.Backend.get():request(xyd.mid.ADVENTURE_DEFENSE_QUIT_ROOM_FIGHT, var_79_0, function(arg_80_0, arg_80_1)
		if arg_80_0 == xyd.error.OK then
			-- block empty
		end

		if arg_79_2 then
			arg_79_2(arg_80_0, arg_80_1)
		end
	end)
end

function var_0_0.getReport(arg_81_0, arg_81_1, arg_81_2)
	local var_81_0 = arg_81_1 or {}

	xyd.Backend.get():request(xyd.mid.ILLUSION_GET_REPORT, var_81_0, function(arg_82_0, arg_82_1)
		if arg_82_0 == xyd.error.OK then
			-- block empty
		end

		if arg_81_2 then
			arg_81_2(arg_82_0, arg_82_1)
		end
	end)
end

function var_0_0.getDamageResult(arg_83_0)
	return arg_83_0.damageResult or 0
end

function var_0_0.setDamageResult(arg_84_0, arg_84_1)
	arg_84_0.damageResult = arg_84_1 or 0
end

function var_0_0.addChallengeTimes(arg_85_0, arg_85_1)
	arg_85_0.teamDefenseInfo.challenge_times[arg_85_1] = arg_85_0.teamDefenseInfo.challenge_times[arg_85_1] + 1
end

function var_0_0.closeDefenseWindow(arg_86_0)
	local var_86_0
	local var_86_1 = xyd.WindowManager.get():getWindow("adventure_defense")

	if var_86_1 and not tolua.isnull(var_86_1) then
		xyd.WindowManager.get():closeWindow("adventure_defense")
	end

	local var_86_2 = xyd.WindowManager.get():getWindow("battle_select_team")

	if var_86_2 and not tolua.isnull(var_86_2) then
		xyd.WindowManager.get():closeWindow("battle_select_team")
	end

	local var_86_3 = xyd.WindowManager.get():getWindow("adventure_defense_invite")

	if var_86_3 and not tolua.isnull(var_86_3) then
		xyd.WindowManager.get():closeWindow("adventure_defense_invite")
	end

	local var_86_4 = xyd.WindowManager.get():getWindow("adventure_defense_player_info")

	if var_86_4 and not tolua.isnull(var_86_4) then
		xyd.WindowManager.get():closeWindow("adventure_defense_player_info")
	end

	local var_86_5 = xyd.WindowManager.get():getWindow("adventure_defense_monster_detail")

	if var_86_5 and not tolua.isnull(var_86_5) then
		xyd.WindowManager.get():closeWindow("adventure_defense_monster_detail")
	end
end

function var_0_0.handleResponse(arg_87_0, arg_87_1)
	if arg_87_1.function_type == xyd.AdventureFunctionType.ROOM_CHANGE then
		if arg_87_1.self_info.room_id == 0 then
			local var_87_0 = xyd.WindowManager.get():getWindow("adventure_illusion_prepare")

			if var_87_0 and not tolua.isnull(var_87_0) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ILLUSION_TEAM_TIPS_18")
				})
				xyd.WindowManager.get():closeWindow("adventure_illusion_prepare")
			end

			local var_87_1 = xyd.WindowManager.get():getWindow("adventure_illusion_invite")

			if var_87_1 and not tolua.isnull(var_87_1) then
				xyd.WindowManager.get():closeWindow("adventure_illusion_invite")
			end

			local var_87_2 = xyd.WindowManager.get():getWindow("adventure_illusion_show_team")

			if var_87_2 and not tolua.isnull(var_87_2) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ADVENTURE_ILLUSION_DISSOLVE")
				})
				xyd.WindowManager.get():closeWindow("adventure_illusion_show_team")
			end
		else
			arg_87_0:updateTeamInfo(arg_87_1)

			local var_87_3 = xyd.WindowManager.get():getWindow("adventure_illusion_prepare")

			if var_87_3 and not tolua.isnull(var_87_3) then
				var_87_3:initList()
			end
		end
	elseif arg_87_1.function_type == xyd.AdventureFunctionType.ENTER_TEAM_FIGHT then
		arg_87_0.teamFightInfos = arg_87_1.self_infos

		local var_87_4 = xyd.WindowManager.get():getWindow("adventure_illusion_invite")

		if var_87_4 and not tolua.isnull(var_87_4) then
			xyd.WindowManager.get():closeWindow("adventure_illusion_invite")
		end

		local var_87_5 = xyd.WindowManager.get():getWindow("adventure_illusion_prepare")

		if var_87_5 and not tolua.isnull(var_87_5) then
			xyd.WindowManager.get():closeWindow("adventure_illusion_prepare")
		end

		xyd.WindowManager.get():openWindow("adventure_illusion_show_team")
	elseif arg_87_1.function_type == xyd.AdventureFunctionType.TEAM_FIGHT_SELECT or arg_87_1.function_type == xyd.AdventureFunctionType.PREPARE_TEAM_FIGHT then
		arg_87_0.teamFightInfos[tostring(arg_87_1.player_id)] = arg_87_1.self_info

		local var_87_6 = xyd.WindowManager.get():getWindow("adventure_illusion_show_team")

		if var_87_6 and not tolua.isnull(var_87_6) then
			var_87_6.adventureEvent.teamFightInfos = arg_87_0.teamFightInfos

			var_87_6:updateHeros()
		end
	elseif arg_87_1.function_type == xyd.AdventureFunctionType.TEAM_FIGHT then
		arg_87_0:setDamageResult(arg_87_1.total_damage)

		if not arg_87_0:checkIsMaster(arg_87_0.selfPlayer.playerID) then
			local var_87_7 = xyd.WindowManager.get():getWindow("adventure_illusion_show_team")

			if var_87_7 and not tolua.isnull(var_87_7) then
				var_87_7:teamFight(arg_87_1.report_key)
			end
		end
	end
end

function var_0_0.handleDefenseResponse(arg_88_0, arg_88_1)
	if arg_88_1.function_type == xyd.AdventureFunctionType.ROOM_CHANGE and arg_88_0.teamDefenseInfo.room_info and arg_88_1.room_id == arg_88_0.teamDefenseInfo.room_info.room_id then
		local var_88_0, var_88_1 = arg_88_0:handleRoomChange(arg_88_1)

		if arg_88_1.self_info and arg_88_1.self_info.room_id == 0 and not arg_88_1.room_info then
			local var_88_2 = xyd.WindowManager.get():getWindow("adventure_defense")

			if var_88_2 and not tolua.isnull(var_88_2) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ADVENTURE_END")
				})
			end

			arg_88_0:clearDefenseTeamInfo()
			arg_88_0:closeDefenseWindow()
		elseif not var_88_1 and tonumber(var_88_0) == arg_88_0.selfPlayer.playerID then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("ILLUSION_TEAM_TIPS_18")
			})
			arg_88_0:clearDefenseTeamInfo()
			arg_88_0:closeDefenseWindow()
		else
			arg_88_0:updateDefenseRoomInfo(arg_88_1)

			if not var_88_1 and tonumber(var_88_0) ~= arg_88_0.selfPlayer.playerID and arg_88_0:checkIsDefenseMaster(arg_88_0.selfPlayer.playerID) then
				arg_88_0:updateDefenseInvitedList(tonumber(var_88_0))
			end

			local var_88_3 = xyd.WindowManager.get():getWindow("adventure_defense_monster_detail")

			if var_88_3 and not tolua.isnull(var_88_3) then
				var_88_3:layout()
			end

			local var_88_4 = xyd.WindowManager.get():getWindow("adventure_defense")

			if var_88_4 and not tolua.isnull(var_88_4) then
				var_88_4:initRoom()
			end
		end

		local var_88_5 = xyd.WindowManager.get():getWindow("adventure_defense")

		if var_88_5 and not tolua.isnull(var_88_5) then
			var_88_5.chatWnd:changeMember(var_88_0, var_88_1)
		end
	elseif arg_88_1.function_type == xyd.AdventureFunctionType.PREPARE_ROOM_FIGHT or arg_88_1.function_type == xyd.AdventureFunctionType.QUIT_ROOM_FIGHT then
		arg_88_0:updateDefensePosInfo(arg_88_1)

		local var_88_6 = xyd.WindowManager.get():getWindow("adventure_defense_monster_detail")

		if var_88_6 and not tolua.isnull(var_88_6) then
			var_88_6:layout()
		end
	elseif arg_88_1.function_type == xyd.AdventureFunctionType.ROOM_FIGHT then
		arg_88_0:updateDefensePosInfo(arg_88_1)

		local var_88_7 = xyd.WindowManager.get():getWindow("adventure_defense")

		if var_88_7 and not tolua.isnull(var_88_7) then
			var_88_7:setMonsterStatus()
		end
	end
end

function var_0_0.handleRoomChange(arg_89_0, arg_89_1)
	local var_89_0
	local var_89_1

	if arg_89_1.room_info then
		for iter_89_0, iter_89_1 in pairs(arg_89_1.room_info.members) do
			if not arg_89_0.roomMap[tostring(iter_89_1)] then
				var_89_0 = iter_89_1
				var_89_1 = arg_89_1.room_info.member_infos[iter_89_0]
				arg_89_0.roomMap[tostring(iter_89_1)] = 1
			end
		end

		if not var_89_0 then
			for iter_89_2, iter_89_3 in pairs(arg_89_0.roomMap) do
				if not arg_89_0:findPlayer(tonumber(iter_89_2), arg_89_1.room_info.members) then
					var_89_0 = iter_89_2
					arg_89_0.roomMap[iter_89_2] = nil
				end
			end
		end
	end

	return var_89_0, var_89_1
end

function var_0_0.findPlayer(arg_90_0, arg_90_1, arg_90_2)
	for iter_90_0, iter_90_1 in pairs(arg_90_2) do
		if arg_90_1 == iter_90_1 then
			return true
		end
	end

	return false
end

function var_0_0.checkisBattle(arg_91_0, arg_91_1)
	for iter_91_0, iter_91_1 in pairs(arg_91_0.teamDefenseInfo.pos_statuses) do
		if tonumber(arg_91_1) == tonumber(iter_91_1.player_id) and iter_91_1.busy_type == xyd.AdventureDefenseBusyType.BATTLE then
			return true
		end
	end

	return false
end

function var_0_0.checkDefenseisFinish(arg_92_0, arg_92_1)
	for iter_92_0, iter_92_1 in pairs(arg_92_0.teamDefenseInfo.monster_statuses) do
		if iter_92_1 == "" then
			return false
		end
	end

	return true
end

function var_0_0.getEndTime(arg_93_0, arg_93_1)
	for iter_93_0, iter_93_1 in pairs(arg_93_0.adventureEventInfo) do
		if iter_93_1.id == tostring(arg_93_1) and iter_93_1.event_info and next(iter_93_1.event_info) then
			return iter_93_1.event_info.end_time
		end
	end

	return 0
end

function var_0_0.getChatWindow(arg_94_0, arg_94_1)
	local var_94_0 = import("app.windows.GroupChatWnd").new()
	local var_94_1 = {}

	for iter_94_0, iter_94_1 in pairs(arg_94_0.teamInfo.member_infos) do
		var_94_1[tostring(iter_94_1.player_id)] = iter_94_1
	end

	local var_94_2 = {
		select_type = xyd.FriendMsgSelectType.ADVENTURE_ILLUSION,
		member_infos = var_94_1,
		add_wnd_name = arg_94_1
	}

	var_94_0:setParams(var_94_2)

	return var_94_0
end

function var_0_0.getDefenseChatWindow(arg_95_0, arg_95_1)
	local var_95_0 = import("app.windows.GroupChatWnd").new()
	local var_95_1 = {}

	for iter_95_0, iter_95_1 in pairs(arg_95_0.teamDefenseInfo.room_info.member_infos) do
		var_95_1[tostring(iter_95_1.player_id)] = iter_95_1
	end

	local var_95_2 = {
		select_type = xyd.FriendMsgSelectType.ADVENTURE_DEFENSE,
		room_id = arg_95_0.teamDefenseInfo.room_info.room_id,
		member_infos = var_95_1,
		add_wnd_name = arg_95_1
	}

	var_95_0:setParams(var_95_2)

	return var_95_0
end

return var_0_0
