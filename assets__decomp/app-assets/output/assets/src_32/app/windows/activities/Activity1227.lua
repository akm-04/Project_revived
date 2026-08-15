local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityAliceBox2
local var_0_3 = import("framework.scheduler")
local var_0_4

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
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

	local var_2_1 = var_2_0:getChildByName("bg")
	local var_2_2 = {
		activity_id = xyd.Activities.AliceBox2
	}

	arg_2_0.activitiesModel:loadSingleActivity(var_2_2, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			dump(arg_3_1)

			arg_2_0.details = arg_3_1.details

			arg_2_0:layout(var_2_1)
		else
			arg_2_0.details = arg_2_0.activity.details

			arg_2_0:layout(var_2_1)
		end
	end)
end

function var_0_0.layout(arg_4_0, arg_4_1)
	arg_4_0:updateTimeCount(arg_4_1:getChildByName("text_time"))
	arg_4_1:getChildByName("total_score"):setString(arg_4_0.details.base_info.point)
	arg_4_1:getChildByName("word_time"):setString(var_0_1:translation("ACTIVITY_ALICE_BOX2_TEXT1"))
	arg_4_1:getChildByName("score_txt"):setString(var_0_1:translation("ACTIVITY_ALICE_BOX2_TEXT2"))
	arg_4_1:getChildByName("text_rule"):setString(var_0_1:translation("ACTIVITY_ALICE_BOX2_RULE"))
	arg_4_1:getChildByName("txt_zuanshi"):setString(var_0_1:translation("ACTIVITY_ALICE_BOX2_TEXT5"))

	local var_4_0 = math.ceil(1 / xyd.tables.misc:getValue("activity_alice_box2_rate"))

	arg_4_1:getChildByName("txt_zuanshi_num"):setString(var_4_0 .. ":1")
	arg_4_1:getChildByName("word_time"):setVisible(false)
	arg_4_1:getChildByName("text_time"):setVisible(false)
	arg_4_0:updateGiftContainer(arg_4_1, 1)
	arg_4_0:updateGiftContainer(arg_4_1, 2)
	arg_4_0:updateGiftContainer(arg_4_1, 3)
	arg_4_0:setButtonClick(arg_4_1)
end

