local var_0_0 = class("TeamCampaignWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.job = arg_1_0.guild:getSelfJob()
	arg_1_0.campaignList = arg_1_0.guild:getGuildCampaignList()
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 10 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, 732, 448),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0:layout()
	arg_3_0:nodeByName("distribute_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("distribute_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0.guild:loadDistributeRecord(function(arg_5_0)
				if arg_5_0 == xyd.error.OK then
					local var_5_0 = {
						records = arg_3_0.guild:getDistriList()
					}

					xyd.WindowManager.get():openWindow("apply_record", var_5_0)
				end
			end)
		end
	end)
	arg_3_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("rule_btn"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = {
				title_name = "GUILD_ACTIVITY_TITLE",
				rule = "team_rule",
				style = xyd.RuleStyle.Yellow
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_6_0)
		end
	end)
	arg_3_0:nodeByName("distribute_text"):setString(var_0_1:translation("SHE_TUAN_TEXT_51"))
	arg_3_0:nodeByName("title"):setString(var_0_1:translation("SHE_TUAN_TEXT_52"))
end

function var_0_0.layout(arg_7_0)
	arg_7_0.list:removeAllItems()

	for iter_7_0 = 1, #arg_7_0.campaignList do
		local var_7_0 = display.newNode()
		local var_7_1 = arg_7_0.list:newItem()
		local var_7_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_campaign_list/campaign_item.csb")
		local var_7_3 = var_7_2:getChildByName("container")
		local var_7_4 = var_7_3:getChildByName("count_time_txt")

		var_7_4:getChildByName("zai"):setString(var_0_1:translation("AT"))
		var_7_4:getChildByName("count_time_desc"):setString(var_0_1:translation("MAY_GET_AWARD_BY_DONE"))
		arg_7_0:initItem(var_7_3, iter_7_0)
		var_7_0:addChild(var_7_2)

		local var_7_5 = var_7_3:getContentSize().width
		local var_7_6 = var_7_3:getContentSize().height

		var_7_0:setContentSize(var_7_5, var_7_6)
		var_7_1:addContent(var_7_0)
		var_7_1:setItemSize(var_7_5, var_7_6)
		arg_7_0.list:addItem(var_7_1)
	end

	arg_7_0.list:reload()
end

