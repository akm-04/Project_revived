local var_0_0 = class("SignInItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/sign_in_window/sign_in_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:contentView():nodeByName("cover"):setVisible(false)
		arg_3_0:contentView():nodeByName("is_signed"):setVisible(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	if arg_4_1.double_vip_lv < 0 then
		arg_4_0:contentView():nodeByName("vip_bg"):setVisible(false)
	else
		arg_4_0:contentView():nodeByName("vip_bg"):setVisible(true)
		arg_4_0:contentView():nodeByName("vip_num_txt"):setString("V" .. arg_4_1.double_vip_lv)
		arg_4_0:contentView():nodeByName("double_text"):setString(var_0_1:translation("SIGN_IN_DOUBLE_TEXT"))
		arg_4_0:contentView():nodeByName("vip_num_txt"):enableOutline(cc.c4b(243, 40, 70, 255), 1)
		arg_4_0:contentView():nodeByName("double_text"):enableOutline(cc.c4b(243, 40, 70, 255), 1)
		arg_4_0:contentView():nodeByName("double_text"):getVirtualRenderer():setAdditionalKerning(2)
		arg_4_0:contentView():nodeByName("vip_num_txt"):getVirtualRenderer():setAdditionalKerning(2)
	end

	local var_4_0 = xyd.split(var_0_1:translation("SIGN_IN_DAY_TRANSPOSE"), ":")
	local var_4_1 = string.format(var_0_1:translation("SIGN_IN_DAY_INDEX_TEXT"), var_4_0[arg_4_1.dayIdx])

	arg_4_0:contentView():nodeByName("day_txt"):setString(var_4_1)
	arg_4_0:contentView():nodeByName("num_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 2)

	if arg_4_1.award_item_id > 0 then
		xyd.setItemBorder(arg_4_0:contentView():nodeByName("item"), arg_4_1.award_item_id)
		arg_4_0:contentView():nodeByName("num_txt"):setString(arg_4_1.award_item_num)
	elseif arg_4_1.award_crystal and arg_4_1.award_crystal > 0 then
		xyd.setItemBorder(arg_4_0:contentView():nodeByName("item"), -1)
		arg_4_0:contentView():nodeByName("num_txt"):setString(arg_4_1.award_crystal)
	end
end

function var_0_0.setBg(arg_5_0, arg_5_1)
	if arg_5_1 ~= 2 then
		arg_5_0:contentView():nodeByName("cover"):setVisible(false)
		arg_5_0:contentView():nodeByName("is_signed"):setVisible(false)
	else
		arg_5_0:contentView():nodeByName("cover"):setVisible(true)
		arg_5_0:contentView():nodeByName("is_signed"):setVisible(true)
	end
end

return var_0_0
