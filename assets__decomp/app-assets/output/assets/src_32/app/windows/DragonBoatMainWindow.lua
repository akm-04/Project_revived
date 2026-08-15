local var_0_0 = class("DragonboatMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.hero
local var_0_4 = {
	400,
	240,
	80,
	65
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dragonBoatModel = xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.DRAGON_BOAT_UPDATE, handler(arg_2_0, arg_2_0.updateWindow))

	arg_2_0.currentShowDay_ = 0
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
end

function var_0_0.willClose(arg_4_0)
	transition.stopTarget(arg_4_0)
end

function var_0_0.didClose(arg_5_0)
	return
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("label_top"):setString(var_0_2:translation("DRAGONBOAT_TOP_TIP"))
	arg_6_0:nodeByName("label_bottom"):setString(var_0_2:translation("DRAGONBOAT_BOTTOM_TIP"))
	arg_6_0:setBackground()
	arg_6_0:getRankBtn()
	arg_6_0:getRuleBtn()
	arg_6_0:getBoatingBtn()
	arg_6_0:updateWindow()
end

function var_0_0.updateWindow(arg_7_0)
	arg_7_0:nodeByName("label_num"):setString(arg_7_0.dragonBoatModel:getTimes())
	arg_7_0:updateBoat()
end

function var_0_0.setBackground(arg_8_0)
	local var_8_0 = arg_8_0:nodeByName("back_container")
	local var_8_1 = display.newClippingRegionNode()

	var_8_1:setClippingRegion(cc.rect(0, 0, var_8_0:getWidth(), var_8_0:getHeight()))
	var_8_1:setContentSize(var_8_0:getContentSize())
	var_8_1:setLocalZOrder(var_8_0:getLocalZOrder())
	var_8_1:setTag(var_8_0:getTag())
	var_8_1:setName("clipping")
	var_8_1:addTo(var_8_0)
	var_8_1:align(display.LEFT_BOTTOM, 0, 0)

	local var_8_2 = xyd.AssetLoader.get():loadSprite("images/maps/dragon_boat_back.png")

	var_8_1:addChild(var_8_2)
	var_8_2:align(display.CENTER, var_8_1:getWidth() / 2, var_8_1:getHeight() / 2)
end

function var_0_0.getRuleBtn(arg_9_0)
	if not arg_9_0.ruleBtn_ then
		arg_9_0.ruleBtn_ = arg_9_0:nodeByName("button_rule")

		arg_9_0.ruleBtn_:addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_9_0.dragonBoatModel:loadInfo(function()
					xyd.WindowManager.get():openWindow("dragon_boat_rule")
				end, true)
			end
		end)
	end

	return arg_9_0.ruleBtn_
end

function var_0_0.getRankBtn(arg_12_0)
	if not arg_12_0.rankBtn_ then
		arg_12_0.rankBtn_ = arg_12_0:nodeByName("button_rank")

		arg_12_0.rankBtn_:addTouchEventListener(function(arg_13_0, arg_13_1)
			if arg_13_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow("dragon_boat_rank")
			end
		end)
	end

	return arg_12_0.rankBtn_
end

function var_0_0.getBoatingBtn(arg_14_0)
	if not arg_14_0.boatingBtn_ then
		arg_14_0.boatingBtn_ = arg_14_0:nodeByName("button_boating")

		arg_14_0.boatingBtn_:addTouchEventListener(function(arg_15_0, arg_15_1)
			if arg_15_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_14_0.dragonBoatModel:getTimes() < 1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_2:translation("DRAGONBOAT_BUY_TIMES_COST"), arg_14_0.dragonBoatModel:getBuyTimesCost()), function()
						print(arg_14_0.selfPlayer.crystal, arg_14_0.dragonBoatModel:getBuyTimesCost())

						if arg_14_0.selfPlayer.crystal < arg_14_0.dragonBoatModel:getBuyTimesCost() then
							local var_16_0 = var_0_2:translation("CRYSTAL_TIP")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_16_0
							})
						else
							arg_14_0.dragonBoatModel:buyTimes(function()
								xyd.WindowManager.get():openWindow("dragon_boat_select_team")
							end)
						end
					end, nil, nil, arg_14_0.colorMode)
				else
					xyd.WindowManager.get():openWindow("dragon_boat_select_team")
				end
			end
		end)
	end

	return arg_14_0.boatingBtn_
