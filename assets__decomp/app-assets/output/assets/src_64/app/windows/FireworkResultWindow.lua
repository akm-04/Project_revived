local var_0_0 = class("FireworkResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityFireworkType
local var_0_3 = {
	"firework_red",
	"firework_yellow",
	"firework_color"
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.isSucc = arg_1_2.isSucc or false
	arg_1_0.fireType = arg_1_2.fireType or 1
	arg_1_0.shotTicket = var_0_2:shotTicket(arg_1_0.fireType)
	arg_1_0.fireworkName = var_0_2:name(arg_1_0.fireType)
	arg_1_0.sendName = arg_1_2.sendName or ""
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("container"):setVisible(false)
	arg_2_0:nodeByName("success"):setVisible(false)
	arg_2_0:nodeByName("failure"):setVisible(false)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:showAnimation()
end

function var_0_0.addBlockLayer(arg_4_0)
	arg_4_0.blockBlackLayer = display.newColorLayer(cc.c4b(0, 0, 0, 200))

	local var_4_0 = arg_4_0:convertToWorldSpace(cc.p(0, 0))

	arg_4_0.blockBlackLayer:pos(-var_4_0.x, -var_4_0.y):addTo(arg_4_0, -1)
	arg_4_0.blockBlackLayer:setVisible(false)
	arg_4_0:addBlockLayerClickClose(cc.c4b(255, 255, 255, 255), nil, nil, 10)
end

function var_0_0.layout(arg_5_0)
	if arg_5_0.isSucc then
		arg_5_0:nodeByName("success"):setVisible(true)

		local var_5_0 = cc.p(arg_5_0:nodeByName("node_img_1"):getPosition())
		local var_5_1 = xyd.AssetLoader.get():loadSprite("windows/firework/firework_result/" .. var_0_3[arg_5_0.fireType] .. ".png")

		if var_5_1 then
			var_5_1:addTo(arg_5_0:nodeByName("success"))
			var_5_1:setPosition(cc.p(var_5_0))
			var_5_1:setLocalZOrder(-1)
		end

		arg_5_0:nodeByName("text_top_1"):setString(var_0_1:translation("FIREWORK_TEXT_7"))
		arg_5_0:nodeByName("text_bottom_1"):setString(var_0_1:translation("FIREWORK_TEXT_8"))
		arg_5_0:nodeByName("text_award_num"):setString("x" .. arg_5_0.shotTicket)
		arg_5_0:nodeByName("text_mid_1"):setString(arg_5_0.sendName .. "·" .. arg_5_0.fireworkName)
	else
		arg_5_0:nodeByName("failure"):setVisible(true)
		arg_5_0:nodeByName("text_top_2"):setString(var_0_1:translation("FIREWORK_TEXT_12"))
		arg_5_0:nodeByName("text_bottom_2"):setString(var_0_1:translation("FIREWORK_TEXT_13"))
	end
end

function var_0_0.willClose(arg_6_0)
	if arg_6_0.callback then
		arg_6_0.callback()
	end
end

function var_0_0.showAnimation(arg_7_0)
	local var_7_0 = {}
	local var_7_1 = 0.1

	arg_7_0.blockLayer_:setOpacity(0)
	arg_7_0.blockLayer_:setTouchEnabled(false)
	arg_7_0.blockLayer_:setCascadeOpacityEnabled(true)
	table.insert(var_7_0, cc.FadeIn:create(var_7_1))
	table.insert(var_7_0, cc.FadeOut:create(var_7_1))
	table.insert(var_7_0, cc.CallFunc:create(function()
		arg_7_0:nodeByName("container"):setVisible(true)
		arg_7_0.blockBlackLayer:setVisible(true)
		arg_7_0.blockLayer_:setTouchEnabled(true)
	end))
	arg_7_0.blockLayer_:runAction(transition.sequence(var_7_0))
end

return var_0_0
