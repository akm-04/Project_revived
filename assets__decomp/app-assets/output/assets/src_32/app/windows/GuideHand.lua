local var_0_0 = class("GuideHand", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0:contentView(arg_2_1)
end

function var_0_0.contentView(arg_3_0, arg_3_1)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/guide_window/guide_hand.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0.contentView_:nodeByName("circle"):setVisible(false)
		arg_3_0.contentView_:nodeByName("rect"):setVisible(false)

		local var_3_0 = 1.5
		local var_3_1 = 1.5

		if arg_3_1 and arg_3_1.rect then
			arg_3_0.border = arg_3_0.contentView_:nodeByName("rect")

			arg_3_0.border:setContentSize(arg_3_1.width, arg_3_1.height)

			var_3_0 = (arg_3_1.width + 50) / arg_3_1.width
			var_3_1 = (arg_3_1.height + 50) / arg_3_1.height
		else
			arg_3_0.border = arg_3_0.contentView_:nodeByName("circle")
		end

		arg_3_0.border:setVisible(true)

		local var_3_2 = transition.sequence({
			cc.ScaleTo:create(1, var_3_0, var_3_1),
			cc.ScaleTo:create(1, 1)
		})
		local var_3_3 = cc.RepeatForever:create(var_3_2)

		arg_3_0.border:runAction(var_3_3)

		local var_3_4, var_3_5 = arg_3_0.contentView_:nodeByName("hand"):getPosition()
		local var_3_6 = transition.sequence({
			cc.MoveTo:create(1, cc.p(var_3_4 + 30, var_3_5 - 30)),
			cc.MoveTo:create(1, cc.p(var_3_4, var_3_5))
		})
		local var_3_7 = cc.RepeatForever:create(var_3_6)

		arg_3_0.contentView_:nodeByName("hand"):runAction(var_3_7)
	end

	return arg_3_0.contentView_
end

function var_0_0.setText(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/function/function_open.csb")

	arg_4_0.contentView_:addChild(var_4_0)
	var_4_0:setPosition(cc.p(arg_4_2))

	local var_4_1 = var_4_0:getChildByName("tip_container")
	local var_4_2 = var_4_1:getContentSize()
	local var_4_3 = var_4_1:getChildByName("text_open")

	var_4_3:setString(arg_4_1)

	local var_4_4 = var_4_3:getContentSize()

	if var_4_4.width > var_4_2.width - 60 then
		local var_4_5 = var_4_4.width - var_4_2.width + 60

		var_4_1:setContentSize(var_4_5 + var_4_2.width, var_4_2.height)

		local var_4_6 = var_4_1:getChildByName("bg"):getContentSize()

		var_4_1:getChildByName("bg"):setContentSize(var_4_6.width + var_4_5, var_4_6.height)
	end

	local var_4_7 = var_4_1:getChildByName("tip_arrow")

	if arg_4_3 and arg_4_3 ~= 0 then
		local var_4_8 = cc.p(var_4_7:getPosition())

		var_4_7:setPosition(cc.p(var_4_8.x + arg_4_3, var_4_8.y))
	end

	if arg_4_4 and arg_4_4 ~= 0 then
		var_4_7:setSkewY(arg_4_4)
	end
end

return var_0_0
