local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.activityConsumeGift
local var_0_4 = {
	free = 1,
	five = 3,
	ticket = 4,
	once = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.flipTimes = arg_1_0.details.record_info.cur_num
	arg_1_0.canGetTime = arg_1_0.details.record_info.record
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

	local var_2_1 = var_2_0:getChildByName("container")

	arg_2_0:layout(var_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	local var_3_0 = "skeletons/ui_effect/activity_charge_gift/zcmtx"
	local var_3_1 = var_3_0 .. ".json"
	local var_3_2 = var_3_0 .. ".atlas"

	arg_3_0.effect = var_0_2.new(var_3_1, var_3_2, 1)

	arg_3_0.effect:addTo(arg_3_1:getChildByName("cat"))
	arg_3_0.effect:setVisible(false)
	arg_3_0.effect:setAnchorPoint(cc.p(0, 0))
	arg_3_0.effect:play(nil, true)
	arg_3_1:getChildByName("cat"):setContentSize(74, 104)
	arg_3_0.effect:setPosition(37, 52)
	arg_3_1:getChildByName("cat"):setAnchorPoint(cc.p(0.5, 0.5))

	local var_3_3 = arg_3_1:getChildByName("btn_one")

	var_3_3:getChildByName("word_1"):setString(var_0_1:translation("ACTIVITY_1121_TEXT1"))
	var_3_3:getChildByName("word_1"):enableOutline(cc.c4b(162, 96, 104, 255), 3)
	var_3_3:getChildByName("word_free"):setString(var_0_1:translation("ACTIVITY_1121_TEXT3"))

	local var_3_4 = arg_3_1:getChildByName("btn_five")

	var_3_4:getChildByName("word_5"):setString(var_0_1:translation("ACTIVITY_1121_TEXT2"))
	var_3_4:getChildByName("word_5"):enableOutline(cc.c4b(162, 96, 104, 255), 3)

	if arg_3_0.details.free_summon_times > 0 then
		var_3_3:getChildByName("zuanshi"):setVisible(true)
		var_3_3:getChildByName("ticket"):setVisible(false)
		var_3_3:getChildByName("txt_price_1"):setVisible(false)
		var_3_3:getChildByName("word_free"):setVisible(true)
	elseif arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityConsumeGiftTicket) > 0 then
		var_3_3:getChildByName("txt_price_1"):setVisible(true)
		var_3_3:getChildByName("word_free"):setVisible(false)
		var_3_3:getChildByName("zuanshi"):setVisible(false)
		var_3_3:getChildByName("ticket"):setVisible(true)
		var_3_3:getChildByName("txt_price_1"):setString("1")
	else
		var_3_3:getChildByName("zuanshi"):setVisible(true)
		var_3_3:getChildByName("ticket"):setVisible(false)
		var_3_3:getChildByName("word_free"):setVisible(false)
		var_3_3:getChildByName("txt_price_1"):setVisible(true)
		var_3_3:getChildByName("txt_price_1"):setString(tostring(xyd.tables.misc.activityConsumeGiftOnce))
	end

	arg_3_1:getChildByName("btn_five"):getChildByName("txt_price_5"):setString(tostring(xyd.tables.misc.activityConsumeGiftFive))
	arg_3_1:getChildByName("txt_1"):setString(string.format(var_0_1:translation("CONSUME_GIFT_WORD_1"), xyd.tables.misc.activityConsumeGiftOnce))
	arg_3_1:getChildByName("txt_2"):setString(var_0_1:translation("CONSUME_GIFT_WORD_2"))
	arg_3_1:getChildByName("txt_1"):enableOutline(cc.c4b(128, 70, 47, 255), 2)
	arg_3_1:getChildByName("txt_2"):enableOutline(cc.c4b(128, 70, 47, 255), 2)
	arg_3_1:getChildByName("award"):removeAllChildren()
	arg_3_0:rewardLayer(arg_3_1:getChildByName("award"))
	var_3_3:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			if arg_3_0.activity.is_open == 1 then
				if arg_3_0.details.free_summon_times > 0 then
					local var_4_0 = {
						summon_type = xyd.SummonType.ConsumeGift,
						summon_index = var_0_4.free
					}

					xyd.Backend.get():request(xyd.mid.CONSUME_GIFT_SUMMON, var_4_0, function(arg_5_0, arg_5_1)
						if arg_5_0 == xyd.error.OK then
							arg_3_0.selfPlayer:handleRewards(arg_5_1.awards)

							arg_3_0.details.free_summon_times = arg_3_0.details.free_summon_times - 1

							local var_5_0 = {
								activity_id = xyd.Activities.ConsumeGift
							}

							xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_5_0, function(arg_6_0, arg_6_1)
								if arg_6_0 == xyd.error.OK then
									if arg_6_1.details.free_summon_times > 0 then
										arg_3_1:getChildByName("btn_one"):getChildByName("zuanshi"):setVisible(true)
										arg_3_1:getChildByName("btn_one"):getChildByName("ticket"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("txt_price_1"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("word_free"):setVisible(true)
									elseif arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityConsumeGiftTicket) > 0 then
										arg_3_1:getChildByName("btn_one"):getChildByName("txt_price_1"):setVisible(true)
										arg_3_1:getChildByName("btn_one"):getChildByName("word_free"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("zuanshi"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("ticket"):setVisible(true)
										arg_3_1:getChildByName("btn_one"):getChildByName("txt_price_1"):setString("1")
									else
										arg_3_1:getChildByName("btn_one"):getChildByName("zuanshi"):setVisible(true)
										arg_3_1:getChildByName("btn_one"):getChildByName("ticket"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("word_free"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("txt_price_1"):setVisible(true)
										arg_3_1:getChildByName("btn_one"):getChildByName("txt_price_1"):setString(tostring(xyd.tables.misc.activityConsumeGiftOnce))
									end

									arg_3_0.details = arg_6_1.details
									arg_3_0.flipTimes = arg_3_0.details.record_info.cur_num
									arg_3_0.canGetTime = arg_3_0.details.record_info.record

									arg_3_0:updateCatState(arg_3_1)
								end
							end)
						end
					end)
				elseif arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityConsumeGiftTicket) > 0 then
					local var_4_1 = {
						summon_type = xyd.SummonType.ConsumeGift,
						summon_index = var_0_4.ticket
					}

					xyd.Backend.get():request(xyd.mid.CONSUME_GIFT_SUMMON, var_4_1, function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							arg_3_0.selfPlayer:handleRewards(arg_7_1.awards)
							arg_3_0.selfPlayer:getBackpack():addItemsByID(xyd.tables.misc.activityConsumeGiftTicket, -1)

							if arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityConsumeGiftTicket) <= 0 then
								local var_7_0 = {}

								var_7_0.itemNum = 0
								var_7_0.itemID = xyd.tables.misc.activityConsumeGiftTicket

								arg_3_0.selfPlayer:getBackpack():removeItem(var_7_0)
							end

							local var_7_1 = {
								activity_id = xyd.Activities.ConsumeGift
							}

							xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_7_1, function(arg_8_0, arg_8_1)
								if arg_8_0 == xyd.error.OK then
									if arg_8_1.details.free_summon_times > 0 then
										arg_3_1:getChildByName("btn_one"):getChildByName("zuanshi"):setVisible(true)
										arg_3_1:getChildByName("btn_one"):getChildByName("ticket"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("txt_price_1"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("word_free"):setVisible(true)
									elseif arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.activityConsumeGiftTicket) > 0 then
										arg_3_1:getChildByName("btn_one"):getChildByName("txt_price_1"):setVisible(true)
										arg_3_1:getChildByName("btn_one"):getChildByName("word_free"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("zuanshi"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("ticket"):setVisible(true)
										arg_3_1:getChildByName("btn_one"):getChildByName("txt_price_1"):setString("1")
									else
										arg_3_1:getChildByName("btn_one"):getChildByName("zuanshi"):setVisible(true)
										arg_3_1:getChildByName("btn_one"):getChildByName("ticket"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("word_free"):setVisible(false)
										arg_3_1:getChildByName("btn_one"):getChildByName("txt_price_1"):setVisible(true)
										arg_3_1:getChildByName("btn_one"):getChildByName("txt_price_1"):setString(tostring(xyd.tables.misc.activityConsumeGiftOnce))
									end

									arg_3_0.details = arg_8_1.details
									arg_3_0.flipTimes = arg_3_0.details.record_info.cur_num
									arg_3_0.canGetTime = arg_3_0.details.record_info.record

									arg_3_0:updateCatState(arg_3_1)
								end
							end)
						end
					end)
				elseif arg_3_0.selfPlayer.crystal < xyd.tables.misc.activityConsumeGiftOnce then
					local var_4_2 = var_0_1:translation("ZUANSHI_ABSENCE")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_2, function()
						local var_9_0 = {}

						var_9_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					local var_4_3 = var_0_1:translation("CONSUME_GIFT_WORD_3")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_3, function()
						local var_10_0 = {
							summon_type = xyd.SummonType.ConsumeGift,
							summon_index = var_0_4.once
						}

						xyd.Backend.get():request(xyd.mid.CONSUME_GIFT_SUMMON, var_10_0, function(arg_11_0, arg_11_1)
							if arg_11_0 == xyd.error.OK then
								arg_3_0.selfPlayer:handleRewards(arg_11_1.awards)

								arg_3_0.flipTimes = arg_11_1.record_info.cur_num
								arg_3_0.canGetTime = arg_11_1.record_info.record

								arg_3_0:updateCatState(arg_3_1)
							end
						end)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_3_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_3_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
	var_3_4:addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			if arg_3_0.activity.is_open == 1 then
				if arg_3_0.selfPlayer.crystal < xyd.tables.misc.activityConsumeGiftFive then
					local var_12_0 = var_0_1:translation("ZUANSHI_ABSENCE")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_0, function()
						local var_13_0 = {}

						var_13_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					local var_12_1 = var_0_1:translation("CONSUME_GIFT_WORD_3")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_1, function()
						local var_14_0 = {
							summon_type = xyd.SummonType.ConsumeGift,
							summon_index = var_0_4.five
						}

						xyd.Backend.get():request(xyd.mid.CONSUME_GIFT_SUMMON, var_14_0, function(arg_15_0, arg_15_1)
							if arg_15_0 == xyd.error.OK then
								arg_3_0.selfPlayer:handleRewards(arg_15_1.awards)

								arg_3_0.flipTimes = arg_15_1.record_info.cur_num
								arg_3_0.canGetTime = arg_15_1.record_info.record

								arg_3_0:updateCatState(arg_3_1)
							end
						end)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_3_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_3_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
	arg_3_1:getChildByName("cat"):setTouchEnabled(true)
	arg_3_1:getChildByName("cat"):setTouchSwallowEnabled(false)
	arg_3_1:getChildByName("cat"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			arg_3_1:getChildByName("cat"):setScale(0.9)

			return true
		elseif arg_16_0.name == "moved" then
			arg_3_1:getChildByName("cat"):setScale(1)
		elseif arg_16_0.name == "ended" then
			arg_3_1:getChildByName("cat"):setScale(1)
			arg_3_0.activitiesModel:getActivityReward(xyd.Activities.ConsumeGift, nil, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					arg_3_0.selfPlayer:handleRewards(arg_17_1.awards)

					arg_3_0.canGetTime = arg_3_0.canGetTime - 1

					arg_3_0:updateCatState(arg_3_1)
				end
			end)
		end
	end)
	arg_3_1:getChildByName("cat_an"):setTouchEnabled(true)
	arg_3_1:getChildByName("cat_an"):setTouchSwallowEnabled(false)
	arg_3_1:getChildByName("cat_an"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
		if arg_18_0.name == "began" then
			arg_3_1:getChildByName("cat_an"):setScale(0.9)

			return true
		elseif arg_18_0.name == "moved" then
			arg_3_1:getChildByName("cat_an"):setScale(1)
		elseif arg_18_0.name == "ended" then
			arg_3_1:getChildByName("cat_an"):setScale(1)

			local var_18_0 = var_0_1:translation("ACTIVITY_CHARGE_GIFT_TIP")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_18_0
			})
		end
	end)
	arg_3_0:updateCatState(arg_3_1)
end

function var_0_0.updateCatState(arg_19_0, arg_19_1)
	arg_19_1:getChildByName("text_cur_times"):setString(arg_19_0.flipTimes .. "/" .. xyd.tables.misc.activityChargeGiftTimes)
	arg_19_1:getChildByName("record_bg"):getChildByName("text_canget"):setString(string.format(var_0_1:translation("ACTIVITY_CHARGE_GIFT_RECORD"), arg_19_0.canGetTime))

	if arg_19_0.canGetTime > 0 then
		arg_19_1:getChildByName("cat_an"):setVisible(false)
		arg_19_0.effect:setVisible(true)
	else
		arg_19_1:getChildByName("cat_an"):setVisible(true)
		arg_19_0.effect:setVisible(false)
	end
end

function var_0_0.rewardLayer(arg_20_0, arg_20_1)
	local var_20_0 = var_0_3:getItems()

	if #var_20_0 == 1 and var_20_0[1] == 0 then
		var_20_0 = {}
	end

	local var_20_1 = var_0_3:getItemNum()
	local var_20_2 = #var_20_1
	local var_20_3 = arg_20_1:getContentSize().height
	local var_20_4 = 39
	local var_20_5 = #var_20_0

	for iter_20_0 = 1, #var_20_0 do
		local var_20_6 = display.newNode()

		var_20_6:setContentSize(var_20_3, var_20_3)

		local var_20_7 = xyd.tables.item:type(var_20_0[iter_20_0])

		xyd.setItemBorder(var_20_6, var_20_0[iter_20_0], false, false, var_20_1[iter_20_0])

		if var_0_3:isRare(iter_20_0) == 1 then
			local var_20_8 = xyd.AssetLoader:get():loadSprite("windows/activities/1121/rare.png")

			var_20_8:setPosition(0, var_20_3)
			var_20_8:setAnchorPoint(cc.p(0, 1))
			var_20_6:addChild(var_20_8)
		end

		var_20_6:addTo(arg_20_1)
		var_20_6:setAnchorPoint(cc.p(0, 0))
		var_20_6:setPosition((iter_20_0 - 1) * (var_20_3 + var_20_4), 0)

		local var_20_9 = {
			id = var_20_0[iter_20_0],
			lev = xyd.tables.item:level(var_20_0[iter_20_0])
		}

		if xyd.tables.item:type(var_20_0[iter_20_0]) == -1 then
			var_20_9.tipsType = 0
			var_20_9.desc1 = xyd.tables.hero:getDes(var_20_0[iter_20_0])
		elseif specialItem then
			var_20_9.tipsType = 1
			var_20_9.id = -3
		else
			var_20_9.tipsType = 1
			var_20_9.desc1 = xyd.tables.item:desc1(var_20_0[iter_20_0])
			var_20_9.desc2 = xyd.tables.item:desc2(var_20_0[iter_20_0])
		end

		var_20_9.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_20_0[iter_20_0])
		var_20_9.name = xyd.tables.item:name(var_20_0[iter_20_0])

		arg_20_0:addTips(var_20_6, var_20_9)
	end

	local var_20_10 = xyd.tables.gift:crystal(giftCode)

	if var_20_10 and var_20_10 > 0 then
		local var_20_11 = display.newNode()

		var_20_11:setContentSize(var_20_3, var_20_3)
		xyd.setItemBorder(var_20_11, -1, false, false, var_20_10)
		var_20_11:addTo(arg_20_1)
		var_20_11:setAnchorPoint(cc.p(0, 0))
		var_20_11:setPosition(var_20_5 * (var_20_3 + var_20_4), 0)

		local var_20_12 = {}

		var_20_12.id = -1
		var_20_12.tipsType = 1

		arg_20_0:addTips(var_20_11, var_20_12)

		var_20_5 = var_20_5 + 1
	end

	local var_20_13 = xyd.tables.gift:mana(giftCode)

	if var_20_13 and var_20_13 > 0 then
		local var_20_14 = display.newNode()

		var_20_14:setContentSize(var_20_3, var_20_3)
		xyd.setItemBorder(var_20_14, -2, false, false, var_20_13)
		var_20_14:addTo(arg_20_1)
		var_20_14:setAnchorPoint(cc.p(0, 0))
		var_20_14:setPosition(var_20_5 * (var_20_3 + var_20_4), 0)

		local var_20_15 = {}

		var_20_15.id = -2
		var_20_15.tipsType = 1

		arg_20_0:addTips(var_20_14, var_20_15)

		local var_20_16 = var_20_5 + 1
	end

	return arg_20_1
end

return var_0_0
