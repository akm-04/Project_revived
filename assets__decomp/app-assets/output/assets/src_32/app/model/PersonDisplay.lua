local var_0_0 = class("PersonDisplay", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.touchCount = 0
	arg_1_0.leftBtnStyle = xyd.PlayerCardButtonStyle.MAIN
	arg_1_0.recordTabType = xyd.PlayerCardHistory.ARENA
	arg_1_0.lastPlayerID = nil
	arg_1_0.isLoadInfo = {}
	arg_1_0.oldPlayerInfos = {}
	arg_1_0.singlePageMsgNum = xyd.tables.misc.personCommentEveryPageMsgNum

	arg_1_0:clear()

	arg_1_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.updateInfo(arg_3_0, arg_3_1, arg_3_2)
	if arg_3_1 == xyd.PlayerCardButtonStyle.HISTORY then
		arg_3_0:updateHistoryInfo(arg_3_2)
	elseif arg_3_1 == xyd.PlayerCardButtonStyle.BATTLE_RECORD then
		arg_3_0:updateRecordInfo(arg_3_2)
	elseif arg_3_1 == xyd.PlayerCardButtonStyle.SPACE then
		arg_3_0:updateSpaceInfo(arg_3_2)
	else
		arg_3_0:updateBasicInfo(arg_3_2)
	end

	if arg_3_1 then
		arg_3_0.isLoadInfo[arg_3_1] = true
	else
		arg_3_0.isLoadInfo[xyd.PlayerCardButtonStyle.MAIN] = true
	end
end

function var_0_0.checkCanTouch(arg_4_0)
	return arg_4_0.touchCount < 2
end

function var_0_0.getTouchCount(arg_5_0)
	return arg_5_0.touchCount
end

function var_0_0.checkNeedReturn(arg_6_0)
	if arg_6_0:getTouchCount() > 1 and arg_6_0:getLastPlayerID() then
		return true
	end

	return false
end

function var_0_0.getLastPlayerLeftInfo(arg_7_0)
	return arg_7_0.leftBtnStyle, arg_7_0.recordTabType
end

function var_0_0.updatePlayerStatus(arg_8_0, arg_8_1, arg_8_2)
	if not arg_8_0:checkNeedReturn() then
		arg_8_0.leftBtnStyle = arg_8_1 or xyd.PlayerCardButtonStyle.MAIN
		arg_8_0.recordTabType = arg_8_2 or xyd.PlayerCardHistory.ARENA
	end
end

function var_0_0.updateLeftBtnStyle(arg_9_0, arg_9_1)
	arg_9_0.leftBtnStyle = arg_9_1
end

function var_0_0.updateRecordTabType(arg_10_0, arg_10_1)
	arg_10_0.recordTabType = arg_10_1
end

function var_0_0.updateTouchCount(arg_11_0, arg_11_1)
	if arg_11_1 then
		arg_11_0.touchCount = arg_11_0.touchCount + 1
		arg_11_0.oldPlayerInfos[arg_11_0.touchCount] = arg_11_0:getBasicInfo()
	else
		arg_11_0.oldPlayerInfos[arg_11_0.touchCount] = nil
		arg_11_0.touchCount = arg_11_0.touchCount - 1
	end
end

function var_0_0.getLastPlayerID(arg_12_0)
	return arg_12_0.lastPlayerID
end

function var_0_0.updateBasicInfo(arg_13_0, arg_13_1)
	arg_13_0.introduce = arg_13_1.intro or ""
	arg_13_0.praiseNum = arg_13_1.praise_num or 0
	arg_13_0.shareSwitch = arg_13_1.share_switch or 0
	arg_13_0.showCase = arg_13_1.show_case or {}
	arg_13_0.showTypes = arg_13_1.show_types or {}
	arg_13_0.hideTypes = arg_13_1.hide_types or {}
	arg_13_0.playerInfo = arg_13_1.player_info or {}
	arg_13_0.isFirstTime = arg_13_1.is_first_time or 0
	arg_13_0.isInblackList = arg_13_1.is_in_blacklist or false

	if arg_13_1.player_info and next(arg_13_1.player_info) then
		arg_13_0.playerID = arg_13_1.player_info.player_id or 0
	end

	arg_13_0.isHasPraise = arg_13_1.is_has_praise or 0
	arg_13_0.isRobot = arg_13_1.isRobot or false
	arg_13_0.avatarFilePath = arg_13_1.avatar_file_path
	arg_13_0.avatarMd5Code = arg_13_1.avatar_md5_code
	arg_13_0.openFunctions = arg_13_1.open_functions
	arg_13_0.basicInfo = arg_13_1

	if not arg_13_0.lastPlayerID then
		arg_13_0.lastPlayerID = arg_13_0.playerID
	end
end

function var_0_0.isFuncOpen(arg_14_0, arg_14_1)
	if arg_14_0.openFunctions and xyd.isInTable(arg_14_0.openFunctions, arg_14_1) then
		return true
	else
		return false
	end
end

function var_0_0.checkIsRobot(arg_15_0)
	return arg_15_0.isRobot
end

function var_0_0.updatePlayerInfo(arg_16_0, arg_16_1)
	if arg_16_1.avatar_id then
		arg_16_0.playerInfo.avatar_id = arg_16_1.avatar_id
		arg_16_0.basicInfo.player_info.avatar_id = arg_16_1.avatar_id
	end

	if arg_16_1.avatar_frame_id then
		arg_16_0.playerInfo.avatar_frame_id = arg_16_1.avatar_frame_id
		arg_16_0.basicInfo.player_info.avatar_frame_id = arg_16_1.avatar_frame_id
	end

	if arg_16_1.player_name then
		arg_16_0.playerInfo.player_name = arg_16_1.player_name
		arg_16_0.basicInfo.player_info.player_name = arg_16_1.player_name
	end
end

function var_0_0.updateHistoryInfo(arg_17_0, arg_17_1)
	arg_17_0.arenaPerformance = arg_17_1.arena_performance or {}
	arg_17_0.regionArenaPerformance = arg_17_1.region_arena_performance or {}
	arg_17_0.superArenaPerformance = arg_17_1.super_arena_performance or {}
end

function var_0_0.updateRecordInfo(arg_18_0, arg_18_1)
	arg_18_0.arenaRecords = arg_18_1.arena_records or {}
	arg_18_0.superArenaRecords = arg_18_1.super_arena_records or {}

	if arg_18_1.region_arena_records then
		arg_18_0.regionArenaRecords = arg_18_1.region_arena_records.records or {}
	end
end

function var_0_0.updateSpaceInfo(arg_19_0, arg_19_1)
	if arg_19_1.best_comments and next(arg_19_1.best_comments) then
		arg_19_0.bestComments = arg_19_1.best_comments
	end

	if arg_19_1.comment_list and next(arg_19_1.comment_list) then
		arg_19_0.commenList = arg_19_1.comment_list
	end

	if arg_19_1.comment_num then
		arg_19_0.commentNum = arg_19_1.comment_num
	end
end

function var_0_0.getPlayerName(arg_20_0)
	return arg_20_0.playerInfo.player_name
end

function var_0_0.updateCommentList(arg_21_0, arg_21_1)
	if arg_21_1 and next(arg_21_1) then
		for iter_21_0 = 1, #arg_21_1 do
			table.insert(arg_21_0.commenList, arg_21_1[iter_21_0])
		end
	end
end

function var_0_0.updateCommentItemInfo(arg_22_0, arg_22_1)
	for iter_22_0 = 1, #arg_22_0.commenList do
		if arg_22_0.commenList[iter_22_0].comment_id == arg_22_1.comment_id then
			arg_22_0.commenList[iter_22_0] = arg_22_1

			break
		end
	end
end

function var_0_0.updateIntroduce(arg_23_0, arg_23_1)
	arg_23_0.introduce = arg_23_1.intro
	arg_23_0.basicInfo.intro = arg_23_1.intro
end

function var_0_0.clear(arg_24_0)
	arg_24_0.introduce = ""
	arg_24_0.praiseNum = 0
	arg_24_0.shareSwitch = 0
	arg_24_0.playerID = 0
	arg_24_0.showCase = {}
	arg_24_0.showTypes = {}
	arg_24_0.playerInfo = {}
	arg_24_0.basicInfo = {}
	arg_24_0.arenaRecords = {}
	arg_24_0.regionArenaRecords = {}
	arg_24_0.superArenaRecords = {}
	arg_24_0.bestComments = {}
	arg_24_0.commenList = {}
	arg_24_0.isLoadInfo = {}
	arg_24_0.hideTypes = {}
	arg_24_0.praiseList = {}
	arg_24_0.isHasPraise = 0
	arg_24_0.isRobot = false
	arg_24_0.commentNum = 0
	arg_24_0.isFirstTime = 0
	arg_24_0.praiseTotalum = 0
	arg_24_0.isInblackList = false
	arg_24_0.avatarFilePath = ""
	arg_24_0.avatarMd5Code = ""
end

function var_0_0.checkIsFirstTime(arg_25_0)
	if arg_25_0.isFirstTime == 1 then
		return true
	end

	return false
end

function var_0_0.updateFirstTime(arg_26_0, arg_26_1)
	arg_26_0.isFirstTime = arg_26_1
	arg_26_0.basicInfo.is_first_time = arg_26_1
end

function var_0_0.getPlayerInfo(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	if arg_27_3 then
		arg_27_0:clear()
	elseif arg_27_1.sub_type and arg_27_0.isLoadInfo[arg_27_1.sub_type] then
		if arg_27_2 then
			arg_27_2(xyd.error.OK)
		end

		return
	end

	if arg_27_1.isRobot then
		arg_27_0:updateInfo(xyd.PlayerCardButtonStyle.MAIN, arg_27_1)

		if arg_27_2 then
			arg_27_2(xyd.error.OK)
		end

		return
	else
		local var_27_0 = arg_27_1.to_player_id

		if var_27_0 and var_27_0 > 25000 and var_27_0 < 100000 then
			var_27_0 = var_27_0 + arg_27_0:getRegion() * 100000
		end

		local var_27_1 = {
			to_player_id = var_27_0,
			sub_type = arg_27_1.sub_type
		}

		xyd.Backend.get():request(xyd.mid.GET_PLAYER_CARD_INFO, var_27_1, function(arg_28_0, arg_28_1, arg_28_2)
			if arg_28_0 == xyd.error.OK then
				arg_27_0.playerID = var_27_1.to_player_id

				arg_27_0:setRegion(arg_27_0.playerID)
				arg_27_0:updateInfo(var_27_1.sub_type, arg_28_1)

				if arg_27_2 then
					arg_27_2(arg_28_0, arg_28_1)
				end
			end
		end)
	end
end

function var_0_0.getBasicInfo(arg_29_0)
	return arg_29_0.basicInfo
end

function var_0_0.setRegion(arg_30_0, arg_30_1)
	arg_30_0.region = xyd.getPlayerRegion(arg_30_1 or 0)
end

function var_0_0.getRegion(arg_31_0)
	return arg_31_0.region or 1
end

function var_0_0.getShowTypes(arg_32_0)
	local var_32_0 = {}

	if arg_32_0:checkIsRobot() then
		var_32_0 = xyd.tables.personDisplayWords:getRobotRandomList()
	else
		var_32_0 = arg_32_0.showTypes
	end

	return var_32_0
end

function var_0_0.getPlayerID(arg_33_0)
	return arg_33_0.playerID
end

function var_0_0.getShowCase(arg_34_0)
	return arg_34_0.showCase
end

function var_0_0.getPraiseNum(arg_35_0)
	return arg_35_0.praiseNum
end

function var_0_0.checkYouIsInBlackList(arg_36_0)
	return arg_36_0.isInblackList
end

function var_0_0.getIsHasPraise(arg_37_0)
	return arg_37_0.isHasPraise
end

function var_0_0.getIntroduce(arg_38_0)
	return arg_38_0.introduce
end

function var_0_0.getHideTypes(arg_39_0)
	return arg_39_0.hideTypes
end

function var_0_0.getPraiseInfos(arg_40_0)
	return arg_40_0.praiseList
end

function var_0_0.updatePraiseList(arg_41_0, arg_41_1)
	for iter_41_0 = 1, #arg_41_1 do
		table.insert(arg_41_0.praiseList, arg_41_1[iter_41_0])
	end
end

function var_0_0.getHistoryInfo(arg_42_0, arg_42_1)
	if arg_42_1 == xyd.PlayerCardHistory.ARENA then
		return arg_42_0:getArena()
	elseif arg_42_1 == xyd.PlayerCardHistory.SUPER_ARENA then
		return arg_42_0:getSuperArena()
	elseif arg_42_1 == xyd.PlayerCardHistory.REGION_ARENA then
		return arg_42_0:getRegionArena()
	end
end

function var_0_0.getRecordInfo(arg_43_0, arg_43_1)
	if arg_43_1 == xyd.PlayerCardHistory.ARENA then
		return arg_43_0.arenaRecords
	elseif arg_43_1 == xyd.PlayerCardHistory.SUPER_ARENA then
		return arg_43_0.superArenaRecords
	elseif arg_43_1 == xyd.PlayerCardHistory.REGION_ARENA then
		return arg_43_0.regionArenaRecords
	end
end

function var_0_0.getSpaceInfo(arg_44_0, arg_44_1)
	if arg_44_1 < 1 then
		return
	end

	local var_44_0 = {}

	for iter_44_0 = (arg_44_1 - 1) * arg_44_0.singlePageMsgNum + 1, #arg_44_0.commenList do
		table.insert(var_44_0, arg_44_0.commenList[iter_44_0])
	end

	return var_44_0
end

function var_0_0.getCommentInfos(arg_45_0, arg_45_1)
	if arg_45_1 < 1 then
		return
	end

	local var_45_0 = {}

	if arg_45_1 == 1 then
		for iter_45_0 = 1, #arg_45_0.bestComments do
			arg_45_0.bestComments[iter_45_0].isBest = true

			table.insert(var_45_0, arg_45_0.bestComments[iter_45_0])
		end
	end

	local var_45_1 = (arg_45_1 - 1) * arg_45_0.singlePageMsgNum + 1

	if arg_45_1 > 1 then
		var_45_1 = var_45_1 - #arg_45_0.bestComments
	end

	local var_45_2 = arg_45_0.singlePageMsgNum - #var_45_0

	for iter_45_1 = var_45_1, #arg_45_0.commenList do
		if var_45_2 > 0 then
			table.insert(var_45_0, arg_45_0.commenList[iter_45_1])

			var_45_2 = var_45_2 - 1

			if var_45_2 <= 0 then
				break
			end
		end
	end

	return var_45_0
end

function var_0_0.removeComment(arg_46_0, arg_46_1)
	for iter_46_0 = 1, #arg_46_0.commenList do
		if arg_46_0.commenList[iter_46_0].comment_id == arg_46_1 then
			table.remove(arg_46_0.commenList, iter_46_0)

			break
		end
	end

	for iter_46_1 = 1, #arg_46_0.bestComments do
		if arg_46_0.bestComments[iter_46_1].comment_id == arg_46_1 then
			table.remove(arg_46_0.bestComments, iter_46_1)

			break
		end
	end

	return #arg_46_0.commenList
end

function var_0_0.getMaxCommentPage(arg_47_0)
	return math.max(1, math.ceil(arg_47_0.commentNum / arg_47_0.singlePageMsgNum))
end

function var_0_0.getArena(arg_48_0)
	return arg_48_0.arenaPerformance or {}
end

function var_0_0.getRegionArena(arg_49_0)
	return arg_49_0.regionArenaPerformance or {}
end

function var_0_0.getSuperArena(arg_50_0)
	return arg_50_0.superArenaPerformance or {}
end

function var_0_0.updateShowCase(arg_51_0, arg_51_1)
	arg_51_0.showCase = arg_51_1
	arg_51_0.basicInfo.show_case = arg_51_1
end

function var_0_0.updateShowTypes(arg_52_0, arg_52_1)
	arg_52_0.showTypes = arg_52_1
	arg_52_0.basicInfo.show_types = arg_52_1
end

function var_0_0.updatePraiseNum(arg_53_0, arg_53_1)
	arg_53_0.praiseNum = arg_53_1
	arg_53_0.basicInfo.praise_num = arg_53_1
end

function var_0_0.updateIsHasPraise(arg_54_0, arg_54_1)
	arg_54_0.isHasPraise = arg_54_1
end

function var_0_0.updatehideSubType(arg_55_0, arg_55_1)
	arg_55_0.hideTypes = arg_55_1
end

function var_0_0.modifyShowCase(arg_56_0, arg_56_1, arg_56_2)
	local var_56_0 = {
		ids = arg_56_1
	}

	xyd.Backend.get():request(xyd.mid.MODIFY_SHOW_CASE, var_56_0, function(arg_57_0, arg_57_1, arg_57_2)
		if arg_57_0 == xyd.error.OK then
			arg_56_0:updateShowCase(arg_57_1.show_case)

			if arg_56_2 then
				arg_56_2(arg_57_0, arg_57_1)
			end
		end
	end)
end

function var_0_0.modifyShowTypes(arg_58_0, arg_58_1, arg_58_2)
	local var_58_0 = {
		show_types = arg_58_1
	}

	xyd.Backend.get():request(xyd.mid.MODIFY_SHOW_TYPES, var_58_0, function(arg_59_0, arg_59_1, arg_59_2)
		if arg_59_0 == xyd.error.OK then
			arg_58_0:updateShowTypes(arg_59_1.show_types)

			if arg_58_2 then
				arg_58_2(arg_59_0, arg_59_1)
			end
		end
	end)
end

function var_0_0.addPraise(arg_60_0, arg_60_1, arg_60_2)
	local var_60_0 = {
		to_player_id = arg_60_1
	}

	xyd.Backend.get():request(xyd.mid.PLAYER_CARD_ADD_PRAISE, var_60_0, function(arg_61_0, arg_61_1, arg_61_2)
		if arg_61_0 == xyd.error.OK then
			arg_60_0:updatePraiseNum(arg_61_1.praise_num)
			arg_60_0:updateIsHasPraise(arg_61_1.is_has_praise)

			if arg_60_2 then
				arg_60_2(arg_61_0, arg_61_1)
			end
		end
	end)
end

function var_0_0.getAllShowTypeInfos(arg_62_0, arg_62_1)
	xyd.Backend.get():request(xyd.mid.GET_ALL_SHOW_TYPE_INFOS, {}, function(arg_63_0, arg_63_1, arg_63_2)
		if arg_63_0 == xyd.error.OK and arg_62_1 then
			arg_62_1(arg_63_0, arg_63_1.all_show_types)
		end
	end)
end

function var_0_0.addComment(arg_64_0, arg_64_1, arg_64_2)
	local var_64_0 = {
		to_player_id = arg_64_1.to_player_id,
		content = arg_64_1.content
	}

	xyd.Backend.get():request(xyd.mid.ADD_COMMENT, var_64_0, function(arg_65_0, arg_65_1, arg_65_2)
		if arg_65_0 == xyd.error.OK then
			arg_64_0:updateSpaceInfo(arg_65_1)

			if arg_64_2 then
				arg_64_2(arg_65_0, arg_65_1)
			end
		end
	end)
end

function var_0_0.delComment(arg_66_0, arg_66_1, arg_66_2)
	local var_66_0 = arg_66_1.commentID
	local var_66_1 = arg_66_1.pageNum
	local var_66_2 = {
		comment_id = var_66_0
	}

	xyd.Backend.get():request(xyd.mid.DEL_COMMENT, var_66_2, function(arg_67_0, arg_67_1, arg_67_2)
		if arg_67_0 == xyd.error.OK then
			if arg_66_0:removeComment(var_66_0) <= var_66_1 * arg_66_0.singlePageMsgNum then
				local var_67_0 = {
					playerID = arg_66_0:getPlayerID(),
					pageNum = var_66_1
				}

				arg_66_0.commentNum = arg_66_0.commentNum - 1

				arg_66_0:getCommentList(var_67_0, function(arg_68_0, arg_68_1)
					if arg_66_2 then
						arg_66_2(arg_68_0, arg_68_1)
					end
				end)
			elseif arg_66_2 then
				arg_66_2(arg_67_0, arg_67_1)
			end
		end
	end)
end

function var_0_0.addCommentPraise(arg_69_0, arg_69_1, arg_69_2)
	local var_69_0 = {
		comment_id = arg_69_1.comment_id,
		to_player_id = arg_69_1.to_player_id
	}

	xyd.Backend.get():request(xyd.mid.ADD_COMMENT_PRAISE, var_69_0, function(arg_70_0, arg_70_1, arg_70_2)
		if arg_70_0 == xyd.error.OK then
			if arg_70_1.best_comments then
				arg_69_0.bestComments = arg_70_1.best_comments
			end

			arg_69_0:updateCommentItemInfo(arg_70_1.comment_info or {})

			if arg_69_2 then
				arg_69_2(arg_70_0, arg_70_1.comment_info or {})
			end
		end
	end)
end

function var_0_0.getCommentList(arg_71_0, arg_71_1, arg_71_2)
	if #arg_71_0:getCommentInfos(arg_71_1.pageNum) == arg_71_0.singlePageMsgNum then
		if arg_71_2 then
			arg_71_2(xyd.error.OK)
		end

		return
	end

	local var_71_0 = arg_71_1.playerID
	local var_71_1 = #arg_71_0.commenList
	local var_71_2 = {
		to_player_id = var_71_0,
		start = var_71_1,
		offset = arg_71_0.singlePageMsgNum
	}

	if arg_71_0.commentNum > 0 then
		var_71_2.comment_num = arg_71_0.commentNum
	end

	xyd.Backend.get():request(xyd.mid.GET_COMMENT_LIST, var_71_2, function(arg_72_0, arg_72_1, arg_72_2)
		if arg_72_0 == xyd.error.OK and arg_72_1.comment_list and next(arg_72_1.comment_list) then
			arg_71_0:updateCommentList(arg_72_1.comment_list)
		end

		if arg_71_2 then
			arg_71_2(arg_72_0, arg_72_1)
		end
	end)
end

function var_0_0.modifyIntro(arg_73_0, arg_73_1, arg_73_2)
	arg_73_1 = arg_73_1 and arg_73_0.filterWord:warningStrGsub(arg_73_1)

	local var_73_0 = {
		content = arg_73_1
	}

	xyd.Backend.get():request(xyd.mid.MODIFY_INTRO, var_73_0, function(arg_74_0, arg_74_1, arg_74_2)
		if arg_74_0 == xyd.error.OK then
			arg_73_0:updateIntroduce(arg_74_1)

			if arg_73_2 then
				arg_73_2(arg_74_0, arg_74_1)
			end
		end
	end)
end

function var_0_0.hideSubType(arg_75_0, arg_75_1, arg_75_2)
	local var_75_0 = {
		sub_types = arg_75_1
	}

	xyd.Backend.get():request(xyd.mid.HIDE_SUB_TYPE, var_75_0, function(arg_76_0, arg_76_1, arg_76_2)
		if arg_76_0 == xyd.error.OK then
			arg_75_0:updatehideSubType(arg_76_1.hide_types)

			if arg_75_2 then
				arg_75_2(arg_76_0, arg_76_1)
			end
		end
	end)
end

function var_0_0.getShowcaseDetail(arg_77_0, arg_77_1, arg_77_2)
	local var_77_0 = {
		index = arg_77_1.index,
		to_player_id = arg_77_1.playerID
	}

	xyd.Backend.get():request(xyd.mid.GET_SHOWCASE_DETAIL, var_77_0, function(arg_78_0, arg_78_1, arg_78_2)
		if arg_78_0 == xyd.error.OK and arg_77_2 then
			arg_77_2(arg_78_0, arg_78_1)
		end
	end)
end

function var_0_0.getPraiseList(arg_79_0, arg_79_1, arg_79_2)
	if arg_79_1 then
		arg_79_0.praiseList = {}
	end

	local var_79_0 = arg_79_0:getPraiseInfos()

	if arg_79_0.praiseTotalum > 0 and #var_79_0 == arg_79_0.praiseTotalum then
		return
	end

	local var_79_1 = #arg_79_0.praiseList
	local var_79_2 = {
		start = var_79_1,
		offset = arg_79_0.singlePageMsgNum
	}

	if arg_79_0.praiseTotalum and arg_79_0.praiseTotalum > 0 then
		var_79_2.total_num = arg_79_0.praiseTotalum
	end

	xyd.Backend.get():request(xyd.mid.GET_PRAISE_LIST, var_79_2, function(arg_80_0, arg_80_1, arg_80_2)
		if arg_80_0 == xyd.error.OK then
			if arg_80_1.praise_list and next(arg_80_1.praise_list) then
				arg_79_0:updatePraiseList(arg_80_1.praise_list)
			end

			if arg_80_1.total_num then
				arg_79_0.praiseTotalum = arg_80_1.total_num
			end

			if arg_79_2 then
				arg_79_2(arg_80_0, arg_80_1)
			end
		end
	end)
end

function var_0_0.uploadAvatar(arg_81_0, arg_81_1, arg_81_2)
	if not arg_81_1.form_name or not arg_81_1.file_path or not arg_81_1.file_name then
		return
	end

	local var_81_0 = arg_81_1.file_path
	local var_81_1, var_81_2 = io.open(var_81_0, "r")

	if not var_81_1 then
		print("File path is not exists. filePath = ", var_81_0)

		return
	end

	var_81_1:close()

	local var_81_3 = cc.Crypto:MD5File(var_81_0)

	if arg_81_0.avatarMd5Code == var_81_3 then
		return
	end

	local var_81_4 = {
		form_name = arg_81_1.form_name,
		file_path = arg_81_1.file_path,
		file_name = arg_81_1.file_name,
		md5_code = var_81_3
	}

	xyd.Backend.get():request(xyd.mid.UPLOAD_SPACE_AVATAR, var_81_4, function(arg_82_0, arg_82_1, arg_82_2)
		if arg_82_0 == xyd.error.OK then
			if arg_82_1 and next(arg_82_1) then
				arg_81_0.avatarFilePath = arg_82_1.avatar_file_path
				arg_81_0.avatarMd5Code = arg_82_1.avatar_md5_code
				arg_81_0.basicInfo.avatar_file_path = arg_82_1.avatar_file_path
				arg_81_0.basicInfo.avatar_md5_code = arg_82_1.avatar_md5_code
			end

			if arg_81_2 then
				arg_81_2(arg_82_0, arg_82_1)
			end
		end
	end)
end

return var_0_0
