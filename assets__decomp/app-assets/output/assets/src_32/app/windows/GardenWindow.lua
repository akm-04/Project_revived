local var_0_0 = class("GardenWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.activityGardenFlower
local var_0_4 = "skeletons/ui_effect/garden/activity_garden1"
local var_0_5 = "skeletons/ui_effect/garden/activity_garden2"
local var_0_6 = "skeletons/ui_effect/garden/activity_garden3"
local var_0_7 = "skeletons/ui_effect/garden/activity_garden4"
local var_0_8 = {
	isShopListShow = false,
	isVisitListShow = false
}
local var_0_9 = {
	guild = 2,
	friend = 1
}
local var_0_10 = 4
local var_0_11 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.garden = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.activity = arg_1_0.garden.activity
	arg_1_0.details = arg_1_0.garden.details
	arg_1_0.selfDetails = arg_1_0.garden.selfDetails
	arg_1_0.playerInfo = arg_1_0.details.np_info
	arg_1_0.isSelfGarden = arg_1_0.garden:isSelfGarden()
	var_0_8 = {
		isShopListShow = false,
		isVisitListShow = false
	}
end

function var_0_0.calculateUpdateTime(arg_2_0)
	local var_2_0 = arg_2_0.details.field_info
	local var_2_1
	local var_2_2 = {}

	for iter_2_0 = 1, #var_2_0 do
		local var_2_3 = var_2_0[iter_2_0]

		if var_2_3.status == 1 and (var_2_3.end_time > xyd.ServerTime.get():getServerTime() or var_2_3.thirsty_time > xyd.ServerTime.get():getServerTime()) then
			local var_2_4 = math.min(var_2_3.end_time, var_2_3.thirsty_time)

			if not var_2_1 then
				var_2_1 = var_2_4
			else
				var_2_1 = math.min(var_2_1, var_2_4)
			end
		end

		if var_2_3.status == 1 and var_2_3.end_time > xyd.ServerTime.get():getServerTime() then
			table.insert(var_2_2, var_2_3.field_id)
		end
	end

	arg_2_0.updateTime = var_2_1
	arg_2_0.updateTimeLandIds = var_2_2
end

function var_0_0.updateLandByTime(arg_3_0)
	for iter_3_0, iter_3_1 in pairs(arg_3_0.updateTimeLandIds or {}) do
		local var_3_0 = arg_3_0.landItems[iter_3_1]
		local var_3_1 = arg_3_0.details.field_info[iter_3_1]

		if var_3_0 and var_3_1 and not var_3_1.is_locked then
			local var_3_2 = var_3_0:getChildByName("container"):getChildByName("state_container")

			if var_3_1 and var_3_1.status == 1 then
				var_3_2:setVisible(true)

				local var_3_3 = var_3_1.end_time - xyd.ServerTime.get():getServerTime()

				if var_3_3 < 0 then
					var_3_3 = 0
				end

				var_3_2:getChildByName("state_text"):setString(xyd.secondsToString(var_3_3))
			end
		end
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.REFRESH_GARDEN_INFO, function(arg_5_0)
		if arg_4_0 and not tolua.isnull(arg_4_0) then
			arg_4_0.isNeedReInit = true

			arg_4_0:updateAsset()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.ECONOMY, handler(arg_4_0, arg_4_0.updateAsset))
	arg_4_0:layout()
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("swallow")
	local var_6_1 = display.newNode()

	var_6_1:addTo(var_6_0, -1)

	local var_6_2 = var_6_0:getContentSize()

	var_6_1:setContentSize(var_6_2.width, var_6_2.height)
	var_6_1:setTouchEnabled(true)
	arg_6_0:nodeByName("garden_text"):setString(var_0_1:translation("GARDEN_TEXT"))
	arg_6_0:nodeByName("time_text"):setString(var_0_1:translation("TEAM_DRINK_LEFT_TIME"))
	arg_6_0:nodeByName("pick_time_text"):setString(var_0_1:translation("GARDEN_PICK_TIME_TEXT"))
	arg_6_0:nodeByName("time_txt"):setString(var_0_1:translation(""))
	arg_6_0:nodeByName("name_txt"):setString(arg_6_0.playerInfo.player_name)

	local var_6_3 = arg_6_0.playerInfo

	if not arg_6_0.isSelfGarden then
		var_6_3.playerInfo = arg_6_0.playerInfo
	end

	xyd.setPlayerAvatar(arg_6_0:nodeByName("avtar_container"), arg_6_0.playerInfo)
	arg_6_0:updateShow()
	arg_6_0:setButtonClick()
	arg_6_0:updateLand()
	arg_6_0:createScheduler()
	arg_6_0:updateAsset()
	arg_6_0:updateViewBaseOnIsSelf()
