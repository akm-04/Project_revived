local var_0_0 = class("UISlider", function()
	return display.newNode()
end)

var_0_0.BAR = "bar"
var_0_0.BUTTON = "button"
var_0_0.BAR_PRESSED = "bar_pressed"
var_0_0.BUTTON_PRESSED = "button_pressed"
var_0_0.BAR_DISABLED = "bar_disabled"
var_0_0.BUTTON_DISABLED = "button_disabled"
var_0_0.PRESSED_EVENT = "PRESSED_EVENT"
var_0_0.RELEASE_EVENT = "RELEASE_EVENT"
var_0_0.STATE_CHANGED_EVENT = "STATE_CHANGED_EVENT"
var_0_0.VALUE_CHANGED_EVENT = "VALUE_CHANGED_EVENT"
var_0_0.BAR_ZORDER = 0
var_0_0.BARFG_ZORDER = 1
var_0_0.BUTTON_ZORDER = 2

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	arg_2_0.fsm_ = {}

	cc(arg_2_0.fsm_):addComponent("components.behavior.StateMachine"):exportMethods()
	arg_2_0.fsm_:setupState({
		initial = {
			event = "startup",
			defer = false,
			state = "normal"
		},
		events = {
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
		},
		callbacks = {
			onchangestate = handler(arg_2_0, arg_2_0.onChangeState_)
		}
	})
	makeUIControl_(arg_2_0)
	arg_2_0:setLayoutSizePolicy(display.FIXED_SIZE, display.FIXED_SIZE)

	arg_2_3 = checktable(arg_2_3)
	arg_2_0.direction_ = arg_2_1
	arg_2_0.isHorizontal_ = arg_2_1 == display.LEFT_TO_RIGHT or arg_2_1 == display.RIGHT_TO_LEFT
	arg_2_0.images_ = clone(arg_2_2)
	arg_2_0.scale9_ = arg_2_3.scale9
	arg_2_0.scale9Size_ = nil
	arg_2_0.min_ = checknumber(arg_2_3.min or 0)
	arg_2_0.max_ = checknumber(arg_2_3.max or 100)
	arg_2_0.value_ = arg_2_0.min_
	arg_2_0.buttonPositionRange_ = {
		max = 0,
		min = 0
	}
	arg_2_0.buttonPositionOffset_ = {
		x = 0,
		y = 0
	}
	arg_2_0.touchInButtonOnly_ = true

	if type(arg_2_3.touchInButton) == "boolean" then
		arg_2_0.touchInButtonOnly_ = arg_2_3.touchInButton
	end

	arg_2_0.buttonRotation_ = 0
	arg_2_0.barSprite_ = nil
	arg_2_0.buttonSprite_ = nil
	arg_2_0.currentBarImage_ = nil
	arg_2_0.currentButtonImage_ = nil

	arg_2_0:updateImage_()
	arg_2_0:updateButtonPosition_()
	arg_2_0:setTouchEnabled(true)
	arg_2_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
		return arg_2_0:onTouch_(arg_3_0.name, arg_3_0.x, arg_3_0.y)
	end)
end

function var_0_0.setSliderSize(arg_4_0, arg_4_1, arg_4_2)
	arg_4_0.scale9Size_ = {
		arg_4_1,
		arg_4_2
	}

	if arg_4_0.barSprite_ then
		if arg_4_0.scale9_ then
			arg_4_0.barSprite_:setContentSize(cc.size(arg_4_0.scale9Size_[1], arg_4_0.scale9Size_[2]))
			arg_4_0:setFgBarSize_(cc.size(arg_4_0.scale9Size_[1], arg_4_0.scale9Size_[2]))
		else
			arg_4_0:setContentSizeAndScale_(arg_4_0.barSprite_, cc.size(arg_4_0.scale9Size_[1], arg_4_0.scale9Size_[2]))
			arg_4_0:setContentSizeAndScale_(arg_4_0.barfgSprite_, cc.size(arg_4_0.scale9Size_[1], arg_4_0.scale9Size_[2]))
		end
	end

	return arg_4_0
end

