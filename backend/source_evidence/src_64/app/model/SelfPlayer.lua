local var_0_0 = class("SelfPlayer", import(".Player"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.hasLogin_ = false
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.ECONOMY, handler(arg_2_0, arg_2_0.economySyncEvent_))
	arg_2_0:registerEvent(xyd.event.HERO_UPDATE, handler(arg_2_0, arg_2_0.heroUpdateEvent_))
	arg_2_0:registerEvent(xyd.event.WORLD_MAP, handler(arg_2_0, arg_2_0.worldMapEvent_))
	arg_2_0:registerEvent(xyd.event.BATTLE_ENDED, handler(arg_2_0, arg_2_0.battleEndedEvent_))
	arg_2_0:registerEvent(xyd.event.SELL_ITEM, handler(arg_2_0, arg_2_0.onSellItem_))
	arg_2_0:registerEvent(xyd.event.RECHARGE, handler(arg_2_0, arg_2_0.onRecharge_))
	arg_2_0:registerEvent(xyd.event.RELOAD, handler(arg_2_0, arg_2_0.reloadEvent_))
	arg_2_0:registerEvent(xyd.event.TRIAL_INFOS, handler(arg_2_0, arg_2_0.trialInfosEvent_))
	arg_2_0:registerEvent(xyd.event.PLAYER_NOTICE, handler(arg_2_0, arg_2_0.onPlayerNotice_))
	arg_2_0:registerEvent(xyd.event.LOAD_BACKPACK, handler(arg_2_0, arg_2_0.onBackpackEvent_))
	arg_2_0:registerEvent(xyd.event.NEW_FUNC_OPEN, handler(arg_2_0, arg_2_0.onNewFuncOpen))
	arg_2_0:registerEvent(xyd.event.HERO_EQUIP_UPDATE, handler(arg_2_0, arg_2_0.onHeroEquipRefresh_))
	arg_2_0:registerEvent(xyd.event.MAP_DETAIL_UPDATE, handler(arg_2_0, arg_2_0.onMapDetailRefresh_))
	arg_2_0:registerEvent(xyd.event.UPDATE_STONE_EQUIP_CAMPAIGN, handler(arg_2_0, arg_2_0.onUpdateStoneEquipCampaign_))
	arg_2_0:registerEvent(cc.mvc.AppBase.APP_ENTER_FOREGROUND_EVENT, handler(arg_2_0, arg_2_0.onUpdateSysTime_))
	arg_2_0:registerEvent(xyd.event.PLAYER_LEVEL_UP, handler(arg_2_0, arg_2_0.onUpdateActivitiesState_))
	arg_2_0:registerEvent(xyd.event.TREASURE_LOAD_SP_INFO, handler(arg_2_0, arg_2_0.onTreasuerLoadSPInfo_))
	arg_2_0:registerEvent(xyd.event.TREASURE_BUY_SP, handler(arg_2_0, arg_2_0.onTreasuerLoadSPInfo_))
	arg_2_0:registerEvent(xyd.event.TOKEN, handler(arg_2_0, arg_2_0.loginEvent_))
	arg_2_0:registerEvent(xyd.event.SYSTEM_BROADCAST, handler(arg_2_0, arg_2_0.systemBroadCastEvent_))
	arg_2_0:registerEvent(xyd.event.WORLD_NOTICE, handler(arg_2_0, arg_2_0.worldNoticeEvent_))
end

function var_0_0.reloadEvent_(arg_3_0, arg_3_1)
	if arg_3_1.params.friend_list == 1 then
		print("SelfPlayer:reloadEvent_")

		arg_3_0.friendRepHeroLoaded_ = false
	end
end

function var_0_0.loadUsedPartners(arg_4_0, arg_4_1)
	xyd.Backend.get():request(xyd.mid.LOAD_USED_PARTNER, nil, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			arg_4_0.usedPartners = arg_5_1.used_partners

			if arg_4_1 then
				arg_4_1(arg_4_0.usedPartners)
			else
				arg_4_1({})
			end
		end
	end)
end

function var_0_0.addBattleAward(arg_6_0, arg_6_1)
	if arg_6_1 == nil then
		return
	end

	for iter_6_0, iter_6_1 in ipairs(arg_6_1.exp or {}) do
		local var_6_0 = iter_6_1.partner_id
		local var_6_1 = arg_6_0:getHeroByID(var_6_0)

		if var_6_1 ~= nil then
			var_6_1:addExp(iter_6_1.exp or 0)
		end
	end

	local var_6_2 = arg_6_1.drop

	if var_6_2 ~= nil then
		local var_6_3 = var_6_2.item_type
		local var_6_4 = var_6_2.item

		if var_6_3 == xyd.ItemType.RUNE then
			if arg_6_0:getRuneBag() ~= nil then
				arg_6_0:getRuneBag():addRuneWithRuneInfo(var_6_4)
			end
		elseif var_6_3 == xyd.ItemType.HERO then
			arg_6_0:addHeroWithHeroInfo(var_6_4)
		elseif var_6_3 == xyd.ItemType.SCROLL then
			local var_6_5 = var_6_4.table_id
			local var_6_6 = var_6_4.num

			if arg_6_0.scrolls_ ~= nil and var_6_6 > 0 then
				arg_6_0.scrolls_[var_6_5] = (arg_6_0.scrolls_[var_6_5] or 0) + var_6_6
			end
		elseif var_6_3 == xyd.ItemType.ESSENCE then
			local var_6_7 = var_6_4.table_id
			local var_6_8 = var_6_4.num

			if arg_6_0.essences_ ~= nil and var_6_8 > 0 then
				arg_6_0.essences_[var_6_7] = (arg_6_0.essences_[var_6_7] or 0) + var_6_8
			end
		end
	end
end

function var_0_0.setPressHero(arg_7_0, arg_7_1, arg_7_2)
	arg_7_0.hasPressHero = arg_7_1
	arg_7_0.hasChangeSkill = arg_7_2
end

function var_0_0.setPetGuideId(arg_8_0)
	if arg_8_0.petGuideId == 0 then
		arg_8_0.petGuideId = 1
	else
		arg_8_0.petGuideId = arg_8_0.petGuideId + 1
	end
end

function var_0_0.onPlayerInfo_(arg_9_0, arg_9_1)
	if arg_9_0.playerID ~= nil and arg_9_0.playerID ~= tonumber(arg_9_1.params.player_id) then
		return
	end

	arg_9_0.playerEvent = arg_9_1

	var_0_0.super.populate(arg_9_0, arg_9_1.params)

	arg_9_0.exp = arg_9_1.params.exp
	arg_9_0.expMulti = arg_9_1.params.boss_incr_exp or 1
	arg_9_0.lev = arg_9_1.params.lev or 1
	arg_9_0.uid = arg_9_1.params.uid
	arg_9_0.mana = arg_9_1.params.mana
	arg_9_0.region = arg_9_1.params.region
	arg_9_0.regionName = arg_9_1.params.region_name
	arg_9_0.crystal = arg_9_1.params.crystal
	arg_9_0.luckyCoin = arg_9_1.params.lucky_coin
	arg_9_0.arena_coin = arg_9_1.params.arena_coin
	arg_9_0.march_coin = arg_9_1.params.march_coin
	arg_9_0.top_coin = arg_9_1.params.top_coin
	arg_9_0.guild_coin = arg_9_1.params.guild_coin
	arg_9_0.region_coin = arg_9_1.params.region_coin
	arg_9_0.kingCoin = arg_9_1.params.king_coin
	arg_9_0.honorCoin = arg_9_1.params.honor_coin or 0
	arg_9_0.academyCoin = arg_9_1.params.god_war_coin or 0
	arg_9_0.friendshipCoin = arg_9_1.params.friendship_coin or 0
	arg_9_0.friendMedal = arg_9_1.params.friend_medal or 0
	arg_9_0.summonCoin = arg_9_1.params.summon_coin or 0
	arg_9_0.skinFragment = arg_9_1.params.skin_fragment or 0
	arg_9_0.glue = arg_9_1.params.glue or 0
	arg_9_0.buyGlueTimes = arg_9_1.params.buy_glue_times or 0
	arg_9_0.lvbuCoin = arg_9_1.params.lvbu_coin
	arg_9_0.illusionCoin = arg_9_1.params.paradise_coin or 0
	arg_9_0.teamDungeonCoin = arg_9_1.params.team_dungeon_coin or 0
	arg_9_0.iceCore = arg_9_1.params.ice_core or 0
	arg_9_0.spiritStone = arg_9_1.params.spirit_stone
	arg_9_0.energy = arg_9_1.params.energy
	arg_9_0.spiritEnergy = arg_9_1.params.spirit_energy
	arg_9_0.invitation = arg_9_1.params.invitation
	arg_9_0.social = arg_9_1.params.social
	arg_9_0.lastEnergy = arg_9_1.params.energy_time
	arg_9_0.lastSpiritEnergy = arg_9_1.params.spirit_energy_time
	arg_9_0.lastInvitation = arg_9_1.params.invitation_time or 0
	arg_9_0.maxEnergy = arg_9_1.params.max_energy
	arg_9_0.maxInvitation = arg_9_1.params.max_invitation
	arg_9_0.glory = arg_9_1.params.glory
	arg_9_0.vip = arg_9_1.params.vip
	arg_9_0.buyManaTimes = arg_9_1.params.buy_mana_times
	arg_9_0.buyEnergyTimes = arg_9_1.params.buy_energy_times
	arg_9_0.buySpiritEnergyTimes = arg_9_1.params.buy_spirit_energy_times
	arg_9_0.buySkillTimes = arg_9_1.params.buy_skill_times

	xyd.StoryData.get():onDataFromBackend(arg_9_1.params)

	arg_9_0.funcIDs = arg_9_1.params.func_ids
	arg_9_0.skillPoint = tonumber(arg_9_1.params.skill_point)
	arg_9_0.lastSkillPoint = arg_9_1.params.skill_time
	arg_9_0.formation = arg_9_1.params.formation
	arg_9_0.playerName = arg_9_1.params.player_name
	arg_9_0.avatarId = arg_9_1.params.avatar_id
	arg_9_0.playerType = arg_9_1.params.player_type or 0
	arg_9_0.arenaBeatFlag = arg_9_1.params.arena_beat_flag
	arg_9_0.monthCardStart = arg_9_1.params.month_card_start or 0
	arg_9_0.monthCardEnd = arg_9_1.params.month_card_end or 0
	arg_9_0.privilegeLeftCardDay = arg_9_1.params.privilege_left_card_day or 0
	arg_9_0.privilegeLeftCardEnd = arg_9_1.params.privilege_month_card_end or 0
	arg_9_0.leftCardDay = arg_9_1.params.left_card_day or 0
	arg_9_0.leftWeekCardDay = arg_9_1.params.left_week_card_day or 0
	arg_9_0.leftEnergyMonthCardDay = arg_9_1.params.left_month_tili_day or 0
	arg_9_0.charge = arg_9_1.params.charge or 0
	arg_9_0.isComment = arg_9_1.params.is_commented or 1
	arg_9_0.commentOpen = arg_9_1.params.comment_open or 0
	arg_9_0.fbShareOpen = arg_9_1.params.fbshare_open or 0
	arg_9_0.guildID = arg_9_1.params.guild_id or 0
	arg_9_0.maxTeamLev = arg_9_1.params.max_lev or 0
	arg_9_0.maxHeroColor = arg_9_1.params.max_color or 0
	arg_9_0.mainSceneType = arg_9_1.params.main_scene_type or 0
	arg_9_0.saveTeam = arg_9_1.params.save_team
	arg_9_0.saveTeamName = arg_9_1.params.save_team_name
	arg_9_0.savePet = arg_9_1.params.save_pet
	arg_9_0.magicEnergy = arg_9_1.params.magic_energy or 0
	arg_9_0.magicDust = arg_9_1.params.magic_dust or 0
	arg_9_0.magicLiquid = arg_9_1.params.magic_liquid or 0
	arg_9_0.magicExp = arg_9_1.params.magic_exp or 0
	arg_9_0.degreeCer = arg_9_1.params.degree_cer or 0
	arg_9_0.graduateCer = arg_9_1.params.graduate_cer or 0
	arg_9_0.patentCer = arg_9_1.params.patent_cer or 0
	arg_9_0.titleInfo = arg_9_1.params.title_info or {}
	arg_9_0.avatarFrame = arg_9_1.params.avatar_frame_id or 0
	arg_9_0.vipAwards = arg_9_1.params.vip_awards or {}
	arg_9_0.conquerLev = arg_9_1.params.conquer_lev or 0
	arg_9_0.conquerLoopID = arg_9_1.params.conquer_loop_id or 1
	arg_9_0.conquerRegion = arg_9_1.params.conquer_region or 0
	arg_9_0.farthestAwakeCampaignID = 0

	arg_9_0:getMessagePush():update(arg_9_1.params.message_pushes or {})

	arg_9_0.firstMainTouch = arg_9_1.params.first_main_touch or 0
	arg_9_0.occultTicket = arg_9_1.params.occult_ticket or 0
	arg_9_0.tutorCoin = arg_9_1.params.tutor_coin or 0
	arg_9_0.skinCoin = arg_9_1.params.skin_coin or 0
	arg_9_0.bubbleInfo = arg_9_1.params.bubble_info or {
		end_time = 0,
		bubble_id = xyd.tables.misc:getValue("default_bubble")
	}
	arg_9_0.crabTimes = arg_9_1.params.crab_times or 0
	arg_9_0.guideFuncList = arg_9_1.params.guide_function_ids or {}
	arg_9_0.reloadGuideID = arg_9_1.params.guide_return_id or 0
	arg_9_0.hasLogin_ = true
	arg_9_0.auctionMsgs = {}
	arg_9_0.auctionBroadcasting = false

	arg_9_0:genOpenFuncMap()

	if not arg_9_0.avatarId or arg_9_0.avatarId == 0 then
		arg_9_0.avatarId = xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
	end

	if not arg_9_0.avatarFrame or arg_9_0.avatarFrame == 0 then
		arg_9_0.avatarFrame = xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId]
	end

	if arg_9_1.params.buff_exp then
		arg_9_0.expTime = arg_9_1.params.buff_exp.start_time + arg_9_1.params.buff_exp.duration
	end

	while arg_9_0.exp >= arg_9_0:getExpLimit() do
		arg_9_0.lev = arg_9_0.lev + 1

		if arg_9_0.lev >= arg_9_0.maxTeamLev then
			break
		end
	end

	arg_9_0.petGuideId = 0

	arg_9_0:getAlbumAttrInfo()
end

function var_0_0.getExpMulti(arg_10_0)
	return 3
end

function var_0_0.genOpenFuncMap(arg_11_0)
	if not arg_11_0.funcIDs or not next(arg_11_0.funcIDs) then
		return
	end

	arg_11_0.openFuncMap = {}

	for iter_11_0, iter_11_1 in pairs(arg_11_0.funcIDs) do
		local var_11_0 = tonumber(iter_11_1) or 0

		if var_11_0 > 0 then
			arg_11_0.openFuncMap[var_11_0] = true
		else
			print("error!, v is " .. iter_11_1)
		end
	end
end

function var_0_0.isFuncOpen(arg_12_0, arg_12_1)
	if arg_12_0.openFuncMap and next(arg_12_0.openFuncMap) and arg_12_0.openFuncMap[arg_12_1] == true then
		return true
	else
		return false
	end
end

function var_0_0.loadWorldMap(arg_13_0, arg_13_1)
	if arg_13_0.worldMapLoaded_ then
		if arg_13_1 then
			arg_13_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_WORLD_MAP, nil, function(arg_14_0, arg_14_1, arg_14_2)
			if arg_14_0 == xyd.error.OK then
				arg_13_0.worldMapLoaded_ = true
			end

			if arg_13_1 then
				arg_13_1(arg_14_0)
			end
		end)
	end
end

function var_0_0.worldMapEvent_(arg_15_0, arg_15_1)
	if not arg_15_0.worldMaps_ then
		arg_15_0.worldMaps_ = {}
	end

	for iter_15_0, iter_15_1 in pairs(arg_15_1.params.normal) do
		local var_15_0 = tonumber(iter_15_1.campaign_id)

		if var_15_0 then
			arg_15_0.worldMaps_[var_15_0] = {}
			arg_15_0.worldMaps_[var_15_0].star = tonumber(iter_15_1.star)
			arg_15_0.worldMaps_[var_15_0].dailyLimit = tonumber(iter_15_1.daily_limit)
			arg_15_0.worldMaps_[var_15_0].resetCount = tonumber(iter_15_1.reset_count)
			arg_15_0.worldMaps_[var_15_0].is_partner_drop = tonumber(iter_15_1.is_partner_drop)
		end
	end

	for iter_15_2, iter_15_3 in pairs(arg_15_1.params.super) do
		local var_15_1 = tonumber(iter_15_3.campaign_id)

		if var_15_1 then
			arg_15_0.worldMaps_[var_15_1] = {}
			arg_15_0.worldMaps_[var_15_1].star = tonumber(iter_15_3.star)
			arg_15_0.worldMaps_[var_15_1].dailyLimit = tonumber(iter_15_3.daily_limit)
			arg_15_0.worldMaps_[var_15_1].resetCount = tonumber(iter_15_3.reset_count)
		end
	end

	for iter_15_4, iter_15_5 in pairs(arg_15_1.params.challenge) do
		local var_15_2 = tonumber(iter_15_5.campaign_id)

		if var_15_2 then
			arg_15_0.worldMaps_[var_15_2] = {}
			arg_15_0.worldMaps_[var_15_2].star = tonumber(iter_15_5.star)
			arg_15_0.worldMaps_[var_15_2].dailyLimit = tonumber(iter_15_5.daily_limit)
			arg_15_0.worldMaps_[var_15_2].resetCount = tonumber(iter_15_5.reset_count)
		end
	end

	if not arg_15_0.chapterEvents then
		arg_15_0.chapterEvents = {}
	end

	for iter_15_6, iter_15_7 in pairs(arg_15_1.params.chapter_events or {}) do
		arg_15_0.chapterEvents[iter_15_7.chapter_id] = iter_15_7
	end

	local var_15_3 = arg_15_1.params.chapter_info

	arg_15_0.normal_chapter_id = var_15_3.normal_chapter_id
	arg_15_0.normal_campaign_id = var_15_3.normal_campaign_id
	arg_15_0.super_chapter_id = var_15_3.super_chapter_id
	arg_15_0.super_campaign_id = var_15_3.super_campaign_id
	arg_15_0.normal_stars = var_15_3.normal_stars
	arg_15_0.normal_bonus_id = var_15_3.normal_bonus_id
	arg_15_0.super_stars = var_15_3.super_stars
	arg_15_0.super_bonus_id = var_15_3.super_bonus_id
end

function var_0_0.worldMapLoginEvent_(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_1.params

	arg_16_0.normal_chapter_id = var_16_0.normal_chapter_id
	arg_16_0.normal_campaign_id = var_16_0.normal_campaign_id
	arg_16_0.super_chapter_id = var_16_0.super_chapter_id
	arg_16_0.super_campaign_id = var_16_0.super_campaign_id
	arg_16_0.normal_stars = var_16_0.normal_stars
	arg_16_0.normal_bonus_id = var_16_0.normal_bonus_id
	arg_16_0.super_stars = var_16_0.super_stars
	arg_16_0.super_bonus_id = var_16_0.super_bonus_id
end

function var_0_0.handleChapterEvent(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_1.chapter_event

	if var_17_0 and var_17_0.chapter_id then
		if not arg_17_0.chapterEvents then
			arg_17_0.chapterEvents = {}
		end

		if not arg_17_0.chapterEvents[var_17_0.chapter_id] then
			var_17_0.is_new = true
		end

		arg_17_0.chapterEvents[var_17_0.chapter_id] = var_17_0
	end
end

function var_0_0.loadTrialInfos(arg_18_0, arg_18_1)
	if arg_18_0.trialLoaded_ then
		if arg_18_1 then
			arg_18_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_TRIAL_INFOS, nil, function(arg_19_0, arg_19_1, arg_19_2)
			if arg_18_1 then
				arg_18_1(arg_19_0)
			end
		end)
	end
end

function var_0_0.trialInfosEvent_(arg_20_0, arg_20_1)
	arg_20_0.trialInfos_ = {}

	for iter_20_0, iter_20_1 in pairs(arg_20_1.params.trial_info.trials) do
		local var_20_0 = tonumber(iter_20_1.id)

		if var_20_0 then
			arg_20_0.trialInfos_[var_20_0] = {}
			arg_20_0.trialInfos_[var_20_0].id = tonumber(iter_20_1.id)
			arg_20_0.trialInfos_[var_20_0].leftTimes = tonumber(iter_20_1.left_times)
			arg_20_0.trialInfos_[var_20_0].isOpen = tonumber(iter_20_1.is_open)
			arg_20_0.trialInfos_[var_20_0].maxTimes = tonumber(iter_20_1.max_times)
			arg_20_0.trialInfos_[var_20_0].lastID = tonumber(iter_20_1.last_id)
		end
	end

	if not arg_20_0.worldMaps_ then
		arg_20_0.worldMaps_ = {}
	end

	for iter_20_2, iter_20_3 in pairs(arg_20_1.params.trial_info.campaigns) do
		local var_20_1 = tonumber(iter_20_3.campaign_id)

		if var_20_1 then
			arg_20_0.worldMaps_[var_20_1] = {}
			arg_20_0.worldMaps_[var_20_1].star = tonumber(iter_20_3.star)
		end
	end

	arg_20_0.challengeInfos_ = {}

	for iter_20_4, iter_20_5 in pairs(arg_20_1.params.challenge_info.challenges) do
		local var_20_2 = tonumber(iter_20_5.id)

		if var_20_2 then
			arg_20_0.challengeInfos_[var_20_2] = {}
			arg_20_0.challengeInfos_[var_20_2].id = tonumber(iter_20_5.id)
			arg_20_0.challengeInfos_[var_20_2].leftTimes = tonumber(iter_20_5.left_times)
			arg_20_0.challengeInfos_[var_20_2].isOpen = tonumber(iter_20_5.is_open)
			arg_20_0.challengeInfos_[var_20_2].maxTimes = tonumber(iter_20_5.max_times)
			arg_20_0.challengeInfos_[var_20_2].lastID = tonumber(iter_20_5.last_id)
		end
	end

	for iter_20_6, iter_20_7 in pairs(arg_20_1.params.challenge_info.campaigns) do
		local var_20_3 = tonumber(iter_20_7.campaign_id)

		if var_20_3 then
			arg_20_0.worldMaps_[var_20_3] = {}
			arg_20_0.worldMaps_[var_20_3].star = tonumber(iter_20_7.star)
		end
	end

	arg_20_0.trialLoaded_ = true
end

function var_0_0.onBackpackEvent_(arg_21_0, arg_21_1)
	arg_21_0.backpack_ = arg_21_0.backpack_ or import("app.model.Backpack").new()
	arg_21_0.backpack_sort_type = arg_21_1.params.sort_type

	arg_21_0.backpack_:populate(arg_21_1.params)
end

function var_0_0.onHeroEquipRefresh_(arg_22_0, arg_22_1)
	local var_22_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.equipConfirmWnd)

	if var_22_0 then
		var_22_0:update()
	end
end

function var_0_0.onMapDetailRefresh_(arg_23_0, arg_23_1)
	local var_23_0 = xyd.WindowManager.get():getWindow("map_detail_window") or xyd.WindowManager.get():getWindow("new_map_detail_window")

	if var_23_0 then
		var_23_0.hasItemNum = arg_23_0:getBackpack():getItemNumByID(50001013)

		var_23_0:nodeByName("sweep_item_num"):setString(string.format(var_0_3:translation("MAP_SWEEP_ITEM"), tostring(var_23_0.hasItemNum)))
	end
