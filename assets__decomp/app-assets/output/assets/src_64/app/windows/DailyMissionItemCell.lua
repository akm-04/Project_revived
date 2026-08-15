local var_0_0 = class("DailyMissionItemCell", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.mission

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.container = arg_2_0:contentView():nodeByName("container")
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.tableID = arg_3_1.id
	arg_3_0.type = arg_3_1.type
	arg_3_0.mission = arg_3_1.mission
	arg_3_0.parent = arg_3_1.parent
	arg_3_0.goal = arg_3_0.mission.goal

	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setItemBg()
	arg_4_0:registerTouchEvent()
	arg_4_0:setMissionAward()
end

function var_0_0.getTableID(arg_5_0)
	return arg_5_0.tableID
end

local function var_0_3(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = xyd.tables.misc.energyMaxLimit
	local var_6_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if var_6_0 < var_6_1.energy and xyd.isInTable({
		10011,
		10012,
		10013,
		10020,
		10021,
		10022,
		10023,
		10035
	}, arg_6_2.id) and arg_6_2.mission.isComplete then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_1:translation("TILI_LIMIT_INFO")
		})
	elseif arg_6_2.mission.isComplete then
		local var_6_2 = {
			table_id = arg_6_2.id
		}

		xyd.Backend.get():request(xyd.mid.TAKE_MISSION_AWARD, var_6_2, function(arg_7_0, arg_7_1, arg_7_2)
			if arg_7_0 == xyd.error.OK and arg_7_1.awards then
				for iter_7_0, iter_7_1 in pairs(arg_7_1.awards) do
					if iter_7_1.mission_huoyue then
						local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.MISSION)

						table.remove(arg_7_1.awards, iter_7_0)

						break
					end
				end

				local var_7_1 = string.format("%s %s", var_0_1:translation("FINISH"), var_0_2:name(var_6_2.table_id))

				var_6_1:handleRewards(arg_7_1.awards)
			end
		end, var_6_2)
	else
		arg_6_0:onItemClicked()
	end
end

function var_0_0.registerTouchEvent(arg_8_0)
	arg_8_0:contentView():setTouchEnabled(true)
	arg_8_0:contentView():setTouchSwallowEnabled(false)

	local var_8_0 = arg_8_0.container
	local var_8_1 = {
		id = arg_8_0.tableID,
		type = arg_8_0.type,
		mission = arg_8_0.mission
	}

	arg_8_0:contentView():addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			arg_8_0:contentView():nodeByName("container"):setScale(0.9)

			arg_8_0.prevX_ = arg_9_0.x
			arg_8_0.prevY_ = arg_9_0.y
			arg_8_0.startClick_ = true
		elseif arg_9_0.name == "moved" then
			if math.abs(arg_9_0.y - arg_8_0.prevY_) > 10 or math.abs(arg_9_0.x - arg_8_0.prevX_) > 20 then
				arg_8_0.startClick_ = false

				arg_8_0:contentView():nodeByName("container"):setScale(1)
			end
		elseif arg_9_0.name == "ended" and arg_8_0.startClick_ then
			if xyd.WindowManager.get():isWindowOpen("guide") then
				xyd.WindowManager.get():closeWindow("guide")
			end

			if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_MISSION_ONE then
				xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_TWO)
			end

			arg_8_0:contentView():nodeByName("container"):setScale(1)

			local var_9_0 = var_8_0:convertToNodeSpace(cc.p(arg_9_0.x, arg_9_0.y))

			arg_8_0:itemHandler(var_0_3, arg_8_0, arg_9_0, var_8_1)
		end

		return true
	end)
end

