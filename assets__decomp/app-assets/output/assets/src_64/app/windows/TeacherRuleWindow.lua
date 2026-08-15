local var_0_0 = class("TeacherRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	INDIEGOGO_TITLE = 3,
	TEACHER = 2,
	TEACHER_TITLE = 4,
	INDIEGOGO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
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
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list"):getWidth(), arg_3_0:nodeByName("list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)

	arg_3_0.ruleType = arg_3_1.ruleType

	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("SOCIAL_RULE"))

	local var_4_0
	local var_4_1 = 0

	if arg_4_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_INDIEGOGO) then
		local var_4_2 = arg_4_0:createRuleLabel(var_0_2.INDIEGOGO_TITLE)

		arg_4_0:createRuleItems(var_4_2, true)

		local var_4_3 = arg_4_0:createRuleLabel(var_0_2.INDIEGOGO)

		arg_4_0:createRuleItems(var_4_3)
	end

	local var_4_4 = arg_4_0:createRuleLabel(var_0_2.TEACHER_TITLE)
	local var_4_5 = arg_4_0:createRuleItems(var_4_4, true) + var_4_1
	local var_4_6 = arg_4_0:createRuleLabel(var_0_2.TEACHER)
	local var_4_7 = arg_4_0:createRuleItems(var_4_6) + var_4_5

	arg_4_0.list:reload()

	if arg_4_0.ruleType == 2 and arg_4_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_INDIEGOGO) then
		if arg_4_0:nodeByName("list"):getHeight() - var_4_7 < 0 then
			arg_4_0.list:scrollTo(0, arg_4_0:nodeByName("list"):getHeight() - var_4_7)
		else
			arg_4_0.list:scrollTo(0, 0)
		end
	end
end

function var_0_0.createRuleItems(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = 0

	for iter_5_0 = 1, #arg_5_1 do
		local var_5_1 = display.newNode()
		local var_5_2 = arg_5_0.list:newItem()
		local var_5_3 = display.newNode()

		arg_5_1[iter_5_0]:addTo(var_5_3)
		arg_5_1[iter_5_0]:setAnchorPoint(cc.p(0, 0))
		arg_5_1[iter_5_0]:setPosition(0, 0)

		if arg_5_2 then
			arg_5_1[iter_5_0]:setPosition(0, 10)
		end

		local var_5_4 = 18

		if arg_5_2 then
			var_5_4 = 35
		end

		var_5_3:setContentSize(arg_5_0:nodeByName("list"):getWidth(), arg_5_1[iter_5_0]:getContentSize().height)
		var_5_3:addTo(var_5_1)
		var_5_1:setContentSize(arg_5_0:nodeByName("list"):getWidth(), arg_5_1[iter_5_0]:getContentSize().height + var_5_4)
		var_5_2:addContent(var_5_1)
		var_5_2:setItemSize(arg_5_0:nodeByName("list"):getWidth(), arg_5_1[iter_5_0]:getContentSize().height + var_5_4)

		var_5_0 = var_5_2:getContentSize().height + var_5_0

		arg_5_0.list:addItem(var_5_2)
	end

	return var_5_0
end

function var_0_0.createRuleLabel(arg_6_0, arg_6_1)
	local var_6_0

	if arg_6_1 == var_0_2.INDIEGOGO then
		var_6_0 = var_0_1:translation("INDIEGOGO_TEXT_RULE")
	elseif arg_6_1 == var_0_2.TEACHER then
		var_6_0 = var_0_1:translation("TEACHER_RULE")
	elseif arg_6_1 == var_0_2.INDIEGOGO_TITLE then
		var_6_0 = var_0_1:translation("INDIEGOGO_TEXT_TITLE")
	else
		var_6_0 = var_0_1:translation("TEACHER_RULE_TITLE")
	end

	local var_6_1 = xyd.luaStringSplit(var_6_0, "\n")
	local var_6_2 = {}

	for iter_6_0 = 1, #var_6_1 do
		local var_6_3 = {
			size = 24,
			color = cc.c3b(52, 54, 55)
		}

		if arg_6_1 == var_0_2.INDIEGOGO_TITLE then
			var_6_3.color = cc.c3b(254, 115, 22)
			var_6_3.size = 26
		elseif arg_6_1 == var_0_2.TEACHER_TITLE then
			var_6_3.color = cc.c3b(80, 164, 255)
			var_6_3.size = 26
		end

		local var_6_4 = xyd.AssetLoader.get():loadLabel(var_6_3)

		var_6_4:setMaxLineWidth(arg_6_0:nodeByName("list"):getWidth())
		var_6_4:setString(var_6_1[iter_6_0])
		print(var_6_4:getLineHeight())
		var_6_4:setLineHeight(30)
		print(var_6_4:getLineHeight())
		table.insert(var_6_2, var_6_4)
	end

	return var_6_2
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
