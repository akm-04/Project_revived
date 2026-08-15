local var_0_0 = class("TipsLayer", function()
	return display.newNode()
end)
local var_0_1 = 18
local var_0_2 = 20

function var_0_0.ctor(arg_2_0)
	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/tips.json")

	var_2_0:setPosition(cc.p(0, 0))
	arg_2_0:addChild(var_2_0)

	arg_2_0.bg_ = var_2_0:getChildByName("background")
	arg_2_0.titleLabel_ = arg_2_0.bg_:getChildByName("Label_name")
	arg_2_0.descLayer_ = arg_2_0.bg_:getChildByName("desc_layer")
	arg_2_0.DEFAULT_HEIGHT = arg_2_0.bg_:getContentSize().height
	arg_2_0.DEFAULT_DESC_LAYER_HEIGHT = arg_2_0.descLayer_:getContentSize().height

	arg_2_0:setContentSize(arg_2_0.bg_:getContentSize())
	xyd.formatAllLabels(arg_2_0, function(arg_3_0)
		arg_3_0:enableShadow()
	end)
end

function var_0_0.setTitle(arg_4_0, arg_4_1)
	arg_4_0.titleLabel_:setString(arg_4_1)
end

function var_0_0.clearAllDescText(arg_5_0)
	arg_5_0.descLayer_:removeAllChildren()
	arg_5_0.descLayer_:setContentSize(cc.size(arg_5_0.descLayer_:getContentSize().width, arg_5_0.DEFAULT_DESC_LAYER_HEIGHT))
	arg_5_0.bg_:setContentSize(cc.size(arg_5_0.bg_:getContentSize().width, arg_5_0.DEFAULT_HEIGHT))
	arg_5_0:setContentSize(arg_5_0.bg_:getContentSize())
end

function var_0_0.addDescText(arg_6_0, arg_6_1)
	local var_6_0 = xyd.AssetLoader.get():loadLabel({
		text = arg_6_1,
		size = var_0_2,
		color = xyd.color.FONT_A
	})

	var_6_0:enableShadow(xyd.color.FONT_SHADOW_A)
	var_6_0:setWidth(arg_6_0.descLayer_:getContentSize().width)
	var_6_0:setLineBreakWithoutSpace(true)
	var_6_0:setAnchorPoint(cc.p(0, 0))
	var_6_0:setPosition(cc.p(0, arg_6_0.descLayer_:getContentSize().height))
	arg_6_0.descLayer_:addChild(var_6_0)

	local var_6_1 = arg_6_0.descLayer_:getContentSize().height
	local var_6_2 = var_6_1 + var_6_0:getContentSize().height

	arg_6_0.descLayer_:setContentSize(cc.size(arg_6_0.descLayer_:getContentSize().width, var_6_2))

	local var_6_3 = arg_6_0.bg_:getContentSize().height - var_6_1 + var_6_2

	arg_6_0.bg_:setContentSize(cc.size(arg_6_0.bg_:getContentSize().width, var_6_3))
	arg_6_0:setContentSize(arg_6_0.bg_:getContentSize())
end

function var_0_0.setWidth(arg_7_0, arg_7_1)
	arg_7_0.bg_:setContentSize(cc.size(arg_7_1, arg_7_0.bg_:getContentSize().height))

	local var_7_0 = arg_7_1 - var_0_1 * 2

	arg_7_0.descLayer_:setContentSize(cc.size(var_7_0, arg_7_0.descLayer_:getContentSize().height))
	arg_7_0:setContentSize(arg_7_0.bg_:getContentSize())
end

return var_0_0