function var_0_0.onItemClicked(arg_10_0)
	local var_10_0 = arg_10_0.tableID

	if arg_10_0.tableID == xyd.MissionIDs.DAILY.RANDOM_TASK and arg_10_0.goal then
		var_10_0 = arg_10_0.goal
	end

	local var_10_1 = arg_10_0.container
	local var_10_2 = xyd.tables.mission
	local var_10_3 = var_10_2:goto_type(var_10_0)
	local var_10_4 = var_10_2:task_req(var_10_0)

	audio.playSound("sound/button.ogg", false)
	arg_10_0:contentView():nodeByName("container"):setScale(1)

	if var_10_0 == xyd.MissionIDs.DAILY.CRYSTAL_TO_GOLD then
		xyd.WindowManager.get():openWindow("golden_hand")
	elseif var_10_0 == xyd.MissionIDs.DAILY.CAMPAIGN_COUNT then
		arg_10_0.guild:loadGuildMap(function(arg_11_0)
			xyd.WindowManager.get():openWindow("map_window", {
				chapter_type = 1
			})
		end)
	elseif var_10_0 == xyd.MissionIDs.DAILY.SUPER_CAMPAIGN_COUNT then
		arg_10_0.guild:loadGuildMap(function(arg_12_0)
			xyd.WindowManager.get():openWindow("map_window", {
				chapter_type = 2
			})
		end)
	elseif var_10_0 == xyd.MissionIDs.DAILY.TIME_CAVE_COUNT then
		xyd.WindowManager.get():openWindow("time_trial")
	elseif var_10_0 == xyd.MissionIDs.DAILY.EXERCISE_COUNT then
		xyd.WindowManager.get():openWindow("trial")
	elseif var_10_0 == xyd.MissionIDs.DAILY.MARCH_COUNT then
		xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH):loadMarchInfo({}, function(arg_13_0)
			if arg_13_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("march")
			end
		end)
	elseif var_10_0 == xyd.MissionIDs.DAILY.ARENA_BATTLE_COUNT then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_14_0, arg_14_1)
			if arg_14_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("arena")
			end
		end)
	elseif var_10_0 == xyd.MissionIDs.DAILY.SKILL_UP_COUNT then
		arg_10_0.selfPlayer:loadHeros({}, function()
			xyd.WindowManager.get():openWindow(xyd.WindowName.heroCollectWnd)
		end)
	elseif var_10_0 == xyd.MissionIDs.DAILY.RUNE_POWERUP then
		xyd.WindowManager.get():openWindow("fumo")
	elseif var_10_0 == xyd.MissionIDs.DAILY.RUN_SUMMON then
		arg_10_0.selfPlayer:loadSummonInfo({}, function()
			xyd.WindowManager.get():openWindow("summon")
		end)
	elseif var_10_0 == xyd.MissionIDs.DAILY.MONTH_CARD then
		xyd.WindowManager.get():openWindow("vip_recharge")
	elseif var_10_0 == xyd.MissionIDs.DAILY.WEEK_CARD then
		xyd.WindowManager.get():openWindow("vip_recharge")
	elseif var_10_0 == xyd.MissionIDs.DAILY.ENERGY_MONTH_CARD then
		xyd.WindowManager.get():openWindow("vip_recharge")
	elseif var_10_0 == xyd.MissionIDs.DAILY.PRIVILEGE_MONTH_CARD then
		local var_10_5 = {}

		var_10_5.windowState = true
		var_10_5.chargeState = xyd.ChargeState.monthlyPrivilege

		xyd.WindowManager.get():openWindow("vip_recharge", var_10_5)
	elseif var_10_0 == xyd.MissionIDs.DAILY.TREASURE then
		xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE):loadTreasureInfo(function(arg_17_0, arg_17_1)
			if arg_17_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("treasure_window")
			end
		end)
	elseif var_10_0 == xyd.MissionIDs.DAILY.ACTIVITY_UNLIMIT_CHALLENGE then
		xyd.WindowManager.get():openWindow("unlimitchallenge")
	elseif var_10_0 == xyd.MissionIDs.DAILY.SKY then
		xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN):getCampaignInfo(function(arg_18_0)
			if arg_18_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("pet_campaign")
			end
		end)
	elseif var_10_0 == xyd.MissionIDs.DAILY.HAOGAN then
		xyd.WindowManager.get():openWindow("tujian_hero")
	elseif var_10_0 == xyd.MissionIDs.DAILY.TEA_TALK then
		xyd.playButtonSound()
		arg_10_0.guild:getTeaTalkInfo(function(arg_19_0, arg_19_1)
			if arg_19_0 == xyd.error.OK then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.DRINK_NOTIF
				})
				xyd.WindowManager.get():openWindow("team_tea_talk")
			else
				local var_19_0 = var_0_1:translation("HAS_NOT_JOIN_GUILD")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_19_0
				})
			end
		end)
	elseif var_10_0 == xyd.MissionIDs.DAILY.TIMETRAVEL then
		xyd.WindowManager.get():openWindow("time_travel")
	elseif var_10_3 == 11 then
		local var_10_6 = var_10_2:goto_value(arg_10_0.tableID)
		local var_10_7 = {
			isStoneCampaign = true,
			chapter = xyd.tables.campaign:chapter(var_10_6),
			campaignID = var_10_6
		}
		local var_10_8 = 2
		local var_10_9 = 1

		if xyd.tables.campaign:campaignType(var_10_6) == var_10_8 or xyd.tables.campaign:campaignType(var_10_6) == var_10_9 then
			var_10_7.campaignType = xyd.CampaignType.NORMAL
		else
			var_10_7.campaignType = xyd.CampaignType.SUPER
		end

		arg_10_0.guild:loadGuildMap(function(arg_20_0)
			xyd.WindowManager.get():openWindow("map_window", var_10_7)
		end)

		local var_10_10 = xyd.WindowManager.get():getWindow("map_window")

		if var_10_10 and xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_MISSION_END then
			var_10_10:playGuide()
		end
	elseif var_10_3 == 14 then
		local var_10_11 = arg_10_0.selfPlayer.normal_chapter_id
		local var_10_12 = arg_10_0.guild:getMinchapterID()

		arg_10_0.guild:loadGuildMap(function(arg_21_0)
			if arg_21_0 == xyd.error.OK then
				var_10_12 = arg_10_0.guild:getMinchapterID()

				if var_10_11 < var_10_12 then
					local var_21_0 = var_0_1:translation("NORMAL_MAP_ALERT")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_21_0
					})

					return
				elseif arg_10_0.selfPlayer.lev < xyd.tables.teamCampaign:openLevByChapter(var_10_12) then
					local var_21_1 = var_0_1:translation("GUILD_CAMPAIGN_CANNOT_TIP2")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_21_1
					})

					return
				else
					local var_21_2 = {
						chapter_type = xyd.CampaignType.GUILD
					}

					xyd.WindowManager.get():openWindow("map_window", var_21_2)
				end
			else
				local var_21_3 = var_0_1:translation("JOIN_GUILD_TIP")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_21_3
				})
			end
		end)
	elseif var_10_3 == 15 then
		arg_10_0.guild:loadSelfGuild(function(arg_22_0)
			if arg_22_0 == xyd.error.OK then
				if arg_10_0.guild.guild_id == nil or arg_10_0.guild.guild_id == 0 then
					xyd.WindowManager.get():openWindow("team_main")
				else
					xyd.WindowManager.get():openWindow("team")
					arg_10_0.guild:loadSentHeros(function(arg_23_0)
						if arg_23_0 == xyd.error.OK then
							arg_10_0.guild:loadRentPets(function(arg_24_0)
								if arg_24_0 == xyd.error.OK then
									local var_24_0 = xyd.WindowManager.get():openWindow("hire_hero")
								end
							end)
						end
					end)
				end
			end
		end)
	elseif var_10_3 == 24 then
		xyd.WindowManager.get():openWindow("pet_collect")
	elseif var_10_4 == xyd.TaskReq.CENTER_ACTIVITY_UPGRADE then
		local var_10_13 = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

		var_10_13:getBuildingList({}, function(arg_25_0)
			if arg_25_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("event_centre")

				if var_10_3 == xyd.EventCentreBuildingType.CABINET then
					var_10_13:getCabinetInfo(function(arg_26_0, arg_26_1)
						if arg_26_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("junk_chest")
						end
					end)
				elseif var_10_3 == xyd.EventCentreBuildingType.DESK then
					var_10_13:getDeskpInfo({}, function(arg_27_0, arg_27_1)
						if arg_27_0 == xyd.error.OK then
							local var_27_0 = {
								deskInfo = arg_27_1
							}

							xyd.WindowManager.get():openWindow("production_table", var_27_0)
						end
					end)
				elseif var_10_3 == xyd.EventCentreBuildingType.TRASH then
					var_10_13:getRecycleInfo({}, function(arg_28_0, arg_28_1)
						if arg_28_0 == xyd.error.OK then
							local var_28_0 = {
								recycleInfo = arg_28_1
							}

							xyd.WindowManager.get():openWindow("recycle", var_28_0)
						end
					end)
				end
			end
		end)
	elseif var_10_4 == xyd.TaskReq.CENTER_ACTIVITY_MISSION then
		local var_10_14 = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

		var_10_14:getBuildingList({}, function(arg_29_0)
			if arg_29_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("event_centre")
				var_10_14:getCabinetInfo(function(arg_30_0, arg_30_1)
					if arg_30_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("junk_chest")
					end
				end)
			end
		end)
	end
