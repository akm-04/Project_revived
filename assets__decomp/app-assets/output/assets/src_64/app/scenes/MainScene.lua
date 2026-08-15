local var_0_0 = import(cc.PACKAGE_NAME .. ".scheduler")
local var_0_1 = import("app.common.AssetLoader")
local var_0_2 = import("app.common.SilenceDownloader")
local var_0_3 = class("MainScene", import("app.common.ui.BaseScene"))
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = "main_scene_bottom"
local var_0_6 = "main_scene_left"
local var_0_7 = "main_scene_middle"
local var_0_8 = "main_scene_top"
local var_0_9 = 25
local var_0_10 = {
	"hero_list",
	"hero_list",
	"summon",
	"pet_collect",
	"wash_hero",
	"fumo"
}
local var_0_11 = {
	"pic_notice",
	"sign_in",
	"walfare_activities",
	"seven_day_login",
	"gift_push"
}

function var_0_3.ctor(arg_1_0)
	arg_1_0.super.ctor(arg_1_0)

	arg_1_0.touchLayer_ = display.newColorLayer(cc.c4b(255, 255, 255, 255)):addTo(arg_1_0)

	arg_1_0.touchLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(arg_1_0, arg_1_0.onTouch_))
	arg_1_0:setupBackground()

	arg_1_0.mainSceneAnimation = true
	arg_1_0.funcGuideIds = {}

	xyd.EventDispatcher.get():addEventListener(xyd.event.BG_EFFECT_VISIBLE, function(arg_2_0)
		if tolua.isnull(arg_1_0) then
			return
		end

		if arg_2_0.show == true then
			arg_1_0:showBackgroundEffects()
		elseif arg_2_0.show == false then
			arg_1_0:hideBackgroundEffects()
		end
	end)
	xyd.EventDispatcher.get():addEventListener(xyd.event.MAIN_SCENE_ACTION_START, function(arg_3_0)
		if tolua.isnull(arg_1_0) then
			return
		end

		arg_1_0.mainSceneAnimation = true
	end)
	xyd.EventDispatcher.get():addEventListener(xyd.event.MAIN_SCENE_ACTION_END, function(arg_4_0)
		if tolua.isnull(arg_1_0) then
			return
		end

		arg_1_0.mainSceneAnimation = false

		for iter_4_0 = 1, #arg_1_0.funcGuideIds do
			arg_1_0:playFuncGuide(arg_1_0.funcGuideIds[iter_4_0])
		end

		arg_1_0.funcGuideIds = {}
	end)
end

function var_0_3.setupBackground(arg_5_0)
	local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	local var_5_1 = var_5_0.bgMain
	local var_5_2 = xyd.tables.libraryBG
	local var_5_3 = var_5_2:getIDs()

	if arg_5_0.sp1 then
		arg_5_0:removeChild(arg_5_0.sp1, true)
	end

	for iter_5_0 = 1, #var_5_3 do
		if var_5_2:getLimit(var_5_3[iter_5_0]) == 2 then
			local var_5_4 = var_5_2:getTime(var_5_3[iter_5_0])

			if var_5_4 > xyd.db.settings:getBGCanLoadTime() then
				xyd.db.settings:setBGCanLoadTime(var_5_4)
				var_5_0:setLibraryBG({
					_type = 1,
					bg_id = var_5_3[iter_5_0]
				}, function()
					return
				end)

				var_5_1 = var_5_3[iter_5_0]
				var_5_0.bgMain = var_5_3[iter_5_0]
			end

			break
		end
	end

	arg_5_0.sp1 = xyd.SpriteLoader.new(var_5_2:getBG(var_5_1), nil, nil, xyd.DefaultImageType.BG_MAIN)

	arg_5_0.sp1:setAnchorPoint(0, 0)
	arg_5_0.sp1:addTo(arg_5_0)
	arg_5_0:showBackgroundEffects()
end

function var_0_3.showBackgroundEffects(arg_7_0)
	local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY).bgMain
	local var_7_1 = xyd.tables.libraryBG:getEffect(var_7_0)

	if arg_7_0.bgEffect and not tolua.isnull(arg_7_0.bgEffect) then
		arg_7_0.bgEffect:removeSelf()
	end

	if var_7_1 == 1 then
		local var_7_2 = "skeletons/ui_effect/common_effect_sunshine/common_effect_sunshine"
		local var_7_3 = var_7_2 .. ".json"
		local var_7_4 = var_7_2 .. ".atlas"

		arg_7_0.bgEffect = var_0_4.new(var_7_3, var_7_4, 1)

		arg_7_0.bgEffect:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)
		arg_7_0.bgEffect:addTo(arg_7_0)
		arg_7_0.bgEffect:play(function()
			return
		end, true)
		arg_7_0.bgEffect:setVisible(true)
	elseif var_7_1 == 2 then
		arg_7_0.bgEffect = cc.ParticleSystemQuad:create("skeletons/ui_effect/common_effect_snow/xuehua_yuan_particle_texture.plist")

		arg_7_0.bgEffect:setPosition(cc.p(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))
		arg_7_0.bgEffect:addTo(arg_7_0, 20001)
		arg_7_0.bgEffect:setVisible(true)
	elseif var_7_1 == 3 then
		arg_7_0.bgEffect = cc.ParticleSystemQuad:create("skeletons/ui_effect/common_effect_snow/xueqian.plist")

		arg_7_0.bgEffect:setPosition(cc.p(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))
		arg_7_0.bgEffect:addTo(arg_7_0, 20001)
		arg_7_0.bgEffect:setVisible(true)
	end
end

function var_0_3.hideBackgroundEffects(arg_9_0)
	if arg_9_0.bgEffect and not tolua.isnull(arg_9_0.bgEffect) then
		arg_9_0.bgEffect:setVisible(false)
	end

	if arg_9_0.snowEffect then
		arg_9_0.snowEffect:setVisible(false)
	end
end

function var_0_3.recallStoryTalk(arg_10_0)
	if xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):isPlayRecallTalk() then
		xyd.WindowManager.get():openWindow("recall_story_talk")
	end
end

