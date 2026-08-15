local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityAliceBox
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

	arg_2_0:layout(var_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_0:updateTimeCount(arg_3_1:getChildByName("text_time"))
	arg_3_1:getChildByName("total_score"):setString(arg_3_0.details.base_info.charge_count)
	arg_3_1:getChildByName("word_time"):setString(var_0_1:translation("ACTIVITY_ALICE_BOX_TEXT1"))
	arg_3_1:getChildByName("score_txt"):setString(var_0_1:translation("ACTIVITY_ALICE_BOX_TEXT2"))
	arg_3_1:getChildByName("text_rule"):setString(var_0_1:translation("ACTIVITY_ALICE_BOX_RULE"))
	arg_3_1:getChildByName("word_time"):setVisible(false)
	arg_3_1:getChildByName("text_time"):setVisible(false)
	arg_3_0:updateGiftContainer(arg_3_1, 1)
	arg_3_0:updateGiftContainer(arg_3_1, 2)
	arg_3_0:updateGiftContainer(arg_3_1, 3)
	arg_3_0:setButtonClick(arg_3_1)
end

function var_0_0.updateGiftContainer(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_1:getChildByName("gift_container" .. arg_4_2)

	arg_4_0:rewardLayer(var_4_0:getChildByName("item_container"), var_0_2:gift(arg_4_2))
	var_4_0:getChildByName("text_score"):setString(var_0_2:cost(arg_4_2) .. var_0_1:translation("ACTIVITY_ALICE_BOX_TEXT3"))
	var_4_0:getChildByName("btn_change"):getChildByName("text_times"):setString("(" .. arg_4_0.details.base_info.is_awarded[arg_4_2] .. "/" .. var_0_2:limitTimes(arg_4_2) .. ")")
	var_4_0:getChildByName("btn_change"):getChildByName("word_change"):setString(var_0_1:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT2"))
	var_4_0:getChildByName("btn_change"):getChildByName("word_sold_out"):setString(var_0_1:translation("ACTIVITY_CHARGE_LEVEL_TEXT3"))

	if arg_4_0.details.base_info.is_awarded[arg_4_2] >= var_0_2:limitTimes(arg_4_2) then
		var_4_0:getChildByName("btn_change"):setBright(false)
		var_4_0:getChildByName("btn_change"):setTouchEnabled(false)
		var_4_0:getChildByName("btn_change"):getChildByName("word_change"):setVisible(false)
		var_4_0:getChildByName("btn_change"):getChildByName("word_sold_out"):setVisible(true)
	else
		var_4_0:getChildByName("btn_change"):setBright(true)
		var_4_0:getChildByName("btn_change"):setTouchEnabled(true)
		var_4_0:getChildByName("btn_change"):getChildByName("word_change"):setVisible(true)
		var_4_0:getChildByName("btn_change"):getChildByName("word_sold_out"):setVisible(false)
	end
end

function var_0_0.setButtonClick(arg_5_0, arg_5_1)
	arg_5_1:getChildByName("gift_container1"):getChildByName("btn_change"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_6_0:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.moved then
			arg_6_0:setScale(1)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			arg_6_0:setScale(1)
			xyd.playButtonSound()

			if xyd.ServerTime.get():getServerTime() >= arg_5_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_5_0.activity.end_time then
				if arg_5_0.details.base_info.charge_count >= var_0_2:cost(1) then
					local var_6_0 = {
						activity_id = xyd.Activities.AliceBox
					}

					var_6_0.award_id = 1

					xyd.Backend.get():request(xyd.mid.ACTIVITY_ALICE_BOX, var_6_0, function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							arg_5_0.selfPlayer:handleRewards(arg_7_1.awards)

							arg_5_0.details.base_info.is_awarded = arg_7_1.base_info.is_awarded
							arg_5_0.details.base_info.charge_count = arg_7_1.base_info.charge_count

							arg_5_1:getChildByName("total_score"):setString(arg_5_0.details.base_info.charge_count)
							arg_5_0:updateGiftContainer(arg_5_1, 1)
							arg_5_0.activitiesModel:refreshRedMark()

							local var_7_0 = xyd.WindowManager.get():getWindow("activities")

							if var_7_0 then
								var_7_0:updateActivityRedMark(arg_5_0.activity)
							end
						end
					end)
				else
					local var_6_1 = var_0_1:translation("ACTIVITY_ALICE_BOX_TEXT4")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_1
					})
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_5_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_5_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
	arg_5_1:getChildByName("gift_container2"):getChildByName("btn_change"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_8_0:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.moved then
			arg_8_0:setScale(1)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			arg_8_0:setScale(1)
			xyd.playButtonSound()

			if xyd.ServerTime.get():getServerTime() >= arg_5_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_5_0.activity.end_time then
				if arg_5_0.details.base_info.charge_count >= var_0_2:cost(2) then
					local var_8_0 = {
						activity_id = xyd.Activities.AliceBox
					}

					var_8_0.award_id = 2

					xyd.Backend.get():request(xyd.mid.ACTIVITY_ALICE_BOX, var_8_0, function(arg_9_0, arg_9_1)
						if arg_9_0 == xyd.error.OK then
							arg_5_0.selfPlayer:handleRewards(arg_9_1.awards)

							arg_5_0.details.base_info.is_awarded = arg_9_1.base_info.is_awarded
							arg_5_0.details.base_info.charge_count = arg_9_1.base_info.charge_count

							arg_5_1:getChildByName("total_score"):setString(arg_5_0.details.base_info.charge_count)
							arg_5_0:updateGiftContainer(arg_5_1, 2)
							arg_5_0.activitiesModel:refreshRedMark()

							local var_9_0 = xyd.WindowManager.get():getWindow("activities")

							if var_9_0 then
								var_9_0:updateActivityRedMark(arg_5_0.activity)
							end
						end
					end)
				else
					local var_8_1 = var_0_1:translation("ACTIVITY_ALICE_BOX_TEXT4")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_8_1
					})
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_5_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_5_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
	arg_5_1:getChildByName("gift_container3"):getChildByName("btn_change"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			arg_10_0:setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.moved then
			arg_10_0:setScale(1)
		elseif arg_10_1 == ccui.TouchEventType.ended then
			arg_10_0:setScale(1)
			xyd.playButtonSound()

			if xyd.ServerTime.get():getServerTime() >= arg_5_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_5_0.activity.end_time then
				if arg_5_0.details.base_info.charge_count >= var_0_2:cost(3) then
					local var_10_0 = {
						activity_id = xyd.Activities.AliceBox
					}

					var_10_0.award_id = 3

					xyd.Backend.get():request(xyd.mid.ACTIVITY_ALICE_BOX, var_10_0, function(arg_11_0, arg_11_1)
						if arg_11_0 == xyd.error.OK then
							arg_5_0.selfPlayer:handleRewards(arg_11_1.awards)

							arg_5_0.details.base_info.is_awarded = arg_11_1.base_info.is_awarded
							arg_5_0.details.base_info.charge_count = arg_11_1.base_info.charge_count

							arg_5_1:getChildByName("total_score"):setString(arg_5_0.details.base_info.charge_count)
							arg_5_0:updateGiftContainer(arg_5_1, 3)
							arg_5_0.activitiesModel:refreshRedMark()

							local var_11_0 = xyd.WindowManager.get():getWindow("activities")

							if var_11_0 then
								var_11_0:updateActivityRedMark(arg_5_0.activity)
							end
						end
					end)
				else
					local var_10_1 = var_0_1:translation("ACTIVITY_ALICE_BOX_TEXT4")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_10_1
					})
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_5_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_5_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
end

