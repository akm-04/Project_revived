local var_0_0 = class("DragonboatBoatingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("app.model.Hero")
local var_0_3 = require("framework.scheduler")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.activityDragonBoat
local var_0_6 = {
	MOVE = 2,
	HIGH_SPEED = 3,
	DEFAULT = 0,
	STAY = 1
}
local var_0_7 = {
	LEFT = 0,
	RIGHT = 1
}
local var_0_8 = {
	ATTENTION = 7,
	COMPLETE = 9,
	WHIRL_CAUTION = 8,
	READY = 6,
	HIGH_SPEED = 2,
	SUPER_SPEED = 1,
	START = 5,
	DESTINATION = 4,
	TIME_OUT = 10,
	SPEED_DOWN = 3
}
local var_0_9 = 5400
local var_0_10 = 10000
local var_0_11 = 20

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.team_ = arg_1_2.team or {}
	arg_1_0.boatID_ = arg_1_2.boatID
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dragonBoatModel = xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.movingback1_ = arg_2_0:nodeByName("dragon_boat_back_sea2")
	arg_2_0.movingback2_ = arg_2_0:nodeByName("dragon_boat_back_sea1")
	arg_2_0.count_ = 0
	arg_2_0.speed_ = 0
	arg_2_0.initCount_ = 90
	arg_2_0.leftDistance_ = var_0_10
	arg_2_0.speedIncreaseCountsPerSeconds_ = 0
	arg_2_0.buttonDisable_ = true
	arg_2_0.boatState_ = var_0_6.DEFAULT
	arg_2_0.matchedPlayers_ = {}
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:setupRandomNumbers()
	arg_3_0:layout()
end

function var_0_0.willClose(arg_4_0)
	return
end

function var_0_0.didClose(arg_5_0)
	return
end

function var_0_0.layout(arg_6_0)
	arg_6_0:initData()
	arg_6_0:setupBoat()
	arg_6_0:startBoating()
	arg_6_0:getRightBtn()
	arg_6_0:getLeftBtn()
	arg_6_0:getPauseBtn()
end

function var_0_0.initData(arg_7_0)
	arg_7_0:setupText()
	arg_7_0:switchTextState(var_0_8.READY)

	for iter_7_0 = 1, 3 do
		arg_7_0:nodeByName("sprite_" .. iter_7_0):hide()
	end

	arg_7_0:nodeByName("text_state6"):show()
	arg_7_0:nodeByName("progress_container_left"):hide()
	arg_7_0:nodeByName("progress_container_right"):hide()
	arg_7_0:nodeByName("whirlpool_left"):hide()
	arg_7_0:nodeByName("whirlpool_right"):hide()
	arg_7_0:nodeByName("progress_container_left"):setTouchEnabled(false)
	arg_7_0:nodeByName("progress_container_right"):setTouchEnabled(false)
	arg_7_0:nodeByName("mask_red"):hide()
	arg_7_0:nodeByName("progress_bar_distance"):setPercent(0)
end

function var_0_0.setupText(arg_8_0)
	arg_8_0:nodeByName("label_time"):setString("00:00:00")
	arg_8_0:nodeByName("text_speed"):setString(string.format(var_0_4:translation("DRAGONBOAT_BOATING_SPEED"), arg_8_0.speed_ * 30))
	arg_8_0:nodeByName("text_distance"):setString(string.format(var_0_4:translation("DRAGONBOAT_BOATING_lEFT_DISTANCE"), arg_8_0.leftDistance_))
	arg_8_0:nodeByName("label_caution_left"):setString(var_0_4:translation("DRAGONBOAT_BOATING_WHIRLPOOL_CAUTION"))
	arg_8_0:nodeByName("label_caution_right"):setString(var_0_4:translation("DRAGONBOAT_BOATING_WHIRLPOOL_CAUTION"))
end

function var_0_0.startBoating(arg_9_0)
	if not arg_9_0.handler then
		arg_9_0.handler = var_0_3.scheduleUpdateGlobal(handler(arg_9_0, arg_9_0.loop))
	end
end

function var_0_0.pauseBoating(arg_10_0)
	if arg_10_0.handler ~= nil then
		var_0_3.unscheduleGlobal(arg_10_0.handler)

		arg_10_0.handler = nil
	end

	arg_10_0:resetBoatState()
end

function var_0_0.loop(arg_11_0)
	if not arg_11_0 or tolua.isnull(arg_11_0) then
		if arg_11_0.handler ~= nil then
			var_0_3.unscheduleGlobal(arg_11_0.handler)

			arg_11_0.handler = nil
		end

		return
	end

	if arg_11_0.initCount_ >= 0 then
		arg_11_0:loop_1()
	else
		arg_11_0:loop_2()
	end
end

function var_0_0.loop_1(arg_12_0)
	if arg_12_0.initCount_ < 1 then
		arg_12_0:switchTextState(var_0_8.START, true)
	end

	if arg_12_0.initCount_ % 30 < 1 then
		for iter_12_0 = 1, 3 do
			arg_12_0:nodeByName("sprite_" .. iter_12_0):setVisible(math.ceil(arg_12_0.initCount_ / 30) == iter_12_0)
		end
	end

	arg_12_0.initCount_ = arg_12_0.initCount_ - 1

	if arg_12_0.initCount_ == 0 then
		arg_12_0.startClock_ = os.clock()
		arg_12_0.buttonDisable_ = var_0_5:distance(arg_12_0.boatID_) > 0
		arg_12_0.speed_ = var_0_5:distance(arg_12_0.boatID_) > 0 and var_0_11 or 0
	end
end

function var_0_0.loop_2(arg_13_0)
	arg_13_0.count_ = arg_13_0.count_ + 1

	if arg_13_0.count_ % 15 < 1 then
		arg_13_0:updateBoatstate()
	end

	if arg_13_0.count_ % 30 < 1 then
		arg_13_0.speedIncreaseCountsPerSeconds_ = 0
	end

	arg_13_0:updateWhirlPool()
	arg_13_0:updateMatchPlayers()
	arg_13_0:updateBackground()

	if arg_13_0.count_ >= var_0_9 then
		arg_13_0.notChange_ = nil

		arg_13_0:switchTextState(var_0_8.TIME_OUT)
		arg_13_0:pauseBoating()
		arg_13_0:unComplete(2)

		return
	end

	if arg_13_0.leftDistance_ <= 0 then
		arg_13_0.notChange_ = nil

		arg_13_0:switchTextState(var_0_8.COMPLETE)
		arg_13_0:pauseBoating()
		arg_13_0:complete()

		return
	end

	if var_0_5:distance(arg_13_0.boatID_) > 0 and var_0_10 - arg_13_0.leftDistance_ > var_0_5:distance(arg_13_0.boatID_) and arg_13_0.buttonDisable_ then
		arg_13_0.buttonDisable_ = false
	end

	if arg_13_0.speed_ >= 5 and arg_13_0.speed_ < 10 and (arg_13_0.noStateShow_ or arg_13_0.lastState_ == var_0_8.SUPER_SPEED) then
		arg_13_0:switchTextState(var_0_8.HIGH_SPEED)
	elseif arg_13_0.speed_ >= 10 and (arg_13_0.noStateShow_ or arg_13_0.lastState_ == var_0_8.HIGH_SPEED) then
		arg_13_0:switchTextState(var_0_8.SUPER_SPEED)
	end

	arg_13_0.speed_ = arg_13_0.speed_ - arg_13_0:getSpeedDecrease()
end

function var_0_0.setupBoat(arg_14_0)
	local var_14_0 = arg_14_0:nodeByName("boat_container")

	var_14_0:removeAllChildren()

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.team_) do
		if iter_14_1.dragonModel_ and iter_14_1.dragonModel_:getParent() then
			iter_14_1.dragonModel_:removeSelf()
		end

		iter_14_1.dragonModel_:addTo(var_14_0):pos(arg_14_0:nodeByName("node_" .. iter_14_0):getX(), arg_14_0:nodeByName("node_" .. iter_14_0):getY())
	end

	local var_14_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1060/boat" .. arg_14_0.boatID_ .. ".png")
	local var_14_2 = var_14_0:getWidth()
	local var_14_3 = var_14_0:getHeight()

	var_14_1:addTo(var_14_0):align(display.CENTER_BOTTOM, var_14_2 / 2, 0)

	local var_14_4 = {
		"skeletons/ui_effect/activity_dragonboat/dragonboat_normal.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_normal.atlas",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_move.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_move.atlas",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_accelerate.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_accelerate.atlas"
	}

	var_14_0.effect1_ = var_0_1.new(var_14_4[1], var_14_4[2], 1)

	var_14_0.effect1_:addTo(var_14_0, -1):pos(var_14_0:getWidth() / 2, 30)

	var_14_0.effect2_ = var_0_1.new(var_14_4[3], var_14_4[4], 1.3)

	var_14_0.effect2_:addTo(var_14_0, -1):pos(25, 20)

	var_14_0.effect3_ = var_0_1.new(var_14_4[5], var_14_4[6], 1)

	var_14_0.effect3_:addTo(var_14_0, 1):pos(180, 50)
	var_14_0.effect1_:hide()
	var_14_0.effect2_:hide()
	var_14_0.effect3_:hide()
	var_14_0:scale(0.7)
	arg_14_0:updateBoatstate()
