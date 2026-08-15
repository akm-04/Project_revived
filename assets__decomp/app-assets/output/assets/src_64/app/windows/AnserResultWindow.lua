local var_0_0 = class("AnserResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.result = arg_1_2.result
	arg_1_0.kite = arg_1_2.kite
	arg_1_0.ans_id = arg_1_2.ans_id
	arg_1_0.crystal = arg_1_2.crystal
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = var_0_1:translation("ANSER_RIGHT")

	if arg_2_0.result ~= true then
		var_2_0 = string.format(var_0_1:translation("ANSER_FALSE"), xyd.tables.activityKiteQuestion:name(arg_2_0.ans_id))
	end

	arg_2_0:nodeByName("result_txt"):setString(var_2_0)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 225))
end

function var_0_0.didClose(arg_4_0)
	local var_4_0 = {
		crystal = arg_4_0.crystal,
		kite = arg_4_0.kite
	}

	wnd = xyd.WindowManager.get():openWindow("grab_kite_result", var_4_0)

	wnd:nodeByName("close_kite_type" .. arg_4_0.kite.id):setVisible(false)
	wnd:playAward()
end

return var_0_0