function var_0_0.initItem(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_0.campaignList[arg_8_2]
	local var_8_1 = xyd.ServerTime.get():getServerTime()
	local var_8_2 = xyd.tables.teamDungeonSelect:headPortrait(tonumber(var_8_0.chapter_id))
	local var_8_3 = xyd.tables.teamDungeonSelect:chapterName(tonumber(var_8_0.chapter_id))
	local var_8_4 = string.format(var_0_1:translation("TEAM_CHAPTER"), tonumber(var_8_0.chapter_id)) .. " " .. var_8_3
	local var_8_5 = xyd.tables.teamDungeonSelect:additionReward(tonumber(var_8_0.chapter_id))
	local var_8_6 = 0

	if var_8_0.end_time and var_8_0.end_time > 0 then
		var_8_6 = var_8_0.end_time - var_8_0.start_time
	else
		var_8_6 = var_8_1 - var_8_0.start_time
	end

	arg_8_1:getChildByName("count_time_txt"):getChildByName("zai"):setString(var_0_1:translation("TEAM_CAMPAIGN_DES_1"))
	arg_8_1:getChildByName("count_time_txt"):getChildByName("count_time_desc"):setString(var_0_1:translation("TEAM_CAMPAIGN_DES_2"))
	arg_8_1:getChildByName("multi_btn_1"):getChildByName("txt_go"):setString(var_0_1:translation("SHE_TUAN_TEXT_53"))
	arg_8_1:getChildByName("multi_btn_2"):getChildByName("txt_reset"):setString(var_0_1:translation("SHE_TUAN_TEXT_54"))
	xyd.setItemBorder(arg_8_1:getChildByName("avatar"), var_8_2)
	arg_8_1:getChildByName("chapter_name"):setString(var_8_4)

	if arg_8_0.job == 0 then
		arg_8_1:getChildByName("go_btn"):getChildByName("open_campaign_txt"):setVisible(false)
		arg_8_1:getChildByName("go_btn"):setVisible(true)
		arg_8_1:getChildByName("multi_btn_1"):setVisible(false)
		arg_8_1:getChildByName("multi_btn_2"):setVisible(false)

		if var_8_0.is_open == 1 then
			arg_8_1:getChildByName("zhezhao"):setVisible(false)
			arg_8_1:getChildByName("campaign_progress"):setPercent(var_8_0.percent * 100)
			arg_8_1:getChildByName("progress_txt"):setString(math.floor(var_8_0.percent * 100) .. "%")

			if var_8_0.percent == 1 then
				if var_8_6 <= 604800 then
					arg_8_1:getChildByName("guild_coin"):setVisible(true)
					arg_8_1:getChildByName("count_time_txt"):setVisible(false)
					arg_8_1:getChildByName("guild_coin"):getChildByName("guild_coin_num"):setString(var_8_5)
				else
					arg_8_1:getChildByName("guild_coin"):setVisible(false)
					arg_8_1:getChildByName("count_time_txt"):setVisible(false)
				end
			elseif var_8_6 <= 604800 then
				arg_8_1:getChildByName("guild_coin"):setVisible(false)
				arg_8_1:getChildByName("count_time_txt"):setVisible(true)

				local var_8_7 = 604800 - var_8_6
				local var_8_8 = math.floor(var_8_7 / 86400)
				local var_8_9 = math.floor(var_8_7 % 86400 / 3600)

				if var_8_9 < 10 then
					var_8_9 = "0" .. var_8_9
				end

				local var_8_10 = var_8_8 .. var_0_1:translation("UNIT_DAY") .. var_8_9 .. var_0_1:translation("UNIT_HOUR")

				arg_8_1:getChildByName("count_time_txt"):setString(var_8_10)
			else
				arg_8_1:getChildByName("guild_coin"):setVisible(false)
				arg_8_1:getChildByName("count_time_txt"):setVisible(false)
			end

			arg_8_1:getChildByName("go_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
				xyd.buttonScaleAnim(arg_8_1:getChildByName("go_btn"), arg_9_1)

				if arg_9_1 == ccui.TouchEventType.ended then
					if arg_8_0.selfPlayer.normal_chapter_id < arg_8_0.campaignList[arg_8_2].chapter_id then
						local var_9_0 = var_0_1:translation("NORMAL_MAP_ALERT")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_9_0
						})

						return
					elseif arg_8_0.selfPlayer.lev < xyd.tables.teamCampaign:openLevByChapter(arg_8_0.campaignList[arg_8_2].chapter_id) then
						local var_9_1 = var_0_1:translation("GUILD_CAMPAIGN_CANNOT_TIP2")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_9_1
						})

						return
					else
						arg_8_0.guild:loadGuildMap(function(arg_10_0, arg_10_1)
							if arg_10_0 == xyd.error.OK then
								local var_10_0 = {
									chapter_type = xyd.CampaignType.GUILD,
									guildChapter = arg_8_0.campaignList[arg_8_2].chapter_id
								}

								xyd.WindowManager.get():openWindow("map_window", var_10_0)
							end
						end)
					end
				end
			end)
		else
			arg_8_1:getChildByName("zhezhao"):setVisible(true)
			arg_8_1:getChildByName("campaign_progress"):setPercent(0)
			arg_8_1:getChildByName("progress_txt"):setString(var_0_1:translation("GUILD_CHAPTER_NOT_OPEN"))
			arg_8_1:getChildByName("go_btn"):setVisible(false)
			arg_8_1:getChildByName("guild_coin"):setVisible(false)
			arg_8_1:getChildByName("count_time_txt"):setVisible(false)
		end
	elseif arg_8_0.job == 1 or arg_8_0.job == 2 then
		arg_8_1:getChildByName("go_btn"):setVisible(false)
		arg_8_1:getChildByName("multi_btn_1"):setVisible(true)
		arg_8_1:getChildByName("multi_btn_2"):setVisible(true)

		if var_8_0.is_open == 1 then
			arg_8_1:getChildByName("zhezhao"):setVisible(false)
			arg_8_1:getChildByName("campaign_progress"):setPercent(var_8_0.percent * 100)
			arg_8_1:getChildByName("progress_txt"):setString(math.floor(var_8_0.percent * 100) .. "%")

			if var_8_0.percent == 1 then
				if var_8_6 <= 604800 then
					arg_8_1:getChildByName("guild_coin"):setVisible(true)
					arg_8_1:getChildByName("count_time_txt"):setVisible(false)
					arg_8_1:getChildByName("go_btn"):setVisible(false)
					arg_8_1:getChildByName("multi_btn_1"):setVisible(true)
					arg_8_1:getChildByName("multi_btn_2"):setVisible(true)
					arg_8_1:getChildByName("guild_coin"):getChildByName("guild_coin_num"):setString(var_8_5)
				else
					arg_8_1:getChildByName("guild_coin"):setVisible(false)
					arg_8_1:getChildByName("count_time_txt"):setVisible(false)
					arg_8_1:getChildByName("go_btn"):setVisible(false)
					arg_8_1:getChildByName("multi_btn_1"):setVisible(true)
					arg_8_1:getChildByName("multi_btn_2"):setVisible(true)
				end
			elseif var_8_6 <= 604800 then
				arg_8_1:getChildByName("guild_coin"):setVisible(false)
				arg_8_1:getChildByName("count_time_txt"):setVisible(true)
				arg_8_1:getChildByName("go_btn"):setVisible(false)
				arg_8_1:getChildByName("multi_btn_1"):setVisible(true)
				arg_8_1:getChildByName("multi_btn_2"):setVisible(true)

				local var_8_11 = 604800 - var_8_6
				local var_8_12 = math.floor(var_8_11 / 86400)
				local var_8_13 = math.floor(var_8_11 % 86400 / 3600)

				if var_8_13 < 10 then
					var_8_13 = "0" .. var_8_13
				end

				local var_8_14 = var_8_12 .. var_0_1:translation("UNIT_DAY") .. var_8_13 .. var_0_1:translation("UNIT_HOUR")

				arg_8_1:getChildByName("count_time_txt"):setString(var_8_14)
			else
				arg_8_1:getChildByName("guild_coin"):setVisible(false)
				arg_8_1:getChildByName("count_time_txt"):setVisible(false)
				arg_8_1:getChildByName("go_btn"):setVisible(false)
				arg_8_1:getChildByName("multi_btn_1"):setVisible(true)
				arg_8_1:getChildByName("multi_btn_2"):setVisible(true)
			end

			arg_8_1:getChildByName("multi_btn_1"):addTouchEventListener(function(arg_11_0, arg_11_1)
				xyd.buttonScaleAnim(arg_8_1:getChildByName("multi_btn_1"), arg_11_1)

				if arg_11_1 == ccui.TouchEventType.ended then
					if arg_8_0.selfPlayer.normal_chapter_id < arg_8_0.campaignList[arg_8_2].chapter_id then
						local var_11_0 = var_0_1:translation("NORMAL_MAP_ALERT")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_11_0
						})

						return
					elseif arg_8_0.selfPlayer.lev < xyd.tables.teamCampaign:openLevByChapter(arg_8_0.campaignList[arg_8_2].chapter_id) then
						local var_11_1 = var_0_1:translation("GUILD_CAMPAIGN_CANNOT_TIP2")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_11_1
						})

						return
					else
						arg_8_0.guild:loadGuildMap(function(arg_12_0, arg_12_1)
							if arg_12_0 == xyd.error.OK then
								local var_12_0 = {
									chapter_type = xyd.CampaignType.GUILD,
									guildChapter = arg_8_0.campaignList[arg_8_2].chapter_id
								}

								xyd.WindowManager.get():openWindow("map_window", var_12_0)
								xyd.WindowManager.get():closeWindow(arg_8_0.name)
							end
						end)
					end
				end
			end)
			arg_8_1:getChildByName("multi_btn_2"):addTouchEventListener(function(arg_13_0, arg_13_1)
				xyd.buttonScaleAnim(arg_8_1:getChildByName("multi_btn_2"), arg_13_1)

				if arg_13_1 == ccui.TouchEventType.ended then
					arg_8_0.guild:loadSelfGuild(function(arg_14_0)
						if arg_14_0 == xyd.error.OK then
							local var_14_0 = arg_8_0.guild:getGuildHuoyue()
							local var_14_1 = xyd.tables.teamDungeonSelect:dungeonOpen(arg_8_0.campaignList[arg_8_2].chapter_id)

							if var_14_1 > arg_8_0.guild:getGuildHuoyue() then
								local var_14_2 = string.format(var_0_1:translation("OPEN_GUILD_CHAPTER_TIP2"), var_14_1)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_14_2
								})

								return
							end

							local var_14_3 = {
								var_0_1:translation("GUILD_RESET_CHAPTER_TIP1"),
								string.format(var_0_1:translation("GUILD_RESET_CHAPTER_TIP2"), arg_8_0.campaignList[arg_8_2].percent * 100) .. "%",
								string.format(var_0_1:translation("GUILD_RESET_CHAPTER_TIP3"), var_14_1),
								(string.format(var_0_1:translation("GUILD_RESET_CHAPTER_TIP4"), var_14_0))
							}

							var_14_3[5] = " "
							var_14_3[6] = var_0_1:translation("GUILD_RESET_CHAPTER_TIP5")

							if arg_8_0.campaignList[arg_8_2].percent == 0 then
								local var_14_4 = var_0_1:translation("TEAM_DUNGEON_RESET_TEXT3")

								xyd.WindowManager.get():openWindow("toast", {
									message = var_14_4
								})
							else
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_3, function(arg_15_0)
									local var_15_0 = {
										chapter_id = arg_8_0.campaignList[arg_8_2].chapter_id
									}

									arg_8_0.guild:resetGuildChapter(var_15_0, function(arg_16_0, arg_16_1)
										if arg_16_0 == xyd.error.OK then
											local var_16_0 = xyd.WindowManager.get():getWindow("team_campaign_list")

											if var_16_0 then
												var_16_0.campaignList = arg_8_0.guild:getGuildCampaignList()

												var_16_0:layout()
											end

											local var_16_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
											local var_16_2 = xyd.tables.shop:teamDungeonHomologousIds()
											local var_16_3

											for iter_16_0, iter_16_1 in ipairs(var_16_2) do
												if iter_16_1 == arg_8_0.campaignList[arg_8_2].chapter_id then
													var_16_3 = iter_16_0
												end
											end

											if var_16_1.statuses_[var_16_3] then
												var_16_1.statuses_[var_16_3].loaded = false
											end

											var_16_1:loadShopInfo({
												shop_type = var_16_3
											}, function(...)
												return
											end)
											xyd.WindowManager.get():closeWindow(arg_8_0.name)
										end
									end)
								end, {
									title = var_0_1:translation("TIP")
								}, 0, xyd.ColorMode.YELLOW)
							end
						end
					end)
				end
			end)
		elseif not arg_8_0.campaignList[arg_8_2 - 1] or arg_8_0.campaignList[arg_8_2 - 1].is_open == 1 and arg_8_0.campaignList[arg_8_2 - 1].have_win == 1 then
			arg_8_1:getChildByName("zhezhao"):setVisible(false)
			arg_8_1:getChildByName("go_btn"):setVisible(true)
			arg_8_1:getChildByName("multi_btn_1"):setVisible(false)
			arg_8_1:getChildByName("multi_btn_2"):setVisible(false)
			arg_8_1:getChildByName("go_btn"):getChildByName("open_campaign_txt"):setVisible(true)
			arg_8_1:getChildByName("go_btn"):getChildByName("go_txt"):setVisible(false)
			arg_8_1:getChildByName("campaign_progress"):setPercent(0)
			arg_8_1:getChildByName("progress_txt"):setString(var_0_1:translation("GUILD_CHAPTER_NOT_OPEN"))
			arg_8_1:getChildByName("guild_coin"):setVisible(false)
			arg_8_1:getChildByName("count_time_txt"):setVisible(false)
			arg_8_1:getChildByName("go_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
				xyd.buttonScaleAnim(arg_8_1:getChildByName("go_btn"), arg_18_1)

				if arg_18_1 == ccui.TouchEventType.ended then
					if xyd.tables.teamCampaign:openLevByChapter(arg_8_0.campaignList[arg_8_2].chapter_id) == -1 then
						local var_18_0 = var_0_1:translation("MAP_CHAPTER_NOT_OPEN")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_18_0
						})

						return
					end

					local var_18_1 = xyd.tables.teamDungeonSelect:dungeonOpen(arg_8_0.campaignList[arg_8_2].chapter_id)
					local var_18_2 = arg_8_0.guild:getGuildHuoyue()

					if var_18_1 > arg_8_0.guild:getGuildHuoyue() then
						local var_18_3 = string.format(var_0_1:translation("OPEN_GUILD_CHAPTER_TIP"), var_18_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_18_3
						})
					else
						local var_18_4 = {
							string.format(var_0_1:translation("GUILD_RESET_CHAPTER_TIP6"), var_18_1),
							string.format(var_0_1:translation("GUILD_RESET_CHAPTER_TIP4"), var_18_2),
							(string.format(var_0_1:translation("GUILD_RESET_CHAPTER_TIP7")))
						}

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_18_4, function()
							local var_19_0 = {
								chapter_id = arg_8_0.campaignList[arg_8_2].chapter_id
							}

							arg_8_0.guild:openGuildChapter(var_19_0, function(arg_20_0)
								if arg_20_0 == xyd.error.OK then
									arg_8_0.campaignList = arg_8_0.guild:getGuildCampaignList()

									arg_8_0:initItem(arg_8_1, arg_8_2)
								end
							end)
						end, nil, 0, xyd.ColorMode.YELLOW)
					end
				end
			end)
		else
			arg_8_1:getChildByName("zhezhao"):setVisible(true)
			arg_8_1:getChildByName("campaign_progress"):setPercent(0)
			arg_8_1:getChildByName("progress_txt"):setString(var_0_1:translation("GUILD_CHAPTER_NOT_OPEN"))
			arg_8_1:getChildByName("go_btn"):setVisible(false)
			arg_8_1:getChildByName("multi_btn_1"):setVisible(false)
			arg_8_1:getChildByName("multi_btn_2"):setVisible(false)
			arg_8_1:getChildByName("guild_coin"):setVisible(false)
			arg_8_1:getChildByName("count_time_txt"):setVisible(false)
		end
	end

	local var_8_15 = display.newNode()

	var_8_15:setContentSize(500, 140)
	var_8_15:setPosition(arg_8_1:getChildByName("click_node"):getPosition())
	var_8_15:addTo(arg_8_1)
	var_8_15:setTouchEnabled(true)
	var_8_15:setTouchSwallowEnabled(false)
	var_8_15:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
		if arg_21_0.name == "began" then
			return true
		elseif arg_21_0.name == "ended" and not arg_8_0.scrollViewMoved_ then
			local var_21_0 = {
				chapter_id = tonumber(var_8_0.chapter_id)
			}

			xyd.WindowManager.get():openWindow("may_drop_item", var_21_0)
		end
	end)
end

function var_0_0.didOpen(arg_22_0, arg_22_1)
	var_0_0.super:didOpen(arg_22_1)
	arg_22_0:addBlockLayer()
end

return var_0_0
