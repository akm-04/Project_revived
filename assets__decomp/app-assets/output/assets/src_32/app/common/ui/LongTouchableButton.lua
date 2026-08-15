local var_0_0 = require("framework.scheduler")
local var_0_1 = class("LongTouchableButton", cc.ui.UIPushButton)

var_0_1.LONG_TOUCH_EVENT = "LONG_TOUCH_EVENT"
var_0_1.LONG_TOUCH_INTERVAL = 0.2
var_0_1.LONG_TOUCH_THRESHOLD = 10

function var_0_1.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_1.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setLongTouchEnabled(true)

	arg_1_0.isTouchHold_ = false
	arg_1_0.isLongTouched_ = false
end

function var_0_1.setLongTouchEnabled(arg_2_0, arg_2_1)
	arg_2_0.longTouchEnabled_ = arg_2_1
end

function var_0_1.isLongTouchEnabled(arg_3_0)
	return arg_3_0.longTouchEnabled_
end

function var_0_1.onLongTouch(arg_4_0, arg_4_1)
	arg_4_0:addLongTouchEventListener(arg_4_1)

	return arg_4_0
end

function var_0_1.addLongTouchEventListener(arg_5_0, arg_5_1)
	return arg_5_0:addEventListener(var_0_1.LONG_TOUCH_EVENT, arg_5_1)
end

function var_0_1.onTouch_(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1.name
	local var_6_1 = arg_6_1.x
	local var_6_2 = arg_6_1.y

	if var_6_0 == "began" then
		arg_6_0.touchBeganX = var_6_1
		arg_6_0.touchBeganY = var_6_2

		if not arg_6_0:checkTouchInSprite_(var_6_1, var_6_2) then
			return false
		end

		arg_6_0.fsm_:doEvent("press")
		arg_6_0:dispatchEvent({
			touchInTarget = true,
			name = var_0_1.PRESSED_EVENT,
			x = var_6_1,
			y = var_6_2
		})

		if arg_6_0.longTouchEnabled_ then
			arg_6_0.isTouchHold_ = true
			arg_6_0.isLongTouched_ = false
			arg_6_0.longTouchHandle_ = var_0_0.performWithDelayGlobal(function()
				if arg_6_0.isTouchHold_ then
					arg_6_0.isLongTouched_ = true

					arg_6_0:dispatchEvent({
						touchInTarget = true,
						name = var_0_1.LONG_TOUCH_EVENT,
						x = var_6_1,
						y = var_6_2
					})
				end
			end, var_0_1.LONG_TOUCH_INTERVAL)
		end

		return true
	end

	local var_6_3 = arg_6_0:checkTouchInSprite_(arg_6_0.touchBeganX, arg_6_0.touchBeganY) and arg_6_0:checkTouchInSprite_(var_6_1, var_6_2)

	if var_6_0 == "moved" then
		if var_6_3 and arg_6_0.fsm_:canDoEvent("press") then
			arg_6_0.fsm_:doEvent("press")
			arg_6_0:dispatchEvent({
				touchInTarget = true,
				name = var_0_1.PRESSED_EVENT,
				x = var_6_1,
				y = var_6_2
			})
		elseif not var_6_3 and arg_6_0.fsm_:canDoEvent("release") then
			arg_6_0.fsm_:doEvent("release")
			arg_6_0:dispatchEvent({
				touchInTarget = false,
				name = var_0_1.RELEASE_EVENT,
				x = var_6_1,
				y = var_6_2
			})
		end

		if arg_6_0.longTouchEnabled_ and (math.abs(var_6_1 - arg_6_0.touchBeganX) > var_0_1.LONG_TOUCH_THRESHOLD or math.abs(var_6_2 - arg_6_0.touchBeganY) > var_0_1.LONG_TOUCH_THRESHOLD) then
			arg_6_0.isTouchHold_ = false

			if arg_6_0.longTouchHandle_ then
				var_0_0.unscheduleGlobal(arg_6_0.longTouchHandle_)
			end
		end
	else
		if arg_6_0.fsm_:canDoEvent("release") then
			arg_6_0.fsm_:doEvent("release")
			arg_6_0:dispatchEvent({
				name = var_0_1.RELEASE_EVENT,
				x = var_6_1,
				y = var_6_2,
				touchInTarget = var_6_3
			})
		end

		if var_6_0 == "ended" and var_6_3 then
			arg_6_0:dispatchEvent({
				touchInTarget = true,
				name = var_0_1.CLICKED_EVENT,
				x = var_6_1,
				y = var_6_2
			})
		end

		if arg_6_0.longTouchEnabled_ then
			arg_6_0.isTouchHold_ = false

			if arg_6_0.longTouchHandle_ then
				var_0_0.unscheduleGlobal(arg_6_0.longTouchHandle_)
			end
		end
	end
end

return var_0_1
