local var_0_0 = class("GuideTalk", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0:contentView(arg_2_1)
end

function var_0_0.contentView(arg_3_0, arg_3_1)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		if arg_3_1 then
			arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/guide_window/guide_talk_left.csb"))
		else
			arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/guide_window/guide_talk_right.csb"))
		end

		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)

		local var_3_0 = xyd.AssetLoader:get():loadSprite("windows/guide_window/guide_clip.png")

		var_3_0:setAnchorPoint(0.5, 1)
		var_3_0:setPosition(0, -120)

		local var_3_1 = cc.ClippingNode:create()

		var_3_1:setStencil(var_3_0)
		var_3_1:setInverted(true)
		var_3_1:setAlphaThreshold(0)
		arg_3_0.contentView_:nodeByName("card_pos"):addChild(var_3_1)

		local var_3_2 = 10001001
		local var_3_3 = xyd.tables.skinDynamic:path(var_3_2)
		local var_3_4 = xyd.tables.misc:getValue("guide_scailing")
		local var_3_5 = xyd.tables.misc:getValue("guide_location")

		xyd.EffectLoader.new(var_3_3, 5, var_3_4, {
			x = var_3_5[1],
			y = var_3_5[2]
		}):addTo(var_3_1)
	end

	return arg_3_0.contentView_
end

function var_0_0.setString(arg_4_0, arg_4_1)
	local var_4_0 = {
		size = 20,
		color = cc.c3b(187, 93, 41)
	}
	local var_4_1 = xyd.AssetLoader:get():loadLabel(var_4_0)

	var_4_1:setMaxLineWidth(334)

	if string.find(arg_4_1, "\n") then
		var_4_1:setPosition(0, arg_4_0.contentView_:nodeByName("talk_list"):getContentSize().height)
	else
		var_4_1:setPosition(0, arg_4_0.contentView_:nodeByName("talk_list"):getContentSize().height * 4 / 5)
	end

	var_4_1:setAnchorPoint(cc.p(0, 0.5))
	arg_4_0.contentView_:nodeByName("talk_list"):removeAllChildren()
	arg_4_0.contentView_:nodeByName("talk_list"):addChild(var_4_1)
	var_4_1:setString(arg_4_1)
	var_4_1:setPositionY(arg_4_0.contentView_:nodeByName("talk_list"):getContentSize().height / 2)
end

return var_0_0
