local var_0_0 = class("WoolenRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1

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
		viewRect = cc.rect(0, 0, 550, 428),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("scroll")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)

	arg_3_0.type = arg_3_1

	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.type == var_0_2 then
		arg_4_0:nodeByName("bind_title"):setVisible(true)
		arg_4_0:nodeByName("rule_title"):setVisible(false)
	else
		arg_4_0:nodeByName("rule_title"):setVisible(true)
		arg_4_0:nodeByName("bind_title"):setVisible(false)
	end

	arg_4_0.labels = {}

	arg_4_0:createAllRuleLabels()

	for iter_4_0 = 1, #arg_4_0.labels do
		local var_4_0 = display.newNode()
		local var_4_1 = arg_4_0.list:newItem()
		local var_4_2 = display.newNode()

		arg_4_0.labels[iter_4_0]:addTo(var_4_2)
		arg_4_0.labels[iter_4_0]:setAnchorPoint(cc.p(0, 0))
		arg_4_0.labels[iter_4_0]:setPosition(0, 0)
		var_4_2:setContentSize(550, arg_4_0.labels[iter_4_0]:getContentSize().height)
		var_4_2:addTo(var_4_0)
		var_4_0:setContentSize(550, arg_4_0.labels[iter_4_0]:getContentSize().height + 20)
		var_4_1:addContent(var_4_0)
		var_4_1:setItemSize(550, arg_4_0.labels[iter_4_0]:getContentSize().height + 20)
		arg_4_0.list:addItem(var_4_1)
	end

	arg_4_0.list:reload()
end

function var_0_0.createAllRuleLabels(arg_5_0)
	if arg_5_0.type == var_0_2 then
		for iter_5_0 = 1, 4 do
			arg_5_0.rule = "ACTIVITY_GOOGLE_NOTICE_TEXT" .. iter_5_0

			arg_5_0:createRuleLabel(iter_5_0)
		end
	else
		arg_5_0.rule = "ACTIVITY_GOOGLE_RULE_TEXT"

		arg_5_0:createRuleLabel(0)
	end
end

function var_0_0.createRuleLabel(arg_6_0, arg_6_1)
	local var_6_0 = var_0_1:translation(arg_6_0.rule)
	local var_6_1 = xyd.luaStringSplit(var_6_0, "|")

	for iter_6_0 = 1, #var_6_1 do
		local var_6_2 = {
			size = 24,
			color = cc.c3b(75, 75, 75)
		}

		if arg_6_1 == 1 or arg_6_1 == 3 then
			var_6_2.color = cc.c3b(39, 67, 136)
		end

		local var_6_3 = xyd.AssetLoader.get():loadLabel(var_6_2)

		var_6_3:setMaxLineWidth(550)
		var_6_3:setLineHeight(49)
		var_6_3:setString(var_6_1[iter_6_0])
		table.insert(arg_6_0.labels, var_6_3)
	end
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