end

function var_0_0.onNewFuncOpen(arg_24_0, arg_24_1)
	if not arg_24_1 or not next(arg_24_1) then
		return
	end

	arg_24_0.newFunctions = arg_24_1

	xyd.StoryData.get():setFuncIDs(arg_24_0.newFunctions)

	if arg_24_0.openFuncMap == nil then
		arg_24_0.openFuncMap = {}
	end

	for iter_24_0, iter_24_1 in pairs(arg_24_1) do
		local var_24_0 = tonumber(iter_24_1) or 0

		if var_24_0 > 0 then
			arg_24_0.openFuncMap[var_24_0] = true
		else
			print("error!, v is " .. iter_24_1)
		end
	end

	local var_24_1 = {}

	for iter_24_2, iter_24_3 in pairs(arg_24_0.openFuncMap) do
		table.insert(var_24_1, iter_24_2)
	end

	table.sort(var_24_1)

	arg_24_0.funcIDs = var_24_1

	xyd.WindowManager.get():closeWindow("chat")
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_MIDDLE_LOCK
	})

	local var_24_2 = xyd.tables.functionOpen

	for iter_24_4, iter_24_5 in pairs(arg_24_1) do
		local var_24_3 = tonumber(iter_24_5) or 0

		if var_24_3 > 0 then
			if var_24_2:isPopUp(var_24_3) == 1 then
				local var_24_4 = {
					funcID = var_24_3
				}

				if xyd.WindowManager.get():isWindowOpen("levelup") then
					xyd.WindowManager.get():getWindow("levelup"):addFuncID(var_24_4)
				else
					xyd.WindowManager.get():openWindow("function_show", var_24_4)
				end
			end

			print("open func: " .. var_24_3)

			if var_24_3 == xyd.FunctionID.ID_SUPER_CAMPAGIN then
				arg_24_0.worldMapLoaded_ = false

				arg_24_0:loadWorldMap(function()
					return
				end)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.PLAY_FUNC_GUIDE,
				params = {
					guide_id = xyd.GuideStoryType.OPEN_FUNCTION_START + var_24_3
				}
			})

			if var_24_3 == xyd.FunctionID.ID_PET then
				local var_24_5 = true

				if arg_24_0:getBackpack() == nil then
					var_24_5 = false
				elseif arg_24_0:getBackpack():getItemNumByID(xyd.tables.misc.firstEgg) == 0 then
					var_24_5 = false

					local var_24_6 = {
						itemID = xyd.tables.misc.firstEgg
					}

					var_24_6.itemNum = 1

					arg_24_0:getBackpack():addItem(var_24_6)
				end

				local var_24_7 = xyd.WindowManager.get():getWindow("main_scene_bottom")

				if var_24_7 then
					arg_24_0:setPetGuideId()

					if xyd.WindowManager.get():getWindow("levelup") then
						xyd.WindowManager.get():closeWindow("levelup")
					end

					var_24_7:playPetGuide(var_24_5)
				end
			end

			if var_24_3 == xyd.FunctionID.ID_CLOUD_CITY then
				xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CLOUD_CITY_START, true)
				xyd.StoryData.get():persist()
			end

			if var_24_3 == xyd.FunctionID.ID_CONQUER_SCHOOL then
				xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CONQUER_SCHOOL_START, true)
				xyd.StoryData.get():persist()
			end

			if var_24_3 == xyd.FunctionID.ID_ACT_CENTRE and arg_24_0:getBackpack() and arg_24_0:getBackpack():getItemNumByID(xyd.tables.misc.eventCentreOpenBook) == 0 then
				local var_24_8 = {
					itemID = xyd.tables.misc.eventCentreOpenBook
				}

				var_24_8.itemNum = 1

				arg_24_0:getBackpack():addItem(var_24_8)
			end

			if xyd.config.FuncShopMap[var_24_3] ~= nil then
				local var_24_9 = xyd.config.FuncShopMap[var_24_3]
				local var_24_10 = var_24_3 == xyd.FunctionID.ID_TMP_GNOME_SHOP or var_24_3 == xyd.FunctionID.ID_TMP_BLACK_SHOP or var_24_3 == xyd.FunctionID.ID_TMP_SPACE

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.OPEN_SHOP_TYPE,
					params = {
						shopType = var_24_9,
						countDown = var_24_10
					}
				})
			end
		end
	end
end

function var_0_0.getOpenFuncMap(arg_26_0)
	return arg_26_0.openFuncMap or {}
end

function var_0_0.loadBackpack(arg_27_0, arg_27_1)
	if arg_27_0.backpackLoaded_ then
		if arg_27_1 then
			arg_27_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_BACKPACK, {}, function(arg_28_0)
			if arg_28_0 == xyd.error.OK then
				arg_27_0.backpackLoaded_ = true
			end

			if arg_27_1 then
				arg_27_1(arg_28_0)
			end
		end)
	end
end

function var_0_0.sellItem(arg_29_0, arg_29_1, arg_29_2)
	xyd.Backend.get():request(xyd.mid.SELL_ITEM, arg_29_1, function(arg_30_0)
		if arg_30_0 == xyd.error.OK then
			local var_30_0 = {
				itemID = arg_29_1.item_id,
				itemNum = arg_29_1.item_num
			}

			arg_29_0:getBackpack():removeItem(var_30_0)
			arg_29_2(arg_30_0)
		end
	end)
end

function var_0_0.sellItems(arg_31_0, arg_31_1, arg_31_2)
	xyd.Backend.get():request(xyd.mid.SELL_ITEMS, arg_31_1, function(arg_32_0)
		if arg_32_0 == xyd.error.OK then
			for iter_32_0, iter_32_1 in pairs(arg_31_1.items) do
				local var_32_0 = {
					itemID = iter_32_1.item_id,
					itemNum = iter_32_1.item_num
				}

				arg_31_0:getBackpack():removeItem(var_32_0)
			end

			arg_31_2(arg_32_0)
		end
	end)
end

function var_0_0.useMagicItems(arg_33_0, arg_33_1, arg_33_2)
	xyd.Backend.get():request(xyd.mid.USE_MAGIC_ITEMS, arg_33_1, function(arg_34_0)
		if arg_34_0 == xyd.error.OK then
			for iter_34_0, iter_34_1 in pairs(arg_33_1.items) do
				local var_34_0 = {
					itemID = iter_34_1.item_id,
					itemNum = iter_34_1.item_num
				}

				arg_33_0:getBackpack():removeItem(var_34_0)
			end

			arg_33_2(arg_34_0)
		end
	end)
end

function var_0_0.useSkillPointItem(arg_35_0, arg_35_1, arg_35_2)
	xyd.Backend.get():request(xyd.mid.USE_SKILL_POINT_ITEM, arg_35_1, function(arg_36_0)
		if arg_36_0 == xyd.error.OK then
			local var_36_0 = {
				itemID = arg_35_1.item_id,
				itemNum = arg_35_1.item_num
			}

			arg_35_0:getBackpack():removeItem(var_36_0)
			arg_35_2(arg_36_0)
		end
	end)
end

function var_0_0.useEnergyItem(arg_37_0, arg_37_1, arg_37_2)
	xyd.Backend.get():request(xyd.mid.USE_ENERGY_ITEM, arg_37_1, function(arg_38_0)
		if arg_38_0 == xyd.error.OK then
			local var_38_0 = {
				itemID = arg_37_1.item_id,
				itemNum = arg_37_1.item_num
			}

			arg_37_0:getBackpack():removeItem(var_38_0)
			arg_37_2(arg_38_0)
		end
	end)
end

function var_0_0.openActItem(arg_39_0, arg_39_1, arg_39_2)
	xyd.Backend.get():request(xyd.mid.OPEN_ACT_ITEM, arg_39_1, function(arg_40_0)
		if arg_40_0 == xyd.error.OK then
			local var_40_0 = {
				itemID = arg_39_1.item_id
			}

			var_40_0.itemNum = 1

			arg_39_0:getBackpack():removeItem(var_40_0)
		end

		arg_39_2(arg_40_0)
	end)
end

function var_0_0.makeItem(arg_41_0, arg_41_1, arg_41_2)
	xyd.Backend.get():request(xyd.mid.COMPOSE_ITEM, arg_41_1, function(arg_42_0)
		if arg_42_0 == xyd.error.OK then
			local var_42_0 = {}

			if not arg_41_1.item_num then
				arg_41_1.item_num = 1
			end

			var_42_0.itemID = arg_41_1.item_id
			var_42_0.itemNum = arg_41_1.item_num

			arg_41_0:getBackpack():addItem(var_42_0)

			local var_42_1 = xyd.tables.item:compose(var_42_0.itemID)
			local var_42_2 = xyd.tables.item:composeNum(var_42_0.itemID)

			for iter_42_0 = 1, #var_42_1 do
				local var_42_3 = {
					itemID = var_42_1[iter_42_0],
					itemNum = var_42_2[iter_42_0] * (tonumber(arg_41_1.item_num) or 1)
				}

				arg_41_0:getBackpack():removeItem(var_42_3)
			end

			arg_41_2(arg_42_0)
		end
	end)
end

function var_0_0.addPartnerExp(arg_43_0, arg_43_1, arg_43_2)
	xyd.Backend.get():request(xyd.mid.USE_EXP_ITEM, arg_43_1, function(arg_44_0, arg_44_1)
		if arg_44_0 == xyd.error.OK then
			local var_44_0 = {
				itemID = arg_43_1.item_id,
				itemNum = arg_43_1.item_num
			}

			arg_43_0:getBackpack():removeItem(var_44_0)
		end

		arg_43_2(arg_44_0, arg_43_1, arg_44_1)
	end, {}, false, true)
end

function var_0_0.addPartnerExps(arg_45_0, arg_45_1, arg_45_2)
	xyd.Backend.get():request(xyd.mid.USE_EXP_ITEMS, arg_45_1, function(arg_46_0, arg_46_1)
		if arg_46_0 == xyd.error.OK then
			for iter_46_0, iter_46_1 in pairs(arg_45_1.items) do
				arg_45_0:getBackpack():removeItem({
					itemID = iter_46_1.item_id,
					itemNum = iter_46_1.item_num
				})
			end
		end

		arg_45_2(arg_46_0, arg_45_1, arg_46_1)
	end, {}, false, true)
end

function var_0_0.breachStoneAdd(arg_47_0, arg_47_1, arg_47_2)
	xyd.Backend.get():request(xyd.mid.BREACH_STONE_ADD, arg_47_1, function(arg_48_0, arg_48_1)
		if arg_48_0 == xyd.error.OK then
			local var_48_0 = arg_47_0:getHero(arg_47_1.partner_id)

			arg_47_0:getBackpack():removeItem({
				itemID = arg_47_1.cost_item,
				itemNum = arg_47_1.add_num
			})
			var_48_0:setEvoInfo(arg_48_1.evo_info)
		end

		arg_47_2(arg_48_0, arg_47_1, arg_48_1)
	end, {}, false, true)
end

function var_0_0.breachStoneEvolve(arg_49_0, arg_49_1, arg_49_2)
	xyd.Backend.get():request(xyd.mid.BREACH_STONE_EVOLVE, arg_49_1, function(arg_50_0, arg_50_1)
		if arg_50_0 == xyd.error.OK then
			arg_49_0:getHero(arg_49_1.partner_id):setEvoInfo(arg_50_1.evo_info)
		end

		arg_49_2(arg_50_0, arg_49_1, arg_50_1)
	end, {}, false, true)
end

function var_0_0.onSellItem_(arg_51_0, arg_51_1)
	return
end

function var_0_0.getBackpack(arg_52_0)
	return arg_52_0.backpack_
end

function var_0_0.getMessagePush(arg_53_0)
	if not arg_53_0.messagePush_ then
		arg_53_0.messagePush_ = import("app.model.MessagePush").new()
	end

	return arg_53_0.messagePush_
end

function var_0_0.buySkillPoint(arg_54_0, arg_54_1)
	xyd.Backend.get():request(xyd.mid.BUY_SKILL_POINT, {}, function(arg_55_0, arg_55_1, arg_55_2)
		if arg_55_0 == xyd.error.OK then
			if arg_55_1.buy_skill_times then
				arg_54_0.buySkillTimes = tonumber(arg_55_1.buy_skill_times)
			else
				arg_54_0.buySkillTimes = arg_54_0.buySkillTimes + 1
			end

			if arg_55_1.skill_point then
				arg_54_0.skillPoint = tonumber(arg_55_1.skill_point)
			end

			if arg_55_1.skill_time then
				arg_54_0.lastSkillPoint = tonumber(arg_55_1.skill_time)
			end

			if arg_54_1 then
				arg_54_1()
			end
		end
	end)
end

function var_0_0.setSkillLevel(arg_56_0, arg_56_1, arg_56_2)
	local var_56_0 = arg_56_1 or {}

	if not var_56_0.skill_index or not var_56_0.partner_id then
		if arg_56_2 then
			arg_56_2()
		end

		return
	end

	xyd.Backend.get():request(xyd.mid.SET_SKILL_LEVEL, var_56_0, function(arg_57_0, arg_57_1, arg_57_2)
		if arg_57_0 == xyd.error.OK then
			if arg_57_1.skill_point then
				arg_56_0.skillPoint = tonumber(arg_57_1.skill_point)
			end

			if arg_57_1.skill_time then
				arg_56_0.lastSkillPoint = tonumber(arg_57_1.skill_time)
			end
		end

		if arg_56_2 then
			arg_56_2(arg_57_0, arg_57_1)
		end
	end, {
		player_id = playerID
	}, false, true)
end

function var_0_0.setAllSkillLevel(arg_58_0, arg_58_1, arg_58_2)
	local var_58_0 = arg_58_1 or {}

	if not var_58_0.skill_colors or not var_58_0.skill_counts or not var_58_0.partner_id then
		if arg_58_2 then
			arg_58_2()
		end

		return
	end

	xyd.Backend.get():request(xyd.mid.SET_ALL_SKILL_LEVEL, var_58_0, function(arg_59_0, arg_59_1, arg_59_2)
		if arg_59_0 == xyd.error.OK then
			arg_58_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			arg_58_0.selfPlayer:getMessagePush():registerNotification()

			if arg_59_1.skill_point then
				arg_58_0.skillPoint = tonumber(arg_59_1.skill_point)
			end

			if arg_59_1.skill_time then
				arg_58_0.lastSkillPoint = tonumber(arg_59_1.skill_time)
			end
		end

		if arg_58_2 then
			arg_58_2(arg_59_0, arg_59_1)
		end
	end)
end

function var_0_0.economySyncEvent_(arg_60_0, arg_60_1)
	if not arg_60_1.params then
		return
	end

	if arg_60_1.params.exp then
		arg_60_0.exp = arg_60_1.params.exp

		local var_60_0 = false
		local var_60_1 = arg_60_0.lev
		local var_60_2 = arg_60_0:getEnergy()
		local var_60_3 = var_60_2

		while arg_60_0.exp >= arg_60_0:getExpLimit() do
			var_60_3 = var_60_3 + xyd.tables.player:awardEnergy(arg_60_0.lev)
			arg_60_0.lev = arg_60_0.lev + 1
			var_60_0 = true

			if arg_60_0.lev >= arg_60_0.maxTeamLev then
				break
			end
		end

		if var_60_0 then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.PLAYER_LEVEL_UP,
				params = {
					lev = arg_60_0.lev
				}
			})

			local var_60_4 = {
				type_ = xyd.LevelUpType.LEVELUP,
				vals = {
					oldLev = var_60_1,
					newLev = arg_60_0.lev,
					oldEnergy = var_60_2,
					newEnergy = var_60_3
				}
			}

			if arg_60_1.news and arg_60_1.news.funcIDs then
				var_60_4.vals.newFuncIDs = arg_60_1.news.funcIDs
			end

			if var_60_1 < 10 and arg_60_0.lev >= 10 then
				xyd.tracking(xyd.AFInAppEventType.LEVEL_ACHIEVED_10)
			end

			if var_60_1 < 20 and arg_60_0.lev >= 20 then
				xyd.tracking(xyd.AFInAppEventType.LEVEL_ACHIEVED_20)
			end

			if var_60_1 < 30 and arg_60_0.lev >= 30 then
				xyd.tracking(xyd.AFInAppEventType.LEVEL_ACHIEVED_30)
			end

			if var_60_1 < 40 and arg_60_0.lev >= 40 then
				xyd.tracking(xyd.AFInAppEventType.LEVEL_ACHIEVED_40)
			end

			if var_60_1 < 50 and arg_60_0.lev >= 50 then
				xyd.tracking(xyd.AFInAppEventType.LEVEL_ACHIEVED_50)
			end

			if var_60_1 < arg_60_0.lev then
				arg_60_0:sendFunctionClick(xyd.FunctionClick.ACTIVITIES)

				if xyd.WindowManager.get():isWindowOpen("main_scene_top") then
					xyd.WindowManager.get():getWindow("main_scene_top"):updateTopBtn()
				end
			end

			xyd.WindowManager.get():openWindow("levelup", var_60_4)

			if var_60_1 < 7 and arg_60_0.lev >= 7 then
				local var_60_5 = xyd.WindowManager.get():getWindow("main_scene_top")

				if var_60_5 and var_60_5:isOpenNewSeverPush(xyd.ServerTime.get():getServerTime()) then
					var_60_5:updateTopBtn()
				end
			end
		end
	end

	if arg_60_1.params.charge then
		arg_60_0.charge = arg_60_1.params.charge

		local var_60_6 = false
		local var_60_7 = arg_60_0.vip

		while arg_60_0.charge >= arg_60_0:getVipLimit() and arg_60_0:getVipLimit() > 0 do
			arg_60_0.vip = arg_60_0.vip + 1
			var_60_6 = true

			if arg_60_0.vip >= 15 then
				break
			end
		end

		if var_60_7 < 1 and arg_60_0.vip >= 1 then
			xyd.tracking(xyd.AFInAppEventType.VIP_1)
		end

		if var_60_7 < 2 and arg_60_0.vip >= 2 then
			xyd.tracking(xyd.AFInAppEventType.VIP_2)
		end

		if var_60_7 < 3 and arg_60_0.vip >= 3 then
			xyd.tracking(xyd.AFInAppEventType.VIP_3)
		end

		if var_60_7 < 4 and arg_60_0.vip >= 4 then
			xyd.tracking(xyd.AFInAppEventType.VIP_4)
		end

		if var_60_7 < 5 and arg_60_0.vip >= 5 then
			xyd.tracking(xyd.AFInAppEventType.VIP_5)
		end

		if var_60_7 < 9 and arg_60_0.vip >= 9 then
			xyd.tracking(xyd.AFInAppEventType.VIP_9)
		end

		if var_60_6 then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.PLAYER_LEVEL_UP,
				params = {
					vip = arg_60_0.vip
				}
			})
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.VIP_LEVEL_CHANGE,
				params = {
					vip = var_60_7
				}
			})

			if xyd.tables.vip:yuanZhengNum(arg_60_0.vip) > xyd.tables.vip:yuanZhengNum(var_60_7) then
				xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH):loadMarchInfo({}, function(arg_61_0)
					return
				end)
			end
		end
	end

	if arg_60_1.params.mana then
		arg_60_0.mana = arg_60_1.params.mana
	end

	if arg_60_1.params.crystal then
		arg_60_0.crystal = arg_60_1.params.crystal
	end

	if arg_60_1.params.vip then
		arg_60_0.vip = arg_60_1.params.vip
	end

	if arg_60_1.params.arena_coin then
		arg_60_0.arena_coin = arg_60_1.params.arena_coin
	end

	if arg_60_1.params.march_coin then
		arg_60_0.march_coin = arg_60_1.params.march_coin
	end

	if arg_60_1.params.top_coin then
		arg_60_0.top_coin = arg_60_1.params.top_coin
	end

	if arg_60_1.params.guild_coin then
		arg_60_0.guild_coin = arg_60_1.params.guild_coin
	end

	if arg_60_1.params.region_coin then
		arg_60_0.region_coin = arg_60_1.params.region_coin
	end

	if arg_60_1.params.honor_coin then
		arg_60_0.honorCoin = arg_60_1.params.honor_coin
	end

	if arg_60_1.params.king_coin then
		arg_60_0.kingCoin = arg_60_1.params.king_coin
	end

	if arg_60_1.params.lucky_coin then
		arg_60_0.luckyCoin = arg_60_1.params.lucky_coin
	end

	if arg_60_1.params.paradise_coin then
		arg_60_0.illusionCoin = arg_60_1.params.paradise_coin
	end

	if arg_60_1.params.god_war_coin then
		arg_60_0.academyCoin = arg_60_1.params.god_war_coin
	end

	if arg_60_1.params.spirit_stone then
		arg_60_0.spiritStone = arg_60_1.params.spirit_stone
	end

	if arg_60_1.params.energy then
		arg_60_0.energy = arg_60_1.params.energy
	end

	if arg_60_1.params.spirit_energy then
		arg_60_0.spiritEnergy = arg_60_1.params.spirit_energy
	end

	if arg_60_1.params.skill_point then
		arg_60_0.skillPoint = tonumber(arg_60_1.params.skill_point)
	end

	if arg_60_1.params.magic_dust then
		arg_60_0.magicDust = tonumber(arg_60_1.params.magic_dust)
	end

	if arg_60_1.params.magic_liquid then
		arg_60_0.magicLiquid = tonumber(arg_60_1.params.magic_liquid)
	end

	if arg_60_1.params.magic_energy then
		arg_60_0.magicEnergy = tonumber(arg_60_1.params.magic_energy)
	end

	if arg_60_1.params.friendship_coin then
		arg_60_0.friendshipCoin = tonumber(arg_60_1.params.friendship_coin)
	end

	if arg_60_1.params.friend_medal then
		arg_60_0.friendMedal = tonumber(arg_60_1.params.friend_medal)
	end

	if arg_60_1.params.summon_coin then
		arg_60_0.summonCoin = tonumber(arg_60_1.params.summon_coin)
	end

	if arg_60_1.params.lvbu_coin then
		arg_60_0.lvbuCoin = tonumber(arg_60_1.params.lvbu_coin)
	end

	if arg_60_1.params.magic_exp then
		arg_60_0.magicExp = tonumber(arg_60_1.params.magic_exp)
	end

	if arg_60_1.params.degree_cer then
		arg_60_0.degreeCer = tonumber(arg_60_1.params.degree_cer)
	end

	if arg_60_1.params.graduate_cer then
		arg_60_0.graduateCer = tonumber(arg_60_1.params.graduate_cer)
	end

	if arg_60_1.params.patent_cer then
		arg_60_0.patentCer = tonumber(arg_60_1.params.patent_cer)
	end

	if arg_60_1.params.conquer_lev then
		arg_60_0.conquerLev = tonumber(arg_60_1.params.conquer_lev)
	end

	if arg_60_1.params.conquer_loop_id then
		arg_60_0.conquerLoopID = tonumber(arg_60_1.params.conquer_loop_id)
	end

	if arg_60_1.params.conquer_region then
		arg_60_0.conquerRegion = tonumber(arg_60_1.params.conquer_region)
	end

	if arg_60_1.params.team_dungeon_coin then
		arg_60_0.teamDungeonCoin = tonumber(arg_60_1.params.team_dungeon_coin)
	end

	if arg_60_1.params.occult_ticket then
		arg_60_0.occultTicket = tonumber(arg_60_1.params.occult_ticket)
	end

	if arg_60_1.params.ice_core then
		arg_60_0.iceCore = tonumber(arg_60_1.params.ice_core)
	end

	if arg_60_1.params.skin_fragment then
		arg_60_0.skinFragment = tonumber(arg_60_1.params.skin_fragment)
	end

	if arg_60_1.params.tutor_coin then
		arg_60_0.tutorCoin = tonumber(arg_60_1.params.tutor_coin)
	end

	if arg_60_1.params.skin_coin then
		arg_60_0.skinCoin = tonumber(arg_60_1.params.skin_coin)
	end

	if arg_60_1.params.daily_updates then
		arg_60_0.trialLoaded_ = false
		arg_60_0.worldMapLoaded_ = false
		arg_60_0.signInfoLoaded_ = false
		arg_60_0.buyManaTimes = arg_60_1.params.updates.buy_mana_times
		arg_60_0.buyEnergyTimes = arg_60_1.params.updates.buy_energy_times
		arg_60_0.buySkillTimes = arg_60_1.params.updates.buy_skill_times
		xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH).mapInfo = nil

		arg_60_0:setSignIn(0)
	end

	if arg_60_0.energy then
		if arg_60_0.energy < arg_60_0:getEnergyLimit() and arg_60_0.lastEnergy == 0 then
			arg_60_0.lastEnergy = xyd.ServerTime.get():getServerTime()
		elseif arg_60_0.energy >= arg_60_0:getEnergyLimit() then
			arg_60_0.lastEnergy = 0
		end
	end

	if arg_60_0.spiritEnergy then
		if arg_60_0.spiritEnergy < arg_60_0:getSpiritEnergyLimit() and arg_60_0.lastSpiritEnergy == 0 then
			arg_60_0.lastSpiritEnergy = xyd.ServerTime.get():getServerTime()
		elseif arg_60_0.spiritEnergy >= arg_60_0:getSpiritEnergyLimit() then
			arg_60_0.lastSpiritEnergy = 0
		end
	end

	if arg_60_1.params.invitation then
		arg_60_0.invitation = arg_60_1.params.invitation
	end

	if arg_60_0.invitation and xyd.isFunctionOpen(xyd.FunctionID.ARENA) then
		if arg_60_0.invitation < arg_60_0:getInvitationLimit() and arg_60_0.lastInvitation == 0 then
			arg_60_0.lastInvitation = xyd.ServerTime.get():getServerTime()
		elseif arg_60_0.invitation >= arg_60_0:getInvitationLimit() then
			arg_60_0.lastInvitation = 0
		end
	end

	if arg_60_1.params.social then
		arg_60_0.social = arg_60_1.params.social
	end

	if arg_60_1.params.lev then
		arg_60_0.lev = arg_60_1.params.lev
	end

	if arg_60_1.params.glory then
		arg_60_0.glory = arg_60_1.params.glory
	end

	if arg_60_1.params.point then
		arg_60_0.point = arg_60_1.params.point
	end

	if arg_60_1.params.glue then
		arg_60_0.glue = arg_60_1.params.glue
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.ECONOMY_AFTER,
		params = arg_60_1.params
	})
