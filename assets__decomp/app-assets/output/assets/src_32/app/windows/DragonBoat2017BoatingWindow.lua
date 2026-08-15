local var_0_0 = class("Dragonboat2017BoatingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("app.model.Hero")
local var_0_3 = require("framework.scheduler")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.activityDragonBoat
local var_0_6 = {
	TypeB = 2,
	TypeA = 1
}
local var_0_7 = {
	Whirl = 2,
	Click = 1
}
local var_0_8 = {
	Default = 0,
	HighSpeed = 3,
	Move = 2,
	Stay = 1
}
local var_0_9 = {
	Lose = 4,
	End = 5,
	Succeed = 3,
	Ready = 6,
	Wave = 2,
	Click = 0,
	Whirl = 1,
	Start = 7
}
local var_0_10 = 7
local var_0_11 = 30
local var_0_12 = "skeletons/ui_effect/dragon_boat2/dragonboat2_event1"
local var_0_13 = "skeletons/ui_effect/dragon_boat2/dragonboat2_event2"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dragonBoatModel = xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT2017)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.team_ = arg_1_0.dragonBoatModel:getTeams()
	arg_1_0.boatID_ = arg_1_0.dragonBoatModel:getBoatID()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.movingback1_ = arg_2_0:nodeByName("dragon_boat_back_sea2")
	arg_2_0.movingback2_ = arg_2_0:nodeByName("dragon_boat_back_sea1")
	arg_2_0.initCount_ = 120
	arg_2_0.count_ = 0
	arg_2_0.speed_ = 4
	arg_2_0.boatState_ = var_0_8.Default
	arg_2_0.currentEvent = 1
	arg_2_0.clickTimes = 0
	arg_2_0.isSucceed = true
	arg_2_0.events = arg_2_0:generateEvents()
	arg_2_0.succeedTimes = 0
end

function var_0_0.generateEvents(arg_3_0)
	local var_3_0 = {}
	local var_3_1 = {
		is_succeed = false,
		event_type = var_0_6.TypeA,
		sub_event = {
			var_0_7.Click,
			math.random(1, 2),
			math.random(1, 2)
		}
	}

	table.insert(var_3_0, var_3_1)

	for iter_3_0 = 2, xyd.tables.misc.dragonboat2Wave do
		table.insert(var_3_0, arg_3_0:generateEvent())
	end

	return var_3_0
end

function var_0_0.generateEvent(arg_4_0)
	local var_4_0 = {}
	local var_4_1 = math.random(1, 2)

	if var_4_1 == var_0_6.TypeA then
		var_4_0 = {
			is_succeed = false,
			event_type = var_4_1,
			sub_event = {
				arg_4_0:generateSubEvent(),
				arg_4_0:generateSubEvent(),
				arg_4_0:generateSubEvent()
			}
		}
	else
		var_4_0 = {
			is_succeed = false,
			event_type = var_4_1
		}
	end

	return var_4_0
end

function var_0_0.generateSubEvent(arg_5_0)
	if math.random() < 0.75 then
		return var_0_7.Click
	else
		return var_0_7.Whirl
	end
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:setupRandomNumbers()
	arg_6_0:layout()
end

function var_0_0.setupRandomNumbers(arg_7_0)
	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))
end

function var_0_0.layout(arg_8_0)
	arg_8_0:setupProgressFragment()
	arg_8_0:updateProgress()
	arg_8_0:initData()
	arg_8_0:setButtonClick()
	arg_8_0:setupBoat()
	arg_8_0:startBoating()
	arg_8_0:nodeByName("button_pause"):setVisible(false)
end

function var_0_0.setupProgressFragment(arg_9_0)
	local var_9_0 = "windows/activities/1104/boating/icon_fragment.png"
	local var_9_1 = arg_9_0:nodeByName("progress_bar_distance"):getContentSize().height / 2
	local var_9_2 = arg_9_0:nodeByName("progress_bar_distance"):getContentSize().width / xyd.tables.misc.dragonboat2Wave

	for iter_9_0 = 1, xyd.tables.misc.dragonboat2Wave - 1 do
		local var_9_3 = xyd.AssetLoader.get():loadSprite(var_9_0)

		var_9_3:addTo(arg_9_0:nodeByName("progress_bar_distance"))
		var_9_3:setPosition(cc.p(var_9_2 * iter_9_0, var_9_1))
	end
end

