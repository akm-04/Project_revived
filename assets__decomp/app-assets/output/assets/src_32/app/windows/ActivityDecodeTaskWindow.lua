local var_0_0 = class("ActivityDecodeTaskWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1
local var_0_3 = xyd.tables.activityDecodeMission

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activity = arg_1_2.activity
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.mission_list = arg_1_0.details.mission_list
	arg_1_0.type = arg_1_2.type
	arg_1_0.rule = arg_1_2.rule
	arg_1_0.title_name = arg_1_2.title_name
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, 550, 428),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("scroll")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.list:setBounceable(true)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:updatedata()

	if arg_4_0.type == var_0_2 then
		arg_4_0.scroll = arg_4_0:nodeByName("scroll")

		local var_4_0 = arg_4_0.scroll:getContentSize()

		arg_4_0.scrollList = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

		arg_4_0.scrollList:setBounceable(true)
		arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
		arg_4_0.scrollList:reload()
	else
		arg_4_0.labels = {}

		arg_4_0:createRuleLabel(0)

		for iter_4_0 = 1, #arg_4_0.labels do
			local var_4_1 = display.newNode()
			local var_4_2 = arg_4_0.list:newItem()
			local var_4_3 = display.newNode()

			arg_4_0.labels[iter_4_0]:addTo(var_4_3)
			arg_4_0.labels[iter_4_0]:setAnchorPoint(cc.p(0, 0))
			arg_4_0.labels[iter_4_0]:setPosition(0, 0)
			var_4_3:setContentSize(540, arg_4_0.labels[iter_4_0]:getContentSize().height)
			var_4_3:addTo(var_4_1)
			var_4_1:setContentSize(540, arg_4_0.labels[iter_4_0]:getContentSize().height + 5)
			var_4_2:addContent(var_4_1)
			var_4_2:setItemSize(540, arg_4_0.labels[iter_4_0]:getContentSize().height + 5)
			arg_4_0.list:addItem(var_4_2)
		end

		arg_4_0.list:reload()
	end
end

function var_0_0.createRuleLabel(arg_5_0, arg_5_1)
	local var_5_0 = var_0_1:translation(arg_5_0.rule)
	local var_5_1 = xyd.luaStringSplit(var_5_0, "|")

	for iter_5_0 = 1, #var_5_1 do
		local var_5_2 = {
			size = 27,
			color = cc.c3b(107, 52, 27)
		}

		if arg_5_1 == 1 or arg_5_1 == 3 then
			var_5_2.color = cc.c3b(107, 52, 27)
		end

		local var_5_3 = xyd.AssetLoader.get():loadLabel(var_5_2)

		var_5_3:setMaxLineWidth(530)
		var_5_3:setLineHeight(55)
		var_5_3:setString(var_5_1[iter_5_0])
		table.insert(arg_5_0.labels, var_5_3)
	end
end

function var_0_0.updatedata(arg_6_0, arg_6_1)
	arg_6_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	local var_6_0 = arg_6_0.activity.start_time
	local var_6_1 = xyd.ServerTime.get():getServerTime()

	arg_6_0.days = math.ceil((var_6_1 - var_6_0) / 86400)
	arg_6_0.date = {
		1,
		2,
		3,
		4,
		5,
		6,
		7
	}

	for iter_6_0 = 1, 7 do
		arg_6_0.date[iter_6_0] = string.format(var_0_1:translation("NDAYS"), iter_6_0)
	end
end

function var_0_0.scrollListDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.mission_list
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0
		local var_7_1 = arg_7_0.scrollList:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_0.scrollList:newItem()
		else
			var_7_1:removeAllChildren(true)
		end

		local var_7_2 = arg_7_0:createListContent(arg_7_3)
		local var_7_3 = var_7_2:getWidth()
		local var_7_4 = var_7_2:getHeight()

		var_7_1:setItemSize(var_7_3, var_7_4)
		var_7_1:addContent(var_7_2)

		return var_7_1
	end
end

function var_0_0.createListContent(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0.mission_list[arg_8_1]
	local var_8_1 = arg_8_0.mission_list[arg_8_1].mission_id
	local var_8_2 = string.format(var_0_3:content(var_8_1))
	local var_8_3 = string.format(var_0_3:num(var_8_1))
	local var_8_4 = display.newNode()
	local var_8_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1171/assignment/task_item.csb")
	local var_8_6 = var_8_5:getChildByName("container")
	local var_8_7 = tonumber(var_8_0.is_awarded)

	if var_8_0.is_award == 1 then
		var_8_6:getChildByName("select"):setVisible(true)
	else
		var_8_6:getChildByName("select"):setVisible(false)
	end

	var_8_6:getChildByName("assignment_txt"):setString(var_8_2)
	var_8_6:getChildByName("count_txt"):setString("(" .. tostring(var_8_0.count) .. "/" .. var_8_3 .. ")")
	var_8_5:addTo(var_8_4)
	var_8_5:setAnchorPoint(cc.p(0, 0))
	var_8_4:setContentSize(var_8_6:getContentSize())
	var_8_5:setName("source")

	return var_8_4
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 5 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

return var_0_0
