local var_0_0 = class("SuperRichGraphicTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc.activityRichPage

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	if arg_1_2 then
		arg_1_0.text = arg_1_2.text
		arg_1_0.giftId = arg_1_2.giftId
	end

	arg_1_0.onview = 1
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0, ...)
	arg_3_0.container = arg_3_0:nodeByName("container")

	local var_3_0 = arg_3_0.container:getContentSize()

	arg_3_0:updateImg()
	arg_3_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("left_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.onview > 1 then
				arg_4_0.onview = arg_4_0.onview - 1
			elseif arg_4_0.onview == 1 then
				arg_4_0.onview = var_0_2
			end

			arg_4_0:updateImg()
		end
	end)
	arg_4_0:nodeByName("right_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.onview < var_0_2 then
				arg_4_0.onview = arg_4_0.onview + 1
			elseif arg_4_0.onview == var_0_2 then
				arg_4_0.onview = 1
			end

			arg_4_0:updateImg()
		end
	end)
end

function var_0_0.updateImg(arg_7_0)
	if arg_7_0.img then
		arg_7_0.img:removeSelf()
	end

	arg_7_0.img = xyd.AssetLoader.get():loadSprite("windows/zillionaire/tip/img" .. arg_7_0.onview .. ".png")

	arg_7_0.img:setAnchorPoint(cc.p(0.5, 0.5))
	arg_7_0.img:addTo(arg_7_0:nodeByName("img_pos"))
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
end

return var_0_0
