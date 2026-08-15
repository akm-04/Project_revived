local var_0_0 = class("ThrowSandbagGuideWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 2
local var_0_3 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.throwSandbag = xyd.ModelManager.get():loadModel(xyd.ModelType.THROW_SANDBAG)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("btn_1"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0:updatePic(-1)
		end
	end)
	arg_3_0:nodeByName("btn_2"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0:updatePic(1)
		end
	end)

	arg_3_0.picIndex = 0

	arg_3_0:updatePic(1)
end

function var_0_0.updatePic(arg_6_0, arg_6_1)
	for iter_6_0 = 1, 3 do
		arg_6_0:nodeByName("pic_" .. iter_6_0):setVisible(false)
		arg_6_0:nodeByName("tag_" .. iter_6_0 .. "_2"):setVisible(true)
	end

	arg_6_0.picIndex = arg_6_0.picIndex + arg_6_1

	arg_6_0:nodeByName("btn_1"):setVisible(arg_6_0.picIndex ~= 1)
	arg_6_0:nodeByName("btn_2"):setVisible(arg_6_0.picIndex ~= 3)
	arg_6_0:nodeByName("pic_" .. arg_6_0.picIndex):setVisible(true)
	arg_6_0:nodeByName("tag_" .. arg_6_0.picIndex .. "_2"):setVisible(false)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
