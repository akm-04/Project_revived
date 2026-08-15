local var_0_0 = class("UIButton", function()
	return display.newNode()
end)

var_0_0.CLICKED_EVENT = "CLICKED_EVENT"
var_0_0.PRESSED_EVENT = "PRESSED_EVENT"
var_0_0.RELEASE_EVENT = "RELEASE_EVENT"
var_0_0.STATE_CHANGED_EVENT = "STATE_CHANGED_EVENT"
var_0_0.IMAGE_ZORDER = -100
var_0_0.LABEL_ZORDER = 0

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	arg_2_0.fsm_ = {}

	cc(arg_2_0.fsm_):addComponent("components.behavior.StateMachine"):exportMethods()
	arg_2_0.fsm_:setupState({
		initial = {
			event = "startup",
			defer = false,
			state = arg_2_2
		},
		events = arg_2_1,
		callbacks = {
			onchangestate = handler(arg_2_0, arg_2_0.onChangeState_)
		}
	})
	makeUIControl_(arg_2_0)
	arg_2_0:setLayoutSizePolicy(display.FIXED_SIZE, display.FIXED_SIZE)
	arg_2_0:setButtonEnabled(true)
	arg_2_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(arg_2_0, arg_2_0.onTouch_))

	arg_2_0.touchInSpriteOnly_ = arg_2_3 and arg_2_3.touchInSprite
	arg_2_0.currentImage_ = nil
	arg_2_0.images_ = {}
	arg_2_0.sprite_ = {}
	arg_2_0.scale9_ = arg_2_3 and arg_2_3.scale9
	arg_2_0.capInsets_ = arg_2_3 and arg_2_3.capInsets
	arg_2_0.flipX_ = arg_2_3 and arg_2_3.flipX
	arg_2_0.flipY_ = arg_2_3 and arg_2_3.flipY
	arg_2_0.scale9Size_ = nil
	arg_2_0.labels_ = {}
	arg_2_0.labelOffset_ = {
		0,
		0
	}
	arg_2_0.labelAlign_ = display.CENTER
	arg_2_0.initialState_ = arg_2_2

	display.align(arg_2_0, display.CENTER)

	if type(arg_2_0.flipX_) ~= "boolean" then
		arg_2_0.flipX_ = false
	end

	if type(arg_2_0.flipY_) ~= "boolean" then
		arg_2_0.flipY_ = false
	end

	arg_2_0:addNodeEventListener(cc.NODE_EVENT, function(arg_3_0)
		if arg_3_0.name == "enter" then
			arg_2_0:updateButtonImage_()
		end
	end)
end

