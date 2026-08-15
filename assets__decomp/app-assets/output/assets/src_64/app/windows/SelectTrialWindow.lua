local var_0_0 = class("TrialItem", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/trial_window/trial_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = xyd.tables.campaign:trialLv(arg_4_1)

	for iter_4_0 = 1, 12 do
		if var_4_0 == iter_4_0 then
			arg_4_0.contentView_:nodeByName("button" .. iter_4_0):setVisible(true)
		else
			arg_4_0.contentView_:nodeByName("button" .. iter_4_0):setVisible(false)
		end

		if arg_4_2 >= 0 and arg_4_2 <= 3 then
			for iter_4_1 = 1, 3 do
				if arg_4_2 < iter_4_1 then
					arg_4_0.contentView_:nodeByName("light_star_" .. iter_4_1):setVisible(false)
				else
					arg_4_0.contentView_:nodeByName("light_star_" .. iter_4_1):setVisible(true)
				end
			end
		end
	end
end

local var_0_1 = class("SelectTrialWindow", import("app.common.ui.BaseWindow"))
local var_0_2 = import("app.common.ui.SplitLine")

var_0_1.TXT_LEFT_TIMES = "txt_left_times"
var_0_1.TXT_ENERGY = "txt_energy"
var_0_1.BTN_BUY = "btn_buy"

local var_0_3 = xyd.tables.translation

function var_0_1.ctor(arg_5_0, arg_5_1, arg_5_2)
	var_0_1.super.ctor(arg_5_0, arg_5_1, arg_5_2)

	arg_5_0.trial = arg_5_2
	arg_5_0.buyTimes = 0
	arg_5_0.maxBuyTime = 0
	arg_5_0.buyCost = 0
end

function var_0_1.willOpen(arg_6_0, arg_6_1)
	arg_6_0:nodeByName(var_0_1.BTN_BUY):setVisible(false)

	arg_6_0.listView_ = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, 850, 250),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_6_0:nodeByName("campaign_list")):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.listView_:setTouchSwallowEnabled(true)
	arg_6_0:updateLayers()

	arg_6_0.initScrollNodeX = nil
	arg_6_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	local var_6_0 = xyd.tables.sound:getSound("ui_button_click")

	audio.playSound(var_6_0, false)

	local var_6_1 = xyd.tables.trialConfig:trials(arg_6_0.trial.id)
	local var_6_2 = tonumber(string.sub(tostring(var_6_1[1]), 1, 1))
	local var_6_3 = {}
	local var_6_4 = {
		xyd.DailyConsumeType.XiaoYao,
		xyd.DailyConsumeType.YiLing,
		xyd.DailyConsumeType.ChiBi,
		xyd.DailyConsumeType.PhysicsTest,
		xyd.DailyConsumeType.MagicTest
	}

	for iter_6_0, iter_6_1 in ipairs(var_6_4) do
		var_6_3[iter_6_0] = var_6_4[iter_6_0] * 2 - 1
	end

	local var_6_5 = tonumber(var_6_3[var_6_2])

	arg_6_0.maxBuyTime = xyd.tables.dailyConsume:getNum(var_6_4[var_6_2])
	arg_6_0.buyCost = xyd.tables.dailyConsume:getCost(var_6_4[var_6_2])

	xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME_LOAD, {}, function(arg_7_0, arg_7_1)
		local var_7_0 = arg_7_1.buy_times

		arg_6_0.buyTimes = tonumber(string.sub(var_7_0, var_6_5, var_6_5))

		if arg_6_0.buyTimes == arg_6_0.maxBuyTime then
			arg_6_0:nodeByName(var_0_1.BTN_BUY):setVisible(true)
		end
	end, {}, false, true)
	arg_6_0.selfPlayer:loadTrialInfos(function()
		if arg_6_0.selfPlayer and arg_6_0.updateItems then
			arg_6_0.campaigns = arg_6_0.selfPlayer.worldMaps_

			arg_6_0:updateItems()
		end
	end)
end

