local var_0_0 = class("ActivityWufuAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.activityWufu
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.idx = arg_1_2.idx
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setTexts()
	arg_3_0:setBtns()

	local var_3_0 = import("app.common.ui.SplitLine")
	local var_3_1 = arg_3_0:nodeByName("line")

	var_3_0.new({
		size = var_3_1:getWidth()
	}):addTo(var_3_1)

	local var_3_2 = var_0_2:gift(arg_3_0.idx)
	local var_3_3 = xyd.tables.gift:items(var_3_2)
	local var_3_4 = xyd.tables.gift:itemNum(var_3_2)
	local var_3_5 = 80

	for iter_3_0 = 1, #var_3_3 do
		local var_3_6 = display.newNode()

		var_3_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_6:setContentSize(var_3_5, var_3_5)
		xyd.setItemAndAddTips(var_3_6, var_3_3[iter_3_0], var_3_4[iter_3_0])
		var_3_6:addTo(arg_3_0:nodeByName("node_award"))
		var_3_6:setPositionX(140 * (iter_3_0 - #var_3_3 / 2 - 0.5))
	end
end

function var_0_0.setTexts(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_2:name(arg_4_0.idx))
	arg_4_0:nodeByName("text_tip"):setString(var_0_3:translation("ACTIVITY_WUFU_TEXT_3"))
	arg_4_0:nodeByName("text_ok"):setString(var_0_3:translation("OK"))
end

function var_0_0.setBtns(arg_5_0)
	arg_5_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playCloseSound()
			arg_5_0:close()
		end
	end)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