function var_0_0.align(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	display.align(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	arg_4_0:updateButtonImage_()
	arg_4_0:updateButtonLable_()

	local var_4_0 = arg_4_0:getCascadeBoundingBox().size
	local var_4_1 = arg_4_0:getAnchorPoint()

	return arg_4_0
end

function var_0_0.setButtonImage(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if arg_5_3 and arg_5_2 == nil then
		return
	end

	arg_5_0.images_[arg_5_1] = arg_5_2

	if arg_5_1 == arg_5_0.fsm_:getState() then
		arg_5_0:updateButtonImage_()
	end

	return arg_5_0
end

function var_0_0.setButtonLabel(arg_6_0, arg_6_1, arg_6_2)
	if not arg_6_2 then
		arg_6_2 = arg_6_1
		arg_6_1 = arg_6_0:getDefaultState_()
	end

	assert(arg_6_2 ~= nil, "UIButton:setButtonLabel() - invalid label")

	if type(arg_6_1) == "table" then
		arg_6_1 = arg_6_1[1]
	end

	local var_6_0 = arg_6_0.labels_[arg_6_1]

	if var_6_0 then
		var_6_0:removeSelf()
	end

	arg_6_0.labels_[arg_6_1] = arg_6_2

	arg_6_0:addChild(arg_6_2, var_0_0.LABEL_ZORDER)
	arg_6_0:updateButtonLable_()

	return arg_6_0
end

function var_0_0.getButtonLabel(arg_7_0, arg_7_1)
	arg_7_1 = arg_7_1 or arg_7_0:getDefaultState_()

	if type(arg_7_1) == "table" then
		arg_7_1 = arg_7_1[1]
	end

	return arg_7_0.labels_[arg_7_1]
end

function var_0_0.setButtonLabelString(arg_8_0, arg_8_1, arg_8_2)
	assert(arg_8_0.labels_ ~= nil, "UIButton:setButtonLabelString() - not add label")

	if arg_8_2 == nil then
		arg_8_2 = arg_8_1

		for iter_8_0, iter_8_1 in pairs(arg_8_0.labels_) do
			iter_8_1:setString(arg_8_2)
		end
	else
		local var_8_0 = arg_8_0.labels_[arg_8_1]

		if var_8_0 then
			var_8_0:setString(arg_8_2)
		end
	end

	return arg_8_0
end

function var_0_0.getButtonLabelOffset(arg_9_0)
	return arg_9_0.labelOffset_[1], arg_9_0.labelOffset_[2]
end

function var_0_0.setButtonLabelOffset(arg_10_0, arg_10_1, arg_10_2)
	arg_10_0.labelOffset_ = {
		arg_10_1,
		arg_10_2
	}

	arg_10_0:updateButtonLable_()

	return arg_10_0
end

function var_0_0.getButtonLabelAlignment(arg_11_0)
	return arg_11_0.labelAlign_
end

function var_0_0.setButtonLabelAlignment(arg_12_0, arg_12_1)
	arg_12_0.labelAlign_ = arg_12_1

	arg_12_0:updateButtonLable_()

	return arg_12_0
end

function var_0_0.setButtonSize(arg_13_0, arg_13_1, arg_13_2)
	arg_13_0.scale9Size_ = {
		arg_13_1,
		arg_13_2
	}

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sprite_) do
		if arg_13_0.scale9_ then
			iter_13_1:setContentSize(cc.size(arg_13_0.scale9Size_[1], arg_13_0.scale9Size_[2]))
		else
			local var_13_0 = iter_13_1:getContentSize()
			local var_13_1 = iter_13_1:getScaleX()
			local var_13_2 = iter_13_1:getScaleY()
			local var_13_3 = var_13_1 * arg_13_0.scale9Size_[1] / var_13_0.width
			local var_13_4 = var_13_2 * arg_13_0.scale9Size_[2] / var_13_0.height

			iter_13_1:setScaleX(var_13_3)
			iter_13_1:setScaleY(var_13_4)
		end
	end

	return arg_13_0
end

function var_0_0.setButtonEnabled(arg_14_0, arg_14_1)
	arg_14_0:setTouchEnabled(arg_14_1)

	if arg_14_1 and arg_14_0.fsm_:canDoEvent("enable") then
		arg_14_0.fsm_:doEventForce("enable")
		arg_14_0:dispatchEvent({
			name = var_0_0.STATE_CHANGED_EVENT,
			state = arg_14_0.fsm_:getState()
		})
	elseif not arg_14_1 and arg_14_0.fsm_:canDoEvent("disable") then
		arg_14_0.fsm_:doEventForce("disable")
		arg_14_0:dispatchEvent({
			name = var_0_0.STATE_CHANGED_EVENT,
			state = arg_14_0.fsm_:getState()
		})
	end

	return arg_14_0
end

function var_0_0.isButtonEnabled(arg_15_0)
	return arg_15_0.fsm_:canDoEvent("disable")
end

function var_0_0.addButtonClickedEventListener(arg_16_0, arg_16_1)
	return arg_16_0:addEventListener(var_0_0.CLICKED_EVENT, arg_16_1)
end

function var_0_0.onButtonClicked(arg_17_0, arg_17_1)
	arg_17_0:addButtonClickedEventListener(arg_17_1)

	return arg_17_0
end

function var_0_0.addButtonPressedEventListener(arg_18_0, arg_18_1)
	return arg_18_0:addEventListener(var_0_0.PRESSED_EVENT, arg_18_1)
end

function var_0_0.onButtonPressed(arg_19_0, arg_19_1)
	arg_19_0:addButtonPressedEventListener(arg_19_1)

	return arg_19_0
end

function var_0_0.addButtonReleaseEventListener(arg_20_0, arg_20_1)
	return arg_20_0:addEventListener(var_0_0.RELEASE_EVENT, arg_20_1)
end

function var_0_0.onButtonRelease(arg_21_0, arg_21_1)
	arg_21_0:addButtonReleaseEventListener(arg_21_1)

	return arg_21_0
end

function var_0_0.addButtonStateChangedEventListener(arg_22_0, arg_22_1)
	return arg_22_0:addEventListener(var_0_0.STATE_CHANGED_EVENT, arg_22_1)
end

function var_0_0.onButtonStateChanged(arg_23_0, arg_23_1)
	arg_23_0:addButtonStateChangedEventListener(arg_23_1)

	return arg_23_0
end

function var_0_0.onChangeState_(arg_24_0, arg_24_1)
	if arg_24_0:isRunning() then
		arg_24_0:updateButtonImage_()
		arg_24_0:updateButtonLable_()
	end
end

function var_0_0.onTouch_(arg_25_0, arg_25_1)
	printError("UIButton:onTouch_() - must override in inherited class")
end

function var_0_0.updateButtonImage_(arg_26_0)
	local var_26_0 = arg_26_0.fsm_:getState()
	local var_26_1 = arg_26_0.images_[var_26_0]

	if not var_26_1 then
		for iter_26_0, iter_26_1 in pairs(arg_26_0:getDefaultState_()) do
			var_26_1 = arg_26_0.images_[iter_26_1]

			if var_26_1 then
				break
			end
		end
	end

	if var_26_1 then
		if arg_26_0.currentImage_ ~= var_26_1 then
			for iter_26_2, iter_26_3 in ipairs(arg_26_0.sprite_) do
				iter_26_3:removeFromParent(true)
			end

			arg_26_0.sprite_ = {}
			arg_26_0.currentImage_ = var_26_1

			if type(var_26_1) == "table" then
				for iter_26_4, iter_26_5 in ipairs(var_26_1) do
					if arg_26_0.scale9_ then
						arg_26_0.sprite_[iter_26_4] = display.newScale9Sprite(iter_26_5, 0, 0, arg_26_0.scale9Size_, arg_26_0.capInsets_)

						if not arg_26_0.scale9Size_ then
							local var_26_2 = arg_26_0.sprite_[iter_26_4]:getContentSize()

							arg_26_0.scale9Size_ = {
								var_26_2.width,
								var_26_2.height
							}
						else
							arg_26_0.sprite_[iter_26_4]:setContentSize(cc.size(arg_26_0.scale9Size_[1], arg_26_0.scale9Size_[2]))
						end
					else
						arg_26_0.sprite_[iter_26_4] = display.newSprite(iter_26_5)
					end

					arg_26_0:addChild(arg_26_0.sprite_[iter_26_4], var_0_0.IMAGE_ZORDER)

					if arg_26_0.sprite_[iter_26_4].setFlippedX then
						if arg_26_0.flipX_ then
							arg_26_0.sprite_[iter_26_4]:setFlippedX(arg_26_0.flipX_ or false)
						end

						if arg_26_0.flipY_ then
							arg_26_0.sprite_[iter_26_4]:setFlippedY(arg_26_0.flipY_ or false)
						end
					end
				end
			else
				if arg_26_0.scale9_ then
					arg_26_0.sprite_[1] = display.newScale9Sprite(var_26_1, 0, 0, arg_26_0.scale9Size_, arg_26_0.capInsets_)

					if not arg_26_0.scale9Size_ then
						local var_26_3 = arg_26_0.sprite_[1]:getContentSize()

						arg_26_0.scale9Size_ = {
							var_26_3.width,
							var_26_3.height
						}
					else
						arg_26_0.sprite_[1]:setContentSize(cc.size(arg_26_0.scale9Size_[1], arg_26_0.scale9Size_[2]))
					end
				else
					arg_26_0.sprite_[1] = display.newSprite(var_26_1)
				end

				if arg_26_0.sprite_[1].setFlippedX then
					if arg_26_0.flipX_ then
						arg_26_0.sprite_[1]:setFlippedX(arg_26_0.flipX_ or false)
					end

					if arg_26_0.flipY_ then
						arg_26_0.sprite_[1]:setFlippedY(arg_26_0.flipY_ or false)
					end
				end

				arg_26_0:addChild(arg_26_0.sprite_[1], var_0_0.IMAGE_ZORDER)
			end
		end

		for iter_26_6, iter_26_7 in ipairs(arg_26_0.sprite_) do
			iter_26_7:setAnchorPoint(arg_26_0:getAnchorPoint())
			iter_26_7:setPosition(0, 0)
		end
	elseif not arg_26_0.labels_ then
		printError("UIButton:updateButtonImage_() - not set image for state %s", var_26_0)
	end
end

function var_0_0.updateButtonLable_(arg_27_0)
	if not arg_27_0.labels_ then
		return
	end

	local var_27_0 = arg_27_0.fsm_:getState()
	local var_27_1 = arg_27_0.labels_[var_27_0]

	if not var_27_1 then
		for iter_27_0, iter_27_1 in pairs(arg_27_0:getDefaultState_()) do
			var_27_1 = arg_27_0.labels_[iter_27_1]

			if var_27_1 then
				break
			end
		end
	end

	local var_27_2 = arg_27_0.labelOffset_[1]
	local var_27_3 = arg_27_0.labelOffset_[2]

	if arg_27_0.sprite_[1] then
		local var_27_4 = arg_27_0:getAnchorPoint()
		local var_27_5 = arg_27_0.sprite_[1]:getContentSize()

		var_27_2 = var_27_2 + var_27_5.width * (0.5 - var_27_4.x)
		var_27_3 = var_27_3 + var_27_5.height * (0.5 - var_27_4.y)
	end

	for iter_27_2, iter_27_3 in pairs(arg_27_0.labels_) do
		iter_27_3:setVisible(iter_27_3 == var_27_1)
		iter_27_3:align(arg_27_0.labelAlign_, var_27_2, var_27_3)
	end
end

function var_0_0.getDefaultState_(arg_28_0)
	return {
		arg_28_0.initialState_
	}
end

function var_0_0.checkTouchInSprite_(arg_29_0, arg_29_1, arg_29_2)
	if arg_29_0.touchInSpriteOnly_ then
		return arg_29_0.sprite_[1] and arg_29_0.sprite_[1]:getCascadeBoundingBox():containsPoint(cc.p(arg_29_1, arg_29_2))
	else
		return arg_29_0:getCascadeBoundingBox():containsPoint(cc.p(arg_29_1, arg_29_2))
	end
end

return var_0_0
