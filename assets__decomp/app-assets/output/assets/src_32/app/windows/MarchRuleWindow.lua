local var_0_0 = class("NewTextRuleWindow", import("app.common.ui.BaseWindow"))

var_0_0.TITLE = "title_text"
var_0_0.DETAIL_CONTAINER = "rule_container"

local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.ruleStyle
local var_0_3 = 814
local var_0_4 = 547

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.titleName = arg_1_2.title_name
	arg_1_0.rule = arg_1_2.rule
	arg_1_0.style = arg_1_2.style or xyd.RuleStyle.YELLOW

	if arg_1_2.split then
		arg_1_0.split = arg_1_2.split
	end

	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.willClose(arg_4_0)
	if arg_4_0.callback then
		arg_4_0.callback()
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0.container = arg_5_0:nodeByName(var_0_0.DETAIL_CONTAINER)

	local var_5_0 = arg_5_0.container:getContentSize()

	arg_5_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_5_0.container):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0:nodeByName(var_0_0.TITLE):setString(var_0_1:translation(arg_5_0.titleName))
	arg_5_0:initRule()
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 5 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.initRule(arg_7_0)
	local var_7_0

	if not arg_7_0.split then
		var_7_0 = xyd.split(var_0_1:translation(arg_7_0.rule), "\n")
	else
		var_7_0 = xyd.split(var_0_1:translation(arg_7_0.rule), arg_7_0.split)
	end

	for iter_7_0 = 1, #var_7_0 do
		local var_7_1 = display.newNode()
		local var_7_2 = arg_7_0.list:newItem()
		local var_7_3 = display.newNode()
		local var_7_4 = {
			size = 22,
			color = cc.c3b(68, 69, 77),
			dimensions = cc.size(714, 0),
			text = var_7_0[iter_7_0]
		}

		if iter_7_0 == 1 or iter_7_0 == 16 then
			var_7_4.color = cc.c3b(255, 107, 42)
		end

		if iter_7_0 == 15 then
			local var_7_5 = import("app.common.ui.SplitLine").new({
				size = 714,
				align = xyd.SplitLineAlign.CENTER
			})

			var_7_5:addTo(var_7_3)
			var_7_5:setPosition(357, 10)
		end

		local var_7_6 = xyd.AssetLoader.get():loadLabel(var_7_4)

		var_7_6:addTo(var_7_3)
		var_7_6:setAnchorPoint(cc.p(0, 0))
		var_7_6:setPosition(cc.p(0, 0))

		local var_7_7 = var_7_6:getContentSize().height

		var_7_3:setContentSize(714, var_7_7)
		var_7_3:addTo(var_7_1)
		var_7_1:setContentSize(714, var_7_7 + 20)
		var_7_2:addContent(var_7_1)
		var_7_2:setItemSize(714, var_7_7 + 20)
		arg_7_0.list:addItem(var_7_2)
	end

	arg_7_0.list:reload()
end

return var_0_0
