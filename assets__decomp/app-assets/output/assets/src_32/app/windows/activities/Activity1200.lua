local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySevenDay
local var_0_3 = xyd.tables.gift
local var_0_4 = 1
local var_0_5 = 2
local var_0_6 = 3
local var_0_7 = 0

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.idx = arg_1_1.idx
	arg_1_0.parent = arg_1_1.parent
	arg_1_0.get = {}
	arg_1_0.details = {}
	arg_1_0.hasFirstSelect = false
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	local var_2_0 = {
		activity_id = xyd.Activities.NewSevenDayLogin
	}

	arg_2_0.activitiesModel:loadSingleActivity(var_2_0, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0.details = arg_3_1.details

			arg_2_0:layout()
		end
	end)
end

function var_0_0.layout(arg_4_0)
	for iter_4_0 = 1, #arg_4_0.details.is_award do
		if iter_4_0 <= arg_4_0.details.login_day then
			if arg_4_0.details.is_award[iter_4_0] == 0 then
				arg_4_0.get[iter_4_0] = var_0_5
			else
				arg_4_0.get[iter_4_0] = var_0_6
			end
		else
			arg_4_0.get[iter_4_0] = var_0_4
		end
	end

	arg_4_0.centre = xyd.AssetLoader.get():loadNodeFromJson("windows/new_seven_day_login/seven_day_login.csb")

	arg_4_0.centre:addTo(arg_4_0.parent)

	arg_4_0.nowDay = 1

	local var_4_0 = arg_4_0.centre:getChildByName("container")
	local var_4_1 = var_4_0:getChildByName("ad_container")

	var_4_0:getChildByName("rule_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(var_4_0:getChildByName("rule_btn"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {
				title_name = "ACTIVITY_SEVENDAY_INFO7",
				rule = "ACTIVITY_SEVENDAY_INFO8",
				style = xyd.RuleStyle.BLUE
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_5_0)
		end
	end)

	for iter_4_1 = 1, 7 do
		arg_4_0:setDayState(iter_4_1, arg_4_0.get[iter_4_1], false)
		var_4_0:getChildByName("day" .. iter_4_1):setTouchEnabled(true)
		var_4_0:getChildByName("day" .. iter_4_1):getChildByName("day" .. iter_4_1 .. "_txt"):setString(var_0_2:date(iter_4_1))

		local var_4_2 = var_4_0:getChildByName("day" .. iter_4_1):getChildByName("item")
		local var_4_3 = var_0_2:awardGiftId(iter_4_1)
		local var_4_4 = var_0_3:items(var_4_3)
		local var_4_5 = var_0_3:itemNum(var_4_3)

		xyd.setItemBorder(var_4_2, var_4_4[1], nil, nil, 1)
		var_4_0:getChildByName("day" .. iter_4_1):setLocalZOrder(100)

		if not arg_4_0.hasFirstSelect and arg_4_0.get[iter_4_1] == var_0_5 then
			arg_4_0.firstInSelect = iter_4_1
			arg_4_0.hasFirstSelect = true
		end
	end

	if not arg_4_0.firstInSelect then
		arg_4_0.firstInSelect = 1
	end

	arg_4_0:setDayState(arg_4_0.firstInSelect, arg_4_0.get[arg_4_0.firstInSelect], true)
	arg_4_0:showDay(arg_4_0.firstInSelect)

	arg_4_0.selectDay = arg_4_0.firstInSelect

	for iter_4_2 = 1, 7 do
		var_4_0:getChildByName("day" .. iter_4_2):getChildByName("touch_container"):addTouchEventListener(function(arg_6_0, arg_6_1)
			xyd.buttonScaleAnim(var_4_0:getChildByName("day" .. iter_4_2), arg_6_1)

			if arg_6_1 == ccui.TouchEventType.ended then
				arg_4_0:setDayState(arg_4_0.selectDay, arg_4_0.get[arg_4_0.selectDay], false)

				arg_4_0.selectDay = iter_4_2

				arg_4_0:showDay(arg_4_0.selectDay)
				arg_4_0:setDayState(arg_4_0.selectDay, arg_4_0.get[arg_4_0.selectDay], true)
			end
		end)
	end

	var_4_1:getChildByName("get_award_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(var_4_1:getChildByName("get_award_btn"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			if arg_4_0.get[arg_4_0.selectDay] == var_0_4 then
				local var_7_0 = var_0_1:translation("ACTIVITY_SEVENDAY_INFO5")

				if xyd.WindowManager.get():getWindow("toast") ~= nil then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_0
				})
			elseif arg_4_0.get[arg_4_0.selectDay] == var_0_6 then
				local var_7_1 = var_0_1:translation("ACTIVITY_SEVENDAY_INFO4")

				if xyd.WindowManager.get():getWindow("toast") ~= nil then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_1
				})
			elseif arg_4_0.get[arg_4_0.selectDay] == var_0_5 then
				arg_4_0.activitiesModel:getActivityReward(xyd.Activities.NewSevenDayLogin, arg_4_0.selectDay, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						dump(arg_8_1)

						if arg_8_1.awards then
							xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_8_1.awards)
						end

						arg_4_0.get[arg_4_0.selectDay] = var_0_6
						arg_4_0.activitiesModel:getActivityInfo(xyd.Activities.NewSevenDayLogin).details.is_award[arg_4_0.selectDay] = 1

						if arg_4_0.selectDay ~= 7 then
							arg_4_0:setDayState(arg_4_0.selectDay, arg_4_0.get[arg_4_0.selectDay], false)

							arg_4_0.selectDay = arg_4_0.selectDay + 1

							arg_4_0:showDay(arg_4_0.selectDay)
							arg_4_0:setDayState(arg_4_0.selectDay, arg_4_0.get[arg_4_0.selectDay], true)
						end

						arg_4_0.activitiesModel:refreshWalfareRedMark()

						local var_8_0 = {
							activity_id = xyd.Activities.NewSevenDayLogin
						}

						arg_4_0.activitiesModel:loadSingleActivity(var_8_0, function(arg_9_0, arg_9_1)
							if arg_9_0 == xyd.error.OK then
								if arg_9_1.is_open ~= 1 then
									local var_9_0 = xyd.WindowManager.get():getWindow("main_scene_top")

									if var_9_0 then
										var_9_0:updateTopBtn()
									end

									local var_9_1 = xyd.WindowManager.get():getWindow("walfare_activities")

									if var_9_1 then
										var_9_1:close()
									end
								else
									arg_4_0.details = arg_9_1.details
								end
							end
						end)
					end
				end)
			end
		end
	end)
