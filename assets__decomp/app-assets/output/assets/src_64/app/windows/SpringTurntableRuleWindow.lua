local var_0_0 = class("SpringTurntableRuleWindow", import("app.common.ui.BaseWindow"))
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

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, 670, 370),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("words_container")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))
end

function var_0_0.layout(arg_4_0)
	local function var_4_0(arg_5_0, arg_5_1)
		for iter_5_0 = 1, #arg_5_0 do
			local var_5_0 = display.newNode()
			local var_5_1 = arg_4_0.list:newItem()
			local var_5_2 = display.newNode()

			arg_5_0[iter_5_0]:addTo(var_5_2)
			arg_5_0[iter_5_0]:setAnchorPoint(cc.p(0, 0))
			arg_5_0[iter_5_0]:setPosition(0, 0)
			var_5_2:setContentSize(670, arg_5_0[iter_5_0]:getContentSize().height)
			var_5_2:addTo(var_5_0)
			var_5_0:setContentSize(670, arg_4_0.height_table[iter_5_0] * arg_5_1)
			var_5_1:addContent(var_5_0)
			var_5_1:setItemSize(670, arg_4_0.height_table[iter_5_0] * arg_5_1)
			arg_4_0.list:addItem(var_5_1)
		end
	end

	arg_4_0:nodeByName("title_txt"):setString(var_0_1:translation("TURNTALBE_TITLE"))

	arg_4_0.height_table = {}

	local var_4_1 = arg_4_0:createRuleLabel(var_0_1:translation("NEWYEAR_TRUNTABLE_RULE_TEXT"), cc.c3b(247, 217, 54))

	var_4_0(var_4_1, 50)
	arg_4_0.list:reload()
end

function var_0_0.createRuleLabel(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = xyd.luaStringSplit(arg_6_1, "|")
	local var_6_1 = {}

	for iter_6_0 = 1, #var_6_0 do
		local var_6_2 = {
			size = 24,
			color = arg_6_2
		}
		local var_6_3 = xyd.AssetLoader.get():loadLabel(var_6_2)

		var_6_3:setMaxLineWidth(670)
		var_6_3:setLineHeight(49)
		var_6_3:setString(var_6_0[iter_6_0])

		arg_6_0.height_table[iter_6_0] = var_6_3:getStringNumLines()

		table.insert(var_6_1, var_6_3)
	end

	return var_6_1
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
	arg_7_0:layout()
end

return var_0_0
