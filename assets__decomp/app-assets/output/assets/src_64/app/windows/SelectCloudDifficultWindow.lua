local var_0_0 = class("SelectCloudDifficultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 150
local var_0_3 = 39
local var_0_4 = {
	xyd.DailyConsumeType.CLOUD_LADDER,
	xyd.DailyConsumeType.CLOUD_ROAD,
	xyd.DailyConsumeType.CLOUD_TEMPLE
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.trialID = arg_1_2.trialID
	arg_1_0.guidePos = nil
	arg_1_0.buyTimes = 0
	arg_1_0.maxBuyTime = 0
	arg_1_0.campaigns = arg_1_2.campaigns
	arg_1_0.trial = arg_1_2.trial
	arg_1_0.dailyConsumeID = var_0_4[arg_1_0.trialID - var_0_3]
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:updateLayers()

	arg_2_0.maxBuyTime = xyd.tables.dailyConsume:getNum(arg_2_0.dailyConsumeID)
	arg_2_0.buyCost = xyd.tables.dailyConsume:getCost(arg_2_0.dailyConsumeID)

	xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME_LOAD, {}, function(arg_3_0, arg_3_1)
		local var_3_0 = xyd.splitToNumber(arg_3_1.buy_times, "|")

		arg_2_0.buyTimes = var_3_0[tonumber(arg_2_0.dailyConsumeID)]

		if arg_2_0.buyTimes == arg_2_0.maxBuyTime then
			arg_2_0:nodeByName("btn_buy"):setVisible(true)
		end

		arg_2_0:layout()
	end, {}, false, true)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
	arg_4_0:nodeByName("btn_buy"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.buyTimes >= arg_4_0.maxBuyTime then
				local var_5_0 = xyd.tables.translation:translation("DAILY_TIMES_OVER")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_5_0
				})

				return
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("DAILY_TRIAL_INFO"), function()
				arg_4_0:buyExtralTime()
			end, nil, 0, arg_4_0.colorMode)
		end
	end)
end

function var_0_0.updateLayers(arg_7_0)
	arg_7_0:nodeByName("title"):setString(var_0_1:translation("TRIAL_SELECT"))

	local var_7_0 = xyd.tables.trialConfig:energyCost(arg_7_0.trial.id)

	arg_7_0:nodeByName("text_cost"):setString(string.format(var_0_1:translation("TRIAL_ENERGY"), tostring(var_7_0)))

	if arg_7_0.trial.leftTimes > 0 then
		arg_7_0:nodeByName("text_count"):setString(var_0_1:translation("MAP_LEFT_TIMES") .. arg_7_0.trial.leftTimes)
		arg_7_0:nodeByName("btn_buy"):setVisible(false)
	else
		arg_7_0:nodeByName("text_count"):setString(var_0_1:translation("TRIAL_NO_TIMES_LEFT"))
		arg_7_0:nodeByName("btn_buy"):setVisible(true)
	end
end

function var_0_0.layout(arg_8_0)
	local var_8_0 = xyd.tables.trialConfig:trials(arg_8_0.trial.id)
	local var_8_1 = arg_8_0.selfPlayer.trialInfos_[arg_8_0.trial.id].lastID
	local var_8_2 = arg_8_0:nodeByName("detail_container")
	local var_8_3 = 30
	local var_8_4 = {}

	for iter_8_0 = 1, #var_8_0 do
		local var_8_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/cloud_city/difficult_item.csb")

		var_8_5:addTo(var_8_2)

		local var_8_6 = var_8_5:getChildByName("container")

		var_8_5:setPosition(cc.p(var_8_3, 0))

		var_8_3 = var_8_3 + var_8_6:getContentSize().width + 10

		local var_8_7 = xyd.tables.campaign:campaignType(var_8_0[iter_8_0])
		local var_8_8 = tonumber(var_8_0[iter_8_0])
		local var_8_9 = 0
		local var_8_10 = true

		if arg_8_0.campaigns[var_8_8] ~= nil then
			var_8_9 = arg_8_0.campaigns[var_8_8].star
		end

		table.insert(var_8_4, var_8_9)

		if iter_8_0 > 1 and var_8_4[iter_8_0 - 1] == 0 then
			var_8_10 = false
		end

		arg_8_0:setParams(var_8_6, var_8_9, iter_8_0, var_8_10)
		var_8_5:setTouchSwallowEnabled(false)
		var_8_5:setTouchEnabled(true)
		var_8_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "began" then
				local var_9_0 = xyd.tables.sound:getSound("ui_button_click")

				audio.playSound(var_9_0, false)
				var_8_6:setScale(0.9)

				return true
			elseif arg_9_0.name == "ended" then
				var_8_6:setScale(1)

				if arg_8_0.trial.leftTimes <= 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("MAP_NO_TIMES")
					})
				elseif iter_8_0 > 1 and var_8_4[iter_8_0 - 1] == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("CLOUD_TIPS_1")
					})
				else
					local var_9_1 = {
						campaignID = var_8_8,
						campaignType = var_8_7,
						star = var_8_9,
						dailyLimit = arg_8_0.trial.leftTimes,
						buyTimes = arg_8_0.buyTimes,
						maxBuyTime = arg_8_0.maxBuyTime
					}

					xyd.WindowManager.get():openWindow("map_detail_window", var_9_1)
				end
			end
		end)

		if iter_8_0 > 1 and var_8_4[iter_8_0 - 1] == 0 then
			break
		end
	end
end

function var_0_0.buyExtralTime(arg_10_0)
	if arg_10_0.selfPlayer.crystal < arg_10_0.buyCost then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, stringLocalizer:translation("ZUANSHI_ABSENCE"), function()
			local var_11_0 = {}

			var_11_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
		end, nil, nil, arg_10_0.colorMode)

		return
	end

	local var_10_0 = xyd.tables.trialConfig:trials(arg_10_0.trial.id)

	params = {
		consume_id = arg_10_0.dailyConsumeID
	}

	xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME, params, function(arg_12_0)
		if arg_12_0 == xyd.error.OK then
			arg_10_0.trial.leftTimes = arg_10_0.trial.leftTimes + 1
			arg_10_0.buyTimes = arg_10_0.buyTimes + 1

			arg_10_0:updateLayers()
		end
	end)
end

function var_0_0.setParams(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	for iter_13_0 = 1, 3 do
		if arg_13_4 then
			arg_13_1:getChildByName("button_gray_" .. iter_13_0):setVisible(false)

			if arg_13_3 == iter_13_0 then
				arg_13_1:getChildByName("button" .. iter_13_0):setVisible(true)
			else
				arg_13_1:getChildByName("button" .. iter_13_0):setVisible(false)
			end
		else
			arg_13_1:getChildByName("button" .. iter_13_0):setVisible(false)

			if arg_13_3 == iter_13_0 then
				arg_13_1:getChildByName("button_gray_" .. iter_13_0):setVisible(true)
			else
				arg_13_1:getChildByName("button_gray_" .. iter_13_0):setVisible(false)
			end
		end

		if arg_13_2 >= 0 and arg_13_2 <= 3 then
			for iter_13_1 = 1, 3 do
				if arg_13_2 < iter_13_1 then
					arg_13_1:getChildByName("light_star_" .. iter_13_1):setVisible(false)
				else
					arg_13_1:getChildByName("light_star_" .. iter_13_1):setVisible(true)
				end
			end
		end
	end
end

return var_0_0