function var_0_3.onEnterTransitionFinish(arg_11_0)
	arg_11_0.super.onEnterTransitionFinish(arg_11_0)

	local var_11_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)

	if var_11_0.retainHistory then
		arg_11_0.windowHistory = var_11_0.retainHistory
		var_11_0.retainHistory = nil
	end

	xyd.WindowManager.get():openWindow(var_0_6)
	xyd.WindowManager.get():openWindow(var_0_7)
	xyd.WindowManager.get():openWindow(var_0_5)
	xyd.WindowManager.get():openWindow("main_scene_touch")
	xyd.WindowManager.get():openWindow(var_0_8)

	if xyd.isArenaBattle then
		xyd.WindowManager.get():closeWindow(var_0_8)
		xyd.WindowManager.get():closeWindow(var_0_6)
		xyd.WindowManager.get():closeWindow(var_0_7)
		xyd.WindowManager.get():closeWindow(var_0_5)
		xyd.WindowManager.get():closeWindow("main_scene_touch")
	end

	arg_11_0:recallStoryTalk()
	arg_11_0:recallStoryTalk()
	arg_11_0:playStory()

	if xyd.battleBackEnterWindow then
		local var_11_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		if var_0_10[xyd.battleBackEnterWindow] == "summon" then
			var_11_1:loadSummonInfo(nil, function()
				xyd.WindowManager.get():openWindow("summon")
			end, true)
		else
			xyd.WindowManager.get():openWindow(var_0_10[xyd.battleBackEnterWindow])
		end

		xyd.WindowManager.get():releaseRetainedHistory()

		xyd.battleBackEnterWindow = nil
	elseif arg_11_0.windowHistory and arg_11_0.restoreParams then
		local var_11_2 = arg_11_0.restoreParams.window

		if var_11_2 then
			for iter_11_0 = 1, #arg_11_0.windowHistory do
				local var_11_3 = arg_11_0.windowHistory[iter_11_0]

				if not var_11_3.params then
					var_11_3.params = {}
				end

				local var_11_4 = arg_11_0.restoreParams.status

				if var_11_4 and next(var_11_4) then
					for iter_11_1, iter_11_2 in pairs(var_11_4) do
						var_11_3.params[iter_11_1] = iter_11_2
					end
				end

				if var_11_3.name == "arena" then
					local var_11_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

					xyd.Backend.get():request(xyd.mid.LOAD_ARENA_FIGHT_RECORDS, {}, function(arg_13_0, arg_13_1)
						if arg_13_0 == xyd.error.OK then
							local var_13_0 = arg_13_1.records
							local var_13_1 = {}

							for iter_13_0, iter_13_1 in ipairs(var_13_0) do
								if iter_13_1.report_key then
									table.insert(var_13_1, iter_13_1.report_key)
								end
							end

							if var_13_1 and next(var_13_1) then
								xyd.db.arenaReportKeys:deleteAllReportKeys(var_11_5.playerID)

								for iter_13_2, iter_13_3 in ipairs(var_13_1) do
									xyd.db.arenaReportKeys:setArenaReportKeys(var_11_5.playerID, iter_13_3)
								end
							end
						end
					end)

					local var_11_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)

					oldBestRank = var_11_6.oldBestRank

					var_11_6:loadArenaInfo(function(arg_14_0, arg_14_1)
						if arg_14_0 == xyd.error.OK and xyd.WindowManager.get():openWindow(var_11_3.name) then
							local var_14_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
							local var_14_1 = 10

							if var_14_0.fbShareOpen > 0 and var_14_1 < oldBestRank and var_14_1 >= arg_14_1.best_rank then
								var_0_0.performWithDelayGlobal(function()
									xyd.WindowManager.get():openWindow("fb_share", {
										type = xyd.FBShareType.ARENA
									})
								end, 0.5)
							end
						end
					end)
				elseif var_11_3.name == "battle_scores" and var_11_4.tabMode then
					local var_11_7 = var_11_4.records
					local var_11_8 = var_11_4.tabMode
					local var_11_9 = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)

					var_11_9:getBattleScoresInfo(function(arg_16_0, arg_16_1)
						if arg_16_0 == xyd.error.OK then
							local var_16_0 = {
								herosInfo = arg_16_1.partner_info,
								totalFight = arg_16_1.arena_info.total_fight,
								winFight = arg_16_1.arena_info.win_times,
								kingPoint = arg_16_1.arena_info.point
							}

							var_11_9:getFightReports(function(arg_17_0, arg_17_1)
								if arg_17_0 == xyd.error.OK then
									var_16_0.reports = arg_17_1.records
									var_16_0.records = var_11_7
									var_16_0.mode = var_11_8

									xyd.WindowManager.get():openWindow("battle_scores", var_16_0)
								end
							end)
						end
					end)
				elseif var_11_3.name == "arena_record" then
					if var_11_4 and var_11_4.records then
						local var_11_10 = {
							records = var_11_4.records,
							type = var_11_4.mytype,
							reports = var_11_4.reports
						}

						xyd.WindowManager.get():openWindow(xyd.WindowName.arenaRecordWnd, var_11_10)
					elseif var_11_4 and var_11_4.is_casual then
						xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA):getRegionArenaInfo(function(arg_18_0, arg_18_1)
							if arg_18_0 == xyd.error.OK then
								xyd.WindowManager.get():openWindow("region_arena")
								xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_CASUAL_ARENA):getRegionCasualArenaInfo(function(arg_19_0, arg_19_1)
									xyd.WindowManager.get():getWindow("region_arena"):initCasualLayout()
									xyd.WindowManager.get():getWindow("region_arena"):updateBtnStatus("btn_casual")
								end)
							end
						end)
					end
				elseif var_11_3.name == "peak_arena_report" and var_11_4 then
					if var_11_4.fromSelectPeak then
						xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA):loadPeakArena(function(arg_20_0)
							if arg_20_0 == xyd.error.OK then
								xyd.WindowManager.get():openWindow("peak_arena")
							end
						end)
					end

					var_11_4.withWin = nil

					xyd.WindowManager.get():openWindow("peak_arena_report", var_11_4)
				elseif var_11_3.name == "region_arena" and var_11_4.mode then
					local var_11_11 = var_11_4.mode
					local var_11_12 = {
						mode = var_11_11
					}

					xyd.WindowManager.get():openWindow("region_arena", var_11_12)

					local var_11_13 = var_11_4.isWin
					local var_11_14 = var_11_4.oldStar
					local var_11_15 = var_11_4.newStar

					if not var_11_15 or not var_11_14 or not var_11_13 then
						return
					end

					local var_11_16 = {}

					if var_11_13 then
						var_11_16.battleResult = 1
						var_11_16.star = var_11_15
						var_11_16.oldStar = var_11_14
					else
						var_11_16.battleResult = 0
						var_11_16.star = var_11_15
						var_11_16.oldStar = var_11_14
					end

					xyd.WindowManager.get():openWindow("region_arena_result", var_11_16)
				elseif var_11_3.name == "activities" then
					-- block empty
				elseif var_11_3.name == "march" then
					xyd.WindowManager.get():openWindow("march", var_11_3.params, var_11_3.callback)
				elseif var_11_3.name == "treasure_window" then
					xyd.WindowManager.get():openWindow("treasure_window", var_11_3.params, var_11_3.callback)
				elseif var_11_3.name == "world_boss_battle_pre" then
					if xyd.WindowManager.get():getWindow("activities") then
						xyd.WindowManager.get():closeWindow("activities")
					end

					arg_11_0.WorldBoss = xyd.ModelManager.get():loadModel(xyd.ModelType.WORLD_BOSS)

					arg_11_0.WorldBoss:loadWorldBoss(function(arg_21_0, arg_21_1)
						if arg_21_0 == xyd.error.OK then
							local var_21_0 = xyd.WindowManager.get():openWindow("world_boss", {})
							local var_21_1 = xyd.WindowManager.get():openWindow(var_11_3.name)
							local var_21_2 = var_0_9
						end
					end, true)
				elseif var_11_3.name == "world_boss" then
					-- block empty
				elseif var_11_3.name == "nian_boss_battle_pre" then
					arg_11_0.nianBoss = xyd.ModelManager.get():loadModel(xyd.ModelType.NIAN_BOSS)

					arg_11_0.nianBoss:loadNianBoss(function(arg_22_0, arg_22_1)
						if arg_22_0 == xyd.error.OK then
							local var_22_0 = xyd.WindowManager.get():openWindow(var_11_3.name)
						end
					end)
				elseif var_11_3.name == "unlimitchallenge" then
					xyd.WindowManager.get():openWindow("time_travel")
					xyd.WindowManager.get():openWindow("unlimitchallenge", var_11_3.callback)
				elseif var_11_3.name == "get_point_window" then
					local var_11_17 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
					local var_11_18 = {
						count = var_11_17:getActivityCount()
					}

					xyd.WindowManager.get():openWindow(var_11_3.name, var_11_18):updateWindow()
				elseif var_11_3.name == "peak_arena" then
					local var_11_19 = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)
					local var_11_20 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

					xyd.Backend.get():request(xyd.mid.PEAK_RECORDS, {}, function(arg_23_0, arg_23_1)
						if arg_23_0 == xyd.error.OK then
							local var_23_0 = arg_23_1
							local var_23_1 = {}

							for iter_23_0, iter_23_1 in ipairs(var_23_0) do
								if iter_23_1.report_key then
									table.insert(var_23_1, iter_23_1.report_key)
								end
							end

							if var_23_1 and next(var_23_1) then
								xyd.db.peakArenaReportKeys:deleteAllReportKeys(var_11_20.playerID)

								for iter_23_2, iter_23_3 in ipairs(var_23_1) do
									xyd.db.peakArenaReportKeys:setReportKeys(var_11_20.playerID, iter_23_3)
								end
							end
						end
					end)
					var_11_19:loadPeakArena(function(arg_24_0)
						if arg_24_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("peak_arena", {}, function()
								local var_25_0 = xyd.WindowManager.get():getWindow("peak_arena")

								if var_25_0 then
									var_25_0:addResultEffectLayer()
								end
							end)
						end
					end)
				elseif var_11_3.name == "map_window" then
					local var_11_21 = xyd.StoryData.get():getGuideID()

					if not xyd.WindowManager.get():isWindowOpen("guide") or var_11_21 >= xyd.GuideStoryType.GUIDE_FIGHT_3_END and var_11_21 <= xyd.GuideStoryType.GUIDE_MISSION_TWO then
						if var_11_3.params.chapter_type and var_11_3.params.chapter_type == xyd.CampaignType.GUILD then
							xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):loadGuildMap(function(arg_26_0)
								xyd.WindowManager.get():openWindow(var_11_3.name, var_11_3.params, var_11_3.callback)
							end)
						else
							xyd.WindowManager.get():openWindow(var_11_3.name, var_11_3.params, var_11_3.callback)
						end
					end
				elseif var_11_3.name == "pet_collect" or var_11_3.name == "pet_main" or var_11_3.name == "pet_stone" then
					xyd.WindowManager.get():openWindow(var_11_3.name, var_11_3.params, var_11_3.callback)
				elseif var_11_3.name == "pet_campaign" then
					local var_11_22 = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)
					local var_11_23 = {}

					if var_11_22.state == xyd.PetCampaignFloorType.SUPER then
						local var_11_24 = var_11_22.superFloor or 0

						var_11_23 = {
							now_floor = var_11_24 + 1
						}
						var_11_22.last_now_floor = var_11_22.superFloor
					elseif var_11_22.last_now_floor ~= var_11_22.now_floor then
						var_11_23 = {
							now_floor = var_11_22.now_floor
						}
						var_11_22.last_now_floor = var_11_22.now_floor
					end

					xyd.WindowManager.get():openWindow("sub_dev")
					xyd.WindowManager.get():openWindow(var_11_3.name, var_11_23, var_11_3.callback)
				elseif var_11_3.params.chapter_type and tonumber(var_11_3.params.chapter_type) >= 11 and tonumber(var_11_3.params.chapter_type) <= 15 then
					xyd.WindowManager.get():openWindow("time_travel")
				elseif var_11_3.name == "team" then
					xyd.WindowManager.get():openWindow(var_11_3.name, var_11_3.params, var_11_3.callback)
				elseif var_11_3.name == "guild_war" or var_11_3.name == "guild_war_path_state" then
					xyd.WindowManager.get():openWindow(var_11_3.name, var_11_3.params, var_11_3.callback)
				elseif var_11_3.name == "board_main_window" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE):getBuildingList({}, function(arg_27_0)
						if arg_27_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("event_centre")
							xyd.WindowManager.get():openWindow("board_main_window")
						end
					end)
				elseif var_11_3.name == "thief_boss_battle_pre" then
					local var_11_25 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
					local var_11_26 = xyd.WindowManager.get():openWindow("activities")

					var_11_25:loadActivities(function(arg_28_0)
						if arg_28_0 == xyd.error.OK then
							for iter_28_0 = 1, #var_11_26.activities do
								if var_11_26.activities[iter_28_0].table_id == 1065 then
									var_11_26:leftLayout(iter_28_0)

									var_11_26.lastClickActivity = iter_28_0
								end
							end
						end
					end)
				elseif var_11_3.name == "cloud_city" then
					xyd.WindowManager.get():openWindow(var_11_3.name, var_11_3.params, var_11_3.callback)
				elseif var_11_3.name == "region_arena_loading" then
					local var_11_27 = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)
					local var_11_28 = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
					local var_11_29 = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_CASUAL_ARENA)

					if var_11_4.is_friend or var_11_28:getBattleResult() then
						-- block empty
					elseif var_11_4.is_casual then
						if not var_11_29:getBattleResult() then
							xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA):getRegionArenaInfo(function(arg_29_0, arg_29_1)
								if arg_29_0 == xyd.error.OK then
									if arg_29_1.is_close == 0 then
										xyd.WindowManager.get():openWindow("region_arena")
										var_11_29:getRegionCasualArenaInfo(function(arg_30_0, arg_30_1)
											xyd.WindowManager.get():getWindow("region_arena"):initCasualLayout()
											xyd.WindowManager.get():getWindow("region_arena"):updateBtnStatus("btn_casual")
										end)
									else
										xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS):getBasePlayers(function(arg_31_0, arg_31_1)
											if arg_31_0 == xyd.error.OK then
												if arg_31_1.playoff_info.is_open == 1 then
													local var_31_0 = {
														is_playoff = true,
														response = arg_31_1
													}

													xyd.WindowManager.get():openWindow("region_arena", var_31_0)
												else
													local var_31_1 = xyd.tables.translation:translation("REGION_ARENA_CLOSE_TIP")

													xyd.WindowManager.get():openWindow("toast", {
														message = var_31_1
													})
												end
											else
												local var_31_2 = xyd.tables.translation:translation("REGION_ARENA_CLOSE_TIP")

												xyd.WindowManager.get():openWindow("toast", {
													message = var_31_2
												})
											end
										end)
									end
								end
							end)
						end
					elseif not var_11_27:getBattleResult() then
						xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA):getRegionArenaInfo(function(arg_32_0, arg_32_1)
							if arg_32_0 == xyd.error.OK then
								if arg_32_1.is_close == 0 then
									xyd.WindowManager.get():openWindow("region_arena")
								else
									xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS):getBasePlayers(function(arg_33_0, arg_33_1)
										if arg_33_0 == xyd.error.OK then
											if arg_33_1.playoff_info.is_open == 1 then
												local var_33_0 = {
													is_playoff = true,
													response = arg_33_1
												}

												xyd.WindowManager.get():openWindow("region_arena", var_33_0)
											else
												local var_33_1 = xyd.tables.translation:translation("REGION_ARENA_CLOSE_TIP")

												xyd.WindowManager.get():openWindow("toast", {
													message = var_33_1
												})
											end
										else
											local var_33_2 = xyd.tables.translation:translation("REGION_ARENA_CLOSE_TIP")

											xyd.WindowManager.get():openWindow("toast", {
												message = var_33_2
											})
										end
									end)
								end
							end
						end)
					end
				elseif var_11_3.name == "illusion" then
					xyd.WindowManager.get():openWindow(var_11_3.name)
				elseif var_11_3.name == "academy_arena" then
					xyd.WindowManager.get():openWindow(var_11_3.name)
				elseif var_11_3.name == "academy_arena_record" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.ACADEMY_ARENA):getRecordList(function()
						xyd.WindowManager.get():openWindow(var_11_3.name)
					end)
				elseif var_11_3.name == "single_day" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.SINGLE_DAY):loadInfo({}, function(arg_35_0, arg_35_1)
						if arg_35_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("single_day")
						end
					end)
				elseif var_11_3.name == "lvbu_main" then
					xyd.WindowManager.get():openWindow("lvbu_main")
				elseif var_11_3.name == "lvbu_door" then
					xyd.WindowManager.get():openWindow("lvbu_door")
				elseif var_11_3.name == "lvbu_world_campus" then
					xyd.WindowManager.get():openWindow("lvbu_world_campus")
				elseif var_11_3.name == "lvbu_world_campus_record" then
					xyd.WindowManager.get():openWindow("lvbu_world_campus_record")
				elseif var_11_3.name == "lvbu_world_campus_report" then
					xyd.WindowManager.get():openWindow("lvbu_world_campus_report", var_11_3.params)
				elseif var_11_3.name == "library" then
					xyd.WindowManager.get():openWindow("library")
				elseif var_11_3.name == "tujian_hero" then
					xyd.WindowManager.get():openWindow("tujian_hero")
				elseif var_11_3.name == "tujian_herodetail" then
					local var_11_30 = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)

					if var_11_30.current_ then
						var_11_3.params.current = var_11_30.current_
					end

					xyd.WindowManager.get():openWindow("tujian_herodetail", var_11_3.params)
				elseif var_11_3.name == "hero_visit_main" then
					xyd.WindowManager.get():openWindow("hero_visit_main", var_11_3.params)
				elseif var_11_3.name == "hero_task_main" then
					xyd.WindowManager.get():openWindow("hero_task_main", var_11_3.params)

					local var_11_31 = var_11_3.params

					if var_11_31 and var_11_31.hero then
						local var_11_32 = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)

						var_11_32:getPartnerMission({
							partner_id = var_11_31.hero:getHeroID()
						}, function(arg_36_0, arg_36_1)
							if arg_36_0 == xyd.error.OK then
								var_11_32.libraryInfos[var_11_31.hero:getHeroID()].partner_missions = arg_36_1.mission_list

								local var_36_0 = xyd.WindowManager.get():getWindow("hero_task_main")

								if var_36_0 and not tolua.isnull(var_36_0) then
									var_36_0.taskList:reload()
								end
							end
						end)
					end
				elseif var_11_3.name == "conquer_school" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.CONQUER_SCHOOL):loadConquerSchoolInfo(function(arg_37_0)
						if arg_37_0 then
							xyd.WindowManager.get():openWindow("conquer_school", response)
						end
					end)
				elseif var_11_3.name == "sakura_main" or var_11_3.name == "sakura_enjoy" then
					xyd.WindowManager.get():openWindow(var_11_3.name)
				elseif var_11_3.name == "sakura_enjoy_playing" then
					var_11_3.params.isOver = true

					xyd.WindowManager.get():openWindow(var_11_3.name, var_11_3.params)
				elseif var_11_3.name == "sakura_battle" then
					local var_11_33 = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA)

					local function var_11_34()
						xyd.WindowManager.get():openWindow(var_11_3.name)
					end

					local var_11_35 = xyd.tables.activitySakura2Campaign:victoryStory(var_11_33.campaignID)

					if var_11_33.battleAwards and var_11_35 then
						xyd.WindowManager.get():openWindow("school_story_talk", {
							callback = var_11_34,
							talk_id = var_11_35
						})
					else
						var_11_34()
					end
				elseif var_11_3.name == "teacher" then
					xyd.WindowManager.get():openWindow("social_system"):gotoTeacher(5)
				elseif var_11_3.name == "person_display" then
					xyd.WindowManager.get():openWindow(var_11_3.name, var_11_3.params)
				elseif var_11_3.name == "zhuge_small_house" then
					if xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL):checkShowBossAward() then
						local var_11_36 = {
							talk_id = "zhuge04",
							callback = function()
								xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL):showBossAwards(function()
									xyd.WindowManager.get():openWindow("zhuge_small_house")
								end)
							end
						}

						xyd.WindowManager.get():openWindow("school_story_talk", var_11_36)
					else
						xyd.WindowManager.get():openWindow("zhuge_small_house")
					end
				elseif var_11_3.name == "zhuge_new_adventure" then
					local var_11_37 = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)

					if var_11_37:checkIsComplete() then
						var_11_37:updateMemberInfo(nil)

						if var_11_37:checkIsFirstComplete() then
							local var_11_38 = {
								talk_id = "zhuge02",
								callback = function()
									xyd.WindowManager.get():openWindow("zhuge_small_house")
								end
							}

							xyd.WindowManager.get():openWindow("school_story_talk", var_11_38)
						else
							local var_11_39 = {
								is_complete = true
							}

							xyd.WindowManager.get():openWindow("zhuge_main_wnd", var_11_39)
						end
					else
						xyd.WindowManager.get():openWindow("zhuge_new_adventure")
					end
				elseif var_11_3.name == "memories_of_school" then
					local var_11_40 = xyd.ModelManager.get():loadModel(xyd.ModelType.MEMORIES_OF_SCHOOL):getLocalParams()

					xyd.WindowManager.get():openWindow("memories_of_school_main", {
						response = clone(var_11_40)
					})
					xyd.WindowManager.get():openWindow("memories_of_school", {
						response = clone(var_11_40)
					})
				elseif var_11_3.name == "summer_main" then
					xyd.WindowManager.get():openWindow(var_11_3.name)
				elseif var_11_3.name == "summer_quiz" then
					xyd.WindowManager.get():openWindow("summer_quiz")
				elseif var_11_3.name == "two_years_main" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS):loadInfo({}, function(arg_42_0, arg_42_1)
						if arg_42_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("two_years_main")
						end
					end)
				elseif var_11_3.name == "occult_sub_map" then
					local var_11_41 = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)

					if var_11_41:isDirectedToMap() then
						xyd.WindowManager.get():openWindow("occult_sub_map")
					else
						xyd.WindowManager.get():openWindow("occult")
					end

					var_11_41:subMapEnded()
				elseif var_11_3.name == "adventure_event" then
					xyd.WindowManager.get():openWindow("adventure_event")
				elseif var_11_3.name == "adventure_defense" then
					if xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT).teamDefenseInfo.room_info then
						xyd.WindowManager.get():openWindow("adventure_defense")
					end
				elseif var_11_3.name == "war_camp_map" or var_11_3.name == "war_camp_entrance" then
					local var_11_42 = var_11_3.params

					xyd.WindowManager.get():openWindow(var_11_3.name, var_11_42)
				elseif var_11_3.name == "snow_battle" then
					xyd.WindowManager.get():openWindow("snow_battle")
				elseif var_11_3.name == "third_anniversary_boss" then
					arg_11_0.thirdAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)

					arg_11_0.thirdAnniversary:loadInfo(function(arg_43_0, arg_43_1)
						if arg_43_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("third_anni_main")
							xyd.WindowManager.get():openWindow(var_11_3.name)
						end
					end)
				elseif var_11_3.name == "super_rich_main" then
					xyd.WindowManager.get():openWindow("super_rich_main", var_11_3.params)
				elseif var_11_3.name == "chocolate_map" then
					arg_11_0.chocolateModel = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)

					arg_11_0.chocolateModel:chocolateInfo(params, function(arg_44_0, arg_44_1)
						if arg_44_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("chocolate_main")
							arg_11_0.chocolateModel:enterMap()
						end
					end)
				elseif var_11_3.name == "battle_test_output" then
					xyd.WindowManager.get():openWindow("battle_test")
					xyd.WindowManager.get():openWindow(var_11_3.name, var_11_3.params)
				elseif var_11_3.name == "tutor_sub" then
					xyd.WindowManager.get():openWindow("tutor_sub")
				elseif var_11_3.name == "tutor_exam" then
					xyd.WindowManager.get():openWindow("tutor_exam")
				elseif var_11_3.name == "tutor_exam_detail" then
					local var_11_43 = var_11_3.params.data.campaign_id
					local var_11_44 = xyd.ModelManager.get():loadModel(xyd.ModelType.TUTOR)
					local var_11_45 = {
						data = var_11_44.campaignInfos[tostring(var_11_43)],
						mode = var_11_44:getMode()
					}

					if xyd.tables.activityTutorCampaign:challengeTimes(var_11_43) - var_11_45.data.challenge_times > 0 then
						xyd.WindowManager.get():openWindow("tutor_exam_detail", var_11_45)
					end
				elseif var_11_3.name == "time_travel" then
					xyd.WindowManager.get():openWindow("time_travel")
				elseif var_11_3.name == "dream_world_main" then
					local var_11_46 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)

					var_11_46:loadInfo(function()
						xyd.WindowManager.get():openWindow("dream_world_main")
						var_11_46:getMap(function()
							xyd.WindowManager.get():openWindow("dream_world_explore")
						end)
					end)
				elseif var_11_3.name == "champions_league" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.CHAMPIONS_LEAGUE):loadInfo(function(arg_47_0, arg_47_1)
						if arg_47_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("champions_league", arg_47_1)
						end
					end)
				elseif var_11_3.name == "fourth_annni_map" then
					arg_11_0.fourthAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.FOURTH_ANNIVERSARY)

					arg_11_0.fourthAnniversary:enterMap(nil, function(arg_48_0, arg_48_1)
						if arg_48_0 == xyd.error.OK then
							-- block empty
						end
					end)
				elseif var_11_3.name == "all_night_map" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadActivities(function(arg_49_0)
						if arg_49_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("activities", {
								default_table_id = 1199
							})
						end
					end)

					local var_11_47 = xyd.ModelManager.get():loadModel(xyd.ModelType.ALL_NIGHT)

					var_11_47:enterMap(nil, var_11_47.mapMode)
				elseif var_11_3.name == "all_night_boss" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadActivities(function(arg_50_0)
						if arg_50_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("activities", {
								default_table_id = 1199
							})
							xyd.ModelManager.get():loadModel(xyd.ModelType.ALL_NIGHT):AllNightInfo(nil, function(arg_51_0, arg_51_1)
								if arg_51_0 == xyd.error.OK then
									xyd.WindowManager.get():openWindow("all_night_boss")
								end
							end)
						end
					end)
				elseif var_11_3.name == "flappy_bird_main" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.FLAPPY_BIRD):getInfo(nil, function(arg_52_0, arg_52_1)
						if arg_52_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("flappy_bird_main")
						end
					end)
				elseif var_11_3.name == "activity_ragnarok_map" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadActivities(function(arg_53_0)
						if arg_53_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("activities", {
								default_table_id = 1203
							})
						end
					end)
					xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK):enterMap()
				elseif var_11_3.name == "ragnarok_battle" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadActivities(function(arg_54_0)
						if arg_54_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("activities", {
								default_table_id = 1203
							})
							xyd.WindowManager.get():openWindow("ragnarok_main")
							xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK):checkIsEnd(function()
								xyd.WindowManager.get():openWindow("ragnarok_battle")
							end)
						end
					end)
				elseif var_11_3.name == "fifth_anni_boss" then
					xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadActivities(function(arg_56_0)
						if arg_56_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("activities", {
								default_table_id = 1232
							})
							xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY):getBossInfo(function(arg_57_0, arg_57_1)
								if arg_57_0 == xyd.error.OK then
									xyd.WindowManager.get():openWindow("fifth_anni_boss", arg_57_1)
								end
							end)
						end
					end)
				elseif var_11_3.name == "hunqi_campaign" then
					xyd.Backend.get():request(xyd.mid.HUNQI_GET_CAMPAIGN_INFO, {}, function(arg_58_0, arg_58_1)
						if arg_58_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("hunqi_campaign", arg_58_1)
						end
					end)
				end

				if var_11_2 == var_11_3.name then
					break
				end
			end
		end

		xyd.WindowManager.get():releaseRetainedHistory()
	end

	if arg_11_0.firstTime_ then
		arg_11_0.firstTime_ = nil
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.MAIN_SCENE_VISIBLE, function(arg_59_0)
		arg_11_0:setContentVisible(arg_59_0.params.visible)
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.MAIN_SCENE_RESTORE_WINDOW, function(arg_60_0)
		arg_11_0.restoreParams = arg_60_0.params
	end)

	if not arg_11_0.windowHistory then
		local var_11_48 = xyd.tables.sound:getSound("home_bg_music")

		if not audio.isMusicPlaying() then
			audio.playMusic(var_11_48, true)
		end
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.PLAY_FUNC_GUIDE, function(arg_61_0)
		local var_61_0 = arg_61_0.params

		arg_11_0:playFuncGuide(var_61_0.guide_id)
	end)

	local var_11_49 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_11_50 = xyd.ModelManager.get():loadModel(xyd.ModelType.JIGSAW)

	if var_11_49.newJigIds and next(var_11_49.newJigIds) then
		local var_11_51 = {
			ids = var_11_49.newJigIds
		}

		var_11_49.newJigIds = {}

		xyd.WindowManager.get():openWindow("jigsaw_view", var_11_51)
		var_11_50:updateRedMark()
	end

	local var_11_52 = xyd.ModelManager.get():loadModel(xyd.ModelType.JIGSAW2)

	if var_11_49.newJig2Ids and next(var_11_49.newJig2Ids) then
		local var_11_53 = {
			ids = var_11_49.newJig2Ids
		}

		var_11_49.newJig2Ids = {}

		xyd.WindowManager.get():openWindow("jigsaw2_view", var_11_53)
		var_11_52:updateRedMark()
	end

	var_11_49:handleNewAchievements()
	var_11_49:handleAdventureEventOccurNotice()
	var_11_49:handleAdventureEventFinishNotice()