end

function var_0_0.showDay(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0.centre:getChildByName("container")
	local var_10_1 = var_10_0:getChildByName("item_container")
	local var_10_2 = var_10_0:getChildByName("ad_container")
	local var_10_3 = var_0_2:mainitempicLabel(arg_10_1)

	var_10_0:getChildByName("refresh_txt"):setString(var_0_1:translation("ACTIVITY_SEVENDAY_INFO6"))
	var_10_1:getChildByName("main_res_bg"):getChildByName("item_name"):setString(var_0_2:mainitempicLabel(arg_10_1))
	var_10_2:getChildByName("describe_bg"):getChildByName("godlike_txt"):setString(var_0_2:adcopywritting3(arg_10_1))
	var_10_2:getChildByName("rare_txt"):setString(var_0_2:adcopywritting1(arg_10_1))
	var_10_2:getChildByName("free_txt"):setString(var_0_2:adcopywritting2(arg_10_1))

	local var_10_4 = var_0_2:mainitemPic(arg_10_1)

	var_10_1:getChildByName("icon_lvment"):setVisible(false)
	var_10_1:getChildByName("icon_yibu"):setVisible(false)
	var_10_1:getChildByName("icon_shilian"):setVisible(false)
	var_10_1:getChildByName("fumo_material"):setVisible(false)
	var_10_1:getChildByName("icon_crystal"):setVisible(false)
	var_10_1:getChildByName("icon_gold"):setVisible(false)
	var_10_1:getChildByName("feiyu"):setVisible(false)
	var_10_1:getChildByName(var_10_4):setVisible(true)

	local var_10_5 = var_0_2:awardGiftId(arg_10_1)
	local var_10_6 = var_0_3:items(var_10_5)
	local var_10_7 = var_0_3:itemNum(var_10_5)

	for iter_10_0 = 1, 3 do
		local var_10_8 = var_10_2:getChildByName("item_" .. iter_10_0)

		xyd.setItemAndAddTips(var_10_8, var_10_6[iter_10_0], var_10_7[iter_10_0])
	end
end

function var_0_0.setDayState(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = arg_11_0.centre:getChildByName("container")
	local var_11_1 = var_11_0:getChildByName("day" .. arg_11_1)
	local var_11_2 = var_11_0:getChildByName("ad_container")

	if arg_11_2 then
		if arg_11_2 == var_0_4 then
			var_11_2:getChildByName("get_award_btn"):setBright(false)
			var_11_2:getChildByName("get_award_btn"):getChildByName("award_txt"):setString(var_0_1:translation("ACTIVITY_SEVENDAY_INFO3"))
			var_11_1:getChildByName("bg_not_open"):setVisible(false)
			var_11_1:getChildByName("bg_not_open"):setVisible(true)
			var_11_1:getChildByName("bg_have_got"):setVisible(false)
			var_11_1:getChildByName("bg_can_get"):setVisible(false)
			var_11_1:getChildByName("bg_shadow"):setVisible(false)
			var_11_1:getChildByName("gou"):setVisible(false)
			var_11_1:getChildByName("select_shadow"):setVisible(false)
			var_11_1:getChildByName("day" .. arg_11_1 .. "_txt"):setVisible(true)
		elseif arg_11_2 == var_0_5 then
			var_11_2:getChildByName("get_award_btn"):setBright(true)
			var_11_2:getChildByName("get_award_btn"):getChildByName("award_txt"):setString(var_0_1:translation("ACTIVITY_SEVENDAY_INFO3"))
			var_11_1:getChildByName("bg_not_open"):setVisible(false)
			var_11_1:getChildByName("bg_not_open"):setVisible(false)
			var_11_1:getChildByName("bg_have_got"):setVisible(false)
			var_11_1:getChildByName("bg_can_get"):setVisible(true)
			var_11_1:getChildByName("bg_shadow"):setVisible(false)
			var_11_1:getChildByName("gou"):setVisible(false)
			var_11_1:getChildByName("select_shadow"):setVisible(false)
			var_11_1:getChildByName("day" .. arg_11_1 .. "_txt"):setVisible(true)
		elseif arg_11_2 == var_0_6 then
			var_11_2:getChildByName("get_award_btn"):setBright(false)
			var_11_2:getChildByName("get_award_btn"):getChildByName("award_txt"):setString(var_0_1:translation("ACTIVITY_SEVENDAY_INFO2"))
			var_11_1:getChildByName("bg_not_open"):setVisible(false)
			var_11_1:getChildByName("bg_have_got"):setVisible(true)
			var_11_1:getChildByName("bg_can_get"):setVisible(false)
			var_11_1:getChildByName("bg_shadow"):setVisible(true)
			var_11_1:getChildByName("gou"):setVisible(true)
			var_11_1:getChildByName("select_shadow"):setVisible(false)
			var_11_1:getChildByName("day" .. arg_11_1 .. "_txt"):setVisible(false)
		end
	end

	if arg_11_3 then
		var_11_1:getChildByName("select_shadow"):setVisible(true)
	else
		var_11_1:getChildByName("select_shadow"):setVisible(false)
	end
end

return var_0_0
