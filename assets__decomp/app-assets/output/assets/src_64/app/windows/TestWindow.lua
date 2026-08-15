local var_0_0 = class("TestWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:addTopSidebar()

	arg_2_0.hideNpc = xyd.AssetLoader.get():loadSprite("windows/test/hide_npc.png")

	local var_2_0 = display.newNode()

	var_2_0:size(1280, 720)

	arg_2_0.jjClipper = cc.ClippingNode:create()

	arg_2_0.jjClipper:setInverted(false)
	arg_2_0.jjClipper:setAlphaThreshold(0.4)
	arg_2_0.jjClipper:setStencil(var_2_0)

	arg_2_0.jjNode = xyd.AssetLoader.get():loadSprite("windows/test/jj.png")

	arg_2_0.jjNode:setVisible(false)
	arg_2_0.jjNode:setAnchorPoint(0.5, 0.5)
	arg_2_0.jjNode:addTo(var_2_0)
	arg_2_0.jjNode:setScale(3)
	arg_2_0.hideNpc:setAnchorPoint(0.5, 0)
	arg_2_0.hideNpc:pos(640, 0)
	arg_2_0.hideNpc:addTo(arg_2_0.jjClipper)
	arg_2_0.jjClipper:addTo(arg_2_0)

	local var_2_1 = cc.Director:getInstance():getVisibleSize()

	arg_2_0.layer = display.newNode()

	arg_2_0.layer:size(1280, 660)
	arg_2_0.layer:pos(0, 0)
	arg_2_0.layer:addTo(arg_2_0)
	arg_2_0.layer:setTouchEnabled(true)
	arg_2_0.layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
		if arg_3_0.name == "began" then
			arg_2_0.jjNode:setVisible(true)
			arg_2_0.jjNode:pos(arg_3_0.x - 0.5 * (var_2_1.width - xyd.STAGE_WIDTH), arg_3_0.y - 0.5 * (var_2_1.height - xyd.STAGE_HEIGHT))

			return true
		elseif arg_3_0.name == "moved" then
			arg_2_0.jjNode:pos(arg_3_0.x - 0.5 * (var_2_1.width - xyd.STAGE_WIDTH), arg_3_0.y - 0.5 * (var_2_1.height - xyd.STAGE_HEIGHT))
		elseif arg_3_0.name == "ended" then
			arg_2_0.jjNode:setVisible(false)
		end
	end)
end

return var_0_0