end

function var_0_0.updateBoatstate(arg_15_0)
	local var_15_0 = arg_15_0:nodeByName("boat_container")

	if arg_15_0.speed_ < 1 and arg_15_0.boatState_ ~= var_0_6.STAY then
		var_15_0.effect1_:show()
		var_15_0.effect1_:play(nil, true)
		var_15_0.effect2_:hide()
		var_15_0.effect2_:stop()
		var_15_0.effect3_:hide()
		var_15_0.effect3_:stop()

		arg_15_0.boatState_ = var_0_6.STAY
	elseif arg_15_0.speed_ > 0 and arg_15_0.speed_ < 10 and arg_15_0.boatState_ ~= var_0_6.MOVE then
		var_15_0.effect1_:show()
		var_15_0.effect1_:play(nil, true)
		var_15_0.effect2_:show()
		var_15_0.effect2_:play(nil, true)
		var_15_0.effect3_:hide()
		var_15_0.effect3_:stop()

		arg_15_0.boatState_ = var_0_6.MOVE
	elseif arg_15_0.speed_ >= 10 and arg_15_0.boatState_ ~= var_0_6.HIGH_SPEED then
		var_15_0.effect1_:hide()
		var_15_0.effect1_:stop()
		var_15_0.effect2_:show()
		var_15_0.effect2_:play(nil, true)
		var_15_0.effect3_:show()
		var_15_0.effect3_:play(nil, true)

		arg_15_0.boatState_ = var_0_6.SPEED
	end