end

function var_0_3.onEnterGuide(arg_62_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_62_0):addEventListener(xyd.event.PLAY_GUIDE, function(arg_63_0)
		local var_63_0 = arg_63_0.params

		if var_63_0.guide_id == xyd.GuideStoryType.GUIDE_SUMMON_START then
			arg_62_0:playStory(true)
		else
			arg_62_0:playGuide(var_63_0.guide_id)
		end
	end)
	arg_62_0:checkInValidGuideID()

	if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_START then
		local var_62_0 = {
			toStone = false,
			partnerID = 10001001,
			isGuide = true
		}

		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):loadSummonInfo(nil, function()
			local var_64_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_62_0)
		end, true)
	elseif arg_62_0:checkMiddleWndPlayGuide() then
		xyd.WindowManager.get():getWindow("main_scene_middle"):playGuide()
	elseif arg_62_0:checkBottomWndPlayGuide() then
		xyd.WindowManager.get():getWindow("main_scene_bottom"):playGuide()
	elseif arg_62_0:checkTopPlayGuide() then
		xyd.WindowManager.get():getWindow("main_scene_top"):playGuide()
	end

	local var_62_1 = xyd.StoryData.get():getFuncIDs()

	if var_62_1 and next(var_62_1) then
		for iter_62_0, iter_62_1 in pairs(var_62_1) do
			arg_62_0:playFuncGuide(xyd.GuideStoryType.OPEN_FUNCTION_START + iter_62_1)
		end
	end
