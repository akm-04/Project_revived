local var_0_0 = class("ItemDetailTitle", function()
	return cc.Node:create()
end)

var_0_0.TITLE_NAME = "title_name"

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.titleName = arg_3_1.titleName

	arg_3_0:layout()
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.contentView_:nodeByName(var_0_0.TITLE_NAME):setString(arg_4_0.titleName)
end

function var_0_0.contentView(arg_5_0)
	if arg_5_0.contentView_ == nil then
		arg_5_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_5_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/backpack_window/item_detail_title.csb"))
		arg_5_0.contentView_:nodeByName("title_name"):setString(xyd.tables.translation:translation("ITEM_DETAIL_CAN_COMPOSE"))
		arg_5_0.contentView_:addTo(arg_5_0)
		arg_5_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_5_0.contentView_
end

return var_0_0