function var_0_0.updateGiftContainer(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1:getChildByName("gift_container" .. arg_5_2)

	arg_5_0:rewardLayer(var_5_0:getChildByName("item_container"), var_0_2:gift(arg_5_2))
	var_5_0:getChildByName("text_score"):setString(var_0_2:cost(arg_5_2) .. var_0_1:translation("ACTIVITY_ALICE_BOX2_TEXT3"))
	var_5_0:getChildByName("btn_change"):getChildByName("text_times"):setString("(" .. arg_5_0.details.base_info.is_awarded[arg_5_2] .. "/" .. var_0_2:limitTimes(arg_5_2) .. ")")
	var_5_0:getChildByName("btn_change"):getChildByName("word_change"):setString(var_0_1:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT2"))
	var_5_0:getChildByName("btn_change"):getChildByName("word_sold_out"):setString(var_0_1:translation("ACTIVITY_CHARGE_LEVEL_TEXT3"))

	if arg_5_0.details.base_info.is_awarded[arg_5_2] >= var_0_2:limitTimes(arg_5_2) then
		var_5_0:getChildByName("btn_change"):setBright(false)
		var_5_0:getChildByName("btn_change"):setTouchEnabled(false)
		var_5_0:getChildByName("btn_change"):getChildByName("word_change"):setVisible(false)
		var_5_0:getChildByName("btn_change"):getChildByName("word_sold_out"):setVisible(true)
	else
		var_5_0:getChildByName("btn_change"):setBright(true)
		var_5_0:getChildByName("btn_change"):setTouchEnabled(true)
		var_5_0:getChildByName("btn_change"):getChildByName("word_change"):setVisible(true)
		var_5_0:getChildByName("btn_change"):getChildByName("word_sold_out"):setVisible(false)
	end
end

function var_0_0.setButtonClick(arg_6_0, arg_6_1)
	arg_6_1:getChildByName("gift_container1"):getChildByName("btn_change"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_7_0:setScale(0.9)
		elseif arg_7_1 == ccui.TouchEventType.moved then
			arg_7_0:setScale(1)
		elseif arg_7_1 == ccui.TouchEventType.ended then
			arg_7_0:setScale(1)
			xyd.playButtonSound()

			if xyd.ServerTime.get():getServerTime() >= arg_6_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_6_0.activity.end_time then
				if arg_6_0.details.base_info.point >= var_0_2:cost(1) then
					({
						activity_id = xyd.Activities.AliceBox
					}).award_id = 1

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ACTIVITY_ALICE_BOX2_TEXT6"), function()
						arg_6_0.activitiesModel:getActivityReward(arg_6_0.activity.table_id, 1, function(arg_9_0, arg_9_1)
							if arg_9_0 == xyd.error.OK then
								arg_6_0.selfPlayer:handleRewards(arg_9_1.awards)

								arg_6_0.details.base_info.is_awarded = arg_9_1.base_info.is_awarded
								arg_6_0.details.base_info.point = arg_9_1.base_info.point

								arg_6_1:getChildByName("total_score"):setString(arg_6_0.details.base_info.point)
								arg_6_0:updateGiftContainer(arg_6_1, 1)
							end
						end)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					local var_7_0 = var_0_1:translation("ACTIVITY_ALICE_BOX2_TEXT4")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_7_0
					})
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_6_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_6_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
	arg_6_1:getChildByName("gift_container2"):getChildByName("btn_change"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			arg_10_0:setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.moved then
			arg_10_0:setScale(1)
		elseif arg_10_1 == ccui.TouchEventType.ended then
			arg_10_0:setScale(1)
			xyd.playButtonSound()

			if xyd.ServerTime.get():getServerTime() >= arg_6_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_6_0.activity.end_time then
				if arg_6_0.details.base_info.point >= var_0_2:cost(2) then
					({
						activity_id = xyd.Activities.AliceBox
					}).award_id = 2

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ACTIVITY_ALICE_BOX2_TEXT6"), function()
						arg_6_0.activitiesModel:getActivityReward(arg_6_0.activity.table_id, 2, function(arg_12_0, arg_12_1)
							if arg_12_0 == xyd.error.OK then
								arg_6_0.selfPlayer:handleRewards(arg_12_1.awards)

								arg_6_0.details.base_info.is_awarded = arg_12_1.base_info.is_awarded
								arg_6_0.details.base_info.point = arg_12_1.base_info.point

								arg_6_1:getChildByName("total_score"):setString(arg_6_0.details.base_info.point)
								arg_6_0:updateGiftContainer(arg_6_1, 2)
							end
						end)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					local var_10_0 = var_0_1:translation("ACTIVITY_ALICE_BOX2_TEXT4")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_10_0
					})
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_6_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_6_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
	arg_6_1:getChildByName("gift_container3"):getChildByName("btn_change"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.began then
			arg_13_0:setScale(0.9)
		elseif arg_13_1 == ccui.TouchEventType.moved then
			arg_13_0:setScale(1)
		elseif arg_13_1 == ccui.TouchEventType.ended then
			arg_13_0:setScale(1)
			xyd.playButtonSound()

			if xyd.ServerTime.get():getServerTime() >= arg_6_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_6_0.activity.end_time then
				if arg_6_0.details.base_info.point >= var_0_2:cost(3) then
					({
						activity_id = xyd.Activities.AliceBox
					}).award_id = 3

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ACTIVITY_ALICE_BOX2_TEXT6"), function()
						arg_6_0.activitiesModel:getActivityReward(arg_6_0.activity.table_id, 3, function(arg_15_0, arg_15_1)
							if arg_15_0 == xyd.error.OK then
								arg_6_0.selfPlayer:handleRewards(arg_15_1.awards)

								arg_6_0.details.base_info.is_awarded = arg_15_1.base_info.is_awarded
								arg_6_0.details.base_info.point = arg_15_1.base_info.point

								arg_6_1:getChildByName("total_score"):setString(arg_6_0.details.base_info.point)
								arg_6_0:updateGiftContainer(arg_6_1, 3)
							end
						end)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					local var_13_0 = var_0_1:translation("ACTIVITY_ALICE_BOX2_TEXT4")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_13_0
					})
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_6_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_6_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
end