end

function var_0_3.checkInValidGuideID(arg_65_0)
	local var_65_0 = xyd.StoryData.get():getGuideID()

	if var_65_0 >= xyd.GuideStoryType.GUIDE_PET_ONE and var_65_0 < xyd.GuideStoryType.GUIDE_PET_THREE then
		local var_65_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		if var_65_1.collectedPets and #var_65_1.collectedPets > 1 then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_PET_THREE)
			xyd.StoryData.get():persist()
		end
	end
end

function var_0_3.checkMiddleWndPlayGuide(arg_66_0)
	local var_66_0 = xyd.StoryData.get():getGuideID()

	if var_66_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END or var_66_0 >= xyd.GuideStoryType.GUIDE_FIGHT_2_START and var_66_0 < xyd.GuideStoryType.GUIDE_FIGHT_2_END or var_66_0 >= xyd.GuideStoryType.GUIDE_FIGHT_3_START and var_66_0 <= xyd.GuideStoryType.GUIDE_FIGHT_3_END or var_66_0 >= xyd.GuideStoryType.GUIDE_LEVUP_FOUR and var_66_0 <= xyd.GuideStoryType.GUIDE_LEVUP_END or var_66_0 >= xyd.GuideStoryType.ACTIVITY_SIX and var_66_0 <= xyd.GuideStoryType.ACTIVITY_END or var_66_0 >= xyd.GuideStoryType.GUIDE_FIGHT_4_START and var_66_0 <= xyd.GuideStoryType.GUIDE_FIGHT_4_END or var_66_0 >= xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_SIX and var_66_0 <= xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_END or var_66_0 >= xyd.GuideStoryType.GUIDE_FIGHT_5_START and var_66_0 < xyd.GuideStoryType.GUIDE_FIGHT_5_END or var_66_0 == xyd.GuideStoryType.GUIDE_SUMMON_START or var_66_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_START or var_66_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_ONE or var_66_0 >= xyd.GuideStoryType.GUIDE_FIGHT_3_END and var_66_0 <= xyd.GuideStoryType.GUIDE_MISSION_TWO then
		return true
	end

	return false
