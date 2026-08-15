local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.activityLottery
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
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.container:getChildByName("text_item_none"):setString(var_0_1:translation("ACTIVITY_LOTTERY_TIP1"))
	arg_3_0.container:getChildByName("text_player_none"):setString(var_0_1:translation("ACTIVITY_LOTTERY_TIP2"))
	arg_3_0.container:getChildByName("text_time_title"):setString(var_0_1:translation("ACTIVITY_LOTTERY_TIP4"))
	arg_3_0.container:getChildByName("text_lucky_num_title"):setString(var_0_1:translation("ACTIVITY_LOTTERY_TIP5"))

	if arg_3_0.details.base_info.extra_times > 0 and arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityLotteryItem) > 0 then
		local var_3_0 = {
			itemID = xyd.tables.misc.activityLotteryItem,
			itemNum = arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityLotteryItem)
		}

		arg_3_0.selfPlayer:getBackpack():removeItem(var_3_0)
	end

	arg_3_0:updateWnd()
	arg_3_0:setButtonClick()
	arg_3_0:addDialog()
end

function var_0_0.updateWnd(arg_4_0)
	arg_4_0.stageCount = arg_4_0.details.base_info.day_count % var_0_4

	if arg_4_0.stageCount == 0 then
		arg_4_0.stageCount = var_0_4
	end

	if xyd.ServerTime.get():getServerTime() < arg_4_0.activity.start_time then
		arg_4_0.container:getChildByName("text_stage"):setString("1")
		arg_4_0.container:getChildByName("btn_check"):setBright(false)
		arg_4_0.container:getChildByName("btn_check"):setTouchEnabled(false)
		arg_4_0.container:getChildByName("text_player"):setVisible(false)
		arg_4_0.container:getChildByName("text_player_region"):setVisible(false)
		arg_4_0.container:getChildByName("text_player_none"):setVisible(true)
		arg_4_0.container:getChildByName("text_item_none"):setVisible(true)
		arg_4_0.container:getChildByName("btn_check"):getChildByName("text_check"):setColor(cc.c3b(128, 128, 128))
	else
		arg_4_0:rewardLayer(arg_4_0.container:getChildByName("item"), arg_4_0.stageCount)
		arg_4_0:setRealAward(arg_4_0.container:getChildByName("item_real"), arg_4_0.stageCount)
		arg_4_0.container:getChildByName("text_stage"):setString(arg_4_0.details.base_info.day_count)
		arg_4_0.container:getChildByName("text_item_none"):setVisible(false)

		if arg_4_0.details.base_info.day_count <= 1 then
			arg_4_0.container:getChildByName("btn_check"):setBright(false)
			arg_4_0.container:getChildByName("btn_check"):setTouchEnabled(false)
			arg_4_0.container:getChildByName("text_player"):setVisible(false)
			arg_4_0.container:getChildByName("text_player_region"):setVisible(false)
			arg_4_0.container:getChildByName("text_player_none"):setVisible(true)
			arg_4_0.container:getChildByName("btn_check"):getChildByName("text_check"):setColor(cc.c3b(128, 128, 128))
		else
			arg_4_0.container:getChildByName("btn_check"):getChildByName("text_check"):setColor(cc.c3b(126, 67, 14))
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

	arg_4_0.container:getChildByName("text_lucky_num"):setString(#arg_4_0.details.base_info.selected_nums .. "/" .. arg_4_0.details.base_info.can_select_times)
	arg_4_0:updateTimeCount(arg_4_0.container, activity)

	if arg_4_0.details.base_info.can_select_times - #arg_4_0.details.base_info.selected_nums > 0 and #arg_4_0.details.total_info.total_selected_nums < var_0_3:ticketNum(arg_4_0.stageCount) then
		arg_4_0.container:getChildByName("btn_num"):getChildByName("text_choose"):setVisible(true)
		arg_4_0.container:getChildByName("btn_num"):getChildByName("text_num"):setVisible(false)

		arg_4_0.canChoose = true
	else
		arg_4_0.canChoose = false

		arg_4_0.container:getChildByName("btn_num"):getChildByName("text_choose"):setVisible(false)
		arg_4_0.container:getChildByName("btn_num"):getChildByName("text_num"):setVisible(true)
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

			if arg_7_0.canChoose and xyd.ServerTime.get():getServerTime() >= arg_7_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_7_0.activity.end_time then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("LOTTERY_NUMBER_TIPS"), function()
					xyd.WindowManager.get():openWindow("lottery_number", var_8_0)
				end, {
					lcallback = function()
						xyd.Backend.get():request(xyd.mid.LOTTERY_AUTO_SELECT_NUMS, nil, function(arg_11_0, arg_11_1)
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
										activity_id = xyd.Activities.Lottery
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
									activity_id = xyd.Activities.Lottery
								}

								xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_11_2, function(arg_13_0, arg_13_1)
									if arg_13_0 == xyd.error.OK then
										arg_7_0.details = arg_13_1.details

										arg_7_0:updateWnd()
									end
								end)
							end
						end)
					end,
					leftName = var_0_1:translation("ACTIVITY_1116_AUTO"),
					rightName = var_0_1:translation("ACTIVITY_1116_MANUAL")
				}, nil, xyd.ColorMode.ACTIVITY)
			elseif xyd.ServerTime.get():getServerTime() >= arg_7_0.activity.end_time then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_FINISHED")
				})
			elseif xyd.ServerTime.get():getServerTime() < arg_7_0.activity.start_time then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				})
			else
				local var_8_1 = arg_7_0.details

				xyd.WindowManager.get():openWindow("lottery_number", var_8_1)
			end
		end
	end)
	arg_7_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.began then
			arg_7_0.container:getChildByName("btn_rule"):setScale(0.9, 0.9)
		end

		if arg_14_1 == ccui.TouchEventType.moved then
			arg_7_0.container:getChildByName("btn_rule"):setScale(1, 1)
		end

		if arg_14_1 == ccui.TouchEventType.ended then
			arg_7_0.container:getChildByName("btn_rule"):setScale(1, 1)

			local var_14_0 = {
				title_name = "ACTIVITY_LOTTERY_RULE_TITLE",
				rule = "ACTIVITY_LOTTERY_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_14_0)
		end
	end)
	arg_7_0.container:getChildByName("btn_check"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.began then
			arg_7_0.container:getChildByName("btn_check"):setScale(0.9, 0.9)
		end

		if arg_15_1 == ccui.TouchEventType.moved then
			arg_7_0.container:getChildByName("btn_check"):setScale(1, 1)
		end

		if arg_15_1 == ccui.TouchEventType.ended then
			arg_7_0.container:getChildByName("btn_check"):setScale(1, 1)

			local var_15_0 = {}

			xyd.Backend.get():request(xyd.mid.LOTTERY_GET_AWARD_INFOS, nil, function(arg_16_0, arg_16_1)
				if arg_16_0 == xyd.error.OK then
					var_15_0 = arg_16_1

					xyd.WindowManager.get():openWindow("lottery_prev", var_15_0)
				end
			end)
		end
	end)
