local var_0_0 = class("LuckybagGetWayWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.AnniLuckybagTable
local var_0_3 = {
	title = var_0_1:translation("TIP"),
	message = {
		var_0_1:translation("LUCKYBAG_TXT_2"),
		var_0_1:translation("LUCKYBAG_TXT_3"),
		var_0_1:translation("LUCKYBAG_TXT_4")
	},
	get_way_2 = {
		nil,
		var_0_1:translation("LUCKYBAG_TXT_5"),
		var_0_1:translation("LUCKYBAG_TXT_6")
	},
	get_way_1 = {
		nil,
		var_0_1:translation("LUCKYBAG_TXT_7"),
		var_0_1:translation("LUCKYBAG_TXT_8")
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.id = arg_1_2.fudai_id
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setButtonClick()
	arg_4_0:nodeByName("title"):setString(var_0_3.title)
	arg_4_0:nodeByName("get_text"):setString(var_0_3.message[arg_4_0.id])
end

function var_0_0.setButtonClick(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("get_way_btn1")

	var_5_0:getChildByName("txt_1"):setString(var_0_3.get_way_1[arg_5_0.id])
	var_5_0:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.callback(false)
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)

	local var_5_1 = arg_5_0:nodeByName("get_way_btn2")

	var_5_1:getChildByName("txt_2"):setString(var_0_3.get_way_2[arg_5_0.id])
	var_5_1:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.callback(true)
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
end

return var_0_0
