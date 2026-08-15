local var_0_0 = class("TextBarrageItem", function()
	return cc.Node:create()
end)
local var_0_1 = 10
local var_0_2 = import("framework.scheduler")

function var_0_0.ctor(arg_2_0)
	arg_2_0.textLabel = nil
	arg_2_0.initWidth = math.random(1, 5) * 10 + 30
	arg_2_0.speed = 0
	arg_2_0.labelWidth = 0
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.parent = arg_3_1.parent

	arg_3_0.parent:addChild(arg_3_0)

	arg_3_0.duration = arg_3_1.duration or var_0_1
	arg_3_0.text_1 = arg_3_1.text
	arg_3_0.text_2 = arg_3_1.text_2 or nil
	arg_3_0.isSelf = arg_3_1.isSelf
	arg_3_0.txtSize = arg_3_1.txtSize or 22
	arg_3_0.height = arg_3_1.height
	arg_3_0.callback = arg_3_1.callback
	arg_3_0.viewWidth = arg_3_0.parent:getContentSize().width

	arg_3_0:contentView()
end

function var_0_0.contentView(arg_4_0)
	local var_4_0 = cc.c3b(255, 255, 255)

	if arg_4_0.text_2 then
		arg_4_0.text_1 = arg_4_0.text_1 .. "："
		var_4_0 = cc.c3b(255, 165, 0)
	end

	local var_4_1 = {
		text = arg_4_0.text_1,
		color = var_4_0,
		align = cc.ui.TEXT_ALIGN_CENTER,
		size = arg_4_0.txtSize
	}

	arg_4_0.textLabel_1 = xyd.AssetLoader.get():loadLabel(var_4_1)

	arg_4_0.textLabel_1:enableShadow(cc.c4b(139, 69, 19, 255), cc.size(1, -1), 1)
	arg_4_0.textLabel_1:setPosition(cc.p(0, arg_4_0.textLabel_1:getContentSize().height / 2))
	arg_4_0.textLabel_1:setAnchorPoint(cc.p(0, 0.5))
	arg_4_0.textLabel_1:addTo(arg_4_0)

	arg_4_0.labelTextWidth_1 = arg_4_0.textLabel_1:getContentSize().width
	arg_4_0.labelTextWidth_2 = 0

	if arg_4_0.text_2 then
		local var_4_2 = {
			text = arg_4_0.text_2,
			color = cc.c3b(255, 255, 255),
			align = cc.ui.TEXT_ALIGN_CENTER,
			size = arg_4_0.txtSize
		}

		arg_4_0.textLabel_2 = xyd.AssetLoader.get():loadLabel(var_4_2)

		if arg_4_0.isSelf == 1 then
			arg_4_0.textLabel_2:enableOutline(cc.c4b(255, 153, 170, 255), 2)
		end

		arg_4_0.textLabel_2:enableShadow(xyd.color.FONT_SHADOW_B, cc.size(1, -1), 1)
		arg_4_0.textLabel_2:setPosition(cc.p(arg_4_0.textLabel_1:getContentSize().width, arg_4_0.textLabel_1:getContentSize().height / 2))
		arg_4_0.textLabel_2:setAnchorPoint(cc.p(0, 0.5))
		arg_4_0.textLabel_2:addTo(arg_4_0)

		arg_4_0.labelTextWidth_2 = arg_4_0.textLabel_2:getContentSize().width
	end

	arg_4_0.distance = arg_4_0.labelTextWidth_1 + arg_4_0.labelTextWidth_2 + arg_4_0.viewWidth + arg_4_0.initWidth
end

function var_0_0.move(arg_5_0)
	local var_5_0 = arg_5_0.distance

	if arg_5_0.duration ~= 0 then
		arg_5_0:setPosition(arg_5_0.viewWidth + arg_5_0.initWidth, arg_5_0.height)
		arg_5_0:runAction(cc.Sequence:create(cc.Spawn:create({
			cc.MoveBy:create(arg_5_0.duration, cc.p(-var_5_0, 0)),
			cc.CallFunc:create(function()
				local var_6_0 = arg_5_0:completeIntoViewTime()

				if var_6_0 ~= 0 then
					var_0_2.performWithDelayGlobal(function()
						if arg_5_0.callback then
							arg_5_0.callback()
						end
					end, var_6_0)
				end
			end)
		}), cc.DelayTime:create(2), cc.CallFunc:create(function()
			arg_5_0.parent:removeChild(arg_5_0)
		end)))
	else
		arg_5_0:setPosition(arg_5_0.viewWidth / 2, arg_5_0.height)
		arg_5_0:setLocalZOrder(999)
		arg_5_0:runAction(cc.Sequence:create(cc.DelayTime:create(var_0_1), cc.CallFunc:create(function()
			if arg_5_0.callback then
				arg_5_0.callback()
			end

			arg_5_0.parent:removeChild(arg_5_0)
		end)))
	end
end

function var_0_0.getSpeed(arg_10_0)
	if arg_10_0.duration ~= 0 then
		arg_10_0.speed = math.ceil(arg_10_0.distance / arg_10_0.duration)
	else
		arg_10_0.speed = 0
	end

	return arg_10_0.speed
end

function var_0_0.completeIntoViewTime(arg_11_0)
	local var_11_0 = arg_11_0:getSpeed()

	if var_11_0 ~= 0 then
		return math.ceil((arg_11_0.labelWidth + arg_11_0.initWidth) / var_11_0)
	else
		return 0
	end
end

return var_0_0
