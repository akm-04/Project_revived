local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc
local var_0_4 = xyd.tables.activityBalloonPool
local var_0_5 = xyd.tables.activityBalloonMission
local var_0_6 = xyd.tables.activityBalloonRefreshPrice
local var_0_7 = xyd.tables.activityBalloonDropbox
local var_0_8 = {
	cc.p(0.4, 0.9),
	cc.p(0.49, 0.91),
	cc.p(0.5, 0.9)
}
local var_0_9 = var_0_3:getValue("activity_balloon_refresh_limit_time")
local var_0_10 = var_0_3:getValue("activity_balloon_round_limit")
local var_0_11 = var_0_3:getValue("activity_balloon_round_special")
local var_0_12 = var_0_3:getValue("activity_balloon_item_id")
local var_0_13 = var_0_3:getValue("activity_balloon_item_num")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.isEffectPlaying = false
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
	arg_2_0:initTextString()
	arg_2_0:initBtns()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = xyd.createEffect("skeletons/ui_effect/activity_balloon/daqiqiutexiao02")

	var_3_0:play(nil, true)
	arg_3_0.container:getChildByName("award_effect"):addChild(var_3_0)

	local var_3_1 = xyd.createEffect("skeletons/ui_effect/activity_balloon/daqiqiutexiao05")
	local var_3_2 = arg_3_0.container:getChildByName("btn_buy_dart"):getContentSize()

	var_3_1:setPosition(var_3_2.width / 2, var_3_2.height / 2)
	var_3_1:play(nil, true)
	arg_3_0.container:getChildByName("btn_buy_dart"):addChild(var_3_1)

	local var_3_3 = xyd.createEffect("skeletons/ui_effect/activity_balloon/daqiqiutexiao04")
	local var_3_4 = arg_3_0.container:getChildByName("next"):getChildByName("btn_next")
	local var_3_5 = var_3_4:getContentSize()

	var_3_3:setPosition(var_3_5.width / 2 - 3, var_3_5.height / 2 + 2)
	var_3_3:play(nil, true)
	var_3_4:addChild(var_3_3)
	arg_3_0:updateBalloonShow()
	arg_3_0:updateRound()
	arg_3_0:updateMission()
	arg_3_0:updateRefreshBtn()
	arg_3_0:updateDart()
end

function var_0_0.initTextString(arg_4_0)
	arg_4_0.container:getChildByName("txt_round"):enableOutline(cc.c4b(99, 123, 224, 255), 2)
	arg_4_0.container:getChildByName("txt_remain"):enableOutline(cc.c4b(99, 123, 224, 255), 2)
	arg_4_0.container:getChildByName("txt_dart_num"):enableOutline(cc.c4b(109, 19, 2, 255), 2)
	arg_4_0.container:getChildByName("txt_dart"):enableOutline(cc.c4b(109, 19, 2, 255), 2)
	arg_4_0.container:getChildByName("refresh"):getChildByName("txt_refresh"):enableOutline(cc.c4b(107, 59, 120, 255), 2)
	arg_4_0.container:getChildByName("refresh_gray"):getChildByName("txt_refresh2"):enableOutline(cc.c4b(55, 55, 55, 255), 2)
	arg_4_0.container:getChildByName("next"):getChildByName("txt_next"):enableOutline(cc.c4b(107, 59, 120, 255), 2)
	arg_4_0.container:getChildByName("txt_mission"):setString(var_0_2:translation("ACTIVITY_BALLOON_TEXT_1"))
	arg_4_0.container:getChildByName("txt_dart"):setString(var_0_2:translation("ACTIVITY_BALLOON_TEXT_2"))
	arg_4_0.container:getChildByName("btn_get"):getChildByName("txt_get"):setString(var_0_2:translation("ACTIVITY_BALLOON_TEXT_3"))
	arg_4_0.container:getChildByName("next"):getChildByName("txt_next"):setString(var_0_2:translation("ACTIVITY_BALLOON_TEXT_4"))
	arg_4_0.container:getChildByName("btn_buy_dart"):getChildByName("txt_buy_dart"):setString(var_0_2:translation("ACTIVITY_BALLOON_TEXT_5"))
end

