local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.activityLotteryConsume
local var_0_4 = var_0_3:getDays()

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.stage = arg_1_0.details.base_info.day_count
	arg_1_0.dispatcher = nil
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(33, 23)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.container:getChildByName("btn_rule"):getChildByName("rule_text"):setString(var_0_1:translation("FOURTH_ANNI_MAIN_TXT1"))
	arg_3_0.container:getChildByName("btn_check"):getChildByName("text_check"):setString(var_0_1:translation("BIG_BONUS"))
	arg_3_0.container:getChildByName("btn_buy"):getChildByName("text_buy"):setString(var_0_1:translation("MAP_BUY"))
	arg_3_0.container:getChildByName("btn_num"):getChildByName("text_choose"):setString(var_0_1:translation("BACKPACK_USE"))
	arg_3_0.container:getChildByName("btn_num"):getChildByName("text_view"):setString(var_0_1:translation("SUMMON_BUTTON_CHAKAN"))
	arg_3_0.container:getChildByName("change_bg"):getChildByName("btn_change"):getChildByName("word_duihuan"):setString(var_0_1:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT2"))
	arg_3_0.container:getChildByName("text_item_none"):setString(var_0_1:translation("ACTIVITY_LOTTERY_TIP1"))
	arg_3_0.container:getChildByName("text_player_none"):setString(var_0_1:translation("ACTIVITY_LOTTERY_TIP2"))
	arg_3_0.container:getChildByName("text_time_title"):setString(var_0_1:translation("ACTIVITY_LOTTERY_TIP4"))
	arg_3_0.container:getChildByName("text_lucky_num_title"):setString(var_0_1:translation("ACTIVITY_LOTTERY_TIP5"))

	if arg_3_0.details.base_info.extra_times > 0 and arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityLotteryConsumeItem) > 0 then
		local var_3_0 = {
			itemID = xyd.tables.misc.activityLotteryConsumeItem,
			itemNum = arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityLotteryConsumeItem)
		}

		arg_3_0.selfPlayer:getBackpack():removeItem(var_3_0)
	end

	arg_3_0:updateWnd()
	arg_3_0:setButtonClick()
end

