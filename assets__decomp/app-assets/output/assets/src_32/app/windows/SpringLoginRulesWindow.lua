local var_0_0 = class("SpringLoginRulesWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

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

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, 670, 360),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("container")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	local var_3_0 = {
		color = cc.c3b(255, 255, 255)
	}

	var_3_0.size = 24

	local var_3_1 = arg_3_0:nodeByName("title")
	local var_3_2 = xyd.AssetLoader.get():loadLabel(var_3_0)

	var_3_2:setString(var_0_2:translation("SPRINGLOGIN_RULE_TITLE"))
	var_3_2:setMaxLineWidth(280)
	var_3_2:addTo(var_3_1)
	var_3_2:setAnchorPoint(cc.p(0, 0))
	var_3_2:setPosition(-46, -12)
	var_3_2:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.height_table = {}

	local var_4_0 = arg_4_0:createRuleLabel()

	for iter_4_0 = 1, #var_4_0 do
		local var_4_1 = display.newNode()
		local var_4_2 = arg_4_0.list:newItem()
		local var_4_3 = display.newNode()

		var_4_0[iter_4_0]:addTo(var_4_3)
		var_4_0[iter_4_0]:setAnchorPoint(cc.p(0, 0))
		var_4_0[iter_4_0]:setPosition(0, 0)
		var_4_3:setContentSize(670, var_4_0[iter_4_0]:getContentSize().height)
		var_4_3:addTo(var_4_1)
		var_4_1:setContentSize(670, arg_4_0.height_table[iter_4_0] * 49)
		var_4_2:addContent(var_4_1)
		var_4_2:setItemSize(670, arg_4_0.height_table[iter_4_0] * 49)
		arg_4_0.list:addItem(var_4_2)
	end

	arg_4_0.list:reload()
end

function var_0_0.createRuleLabel(arg_5_0)
	local var_5_0 = var_0_2:translation("SPRINGLOGIN_RULE_TEXT")
	local var_5_1 = xyd.luaStringSplit(var_5_0, "@")
	local var_5_2 = {}

	for iter_5_0 = 1, #var_5_1 do
		local var_5_3 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_5_4 = xyd.AssetLoader.get():loadLabel(var_5_3)

		var_5_4:setMaxLineWidth(670)
		var_5_4:setLineHeight(49)
		var_5_4:setString(var_5_1[iter_5_0])

		arg_5_0.height_table[iter_5_0] = var_5_4:getStringNumLines()

		table.insert(var_5_2, var_5_4)
	end

	return var_5_2
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