end

function var_0_0.updateViewBaseOnIsSelf(arg_7_0)
	if not arg_7_0.isSelfGarden then
		arg_7_0:nodeByName("shop_container"):setVisible(false)
		arg_7_0:nodeByName("shop_btn"):setVisible(false)
		arg_7_0:nodeByName("rank_btn"):setVisible(false)
		arg_7_0:nodeByName("log_btn"):setVisible(false)
		arg_7_0:nodeByName("rule_btn"):setVisible(false)
		arg_7_0:nodeByName("onekey_deal"):setVisible(false)
	else
		arg_7_0:nodeByName("pick_time_container"):setVisible(false)
	end
end

function var_0_0.updateAsset(arg_8_0)
	arg_8_0:nodeByName("pick_time_txt"):setString(tostring(arg_8_0.selfDetails.steal_times) .. "/" .. xyd.tables.misc.activityGardenStealMax)
	arg_8_0:nodeByName("nectar_num_txt"):setString(arg_8_0.selfDetails.nectar)
	arg_8_0:nodeByName("crystal_num_txt"):setString(arg_8_0.selfPlayer.crystal)
end

function var_0_0.createScheduler(arg_9_0)
	if arg_9_0.handle then
		var_0_2.unscheduleGlobal(arg_9_0.handle)

		arg_9_0.handle = nil
	end

	local var_9_0 = arg_9_0.activity.end_time - xyd.ServerTime.get():getServerTime()

	arg_9_0:updateTimeText(var_9_0)

	arg_9_0.handle = var_0_2.scheduleGlobal(function()
		local var_10_0 = arg_9_0.activity.end_time - xyd.ServerTime.get():getServerTime()

		if not arg_9_0 or var_10_0 < 0 then
			if arg_9_0.handle then
				var_0_2.unscheduleGlobal(arg_9_0.handle)

				arg_9_0.handle = nil
			end

			return
		end

		arg_9_0:updateTimeText(var_10_0)

		if xyd.WindowManager.get():getWindow("garden_select") then
			-- block empty
		elseif arg_9_0.updateTime and arg_9_0.updateTime <= xyd.ServerTime.get():getServerTime() or arg_9_0.isNeedReInit then
			arg_9_0.updateTime = nil
			arg_9_0.isNeedReInit = nil

			arg_9_0:reInitLandByLandInfo()
		end

		arg_9_0:updateLandByTime()
	end, 0.1)
end

function var_0_0.updateTimeText(arg_11_0, arg_11_1)
	if arg_11_1 < 0 then
		arg_11_1 = 0
	end

	if arg_11_0 and arg_11_0:nodeByName("time_txt") and not tolua.isnull(arg_11_0:nodeByName("time_txt")) then
		local var_11_0 = xyd.secondsToString1(arg_11_1, 2)

		arg_11_0:nodeByName("time_txt"):setString(var_11_0)
	end
end