end

function var_0_0.updateOpenFunctions(arg_62_0)
	return
end

function var_0_0.getExpLimit(arg_63_0)
	return xyd.tables.player:totalExp(arg_63_0.lev)
end

function var_0_0.getLevExpTotal(arg_64_0)
	return xyd.tables.player:diffExp(arg_64_0.lev)
end

function var_0_0.getLevExp(arg_65_0)
	return arg_65_0.exp - xyd.tables.player:totalExp(arg_65_0.lev - 1)
end

function var_0_0.getVipLimit(arg_66_0)
	return xyd.tables.vip:chargeReq(arg_66_0.vip + 1)
end

function var_0_0.getEnergy(arg_67_0)
	local var_67_0 = math.floor(xyd.tables.misc.energyIncrTime)

	arg_67_0:recoverByTime("energy", "lastEnergy", var_67_0, arg_67_0:getEnergyLimit())

	return arg_67_0.energy
end

function var_0_0.getSpiritEnergy(arg_68_0)
	local var_68_0 = math.floor(xyd.tables.misc:getValue("spirit_energy_minute"))

	arg_68_0:recoverByTime("spiritEnergy", "lastSpiritEnergy", var_68_0, arg_68_0:getSpiritEnergyLimit())

	return arg_68_0.spiritEnergy
end

function var_0_0.getEnergyLimit(arg_69_0)
	return xyd.tables.player:maxEnergy(arg_69_0.lev)
end

function var_0_0.getSpiritEnergyLimit(arg_70_0)
	return xyd.tables.misc:getValue("spirit_energy_up_limit")
end

function var_0_0.getNextEnergyIncrTime(arg_71_0)
	local var_71_0 = math.floor(xyd.tables.misc.energyIncrTime)

	arg_71_0:recoverByTime("energy", "lastEnergy", var_71_0, arg_71_0:getEnergyLimit())

	if arg_71_0.lastEnergy == 0 then
		return 0
	else
		return arg_71_0.lastEnergy + var_71_0
	end
end

function var_0_0.getNextEnergyCoolTime(arg_72_0)
	local var_72_0 = math.floor(xyd.tables.misc.energyIncrTime)

	arg_72_0:recoverByTime("energy", "lastEnergy", var_72_0, arg_72_0:getEnergyLimit())

	if arg_72_0.energy >= xyd.tables.player:maxEnergy(arg_72_0.lev) then
		return 0, 0
	else
		local var_72_1 = xyd.tables.misc.energyIncrTime - (xyd.ServerTime.get():getServerTime() - arg_72_0.lastEnergy)
		local var_72_2 = var_72_1 + (xyd.tables.player:maxEnergy(arg_72_0.lev) - arg_72_0.energy - 1) * var_72_0

		return arg_72_0:coolTimeFormat_(var_72_1), arg_72_0:coolTimeFormat_(var_72_2)
	end
end

function var_0_0.getTotalEnergyCoolTime(arg_73_0)
	local var_73_0 = math.floor(xyd.tables.misc.energyIncrTime)

	arg_73_0:recoverByTime("energy", "lastEnergy", var_73_0, arg_73_0:getEnergyLimit())

	if arg_73_0.energy >= xyd.tables.player:maxEnergy(arg_73_0.lev) then
		return 0
	else
		return xyd.tables.misc.energyIncrTime - (xyd.ServerTime.get():getServerTime() - arg_73_0.lastEnergy) + (xyd.tables.player:maxEnergy(arg_73_0.lev) - arg_73_0.energy - 1) * var_73_0
	end
end

function var_0_0.getNextSpiritEnergyCoolTime(arg_74_0)
	local var_74_0 = math.floor(xyd.tables.misc:getValue("spirit_energy_minute"))

	arg_74_0:recoverByTime("spiritEnergy", "lastSpiritEnergy", var_74_0, arg_74_0:getSpiritEnergyLimit())

	if arg_74_0.spiritEnergy >= arg_74_0:getSpiritEnergyLimit() then
		return 0, 0
	else
		local var_74_1 = var_74_0 - (xyd.ServerTime.get():getServerTime() - arg_74_0.lastSpiritEnergy)
		local var_74_2 = var_74_1 + (arg_74_0:getSpiritEnergyLimit() - arg_74_0.spiritEnergy - 1) * var_74_0

		return arg_74_0:coolTimeFormat_(var_74_1), arg_74_0:coolTimeFormat_(var_74_2)
	end
end

function var_0_0.getTotalSpiritEnergyCoolTime(arg_75_0)
	local var_75_0 = math.floor(xyd.tables.misc:getValue("spirit_energy_minute"))

	arg_75_0:recoverByTime("spiritEnergy", "lastSpiritEnergy", var_75_0, arg_75_0:getSpiritEnergyLimit())

	if arg_75_0.spiritEnergy >= arg_75_0:getSpiritEnergyLimit() then
		return 0
	else
		return var_75_0 - (xyd.ServerTime.get():getServerTime() - arg_75_0.lastSpiritEnergy) + (arg_75_0:getSpiritEnergyLimit() - arg_75_0.spiritEnergy - 1) * var_75_0
	end
end

function var_0_0.getNextTreasureSPCoolTime(arg_76_0)
	local var_76_0 = math.floor(xyd.tables.misc.treasureSPInterval)

	arg_76_0:recoverByTime("treasureSP", "lastTreasureSP", var_76_0, xyd.tables.misc.treasureSPLimit)

	if arg_76_0.treasureSP >= xyd.tables.misc.treasureSPLimit then
		return 0, 0
	else
		if arg_76_0.lastTreasureSP == 0 then
			arg_76_0.lastTreasureSP = xyd.ServerTime.get():getServerTime()
		end

		local var_76_1 = xyd.tables.misc.treasureSPInterval - (xyd.ServerTime.get():getServerTime() - arg_76_0.lastTreasureSP)
		local var_76_2 = var_76_1 + (xyd.tables.misc.treasureSPLimit - arg_76_0.treasureSP - 1) * var_76_0

		return arg_76_0:coolTimeFormat_(var_76_1), arg_76_0:coolTimeFormat_(var_76_2)
	end
end

function var_0_0.coolTimeFormat_(arg_77_0, arg_77_1)
	local var_77_0 = {}
	local var_77_1 = tostring(arg_77_1 % 60)
	local var_77_2 = tostring(math.floor(arg_77_1 / 60) % 60)
	local var_77_3 = tostring(math.floor(math.floor(arg_77_1 / 60) / 60))

	table.insert(var_77_0, var_77_3)
	table.insert(var_77_0, var_77_2)
	table.insert(var_77_0, var_77_1)

	for iter_77_0, iter_77_1 in pairs(var_77_0) do
		if string.len(var_77_0[iter_77_0]) == 1 then
			var_77_0[iter_77_0] = "0" .. var_77_0[iter_77_0]
		end
	end

	return var_77_0[1] .. ":" .. var_77_0[2] .. ":" .. var_77_0[3]
end

function var_0_0.skillPointDecr(arg_78_0)
	if arg_78_0.skillPoint < 1 then
		return
	end

	arg_78_0.skillPoint = arg_78_0.skillPoint - 1
end

function var_0_0.getSkillPoint(arg_79_0)
	local var_79_0 = xyd.tables.misc.skillPointDuration
	local var_79_1 = xyd.tables.vip:skillPoint(arg_79_0.vip)

	if arg_79_0.privilegeLeftCardDay > 0 then
		var_79_1 = var_79_1 + xyd.tables.monthlyPrivilege:skillMax(1)
	end

	arg_79_0:recoverByTime("skillPoint", "lastSkillPoint", var_79_0, var_79_1)

	return arg_79_0.skillPoint
end

function var_0_0.getNextSkillRecoverDuration(arg_80_0)
	local var_80_0 = xyd.tables.misc.skillPointDuration
	local var_80_1 = xyd.tables.vip:skillPoint(arg_80_0.vip)

	if arg_80_0.privilegeLeftCardDay > 0 then
		var_80_1 = var_80_1 + xyd.tables.monthlyPrivilege:skillMax(1)
	end

	arg_80_0:recoverByTime("skillPoint", "lastSkillPoint", var_80_0, var_80_1)

	if arg_80_0.lastSkillPoint == 0 then
		return 0
	else
		return arg_80_0.lastSkillPoint + var_80_0 - xyd.ServerTime.get():getServerTime()
	end
end

function var_0_0.getTotalSkillRecoverTime(arg_81_0)
	local var_81_0 = xyd.tables.misc.skillPointDuration
	local var_81_1 = xyd.tables.vip:skillPoint(arg_81_0.vip)

	if arg_81_0.privilegeLeftCardDay > 0 then
		var_81_1 = var_81_1 + xyd.tables.monthlyPrivilege:skillMax(1)
	end

	arg_81_0:recoverByTime("skillPoint", "lastSkillPoint", var_81_0, var_81_1)

	if arg_81_0.lastSkillPoint == 0 then
		return 0
	else
		return arg_81_0.lastSkillPoint + var_81_0 - xyd.ServerTime.get():getServerTime() + (var_81_1 - arg_81_0.skillPoint - 1) * var_81_0
	end
end

function var_0_0.getNextFreeCrystalSummonTime(arg_82_0)
	if not arg_82_0.lastCrystalFreeSummon then
		return nil
	end

	local var_82_0 = xyd.tables.misc.freeCrystalSummonDuration

	arg_82_0:recoverByTime("crystalFreeSummon", "lastCrystalFreeSummon", var_82_0, 1)

	if arg_82_0.crystalFreeSummon > 0 then
		return 0
	end

	return arg_82_0.lastCrystalFreeSummon + var_82_0 - xyd.ServerTime.get():getServerTime()
end

function var_0_0.getNextFreeManaSummonTime(arg_83_0)
	if not arg_83_0.lastManaFreeSummon then
		return nil
	end

	if not arg_83_0.manaFreeNum_ or arg_83_0.manaFreeNum_ < 1 then
		return 0
	end

	local var_83_0 = xyd.tables.misc.freeManaSummonDuration

	arg_83_0:recoverByTime("manaFreeSummon", "lastManaFreeSummon", var_83_0, 1)

	if arg_83_0.manaFreeSummon > 0 then
		return 0
	end

	return arg_83_0.lastManaFreeSummon + var_83_0 - xyd.ServerTime.get():getServerTime()
end

function var_0_0.getFreeManaNum(arg_84_0)
	return arg_84_0.manaFreeNum_ or 0
end

function var_0_0.getHotSummonStone(arg_85_0)
	return arg_85_0.main_ids, arg_85_0.second_ids, arg_85_0.mana_id, arg_85_0.pet_id, arg_85_0.summon_partner_id, arg_85_0.magic_show_id
end

function var_0_0.getSkillPointLimit(arg_86_0)
	local var_86_0 = xyd.tables.vip:skillPoint(arg_86_0.vip)

	if arg_86_0.privilegeLeftCardDay > 0 then
		var_86_0 = var_86_0 + xyd.tables.monthlyPrivilege:skillMax(1)
	end

	return var_86_0
end

function var_0_0.getFormation(arg_87_0)
	return arg_87_0.formation
end

function var_0_0.getInvitationLimit(arg_88_0)
	return xyd.tables.player:invitation(arg_88_0.lev)
end

function var_0_0.getInvitation(arg_89_0)
	arg_89_0:recoverByTime("invitation", "lastInvitation", xyd.tables.misc.invitationIncrTime, arg_89_0:getInvitationLimit())

	return arg_89_0.invitation
end

function var_0_0.getNextInvitationIncrTime(arg_90_0)
	local var_90_0 = xyd.tables.misc.invitationIncrTime

	arg_90_0:recoverByTime("invitation", "lastInvitation", var_90_0, arg_90_0:getInvitationLimit())

	if arg_90_0.lastInvitation == 0 then
		return 0
	else
		return arg_90_0.lastInvitation + var_90_0
	end
end

function var_0_0.recoverByTime(arg_91_0, arg_91_1, arg_91_2, arg_91_3, arg_91_4)
	if arg_91_0[arg_91_2] == 0 or arg_91_0[arg_91_2] == nil then
		return
	end

	local var_91_0 = xyd.ServerTime.get():getServerTime()
	local var_91_1 = math.floor((var_91_0 - arg_91_0[arg_91_2]) / arg_91_3)

	if arg_91_4 < arg_91_0[arg_91_1] + var_91_1 and arg_91_4 >= arg_91_0[arg_91_1] then
		var_91_1 = arg_91_4 - arg_91_0[arg_91_1]
	end

	arg_91_0[arg_91_2] = arg_91_0[arg_91_2] + var_91_1 * arg_91_3

	if arg_91_4 > arg_91_0[arg_91_1] and arg_91_4 >= arg_91_0[arg_91_1] + var_91_1 then
		arg_91_0[arg_91_1] = arg_91_0[arg_91_1] + var_91_1
	elseif arg_91_4 > arg_91_0[arg_91_1] and arg_91_4 < arg_91_0[arg_91_1] + var_91_1 then
		arg_91_0[arg_91_1] = arg_91_4
	end

	if arg_91_4 <= arg_91_0[arg_91_1] then
		arg_91_0[arg_91_2] = 0
	end
end

function var_0_0.loadScrolls(arg_92_0, arg_92_1)
	if arg_92_0.scrollsLoaded_ then
		if arg_92_1 then
			arg_92_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_SCROLLS, {}, function(arg_93_0, arg_93_1, arg_93_2)
			if arg_93_0 == xyd.error.OK then
				if not arg_92_0.scrolls_ then
					arg_92_0:scrollsEvent_({
						name = xyd.event.SCROLLS,
						params = arg_93_1,
						userdata = arg_93_2
					})
				end

				arg_92_0.scrollsLoaded_ = true
			end

			if arg_92_1 then
				arg_92_1(arg_93_0)
			end
		end)
	end
end

function var_0_0.scrollsEvent_(arg_94_0, arg_94_1)
	arg_94_0.scrolls_ = {}

	local var_94_0 = {
		[xyd.ScrollID.CRYSTAL] = true,
		[xyd.ScrollID.SOCIAL] = true,
		[xyd.ScrollID.HERO_PIECE] = true,
		[xyd.ScrollID.WISH] = true,
		[xyd.ScrollID.MARKET] = true
	}

	for iter_94_0, iter_94_1 in pairs(arg_94_1.params) do
		local var_94_1 = tonumber(iter_94_0)

		if var_94_1 ~= nil then
			local var_94_2 = tonumber(iter_94_1)

			if var_94_0[var_94_1] == nil then
				arg_94_0.scrolls_[var_94_1] = var_94_2
			end
		end
	end
end

function var_0_0.loadHeroPieces(arg_95_0, arg_95_1)
	if arg_95_0.heroPiecesLoaded_ then
		if arg_95_1 then
			arg_95_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_HERO_PIECES, {}, function(arg_96_0, arg_96_1, arg_96_2)
			if arg_96_0 == xyd.error.OK then
				if not arg_95_0.heroPieces_ then
					arg_95_0:heroPiecesEvent_({
						name = xyd.event.HERO_PIECES,
						params = arg_96_1,
						userdata = arg_96_2
					})
				end

				arg_95_0.heroPiecesLoaded_ = true
			end

			if arg_95_1 then
				arg_95_1(arg_96_0)
			end
		end)
	end
end

function var_0_0.heroPiecesEvent_(arg_97_0, arg_97_1)
	arg_97_0.heroPieces_ = {}

	for iter_97_0, iter_97_1 in pairs(arg_97_1.params) do
		local var_97_0 = tonumber(iter_97_0)

		if var_97_0 then
			local var_97_1 = tonumber(iter_97_1)

			arg_97_0.heroPieces_[var_97_0] = var_97_1
		end
	end
end

function var_0_0.getHeroPieceNum(arg_98_0)
	local var_98_0 = 0

	for iter_98_0, iter_98_1 in pairs(arg_98_0.heroPieces_) do
		var_98_0 = var_98_0 + 1
	end

	return var_98_0
end

function var_0_0.loadEssences(arg_99_0, arg_99_1)
	if arg_99_0.essencesLoaded_ then
		if arg_99_1 then
			arg_99_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_ESSENCES, {}, function(arg_100_0, arg_100_1, arg_100_2)
			if arg_100_0 == xyd.error.OK then
				if not arg_99_0.essences_ then
					arg_99_0:essencesEvent_({
						name = xyd.event.ESSENCES,
						params = arg_100_1,
						userdata = arg_100_2
					})
				end

				arg_99_0.essencesLoaded_ = true
			end

			if arg_99_1 then
				arg_99_1(arg_100_0)
			end
		end)
	end
end

function var_0_0.essencesEvent_(arg_101_0, arg_101_1)
	arg_101_0.essences_ = {}

	for iter_101_0, iter_101_1 in pairs(arg_101_1.params) do
		local var_101_0 = tonumber(iter_101_0)

		if var_101_0 then
			local var_101_1 = tonumber(iter_101_1)

			arg_101_0.essences_[var_101_0] = var_101_1
		end
	end
end

function var_0_0.getPetByID(arg_102_0, arg_102_1)
	if not arg_102_0.collectedPets then
		return
	end

	for iter_102_0, iter_102_1 in ipairs(arg_102_0.collectedPets) do
		if iter_102_1:getPetID() == arg_102_1 then
			return iter_102_1
		end
	end
end

function var_0_0.loadCollectedPets(arg_103_0, arg_103_1)
	if arg_103_0.petLoaded_ then
		if arg_103_1 then
			arg_103_1()
		end

		return
	end

	arg_103_0.collectedPets = {}

	xyd.Backend.get():request(xyd.mid.PETS_GET, {}, function(arg_104_0, arg_104_1)
		if arg_104_0 == xyd.error.OK then
			arg_103_0.petLoaded_ = true

			if arg_104_1 and arg_104_1.pets then
				for iter_104_0, iter_104_1 in pairs(arg_104_1.pets) do
					local var_104_0 = import("app.model.Pet").new()

					var_104_0:populate(iter_104_1)
					var_104_0:setPlayerID(arg_103_0.playerID)

					arg_103_0.collectedPets[#arg_103_0.collectedPets + 1] = var_104_0
				end
			end
		end

		arg_103_1(arg_104_0, arg_104_1)
	end)
end

function var_0_0.loadCollectedHeros(arg_105_0, arg_105_1)
	if arg_105_0.collectedHerosLoaded_ then
		if arg_105_1 then
			arg_105_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_COLLECTED_HEROS, {}, function(arg_106_0, arg_106_1, arg_106_2)
			if arg_106_0 == xyd.error.OK then
				if not arg_105_0.collectedHeros_ then
					arg_105_0:collectedHerosEvent_({
						name = xyd.event.COLLECTED_HEROS,
						params = arg_106_1,
						userdata = arg_106_2
					})
				end

				arg_105_0.collectedHerosLoaded_ = true
			end

			if arg_105_1 then
				arg_105_1(arg_106_0)
			end
		end)
	end
end

function var_0_0.collectedHerosEvent_(arg_107_0, arg_107_1)
	arg_107_0.collectedHeros_ = {}

	for iter_107_0, iter_107_1 in pairs(arg_107_1.params.list) do
		arg_107_0.collectedHeros_[tonumber(iter_107_1)] = true
	end
end

function var_0_0.getCollectedHeroNum(arg_108_0)
	local var_108_0 = 0

	for iter_108_0, iter_108_1 in pairs(arg_108_0.collectedHeros_) do
		var_108_0 = var_108_0 + 1
	end

	return var_108_0
end

function var_0_0.loadFriendRepHeros(arg_109_0, arg_109_1)
	if arg_109_0.friendRepHeroLoaded_ then
		if arg_109_1 then
			arg_109_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_FRIEND_REP_HEROS, {}, function(arg_110_0, arg_110_1, arg_110_2)
			if arg_110_0 == xyd.error.OK then
				arg_109_0:friendRepHerosEvent_({
					name = xyd.event.FRIEND_REP_HEROS,
					params = arg_110_1,
					userdata = arg_110_2
				})

				arg_109_0.friendRepHeroLoaded_ = true
			end

			if arg_109_1 then
				arg_109_1(arg_110_0)
			end
		end, nil, false, true)
	end
end

function var_0_0.removeFriendRepHero(arg_111_0, arg_111_1)
	for iter_111_0 = #(arg_111_0.friendRepHeros_ or {}), 1, -1 do
		if arg_111_0.friendRepHeros_[iter_111_0]:getPlayerID() == arg_111_1 then
			table.remove(arg_111_0.friendRepHeros_, iter_111_0)
		end
	end
end

function var_0_0.friendRepHerosEvent_(arg_112_0, arg_112_1)
	arg_112_0.friendRepHeros_ = {}

	for iter_112_0, iter_112_1 in pairs(arg_112_1.params.list) do
		local var_112_0 = import("app.model.RepHero").new()

		var_112_0:populate(iter_112_1)
		table.insert(arg_112_0.friendRepHeros_, var_112_0)
	end
