local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.activityChargeGift
local var_0_5 = {
	five = 2,
	once = 1
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

	local var_2_1 = var_2_0:getChildByName("bg")

	arg_2_0:layout(var_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	local var_3_0 = "skeletons/ui_effect/activity_charge_gift/zcmtx"
	local var_3_1 = var_3_0 .. ".json"
	local var_3_2 = var_3_0 .. ".atlas"

	arg_3_0.effect = var_0_3.new(var_3_1, var_3_2, 1)

	arg_3_0.effect:addTo(arg_3_1:getChildByName("cat"))
	arg_3_0.effect:setVisible(false)
	arg_3_0.effect:setAnchorPoint(cc.p(0, 0))
	arg_3_0.effect:play(nil, true)
	arg_3_1:getChildByName("cat"):setContentSize(74, 104)
	arg_3_0.effect:setPosition(37, 52)
	arg_3_1:getChildByName("cat"):setAnchorPoint(cc.p(0.5, 0.5))
	arg_3_1:getChildByName("txt_times"):setString(arg_3_0.details.times)
	arg_3_1:getChildByName("txt_1"):setString(string.format(var_0_1:translation("CHARGE_GIFT_WORD_1"), xyd.tables.misc.activityChargeGiftOnce))
	arg_3_1:getChildByName("txt_2"):setString(var_0_1:translation("CONSUME_GIFT_WORD_2"))
	arg_3_1:getChildByName("txt_4"):setString(var_0_1:translation("CHARGE_GIFT_WORD_3"))
	arg_3_1:getChildByName("txt_1"):enableOutline(cc.c4b(141, 80, 51, 255), 2)
	arg_3_1:getChildByName("txt_2"):enableOutline(cc.c4b(141, 80, 51, 255), 2)
	arg_3_1:getChildByName("txt_4"):enableOutline(cc.c4b(141, 80, 51, 255), 2)
	arg_3_1:getChildByName("txt_3"):setString(var_0_1:translation("ACTIVITY_CHARGE_GIFT_TEXT"))
	arg_3_1:getChildByName("btn_one"):getChildByName("txt_one"):setString(var_0_1:translation("ACTIVITY_1122_TEXT1"))
	arg_3_1:getChildByName("btn_five"):getChildByName("txt_five"):setString(var_0_1:translation("ACTIVITY_1122_TEXT2"))
	arg_3_1:getChildByName("btn_one"):getChildByName("txt_one"):enableOutline(cc.c4b(252, 214, 162, 255), 3)
	arg_3_1:getChildByName("btn_five"):getChildByName("txt_five"):enableOutline(cc.c4b(247, 237, 225, 255), 3)
	arg_3_1:getChildByName("award"):removeAllChildren()
	arg_3_0:rewardLayer(arg_3_1:getChildByName("award"))
	arg_3_1:getChildByName("btn_one"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_3_1:getChildByName("btn_one"):setScale(0.9, 0.9)
		end

		if arg_4_1 == ccui.TouchEventType.moved then
			arg_3_1:getChildByName("btn_one"):setScale(1, 1)
		end

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_1:getChildByName("btn_one"):setScale(1, 1)

			if arg_3_0.activity.is_open == 1 then
				if arg_3_0.details.times > 0 then
					local var_4_0 = {
						summon_type = xyd.SummonType.ChargeGift,
						summon_index = var_0_5.once
					}

					xyd.Backend.get():request(xyd.mid.CHARGE_GIFT_SUMMON, var_4_0, function(arg_5_0, arg_5_1)
						if arg_5_0 == xyd.error.OK then
							arg_3_0.selfPlayer:handleRewards(arg_5_1.awards)

							arg_3_0.details.times = arg_3_0.details.times - 1

							local var_5_0 = {
								activity_id = xyd.Activities.ChargeGift
							}

							xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_5_0, function(arg_6_0, arg_6_1)
								if arg_6_0 == xyd.error.OK then
									arg_3_1:getChildByName("txt_times"):setString(arg_6_1.details.times)

									arg_3_0.details = arg_6_1.details
									arg_3_0.flipTimes = arg_3_0.details.record_info.cur_num
									arg_3_0.canGetTime = arg_3_0.details.record_info.record

									arg_3_0:updateCatState(arg_3_1)
								end
							end)
						end
					end)
				else
					local var_4_1 = var_0_1:translation("CHARGE_GIFT_WORD_2")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_1, function()
						local var_7_0 = {}

						var_7_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
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
	arg_3_1:getChildByName("btn_five"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_3_1:getChildByName("btn_five"):setScale(0.9, 0.9)
		end

		if arg_8_1 == ccui.TouchEventType.moved then
			arg_3_1:getChildByName("btn_five"):setScale(1, 1)
		end

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_3_1:getChildByName("btn_five"):setScale(1, 1)

			if arg_3_0.activity.is_open == 1 then
				if arg_3_0.details.times >= 5 then
					local var_8_0 = {
						summon_type = xyd.SummonType.ChargeGift,
						summon_index = var_0_5.five
					}

					xyd.Backend.get():request(xyd.mid.CHARGE_GIFT_SUMMON, var_8_0, function(arg_9_0, arg_9_1)
						if arg_9_0 == xyd.error.OK then
							arg_3_0.selfPlayer:handleRewards(arg_9_1.awards)

							arg_3_0.details.times = arg_3_0.details.times - 5

							local var_9_0 = {
								activity_id = xyd.Activities.ChargeGift
							}

							xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_9_0, function(arg_10_0, arg_10_1)
								if arg_10_0 == xyd.error.OK then
									arg_3_1:getChildByName("txt_times"):setString(arg_10_1.details.times)

									arg_3_0.details = arg_10_1.details
									arg_3_0.flipTimes = arg_3_0.details.record_info.cur_num
									arg_3_0.canGetTime = arg_3_0.details.record_info.record

									arg_3_0:updateCatState(arg_3_1)
								end
							end)
						end
					end)
				else
					local var_8_1 = var_0_1:translation("CHARGE_GIFT_WORD_2")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_1, function()
						local var_11_0 = {}

						var_11_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
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
	arg_3_1:getChildByName("cat"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			arg_3_1:getChildByName("cat"):setScale(0.9)

			return true
		elseif arg_12_0.name == "moved" then
			arg_3_1:getChildByName("cat"):setScale(1)
		elseif arg_12_0.name == "ended" then
			arg_3_1:getChildByName("cat"):setScale(1)
			arg_3_0.activitiesModel:getActivityReward(xyd.Activities.ChargeGift, nil, function(arg_13_0, arg_13_1)
				if arg_13_0 == xyd.error.OK then
					arg_3_0.selfPlayer:handleRewards(arg_13_1.awards)

					arg_3_0.canGetTime = arg_3_0.canGetTime - 1

					arg_3_0:updateCatState(arg_3_1)
				end
			end)
		end
	end)
	arg_3_1:getChildByName("cat_an"):setTouchEnabled(true)
	arg_3_1:getChildByName("cat_an"):setTouchSwallowEnabled(false)
	arg_3_1:getChildByName("cat_an"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			arg_3_1:getChildByName("cat_an"):setScale(0.9)

			return true
		elseif arg_14_0.name == "moved" then
			arg_3_1:getChildByName("cat_an"):setScale(1)
		elseif arg_14_0.name == "ended" then
			arg_3_1:getChildByName("cat_an"):setScale(1)

			local var_14_0 = var_0_1:translation("ACTIVITY_CHARGE_GIFT_TIP")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_14_0
			})
		end
	end)

	if xyd.tables.misc.mifurenShowItem > 0 then
		arg_3_1:getChildByName("btn_check"):setVisible(true)
	else
		arg_3_1:getChildByName("btn_check"):setVisible(false)
	end

	arg_3_1:getChildByName("btn_check"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.began then
			arg_3_1:getChildByName("btn_check"):setScale(0.9)
		elseif arg_15_1 == ccui.TouchEventType.moved then
			arg_3_1:getChildByName("btn_check"):setScale(1)
		elseif arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_1:getChildByName("btn_check"):setScale(1)

			local var_15_0 = var_0_2.new()

			var_15_0:initUnCollected(xyd.tables.misc.mifurenShowItem)

			var_15_0.isHideBorrow = true

			xyd.WindowManager.get():openWindow(xyd.WindowName.heroattributeWnd, var_15_0)
		end
	end)
	arg_3_0:updateCatState(arg_3_1)
