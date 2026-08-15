local var_0_0 = class("WarCampEntranceWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.model
local var_0_4 = xyd.tables.warCampTimeline
local var_0_5 = xyd.tables.translation
local var_0_6 = 86400
local var_0_7 = 36000
local var_0_8 = 79200

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activity = arg_1_0.warCamp_.activity
	arg_1_0.isSelect = xyd.WarCampSelectType.NONE
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.isSelect = arg_2_0.warCamp_:getCampType()

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("text_time"):enableOutline(cc.c4b(39, 7, 59, 255), 2)
	arg_3_0:nodeByName("dialog_left"):setString(var_0_5:translation("CAMP_TALK_DEMON"))
	arg_3_0:nodeByName("dialog_right"):setString(var_0_5:translation("CAMP_TALK_ANGEL"))
	arg_3_0:nodeByName("tip_txt"):setString(var_0_5:translation("WAR_CAMP_ENTRANCE_TIPS_8"))
	arg_3_0:showBasicLayout()
	arg_3_0:updateTimeCount()
end

function var_0_0.showBasicLayout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("container"):getContentSize()

	if arg_4_0.isSelect == xyd.WarCampSelectType.NONE then
		arg_4_0:nodeByName("entrance"):setVisible(true)
		arg_4_0:nodeByName("select_camp"):setVisible(false)
		arg_4_0:nodeByName("camp_left"):setVisible(false)
		arg_4_0:nodeByName("camp_right"):setVisible(false)
		arg_4_0:nodeByName("hero"):setVisible(false)
		arg_4_0:nodeByName("time_bg"):setTexture("windows/war_camp/entrance/time_bg_1.png")
		arg_4_0:nodeByName("close_2"):setVisible(false)
		arg_4_0:nodeByName("bg_1"):setVisible(false)
		arg_4_0:nodeByName("bg_2"):setVisible(false)
		arg_4_0:nodeByName("start_bg"):setVisible(true)
		arg_4_0:nodeByName("days_panel"):setVisible(false)
		arg_4_0:setupEntranceBtn()
	elseif arg_4_0.isSelect == xyd.WarCampSelectType.LEFT then
		arg_4_0:nodeByName("entrance"):setVisible(false)
		arg_4_0:nodeByName("select_camp"):setVisible(false)
		arg_4_0:nodeByName("camp_left"):setVisible(true)
		arg_4_0:nodeByName("camp_right"):setVisible(false)
		arg_4_0:nodeByName("time_bg"):setTexture("windows/war_camp/entrance/time_bg_1.png")
		arg_4_0:nodeByName("close_2"):setVisible(false)
		arg_4_0:nodeByName("bg_1"):setVisible(true)
		arg_4_0:nodeByName("bg_2"):setVisible(false)
		arg_4_0:nodeByName("start_bg"):setVisible(false)
		arg_4_0:nodeByName("days_panel"):setVisible(true)
		arg_4_0:nodeByName("panel_1"):setVisible(true)
		arg_4_0:nodeByName("panel_2"):setVisible(false)
		arg_4_0:layoutDaysPanel(xyd.WarCampSelectType.LEFT)
		arg_4_0:setupLeftCampBtn()
		arg_4_0:initHeroModel()
	else
		arg_4_0:nodeByName("entrance"):setVisible(false)
		arg_4_0:nodeByName("select_camp"):setVisible(false)
		arg_4_0:nodeByName("camp_left"):setVisible(false)
		arg_4_0:nodeByName("camp_right"):setVisible(true)
		arg_4_0:nodeByName("time_bg"):setTexture("windows/war_camp/entrance/time_bg_2.png")
		arg_4_0:nodeByName("close"):setVisible(false)
		arg_4_0:nodeByName("bg_1"):setVisible(false)
		arg_4_0:nodeByName("bg_2"):setVisible(true)
		arg_4_0:nodeByName("start_bg"):setVisible(false)
		arg_4_0:nodeByName("close_2"):setVisible(true)
		arg_4_0:nodeByName("days_panel"):setVisible(true)
		arg_4_0:nodeByName("panel_1"):setVisible(false)
		arg_4_0:nodeByName("panel_2"):setVisible(true)
		arg_4_0:layoutDaysPanel(xyd.WarCampSelectType.RIGHT)
		arg_4_0:setupRightCampBtn()
		arg_4_0:initHeroModel()
	end
end

function var_0_0.layoutDaysPanel(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0:nodeByName("panel_" .. arg_5_1)
	local var_5_1 = arg_5_0.activity.details.daily_wins
	local var_5_2 = #(var_5_1 or {})

	for iter_5_0 = 1, var_5_2 do
		local var_5_3

		if var_5_1[iter_5_0] == arg_5_1 then
			var_5_3 = xyd.AssetLoader.get():loadSprite("windows/war_camp/entrance/win.png")
		elseif var_5_1[iter_5_0] == 3 - arg_5_1 then
			var_5_3 = xyd.AssetLoader.get():loadSprite("windows/war_camp/entrance/lose.png")
		elseif var_5_1[iter_5_0] == 0 then
			var_5_3 = xyd.AssetLoader.get():loadSprite("windows/war_camp/entrance/draw.png")
		end

		if var_5_3 then
			var_5_3:addTo(arg_5_0:nodeByName("day_bg_" .. arg_5_1 .. "_" .. iter_5_0))
			var_5_3:setAnchorPoint(cc.p(0.5, 0.5))
			var_5_3:setPosition(44, 40)
		end
	end

	local var_5_4

	if xyd.ServerTime.get():getSecondsOfDay() >= var_0_7 and xyd.ServerTime.get():getSecondsOfDay() < var_0_8 then
		var_5_4 = xyd.AssetLoader.get():loadSprite("windows/war_camp/entrance/fighting_" .. arg_5_1 .. ".png")

		if var_5_2 + 1 <= 7 then
			var_5_4:addTo(arg_5_0:nodeByName("day_bg_" .. arg_5_1 .. "_" .. var_5_2 + 1))
		end
	elseif xyd.ServerTime.get():getSecondsOfDay() >= var_0_8 or xyd.ServerTime.get():getSecondsOfDay() < var_0_7 then
		var_5_4 = xyd.AssetLoader.get():loadSprite("windows/war_camp/entrance/rest_" .. arg_5_1 .. ".png")

		if var_5_2 + 1 <= 7 then
			var_5_4:addTo(arg_5_0:nodeByName("day_bg_" .. arg_5_1 .. "_" .. var_5_2 + 1))
		end
	end

	var_5_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_4:setPosition(44, 40)

	for iter_5_1 = 1, 7 do
		arg_5_0:nodeByName("day_txt_" .. arg_5_1 .. "_" .. iter_5_1):setString(string.format(var_0_5:translation("WAR_CAMP_DAY_TXT"), var_0_5:translation("NUM_" .. iter_5_1)))
	end
end

function var_0_0.setupEntranceBtn(arg_6_0)
	arg_6_0:nodeByName("btn_add"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_6_0:checkCanShowSelectCamp() then
				arg_6_0:showSelectWnd()
			end
		end
	end)
	arg_6_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_8_0 = {
				rule = "CAMP_WAR_RULES_TEXT",
				title_name = "CAMP_WAR_RULES_TITLE"
			}

			xyd.WindowManager.get():openWindow("text_rule", var_8_0)
		end
	end)
	arg_6_0:nodeByName("btn_select_random"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_9_0 = var_0_5:translation("WAR_CAMP_ENTRANCE_TIPS_7")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
				arg_6_0.warCamp_:apply(xyd.WarCampSelectType.RANDOM, function(arg_11_0, arg_11_1)
					if arg_11_0 == xyd.error.OK then
						arg_6_0.selfPlayer:handleRewards(arg_11_1.awards)

						arg_6_0.isSelect = arg_6_0.warCamp_:getCampType()

						if arg_6_0.isSelect == xyd.WarCampSelectType.LEFT then
							arg_6_0:showLeftCamp()
						else
							arg_6_0:showRightCamp()
						end
					end
				end)
			end, nil, nil, arg_6_0.colorMode)
		end
	end)
	arg_6_0:nodeByName("btn_select_left"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended and arg_6_0:checkCanSelectCamp(xyd.WarCampSelectType.LEFT) then
			xyd.playButtonSound()

			local var_12_0 = var_0_5:translation("WAR_CAMP_ENTRANCE_TIPS_1")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_0, function()
				arg_6_0.warCamp_:apply(xyd.WarCampSelectType.LEFT, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						arg_6_0.isSelect = arg_6_0.warCamp_:getCampType()

						arg_6_0:showLeftCamp()
					end
				end)
			end, nil, nil, arg_6_0.colorMode)
		end
	end)
	arg_6_0:nodeByName("btn_select_right"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended and arg_6_0:checkCanSelectCamp(xyd.WarCampSelectType.RIGHT) then
			xyd.playButtonSound()

			local var_15_0 = var_0_5:translation("WAR_CAMP_ENTRANCE_TIPS_2")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_0, function()
				arg_6_0.warCamp_:apply(xyd.WarCampSelectType.RIGHT, function(arg_17_0, arg_17_1)
					if arg_17_0 == xyd.error.OK then
						arg_6_0.isSelect = arg_6_0.warCamp_:getCampType()

						arg_6_0:showRightCamp()
					end
				end)
			end, nil, nil, arg_6_0.colorMode)
		end
	end)