end

function var_0_3.checkBottomWndPlayGuide(arg_67_0)
	local var_67_0 = xyd.StoryData.get():getGuideID()

	if var_67_0 < xyd.GuideStoryType.GUIDE_EQUIP_END or var_67_0 >= xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_START and var_67_0 < xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_SIX or var_67_0 == xyd.GuideStoryType.GUIDE_SKILL_START or var_67_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_END or var_67_0 >= xyd.GuideStoryType.GUIDE_MISSION_THREE and var_67_0 <= xyd.GuideStoryType.GUIDE_MISSION_END or var_67_0 <= xyd.GuideStoryType.GUIDE_STONE_END or var_67_0 == xyd.GuideStoryType.GUIDE_LEVUP_START or var_67_0 == xyd.GuideStoryType.GUIDE_EQUIP_START or var_67_0 == xyd.GuideStoryType.GUIDE_STONE_START then
		return true
	end

	return false
end

function var_0_3.checkTopPlayGuide(arg_68_0)
	local var_68_0 = xyd.StoryData.get():getGuideID()

	if var_68_0 >= xyd.GuideStoryType.GUIDE_LEVUP_THREE and var_68_0 < xyd.GuideStoryType.ACTIVITY_SIX then
		return true
	end

	return false
end

function var_0_3.playGuide(arg_69_0, arg_69_1)
	if arg_69_1 == xyd.GuideStoryType.GUIDE_START then
		local var_69_0 = {
			toStone = false,
			partnerID = 10001001,
			isGuide = true
		}

		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):loadSummonInfo(nil, function()
			local var_70_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_69_0)
		end, true)
	elseif arg_69_0:checkMiddleWndPlayGuide() then
		local var_69_1 = xyd.WindowManager.get():getWindow("main_scene_middle")

		if var_69_1 then
			var_69_1:playGuide()
		end
	elseif arg_69_0:checkBottomWndPlayGuide() then
		local var_69_2 = xyd.WindowManager.get():getWindow("main_scene_bottom")

		if var_69_2 then
			var_69_2:playGuide()
		end
	elseif arg_69_0:checkTopPlayGuide() then
		local var_69_3 = xyd.WindowManager.get():getWindow("main_scene_top")

		if var_69_3 then
			var_69_3:playGuide()
		end
	end
