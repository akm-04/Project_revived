local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = "skeletons/ui_effect/activity_party/activity_party_choose_light"
local var_0_4 = "skeletons/ui_effect/activity_party/activity_party_chest"
local var_0_5 = import("app.model.Hero")
local var_0_6 = xyd.tables.activityPartyMission
local var_0_7 = xyd.tables.activityPartyTimeline
local var_0_8 = {
	Sub = 2,
	Main = 1
}
local var_0_9 = {
	Star = 1,
	GetHero = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.showType = var_0_8.Main
	arg_1_0.missionType = var_0_9.Star

	if not arg_1_0.details.mission_list then
		arg_1_0.details.mission_list = {}
	end

	if not arg_1_0.details.base_info.stars then
		arg_1_0.details.base_info.stars = 0
	end

	if not arg_1_0.details.hero_stars then
		arg_1_0.details.hero_stars = {}
	end
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")
		arg_2_0.mainContainer = arg_2_0.container:getChildByName("main_container")
		arg_2_0.subContainer = arg_2_0.container:getChildByName("sub_container")

		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(0, 0)

		arg_2_0.scroll = arg_2_0.subContainer:getChildByName("scroll")

		local var_2_1 = arg_2_0.scroll:getContentSize()

		arg_2_0.missionList = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_2_0.scroll):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

		arg_2_0.missionList:setBounceable(false)
		arg_2_0.missionList:setTouchType(false)
		arg_2_0:updateShow()
		arg_2_0.container:getChildByName("rule_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.ended then
				local var_3_0 = {}

				var_3_0.title_name = "ACTIVITY_PARTY_RULE_TITLE"
				var_3_0.rule = "ACTIVITY_PARTY_RULE_TEXT"

				xyd.WindowManager.get():openWindow("new_text_rule", var_3_0)
			end
		end)
		arg_2_0.subContainer:getChildByName("return_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
			if arg_4_1 == ccui.TouchEventType.ended then
				arg_2_0.showType = var_0_8.Main

				arg_2_0:updateShow()
			end
		end)
		arg_2_0.subContainer:getChildByName("light_star_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				arg_2_0.missionType = var_0_9.Star

				arg_2_0:update()
			end
		end)
		arg_2_0.subContainer:getChildByName("hero_get_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				arg_2_0.missionType = var_0_9.GetHero

				arg_2_0:update()
			end
		end)

		arg_2_0.effect = xyd.createEffect(var_0_3)

		arg_2_0.effect:addTo(arg_2_0.subContainer)
		arg_2_0.effect:play(nil, true)
		arg_2_0.effect:setPosition(arg_2_0.subContainer:getChildByName("light_star_btn"):getPosition())
		arg_2_0.subContainer:getChildByName("time_tip_txt"):enableOutline(xyd.color.WHITE, 2)
		arg_2_0:updateMainContainer()
		arg_2_0:updateStarAward()
	end
end

function var_0_0.canAward(arg_7_0)
	for iter_7_0 = 1, #arg_7_0.details.mission_list do
		local var_7_0 = arg_7_0.details.mission_list[iter_7_0]

		if var_7_0.is_complete == 1 and var_7_0.is_award == 0 then
			return true
		end
	end

	return false
end

