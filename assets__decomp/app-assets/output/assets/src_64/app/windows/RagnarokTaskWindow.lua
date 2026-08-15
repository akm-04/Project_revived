local var_0_0 = class("RagnarokTaskWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.ragnarokTaskTable
local var_0_4 = {
	task = var_0_1:translation("RAGNAROK_TASK_1"),
	award = var_0_1:translation("RAGNAROK_TASK_2"),
	tips = var_0_1:translation("RAGNAROK_TASK_3"),
	finish = var_0_1:translation("RAGNAROK_TASK_4")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2 or {})

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
	arg_1_0.taskInfo = arg_1_0.ragnarok.taskInfo

	local var_1_0 = arg_1_0.taskInfo.mission_ids
	local var_1_1 = {}
	local var_1_2 = {}

	for iter_1_0 = 1, #var_1_0 do
		local var_1_3 = arg_1_0.taskInfo.mission_counts[iter_1_0]
		local var_1_4 = arg_1_0.taskInfo.mission_levs[iter_1_0]
		local var_1_5 = var_0_3:getCondition(var_1_0[iter_1_0])[var_1_4]

		if var_1_3 < var_1_5 then
			local var_1_6 = {
				finish_flag = 0,
				key = iter_1_0,
				id = var_1_0[iter_1_0],
				count = var_1_3,
				cond = var_1_5
			}

			table.insert(var_1_2, var_1_6)
		else
			local var_1_7 = {
				finish_flag = 1,
				key = iter_1_0,
				id = var_1_0[iter_1_0],
				count = var_1_3,
				cond = var_1_5
			}

			table.insert(var_1_1, var_1_7)
		end
	end

	arg_1_0.mission = clone(var_1_2)

	for iter_1_1 = 1, #var_1_1 do
		table.insert(arg_1_0.mission, var_1_1[iter_1_1])
	end

	if #var_1_2 == 0 then
		arg_1_0.canAward = 1
	else
		arg_1_0.canAward = 0
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("list")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):onScroll(handler(arg_2_0, arg_2_0.scrollListener)):setBounceable(true):pos(0, 0):addTo(var_2_0)

	arg_2_0.list:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:addTopSidebar()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super.didClose(arg_4_0, arg_4_1)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_task"):setString(var_0_4.task)
	arg_5_0:nodeByName("txt_award"):setString(var_0_4.award)
	arg_5_0:nodeByName("txt_tips"):setString(var_0_4.tips)
	arg_5_0:nodeByName("txt_get"):setString(var_0_4.finish)

	local var_5_0 = var_0_2:getValue("activity_ragnarok_mission_gift")
	local var_5_1 = xyd.tables.gift:items(var_5_0)
	local var_5_2 = xyd.tables.gift:itemNum(var_5_0)

	for iter_5_0 = 1, #var_5_1 do
		local var_5_3 = display.newNode()

		var_5_3:setContentSize(86, 86)
		var_5_3:setAnchorPoint(cc.p(0, 0))
		var_5_3:addTo(arg_5_0:nodeByName("award"))
		var_5_3:setPosition(cc.p(110 * (iter_5_0 - 1), 0))
		xyd.setItemAndAddTips(var_5_3, var_5_1[iter_5_0], var_5_2[iter_5_0])
	end

	arg_5_0.list:reload()
	arg_5_0:initBtn()
end

function var_0_0.initBtn(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("btn_get")

	if arg_6_0.canAward == 0 or arg_6_0.taskInfo.is_award == 1 then
		var_6_0:setBright(false)
		var_6_0:setTouchEnabled(false)
	else
		var_6_0:setBright(true)
		var_6_0:setTouchEnabled(true)
	end

	var_6_0:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			var_6_0:setScale(0.9)
		elseif arg_7_1 == ccui.TouchEventType.ended then
			var_6_0:setScale(1)
			xyd.Backend.get():request(xyd.mid.RAGNAROK_MISSION_AWARD, nil, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					var_6_0:setBright(false)
					var_6_0:setTouchEnabled(false)
					arg_6_0.selfPlayer:handleRewards(arg_8_1.awards)
				end
			end)
		end
	end)
end

function var_0_0.delegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return #arg_9_0.mission
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0 = arg_9_0.list:dequeueItem()

		if not var_9_0 then
			var_9_0 = arg_9_0.list:newItem()
		else
			var_9_0:removeAllChildren(true)
		end

		local var_9_1 = arg_9_0:createTaskItem(arg_9_3)

		var_9_0:setItemSize(620, 140)
		var_9_0:addContent(var_9_1)

		return var_9_0
	end
end

function var_0_0.createTaskItem(arg_10_0, arg_10_1)
	local var_10_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1203/task/task_item.csb")
	local var_10_1 = var_10_0:getChildByName("container")

	if arg_10_0.mission[arg_10_1].finish_flag == 0 then
		var_10_1:getChildByName("bg_finished"):setVisible(false)
		var_10_1:getChildByName("img_finish"):setVisible(false)
	else
		var_10_1:getChildByName("img_tips"):setVisible(false)
	end

	var_10_1:getChildByName("txt_tasks"):setString(var_0_4.task .. arg_10_0.mission[arg_10_1].key)

	local var_10_2 = string.format(var_0_3:getDescById(arg_10_0.mission[arg_10_1].id), tostring(arg_10_0.mission[arg_10_1].cond)) .. "(" .. arg_10_0.mission[arg_10_1].count .. "/" .. arg_10_0.mission[arg_10_1].cond .. ")"

	var_10_1:getChildByName("txt_desc"):setString(var_10_2)

	local var_10_3 = display.newNode()

	var_10_0:addTo(var_10_3)
	var_10_0:setAnchorPoint(cc.p(0, 0))
	var_10_3:setContentSize(var_10_1:getContentSize())
	var_10_0:setName("source")

	return var_10_3
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevX_ = arg_11_1.x
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 5 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

return var_0_0