end

function var_0_3.playFuncGuide(arg_71_0, arg_71_1)
	local var_71_0

	if arg_71_1 > xyd.GuideStoryType.OPEN_FUNCTION_START and arg_71_1 < xyd.GuideStoryType.OPEN_FUNCTION_END then
		arg_71_1 = arg_71_1 - xyd.GuideStoryType.OPEN_FUNCTION_START
		var_71_0 = true
	end

	local var_71_1 = xyd.WindowManager.get():getWindow("main_scene_middle")
	local var_71_2 = xyd.WindowManager.get():getWindow("main_scene_top")
	local var_71_3 = xyd.WindowManager.get():getWindow("main_scene_bottom")

	if arg_71_1 == xyd.FunctionID.ID_SKILL_UP then
		xyd.WindowManager.get():closeAllWindowsForGuide()
		xyd.StoryData.get():removeFuncID(xyd.FunctionID.ID_SKILL_UP)

		arg_71_1 = nil

		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_START)
		xyd.StoryData.get():persist()

		if var_71_3 and not tolua.isnull(var_71_3) then
			var_71_3:playGuide()
		end
	elseif arg_71_1 == xyd.FunctionID.ID_SUPER_CAMPAGIN then
		xyd.StoryData.get():removeFuncID(xyd.FunctionID.ID_SUPER_CAMPAGIN)

		arg_71_1 = nil

		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUPER_BATTLE_START)
		xyd.StoryData.get():persist()
	elseif arg_71_0.mainSceneAnimation then
		table.insert(arg_71_0.funcGuideIds, arg_71_1 + (var_71_0 and xyd.GuideStoryType.OPEN_FUNCTION_START or 0))

		return
	end

	if arg_71_1 then
		if var_71_1 and not tolua.isnull(var_71_1) then
			var_71_1:playFunctionGuide(arg_71_1)
		end

		if var_71_2 and not tolua.isnull(var_71_2) then
			var_71_2:playFunctionGuide(arg_71_1)
		end

		if var_71_3 and not tolua.isnull(var_71_3) then
			var_71_3:playFunctionGuide(arg_71_1)
		end
	end
