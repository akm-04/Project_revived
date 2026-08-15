local var_0_0 = class("BackpackItem", function()
	return cc.Node:create()
end)

var_0_0.IMG_ICON = "img_icon"
var_0_0.NUM_TXT = "num_txt"

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/backpack_window/item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	arg_4_0.params = arg_4_1
	arg_4_0.iconImg = arg_4_0:contentView():nodeByName(var_0_0.IMG_ICON)

	arg_4_0.iconImg:removeAllChildren()
	xyd.setItemBorder(arg_4_0.iconImg, arg_4_0.params.itemID, false, false, arg_4_0.params.itemNum)
end

return var_0_0
