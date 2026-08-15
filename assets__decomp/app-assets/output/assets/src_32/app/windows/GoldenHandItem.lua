local var_0_0 = class("GoldenHandItem", function()
	return cc.Node:create()
end)

var_0_0.COST = "text_diamond_use"
var_0_0.GAIN = "text_coin_gain_num"
var_0_0.CRIT = "text_crit"

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.cost = arg_3_1.cost
	arg_3_0.gain = arg_3_1.gain
	arg_3_0.crit = arg_3_1.crit

	arg_3_0:layout()
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.contentView_:nodeByName("text_use"):setString(xyd.tables.translation:translation("BACKPACK_USE"))
	arg_4_0.contentView_:nodeByName("text_get"):setString(xyd.tables.translation:translation("WILL_GET"))
	arg_4_0.contentView_:nodeByName(var_0_0.COST):setString(arg_4_0.cost)
	arg_4_0.contentView_:nodeByName(var_0_0.GAIN):setString(arg_4_0.gain)

	if arg_4_0.crit == 1 then
		arg_4_0.contentView_:nodeByName(var_0_0.CRIT):setString("")
	else
		arg_4_0.contentView_:nodeByName(var_0_0.CRIT):setString(xyd.tables.translation:translation("CRIT_X") .. arg_4_0.crit)
	end
end

function var_0_0.contentView(arg_5_0)
	if arg_5_0.contentView_ == nil then
		arg_5_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_5_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/golden_hand_window/goldenhanditem.csb"))
		arg_5_0.contentView_:addTo(arg_5_0)
		arg_5_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_5_0.contentView_
end

return var_0_0
