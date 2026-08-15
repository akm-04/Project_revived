local var_0_0 = class("Dragonboat2017MainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.misc.activityDragonBoatTicket

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dragonBoatModel = xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT2017)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.DRAGON_BOAT_UPDATE, handler(arg_2_0, arg_2_0.updateWindow))

	if not arg_2_0.dragonBoatModel.hasShowTip then
		arg_2_0.dragonBoatModel.hasShowTip = true

		xyd.WindowManager.get():openWindow("pic_tip", {
			path = "windows/activities/1104/main/tip_pic.png"
		})
	end
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
end

function var_0_0.willClose(arg_4_0)
	transition.stopTarget(arg_4_0)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:setButtonClick()
	arg_5_0:updateWindow()
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_6_0:nodeByName("rule_btn"):setScale(0.9)
		elseif arg_7_1 == ccui.TouchEventType.ended then
			arg_6_0:nodeByName("rule_btn"):setScale(1)
			xyd.WindowManager.get():openWindow("dragon_boat2017_rule")
		end
	end)
	arg_6_0:nodeByName("boating_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_6_0:nodeByName("boating_btn"):setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			arg_6_0:nodeByName("boating_btn"):setScale(1)

			if arg_6_0.backpack:getItemNumByID(var_0_4) <= 0 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_2:translation("NO_DRAGONBOAT_TIME_LEFT"), nil, nil, nil, arg_6_0.colorMode)

				return
			end

			arg_6_0:sureStartBoat()
		end
	end)
	arg_6_0:nodeByName("select_team_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			arg_6_0:nodeByName("select_team_btn"):setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.ended then
			arg_6_0:nodeByName("select_team_btn"):setScale(1)
			xyd.WindowManager.get():openWindow("dragon_boat2017_select_team")
		end
	end)
	arg_6_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			arg_6_0:nodeByName("rank_btn"):setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.ended then
			arg_6_0:nodeByName("rank_btn"):setScale(1)

			local var_10_0 = {}

			arg_6_0.dragonBoatModel:getRankData(var_10_0, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("dragon_boat2017_rank", arg_11_1)
				end
			end)
		end
	end)
	arg_6_0:nodeByName("exchange_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.began then
			arg_6_0:nodeByName("exchange_btn"):setScale(0.9)
		elseif arg_12_1 == ccui.TouchEventType.ended then
			arg_6_0:nodeByName("exchange_btn"):setScale(1)
			xyd.WindowManager.get():openWindow("dragon_boat2017_shop")
		end
	end)
end

function var_0_0.sureStartBoat(arg_13_0)
	local function var_13_0(arg_14_0)
		if xyd.tables.activityDragonship2:crystal(arg_13_0.dragonBoatModel:getBoatID()) * arg_14_0 > arg_13_0.selfPlayer.crystal then
			local var_14_0 = var_0_2:translation("ZUANSHI_ABSENCE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_0, function()
				xyd.WindowManager.get():openWindow("vip_recharge")
			end, nil, nil, arg_13_0.colorMode)
		elseif xyd.tables.activityDragonship2:crystal(arg_13_0.dragonBoatModel:getBoatID()) * arg_14_0 > 0 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_2:translation("DRAGONBOAT2017_COST_TIPS"), xyd.tables.activityDragonship2:crystal(arg_13_0.dragonBoatModel:getBoatID()) * arg_14_0, xyd.tables.activityDragonship2:name(arg_13_0.dragonBoatModel:getBoatID())), function()
				arg_13_0:playStartBoating(arg_14_0)
			end, nil, nil, arg_13_0.colorMode)
		else
			arg_13_0:playStartBoating(arg_14_0)
		end
	end

	local var_13_1 = {
		item_id = var_0_4,
		callback = var_13_0
	}

	xyd.WindowManager.get():openWindow("dragon_boat2017_confirm_start", var_13_1)
end

function var_0_0.playStartBoating(arg_17_0, arg_17_1)
	local var_17_0 = {
		boat_id = arg_17_0.dragonBoatModel:getBoatID(),
		ticket_num = arg_17_1
	}

	arg_17_0.dragonBoatModel:startBoating(var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			local var_18_0 = {
				itemID = var_0_4,
				itemNum = arg_17_1
			}

			arg_17_0.backpack:removeItem(var_18_0)
			arg_17_0:updateWindow()
			xyd.WindowManager.get():openWindow("dragon_boat2017_boating", res)
		end
	end)
end

function var_0_0.updateWindow(arg_19_0)
	local var_19_0 = arg_19_0.backpack:getItemNumByID(var_0_4)

	arg_19_0:nodeByName("remain_time_txt"):setString("x" .. var_19_0)

	if var_19_0 <= 0 then
		arg_19_0:nodeByName("remain_time_txt"):setColor(xyd.color.RED)
	else
		arg_19_0:nodeByName("remain_time_txt"):setColor(cc.c3b(232, 130, 18))
	end

	arg_19_0:updateBoat()
end

function var_0_0.setBackground(arg_20_0)
	local var_20_0 = arg_20_0:nodeByName("inner_container")
	local var_20_1 = display.newClippingRegionNode()

	var_20_1:setClippingRegion(cc.rect(0, 0, var_20_0:getWidth(), var_20_0:getHeight()))
	var_20_1:setContentSize(var_20_0:getContentSize())
	var_20_1:setLocalZOrder(var_20_0:getLocalZOrder())
	var_20_1:setTag(var_20_0:getTag())
	var_20_1:setName("clipping")
	var_20_1:addTo(var_20_0)
	var_20_1:align(display.LEFT_BOTTOM, 0, 0)

	local var_20_2 = xyd.AssetLoader.get():loadSprite("images/maps/dragon_boat_back.png")

	var_20_1:addChild(var_20_2)
	var_20_2:align(display.CENTER, var_20_1:getWidth() / 2, var_20_1:getHeight() / 2)
end

function var_0_0.updateBoat(arg_21_0)
	local var_21_0 = arg_21_0:nodeByName("boat_container")

	var_21_0:removeAllChildren()
	arg_21_0:getBoatResource():addTo(var_21_0):align(display.CENTER_BOTTOM, var_21_0:getWidth() / 2, 0)
end

function var_0_0.getBoatResource(arg_22_0)
	local var_22_0 = display.newNode()

	var_22_0:size(500, 200)

	local var_22_1 = arg_22_0.dragonBoatModel:getTeams()

	for iter_22_0, iter_22_1 in pairs(var_22_1) do
		local var_22_2 = iter_22_1:getHeroModel()

		var_22_2:setScale(0.7)
		var_22_2:addTo(var_22_0)
		var_22_2:setPosition(cc.p(400 - (iter_22_0 - 1) * 90, 68))
	end

	local var_22_3 = xyd.AssetLoader.get():loadSprite("windows/activities/1104/boat" .. arg_22_0.dragonBoatModel:getBoatID() .. ".png")
	local var_22_4 = var_22_0:getWidth()
	local var_22_5 = var_22_0:getHeight()

	var_22_3:addTo(var_22_0):align(display.CENTER_BOTTOM, var_22_4 / 2, 0)

	return var_22_0
end

return var_0_0
