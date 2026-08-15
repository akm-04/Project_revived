local var_0_0 = class("SuperRichRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	if arg_1_2 then
		arg_1_0.text = arg_1_2.text
		arg_1_0.giftId = arg_1_2.giftId
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.container = arg_2_0:nodeByName("scroll")

	local var_2_0 = arg_2_0.container:getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0.container):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.list:setBounceable(true)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0, ...)
	arg_3_0.labels = {}

	arg_3_0:createRuleLabel()

	for iter_3_0 = 1, #arg_3_0.labels do
		local var_3_0 = display.newNode()
		local var_3_1 = arg_3_0.list:newItem()
		local var_3_2 = display.newNode()

		arg_3_0.labels[iter_3_0]:addTo(var_3_2)
		arg_3_0.labels[iter_3_0]:setAnchorPoint(cc.p(0, 0))
		arg_3_0.labels[iter_3_0]:setPosition(0, 0)
		var_3_2:setContentSize(630, arg_3_0.labels[iter_3_0]:getContentSize().height)
		var_3_2:addTo(var_3_0)
		var_3_0:setContentSize(630, arg_3_0.labels[iter_3_0]:getContentSize().height + 20)
		var_3_1:addContent(var_3_0)
		var_3_1:setItemSize(630, arg_3_0.labels[iter_3_0]:getContentSize().height + 20)
		arg_3_0.list:addItem(var_3_1)
	end

	arg_3_0.list:reload()
	arg_3_0:updateAward()
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevX_ = arg_4_1.x
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 5 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
end

function var_0_0.updateAward(arg_6_0, ...)
	local var_6_0 = arg_6_0.giftId or 90001086

	class("Activity", import("app.windows.activities.BaseActivity")):rewardFormat(arg_6_0:nodeByName("award_scroll"), var_6_0)
end

function var_0_0.createRuleLabel(arg_7_0)
	local var_7_0 = arg_7_0.text
	local var_7_1 = xyd.luaStringSplit(var_7_0, "|")

	for iter_7_0 = 1, #var_7_1 do
		local var_7_2 = {
			size = 24,
			color = cc.c3b(75, 75, 75)
		}

		if id == 1 or id == 3 then
			var_7_2.color = cc.c3b(39, 67, 136)
		end

		local var_7_3 = xyd.AssetLoader.get():loadLabel(var_7_2)

		var_7_3:setMaxLineWidth(630)
		var_7_3:setLineHeight(49)
		var_7_3:setString(var_7_1[iter_7_0])
		table.insert(arg_7_0.labels, var_7_3)
	end
end

return var_0_0