end

function var_0_3.onExitTransitionStart(arg_72_0)
	arg_72_0.windowHistory = xyd.WindowManager.get():getRetainedHistory()
end

function var_0_3.onTouch_(arg_73_0, arg_73_1)
	if arg_73_1.name ~= "ended" then
		return true
	end

	return true
end

function var_0_3.onOpenSignIn(arg_74_0)
	local var_74_0 = xyd.StoryData.get():getGuideID()

	if not xyd.WindowManager.get():isWindowOpen("guide") and not xyd.WindowManager.get():isWindowOpen("guide_new") and var_74_0 >= xyd.GuideStoryType.GUIDE_END then
		arg_74_0:openWindowInOrder(1)
	end
end

function var_0_3.onOpenSevenDayLogin(arg_75_0)
	local var_75_0 = xyd.StoryData.get():getGuideID()

	if not xyd.WindowManager.get():isWindowOpen("guide") and var_75_0 >= xyd.GuideStoryType.GUIDE_END then
		local var_75_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

		if var_75_1:isActivityOpen(xyd.Activities.NewSevenDayLogin) then
			local var_75_2 = {
				activity_id = xyd.Activities.NewSevenDayLogin
			}

			var_75_1:loadSingleActivity(var_75_2, function(arg_76_0, arg_76_1)
				if arg_76_0 == xyd.error.OK and arg_76_1.is_open == 1 then
					xyd.WindowManager.get():openWindow("walfare_activities")

					return
				end
			end)
		end

		if var_75_1:isActivityOpen(xyd.Activities.SevenDayLogin) and not var_75_1:isActivityOpen(xyd.Activities.NewSevenDayLogin) then
			local var_75_3 = {
				activity_id = xyd.Activities.SevenDayLogin
			}

			var_75_1:loadSingleActivity(var_75_3, function(arg_77_0, arg_77_1)
				if arg_77_0 == xyd.error.OK then
					local var_77_0 = arg_77_1.details

					if var_77_0.award_id < var_77_0.login_day then
						xyd.WindowManager.get():openWindow("seven_day_login", arg_77_1)
					end
				end
			end)
		end
	end
