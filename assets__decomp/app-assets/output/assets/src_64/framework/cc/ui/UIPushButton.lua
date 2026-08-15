local var_0_0 = import(".UIButton")
local var_0_1 = class("UIPushButton", var_0_0)

var_0_1.NORMAL = "normal"
var_0_1.PRESSED = "pressed"
var_0_1.DISABLED = "disabled"

function var_0_1.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_1.super.ctor(arg_1_0, {
		{
			to = "disabled",
			name = "disable",
			from = {
				"normal",
				"pressed"
			}
		},
		{
			to = "normal",
			name = "enable",
			from = {
				"disabled"
			}
		},
		{
			to = "pressed",
			name = "press",
			from = "normal"
		},
		{
			to = "normal",
			name = "release",
			from = "pressed"
		}
	}, "normal", arg_1_2)

	if type(arg_1_1) ~= "table" then
		arg_1_1 = {
			normal = arg_1_1
		}
	end

	arg_1_0:setButtonImage(var_0_1.NORMAL, arg_1_1.normal, true)
	arg_1_0:setButtonImage(var_0_1.PRESSED, arg_1_1.pressed, true)
	arg_1_0:setButtonImage(var_0_1.DISABLED, arg_1_1.disabled, true)
end

function var_0_1.setButtonImage(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	assert(arg_2_1 == var_0_1.NORMAL or arg_2_1 == var_0_1.PRESSED or arg_2_1 == var_0_1.DISABLED, string.format("UIPushButton:setButtonImage() - invalid state %s", tostring(arg_2_1)))
	var_0_1.super.setButtonImage(arg_2_0, arg_2_1, arg_2_2, arg_2_3)

	if arg_2_1 == var_0_1.NORMAL then
		if not arg_2_0.images_[var_0_1.PRESSED] then
			arg_2_0.images_[var_0_1.PRESSED] = arg_2_2
		end

		if not arg_2_0.images_[var_0_1.DISABLED] then
			arg_2_0.images_[var_0_1.DISABLED] = arg_2_2
		end
	end

	return arg_2_0
end

function var_0_1.onTouch_(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.name
	local var_3_1 = arg_3_1.x
	local var_3_2 = arg_3_1.y

	if var_3_0 == "began" then
		arg_3_0.touchBeganX = var_3_1
		arg_3_0.touchBeganY = var_3_2

		if not arg_3_0:checkTouchInSprite_(var_3_1, var_3_2) then
			return false
		end

		arg_3_0.fsm_:doEvent("press")
		arg_3_0:dispatchEvent({
			touchInTarget = true,
			name = var_0_0.PRESSED_EVENT,
			x = var_3_1,
			y = var_3_2
		})

		return true
	end

	local var_3_3 = arg_3_0:checkTouchInSprite_(arg_3_0.touchBeganX, arg_3_0.touchBeganY) and arg_3_0:checkTouchInSprite_(var_3_1, var_3_2)

	if var_3_0 == "moved" then
		if var_3_3 and arg_3_0.fsm_:canDoEvent("press") then
			arg_3_0.fsm_:doEvent("press")
			arg_3_0:dispatchEvent({
				touchInTarget = true,
				name = var_0_0.PRESSED_EVENT,
				x = var_3_1,
				y = var_3_2
			})
		elseif not var_3_3 and arg_3_0.fsm_:canDoEvent("release") then
			arg_3_0.fsm_:doEvent("release")
			arg_3_0:dispatchEvent({
				touchInTarget = false,
				name = var_0_0.RELEASE_EVENT,
				x = var_3_1,
				y = var_3_2
			})
		end
	else
		if arg_3_0.fsm_:canDoEvent("release") then
			arg_3_0.fsm_:doEvent("release")
			arg_3_0:dispatchEvent({
				name = var_0_0.RELEASE_EVENT,
				x = var_3_1,
				y = var_3_2,
				touchInTarget = var_3_3
			})
		end

		if var_3_0 == "ended" and var_3_3 then
			arg_3_0:dispatchEvent({
				touchInTarget = true,
				name = var_0_0.CLICKED_EVENT,
				x = var_3_1,
				y = var_3_2
			})
		end
	end
end

return var_0_1
