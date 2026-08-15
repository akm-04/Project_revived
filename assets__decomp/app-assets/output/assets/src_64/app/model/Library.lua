local var_0_0 = class("Library", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = 1000

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.libraryInfos = {}
	arg_1_0.talkInfo = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.queryForumByPage(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.QUERY_FORUM_BY_PAGE, var_3_0, function(arg_4_0, arg_4_1)
		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.addForumLike(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.ADD_FORUM_LIKE, var_5_0, function(arg_6_0, arg_6_1)
		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.addForumComment(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.ADD_FORUM_COMMENT, var_7_0, function(arg_8_0, arg_8_1)
		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.setBoardHero(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.SET_BOARD_HERO, var_9_0, function(arg_10_0, arg_10_1)
		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.readDialog(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.READ_DIALOG, var_11_0, function(arg_12_0, arg_12_1)
		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.updateLibraryInfos(arg_13_0, arg_13_1)
	if arg_13_1 and arg_13_1.library_infos and next(arg_13_1.library_infos) then
		for iter_13_0, iter_13_1 in pairs(arg_13_1.library_infos) do
			arg_13_0.libraryInfos[tonumber(iter_13_0)] = iter_13_1
		end
	end

	arg_13_0.talkInfo = arg_13_1.library_talk_infos

	if arg_13_0.libraryInfos and next(arg_13_0.libraryInfos) then
		for iter_13_2, iter_13_3 in pairs(arg_13_0.libraryInfos) do
			if iter_13_3 and iter_13_3.favor_degree then
				local var_13_0 = arg_13_0.selfPlayer:getHeroByID(tonumber(iter_13_2))

				if not var_13_0 then
					dump(iter_13_2)
				end

				var_13_0.favorDegree = iter_13_3.favor_degree
			end
		end
	end

	arg_13_0:initTalkOPenList()

	local var_13_1 = #xyd.tables.libraryCG:getIDs()

	arg_13_0.memoryCollectInfo = {}

	for iter_13_4 = 1, var_13_1 do
		arg_13_0.memoryCollectInfo[iter_13_4] = 0
	end

	for iter_13_5 = 1, #(arg_13_1.library_cg_infos or {}) do
		arg_13_0.memoryCollectInfo[arg_13_1.library_cg_infos[iter_13_5]] = 1
	end

	local var_13_2 = arg_13_1.library_bg_infos or {}
	local var_13_3 = xyd.tables.libraryBG
	local var_13_4 = var_13_3:getIDs()
	local var_13_5
	local var_13_6

	arg_13_0.bgInfo = {}
	arg_13_0.bgMain = var_13_2.bg_main or 1
	arg_13_0.bgRoom = var_13_2.bg_room or 2

	for iter_13_6 = 1, #var_13_4 do
		local var_13_7 = {
			isUnlock = false,
			id = iter_13_6
		}

		if var_13_3:getLimit(iter_13_6) == 0 then
			var_13_7.isUnlock = true
		elseif var_13_3:getLimit(iter_13_6) == 2 then
			var_13_5 = var_13_3:getTime(iter_13_6)
			var_13_6 = iter_13_6
		end

		table.insert(arg_13_0.bgInfo, var_13_7)
	end

	for iter_13_7 = 1, #(var_13_2.has_buy or {}) do
		arg_13_0.bgInfo[var_13_2.has_buy[iter_13_7]].isUnlock = true
	end

	if var_13_5 and var_13_5 > var_13_2.server_time then
		local var_13_8 = var_13_5 - var_13_2.server_time

		arg_13_0.countDownHandle = var_0_2.scheduleGlobal(function()
			var_13_8 = var_13_8 - 1

			if var_13_8 <= 0 then
				if arg_13_0.bgMain == var_13_6 and not arg_13_0.bgInfo[i].isUnlock then
					arg_13_0.bgMain = 1

					arg_13_0:setLibraryBG({
						bg_id = 1,
						_type = 1
					})

					if display.getRunningScene().__cname == "MainScene" then
						display.getRunningScene():setupBackground()
					end
				end

				if arg_13_0.bgRoom == var_13_6 and not arg_13_0.bgInfo[i].isUnlock then
					arg_13_0.bgRoom = 2

					arg_13_0:setLibraryBG({
						bg_id = 2,
						_type = 2
					})

					local var_14_0 = xyd.WindowManager.get():getWindow("hero_dialog")

					if var_14_0 then
						var_14_0:setBG()
					end

					local var_14_1 = xyd.WindowManager.get():getWindow("hero_talk_wnd")

					if var_14_1 then
						var_14_1:setBG()
					end

					local var_14_2 = xyd.WindowManager.get():getWindow("hero_visit_main")

					if var_14_2 then
						var_14_2:setBG()
					end

					local var_14_3 = xyd.WindowManager.get():getWindow("hero_gift_box")

					if var_14_3 then
						var_14_3:setBG()
					end

					local var_14_4 = xyd.WindowManager.get():getWindow("hero_task_main")

					if var_14_4 then
						var_14_4:setBG()
					end

					local var_14_5 = xyd.WindowManager.get():getWindow("hero_touch_game")

					if var_14_5 then
						var_14_5:setBG()
					end

					local var_14_6 = xyd.WindowManager.get():getWindow("library_feed")

					if var_14_6 then
						var_14_6:setBG()
					end
				end

				var_0_2.unscheduleGlobal(arg_13_0.countDownHandle)

				arg_13_0.countDownHandle = nil
			end
		end, 1)
	end
end

function var_0_0.getHeroDialog(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_HERO_DIALOG, var_15_0, function(arg_16_0, arg_16_1)
		if arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.buyGift(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.BUY_GIFT, var_17_0, function(arg_18_0, arg_18_1)
		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.addFavor(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.ADD_FAVOR, var_19_0, function(arg_20_0, arg_20_1)
		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.getPartnerMission(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_PARTNER_MISSION, var_21_0, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			-- block empty
		end

		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.getTalkAward(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_HERO_TALK_AWARD, var_23_0, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			-- block empty
		end

		if arg_23_2 then
			arg_23_2(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.getActAward(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_HERO_ACT_AWARD, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			-- block empty
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.getPartnerAct(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_HERO_ACT, var_27_0, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			-- block empty
		end

		if arg_27_2 then
			arg_27_2(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.getMissionAward(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_HERO_MISSION_AWARD, var_29_0, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			-- block empty
		end

		if arg_29_2 then
			arg_29_2(arg_30_0, arg_30_1)
		end
	end)
end

function var_0_0.acceptHeroMission(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = arg_31_1 or {}

	xyd.Backend.get():request(xyd.mid.ACCEPT_HERO_MISSION, var_31_0, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			-- block empty
		end

		if arg_31_2 then
			arg_31_2(arg_32_0, arg_32_1)
		end
	end)
end

function var_0_0.abandonMission(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_1 or {}

	xyd.Backend.get():request(xyd.mid.ABANDON_MISSION, var_33_0, function(arg_34_0, arg_34_1)
		if arg_34_0 == xyd.error.OK then
			-- block empty
		end

		if arg_33_2 then
			arg_33_2(arg_34_0, arg_34_1)
		end
	end)
end

function var_0_0.initTalkOPenList(arg_35_0)
	arg_35_0.talkOpenList = {}

	for iter_35_0, iter_35_1 in pairs(arg_35_0.talkInfo) do
		arg_35_0.talkOpenList[tonumber(iter_35_0)] = arg_35_0:isTalkOpen(tonumber(iter_35_0))
	end
end

function var_0_0.isTalkOpen(arg_36_0, arg_36_1)
	local var_36_0 = xyd.tables.libraryTalkTable:getUnlockConditionTypes(arg_36_1)
	local var_36_1 = xyd.tables.libraryTalkTable:getUnlockHero(arg_36_1)
	local var_36_2 = xyd.tables.libraryTalkTable:getUnlockParam(arg_36_1)

	for iter_36_0 = 1, #var_36_0 do
		if var_36_0[iter_36_0] == xyd.SchoolStoryUnlockConditionTypes.ownHero and var_36_1[iter_36_0] and var_36_1[iter_36_0] > 0 then
			if not arg_36_0.selfPlayer:getHeroIgnoreAwaken(var_36_1[iter_36_0]) then
				return false
			end
		elseif var_36_0[iter_36_0] == xyd.SchoolStoryUnlockConditionTypes.heroLev then
			local var_36_3 = arg_36_0.selfPlayer:getHeroIgnoreAwaken(var_36_1[iter_36_0])

			if not var_36_3 or var_36_3:getLevel() < var_36_2[iter_36_0] then
				return false
			end
		elseif var_36_0[iter_36_0] == xyd.SchoolStoryUnlockConditionTypes.playerLev then
			if arg_36_0.selfPlayer.lev < var_36_2[iter_36_0] then
				return false
			end
		elseif var_36_0[iter_36_0] == xyd.SchoolStoryUnlockConditionTypes.nomalChapter and arg_36_0.selfPlayer.normal_chapter_id <= var_36_2[iter_36_0] then
			return false
		end
	end

	return true
end

function var_0_0.isLibraryRedPointShow(arg_37_0)
	arg_37_0.selfPlayer:getLibraryInfos(function()
		return arg_37_0:isSchoolStoryRedPointShow() or arg_37_0:isMemoryCollectRedPointShow()
	end)
end

function var_0_0.isSchoolStoryRedPointShow(arg_39_0, ...)
	for iter_39_0 = 1, xyd.tables.libraryTalkTable:getStoryTotalNum() do
		if arg_39_0:isStoryItemRedPointShow(iter_39_0) then
			return true
		end
	end

	return false
end

function var_0_0.isStoryItemRedPointShow(arg_40_0, arg_40_1)
	arg_40_0:initTalkOPenList()

	local var_40_0 = xyd.tables.libraryTalkTable:getTalkIdsByIdPrefix(arg_40_1)

	for iter_40_0 = 1, #var_40_0 do
		if arg_40_0.talkOpenList[var_40_0[iter_40_0]] and arg_40_0.talkInfo[tostring(var_40_0[iter_40_0])] == 0 then
			return true
		end
	end

	return false
end

function var_0_0.isMemoryCollectRedPointShow(arg_41_0)
	arg_41_0:initMemoryCollectInfoList()

	for iter_41_0 = 1, #arg_41_0.memoryCollectOpenList do
		if arg_41_0.memoryCollectOpenList[iter_41_0] and arg_41_0.memoryCollectInfo[iter_41_0] == 0 then
			return true
		end
	end

	return false
end

function var_0_0.isMemoryCollectItemRedPointShow(arg_42_0, arg_42_1)
	return arg_42_0.memoryCollectOpenList[arg_42_1] and arg_42_0.memoryCollectInfo[arg_42_1] == 0
end

function var_0_0.getMemoryCollectItemInfo(arg_43_0, arg_43_1)
	return arg_43_0.memoryCollectOpenList[arg_43_1], arg_43_0.memoryCollectInfoList[arg_43_1]
end

function var_0_0.initMemoryCollectInfoList(arg_44_0)
	arg_44_0.memoryCollectInfoList = {}
	arg_44_0.memoryCollectOpenList = {}

	local var_44_0 = xyd.tables.libraryCG

	for iter_44_0 = 1, #var_44_0:getIDs() do
		local var_44_1 = var_44_0:getUnlockIDs(iter_44_0)
		local var_44_2 = var_44_0:getUnlockTypes(iter_44_0)
		local var_44_3 = {}
		local var_44_4 = true

		for iter_44_1 = 1, #var_44_1 do
			local var_44_5

			if var_44_2[iter_44_1] == 1 then
				var_44_5 = arg_44_0.selfPlayer:isHaveSkin(var_44_1[iter_44_1])
			elseif var_44_2[iter_44_1] == 2 then
				var_44_5 = arg_44_0.selfPlayer:getHeroIgnoreAwaken(var_44_1[iter_44_1]) and true or false
			elseif var_44_2[iter_44_1] == 3 then
				var_44_5 = arg_44_0.selfPlayer:getHeroByTableID(var_44_1[iter_44_1]) and true or false
			end

			var_44_4 = var_44_4 and var_44_5

			table.insert(var_44_3, var_44_5)
		end

		arg_44_0.memoryCollectInfoList[iter_44_0] = var_44_3
		arg_44_0.memoryCollectOpenList[iter_44_0] = var_44_4
	end
end

function var_0_0.getMemoryCollectAward(arg_45_0, arg_45_1, arg_45_2)
	xyd.Backend.get():request(xyd.mid.GET_CG_AWARD, {
		index = arg_45_1
	}, function(arg_46_0, arg_46_1)
		if arg_46_0 == xyd.error.OK then
			if arg_46_1.awards then
				arg_45_0.selfPlayer:handleRewards(arg_46_1.awards)
			end

			if arg_45_2 then
				arg_45_2()
			end
		end
	end)
end

function var_0_0.unlockLibraryBG(arg_47_0, arg_47_1, arg_47_2)
	xyd.Backend.get():request(xyd.mid.UNLOCK_BG, arg_47_1, function(arg_48_0, arg_48_1)
		if arg_48_0 == xyd.error.OK and arg_47_2 then
			arg_47_2()
		end
	end)
end

function var_0_0.setLibraryBG(arg_49_0, arg_49_1, arg_49_2)
	xyd.Backend.get():request(xyd.mid.SET_BG, arg_49_1, function(arg_50_0, arg_50_1)
		if arg_50_0 == xyd.error.OK and arg_49_2 then
			arg_49_2()
		end
	end)
end

function var_0_0.isDialogRedPointShow(arg_51_0, arg_51_1)
	if not arg_51_0.libraryInfos[arg_51_1:getHeroID()] or not arg_51_0.libraryInfos[arg_51_1:getHeroID()].partner_dialogs then
		return false
	end

	local var_51_0 = arg_51_0.libraryInfos[arg_51_1:getHeroID()].partner_dialogs

	for iter_51_0 = 1, #var_51_0 do
		if var_51_0[iter_51_0].is_read == 0 then
			return true
		end
	end

	return false
end

function var_0_0.isMissionRedPointShow(arg_52_0, arg_52_1)
	if not arg_52_0.libraryInfos[arg_52_1:getHeroID()] or not arg_52_0.libraryInfos[arg_52_1:getHeroID()].partner_missions then
		return false
	end

	local var_52_0 = arg_52_0.libraryInfos[arg_52_1:getHeroID()].partner_missions

	for iter_52_0 = 1, #var_52_0 do
		if var_52_0[iter_52_0].mission_state == xyd.LibraryMissionState.SUCCESS then
			return true
		end
	end

	return false
end

function var_0_0.isVisitRedPointShow(arg_53_0, arg_53_1)
	return arg_53_0:isDialogRedPointShow(arg_53_1) or arg_53_0:isMissionRedPointShow(arg_53_1)
end

function var_0_0.getSchoolStoryReward(arg_54_0, arg_54_1, arg_54_2)
	local var_54_0 = arg_54_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_SCHOOL_STORY_REWARD, var_54_0, function(arg_55_0, arg_55_1)
		if arg_54_2 then
			arg_54_2(arg_55_0, arg_55_1)
		end
	end)
end

function var_0_0.heroFeed(arg_56_0, arg_56_1, arg_56_2)
	local var_56_0 = arg_56_1 or {}

	xyd.Backend.get():request(xyd.mid.HERO_FEED, var_56_0, function(arg_57_0, arg_57_1)
		if arg_56_2 then
			arg_56_2(arg_57_0, arg_57_1)
		end
	end)
end

function var_0_0.getFeedInfo(arg_58_0, arg_58_1, arg_58_2)
	local var_58_0 = arg_58_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_FEED_INFO, var_58_0, function(arg_59_0, arg_59_1)
		if arg_58_2 then
			arg_58_2(arg_59_0, arg_59_1)
		end
	end)
end

function var_0_0.saveHeroFeed(arg_60_0, arg_60_1, arg_60_2)
	local var_60_0 = arg_60_1 or {}

	xyd.Backend.get():request(xyd.mid.SAVE_HERO_FEED, var_60_0, function(arg_61_0, arg_61_1)
		if arg_60_2 then
			arg_60_2(arg_61_0, arg_61_1)
		end
	end)
end

function var_0_0.formatDifficultyText(arg_62_0, arg_62_1, arg_62_2)
	local var_62_0 = xyd.split(var_0_1:translation("LIBRARY_MISSION_LEVEL"), ",")
	local var_62_1 = xyd.tables.libraryMission:difficulty(arg_62_2)

	arg_62_1:setString("(" .. var_62_0[var_62_1] .. ")")

	local var_62_2

	if var_62_1 == 1 then
		var_62_2 = cc.c3b(100, 222, 128)
	elseif var_62_1 == 2 then
		var_62_2 = cc.c3b(117, 106, 109)
	elseif var_62_1 == 3 then
		var_62_2 = cc.c3b(248, 63, 64)
	end

	arg_62_1:setColor(var_62_2)
	arg_62_1:enableShadow()
end

function var_0_0.playDialog(arg_63_0, arg_63_1, arg_63_2)
	local var_63_0 = {
		hero = arg_63_1,
		dialog = arg_63_2
	}

	if xyd.WindowManager.get():isWindowOpen("hero_talk_wnd") then
		xyd.WindowManager.get():closeWindow("hero_talk_wnd")
	end

	xyd.WindowManager.get():openWindow("hero_talk_wnd", var_63_0)
end

function var_0_0.getSendGiftDialogId(arg_64_0, arg_64_1, arg_64_2)
	local var_64_0 = arg_64_1:getFirstTableID()
	local var_64_1 = xyd.tables.hero:giftLikeType(var_64_0)
	local var_64_2 = xyd.tables.hero:giftDislikeType(var_64_0)
	local var_64_3 = xyd.tables.libraryGift:getItemLikeType(arg_64_2)

	if var_64_1 == var_64_3 then
		return 17
	elseif var_64_2 == var_64_3 then
		return 19
	else
		return 18
	end
end

function var_0_0.freshSingleMission(arg_65_0, arg_65_1)
	local var_65_0 = arg_65_1.mission_info
	local var_65_1 = arg_65_1.partner_id
	local var_65_2 = arg_65_1.favor
	local var_65_3 = arg_65_0.selfPlayer:getHero(var_65_1)

	if var_65_2 and var_65_3 and var_65_2 > var_65_3:getFavorDegree() then
		var_65_3:setFavorDegree(var_65_2)
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REFRESH_FAVOR_INFO
		})
	end

	if not arg_65_0.libraryInfos or not arg_65_0.libraryInfos[var_65_1] then
		return
	end

	local var_65_4 = arg_65_0.libraryInfos[var_65_1].partner_missions

	if not var_65_0 or not var_65_4 then
		return
	end

	for iter_65_0 = 1, #var_65_4 do
		if var_65_4[iter_65_0].mission_id == var_65_0.mission_id then
			var_65_4[iter_65_0] = var_65_0
		end
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_HERO_VISIT_REDPOINT
	})

	local var_65_5 = xyd.WindowManager.get():getWindow("hero_task_main")

	if var_65_5 and not tolua.isnull(var_65_5) then
		var_65_5.taskList:reload()
	end
end

function var_0_0.freshSingleDialog(arg_66_0, arg_66_1, arg_66_2)
	if not arg_66_0.libraryInfos or not arg_66_0.libraryInfos[arg_66_2] then
		return
	end

	local var_66_0 = arg_66_0.libraryInfos[arg_66_2].partner_dialogs

	if not arg_66_1 or not var_66_0 then
		return
	end

	local var_66_1 = 0

	for iter_66_0 = 1, #var_66_0 do
		if var_66_0[iter_66_0].dialog_id == arg_66_1.dialog_id then
			var_66_1 = iter_66_0

			break
		end
	end

	local var_66_2 = 1

	while var_66_0[var_66_2] and var_66_0[var_66_2].dialog_id > arg_66_1.dialog_id do
		var_66_2 = var_66_2 + 1
	end

	if var_66_1 > 0 then
		var_66_0[var_66_1] = arg_66_1
	else
		table.insert(var_66_0, var_66_2, arg_66_1)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_HERO_VISIT_REDPOINT
	})

	local var_66_3 = xyd.WindowManager.get():getWindow("hero_task_main")

	if var_66_3 and not tolua.isnull(var_66_3) then
		var_66_3.taskList:reload()
	end
end

function var_0_0.insertNewPartnerInfo(arg_67_0, arg_67_1, arg_67_2)
	arg_67_0.libraryInfos[arg_67_2] = arg_67_1
end

function var_0_0.freshPartnerLog(arg_68_0, arg_68_1, arg_68_2)
	if not arg_68_1 or not arg_68_2 or not arg_68_0.libraryInfos or not arg_68_0.libraryInfos[arg_68_2] then
		return
	end

	arg_68_0.libraryInfos[arg_68_2].partner_logs = arg_68_1

	local var_68_0 = arg_68_0.cardState
	local var_68_1 = xyd.WindowManager.get():getWindow("tujian_herodetail")

	if var_68_1 then
		var_68_1:update()
	end

	arg_68_0.cardState = var_68_0

	local var_68_2 = xyd.WindowManager.get():getWindow("favor_wnd")

	if var_68_2 then
		var_68_2:update()
	end
end

function var_0_0.getPartnerMissions(arg_69_0, arg_69_1)
	local var_69_0 = arg_69_0.libraryInfos[arg_69_1:getHeroID()].partner_missions
	local var_69_1 = {}

	for iter_69_0 = 1, #var_69_0 do
		if arg_69_0:isMissionOpen(var_69_0[iter_69_0].mission_id) then
			table.insert(var_69_1, var_69_0[iter_69_0])
		end
	end

	return var_69_1
end

function var_0_0.isMissionOpen(arg_70_0, arg_70_1)
	if arg_70_0.selfPlayer.lev >= xyd.tables.libraryMission:openLev(arg_70_1) then
		return true
	end

	return false
end

function var_0_0.updateCardContainer(arg_71_0, arg_71_1, arg_71_2, arg_71_3)
	local var_71_0 = arg_71_1:getSkinDatas()

	arg_71_3 = arg_71_3 or arg_71_0:getInitSkinIndex(arg_71_1)

	local var_71_1, var_71_2, var_71_3 = arg_71_0:getCardIDInfoBaseOnCardState(arg_71_1, arg_71_3)
	local var_71_4, var_71_5 = xyd.getTransparentCard(arg_71_1, xyd.SkinDynamicPosType.VISIT)

	if not var_71_4 then
		return
	end

	if not xyd.isShowDynamicCard(arg_71_1) then
		var_71_4:setPosition(var_71_2, var_71_3)
	end

	arg_71_2:removeAllChildren()
	arg_71_2:addChild(var_71_4)
	var_71_4:setAnchorPoint(cc.p(0.5, 0))
	var_71_4:setPosition(cc.p(arg_71_2:getContentSize().width / 2 + var_71_2, var_71_3))
	var_71_4:setTouchEnabled(false)
	var_71_4:setName("card")

	return var_71_5
end

function var_0_0.getCardIDInfoBaseOnCardState(arg_72_0, arg_72_1, arg_72_2)
	local var_72_0 = arg_72_1:getSkinDatas()

	arg_72_2 = arg_72_2 or arg_72_0:getInitSkinIndex(arg_72_1)

	local var_72_1 = var_72_0[arg_72_2] or var_72_0[1]
	local var_72_2 = xyd.tables.libraryHomeCard:x(var_72_1.modelID)
	local var_72_3 = xyd.tables.libraryHomeCard:y(var_72_1.modelID)

	return var_72_1.modelID, var_72_2, var_72_3
end

function var_0_0.getInitSkinIndex(arg_73_0, arg_73_1)
	local var_73_0 = arg_73_1:getSkinDatas()

	if not arg_73_1.illusionSkinId_ then
		return skinIndex
	end

	if arg_73_1.illusionSkinId_ <= 1 then
		return arg_73_1.illusionSkinId_ + 1
	else
		for iter_73_0 = 2, #var_73_0 do
			local var_73_1 = var_73_0[iter_73_0]

			if var_73_1.isHave and var_73_1.cardState == xyd.CardStatus.SKIN_CARD and arg_73_1.illusionSkinId_ == var_73_1.modelID then
				return iter_73_0
			end
		end
	end

	return skinIndex
end

function var_0_0.refreshPartnersFavor(arg_74_0, arg_74_1)
	for iter_74_0, iter_74_1 in pairs(arg_74_1 or {}) do
		arg_74_0.selfPlayer:getHero(tonumber(iter_74_0)):setFavorDegree(iter_74_1)
	end
end

return var_0_0