end

function var_0_0.getFriendRepHeroByID(arg_113_0, arg_113_1)
	if not arg_113_0.friendRepHeros_ then
		return nil
	end

	for iter_113_0, iter_113_1 in pairs(arg_113_0.friendRepHeros_) do
		if iter_113_1:getPlayerID() == arg_113_1 then
			return iter_113_1
		end
	end

	return nil
end

function var_0_0.battleEndedEvent_(arg_114_0, arg_114_1)
	if arg_114_1.instance_type ~= xyd.InstanceType.INSTANCE then
		return
	end

	if not arg_114_1.is_win then
		return
	end

	local var_114_0 = arg_114_1.instance_id
	local var_114_1 = xyd.tables.stage:mapID(var_114_0)
	local var_114_2 = arg_114_0.worldMaps_[var_114_1].passed_stage_id

	if var_114_2 > 0 then
		if var_114_2 == var_114_0 then
			return
		end

		local var_114_3 = var_114_0

		while var_114_3 ~= xyd.tables.stage:lastStageAtLevel(var_114_1, xyd.StageLevel.HELL) do
			var_114_3 = xyd.tables.stage:nextStageID(var_114_3)

			if var_114_2 == var_114_3 then
				return
			end
		end
	end

	arg_114_0.worldMaps_[var_114_1].passed_stage_id = var_114_0

	local var_114_4 = xyd.tables.stage:nextStageID(var_114_0)

	if var_114_4 == 0 then
		var_114_4 = xyd.tables.stage:lastStageAtLevel(var_114_1, xyd.StageLevel.HELL)
	end

	arg_114_0.worldMaps_[var_114_1].current_stage_id = var_114_4

	if var_114_0 == xyd.tables.stage:lastStageAtLevel(var_114_1, xyd.StageLevel.NORMAL) then
		local var_114_5 = xyd.tables.map:nextMapID(var_114_1)
		local var_114_6 = xyd.tables.map:firstStage(var_114_5)

		arg_114_0.worldMaps_[var_114_5] = {}
		arg_114_0.worldMaps_[var_114_5].passed_stage_id = 0
		arg_114_0.worldMaps_[var_114_5].current_stage_id = var_114_6
		arg_114_0.levels_[var_114_5] = xyd.tables.stage:lev(var_114_6)
		arg_114_0.newMap_ = var_114_5
	end
end

function var_0_0.getLastOpenStage(arg_115_0, arg_115_1)
	if arg_115_0.worldMaps_ == nil or arg_115_0.worldMaps_[arg_115_1] == nil then
		return 0
	end

	local var_115_0 = arg_115_0.worldMaps_[arg_115_1].passed_stage_id
	local var_115_1 = xyd.tables.stage:nextStageID(var_115_0)

	if xyd.tables.stage:hasStage(var_115_1) then
		return var_115_1
	else
		return var_115_0
	end
end

function var_0_0.getBattleHeros(arg_116_0)
	local var_116_0 = {}

	if not arg_116_0.heros_ then
		return var_116_0
	end

	for iter_116_0, iter_116_1 in pairs(arg_116_0.heros_) do
		if iter_116_1:canBattle() == 1 then
			table.insert(var_116_0, iter_116_1)
		end
	end

	return var_116_0
end

function var_0_0.addHero(arg_117_0, arg_117_1)
	arg_117_1.playerID_ = arg_117_0.playerID

	if arg_117_0.heros_ == nil then
		return
	end

	arg_117_1:setConquerSchoolLev(arg_117_0.conquerLev or 0)
	table.insert(arg_117_0.heros_, arg_117_1)

	if not arg_117_0.newHeroIDs_ then
		arg_117_0.newHeroIDs_ = {}
	end

	if arg_117_0:isFuncOpen(xyd.FunctionID.ID_MARCH) then
		xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH):loadMarchInfo({}, function(arg_118_0)
			return
		end)
	end

	table.insert(arg_117_0.newHeroIDs_, arg_117_1:getHeroID())

	if arg_117_0.heroMap then
		local var_117_0 = xyd.getOriginHeroId(arg_117_1:getTableID())

		arg_117_0.heroMap[var_117_0] = true
	end

	arg_117_0:checkSingleHeroAlbumNormal(arg_117_1)
	arg_117_0:checkAlbumSpecial()
	arg_117_0:albumRedPointEvent()
end

function var_0_0.addPet(arg_119_0, arg_119_1)
	if arg_119_0.collectedPets == nil then
		arg_119_0.collectedPets = {}
	end

	table.insert(arg_119_0.collectedPets, arg_119_1)
end

function var_0_0.getHeros(arg_120_0)
	return arg_120_0.heros_
end

function var_0_0.getHero(arg_121_0, arg_121_1)
	if arg_121_0.heros_ then
		for iter_121_0, iter_121_1 in pairs(arg_121_0.heros_) do
			if iter_121_1:getHeroID() == arg_121_1 then
				return iter_121_1
			end
		end
	end
end

function var_0_0.getHeroByID(arg_122_0, arg_122_1)
	if arg_122_0.heros_ then
		for iter_122_0, iter_122_1 in pairs(arg_122_0.heros_) do
			if iter_122_1:getHeroID() == arg_122_1 then
				return iter_122_1
			end
		end
	end
end

function var_0_0.getHeroByTableID(arg_123_0, arg_123_1)
	if arg_123_0.heros_ then
		for iter_123_0, iter_123_1 in pairs(arg_123_0.heros_) do
			if iter_123_1:getTableID() == arg_123_1 then
				return iter_123_1
			end
		end
	end
end

function var_0_0.getHeroByID(arg_124_0, arg_124_1)
	if not arg_124_0.heros_ then
		return nil
	end

	for iter_124_0, iter_124_1 in pairs(arg_124_0.heros_) do
		if iter_124_1:getHeroID() == arg_124_1 then
			return iter_124_1
		end
	end

	return nil
end

function var_0_0.getPetByTableID(arg_125_0, arg_125_1)
	if not arg_125_0.collectedPets then
		return
	end

	if arg_125_0.collectedPets then
		for iter_125_0, iter_125_1 in pairs(arg_125_0.collectedPets) do
			if iter_125_1:getTableID() == arg_125_1 then
				return iter_125_1
			end
		end
	end
end

function var_0_0.getPetIgnoreAwaken(arg_126_0, arg_126_1)
	if arg_126_0.collectedPets then
		for iter_126_0, iter_126_1 in pairs(arg_126_0.collectedPets) do
			if iter_126_1:getTableID() == arg_126_1 or iter_126_1:getTableID() == xyd.tables.hero:afterAwaken(arg_126_1) then
				return iter_126_1
			end
		end
	end
end

function var_0_0.getHeroIgnoreAwaken(arg_127_0, arg_127_1)
	if arg_127_0.heros_ then
		for iter_127_0, iter_127_1 in pairs(arg_127_0.heros_) do
			if iter_127_1:getTableID() == arg_127_1 or iter_127_1:getTableID() == xyd.tables.hero:afterAwaken(arg_127_1) then
				return iter_127_1
			end
		end
	end
end

function var_0_0.hasSkin(arg_128_0, arg_128_1)
	if arg_128_0:getBackpack():getItemNumByID(arg_128_1) > 0 then
		return true
	end

	local var_128_0 = xyd.tables.item:skinPartner(arg_128_1)
	local var_128_1 = arg_128_0:getHeroIgnoreAwaken(var_128_0)

	if var_128_1 and var_128_1.skinIds_ and next(var_128_1.skinIds_) then
		for iter_128_0, iter_128_1 in ipairs(var_128_1.skinIds_) do
			if iter_128_1 == xyd.tables.item:skinModel(arg_128_1) then
				return true
			end
		end
	end

	return false
end

function var_0_0.getHerosByHeroIDs(arg_129_0, arg_129_1)
	if type(arg_129_1) == "string" then
		arg_129_1 = xyd.splitToNumber(arg_129_1, "|")
	end

	local var_129_0 = {}

	if not arg_129_1 or not next(arg_129_1) then
		return var_129_0
	end

	if arg_129_0.heros_ then
		for iter_129_0, iter_129_1 in pairs(arg_129_1) do
			local var_129_1 = arg_129_0:getHero(iter_129_1)

			if var_129_1 then
				table.insert(var_129_0, var_129_1)
			end
		end
	end

	return var_129_0
end

function var_0_0.isNewHero(arg_130_0, arg_130_1)
	local var_130_0 = false

	if not arg_130_0.newHeroIDs_ then
		return var_130_0
	end

	for iter_130_0, iter_130_1 in pairs(arg_130_0.newHeroIDs_) do
		if iter_130_1 == arg_130_1 then
			var_130_0 = true
		end
	end

	return var_130_0
end

function var_0_0.deleteNewHero(arg_131_0, arg_131_1)
	local var_131_0

	if not arg_131_0.newHeroIDs_ then
		return
	end

	for iter_131_0 = 1, #arg_131_0.newHeroIDs_ do
		if arg_131_0.newHeroIDs_[iter_131_0] == arg_131_1 then
			var_131_0 = iter_131_0

			break
		end
	end

	if var_131_0 then
		table.remove(arg_131_0.newHeroIDs_, var_131_0)
	end
end

function var_0_0.addHeroWithHeroInfo(arg_132_0, arg_132_1)
	local var_132_0 = var_0_1.new()

	var_132_0:populate(arg_132_1)
	arg_132_0:addHero(var_132_0)

	return var_132_0
end

function var_0_0.updateHero(arg_133_0, arg_133_1)
	arg_133_1.playerID_ = arg_133_0.playerID

	local var_133_0

	for iter_133_0 = 1, #arg_133_0.heros_ do
		if arg_133_0.heros_[iter_133_0]:getHeroID() == arg_133_1:getHeroID() then
			arg_133_1.slots = arg_133_0.heros_[iter_133_0].slots
			arg_133_0.heros_[iter_133_0] = arg_133_1
			var_133_0 = true

			break
		end
	end

	if not var_133_0 then
		arg_133_0:addHero(arg_133_1)
	end
end

function var_0_0.updateRepHero(arg_134_0, arg_134_1)
	for iter_134_0 = 1, #arg_134_0.heros_ do
		if arg_134_0.heros_[iter_134_0]:getHeroID() == arg_134_1 then
			arg_134_0.heros_[iter_134_0]:setIsRep(true)
		else
			arg_134_0.heros_[iter_134_0]:setIsRep(false)
		end
	end
end

function var_0_0.deleteHero(arg_135_0, arg_135_1)
	local var_135_0

	for iter_135_0 = 1, #arg_135_0.heros_ do
		if arg_135_0.heros_[iter_135_0]:getHeroID() == arg_135_1 then
			var_135_0 = iter_135_0

			break
		end
	end

	print("delete hero at idx:", var_135_0)

	local function var_135_1(arg_136_0)
		if not arg_135_0.battleFormation_ then
			arg_135_0.battleFormation_ = {}
		end

		local var_136_0 = arg_135_0.battleFormation_[arg_136_0]

		if not var_136_0 then
			arg_135_0.battleFormation_[arg_136_0] = xyd.db.formation:getFormationData(arg_136_0)
			var_136_0 = arg_135_0.battleFormation_[arg_136_0]
		end

		if not var_136_0 then
			return
		end

		local var_136_1 = -1
		local var_136_2

		for iter_136_0, iter_136_1 in ipairs(var_136_0) do
			if var_136_0[iter_136_0] == arg_135_1 then
				print("delete hero in formation:", iter_136_1)

				var_136_0[iter_136_0] = var_136_1
				var_136_2 = true

				break
			end
		end

		if var_136_2 then
			print("persist db")
			xyd.db.formation:setFormationData(arg_136_0, var_136_0)
		end
	end

	if var_135_0 then
		print("updateBattleFormation")
		var_135_1(xyd.FormationType.INSTANCE)
		var_135_1(xyd.FormationType.DUNGEON)
		var_135_1(xyd.FormationType.ARENA)
		table.remove(arg_135_0.heros_, var_135_0)
	end
end

function var_0_0.summonHero(arg_137_0, arg_137_1, arg_137_2)
	xyd.Backend.get():request(xyd.mid.SUMMON_HERO, arg_137_1, function(arg_138_0, arg_138_1, arg_138_2)
		if arg_138_0 == xyd.error.OK then
			if type(arg_138_1) ~= "table" then
				if arg_137_2 then
					arg_137_2(arg_138_0, arg_138_1)
				end

				return
			end

			for iter_138_0, iter_138_1 in pairs(arg_138_1.result) do
				if iter_138_1.is_partner == true then
					local var_138_0 = var_0_1.new()

					var_138_0:populate(iter_138_1)
					arg_137_0:addHero(var_138_0)
				else
					arg_137_0:getBackpack():addItemsByID(tonumber(iter_138_1.table_id), tonumber(iter_138_1.item_num))
				end
			end

			if arg_138_1.reward then
				local var_138_1 = tonumber(arg_138_1.reward.item_id)
				local var_138_2 = tonumber(arg_138_1.reward.item_num)

				if var_138_1 and var_138_2 then
					arg_137_0:getBackpack():addItemsByID(var_138_1, var_138_2)
				end
			end

			if arg_138_1.extra_reward then
				local var_138_3 = tonumber(arg_138_1.extra_reward.item_id)
				local var_138_4 = tonumber(arg_138_1.extra_reward.item_num)

				if var_138_3 and var_138_4 then
					arg_137_0:getBackpack():addItemsByID(var_138_3, var_138_4)
				end
			end

			if arg_138_1.sakura_items then
				for iter_138_2, iter_138_3 in pairs(arg_138_1.sakura_items) do
					local var_138_5 = tonumber(iter_138_3.item_id)
					local var_138_6 = tonumber(iter_138_3.item_num)

					if var_138_5 and var_138_6 then
						arg_137_0:getBackpack():addItemsByID(var_138_5, var_138_6)
					end
				end
			end

			if arg_138_1.stick_items then
				for iter_138_4, iter_138_5 in pairs(arg_138_1.stick_items) do
					local var_138_7 = tonumber(iter_138_5.item_id)
					local var_138_8 = tonumber(iter_138_5.item_num)

					if var_138_7 and var_138_8 then
						arg_137_0:getBackpack():addItemsByID(var_138_7, var_138_8)
					end
				end
			end

			if arg_138_1.summon_info then
				local var_138_9 = arg_138_1.summon_info

				arg_137_0.lastManaFreeSummon = tonumber(var_138_9.mana_free_time)
				arg_137_0.lastCrystalFreeSummon = tonumber(var_138_9.crystal_free_time)

				if arg_137_0.lastCrystalFreeSummon < 1 then
					arg_137_0.crystalFreeSummon = 1
				else
					arg_137_0.crystalFreeSummon = 0
				end

				if arg_137_0.lastManaFreeSummon < 1 then
					arg_137_0.manaFreeSummon = 1
				else
					arg_137_0.manaFreeSummon = 0
				end

				if var_138_9.mana_free_num then
					arg_137_0.manaFreeNum_ = tonumber(var_138_9.mana_free_num)
				end
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.CHECK_MIDDLE_RED_MARK,
				params = xyd.CheckMiddleRed.SUMMON
			})
			arg_137_0:heroUpdateEvent_({
				name = xyd.event.HERO_UPDATE,
				params = arg_138_1,
				userdata = arg_138_2
			}, true)
		end

		arg_137_2(arg_138_0, arg_138_1)
	end, nil, false, true)
end

function var_0_0.magicSummonHero(arg_139_0, arg_139_1, arg_139_2)
	xyd.Backend.get():request(xyd.mid.MAGIC_SUMMON_BUY, arg_139_1, function(arg_140_0, arg_140_1, arg_140_2)
		if arg_140_0 == xyd.error.OK then
			if type(arg_140_1) ~= "table" then
				if arg_139_2 then
					arg_139_2(arg_140_0, arg_140_1)
				end

				return
			end

			for iter_140_0, iter_140_1 in pairs(arg_140_1.result) do
				if iter_140_1.is_partner == true then
					local var_140_0 = var_0_1.new()

					var_140_0:populate(iter_140_1)
					arg_139_0:addHero(var_140_0)
				else
					arg_139_0:getBackpack():addItemsByID(tonumber(iter_140_1.table_id), tonumber(iter_140_1.item_num))
				end
			end

			if arg_140_1.reward then
				local var_140_1 = tonumber(arg_140_1.reward.item_id)
				local var_140_2 = tonumber(arg_140_1.reward.item_num)

				if var_140_1 and var_140_2 then
					arg_139_0:getBackpack():addItemsByID(var_140_1, var_140_2)
				end
			end

			if arg_140_1.stick_items then
				for iter_140_2, iter_140_3 in pairs(arg_140_1.stick_items) do
					local var_140_3 = tonumber(iter_140_3.item_id)
					local var_140_4 = tonumber(iter_140_3.item_num)

					if var_140_3 and var_140_4 then
						arg_139_0:getBackpack():addItemsByID(var_140_3, var_140_4)
					end
				end
			end
		end

		arg_139_2(arg_140_0, arg_140_1)
	end)
end

function var_0_0.stoneSummonHero(arg_141_0, arg_141_1, arg_141_2)
	xyd.Backend.get():request(xyd.mid.STONE_SUMMON_HERO, arg_141_1, function(arg_142_0, arg_142_1, arg_142_2)
		if arg_142_0 == xyd.error.OK then
			if type(arg_142_1) ~= "table" then
				if arg_141_2 then
					arg_141_2(arg_142_0, arg_142_1)
				end

				return
			end

			local var_142_0 = var_0_1.new()

			var_142_0:populate(arg_142_1)
			arg_141_0:addHero(var_142_0)
			arg_141_0:getBackpack():removeItem({
				itemID = tonumber(arg_141_1.stone),
				itemNum = arg_141_1.stone_num
			})
		end

		if arg_141_2 then
			arg_141_2(arg_142_0, arg_142_1)
		end
	end)
end

function var_0_0.summonSuperHero(arg_143_0, arg_143_1, arg_143_2)
	xyd.Backend.get():request(xyd.mid.SUMMON_SUPER_HERO, arg_143_1, function(arg_144_0, arg_144_1, arg_144_2)
		if arg_144_0 == xyd.error.OK then
			if type(arg_144_1) ~= "table" then
				if arg_143_2 then
					arg_143_2(arg_144_0, arg_144_1)
				end

				return
			end

			local var_144_0 = var_0_1.new()

			var_144_0:populate(arg_144_1.partner_info)
			arg_143_0:addHero(var_144_0)
		end

		if arg_143_2 then
			arg_143_2(arg_144_0, arg_144_1)
		end
	end)
end

function var_0_0.loadSummonInfo(arg_145_0, arg_145_1, arg_145_2, arg_145_3)
	arg_145_1 = arg_145_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_SUMMON_INFO, arg_145_1, function(arg_146_0, arg_146_1, arg_146_2)
		if arg_146_0 == xyd.error.OK then
			if type(arg_146_1) ~= "table" then
				if arg_145_2 then
					arg_145_2(arg_146_0, arg_146_1)
				end

				return
			end

			arg_145_0.lastManaFreeSummon = tonumber(arg_146_1.mana_free_time) or 0
			arg_145_0.lastCrystalFreeSummon = tonumber(arg_146_1.crystal_free_time) or 0
			arg_145_0.second_ids = arg_146_1.second_ids
			arg_145_0.main_ids = arg_146_1.main_ids
			arg_145_0.mana_id = tonumber(arg_146_1.mana_id)
			arg_145_0.pet_id = tonumber(arg_146_1.pet_id)
			arg_145_0.summon_partner_id = tonumber(arg_146_1.partner_id)

			if arg_146_1.directional_show_id and tonumber(arg_146_1.directional_show_id) ~= 0 then
				arg_145_0.magic_show_id = tonumber(arg_146_1.directional_show_id)
			end

			if arg_145_0.lastCrystalFreeSummon < 1 then
				arg_145_0.crystalFreeSummon = 1
			else
				arg_145_0.crystalFreeSummon = 0
			end

			if arg_145_0.lastManaFreeSummon < 1 then
				arg_145_0.manaFreeSummon = 1
			else
				arg_145_0.manaFreeSummon = 0
			end

			if arg_146_1.mana_free_num then
				arg_145_0.manaFreeNum_ = tonumber(arg_146_1.mana_free_num)
			end
		end

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.SUMMON
		})

		if arg_145_2 then
			arg_145_2(arg_146_0, arg_146_1)
		end
	end, nil, false, arg_145_3)
end

function var_0_0.onLoadSummonInfo(arg_147_0, arg_147_1)
	local var_147_0 = arg_147_1.params

	arg_147_0.lastManaFreeSummon = tonumber(var_147_0.mana_free_time or 0)
	arg_147_0.lastCrystalFreeSummon = tonumber(var_147_0.crystal_free_time or 0)
	arg_147_0.second_ids = var_147_0.second_ids
	arg_147_0.main_ids = var_147_0.main_ids
	arg_147_0.mana_id = tonumber(var_147_0.mana_id)
	arg_147_0.summon_partner_id = tonumber(var_147_0.partner_id)

	if arg_147_0.lastCrystalFreeSummon < 1 then
		arg_147_0.crystalFreeSummon = 1
	else
		arg_147_0.crystalFreeSummon = 0
	end

	if arg_147_0.lastManaFreeSummon < 1 then
		arg_147_0.manaFreeSummon = 1
	else
		arg_147_0.manaFreeSummon = 0
	end

	if var_147_0.mana_free_num then
		arg_147_0.manaFreeNum_ = tonumber(var_147_0.mana_free_num)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.CHECK_MIDDLE_RED_MARK,
		params = xyd.CheckMiddleRed.SUMMON
	})
end

function var_0_0.loadArenaReports(arg_148_0, arg_148_1)
	xyd.Backend.get():request(xyd.mid.LOAD_ARENA_FIGHT_RECORDS, {}, function(arg_149_0, arg_149_1)
		if arg_149_0 == xyd.error.OK then
			local var_149_0 = arg_149_1.records
			local var_149_1 = xyd.db.arenaReportKeys:getAllArenaReportKeys(arg_148_0.playerID)
			local var_149_2 = {}

			arg_148_0.newReportKeyTable = {}

			for iter_149_0, iter_149_1 in ipairs(var_149_0) do
				if iter_149_1.report_key then
					table.insert(var_149_2, iter_149_1.report_key)
					table.insert(arg_148_0.newReportKeyTable, iter_149_1.report_key)
				end
			end

			for iter_149_2 = 1, #var_149_1 do
				for iter_149_3, iter_149_4 in ipairs(var_149_2) do
					if var_149_1[iter_149_2] == iter_149_4 then
						table.remove(var_149_2, iter_149_3)

						break
					end
				end
			end

			if #var_149_2 > 0 then
				arg_148_0.arenaRedMarkEnable = true

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.CHECK_MIDDLE_RED_MARK,
					params = xyd.CheckMiddleRed.ARENA
				})
			else
				arg_148_0.arenaRedMarkEnable = false
			end
		end
	end)
end