end

function var_0_0.updateCatState(arg_16_0, arg_16_1)
	arg_16_1:getChildByName("text_cur_times"):setString(arg_16_0.flipTimes .. "/" .. xyd.tables.misc.activityChargeGiftTimes)
	arg_16_1:getChildByName("text_cur_times"):enableOutline(cc.c4b(243, 96, 125, 255), 2)
	arg_16_1:getChildByName("record_bg"):getChildByName("text_canget"):setString(string.format(var_0_1:translation("ACTIVITY_CHARGE_GIFT_RECORD"), arg_16_0.canGetTime))

	if arg_16_0.canGetTime > 0 then
		arg_16_1:getChildByName("cat_an"):setVisible(false)
		arg_16_0.effect:setVisible(true)
	else
		arg_16_1:getChildByName("cat_an"):setVisible(true)
		arg_16_0.effect:setVisible(false)
	end
end

function var_0_0.rewardLayer(arg_17_0, arg_17_1)
	local var_17_0 = var_0_4:getItems()

	if #var_17_0 == 1 and var_17_0[1] == 0 then
		var_17_0 = {}
	end

	local var_17_1 = var_0_4:getItemNum()
	local var_17_2 = #var_17_1
	local var_17_3 = arg_17_1:getContentSize().height
	local var_17_4 = 39
	local var_17_5 = #var_17_0

	for iter_17_0 = 1, #var_17_0 do
		local var_17_6 = display.newNode()

		var_17_6:setContentSize(var_17_3, var_17_3)

		local var_17_7 = xyd.tables.item:type(var_17_0[iter_17_0])

		xyd.setItemBorder(var_17_6, var_17_0[iter_17_0], false, false, var_17_1[iter_17_0])

		if var_0_4:isRare(iter_17_0) == 1 then
			local var_17_8 = xyd.AssetLoader:get():loadSprite("windows/activities/1121/rare.png")

			var_17_8:setPosition(0, var_17_3)
			var_17_8:setAnchorPoint(cc.p(0, 1))
			var_17_6:addChild(var_17_8)
		end

		var_17_6:addTo(arg_17_1)
		var_17_6:setAnchorPoint(cc.p(0, 0))
		var_17_6:setPosition((iter_17_0 - 1) * (var_17_3 + var_17_4), 0)

		local var_17_9 = {
			id = var_17_0[iter_17_0],
			lev = xyd.tables.item:level(var_17_0[iter_17_0])
		}

		if xyd.tables.item:type(var_17_0[iter_17_0]) == -1 then
			var_17_9.tipsType = 0
			var_17_9.desc1 = xyd.tables.hero:getDes(var_17_0[iter_17_0])
		elseif specialItem then
			var_17_9.tipsType = 1
			var_17_9.id = -3
		else
			var_17_9.tipsType = 1
			var_17_9.desc1 = xyd.tables.item:desc1(var_17_0[iter_17_0])
			var_17_9.desc2 = xyd.tables.item:desc2(var_17_0[iter_17_0])
		end

		var_17_9.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_17_0[iter_17_0])
		var_17_9.name = xyd.tables.item:name(var_17_0[iter_17_0])

		arg_17_0:addTips(var_17_6, var_17_9)
	end

	local var_17_10 = xyd.tables.gift:crystal(giftCode)

	if var_17_10 and var_17_10 > 0 then
		local var_17_11 = display.newNode()

		var_17_11:setContentSize(var_17_3, var_17_3)
		xyd.setItemBorder(var_17_11, -1, false, false, var_17_10)
		var_17_11:addTo(arg_17_1)
		var_17_11:setAnchorPoint(cc.p(0, 0))
		var_17_11:setPosition(var_17_5 * (var_17_3 + var_17_4), 0)

		local var_17_12 = {}

		var_17_12.id = -1
		var_17_12.tipsType = 1

		arg_17_0:addTips(var_17_11, var_17_12)

		var_17_5 = var_17_5 + 1
	end

	local var_17_13 = xyd.tables.gift:mana(giftCode)

	if var_17_13 and var_17_13 > 0 then
		local var_17_14 = display.newNode()

		var_17_14:setContentSize(var_17_3, var_17_3)
		xyd.setItemBorder(var_17_14, -2, false, false, var_17_13)
		var_17_14:addTo(arg_17_1)
		var_17_14:setAnchorPoint(cc.p(0, 0))
		var_17_14:setPosition(var_17_5 * (var_17_3 + var_17_4), 0)

		local var_17_15 = {}

		var_17_15.id = -2
		var_17_15.tipsType = 1

		arg_17_0:addTips(var_17_14, var_17_15)

		local var_17_16 = var_17_5 + 1
	end

	return arg_17_1
end

return var_0_0
