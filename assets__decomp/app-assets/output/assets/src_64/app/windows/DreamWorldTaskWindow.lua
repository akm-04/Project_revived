local var_0_0 = class("DreamWorldTaskWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.dreamWorldTaskTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dreamWorld = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)
	arg_1_0.tasks = arg_1_0.dreamWorld.taskList
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.listViewStory_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list_1"):getWidth(), arg_2_0:nodeByName("list_1"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list_1")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listViewStory_:setBounceable(true)
	arg_2_0.listViewStory_:setDelegate(handler(arg_2_0, arg_2_0.delegateStory))
	arg_2_0.listViewStory_:reload()

	arg_2_0.listViewChallenge_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list_2"):getWidth(), arg_2_0:nodeByName("list_2"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list_2")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listViewChallenge_:setBounceable(true)
	arg_2_0.listViewChallenge_:setDelegate(handler(arg_2_0, arg_2_0.delegateChallenge))
	arg_2_0.listViewChallenge_:reload()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_0:addTopSidebar()
	arg_3_0:nodeByName("text_story_mode"):setString(var_0_1:translation("DREAM_WORLD_TEXT_14"))
	arg_3_0:nodeByName("text_challenge_mode"):setString(var_0_1:translation("DREAM_WORLD_TEXT_15"))
	arg_3_0:nodeByName("text_story_mode"):enableOutline(cc.c4b(33, 33, 33, 255), 2)
	arg_3_0:nodeByName("text_challenge_mode"):enableOutline(cc.c4b(33, 33, 33, 255), 2)
end

function var_0_0.delegateStory(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_0.tasks[xyd.DreamWorldType.STORY]

	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #var_4_0
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		if arg_4_3 > #var_4_0 then
			return nil
		end

		local var_4_1 = arg_4_0.listViewStory_:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.listViewStory_:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = var_4_0[arg_4_3]
		local var_4_3 = display.newNode()

		arg_4_0:initCell(var_4_3, var_4_2, arg_4_3, xyd.DreamWorldType.STORY)

		local var_4_4 = display.newNode()

		var_4_4:addChild(var_4_3)
		var_4_4:setContentSize(var_4_3:getContentSize())
		var_4_1:setItemSize(var_4_3:getContentSize().width, var_4_3:getContentSize().height)
		var_4_1:addContent(var_4_4)

		return var_4_1
	end
end

function var_0_0.delegateChallenge(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = arg_5_0.tasks[xyd.DreamWorldType.CHALLENGE]

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		if arg_5_3 > #var_5_0 then
			return nil
		end

		local var_5_1 = arg_5_0.listViewChallenge_:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.listViewChallenge_:newItem()
		else
			var_5_1:removeAllChildren(true)
		end

		local var_5_2 = var_5_0[arg_5_3]
		local var_5_3 = display.newNode()

		arg_5_0:initCell(var_5_3, var_5_2, arg_5_3, xyd.DreamWorldType.CHALLENGE)

		local var_5_4 = display.newNode()

		var_5_4:addChild(var_5_3)
		var_5_4:setContentSize(var_5_3:getContentSize())
		var_5_1:setItemSize(var_5_3:getContentSize().width, var_5_3:getContentSize().height)
		var_5_1:addContent(var_5_4)

		return var_5_1
	end
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/dream_world/task/task_item.csb")
	local var_6_1 = var_6_0:getChildByName("container")
	local var_6_2 = var_6_1:getContentSize()
	local var_6_3 = arg_6_2.task_id
	local var_6_4 = import("app.common.ui.SplitLine")
	local var_6_5 = var_6_1:getChildByName("line")

	var_6_4.new({
		size = var_6_5:getWidth(),
		type = xyd.SplitlineType.SOLID
	}):addTo(var_6_5)
	var_6_1:getChildByName("name"):setString(var_0_2:name(var_6_3))

	if arg_6_4 == xyd.DreamWorldType.STORY then
		var_6_1:getChildByName("bg_item_2"):setVisible(false)
		var_6_1:getChildByName("name"):setColor(cc.c3b(105, 73, 148))
	else
		var_6_1:getChildByName("bg_item_1"):setVisible(false)
		var_6_1:getChildByName("name"):setColor(cc.c3b(161, 73, 148))
	end

	local var_6_6 = var_0_2:taskNum(var_6_3)

	var_6_1:getChildByName("desc"):setString(var_0_2:desc(var_6_3) .. "  " .. arg_6_2.count .. "/" .. var_6_6)

	local var_6_7 = var_0_2:item(var_6_3)[arg_6_4]
	local var_6_8 = var_0_2:itemNum(var_6_3)[arg_6_4]

	if var_6_7 and var_6_7 > 0 and var_6_8 > 0 then
		local var_6_9 = var_6_1:getChildByName("award_node")
		local var_6_10 = display.newNode()

		var_6_10:setAnchorPoint(cc.p(0, 0.5))
		var_6_10:setContentSize(90, 90)
		xyd.setItemAndAddTips(var_6_10, var_6_7, var_6_8)
		var_6_10:addTo(var_6_9)
		var_6_10:setPositionX(35)
	end

	local var_6_11 = var_0_2:title(var_6_3)[arg_6_4]

	if var_6_11 and var_6_11 > 0 then
		local var_6_12 = xyd.tables.titleSystemTable:bg(var_6_11)
		local var_6_13 = xyd.AssetLoader:get():loadSprite(var_6_12)

		var_6_13:setAnchorPoint(0, 0.5)
		var_6_13:addTo(var_6_1:getChildByName("award_node"))
		var_6_13:setScale(0.6)
		var_6_13:setPositionX(-20)
	end

	if arg_6_2.is_award == 1 then
		var_6_1:getChildByName("icon_recieved"):setVisible(true)
	elseif arg_6_2.is_complete == 1 then
		var_6_1:getChildByName("icon_available"):setVisible(true)
		var_6_0:setTouchEnabled(true)
		var_6_0:setTouchSwallowEnabled(false)
		var_6_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				arg_6_0.click = true
				arg_6_0.touchBeganX = arg_7_0.x
				arg_6_0.touchBeganY = arg_7_0.y

				return true
			elseif arg_7_0.name == "moved" then
				if math.abs(arg_6_0.touchBeganX - arg_7_0.x) + math.abs(arg_6_0.touchBeganY - arg_7_0.y) < 20 then
					return true
				else
					arg_6_0.click = false
				end
			elseif arg_7_0.name == "ended" and arg_6_0.click then
				xyd.playButtonSound()
				arg_6_0.dreamWorld:getTaskAward(arg_6_4, var_6_3, arg_6_3, function()
					arg_6_0.listViewStory_:refreshList()
					arg_6_0.listViewChallenge_:refreshList()
				end)

				return true
			end
		end)
	else
		var_6_1:getChildByName("text_not_complete"):setVisible(true)
		var_6_1:getChildByName("text_not_complete"):setString(var_0_1:translation("NOT_REACHED_TEXT"))
	end

	var_6_0:addTo(arg_6_1)
	arg_6_1:setContentSize(var_6_2.width, var_6_2.height + 9)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.startClick_ = true
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" and 20 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
		arg_9_0.startClick_ = false
	end
end

return var_0_0