end

function var_0_0.setupLeftCampBtn(arg_18_0)
	if arg_18_0.isSelect == xyd.WarCampSelectType.LEFT then
		arg_18_0:nodeByName("start_battle_left"):addTouchEventListener(function(arg_19_0, arg_19_1)
			if arg_19_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_18_0.warCamp_:getInfos(function(arg_20_0, arg_20_1)
					if arg_20_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("war_camp_map")
					end
				end)
			end
		end)
		arg_18_0:nodeByName("btn_exchange_left"):addTouchEventListener(function(arg_21_0, arg_21_1)
			if arg_21_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow("war_camp_shop")
			end
		end)
		arg_18_0:nodeByName("btn_mission_left"):addTouchEventListener(function(arg_22_0, arg_22_1)
			if arg_22_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow("war_camp_mission")
			end
		end)
		arg_18_0:nodeByName("btn_rule_left"):addTouchEventListener(function(arg_23_0, arg_23_1)
			if arg_23_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_23_0 = {
					rule = "CAMP_WAR_RULES_TEXT",
					title_name = "CAMP_WAR_RULES_TITLE"
				}

				xyd.WindowManager.get():openWindow("text_rule", var_23_0)
			end
		end)
	end
end

function var_0_0.setupRightCampBtn(arg_24_0)
	if arg_24_0.isSelect == xyd.WarCampSelectType.RIGHT then
		arg_24_0:nodeByName("start_battle_right"):addTouchEventListener(function(arg_25_0, arg_25_1)
			if arg_25_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_24_0.warCamp_:getInfos(function(arg_26_0, arg_26_1)
					if arg_26_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("war_camp_map")
					end
				end)
			end
		end)
		arg_24_0:nodeByName("btn_exchange_right"):addTouchEventListener(function(arg_27_0, arg_27_1)
			if arg_27_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow("war_camp_shop")
			end
		end)
		arg_24_0:nodeByName("btn_mission_right"):addTouchEventListener(function(arg_28_0, arg_28_1)
			if arg_28_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow("war_camp_mission")
			end
		end)
		arg_24_0:nodeByName("btn_rule_right"):addTouchEventListener(function(arg_29_0, arg_29_1)
			if arg_29_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_29_0 = {
					rule = "CAMP_WAR_RULES_TEXT",
					title_name = "CAMP_WAR_RULES_TITLE"
				}

				xyd.WindowManager.get():openWindow("text_rule", var_29_0)
			end
		end)
		arg_24_0:nodeByName("close_2"):addTouchEventListener(function(arg_30_0, arg_30_1)
			if arg_30_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.WindowManager.get():closeWindow(arg_24_0)
			end
		end)
	end