end

function var_0_0.resetBoatState(arg_16_0)
	local var_16_0 = arg_16_0:nodeByName("boat_container")

	var_16_0.effect1_:show()
	var_16_0.effect1_:play(nil, true)
	var_16_0.effect2_:hide()
	var_16_0.effect2_:stop()
	var_16_0.effect3_:hide()
	var_16_0.effect3_:stop()

	arg_16_0.boatState_ = var_0_6.STAY
end

function var_0_0.getLeftBtn(arg_17_0)
	if not arg_17_0.leftBtn_ then
		arg_17_0.leftBtn_ = arg_17_0:nodeByName("button_left")

		arg_17_0.leftBtn_:addTouchEventListener(function(arg_18_0, arg_18_1)
			if arg_17_0.buttonDisable_ then
				return
			end

			if arg_18_1 == ccui.TouchEventType.began then
				if arg_17_0:enableBtn(var_0_7.LEFT) then
					arg_17_0:speedUp()
				else
					arg_17_0:speedDown()
				end
			elseif arg_18_1 == ccui.TouchEventType.ended then
				arg_17_0.currentState_ = var_0_7.LEFT
			elseif arg_18_1 == ccui.TouchEventType.canceled then
				arg_17_0.currentState_ = var_0_7.LEFT
			end
		end)
	end
end