function var_0_0.updateProgress(arg_10_0)
	if arg_10_0.count_ % (var_0_11 / 10) == 0 then
		arg_10_0:nodeByName("progress_txt"):setString(string.format("%.1f", arg_10_0.count_ / var_0_11 / xyd.tables.misc.dragonboat2Wave / 5 * 100) .. "%")
		arg_10_0:nodeByName("pass_txt"):setString(tostring(arg_10_0.succeedTimes) .. "/" .. xyd.tables.misc.dragonboat2Wave)
		arg_10_0:nodeByName("progress_bar_distance"):setPercent(arg_10_0.count_ / var_0_11 / xyd.tables.misc.dragonboat2Wave / 5 * 100)
	end
end

function var_0_0.initData(arg_11_0)
	arg_11_0:nodeByName("mask_red"):hide()
	arg_11_0:nodeByName("progress_bar_distance"):setPercent(0)
	arg_11_0:switchTextState(var_0_9.Ready)

	for iter_11_0 = 1, 3 do
		arg_11_0:nodeByName("sprite" .. iter_11_0):hide()
	end
end

function var_0_0.setButtonClick(arg_12_0)
	arg_12_0:nodeByName("paddle_btn"):setVisible(false)
	arg_12_0:nodeByName("whirl_btn"):setVisible(false)
	arg_12_0:nodeByName("click_btn"):setVisible(false)
	arg_12_0:nodeByName("paddle_tip_txt"):setString(var_0_4:translation("PADDLE_TIP_TEXT"))
	arg_12_0:nodeByName("paddle_tip_txt"):enableOutline(xyd.color.BLUE, 1)
	arg_12_0:nodeByName("paddle_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			arg_12_0.clickTimes = arg_12_0.clickTimes + 1
		end
	end)
	arg_12_0:nodeByName("whirl_tip_txt"):setString(var_0_4:translation("WHIRL_TIP_TEXT"))
	arg_12_0:nodeByName("whirl_tip_txt"):enableOutline(xyd.color.BLUE, 1)
	arg_12_0:nodeByName("whirl_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.began then
			arg_12_0.clickTimes = arg_12_0.clickTimes + 1
		elseif arg_14_1 == ccui.TouchEventType.ended then
			-- block empty
		elseif arg_14_1 == ccui.TouchEventType.canceled then
			-- block empty
		end
	end)
	arg_12_0:nodeByName("click_tip_txt"):setString(var_0_4:translation("CLICK_TIP_TEXT"))
	arg_12_0:nodeByName("click_tip_txt"):enableOutline(xyd.color.BLUE, 1)
	arg_12_0:nodeByName("click_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			arg_12_0.clickTimes = arg_12_0.clickTimes + 1
		end
	end)
end

function var_0_0.startBoating(arg_16_0)
	if not arg_16_0.handler then
		arg_16_0.handler = var_0_3.scheduleUpdateGlobal(handler(arg_16_0, arg_16_0.loop))
	end
end

function var_0_0.loop(arg_17_0)
	if not arg_17_0 or tolua.isnull(arg_17_0) then
		if arg_17_0.handler ~= nil then
			var_0_3.unscheduleGlobal(arg_17_0.handler)

			arg_17_0.handler = nil
		end

		return
	end

	if arg_17_0.initCount_ >= 0 then
		arg_17_0:loop_1()
	else
		arg_17_0:loop_2()
	end
end

function var_0_0.loop_1(arg_18_0)
	if arg_18_0.initCount_ < 30 then
		arg_18_0:switchTextState(var_0_9.Start, true)
	end

	if arg_18_0.initCount_ % 30 < 1 then
		for iter_18_0 = 1, 3 do
			arg_18_0:nodeByName("sprite" .. iter_18_0):setVisible(math.ceil(arg_18_0.initCount_ / 30) - 1 == iter_18_0)
		end
	end

	arg_18_0.initCount_ = arg_18_0.initCount_ - 1
end

function var_0_0.loop_2(arg_19_0)
	if not arg_19_0 or tolua.isnull(arg_19_0) then
		if arg_19_0.handler ~= nil then
			var_0_3.unscheduleGlobal(arg_19_0.handler)

			arg_19_0.handler = nil
		end

		return
	end

	arg_19_0.count_ = arg_19_0.count_ + 1

	arg_19_0:updateProgress()
	arg_19_0:updateEvent()
	arg_19_0:updateBackground()

	if arg_19_0.count_ >= 5 * var_0_11 * xyd.tables.misc.dragonboat2Wave then
		arg_19_0.notChange_ = nil

		arg_19_0:pauseBoating()
		arg_19_0:complete()

		return
	end
end