end

function var_0_0.checkCanShowSelectCamp(arg_31_0)
	local var_31_0 = xyd.ServerTime.get():getServerTime()
	local var_31_1 = arg_31_0.warCamp_:getDayCount()

	if var_31_0 < arg_31_0.activity.start_time then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("ACTIVITY_NO_OPEN")
		})

		return false
	elseif var_31_0 > arg_31_0.activity.end_time then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("ACTIVITY_END")
		})

		return false
	end

	if var_0_4:isOpenJoin(var_31_1) == 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("WAR_CAMP_ENTRANCE_TIPS_3")
		})

		return false
	end

	return true
end

function var_0_0.checkCanSelectCamp(arg_32_0, arg_32_1)
	local var_32_0 = arg_32_0.activity.details.sign_info
	local var_32_1 = xyd.tables.misc.campWarNumDifference
	local var_32_2 = true
	local var_32_3 = ""

	if arg_32_1 == xyd.WarCampSelectType.LEFT and var_32_1 <= var_32_0.group_1 - var_32_0.group_2 then
		var_32_2 = false
		var_32_3 = var_0_5:translation("WAR_CAMP_ENTRANCE_TIPS_5")
	elseif arg_32_1 == xyd.WarCampSelectType.RIGHT and var_32_1 <= var_32_0.group_2 - var_32_0.group_1 then
		var_32_2 = false
		var_32_3 = var_0_5:translation("WAR_CAMP_ENTRANCE_TIPS_6")
	end

	if not var_32_2 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_32_3
		})
	end

	return var_32_2