function var_0_0.getRightBtn(arg_19_0)
	if not arg_19_0.rightBtn_ then
		arg_19_0.rightBtn_ = arg_19_0:nodeByName("button_right")

		arg_19_0.rightBtn_:addTouchEventListener(function(arg_20_0, arg_20_1)
			if arg_19_0.buttonDisable_ then
				return
			end

			if arg_20_1 == ccui.TouchEventType.began then
				if arg_19_0:enableBtn(var_0_7.RIGHT) then
					arg_19_0:speedUp()
				else
					arg_19_0:speedDown()
				end
			elseif arg_20_1 == ccui.TouchEventType.ended then
				arg_19_0.currentState_ = var_0_7.RIGHT
			elseif arg_20_1 == ccui.TouchEventType.canceled then
				arg_19_0.currentState_ = var_0_7.RIGHT
			end
		end)
	end
end

function var_0_0.enableBtn(arg_21_0, arg_21_1)
	if arg_21_0.whirl_ then
		return arg_21_1 ~= arg_21_0.whirl_
	end

	if not arg_21_0.currentState_ then
		arg_21_0.currentState_ = arg_21_1

		return true
	end

	if arg_21_0.currentState_ == arg_21_1 then
		return flase
	end

	return true
end

function var_0_0.speedUp(arg_22_0)
	if arg_22_0.speedIncreaseCountsPerSeconds_ >= 4 then
		return
	end

	arg_22_0.speed_ = arg_22_0.speed_ + arg_22_0:getSpeedIncrease()
end

function var_0_0.speedDown(arg_23_0)
	local var_23_0 = {
		0.5,
		0.55,
		0.6,
		0.65
	}

	arg_23_0.currentState_ = nil
	arg_23_0.speed_ = arg_23_0.speed_ * var_23_0[arg_23_0.boatID_]

	transition.stopTarget(arg_23_0:nodeByName("mask_red"))
	arg_23_0:switchTextState(var_0_8.SPEED_DOWN, true)
	arg_23_0:nodeByName("mask_red"):show()
	arg_23_0:nodeByName("mask_red"):setOpacity(255)
	arg_23_0:nodeByName("mask_red"):setCascadeOpacityEnabled(true)
	arg_23_0:nodeByName("mask_red"):runActionOnce(cc.FadeOut:create(0.5), false, function()
		if not arg_23_0 or tolua.isnull(arg_23_0) then
			return
		end

		arg_23_0:nodeByName("mask_red"):setOpacity(255)
		arg_23_0:nodeByName("mask_red"):hide()
	end, 0.2)
end

function var_0_0.switchTextState(arg_25_0, arg_25_1, arg_25_2)
	if arg_25_0.notChange_ then
		return
	end

	for iter_25_0 = 1, 10 do
		arg_25_0:nodeByName("text_state" .. iter_25_0):hide()
		transition.stopTarget(arg_25_0:nodeByName("text_state" .. iter_25_0))
	end

	if not arg_25_1 then
		arg_25_0.noStateShow_ = true

		return
	end

	arg_25_0.lastState_ = arg_25_1

	local var_25_0 = arg_25_0:nodeByName("text_state" .. arg_25_1):show()

	var_25_0:setOpacity(255)

	arg_25_0.noStateShow_ = nil

	if arg_25_2 then
		var_25_0:runActionOnce(cc.FadeOut:create(0.4), false, function()
			if not arg_25_0 or tolua.isnull(arg_25_0) then
				return
			end

			var_25_0:setOpacity(255)
			var_25_0:hide()

			arg_25_0.noStateShow_ = true
		end, 1)
	end
end

function var_0_0.setupRandomNumbers(arg_27_0)
	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))
	arg_27_0:setupWhirlPool()
	arg_27_0:setupMatchPlayers()
end

