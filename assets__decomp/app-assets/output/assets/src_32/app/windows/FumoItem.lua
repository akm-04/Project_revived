local var_0_0 = class("FumoItem", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/fumo_window/fumo_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	if arg_4_1 == nil then
		return true
	end

	arg_4_0.item_ = arg_4_1

	arg_4_0:contentView():nodeByName("item"):setContentSize(105, 105)
	arg_4_0:contentView():nodeByName("decrease"):setLocalZOrder(100)
	xyd.setItemBorder(arg_4_0:contentView():nodeByName("item"), arg_4_1.itemID, false)
	arg_4_0:updateNums(0)
end

function var_0_0.updateNums(arg_5_0, arg_5_1)
	arg_5_0:contentView():nodeByName("txt_num"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	if arg_5_1 > 0 then
		arg_5_0:contentView():nodeByName("txt_num"):setString(arg_5_1 .. "/" .. arg_5_0.item_.itemNum)
		arg_5_0:contentView():nodeByName("decrease"):setVisible(true)
	else
		arg_5_0:contentView():nodeByName("txt_num"):setString(arg_5_0.item_.itemNum)
		arg_5_0:contentView():nodeByName("decrease"):setVisible(false)
	end
end

function var_0_0.getFumoItem(arg_6_0, arg_6_1)
	return arg_6_0.item_
end

return var_0_0