function var_0_0.loadPeakArenaReports(arg_150_0, arg_150_1)
	xyd.Backend.get():request(xyd.mid.PEAK_RECORDS, {}, function(arg_151_0, arg_151_1)
		if arg_151_0 == xyd.error.OK then
			local var_151_0 = arg_151_1
			local var_151_1 = xyd.db.peakArenaReportKeys:getAllReportKeys(arg_150_0.playerID)
			local var_151_2 = {}

			arg_150_0.newPeakReportKeyTable = {}

			for iter_151_0, iter_151_1 in ipairs(var_151_0) do
				if iter_151_1.report_key then
					table.insert(var_151_2, iter_151_1.report_key)
					table.insert(arg_150_0.newPeakReportKeyTable, iter_151_1.report_key)
				end
			end

			for iter_151_2 = 1, #var_151_1 do
				for iter_151_3, iter_151_4 in ipairs(var_151_2) do
					if var_151_1[iter_151_2] == iter_151_4 then
						table.remove(var_151_2, iter_151_3)

						break
					end
				end
			end

			if #var_151_2 > 0 then
				arg_150_0.peakArenaRedMarkEnable = true

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.CHECK_MIDDLE_RED_MARK,
					params = xyd.CheckMiddleRed.PEAK
				})
			else
				arg_150_0.peakArenaRedMarkEnable = false
			end

			if arg_150_1 then
				arg_150_1(arg_151_0)
			end
		end
	end)
end

function var_0_0.sellRunes(arg_152_0, arg_152_1, arg_152_2)
	xyd.Backend.get():request(xyd.mid.SELL_RUNES, {
		rune_ids = arg_152_1
	}, function(arg_153_0)
		if arg_153_0 == xyd.error.OK then
			for iter_153_0, iter_153_1 in pairs(arg_152_1) do
				arg_152_0.runeBag_:removeRune(iter_153_1)
			end
		end

		if arg_152_2 then
			arg_152_2(arg_153_0)
		end
	end)
end

function var_0_0.powerupHero(arg_154_0, arg_154_1, arg_154_2)
	xyd.Backend.get():request(xyd.mid.POWERUP_HERO, arg_154_1, function(arg_155_0, arg_155_1, arg_155_2)
		arg_154_2(arg_155_0, arg_155_1)
	end)
end

function var_0_0.oneKeyPowerUp(arg_156_0, arg_156_1, arg_156_2)
	xyd.Backend.get():request(xyd.mid.ONE_CLICK_JINJIE, arg_156_1, function(arg_157_0, arg_157_1)
		if arg_156_2 then
			arg_156_2(arg_157_0, arg_157_1)
		end
	end)
end

function var_0_0.oneKeyEquip(arg_158_0, arg_158_1, arg_158_2)
	xyd.Backend.get():request(xyd.mid.ONE_CLICK_EQUIP, arg_158_1, function(arg_159_0, arg_159_1)
		if arg_158_2 then
			arg_158_2(arg_159_0, arg_159_1)
		end
	end)
end

function var_0_0.evolveHero(arg_160_0, arg_160_1, arg_160_2)
	local var_160_0 = {
		partner_id = arg_160_1.partner_id
	}
	local var_160_1 = arg_160_1.hero

	xyd.Backend.get():request(xyd.mid.EVOLVE_HERO, var_160_0, function(arg_161_0, arg_161_1, arg_161_2)
		if arg_161_0 == xyd.error.OK and (not var_160_1:isSuper() or not (var_160_1:getStar() <= xyd.HERO_TOTAL_STARS)) then
			local var_161_0 = {
				itemID = var_160_1:getSuiPianID(),
				itemNum = xyd.StarLevelSuipian[var_160_1:getStar() + 1]
			}

			arg_160_0:getBackpack():removeItem(var_161_0)
		end

		arg_160_2(arg_161_0, arg_161_1)
	end)
end

function var_0_0.awakeHero(arg_162_0, arg_162_1, arg_162_2)
	xyd.Backend.get():request(xyd.mid.AWAKE_HERO, arg_162_1, function(arg_163_0, arg_163_1, arg_163_2)
		if arg_163_0 == xyd.error.OK then
			local var_163_0 = arg_162_0:getHeroByID(arg_162_1.partner_id)
			local var_163_1 = var_163_0:getTableID()

			if var_163_0:getHeroRarity() == xyd.HeroRarity.PURLE then
				var_163_1 = xyd.tables.hero:unawakenID(var_163_1)
			end

			local var_163_2 = xyd.tables.hero:essences(var_163_1)

			for iter_163_0, iter_163_1 in pairs(var_163_2) do
				local var_163_3 = iter_163_1.id

				arg_162_0.essences_[var_163_3] = arg_162_0.essences_[var_163_3] - iter_163_1.num

				if arg_162_0.essences_[var_163_3] == 0 then
					arg_162_0.essences_[var_163_3] = nil
				end
			end

			arg_162_0:heroUpdateEvent_({
				name = xyd.event.HERO_UPDATE,
				params = arg_163_1,
				userdata = arg_163_2
			}, true)
		end

		arg_162_2(arg_163_0, arg_163_1)
	end)
end

function var_0_0.heroUpdateEvent_(arg_164_0, arg_164_1, arg_164_2)
	local var_164_0

	if arg_164_1.params.partner_id then
		var_164_0 = arg_164_1.params
	elseif arg_164_1.params.partner then
		var_164_0 = arg_164_1.params.partner
	elseif arg_164_1.params.partner_info then
		var_164_0 = arg_164_1.params.partner_info
	end

	if var_164_0 ~= nil then
		local var_164_1 = var_0_1.new()

		var_164_1:populate(var_164_0)
		arg_164_0:updateHero(var_164_1)
	end

	if not arg_164_2 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.HERO_UPDATE_COMPLETE
		})
	end
end

function var_0_0.expandHeroSlots(arg_165_0, arg_165_1, arg_165_2)
	xyd.Backend.get():request(xyd.mid.EXPAND_HERO_SLOTS, arg_165_1, function(arg_166_0, arg_166_1, arg_166_2)
		if arg_166_0 == xyd.error.OK then
			local var_166_0 = xyd.tables.misc.expandHeroSlotNum

			arg_165_0.maxHeroNumLimit_ = arg_165_0.maxHeroNumLimit_ + var_166_0

			arg_165_0:heroUpdateEvent_({
				name = xyd.event.HERO_UPDATE,
				params = arg_166_1,
				userdata = arg_166_2
			})
		end

		arg_165_2(arg_166_0)
	end)
end

function var_0_0.setRepHero(arg_167_0, arg_167_1, arg_167_2)
	local var_167_0 = arg_167_1.partner_id

	if arg_167_0:getRepHero() and arg_167_0:getRepHero():getHeroID() == var_167_0 then
		arg_167_2(xyd.error.OK)
	else
		xyd.Backend.get():request(xyd.mid.SET_REP_HERO, arg_167_1, function(arg_168_0, arg_168_1, arg_168_2)
			if arg_168_0 == xyd.error.OK then
				arg_167_0:updateRepHero(var_167_0)
				arg_167_0:heroUpdateEvent_({
					name = xyd.event.HERO_UPDATE,
					params = arg_168_1,
					userdata = arg_168_2
				})
			end

			arg_167_2(arg_168_0)
		end)
	end
end

function var_0_0.setLockHero(arg_169_0, arg_169_1, arg_169_2)
	local var_169_0 = arg_169_1.partner_id
	local var_169_1 = arg_169_1.is_lock

	if arg_169_0:getHeroByID(var_169_0):isLock() == var_169_1 then
		arg_169_2(xyd.error.OK)
	else
		xyd.Backend.get():request(xyd.mid.SET_LOCK_HERO, arg_169_1, function(arg_170_0, arg_170_1, arg_170_2)
			if arg_170_0 == xyd.error.OK then
				arg_169_0:getHeroByID(var_169_0):setIsLock(var_169_1)
				arg_169_0:heroUpdateEvent_({
					name = xyd.event.HERO_UPDATE,
					params = arg_170_1,
					userdata = arg_170_2
				})
			end

			arg_169_2(arg_170_0)
		end)
	end
end

function var_0_0.dismissHero(arg_171_0, arg_171_1, arg_171_2)
	xyd.Backend.get():request(xyd.mid.DISMISS_HERO, arg_171_1, function(arg_172_0, arg_172_1, arg_172_2)
		if arg_172_0 == xyd.error.OK then
			arg_171_0:deleteHero(arg_171_1.partner_id)
			arg_171_0:heroUpdateEvent_({
				name = xyd.event.HERO_UPDATE,
				params = arg_172_1,
				userdata = arg_172_2
			})
		end

		arg_171_2(arg_172_0)
	end)
end

function var_0_0.searchPlayer(arg_173_0, arg_173_1, arg_173_2)
	xyd.Backend.get():request(xyd.mid.SEARCH_PLAYER, arg_173_1, function(arg_174_0, arg_174_1)
		arg_173_2(arg_174_0, arg_174_1)
	end)
end

function var_0_0.onRecharge_(arg_175_0, arg_175_1)
	if arg_175_1.params.params.items == nil then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, string.format(xyd.tables.translation:translation("RECHARGE_SUC"), arg_175_1.params.params.delta))
	else
		arg_175_0:handleRewards(arg_175_1.params.params.items)
	end

	if arg_175_1.params.params.skin_ids then
		local var_175_0 = arg_175_1.params.params.items[1].table_id
		local var_175_1 = xyd.tables.skinSkill:getHeroID(var_175_0)
		local var_175_2 = arg_175_0:getHeroIgnoreAwaken(var_175_1)

		if var_175_2 then
			var_175_2:setSkinInfo(var_175_2.skinId_, arg_175_1.params.params.skin_ids)

			local var_175_3 = xyd.tables.skinSkill:getSkillID(var_175_0)

			if var_175_3 and var_175_3 > 0 then
				xyd.db.skinSkillRedMark:updateSkinSkillRedMark(arg_175_0.playerID, var_175_2:getHeroID(), 1)
			end

			local var_175_4 = {
				itemID = var_175_0,
				itemNum = arg_175_1.params.params.remove_item or 1
			}

			arg_175_0:getBackpack():removeItem(var_175_4)
		end
	end

	local var_175_5 = arg_175_1.params.params.charge_id

	if var_175_5 then
		if var_175_5 == xyd.tables.misc:getValue("battle_pass_charge_id") then
			xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS):onCharge()
		elseif var_175_5 == xyd.tables.misc:getValue("battle_pass_deluxe_charge_id") then
			xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS):onDeluxeCharge()
		end
	end

	arg_175_0.crystal = arg_175_1.params.params.total

	local var_175_6 = arg_175_0.vip

	arg_175_0.vip = arg_175_1.params.params.vip

	if var_175_6 < 1 and arg_175_0.vip >= 1 then
		xyd.tracking(xyd.AFInAppEventType.VIP_1)
	end

	if var_175_6 < 2 and arg_175_0.vip >= 2 then
		xyd.tracking(xyd.AFInAppEventType.VIP_2)
	end

	if var_175_6 < 3 and arg_175_0.vip >= 3 then
		xyd.tracking(xyd.AFInAppEventType.VIP_3)
	end

	if var_175_6 < 4 and arg_175_0.vip >= 4 then
		xyd.tracking(xyd.AFInAppEventType.VIP_4)
	end

	if var_175_6 < 5 and arg_175_0.vip >= 5 then
		xyd.tracking(xyd.AFInAppEventType.VIP_5)
	end

	if var_175_6 < 9 and arg_175_0.vip >= 9 then
		xyd.tracking(xyd.AFInAppEventType.VIP_9)
	end

	arg_175_0.charge = arg_175_1.params.params.charge
	arg_175_0.leftCardDay = tonumber(arg_175_1.params.params.left_card_day) or 0
	arg_175_0.leftWeekCardDay = tonumber(arg_175_1.params.params.left_week_card_day) or 0
	arg_175_0.leftEnergyMonthCardDay = tonumber(arg_175_1.params.params.left_month_tili_day) or 0
	arg_175_0.privilegeLeftCardDay = tonumber(arg_175_1.params.params.privilege_left_card_day) or 0
	arg_175_0.privilegeLeftCardEnd = tonumber(arg_175_1.params.params.privilege_month_card_end) or 0

	local var_175_7 = xyd.WindowManager.get():getWindow("vip_recharge")

	if var_175_7 then
		var_175_7:update()
	else
		arg_175_0:queryChargeData()
	end

	local var_175_8 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_175_8 then
		var_175_8:updatePlayerInfo()
	end

	local var_175_9 = xyd.WindowManager.get():getWindow("new_push_window")

	if var_175_9 then
		var_175_9:updateTimes()
	end

	arg_175_0:onUpdateActivitiesState_()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.ECONOMY,
		params = arg_175_1.params.params.economy
	})
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_CHARGE_ACTIVITY
	})
	arg_175_0:onUpdateMonthCard()
end

function var_0_0.getNewIDs(arg_176_0)
	local var_176_0 = {}
	local var_176_1 = 80001001

	for iter_176_0, iter_176_1 in pairs(arg_176_0.vipChargeData) do
		if tonumber(iter_176_1) == 0 and iter_176_0 ~= var_176_1 then
			table.insert(var_176_0, iter_176_0)
		end
	end

	return var_176_0
end

function var_0_0.onPlayerNotice_(arg_177_0, arg_177_1)
	local var_177_0 = arg_177_1.params

	if not var_177_0 then
		return
	end

	if var_177_0.notice_type == xyd.NoticeType.ARENA then
		arg_177_0.arenaRedMarkEnable = true

		arg_177_0:loadArenaReports()
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.ARENA
		})
	elseif var_177_0.notice_type == xyd.NoticeType.OPEN_TRIAL then
		arg_177_0.trialLoaded_ = false

		arg_177_0:loadTrialInfos(function()
			return
		end)
	elseif var_177_0.notice_type == xyd.NoticeType.OPEN_LEVEL then
		xyd.Backend.get():request(xyd.mid.GET_MAXLEVEL, {}, function(arg_179_0, arg_179_1)
			if arg_179_0 == xyd.error.OK then
				arg_177_0.maxTeamLev = tonumber(arg_179_1.max_lev)
				arg_177_0.maxHeroColor = tonumber(arg_179_1.max_color)
			end
		end)
	elseif var_177_0.notice_type == xyd.NoticeType.OPEN_CAMPAIGN then
		arg_177_0.worldMapLoaded_ = false

		arg_177_0:loadWorldMap(function()
			return
		end)
	elseif var_177_0.notice_type == xyd.NoticeType.TOP then
		arg_177_0.peakArenaRedMarkEnable = true

		arg_177_0:loadPeakArenaReports()
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.PEAK
		})
	elseif var_177_0.notice_type == xyd.NoticeType.GUILD_BE_APPLYED then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.GUILD_APPLY_NOTICE
		})
	elseif var_177_0.notice_type == xyd.NoticeType.OPEN_SERVER then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.OPEN_SERVICE_ACTIVITY_NOTICE
		})
	elseif var_177_0.notice_type == xyd.NoticeType.GM_TALK then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
			params = {
				index = 1,
				show = true
			}
		})

		local var_177_1 = xyd.WindowManager.get():getWindow("chat")
		local var_177_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER)

		var_177_2.isNews[var_177_2.GM_CHANNEL] = true

		if var_177_1 and var_177_2:getChannel() == var_177_2.GM_CHANNEL then
			var_177_1:switchToGMChannel()
		end
	elseif var_177_0.notice_type == xyd.NoticeType.MAIL then
		local var_177_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.MAILBOX)

		if var_177_3.newMailTotal and var_177_3.newMailTotal >= 0 then
			var_177_3:incrNewMail()
		else
			var_177_3.newMailTotal = 1
		end

		var_177_3:checkNewMail()
	elseif var_177_0.notice_type == xyd.NoticeType.JIGSAW_CHANGE then
		arg_177_0.newJigIds = arg_177_0.newJigIds or {}

		local var_177_4 = var_177_0.params.type
		local var_177_5 = var_177_0.params.count

		arg_177_0.jigsaw = xyd.ModelManager.get():loadModel(xyd.ModelType.JIGSAW)

		if not arg_177_0.jigsaw.details then
			return
		end

		local var_177_6 = clone(arg_177_0.jigsaw.details.jig_infos)
		local var_177_7 = 20

		for iter_177_0 = 1, var_177_7 do
			if xyd.tables.ActivityJigsaw:type(var_177_6[iter_177_0].jigsaw_id) == var_177_4 then
				arg_177_0.jigsaw.details.jig_infos[iter_177_0].count = var_177_5

				if var_177_5 and var_177_6[iter_177_0].count and xyd.tables.ActivityJigsaw:amount(var_177_6[iter_177_0].jigsaw_id) and var_177_6[iter_177_0].count < xyd.tables.ActivityJigsaw:amount(var_177_6[iter_177_0].jigsaw_id) and var_177_5 >= xyd.tables.ActivityJigsaw:amount(var_177_6[iter_177_0].jigsaw_id) then
					table.insert(arg_177_0.newJigIds, var_177_6[iter_177_0].jigsaw_id)
				end
			end
		end

		if arg_177_0.newJigIds and next(arg_177_0.newJigIds) and not xyd.WindowManager.get():isWindowOpen("jigsaw_view") and display.getRunningScene().__cname ~= "BattleCreate" and display.getRunningScene().__cname ~= "BattleScene" then
			local var_177_8 = {
				ids = arg_177_0.newJigIds
			}

			arg_177_0.newJigIds = {}

			xyd.WindowManager.get():openWindow("jigsaw_view", var_177_8)
		end

		arg_177_0.jigsaw:updateRedMark()
	elseif var_177_0.notice_type == xyd.NoticeType.PLAYOFFS then
		xyd.Backend.get():request(xyd.mid.PLAYOFFS_CONFIRM_SELECT_TEAM, {
			stage = var_177_0.params.stage,
			room_key = var_177_0.params.room_key
		}, function(arg_181_0, arg_181_1)
			if arg_181_0 == xyd.error.OK then
				print("Already Confirm The Request.")
			end
		end)

		if var_177_0.params.is_open == 0 and not xyd.WindowManager.get():getWindow("playoffs_vs_ready") then
			if not xyd.WindowManager.get():getWindow("battle_top") and not xyd.WindowManager.get():getWindow("battle_lose") and not xyd.WindowManager.get():getWindow("battle_win") and not xyd.WindowManager.get():getWindow("battle_select_team") and not xyd.WindowManager.get():getWindow("sync_select_team") then
				if xyd.WindowManager.get():getWindow("social_system_select_mode") then
					xyd.WindowManager.get():closeWindow("social_system_select_mode")
				end

				if xyd.WindowManager.get():getWindow("social_system_waiting") then
					xyd.WindowManager.get():closeWindow("social_system_waiting")
				end

				if xyd.WindowManager.get():getWindow("social_system_mode_info") then
					xyd.WindowManager.get():closeWindow("social_system_mode_info")
				end

				local var_177_9 = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_CASUAL_ARENA)

				if var_177_9 and var_177_9.isMatching then
					var_177_9.isMatching = false
				end

				xyd.WindowManager.get():openWindow("playoffs_vs_ready", var_177_0.params)
			else
				if xyd.WindowManager.get():getWindow("toast") ~= nil then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("PLAYOFFS_BATTLING")
				})
			end
		elseif var_177_0.params.is_open == 0 and xyd.WindowManager.get():getWindow("playoffs_vs_ready") and not tolua.isnull(xyd.WindowManager.get():getWindow("playoffs_vs_ready")) then
			xyd.WindowManager.get():getWindow("playoffs_vs_ready"):updateReadyFlag(var_177_0.params)
		elseif var_177_0.params.is_open == 1 and var_177_0.params.stage == 0 then
			if xyd.WindowManager.get():getWindow("playoffs_vs_ready") then
				xyd.WindowManager.get():closeWindow("playoffs_vs_ready")
			end

			if xyd.WindowManager.get():getWindow("sync_select_team") and xyd.WindowManager.get():getWindow("sync_select_team").stage >= 8 then
				xyd.WindowManager.get():closeWindow("sync_select_team")
			end

			if not xyd.WindowManager.get():getWindow("battle_top") and not xyd.WindowManager.get():getWindow("battle_lose") and not xyd.WindowManager.get():getWindow("battle_win") then
				if not xyd.WindowManager.get():getWindow("playoffs_vs_round") and (not xyd.WindowManager.get():getWindow("sync_select_team") or xyd.WindowManager.get():getWindow("sync_select_team").stage ~= 0) then
					xyd.WindowManager.get():closeAllWindows()
					xyd.WindowManager.get():openWindow("playoffs_vs_round", var_177_0.params)
				end
			else
				if xyd.WindowManager.get():getWindow("toast") ~= nil then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("PLAYOFFS_BATTLING")
				})
			end

			local var_177_10 = 2

			if not arg_177_0.playoffsHandle then
				arg_177_0.playoffsHandle = var_0_2.scheduleGlobal(function()
					var_177_10 = var_177_10 - 1

					if var_177_10 <= 0 then
						if xyd.WindowManager.get():getWindow("playoffs_vs_round") then
							xyd.WindowManager.get():closeWindow("playoffs_vs_round")
						end

						if not xyd.WindowManager.get():getWindow("sync_select_team") then
							if not xyd.WindowManager.get():getWindow("battle_top") and not xyd.WindowManager.get():getWindow("battle_lose") and not xyd.WindowManager.get():getWindow("battle_select_team") and not xyd.WindowManager.get():getWindow("select_team_peak") and not xyd.WindowManager.get():getWindow("select_team_rearena") and not xyd.WindowManager.get():getWindow("battle_win") and not xyd.WindowManager.get():getWindow("battle_loading_new") then
								xyd.WindowManager.get():closeAllWindows()
								xyd.WindowManager.get():openWindow("sync_select_team", var_177_0.params)
							else
								if xyd.WindowManager.get():getWindow("toast") ~= nil then
									xyd.WindowManager.get():closeWindow("toast")
								end

								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_3:translation("PLAYOFFS_BATTLING")
								})
							end
						end

						var_0_2.unscheduleGlobal(arg_177_0.playoffsHandle)

						arg_177_0.playoffsHandle = nil
					end
				end, 1)
			end
		elseif var_177_0.params.is_open == 1 and var_177_0.params.stage ~= 0 then
			if xyd.WindowManager.get():getWindow("sync_select_team") then
				xyd.WindowManager.get():getWindow("sync_select_team"):updateSelectHeroes(var_177_0.params)
			elseif not xyd.WindowManager.get():getWindow("battle_top") and not xyd.WindowManager.get():getWindow("battle_lose") and not xyd.WindowManager.get():getWindow("battle_select_team") and not xyd.WindowManager.get():getWindow("select_team_peak") and not xyd.WindowManager.get():getWindow("select_team_rearena") and not xyd.WindowManager.get():getWindow("battle_win") and not xyd.WindowManager.get():getWindow("battle_loading_new") then
				xyd.WindowManager.get():closeAllWindows()
				xyd.WindowManager.get():openWindow("sync_select_team", var_177_0.params, function()
					xyd.WindowManager.get():getWindow("sync_select_team"):updateSelectHeroes(var_177_0.params)
				end)
			end
		end
	elseif var_177_0.notice_type == xyd.NoticeType.FRIEND_FIGHT then
		if not xyd.WindowManager.get():getWindow("battle_top") and not xyd.WindowManager.get():getWindow("battle_lose") and not xyd.WindowManager.get():getWindow("battle_win") and not xyd.WindowManager.get():getWindow("battle_select_team") and not xyd.WindowManager.get():getWindow("select_team_peak") and not xyd.WindowManager.get():getWindow("select_team_rearena") and not xyd.WindowManager.get():getWindow("sync_select_team") then
			xyd.WindowManager.get():openWindow("social_system_mode_info", var_177_0.params)
		else
			xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM):rejectFriendFight({
				player_id = var_177_0.params.player_info.player_id
			})
		end
	elseif var_177_0.notice_type == xyd.NoticeType.REJECT_FRIEND_FIGHT then
		if xyd.WindowManager.get():getWindow("social_system_waiting") then
			xyd.WindowManager.get():getWindow("social_system_waiting"):setHasRefusedShow()
		end
	elseif var_177_0.notice_type == xyd.NoticeType.FIREWORK then
		if var_177_0.params and next(var_177_0.params) then
			for iter_177_1, iter_177_2 in ipairs(var_177_0.params.items) do
				arg_177_0:getBackpack():addItemsByID(tonumber(iter_177_2.item_id), tonumber(iter_177_2.item_num))
			end

			xyd.WindowManager.get():openWindow("halloween_award_items", var_177_0.params)
		end
	elseif var_177_0.notice_type == xyd.NoticeType.ACHIEVEMENT then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT):handleNewAchievementNotice(var_177_0.params)

		arg_177_0.newAchievementIds = arg_177_0.newAchievementIds or {}

		if var_177_0.params.achieve_id then
			table.insert(arg_177_0.newAchievementIds, var_177_0.params.achieve_id)
		end

		arg_177_0:handleNewAchievements()
	elseif var_177_0.notice_type == xyd.NoticeType.SINGLE_DAY then
		arg_177_0.singleDay = xyd.ModelManager.get():loadModel(xyd.ModelType.SINGLE_DAY)

		arg_177_0.singleDay:loadInfo({}, function(arg_184_0, arg_184_1)
			if arg_184_0 == xyd.error.OK then
				arg_177_0:handleSingleDayNotice(var_177_0.params)
			end
		end)
	elseif var_177_0.notice_type == xyd.NoticeType.LIBRARY_MISSION then
		xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY):freshSingleMission(var_177_0.params)
	elseif var_177_0.notice_type == xyd.NoticeType.LIBRARY_RANDOM_EVENT then
		local var_177_11 = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)

		var_177_11:freshSingleDialog(var_177_0.params.dialog_info, var_177_0.params.partner_id)

		if var_177_0.params.partner_library_info then
			var_177_11:insertNewPartnerInfo(var_177_0.params.partner_library_info, var_177_0.params.partner_id)
		end
	elseif var_177_0.notice_type == xyd.NoticeType.LIBRARY_PARTNER_LOG then
		xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY):freshPartnerLog(var_177_0.params.log_info, var_177_0.params.partner_id)
	elseif var_177_0.notice_type == xyd.NoticeType.MASTER_MISSION then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.UPDATE_MASTER_MISSION,
			params = var_177_0.params.mission_info
		})
	elseif var_177_0.notice_type == xyd.NoticeType.MASTER_FRESH then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REFRESH_MASTER,
			params = var_177_0.params
		})
	elseif var_177_0.notice_type == xyd.NoticeType.GIFT_PUSH then
		xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):setGift(var_177_0.params)
	elseif var_177_0.notice_type == xyd.NoticeType.SUMMER_FISH_NET then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER):updateFishNet(var_177_0.params)
	elseif var_177_0.notice_type == xyd.NoticeType.CHARGE_REWARDS then
		local var_177_12 = var_177_0.params.awards or {}

		arg_177_0:handleRewards(var_177_12)
	elseif var_177_0.notice_type == xyd.NoticeType.AVATAR then
		local var_177_13 = var_177_0.params.avatar_id or {}

		arg_177_0:getBackpack():addItemsByID(var_177_13, 1)
	elseif var_177_0.notice_type == xyd.NoticeType.ROOM_NOTICE then
		arg_177_0:handleRoomNotice(var_177_0.params)
	elseif var_177_0.notice_type == xyd.NoticeType.ADVENTURE_EVENT_OCCUR then
		arg_177_0.AdventureEventOccurIds = arg_177_0.AdventureEventOccurIds or {}

		if var_177_0.params then
			local var_177_14 = {
				eventId = tostring(var_177_0.params.table_id),
				eventInfo = {
					special_data = var_177_0.params.special_data,
					end_time = var_177_0.params.end_time,
					extra_data = var_177_0.params.extra_data,
					table_id = var_177_0.params.table_id
				}
			}

			table.insert(arg_177_0.AdventureEventOccurIds, var_177_14)

			if var_177_0.params.server_time ~= nil then
				xyd.ServerTime.get():resetServerTime(var_177_0.params.server_time)
			end
		end

		arg_177_0:handleAdventureEventOccurNotice()
	elseif var_177_0.notice_type == xyd.NoticeType.ADVENTURE_EVENT_FINISH then
		arg_177_0.AdventureEventFinishIds = var_177_0.params or {}

		arg_177_0:handleAdventureEventFinishNotice()
	elseif var_177_0.notice_type == xyd.NoticeType.SNOW_UNLOCK_EFFECT then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY):updateUnlockEffect(var_177_0.params.unlock_effect_ids)

		local var_177_15 = xyd.WindowManager.get():getWindow("snow_info")

		if var_177_15 and not tolua.isnull(var_177_15) then
			var_177_15:updateRight()
		end
	elseif var_177_0.notice_type == xyd.NoticeType.LEVEL_CHARGE_REDMARK then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadActivities(function(arg_185_0, arg_185_1)
			return
		end)
	elseif var_177_0.notice_type == xyd.NoticeType.GIRL_TRAINING then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadActivities(function(arg_186_0, arg_186_1)
			return
		end)
	elseif var_177_0.notice_type == xyd.NoticeType.GIRL_TRAINING2 then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadActivities(function(arg_187_0, arg_187_1)
			return
		end)
	elseif var_177_0.notice_type == xyd.NoticeType.JIGSAW2_CHANGE then
		arg_177_0.newJig2Ids = arg_177_0.newJig2Ids or {}

		local var_177_16 = var_177_0.params.type
		local var_177_17 = var_177_0.params.count

		arg_177_0.jigsaw2 = xyd.ModelManager.get():loadModel(xyd.ModelType.JIGSAW2)

		if not arg_177_0.jigsaw2.details then
			return
		end

		local var_177_18 = clone(arg_177_0.jigsaw2.details.jig_infos)
		local var_177_19 = 20

		for iter_177_3 = 1, var_177_19 do
			if xyd.tables.ActivityJigsaw2:type(var_177_18[iter_177_3].jigsaw_id) == var_177_16 then
				arg_177_0.jigsaw2.details.jig_infos[iter_177_3].count = var_177_17

				if var_177_17 and var_177_18[iter_177_3].count and xyd.tables.ActivityJigsaw2:amount(var_177_18[iter_177_3].jigsaw_id) and var_177_18[iter_177_3].count < xyd.tables.ActivityJigsaw2:amount(var_177_18[iter_177_3].jigsaw_id) and var_177_17 >= xyd.tables.ActivityJigsaw2:amount(var_177_18[iter_177_3].jigsaw_id) then
					table.insert(arg_177_0.newJig2Ids, var_177_18[iter_177_3].jigsaw_id)
				end
			end
		end

		if arg_177_0.newJig2Ids and next(arg_177_0.newJig2Ids) and not xyd.WindowManager.get():isWindowOpen("jigsaw2_view") and display.getRunningScene().__cname ~= "BattleCreate" and display.getRunningScene().__cname ~= "BattleScene" then
			local var_177_20 = {
				ids = arg_177_0.newJig2Ids
			}

			arg_177_0.newJig2Ids = {}

			xyd.WindowManager.get():openWindow("jigsaw2_view", var_177_20)
		end

		arg_177_0.jigsaw2:updateRedMark()
	elseif var_177_0.notice_type == xyd.NoticeType.CHAMPIONS_LEAGUE then
		arg_177_0.championsRedMarkEnable = true

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHAMPIONS_CHECK_REDMARK
		})
	end
