local var_0_0 = class("WhiteAlbumAttrTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.attr

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.attrTxt = {
		1,
		1,
		1,
		2,
		1,
		1,
		1,
		1,
		1,
		1,
		3,
		4,
		2,
		1,
		1,
		1,
		1,
		4,
		3,
		4,
		4,
		2,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		2,
		1,
		2,
		4,
		1,
		4,
		1,
		1
	}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("attr_txt"):setString(var_0_2:name(arg_2_0.params.attr))
	arg_2_0:nodeByName("attr_num"):setString("+" .. arg_2_0.params.num)
	arg_2_0:nodeByName("attr_type"):setString(var_0_1:translation("WHITE_ALBUM_TIP" .. arg_2_0.attrTxt[arg_2_0.params.attr]))
end

return var_0_0