function var_0_0.pauseBoating(arg_20_0)
	if arg_20_0.handler ~= nil then
		var_0_3.unscheduleGlobal(arg_20_0.handler)

		arg_20_0.handler = nil
	end

	arg_20_0:resetBoatState()
end

function var_0_0.updateEvent(arg_21_0)
	local var_21_0 = math.ceil(arg_21_0.count_ / (var_0_11 * 5))

	event = arg_21_0.events[var_21_0]

	local var_21_1 = arg_21_0.count_ % (var_0_11 * 5)

	if event and event.event_type == var_0_6.TypeA and (var_21_1 == 1 or var_21_1 == var_0_11 + 1 or var_21_1 == var_0_11 * 2 + 1 or var_21_1 == var_0_11 * 3 + 1) then
		if var_21_1 == 1 then
			arg_21_0.isSucceed = true
		elseif event.sub_event[math.ceil(var_21_1 / var_0_11) - 1] == var_0_7.Click and arg_21_0.clickTimes == 0 then
			arg_21_0.isSucceed = false
		elseif event.sub_event[math.ceil(var_21_1 / var_0_11) - 1] == var_0_7.Whirl and arg_21_0.clickTimes > 0 then
			arg_21_0.isSucceed = false
		end

		arg_21_0:showSubEvent(event.sub_event[math.ceil(var_21_1 / var_0_11)])
	end

	if event and event.event_type == var_0_6.TypeB then
		arg_21_0:nodeByName("paddle_btn"):setVisible(false)
		arg_21_0:nodeByName("whirl_btn"):setVisible(false)

		if var_21_1 == 1 then
			arg_21_0:switchTextState(var_0_9.Wave)

			arg_21_0.clickTimes = 0
			arg_21_0.boatState_ = var_0_8.HighSpeed

			arg_21_0:updateBoatstate()
			arg_21_0:nodeByName("click_btn"):setVisible(true)
			arg_21_0:nodeByName("click_btn"):setPosition(arg_21_0:generateRandomPosition())
			arg_21_0:nodeByName("circle"):setScale(6)
			arg_21_0:nodeByName("circle"):runActionOnce(cc.ScaleTo:create(3, 1.5))
		elseif var_21_1 == var_0_11 * 3 + 1 then
			arg_21_0.boatState_ = var_0_8.Move

			arg_21_0:updateBoatstate()
			arg_21_0:nodeByName("click_btn"):setVisible(false)

			if arg_21_0.clickTimes < 10 then
				arg_21_0:showEventResult(false)
			else
				arg_21_0:showEventResult(true)
			end
		end
	end
end

function var_0_0.showSubEvent(arg_22_0, arg_22_1)
	arg_22_0:nodeByName("paddle_btn"):setVisible(false)
	arg_22_0:nodeByName("whirl_btn"):setVisible(false)
	arg_22_0:nodeByName("click_btn"):setVisible(false)

	if not arg_22_1 then
		arg_22_0:showEventResult(arg_22_0.isSucceed)

		return
	end

	arg_22_0.boatState_ = var_0_8.Move

	arg_22_0:updateBoatstate()

	if arg_22_1 == var_0_7.Click then
		arg_22_0:switchTextState(var_0_9.Click)
		arg_22_0:nodeByName("paddle_btn"):setVisible(true)
		arg_22_0:nodeByName("paddle_btn"):setPosition(arg_22_0:generateRandomPosition())

		arg_22_0.clickTimes = 0
	elseif arg_22_1 == var_0_7.Whirl then
		arg_22_0:switchTextState(var_0_9.Whirl)
		arg_22_0:nodeByName("whirl_btn"):setVisible(true)
		arg_22_0:nodeByName("whirl_btn"):setPosition(arg_22_0:generateRandomPosition())

		arg_22_0.clickTimes = 0
	end
end

function var_0_0.playWaveEffect(arg_23_0)
	if not arg_23_0.waveEffect then
		local var_23_0 = var_0_12 .. ".json"
		local var_23_1 = var_0_12 .. ".atlas"

		arg_23_0.waveEffect = var_0_1.new(var_23_0, var_23_1, 1)

		arg_23_0.waveEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_23_0.waveEffect:addTo(arg_23_0:nodeByName("container"))
		arg_23_0.waveEffect:setName("wave_effect")
		arg_23_0.waveEffect:play(nil, true)
	end

	arg_23_0.waveEffect:setPosition(cc.p(1880, 360))
	arg_23_0.waveEffect:runActionOnce(cc.MoveTo:create(2, cc.p(-500, 360)))
end