end

function var_0_0.setItemBg(arg_31_0)
	if arg_31_0.mission.isComplete then
		arg_31_0.container:getChildByName("item_bg"):setVisible(false)
		arg_31_0.container:getChildByName("item_bg2"):setVisible(true)
		arg_31_0.container:getChildByName("progress"):setVisible(false)
	else
		local var_31_0 = arg_31_0.tableID

		if arg_31_0.tableID == xyd.MissionIDs.DAILY.RANDOM_TASK and arg_31_0.goal then
			var_31_0 = arg_31_0.goal
		end

		arg_31_0.container:getChildByName("item_bg2"):setVisible(false)
		arg_31_0.container:getChildByName("item_bg"):setVisible(true)

		if var_31_0 == xyd.MissionIDs.DAILY.LUNCH or var_31_0 == xyd.MissionIDs.DAILY.DINNER or var_31_0 == xyd.MissionIDs.DAILY.LATE_SUPPER or var_31_0 == xyd.MissionIDs.DAILY.ACTIVITY_BREADFAST or var_31_0 == xyd.MissionIDs.DAILY.ACTIVITY_LUNCH or var_31_0 == xyd.MissionIDs.DAILY.ACTIVITY_DINNER or var_31_0 == xyd.MissionIDs.DAILY.ACTIVITY_LATE_SUPPER then
			arg_31_0.container:getChildByName("progress"):setString(string.format("%s", xyd.tables.translation:translation("TIME_TOO_EARLY")))
		elseif table.contains(xyd.MissionIDs.MISSION.PLAYER_LEVEL, var_31_0) or table.contains(xyd.MissionIDs.MISSION.PLAYER_LEVEL_BIG, var_31_0) then
			arg_31_0.container:getChildByName("progress"):setString(string.format("%d/%d", arg_31_0.selfPlayer.lev, xyd.tables.mission:task_num(var_31_0)))
		elseif var_31_0 == xyd.MissionIDs.DAILY.MONTH_CARD then
			if arg_31_0.selfPlayer.leftCardDay <= 0 then
				arg_31_0.container:getChildByName("progress"):setString(string.format("%s", xyd.tables.translation:translation("NOT_BUY")))
			else
				arg_31_0.container:getChildByName("progress"):setString(string.format(xyd.tables.translation:translation("CARD_LEFT"), arg_31_0.selfPlayer.leftCardDay))
			end
		elseif var_31_0 == xyd.MissionIDs.DAILY.WEEK_CARD then
			if arg_31_0.selfPlayer.leftWeekCardDay <= 0 then
				arg_31_0.container:getChildByName("progress"):setString(string.format("%s", xyd.tables.translation:translation("NOT_BUY")))
			else
				arg_31_0.container:getChildByName("progress"):setString(string.format(xyd.tables.translation:translation("CARD_LEFT"), arg_31_0.selfPlayer.leftWeekCardDay))
			end
		elseif var_31_0 == xyd.MissionIDs.DAILY.ENERGY_MONTH_CARD then
			if arg_31_0.selfPlayer.leftEnergyMonthCardDay <= 0 then
				arg_31_0.container:getChildByName("progress"):setString(string.format("%s", xyd.tables.translation:translation("NOT_BUY")))
			else
				arg_31_0.container:getChildByName("progress"):setString(string.format(xyd.tables.translation:translation("CARD_LEFT"), arg_31_0.selfPlayer.leftEnergyMonthCardDay))
			end
		elseif var_31_0 == xyd.MissionIDs.DAILY.PRIVILEGE_MONTH_CARD then
			if arg_31_0.selfPlayer.leftEnergyMonthCardDay <= 0 then
				arg_31_0.container:getChildByName("progress"):setString(string.format("%s", xyd.tables.translation:translation("NOT_BUY")))
			else
				arg_31_0.container:getChildByName("progress"):setString(string.format(xyd.tables.translation:translation("CARD_LEFT"), arg_31_0.selfPlayer.privilegeLeftCardDay))
			end
		else
			arg_31_0.container:getChildByName("progress"):setString(string.format("%d/%d", arg_31_0.mission.count, xyd.tables.mission:task_num(var_31_0)))
		end

		arg_31_0.container:getChildByName("progress"):setVisible(true)
	end