function var_0_1.updateLayers(arg_9_0)
	if arg_9_0.trial.leftTimes > 0 then
		arg_9_0:nodeByName(var_0_1.TXT_LEFT_TIMES):setString(string.format(var_0_3:translation("TRIAL_LEFT_TIMES"), tostring(arg_9_0.trial.leftTimes)))
	else
		arg_9_0:nodeByName(var_0_1.TXT_LEFT_TIMES):setString(var_0_3:translation("TRIAL_NO_TIMES_LEFT"))
		arg_9_0:nodeByName(var_0_1.BTN_BUY):setVisible(true)
	end

	local var_9_0 = xyd.tables.trialConfig:energyCost(arg_9_0.trial.id)

	arg_9_0:nodeByName(var_0_1.TXT_ENERGY):setString(string.format(var_0_3:translation("TRIAL_ENERGY"), tostring(var_9_0)))
	arg_9_0:nodeByName("txt_name"):setString(var_0_3:translation("TRIAL_SELECT"))
	arg_9_0:nodeByName(var_0_1.TXT_ENERGY):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_9_0:nodeByName("txt_name"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_9_0:nodeByName(var_0_1.TXT_LEFT_TIMES):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_9_1 = arg_9_0:nodeByName("bar"):getContentSize()
	local var_9_2 = var_0_2.new({
		size = var_9_1.width
	})

	var_9_2:addTo(arg_9_0:nodeByName("background"))
	var_9_2:setAnchorPoint(0.5, 0.5)
	var_9_2:setPosition(arg_9_0:nodeByName("bar"):getPosition())
end

function var_0_1.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevX_ = arg_10_1.x
	elseif arg_10_1.name == "moved" and 20 <= math.abs(arg_10_1.x - arg_10_0.prevX_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

function var_0_1.updateItems(arg_11_0)
	if arg_11_0.listView_ and not tolua.isnull(arg_11_0.listView_) then
		arg_11_0.listView_:removeAllItems()
	else
		return
	end

	local var_11_0 = xyd.tables.trialConfig:trials(arg_11_0.trial.id)
	local var_11_1 = arg_11_0.selfPlayer.trialInfos_[arg_11_0.trial.id].lastID
	local var_11_2 = 0

	for iter_11_0 = 1, #var_11_0 do
		local var_11_3 = xyd.tables.campaign:campaignType(var_11_0[iter_11_0])
		local var_11_4 = tonumber(var_11_0[iter_11_0])

		if var_11_4 <= var_11_1 then
			local var_11_5 = arg_11_0.listView_:newItem()
			local var_11_6 = display.newNode()
			local var_11_7 = var_0_0.new()
			local var_11_8 = xyd.tables.campaign:openLv(var_11_0[iter_11_0])
			local var_11_9 = 0

			if arg_11_0.campaigns[var_11_4] ~= nil then
				var_11_9 = arg_11_0.campaigns[var_11_4].star
			end

			if var_11_8 <= arg_11_0.selfPlayer.lev then
				var_11_2 = var_11_2 + 1
			end

			var_11_7:setParams(var_11_0[iter_11_0], var_11_9)
			var_11_7:setTouchEnabled(true)
			var_11_7:setTouchSwallowEnabled(false)
			var_11_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
				if arg_12_0.name == "began" then
					local var_12_0 = xyd.tables.sound:getSound("ui_button_click")

					audio.playSound(var_12_0, false)
					var_11_7.contentView_:nodeByName("container"):setScale(0.9)

					return true
				elseif arg_12_0.name == "ended" then
					var_11_7.contentView_:nodeByName("container"):setScale(1)

					if not arg_11_0.scrollViewMoved_ then
						if arg_11_0.selfPlayer.lev >= var_11_8 then
							if arg_11_0.trial.leftTimes > 0 then
								local var_12_1 = {
									campaignID = var_11_0[iter_11_0],
									campaignType = var_11_3,
									star = var_11_9,
									dailyLimit = arg_11_0.trial.leftTimes,
									buyTimes = arg_11_0.buyTimes,
									maxBuyTime = arg_11_0.maxBuyTime
								}

								xyd.WindowManager.get():openWindow("new_map_detail_window", var_12_1)
							else
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_3:translation("TRIAL_NO_TIMES_LEFT")
								})

								return
							end
						else
							local var_12_2 = string.format(var_0_3:translation("OPENLEV_TIP"), var_11_8)

							xyd.WindowManager.get():openWindow("toast", {
								message = var_12_2
							})
						end
					end
				end
			end)
			var_11_6:addChild(var_11_7)
			var_11_5:addContent(var_11_6)
			var_11_6:setContentSize(220, 234)
			var_11_5:setItemSize(250, 234)
			arg_11_0.listView_:addItem(var_11_5)
		end
	end

	arg_11_0.listView_:reload()

	local var_11_10 = arg_11_0.listView_:getScrollNode()

	if not arg_11_0.initScrollNodeX then
		arg_11_0.initScrollNodeX = var_11_10:getPositionX()
	end

	if var_11_2 - 3 > 0 then
		var_11_10:setPositionX(arg_11_0.initScrollNodeX - var_11_2 * 250 + 850)
	end
end

function var_0_1.didOpen(arg_13_0)
	arg_13_0:addBlockLayer()
	arg_13_0:nodeByName(var_0_1.BTN_BUY):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			if arg_13_0.buyTimes >= arg_13_0.maxBuyTime then
				local var_14_0 = xyd.tables.translation:translation("DAILY_TIMES_OVER")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_14_0
				})

				return
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("DAILY_TRIAL_INFO"), function()
				arg_13_0:buyExtralTime()
			end, nil, 0, arg_13_0.colorMode)
		end
	end)
end

function var_0_1.buyExtralTime(arg_16_0)
	if arg_16_0.selfPlayer.crystal < arg_16_0.buyCost then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
			local var_17_0 = {}

			var_17_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_17_0)
		end, nil, nil, arg_16_0.colorMode)

		return
	end

	local var_16_0 = xyd.tables.trialConfig:trials(arg_16_0.trial.id)
	local var_16_1 = tonumber(string.sub(tostring(var_16_0[1]), 1, 1))
	local var_16_2 = {
		xyd.DailyConsumeType.XiaoYao,
		xyd.DailyConsumeType.YiLing,
		xyd.DailyConsumeType.ChiBi,
		xyd.DailyConsumeType.PhysicsTest,
		xyd.DailyConsumeType.MagicTest
	}

	params = {
		consume_id = var_16_2[var_16_1]
	}

	xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME, params, function(arg_18_0)
		if arg_18_0 == xyd.error.OK then
			arg_16_0.trial.leftTimes = arg_16_0.trial.leftTimes + 1
			arg_16_0.buyTimes = arg_16_0.buyTimes + 1

			arg_16_0:updateLayers()
		end
	end)
end

return var_0_1