function var_0_0.updateWnd(arg_4_0)
	arg_4_0.stageCount = arg_4_0.details.base_info.day_count % var_0_4

	if arg_4_0.stageCount == 0 then
		arg_4_0.stageCount = var_0_4
	end

	if xyd.ServerTime.get():getServerTime() < arg_4_0.activity.start_time then
		arg_4_0.container:getChildByName("text_item"):setVisible(false)
		arg_4_0.container:getChildByName("text_item_num"):setVisible(false)
		arg_4_0.container:getChildByName("text_stage"):setString("1")
		arg_4_0.container:getChildByName("btn_check"):setBright(false)
		arg_4_0.container:getChildByName("btn_check"):setTouchEnabled(false)
		arg_4_0.container:getChildByName("text_player"):setVisible(false)
		arg_4_0.container:getChildByName("text_player_region"):setVisible(false)
		arg_4_0.container:getChildByName("text_player_none"):setVisible(true)
		arg_4_0.container:getChildByName("text_item_none"):setVisible(true)
		arg_4_0.container:getChildByName("btn_check"):setTouchEnabled(false)
	else
		arg_4_0:rewardLayer(arg_4_0.container:getChildByName("item"), arg_4_0.stageCount)
		arg_4_0.container:getChildByName("text_item"):setString(xyd.tables.item:name(xyd.tables.gift:items(var_0_3:giftID(arg_4_0.stageCount))[1]))

		if xyd.tables.gift:itemNum(var_0_3:giftID(arg_4_0.stageCount))[1] ~= 0 then
			arg_4_0.container:getChildByName("text_item_num"):setString("X " .. xyd.tables.gift:itemNum(var_0_3:giftID(arg_4_0.stageCount))[1])
		elseif xyd.tables.gift:crystal(var_0_3:giftID(arg_4_0.stageCount)) ~= 0 then
			arg_4_0.container:getChildByName("text_item"):setString(xyd.tables.translation:translation("CRYSTAL"))
			arg_4_0.container:getChildByName("text_item_num"):setString("X " .. xyd.tables.gift:crystal(var_0_3:giftID(arg_4_0.stageCount)))
		end

		arg_4_0.container:getChildByName("text_stage"):setString(arg_4_0.details.base_info.day_count)
		arg_4_0.container:getChildByName("text_item_none"):setVisible(false)

		if arg_4_0.details.base_info.day_count <= 1 then
			arg_4_0.container:getChildByName("btn_check"):setBright(false)
			arg_4_0.container:getChildByName("btn_check"):setTouchEnabled(false)
			arg_4_0.container:getChildByName("text_player"):setVisible(false)
			arg_4_0.container:getChildByName("text_player_region"):setVisible(false)
			arg_4_0.container:getChildByName("text_player_none"):setVisible(true)
			arg_4_0.container:getChildByName("btn_check"):setTouchEnabled(false)
		else
			arg_4_0.container:getChildByName("btn_check"):setTouchEnabled(true)
			arg_4_0.container:getChildByName("text_player_none"):setVisible(false)
			arg_4_0.container:getChildByName("btn_check"):setBright(true)
			arg_4_0.container:getChildByName("btn_check"):setTouchEnabled(true)
			arg_4_0.container:getChildByName("text_player"):setVisible(true)
			arg_4_0.container:getChildByName("text_player_region"):setVisible(true)

			if arg_4_0.details.total_info.old_award_info.major_award_info then
				arg_4_0.container:getChildByName("text_player_region"):setString("S" .. xyd.getPlayerRegion(arg_4_0.details.total_info.old_award_info.major_award_info.player_id))
				arg_4_0.container:getChildByName("text_player"):setString(arg_4_0.details.total_info.old_award_info.major_award_info.player_name)

				local var_4_0 = arg_4_0.container:getChildByName("text_player_touch")
				local var_4_1 = {
					to_player_id = arg_4_0.details.total_info.old_award_info.major_award_info.player_id,
					sub_type = xyd.PlayerCardButtonStyle.MAIN,
					isRobot = xyd.checkPlayerIsRobot(arg_4_0.details.total_info.old_award_info.major_award_info.player_id),
					player_info = arg_4_0.details.total_info.old_award_info.major_award_info
				}

				var_4_0:addTouchEventListener(function(arg_5_0, arg_5_1)
					if arg_5_1 == ccui.TouchEventType.began then
						return true
					elseif arg_5_1 == ccui.TouchEventType.ended then
						local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.PERSON_DISPLAY)

						if var_5_0:checkCanTouch() then
							var_5_0:getPlayerInfo(var_4_1, function(arg_6_0, arg_6_1)
								if arg_6_0 == xyd.error.OK then
									var_5_0:updateTouchCount(true)

									if xyd.WindowManager.get():isWindowOpen("person_praise") then
										xyd.WindowManager.get():closeWindow("person_praise")
									end

									if xyd.WindowManager.get():isWindowOpen("person_display") then
										xyd.WindowManager.get():closeWindow("person_display")
									end

									xyd.WindowManager.get():openWindow("person_display")
								end
							end, true)
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = xyd.tables.translation:translation("PERSON_NOT_TOUCH_MORE")
							})
						end
					end
				end)
			else
				arg_4_0.container:getChildByName("text_player_region"):setVisible(false)
				arg_4_0.container:getChildByName("text_player"):setVisible(false)
			end
		end
	end

	arg_4_0.container:getChildByName("change_bg"):getChildByName("score"):setString(arg_4_0.details.base_info.point)
	arg_4_0.container:getChildByName("text_lucky_num"):setString(#arg_4_0.details.base_info.selected_nums .. "/" .. arg_4_0.details.base_info.can_select_times)
	arg_4_0:updateTimeCount(arg_4_0.container, activity)

	if arg_4_0.details.base_info.can_select_times - #arg_4_0.details.base_info.selected_nums > 0 and #arg_4_0.details.total_info.total_selected_nums < var_0_3:ticketNum(arg_4_0.stageCount) then
		arg_4_0.container:getChildByName("btn_num"):getChildByName("text_choose"):setVisible(true)
		arg_4_0.container:getChildByName("btn_num"):getChildByName("text_view"):setVisible(false)

		arg_4_0.canChoose = true
	else
		arg_4_0.canChoose = false

		arg_4_0.container:getChildByName("btn_num"):getChildByName("text_choose"):setVisible(false)
		arg_4_0.container:getChildByName("btn_num"):getChildByName("text_view"):setVisible(true)
	end
end

function var_0_0.setButtonClick(arg_7_0)
	arg_7_0.container:getChildByName("btn_num"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_7_0.container:getChildByName("btn_num"):setScale(0.9, 0.9)
		end

		if arg_8_1 == ccui.TouchEventType.moved then
			arg_7_0.container:getChildByName("btn_num"):setScale(1, 1)
		end

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_7_0.container:getChildByName("btn_num"):setScale(1, 1)

			local var_8_0 = arg_7_0.details
			local var_8_1 = var_0_1:translation("LOTTERY_NUMBER_TIPS")
			local var_8_2 = {
				lcallBefore = 0,
				touchClose = true,
				leftName = var_0_1:translation("AUTO_CHOOSE"),
				rightName = var_0_1:translation("PLAYER_CHOOSE"),
				lcallback = function()
					if yes then
						xyd.WindowManager.get():openWindow("lottery_number_consume", var_8_0)
					else
						local function var_9_0(arg_10_0)
							local var_10_0 = {
								num = arg_10_0
							}

							xyd.Backend.get():request(xyd.mid.LOTTERY_CONSUME_AUTO_SELECT_NUMS, var_10_0, function(arg_11_0, arg_11_1)
								if arg_11_0 == xyd.error.OK then
									local var_11_0 = ""

									for iter_11_0, iter_11_1 in pairs(arg_11_1.nums) do
										if iter_11_0 % 10 == 1 then
											var_11_0 = var_11_0 .. "\n"
										end

										table.insert(arg_7_0.details.base_info.selected_nums, tonumber(iter_11_1))
										table.insert(arg_7_0.details.total_info.total_selected_nums, tonumber(iter_11_1))

										var_11_0 = var_11_0 .. iter_11_1 .. "  "
									end

									if var_0_3:ticketNum(arg_7_0.stageCount) <= #arg_7_0.details.total_info.total_selected_nums then
										local var_11_1 = {
											activity_id = xyd.Activities.LotteryConsume
										}

										xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_11_1, function(arg_12_0, arg_12_1)
											if arg_12_0 == xyd.error.OK then
												arg_7_0.details = arg_12_1.details

												arg_7_0:updateWnd()
											end
										end)
									else
										arg_7_0:updateWnd()
									end

									if #arg_11_1.nums > 20 then
										xyd.WindowManager.get():openWindow("toast", {
											message = string.format(var_0_1:translation("LOTTERY_AUTO_SELECT2"), tostring(#arg_11_1.nums))
										})
									else
										xyd.WindowManager.get():openWindow("toast", {
											delay = 5,
											message = var_0_1:translation("LOTTERY_AUTO_SELECT") .. var_11_0
										})
									end
								else
									xyd.WindowManager.get():openWindow("toast", {
										message = var_0_1:translation("LOTTERY_AUTO_SELECT3")
									})

									local var_11_2 = {
										activity_id = xyd.Activities.LotteryConsume
									}

									xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_11_2, function(arg_13_0, arg_13_1)
										if arg_13_0 == xyd.error.OK then
											arg_7_0.details = arg_13_1.details

											arg_7_0:updateWnd()
										end
									end)
								end
							end)
						end

						local var_9_1 = {
							times = arg_7_0.details.base_info.can_select_times - #arg_7_0.details.base_info.selected_nums,
							canSelectNums = var_0_3:ticketNum(arg_7_0.stageCount) - #arg_7_0.details.total_info.total_selected_nums,
							callback = var_9_0
						}

						xyd.WindowManager.get():openWindow("lottery_use_consume", var_9_1)
					end
				end
			}

			if arg_7_0.canChoose and xyd.ServerTime.get():getServerTime() >= arg_7_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_7_0.activity.end_time then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					var_0_1:translation("LOTTERY_NUMBER_TIPS")
				}, function(arg_14_0)
					if arg_14_0 then
						xyd.WindowManager.get():openWindow("lottery_number_consume", var_8_0)
					else
						local function var_14_0(arg_15_0)
							local var_15_0 = {
								num = arg_15_0
							}

							xyd.Backend.get():request(xyd.mid.LOTTERY_CONSUME_AUTO_SELECT_NUMS, var_15_0, function(arg_16_0, arg_16_1)
								if arg_16_0 == xyd.error.OK then
									local var_16_0 = ""

									for iter_16_0, iter_16_1 in pairs(arg_16_1.nums) do
										if iter_16_0 % 10 == 1 then
											var_16_0 = var_16_0 .. "\n"
										end

										table.insert(arg_7_0.details.base_info.selected_nums, tonumber(iter_16_1))
										table.insert(arg_7_0.details.total_info.total_selected_nums, tonumber(iter_16_1))

										var_16_0 = var_16_0 .. iter_16_1 .. "  "
									end

									if var_0_3:ticketNum(arg_7_0.stageCount) <= #arg_7_0.details.total_info.total_selected_nums then
										local var_16_1 = {
											activity_id = xyd.Activities.LotteryConsume
										}

										xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_16_1, function(arg_17_0, arg_17_1)
											if arg_17_0 == xyd.error.OK then
												arg_7_0.details = arg_17_1.details

												arg_7_0:updateWnd()
											end
										end)
									else
										arg_7_0:updateWnd()
									end

									if #arg_16_1.nums > 20 then
										xyd.WindowManager.get():openWindow("toast", {
											message = string.format(var_0_1:translation("LOTTERY_AUTO_SELECT2"), tostring(#arg_16_1.nums))
										})
									else
										xyd.WindowManager.get():openWindow("toast", {
											delay = 5,
											message = var_0_1:translation("LOTTERY_AUTO_SELECT") .. var_16_0
										})
									end
								else
									xyd.WindowManager.get():openWindow("toast", {
										message = var_0_1:translation("LOTTERY_AUTO_SELECT3")
									})

									local var_16_2 = {
										activity_id = xyd.Activities.LotteryConsume
									}

									xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_16_2, function(arg_18_0, arg_18_1)
										if arg_18_0 == xyd.error.OK then
											arg_7_0.details = arg_18_1.details

											arg_7_0:updateWnd()
										end
									end)
								end
							end)
						end

						local var_14_1 = {
							times = arg_7_0.details.base_info.can_select_times - #arg_7_0.details.base_info.selected_nums,
							canSelectNums = var_0_3:ticketNum(arg_7_0.stageCount) - #arg_7_0.details.total_info.total_selected_nums,
							callback = var_14_0
						}

						xyd.WindowManager.get():openWindow("lottery_use_consume", var_14_1)
					end
				end, var_8_2, 0, xyd.ColorMode.ACTIVITY)
			elseif xyd.ServerTime.get():getServerTime() >= arg_7_0.activity.end_time then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_FINISHED")
				})
			elseif xyd.ServerTime.get():getServerTime() < arg_7_0.activity.start_time then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				})
			else
				local var_8_3 = arg_7_0.details

				xyd.WindowManager.get():openWindow("lottery_number_consume", var_8_3)
			end
		end
	end)
	arg_7_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.began then
			arg_7_0.container:getChildByName("btn_rule"):setScale(0.9, 0.9)
		end

		if arg_19_1 == ccui.TouchEventType.moved then
			arg_7_0.container:getChildByName("btn_rule"):setScale(1, 1)
		end

		if arg_19_1 == ccui.TouchEventType.ended then
			arg_7_0.container:getChildByName("btn_rule"):setScale(1, 1)

			local var_19_0 = {
				title_name = "ACTIVITY_LOTTERY_RULE_TITLE",
				rule = "ACTIVITY_LOTTERY_CONSUME_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_19_0)
		end
	end)
	arg_7_0.container:getChildByName("btn_check"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.began then
			arg_7_0.container:getChildByName("btn_check"):setScale(0.9, 0.9)
		end

		if arg_20_1 == ccui.TouchEventType.moved then
			arg_7_0.container:getChildByName("btn_check"):setScale(1, 1)
		end

		if arg_20_1 == ccui.TouchEventType.ended then
			arg_7_0.container:getChildByName("btn_check"):setScale(1, 1)

			local var_20_0 = {}

			xyd.Backend.get():request(xyd.mid.LOTTERY_CONSUME_GET_AWARD_INFOS, nil, function(arg_21_0, arg_21_1)
				if arg_21_0 == xyd.error.OK then
					var_20_0 = arg_21_1

					xyd.WindowManager.get():openWindow("lottery_prev_consume", var_20_0)
				end
			end)
		end
	end)
	arg_7_0.container:getChildByName("change_bg"):getChildByName("btn_change"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.began then
			arg_7_0.container:getChildByName("change_bg"):getChildByName("btn_change"):setScale(0.9, 0.9)
		end

		if arg_22_1 == ccui.TouchEventType.moved then
			arg_7_0.container:getChildByName("change_bg"):getChildByName("btn_change"):setScale(1, 1)
		end

		if arg_22_1 == ccui.TouchEventType.ended then
			arg_7_0.container:getChildByName("change_bg"):getChildByName("btn_change"):setScale(1, 1)

			if xyd.ServerTime.get():getServerTime() >= arg_7_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_7_0.activity.end_time then
				local var_22_0 = {
					score = arg_7_0.details.base_info.point,
					details = arg_7_0.details
				}

				xyd.WindowManager.get():openWindow("lottery_change_consume", var_22_0)
			elseif xyd.ServerTime.get():getServerTime() >= arg_7_0.activity.end_time then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_FINISHED")
				})
			elseif xyd.ServerTime.get():getServerTime() < arg_7_0.activity.start_time then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				})
			end
		end
	end)
	arg_7_0.container:getChildByName("btn_buy"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.began then
			arg_7_0.container:getChildByName("btn_buy"):setScale(0.9, 0.9)
		end

		if arg_23_1 == ccui.TouchEventType.moved then
			arg_7_0.container:getChildByName("btn_buy"):setScale(1, 1)
		end

		if arg_23_1 == ccui.TouchEventType.ended then
			arg_7_0.container:getChildByName("btn_buy"):setScale(1, 1)

			if xyd.ServerTime.get():getServerTime() >= arg_7_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_7_0.activity.end_time then
				local var_23_0 = {}

				if arg_7_0.handle_ then
					var_23_0.times = arg_7_0.details.base_info.can_select_times
				else
					var_23_0.times = arg_7_0.details.base_info.can_select_times - #arg_7_0.details.base_info.selected_nums
				end

				xyd.WindowManager.get():openWindow("lottery_buy_consume", var_23_0)
			elseif xyd.ServerTime.get():getServerTime() >= arg_7_0.activity.end_time then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_FINISHED")
				})
			elseif xyd.ServerTime.get():getServerTime() < arg_7_0.activity.start_time then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				})
			end
		end
	end)
