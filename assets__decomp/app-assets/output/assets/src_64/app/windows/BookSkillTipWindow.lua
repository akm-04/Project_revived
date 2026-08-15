local var_0_0 = class("BookSkillTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.cabinetSkillTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.id = arg_1_2.id
	arg_1_0.skillLevel = arg_1_2.lev
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("name_text"):setString(var_0_2:name(arg_3_0.id))

	if arg_3_0.skillLevel > 0 then
		arg_3_0:nodeByName("des_text"):setString(string.format(var_0_2:desc2(arg_3_0.id), var_0_2:attrValues(arg_3_0.id) * arg_3_0.skillLevel))
	else
		arg_3_0:nodeByName("des_text"):setString(var_0_2:desc(arg_3_0.id))
	end

	arg_3_0:nodeByName("container"):width(arg_3_0:nodeByName("des_text"):getContentSize().width + 80)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.willClose(arg_5_0, arg_5_1)
	var_0_0.super:willClose(arg_5_1)
end

return var_0_0