function var_0_0.initBtns(arg_5_0)
	xyd.nodeEventSample(arg_5_0.container:getChildByName("btn_rule"), nil, function()
		local var_6_0 = {
			title_name = "ACTIVITY_BALLOON_RULE_TITLE",
			rule = "ACTIVITY_BALLOON_RULE_TEXT"
		}

		xyd.WindowManager.get():openWindow("new_text_rule", var_6_0)
	end)
	xyd.nodeEventSample(arg_5_0.container:getChildByName("btn_buy_dart"), nil, function()
		if arg_5_0.isEffectPlaying then
			return
		end

		local var_7_0 = {
			callback = handler(arg_5_0, arg_5_0.updateDart)
		}

		xyd.WindowManager.get():openWindow("activity_balloon_buy_dart", var_7_0)
	end)

	local var_5_0 = arg_5_0.container:getChildByName("refresh"):getChildByName("btn_refresh")

	xyd.nodeEventSample(var_5_0, nil, function()
		if arg_5_0.isEffectPlaying then
			return
		end

		local var_8_0 = arg_5_0.activity.details.base_info.daily_refresh
		local var_8_1 = var_0_6:price(var_8_0 + 1)
		local var_8_2 = string.format(var_0_2:translation("ACTIVITY_BALLOON_TEXT_16"), var_8_1)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_2, function()
			if arg_5_0.selfPlayer.crystal >= var_8_1 then
				xyd.Backend.get():request(xyd.mid.BALLOON_REFRESH_POOL, nil, function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						arg_5_0.activity.details = arg_10_1
						arg_5_0.activities[arg_5_0.idx].details = arg_10_1

						arg_5_0:updateRefreshBtn()
						arg_5_0:updateBalloonShow()
						arg_5_0:updateRound()
					end
				end)
			else
				local var_9_0 = var_0_2:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end)
			end
		end, nil, 0)
	end)

	local var_5_1 = arg_5_0.container:getChildByName("next"):getChildByName("btn_next")

	xyd.nodeEventSample(var_5_1, nil, function()
		if arg_5_0.isEffectPlaying then
			return
		end

		xyd.Backend.get():request(xyd.mid.BALLOON_NEXT_POOL, nil, function(arg_13_0, arg_13_1)
			if arg_13_0 == xyd.error.OK then
				arg_5_0.activity.details = arg_13_1
				arg_5_0.activities[arg_5_0.idx].details = arg_13_1

				arg_5_0:updateRefreshBtn()
				arg_5_0:updateBalloonShow()
				arg_5_0:updateRound()
			end
		end)
	end)
end

function var_0_0.updateBalloonShow(arg_14_0)
	for iter_14_0 = 1, 16 do
		arg_14_0:updateBalloonAtIndex(iter_14_0)
	end
end

