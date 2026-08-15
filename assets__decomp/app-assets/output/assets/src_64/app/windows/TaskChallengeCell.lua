local var_0_0 = class("TaskChallengeCell", import("app.common.ui.BaseNode"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.window
local var_0_4 = xyd.tables.functionOpen
local var_0_5 = xyd.tables.battlePassMission
local var_0_6 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0)

	arg_1_0.taskInfo = arg_1_1.taskInfo
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.battlePass = xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS)
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.parent = xyd.WindowManager.get():getWindow(xyd.WindowName.TASK)
	arg_1_0.id = arg_1_0.taskInfo.id

	arg_1_0:loadRes("windows/task/challenge_cell.csb")
end

function var_0_0.layout(arg_2_0)
	arg_2_0:nodeByName("txt_desc"):setString(var_0_5:desc(arg_2_0.id))
	arg_2_0:nodeByName("txt_jump"):setString(var_0_2:translation("BATTLE_PASS_TEXT_25"))
	arg_2_0:nodeByName("txt_get"):setString(var_0_2:translation("BATTLE_PASS_TEXT_8"))

	local var_2_0 = var_0_1.new({
		size = 520
	})

	var_2_0:setOpacity(128)
	arg_2_0:nodeByName("pos_line"):addChild(var_2_0)

	local var_2_1 = var_0_5:count(arg_2_0.id)
	local var_2_2 = math.min(var_2_1, arg_2_0.taskInfo.count)

	arg_2_0:nodeByName("txt_count"):setString(var_2_2 .. "/" .. var_2_1)
	arg_2_0:nodeByName("bar"):setPercent(100 * var_2_2 / var_2_1)

	if arg_2_0.taskInfo.is_award == 1 then
		arg_2_0:nodeByName("icon"):setVisible(true)
	elseif var_2_1 <= arg_2_0.taskInfo.count then
		arg_2_0:nodeByName("btn_get"):setVisible(true)
	else
		arg_2_0:nodeByName("btn_jump"):setVisible(true)
	end

	local var_2_3 = var_0_5:score(arg_2_0.id)

	if var_2_3 > 0 then
		xyd.setItemAndAddTips(arg_2_0:nodeByName("item"), var_0_6:getValue("battle_pass_score_id"), var_2_3)
	end

	arg_2_0:nodeByName("btn_jump"):addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(arg_3_0, arg_3_1)

		if arg_3_1 == ccui.TouchEventType.ended then
			if arg_2_0.parent and arg_2_0.parent.scrollViewMoved_ then
				return
			end

			local var_3_0 = var_0_5:jumpWindow(arg_2_0.id)
			local var_3_1 = var_0_3:className(var_3_0)

			if var_3_0 and var_3_0 == "main_scene" then
				xyd.WindowManager.get():closeAllWindowsForGuide()

				return
			end

			if var_3_1 and arg_2_0["open" .. var_3_1] then
				local var_3_2 = var_0_5:functionId(arg_2_0.id)

				if var_3_2 > 0 then
					if arg_2_0.selfPlayer:isFuncOpen(var_3_2) then
						arg_2_0["open" .. var_3_1](arg_2_0)
					else
						local var_3_3 = var_0_4:tip(var_3_2)

						if var_3_3 == "" then
							var_3_3 = var_0_2:translation("FUNCTION_OPEN_TIP_OTHER")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_3_3
						})
					end
				else
					arg_2_0["open" .. var_3_1](arg_2_0)
				end
			end
		end
	end)
	arg_2_0:nodeByName("btn_get"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_2_0.battlePass:getMissionAward({
				id = arg_2_0.taskInfo.list_id
			}, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					local var_5_0 = {
						{
							table_id = var_0_6:getValue("battle_pass_score_id"),
							item_num = var_2_3
						}
					}

					arg_2_0.selfPlayer:handleRewards(var_5_0)
					arg_2_0.parent:battlePassRefreshList()
				end
			end, var_2_3)
		end
	end)