function var_0_0.playWhirlEffect(arg_24_0)
	if not arg_24_0.whirlEffect then
		local var_24_0 = var_0_13 .. ".json"
		local var_24_1 = var_0_13 .. ".atlas"

		arg_24_0.whirlEffect = var_0_1.new(var_24_0, var_24_1, 1)

		arg_24_0.whirlEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_24_0.whirlEffect:addTo(arg_24_0:nodeByName("whirl_effect_pos"))
		arg_24_0.whirlEffect:setLocalZOrder(-1)
		arg_24_0.whirlEffect:setName("whirl_effect")
		arg_24_0.whirlEffect:play(nil, true)
	end

	arg_24_0.whirlEffect:setPosition(cc.p(1580, 100))
	arg_24_0.whirlEffect:runActionOnce(cc.MoveTo:create(2, cc.p(-300, 100)))
end

function var_0_0.generateRandomPosition(arg_25_0)
	return cc.p(math.random(150, 1130), math.random(60, 400))
end

function var_0_0.showEventResult(arg_26_0, arg_26_1)
	if arg_26_1 then
		arg_26_0:switchTextState(var_0_9.Succeed)

		arg_26_0.succeedTimes = arg_26_0.succeedTimes + 1
	else
		arg_26_0:switchTextState(var_0_9.Lose)
		arg_26_0:performWithDelay(function()
			if not arg_26_0 or tolua.isnull(arg_26_0) then
				return
			end

			xyd.playSceneShaking(1, 1)
			arg_26_0:handleMaskRed()
		end, 1)
	end

	local var_26_0 = math.ceil(arg_26_0.count_ / (var_0_11 * 5))

	event = arg_26_0.events[var_26_0]

	if not event then
		return
	end

	eventType = event.event_type

	if eventType == var_0_6.TypeA then
		arg_26_0:playWhirlEffect()
	elseif eventType == var_0_6.TypeB then
		arg_26_0:playWaveEffect()
	end
end

function var_0_0.handleMaskRed(arg_28_0)
	transition.stopTarget(arg_28_0:nodeByName("mask_red"))
	arg_28_0:nodeByName("mask_red"):show()
	arg_28_0:nodeByName("mask_red"):setOpacity(255)
	arg_28_0:nodeByName("mask_red"):setCascadeOpacityEnabled(true)
	arg_28_0:nodeByName("mask_red"):runActionOnce(cc.FadeOut:create(0.5), false, function()
		if not arg_28_0 or tolua.isnull(arg_28_0) then
			return
		end

		arg_28_0:nodeByName("mask_red"):setOpacity(255)
		arg_28_0:nodeByName("mask_red"):hide()
	end, 0.5)
end

function var_0_0.setupBoat(arg_30_0)
	local var_30_0 = arg_30_0:nodeByName("boat_container")

	var_30_0:removeAllChildren()

	for iter_30_0, iter_30_1 in ipairs(arg_30_0.team_) do
		if iter_30_1.dragonModel_ and iter_30_1.dragonModel_:getParent() then
			iter_30_1.dragonModel_:removeSelf()
		end

		iter_30_1.dragonModel_:addTo(var_30_0):pos(400 - (iter_30_0 - 1) * 90, 68)
		iter_30_1.dragonModel_:setScale(0.7)
	end

	local var_30_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1104/boat" .. arg_30_0.boatID_ .. ".png")
	local var_30_2 = var_30_0:getWidth()
	local var_30_3 = var_30_0:getHeight()

	var_30_1:addTo(var_30_0):align(display.CENTER_BOTTOM, var_30_2 / 2, 0)

	local var_30_4 = {
		"skeletons/ui_effect/activity_dragonboat/dragonboat_normal.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_normal.atlas",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_move.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_move.atlas",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_accelerate.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_accelerate.atlas"
	}

	var_30_0.effect1_ = var_0_1.new(var_30_4[1], var_30_4[2], 1)

	var_30_0.effect1_:addTo(var_30_0, -1):pos(var_30_0:getWidth() / 2, 30)

	var_30_0.effect2_ = var_0_1.new(var_30_4[3], var_30_4[4], 1.3)

	var_30_0.effect2_:addTo(var_30_0, -1):pos(25, 20)

	var_30_0.effect3_ = var_0_1.new(var_30_4[5], var_30_4[6], 1)

	var_30_0.effect3_:addTo(var_30_0, 1):pos(180, 50)
	var_30_0.effect1_:hide()
	var_30_0.effect2_:hide()
	var_30_0.effect3_:hide()
	var_30_0:scale(0.7)
	arg_30_0:updateBoatstate()