function var_0_0.updateBalloonAtIndex(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0.activity.details.base_info.pool_id
	local var_15_1 = var_0_4:type(var_15_0)
	local var_15_2 = arg_15_0.activity.details.drop_info.item_ids[arg_15_1]
	local var_15_3 = arg_15_0.activity.details.drop_info.item_nums[arg_15_1]
	local var_15_4 = var_0_4:speicalItemId(var_15_0)
	local var_15_5 = arg_15_0.container:getChildByName("balloon_" .. arg_15_1)

	var_15_5:removeAllChildren()

	if var_15_2 and var_15_2 > 0 then
		xyd.setItemAndAddTips(var_15_5, var_15_2, var_15_3)

		if var_15_2 == var_0_7:itemId(var_15_4) and var_15_3 == var_0_7:itemNum(var_15_4) then
			local var_15_6 = xyd.createEffect("skeletons/ui_effect/activity_balloon/daqiqiutexiao03")
			local var_15_7 = var_15_5:getContentSize()

			var_15_6:setPosition(var_15_7.width / 2, var_15_7.height / 2)
			var_15_6:play(nil, true)
			var_15_5:addChild(var_15_6)
		end
	else
		local var_15_8 = xyd.AssetLoader.get():loadSprite("windows/activities/1225/balloon/bg.png")
		local var_15_9 = xyd.AssetLoader.get():loadSprite("windows/activities/1225/balloon/" .. var_15_1 .. ".png")
		local var_15_10 = var_15_5:getContentSize()

		var_15_8:setPosition(49.5, 106)
		var_15_9:setAnchorPoint(var_0_8[var_15_1])
		var_15_9:setPosition(var_15_10.width / 2, var_15_10.height)
		var_15_5:addChild(var_15_8)
		var_15_5:addChild(var_15_9)
		xyd.nodeEventSample(var_15_9, nil, function()
			if arg_15_0.isEffectPlaying then
				return
			end

			if arg_15_0.backpack:getItemNumByID(var_0_12) < var_0_13 then
				local var_16_0 = {
					callback = handler(arg_15_0, arg_15_0.updateDart)
				}

				xyd.WindowManager.get():openWindow("activity_balloon_buy_dart", var_16_0)

				return
			end

			xyd.Backend.get():request(xyd.mid.BALLOON_DRAW_POOL, {
				pos = arg_15_1
			}, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					var_15_9:setVisible(false)

					local var_17_0 = xyd.createEffect("skeletons/ui_effect/activity_balloon/daqiqiutexiao01")

					var_17_0:setPosition(var_15_10.width / 2, var_15_10.height / 2)
					var_17_0:addTo(var_15_5)

					arg_15_0.isEffectPlaying = true

					var_17_0:play(function()
						var_0_1.performWithDelayGlobal(function()
							arg_15_0.activity.details = arg_17_1
							arg_15_0.activities[arg_15_0.idx].details = arg_17_1

							arg_15_0.selfPlayer:handleRewards(arg_17_1.awards)
							arg_15_0.backpack:addItemsByID(var_0_12, -var_0_13)
							arg_15_0:updateBalloonAtIndex(arg_15_1)
							arg_15_0:updateDart()
							arg_15_0:updateMission()
							arg_15_0:updateRefreshBtn()

							arg_15_0.isEffectPlaying = false
						end, 0.01)
					end, nil, nil, "texiao0" .. var_15_1)
				end
			end)
		end)
	end
end

function var_0_0.updateRound(arg_20_0)
	local var_20_0 = arg_20_0.activity.details.base_info.round
	local var_20_1 = arg_20_0.activity.details.base_info.pool_id
	local var_20_2 = arg_20_0.activity.details.base_info.get_skin_pool == 1
	local var_20_3 = var_0_4:speicalItemId(var_20_1)
	local var_20_4 = var_0_7:itemId(var_20_3)
	local var_20_5 = var_0_7:itemNum(var_20_3)

	arg_20_0.container:getChildByName("word_5"):setVisible(var_20_0 >= var_0_10)
	arg_20_0.container:getChildByName("txt_round"):setString(var_20_0)
	arg_20_0.container:getChildByName("word_2"):setVisible(not var_20_2)
	arg_20_0.container:getChildByName("txt_remain"):setVisible(not var_20_2)
	arg_20_0.container:getChildByName("word_4"):setVisible(var_20_2 and var_0_4:type(var_20_1) == 1)
	arg_20_0.container:getChildByName("txt_remain"):setString(var_0_11 - var_20_0)
	arg_20_0.container:getChildByName("award"):removeAllChildren()
	xyd.setItemAndAddTips(arg_20_0.container:getChildByName("award"), var_20_4, var_20_5)
end

function var_0_0.updateMission(arg_21_0)
	local var_21_0 = arg_21_0.activity.details.mission_info.mission_id
	local var_21_1 = arg_21_0.activity.details.mission_info.drop_time
	local var_21_2 = arg_21_0.activity.details.mission_info.is_complete
	local var_21_3 = var_0_5:content(var_21_0)
	local var_21_4 = var_0_5:num(var_21_0)
	local var_21_5 = var_0_5:itemId(var_21_0)
	local var_21_6 = var_0_5:itemNum(var_21_0)

	arg_21_0.container:getChildByName("mission_item"):removeAllChildren()
	xyd.setItemAndAddTips(arg_21_0.container:getChildByName("mission_item"), var_21_5, var_21_6)

	if var_0_5:type(var_21_0) == 1 then
		arg_21_0.container:getChildByName("txt_mission_intro"):setString(var_21_3)
		arg_21_0.container:getChildByName("txt_mission_count"):setVisible(false)
	else
		arg_21_0.container:getChildByName("txt_mission_intro"):setString(string.format(var_21_3, var_21_4))
		arg_21_0.container:getChildByName("txt_mission_count"):setVisible(true)
		arg_21_0.container:getChildByName("txt_mission_count"):setString(var_21_1 .. "/" .. var_21_4)
	end

	if var_21_2 == 1 then
		arg_21_0.container:getChildByName("already_get"):setVisible(true)
		arg_21_0.container:getChildByName("txt_mission_count"):setVisible(false)
		arg_21_0.container:getChildByName("btn_get"):setVisible(false)

		return
	end

	if var_21_1 < var_21_4 then
		arg_21_0.container:getChildByName("btn_get"):setBright(false)
		arg_21_0.container:getChildByName("btn_get"):setTouchEnabled(false)
	else
		arg_21_0.container:getChildByName("btn_get"):setBright(true)
		arg_21_0.container:getChildByName("btn_get"):setTouchEnabled(true)
		arg_21_0.container:getChildByName("btn_get"):addTouchEventListener(function(arg_22_0, arg_22_1)
			xyd.buttonScaleAnim(arg_22_0, arg_22_1)

			if arg_22_1 == ccui.TouchEventType.ended then
				if arg_21_0.isEffectPlaying then
					return
				end

				xyd.Backend.get():request(xyd.mid.BALLOON_MISSION_AWARD, nil, function(arg_23_0, arg_23_1)
					if arg_23_0 == xyd.error.OK then
						arg_21_0.selfPlayer:handleRewards(arg_23_1.awards)

						arg_21_0.activity.details.mission_info = arg_23_1.mission_info
						arg_21_0.activities[arg_21_0.idx].details.mission_info = arg_23_1.mission_info

						arg_21_0:updateDart()
						arg_21_0:updateMission()
					end
				end)
			end
		end)
	end
end

function var_0_0.updateRefreshBtn(arg_24_0)
	local var_24_0 = arg_24_0.activity.details.base_info.round
	local var_24_1 = arg_24_0.activity.details.base_info.pool_id
	local var_24_2 = arg_24_0.activity.details.base_info.get_special
	local var_24_3 = arg_24_0.activity.details.base_info.daily_refresh
	local var_24_4 = var_0_6:price(var_24_3 + 1)

	if var_24_0 >= var_0_10 and var_24_2 == 1 then
		arg_24_0.container:getChildByName("refresh"):setVisible(false)
		arg_24_0.container:getChildByName("next"):setVisible(false)
		arg_24_0.container:getChildByName("refresh_gray"):setVisible(true)
		arg_24_0.container:getChildByName("refresh_gray"):getChildByName("txt_refresh2"):setString(var_0_2:translation("ACTIVITY_BALLOON_TEXT_7"))
	elseif var_24_2 == 1 then
		arg_24_0.container:getChildByName("refresh_gray"):setVisible(false)
		arg_24_0.container:getChildByName("next"):setVisible(true)
		arg_24_0.container:getChildByName("refresh"):setVisible(false)
	elseif var_0_4:type(var_24_1) == 1 then
		arg_24_0.container:getChildByName("refresh"):setVisible(false)
		arg_24_0.container:getChildByName("next"):setVisible(false)
		arg_24_0.container:getChildByName("refresh_gray"):setVisible(true)
		arg_24_0.container:getChildByName("refresh_gray"):getChildByName("txt_refresh2"):setString(var_0_2:translation("ACTIVITY_BALLOON_TEXT_8"))
	elseif var_24_3 < var_0_9 then
		local var_24_5 = arg_24_0.container:getChildByName("refresh")

		arg_24_0.container:getChildByName("refresh_gray"):setVisible(false)
		arg_24_0.container:getChildByName("next"):setVisible(false)
		var_24_5:setVisible(true)
		var_24_5:getChildByName("txt_price"):setString(var_24_4)
		var_24_5:getChildByName("txt_refresh"):setString(string.format(var_0_2:translation("ACTIVITY_BALLOON_TEXT_9"), var_0_9 - var_24_3, var_0_9))
	else
		arg_24_0.container:getChildByName("refresh"):setVisible(false)
		arg_24_0.container:getChildByName("refresh_gray"):setVisible(true)
		arg_24_0.container:getChildByName("next"):setVisible(false)
		arg_24_0.container:getChildByName("refresh_gray"):getChildByName("txt_refresh2"):setString(string.format(var_0_2:translation("ACTIVITY_BALLOON_TEXT_9"), 0, var_0_9))
	end
end

function var_0_0.updateDart(arg_25_0)
	local var_25_0 = arg_25_0.backpack:getItemNumByID(var_0_12)

	arg_25_0.container:getChildByName("txt_dart_num"):setString(var_25_0)
end

return var_0_0