end

function var_0_0.handleAdventureEventOccurNotice(arg_188_0)
	local var_188_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

	if arg_188_0.AdventureEventOccurIds and next(arg_188_0.AdventureEventOccurIds) and display.getRunningScene().__cname == "MainScene" then
		for iter_188_0, iter_188_1 in pairs(arg_188_0.AdventureEventOccurIds) do
			var_188_0:adventureEventOccur(iter_188_1)
		end

		local var_188_1 = arg_188_0.AdventureEventOccurIds

		arg_188_0.AdventureEventOccurIds = {}

		xyd.WindowManager.get():openWindow("adventure_occur", var_188_1)
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.ADVENTURE_EVENT_OCCUR
		})
	end
end

function var_0_0.handleAdventureEventFinishNotice(arg_189_0)
	local var_189_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)

	if display.getRunningScene().__cname == "MainScene" and arg_189_0.AdventureEventFinishIds and next(arg_189_0.AdventureEventFinishIds) then
		var_189_0:adventureEventFinish(tostring(arg_189_0.AdventureEventFinishIds.table_id))
		xyd.WindowManager.get():openWindow("adventure_finish", arg_189_0.AdventureEventFinishIds)

		arg_189_0.AdventureEventFinishIds = {}

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.ADVENTURE_EVENT_FINISH
		})
	end
end

function var_0_0.handleRoomNotice(arg_190_0, arg_190_1)
	if arg_190_1.room_type == xyd.RoomType.OCCULT then
		xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT):handleRoomNotice(arg_190_1)
	elseif arg_190_1.room_type == xyd.RoomType.ADV_TEAM then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT):handleResponse(arg_190_1)
	elseif arg_190_1.room_type == xyd.RoomType.ADVENTURE then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT):handleDefenseResponse(arg_190_1)
	elseif arg_190_1.room_type == xyd.RoomType.RAGNAROK then
		xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK):notice(arg_190_1)
	end
end

function var_0_0.handleSingleDayNotice(arg_191_0, arg_191_1)
	local var_191_0 = xyd.WindowManager.get():getWindow("single_day")

	if not var_191_0 or tolua.isnull(var_191_0) then
		return
	end

	var_191_0:update()
	var_191_0:handleAlertWindow(arg_191_1.type)
end

function var_0_0.handleNewAchievements(arg_192_0)
	if arg_192_0.newAchievementIds and next(arg_192_0.newAchievementIds) and display.getRunningScene().__cname == "MainScene" then
		local var_192_0 = {
			ids = arg_192_0.newAchievementIds
		}

		arg_192_0.newAchievementIds = {}

		local var_192_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT)

		if not var_192_1.achieveList or not next(var_192_1.achieveList) then
			var_192_1:loadAchievementInfo({}, function(arg_193_0, arg_193_1)
				if arg_193_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("achievement_get", var_192_0)
				end
			end)
		else
			xyd.WindowManager.get():openWindow("achievement_get", var_192_0)
		end
	end
end

function var_0_0.editName(arg_194_0, arg_194_1, arg_194_2)
	xyd.Backend.get():request(xyd.mid.EDIT_PLAYER_NAME, arg_194_1, function(arg_195_0, arg_195_1)
		if arg_195_0 == xyd.error.OK then
			arg_194_0.playerName = arg_194_1.player_name
		end

		arg_194_2(arg_195_0, arg_195_1)
	end)
end

function var_0_0.loadSignInfo(arg_196_0, arg_196_1)
	if arg_196_0.signInfoLoaded_ then
		if arg_196_1 then
			arg_196_1()
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_SIGN_INFO, {}, function(arg_197_0, arg_197_1)
			if arg_197_0 == xyd.error.OK then
				arg_196_0.signAwards = arg_197_1.awards

				arg_196_0:setSignIn(arg_197_1.is_signed)

				arg_196_0.signPartnerID = arg_197_1.partner_id
				arg_196_0.signTimes = arg_197_1.sign_times
				arg_196_0.signMonth = arg_197_1.month
				arg_196_0.signPartnerIsSkin = arg_197_1.is_skin
				arg_196_0.signInfoLoaded_ = true

				if arg_196_0.signAwards then
					for iter_197_0 = 1, #arg_196_0.signAwards do
						if xyd.tables.item:type(arg_196_0.signAwards[iter_197_0].award_item_id) == -1 then
							arg_196_0.signHeroPos = iter_197_0

							break
						end
					end
				end

				if arg_196_1 then
					arg_196_1()
				end
			end
		end)
	end
end

function var_0_0.setSignIn(arg_198_0, arg_198_1)
	arg_198_0.isSigned = arg_198_1

	arg_198_0:refreshActivityRedMark()
end

function var_0_0.setActivity(arg_199_0, arg_199_1)
	if arg_199_1 then
		arg_199_0.isActivity = 1
	else
		arg_199_0.isActivity = 0
	end

	arg_199_0:refreshActivityRedMark()
end

function var_0_0.setInvite(arg_200_0, arg_200_1)
	if arg_200_1 ~= arg_200_0.isInviteAward then
		arg_200_0:refreshFriendRedMark()
	end

	if arg_200_1 then
		arg_200_0.isInviteAward = 1
	else
		arg_200_0.isInviteAward = 0
	end
end

function var_0_0.refreshFriendRedMark(arg_201_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
		params = {
			index = 3
		}
	})
end

function var_0_0.refreshActivityRedMark(arg_202_0)
	if arg_202_0.isActivity == 1 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
			params = {
				index = 3,
				show = true
			}
		})
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REfRESH_ACTIVITIES_NOTIFY,
			params = {
				index = 3,
				show = true
			}
		})
	else
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
			params = {
				index = 3,
				show = false
			}
		})
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REfRESH_ACTIVITIES_NOTIFY,
			params = {
				index = 3,
				show = false
			}
		})
	end
end

function var_0_0.checkEquipableAndSummon(arg_203_0)
	if not arg_203_0:getBackpack() then
		return
	end

	local var_203_0 = false

	if arg_203_0.heros_ and next(arg_203_0.heros_) then
		for iter_203_0, iter_203_1 in pairs(arg_203_0.heros_) do
			for iter_203_2 = 1, 6 do
				if iter_203_1:canEquipItem(iter_203_2) then
					var_203_0 = true

					break
				end
			end

			if var_203_0 == true then
				break
			end
		end
	end

	for iter_203_3, iter_203_4 in pairs(xyd.tables.hero:getPartnerDistanceType()) do
		local var_203_1 = xyd.tables.hero:afterAwaken(iter_203_3)

		if var_203_1 > 0 and arg_203_0:getHeroByTableID(iter_203_3) == nil and arg_203_0:getHeroByTableID(var_203_1) == nil then
			local var_203_2 = var_0_1.new()

			var_203_2:initUnCollected(iter_203_3)

			if var_203_2:canSummon() and not xyd.isSuperHero(iter_203_3) then
				var_203_0 = true

				break
			end
		end
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
		params = {
			index = 6,
			show = var_203_0
		}
	})
end

function var_0_0.queryChargeData(arg_204_0, arg_204_1)
	xyd.Backend.get():request(xyd.mid.QUERY_CHARGE_DATA, {}, function(arg_205_0, arg_205_1)
		if arg_205_0 == xyd.error.OK then
			arg_204_0.vipChargeData = {}
			arg_204_0.charges = {}
			arg_204_0.lastbuyTimes = {}
			arg_204_0.charges = arg_205_1.charges

			for iter_205_0, iter_205_1 in ipairs(arg_205_1.charges or {}) do
				arg_204_0.vipChargeData[iter_205_1.charge_id] = iter_205_1.charge_count
			end

			for iter_205_2, iter_205_3 in ipairs(arg_205_1.charges or {}) do
				arg_204_0.lastbuyTimes[iter_205_3.charge_id] = iter_205_3.last_buy_time
			end

			arg_204_0.vipGiftBoxData = arg_205_1.giftbags or {}

			if arg_205_1.server_time then
				xyd.ServerTime.get():resetServerTime(arg_205_1.server_time)
			end

			if arg_204_1 then
				arg_204_1(arg_205_0, arg_205_1)
			end
		end
	end, {}, true, true)
end

function var_0_0.getServerTime(arg_206_0)
	xyd.Backend.get():request(xyd.mid.QUERY_SERVER_TIME, {}, nil, {}, true, true)
end

function var_0_0.onUpdateStoneEquipCampaign_(arg_207_0, arg_207_1)
	local var_207_0 = xyd.WindowManager.get():getWindow("stone")
	local var_207_1 = xyd.WindowManager.get():getWindow("item_compose")
	local var_207_2 = xyd.WindowManager.get():getWindow("hero_main")
	local var_207_3 = arg_207_1.params.itemComposeID

	if var_207_0 then
		var_207_0:updateStoneCampaign()
	end

	if var_207_1 and var_207_1.isShowGainWay then
		var_207_1:showGainWay(var_207_3)
	end

	if var_207_2 then
		var_207_2:updateHeroStar()
	end
end

function var_0_0.onUpdateSysTime_(arg_208_0, arg_208_1)
	if arg_208_0.playerID and arg_208_0.playerID > 0 then
		arg_208_0:getServerTime()
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.UPDATE_MISSION_ONTIME
		})
	end
end

function var_0_0.onUpdateActivitiesState_(arg_209_0, arg_209_1)
	local var_209_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

	var_209_0:loadActivities(function(arg_210_0)
		if arg_210_0 == xyd.error.OK then
			wnd = xyd.WindowManager.get():getWindow("activities")

			if wnd then
				wnd.activities = var_209_0:getActivitiesList()

				wnd:rightLayout()

				if wnd.count then
					wnd:leftLayout(wnd.count)
				end
			end
		end
	end)
end

function var_0_0.onUpdateMonthCard(arg_211_0)
	local var_211_0 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_211_0 then
		var_211_0:checkMonthCardShow()
	end
end

function var_0_0.getStoryABTestType(arg_212_0)
	return arg_212_0.storyABTest_ or xyd.storyABTest.Battle
end

function var_0_0.onTreasuerLoadSPInfo_(arg_213_0, arg_213_1)
	arg_213_0.treasureSP = arg_213_1.params.sp or 0
	arg_213_0.lastTreasureSP = arg_213_1.params.sp_last_refresh_time or 0
	arg_213_0.buyTreasureSPTimes = arg_213_1.params.refresh_sp_times or 0
end

function var_0_0.sendOperationLog(arg_214_0, arg_214_1)
	local var_214_0 = {
		operation_id = arg_214_1
	}

	xyd.Backend.get():request(xyd.mid.SEND_OPERATION_LOG, var_214_0, nil, nil, true, false)
end

function var_0_0.loginEvent_(arg_215_0, arg_215_1)
	arg_215_0.uid = arg_215_1.params.uid

	arg_215_0:loadGameStartInfoEvent_(arg_215_1)
end

function var_0_0.systemBroadCastEvent_(arg_216_0, arg_216_1)
	local var_216_0 = xyd.tables.translation
	local var_216_1 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_216_1 then
		local var_216_2 = {
			time = 7
		}
		local var_216_3 = arg_216_1.params.msg

		if var_216_3.msg_type == xyd.SystemBroadcast.MARRIED then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.player_name, xyd.tables.hero:name(var_216_3.hero_table_id))
			var_216_2.msg_type = xyd.tables.announce:type(var_216_3.msg_type)
		elseif var_216_3.msg_type == xyd.SystemBroadcast.CONQUER_SCHOOL then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.player_name, xyd.tables.conquerSchool:regionName(var_216_3.region), var_216_3.conquer_loop_id, var_216_3.conquer_lev)
			var_216_2.msg_type = xyd.tables.announce:type(var_216_3.msg_type)
		elseif var_216_3.msg_type == xyd.SystemBroadcast.ARENA_WINS then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.player_name, var_216_3.keep_win_times)
			var_216_2.msg_type = xyd.tables.announce:type(var_216_3.msg_type)
		elseif var_216_3.msg_type == xyd.SystemBroadcast.ARENA_TOP3 then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.player_name, var_216_3.enemy_name, var_216_3.rank)
			var_216_2.msg_type = xyd.tables.announce:type(var_216_3.msg_type)
		elseif var_216_3.msg_type == xyd.SystemBroadcast.TREASURE_DIAMOND then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.player_name, var_216_3.crystal_award)
			var_216_2.msg_type = xyd.tables.announce:type(var_216_3.msg_type)
		elseif var_216_3.msg_type == xyd.SystemBroadcast.SXHERO then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.player_name, xyd.tables.hero:name(var_216_3.partner_id))
			var_216_2.msg_type = xyd.tables.announce:type(var_216_3.msg_type)
		elseif var_216_3.msg_type == xyd.SystemBroadcast.AUCTION_OVER then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.region, var_216_3.player_name, xyd.tables.item:name(var_216_3.item_id))
			var_216_2.msg_type = xyd.tables.announce:type(var_216_3.msg_type)
		elseif var_216_3.msg_type == xyd.SystemBroadcast.GET_DORM_KEY then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.player_name, xyd.tables.item:name(var_216_3.key_item))
			var_216_2.msg_type = xyd.tables.announce:type(var_216_3.msg_type)
		elseif var_216_3.msg_type == xyd.SystemBroadcast.GET_DORM_KEY_NEW then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.player_name, xyd.tables.item:name(var_216_3.key_item))
			var_216_2.msg_type = xyd.tables.announce:type(var_216_3.msg_type)
		elseif var_216_3.msg_type == xyd.SystemBroadcast.UNLOCK_CG then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.region, var_216_3.player_name, xyd.tables.libraryCG:getName(var_216_3.cg_id))
			var_216_2.msg_type = xyd.tables.announce:type(var_216_3.msg_type)
		elseif var_216_3.msg_type == xyd.SystemBroadcast.SUPER_PARTNER then
			var_216_2.msg = string.format(xyd.tables.announce:content(var_216_3.msg_type), var_216_3.region, var_216_3.player_name, xyd.tables.hero:name(var_216_3.table_id))
		end

		var_216_1:showBroadcast(var_216_2)
	end
end

function var_0_0.worldNoticeEvent_(arg_217_0, arg_217_1)
	if xyd.WindowManager.get():getWindow("main_scene_top") then
		if arg_217_1.params and arg_217_1.params.notice_type == xyd.NoticeType.SUMMER_QUIZ_TIP then
			local var_217_0 = {
				msg = {
					activity_id = xyd.Activities.Summer,
					player_name = arg_217_1.params.params.player_name,
					region = arg_217_1.params.params.region
				}
			}
			local var_217_1 = arg_217_1.params.params.finish_time - xyd.ServerTime.get():getServerTime()

			if arg_217_1.params.params.finish_time and var_217_1 > 0 then
				var_0_2.performWithDelayGlobal(function()
					if xyd.WindowManager.get():getWindow("main_scene_top") then
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.ACTIVITY_BROADCAST,
							params = var_217_0
						})
					end
				end, var_217_1)
			else
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.ACTIVITY_BROADCAST,
					params = var_217_0
				})
			end
		elseif arg_217_1.params and arg_217_1.params.notice_type == xyd.NoticeType.AUCTION_OVER then
			local var_217_2 = {
				msg = {
					msg_type = xyd.SystemBroadcast.AUCTION_OVER,
					player_name = arg_217_1.params.params.player_name,
					item_id = arg_217_1.params.params.item_id,
					region = arg_217_1.params.params.region
				}
			}

			table.insert(arg_217_0.auctionMsgs, var_217_2)

			local function var_217_3()
				if xyd.WindowManager.get():getWindow("main_scene_top") then
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.SYSTEM_BROADCAST,
						params = arg_217_0.auctionMsgs[1]
					})
				end

				var_0_2.performWithDelayGlobal(function()
					table.remove(arg_217_0.auctionMsgs, 1)

					if #arg_217_0.auctionMsgs == 0 then
						arg_217_0.auctionBroadcasting = false
					end

					if #arg_217_0.auctionMsgs ~= 0 then
						var_217_3()
					end
				end, 5)
			end

			if not arg_217_0.auctionBroadcasting then
				arg_217_0.auctionBroadcasting = true

				var_217_3()
			end
		elseif arg_217_1.params and arg_217_1.params.notice_type == xyd.NoticeType.POPULARITY_CONTEST then
			local var_217_4 = {
				msg = {
					activity_id = xyd.Activities.PopularityContest,
					player_name = arg_217_1.params.params.player_name,
					region = arg_217_1.params.params.region,
					table_id = arg_217_1.params.params.table_id
				}
			}

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ACTIVITY_BROADCAST,
				params = var_217_4
			})
		elseif arg_217_1.params and arg_217_1.params.notice_type == xyd.NoticeType.STICK_BLESS then
			local var_217_5 = {
				msg = {
					activity_id = xyd.Activities.StickBless,
					player_name = arg_217_1.params.params.player_name,
					region = arg_217_1.params.params.region
				}
			}

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ACTIVITY_BROADCAST,
				params = var_217_5
			})
		elseif arg_217_1.params and arg_217_1.params.notice_type == xyd.NoticeType.CG then
			local var_217_6 = {
				msg = {
					msg_type = xyd.SystemBroadcast.UNLOCK_CG,
					player_name = arg_217_1.params.params.player_name,
					cg_id = arg_217_1.params.params.cg_id,
					region = arg_217_1.params.params.region
				}
			}

			if xyd.WindowManager.get():getWindow("main_scene_top") then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.SYSTEM_BROADCAST,
					params = var_217_6
				})
			end
		elseif arg_217_1.params and arg_217_1.params.notice_type == xyd.NoticeType.SUPER_PARTNER then
			local var_217_7 = {
				msg = {
					msg_type = xyd.SystemBroadcast.SUPER_PARTNER,
					player_name = arg_217_1.params.params.player_name,
					table_id = arg_217_1.params.params.table_id,
					region = arg_217_1.params.params.region
				}
			}

			if xyd.WindowManager.get():getWindow("main_scene_top") then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.SYSTEM_BROADCAST,
					params = var_217_7
				})
			end
		end
	end

	if arg_217_1.params and arg_217_1.params.notice_type == xyd.NoticeType.BARRAGE then
		local var_217_8 = xyd.WindowManager.get():getWindow("chat")

		if var_217_8 and not tolua.isnull(var_217_8) then
			var_217_8:addBarrageMessage(arg_217_1.params.params)
		end
	end