function var_0_0.updateShow(arg_12_0, arg_12_1)
	if arg_12_1 then
		var_0_8 = {
			isShopListShow = false,
			isVisitListShow = false
		}
	end

	arg_12_0:nodeByName("shop_container"):setVisible(var_0_8.isShopListShow)
	arg_12_0:nodeByName("visit_container"):setVisible(var_0_8.isVisitListShow)
	arg_12_0:nodeByName("visit_container"):setTouchEnabled(true)
	arg_12_0:nodeByName("visit_container"):setTouchSwallowEnabled(true)
	arg_12_0:nodeByName("shop_container"):setTouchEnabled(true)
	arg_12_0:nodeByName("shop_container"):setTouchSwallowEnabled(true)

	local var_12_0 = xyd.tables.misc:getValue("activity_garden_auto_water")

	arg_12_0:nodeByName("auto_btn"):setTouchEnabled(true)
	arg_12_0:nodeByName("auto_btn"):setTouchSwallowEnabled(false)

	local var_12_1 = arg_12_0.backpack:getItemNumByID(var_12_0)

	if var_12_1 and var_12_1 > 0 then
		arg_12_0:nodeByName("auto_btn"):setBright(true)
	else
		arg_12_0:nodeByName("auto_btn"):setBright(false)
	end

	local var_12_2 = display.newNode()

	var_12_2:setContentSize(85, 85)
	var_12_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_12_2:addTo(arg_12_0:nodeByName("bottom_container"))
	var_12_2:setPosition(arg_12_0:nodeByName("auto_btn"):getPosition())
	var_12_2:setTouchEnabled(true)
	var_12_2:setTouchSwallowEnabled(false)
	var_12_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "ended" then
			if var_12_1 and var_12_1 > 0 then
				local var_13_0 = var_0_1:translation("GARDEN_AUTO_WATER_TIP2")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_13_0
				})
			else
				local var_13_1 = var_0_1:translation("GARDEN_AUTO_WATER_TIP1")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_13_1
				})
			end
		end
	end)
end

