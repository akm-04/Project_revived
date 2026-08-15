local var_0_0 = class("BroadcastWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.text = arg_1_2.text
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = {
		text = arg_3_0.text
	}

	arg_3_0:updateText(var_3_0)

	topNode = cc.Node:create()

	topNode:setContentSize(arg_3_0:nodeByName("top_word_bg"):getContentSize())
	topNode:addTo(arg_3_0)
	topNode:setAnchorPoint(cc.p(0, 0))
	topNode:setPosition(arg_3_0:nodeByName("top_word_bg"):getPosition())
	topNode:setTouchEnabled(true)
	topNode:setGlobalZOrder(99)
	topNode:setTouchSwallowEnabled(false)
	topNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.updateText(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.text or ""

	arg_5_0:nodeByName("top_text"):setString("")

	if arg_5_0:nodeByName("top_word_bg"):getChildByName("top_node") then
		arg_5_0:nodeByName("top_word_bg"):removeChildByName("top_node")
	end

	local var_5_1 = xyd.createMultiColorTxt(var_5_0, xyd.color.WHITE, 24, true)

	arg_5_0:nodeByName("top_word_bg"):addChild(var_5_1)
	var_5_1:setAnchorPoint(0.5, 0.5)
	var_5_1:setPosition(arg_5_0:nodeByName("top_text"):getPosition())
	var_5_1:setName("top_node")
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
end

return var_0_0