end

function var_0_0.rewardLayer(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_1:getContentSize().height
	local var_24_1 = var_24_0 / 4
	local var_24_2 = var_0_3:giftID(arg_24_2)
	local var_24_3 = xyd.tables.gift:items(var_24_2)

	if #var_24_3 == 1 and var_24_3[1] == 0 then
		var_24_3 = {}
	end

	local var_24_4 = xyd.tables.gift:itemNum(var_24_2)
	local var_24_5 = #var_24_3

	for iter_24_0 = 1, #var_24_3 do
		if xyd.tables.item:type(var_24_3[iter_24_0]) ~= -1 then
			local var_24_6 = display.newNode()

			var_24_6:setContentSize(var_24_0, var_24_0)

			local var_24_7 = xyd.tables.item:type(var_24_3[iter_24_0])

			xyd.setItemBorder(var_24_6, var_24_3[iter_24_0], false, false, var_24_4[iter_24_0])
			var_24_6:addTo(arg_24_1)
			var_24_6:setAnchorPoint(cc.p(0, 0))
			var_24_6:setPosition((iter_24_0 - 1) * (var_24_0 + var_24_1), 0)

			local var_24_8 = {
				id = var_24_3[iter_24_0],
				lev = xyd.tables.item:level(var_24_3[iter_24_0])
			}

			if xyd.tables.item:type(var_24_3[iter_24_0]) == -1 then
				var_24_8.tipsType = 0
				var_24_8.desc1 = xyd.tables.hero:getDes(var_24_3[iter_24_0])
			elseif specialItem then
				var_24_8.tipsType = 1
				var_24_8.id = -3
			else
				var_24_8.tipsType = 1
				var_24_8.desc1 = xyd.tables.item:desc1(var_24_3[iter_24_0])
				var_24_8.desc2 = xyd.tables.item:desc2(var_24_3[iter_24_0])
			end

			var_24_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_24_3[iter_24_0])
			var_24_8.name = xyd.tables.item:name(var_24_3[iter_24_0])

			arg_24_0:addTips(var_24_6, var_24_8)
		end
	end

	local var_24_9 = xyd.tables.gift:crystal(var_24_2)

	if var_24_9 and var_24_9 > 0 then
		local var_24_10 = display.newNode()

		var_24_10:setContentSize(var_24_0, var_24_0)
		xyd.setItemBorder(var_24_10, -1, false, false, var_24_9)
		var_24_10:addTo(arg_24_1)
		var_24_10:setAnchorPoint(cc.p(0, 0))
		var_24_10:setPosition(var_24_5 * (var_24_0 + var_24_1), 0)

		local var_24_11 = {}

		var_24_11.id = -1
		var_24_11.tipsType = 1

		arg_24_0:addTips(var_24_10, var_24_11)

		var_24_5 = var_24_5 + 1
	end

	local var_24_12 = xyd.tables.gift:mana(var_24_2)

	if var_24_12 and var_24_12 > 0 then
		local var_24_13 = display.newNode()

		var_24_13:setContentSize(var_24_0, var_24_0)
		xyd.setItemBorder(var_24_13, -2, false, false, var_24_12)
		var_24_13:addTo(arg_24_1)
		var_24_13:setAnchorPoint(cc.p(0, 0))
		var_24_13:setPosition(var_24_5 * (var_24_0 + var_24_1), 0)

		local var_24_14 = {}

		var_24_14.id = -2
		var_24_14.tipsType = 1

		arg_24_0:addTips(var_24_13, var_24_14)

		local var_24_15 = var_24_5 + 1
	end

	return arg_24_1