function var_0_0.updateStarAward(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0.details.base_info.stars
	local var_8_1 = arg_8_0.details.base_info.is_extra_awards
	local var_8_2 = xyd.tables.misc.activityPartyExtraNum

	for iter_8_0 = 1, #var_8_2 do
		arg_8_0.mainContainer:getChildByName("box_close_pos" .. iter_8_0):removeAllChildren(true)
		arg_8_0.mainContainer:getChildByName("box_gray" .. iter_8_0):setOpacity(0)
		arg_8_0.mainContainer:getChildByName("box_open" .. iter_8_0):setOpacity(0)

		if var_8_1[iter_8_0] == 1 then
			arg_8_0.mainContainer:getChildByName("box_open" .. iter_8_0):setOpacity(255)
		elseif var_8_0 >= var_8_2[iter_8_0] then
			local var_8_3 = xyd.createEffect(var_0_4)

			var_8_3:addTo(arg_8_0.mainContainer:getChildByName("box_close_pos" .. iter_8_0))
			var_8_3:play(nil, true)

			local var_8_4 = arg_8_0.mainContainer:getChildByName("box_close_pos" .. iter_8_0):getContentSize()

			var_8_3:setPosition(var_8_4.width / 2, var_8_4.height / 2 - 10)
		else
			arg_8_0.mainContainer:getChildByName("box_gray" .. iter_8_0):setOpacity(255)
		end

		arg_8_0.mainContainer:getChildByName("progress_txt" .. iter_8_0):setString(var_8_0 .. "/" .. var_8_2[iter_8_0])

		if not arg_8_1 then
			local var_8_5 = arg_8_0.mainContainer:getChildByName("box_gray" .. iter_8_0)

			arg_8_0.mainContainer:getChildByName("progress_txt" .. iter_8_0):enableOutline(cc.c4b(29, 14, 0, 155), 2)
			var_8_5:setTouchEnabled(true)
			var_8_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
				if arg_9_0.name == "began" then
					if arg_8_0.details.base_info.stars < var_8_2[iter_8_0] then
						local var_9_0 = xyd.tables.misc.activityPartyExtraGift[iter_8_0]
						local var_9_1 = xyd.getFormatItemsByGiftId(var_9_0)

						xyd.WindowManager.get():openWindow("common_award", {
							awards = var_9_1
						})
						xyd.WindowManager.get():getWindow("common_award"):setPosition(var_8_5:getPositionX(), var_8_5:getPositionY() + 10)
					end

					return true
				elseif arg_9_0.name == "ended" then
					xyd.playButtonSound()

					if xyd.WindowManager:get():getWindow("common_award") then
						xyd.WindowManager:get():closeWindow("common_award")
					end

					local var_9_2 = arg_8_0.details.base_info.stars
					local var_9_3 = arg_8_0.details.base_info.is_extra_awards

					if var_9_3[iter_8_0] == 0 and var_9_2 >= var_8_2[iter_8_0] then
						xyd.Backend.get():request(xyd.mid.ACTIVITY_PARTY_STAR_AWARD, {
							award_id = iter_8_0
						}, function(arg_10_0, arg_10_1, arg_10_2)
							if arg_10_0 == xyd.error.OK then
								var_9_3[iter_8_0] = 1

								arg_8_0:updateStarAward(true)

								if arg_10_1 and arg_10_1.awards then
									arg_8_0.selfPlayer:handleRewards(arg_10_1.awards)
								end
							end
						end)
					end
				end
			end)
		end
	end

	if not arg_8_1 then
		arg_8_0.mainContainer:getChildByName("star_award_text"):setString(var_0_1:translation("ACTIVITY_PARTY_STATE_REWARD"))
		arg_8_0.mainContainer:getChildByName("star_award_text"):enableOutline(cc.c4b(29, 14, 0, 155), 2)
	end
end

