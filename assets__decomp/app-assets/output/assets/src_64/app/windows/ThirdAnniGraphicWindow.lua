local var_0_0 = class("ThirdAnniGraphicWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("title"):setString(var_0_1:translation("ACTIVITY_THIRD_TITLE"))

	arg_2_0.pageNum = xyd.tables.misc:getValue("activity_anniversary_page")
	arg_2_0.nowPage = 1

	arg_2_0:updateImg()
	arg_2_0:nodeByName("left_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			arg_2_0.nowPage = (arg_2_0.nowPage - 2 + arg_2_0.pageNum) % arg_2_0.pageNum + 1

			arg_2_0:updateImg()
		end
	end)
	arg_2_0:nodeByName("right_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
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

	arg_5_0.img = xyd.AssetLoader.get():loadSprite("windows/anniversary3rd/graphic/img" .. arg_5_0.nowPage .. ".png")

	arg_5_0.img:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.img:addTo(arg_5_0:nodeByName("img"))
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
