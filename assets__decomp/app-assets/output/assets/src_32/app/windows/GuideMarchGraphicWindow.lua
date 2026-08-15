local var_0_0 = class("GuideMarchGraphicWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	if arg_1_2 then
		arg_1_0.callback = arg_1_2.callback
		arg_1_0.pageNum = arg_1_2.pageNum
		arg_1_0.nowPage = arg_1_2.nowPage
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("title"):setVisible(false)

	arg_2_0.pageNum = arg_2_0.pageNum or 1
	arg_2_0.nowPage = arg_2_1.nowPage or 1

	dump(arg_2_0.nowPage)
	arg_2_0:updateImg()

	local var_2_0 = arg_2_0:nodeByName("left_btn")

	var_2_0:setVisible(arg_2_0.pageNum ~= 1)
	var_2_0:addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(var_2_0, arg_3_1)

		if arg_3_1 == ccui.TouchEventType.ended then
			arg_2_0.nowPage = (arg_2_0.nowPage - 2 + arg_2_0.pageNum) % arg_2_0.pageNum + 1

			arg_2_0:updateImg()
		end
	end)

	local var_2_1 = arg_2_0:nodeByName("right_btn")

	var_2_1:setVisible(arg_2_0.pageNum ~= 1)
	var_2_1:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(var_2_1, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_2_0.nowPage = arg_2_0.nowPage % arg_2_0.pageNum + 1

			arg_2_0:updateImg()
		end
	end)
end

function var_0_0.updateImg(arg_5_0)
	if arg_5_0.img then
		arg_5_0.img:removeSelf()
	end

	dump(arg_5_0.nowPage)

	arg_5_0.img = xyd.AssetLoader.get():loadSprite("windows/march/graphic/img" .. arg_5_0.nowPage .. ".png")

	arg_5_0.img:setScale(0.88)
	arg_5_0.img:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.img:addTo(arg_5_0:nodeByName("img"))
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	arg_6_0:addBlockLayer()
end

function var_0_0.didClose(arg_7_0, arg_7_1)
	if arg_7_0.callback then
		arg_7_0.callback()
	end
end

return var_0_0
