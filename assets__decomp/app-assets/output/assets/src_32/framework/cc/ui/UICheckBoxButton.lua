local var_0_0 = import(".UIButton")
local var_0_1 = class("UICheckBoxButton", var_0_0)

var_0_1.OFF = "off"
var_0_1.OFF_PRESSED = "off_pressed"
var_0_1.OFF_DISABLED = "off_disabled"
var_0_1.ON = "on"
var_0_1.ON_PRESSED = "on_pressed"
var_0_1.ON_DISABLED = "on_disabled"

function var_0_1.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_1.super.ctor(arg_1_0, {
		{
			to = "off_disabled",
			name = "disable",
			from = {
				"off",
				"off_pressed"
			}
		},
		{
			to = "on_disabled",
			name = "disable",
			from = {
				"on",
				"on_pressed"
			}
		},
		{
			to = "off",
			name = "enable",
			from = {
				"off_disabled"
			}
		},
		{
			to = "on",
			name = "enable",
			from = {
				"on_disabled"
			}
		},
		{
			to = "off_pressed",
			name = "press",
			from = "off"
		},
		{
			to = "on_pressed",
			name = "press",
			from = "on"
		},
		{
			to = "off",
			name = "release",
			from = "off_pressed"
		},
		{
			to = "on",
			name = "release",
			from = "on_pressed"
		},
		{
			to = "on",
			name = "select",
			from = "off"
		},
		{
			to = "on_disabled",
			name = "select",
			from = "off_disabled"
		},
		{
			to = "off",
			name = "unselect",
			from = "on"
		},
		{
			to = "off_disabled",
			name = "unselect",
			from = "on_disabled"
		}
	}, "off", arg_1_2)
	arg_1_0:setButtonImage(var_0_1.OFF, arg_1_1.off, true)
	arg_1_0:setButtonImage(var_0_1.OFF_PRESSED, arg_1_1.off_pressed, true)
	arg_1_0:setButtonImage(var_0_1.OFF_DISABLED, arg_1_1.off_disabled, true)
	arg_1_0:setButtonImage(var_0_1.ON, arg_1_1.on, true)
	arg_1_0:setButtonImage(var_0_1.ON_PRESSED, arg_1_1.on_pressed, true)
	arg_1_0:setButtonImage(var_0_1.ON_DISABLED, arg_1_1.on_disabled, true)

	arg_1_0.labelAlign_ = display.LEFT_CENTER
end

function var_0_1.setButtonImage(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	assert(arg_2_1 == var_0_1.OFF or arg_2_1 == var_0_1.OFF_PRESSED or arg_2_1 == var_0_1.OFF_DISABLED or arg_2_1 == var_0_1.ON or arg_2_1 == var_0_1.ON_PRESSED or arg_2_1 == var_0_1.ON_DISABLED, string.format("UICheckBoxButton:setButtonImage() - invalid state %s", tostring(arg_2_1)))
	var_0_1.super.setButtonImage(arg_2_0, arg_2_1, arg_2_2, arg_2_3)

	if arg_2_1 == var_0_1.OFF then
		if not arg_2_0.images_[var_0_1.OFF_PRESSED] then
			arg_2_0.images_[var_0_1.OFF_PRESSED] = arg_2_2
		end

		if not arg_2_0.images_[var_0_1.OFF_DISABLED] then
			arg_2_0.images_[var_0_1.OFF_DISABLED] = arg_2_2
		end
	elseif arg_2_1 == var_0_1.ON then
		if not arg_2_0.images_[var_0_1.ON_PRESSED] then
			arg_2_0.images_[var_0_1.ON_PRESSED] = arg_2_2
		end

		if not arg_2_0.images_[var_0_1.ON_DISABLED] then
			arg_2_0.images_[var_0_1.ON_DISABLED] = arg_2_2
		end
	end

	return arg_2_0
end

function var_0_1.isButtonSelected(arg_3_0)
	return arg_3_0.fsm_:canDoEvent("unselect")
end

function var_0_1.setButtonSelected(arg_4_0, arg_4_1)
	if arg_4_0:isButtonSelected() ~= arg_4_1 then
		if arg_4_1 then
			arg_4_0.fsm_:doEventForce("select")
		else
			arg_4_0.fsm_:doEventForce("unselect")
		end

		arg_4_0:dispatchEvent({
			name = var_0_0.STATE_CHANGED_EVENT,
			state = arg_4_0.fsm_:getState()
		})
	end

	return arg_4_0
end

function var_0_1.onTouch_(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.name
	local var_5_1 = arg_5_1.x
	local var_5_2 = arg_5_1.y

	if var_5_0 == "began" then
		if not arg_5_0:checkTouchInSprite_(var_5_1, var_5_2) then
			return false
		end

		arg_5_0.fsm_:doEvent("press")
		arg_5_0:dispatchEvent({
			touchInTarget = true,
			name = var_0_0.PRESSED_EVENT,
			x = var_5_1,
			y = var_5_2
		})

		return true
	end

	local var_5_3 = arg_5_0:checkTouchInSprite_(var_5_1, var_5_2)

	if var_5_0 == "moved" then
		if var_5_3 and arg_5_0.fsm_:canDoEvent("press") then
			arg_5_0.fsm_:doEvent("press")
			arg_5_0:dispatchEvent({
				touchInTarget = true,
				name = var_0_0.PRESSED_EVENT,
				x = var_5_1,
				y = var_5_2
			})
		elseif not var_5_3 and arg_5_0.fsm_:canDoEvent("release") then
			arg_5_0.fsm_:doEvent("release")
			arg_5_0:dispatchEvent({
				touchInTarget = false,
				name = var_0_0.RELEASE_EVENT,
				x = var_5_1,
				y = var_5_2
			})
		end
	else
		if arg_5_0.fsm_:canDoEvent("release") then
			arg_5_0.fsm_:doEvent("release")
			arg_5_0:dispatchEvent({
				name = var_0_0.RELEASE_EVENT,
				x = var_5_1,
				y = var_5_2,
				touchInTarget = var_5_3
			})
		end

		if var_5_0 == "ended" and var_5_3 then
			arg_5_0:setButtonSelected(arg_5_0.fsm_:canDoEvent("select"))
			arg_5_0:dispatchEvent({
				touchInTarget = true,
				name = var_0_0.CLICKED_EVENT,
				x = var_5_1,
				y = var_5_2
			})
		end
	end
end

function var_0_1.getDefaultState_(arg_6_0)
	local var_6_0 = arg_6_0.fsm_:getState()

	if var_6_0 == var_0_1.ON or var_6_0 == var_0_1.ON_DISABLED or var_6_0 == var_0_1.ON_PRESSED then
		return {
			var_0_1.ON,
			var_0_1.OFF
		}
	else
		return {
			var_0_1.OFF,
			var_0_1.ON
		}
	end
end

return var_0_1
