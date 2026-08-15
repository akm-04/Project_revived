local var_0_0 = class("NewAvatarTypeTitle", function()
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
	arg_4_0:contentView():nodeByName("txt_type"):setString(arg_4_0.title)

	if arg_4_0.tip then
		arg_4_0:contentView():nodeByName("txt_tip"):setString(arg_4_0.tip)
		arg_4_0:contentView():nodeByName("txt_tip"):setVisible(true)
		arg_4_0:contentView():nodeByName("txt_tip"):setPosition(arg_4_0:contentView():nodeByName("txt_tip"):getX(), arg_4_0:contentView():nodeByName("txt_tip"):getY() - 30)
	end

	local var_4_0 = arg_4_0:contentView():nodeByName("container"):getWidth()
	local var_4_1 = arg_4_0:contentView():nodeByName("txt_type"):getWidth() / 2
	local var_4_2, var_4_3 = arg_4_0:contentView():nodeByName("txt_type"):getPosition()
	local var_4_4 = {
		size = var_4_2 - var_4_1,
		align = xyd.SplitLineAlign.RIGHT
	}
	local var_4_5 = import("app.common.ui.SplitLine").new(var_4_4)

	var_4_4.size = var_4_0 - var_4_2 - var_4_1
	var_4_4.align = xyd.SplitLineAlign.LEFT

	local var_4_6 = import("app.common.ui.SplitLine").new(var_4_4)

	arg_4_0:contentView():addChild(var_4_5)
	arg_4_0:contentView():addChild(var_4_6)
	var_4_5:setPosition(var_4_2 - var_4_1, var_4_3)
	var_4_6:setPosition(var_4_2 + var_4_1, var_4_3)
end

function var_0_0.contentView(arg_5_0)
	if arg_5_0.contentView_ == nil then
		arg_5_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_5_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/playerwindow/banner_title.csb"))
		arg_5_0.contentView_:addTo(arg_5_0)
		arg_5_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_5_0.contentView_
end

return var_0_0