function var_0_0.setSliderEnabled(arg_5_0, arg_5_1)
	arg_5_0:setTouchEnabled(arg_5_1)

	if arg_5_1 and arg_5_0.fsm_:canDoEvent("enable") then
		arg_5_0.fsm_:doEventForce("enable")
		arg_5_0:dispatchEvent({
			name = var_0_0.STATE_CHANGED_EVENT,
			state = arg_5_0.fsm_:getState()
		})
	elseif not arg_5_1 and arg_5_0.fsm_:canDoEvent("disable") then
		arg_5_0.fsm_:doEventForce("disable")
		arg_5_0:dispatchEvent({
			name = var_0_0.STATE_CHANGED_EVENT,
			state = arg_5_0.fsm_:getState()
		})
	end

	return arg_5_0
end

function var_0_0.align(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	display.align(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	arg_6_0:updateImage_()

	return arg_6_0
end

function var_0_0.isButtonEnabled(arg_7_0)
	return arg_7_0.fsm_:canDoEvent("disable")
end

function var_0_0.getSliderValue(arg_8_0)
	return arg_8_0.value_
end

function var_0_0.setSliderValue(arg_9_0, arg_9_1)
	assert(arg_9_1 >= arg_9_0.min_ and arg_9_1 <= arg_9_0.max_, "UISlider:setSliderValue() - invalid value")

	if arg_9_0.value_ ~= arg_9_1 then
		arg_9_0.value_ = arg_9_1

		arg_9_0:updateButtonPosition_()
		arg_9_0:dispatchEvent({
			name = var_0_0.VALUE_CHANGED_EVENT,
			value = arg_9_0.value_
		})
	end

	return arg_9_0
end

function var_0_0.setSliderButtonRotation(arg_10_0, arg_10_1)
	arg_10_0.buttonRotation_ = arg_10_1

	arg_10_0:updateImage_()

	return arg_10_0
end

function var_0_0.addSliderValueChangedEventListener(arg_11_0, arg_11_1)
	return arg_11_0:addEventListener(var_0_0.VALUE_CHANGED_EVENT, arg_11_1)
end

function var_0_0.onSliderValueChanged(arg_12_0, arg_12_1)
	arg_12_0:addSliderValueChangedEventListener(arg_12_1)

	return arg_12_0
end

function var_0_0.addSliderPressedEventListener(arg_13_0, arg_13_1)
	return arg_13_0:addEventListener(var_0_0.PRESSED_EVENT, arg_13_1)
end

function var_0_0.onSliderPressed(arg_14_0, arg_14_1)
	arg_14_0:addSliderPressedEventListener(arg_14_1)

	return arg_14_0
end

function var_0_0.addSliderReleaseEventListener(arg_15_0, arg_15_1)
	return arg_15_0:addEventListener(var_0_0.RELEASE_EVENT, arg_15_1)
end

function var_0_0.onSliderRelease(arg_16_0, arg_16_1)
	arg_16_0:addSliderReleaseEventListener(arg_16_1)

	return arg_16_0
end

function var_0_0.addSliderStateChangedEventListener(arg_17_0, arg_17_1)
	return arg_17_0:addEventListener(var_0_0.STATE_CHANGED_EVENT, arg_17_1)
end

function var_0_0.onSliderStateChanged(arg_18_0, arg_18_1)
	arg_18_0:addSliderStateChangedEventListener(arg_18_1)

	return arg_18_0
end

function var_0_0.onTouch_(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if arg_19_1 == "began" then
		if not arg_19_0:checkTouchInButton_(arg_19_2, arg_19_3) then
			return false
		end

		local var_19_0, var_19_1 = arg_19_0.buttonSprite_:getPosition()
		local var_19_2 = arg_19_0:convertToWorldSpace(cc.p(var_19_0, var_19_1))

		arg_19_0.buttonPositionOffset_.x = var_19_2.x - arg_19_2
		arg_19_0.buttonPositionOffset_.y = var_19_2.y - arg_19_3

		arg_19_0.fsm_:doEvent("press")
		arg_19_0:dispatchEvent({
			touchInTarget = true,
			name = var_0_0.PRESSED_EVENT,
			x = arg_19_2,
			y = arg_19_3
		})

		return true
	end

	local var_19_3 = arg_19_0:checkTouchInButton_(arg_19_2, arg_19_3)

	arg_19_2 = arg_19_2 + arg_19_0.buttonPositionOffset_.x
	arg_19_3 = arg_19_3 + arg_19_0.buttonPositionOffset_.y

	local var_19_4 = arg_19_0:convertToNodeSpace(cc.p(arg_19_2, arg_19_3))

	arg_19_2 = var_19_4.x
	arg_19_3 = var_19_4.y

	local var_19_5 = 0

	if arg_19_0.isHorizontal_ then
		if arg_19_2 < arg_19_0.buttonPositionRange_.min then
			arg_19_2 = arg_19_0.buttonPositionRange_.min
		elseif arg_19_2 > arg_19_0.buttonPositionRange_.max then
			arg_19_2 = arg_19_0.buttonPositionRange_.max
		end

		if arg_19_0.direction_ == display.LEFT_TO_RIGHT then
			var_19_5 = (arg_19_2 - arg_19_0.buttonPositionRange_.min) / arg_19_0.buttonPositionRange_.length
		else
			var_19_5 = (arg_19_0.buttonPositionRange_.max - arg_19_2) / arg_19_0.buttonPositionRange_.length
		end
	else
		if arg_19_3 < arg_19_0.buttonPositionRange_.min then
			arg_19_3 = arg_19_0.buttonPositionRange_.min
		elseif arg_19_3 > arg_19_0.buttonPositionRange_.max then
			arg_19_3 = arg_19_0.buttonPositionRange_.max
		end

		if arg_19_0.direction_ == display.TOP_TO_BOTTOM then
			var_19_5 = (arg_19_0.buttonPositionRange_.max - arg_19_3) / arg_19_0.buttonPositionRange_.length
		else
			var_19_5 = (arg_19_3 - arg_19_0.buttonPositionRange_.min) / arg_19_0.buttonPositionRange_.length
		end
	end

	arg_19_0:setSliderValue(var_19_5 * (arg_19_0.max_ - arg_19_0.min_) + arg_19_0.min_)

	if arg_19_1 ~= "moved" and arg_19_0.fsm_:canDoEvent("release") then
		arg_19_0.fsm_:doEvent("release")
		arg_19_0:dispatchEvent({
			name = var_0_0.RELEASE_EVENT,
			x = arg_19_2,
			y = arg_19_3,
			touchInTarget = var_19_3
		})
	end
end

function var_0_0.checkTouchInButton_(arg_20_0, arg_20_1, arg_20_2)
	if not arg_20_0.buttonSprite_ then
		return false
	end

	if arg_20_0.touchInButtonOnly_ then
		return arg_20_0.buttonSprite_:getCascadeBoundingBox():containsPoint(cc.p(arg_20_1, arg_20_2))
	else
		return arg_20_0:getCascadeBoundingBox():containsPoint(cc.p(arg_20_1, arg_20_2))
	end
end

function var_0_0.updateButtonPosition_(arg_21_0)
	if not arg_21_0.barSprite_ or not arg_21_0.buttonSprite_ then
		return
	end

	local var_21_0 = 0
	local var_21_1 = 0
	local var_21_2 = arg_21_0.barSprite_:getContentSize()

	var_21_2.width = var_21_2.width * arg_21_0.barSprite_:getScaleX()
	var_21_2.height = var_21_2.height * arg_21_0.barSprite_:getScaleY()

	local var_21_3 = arg_21_0.buttonSprite_:getContentSize()
	local var_21_4 = (arg_21_0.value_ - arg_21_0.min_) / (arg_21_0.max_ - arg_21_0.min_)
	local var_21_5 = arg_21_0:getAnchorPoint()

	if arg_21_0.isHorizontal_ then
		var_21_0 = var_21_0 - var_21_2.width * var_21_5.x
		var_21_1 = var_21_1 + var_21_2.height * (0.5 - var_21_5.y)
		arg_21_0.buttonPositionRange_.length = var_21_2.width - var_21_3.width
		arg_21_0.buttonPositionRange_.min = var_21_0 + var_21_3.width / 2
		arg_21_0.buttonPositionRange_.max = arg_21_0.buttonPositionRange_.min + arg_21_0.buttonPositionRange_.length

		local var_21_6 = cc.p(0, 0)

		if arg_21_0.barfgSprite_ and arg_21_0.scale9Size_ then
			arg_21_0:setContentSizeAndScale_(arg_21_0.barfgSprite_, cc.size(var_21_4 * arg_21_0.buttonPositionRange_.length, arg_21_0.scale9Size_[2]))

			var_21_6 = arg_21_0:getbgSpriteLeftBottomPoint_()
		end

		if arg_21_0.direction_ == display.LEFT_TO_RIGHT then
			var_21_0 = arg_21_0.buttonPositionRange_.min + var_21_4 * arg_21_0.buttonPositionRange_.length
		else
			if arg_21_0.barfgSprite_ and arg_21_0.scale9Size_ then
				var_21_6.x = var_21_6.x + (1 - var_21_4) * arg_21_0.buttonPositionRange_.length
			end

			var_21_0 = arg_21_0.buttonPositionRange_.min + (1 - var_21_4) * arg_21_0.buttonPositionRange_.length
		end

		if arg_21_0.barfgSprite_ and arg_21_0.scale9Size_ then
			arg_21_0.barfgSprite_:setPosition(var_21_6)
		end
	else
		var_21_0 = var_21_0 - var_21_2.width * (0.5 - var_21_5.x)
		var_21_1 = var_21_1 - var_21_2.height * var_21_5.y
		arg_21_0.buttonPositionRange_.length = var_21_2.height - var_21_3.height
		arg_21_0.buttonPositionRange_.min = var_21_1 + var_21_3.height / 2
		arg_21_0.buttonPositionRange_.max = arg_21_0.buttonPositionRange_.min + arg_21_0.buttonPositionRange_.length

		local var_21_7 = cc.p(0, 0)

		if arg_21_0.barfgSprite_ and arg_21_0.scale9Size_ then
			arg_21_0:setContentSizeAndScale_(arg_21_0.barfgSprite_, cc.size(arg_21_0.scale9Size_[1], var_21_4 * arg_21_0.buttonPositionRange_.length))

			var_21_7 = arg_21_0:getbgSpriteLeftBottomPoint_()
		end

		if arg_21_0.direction_ == display.TOP_TO_BOTTOM then
			var_21_1 = arg_21_0.buttonPositionRange_.min + (1 - var_21_4) * arg_21_0.buttonPositionRange_.length

			if arg_21_0.barfgSprite_ and arg_21_0.scale9Size_ then
				var_21_7.y = var_21_7.y + (1 - var_21_4) * arg_21_0.buttonPositionRange_.length
			end
		else
			var_21_1 = arg_21_0.buttonPositionRange_.min + var_21_4 * arg_21_0.buttonPositionRange_.length

			if arg_21_0.barfgSprite_ then
				-- block empty
			end
		end

		if arg_21_0.barfgSprite_ and arg_21_0.scale9Size_ then
			arg_21_0.barfgSprite_:setPosition(var_21_7)
		end
	end

	arg_21_0.buttonSprite_:setPosition(var_21_0, var_21_1)
end

function var_0_0.updateImage_(arg_22_0)
	local var_22_0 = arg_22_0.fsm_:getState()
	local var_22_1 = "bar"
	local var_22_2 = "barfg"
	local var_22_3 = "button"
	local var_22_4 = arg_22_0.images_[var_22_1]
	local var_22_5 = arg_22_0.images_[var_22_2]
	local var_22_6 = arg_22_0.images_[var_22_3]

	if var_22_0 ~= "normal" then
		var_22_1 = var_22_1 .. "_" .. var_22_0
		var_22_3 = var_22_3 .. "_" .. var_22_0
	end

	if arg_22_0.images_[var_22_1] then
		var_22_4 = arg_22_0.images_[var_22_1]
	end

	if arg_22_0.images_[var_22_3] then
		var_22_6 = arg_22_0.images_[var_22_3]
	end

	if var_22_4 then
		if arg_22_0.currentBarImage_ ~= var_22_4 then
			if arg_22_0.barSprite_ then
				arg_22_0.barSprite_:removeFromParent(true)

				arg_22_0.barSprite_ = nil
			end

			if arg_22_0.scale9_ then
				arg_22_0.barSprite_ = display.newScale9Sprite(var_22_4)

				if not arg_22_0.scale9Size_ then
					local var_22_7 = arg_22_0.barSprite_:getContentSize()

					arg_22_0.scale9Size_ = {
						var_22_7.width,
						var_22_7.height
					}
				else
					arg_22_0.barSprite_:setContentSize(cc.size(arg_22_0.scale9Size_[1], arg_22_0.scale9Size_[2]))
				end
			else
				arg_22_0.barSprite_ = display.newSprite(var_22_4)

				if arg_22_0.scale9Size_ then
					arg_22_0:setContentSizeAndScale_(arg_22_0.barSprite_, cc.size(arg_22_0.scale9Size_[1], arg_22_0.scale9Size_[2]))
				end
			end

			arg_22_0:addChild(arg_22_0.barSprite_, var_0_0.BAR_ZORDER)
		end

		arg_22_0.barSprite_:setAnchorPoint(arg_22_0:getAnchorPoint())
		arg_22_0.barSprite_:setPosition(0, 0)
	else
		printError("UISlider:updateImage_() - not set bar image for state %s", var_22_0)
	end

	if var_22_5 and not arg_22_0.barfgSprite_ then
		if arg_22_0.scale9_ then
			arg_22_0.barfgSprite_ = display.newScale9Sprite(var_22_5)

			arg_22_0.barfgSprite_:setContentSize(cc.size(arg_22_0.scale9Size_[1], arg_22_0.scale9Size_[2]))
		else
			arg_22_0.barfgSprite_ = display.newSprite(var_22_5)
		end

		arg_22_0:addChild(arg_22_0.barfgSprite_, var_0_0.BARFG_ZORDER)
		arg_22_0.barfgSprite_:setAnchorPoint(cc.p(0, 0))
		arg_22_0.barfgSprite_:setPosition(arg_22_0.barSprite_:getPosition())
	end

	if var_22_6 then
		if arg_22_0.currentButtonImage_ ~= var_22_6 then
			if arg_22_0.buttonSprite_ then
				arg_22_0.buttonSprite_:removeFromParent(true)

				arg_22_0.buttonSprite_ = nil
			end

			arg_22_0.buttonSprite_ = display.newSprite(var_22_6)

			arg_22_0:addChild(arg_22_0.buttonSprite_, var_0_0.BUTTON_ZORDER)
		end

		arg_22_0.buttonSprite_:setPosition(0, 0)
		arg_22_0.buttonSprite_:setRotation(arg_22_0.buttonRotation_)
		arg_22_0:updateButtonPosition_()
	else
		printError("UISlider:updateImage_() - not set button image for state %s", var_22_0)
	end
end

function var_0_0.onChangeState_(arg_23_0, arg_23_1)
	if arg_23_0:isRunning() then
		arg_23_0:updateImage_()
	end
end

function var_0_0.setFgBarSize_(arg_24_0, arg_24_1)
	if not arg_24_0.barfgSprite_ then
		return
	end

	arg_24_0.barfgSprite_:setContentSize(arg_24_1)
end

function var_0_0.getbgSpriteLeftBottomPoint_(arg_25_0)
	if not arg_25_0.barSprite_ then
		return cc.p(0, 0)
	end

	local var_25_0, var_25_1 = arg_25_0.barSprite_:getPosition()
	local var_25_2 = arg_25_0.barSprite_:getBoundingBox()
	local var_25_3 = arg_25_0.barSprite_:getAnchorPoint()
	local var_25_4 = var_25_0 - var_25_2.width * var_25_3.x
	local var_25_5 = var_25_1 - var_25_2.height * var_25_3.y

	return (cc.p(var_25_4, var_25_5))
end

function var_0_0.setContentSizeAndScale_(arg_26_0, arg_26_1, arg_26_2)
	if not arg_26_1 then
		return
	end

	local var_26_0 = arg_26_1:getContentSize()
	local var_26_1
	local var_26_2
	local var_26_3 = arg_26_2.width / var_26_0.width
	local var_26_4 = arg_26_2.height / var_26_0.height

	arg_26_1:setScaleX(var_26_3)
	arg_26_1:setScaleY(var_26_4)
end

return var_0_0