function var_0_0.rewardLayer(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = xyd.tables.gift:items(arg_12_2)

	if #var_12_0 == 1 and var_12_0[1] == 0 then
		var_12_0 = {}
	end

	local var_12_1 = xyd.tables.gift:itemNum(arg_12_2)
	local var_12_2 = #var_12_1
	local var_12_3 = arg_12_1:getContentSize().width
	local var_12_4 = 5
	local var_12_5 = #var_12_0 + 1

	for iter_12_0 = 1, #var_12_0 do
		local var_12_6 = display.newNode()

		var_12_6:setContentSize(var_12_3, var_12_3)

		local var_12_7 = xyd.tables.item:type(var_12_0[iter_12_0])

		xyd.setItemBorder(var_12_6, var_12_0[iter_12_0], false, false, var_12_1[iter_12_0])
		var_12_6:addTo(arg_12_1)
		var_12_6:setAnchorPoint(cc.p(0, 0))
		var_12_6:setPosition(0, (3 - iter_12_0) * (var_12_3 + var_12_4))

		local var_12_8 = {
			id = var_12_0[iter_12_0],
			lev = xyd.tables.item:level(var_12_0[iter_12_0])
		}

		if xyd.tables.item:type(var_12_0[iter_12_0]) == -1 then
			var_12_8.tipsType = 0
			var_12_8.desc1 = xyd.tables.hero:getDes(var_12_0[iter_12_0])
		elseif specialItem then
			var_12_8.tipsType = 1
			var_12_8.id = -3
		else
			var_12_8.tipsType = 1
			var_12_8.desc1 = xyd.tables.item:desc1(var_12_0[iter_12_0])
			var_12_8.desc2 = xyd.tables.item:desc2(var_12_0[iter_12_0])
		end

		var_12_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_12_0[iter_12_0])
		var_12_8.name = xyd.tables.item:name(var_12_0[iter_12_0])

		arg_12_0:addTips(var_12_6, var_12_8)
	end

	local var_12_9 = xyd.tables.gift:crystal(arg_12_2)

	if var_12_9 and var_12_9 > 0 then
		local var_12_10 = display.newNode()

		var_12_10:setContentSize(var_12_3, var_12_3)
		xyd.setItemBorder(var_12_10, -1, false, false, var_12_9)
		var_12_10:addTo(arg_12_1)
		var_12_10:setAnchorPoint(cc.p(0, 0))
		var_12_10:setPosition(0, 225 - var_12_5 * (var_12_3 + var_12_4))

		local var_12_11 = {}

		var_12_11.id = -1
		var_12_11.tipsType = 1

		arg_12_0:addTips(var_12_10, var_12_11)

		var_12_5 = var_12_5 + 1
	end

	local var_12_12 = xyd.tables.gift:mana(arg_12_2)

	if var_12_12 and var_12_12 > 0 then
		local var_12_13 = display.newNode()

		var_12_13:setContentSize(var_12_3, var_12_3)
		xyd.setItemBorder(var_12_13, -2, false, false, var_12_12)
		var_12_13:addTo(arg_12_1)
		var_12_13:setAnchorPoint(cc.p(0, 0))
		var_12_13:setPosition(0, 225 - var_12_5 * (var_12_3 + var_12_4))

		local var_12_14 = {}

		var_12_14.id = -2
		var_12_14.tipsType = 1

		arg_12_0:addTips(var_12_13, var_12_14)

		local var_12_15 = var_12_5 + 1
	end

	return arg_12_1
end

function var_0_0.updateTimeCount(arg_13_0, arg_13_1)
	if var_0_4 then
		var_0_3.unscheduleGlobal(var_0_4)
	end

	local var_13_0 = arg_13_0.activity.end_time - xyd.ServerTime.get():getServerTime()

	if var_13_0 <= 0 then
		arg_13_1:setString(xyd.secondsToString(0, {
			toText = false
		}))

		return
	end

	arg_13_1:setString(xyd.secondsToString(var_13_0, {
		toText = false
	}))

	var_0_4 = var_0_3.scheduleGlobal(function()
		if arg_13_1 and not tolua.isnull(arg_13_1) then
			var_13_0 = var_13_0 - 1

			arg_13_1:setString(xyd.secondsToString(var_13_0, {
				toText = false
			}))

			if var_13_0 == 0 and var_0_4 then
				var_0_3.unscheduleGlobal(var_0_4)

				var_0_4 = nil
			end
		end
	end, 1)
end

function var_0_0.release(arg_15_0)
	var_0_0.super.release(arg_15_0, params)

	if var_0_4 then
		var_0_3.unscheduleGlobal(var_0_4)

		var_0_4 = nil
	end
end

return var_0_0
