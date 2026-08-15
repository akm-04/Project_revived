local var_0_0 = class("VipRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 10 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	local var_3_0 = arg_3_0:nodeByName("scroll"):getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(5, 5, var_3_0.width - 5, var_3_0.height - 5),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("scroll")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(false)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	local var_4_0
	local var_4_1 = arg_4_0.list:dequeueItem()

	if not var_4_1 then
		var_4_1 = arg_4_0.list:newItem()
	else
		var_4_1:removeAllChildren(true)
	end

	local var_4_2 = arg_4_0:createRuleContent()
	local var_4_3 = var_4_2:getWidth()
	local var_4_4 = var_4_2:getHeight()

	var_4_1:setItemSize(var_4_3, var_4_4)
	var_4_1:addContent(var_4_2)
	arg_4_0.list:addItem(var_4_1)
	arg_4_0.list:reload()
end

function var_0_0.createRuleContent(arg_5_0)
	local var_5_0 = display.newNode()
	local var_5_1 = "windows/vipwindow/rule_txt_img.png"
	local var_5_2 = xyd.AssetLoader:get():loadSprite(var_5_1)

	var_5_2:addTo(var_5_0)
	var_5_2:setAnchorPoint(cc.p(0, 0))
	var_5_0:setContentSize(var_5_2:getContentSize())
	var_5_2:setName("ruleImg")

	return var_5_0
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