function var_0_0.setupMatchPlayers(arg_28_0)
	arg_28_0.matchPlayers = {}

	for iter_28_0, iter_28_1 in ipairs(arg_28_0.dragonBoatModel:getMatchPlayers()) do
		table.insert(arg_28_0.matchPlayers, iter_28_1)
	end

	if not next(arg_28_0.matchPlayers) then
		return
	end

	local var_28_0 = var_0_10 / (#arg_28_0.matchPlayers + 1)

	arg_28_0.matchPlayers[1].meetPosition_ = var_28_0 / 5 + math.random(math.ceil(1.2 * var_28_0))

	for iter_28_2, iter_28_3 in ipairs(arg_28_0.matchPlayers) do
		arg_28_0.matchPlayers[iter_28_2].meetPosition_ = arg_28_0.matchPlayers[iter_28_2].meetPosition_ or arg_28_0.matchPlayers[iter_28_2 - 1].meetPosition_ + math.random(math.ceil(var_28_0 * 1.5))
		arg_28_0.matchPlayers[iter_28_2].speed_ = var_0_10 / arg_28_0.matchPlayers[iter_28_2].cost_time / 30
	end
end

function var_0_0.setupWhirlPool(arg_29_0)
	arg_29_0.whirlpools = {}

	local function var_29_0(arg_30_0)
		if arg_30_0 == 1 then
			arg_29_0.whirlpools[1] = 60 + math.random(600)
			arg_29_0.whirlpools[2] = 30 + math.random(360)
			arg_29_0.whirlpools[3] = arg_29_0.whirlpools[1] % 2 > 0

			return
		end

		arg_29_0.whirlpools[3 * arg_30_0 - 2] = arg_29_0.whirlpools[3 * arg_30_0 - 5] + arg_29_0.whirlpools[3 * arg_30_0 - 4] + math.random(1000) + 31
		arg_29_0.whirlpools[3 * arg_30_0 - 1] = 30 + math.random(360)
		arg_29_0.whirlpools[3 * arg_30_0 - 0] = arg_29_0.whirlpools[3 * arg_30_0 - 2] % 2 > 0
	end

	for iter_29_0 = 1, 5 do
		var_29_0(iter_29_0)
	end
end

function var_0_0.updateWhirlPool(arg_31_0)
	if not next(arg_31_0.whirlpools) then
		return
	end

	if arg_31_0.count_ == arg_31_0.whirlpools[1] - xyd.tables.misc.dragonBoatWhirlCautionFrames then
		if arg_31_0.whirlpools[3] then
			arg_31_0:nodeByName("progress_container_left"):show()
			arg_31_0:nodeByName("progress_pre_right"):show()
			arg_31_0:nodeByName("progress_pre_right"):setPercent(100)
			arg_31_0:nodeByName("progress_caution_left"):hide()
		else
			arg_31_0:nodeByName("progress_container_right"):show()
			arg_31_0:nodeByName("progress_pre_right"):show()
			arg_31_0:nodeByName("progress_pre_right"):setPercent(100)
			arg_31_0:nodeByName("progress_caution_right"):hide()
		end
	elseif arg_31_0.count_ < arg_31_0.whirlpools[1] and arg_31_0.count_ > arg_31_0.whirlpools[1] - xyd.tables.misc.dragonBoatWhirlCautionFrames then
		local var_31_0 = (arg_31_0.whirlpools[1] - arg_31_0.count_) / xyd.tables.misc.dragonBoatWhirlCautionFrames * 100

		if arg_31_0.whirlpools[3] then
			arg_31_0:nodeByName("progress_pre_left"):show()
			arg_31_0:nodeByName("progress_pre_left"):setPercent(var_31_0)
		else
			arg_31_0:nodeByName("progress_pre_right"):show()
			arg_31_0:nodeByName("progress_pre_right"):setPercent(var_31_0)
		end
	elseif arg_31_0.count_ == arg_31_0.whirlpools[1] then
		arg_31_0:switchTextState(var_0_8.WHIRL_CAUTION, nil)

		arg_31_0.notChange_ = true

		if arg_31_0.whirlpools[3] then
			arg_31_0:nodeByName("whirlpool_left"):show()
			arg_31_0:nodeByName("progress_container_left"):show()
			arg_31_0:nodeByName("progress_caution_left"):show()
			arg_31_0:nodeByName("paddle_left"):hide()
			arg_31_0:nodeByName("progress_pre_left"):hide()
			arg_31_0:nodeByName("progress_caution_left"):setPercent(100)

			arg_31_0.whirl_ = var_0_7.LEFT
		else
			arg_31_0:nodeByName("whirlpool_right"):show()
			arg_31_0:nodeByName("progress_container_right"):show()
			arg_31_0:nodeByName("progress_caution_right"):show()
			arg_31_0:nodeByName("paddle_right"):hide()
			arg_31_0:nodeByName("progress_pre_right"):hide()
			arg_31_0:nodeByName("progress_caution_right"):setPercent(100)

			arg_31_0.whirl_ = var_0_7.RIGHT
		end
	elseif arg_31_0.count_ > arg_31_0.whirlpools[1] and arg_31_0.count_ < arg_31_0.whirlpools[1] + arg_31_0.whirlpools[2] then
		local var_31_1 = (arg_31_0.whirlpools[1] + arg_31_0.whirlpools[2] - arg_31_0.count_) / arg_31_0.whirlpools[2] * 100

		if arg_31_0.whirlpools[3] then
			arg_31_0:nodeByName("progress_caution_left"):setPercent(var_31_1)
		else
			arg_31_0:nodeByName("progress_caution_right"):setPercent(var_31_1)
		end
	elseif arg_31_0.count_ == arg_31_0.whirlpools[1] + arg_31_0.whirlpools[2] then
		if arg_31_0.whirlpools[3] then
			arg_31_0:nodeByName("whirlpool_left"):hide()
			arg_31_0:nodeByName("progress_container_left"):hide()
			arg_31_0:nodeByName("paddle_left"):show()
		else
			arg_31_0:nodeByName("whirlpool_right"):hide()
			arg_31_0:nodeByName("progress_container_right"):hide()
			arg_31_0:nodeByName("paddle_right"):show()
		end

		arg_31_0.whirl_ = nil
		arg_31_0.notChange_ = nil

		if arg_31_0.speed_ >= 5 and arg_31_0.speed_ < 10 then
			arg_31_0:switchTextState(var_0_8.HIGH_SPEED)
		elseif arg_31_0.speed_ >= 10 then
			arg_31_0:switchTextState(var_0_8.SUPER_SPEED)
		else
			arg_31_0:switchTextState()
		end

		for iter_31_0 = 1, 3 do
			table.remove(arg_31_0.whirlpools, 1)
		end
	end
end

function var_0_0.updateMatchPlayers(arg_32_0)
	for iter_32_0, iter_32_1 in ipairs(arg_32_0.matchedPlayers_) do
		iter_32_1.boatSp_:x(iter_32_1.boatSp_:getX() + iter_32_1.speed_ - arg_32_0.speed_)
	end

	if not next(arg_32_0.matchPlayers) then
		return
	end

	if var_0_10 - arg_32_0.leftDistance_ >= arg_32_0.matchPlayers[1].meetPosition_ then
		local var_32_0 = table.remove(arg_32_0.matchPlayers, 1)

		table.insert(arg_32_0.matchedPlayers_, var_32_0)

		local var_32_1 = 80 + math.random(160)
		local var_32_2 = 0.35 + (240 - var_32_1) / 160 * 0.15

		var_32_0.boatSp_:scale(var_32_2)
		var_32_0.boatSp_:addTo(arg_32_0:nodeByName("match_player_container"), 240 - var_32_1)

		if var_32_0.speed_ > arg_32_0.speed_ then
			var_32_0.boatSp_:pos(-var_32_0.boatSp_:getWidth() / 2, var_32_1)
		else
			var_32_0.boatSp_:pos(var_32_0.boatSp_:getWidth() / 2 + xyd.STAGE_WIDTH, var_32_1)
		end

		if var_32_0.speed_ < 10 then
			var_32_0.boatSp_.effect1_:show()
			var_32_0.boatSp_.effect1_:play(nil, true)
			var_32_0.boatSp_.effect2_:show()
			var_32_0.boatSp_.effect2_:play(nil, true)
			var_32_0.boatSp_.effect3_:hide()
			var_32_0.boatSp_.effect3_:stop()
		elseif var_32_0.speed_ >= 10 then
			var_32_0.boatSp_.effect1_:hide()
			var_32_0.boatSp_.effect1_:stop()
			var_32_0.boatSp_.effect2_:show()
			var_32_0.boatSp_.effect2_:play(nil, true)
			var_32_0.boatSp_.effect3_:show()
			var_32_0.boatSp_.effect3_:play(nil, true)
		end
	end
end

function var_0_0.updateBackground(arg_33_0)
	arg_33_0:nodeByName("label_time"):setString(arg_33_0:getClock())

	arg_33_0.leftDistance_ = arg_33_0.leftDistance_ - arg_33_0.speed_

	arg_33_0:nodeByName("text_speed"):setString(string.format(var_0_4:translation("DRAGONBOAT_BOATING_SPEED"), arg_33_0.speed_ * 30))

	if arg_33_0.count_ % 30 < 1 or arg_33_0.leftDistance_ <= 0 then
		arg_33_0:nodeByName("text_distance"):setString(string.format(var_0_4:translation("DRAGONBOAT_BOATING_lEFT_DISTANCE"), math.max(arg_33_0.leftDistance_, 0)))
	end

	if arg_33_0.speed_ <= 0 then
		return
	end

	arg_33_0.movingback1_:x(arg_33_0.movingback1_:getX() - arg_33_0.speed_ * 3)
	arg_33_0.movingback2_:x(arg_33_0.movingback2_:getX() - arg_33_0.speed_ * 3)

	if arg_33_0.movingback1_:getX() < -1280 then
		arg_33_0.movingback1_:x(arg_33_0.movingback2_:getX() + 1280)
	end

	if arg_33_0.movingback2_:getX() < -1280 then
		arg_33_0.movingback2_:x(arg_33_0.movingback1_:getX() + 1280)
	end

	arg_33_0:nodeByName("progress_bar_distance"):setPercent(100 - arg_33_0.leftDistance_ / 100)
end

function var_0_0.getClock(arg_34_0)
	local var_34_0 = arg_34_0.count_ / 30
	local var_34_1 = math.floor(var_34_0)
	local var_34_2 = math.floor(var_34_1 / 60)
	local var_34_3 = var_34_1 % 60
	local var_34_4 = math.floor((var_34_0 - var_34_1) * 100)

	return (string.format("%02d'%02d\"%02d", var_34_2, var_34_3, var_34_4))
end

function var_0_0.complete(arg_35_0, arg_35_1)
	arg_35_0.ended_ = true

	local var_35_0 = math.ceil(arg_35_0.count_ / 30 * 100) / 100

	arg_35_0.dragonBoatModel.costTime_ = var_35_0

	local var_35_1 = {}

	for iter_35_0, iter_35_1 in ipairs(arg_35_0.team_) do
		table.insert(var_35_1, iter_35_1:getHeroID())
	end

	local var_35_2 = table.concat(var_35_1, "|")

	arg_35_0.dragonBoatModel:endBoating({
		cost_time = var_35_0,
		partners = var_35_2,
		boat_id = arg_35_0.boatID_,
		distance = var_0_10,
		start_speed = var_0_11
	}, function(arg_36_0)
		local var_36_0 = arg_36_0

		arg_35_0:performWithDelay(function()
			if not arg_35_0 or tolua.isnull(arg_35_0) then
				return
			end

			arg_35_0:showResult(var_36_0)
		end, 1)
	end)
end

function var_0_0.unComplete(arg_38_0, arg_38_1)
	arg_38_0.ended_ = true

	local var_38_0 = {}

	for iter_38_0, iter_38_1 in ipairs(arg_38_0.team_) do
		table.insert(var_38_0, iter_38_1:getHeroID())
	end

	local var_38_1 = table.concat(var_38_0, "|")

	arg_38_0.dragonBoatModel:endBoating({
		cost_time = -1,
		partners = var_38_1,
		boat_id = arg_38_0.boatID_,
		distance = var_0_10,
		start_speed = var_0_11
	}, function()
		if not arg_38_1 then
			xyd.WindowManager.get():closeWindow(arg_38_0)

			return
		end

		arg_38_0:performWithDelay(function()
			if not arg_38_0 or tolua.isnull(arg_38_0) then
				return
			end

			xyd.WindowManager.get():closeWindow(arg_38_0)
		end, arg_38_1)
	end)
end

function var_0_0.getPauseBtn(arg_41_0)
	if not arg_41_0.pauseBtn_ then
		arg_41_0.pauseBtn_ = arg_41_0:nodeByName("button_pause")

		arg_41_0.pauseBtn_:addTouchEventListener(function(arg_42_0, arg_42_1)
			if arg_42_1 == ccui.TouchEventType.ended then
				if arg_41_0.ended_ then
					return
				end

				arg_41_0:pauseBoating()

				local var_42_0 = xyd.WindowManager.get():openWindow("dragon_boat_paused")

				cc.EventProxy.new(var_42_0, var_42_0):addEventListener(xyd.event.BATTLE_RESUMED, function()
					arg_41_0:startBoating()
				end):addEventListener(xyd.event.EXIT_BATTLE, function()
					arg_41_0:unComplete()
				end)
			end
		end)
	end

	return arg_41_0.pauseBtn_
end

function var_0_0.getSpeedIncrease(arg_45_0)
	if arg_45_0.speed_ > 15 then
		return 0.1
	else
		return (10 - 0.5 * arg_45_0.speed_) / (10 + 0.5 * arg_45_0.speed_) * 2
	end
end

function var_0_0.getSpeedDecrease(arg_46_0, arg_46_1)
	if arg_46_0.buttonDisable_ then
		return 0
	end

	local var_46_0 = arg_46_0.boatID_

	if var_46_0 == 4 then
		if arg_46_0.speed_ > 15.555 then
			return arg_46_0.speed_ / 53
		elseif arg_46_0.speed_ > 13 then
			return arg_46_0.speed_ / 85
		elseif arg_46_0.speed_ > 12 then
			return arg_46_0.speed_ / 100
		elseif arg_46_0.speed_ > 10 then
			return arg_46_0.speed_ / 200
		elseif arg_46_0.speed_ > 5 then
			return arg_46_0.speed_ / 250
		end

		return arg_46_0.speed_ / 1000
	end

	if var_46_0 == 3 then
		if arg_46_0.speed_ > 13 then
			return arg_46_0.speed_ / 42
		elseif arg_46_0.speed_ > 12 then
			return arg_46_0.speed_ / 70
		elseif arg_46_0.speed_ > 11 then
			return arg_46_0.speed_ / 80
		elseif arg_46_0.speed_ > 10 then
			return arg_46_0.speed_ / 110
		elseif arg_46_0.speed_ > 5 then
			return arg_46_0.speed_ / 250
		end

		return arg_46_0.speed_ / 1000
	end

	if var_46_0 == 2 then
		if arg_46_0.speed_ > 11 then
			return arg_46_0.speed_ / 30
		elseif arg_46_0.speed_ > 10 then
			return arg_46_0.speed_ / 65
		elseif arg_46_0.speed_ > 9 then
			return arg_46_0.speed_ / 100
		elseif arg_46_0.speed_ > 7 then
			return arg_46_0.speed_ / 120
		elseif arg_46_0.speed_ > 3 then
			return arg_46_0.speed_ / 250
		end

		return arg_46_0.speed_ / 1000
	end

	if var_46_0 == 1 then
		if arg_46_0.speed_ > 11 then
			return arg_46_0.speed_ / 20
		elseif arg_46_0.speed_ > 10 then
			return arg_46_0.speed_ / 30
		elseif arg_46_0.speed_ > 8 then
			return arg_46_0.speed_ / 50
		elseif arg_46_0.speed_ > 5 then
			return arg_46_0.speed_ / 120
		elseif arg_46_0.speed_ > 3 then
			return arg_46_0.speed_ / 250
		end

		return arg_46_0.speed_ / 1000
	end
end

function var_0_0.showResult(arg_47_0, arg_47_1)
	local var_47_0 = {
		match_players = arg_47_0.dragonBoatModel:getMatchPlayers(),
		awards = arg_47_1.award,
		rank = arg_47_1.current_rank,
		cost_time = arg_47_0.dragonBoatModel:getCostTime(),
		pre_cost_time = arg_47_1.pre_cost_time,
		last_rank = arg_47_1.last_rank
	}

	xyd.WindowManager.get():openWindow("dragon_boat_result", var_47_0)
end

function var_0_0.willClose(arg_48_0)
	if arg_48_0.handler ~= nil then
		var_0_3.unscheduleGlobal(arg_48_0.handler)

		arg_48_0.handler = nil
	end
end

return var_0_0
