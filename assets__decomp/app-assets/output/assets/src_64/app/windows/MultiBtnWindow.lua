local var_0_0 = class("MultiBtnWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.percent = arg_1_2.percent
	arg_1_0.chapterID = arg_1_2.chapterID
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:nodeByName("go_txt"):setString(var_0_1:translation("SHE_TUAN_TEXT_53"))
	arg_2_0:nodeByName("reset_btn_txt"):setString(var_0_1:translation("SHE_TUAN_TEXT_54"))
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.guild

	arg_3_0:nodeByName("reset_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("reset_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0.guild:loadSelfGuild(function(arg_5_0)
				if arg_5_0 == xyd.error.OK then
					local var_5_0 = arg_3_0.guild:getGuildHuoyue()
					local var_5_1 = xyd.tables.teamDungeonSelect:dungeonOpen(arg_3_0.chapterID)

					if var_5_1 > arg_3_0.guild:getGuildHuoyue() then
						local var_5_2 = string.format(var_0_1:translation("OPEN_GUILD_CHAPTER_TIP2"), var_5_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_5_2
						})

						return
					end

					local var_5_3 = {
						var_0_1:translation("GUILD_RESET_CHAPTER_TIP1"),
						string.format(var_0_1:translation("GUILD_RESET_CHAPTER_TIP2"), arg_3_0.percent * 100) .. "%",
						string.format(var_0_1:translation("GUILD_RESET_CHAPTER_TIP3"), var_5_1),
						(string.format(var_0_1:translation("GUILD_RESET_CHAPTER_TIP4"), var_5_0))
					}

					var_5_3[5] = " "
					var_5_3[6] = var_0_1:translation("GUILD_RESET_CHAPTER_TIP5")

					if arg_3_0.percent == 0 then
						local var_5_4 = var_0_1:translation("TEAM_DUNGEON_RESET_TEXT3")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_5_4
						})
					else
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_3, function(arg_6_0)
							local var_6_0 = {
								chapter_id = arg_3_0.chapterID
							}

							arg_3_0.guild:resetGuildChapter(var_6_0, function(arg_7_0, arg_7_1)
								if arg_7_0 == xyd.error.OK then
									local var_7_0 = xyd.WindowManager.get():getWindow("team_campaign_list")

									if var_7_0 then
										var_7_0.campaignList = arg_3_0.guild:getGuildCampaignList()

										var_7_0:layout()
									end

									local var_7_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
									local var_7_2 = xyd.tables.shop:teamDungeonHomologousIds()
									local var_7_3

									for iter_7_0, iter_7_1 in ipairs(var_7_2) do
										if iter_7_1 == arg_3_0.chapterID then
											var_7_3 = iter_7_0
										end
									end

									if var_7_1.statuses_[var_7_3] then
										var_7_1.statuses_[var_7_3].loaded = false
									end

									var_7_1:loadShopInfo({
										shop_type = var_7_3
									}, function(...)
										return
									end)
									xyd.WindowManager.get():closeWindow(arg_3_0.name)
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
	arg_3_0:nodeByName("go_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("go_btn"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_3_0.selfPlayer.normal_chapter_id < arg_3_0.chapterID then
				local var_9_0 = var_0_1:translation("NORMAL_MAP_ALERT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_0
				})

				return
			elseif arg_3_0.selfPlayer.lev < xyd.tables.teamCampaign:openLevByChapter(arg_3_0.chapterID) then
				local var_9_1 = var_0_1:translation("GUILD_CAMPAIGN_CANNOT_TIP2")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_1
				})

				return
			else
				arg_3_0.guild:loadGuildMap(function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						local var_10_0 = {
							chapter_type = xyd.CampaignType.GUILD,
							guildChapter = arg_3_0.chapterID
						}

						xyd.WindowManager.get():openWindow("map_window", var_10_0)
						xyd.WindowManager.get():closeWindow(arg_3_0.name)
					end
				end)
			end
		end
	end)
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
	arg_11_0:addBlockLayer()
end

return var_0_0