end

function var_0_0.rewardLayer(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1:getContentSize().height
	local var_17_1 = var_17_0 / 4
	local var_17_2 = var_0_3:giftID(arg_17_2)
	local var_17_3 = xyd.tables.gift:items(var_17_2)

	if #var_17_3 == 1 and var_17_3[1] == 0 then
		var_17_3 = {}
	end

	local var_17_4 = xyd.tables.gift:itemNum(var_17_2)
	local var_17_5 = #var_17_3

	for iter_17_0 = 1, #var_17_3 do
		if xyd.tables.item:type(var_17_3[iter_17_0]) ~= -1 then
			local var_17_6 = display.newNode()

			var_17_6:setContentSize(var_17_0, var_17_0)

			local var_17_7 = xyd.tables.item:type(var_17_3[iter_17_0])

			xyd.setItemBorder(var_17_6, var_17_3[iter_17_0], false, false, var_17_4[iter_17_0])
			var_17_6:addTo(arg_17_1)
			var_17_6:setAnchorPoint(cc.p(0, 0))
			var_17_6:setPosition((iter_17_0 - 1) * (var_17_0 + var_17_1), 0)

			local var_17_8 = {
				id = var_17_3[iter_17_0],
				lev = xyd.tables.item:level(var_17_3[iter_17_0])
			}

			if xyd.tables.item:type(var_17_3[iter_17_0]) == -1 then
				var_17_8.tipsType = 0
				var_17_8.desc1 = xyd.tables.hero:getDes(var_17_3[iter_17_0])
			elseif specialItem then
				var_17_8.tipsType = 1
				var_17_8.id = -3
			else
				var_17_8.tipsType = 1
				var_17_8.desc1 = xyd.tables.item:desc1(var_17_3[iter_17_0])
				var_17_8.desc2 = xyd.tables.item:desc2(var_17_3[iter_17_0])
			end

			var_17_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_17_3[iter_17_0])
			var_17_8.name = xyd.tables.item:name(var_17_3[iter_17_0])

			arg_17_0:addTips(var_17_6, var_17_8)
		end
	end

	local var_17_9 = xyd.tables.gift:crystal(var_17_2)

	if var_17_9 and var_17_9 > 0 then
		local var_17_10 = display.newNode()

		var_17_10:setContentSize(var_17_0, var_17_0)
		xyd.setItemBorder(var_17_10, -1, false, false, var_17_9)
		var_17_10:addTo(arg_17_1)
		var_17_10:setAnchorPoint(cc.p(0, 0))
		var_17_10:setPosition(var_17_5 * (var_17_0 + var_17_1), 0)

		local var_17_11 = {}

		var_17_11.id = -1
		var_17_11.tipsType = 1

		arg_17_0:addTips(var_17_10, var_17_11)

		var_17_5 = var_17_5 + 1
	end

	local var_17_12 = xyd.tables.gift:mana(var_17_2)

	if var_17_12 and var_17_12 > 0 then
		local var_17_13 = display.newNode()

		var_17_13:setContentSize(var_17_0, var_17_0)
		xyd.setItemBorder(var_17_13, -2, false, false, var_17_12)
		var_17_13:addTo(arg_17_1)
		var_17_13:setAnchorPoint(cc.p(0, 0))
		var_17_13:setPosition(var_17_5 * (var_17_0 + var_17_1), 0)

		local var_17_14 = {}

		var_17_14.id = -2
		var_17_14.tipsType = 1

		arg_17_0:addTips(var_17_13, var_17_14)

		local var_17_15 = var_17_5 + 1
	end

	return arg_17_1
