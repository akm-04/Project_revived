local var_0_0 = class("CourseStudySelectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.objectBook

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.coursesInfo = arg_1_2.partner_courses
	arg_1_0.coursesIds = table.keys(arg_1_0.coursesInfo)
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("title_txt"):setString(var_0_1:translation("COURSE_SELECT_TITLE_TEXT"))

	arg_3_0.scroll = arg_3_0:nodeByName("course_scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.courseList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.courseList:setBounceable(false)
	arg_3_0.courseList:setDelegate(handler(arg_3_0, arg_3_0.courseListDelegate))
	arg_3_0.courseList:setTouchType(false)
	arg_3_0.courseList:reload()
end

function var_0_0.courseListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #arg_4_0.coursesIds
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.courseList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.courseList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListContent(arg_4_0.coursesIds[arg_4_3])
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3 + 10, var_4_4)
		var_4_1:addContent(var_4_2)
		var_4_1:setPositionX(5)

		return var_4_1
	end
end

function var_0_0.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.coursesInfo[arg_5_1]
	local var_5_1 = display.newNode()

	var_5_1:setContentSize(100, 100)

	local var_5_2 = var_0_2:icon(tonumber(arg_5_1))

	xyd.setSpriteBorder(var_5_1, var_5_2, 1)
	var_5_1:setTouchEnabled(true)
	var_5_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			var_5_1:setScale(0.9)

			return true
		elseif arg_6_0.name == "ended" then
			xyd.playButtonSound()
			var_5_1:setScale(1)
			arg_5_0.callback(tonumber(arg_5_1))
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)

	if var_5_0.progress >= 100 then
		local var_5_3 = xyd.AssetLoader.get():loadSprite("windows/fumo_hero/avatar_mask.png")

		var_5_3:setScale(1.1)
		var_5_3:setPosition(63, 62)
		var_5_1:addChild(var_5_3, 10)
		var_5_1:setTouchEnabled(false)
	end

	return var_5_1
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 5 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

return var_0_0