end

function var_0_0.openArenaWindow(arg_6_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("arena")
		end
	end)
end

function var_0_0.openPeakArenaWindow(arg_8_0)
	if arg_8_0.selfPlayer.isOldTop == 1 then
		xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA_OLD):loadPeakArena(function(arg_9_0)
			if arg_9_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("peak_arena_old")
			end
		end)
	else
		xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA):loadPeakArena(function(arg_10_0)
			if arg_10_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("peak_arena")
			end
		end)
	end
end

function var_0_0.openSummonWindow(arg_11_0)
	arg_11_0.selfPlayer:loadSummonInfo({}, function()
		xyd.WindowManager.get():openWindow("summon")
	end)
end

function var_0_0.openMapWindow(arg_13_0)
	arg_13_0.selfPlayer:loadWorldMap(function()
		if arg_13_0.id == 8 then
			if arg_13_0.selfPlayer.lev < 80 then
				return
			elseif arg_13_0.selfPlayer.worldMaps_[24111] == nil then
				local var_14_0 = var_0_2:translation("CHALLENGE_ISNOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_14_0
				})

				return
			end
		end

		arg_13_0.guild:loadGuildMap(function(arg_15_0)
			xyd.WindowManager.get():openWindow("map_window", {
				chapter_type = 1
			})
		end)
	end)
end

function var_0_0.openTimeTravelWindow(arg_16_0)
	xyd.WindowManager.get():openWindow("time_travel")
end

function var_0_0.openIllusionWindow(arg_17_0)
	xyd.WindowManager.get():openWindow("illusion")
end

function var_0_0.openMemoriesOfSchoolMainWindow(arg_18_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.MEMORIES_OF_SCHOOL):getInfo({}, function(arg_19_0, arg_19_1)
		xyd.WindowManager.get():openWindow("memories_of_school_main", {
			response = clone(arg_19_1)
		})
	end)
end

function var_0_0.openOccultWindow(arg_20_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT):openOccultWindow()
end

function var_0_0.openDormWindow(arg_21_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.DORM):getHouseList()
end

function var_0_0.openFurnitureFactoryWindow(arg_22_0)
	xyd.WindowManager.get():openWindow("furniture_factory")
end

function var_0_0.openCourseWindow(arg_23_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE):enterCourseWindow()
end

function var_0_0.openWhiteAlbumWindow(arg_24_0)
	xyd.WindowManager.get():openWindow("white_album")
end

function var_0_0.openFumoWindow(arg_25_0)
	xyd.WindowManager.get():openWindow("fumo")
end

function var_0_0.openWashHeroWindow(arg_26_0)
	xyd.WindowManager.get():openWindow("wash_hero")
end

function var_0_0.openSuperPartnerWindow(arg_27_0)
	xyd.WindowManager.get():openWindow("super_partner")
end

function var_0_0.openInscriptionWindow(arg_28_0)
	xyd.WindowManager.get():openWindow("inscription")
end

function var_0_0.openProductionTableWindow(arg_29_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE):getDeskpInfo({}, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			local var_30_0 = {
				deskInfo = arg_30_1
			}

			xyd.WindowManager.get():openWindow("production_table", var_30_0)
		end
	end)
end

function var_0_0.openTreasureWindow(arg_31_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE):loadTreasureInfo(function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("treasure_window")
		end
	end)
end

function var_0_0.openMarchWindow(arg_33_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH):loadMarchInfo({}, function(arg_34_0)
		if arg_34_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("march")
		end
	end)
end

function var_0_0.openShopWindow(arg_35_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
		xyd.WindowManager.get():openWindow("shop", {
			shop_type = 1
		})
	end)
end

function var_0_0.openCloudCityWindow(arg_37_0)
	xyd.WindowManager.get():openWindow("cloud_city")
end

