local var_0_0 = class("AvatarTypeTitle", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.title = arg_3_1.title
	arg_3_0.tip = arg_3_1.tip

	arg_3_0:layout()
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:contentView():nodeByName("touxiang_type_txt"):setString(arg_4_0.title)

	if arg_4_0.tip then
		arg_4_0:contentView():nodeByName("tip_text"):setString(arg_4_0.tip)
		arg_4_0:contentView():nodeByName("tip_text"):setVisible(true)
		arg_4_0:contentView():nodeByName("tip_text"):setPosition(arg_4_0:contentView():nodeByName("tip_text"):getX(), arg_4_0:contentView():nodeByName("tip_text"):getY() - 30)
	end

	local var_4_0 = (arg_4_0:contentView():nodeByName("touxiang_type_txt"):getWidth() - 120) / 2

	arg_4_0:contentView():nodeByName("left_hua"):setPosition(arg_4_0:contentView():nodeByName("left_hua"):getX() - var_4_0, arg_4_0:contentView():nodeByName("left_hua"):getY())
	arg_4_0:contentView():nodeByName("right_hua"):setPosition(arg_4_0:contentView():nodeByName("right_hua"):getX() + var_4_0, arg_4_0:contentView():nodeByName("right_hua"):getY())
end

function var_0_0.contentView(arg_5_0)
	if arg_5_0.contentView_ == nil then
		arg_5_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_5_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/playerwindow/touxiang_title.csb"))
		arg_5_0.contentView_:addTo(arg_5_0)
		arg_5_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_5_0.contentView_
end

return var_0_0
