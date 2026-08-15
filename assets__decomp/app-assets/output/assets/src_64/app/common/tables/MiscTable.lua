local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = class("MiscTable")
local var_0_3 = {
	"parse_tostring",
	"parse_tonumber",
	"parse_splitToString",
	"parse_splitToNumber"
}

function var_0_2.ctor(arg_1_0)
	arg_1_0.dict_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("misc.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("misc", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse_tostring(arg_2_0, arg_2_1, arg_2_2)
	arg_2_0.dict_[arg_2_2] = arg_2_1
end

function var_0_2.parse_tonumber(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0.dict_[arg_3_2] = tonumber(arg_3_1)
end

function var_0_2.parse_splitToString(arg_4_0, arg_4_1, arg_4_2)
	arg_4_0.dict_[arg_4_2] = var_0_1.split(arg_4_1, "|")
end

function var_0_2.parse_splitToNumber(arg_5_0, arg_5_1, arg_5_2)
	arg_5_0.dict_[arg_5_2] = var_0_1.splitToNumber(arg_5_1, "|")
end

function var_0_2.parse(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1.key
	local var_6_1 = arg_6_1.value

	if var_6_0 == "web_api_url" then
		arg_6_0.webAPIURL = var_6_1
	elseif var_6_0 == "min_resolution_ratio" then
		arg_6_0.minimumResolutionRatio = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "content_scale_factor" then
		arg_6_0.contentScaleFactor = tonumber(var_6_1) / var_0_1.DECIMAL_BASE
	elseif var_6_0 == "design_width" then
		arg_6_0.designWidth = tonumber(var_6_1)
	elseif var_6_0 == "design_height" then
		arg_6_0.designHeight = tonumber(var_6_1)
	elseif var_6_0 == "fps" then
		arg_6_0.fps = tonumber(var_6_1)
	elseif var_6_0 == "magic_shop_refresh_crystal" then
		arg_6_0.magicShopRefreshCrystal = tonumber(var_6_1)
	elseif var_6_0 == "expand_hero_slot_num" then
		arg_6_0.expandHeroSlotNum = tonumber(var_6_1)
	elseif var_6_0 == "max_swallow_hero_num" then
		arg_6_0.maxSwallowHeroNum = tonumber(var_6_1)
	elseif var_6_0 == "max_battle_hero_num" then
		arg_6_0.maxBattleHeroNum = tonumber(var_6_1)
	elseif var_6_0 == "arena_max_hero_num" then
		arg_6_0.arenaMaxHeroNum = tonumber(var_6_1)
	elseif var_6_0 == "arena_battle_invitation" then
		arg_6_0.arenaBattleInvitation = tonumber(var_6_1)
	elseif var_6_0 == "max_battle_friend_num" then
		arg_6_0.maxBattleFriendNum = tonumber(var_6_1)
	elseif var_6_0 == "social_friend_max_number" then
		arg_6_0.maxFriendNum = tonumber(var_6_1)
	elseif var_6_0 == "social_request_limit" then
		arg_6_0.socialRequestLimit = tonumber(var_6_1)
	elseif var_6_0 == "social_point_max_total" then
		arg_6_0.maxSocialPoint = tonumber(var_6_1)
	elseif var_6_0 == "guild_create_diamond" then
		arg_6_0.guildCreateDiamond = tonumber(var_6_1)
	elseif var_6_0 == "guild_request_limit" then
		arg_6_0.guildRequstLimit = tonumber(var_6_1)
	elseif var_6_0 == "guild_create_lev" then
		arg_6_0.guildCreateLevel = tonumber(var_6_1)
	elseif var_6_0 == "guild_create_mana" then
		arg_6_0.guildCreateMana = tonumber(var_6_1)
	elseif var_6_0 == "guild_create_desc_limit" then
		arg_6_0.guildDescMaxCharNum = tonumber(var_6_1)
	elseif var_6_0 == "guild_create_desc_lower_bound" then
		arg_6_0.guildDescMinCharNum = tonumber(var_6_1)
	elseif var_6_0 == "guild_bulletin_limit" then
		arg_6_0.guildBulletinMaxCharNum = tonumber(var_6_1)
	elseif var_6_0 == "guild_bulletin_lower_bound" then
		arg_6_0.guildBulletinMinCharNum = tonumber(var_6_1)
	elseif var_6_0 == "guild_create_name_limit" then
		arg_6_0.guildNameMaxCharNum = tonumber(var_6_1)
	elseif var_6_0 == "guild_create_name_lower_bound" then
		arg_6_0.guildNameMinCharNum = tonumber(var_6_1)
	elseif var_6_0 == "energy_incr_time" then
		arg_6_0.energyIncrTime = tonumber(var_6_1)
	elseif var_6_0 == "invitation_incr_time" then
		arg_6_0.invitationIncrTime = tonumber(var_6_1)
	elseif var_6_0 == "rune_backpack_max" then
		arg_6_0.maxRuneBag = tonumber(var_6_1)
	elseif var_6_0 == "arena_win_glory_award" then
		arg_6_0.arenaWinGloryAward = tonumber(var_6_1)
	elseif var_6_0 == "arena_auto_refresh_time" then
		arg_6_0.arenaAutoRefreshTime = tonumber(var_6_1)
	elseif var_6_0 == "arena_rank_refresh_duration" then
		arg_6_0.arenaRankRefreshDuration = tonumber(var_6_1)
	elseif var_6_0 == "xiangong_output_show_time" then
		arg_6_0.xianGongOutputShowTime = tonumber(var_6_1)
	elseif var_6_0 == "guide_qianghua_partner" then
		local var_6_2, var_6_3 = var_6_1:find(":")

		arg_6_0.guideQiangHuaPartner = tonumber(var_6_1:sub(1, var_6_2 - 1))
	elseif var_6_0 == "arena_refresh_crystal" then
		arg_6_0.arenaRefreshCrystal = tonumber(var_6_1)
	elseif var_6_0 == "player_name_min_length" then
		arg_6_0.playerNameMinLength = tonumber(var_6_1)
	elseif var_6_0 == "player_name_max_length" then
		arg_6_0.playerNameMaxLength = tonumber(var_6_1)
	elseif var_6_0 == "arena_refresh_duration" then
		arg_6_0.arenaRefreshDuration = tonumber(var_6_1)
	elseif var_6_0 == "auto_battle_open_level" then
		arg_6_0.autoBattleOpenLevel = 3
	elseif var_6_0 == "skill_point_incr_time" then
		arg_6_0.skillPointDuration = tonumber(var_6_1)
	elseif var_6_0 == "summon_mana_free_period" then
		arg_6_0.freeManaSummonDuration = tonumber(var_6_1)
	elseif var_6_0 == "summon_crystal_free_period" then
		arg_6_0.freeCrystalSummonDuration = tonumber(var_6_1)
	elseif var_6_0 == "revive_duration" then
		arg_6_0.reviveDuration = tonumber(var_6_1)
	elseif var_6_0 == "soul_summon_animation_duration" then
		arg_6_0.stoneSummonDuration = tonumber(var_6_1)
	elseif var_6_0 == "summon_animation_duration" then
		arg_6_0.summonDuration = tonumber(var_6_1)
	elseif var_6_0 == "summon_animation_delay" then
		arg_6_0.summonDelay = tonumber(var_6_1)
	elseif var_6_0 == "multi_summon_animation_duration" then
		arg_6_0.summonTenDuration = tonumber(var_6_1)
	elseif var_6_0 == "shake_off_position1" then
		arg_6_0.shakeOffPos1 = tonumber(var_6_1)
	elseif var_6_0 == "shake_off_position2" then
		arg_6_0.shakeOffPos2 = tonumber(var_6_1)
	elseif var_6_0 == "story_shake_duration" then
		arg_6_0.storyShakeDuration = tonumber(var_6_1)
	elseif var_6_0 == "midas_base" then
		arg_6_0.midasBase = tonumber(var_6_1)
	elseif var_6_0 == "midas_lv_increase" then
		arg_6_0.midasLvInr = tonumber(var_6_1)
	elseif var_6_0 == "midas_float_down" then
		arg_6_0.midasLeast = tonumber(var_6_1)
	elseif var_6_0 == "base_avatar" then
		arg_6_0.baseAvatar = var_0_1.luaStringSplit(var_6_1, "|")
	elseif var_6_0 == "edit_name_cost" then
		arg_6_0.editNameCost = tonumber(var_6_1)
	elseif var_6_0 == "arena_refresh_cost" then
		arg_6_0.arenaRefreshCost = tonumber(var_6_1)
	elseif var_6_0 == "treasure_team2_open_lv" then
		arg_6_0.treasureTeam2OpenLV = tonumber(var_6_1)
	elseif var_6_0 == "treasure_sp_interval" then
		arg_6_0.treasureSPInterval = tonumber(var_6_1)
	elseif var_6_0 == "treasure_root_cost" then
		arg_6_0.treasureRootCost = tonumber(var_6_1)
	elseif var_6_0 == "treasure_buy_sp_num" then
		arg_6_0.treasureBuySPNum = tonumber(var_6_1)
	elseif var_6_0 == "treasure_sp_limit" then
		arg_6_0.treasureSPLimit = tonumber(var_6_1)
	elseif var_6_0 == "Match_Duration" then
		arg_6_0.treasureMatchDuration = tonumber(var_6_1)
	elseif var_6_0 == "expedition_init_mana" then
		arg_6_0.marchInitMp = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "comment_crystal_award" then
		arg_6_0.commendReward = tonumber(var_6_1)
	elseif var_6_0 == "comment_remind_lv" then
		arg_6_0.commendRewardLevs = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "Work_Time_Limit" then
		arg_6_0.workTimeLimit = tonumber(var_6_1)
	elseif var_6_0 == "fund_price" then
		arg_6_0.fundPrice = tonumber(var_6_1)
	elseif var_6_0 == "invitation_lv_limit" then
		arg_6_0.inviteLevLimit = tonumber(var_6_1)
	elseif var_6_0 == "encrypto_key" then
		arg_6_0.encryptoKey = tostring(var_6_1)
	elseif var_6_0 == "top_refresh_cost" then
		arg_6_0.topRefreshCost = tonumber(var_6_1)
	elseif var_6_0 == "top_buy_cost" then
		arg_6_0.topBuyCost = tonumber(var_6_1)
	elseif var_6_0 == "top_start" then
		arg_6_0.topStartTime = tonumber(var_6_1)
	elseif var_6_0 == "top_stop" then
		arg_6_0.topStopTime = tonumber(var_6_1)
	elseif var_6_0 == "guild_avatar" then
		arg_6_0.teamIcons = var_0_1.luaStringSplit(var_6_1, "|")
	elseif var_6_0 == "guild_level_min" then
		arg_6_0.teamLevelMin = tonumber(var_6_1)
	elseif var_6_0 == "guild_level_max" then
		arg_6_0.teamLevelMax = tonumber(var_6_1)
	elseif var_6_0 == "guild_mail_body_limit" then
		arg_6_0.teamMailBodyLimit = tonumber(var_6_1)
	elseif var_6_0 == "guild_mail_title_limit" then
		arg_6_0.teamMailTitleLimit = tonumber(var_6_1)
	elseif var_6_0 == "guild_people_limit" then
		arg_6_0.teamPeopleLimit = tonumber(var_6_1)
	elseif var_6_0 == "drink_energy_num1" then
		arg_6_0.drinkEnergyNum1 = tonumber(var_6_1)
	elseif var_6_0 == "drink_energy_num2" then
		arg_6_0.drinkEnergyNum2 = tonumber(var_6_1)
	elseif var_6_0 == "drink_energy_num3" then
		arg_6_0.drinkEnergyNum3 = tonumber(var_6_1)
	elseif var_6_0 == "dink_cost_1" then
		arg_6_0.drinkCost1 = tonumber(var_6_1)
	elseif var_6_0 == "dink_cost_2" then
		arg_6_0.drinkCost2 = tonumber(var_6_1)
	elseif var_6_0 == "drink_buy_number1" then
		arg_6_0.drinkBuyNum1 = tonumber(var_6_1)
	elseif var_6_0 == "drink_buy_number2" then
		arg_6_0.drinkBuyNum2 = tonumber(var_6_1)
	elseif var_6_0 == "drink_invite1" then
		arg_6_0.drinkInvite1 = tonumber(var_6_1)
	elseif var_6_0 == "drink_invite2" then
		arg_6_0.drinkInvite2 = tonumber(var_6_1)
	elseif var_6_0 == "guild_vitality_limit1" then
		arg_6_0.guildVitalitySelfLimit = tonumber(var_6_1)
	elseif var_6_0 == "guild_vitality_limit2" then
		arg_6_0.guildVitalityGuildLimit = tonumber(var_6_1)
	elseif var_6_0 == "guild_search_limit" then
		arg_6_0.guildIdLengthLimit = tonumber(var_6_1)
	elseif var_6_0 == "fb_link" then
		arg_6_0.fb_link = var_6_1
	elseif var_6_0 == "skill_point_full_hide_min_lv" then
		arg_6_0.skill_point_full_hide_min_lv = tonumber(var_6_1)
	elseif var_6_0 == "skill_point_full_hide_max_lv" then
		arg_6_0.skill_point_full_hide_max_lv = tonumber(var_6_1)
	elseif var_6_0 == "team_time_limit" then
		arg_6_0.guildCampaignTimeLimits = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "dungeon_challenge_limit" then
		arg_6_0.dungenChallengeLimit = tonumber(var_6_1)
	elseif var_6_0 == "dungeon_boss_start" then
		arg_6_0.dungenBossStart = tonumber(var_6_1)
	elseif var_6_0 == "dungeon_boss_stop" then
		arg_6_0.dungenBossStop = tonumber(var_6_1)
	elseif var_6_0 == "tarot_buy1_mana" then
		arg_6_0.tarotBuyOne = tonumber(var_6_1)
	elseif var_6_0 == "tarot_buy10_mana" then
		arg_6_0.tarotBuyTen = tonumber(var_6_1)
	elseif var_6_0 == "energy_max_limit" then
		arg_6_0.energyMaxLimit = tonumber(var_6_1)
	elseif var_6_0 == "awaken_open_level" then
		arg_6_0.awakenOpenLev = tonumber(var_6_1)
	elseif var_6_0 == "bloodline_open_level" then
		arg_6_0.awakeTwiceOpenLev = tonumber(var_6_1)
	elseif var_6_0 == "bloodline_open_quality" then
		arg_6_0.awakeTwiceOpenQua = tonumber(var_6_1)
	elseif var_6_0 == "element_entrance_display_lv" then
		arg_6_0.elementEntranceLv = tonumber(var_6_1)
	elseif var_6_0 == "open_energy_reduce_chapter" then
		arg_6_0.energyReduceChapter = tonumber(var_6_1)
	elseif var_6_0 == "redpackets_dis_message" then
		arg_6_0.redEnvelopeShowMaxNum = tonumber(var_6_1)
	elseif var_6_0 == "redpackets_get_time" then
		arg_6_0.redEnvelopeExpireTime = tonumber(var_6_1)
	elseif var_6_0 == "luckypackets_get_time" then
		arg_6_0.luckyPacketsExpireTime = tonumber(var_6_1)
	elseif var_6_0 == "luckypackets_dis_message" then
		arg_6_0.luckyPacketsShowMaxNum = tonumber(var_6_1)
	elseif var_6_0 == "kites_get_time" then
		arg_6_0.kitesExpireTime = tonumber(var_6_1)
	elseif var_6_0 == "kites_dis_message" then
		arg_6_0.kitesShowMaxNum = tonumber(var_6_1)
	elseif var_6_0 == "newyear_total_num" then
		arg_6_0.fireTotalNum = tonumber(var_6_1)
	elseif var_6_0 == "newyear_challenge_num" then
		arg_6_0.newYearChallengeNum = tonumber(var_6_1)
	elseif var_6_0 == "default_avatar" then
		arg_6_0.defaultAvatarId = tonumber(var_6_1)
	elseif var_6_0 == "default_avatar_frame" then
		arg_6_0.defaultAvatarFrameId = tonumber(var_6_1)
	elseif var_6_0 == "chat_limit_time" then
		arg_6_0.chatLimitTime = tonumber(var_6_1)
	elseif var_6_0 == "sakura_security_price" then
		arg_6_0.sakuraSecurityPrice = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "sakura_security_buy_limit" then
		arg_6_0.sakuraSecurityBuyLimit = tonumber(var_6_1)
	elseif var_6_0 == "sakura_security_fight_limit" then
		arg_6_0.sakuraSecurityFightLimit = tonumber(var_6_1)
	elseif var_6_0 == "first_egg" then
		arg_6_0.firstEgg = tonumber(var_6_1)
	elseif var_6_0 == "skill_book_item" then
		arg_6_0.skillBookItem = tonumber(var_6_1)
	elseif var_6_0 == "pet_hatch_cost_param" then
		arg_6_0.petHatchCostParam = tonumber(var_6_1)
	elseif var_6_0 == "pet_fatigue_limit" then
		arg_6_0.petFatigueLimit = tonumber(var_6_1)
	elseif var_6_0 == "skycity_layer_time" then
		arg_6_0.petSweepLayerTime = tonumber(var_6_1)
	elseif var_6_0 == "skycity_layer_cost" then
		arg_6_0.petSweepLayerCost = tonumber(var_6_1)
	elseif var_6_0 == "battle_cost_fatigue" then
		arg_6_0.petBattleFatigue = tonumber(var_6_1)
	elseif var_6_0 == "exchange_init" then
		arg_6_0.guildExchangeDrinkInit = tonumber(var_6_1)
	elseif var_6_0 == "day_exchange_limit" then
		arg_6_0.dayExchangeDrinkLimit = tonumber(var_6_1)
	elseif var_6_0 == "exchange_active" then
		arg_6_0.drinkExchangeActive = tonumber(var_6_1)
	elseif var_6_0 == "buy_group_cost" then
		arg_6_0.buyGroupCost = tonumber(var_6_1)
	elseif var_6_0 == "scratch_card_cost" then
		arg_6_0.scratchCardCost = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "chat_limit_words" then
		arg_6_0.chatLimitWords = tonumber(var_6_1)
	elseif var_6_0 == "newskin_discount" then
		arg_6_0.newskinDiscount = tonumber(var_6_1)
	elseif var_6_0 == "dragonboat_buy_diamond" then
		arg_6_0.dragonBoatBuyTimesCost = tonumber(var_6_1)
	elseif var_6_0 == "dragon_boat_whirl_caution" then
		arg_6_0.dragonBoatWhirlCautionFrames = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_saturation_time" then
		arg_6_0.eventCentreSaturationTime = tonumber(var_6_1)
	elseif var_6_0 == "beach_pink_damage" then
		arg_6_0.pinkDamage = tonumber(var_6_1)
	elseif var_6_0 == "beach_blue_damage" then
		arg_6_0.blueDamage = tonumber(var_6_1)
	elseif var_6_0 == "beach_red_damage" then
		arg_6_0.redDamage = tonumber(var_6_1)
	elseif var_6_0 == "beach_free_attack_num" then
		arg_6_0.beachFreeAttackNum = tonumber(var_6_1)
	elseif var_6_0 == "beach_buy_attack_num" then
		arg_6_0.beachBuyAttackNum = tonumber(var_6_1)
	elseif var_6_0 == "beach_critical_times" then
		arg_6_0.beachCritNum = tonumber(var_6_1)
	elseif var_6_0 == "beach_buy_game_price" then
		arg_6_0.beachBuyGamePrice = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "beach_buy_attack_price" then
		arg_6_0.beachBuyAttackPrice = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "beach_buy_critical_price" then
		arg_6_0.beachBuyCritPrice = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "beach_buy_game_limit" then
		arg_6_0.beachBuyGameLimit = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_saturation_init" then
		arg_6_0.saturationInit = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_open_book" then
		arg_6_0.eventCentreOpenBook = tonumber(var_6_1)
	elseif var_6_0 == "beach_dandao" then
		arg_6_0.beachDandao = var_0_1.split(var_6_1, "|")
	elseif var_6_0 == "beach_shouji" then
		arg_6_0.beachHurt = var_0_1.split(var_6_1, "|")
	elseif var_6_0 == "event_centre_skill_exp" then
		arg_6_0.eventCentreSkillExp = var_0_1.split(var_6_1, "|")
	elseif var_6_0 == "event_centre_book_exp" then
		arg_6_0.eventCentreBookExp = var_0_1.split(var_6_1, "|")
	elseif var_6_0 == "activity_outing_circle_gift" then
		arg_6_0.outingCircleGift = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_outing_circle_full" then
		arg_6_0.outingCircleFull = tonumber(var_6_1)
	elseif var_6_0 == "guild_battle_turn" then
		arg_6_0.guildBattleTurn = tonumber(var_6_1)
	elseif var_6_0 == "region_arena_star_time" then
		arg_6_0.regionArenaStartTime = var_6_1
	elseif var_6_0 == "region_arena_end_time" then
		arg_6_0.regionArenaEndTime = var_6_1
	elseif var_6_0 == "guild_battle_cost" then
		arg_6_0.guildBattleCost = tonumber(var_6_1)
	elseif var_6_0 == "guild_war_notice_num" then
		arg_6_0.guildWarNoticeNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_candle_total" then
		arg_6_0.candleTotal = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_candle_coin" then
		arg_6_0.candleCoin = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_candle_diamond" then
		arg_6_0.candleDiamond = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_candle_cost" then
		arg_6_0.candleCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_candle_item" then
		arg_6_0.candleItem = tonumber(var_6_1)
	elseif var_6_0 == "dialog_default_time" then
		arg_6_0.dialogDefaultTime = tonumber(var_6_1)
	elseif var_6_0 == "married_attr_growth" then
		arg_6_0.marriedAttrGrowth = tonumber(var_6_1)
	elseif var_6_0 == "incubus_energy_cost" then
		arg_6_0.incubusEnergy = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "dialog_speed" then
		arg_6_0.dialogSpeed = tonumber(var_6_1)
	elseif var_6_0 == "star_treasure_max_floor" then
		arg_6_0.starTreasureMaxFloor = tonumber(var_6_1)
	elseif var_6_0 == "friend_number_limit" then
		arg_6_0.friendNumberLimit = tonumber(var_6_1)
	elseif var_6_0 == "gift_send_limit" then
		arg_6_0.giftSendLimit = tonumber(var_6_1)
	elseif var_6_0 == "gift_get_limit" then
		arg_6_0.giftGetLimit = tonumber(var_6_1)
	elseif var_6_0 == "offline_message_number" then
		arg_6_0.offlineMessageNumber = tonumber(var_6_1)
	elseif var_6_0 == "friend_battle_level" then
		arg_6_0.friendBattleLevel = tonumber(var_6_1)
	elseif var_6_0 == "herosell_buy_limit" then
		arg_6_0.herosellBuyLimit = tonumber(var_6_1)
	elseif var_6_0 == "paradise_daily_challenge_num" then
		arg_6_0.illusionInitTime = tonumber(var_6_1)
	elseif var_6_0 == "region_hero_level" then
		arg_6_0.regionHeroLevel = tonumber(var_6_1)
	elseif var_6_0 == "region_hero_color" then
		arg_6_0.regionHeroColor = tonumber(var_6_1)
	elseif var_6_0 == "skin_ticket_id" then
		arg_6_0.skinTicketId = tonumber(var_6_1)
	elseif var_6_0 == "practice_ticket_id" then
		arg_6_0.practiceTicketId = tonumber(var_6_1)
	elseif var_6_0 == "activity_fusion_max" then
		arg_6_0.activityFusionMax = tonumber(var_6_1)
	elseif var_6_0 == "activity_fusion_server_target" then
		arg_6_0.activityFusionServerTarget = tonumber(var_6_1)
	elseif var_6_0 == "activity_fusion_target_require" then
		arg_6_0.activityFusionTargetRequire = tonumber(var_6_1)
	elseif var_6_0 == "activity_fusion_server_gift" then
		arg_6_0.activityFusionServerGift = tonumber(var_6_1)
	elseif var_6_0 == "single_doggift_time" then
		arg_6_0.singleDogGiftTime = tonumber(var_6_1)
	elseif var_6_0 == "pet_awaken_sweep_cost" then
		arg_6_0.petAwakenSweepCost = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "apply_time_limit" then
		arg_6_0.applyFellowTimeLimit = tonumber(var_6_1)
	elseif var_6_0 == "single_remove_partner_params1" then
		arg_6_0.singleRemovePartnerParams1 = tonumber(var_6_1)
	elseif var_6_0 == "single_remove_partner_params2" then
		arg_6_0.singleRemovePartnerParams2 = tonumber(var_6_1)
	elseif var_6_0 == "single_challenge_ratio" then
		arg_6_0.singleChallengeRatio = tonumber(var_6_1)
	elseif var_6_0 == "single_challenge_limit" then
		arg_6_0.singleChallengeLimit = tonumber(var_6_1)
	elseif var_6_0 == "guild_battle_limit" then
		arg_6_0.guildBattleLimit = tonumber(var_6_1)
	elseif var_6_0 == "blessing_crystal" then
		arg_6_0.blessing_crystal = tonumber(var_6_1)
	elseif var_6_0 == "blessing_crystal_debris" then
		arg_6_0.blessing_crystal_debris = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_stone_agility" then
		arg_6_0.event_centre_stone_agility = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_stone_agility_conrrection" then
		arg_6_0.event_centre_stone_agility_conrrection = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_stone_strength" then
		arg_6_0.event_centre_stone_strength = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_stone_strength_conrrection" then
		arg_6_0.event_centre_stone_strength_conrrection = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_stone_intelligence_upper" then
		arg_6_0.event_centre_stone_intelligence_upper = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_stone_intelligence_upper_conrrection" then
		arg_6_0.event_centre_stone_intelligence_upper_conrrection = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_stone_intelligence_low" then
		arg_6_0.event_centre_stone_intelligence_low = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_stone_intelligence_low_conrrection" then
		arg_6_0.event_centre_stone_intelligence_low_conrrection = tonumber(var_6_1)
	elseif var_6_0 == "world_match_time" then
		arg_6_0.worldMatchTime = tonumber(var_6_1)
	elseif var_6_0 == "friend_buy_limit" then
		arg_6_0.friendBuyLimit = tonumber(var_6_1)
	elseif var_6_0 == "lvbu_walk_total" then
		arg_6_0.lvbuWalkTotal = tonumber(var_6_1)
	elseif var_6_0 == "lvbu_walk_buy" then
		arg_6_0.lvbuWalkBuy = tonumber(var_6_1)
	elseif var_6_0 == "lvbu_team_change" then
		arg_6_0.lvbuTeamChange = tonumber(var_6_1)
	elseif var_6_0 == "lvbu_match_ticket" then
		arg_6_0.lubuMatchTicket = tonumber(var_6_1)
	elseif var_6_0 == "lvbu_cost_once" then
		arg_6_0.lvbuCostOnce = tonumber(var_6_1)
	elseif var_6_0 == "lvbu_cost_five" then
		arg_6_0.lvbuCostFive = tonumber(var_6_1)
	elseif var_6_0 == "lvbu_vip_limit" then
		arg_6_0.lvbuVipLimit = tonumber(var_6_1)
	elseif var_6_0 == "lvbu_partner_id" then
		arg_6_0.lvbuTableID = tonumber(var_6_1)
	elseif var_6_0 == "lvbu_broken_card" then
		arg_6_0.lvbuBrokenCard = tonumber(var_6_1)
	elseif var_6_0 == "lvbu_repair_dollar" then
		arg_6_0.lvbuRepairDollar = tonumber(var_6_1)
	elseif var_6_0 == "indiegogo_storage_upper" then
		arg_6_0.indiegogoStorageUpper = tonumber(var_6_1)
	elseif var_6_0 == "guild_camp_limt" then
		arg_6_0.guildCampLimt = var_0_1.split(var_6_1, "|")
	elseif var_6_0 == "crowd_fund_lev_limit" then
		arg_6_0.crowdFundLevLimit = tonumber(var_6_1)
	elseif var_6_0 == "new_arena_challenge_begin" then
		arg_6_0.newArenaChallengeBegin = tonumber(var_6_1)
	elseif var_6_0 == "new_arena_challenge_finish" then
		arg_6_0.newArenaChallengeFinish = tonumber(var_6_1)
	elseif var_6_0 == "shop_exclusive_cost_array" then
		arg_6_0.shopExclusiveCostArray = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_en_hero_exchange" then
		arg_6_0.enHeroExchange = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_en_hero_exchange_rate" then
		arg_6_0.enHeroExchangeRate = tonumber(var_6_1)
	elseif var_6_0 == "activity_en_christmas_new_chest" then
		arg_6_0.vipBoxDrawCost1 = tonumber(var_6_1)
	elseif var_6_0 == "activity_en_christmas_old_chest" then
		arg_6_0.vipBoxDrawCost2 = tonumber(var_6_1)
	elseif var_6_0 == "friend_recall_days" then
		arg_6_0.friendRecallDays = tonumber(var_6_1)
	elseif var_6_0 == "friend_recall_task_time" then
		arg_6_0.friendRecallTaskDays = tonumber(var_6_1)
	elseif var_6_0 == "friend_recall_task_limit" then
		arg_6_0.friendRecallTaskLimit = tonumber(var_6_1)
	elseif var_6_0 == "new_arena_conceal_num" then
		arg_6_0.newArenaConcealNum = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "new_arena_conceal_rank" then
		arg_6_0.newArenaConcealRank = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "new_arena_audience_award_basis" then
		arg_6_0.newArenaAudienceAwardBasis = tonumber(var_6_1)
	elseif var_6_0 == "new_arena_audience_award_num" then
		arg_6_0.newArenaAudienceAwardNum = tonumber(var_6_1)
	elseif var_6_0 == "new_arena_audience_award_time" then
		arg_6_0.newArenaAudienceAwardTime = tonumber(var_6_1)
	elseif var_6_0 == "skycity_super_paper" then
		arg_6_0.skyCitySuperPaper = tonumber(var_6_1)
	elseif var_6_0 == "activity_pray_timespan" then
		arg_6_0.activityPrayTimespan = tonumber(var_6_1)
	elseif var_6_0 == "activity_pray_time" then
		arg_6_0.activityPrayTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_pray_award_time" then
		arg_6_0.activityPrayAwardTime = tonumber(var_6_1)
	elseif var_6_0 == "max_pet_color" then
		arg_6_0.maxPetColor = tonumber(var_6_1)
	elseif var_6_0 == "skycity_super_times_buy" then
		arg_6_0.skyCitySuperTimesBuy = tonumber(var_6_1)
	elseif var_6_0 == "arena_adjustment_time" then
		arg_6_0.arenaAdjustmentTime = tonumber(var_6_1)
	elseif var_6_0 == "skycity_test_cost" then
		arg_6_0.skyCityTestCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_cook_time" then
		arg_6_0.yuanxiaoCookTime = tonumber(var_6_1)
	elseif var_6_0 == "library_act_feel_radius" then
		arg_6_0.libraryActFeelRadicus = tonumber(var_6_1)
	elseif var_6_0 == "library_act_feel_increase" then
		arg_6_0.libraryActFeelIncrease = tonumber(var_6_1)
	elseif var_6_0 == "library_act_feel_decrease" then
		arg_6_0.libraryActFeelDecrease = tonumber(var_6_1)
	elseif var_6_0 == "library_act_touch_increase" then
		arg_6_0.libraryActTouchIncrease = tonumber(var_6_1)
	elseif var_6_0 == "library_act_touch_decrease" then
		arg_6_0.libraryActTouchDecrease = tonumber(var_6_1)
	elseif var_6_0 == "library_favor_limit" then
		arg_6_0.libraryFavorLimit = tonumber(var_6_1)
	elseif var_6_0 == "guide_break_enemy" then
		arg_6_0.guideBreakEnemy = tonumber(var_6_1)
	elseif var_6_0 == "auto_battle_open_campaign" then
		arg_6_0.autoBattleOpenCampaign = tonumber(var_6_1)
	elseif var_6_0 == "library_speed_min" then
		arg_6_0.librarySpeedMin = tonumber(var_6_1)
	elseif var_6_0 == "library_speed_max" then
		arg_6_0.librarySpeedMax = tonumber(var_6_1)
	elseif var_6_0 == "guild_normal_scroll_request_num" then
		arg_6_0.guildNormalScrollRequestNum = tonumber(var_6_1)
	elseif var_6_0 == "guild_sx_scroll_request_num" then
		arg_6_0.guildSXScrollRequestNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_clothes_shop_discount" then
		arg_6_0.skinShopDiscountNum = tonumber(var_6_1)
	elseif var_6_0 == "guild_donate_scroll_reward" then
		arg_6_0.guildDonateScrollReward = tonumber(var_6_1)
	elseif var_6_0 == "skin_cost_yuanbao" then
		arg_6_0.skinCostYuanbao = tonumber(var_6_1)
	elseif var_6_0 == "remove_inscript_cost" then
		arg_6_0.removeInscriptionCost = tonumber(var_6_1)
	elseif var_6_0 == "speacial_item_id" then
		arg_6_0.speacialItemID = tonumber(var_6_1)
	elseif var_6_0 == "inscript_cost_items" then
		arg_6_0.inscriptCostItems = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "treasure_color_param" then
		arg_6_0.treasureColorParam = tonumber(var_6_1)
	elseif var_6_0 == "treasure_star_param" then
		arg_6_0.treasureStarParam = tonumber(var_6_1)
	elseif var_6_0 == "treasure_level_param" then
		arg_6_0.treasureLevelParam = tonumber(var_6_1)
	elseif var_6_0 == "treasure_gold_param1" then
		arg_6_0.treasureGoldParam1 = tonumber(var_6_1)
	elseif var_6_0 == "treasure_gold_param2" then
		arg_6_0.treasureGoldParam2 = tonumber(var_6_1)
	elseif var_6_0 == "treasure_exp_param" then
		arg_6_0.treasureExpParam = tonumber(var_6_1)
	elseif var_6_0 == "treasure_scroll_param" then
		arg_6_0.treasureScrollParam = tonumber(var_6_1) / 100000
	elseif var_6_0 == "treasure_magic_dust_param" then
		arg_6_0.treasureMagicDustParam = tonumber(var_6_1)
	elseif var_6_0 == "treasure_magic_liquid_param" then
		arg_6_0.treasureMagicLiquidParam = tonumber(var_6_1)
	elseif var_6_0 == "treasure_glue_param" then
		arg_6_0.treasureGlueParam = tonumber(var_6_1) / 100000
	elseif var_6_0 == "event_centre_accelerate_item" then
		arg_6_0.eventCentreAccelerateItem = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_accelerate_time" then
		arg_6_0.eventCentreAccelerateTime = tonumber(var_6_1)
	elseif var_6_0 == "event_centre_pet_cost_item" then
		arg_6_0.eventCentrePetCostItem = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "event_centre_pet_color_accelerate_time" then
		arg_6_0.eventCentrePetColorAccelerateTime = tonumber(var_6_1)
	elseif var_6_0 == "conquer_school_challenge_num" then
		arg_6_0.conquerSchoolChallengeNum = tonumber(var_6_1)
	elseif var_6_0 == "conquer_school_hurt_param" then
		arg_6_0.conquerSchoolHurtParam = tonumber(var_6_1)
	elseif var_6_0 == "activity_sakura2_cook_material" then
		arg_6_0.activitySakura2CookMaterial = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_sakura2_sit_model" then
		arg_6_0.activitySakura2SitModel = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "teacher_lev" then
		arg_6_0.teacherLev = tonumber(var_6_1)
	elseif var_6_0 == "teacher_relation_send_times" then
		arg_6_0.teacherRelationSendTimes = tonumber(var_6_1)
	elseif var_6_0 == "student_lev_limit" then
		arg_6_0.studentLevLimit = tonumber(var_6_1)
	elseif var_6_0 == "person_comment_page" then
		arg_6_0.personCommentPage = tonumber(var_6_1)
	elseif var_6_0 == "person_comment_every_page_message_num" then
		arg_6_0.personCommentEveryPageMsgNum = tonumber(var_6_1)
	elseif var_6_0 == "announce_last_time" then
		arg_6_0.announceLastTime = tonumber(var_6_1)
	elseif var_6_0 == "announce_screen_time" then
		arg_6_0.announceScreenTime = tonumber(var_6_1)
	elseif var_6_0 == "match_out_time" then
		arg_6_0.matchOutTime = tonumber(var_6_1)
	elseif var_6_0 == "super_announce_times" then
		arg_6_0.superAnnounceTimes = tonumber(var_6_1)
	elseif var_6_0 == "monday_gift_id" then
		arg_6_0.mondayGiftId = tonumber(var_6_1)
	elseif var_6_0 == "small_monthcard_diamond" then
		arg_6_0.smallMonthCardDiamond = tonumber(var_6_1)
	elseif var_6_0 == "small_monthcard_period1" then
		arg_6_0.samllMonthCardPeriod1 = tonumber(var_6_1)
	elseif var_6_0 == "small_monthcard_period2" then
		arg_6_0.samllMonthCardPeriod2 = tonumber(var_6_1)
	elseif var_6_0 == "small_monthcard_model1" then
		arg_6_0.smallMonthCardModel1 = tonumber(var_6_1)
	elseif var_6_0 == "small_monthcard_model2" then
		arg_6_0.smallMonthCardModel2 = tonumber(var_6_1)
	elseif var_6_0 == "bank_activity_switch_time" then
		arg_6_0.bankActivitySwitchTime = tonumber(var_6_1)
	elseif var_6_0 == "bank_activity_end_time" then
		arg_6_0.bankActivityEndTime = tonumber(var_6_1)
	elseif var_6_0 == "bank_activity_rebate_ratio" then
		arg_6_0.bankActivityRebateRatio = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "greenhand_activity_gears" then
		arg_6_0.greenhandActivityGears = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "peak_arena_rank_limit" then
		arg_6_0.peakArenaRankLimit = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "dragonboat2_wave" then
		arg_6_0.dragonboat2Wave = tonumber(var_6_1)
	elseif var_6_0 == "activity_zhanghe_normal_chest" then
		arg_6_0.zhangheBoxCost2 = tonumber(var_6_1)
	elseif var_6_0 == "activity_zhanghe_special_chest" then
		arg_6_0.zhangheBoxCost1 = tonumber(var_6_1)
	elseif var_6_0 == "activity_zhanghe_lowest_chest" then
		arg_6_0.zhangheBoxCost3 = tonumber(var_6_1)
	elseif var_6_0 == "awake_item_wish" then
		arg_6_0.awakeItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_week_present_partner" then
		arg_6_0.activityWeekPresentPartner = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_week_day" then
		arg_6_0.activityWeekDay = tonumber(var_6_1)
	elseif var_6_0 == "activity_week_rechoose_cost" then
		arg_6_0.activityWeekRechooseCost = tonumber(var_6_1)
	elseif var_6_0 == "treasure_inscript_param" then
		arg_6_0.treasureInscriptParam = tonumber(var_6_1) / 100000
	elseif var_6_0 == "treasure_inscript_item1" then
		arg_6_0.treasureInscriptItem1 = tonumber(var_6_1)
	elseif var_6_0 == "treasure_inscript_item2" then
		arg_6_0.treasureInscriptItem2 = tonumber(var_6_1)
	elseif var_6_0 == "treasure_inscript_item3" then
		arg_6_0.treasureInscriptItem3 = tonumber(var_6_1)
	elseif var_6_0 == "relax_match_begin" then
		arg_6_0.relaxMatchBegin = tonumber(var_6_1)
	elseif var_6_0 == "relax_match_end" then
		arg_6_0.relaxMatchEnd = tonumber(var_6_1)
	elseif var_6_0 == "awake_item_wish_not" then
		arg_6_0.awakeItemWishNots = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "magic_shop_normal" then
		arg_6_0.magicShopNormal = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "magic_shop_discount" then
		arg_6_0.magicShopDiscount = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "team_dungeon_rank" then
		arg_6_0.teamDungeonRank = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "team_dungeon_rank_reward" then
		arg_6_0.teamDungeonRankReward = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "magic_shop_items" then
		local var_6_4 = var_0_1.luaStringSplit(var_6_1, "|")

		arg_6_0.magicShopItems = {}

		for iter_6_0 = 1, #var_6_4 do
			arg_6_0.magicShopItems[iter_6_0] = var_0_1.splitToNumber(var_6_4[iter_6_0], ",")
		end
	elseif var_6_0 == "zhuge_forest_partner_num" then
		arg_6_0.zhugeForestPartnerNum = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_forest_pet_num" then
		arg_6_0.zhugeForestPetNum = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_box2_item" then
		arg_6_0.zhugeBox2Item = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_teleport_battle" then
		arg_6_0.zhugeTeleportBattle = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_teleport_item" then
		arg_6_0.zhugeTeleportItem = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_forest_bag_max_num" then
		arg_6_0.zhugeForestBagMaxNum = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_forest_sweep_cost" then
		arg_6_0.zhugeForestSweepCost = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_forest_cost" then
		arg_6_0.zhugeForestCost = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_forest_helper_cost" then
		arg_6_0.zhugeForestHelperCost = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "zhuge_forest_helper_pet_cost" then
		arg_6_0.zhugeForestHelperPetCost = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "zhuge_teleport_max_damage" then
		arg_6_0.zhugeTeleportMaxDamage = tonumber(var_6_1)
	elseif var_6_0 == "object_classroom_time" then
		arg_6_0.objectClassRoomTime = tonumber(var_6_1)
	elseif var_6_0 == "object_classroom_knowledge" then
		arg_6_0.objectClassRoomKnowledge = tonumber(var_6_1)
	elseif var_6_0 == "object_classroom_money" then
		arg_6_0.objectClassRoomMoney = tonumber(var_6_1)
	elseif var_6_0 == "object_classroom_log_limit" then
		arg_6_0.objectClassRoomLogLimit = tonumber(var_6_1)
	elseif var_6_0 == "supremacy_action_point_upper" then
		arg_6_0.academyApUpper = tonumber(var_6_1)
	elseif var_6_0 == "supremacy_summon_point_upper" then
		arg_6_0.academySpUpper = tonumber(var_6_1)
	elseif var_6_0 == "school_memory_maze_col" then
		arg_6_0.memoriesOfSchoolMazeCol = tonumber(var_6_1)
	elseif var_6_0 == "school_memory_maze_row" then
		arg_6_0.memoriesOfSchoolMazeRow = tonumber(var_6_1)
	elseif var_6_0 == "school_memory_maze_key_small" then
		arg_6_0.memoriesOfSchoolKeySmall = tonumber(var_6_1)
	elseif var_6_0 == "school_memory_maze_max_floor" then
		arg_6_0.memoriesOfSchoolMaxFloor = tonumber(var_6_1)
	elseif var_6_0 == "school_memory_maze_girls" then
		arg_6_0.memoriesOfSchoolMazeGirls = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "paradise_team_limit" then
		arg_6_0.paradiseTeamLimit = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_buy_cost" then
		arg_6_0.summerGoldFishBuyCost = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_buy_num" then
		arg_6_0.summerGoldFishBuyNum = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_recharge_cost" then
		arg_6_0.summerGoldFishRechargeCost = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_recharge_num" then
		arg_6_0.summerGoldFishRechargeNum = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_super_net_pt" then
		arg_6_0.summerGoldFishSuperNetPt = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_super_net_item" then
		arg_6_0.summerGoldFishSuperNetItem = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_top_reward" then
		arg_6_0.summerGoldFishTopReward = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_rate_max" then
		arg_6_0.summerGoldFishRateMax = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_rank_num" then
		arg_6_0.summerGoldFishRankNum = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_start_time" then
		arg_6_0.summerQuizStartTime = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_end_time" then
		arg_6_0.summerQuizEndTime = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_question_num" then
		arg_6_0.summerQuizQuestionNum = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_revive_cost" then
		arg_6_0.summerQuizReviveCost = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_revive_time" then
		arg_6_0.summerQuizReviveTime = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_announce" then
		arg_6_0.summerQuizAnnounce = tonumber(var_6_1)
	elseif var_6_0 == "indiegogo_query_num" then
		arg_6_0.indiegogoQueryNum = tonumber(var_6_1)
	elseif var_6_0 == "auction_end_time" then
		arg_6_0.auctionEndTime = tonumber(var_6_1)
	elseif var_6_0 == "auction_start_time" then
		arg_6_0.auctionStartTime = tonumber(var_6_1)
	elseif var_6_0 == "vote_list_query_num" then
		arg_6_0.voteListQueryNum = tonumber(var_6_1)
	elseif var_6_0 == "vote_ticket_cost" then
		arg_6_0.voteTicketCost = tonumber(var_6_1)
	elseif var_6_0 == "object_box_book_numb" then
		arg_6_0.objectBoxBookNumb = tonumber(var_6_1)
	elseif var_6_0 == "object_box_book1" then
		arg_6_0.objectBoxBook1 = tonumber(var_6_1)
	elseif var_6_0 == "object_box_book2" then
		arg_6_0.objectBoxBook2 = tonumber(var_6_1)
	elseif var_6_0 == "object_box_books" then
		arg_6_0.objectBoxBooks = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_lottery_lucky_gift" then
		arg_6_0.activityLotteryLuckyGift = tonumber(var_6_1)
	elseif var_6_0 == "anni2_partner_refresh_cost" then
		arg_6_0.twoYearsRefreshCost = tonumber(var_6_1)
	elseif var_6_0 == "anni2_partner_refresh_time" then
		arg_6_0.twoYearsRefreshTime = tonumber(var_6_1)
	elseif var_6_0 == "anni2_present_item" then
		arg_6_0.twoYearspresentItem = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "anni2_present_limit_num" then
		arg_6_0.twoYearsPresentLimitNum = tonumber(var_6_1)
	elseif var_6_0 == "anni2_reward_max_lev" then
		arg_6_0.twoYearsRewardMaxLev = tonumber(var_6_1)
	elseif var_6_0 == "creats_ticket_get" then
		arg_6_0.creatsTicketGet = tonumber(var_6_1)
	elseif var_6_0 == "creats_ticket_max" then
		arg_6_0.creatsTicketMax = tonumber(var_6_1)
	elseif var_6_0 == "creats_team_limit" then
		arg_6_0.creatsTeamLimit = tonumber(var_6_1)
	elseif var_6_0 == "creats_team_people_limit" then
		arg_6_0.creatsTeamPeopleLimit = tonumber(var_6_1)
	elseif var_6_0 == "creats_campaign_duration" then
		arg_6_0.creatsCampaignDuration = tonumber(var_6_1)
	elseif var_6_0 == "creats_rescue_time" then
		arg_6_0.creatsRescueTime = tonumber(var_6_1)
	elseif var_6_0 == "creats_dispatch_hero_limit" then
		arg_6_0.creatsDispatchHeroLimit = tonumber(var_6_1)
	elseif var_6_0 == "creats_survival_param" then
		arg_6_0.creatsSurvivalParam = tonumber(var_6_1)
	elseif var_6_0 == "creats_dispatch_param" then
		arg_6_0.creatsDispatchParam = tonumber(var_6_1)
	elseif var_6_0 == "creats_time_param" then
		arg_6_0.creatsTimeParam = tonumber(var_6_1)
	elseif var_6_0 == "creats_timeout1" then
		arg_6_0.creatsTimeOut1 = tonumber(var_6_1)
	elseif var_6_0 == "creats_timeout2" then
		arg_6_0.creatsTimeOut2 = tonumber(var_6_1)
	elseif var_6_0 == "space_trip_replace_item" then
		arg_6_0.spaceShopItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_lianyi_materials" then
		arg_6_0.newTermMaterials = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_lianyi_charm" then
		arg_6_0.newTermCharmBonusIcon = tonumber(var_6_1)
	elseif var_6_0 == "activity_lianyi_connection" then
		arg_6_0.newTermConnectionBonusIcon = tonumber(var_6_1)
	elseif var_6_0 == "activity_lianyi_anime" then
		arg_6_0.newTermAnime = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_lianyi_color" then
		arg_6_0.newTermTextColor = var_0_1.luaStringSplit(var_6_1, "|")
	elseif var_6_0 == "amour_limit" then
		arg_6_0.amourLimit = tonumber(var_6_1)
	elseif var_6_0 == "arena_mode_enter_rank_req" then
		arg_6_0.arenaModeRank = tonumber(var_6_1)
	elseif var_6_0 == "arena_mode_enter_battle_req" then
		arg_6_0.arenaModeTimes = tonumber(var_6_1)
	elseif var_6_0 == "adventure_paradise_gift_single" then
		arg_6_0.adventureIllusionSingleGift = tonumber(var_6_1)
	elseif var_6_0 == "adventure_paradise_boss" then
		arg_6_0.adventureIllusionBoss = tonumber(var_6_1)
	elseif var_6_0 == "adventure_level_limit" then
		arg_6_0.adventureDefenseLevelLimit = tonumber(var_6_1)
	elseif var_6_0 == "adventure_monster_challenge_times_limit" then
		arg_6_0.adventureDefenseChallengeTimesLimit = tonumber(var_6_1)
	elseif var_6_0 == "adventure_challenge_choose_time_limit" then
		arg_6_0.adventureDefenseSelectTeamTimeLimit = tonumber(var_6_1)
	elseif var_6_0 == "adventure_paradise_gift" then
		arg_6_0.adventureIllusionCoopGift = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_revive_item" then
		arg_6_0.campWarReviveItem = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_boss_honor_param" then
		arg_6_0.campWarBossHonorParam = tonumber(var_6_1)
	elseif var_6_0 == "library_gift_right" then
		arg_6_0.libraryGiftRight = tonumber(var_6_1)
	elseif var_6_0 == "library_gift_wrong" then
		arg_6_0.libraryGiftWrong = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_hero_honor" then
		arg_6_0.campWarHeroHonor = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_num_difference" then
		arg_6_0.campWarNumDifference = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_battle_para1" then
		arg_6_0.campWarBattlePara1 = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_battle_para2" then
		arg_6_0.campWarBattlePara2 = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_battle_time" then
		arg_6_0.campWarBattleTime = tonumber(var_6_1)
	elseif var_6_0 == "max_challenge_chapter" then
		arg_6_0.maxChallengeChapter = tonumber(var_6_1)
	elseif var_6_0 == "activity_consume_gift_once" then
		arg_6_0.activityConsumeGiftOnce = tonumber(var_6_1)
	elseif var_6_0 == "activity_consume_gift_five" then
		arg_6_0.activityConsumeGiftFive = tonumber(var_6_1)
	elseif var_6_0 == "activity_charge_gift_once" then
		arg_6_0.activityChargeGiftOnce = tonumber(var_6_1)
	elseif var_6_0 == "en_anni_share" then
		arg_6_0.anniversary_share_url = var_6_1
	elseif var_6_0 == "faq_en_avatar_frames" then
		arg_6_0.faqEnAvatarFrames = tonumber(var_6_1)
	elseif var_6_0 == "faq_en_avatar" then
		arg_6_0.faqEnAvatar = tonumber(var_6_1)
	elseif var_6_0 == "guild_war_buff_price" then
		arg_6_0.guildWarBuffPrice = tonumber(var_6_1)
	elseif var_6_0 == "guild_war_buff_exchange" then
		arg_6_0.guildWarBuffExchange = tonumber(var_6_1)
	elseif var_6_0 == "guild_war_buff_max" then
		arg_6_0.guildWarBuffMax = tonumber(var_6_1)
	elseif var_6_0 == "faq_en_soulved" then
		arg_6_0.faqEnSoulved = var_6_1
	elseif var_6_0 == "get_redpacket_max_num" then
		arg_6_0.activityRedPacketGrabLimit = tonumber(var_6_1)
	elseif var_6_0 == "activity_test_paper_num" then
		arg_6_0.activityTestPaperNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_skin_warmup_partner" then
		arg_6_0.activitySkinWarmupPartner = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "zhuge_forest_partner_num" then
		arg_6_0.zhugeForestPartnerNum = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_forest_pet_num" then
		arg_6_0.zhugeForestPetNum = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_box1_item" then
		arg_6_0.zhugeBox1Item = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_box2_item" then
		arg_6_0.zhugeBox2Item = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_teleport_battle" then
		arg_6_0.zhugeTeleportBattle = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_teleport_item" then
		arg_6_0.zhugeTeleportItem = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_forest_bag_max_num" then
		arg_6_0.zhugeForestBagMaxNum = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_forest_sweep_cost" then
		arg_6_0.zhugeForestSweepCost = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_forest_cost" then
		arg_6_0.zhugeForestCost = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_forest_helper_cost" then
		arg_6_0.zhugeForestHelperCost = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "zhuge_forest_helper_pet_cost" then
		arg_6_0.zhugeForestHelperPetCost = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "zhuge_teleport_max_damage" then
		arg_6_0.zhugeTeleportMaxDamage = tonumber(var_6_1)
	elseif var_6_0 == "object_class_forget" then
		arg_6_0.objectClassForget = tonumber(var_6_1)
	elseif var_6_0 == "object_classroom_time" then
		arg_6_0.objectClassRoomTime = tonumber(var_6_1)
	elseif var_6_0 == "object_classroom_knowledge" then
		arg_6_0.objectClassRoomKnowledge = tonumber(var_6_1)
	elseif var_6_0 == "object_classroom_money" then
		arg_6_0.objectClassRoomMoney = tonumber(var_6_1)
	elseif var_6_0 == "object_classroom_log_limit" then
		arg_6_0.objectClassRoomLogLimit = tonumber(var_6_1)
	elseif var_6_0 == "supremacy_action_point_upper" then
		arg_6_0.academyApUpper = tonumber(var_6_1)
	elseif var_6_0 == "supremacy_summon_point_upper" then
		arg_6_0.academySpUpper = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_boss_location" then
		arg_6_0.summerQuizBossLocation = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "summer_quiz_boss_pos" then
		arg_6_0.summerQuizBossPos = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "school_memory_maze_col" then
		arg_6_0.memoriesOfSchoolMazeCol = tonumber(var_6_1)
	elseif var_6_0 == "school_memory_maze_row" then
		arg_6_0.memoriesOfSchoolMazeRow = tonumber(var_6_1)
	elseif var_6_0 == "school_memory_maze_key_big" then
		arg_6_0.memoriesOfSchoolKeyBig = tonumber(var_6_1)
	elseif var_6_0 == "school_memory_maze_key_small" then
		arg_6_0.memoriesOfSchoolKeySmall = tonumber(var_6_1)
	elseif var_6_0 == "school_memory_maze_max_floor" then
		arg_6_0.memoriesOfSchoolMaxFloor = tonumber(var_6_1)
	elseif var_6_0 == "school_memory_maze_pass_box" then
		arg_6_0.memoriesOfSchoolPassBox = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "school_memory_maze_girls" then
		arg_6_0.memoriesOfSchoolMazeGirls = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "paradise_team_limit" then
		arg_6_0.paradiseTeamLimit = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_buy_cost" then
		arg_6_0.summerGoldFishBuyCost = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_buy_num" then
		arg_6_0.summerGoldFishBuyNum = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_recharge_cost" then
		arg_6_0.summerGoldFishRechargeCost = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_recharge_num" then
		arg_6_0.summerGoldFishRechargeNum = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_super_net_pt" then
		arg_6_0.summerGoldFishSuperNetPt = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_net_item" then
		arg_6_0.summerGoldFishNetItem = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_super_net_item" then
		arg_6_0.summerGoldFishSuperNetItem = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_top_reward" then
		arg_6_0.summerGoldFishTopReward = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_rate_max" then
		arg_6_0.summerGoldFishRateMax = tonumber(var_6_1)
	elseif var_6_0 == "summer_goldfish_rank_num" then
		arg_6_0.summerGoldFishRankNum = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_start_time" then
		arg_6_0.summerQuizStartTime = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_end_time" then
		arg_6_0.summerQuizEndTime = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_question_num" then
		arg_6_0.summerQuizQuestionNum = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_boss_battle" then
		arg_6_0.summerQuizBossBattle = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "summer_quiz_revive_cost" then
		arg_6_0.summerQuizReviveCost = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_revive_time" then
		arg_6_0.summerQuizReviveTime = tonumber(var_6_1)
	elseif var_6_0 == "summer_quiz_announce" then
		arg_6_0.summerQuizAnnounce = tonumber(var_6_1)
	elseif var_6_0 == "indiegogo_query_num" then
		arg_6_0.indiegogoQueryNum = tonumber(var_6_1)
	elseif var_6_0 == "auction_end_time" then
		arg_6_0.auctionEndTime = tonumber(var_6_1)
	elseif var_6_0 == "auction_start_time" then
		arg_6_0.auctionStartTime = tonumber(var_6_1)
	elseif var_6_0 == "vote_list_query_num" then
		arg_6_0.voteListQueryNum = tonumber(var_6_1)
	elseif var_6_0 == "vote_ticket_cost" then
		arg_6_0.voteTicketCost = tonumber(var_6_1)
	elseif var_6_0 == "object_box_book_numb" then
		arg_6_0.objectBoxBookNumb = tonumber(var_6_1)
	elseif var_6_0 == "object_box_book1" then
		arg_6_0.objectBoxBook1 = tonumber(var_6_1)
	elseif var_6_0 == "object_box_book2" then
		arg_6_0.objectBoxBook2 = tonumber(var_6_1)
	elseif var_6_0 == "object_box_books" then
		arg_6_0.objectBoxBooks = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_lottery_lucky_gift" then
		arg_6_0.activityLotteryLuckyGift = tonumber(var_6_1)
	elseif var_6_0 == "anni2_partner_refresh_cost" then
		arg_6_0.twoYearsRefreshCost = tonumber(var_6_1)
	elseif var_6_0 == "anni2_partner_refresh_time" then
		arg_6_0.twoYearsRefreshTime = tonumber(var_6_1)
	elseif var_6_0 == "anni2_present_item" then
		arg_6_0.twoYearspresentItem = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "anni2_present_limit_num" then
		arg_6_0.twoYearsPresentLimitNum = tonumber(var_6_1)
	elseif var_6_0 == "anni2_reward_max_lev" then
		arg_6_0.twoYearsRewardMaxLev = tonumber(var_6_1)
	elseif var_6_0 == "creats_ticket_get" then
		arg_6_0.creatsTicketGet = tonumber(var_6_1)
	elseif var_6_0 == "creats_ticket_max" then
		arg_6_0.creatsTicketMax = tonumber(var_6_1)
	elseif var_6_0 == "creats_team_limit" then
		arg_6_0.creatsTeamLimit = tonumber(var_6_1)
	elseif var_6_0 == "creats_team_people_limit" then
		arg_6_0.creatsTeamPeopleLimit = tonumber(var_6_1)
	elseif var_6_0 == "creats_campaign_duration" then
		arg_6_0.creatsCampaignDuration = tonumber(var_6_1)
	elseif var_6_0 == "creats_rescue_time" then
		arg_6_0.creatsRescueTime = tonumber(var_6_1)
	elseif var_6_0 == "creats_dispatch_hero_limit" then
		arg_6_0.creatsDispatchHeroLimit = tonumber(var_6_1)
	elseif var_6_0 == "creats_survival_param" then
		arg_6_0.creatsSurvivalParam = tonumber(var_6_1)
	elseif var_6_0 == "creats_dispatch_param" then
		arg_6_0.creatsDispatchParam = tonumber(var_6_1)
	elseif var_6_0 == "creats_time_param" then
		arg_6_0.creatsTimeParam = tonumber(var_6_1)
	elseif var_6_0 == "creats_timeout1" then
		arg_6_0.creatsTimeOut1 = tonumber(var_6_1)
	elseif var_6_0 == "creats_timeout2" then
		arg_6_0.creatsTimeOut2 = tonumber(var_6_1)
	elseif var_6_0 == "space_trip_replace_item" then
		arg_6_0.spaceShopItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_lianyi_materials" then
		arg_6_0.newTermMaterials = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_lianyi_charm" then
		arg_6_0.newTermCharmBonusIcon = tonumber(var_6_1)
	elseif var_6_0 == "activity_lianyi_connection" then
		arg_6_0.newTermConnectionBonusIcon = tonumber(var_6_1)
	elseif var_6_0 == "activity_lianyi_anime" then
		arg_6_0.newTermAnime = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_lianyi_color" then
		arg_6_0.newTermTextColor = var_0_1.luaStringSplit(var_6_1, "|")
	elseif var_6_0 == "amour_limit" then
		arg_6_0.amourLimit = tonumber(var_6_1)
	elseif var_6_0 == "arena_mode_enter_rank_req" then
		arg_6_0.arenaModeRank = tonumber(var_6_1)
	elseif var_6_0 == "arena_mode_enter_battle_req" then
		arg_6_0.arenaModeTimes = tonumber(var_6_1)
	elseif var_6_0 == "adventure_paradise_gift_single" then
		arg_6_0.adventureIllusionSingleGift = tonumber(var_6_1)
	elseif var_6_0 == "adventure_paradise_boss" then
		arg_6_0.adventureIllusionBoss = tonumber(var_6_1)
	elseif var_6_0 == "adventure_level_limit" then
		arg_6_0.adventureDefenseLevelLimit = tonumber(var_6_1)
	elseif var_6_0 == "adventure_monster_challenge_times_limit" then
		arg_6_0.adventureDefenseChallengeTimesLimit = tonumber(var_6_1)
	elseif var_6_0 == "adventure_challenge_choose_time_limit" then
		arg_6_0.adventureDefenseSelectTeamTimeLimit = tonumber(var_6_1)
	elseif var_6_0 == "adventure_paradise_gift" then
		arg_6_0.adventureIllusionCoopGift = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_revive_item" then
		arg_6_0.campWarReviveItem = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_boss_honor_param" then
		arg_6_0.campWarBossHonorParam = tonumber(var_6_1)
	elseif var_6_0 == "library_gift_right" then
		arg_6_0.libraryGiftRight = tonumber(var_6_1)
	elseif var_6_0 == "library_gift_wrong" then
		arg_6_0.libraryGiftWrong = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_hero_honor" then
		arg_6_0.campWarHeroHonor = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_num_difference" then
		arg_6_0.campWarNumDifference = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_battle_para1" then
		arg_6_0.campWarBattlePara1 = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_battle_para2" then
		arg_6_0.campWarBattlePara2 = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_battle_time" then
		arg_6_0.campWarBattleTime = tonumber(var_6_1)
	elseif var_6_0 == "max_challenge_chapter" then
		arg_6_0.maxChallengeChapter = tonumber(var_6_1)
	elseif var_6_0 == "max_challenge_distance" then
		arg_6_0.maxChallengeDistance = tonumber(var_6_1)
	elseif var_6_0 == "activity_consume_gift_once" then
		arg_6_0.activityConsumeGiftOnce = tonumber(var_6_1)
	elseif var_6_0 == "activity_consume_gift_five" then
		arg_6_0.activityConsumeGiftFive = tonumber(var_6_1)
	elseif var_6_0 == "activity_charge_gift_once" then
		arg_6_0.activityChargeGiftOnce = tonumber(var_6_1)
	elseif var_6_0 == "legend_promote_cool_time" then
		arg_6_0.peakPromoCoolTime = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_recover_energy" then
		arg_6_0.zhugeRecoverEnergy = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_recover_energy_item" then
		arg_6_0.zhugeRecoverEnergyItem = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_recover_energy_cost" then
		arg_6_0.zhugeRecoverEnergyCost = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_box_part_item" then
		arg_6_0.zhugeBoxPartItem = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_max_energy" then
		arg_6_0.zhugeMaxEnergy = tonumber(var_6_1)
	elseif var_6_0 == "activity_consume_gift_ticket" then
		arg_6_0.activityConsumeGiftTicket = tonumber(var_6_1)
	elseif var_6_0 == "activity_square_turntable2_ticket" then
		arg_6_0.activitySquareTurntable2Ticket = tonumber(var_6_1)
	elseif var_6_0 == "glue_buy_limit" then
		arg_6_0.glueBuyLimit = tonumber(var_6_1)
	elseif var_6_0 == "glue_buy_number" then
		arg_6_0.glueBuyNumber = tonumber(var_6_1)
	elseif var_6_0 == "dorm_girl_cover_size" then
		arg_6_0.dormGirlCoverSize = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "dorm_exp_base" then
		arg_6_0.dormExpBase = tonumber(var_6_1)
	elseif var_6_0 == "dorm_exp_ratio" then
		arg_6_0.dormExpRatio = tonumber(var_6_1)
	elseif var_6_0 == "dorm_girls_cool_time" then
		arg_6_0.dormGirlsCoolTime = tonumber(var_6_1)
	elseif var_6_0 == "dorm_exp_limit" then
		arg_6_0.dormExpLimit = tonumber(var_6_1)
	elseif var_6_0 == "activity_week2_present_partner" then
		arg_6_0.activityWeek2PresentPartner = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "team_power_limit" then
		arg_6_0.teamPowerLimit = tonumber(var_6_1)
	elseif var_6_0 == "arena_gift_time1" then
		arg_6_0.arenaTime1 = tonumber(var_6_1)
	elseif var_6_0 == "arena_gift_time2" then
		arg_6_0.arenaTime2 = tonumber(var_6_1)
	elseif var_6_0 == "skin_warmup_cost" then
		arg_6_0.skinWarmUpCost = tonumber(var_6_1)
	elseif var_6_0 == "dorm_girls_speed_time" then
		arg_6_0.dormGirlsSpeedTime = tonumber(var_6_1)
	elseif var_6_0 == "dorm_girls_speed" then
		arg_6_0.dormGirlsSpeed = tonumber(var_6_1)
	elseif var_6_0 == "activity_snowball_item" then
		arg_6_0.snowBallItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_snowball_super_item" then
		arg_6_0.snowBallSuperItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_snowball_buy_cost" then
		arg_6_0.snowBallBuyCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_snowball_buy_num" then
		arg_6_0.snowBallBuyNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_snowball_recharge_cost" then
		arg_6_0.snowBallChargeCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_snowball_model_init_num" then
		arg_6_0.snowBallModelInitNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_snowball_rank_reward_item" then
		arg_6_0.snowBallRewardItem = tonumber(var_6_1)
	elseif var_6_0 == "snowman_challenge_item" then
		arg_6_0.snowmanChallengeItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_charge_gift_times" then
		arg_6_0.activityChargeGiftTimes = tonumber(var_6_1)
	elseif var_6_0 == "snowman_gacha_recycle_num" then
		arg_6_0.snowGachaExtraNum = tonumber(var_6_1)
	elseif var_6_0 == "moegirls_activity_gears" then
		arg_6_0.moegirlsActivityGears = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_gamble_up_limit" then
		arg_6_0.illusionBetUpLimit = tonumber(var_6_1)
	elseif var_6_0 == "activity_gamble_down_limit" then
		arg_6_0.illusionBetDownLimit = tonumber(var_6_1)
	elseif var_6_0 == "day_start_time" then
		arg_6_0.dayStartTime = tonumber(var_6_1)
	elseif var_6_0 == "moegirls_activity_cost" then
		arg_6_0.moegirlsActivityCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_mifuren_show" then
		arg_6_0.mifurenShowItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_level_charge_discount_time" then
		arg_6_0.levelChargeDiscountTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_sticker_stick_cost" then
		arg_6_0.activityStickerStickCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_sticker_ban_count" then
		arg_6_0.activityStickerBanCount = tonumber(var_6_1)
	elseif var_6_0 == "activity_sticker_item" then
		arg_6_0.activityStickerItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_sticker_reset_cost" then
		arg_6_0.activityStickerResetCost = tonumber(var_6_1)
	elseif var_6_0 == "creats_sweep_reward_rate" then
		arg_6_0.creatsSweepRewardRate = tonumber(var_6_1)
	elseif var_6_0 == "gacha_max_gift_time" then
		arg_6_0.activityGachaExtraTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_lottery_interval" then
		arg_6_0.activityLotteryInterval = tonumber(var_6_1)
	elseif var_6_0 == "activity_lottery_item" then
		arg_6_0.activityLotteryItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_girl_training_partner" then
		arg_6_0.activityGirlTrainingPartner = tonumber(var_6_1)
	elseif var_6_0 == "activity_redpacket_max_num" then
		arg_6_0.activityRedPacketMaxNum = tonumber(var_6_1)
	elseif var_6_0 == "select_equip_gift_ids" then
		arg_6_0.selectEquipGiftIDs = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "valentine_present_item" then
		arg_6_0.valentinePresentItems = {}
		arg_6_0.valentinePresentItems2 = {}

		local var_6_5 = var_0_1.luaStringSplit(var_6_1, "|")

		for iter_6_1, iter_6_2 in pairs(var_6_5) do
			table.insert(arg_6_0.valentinePresentItems, var_0_1.splitToNumber(iter_6_2, ",")[1])
			table.insert(arg_6_0.valentinePresentItems2, var_0_1.splitToNumber(iter_6_2, ",")[2])
		end
	elseif var_6_0 == "activity_sticker_cost" then
		arg_6_0.activityStickerBuyCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_sticker_get" then
		arg_6_0.activityStickerBuyNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_lottery_consume_item" then
		arg_6_0.activityLotteryConsumeItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_lottery_consume_price" then
		arg_6_0.activityLotteryConsumePrice = tonumber(var_6_1)
	elseif var_6_0 == "chest_us_price" then
		arg_6_0.chestUSPrice = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "chest_us_max_num" then
		arg_6_0.chestUSMaxNum = tonumber(var_6_1)
	elseif var_6_0 == "chat_barrage_item" then
		arg_6_0.chatBarrageItem = tonumber(var_6_1)
	elseif var_6_0 == "chat_barrage_length" then
		arg_6_0.chatBarrageLength = tonumber(var_6_1)
	elseif var_6_0 == "valentine2_present_item" then
		arg_6_0.valentine2PresentItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_server_candle_total" then
		arg_6_0.activityServerCandleTotal = tonumber(var_6_1)
	elseif var_6_0 == "activity_server_candle_charge" then
		arg_6_0.activityServerCandleCharge = tonumber(var_6_1)
	elseif var_6_0 == "activity_server_candle_cost" then
		arg_6_0.activityServerCandleCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_server_candle_sweep_limit" then
		arg_6_0.activityServerCandleSweepLimit = tonumber(var_6_1)
	elseif var_6_0 == "activity_server_candle_box_num" then
		arg_6_0.activityServerCandleBoxNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_server_candle_item" then
		arg_6_0.activityServerCandleItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_party_extra_num" then
		arg_6_0.activityPartyExtraNum = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_party_extra_gift" then
		arg_6_0.activityPartyExtraGift = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_dragonboat_charge" then
		arg_6_0.activityDragonBoatCharge = tonumber(var_6_1)
	elseif var_6_0 == "activity_dragonboat_ticket" then
		arg_6_0.activityDragonBoatTicket = tonumber(var_6_1)
	elseif var_6_0 == "activity_dragonboat_reward" then
		arg_6_0.activityDragonBoatReward = tonumber(var_6_1)
	elseif var_6_0 == "activity_garden_charge " then
		arg_6_0.activityGardenCharge = tonumber(var_6_1)
	elseif var_6_0 == "activity_garden_land_default" then
		arg_6_0.activityGardenLandDefault = tonumber(var_6_1)
	elseif var_6_0 == "activity_garden_land_max" then
		arg_6_0.activityGardenLandMax = tonumber(var_6_1)
	elseif var_6_0 == "activity_garden_land_cost" then
		arg_6_0.activityGardenLandCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_garden_steal_max" then
		arg_6_0.activityGardenStealMax = tonumber(var_6_1)
	elseif var_6_0 == "activity_garden_steal_cost" then
		arg_6_0.activityGardenStealCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_garden_fertilize_item" then
		arg_6_0.activityGardenFertilizeItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_garden_fertilize_time" then
		arg_6_0.activityGardenFertilizeTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_open_id" then
		arg_6_0.activity_open_id = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "zhugeliang_id" then
		arg_6_0.zhuGeLiangID = tonumber(var_6_1)
	elseif var_6_0 == "activity_card_match_cost" then
		arg_6_0.activityCardMatchCost = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_card_match_reset_cost" then
		arg_6_0.activitCardMatchResetCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_google_ad_charge_id" then
		arg_6_0.activityGoogleAdChargeId = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "lvlingqi_partner_id" then
		arg_6_0.lvlingqiTableID = tonumber(var_6_1)
	elseif var_6_0 == "stone_ticket_low" then
		arg_6_0.stoneTicketLow = tonumber(var_6_1)
	elseif var_6_0 == "stone_ticket_high" then
		arg_6_0.stoneTicketHigh = tonumber(var_6_1)
	elseif var_6_0 == "zhuge_box_switch_avatar" then
		arg_6_0.zhugeBoxSwitchAvatar = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_anniversary_wish_coin" then
		arg_6_0.activityAnniversaryWishCoin = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_wish_time" then
		arg_6_0.activityAnniversaryWishTime = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_anniversary_wish_word_limit" then
		arg_6_0.activityAnniversaryWishWordLimit = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_diglett_cost" then
		arg_6_0.activityAnniversaryDiglettCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_diglett_lost_times" then
		arg_6_0.activityAnniversaryDiglettLostTimes = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_diglett_challenge_times" then
		arg_6_0.activityAnniversaryDiglettChallengeTimes = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_boss_start_time" then
		arg_6_0.thirdAnniversaryBossStartTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_boss_end_time" then
		arg_6_0.thirdAnniversaryBossEndTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_boss_stage" then
		arg_6_0.thirdAnniversaryBossStage = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_anniversary_boss_hp" then
		arg_6_0.thirdAnniversaryBossHp = tonumber(var_6_1)
	elseif var_6_0 == "activity_anniversary_boss_ticket" then
		arg_6_0.thirdAnniversaryBossTicket = tonumber(var_6_1)
	elseif var_6_0 == "activity_snowbattle_banlist" then
		arg_6_0.activitySnowbattleBanlist = tonumber(var_6_1)
	elseif var_6_0 == "activity_consume_pool_price" then
		arg_6_0.activityConsumePoolPrice = tonumber(var_6_1)
	elseif var_6_0 == "activity_consume_pool_price_10" then
		arg_6_0.activityConsumePoolPrice10 = tonumber(var_6_1)
	elseif var_6_0 == "conquer_school_max_loop" then
		arg_6_0.conquerSchoolMaxLoop = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_dice_item" then
		arg_6_0.activityRichDiceItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_dice_charge" then
		arg_6_0.activityRichDiceCharge = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_boutique_cost" then
		arg_6_0.activityRichBoutiqueCost = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_rich_boutique_gain" then
		arg_6_0.activityRichBoutiqueGain = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_rich_bank_cost" then
		arg_6_0.activityRichBankCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_bank_gain" then
		arg_6_0.activityRichBankGain = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_remote_dice_item" then
		arg_6_0.activityRichRemoteDiceItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_vip_card_item" then
		arg_6_0.activityRichVipCardItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_passerby_card_item" then
		arg_6_0.activityRichPasserByCardItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_water_pipe" then
		arg_6_0.activityRichWaterPipe = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_water_pipe_reward" then
		arg_6_0.activityRichWaterPipeReward = tonumber(var_6_1)
	elseif var_6_0 == "activity_chest_us_ticket" then
		arg_6_0.activityChestUSTicket = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_battle_reward" then
		arg_6_0.activityRichBattleReward = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_battle_reward_time" then
		arg_6_0.activityRichBattleRewardTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_wheel_reward_time" then
		arg_6_0.activityRichWheeelRewardTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_wheel_reward" then
		arg_6_0.activityRichWheelReward = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_hero" then
		arg_6_0.activityRichHero = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_page" then
		arg_6_0.activityRichPage = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_girls_speed_time" then
		arg_6_0.activityRichGirlsSpeedTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_decode_credits_price" then
		arg_6_0.activityDecodeCreditsPrice = tonumber(var_6_1)
	elseif var_6_0 == "activity_decode_credits_to_num" then
		arg_6_0.acitivityDecodeCreditsToNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_decode_num" then
		arg_6_0.activiityDecodeNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_decode_num1" then
		arg_6_0.acitvityDecodeNum1 = tonumber(var_6_1)
	elseif var_6_0 == "activity_decode_num36" then
		arg_6_0.activityDecodeNum36 = tonumber(var_6_1)
	elseif var_6_0 == "activity_decode_pandent" then
		arg_6_0.activityDecodePandent = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "activity_decode_mission_daily_num" then
		arg_6_0.activityDecodeMissionDailyNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_page" then
		arg_6_0.activityRichPage = tonumber(var_6_1)
	elseif var_6_0 == "house_key_blue" then
		arg_6_0.houseKeyBlue = tonumber(var_6_1)
	elseif var_6_0 == "house_key_green" then
		arg_6_0.houseKeyGreen = tonumber(var_6_1)
	elseif var_6_0 == "skip_expand_cost" then
		arg_6_0.skipExpandCost = tonumber(var_6_1)
	elseif var_6_0 == "skip_expand_times" then
		arg_6_0.skipExpandTimes = tonumber(var_6_1)
	elseif var_6_0 == "expand_cost_item" then
		arg_6_0.expandCostItem = tonumber(var_6_1)
	elseif var_6_0 == "expand_get_way" then
		arg_6_0.expandGetWay = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "house_key_blue_id" then
		arg_6_0.houseKeyBlueId = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "house_key_green_id" then
		arg_6_0.housekeyGreenId = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "homepage_shake_duration" then
		arg_6_0.homepageShakeDuration = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "homepage_shake_off_position1" then
		arg_6_0.homepageShakeOffPosition1 = tonumber(var_6_1)
	elseif var_6_0 == "activity_dongyun_souvenir_day" then
		arg_6_0.activityDongYunSouvenirDay = tonumber(var_6_1)
	elseif var_6_0 == "partner_table_init_id" then
		arg_6_0.partnerTableInitID = tonumber(var_6_1)
	elseif var_6_0 == "super_partner_init_id" then
		arg_6_0.superPartnerInitID = tonumber(var_6_1)
	elseif var_6_0 == "taitan_stone_item_id" then
		arg_6_0.taitanItemID = tonumber(var_6_1)
	elseif var_6_0 == "taitan_exchange_hero" then
		arg_6_0.taitanExchangeHero = tonumber(var_6_1)
	elseif var_6_0 == "taitan_exchange_super_hero" then
		arg_6_0.taitanExchangeSuperHero = tonumber(var_6_1)
	elseif var_6_0 == "taitan_exchange_sx" then
		arg_6_0.taitanExchangeSXHero = tonumber(var_6_1)
	elseif var_6_0 == "dormitory_expression" then
		arg_6_0.dormitoryExpression = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "award_show_time" then
		arg_6_0.awardShowTime = tonumber(var_6_1)
	elseif var_6_0 == "homepage_float_time" then
		arg_6_0.homepageFloatTime = tonumber(var_6_1)
	elseif var_6_0 == "homepage_float_pixel" then
		arg_6_0.homepageFloatPixel = tonumber(var_6_1)
	elseif var_6_0 == "single_doggift_model" then
		arg_6_0.singleDogGiftModel = tonumber(var_6_1)
	elseif var_6_0 == "activity_rich_dice_cost" then
		arg_6_0.activityRichDiceCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_slot_machine_item_id" then
		arg_6_0.activityChocolateSlotMachineItemCoin = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_campaign_sweep_item" then
		arg_6_0.activityChocolateCampaignSweepItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_item" then
		arg_6_0.activityChocolateFruitItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_item" then
		arg_6_0.activityChocolateItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_slot_machine_diamond_cost" then
		arg_6_0.activityChocolateSlotMachineDiamondCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_slot_machine_double_cost" then
		arg_6_0.activityChocolateSlotMachineDoubleCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_pool_num" then
		arg_6_0.activityChocolatePoolNum = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_time" then
		arg_6_0.activityChocolateFruitTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_boom" then
		arg_6_0.activityChocolateFruitBoom = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_item" then
		arg_6_0.activityChocolateItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_diamond_cost" then
		arg_6_0.activityChocolateFruitDiamondCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_limitless_times" then
		arg_6_0.activityChocolateLimitLessTimes = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_limitless_item" then
		arg_6_0.activityChocolateLimitLessItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_pool_reset_item" then
		arg_6_0.activityChocolatePoolResetItem = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_double_cost" then
		arg_6_0.activityChocolateFritDoubleCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_double_times" then
		arg_6_0.activityChocolateFruitDoubleTimes = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_title" then
		arg_6_0.activityChocolateFruitTitle = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_mask" then
		arg_6_0.activityChocolateFruitMask = var_0_1.splitToNumber(var_6_1, ",")
	elseif var_6_0 == "activity_chocolate_fruit_gravity" then
		arg_6_0.activityChocolatefruitGravity = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_fruit_run_min" then
		arg_6_0.activityChocolatefruitRunMin = tonumber(var_6_1)
	elseif var_6_0 == "activity_chocolate_pool_cost_nums" then
		arg_6_0.activityChocolatePoolCostNums = tonumber(var_6_1)
	elseif var_6_0 == "activity_recall_show_level" then
		arg_6_0.activityRecallShowLevel = tonumber(var_6_1)
	elseif var_6_0 == "activity_lvbu_fengxian_add_rate" then
		arg_6_0.activityLvbuFengxianAddRate = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "fengxian_table_id" then
		arg_6_0.fengxianTableId = tonumber(var_6_1)
	elseif var_6_0 == "story_card_distance" then
		arg_6_0.storyCardDistance = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_extra_skin" then
		arg_6_0.warCampSkinItems = var_0_1.splitToNumber(var_6_1, "|")
	elseif var_6_0 == "beach_unlock_item" then
		arg_6_0.beachUnlockItem = tonumber(var_6_1)
	elseif var_6_0 == "beach_exchange_rate" then
		arg_6_0.beachExchangeRate = tonumber(var_6_1)
	elseif var_6_0 == "beach_gift_charge_id" then
		arg_6_0.beachGiftChagreID = tonumber(var_6_1)
	elseif var_6_0 == "beach_max_level" then
		arg_6_0.beachMaxLevel = tonumber(var_6_1)
	elseif var_6_0 == "camp_war_extra_skin_ratio" then
		arg_6_0.warCampSkinItemRate = tonumber(var_6_1)
	elseif var_6_0 == "activity_anni_4th_gold_challenge_times" then
		arg_6_0.activityAnni4thGoldChallengeTimes = tonumber(var_6_1)
	elseif var_6_0 == "activity_anni_4th_gold_diamond_cost" then
		arg_6_0.activityAnni4thGoldDiamondCost = tonumber(var_6_1)
	elseif var_6_0 == "activity_anni_4th_gold_time" then
		arg_6_0.activityAnni4thGoldTime = tonumber(var_6_1)
	elseif var_6_0 == "activity_anni_4th_gold_reset_item" then
		arg_6_0.activityAnni4thGoldResetItem = tonumber(var_6_1)
	elseif var_6_0 == "monthly_card_time2" then
		arg_6_0.monthCardTime2 = tonumber(var_6_1)
	elseif var_6_0 == "season_privilege_card" then
		arg_6_0.seasonPrivilegeCard = tonumber(var_6_1)
	elseif var_6_0 == "halfyear_privilege_card" then
		arg_6_0.halfyearPrivilegeCard = tonumber(var_6_1)
	elseif var_6_0 == "monthly_privilege_card" then
		arg_6_0.monthlyPrivilegeCardDiscount = tonumber(var_6_1)
	else
		local var_6_6 = tonumber(arg_6_1.parse) or 1

		if var_0_3[var_6_6] then
			local var_6_7 = var_0_3[var_6_6]

			var_0_2[var_6_7](arg_6_0, var_6_1, var_6_0)
		end
	end
end

function var_0_2.getValue(arg_7_0, arg_7_1)
	return arg_7_0.dict_[arg_7_1]
end

return var_0_2