end

function var_0_3.playStory(arg_78_0, arg_78_1)
	local var_78_0 = xyd.StoryData.get():getStoryID()
	local var_78_1 = xyd.StoryData.get():getStoryState()
	local var_78_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if var_78_0 == 0 and var_78_2.lev == 1 then
		local var_78_3 = xyd.WindowManager.get():openWindow("story", {
			battle_id = 10000,
			story_state = 1,
			story_id = var_78_0 + 10001
		})

		cc.EventProxy.new(var_78_3, var_78_3):addEventListener(xyd.event.STORY_COMPLETE, function(arg_79_0)
			if arg_79_0.state == 1 then
				var_78_2:sendOperationLog(xyd.StatID.ID_DIALOG8)
				arg_78_0:onEnterGuide()
				arg_78_0:onOpenSignIn()
			end
		end)
	elseif var_78_0 == 10000 and var_78_1 == 1 and var_78_2.lev == 1 then
		local var_78_4 = xyd.WindowManager.get():openWindow("story", {
			battle_id = 10000,
			story_state = 2,
			story_id = var_78_0 + 2
		})

		cc.EventProxy.new(var_78_4, var_78_4):addEventListener(xyd.event.STORY_COMPLETE, function(arg_80_0)
			if arg_80_0.state == 2 then
				var_78_2:sendOperationLog(xyd.StatID.ID_DIALOG9)
				arg_78_0:playGuide(xyd.GuideStoryType.GUIDE_SUMMON_START)
			end
		end)
	elseif not arg_78_1 then
		arg_78_0:onEnterGuide()
		arg_78_0:onOpenSignIn()
	end
end

function var_0_3.openWindowInOrder(arg_81_0, arg_81_1)
	local var_81_0 = var_0_11[arg_81_1]

	if var_81_0 == "pic_notice" then
		local var_81_1
		local var_81_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		if not var_81_2.readPicNotice then
			var_81_2.readPicNotice = 1

			xyd.Backend.get():request(xyd.mid.GET_PIC_NOTICE_INFO, {}, function(arg_82_0, arg_82_1)
				if arg_82_0 == xyd.error.OK then
					var_81_1 = arg_82_1
				else
					var_81_1 = {}
				end

				if var_81_1.has_read == 0 and #var_81_1.contents > 0 then
					xyd.WindowManager.get():openWindow("pic_notice", {
						contents = var_81_1.contents,
						callback = function()
							arg_81_0:openWindowInOrder(arg_81_1 + 1)
						end
					})
				else
					arg_81_0:openWindowInOrder(arg_81_1 + 1)
				end
			end)
		end
	elseif var_81_0 == "sign_in" then
		local var_81_3
		local var_81_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		var_81_4:loadSignInfo(function()
			if var_81_4.isSigned == 0 then
				xyd.Backend.get():request(xyd.mid.SIGN, {}, function(arg_85_0, arg_85_1)
					if arg_85_0 == xyd.error.OK then
						var_81_3 = arg_85_1

						xyd.WindowManager.get():openWindow("sign_in", {
							signResponse = var_81_3,
							callback = function()
								arg_81_0:openWindowInOrder(arg_81_1 + 1)
							end
						})
					else
						arg_81_0:openWindowInOrder(arg_81_1 + 1)
					end
				end)
			else
				arg_81_0:openWindowInOrder(arg_81_1 + 1)
			end
		end)
	elseif var_81_0 == "walfare_activities" then
		local var_81_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

		if var_81_5:isActivityOpen(xyd.Activities.NewSevenDayLogin) then
			local var_81_6 = {
				activity_id = xyd.Activities.NewSevenDayLogin
			}

			var_81_5:loadSingleActivity(var_81_6, function(arg_87_0, arg_87_1)
				if arg_87_0 == xyd.error.OK and arg_87_1.is_open == 1 then
					xyd.WindowManager.get():openWindow("walfare_activities", {
						callback = function()
							arg_81_0:openWindowInOrder(arg_81_1 + 1)
						end
					})

					return
				end

				arg_81_0:openWindowInOrder(arg_81_1 + 1)
			end)
		else
			arg_81_0:openWindowInOrder(arg_81_1 + 1)
		end
	elseif var_81_0 == "seven_day_login" then
		local var_81_7 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

		if var_81_7:isActivityOpen(xyd.Activities.SevenDayLogin) then
			local var_81_8 = {
				activity_id = xyd.Activities.SevenDayLogin
			}

			var_81_7:loadSingleActivity(var_81_8, function(arg_89_0, arg_89_1)
				if arg_89_0 == xyd.error.OK then
					local var_89_0 = arg_89_1.details

					if var_89_0.award_id < var_89_0.login_day then
						xyd.WindowManager.get():openWindow("seven_day_login", {
							response = arg_89_1,
							callback = function()
								arg_81_0:openWindowInOrder(arg_81_1 + 1)
							end
						})

						return
					end
				end

				arg_81_0:openWindowInOrder(arg_81_1 + 1)
			end)
		else
			arg_81_0:openWindowInOrder(arg_81_1 + 1)
		end
	elseif var_81_0 == "gift_push" then
		local var_81_9 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		if #xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):getGiftInfo() > 0 then
			var_81_9:queryChargeData(function()
				xyd.WindowManager.get():openWindow("gift_push")
			end)
		end
	end
end

return var_0_3