function var_0_0.setButtonClick(arg_14_0)
	arg_14_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_15_0 = {
				hasOtherItem = true,
				title_name = "ACTIVITY_GARDEN_RULE_TITLE",
				rule = "ACTIVITY_GARDEN_RULE_TEXT",
				otherItemType = xyd.TextRuleItemType.Award,
				award = xyd.tables.activityGardenawardTable
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_15_0)
		end
	end)
	arg_14_0:nodeByName("guild_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_14_0.guild:loadTeam(function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					local var_17_0 = {
						visit_type = var_0_9.guild
					}

					if arg_14_0.guild.members then
						xyd.WindowManager.get():openWindow("garden_friend_list", var_17_0)
						arg_14_0:updateShow(true)
					else
						local var_17_1 = var_0_1:translation("GUILD_CHAT_ALERT")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_17_1
						})
					end
				end
			end)
		end
	end)
	arg_14_0:nodeByName("friend_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_18_0 = {
				visit_type = var_0_9.friend
			}

			if #arg_14_0.socialSystem.friendlist < 1 then
				local var_18_1 = var_0_1:translation("GARDEN_NO_FRIEDN_TIP")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_18_1
				})

				return
			end

			xyd.WindowManager.get():openWindow("garden_friend_list", var_18_0)
			arg_14_0:updateShow(true)
		end
	end)
	arg_14_0:nodeByName("shop_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			var_0_8.isShopListShow = not var_0_8.isShopListShow
			var_0_8.isVisitListShow = false

			arg_14_0:updateShow()
		end
	end)
	arg_14_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_20_0 = {}

			arg_14_0.garden:gardenRank(var_20_0, function(arg_21_0, arg_21_1)
				if arg_21_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("garden_rank", arg_21_1)
				end
			end)
			arg_14_0:updateShow(true)
		end
	end)
	arg_14_0:nodeByName("exchange_shop_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_14_0:nodeByName("top_container"):setVisible(false)
			xyd.WindowManager.get():openWindow("garden_nectar_shop")
			arg_14_0:updateShow(true)
		end
	end)
	arg_14_0:nodeByName("go_btn"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_23_0 = {}

			var_23_0.random_visit = 1

			arg_14_0.garden:getGardenInfo(var_23_0, function(arg_24_0, arg_24_1)
				if arg_24_0 == xyd.error.OK then
					-- block empty
				end
			end)
			arg_14_0:updateShow(true)
		end
	end)
	arg_14_0:nodeByName("add_time_btn"):addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_14_0.selfDetails.steal_times >= xyd.tables.misc.activityGardenStealMax then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("GARDEN_PLANT_TIP16")
				})

				return
			end

			if arg_14_0.selfPlayer.crystal < xyd.tables.misc.activityGardenStealCost then
				local var_25_0 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_25_0, function()
					local var_26_0 = {}

					var_26_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_26_0)
				end, nil, nil, arg_14_0.colorMode)

				return
			end

			local var_25_1 = xyd.tables.misc.activityGardenStealMax - arg_14_0.selfDetails.steal_times

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("GARDEN_HANDLE_TIP_TEXT1"), xyd.tables.misc.activityGardenStealCost * var_25_1, var_25_1), function()
				local var_27_0 = {}

				arg_14_0.garden:gardenBuySteal(var_27_0, function(arg_28_0, arg_28_1)
					if arg_28_0 == xyd.error.OK then
						arg_14_0:updateAsset()
					end
				end)
			end, nil, nil, arg_14_0.colorMode)
			arg_14_0:updateShow(true)
		end
	end)
	arg_14_0:nodeByName("log_btn"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_29_0 = {}

			arg_14_0.garden:gardenLog(var_29_0, function(arg_30_0, arg_30_1)
				if arg_30_0 == xyd.error.OK then
					local var_30_0 = {
						data = arg_30_1.log_list
					}

					xyd.WindowManager.get():openWindow("garden_log", var_30_0)
				end
			end)
			arg_14_0:updateShow(true)
		end
	end)
	arg_14_0:nodeByName("visit_btn"):addTouchEventListener(function(arg_31_0, arg_31_1)
		if arg_31_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			var_0_8.isVisitListShow = not var_0_8.isVisitListShow
			var_0_8.isShopListShow = false

			arg_14_0:updateShow()
		end
	end)
	arg_14_0:nodeByName("flower_shop_btn"):addTouchEventListener(function(arg_32_0, arg_32_1)
		if arg_32_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("garden_flower_shop")
			arg_14_0:updateShow(true)
		end
	end)
	arg_14_0:nodeByName("onekey_deal"):addTouchEventListener(function(arg_33_0, arg_33_1)
		if arg_33_1 == ccui.TouchEventType.ended then
			local var_33_0 = xyd.ServerTime.get():getServerTime()
			local var_33_1 = arg_14_0.garden.details.field_info
			local var_33_2 = 0
			local var_33_3 = 0
			local var_33_4 = 0
			local var_33_5 = {}

			local function var_33_6()
				var_33_2 = var_33_2 - 1

				if var_33_2 == 0 then
					-- block empty
				end
			end

			for iter_33_0, iter_33_1 in ipairs(var_33_1) do
				if iter_33_1.seed_id > 0 then
					if var_33_0 >= iter_33_1.end_time then
						var_33_2 = var_33_2 + 1

						local var_33_7 = {
							player_id = arg_14_0.selfPlayer.playerID,
							field_id = iter_33_0,
							seed_id = iter_33_1.seed_id
						}

						var_33_7.is_gain = 1

						table.insert(var_33_5, var_33_7)
					elseif var_33_0 >= iter_33_1.thirsty_time then
						var_33_2 = var_33_2 + 1

						local var_33_8 = {
							player_id = arg_14_0.selfPlayer.playerID,
							field_id = iter_33_0
						}

						var_33_8.is_water = 1

						table.insert(var_33_5, var_33_8)
					end
				end
			end

			local function var_33_9(arg_35_0)
				if arg_35_0 > #var_33_5 then
					if arg_14_0 and not tolua.isnull(arg_14_0) then
						arg_14_0:updateAsset()
					end

					local var_35_0 = string.format(var_0_1:translation("ACT_FARM_ONEKEY_DEALING_RESULT"), var_33_3, var_33_4)

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_35_0, nil, nil, nil, arg_14_0.colorMode)

					return
				end

				local var_35_1 = var_33_5[arg_35_0]

				if var_35_1.is_gain then
					arg_14_0.garden:gardenGain(var_35_1, function(arg_36_0, arg_36_1)
						if arg_36_0 == xyd.error.OK then
							var_33_3 = var_33_3 + var_0_3:price(var_35_1.seed_id) * arg_36_1.get_num
						end

						var_33_9(arg_35_0 + 1)
					end)
				elseif var_35_1.is_water then
					arg_14_0.garden:gardenWater(var_35_1, function(arg_37_0, arg_37_1)
						if arg_37_0 == xyd.error.OK then
							var_33_4 = var_33_4 + 1
						end

						var_33_9(arg_35_0 + 1)
					end)
				end
			end

			var_33_9(1)
		end
	end)
	arg_14_0:nodeByName("close"):addTouchEventListener(function(arg_38_0, arg_38_1)
		if arg_38_1 == ccui.TouchEventType.ended then
			local var_38_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_38_0, false)

			if not arg_14_0.isSelfGarden then
				arg_14_0.garden:loadInfo(function(arg_39_0, arg_39_1)
					if arg_39_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow(arg_14_0)
						xyd.WindowManager.get():openWindow("garden")
					end
				end)
			else
				xyd.WindowManager.get():closeWindow(arg_14_0)
			end
		end
	end)
	arg_14_0:initSelectContainer()