function var_0_0.rewardLayer(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = xyd.tables.gift:items(arg_16_2)

	if #var_16_0 == 1 and var_16_0[1] == 0 then
		var_16_0 = {}
	end

	local var_16_1 = xyd.tables.gift:itemNum(arg_16_2)
	local var_16_2 = #var_16_1
	local var_16_3 = arg_16_1:getContentSize().width
	local var_16_4 = 5
	local var_16_5 = #var_16_0 + 1

	for iter_16_0 = 1, #var_16_0 do
		local var_16_6 = display.newNode()

		var_16_6:setContentSize(var_16_3, var_16_3)

		local var_16_7 = xyd.tables.item:type(var_16_0[iter_16_0])

		xyd.setItemBorder(var_16_6, var_16_0[iter_16_0], false, false, var_16_1[iter_16_0])
		var_16_6:addTo(arg_16_1)
		var_16_6:setAnchorPoint(cc.p(0, 0))
		var_16_6:setPosition(0, (3 - iter_16_0) * (var_16_3 + var_16_4))

		local var_16_8 = {
			id = var_16_0[iter_16_0],
			lev = xyd.tables.item:level(var_16_0[iter_16_0])
		}

		if xyd.tables.item:type(var_16_0[iter_16_0]) == -1 then
			var_16_8.tipsType = 0
			var_16_8.desc1 = xyd.tables.hero:getDes(var_16_0[iter_16_0])
		elseif specialItem then
			var_16_8.tipsType = 1
			var_16_8.id = -3
		else
			var_16_8.tipsType = 1
			var_16_8.desc1 = xyd.tables.item:desc1(var_16_0[iter_16_0])
			var_16_8.desc2 = xyd.tables.item:desc2(var_16_0[iter_16_0])
		end

		var_16_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_16_0[iter_16_0])
		var_16_8.name = xyd.tables.item:name(var_16_0[iter_16_0])

		arg_16_0:addTips(var_16_6, var_16_8)
	end

	local var_16_9 = xyd.tables.gift:crystal(arg_16_2)

	if var_16_9 and var_16_9 > 0 then
		local var_16_10 = display.newNode()

		var_16_10:setContentSize(var_16_3, var_16_3)
		xyd.setItemBorder(var_16_10, -1, false, false, var_16_9)
		var_16_10:addTo(arg_16_1)
		var_16_10:setAnchorPoint(cc.p(0, 0))
		var_16_10:setPosition(0, 225 - var_16_5 * (var_16_3 + var_16_4))

		local var_16_11 = {}

		var_16_11.id = -1
		var_16_11.tipsType = 1

		arg_16_0:addTips(var_16_10, var_16_11)

		var_16_5 = var_16_5 + 1
	end

	local var_16_12 = xyd.tables.gift:mana(arg_16_2)

	if var_16_12 and var_16_12 > 0 then
		local var_16_13 = display.newNode()

		var_16_13:setContentSize(var_16_3, var_16_3)
		xyd.setItemBorder(var_16_13, -2, false, false, var_16_12)
		var_16_13:addTo(arg_16_1)
		var_16_13:setAnchorPoint(cc.p(0, 0))
		var_16_13:setPosition(0, 225 - var_16_5 * (var_16_3 + var_16_4))

		local var_16_14 = {}

		var_16_14.id = -2
		var_16_14.tipsType = 1

		arg_16_0:addTips(var_16_13, var_16_14)

		local var_16_15 = var_16_5 + 1
	end

	return arg_16_1
end

function var_0_0.updateTimeCount(arg_17_0, arg_17_1)
	if var_0_4 then
		var_0_3.unscheduleGlobal(var_0_4)
	end

	local var_17_0 = arg_17_0.activity.end_time - xyd.ServerTime.get():getServerTime()

	if var_17_0 <= 0 then
		arg_17_1:setString(xyd.secondsToString(0, {
			toText = false
		}))

		return
	end

	arg_17_1:setString(xyd.secondsToString(var_17_0, {
		toText = false
	}))

	var_0_4 = var_0_3.scheduleGlobal(function()
		if arg_17_1 and not tolua.isnull(arg_17_1) then
			var_17_0 = var_17_0 - 1

			arg_17_1:setString(xyd.secondsToString(var_17_0, {
				toText = false
			}))

			if var_17_0 == 0 and var_0_4 then
				var_0_3.unscheduleGlobal(var_0_4)

				var_0_4 = nil
			end
		end
	end, 1)
end

function var_0_0.release(arg_19_0)
	var_0_0.super.release(arg_19_0, params)

	if var_0_4 then
		var_0_3.unscheduleGlobal(var_0_4)

		var_0_4 = nil
	end
end

return var_0_0
