local var_0_0 = require("framework.scheduler")
local var_0_1 = class("MultiFuncButton", cc.ui.UIPushButton)

var_0_1.LONG_TOUCH_EVENT = "LONG_TOUCH_EVENT"
var_0_1.LONG_TOUCH_INTERVAL = 0.2
var_0_1.LONG_TOUCH_THRESHOLD = 10
var_0_1.CLICKED_EVENT = "CLICKED_EVENT"
var_0_1.PRESSED_EVENT = "PRESSED_EVENT"
var_0_1.RELEASE_EVENT = "RELEASE_EVENT"
var_0_1.TOUCH_END_EVENT = "TOUCH_END_EVENT"

function var_0_1.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_1.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setLongTouchEnabled(true)

	arg_1_0.isTouchHold_ = false
	arg_1_0.isLongTouched_ = false
	arg_1_0.isLongTouchRepeat_ = false
end

function var_0_1.setLongTouchRepeat(arg_2_0, arg_2_1)
	arg_2_0.isLongTouchRepeat_ = arg_2_1
end

function var_0_1.setLongTouchEnabled(arg_3_0, arg_3_1)
	arg_3_0.longTouchEnabled_ = arg_3_1
end

function var_0_1.isLongTouchEnabled(arg_4_0)
	return arg_4_0.longTouchEnabled_
end

function var_0_1.onLongTouch(arg_5_0, arg_5_1)
	arg_5_0:addLongTouchEventListener(arg_5_1)

	return arg_5_0
end

function var_0_1.addLongTouchEventListener(arg_6_0, arg_6_1)
	return arg_6_0:addEventListener(var_0_1.LONG_TOUCH_EVENT, arg_6_1)
end

function var_0_1.onClick(arg_7_0, arg_7_1)
	arg_7_0:addClickEventListener(arg_7_1)

	return arg_7_0
end

function var_0_1.addClickEventListener(arg_8_0, arg_8_1)
	return arg_8_0:addEventListener(var_0_1.CLICKED_EVENT, arg_8_1)
end

function var_0_1.onTouchEnd(arg_9_0, arg_9_1)
	arg_9_0:addTouchEndEventListener(arg_9_1)

	return arg_9_0
end

function var_0_1.addTouchEndEventListener(arg_10_0, arg_10_1)
	return arg_10_0:addEventListener(var_0_1.TOUCH_END_EVENT, arg_10_1)
end

function var_0_1.onTouch_(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1.name
	local var_11_1 = arg_11_1.x
	local var_11_2 = arg_11_1.y

	if var_11_0 == "began" then
		arg_11_0.touchBeganX = var_11_1
		arg_11_0.touchBeganY = var_11_2

		if not arg_11_0:checkTouchInSprite_(var_11_1, var_11_2) then
			return false
		end

		arg_11_0.fsm_:doEvent("press")
		arg_11_0:dispatchEvent({
			touchInTarget = true,
			name = var_0_1.PRESSED_EVENT,
			x = var_11_1,
			y = var_11_2
		})

		if arg_11_0.longTouchEnabled_ then
			arg_11_0.isTouchHold_ = true
			arg_11_0.isLongTouched_ = false

			if arg_11_0.isLongTouchRepeat_ then
				arg_11_0.longTouchHandle_ = var_0_0.scheduleGlobal(function()
					if arg_11_0.isTouchHold_ then
						arg_11_0.isLongTouched_ = true

						arg_11_0:dispatchEvent({
							touchInTarget = true,
							name = var_0_1.LONG_TOUCH_EVENT,
							x = var_11_1,
							y = var_11_2
						})
					end
				end, var_0_1.LONG_TOUCH_INTERVAL)
			else
				arg_11_0.longTouchHandle_ = var_0_0.performWithDelayGlobal(function()
					if arg_11_0.isTouchHold_ then
						arg_11_0.isLongTouched_ = true

						arg_11_0:dispatchEvent({
							touchInTarget = true,
							name = var_0_1.LONG_TOUCH_EVENT,
							x = var_11_1,
							y = var_11_2
						})
					end
				end, var_0_1.LONG_TOUCH_INTERVAL)
			end
		end

		return true
	end

	local var_11_3 = arg_11_0:checkTouchInSprite_(arg_11_0.touchBeganX, arg_11_0.touchBeganY) and arg_11_0:checkTouchInSprite_(var_11_1, var_11_2)

	if var_11_0 == "moved" then
		if var_11_3 and arg_11_0.fsm_:canDoEvent("press") then
			arg_11_0.fsm_:doEvent("press")
			arg_11_0:dispatchEvent({
				touchInTarget = true,
				name = var_0_1.PRESSED_EVENT,
				x = var_11_1,
				y = var_11_2
			})
		elseif not var_11_3 and arg_11_0.fsm_:canDoEvent("release") then
			arg_11_0.fsm_:doEvent("release")
			arg_11_0:dispatchEvent({
				touchInTarget = false,
				name = var_0_1.RELEASE_EVENT,
				x = var_11_1,
				y = var_11_2
			})
		end

		if arg_11_0.longTouchEnabled_ and (math.abs(var_11_1 - arg_11_0.touchBeganX) > var_0_1.LONG_TOUCH_THRESHOLD or math.abs(var_11_2 - arg_11_0.touchBeganY) > var_0_1.LONG_TOUCH_THRESHOLD) then
			arg_11_0.isTouchHold_ = false

			if arg_11_0.longTouchHandle_ then
				var_0_0.unscheduleGlobal(arg_11_0.longTouchHandle_)
			end
		end
	else
		if arg_11_0.fsm_:canDoEvent("release") then
			arg_11_0.fsm_:doEvent("release")
			arg_11_0:dispatchEvent({
				name = var_0_1.RELEASE_EVENT,
				x = var_11_1,
				y = var_11_2,
				touchInTarget = var_11_3
			})
		end

		if var_11_0 == "ended" and var_11_3 then
			if arg_11_0.isLongTouched_ == false then
				arg_11_0:dispatchEvent({
					touchInTarget = true,
					name = var_0_1.CLICKED_EVENT,
					x = var_11_1,
					y = var_11_2
				})
			end

			arg_11_0:dispatchEvent({
				touchInTarget = true,
				name = var_0_1.TOUCH_END_EVENT,
				x = var_11_1,
				y = var_11_2
			})
		end

		if arg_11_0.longTouchEnabled_ then
			arg_11_0.isTouchHold_ = false

			if arg_11_0.longTouchHandle_ then
				var_0_0.unscheduleGlobal(arg_11_0.longTouchHandle_)
			end
		end
	end
end

return var_0_1