function var_0_0.updateMainContainer(arg_11_0)
	local var_11_0 = var_0_7:getPartners()

	arg_11_0.mainContainer:getChildByName("item_pos"):removeAllChildren(true)

	local var_11_1 = math.ceil(arg_11_0.details.day_count / 2)

	for iter_11_0 = 1, 3 do
		local var_11_2 = var_0_5.new()

		var_11_2:initUnCollected(var_11_0[iter_11_0])

		local var_11_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1152/party_item.csb")
		local var_11_4 = var_11_3:getChildByName("container")

		var_11_4:getChildByName("enter_btn"):setVisible(false)
		var_11_4:getChildByName("btn_gray"):setVisible(false)
		var_11_4:getChildByName("red_point"):setVisible(false)
		var_11_4:getChildByName("bg_1"):setVisible(false)
		var_11_4:getChildByName("bg_2"):setVisible(false)
		var_11_4:getChildByName("bg_3"):setVisible(false)
		var_11_4:getChildByName("bg_" .. iter_11_0):setVisible(true)

		local var_11_5

		if iter_11_0 < var_11_1 then
			var_11_5 = string.format(var_0_1:translation("ACTIVITY_PARTY_STATE_TEXT1"), arg_11_0.details.hero_stars[tostring(var_11_0[iter_11_0])] or 0)
		elseif var_11_1 < iter_11_0 then
			local var_11_6 = (iter_11_0 - 1) * 2 + 1 - arg_11_0.details.day_count

			var_11_5 = string.format(var_0_1:translation("ACTIVITY_PARTY_STATE_TEXT3"), var_11_6)
		elseif iter_11_0 == var_11_1 then
			var_11_5 = var_0_1:translation("ACTIVITY_PARTY_STATE_TEXT2")

			var_11_4:getChildByName("enter_btn"):setVisible(true)
			var_11_4:getChildByName("enter_btn"):setPosition(cc.p(783 - (iter_11_0 - 1) * 350, 390))

			if arg_11_0:canAward() then
				var_11_4:getChildByName("red_point"):setVisible(true)
			end
		end

		var_11_4:getChildByName("desc_txt"):setString(var_11_5)
		var_11_3:setAnchorPoint(cc.p(0, 0))
		var_11_3:addTo(arg_11_0.mainContainer:getChildByName("item_pos"))
		var_11_3:setPosition(cc.p((iter_11_0 - 1) * 350, 0))
		var_11_4:getChildByName("enter_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				arg_11_0.showType = var_0_8.Sub
				arg_11_0.showHeroID = var_11_0[iter_11_0]

				arg_11_0:updateShow()
			end
		end)

		local var_11_7 = var_11_2:getHeroModel()

		var_11_7:addTo(var_11_4:getChildByName("model_pos"))
		var_11_7:setScale(0.85)
	end
end

function var_0_0.updateShow(arg_13_0)
	if arg_13_0.showType == var_0_8.Main then
		arg_13_0.mainContainer:setVisible(true)
		arg_13_0.subContainer:setVisible(false)
	else
		arg_13_0.mainContainer:setVisible(false)
		arg_13_0.subContainer:setVisible(true)
		arg_13_0:update()
	end
end

function var_0_0.update(arg_14_0)
	arg_14_0.showMissions = {}

	local var_14_0 = 0

	for iter_14_0 = 1, #arg_14_0.details.mission_list do
		local var_14_1 = arg_14_0.details.mission_list[iter_14_0]

		if var_0_6:type(var_14_1.mission_id) == arg_14_0.missionType then
			table.insert(arg_14_0.showMissions, var_14_1)
		end
	end

	if arg_14_0.effect and not tolua.isnull(arg_14_0.effect) then
		if arg_14_0.missionType == var_0_9.Star then
			arg_14_0.effect:setPosition(arg_14_0.subContainer:getChildByName("light_star_btn"):getPosition())
		else
			arg_14_0.effect:setPosition(arg_14_0.subContainer:getChildByName("hero_get_btn"):getPosition())
		end
	end

	arg_14_0:updateMissionScroll()
	arg_14_0:updateCardInfo()
	arg_14_0:updateStar()
end

function var_0_0.updateStar(arg_15_0)
	local var_15_0 = arg_15_0.subContainer:getChildByName("star_container")
	local var_15_1 = 0

	for iter_15_0 = 1, #arg_15_0.details.mission_list do
		local var_15_2 = arg_15_0.details.mission_list[iter_15_0]

		if var_0_6:type(var_15_2.mission_id) == var_0_9.Star and var_15_2.is_award == 1 then
			var_15_1 = var_15_1 + 1
		end
	end

	for iter_15_1 = 1, 5 do
		if iter_15_1 <= var_15_1 then
			var_15_0:getChildByName("star_light" .. tostring(iter_15_1)):setVisible(true)
		else
			var_15_0:getChildByName("star_light" .. tostring(iter_15_1)):setVisible(false)
		end
	end
end

function var_0_0.updateCardInfo(arg_16_0)
	if not arg_16_0.showHeroID then
		return
	end

	arg_16_0.subContainer:getChildByName("card_pos"):removeAllChildren(true)

	local var_16_0 = xyd.SpriteLoader.new(xyd.tables.model:transparentCard(arg_16_0.showHeroID), nil, nil, xyd.DefaultImageType.HOME_CARD)

	var_16_0:setScale(1)

	if not var_16_0 then
		return
	end

	var_16_0:setAnchorPoint(cc.p(0.5, 0))
	var_16_0:addTo(arg_16_0.subContainer:getChildByName("card_pos"))

	local var_16_1 = math.ceil(arg_16_0.details.day_count / 2)

	if var_16_1 <= 3 then
		local var_16_2 = arg_16_0.activity.start_time + var_16_1 * 2 * 24 * 3600 - xyd.ServerTime.get():getServerTime()
		local var_16_3 = string.format(var_0_1:translation("ACTIVITY_PARTY_CHAT"), xyd.secondsToString1(var_16_2, 2))

		arg_16_0.subContainer:getChildByName("time_tip_txt"):setString(var_16_3)
	end