end

function var_0_0.initSelectContainer(arg_40_0)
	if not arg_40_0.selectEffect then
		local var_40_0 = xyd.createEffect(var_0_5)

		var_40_0:addTo(arg_40_0:nodeByName("container"))
		var_40_0:play(nil, true)

		arg_40_0.selectEffect = var_40_0

		arg_40_0.selectEffect:setVisible(false)
	end
end

function var_0_0.updateSelectInfo(arg_41_0)
	if arg_41_0.selectLandId then
		local var_41_0 = {
			selectLandId = arg_41_0.selectLandId,
			position = arg_41_0:getLandMainPositon(arg_41_0.selectLandId),
			landItem = arg_41_0.landItems[arg_41_0.selectLandId]
		}

		xyd.WindowManager.get():openWindow("garden_select", var_41_0)
	end
end

function var_0_0.getLandMainPositon(arg_42_0, arg_42_1)
	local var_42_0 = cc.p(arg_42_0.landItems[arg_42_1]:getPosition())

	return (xyd.addPosition(var_42_0, cc.p(arg_42_0:nodeByName("land_pos"):getPosition())))
end

function var_0_0.reInitLandByLandInfo(arg_43_0)
	arg_43_0:calculateUpdateTime()

	for iter_43_0, iter_43_1 in pairs(arg_43_0.landItems or {}) do
		local var_43_0 = arg_43_0.details.field_info[iter_43_0]
		local var_43_1 = iter_43_1:getChildByName("container")
		local var_43_2 = var_43_1:getChildByName("state_container")

		var_43_1:getChildByName("land1"):setVisible(false)
		var_43_1:getChildByName("land2"):setVisible(false)
		var_43_1:getChildByName("build_btn"):setVisible(false)
		var_43_1:getChildByName("state_container"):setVisible(false)

		if not var_43_0 then
			var_43_1:getChildByName("land2"):setVisible(true)

			if iter_43_0 == arg_43_0.details.field_num + 1 and arg_43_0.isSelfGarden then
				var_43_1:getChildByName("build_btn"):getChildByName("cost_txt"):setString(xyd.tables.misc.activityGardenLandCost)
				var_43_1:getChildByName("build_btn"):setVisible(true)
			end
		else
			var_43_1:getChildByName("land1"):setVisible(true)
			var_43_1:getChildByName("flower"):removeAllChildren(true)

			if var_43_0.status == 1 then
				local var_43_3

				if xyd.ServerTime.get():getServerTime() >= var_43_0.end_time then
					var_43_3 = xyd.AssetLoader.get():loadSprite(var_0_3:flowerImg(var_43_0.seed_id))
				elseif xyd.ServerTime.get():getServerTime() >= var_43_0.thirsty_time then
					var_43_3 = xyd.AssetLoader.get():loadSprite("windows/garden/main/flower_state2.png")
				else
					var_43_3 = xyd.AssetLoader.get():loadSprite("windows/garden/main/flower_state1.png")
				end

				var_43_3:setAnchorPoint(cc.p(0.5, 0))
				var_43_3:addTo(var_43_1:getChildByName("flower"))
			end
		end

		if iter_43_1.effect then
			iter_43_1.effect:setVisible(false)
		end

		if var_43_0 and var_43_0.status == 1 then
			var_43_2:setVisible(true)

			local var_43_4 = var_43_0.end_time - xyd.ServerTime.get():getServerTime()

			if var_43_4 <= 0 and not iter_43_1.effect then
				var_43_2:getChildByName("state_text"):setString(var_0_1:translation("GARDEN_PLANT_TIP15"))

				local var_43_5 = xyd.createEffect(var_0_7)

				var_43_5:addTo(var_43_1)
				var_43_5:play(nil, true)
				var_43_5:setPosition(cc.p(130, 0))

				iter_43_1.effect = var_43_5
			elseif var_43_4 <= 0 and iter_43_1.effect then
				iter_43_1.effect:setVisible(true)
				var_43_2:getChildByName("state_text"):setString(var_0_1:translation("GARDEN_PLANT_TIP15"))
			else
				var_43_2:getChildByName("state_text"):setString(string.format(var_0_1:translation("GARDEN_PLANT_TIP5"), xyd.secondsToString(var_43_4)))
			end

			if var_43_4 <= 0 and not arg_43_0.isSelfGarden and iter_43_1.effect and (xyd.isInTable(var_43_0.steal_players, arg_43_0.selfPlayer.playerID) or #var_43_0.steal_players >= var_0_3:pickLimit(var_43_0.seed_id)) then
				iter_43_1.effect:setVisible(false)
			end
		end
	end
end

function var_0_0.updateLand(arg_44_0)
	arg_44_0.landItems = {}

	arg_44_0:nodeByName("land_pos"):removeAllChildren(true)

	local var_44_0 = cc.p(123, -65.5)
	local var_44_1 = cc.p(128, 63.5)

	for iter_44_0 = 1, var_0_10 do
		for iter_44_1 = 1, var_0_11 do
			local var_44_2 = iter_44_0 + (iter_44_1 - 1) * var_0_10
			local var_44_3 = arg_44_0:getLandItem(var_44_2, iter_44_0, iter_44_1)
			local var_44_4 = xyd.addPosition(xyd.mulPosition(var_44_1, iter_44_0 - 1), xyd.mulPosition(var_44_0, iter_44_1 - 1))
			local var_44_5 = xyd.addPosition(var_44_4, cc.p(0, -var_44_3:getChildByName("container"):getContentSize().height / 2))

			var_44_3:addTo(arg_44_0:nodeByName("land_pos"))
			var_44_3:setPosition(var_44_5)

			local var_44_6 = 100 - (5 - iter_44_1) * var_0_10 - (iter_44_0 - 1)

			var_44_3:setLocalZOrder(var_44_6)

			arg_44_0.landItems[var_44_2] = var_44_3
		end
	end

	arg_44_0:reInitLandByLandInfo()
end

function var_0_0.getCoordinateByLandId(arg_45_0, arg_45_1)
	return (arg_45_1 - 1) % var_0_10 + 1, math.floor((arg_45_1 - 1) / var_0_10) + 1
end

function var_0_0.getLandItem(arg_46_0, arg_46_1, arg_46_2, arg_46_3)
	local var_46_0 = arg_46_0.details.field_info[arg_46_1]
	local var_46_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/garden/main/land_item.csb")
	local var_46_2 = var_46_1:getChildByName("container")
	local var_46_3 = var_46_2:getChildByName("state_container")

	var_46_2:getChildByName("land1"):setVisible(false)
	var_46_2:getChildByName("land2"):setVisible(false)
	var_46_2:getChildByName("build_btn"):setVisible(false)
	var_46_2:getChildByName("state_container"):setVisible(false)
	var_46_3:getChildByName("state_text"):enableOutline(xyd.color.GRAY, 2)
	var_46_2:getChildByName("build_btn"):getChildByName("cost_txt"):enableOutline(xyd.color.GRAY, 2)

	local function var_46_4(arg_47_0)
		if arg_47_0 then
			var_0_2.unscheduleGlobal(arg_47_0)

			arg_47_0 = nil
		end

		if var_46_0 and var_46_0.status == 1 then
			local var_47_0 = {
				land_id = arg_46_1
			}

			arg_46_0.longTouchLandId = arg_46_1

			xyd.WindowManager.get():openWindow("garden_tip", var_47_0)

			local var_47_1 = arg_46_0:getLandMainPositon(arg_46_1)
			local var_47_2 = xyd.addPosition(var_47_1, cc.p(122, 76))

			arg_46_0.selectEffect:setPosition(var_47_2)
			arg_46_0.selectEffect:setVisible(true)
		elseif not arg_46_0.isSelfGarden then
			return
		elseif arg_46_1 >= arg_46_0.details.field_num + 1 then
			return
		elseif var_46_0 and var_46_0.status == 0 and var_46_3 and not tolua.isnull(var_46_3) then
			var_46_3:setVisible(true)
			var_46_3:getChildByName("state_text"):setString(var_0_1:translation("GARDEN_PLANT_TIP4"))
		end
	end

	local function var_46_5(arg_48_0)
		if var_46_0 and var_46_0.status == 1 then
			if xyd.ServerTime.get():getServerTime() >= var_46_0.end_time then
				if xyd.isInTable(var_46_0.steal_players, arg_46_0.selfPlayer.playerID) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("GARDEN_PLANT_TIP13")
					})

					return
				end

				if not arg_46_0.isSelfGarden and arg_46_0.selfDetails.steal_times <= 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("GARDEN_PLANT_TIP12")
					})

					return
				end

				if not arg_46_0.isSelfGarden and #var_46_0.steal_players >= var_0_3:pickLimit(var_46_0.seed_id) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("GARDEN_PLANT_TIP14")
					})

					return
				end

				local var_48_0 = {
					player_id = arg_46_0.playerInfo.player_id,
					field_id = arg_46_1
				}

				arg_46_0.garden:gardenGain(var_48_0, function(arg_49_0, arg_49_1)
					if arg_49_0 == xyd.error.OK then
						local var_49_0 = var_0_3:price(var_46_0.seed_id)
						local var_49_1 = arg_49_1.get_num
						local var_49_2

						if arg_46_0.isSelfGarden then
							var_49_2 = string.format(var_0_1:translation("GARDEN_PLANT_TIP8"), arg_46_1, var_0_3:name(var_46_0.seed_id), var_49_1, var_49_0 * var_49_1)
						else
							var_49_2 = string.format(var_0_1:translation("GARDEN_PLANT_TIP11"), arg_46_1, var_49_1, var_0_3:name(var_46_0.seed_id), var_49_0 * var_49_1)
						end

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_49_2, function()
							return
						end, nil, nil, arg_46_0.colorMode)
						arg_46_0:updateAsset()
					end
				end)
			else
				arg_46_0.selectLandId = arg_46_1

				arg_46_0:updateSelectInfo()
			end
		elseif not arg_46_0.isSelfGarden then
			-- block empty
		elseif arg_46_1 > arg_46_0.details.field_num + 1 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("GARDEN_PLANT_TIP2")
			})
		elseif arg_46_1 == arg_46_0.details.field_num + 1 and arg_46_0.isSelfGarden then
			if arg_46_0.selfPlayer.crystal < xyd.tables.misc.activityGardenLandCost then
				local var_48_1 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_48_1, function()
					local var_51_0 = {}

					var_51_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_51_0)
				end, nil, nil, arg_46_0.colorMode)

				return
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("GARDEN_PLANT_TIP1"), xyd.tables.misc.activityGardenLandCost, arg_46_1), function()
				local var_52_0 = {}

				arg_46_0.garden:gardenBuyField(var_52_0, function(arg_53_0, arg_53_1)
					if arg_53_0 == xyd.error.OK then
						arg_46_0:updateAsset()
					end
				end)
			end, nil, nil, arg_46_0.colorMode)
		elseif var_46_0 and var_46_0.status == 0 then
			local var_48_2 = arg_46_0.garden:getCanPlantFlower()

			if var_48_2 and next(var_48_2) then
				local var_48_3 = {
					land_id = arg_46_1
				}

				xyd.WindowManager.get():openWindow("garden_plant", var_48_3)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("GARDEN_PLANT_TIP3")
				})
			end
		end

		if arg_48_0 then
			var_0_2.unscheduleGlobal(arg_48_0)

			arg_48_0 = nil
		end
	end

	local var_46_6
	local var_46_7 = false

	var_46_1:setTouchEnabled(true)
	var_46_1:setTouchSwallowEnabled(false)
	var_46_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_54_0)
		if arg_54_0.name == "began" then
			var_46_0 = arg_46_0.garden.details.field_info[arg_46_1]

			arg_46_0:updateShow(true)

			local var_54_0, var_54_1 = arg_46_0:getTouchInLandPos(arg_54_0)

			if var_54_0 ~= arg_46_2 or var_54_1 ~= arg_46_3 then
				if var_46_6 then
					var_0_2.unscheduleGlobal(var_46_6)

					var_46_6 = nil
				end

				if arg_46_0.longTouchLandId == arg_46_1 then
					xyd.WindowManager.get():closeWindow("garden_tip")
				end

				return true
			end

			local var_54_2 = 0

			local function var_54_3()
				var_54_2 = var_54_2 + 0.1

				if var_54_2 > 0.5 then
					var_46_7 = true

					if var_46_4 then
						var_46_4(var_46_6)
					end
				else
					var_46_7 = false
				end
			end

			var_46_7 = false
			var_46_6 = var_0_2.scheduleGlobal(var_54_3, 0.1)

			return true
		elseif arg_54_0.name == "moved" then
			xyd.WindowManager.get():closeWindow("garden_tip")
			arg_46_0.selectEffect:setVisible(false)

			return true
		elseif arg_54_0.name == "ended" then
			if var_46_6 then
				var_0_2.unscheduleGlobal(var_46_6)

				var_46_6 = nil
			end

			arg_46_0.selectEffect:setVisible(false)
			xyd.WindowManager.get():closeWindow("garden_tip")

			local var_54_4, var_54_5 = arg_46_0:getTouchInLandPos(arg_54_0)

			if var_54_4 ~= arg_46_2 or var_54_5 ~= arg_46_3 then
				return
			end

			if not var_46_0 or var_46_0.status == 0 then
				var_46_2:getChildByName("state_container"):setVisible(false)
			end

			if not var_46_7 and var_46_5 then
				var_46_5()
			end
		end
	end)

	return var_46_1
end

function var_0_0.getTouchInLandPos(arg_56_0, arg_56_1)
	local var_56_0 = arg_56_0:nodeByName("container"):convertToNodeSpace(cc.p(arg_56_1.x, arg_56_1.y))
	local var_56_1, var_56_2 = arg_56_0:transposePosition(var_56_0)

	return var_56_1, var_56_2
end

function var_0_0.transposePosition(arg_57_0, arg_57_1)
	local var_57_0 = cc.p(arg_57_0:nodeByName("land_pos"):getPosition())
	local var_57_1 = xyd.subPosition(arg_57_1, var_57_0)
	local var_57_2 = cc.p(0.004044583 * var_57_1.x + 0.0075951712 * var_57_1.y, 0.0039210843 * var_57_1.x - 0.007903918 * var_57_1.y)

	return math.ceil(var_57_2.x), math.ceil(var_57_2.y)
end

function var_0_0.willClose(arg_58_0, arg_58_1)
	var_0_0.super:willClose(arg_58_1)

	if arg_58_0.handle then
		var_0_2.unscheduleGlobal(arg_58_0.handle)

		arg_58_0.handle = nil
	end
end

return var_0_0