end

function var_0_0.loadGameStartInfoEvent_(arg_221_0, arg_221_1)
	local var_221_0 = arg_221_1.params.detail
	local var_221_1 = {}

	for iter_221_0, iter_221_1 in pairs(var_221_0) do
		table.insert(var_221_1, tonumber(iter_221_0))
	end

	table.sort(var_221_1)

	local function var_221_2(arg_222_0)
		local var_222_0

		for iter_222_0, iter_222_1 in ipairs(var_221_1) do
			if iter_222_1 == arg_222_0 then
				var_222_0 = iter_222_0

				break
			end
		end

		if var_222_0 then
			table.remove(var_221_1, var_222_0)
		end
	end

	local var_221_3 = xyd.mid.LOAD_PLAYER_INFO

	if var_221_0[tostring(var_221_3)] and not var_221_0[tostring(var_221_3)].error_msg then
		arg_221_0:onPlayerInfo_({
			name = xyd.event.PLAYER_INFO,
			params = var_221_0[tostring(var_221_3)]
		})
	end

	var_221_2(var_221_3)

	local var_221_4 = xyd.mid.PETS_GET

	if var_221_0[tostring(var_221_4)] and not var_221_0[tostring(var_221_4)].error_msg then
		arg_221_0.collectedPets = {}

		local var_221_5 = var_221_0[tostring(var_221_4)]

		if var_221_5 and var_221_5.pets then
			for iter_221_2, iter_221_3 in pairs(var_221_5.pets) do
				local var_221_6 = import("app.model.Pet").new()

				var_221_6:populate(iter_221_3)
				var_221_6:setPlayerID(arg_221_0.playerID)

				arg_221_0.collectedPets[#arg_221_0.collectedPets + 1] = var_221_6
			end
		end
	end

	var_221_2(var_221_4)

	local var_221_7 = xyd.mid.LOAD_HEROS

	if var_221_0[tostring(var_221_7)] and not var_221_0[tostring(var_221_7)].error_msg then
		arg_221_0.herosLoaded_ = true

		arg_221_0:herosEvent_({
			name = xyd.event.HEROS,
			params = var_221_0[tostring(var_221_7)],
			userdata = {
				player_id = arg_221_0.playerID,
				conquer_lev = arg_221_0.conquerLev
			}
		})
	end

	var_221_2(var_221_7)

	local var_221_8 = xyd.mid.LOAD_BACKPACK

	if var_221_0[tostring(var_221_8)] and not var_221_0[tostring(var_221_8)].error_msg then
		arg_221_0.backpackLoaded_ = true

		arg_221_0:onBackpackEvent_({
			params = var_221_0[tostring(var_221_8)]
		})
		arg_221_0:checkEquipableAndSummon()
	end

	var_221_2(var_221_8)

	local var_221_9 = xyd.mid.LOAD_WORLD_MAP

	if var_221_0[tostring(var_221_9)] and not var_221_0[tostring(var_221_9)].error_msg then
		arg_221_0:worldMapLoginEvent_({
			params = var_221_0[tostring(var_221_9)]
		})
	end

	var_221_2(var_221_9)

	local var_221_10 = xyd.mid.LOAD_TRIAL_INFOS

	if var_221_0[tostring(var_221_10)] and not var_221_0[tostring(var_221_10)].error_msg then
		arg_221_0:trialInfosEvent_({
			name = xyd.event.WORLD_MAP,
			params = var_221_0[tostring(var_221_10)]
		})
	end

	var_221_2(var_221_10)

	local var_221_11 = xyd.mid.AWAKE_MISSION_LIST

	if var_221_0[tostring(var_221_11)] and not var_221_0[tostring(var_221_11)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.TASK):initData(var_221_0[tostring(var_221_11)], xyd.TaskType.AWAKE)
	end

	var_221_2(var_221_11)

	local var_221_12 = xyd.mid.ACTIVITIES

	if var_221_0[tostring(var_221_12)] and not var_221_0[tostring(var_221_12)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):onLoadActivities_({
			name = xyd.event.LOAD_ACTIVITIES,
			params = var_221_0[tostring(var_221_12)]
		})
	end

	var_221_2(var_221_12)

	local var_221_13 = xyd.mid.LOAD_ARENA_FIGHT_RECORDS

	if var_221_0[tostring(var_221_13)] and not var_221_0[tostring(var_221_13)].error_msg then
		arg_221_0:loadArenaRecordEvent_({
			params = var_221_0[tostring(var_221_13)]
		})
	end

	var_221_2(var_221_13)

	local var_221_14 = xyd.mid.LOAD_MARCH

	if var_221_0[tostring(var_221_14)] and not var_221_0[tostring(var_221_14)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH):onLoadMarch_({
			name = xyd.event.LOAD_MARCH,
			params = var_221_0[tostring(var_221_14)]
		})
	end

	var_221_2(var_221_14)

	local var_221_15 = xyd.mid.LOAD_SIGN_INFO

	if var_221_0[tostring(var_221_15)] and not var_221_0[tostring(var_221_15)].error_msg then
		arg_221_0:loadSignInfoEvent_({
			params = var_221_0[tostring(var_221_15)]
		})
	end

	var_221_2(var_221_15)

	local var_221_16 = xyd.mid.LOAD_INVITE_INFOS

	if var_221_0[tostring(var_221_16)] and not var_221_0[tostring(var_221_16)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.INVITE_FRIENDS_INFOS):onLoadInviteInfos_({
			params = var_221_0[tostring(var_221_16)]
		})
	end

	var_221_2(var_221_16)

	local var_221_17 = xyd.mid.PEAK_RECORDS

	if var_221_0[tostring(var_221_17)] and not var_221_0[tostring(var_221_17)].error_msg then
		arg_221_0:peakRecordEvent({
			params = var_221_0[tostring(var_221_17)]
		})
	end

	var_221_2(var_221_17)

	local var_221_18 = xyd.mid.REGION_GET_ARENA_INFO

	if var_221_0[tostring(var_221_18)] and not var_221_0[tostring(var_221_18)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA):onGetRegionArenaInfo_({
			params = var_221_0[tostring(var_221_18)]
		})
	end

	var_221_2(var_221_18)

	local var_221_19 = xyd.mid.LOAD_MAIL_LIST

	if var_221_0[tostring(var_221_19)] and not var_221_0[tostring(var_221_19)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.MAILBOX):onMailList_({
			params = var_221_0[tostring(var_221_19)]
		})
	end

	var_221_2(var_221_19)

	local var_221_20 = xyd.mid.LOAD_SUMMON_INFO

	if var_221_0[tostring(var_221_20)] and not var_221_0[tostring(var_221_20)].error_msg then
		arg_221_0:onLoadSummonInfo({
			params = var_221_0[tostring(var_221_20)]
		})
	end

	var_221_2(var_221_20)

	local var_221_21 = xyd.mid.WORLD_BOSS

	if var_221_0[tostring(var_221_21)] and not var_221_0[tostring(var_221_21).error_msg] then
		xyd.ModelManager.get():loadModel(xyd.ModelType.WORLD_BOSS):onWorldBoss_({
			params = var_221_0[tostring(var_221_21)]
		})
	end

	var_221_2(var_221_21)

	local var_221_22 = xyd.mid.GET_SELF_GUILD

	if var_221_0[tostring(var_221_22)] and not var_221_0[tostring(var_221_22).error_msg] then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):onLoadSelfGuild({
			params = var_221_0[tostring(var_221_22)]
		})
	end

	var_221_2(var_221_22)

	local var_221_23 = xyd.mid.PET_CAMPAIGN_RED_POINT

	if var_221_0[tostring(var_221_23)] and not var_221_0[tostring(var_221_23).error_msg] then
		xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN):onLoadPetCampaignAwards({
			params = var_221_0[tostring(var_221_23)]
		})
	end

	var_221_2(var_221_23)

	local var_221_24 = xyd.mid.TREASURE_LOAD_INFO

	if var_221_0[tostring(var_221_24)] and not var_221_0[tostring(var_221_24).error_msg] then
		xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE):onLoadTreasureInfo_({
			params = var_221_0[tostring(var_221_24)]
		})
	end

	var_221_2(var_221_24)

	local var_221_25 = xyd.mid.GET_BUILDING_LIST

	if var_221_0[tostring(var_221_25)] and not var_221_0[tostring(var_221_25)[error_msg]] then
		xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE):onLoadBuildingInfo({
			params = var_221_0[tostring(var_221_25)]
		})
	end

	var_221_2(var_221_25)

	local var_221_26 = xyd.mid.GUILD_WAR_RED_POINT

	if var_221_0[tostring(var_221_26)] and not var_221_0[tostring(var_221_26)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):guildWarRedPointInfo({
			params = var_221_0[tostring(var_221_26)]
		})
	end

	local var_221_27 = xyd.mid.GET_TEA_TALK_INFO

	if var_221_0[tostring(var_221_27)] and not var_221_0[tostring(var_221_27)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):teaTalkInitRed({
			params = var_221_0[tostring(var_221_27)]
		})
	end

	local var_221_28 = xyd.mid.GET_OFFLINE_INFO

	if var_221_0[tostring(var_221_28)] and not var_221_0[tostring(var_221_28)].error_msg then
		local var_221_29 = var_221_0[tostring(var_221_28)]

		arg_221_0.newAchievementIds = var_221_29 or {}

		if #var_221_29 > 0 then
			local var_221_30 = xyd.WindowManager.get():getWindow("main_scene_top")

			if var_221_30 and not tolua.isnull(var_221_30) then
				var_221_30:updateAchievementRedMark(true)
			end

			arg_221_0:handleNewAchievements()
		end
	end

	local var_221_31 = xyd.mid.GET_CLASS_INFO

	if var_221_0[tostring(var_221_31)] and not var_221_0[tostring(var_221_31)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM):getStartTeacherInfo({
			params = var_221_0[tostring(var_221_31)]
		})
	end

	local var_221_32 = xyd.mid.GET_LIBRARY_INFOS

	if var_221_0[tostring(var_221_32)] and not var_221_0[tostring(var_221_32)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY):updateLibraryInfos(var_221_0[tostring(var_221_32)])
	end

	local var_221_33 = xyd.mid.GET_STUDY_INFOS

	if var_221_0[tostring(var_221_33)] and not var_221_0[tostring(var_221_33)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE):setStudyInfos(var_221_0[tostring(var_221_33)])
	end

	local var_221_34 = xyd.mid.GET_GIFT_BOX_INFO

	if var_221_0[tostring(var_221_34)] and not var_221_0[tostring(var_221_34)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE):handleInfos(var_221_0[tostring(var_221_34)])
	end

	local var_221_35 = xyd.mid.GET_ADVENTURE_LIST

	if var_221_0[tostring(var_221_35)] and not var_221_0[tostring(var_221_35)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT):initAdventureEventInfos(var_221_0[tostring(var_221_35)])
	end

	local var_221_36 = xyd.mid.GET_HERO_RECOMMEND_SCORES

	if var_221_0[tostring(var_221_36)] and not var_221_0[tostring(var_221_36)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND):handleRecommendScores(var_221_0[tostring(var_221_36)])
	end

	local var_221_37 = xyd.mid.RED_POINT

	if var_221_0[tostring(var_221_37)] and not var_221_0[tostring(var_221_37)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.REDMARK):onUpdate(var_221_0[tostring(var_221_37)])
	end

	local var_221_38 = xyd.mid.BATTLE_PASS_GET_INFO

	if var_221_0[tostring(var_221_38)] and not var_221_0[tostring(var_221_38)].error_msg then
		xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS):setInfo(var_221_0[tostring(var_221_38)])
	end

	local var_221_39 = xyd.mid.HUNQI_START_GAME_GET_INFO

	if var_221_0[tostring(var_221_39)] and not var_221_0[tostring(var_221_39)].error_msg then
		arg_221_0.spiritCampaignInfo = var_221_0[tostring(var_221_39)]
	end

	var_221_2(var_221_39)
end

function var_0_0.loadArenaRecordEvent_(arg_223_0, arg_223_1)
	local var_223_0 = arg_223_1.params.records
	local var_223_1 = xyd.db.arenaReportKeys:getAllArenaReportKeys(arg_223_0.playerID)
	local var_223_2 = {}

	arg_223_0.newReportKeyTable = {}

	for iter_223_0, iter_223_1 in ipairs(var_223_0) do
		if iter_223_1.report_key then
			table.insert(var_223_2, iter_223_1.report_key)
			table.insert(arg_223_0.newReportKeyTable, iter_223_1.report_key)
		end
	end

	for iter_223_2 = 1, #var_223_1 do
		for iter_223_3, iter_223_4 in ipairs(var_223_2) do
			if var_223_1[iter_223_2] == iter_223_4 then
				table.remove(var_223_2, iter_223_3)

				break
			end
		end
	end

	if #var_223_2 > 0 then
		arg_223_0.arenaRedMarkEnable = true

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.ARENA
		})
	else
		arg_223_0.arenaRedMarkEnable = false
	end
end

function var_0_0.loadSignInfoEvent_(arg_224_0, arg_224_1)
	arg_224_0.signAwards = arg_224_1.params.awards

	arg_224_0:setSignIn(arg_224_1.params.is_signed)

	arg_224_0.signPartnerID = arg_224_1.params.partner_id
	arg_224_0.signTimes = arg_224_1.params.sign_times
	arg_224_0.signMonth = arg_224_1.params.month
	arg_224_0.signPartnerIsSkin = arg_224_1.params.is_skin
	arg_224_0.signInfoLoaded_ = true

	if arg_224_0.signAwards then
		for iter_224_0 = 1, #arg_224_0.signAwards do
			if xyd.tables.item:type(arg_224_0.signAwards[iter_224_0].award_item_id) == -1 then
				arg_224_0.signHeroPos = iter_224_0

				break
			end
		end
	end
end

function var_0_0.peakRecordEvent(arg_225_0, arg_225_1)
	local var_225_0 = arg_225_1.params
	local var_225_1 = xyd.db.peakArenaReportKeys:getAllReportKeys(arg_225_0.playerID)
	local var_225_2 = {}

	arg_225_0.newPeakReportKeyTable = {}

	for iter_225_0, iter_225_1 in ipairs(var_225_0) do
		if iter_225_1.report_key then
			if iter_225_1.attacker_player_id ~= arg_225_0.playerID then
				table.insert(var_225_2, iter_225_1.report_key)
			end

			table.insert(arg_225_0.newPeakReportKeyTable, iter_225_1.report_key)
		end
	end

	for iter_225_2 = 1, #var_225_1 do
		for iter_225_3, iter_225_4 in ipairs(var_225_2) do
			if var_225_1[iter_225_2] == iter_225_4 then
				table.remove(var_225_2, iter_225_3)

				break
			end
		end
	end

	if #var_225_2 > 0 then
		arg_225_0.peakArenaRedMarkEnable = true

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.PEAK
		})
	else
		arg_225_0.peakArenaRedMarkEnable = false
	end
end

function var_0_0.handleRewards(arg_226_0, arg_226_1, arg_226_2, arg_226_3)
	if not arg_226_1 and not arg_226_3 then
		if arg_226_2 then
			arg_226_2()
		end

		return
	end

	arg_226_1 = arg_226_1 or {}
	arg_226_3 = arg_226_3 or {}

	local var_226_0 = arg_226_0:handleRewardsWithoutShow(arg_226_1, arg_226_3)

	if var_226_0 and next(var_226_0) then
		local var_226_1 = var_226_0[1]

		if var_226_1.is_partner then
			local var_226_2 = {
				toStone = false,
				partnerID = var_226_1.table_id
			}
			local var_226_3 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_226_2)

			cc.EventProxy.new(var_226_3, var_226_3):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
				arg_226_0:showRewards(arg_226_1, arg_226_2)
			end)
		elseif var_226_1.to_stone then
			local var_226_4 = {
				partnerID = xyd.tables.item:heroID(var_226_1.table_id),
				toStone = tonumber(var_226_1.item_num)
			}
			local var_226_5 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_226_4)

			cc.EventProxy.new(var_226_5, var_226_5):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
				arg_226_0:showRewards(arg_226_1, arg_226_2)
			end)
		end
	else
		arg_226_0:showRewards(arg_226_1, arg_226_2, arg_226_3)
	end
end

function var_0_0.handleRewardsWithoutShow(arg_229_0, arg_229_1, arg_229_2)
	local var_229_0 = {}
	local var_229_1 = {}

	for iter_229_0, iter_229_1 in ipairs(arg_229_1) do
		if iter_229_1.is_partner == true then
			table.insert(var_229_1, iter_229_1)

			iter_229_1.item_num = 1
		elseif iter_229_1.to_stone == true then
			table.insert(var_229_1, iter_229_1)
			table.insert(var_229_0, iter_229_1)
		else
			table.insert(var_229_0, iter_229_1)
		end
	end

	for iter_229_2, iter_229_3 in ipairs(var_229_0) do
		arg_229_0:getBackpack():addItemsByID(tonumber(iter_229_3.table_id), tonumber(iter_229_3.item_num))
	end

	for iter_229_4, iter_229_5 in ipairs(var_229_1) do
		if iter_229_5.is_partner then
			local var_229_2 = var_0_1.new()

			var_229_2:populate(iter_229_5)
			arg_229_0:addHero(var_229_2)
		end
	end

	if arg_229_2 and #arg_229_2 > 0 then
		for iter_229_6, iter_229_7 in ipairs(arg_229_2) do
			arg_229_0:getBackpack():addSpiritItem(iter_229_7)
		end
	end

	return var_229_1
end

function var_0_0.showRewards(arg_230_0, arg_230_1, arg_230_2, arg_230_3)
	if arg_230_1 and #arg_230_1 > 0 or arg_230_3 and #arg_230_3 > 0 then
		if xyd.WindowManager.get():isWindowOpen("alert_award") then
			xyd.WindowManager.get():openAnnotherWindow("alert_award", {
				awards = arg_230_1,
				callback = arg_230_2,
				spiritAwards = arg_230_3
			})
		else
			xyd.WindowManager.get():openWindow("alert_award", {
				awards = arg_230_1,
				callback = arg_230_2,
				spiritAwards = arg_230_3
			})
		end
	end
end

function var_0_0.getMyCurrentAvatarID(arg_231_0)
	if not arg_231_0.avatarId then
		arg_231_0.avatarId = 110001001

		return arg_231_0.avatarId
	end

	local var_231_0 = arg_231_0:getBackpack():getItemByID(arg_231_0.avatarId)

	if var_231_0 and var_231_0.startTime and var_231_0.startTime > 0 and xyd.tables.avatar:getAvatarTime(var_231_0.itemID) > 0 and xyd.tables.avatar:getAvatarTime(arg_231_0.avatarId) * 24 * 60 * 60 + var_231_0.startTime < xyd.ServerTime.get():getServerTime() then
		arg_231_0.avatarId = 110001001

		arg_231_0:getBackpack():removeItem(var_231_0)
		xyd.Backend.get():enterChatRoom(arg_231_0.region)
		xyd.Backend.get():enterServiceChatRoom(99999)

		if arg_231_0.guildID and arg_231_0.guildID ~= 0 then
			xyd.Backend.get():enterLeagueRoom(arg_231_0.guildID)
		end
	end

	return arg_231_0.avatarId
end

function var_0_0.getBoardHero(arg_232_0)
	for iter_232_0 = 1, #arg_232_0.heros_ do
		local var_232_0 = arg_232_0.heros_[iter_232_0]

		if var_232_0:isBoardHero() then
			return var_232_0
		end
	end
end

function var_0_0.reSetAllHeroBoardInfo(arg_233_0)
	for iter_233_0 = 1, #arg_233_0.heros_ do
		local var_233_0 = arg_233_0.heros_[iter_233_0]

		if var_233_0:isBoardHero() then
			var_233_0:setIsBoardHero(0)
		end
	end
end

function var_0_0.updateLastSkillPoint(arg_234_0, arg_234_1)
	if arg_234_1 and arg_234_1 > 0 then
		arg_234_0.lastSkillPoint = arg_234_1
	end
end

function var_0_0.saveFilterType(arg_235_0, arg_235_1)
	xyd.Backend.get():request(xyd.mid.BACKPACK_SORT_TYPE, {
		sort_type = arg_235_1
	}, function(arg_236_0)
		if arg_236_0 == xyd.error.OK then
			arg_235_0.backpack_sort_type = arg_235_1
		end
	end)
end

function var_0_0.saveHeroFilterType(arg_237_0, arg_237_1)
	xyd.Backend.get():request(xyd.mid.SAVA_SORT_TYPE, {
		sort_type = arg_237_1
	}, function(arg_238_0)
		if arg_238_0 == xyd.error.OK then
			arg_237_0.sortType = arg_237_1

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.UPDATE_FILTER_HEROS
			})
		end
	end)
end

function var_0_0.getSaveTeamStr(arg_239_0)
	return arg_239_0.saveTeam, arg_239_0.saveTeamName, arg_239_0.savePet
end

function var_0_0.getSaveTeamIDs(arg_240_0, arg_240_1)
	if not arg_240_1 or arg_240_1 == "" then
		return {}
	end

	local var_240_0 = {}
	local var_240_1 = xyd.split(arg_240_1, ":")

	for iter_240_0 = 1, #var_240_1 do
		local var_240_2 = xyd.splitToNumber(var_240_1[iter_240_0], "|")

		if var_240_2 and next(var_240_2) then
			table.insert(var_240_0, var_240_2)
		end
	end

	return var_240_0
end