end

function var_0_0.setRealAward(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = display.newNode()
	local var_25_1 = arg_25_1:getContentSize().width
	local var_25_2 = arg_25_1:getContentSize().height

	var_25_0:setContentSize(var_25_1, var_25_2)

	local var_25_3 = xyd.AssetLoader:get():loadSprite("images/icon/activity/lottery_real_award.png")

	stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

	stencil:setPosition(var_25_1 / 2, var_25_2 / 2)
	stencil:setAnchorPoint(cc.p(0.5, 0.5))
	stencil:setScale(var_25_2 / stencil:getHeight())

	local var_25_4 = var_25_2 / stencil:getHeight()
	local var_25_5 = cc.ClippingNode:create()

	var_25_5:setStencil(stencil)
	var_25_5:setName("clipper")
	var_25_5:setInverted(true)
	var_25_5:setAlphaThreshold(0)
	var_25_0:addChild(var_25_5)
	var_25_5:addChild(var_25_3)
	var_25_3:setPosition(var_25_1 / 2, var_25_2 / 2)
	var_25_3:setAnchorPoint(cc.p(0.5, 0.5))

	local var_25_6 = var_25_2 / var_25_3:getHeight()

	var_25_3:setScale(var_25_6)
	var_25_5:setLocalZOrder(-1)

	local var_25_7 = xyd.AssetLoader:get():loadSprite("images/border-white.png")

	var_25_7:setPosition(var_25_1 / 2, var_25_2 / 2)
	var_25_7:setAnchorPoint(cc.p(0.5, 0.5))

	local var_25_8 = var_25_2 / var_25_7:getHeight()

	var_25_7:setScale(var_25_8)
	var_25_0:addChild(var_25_7)
	var_25_0:addTo(arg_25_1)
	var_25_0:setPosition(var_25_1 / 2, var_25_2 / 2)
	var_25_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_25_0:setTouchEnabled(true)
	var_25_0:setTouchSwallowEnabled(false)
	var_25_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
		if arg_26_0.name == "began" then
			var_25_0:setScale(0.9)

			return true
		elseif arg_26_0.name == "moved" then
			var_25_0:setScale(1)
		elseif arg_26_0.name == "ended" then
			var_25_0:setScale(1)

			local var_26_0 = {
				dayStage = arg_25_2
			}

			xyd.WindowManager.get():openWindow("lottery_award", var_26_0)
		end
	end)