function var_0_0.openAuctionRoomWindow(arg_38_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.AUCTION):getAuctionInfoByType({
		auction_type = 2
	}, function(arg_39_0, arg_39_1)
		if arg_39_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("auction_room", {
				loaded = true
			})
		end
	end)
end

function var_0_0.openSocialSystemWindow(arg_40_0)
	xyd.WindowManager.get():openWindow("social_system", {
		goToClass = false
	})
end

function var_0_0.openTeamWindow(arg_41_0)
	arg_41_0.guild:loadSelfGuild(function(arg_42_0)
		if arg_42_0 == xyd.error.OK then
			if arg_41_0.guild.guild_id == nil or arg_41_0.guild.guild_id == 0 then
				xyd.WindowManager.get():openWindow("team_main")
			else
				xyd.WindowManager.get():openWindow("team")
			end
		end
	end)
end

function var_0_0.openHeroListWindow(arg_43_0)
	arg_43_0.selfPlayer:loadHeros({}, function(arg_44_0)
		if arg_44_0 == xyd.error.OK then
			if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_EQUIP_END then
				arg_43_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_HEROWND)
			end

			if not arg_43_0.selfPlayer:getBackpack() then
				arg_43_0.selfPlayer:loadBackpack(function(arg_45_0)
					if arg_45_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("hero_list")

						if arg_43_0.selfPlayer:getSkillPoint() == arg_43_0.selfPlayer:getSkillPointLimit() then
							arg_43_0.selfPlayer:setPressHero(true, arg_43_0.selfPlayer.hasChangeSkill)
						end
					end
				end)
			else
				xyd.WindowManager.get():openWindow("hero_list")

				if arg_43_0.selfPlayer:getSkillPoint() == arg_43_0.selfPlayer:getSkillPointLimit() then
					arg_43_0.selfPlayer:setPressHero(true, arg_43_0.selfPlayer.hasChangeSkill)
				end
			end
		end
	end)
end

function var_0_0.openSkinShopWindow(arg_46_0)
	if not arg_46_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_SHOP) then
		local var_46_0 = xyd.tables.campaign
		local var_46_1 = "NUM_" .. var_46_0:chapter(var_0_4:stage(xyd.FunctionID.ID_SHOP))
		local var_46_2 = string.format(var_0_2:translation("FUNCTION_OPEN_TIP_STAGE"), var_0_2:translation(var_46_1))

		xyd.WindowManager.get():openWindow("toast", {
			message = var_46_2
		})

		return
	end

	xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadSkinShopInfo({}, function()
		xyd.WindowManager.get():openWindow("skin_shop", {})
	end)
end

function var_0_0.openHunqiCampaignWindow(arg_48_0)
	if arg_48_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_HUNQI) then
		xyd.Backend.get():request(xyd.mid.HUNQI_GET_CAMPAIGN_INFO, {}, function(arg_49_0, arg_49_1)
			if arg_49_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("hunqi_campaign", arg_49_1)
			end
		end)
	else
		local var_48_0 = var_0_4:tip(xyd.FunctionID.ID_HUNQI)

		if var_48_0 == "" then
			var_48_0 = transTable:translation("FUNCTION_OPEN_TIP_OTHER")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_48_0
		})
	end
end

function var_0_0.openChampionsLeagueWinodw(arg_50_0)
	if arg_50_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CHAMPIONS_LEAGUE) then
		xyd.ModelManager.get():loadModel(xyd.ModelType.CHAMPIONS_LEAGUE):loadInfo(function(arg_51_0, arg_51_1)
			if arg_51_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("champions_league", arg_51_1)
			end
		end)
	else
		local var_50_0 = var_0_4:tip(xyd.FunctionID.ID_CHAMPIONS_LEAGUE)

		if var_50_0 == "" then
			var_50_0 = transTable:translation("FUNCTION_OPEN_TIP_OTHER")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_50_0
		})
	end
end

return var_0_0