end

function var_0_0.setRealAward(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = display.newNode()
	local var_18_1 = arg_18_1:getContentSize().width
	local var_18_2 = arg_18_1:getContentSize().height

	var_18_0:setContentSize(var_18_1, var_18_2)

	local var_18_3 = xyd.AssetLoader:get():loadSprite("images/icon/activity/1116/lottery_extra.png")

	stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

	stencil:setPosition(var_18_1 / 2, var_18_2 / 2)
	stencil:setAnchorPoint(cc.p(0.5, 0.5))
	stencil:setScale(var_18_2 / stencil:getHeight())

	local var_18_4 = var_18_2 / stencil:getHeight()
	local var_18_5 = cc.ClippingNode:create()

	var_18_5:setStencil(stencil)
	var_18_5:setName("clipper")
	var_18_5:setInverted(true)
	var_18_5:setAlphaThreshold(0)
	var_18_0:addChild(var_18_5)
	var_18_5:addChild(var_18_3)
	var_18_3:setPosition(var_18_1 / 2, var_18_2 / 2)
	var_18_3:setAnchorPoint(cc.p(0.5, 0.5))

	local var_18_6 = var_18_2 / var_18_3:getHeight()

	var_18_3:setScale(var_18_6)
	var_18_5:setLocalZOrder(-1)

	local var_18_7 = xyd.AssetLoader:get():loadSprite("images/border-white.png")

	var_18_7:setPosition(var_18_1 / 2, var_18_2 / 2)
	var_18_7:setAnchorPoint(cc.p(0.5, 0.5))

	local var_18_8 = var_18_2 / var_18_7:getHeight()

	var_18_7:setScale(var_18_8)
	var_18_0:addChild(var_18_7)
	var_18_0:addTo(arg_18_1)
	var_18_0:setPosition(var_18_1 / 2, var_18_2 / 2)
	var_18_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_18_0:setTouchEnabled(true)
	var_18_0:setTouchSwallowEnabled(false)
	var_18_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			var_18_0:setScale(0.9)

			return true
		elseif arg_19_0.name == "moved" then
			var_18_0:setScale(1)
		elseif arg_19_0.name == "ended" then
			var_18_0:setScale(1)

			local var_19_0 = {
				dayStage = arg_18_2
			}

			xyd.WindowManager.get():openWindow("lottery_award", var_19_0)
		end
	end)
end