end

function var_0_0.checkCanStartFight(arg_33_0)
	local var_33_0 = xyd.ServerTime.get():getServerTime()
	local var_33_1 = arg_33_0.warCamp_:getDayCount()

	if var_33_0 < arg_33_0.activity.start_time then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("ACTIVITY_NO_OPEN")
		})

		return false
	elseif var_33_0 > arg_33_0.activity.end_time then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("ACTIVITY_END")
		})

		return false
	end

	if var_0_4:isOpenWar(var_33_1) == 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("WAR_CAMP_ENTRANCE_TIPS_4")
		})

		return false
	end

	if xyd.ServerTime.get():getSecondsOfDay() >= var_0_8 or xyd.ServerTime.get():getSecondsOfDay() < var_0_7 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_5:translation("ACTIVITY_NO_OPEN")
		})

		return false
	end

	return true
end

function var_0_0.showSelectWnd(arg_34_0)
	arg_34_0:nodeByName("entrance"):setVisible(false)
	arg_34_0:nodeByName("select_camp"):setVisible(true)
end

function var_0_0.initHeroModel(arg_35_0)
	if arg_35_0.isSelect == xyd.WarCampSelectType.NONE then
		return
	end

	local var_35_0 = 0
	local var_35_1 = 0
	local var_35_2 = cc.p(0, 0)
	local var_35_3 = false

	if arg_35_0.isSelect == xyd.WarCampSelectType.LEFT then
		var_35_0 = 10001158
		var_35_1 = 10001158
		var_35_2 = cc.p(820, 90)
		var_35_3 = true
	else
		var_35_0 = 10001157
		var_35_1 = 10001157
		var_35_2 = cc.p(205, 200)
	end

	local var_35_4 = xyd.HeroAnimation.new(var_35_0, var_35_1, var_0_3:uiScale(var_35_1), {})

	if var_35_4 then
		var_35_4:idle()
		var_35_4:setScale(0.85)
	end

	var_35_4:setFlipX(var_35_3)
	var_35_4:addTo(arg_35_0:nodeByName("hero")):pos(100, 0)
	arg_35_0:nodeByName("hero"):setPosition(cc.p(var_35_2))

	arg_35_0.heroModel = var_35_4
end

function var_0_0.getTimeText(arg_36_0)
	local var_36_0 = xyd.ServerTime.get():getServerTime()
	local var_36_1 = arg_36_0.activity.start_time
	local var_36_2 = arg_36_0.activity.end_time
	local var_36_3 = arg_36_0.warCamp_:getDayCount()
	local var_36_4 = (var_0_4:getOpenWarDay() - 1) * var_0_6 + var_36_1
	local var_36_5 = (var_0_4:getEndWarDay() - 1) * var_0_6 + var_36_1
	local var_36_6 = ""
	local var_36_7 = 0

	if var_36_0 < var_36_1 then
		var_36_7 = var_36_1 - var_36_0
		var_36_6 = var_0_5:translation("WAR_CAMP_ACTIVITY_START")
	elseif var_36_1 < var_36_0 and var_36_0 <= var_36_4 then
		var_36_7 = var_36_4 - var_36_0
		var_36_6 = var_0_5:translation("WAR_CAMP_WAR_START")
	elseif var_36_5 < var_36_0 and var_36_0 <= var_36_2 then
		var_36_7 = var_36_2 - var_36_0
		var_36_6 = var_0_5:translation("WAR_CAMP_ACTIVITY_END")
	elseif xyd.ServerTime.get():getSecondsOfDay() >= var_0_7 and xyd.ServerTime.get():getSecondsOfDay() < var_0_8 then
		var_36_7 = var_0_8 - xyd.ServerTime.get():getSecondsOfDay()
		var_36_6 = var_0_5:translation("WAR_CAMP_WAR_END")
	elseif xyd.ServerTime.get():getSecondsOfDay() >= var_0_8 then
		var_36_7 = var_0_6 + var_0_7 - xyd.ServerTime.get():getSecondsOfDay()
		var_36_6 = var_0_5:translation("WAR_CAMP_WAR_START")
	elseif xyd.ServerTime.get():getSecondsOfDay() < var_0_7 then
		var_36_7 = var_0_7 - xyd.ServerTime.get():getSecondsOfDay()
		var_36_6 = var_0_5:translation("WAR_CAMP_WAR_START")
	end

	return var_36_7, var_36_6