end

local function var_0_4(arg_32_0, arg_32_1, arg_32_2, arg_32_3, arg_32_4)
	local var_32_0 = arg_32_0:getChildByName(arg_32_1)

	var_32_0:setVisible(true)

	local var_32_1 = arg_32_0:getChildByName(arg_32_2)

	var_32_1:setVisible(true)
	var_32_1:setString("x" .. arg_32_3)

	if arg_32_4 > 0 then
		local var_32_2, var_32_3 = var_32_0:getPosition()
		local var_32_4, var_32_5 = var_32_1:getPosition()

		var_32_0:setPosition(cc.p(var_32_2 + arg_32_4, var_32_3))
		var_32_1:setPosition(cc.p(var_32_4 + arg_32_4, var_32_5))
	end
end

function var_0_0.setMissionAward(arg_33_0)
	local var_33_0 = arg_33_0.container
	local var_33_1 = arg_33_0.tableID

	var_33_0:getChildByName("diamond"):setVisible(false)
	var_33_0:getChildByName("small_bonus"):setVisible(false)
	var_33_0:getChildByName("power"):setVisible(false)
	var_33_0:getChildByName("award_icon"):setVisible(false)
	var_33_0:getChildByName("title"):setString(xyd.tables.mission:name(var_33_1))

	local var_33_2 = xyd.tables.mission:des(var_33_1)

	if var_33_1 == xyd.MissionIDs.DAILY.RANDOM_TASK and arg_33_0.goal then
		var_33_2 = xyd.tables.mission:des(arg_33_0.goal)
	end

	local var_33_3, var_33_4, var_33_5 = string.match(var_33_2, "(.*[^%d]+)(%d+)|(%d+)$")

	if var_33_3 and var_33_4 and var_33_5 then
		var_33_0:getChildByName("desc"):setString(string.format(xyd.tables.translation:translation("MISSION_DESC"), var_33_3, "《" .. xyd.tables.campaign:campaignName(tonumber(var_33_4)) .. "》", tonumber(var_33_5) or 1))
	else
		var_33_0:getChildByName("desc"):setString(var_33_2)
	end

	var_33_0:getChildByName("award_desc"):setString(xyd.tables.translation:translation("MISSION_TEXT"))

	local var_33_6 = 0
	local var_33_7 = xyd.tables.mission:exp(var_33_1)
	local var_33_8 = xyd.tables.mission:guildCoin(var_33_1)

	if arg_33_0.selfPlayer.vip >= xyd.tables.mission:vip(var_33_1) then
		local var_33_9 = var_33_8 + xyd.tables.mission:exCoin(var_33_1)
	end

	local var_33_10 = xyd.tables.mission:crystal(var_33_1)

	if var_33_1 == xyd.MissionIDs.DAILY.MONTH_CARD then
		var_33_10 = xyd.tables.mission:crystal(xyd.MissionIDs.DAILY.GET_CRYSTAL)
	end

	if var_33_10 > 0 then
		var_0_4(var_33_0, "diamond", "diamond_num", var_33_10, var_33_6)

		var_33_6 = var_33_6 + 80
	end

	local var_33_11 = xyd.tables.mission:medal(var_33_1)

	if var_33_1 == xyd.MissionIDs.DAILY.MONTH_CARD then
		var_33_11 = xyd.tables.mission:medal(xyd.MissionIDs.DAILY.GET_CRYSTAL)
	end

	if var_33_11 > 0 then
		var_0_4(var_33_0, "small_bonus", "medal_num", var_33_11, var_33_6)

		var_33_6 = var_33_6 + 80
	end

	local var_33_12 = xyd.tables.mission:award(var_33_1)
	local var_33_13

	if var_33_12 ~= "" and var_33_12 ~= "0" and var_33_12 ~= "0.0" then
		local var_33_14 = xyd.splitToNumber(var_33_12, "|")
		local var_33_15 = var_33_14[1]

		if #var_33_14 > 1 then
			if var_33_15 == 1 then
				local var_33_16 = var_33_14[2]

				var_0_4(var_33_0, "power", "power_num", var_33_16, var_33_6)

				var_33_6 = var_33_6 + 80
			end
		else
			local var_33_17 = xyd.tables.mission:award_num(var_33_1)

			if var_33_1 == xyd.MissionIDs.DAILY.GET_SWEEP_CARD then
				var_33_17 = xyd.tables.vip:sweepCard(arg_33_0.selfPlayer.vip)
			end

			if var_33_17 > 0 then
				var_0_4(var_33_0, "award_icon", "award_num", var_33_17, var_33_6)

				local var_33_18 = var_33_0:getChildByName("award_icon")

				xyd.setItemBorder(var_33_18, var_33_15)

				var_33_6 = var_33_6 + 80
				var_33_13 = var_33_15
			end
		end
	end

	if arg_33_0.mission.inscript_id and arg_33_0.mission.inscript_id > 0 then
		var_0_4(var_33_0, "award_icon", "award_num", 1, var_33_6)

		local var_33_19 = var_33_0:getChildByName("award_icon")

		xyd.setItemBorder(var_33_19, arg_33_0.mission.inscript_id)

		local var_33_20 = var_33_6 + 80
	end

	local var_33_21 = var_33_0:getChildByName("icon_container")
	local var_33_22 = xyd.tables.mission:icon(var_33_1)

	if var_33_22 == 0 or var_33_22 == "0.0" or var_33_22 == "0" then
		if arg_33_0.tableID == xyd.MissionIDs.DAILY.INSCRIPTION_FIRST or arg_33_0.tableID == xyd.MissionIDs.DAILY.INSCRIPTION_FINAL then
			xyd.setItemBorder(var_33_21, arg_33_0.mission.inscript_id)
			var_33_21:getChildByName("clipper"):setTouchEnabled(true)
			var_33_21:getChildByName("clipper"):setTouchSwallowEnabled(false)
			var_33_21:getChildByName("clipper"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_34_0)
				if arg_34_0.name == "began" then
					arg_33_0.prevX_ = arg_34_0.x
					arg_33_0.prevY_ = arg_34_0.y
					arg_33_0.iconStartClick_ = true
				elseif arg_34_0.name == "moved" then
					if math.abs(arg_34_0.y - arg_33_0.prevY_) > 10 or math.abs(arg_34_0.x - arg_33_0.prevX_) > 20 then
						arg_33_0.iconStartClick_ = false
					end
				elseif arg_34_0.name == "ended" and arg_33_0.iconStartClick_ then
					xyd.WindowManager.get():openWindow("equip_confirm", {
						inscript_id = arg_33_0.mission.inscript_id
					})
				end

				return true
			end)
		else
			xyd.setItemBorder(var_33_21, var_33_13)
		end
	else
		xyd.setSpriteBorder(var_33_21, var_33_22, 1)
	end
end

function var_0_0.contentView(arg_35_0)
	if arg_35_0.contentView_ == nil then
		arg_35_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_35_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/task/task_item_small.csb"))
		arg_35_0.contentView_:addTo(arg_35_0)
		arg_35_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_35_0.contentView_
end

function var_0_0.itemHandler(arg_36_0, arg_36_1, arg_36_2, arg_36_3, arg_36_4)
	arg_36_2:setLocalZOrder(0)

	if arg_36_3.name == "ended" then
		if not arg_36_2.scrollViewMoved_ then
			transition.scaleTo(arg_36_2, {
				scale = 1,
				time = 0.1
			})

			if arg_36_1 then
				arg_36_1(arg_36_2, arg_36_3, arg_36_4)
			end
		end
	elseif arg_36_3.name == "began" then
		transition.scaleTo(arg_36_2, {
			scale = 0.99,
			time = 0.1
		})
		arg_36_2:setLocalZOrder(5)
	elseif arg_36_3.name == "canceled" then
		transition.scaleTo(arg_36_2, {
			scale = 1,
			time = 0.1
		})
		arg_36_2:setLocalZOrder(0)
	end
end

return var_0_0