end

function var_0_0.updateBoat(arg_18_0)
	local function var_18_0(arg_19_0)
		local var_19_0 = arg_18_0.dragonBoatModel:getRankData(arg_19_0).rank_list

		if not var_19_0[1] then
			return var_18_0((arg_19_0 + 1) % 8)
		end

		return var_19_0[1], arg_19_0
	end

	if not arg_18_0.dragonBoatModel:getRankData(0).rank_list[1] then
		return
	end

	local var_18_1, var_18_2 = var_18_0(arg_18_0.currentShowDay_)

	arg_18_0.currentShowDay_ = var_18_2

	arg_18_0:nodeByName("text_name"):setString(var_18_1.player_name)

	local var_18_3 = xyd.split(var_0_2:translation("DRAGONBOAT_RANK_TIP"), ":")

	arg_18_0:nodeByName("label_rank_no1"):setString(var_18_3[var_18_2 + 1])

	local var_18_4 = arg_18_0:nodeByName("boat")

	var_18_4:removeAllChildren()
	arg_18_0:getBoatResource(var_18_1):addTo(var_18_4):align(display.CENTER_BOTTOM, var_18_4:getWidth() / 2, 0)
	transition.stopTarget(arg_18_0)
	arg_18_0:schedule(function()
		if not arg_18_0 or tolua.isnull(arg_18_0) then
			return
		end

		if xyd.WindowManager.get():isWindowOpen("dragon_boat_select_team") or xyd.WindowManager.get():isWindowOpen("dragon_boat_boating") then
			return
		end

		local var_20_0, var_20_1 = var_18_0(arg_18_0.currentShowDay_ + 1)

		arg_18_0.currentShowDay_ = var_20_1

		arg_18_0:nodeByName("text_name"):setString(var_20_0.player_name)

		local var_20_2 = xyd.split(var_0_2:translation("DRAGONBOAT_RANK_TIP"), ":")

		arg_18_0:nodeByName("label_rank_no1"):setString(var_20_2[var_20_1 + 1])
		var_18_4:removeAllChildren()
		arg_18_0:getBoatResource(var_20_0):addTo(var_18_4):align(display.CENTER_BOTTOM, var_18_4:getWidth() / 2, 0)
	end, 10)
end

function var_0_0.getBoatResource(arg_21_0, arg_21_1)
	local function var_21_0(arg_22_0)
		if tonumber(arg_22_0.is_skin_on) == 1 then
			return tonumber(arg_22_0.skin_id)
		else
			return var_0_3:modelID(arg_22_0.table_id)
		end
	end

	local var_21_1 = display.newNode()

	var_21_1:size(500, 200)

	arg_21_1.boat_id = arg_21_1.boat_id or 1

	local var_21_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1060/boat" .. arg_21_1.boat_id .. ".png")
	local var_21_3 = var_21_1:getWidth()
	local var_21_4 = var_21_1:getHeight()

	var_21_2:addTo(var_21_1):align(display.CENTER_BOTTOM, var_21_3 / 2, 0)

	for iter_21_0, iter_21_1 in ipairs(arg_21_1.partners or {}) do
		local var_21_5 = xyd.HeroAnimation.new(iter_21_1.table_id, var_21_0(iter_21_1), 1, {})

		var_21_5:idle()
		var_21_5:addTo(var_21_1, -1):pos(var_0_4[iter_21_0], var_0_4[4])
	end

	return var_21_1
end

return var_0_0