end

function var_0_0.updateBoatstate(arg_31_0)
	local var_31_0 = arg_31_0:nodeByName("boat_container")

	if arg_31_0.boatState_ == var_0_8.Stay or arg_31_0.boatState_ == var_0_8.Default then
		var_31_0.effect1_:show()
		var_31_0.effect1_:play(nil, true)
		var_31_0.effect2_:hide()
		var_31_0.effect2_:stop()
		var_31_0.effect3_:hide()
		var_31_0.effect3_:stop()
	elseif arg_31_0.boatState_ == var_0_8.Move then
		var_31_0.effect1_:show()
		var_31_0.effect1_:play(nil, true)
		var_31_0.effect2_:show()
		var_31_0.effect2_:play(nil, true)
		var_31_0.effect3_:hide()
		var_31_0.effect3_:stop()
	elseif arg_31_0.boatState_ == var_0_8.HighSpeed then
		var_31_0.effect1_:hide()
		var_31_0.effect1_:stop()
		var_31_0.effect2_:show()
		var_31_0.effect2_:play(nil, true)
		var_31_0.effect3_:show()
		var_31_0.effect3_:play(nil, true)
	end
end

function var_0_0.resetBoatState(arg_32_0)
	local var_32_0 = arg_32_0:nodeByName("boat_container")

	var_32_0.effect1_:show()
	var_32_0.effect1_:play(nil, true)
	var_32_0.effect2_:hide()
	var_32_0.effect2_:stop()
	var_32_0.effect3_:hide()
	var_32_0.effect3_:stop()

	arg_32_0.boatState_ = var_0_8.Stay
end

function var_0_0.switchTextState(arg_33_0, arg_33_1, arg_33_2)
	if arg_33_0.notChange_ then
		return
	end

	for iter_33_0 = 1, var_0_10 do
		arg_33_0:nodeByName("state_text" .. iter_33_0):hide()
		transition.stopTarget(arg_33_0:nodeByName("state_text" .. iter_33_0))
	end

	if arg_33_1 == var_0_9.Click then
		return
	end

	if not arg_33_1 then
		arg_33_0.noStateShow_ = true

		return
	end

	arg_33_0.lastState_ = arg_33_1

	local var_33_0 = arg_33_0:nodeByName("state_text" .. arg_33_1):show()

	var_33_0:setOpacity(255)

	arg_33_0.noStateShow_ = nil

	if arg_33_2 then
		var_33_0:runActionOnce(cc.FadeOut:create(0.4), false, function()
			if not arg_33_0 or tolua.isnull(arg_33_0) then
				return
			end

			var_33_0:setOpacity(255)
			var_33_0:hide()

			arg_33_0.noStateShow_ = true
		end, 1)
	end
end

function var_0_0.updateBackground(arg_35_0)
	arg_35_0.movingback1_:x(arg_35_0.movingback1_:getX() - arg_35_0.speed_ * 3)
	arg_35_0.movingback2_:x(arg_35_0.movingback2_:getX() - arg_35_0.speed_ * 3)

	if arg_35_0.movingback1_:getX() < -1280 then
		arg_35_0.movingback1_:x(arg_35_0.movingback2_:getX() + 1280)
	end

	if arg_35_0.movingback2_:getX() < -1280 then
		arg_35_0.movingback2_:x(arg_35_0.movingback1_:getX() + 1280)
	end
end

function var_0_0.complete(arg_36_0, arg_36_1)
	arg_36_0.ended_ = true

	arg_36_0:switchTextState(var_0_9.End)
	arg_36_0.activitiesModel:getActivityReward(xyd.Activities.DragonBoat2017, arg_36_0.succeedTimes, function(arg_37_0, arg_37_1)
		if arg_37_0 == xyd.error.OK then
			local var_37_0 = arg_37_1

			arg_36_0:performWithDelay(function()
				if not arg_36_0 or tolua.isnull(arg_36_0) then
					return
				end

				arg_36_0:showResult(var_37_0)
			end, 3)
		end
	end)
end

function var_0_0.showResult(arg_39_0, arg_39_1)
	arg_39_0.selfPlayer:handleRewards(arg_39_1.awards, function()
		xyd.WindowManager.get():closeWindow(arg_39_0)
	end)
end

function var_0_0.willClose(arg_41_0)
	if arg_41_0.handler ~= nil then
		var_0_3.unscheduleGlobal(arg_41_0.handler)

		arg_41_0.handler = nil
	end
end

return var_0_0