end

function var_0_0.updateTimeCount(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_1:getChildByName("text_time")

	if arg_27_0.handle_ then
		var_0_2.unscheduleGlobal(arg_27_0.handle_)
	end

	local var_27_1 = arg_27_0.details.base_info.award_time + xyd.tables.misc.activityLotteryInterval - xyd.ServerTime.get():getServerTime()

	if var_27_1 <= 0 then
		var_27_0:setVisible(false)
		arg_27_1:getChildByName("text_time_title"):setVisible(false)
		arg_27_1:getChildByName("text_total_num"):setVisible(true)
		arg_27_1:getChildByName("text_total_num"):setString(var_0_1:translation("ACTIVITY_LOTTERY_TIP3") .. var_0_3:ticketNum(arg_27_0.stageCount) - #arg_27_0.details.total_info.total_selected_nums .. "/" .. var_0_3:ticketNum(arg_27_0.stageCount))

		return
	else
		var_27_0:setVisible(true)
		arg_27_1:getChildByName("text_time_title"):setVisible(true)
		arg_27_1:getChildByName("text_total_num"):setVisible(false)
	end

	var_27_0:setString(arg_27_0:buildTimeStr(var_27_1))

	arg_27_0.handle_ = var_0_2.scheduleGlobal(function()
		if var_27_0 and not tolua.isnull(var_27_0) then
			var_27_1 = var_27_1 - 1

			var_27_0:setString(arg_27_0:buildTimeStr(var_27_1))

			if var_27_1 == 0 then
				local var_28_0 = {
					activity_id = xyd.Activities.LotteryConsume
				}

				xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_28_0, function(arg_29_0, arg_29_1)
					if arg_29_0 == xyd.error.OK then
						arg_27_0.details = arg_29_1.details

						arg_27_0:updateWnd()
					end
				end)

				if arg_27_0.handle_ then
					var_0_2.unscheduleGlobal(arg_27_0.handle_)

					arg_27_0.handle_ = nil
				end
			end
		elseif arg_27_0.handle_ then
			var_0_2.unscheduleGlobal(arg_27_0.handle_)

			arg_27_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.buildTimeStr(arg_30_0, arg_30_1)
	local var_30_0 = {
		math.floor(arg_30_1 / 3600),
		math.floor(arg_30_1 % 3600 / 60),
		arg_30_1 % 3600 % 60
	}
	local var_30_1 = {
		var_0_1:translation("UNIT_HOUR"),
		var_0_1:translation("UNIT_MINUTE"),
		(var_0_1:translation("UNIT_SECOND"))
	}
	local var_30_2 = ""

	for iter_30_0, iter_30_1 in ipairs(var_30_0) do
		if iter_30_1 ~= 0 then
			iter_30_1 = iter_30_1 .. var_30_1[iter_30_0]
			var_30_2 = var_30_2 .. iter_30_1
		end
	end

	return var_30_2
end

function var_0_0.addDialog(arg_31_0)
	local var_31_0 = {
		touchPosition = cc.p(0, 0),
		touchAreaSize = {
			width = 350,
			height = 420
		},
		times = {}
	}
	local var_31_1 = {}

	for iter_31_0 = 1, 6 do
		if iter_31_0 ~= 5 then
			table.insert(var_31_1, var_0_1:translation("LOTTERY_DIALOG" .. iter_31_0))
		elseif iter_31_0 == 5 and arg_31_0.stage ~= 1 and arg_31_0.details.total_info.old_award_info.major_award_info then
			table.insert(var_31_1, string.format(var_0_1:translation("LOTTERY_DIALOG" .. iter_31_0), arg_31_0.details.total_info.old_award_info.major_award_info.player_name))
		end

		table.insert(var_31_0.times, xyd.tables.misc.dialogDefaultTime)
	end

	var_31_0.msgs = var_31_1
	arg_31_0.speakCellContent = import("app.windows.SpeakCell").new(var_31_0)

	arg_31_0.speakCellContent:addTo(arg_31_0.container)
	arg_31_0.speakCellContent:setAnchorPoint(cc.p(0, 0))
	arg_31_0.speakCellContent:setPosition(arg_31_0.container:getChildByName("speak_pos"):getPosition())
	arg_31_0.speakCellContent:onclick()
end

function var_0_0.release(arg_32_0)
	if arg_32_0.handle_ then
		var_0_2.unscheduleGlobal(arg_32_0.handle_)

		arg_32_0.handle_ = nil
	end

	if arg_32_0.dispatcher then
		xyd.EventDispatcher.get():removeEventListener(arg_32_0.dispatcher)
	end
end

return var_0_0