function var_0_0.getSaveTeams(arg_241_0)
	local var_241_0, var_241_1, var_241_2 = arg_241_0:getSaveTeamStr()
	local var_241_3 = arg_241_0:getSaveTeamIDs(var_241_0)
	local var_241_4 = {}

	if var_241_1 then
		var_241_4 = string.split(var_241_1, "|||")
	end

	var_241_2 = var_241_2 and string.split(var_241_2, "|")

	local var_241_5 = {}

	for iter_241_0 = 1, #var_241_3 do
		local var_241_6 = {}
		local var_241_7 = var_241_4[iter_241_0] or ""
		local var_241_8 = var_241_3[iter_241_0]

		for iter_241_1 = 1, #var_241_8 do
			local var_241_9 = var_241_8[iter_241_1]
			local var_241_10 = arg_241_0:getHero(var_241_9)

			if var_241_10 then
				local var_241_11 = var_0_1.new()

				var_241_11:populate(var_241_10:toParams())
				table.insert(var_241_6, var_241_11)
			end
		end

		local var_241_12 = tonumber(var_241_2[iter_241_0])
		local var_241_13

		if var_241_12 ~= 0 then
			var_241_13 = arg_241_0:getPetByID(var_241_12)
		end

		if next(var_241_6) then
			table.insert(var_241_5, {
				teamName = var_241_7,
				team = var_241_6,
				pet = var_241_13
			})
		end
	end

	return var_241_5
end

function var_0_0.heroPreset(arg_242_0, arg_242_1, arg_242_2)
	local var_242_0 = arg_242_1 or {}

	xyd.Backend.get():request(xyd.mid.SAVE_TEAM, var_242_0, function(arg_243_0, arg_243_1)
		if arg_243_0 == xyd.error.OK then
			if arg_243_0 == xyd.error.OK then
				arg_242_0.saveTeam = arg_243_1.save_team
				arg_242_0.saveTeamName = arg_243_1.save_team_name
				arg_242_0.savePet = arg_243_1.save_pet
			end

			if arg_242_2 then
				arg_242_2(arg_243_0, arg_243_1)
			end
		end
	end)
end

function var_0_0.getPracticeInfo(arg_244_0, arg_244_1)
	if not arg_244_0.practiceInfo then
		xyd.Backend.get():request(xyd.mid.GET_PRACTICE_INFO, nil, function(arg_245_0, arg_245_1)
			if arg_245_0 == xyd.error.OK then
				arg_244_0.practiceInfo = arg_245_1

				if arg_244_1 then
					arg_244_1(arg_245_1)
				end
			end
		end)
	elseif arg_244_1 then
		arg_244_1(arg_244_0.practiceInfo)
	end
end

function var_0_0.checkHaveAwakenHero(arg_246_0)
	if arg_246_0.isHaveAwakenHero ~= nil then
		return arg_246_0.isHaveAwakenHero
	end

	arg_246_0.isHaveAwakenHero = false

	for iter_246_0, iter_246_1 in pairs(arg_246_0.heros_) do
		if iter_246_1:isAwaken() then
			arg_246_0.isHaveAwakenHero = true

			break
		end
	end

	return arg_246_0.isHaveAwakenHero
end

function var_0_0.checkPracticeRedMark(arg_247_0)
	if not arg_247_0:isFuncOpen(xyd.FunctionID.ID_PRACTICE) then
		return false
	elseif not arg_247_0:checkHaveAwakenHero() then
		return false
	end

	if not arg_247_0.practiceInfo then
		arg_247_0:getPracticeInfo()

		return false
	end

	local var_247_0 = tonumber(xyd.ServerTime.get():getServerTime())

	if arg_247_0.practiceInfo.last_time + xyd.TimeGap - var_247_0 <= 0 then
		return true
	end

	return false
end

function var_0_0.checkSuperPartnerRedMark(arg_248_0)
	if not arg_248_0:isFuncOpen(xyd.FunctionID.ID_SUPER_PARTNER) then
		return false
	end

	local var_248_0 = xyd.tables.hero:getSuperHeros()

	for iter_248_0, iter_248_1 in ipairs(var_248_0) do
		if not arg_248_0:getHeroByTableID(iter_248_1) then
			local var_248_1 = xyd.tables.hero:materialHero(iter_248_1)
			local var_248_2 = true
			local var_248_3 = 0

			for iter_248_2, iter_248_3 in ipairs(var_248_1) do
				local var_248_4 = arg_248_0:getHeroByTableID(iter_248_3) or arg_248_0:getHeroByTableID(xyd.tables.hero:afterAwaken(iter_248_3))

				if var_248_4 then
					if var_248_4:getStar() == xyd.MAX_STAR_LEVEL then
						var_248_3 = var_248_3 + 1
					end
				else
					var_248_2 = false
				end
			end

			if var_248_2 and var_248_3 > 0 then
				return true
			end
		end
	end

	return false
end

function var_0_0.updateConquerLev(arg_249_0, arg_249_1)
	arg_249_0.conquerLev = arg_249_1 or 0

	local var_249_0 = arg_249_0:getHeros()

	for iter_249_0, iter_249_1 in pairs(var_249_0) do
		iter_249_1:setConquerSchoolLev(arg_249_0.conquerLev)
	end
end

function var_0_0.updateConquerLoopID(arg_250_0, arg_250_1)
	arg_250_0.conquerLoopID = arg_250_1 or 1
end

function var_0_0.sendFunctionClick(arg_251_0, arg_251_1)
	xyd.Backend.get():request(xyd.mid.FUNCTION_CLICK, {
		click_id = arg_251_1
	}, function(arg_252_0, arg_252_1)
		return
	end)
end

function var_0_0.changeTitleInfo(arg_253_0, arg_253_1)
	arg_253_0.titleInfo = arg_253_1
end

function var_0_0.updateBookShelfLev(arg_254_0, arg_254_1)
	if not arg_254_1 then
		return
	end

	for iter_254_0, iter_254_1 in ipairs(arg_254_0.heros_) do
		iter_254_1:setBookshelfLevel(arg_254_1)
	end
end

function var_0_0.setBuyGlueTimes(arg_255_0, arg_255_1)
	arg_255_0.buyGlueTimes = arg_255_1
end

function var_0_0.playHeroSound(arg_256_0, arg_256_1, arg_256_2, arg_256_3)
	if type(arg_256_0.musicBlocked) == "nil" then
		arg_256_0.musicBlocked = xyd.db.settings:getBackgroudMusicOn() == 0
	end

	if arg_256_0.soundHandle_ and arg_256_0.playSound_ then
		audio.stopSound(arg_256_0.playSound_)
	end

	if not arg_256_0.natureVolume then
		arg_256_0.natureVolume = arg_256_0.musicBlocked and 0 or 1
	end

	if arg_256_0.musicFadeInHandle_ then
		var_0_2.unscheduleGlobal(arg_256_0.musicFadeInHandle_)

		arg_256_0.musicFadeInHandle_ = nil
	end

	audio.setMusicVolume(0.3 * arg_256_0.natureVolume)

	arg_256_0.playSound_ = audio.playSound(arg_256_1, false)
	arg_256_0.soundLeftTime = arg_256_2

	if not arg_256_0.soundHandle_ then
		arg_256_0:creatSoundScheduler(arg_256_3)
	end
end

function var_0_0.creatSoundScheduler(arg_257_0, arg_257_1)
	arg_257_0.soundHandle_ = var_0_2.scheduleGlobal(function()
		arg_257_0.soundLeftTime = arg_257_0.soundLeftTime - 0.5

		audio.setMusicVolume(0.3 * arg_257_0.natureVolume)

		if arg_257_0.soundLeftTime <= 0 then
			var_0_2.unscheduleGlobal(arg_257_0.soundHandle_)

			arg_257_0.soundHandle_ = nil

			arg_257_0:musicFadeInScheduler(0.6, arg_257_1)

			if arg_257_0.playSound_ then
				audio.stopSound(arg_257_0.playSound_)
			end
		end
	end, 0.5)
end

function var_0_0.musicFadeInScheduler(arg_259_0, arg_259_1, arg_259_2)
	local var_259_0 = math.floor(arg_259_1 / 0.03)
	local var_259_1 = 0.7 / var_259_0
	local var_259_2 = 0

	if arg_259_0.musicFadeInHandle_ then
		var_0_2.unscheduleGlobal(arg_259_0.musicFadeInHandle_)
	end

	arg_259_0.musicFadeInHandle_ = var_0_2.scheduleGlobal(function()
		var_259_2 = var_259_2 + 1

		if var_259_2 == var_259_0 then
			audio.setMusicVolume(arg_259_0.natureVolume)
			var_0_2.unscheduleGlobal(arg_259_0.musicFadeInHandle_)

			arg_259_0.musicFadeInHandle_ = nil

			if arg_259_2 then
				arg_259_2()
			end
		else
			audio.setMusicVolume((0.3 + var_259_2 * var_259_1) * arg_259_0.natureVolume)
		end
	end, 0.03)
end

function var_0_0.stopHeroSound(arg_261_0)
	if arg_261_0.soundHandle_ then
		if arg_261_0.playSound_ then
			audio.stopSound(arg_261_0.playSound_)
		end

		var_0_2.unscheduleGlobal(arg_261_0.soundHandle_)

		arg_261_0.soundHandle_ = nil

		audio.setMusicVolume(arg_261_0.natureVolume)
	elseif arg_261_0.musicFadeInHandle_ then
		audio.setMusicVolume(arg_261_0.natureVolume)
		var_0_2.unscheduleGlobal(arg_261_0.musicFadeInHandle_)

		arg_261_0.musicFadeInHandle_ = nil
	end
end

function var_0_0.setNatureVolume(arg_262_0, arg_262_1)
	arg_262_0.musicBlocked = arg_262_1 == 0
	arg_262_0.natureVolume = arg_262_0.musicBlocked and 0 or 1

	local var_262_0 = false

	if arg_262_0.soundHandle_ or arg_262_0.musicFadeInHandle_ then
		var_262_0 = true
	end

	xyd.db.settings:setBakgroundMusic(arg_262_1 > 0, var_262_0)
end

function var_0_0.isHaveSkin(arg_263_0, arg_263_1)
	if arg_263_0:getBackpack():getItemNumByID(arg_263_1) > 0 then
		return true
	end

	local var_263_0 = xyd.tables.item:skinPartner(arg_263_1)
	local var_263_1 = arg_263_0:getHeroIgnoreAwaken(var_263_0)

	if not var_263_1 then
		return false
	end

	local var_263_2 = false

	for iter_263_0 = 1, #var_263_1.skinIds_ do
		if var_263_1.skinIds_[iter_263_0] == xyd.tables.skinSkill:getModelID(arg_263_1) then
			var_263_2 = true
		end
	end

	return var_263_2
end

function var_0_0.getEconomicItemNumByType(arg_264_0, arg_264_1)
	if arg_264_1 == xyd.EconomicType.MANA then
		return arg_264_0.mana
	elseif arg_264_1 == xyd.EconomicType.CRYSTAL then
		return arg_264_0.crystal
	elseif arg_264_1 == xyd.EconomicType.ENERGY then
		return arg_264_0:getEnergy()
	end
end

function var_0_0.isMaxLev(arg_265_0)
	return arg_265_0.lev >= arg_265_0.maxTeamLev
end

function var_0_0.onUpdateTwiceAwakeStage(arg_266_0, arg_266_1)
	if not arg_266_1 or not next(arg_266_1) then
		return
	end

	if not arg_266_1.table_id or not arg_266_1.stage then
		return
	end

	local var_266_0 = arg_266_1.table_id
	local var_266_1 = arg_266_1.stage
	local var_266_2 = arg_266_0:getHeroByTableID(var_266_0)

	if var_266_2 then
		var_266_2:setAwakeTwiceStage(var_266_1)
	end
end

function var_0_0.getInitSortType(arg_267_0)
	local var_267_0
	local var_267_1
	local var_267_2
	local var_267_3

	if arg_267_0.sortType > 0 then
		var_267_0 = {
			0,
			0,
			0
		}
		var_267_1 = {
			0,
			0,
			0
		}
		var_267_2 = {
			0,
			0,
			0,
			0
		}
		var_267_3 = {
			0,
			0,
			0
		}

		local var_267_4 = {}
		local var_267_5 = arg_267_0.sortType
		local var_267_6 = 1

		while var_267_5 > 0 do
			var_267_4[var_267_6] = var_267_5 % 2
			var_267_6 = var_267_6 + 1
			var_267_5 = math.floor(var_267_5 / 2)
		end

		local var_267_7 = 1

		for iter_267_0 = 13, 1, -1 do
			if iter_267_0 <= 4 then
				if iter_267_0 == 4 then
					var_267_7 = 1
				end

				var_267_2[var_267_7] = var_267_4[iter_267_0]
			elseif iter_267_0 <= 7 then
				if iter_267_0 == 7 then
					var_267_7 = 1
				end

				var_267_1[var_267_7] = var_267_4[iter_267_0]
			elseif iter_267_0 <= 10 then
				if iter_267_0 == 10 then
					var_267_7 = 1
				end

				if var_267_4[iter_267_0] then
					var_267_0[var_267_7] = var_267_4[iter_267_0]
				end
			elseif iter_267_0 <= 13 and var_267_4[iter_267_0] then
				var_267_3[var_267_7] = var_267_4[iter_267_0]
			end

			var_267_7 = var_267_7 + 1
		end
	else
		var_267_0 = {
			1,
			1,
			1
		}
		var_267_1 = {
			1,
			1,
			1
		}
		var_267_2 = {
			1,
			1,
			1,
			1
		}
		var_267_3 = {
			1,
			1,
			1
		}
	end

	return {
		herosPos = var_267_0,
		herosType = var_267_1,
		herosPower = var_267_2,
		herosAwaken = var_267_3
	}
end

function var_0_0.getFilterParams(arg_268_0)
	local var_268_0 = arg_268_0:getInitSortType()
	local var_268_1 = var_268_0.herosPos
	local var_268_2 = var_268_0.herosType
	local var_268_3 = var_268_0.herosPower
	local var_268_4 = var_268_0.herosAwaken
	local var_268_5

	if var_268_1 and next(var_268_1) then
		for iter_268_0, iter_268_1 in ipairs(var_268_1) do
			if iter_268_1 == 1 then
				var_268_5 = var_268_5 or ""
				var_268_5 = var_268_5 .. tostring(iter_268_0 + 1) .. "|"
			end
		end
	end

	local var_268_6

	if var_268_2 and next(var_268_2) then
		for iter_268_2, iter_268_3 in ipairs(var_268_2) do
			if iter_268_3 == 1 then
				var_268_6 = var_268_6 or ""
				var_268_6 = var_268_6 .. iter_268_2 .. "|"
			end
		end
	end

	local var_268_7

	if var_268_3 and next(var_268_3) then
		for iter_268_4, iter_268_5 in ipairs(var_268_3) do
			if iter_268_5 == 1 then
				var_268_7 = var_268_7 or ""
				var_268_7 = var_268_7 .. iter_268_4 .. "|"
			end
		end
	end

	local var_268_8

	if var_268_4 and next(var_268_4) then
		for iter_268_6, iter_268_7 in ipairs(var_268_4) do
			if iter_268_7 == 1 then
				var_268_8 = var_268_8 or ""
				var_268_8 = var_268_8 .. iter_268_6 .. "|"
			end
		end
	end

	return {
		posFilter = var_268_5,
		forceFilter = var_268_7,
		attrFilter = var_268_6,
		awakeFilter = var_268_8
	}
end

function var_0_0.getAlbumAttrInfo(arg_269_0)
	xyd.Backend.get():request(xyd.mid.ALBUM_SPECIAL_COLLECT_INFO, nil, function(arg_270_0, arg_270_1)
		if arg_270_0 == xyd.error.OK then
			arg_269_0.albumSpecialCollect = arg_270_1.is_award

			arg_269_0:calculateWhiteAlbumAttr()
			arg_269_0:checkAlbumRedPoint()
		end
	end)
end

function var_0_0.calculateWhiteAlbumAttr(arg_271_0)
	local var_271_0 = xyd.tables.albumNormalCollectTable
	local var_271_1 = xyd.tables.albumSpecialCollectTable

	arg_271_0.albumAttr = {}

	for iter_271_0 = 1, 50 do
		arg_271_0.albumAttr[iter_271_0] = 0
	end

	for iter_271_1, iter_271_2 in ipairs(arg_271_0.heros_) do
		local var_271_2 = xyd.getOriginHeroId(iter_271_2:getTableID())
		local var_271_3 = var_271_0:attrType(var_271_2)

		if var_271_3 ~= 0 then
			local var_271_4 = var_271_0:qualityAttr(var_271_2)

			arg_271_0.albumAttr[var_271_3] = arg_271_0.albumAttr[var_271_3] + (var_271_4[iter_271_2.collectQualityStage] or 0)

			local var_271_5 = var_271_0:starAttr(var_271_2)

			arg_271_0.albumAttr[var_271_3] = arg_271_0.albumAttr[var_271_3] + (var_271_5[iter_271_2.collectStarStage] or 0)
		end
	end

	arg_271_0.albumSpecialCollectedNum = 0

	for iter_271_3 = 1, #arg_271_0.albumSpecialCollect do
		if arg_271_0.albumSpecialCollect[iter_271_3] == 1 and var_271_1:type(iter_271_3) == 1 then
			local var_271_6 = var_271_1:reward(iter_271_3)
			local var_271_7 = var_271_1:num(iter_271_3)

			arg_271_0.albumAttr[var_271_6] = arg_271_0.albumAttr[var_271_6] + var_271_7
		end

		if arg_271_0.albumSpecialCollect[iter_271_3] == 1 then
			arg_271_0.albumSpecialCollectedNum = arg_271_0.albumSpecialCollectedNum + 1
		end
	end
end

function var_0_0.checkAlbumRedPoint(arg_272_0)
	if not arg_272_0.heroMap then
		arg_272_0.heroMap = {}

		for iter_272_0, iter_272_1 in ipairs(arg_272_0.heros_) do
			local var_272_0 = xyd.getOriginHeroId(iter_272_1:getTableID())

			arg_272_0.heroMap[var_272_0] = true
		end
	end

	arg_272_0:checkAlbumNormal()
	arg_272_0:checkAlbumSpecial()
	arg_272_0:albumRedPointEvent()
end

function var_0_0.albumRedPointEvent(arg_273_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.CHECK_MIDDLE_RED_MARK,
		params = xyd.CheckMiddleRed.WHITE_ALBUM
	})
end

function var_0_0.checkAlbumNormal(arg_274_0)
	local var_274_0 = xyd.tables.albumNormalCollectTable

	arg_274_0.albumNormalRedP = false

	for iter_274_0, iter_274_1 in ipairs(arg_274_0.heros_) do
		local var_274_1 = xyd.getOriginHeroId(iter_274_1:getTableID())

		if var_274_0:attrType(var_274_1) ~= 0 then
			local var_274_2 = iter_274_1.collectQualityStage
			local var_274_3 = iter_274_1.collectStarStage
			local var_274_4 = var_274_0:qualityStages(var_274_1)

			if var_274_2 ~= #var_274_4 and iter_274_1:getColor() >= var_274_4[var_274_2 + 1] then
				arg_274_0.albumNormalRedP = true

				return
			end

			local var_274_5 = var_274_0:starStages(var_274_1)

			if var_274_3 ~= #var_274_5 and iter_274_1:getStar() >= var_274_5[var_274_3 + 1] then
				arg_274_0.albumNormalRedP = true

				return
			end
		end
	end
end

function var_0_0.checkSingleHeroAlbumNormal(arg_275_0, arg_275_1)
	if arg_275_0.albumNormalRedP then
		return
	end

	local var_275_0 = xyd.tables.albumNormalCollectTable
	local var_275_1 = xyd.getOriginHeroId(arg_275_1:getTableID())

	if var_275_0:attrType(var_275_1) == 0 then
		return
	end

	local var_275_2 = arg_275_1.collectQualityStage
	local var_275_3 = arg_275_1.collectStarStage
	local var_275_4 = var_275_0:qualityStages(var_275_1)

	if var_275_2 ~= #var_275_4 and arg_275_1:getColor() >= var_275_4[var_275_2 + 1] then
		arg_275_0.albumNormalRedP = true

		return
	end

	local var_275_5 = var_275_0:starStages(var_275_1)

	if var_275_3 ~= #var_275_5 and arg_275_1:getStar() >= var_275_5[var_275_3 + 1] then
		arg_275_0.albumNormalRedP = true

		return
	end
end

function var_0_0.checkAlbumSpecial(arg_276_0)
	local var_276_0 = xyd.tables.albumSpecialCollectTable

	arg_276_0.albumSpecialRedP = false
	arg_276_0.albumSpecialCanCollect = arg_276_0.albumSpecialCanCollect or {}

	for iter_276_0 = 1, #arg_276_0.albumSpecialCollect do
		if arg_276_0.albumSpecialCollect[iter_276_0] == 0 and not arg_276_0.albumSpecialCanCollect[iter_276_0] then
			local var_276_1 = var_276_0:partnerId(iter_276_0)
			local var_276_2 = true

			for iter_276_1 = 1, #var_276_1 do
				if not arg_276_0.heroMap[var_276_1[iter_276_1]] then
					var_276_2 = false

					break
				end
			end

			arg_276_0.albumSpecialCanCollect[iter_276_0] = var_276_2
			arg_276_0.albumSpecialRedP = arg_276_0.albumSpecialRedP or var_276_2
		end
	end
end

function var_0_0.getLibraryInfos(arg_277_0, arg_277_1)
	if arg_277_0.isLibraryLoaded then
		arg_277_1()
	else
		xyd.Backend.get():request(xyd.mid.GET_LIBRARY_INFOS, nil, function(arg_278_0, arg_278_1)
			if arg_278_0 == xyd.error.OK then
				xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY):updateLibraryInfos(arg_278_1)

				arg_277_0.isLibraryLoaded = true

				arg_277_1()
			end
		end)
	end
end

function var_0_0.sendReloadGuideID(arg_279_0, arg_279_1)
	if arg_279_0.isLibraryLoaded then
		arg_279_1()
	end
end

function var_0_0.setPlayerGuideFunction(arg_280_0, arg_280_1)
	xyd.Backend.get():request(xyd.mid.SET_PLAYER_GUIDE_FUNCTION, arg_280_1, function(arg_281_0, arg_281_1)
		if arg_281_0 == xyd.error.OK then
			arg_280_0.guideFuncList = arg_281_1.guide_function_ids or {}
			arg_280_0.reloadGuideID = arg_281_1.guide_return_id or 0

			dump(arg_281_1)
		end
	end)
end

function var_0_0.setPlayerReturnID(arg_282_0, arg_282_1)
	xyd.Backend.get():request(xyd.mid.SET_PLAYER_RETURN_ID, arg_282_1, function(arg_283_0, arg_283_1)
		if arg_283_0 == xyd.error.OK then
			arg_282_0.reloadGuideID = arg_283_1.guide_return_id or 0

			dump(arg_283_1)
		end
	end)
end

function var_0_0.initABtest(arg_284_0)
	if not arg_284_0.abtestGroup then
		arg_284_0.abtestGroup = {}
	end
end

function var_0_0.getAbtestGroupByKey(arg_285_0, arg_285_1)
	arg_285_0.getGroup = false

	if not arg_285_0.abtestGroup[arg_285_1] then
		local var_285_0 = {
			unique_key = arg_285_1
		}

		xyd.Backend.get():request(xyd.mid.GET_PLAYER_GROUP_BY_KEY, var_285_0, function(arg_286_0, arg_286_1)
			if arg_286_0 == xyd.error.OK then
				arg_285_0.abtestGroup[arg_285_1] = arg_286_1
				arg_285_0.getGroup = true
			else
				arg_285_0.getGroup = false
			end
		end)

		if not arg_285_0.getGroup then
			if math.random(1, 2) == 1 then
				arg_285_0.abtestGroup[arg_285_1] = "A"
			else
				arg_285_0.abtestGroup[arg_285_1] = "B"
			end

			arg_285_0.abtestGroup[arg_285_1] = "A"
		end
	end
end

return var_0_0