end

function var_0_0.updateMissionScroll(arg_17_0)
	arg_17_0.missionList:removeAllItems()

	local var_17_0 = arg_17_0.showMissions

	for iter_17_0 = 1, #var_17_0 do
		local var_17_1
		local var_17_2 = arg_17_0.missionList:dequeueItem()

		if not var_17_2 then
			var_17_2 = arg_17_0.missionList:newItem()
		else
			var_17_2:removeAllChildren(true)
		end

		local var_17_3 = arg_17_0:createListContent(var_17_0[iter_17_0])
		local var_17_4 = var_17_3:getWidth()
		local var_17_5 = var_17_3:getHeight()

		var_17_2:setItemSize(var_17_4, var_17_5)
		var_17_2:addContent(var_17_3)
		arg_17_0.missionList:addItem(var_17_2)
		arg_17_0.missionList:reload()
	end
end

function var_0_0.createListContent(arg_18_0, arg_18_1)
	local var_18_0 = display.newNode()
	local var_18_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1152/task_item.csb")
	local var_18_2 = var_18_1:getChildByName("container")
	local var_18_3 = var_0_6:type(arg_18_1.mission_id)
	local var_18_4 = var_0_6:subType(arg_18_1.mission_id)
	local var_18_5 = var_0_6:condition(arg_18_1.mission_id)

	var_18_2:getChildByName("progress_txt"):setString("(" .. tostring(arg_18_1.count) .. "/" .. tostring(var_18_5) .. ")")
	var_18_2:getChildByName("name_txt"):setString(var_0_6:mesc(arg_18_1.mission_id))
	var_18_2:getChildByName("award_text"):setString(var_0_1:translation("MISSION_TEXT"))

	local var_18_6 = var_0_6:gift(arg_18_1.mission_id)

	arg_18_0:rewardFormat(var_18_2:getChildByName("award_container"), var_18_6)

	local var_18_7 = var_18_2:getChildByName("task_btn")

	var_18_7:setVisible(false)
	var_18_2:getChildByName("star_light"):setVisible(false)
	var_18_2:getChildByName("star_gray"):setVisible(false)
	var_18_2:getChildByName("gotten_text"):setVisible(false)

	if arg_18_1.is_award == 0 and arg_18_0.missionType == var_0_9.Star then
		var_18_2:getChildByName("star_gray"):setVisible(true)
	elseif arg_18_1.is_award == 1 and arg_18_0.missionType == var_0_9.Star then
		var_18_2:getChildByName("star_light"):setVisible(true)
	elseif arg_18_1.is_award == 0 and var_18_4 == 6 then
		var_18_7:setVisible(true)
		var_18_7:getChildByName("buy_text"):setVisible(true)
		var_18_7:addTouchEventListener(function(arg_19_0, arg_19_1)
			if arg_19_1 == ccui.TouchEventType.ended then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("ACTIVITY_PARTY_BUY_TIP"), var_18_5), function()
					if arg_18_0.selfPlayer.crystal < var_18_5 then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							local var_21_0 = {}

							var_21_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_21_0)
						end, nil, nil, xyd.ColorMode.ACTIVITY)

						return
					end

					arg_18_0.activitiesModel:getActivityReward(arg_18_0.activity.table_id, arg_18_1.mission_id, function(arg_22_0, arg_22_1)
						if arg_22_0 == xyd.error.OK then
							if arg_22_1.awards then
								arg_18_0.selfPlayer:handleRewards(arg_22_1.awards)
							end

							if arg_22_1.mission_list then
								arg_18_0.details.mission_list = arg_22_1.mission_list
							end

							if arg_22_1.base_info then
								arg_18_0.details.base_info = arg_22_1.base_info
							end

							arg_18_0.activity.details = arg_18_0.details

							if var_18_7 and not tolua.isnull(var_18_7) then
								var_18_7:setVisible(false)
								var_18_2:getChildByName("gotten_text"):setVisible(true)
							end

							if var_18_2 and not tolua.isnull(var_18_2) then
								var_18_2:getChildByName("progress_txt"):setString("(" .. tostring(var_18_5) .. "/" .. tostring(var_18_5) .. ")")
							end

							arg_18_0:updateStarAward(true)
						end
					end)
				end, nil, 0, xyd.ColorMode.ACTIVITY)
			end
		end)
	elseif arg_18_1.is_award == 1 and arg_18_0.missionType == var_0_9.GetHero then
		var_18_2:getChildByName("gotten_text"):setVisible(true)
	end

	if arg_18_1.is_award == 0 then
		if arg_18_1.is_complete == 1 then
			var_18_2:getChildByName("item_bg"):setVisible(false)
		end

		var_18_1:setTouchEnabled(true)
		var_18_1:setTouchSwallowEnabled(false)
		var_18_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
			if arg_23_0.name == "began" then
				return true
			elseif arg_23_0.name == "ended" and not arg_18_0.scrollViewMoved_ then
				if arg_18_1.is_complete == 1 then
					arg_18_0.activitiesModel:getActivityReward(arg_18_0.activity.table_id, arg_18_1.mission_id, function(arg_24_0, arg_24_1)
						if arg_24_0 == xyd.error.OK then
							if arg_24_1.awards then
								arg_18_0.selfPlayer:handleRewards(arg_24_1.awards)
							end

							if arg_24_1.mission_list then
								arg_18_0.details.mission_list = arg_24_1.mission_list
							end

							if arg_24_1.base_info then
								arg_18_0.details.base_info = arg_24_1.base_info
							end

							arg_18_0.activity.details = arg_18_0.details

							if var_18_2 and not tolua.isnull(var_18_2) then
								var_18_2:getChildByName("item_bg"):setVisible(true)
								var_18_1:setTouchEnabled(false)

								if var_18_3 == var_0_9.Star then
									var_18_2:getChildByName("star_light"):setVisible(true)
									var_18_2:getChildByName("star_gray"):setVisible(false)
								else
									var_18_2:getChildByName("gotten_text"):setVisible(true)
								end
							end

							if arg_18_0 then
								arg_18_0:updateStar()
								arg_18_0:updateStarAward(true)
								arg_18_0:updateMainContainer()
								xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):refreshRedMark()

								local var_24_0 = xyd.WindowManager.get():getWindow("activities")

								if var_24_0 and not tolua.isnull(var_24_0) then
									var_24_0:rightLayout()
								end
							end
						end
					end)
				elseif var_18_4 == 2 or var_18_4 == 3 or var_18_4 == 5 then
					if var_18_4 == 2 then
						xyd.WindowManager.get():openWindow("tujian_hero", {
							hero_show_type = 8
						})
					elseif var_18_4 == 3 then
						arg_18_0.guild:loadGuildMap(function(arg_25_0)
							xyd.WindowManager.get():openWindow("map_window", {
								chapter_type = 1
							})
						end)
					elseif var_18_4 == 5 then
						xyd.WindowManager.get():openWindow("vip_recharge")
					end

					xyd.WindowManager.get():closeWindow("activities")
				end
			end
		end)
	end

	var_18_1:addTo(var_18_0)
	var_18_1:setAnchorPoint(cc.p(0, 0))
	var_18_0:setContentSize(var_18_2:getContentSize().width, var_18_2:getContentSize().height)
	var_18_1:setPosition(cc.p(0, 0))
	var_18_1:setName("source")

	return var_18_0
end

function var_0_0.scrollListener(arg_26_0, arg_26_1)
	if arg_26_1.name == "began" then
		arg_26_0.scrollViewMoved_ = false
		arg_26_0.prevY_ = arg_26_1.y
	elseif arg_26_1.name == "moved" and 10 <= math.abs(arg_26_1.y - arg_26_0.prevY_) then
		arg_26_0.scrollViewMoved_ = true
	end
end

return var_0_0
