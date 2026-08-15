local var_0_0 = class("CourseListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.objectSubject
local var_0_3 = xyd.tables.objectClass
local var_0_4 = xyd.tables.objectBook

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.currentListIndex = 1
	arg_1_0.currentStoryItemContainer = nil

	if arg_1_2 and arg_1_2.hero then
		arg_1_0.hero = arg_1_2.hero

		local var_1_0 = arg_1_0.hero:getCoursesInfo()

		if #table.keys(var_1_0) >= #arg_1_0.hero:getCourseSkills() then
			arg_1_0.hero = nil
		end
	end

	if arg_1_2 and arg_1_2.callback then
		arg_1_0.callback = arg_1_2.callback
	end

	arg_1_0.departmentIds = var_0_2:department(arg_1_0.currentListIndex)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)

	if arg_4_0.callback then
		arg_4_0.callback()
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0.listContainer = arg_5_0:nodeByName("list_container")
	arg_5_0.detailContainer = arg_5_0:nodeByName("detail_container")

	local var_5_0 = arg_5_0.listContainer:getContentSize()

	arg_5_0.listScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_0.width, var_5_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0.listContainer):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.listScroll:setBounceable(true)
	arg_5_0.listScroll:setDelegate(handler(arg_5_0, arg_5_0.listScrollDelegate))
	arg_5_0.listScroll:reload()

	local var_5_1 = arg_5_0.detailContainer:getContentSize()

	arg_5_0.detailScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_5_0.detailContainer):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.detailScroll:setBounceable(true)
	arg_5_0.detailScroll:setDelegate(handler(arg_5_0, arg_5_0.detailScrollDelegate))
	arg_5_0.detailScroll:reload()
	arg_5_0:nodeByName("detail_desc_txt"):setString(var_0_1:translation("STORY_READ_DESC"))
end

function var_0_0.listScrollDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_0_2:objectCount()
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0 = arg_6_0.listScroll:dequeueItem()

		if not var_6_0 then
			var_6_0 = arg_6_0.listScroll:newItem()
		else
			var_6_0:removeAllChildren(true)
		end

		local var_6_1 = arg_6_0:creatListItemContent(arg_6_3)
		local var_6_2 = var_6_1:getWidth()
		local var_6_3 = var_6_1:getHeight()

		var_6_0:setItemSize(var_6_2, var_6_3 + 4)
		var_6_0:addContent(var_6_1)
		var_6_1:setPositionY(2)

		return var_6_0
	end
end

