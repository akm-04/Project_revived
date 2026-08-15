local var_0_0 = class("TaskDailyCell", import("app.common.ui.BaseNode"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.mission
local var_0_4 = "#44505B"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0)

	arg_1_0.taskInfo = arg_1_1.taskInfo
	arg_1_0.tableID = arg_1_0.taskInfo.table_id
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.battlePass = xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS)

	arg_1_0:loadRes("windows/task/task_normal_cell.csb")
end

function var_0_0.layout(arg_2_0)
	if arg_2_0.taskInfo.is_complete == 1 and arg_2_0.taskInfo.is_reward == 0 then
		arg_2_0:nodeByName("bg_task_highlight"):setVisible(true)
		arg_2_0:nodeByName("bg_task"):setVisible(false)
	else
		arg_2_0:nodeByName("bg_task_highlight"):setVisible(false)
		arg_2_0:nodeByName("bg_task"):setVisible(true)
	end

	local var_2_0 = xyd.createAutoFixLabel({
		height = 30,
		fontSize = 24,
		txtColor = "#4fa6fe",
		width = 330,
		text = var_0_3:name(arg_2_0.tableID),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_2_0:addTo(arg_2_0:background())
	var_2_0:setAnchorPoint(0, 0.5)
	var_2_0:setPosition(arg_2_0:nodeByName("pos_txt_name"):getPosition())

	local var_2_1 = xyd.createAutoFixLabel({
		height = 53,
		fontSize = 20,
		txtColor = "#6A6977",
		width = 285,
		text = var_0_3:des(arg_2_0.tableID),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_2_1:addTo(arg_2_0:background())
	var_2_1:setAnchorPoint(0, 1)
	var_2_1:setPosition(arg_2_0:nodeByName("pos_txt_desc"):getPosition())

	local var_2_2 = var_0_1.new({
		size = 282,
		color = var_0_4
	})

	var_2_2:addTo(arg_2_0:background())
	var_2_2:setAnchorPoint(0, 0.5)
	var_2_2:setPosition(arg_2_0:nodeByName("pos_splitline"):getPosition())

	local var_2_3 = arg_2_0:nodeByName("icon_container")
	local var_2_4 = var_0_3:icon(arg_2_0.tableID)

	if var_2_4 and type(var_2_4) == "string" and tonumber(var_2_4) == nil then
		xyd.setSpriteBorder(var_2_3, var_2_4, 1)
	else
		local var_2_5

		if arg_2_0.taskInfo.inscript_id and arg_2_0.taskInfo.inscript_id > 0 then
			var_2_5 = arg_2_0.taskInfo.inscript_id
		else
			local var_2_6 = var_0_3:award(arg_2_0.tableID)

			xyd.splitToNumber(var_2_6, "|")

			if var_2_6 and var_2_6[1] and var_2_6[1] > 0 then
				var_2_5 = var_2_6[1]
			end
		end

		xyd.setItemAndAddTips(var_2_3, var_2_5)
	end

	local var_2_7 = arg_2_0:updateAwardShow()

	if var_2_7 then
		var_2_7:addTo(arg_2_0:background())
		var_2_7:setAnchorPoint(0, 0.5)

		local var_2_8, var_2_9 = arg_2_0:nodeByName("pos_award"):getPosition()

		var_2_7:setPosition(var_2_8, var_2_9 - 5)
	end

	arg_2_0:updateTaskProgress()

	arg_2_0.clickNode = display.newNode()

	arg_2_0.clickNode:setContentSize(arg_2_0:background():getContentSize())
	arg_2_0.clickNode:addTo(arg_2_0:background())
	arg_2_0.clickNode:setAnchorPoint(0, 0)
	arg_2_0.clickNode:setPosition(0, 0)
	arg_2_0.clickNode:setTouchEnabled(true)
	arg_2_0.clickNode:setTouchSwallowEnabled(false)
	arg_2_0:onRegister()
end

function var_0_0.updateAwardShow(arg_3_0)
	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/task/task_award.csb")

	if not var_3_0 then
		return
	end

	local var_3_1 = var_3_0:getChildByName("background")
	local var_3_2 = var_0_3:getShowAward(arg_3_0.tableID)

	if var_3_2 and var_3_2[1] and var_3_2[1] ~= "" then
		for iter_3_0 = 1, 3 do
			local var_3_3 = var_3_2[iter_3_0]

			if var_3_3 then
				local var_3_4
				local var_3_5
				local var_3_6
				local var_3_7 = var_3_1:getChildByName("pos_eco_" .. iter_3_0)
				local var_3_8 = var_3_1:getChildByName("txt_val_" .. iter_3_0)

				if var_3_3 == "medal" then
					local var_3_9 = xyd.tables.ecoType:getEcoPath("mission_huoyue")

					var_3_6 = xyd.AssetLoader.get():loadSprite(var_3_9)
					var_3_5 = var_0_3:medal(arg_3_0.tableID)
				elseif var_3_3 == "energy" then
					local var_3_10 = xyd.tables.ecoType:getEcoPath("energy")

					var_3_6 = xyd.AssetLoader.get():loadSprite(var_3_10)

					local var_3_11 = var_0_3:award(arg_3_0.tableID)
					local var_3_12 = xyd.split(var_3_11, "|")

					var_3_5 = tonumber(var_3_12[2])
				elseif var_3_3 == "diamond_new" then
					local var_3_13 = xyd.tables.ecoType:getEcoPath("crystal")

					var_3_6 = xyd.AssetLoader.get():loadSprite(var_3_13)
					var_3_5 = var_0_3:crystal(arg_3_0.tableID)
				elseif var_3_3 == "inscript" then
					var_3_6 = display.newNode()

					var_3_6:setContentSize(45, 45)
					xyd.setItemBorder(var_3_6, arg_3_0.taskInfo.inscript_id)

					var_3_5 = 1
				elseif var_3_3 == "item" then
					if arg_3_0.tableID == xyd.MissionIDs.DAILY.GET_SWEEP_CARD then
						local var_3_14 = var_0_3:award(arg_3_0.tableID)
						local var_3_15 = xyd.tables.vip:sweepCard(arg_3_0.selfPlayer.vip)

						var_3_6 = display.newNode()

						var_3_6:setContentSize(45, 45)
						xyd.setItemBorder(var_3_6, tonumber(var_3_14))

						var_3_5 = var_3_15
					else
						local var_3_16 = var_0_3:award(arg_3_0.tableID)
						local var_3_17 = var_0_3:award_num(arg_3_0.tableID)

						var_3_6 = display.newNode()

						var_3_6:setContentSize(45, 45)
						xyd.setItemBorder(var_3_6, tonumber(var_3_16))

						var_3_5 = var_3_17
					end
				elseif var_3_3 == "bp_score" and arg_3_0.battlePass:isOpen() and arg_3_0.battlePass:isFuncOpen() then
					local var_3_18 = "images/icon/eco/battle_pass_gp.png"

					var_3_6 = xyd.AssetLoader.get():loadSprite(var_3_18)
					var_3_5 = var_0_3:battlePassScore(arg_3_0.tableID)
				end

				if var_3_6 and var_3_5 and var_3_5 > 0 then
					var_3_6:setScale(0.75)
					var_3_6:addTo(var_3_1)
					var_3_6:setPosition(var_3_7:getPosition())
					var_3_6:setAnchorPoint(0.5, 0.5)
					var_3_8:setString("x" .. var_3_5)
				end
			end
		end

		return var_3_0
	end

	return var_3_0
end

function var_0_0.updateTaskProgress(arg_4_0)
	if arg_4_0.taskInfo.is_complete == 1 and arg_4_0.taskInfo.is_reward == 0 then
		if arg_4_0.progressTxt then
			arg_4_0.progressTxt:setVisible(false)
		end

		return
	end

	local var_4_0
	local var_4_1 = var_0_3:task_req(arg_4_0.tableID)

	if var_4_1 == 111 or var_4_1 == 118 then
		var_4_0 = var_0_2:translation("TIME_TOO_EARLY")
	elseif arg_4_0.tableID == xyd.MissionIDs.DAILY.MONTH_CARD then
		if arg_4_0.selfPlayer.leftCardDay <= 0 then
			var_4_0 = string.format("%s", var_0_2:translation("NOT_BUY"))
		else
			var_4_0 = string.format(var_0_2:translation("CARD_LEFT"), arg_4_0.selfPlayer.leftCardDay)
		end
	elseif arg_4_0.tableID == xyd.MissionIDs.DAILY.WEEK_CARD then
		if arg_4_0.selfPlayer.leftWeekCardDay <= 0 then
			var_4_0 = string.format("%s", var_0_2:translation("NOT_BUY"))
		else
			var_4_0 = string.format(var_0_2:translation("CARD_LEFT"), arg_4_0.selfPlayer.leftWeekCardDay)
		end
	elseif arg_4_0.tableID == xyd.MissionIDs.DAILY.ENERGY_MONTH_CARD then
		if arg_4_0.selfPlayer.leftEnergyMonthCardDay <= 0 then
			var_4_0 = string.format("%s", var_0_2:translation("NOT_BUY"))
		else
			var_4_0 = string.format(var_0_2:translation("CARD_LEFT"), arg_4_0.selfPlayer.leftEnergyMonthCardDay)
		end
	elseif arg_4_0.tableID == xyd.MissionIDs.DAILY.PRIVILEGE_MONTH_CARD then
		if arg_4_0.selfPlayer.privilegeLeftCardDay <= 0 then
			var_4_0 = string.format("%s", var_0_2:translation("NOT_BUY"))
		else
			var_4_0 = string.format(var_0_2:translation("CARD_LEFT"), arg_4_0.selfPlayer.privilegeLeftCardDay)
		end
	else
		var_4_0 = string.format("%d/%d", arg_4_0.taskInfo.count, var_0_3:task_num(arg_4_0.tableID))
	end

	local var_4_2 = xyd.createAutoFixLabel({
		height = 25,
		fontSize = 20,
		txtColor = "#6A6977",
		width = 95,
		text = var_4_0,
		align = cc.ui.TEXT_ALIGN_RIGHT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_4_2:addTo(arg_4_0:background())
	var_4_2:setAnchorPoint(1, 0.5)
	var_4_2:setPosition(arg_4_0:nodeByName("pos_txt_progress"):getPosition())
end

function var_0_0.onRegister(arg_5_0)
	arg_5_0.clickNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			arg_5_0:background():setScale(0.95)

			arg_5_0.prevX = arg_6_0.x
			arg_5_0.prevY = arg_6_0.y
			arg_5_0.startClick = true

			return true
		elseif arg_6_0.name == "moved" then
			if math.abs(arg_6_0.y - arg_5_0.prevY) > 10 or math.abs(arg_6_0.x - arg_5_0.prevX) > 10 then
				arg_5_0.startClick = false

				arg_5_0:background():setScale(1)

				return true
			end
		elseif arg_6_0.name == "ended" then
			if not arg_5_0.startClick then
				return
			end

			arg_5_0:background():setScale(1)

			if arg_5_0.taskInfo.is_complete == 1 and arg_5_0.taskInfo.is_reward == 0 then
				local var_6_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
				local var_6_1 = arg_5_0.tableID

				var_6_0:getTaskReward(var_6_1, xyd.TaskType.DAILY, function(arg_7_0, arg_7_1)
					if arg_7_0 == xyd.error.OK and arg_7_1 and arg_7_1.awards then
						xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_7_1.awards)
					end
				end)
			else
				arg_5_0:goToTargetWnd()
			end
		end
	end)
end

function var_0_0.goToTargetWnd(arg_8_0)
	local var_8_0 = var_0_3:goto_type(arg_8_0.tableID)
	local var_8_1 = var_0_3:task_req(arg_8_0.tableID)

	if arg_8_0.tableID == xyd.MissionIDs.DAILY.CRYSTAL_TO_GOLD then
		xyd.WindowManager.get():openWindow("golden_hand")
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.CAMPAIGN_COUNT then
		arg_8_0.guild:loadGuildMap(function(arg_9_0)
			if arg_9_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("map_window", {
					chapter_type = 1
				})
			end
		end)
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.SUPER_CAMPAIGN_COUNT then
		arg_8_0.guild:loadGuildMap(function(arg_10_0)
			if arg_10_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("map_window", {
					chapter_type = 2
				})
			end
		end)
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.TIME_CAVE_COUNT then
		xyd.WindowManager.get():openWindow("time_trial")
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.EXERCISE_COUNT then
		xyd.WindowManager.get():openWindow("trial")
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.MARCH_COUNT then
		xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH):loadMarchInfo({}, function(arg_11_0)
			if arg_11_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("march")
			end
		end)
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.ARENA_BATTLE_COUNT then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_12_0, arg_12_1)
			if arg_12_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("sub_arena")
			end
		end)
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.SKILL_UP_COUNT then
		arg_8_0.selfPlayer:loadHeros({}, function()
			xyd.WindowManager.get():openWindow(xyd.WindowName.heroCollectWnd)
		end)
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.RUNE_POWERUP then
		xyd.WindowManager.get():openWindow("fumo")
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.RUN_SUMMON then
		arg_8_0.selfPlayer:loadSummonInfo({}, function()
			xyd.WindowManager.get():openWindow("summon")
		end)
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.MONTH_CARD then
		xyd.WindowManager.get():openWindow("vip_recharge")
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.WEEK_CARD then
		xyd.WindowManager.get():openWindow("vip_recharge")
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.ENERGY_MONTH_CARD then
		xyd.WindowManager.get():openWindow("vip_recharge")
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.PRIVILEGE_MONTH_CARD then
		local var_8_2 = {}

		var_8_2.windowState = true
		var_8_2.chargeState = xyd.ChargeState.monthlyPrivilege

		xyd.WindowManager.get():openWindow("vip_recharge", var_8_2)
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.TREASURE then
		xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE):loadTreasureInfo(function(arg_15_0)
			if arg_15_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("treasure_window")
			end
		end)
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.ACTIVITY_UNLIMIT_CHALLENGE then
		xyd.WindowManager.get():openWindow("unlimitchallenge")
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.SKY then
		xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN):getCampaignInfo(function(arg_16_0)
			if arg_16_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("pet_campaign")
			end
		end)
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.HAOGAN then
		xyd.WindowManager.get():openWindow("tujian_hero")
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.TEA_TALK then
		arg_8_0.guild:getTeaTalkInfo(function(arg_17_0)
			if arg_17_0 == xyd.error.OK then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.DRINK_NOTIF
				})
				xyd.WindowManager.get():openWindow("team_tea_talk")
			else
				local var_17_0 = var_0_2:translation("HAS_NOT_JOIN_GUILD")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_0
				})
			end
		end)
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.TIMETRAVEL then
		xyd.WindowManager.get():openWindow("time_travel")
	elseif arg_8_0.tableID == xyd.MissionIDs.DAILY.HUNQI_CAMPAIGN_CARD then
		if arg_8_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_HUNQI) then
			xyd.Backend.get():request(xyd.mid.HUNQI_GET_CAMPAIGN_INFO, {}, function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("hunqi_campaign", arg_18_1)
				end
			end)
		else
			local var_8_3 = xyd.tables.functionOpen:tip(xyd.FunctionID.ID_HUNQI)

			if var_8_3 == "" then
				var_8_3 = var_0_2:translation("FUNCTION_OPEN_TIP_OTHER")
			end

			xyd.WindowManager.get():openWindow("toast", {
				message = var_8_3
			})
		end
	elseif var_8_0 == 11 then
		local var_8_4 = var_0_3:goto_value(arg_8_0.tableID)
		local var_8_5 = {
			isStoneCampaign = true,
			chapter = xyd.tables.campaign:chapter(var_8_4),
			campaignID = var_8_4
		}
		local var_8_6 = 2
		local var_8_7 = 1

		if xyd.tables.campaign:campaignType(var_8_4) == var_8_6 or xyd.tables.campaign:campaignType(var_8_4) == var_8_7 then
			var_8_5.campaignType = xyd.CampaignType.NORMAL
		else
			var_8_5.campaignType = xyd.CampaignType.SUPER
		end

		arg_8_0.guild:loadGuildMap(function()
			xyd.WindowManager.get():openWindow("map_window", var_8_5)
		end)

		local var_8_8 = xyd.WindowManager.get():getWindow("map_window")

		if var_8_8 and xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_MISSION_END then
			var_8_8:playGuide()
		end
	elseif var_8_0 == 14 then
		local var_8_9 = arg_8_0.selfPlayer.normal_chapter_id
		local var_8_10 = arg_8_0.guild:getMinchapterID()

		arg_8_0.guild:loadGuildMap(function(arg_20_0)
			if arg_20_0 == xyd.error.OK then
				var_8_10 = arg_8_0.guild:getMinchapterID()

				if var_8_9 < var_8_10 then
					local var_20_0 = var_0_2:translation("NORMAL_MAP_ALERT")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_20_0
					})

					return
				elseif arg_8_0.selfPlayer.lev < xyd.tables.teamCampaign:openLevByChapter(var_8_10) then
					local var_20_1 = var_0_2:translation("GUILD_CAMPAIGN_CANNOT_TIP2")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_20_1
					})

					return
				else
					local var_20_2 = {
						chapter_type = xyd.CampaignType.GUILD
					}

					xyd.WindowManager.get():openWindow("map_window", var_20_2)
				end
			else
				local var_20_3 = var_0_2:translation("JOIN_GUILD_TIP")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_20_3
				})
			end
		end)
	elseif var_8_0 == 15 then
		arg_8_0.guild:loadSelfGuild(function(arg_21_0)
			if arg_21_0 == xyd.error.OK then
				local var_21_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

				if var_21_0.guild_id == nil or var_21_0.guild_id == 0 then
					xyd.WindowManager.get():openWindow("team_main")
				else
					xyd.WindowManager.get():openWindow("team")
					var_21_0:loadSentHeros(function(arg_22_0)
						if arg_22_0 == xyd.error.OK then
							var_21_0:loadRentPets(function(arg_23_0)
								if arg_23_0 == xyd.error.OK then
									xyd.WindowManager.get():openWindow("hire_hero")
								end
							end)
						end
					end)
				end
			end
		end)
	elseif var_8_0 == 24 then
		xyd.WindowManager.get():openWindow("pet_collect")
	elseif var_8_1 == xyd.TaskReq.CENTER_ACTIVITY_UPGRADE then
		local var_8_11 = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

		var_8_11:getBuildingList({}, function(arg_24_0)
			if arg_24_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("event_centre")

				if var_8_0 == xyd.EventCentreBuildingType.CABINET then
					var_8_11:getCabinetInfo(function(arg_25_0)
						if arg_25_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("junk_chest")
						end
					end)
				elseif var_8_0 == xyd.EventCentreBuildingType.DESK then
					var_8_11:getDeskpInfo({}, function(arg_26_0, arg_26_1)
						if arg_26_0 == xyd.error.OK then
							local var_26_0 = {
								deskInfo = arg_26_1
							}

							xyd.WindowManager.get():openWindow("production_table", var_26_0)
						end
					end)
				elseif var_8_0 == xyd.EventCentreBuildingType.TRASH then
					var_8_11:getRecycleInfo({}, function(arg_27_0, arg_27_1)
						if arg_27_0 == xyd.error.OK then
							local var_27_0 = {
								recycleInfo = arg_27_1
							}

							xyd.WindowManager.get():openWindow("recycle", var_27_0)
						end
					end)
				end
			end
		end)
	elseif var_8_1 == xyd.TaskReq.CENTER_ACTIVITY_MISSION then
		local var_8_12 = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

		var_8_12:getBuildingList({}, function(arg_28_0)
			if arg_28_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("event_centre")
				var_8_12:getCabinetInfo(function(arg_29_0)
					if arg_29_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("junk_chest")
					end
				end)
			end
		end)
	end
end

return var_0_0
