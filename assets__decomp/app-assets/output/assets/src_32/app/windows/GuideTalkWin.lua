local var_0_0 = class("GuideTalkWin", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0:contentView(arg_2_1)
end

function var_0_0.contentView(arg_3_0, arg_3_1)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		if arg_3_1 then
			arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/guide_window_win/guide_talk_left.csb"))
		else
			arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/guide_window_win/guide_talk_right.csb"))
		end

		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
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
	var_4_1:setPosition(15, arg_4_0.contentView_:nodeByName("talk_list"):getContentSize().height)
	var_4_1:setAnchorPoint(cc.p(0, 1))
	arg_4_0.contentView_:nodeByName("talk_list"):removeAllChildren()
	arg_4_0.contentView_:nodeByName("talk_list"):addChild(var_4_1)
	var_4_1:setString(arg_4_1)
end

return var_0_0