end

function var_0_0.updateTimeCount(arg_37_0)
	if arg_37_0.handle_ then
		var_0_1.unscheduleGlobal(arg_37_0.handle_)
	end

	local var_37_0, var_37_1 = arg_37_0:getTimeText()

	if var_37_0 <= 0 then
		arg_37_0:nodeByName("text_time"):setString(var_37_1 .. "00:00:00")

		return
	end

	local function var_37_2(arg_38_0)
		if arg_38_0 > var_0_6 then
			return xyd.secondsToString1(arg_38_0, 3)
		end

		return xyd.secondsToString(arg_38_0)
	end

	arg_37_0:nodeByName("text_time"):setString(var_37_1 .. var_37_2(var_37_0))

	arg_37_0.handle_ = var_0_1.scheduleGlobal(function()
		if arg_37_0 and not tolua.isnull(arg_37_0) then
			var_37_0 = var_37_0 - 1

			arg_37_0:nodeByName("text_time"):setString(var_37_1 .. var_37_2(var_37_0))

			if var_37_0 == 0 and arg_37_0.handle_ then
				var_0_1.unscheduleGlobal(arg_37_0.handle_)

				arg_37_0.handle_ = nil
			end
		elseif arg_37_0.handle_ then
			var_0_1.unscheduleGlobal(arg_37_0.handle_)

			arg_37_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.willClose(arg_40_0)
	if arg_40_0.handle_ then
		var_0_1.unscheduleGlobal(arg_40_0.handle_)

		arg_40_0.handle_ = nil
	end
end

function var_0_0.createEffect(arg_41_0, arg_41_1, arg_41_2)
	local var_41_0 = arg_41_1 .. ".json"
	local var_41_1 = arg_41_1 .. ".atlas"
	local var_41_2 = var_0_2.new(var_41_0, var_41_1, 1)

	var_41_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_41_2:setPosition(cc.p(640, 360))
	var_41_2:play(arg_41_2, false)
	var_41_2:addTo(arg_41_0)

	return var_41_2
end

function var_0_0.showLeftCamp(arg_42_0)
	local var_42_0 = "skeletons/ui_effect/war_camp/demon_toggle"
	local var_42_1 = arg_42_0:createEffect(var_42_0)

	arg_42_0:showBasicLayout()

	local var_42_2 = arg_42_0:nodeByName("container"):getContentSize()

	arg_42_0:fadeInAction(arg_42_0:nodeByName("camp_left"), function()
		arg_42_0:setupLeftCampBtn()
	end)
	arg_42_0:fadeInAction(arg_42_0:nodeByName("hero"))
end

function var_0_0.showRightCamp(arg_44_0)
	local var_44_0 = "skeletons/ui_effect/war_camp/angel_toggle"
	local var_44_1 = arg_44_0:createEffect(var_44_0)

	arg_44_0:showBasicLayout()
	arg_44_0:fadeInAction(arg_44_0:nodeByName("camp_right"), function()
		arg_44_0:setupRightCampBtn()
	end)
	arg_44_0:fadeInAction(arg_44_0:nodeByName("hero"))
end

function var_0_0.fadeInAction(arg_46_0, arg_46_1, arg_46_2)
	arg_46_1:setVisible(true)
	arg_46_0:widgetSet(arg_46_1)
	arg_46_1:setCascadeOpacityEnabled(true)
	arg_46_1:setOpacity(0)
	arg_46_1:runActionOnce(cc.FadeIn:create(0.4), false, arg_46_2)
end

function var_0_0.widgetSet(arg_47_0, arg_47_1)
	for iter_47_0, iter_47_1 in ipairs(arg_47_1:getChildren()) do
		if iter_47_1 ~= nil then
			iter_47_1:setCascadeOpacityEnabled(true)
			arg_47_0:widgetSet(iter_47_1)
		end
	end
end

return var_0_0