function var_0_0.updateTimeCount(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_1:getChildByName("text_time")

	if arg_20_0.handle_ then
		var_0_2.unscheduleGlobal(arg_20_0.handle_)
	end

	local var_20_1 = arg_20_0.details.base_info.award_time + xyd.tables.misc.activityLotteryInterval - xyd.ServerTime.get():getServerTime()

	if var_20_1 <= 0 then
		var_20_0:setVisible(false)
		arg_20_1:getChildByName("text_time_title"):setVisible(false)
		arg_20_1:getChildByName("text_total_num"):setVisible(true)
		arg_20_1:getChildByName("text_total_num"):setString(var_0_1:translation("ACTIVITY_LOTTERY_TIP3") .. var_0_3:ticketNum(arg_20_0.stageCount) - #arg_20_0.details.total_info.total_selected_nums .. "/" .. var_0_3:ticketNum(arg_20_0.stageCount))

		return
	else
		var_20_0:setVisible(true)
		arg_20_1:getChildByName("text_time_title"):setVisible(true)
		arg_20_1:getChildByName("text_total_num"):setVisible(false)
	end

	var_20_0:setString(arg_20_0:buildTimeStr(var_20_1))

	arg_20_0.handle_ = var_0_2.scheduleGlobal(function()
		if var_20_0 and not tolua.isnull(var_20_0) then
			var_20_1 = var_20_1 - 1

			var_20_0:setString(arg_20_0:buildTimeStr(var_20_1))

			if var_20_1 == 0 then
				local var_21_0 = {
					activity_id = xyd.Activities.Lottery
				}

				xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_21_0, function(arg_22_0, arg_22_1)
					if arg_22_0 == xyd.error.OK then
						arg_20_0.details = arg_22_1.details

						arg_20_0:updateWnd()
					end
				end)

				if arg_20_0.handle_ then
					var_0_2.unscheduleGlobal(arg_20_0.handle_)

					arg_20_0.handle_ = nil
				end
			end
		elseif arg_20_0.handle_ then
			var_0_2.unscheduleGlobal(arg_20_0.handle_)

			arg_20_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.buildTimeStr(arg_23_0, arg_23_1)
	local var_23_0 = {
		math.floor(arg_23_1 / 3600),
		math.floor(arg_23_1 % 3600 / 60),
		arg_23_1 % 3600 % 60
	}
	local var_23_1 = {
		var_0_1:translation("UNIT_HOUR"),
		var_0_1:translation("UNIT_MINUTE"),
		(var_0_1:translation("UNIT_SECOND"))
	}
	local var_23_2 = ""

	for iter_23_0, iter_23_1 in ipairs(var_23_0) do
		if iter_23_1 ~= 0 then
			iter_23_1 = iter_23_1 .. var_23_1[iter_23_0]
			var_23_2 = var_23_2 .. iter_23_1
		end
	end

	return var_23_2
end

function var_0_0.addDialog(arg_24_0)
	local var_24_0 = {
		touchPosition = cc.p(0, 0),
		touchAreaSize = {
			width = 350,
			height = 420
		},
		times = {}
	}
	local var_24_1 = {}

	for iter_24_0 = 1, 6 do
		if iter_24_0 ~= 5 then
			table.insert(var_24_1, var_0_1:translation("LOTTERY_DIALOG" .. iter_24_0))
		elseif iter_24_0 == 5 and arg_24_0.stage ~= 1 and arg_24_0.details.total_info.old_award_info.major_award_info then
			table.insert(var_24_1, string.format(var_0_1:translation("LOTTERY_DIALOG" .. iter_24_0), arg_24_0.details.total_info.old_award_info.major_award_info.player_name))
		end

		table.insert(var_24_0.times, xyd.tables.misc.dialogDefaultTime)
	end

	var_24_0.msgs = var_24_1
	arg_24_0.speakCellContent = import("app.windows.SpeakCell").new(var_24_0)

	arg_24_0.speakCellContent:addTo(arg_24_0.container)
	arg_24_0.speakCellContent:setAnchorPoint(cc.p(0, 0))
	arg_24_0.speakCellContent:setPosition(arg_24_0.container:getChildByName("speak_pos"):getPosition())
	arg_24_0.speakCellContent:onclick()
end

function var_0_0.release(arg_25_0)
	if arg_25_0.handle_ then
		var_0_2.unscheduleGlobal(arg_25_0.handle_)

		arg_25_0.handle_ = nil
	end

	if arg_25_0.dispatcher then
		xyd.EventDispatcher.get():removeEventListener(arg_25_0.dispatcher)
	end
end

return var_0_0
