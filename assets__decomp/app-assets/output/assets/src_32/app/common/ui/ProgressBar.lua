local var_0_0 = class("ProgressBar", function(arg_1_0, arg_1_1)
	local var_1_0 = display.newNode()

	var_1_0.sprite_ = xyd.AssetLoader.get():loadSprite(arg_1_0, arg_1_1):align(display.LEFT_BOTTOM, 0, 0):addTo(var_1_0)

	return var_1_0
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:setPercent(0)
end

function var_0_0.setBarSize(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0.sprite_:retain()
	arg_3_0.sprite_:removeSelf()

	if arg_3_0.mask_ ~= nil then
		arg_3_0.mask_:removeSelf()
	end

	arg_3_0.mask_ = display.newClippingRegionNode(cc.rect(0, 0, arg_3_1, arg_3_2)):pos(0, 0):size(arg_3_1, arg_3_2):addTo(arg_3_0)

	arg_3_0.sprite_:addTo(arg_3_0.mask_)
	arg_3_0.sprite_:release()
	arg_3_0:size(arg_3_1, arg_3_2)
	arg_3_0:setPercent_(arg_3_0.percent_)
end

function var_0_0.getPercent(arg_4_0)
	return arg_4_0.percent_ or 0
end

function var_0_0.setPercent(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	if arg_5_0.callback_ ~= nil then
		local var_5_0 = arg_5_0.callback_

		arg_5_0.callback_ = nil

		var_5_0()
	end

	local function var_5_1()
		if arg_5_4 ~= nil then
			arg_5_4()
		end
	end

	arg_5_0:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
	arg_5_0:unscheduleUpdate()

	arg_5_1 = math.max(0, math.min(1, arg_5_1))

	if not arg_5_2 or arg_5_3 == nil or arg_5_3 <= 0 then
		arg_5_0:setPercent_(arg_5_1)

		return var_5_1()
	end

	arg_5_0.from_ = arg_5_0.percent_ or 0
	arg_5_0.to_ = arg_5_1
	arg_5_0.elapsed_ = 0
	arg_5_0.duration_ = arg_5_3
	arg_5_0.callback_ = var_5_1

	arg_5_0:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(arg_7_0)
		arg_5_0.elapsed_ = arg_5_0.elapsed_ + arg_7_0

		if arg_5_0.elapsed_ < arg_5_3 then
			arg_5_0:setPercent_((arg_5_0.percent_ or 0) + arg_7_0 / arg_5_3 * (arg_5_0.to_ - arg_5_0.from_))
		else
			arg_5_0:setPercent_(arg_5_0.to_)
			arg_5_0:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
			arg_5_0:unscheduleUpdate()

			if arg_5_0.callback_ ~= nil then
				local var_7_0 = arg_5_0.callback_

				arg_5_0.callback_ = nil

				var_7_0()
			end
		end
	end)
	arg_5_0:scheduleUpdate()
end

function var_0_0.setPercent_(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0:getContentSize()

	if var_8_0.width <= 0 then
		return
	end

	arg_8_0.percent_ = arg_8_1 or 0

	arg_8_0.sprite_:size(arg_8_0.percent_ * var_8_0.width, var_8_0.height)
end

return var_0_0