function var_0_0.creatListItemContent(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/course_list/list_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = var_0_2:nameIcon(arg_7_1)

	nameIcon = xyd.AssetLoader.get():loadSprite(var_7_3)

	nameIcon:addTo(var_7_2:getChildByName("name_icon_pos"))

	if arg_7_1 == arg_7_0.currentListIndex then
		arg_7_0.currentStoryItemContainer = var_7_2
		arg_7_0.currentItemBtn = var_7_2:getChildByName("select_btn")

		arg_7_0.currentItemBtn:setBrightStyle(ccui.BrightStyle.highlight)
	else
		var_7_2:getChildByName("select_btn"):setBrightStyle(ccui.BrightStyle.normal)
	end

	var_7_2:getChildByName("select_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended and arg_7_0.scrollViewMoved_ ~= true then
			if arg_7_0.currentListIndex ~= arg_7_1 and arg_7_0.currentItemBtn then
				arg_7_0.currentItemBtn:setBrightStyle(ccui.BrightStyle.normal)
			end

			arg_7_0.currentStoryItemContainer = var_7_2
			arg_7_0.currentItemBtn = var_7_2:getChildByName("select_btn")

			arg_7_0.currentItemBtn:setBrightStyle(ccui.BrightStyle.highlight)

			arg_7_0.currentListIndex = arg_7_1
			arg_7_0.departmentIds = var_0_2:department(arg_7_0.currentListIndex)

			arg_7_0.detailScroll:reload()
		end
	end)
	var_7_1:addTo(var_7_0)
	var_7_1:setAnchorPoint(cc.p(0, 0))
	var_7_0:setContentSize(var_7_2:getContentSize())
	var_7_1:setName("source")

	return var_7_0
end

function var_0_0.detailScrollDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return #arg_9_0.departmentIds
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0 = arg_9_0.detailScroll:dequeueItem()

		if not var_9_0 then
			var_9_0 = arg_9_0.detailScroll:newItem()
		else
			var_9_0:removeAllChildren(true)
		end

		local var_9_1 = arg_9_0:creatDetailItemContent(arg_9_0.departmentIds[arg_9_3])
		local var_9_2 = var_9_1:getWidth()
		local var_9_3 = var_9_1:getHeight()

		var_9_0:setItemSize(var_9_2 + 20, var_9_3)
		var_9_0:addContent(var_9_1)

		return var_9_0
	end
end

function var_0_0.creatDetailItemContent(arg_10_0, arg_10_1)
	local var_10_0 = display.newNode()
	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/course/course_list/detail_item.csb")
	local var_10_2 = var_10_1:getChildByName("container")
	local var_10_3 = var_10_2:getChildByName("apply_btn")

	var_10_2:getChildByName("title_txt"):setString(var_0_3:name(arg_10_1))

	local var_10_4 = xyd.AssetLoader.get():loadSprite(var_0_3:icon(arg_10_1))

	var_10_4:addTo(var_10_2:getChildByName("class_icon_pos"))

	local var_10_5 = var_0_3:book(arg_10_1)

	for iter_10_0 = 1, #var_10_5 do
		local var_10_6 = arg_10_0:createBookWithTips(var_10_5[iter_10_0])

		var_10_6:addTo(var_10_2:getChildByName("book_pos"))
		var_10_6:setAnchorPoint(cc.p(0, 0.5))
		var_10_6:setPositionX((iter_10_0 - 1) * 60)
	end

	var_10_2:getChildByName("course_list_bg"):setTouchEnabled(true)
	var_10_2:getChildByName("course_list_bg"):setTouchSwallowEnabled(true)
	var_10_4:setTouchEnabled(true)
	var_10_4:setTouchSwallowEnabled(false)
	var_10_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			return true
		elseif arg_11_0.name == "ended" and not arg_10_0.scrollViewMoved_ then
			xyd.playButtonSound()

			local var_11_0 = {
				departmentId = arg_10_1
			}

			if arg_10_0.hero then
				var_11_0.hero = arg_10_0.hero
			end

			xyd.WindowManager.get():openWindow("course_apply", var_11_0)
		end
	end)
	var_10_1:addTo(var_10_0)
	var_10_1:setAnchorPoint(cc.p(0, 0))
	var_10_0:setContentSize(var_10_2:getContentSize())
	var_10_1:setName("source")

	return var_10_0
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevX_ = arg_12_1.x
	elseif arg_12_1.name == "moved" and 5 <= math.abs(arg_12_1.x - arg_12_0.prevX_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.createBookWithTips(arg_13_0, arg_13_1)
	local var_13_0 = 50
	local var_13_1 = display.newNode()

	var_13_1:setContentSize(var_13_0, var_13_0)

	local var_13_2 = var_0_4:icon(arg_13_1)

	xyd.setSpriteBorder(var_13_1, var_13_2, 1)
	arg_13_0:addTips(var_13_1, arg_13_1)

	return var_13_1
end

function var_0_0.addTips(arg_14_0, arg_14_1, arg_14_2)
	arg_14_1:setTouchEnabled(true)
	arg_14_1:setTouchSwallowEnabled(false)

	local var_14_0

	arg_14_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			var_14_0 = arg_15_0.y

			if not xyd.WindowManager.get():getWindow("course_tip") then
				local var_15_0 = {
					book_id = arg_14_2
				}
				local var_15_1 = xyd.WindowManager.get():openWindow("course_tip", var_15_0)
				local var_15_2, var_15_3 = arg_14_1:getPosition()
				local var_15_4 = arg_14_1:getHeight()
				local var_15_5 = 200
				local var_15_6 = arg_14_1:getParent():convertToWorldSpace(cc.p(var_15_2 + 10, var_15_3 + var_15_4 / 2 + var_15_5 / 2 + 30))

				var_15_6.x, var_15_6.y = xyd.convertWorldPos(var_15_6.x, var_15_6.y)

				var_15_1:setPosition(var_15_6.x, var_15_6.y)
				var_15_1:addBlockLayerClickClose(cc.c4b(0, 0, 0, 0), nil, nil, 2)
			end

			return true
		elseif arg_15_0.name == "moved" then
			local var_15_7 = arg_15_0.y

			if math.abs(var_15_7 - var_14_0) > 30 then
				xyd.WindowManager.get():closeWindow("course_tip")
			end
		elseif arg_15_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("course_tip")
		end
	end)
end

return var_0_0
