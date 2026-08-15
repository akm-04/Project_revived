local var_0_0 = class("SubCollegeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.functionOpen
local var_0_2 = xyd.tables.translation
local var_0_3 = cc.Director:getInstance():getVisibleSize()
local var_0_4 = (var_0_3.width - xyd.STAGE_WIDTH) / 2
local var_0_5 = (var_0_3.height - xyd.STAGE_HEIGHT) / 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()
	xyd.nodeEventSample(arg_2_0:nodeByName("library_node"), {}, function()
		xyd.WindowManager.get():openWindow("library")
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("fresh_node"), {}, function()
		xyd.WindowManager.get():openWindow("faq")
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("album_node"), {}, function()
		xyd.WindowManager.get():openWindow("white_album")
	end)

	local var_2_0 = arg_2_0:nodeByName("dorm_node")

	var_2_0:setTouchEnabled(true)
	var_2_0:setTouchSwallowEnabled(false)

	if not arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_DORM) then
		arg_2_0:addLock(var_2_0)
	end

	var_2_0.points = {
		{
			x = 412,
			y = 83
		},
		{
			x = 412,
			y = 386
		},
		{
			x = 695,
			y = 386
		},
		{
			x = 601,
			y = 83
		}
	}

	var_2_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			if not arg_2_0:isEventPossibleOnNode(var_2_0.points, arg_6_0.x - var_0_4, arg_6_0.y - var_0_5) then
				return
			end

			var_2_0:setScale(0.9)

			return true
		elseif arg_6_0.name == "moved" then
			if arg_2_0:isEventPossibleOnNode(var_2_0.points, arg_6_0.x - var_0_4, arg_6_0.y - var_0_5) then
				return
			end

			var_2_0:setScale(1)
		elseif arg_6_0.name == "ended" then
			var_2_0:setScale(1)

			if not arg_2_0:isEventPossibleOnNode(var_2_0.points, arg_6_0.x - var_0_4, arg_6_0.y - var_0_5) then
				return
			end

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_DORM) then
				arg_2_0.dorm = arg_2_0.dorm or xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)

				arg_2_0.dorm:getHouseList()
			else
				arg_2_0:lockTip(xyd.FunctionID.ID_DORM)
			end
		end
	end)

	local var_2_1 = arg_2_0:nodeByName("furn_fact_node")

	var_2_1:setTouchEnabled(true)
	var_2_1:setTouchSwallowEnabled(false)

	if not arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_FURNITURE_FACTORY) then
		arg_2_0:addLock(var_2_1)
	end

	var_2_1.points = {
		{
			x = 608,
			y = 83
		},
		{
			x = 710,
			y = 386
		},
		{
			x = 895,
			y = 386
		},
		{
			x = 895,
			y = 83
		}
	}

	var_2_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			if not arg_2_0:isEventPossibleOnNode(var_2_1.points, arg_7_0.x - var_0_4, arg_7_0.y - var_0_5) then
				return
			end

			var_2_1:setScale(0.9)

			return true
		elseif arg_7_0.name == "moved" then
			if arg_2_0:isEventPossibleOnNode(var_2_1.points, arg_7_0.x - var_0_4, arg_7_0.y - var_0_5) then
				return
			end

			var_2_1:setScale(1)
		elseif arg_7_0.name == "ended" then
			var_2_1:setScale(1)

			if not arg_2_0:isEventPossibleOnNode(var_2_1.points, arg_7_0.x - var_0_4, arg_7_0.y - var_0_5) then
				return
			end

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_FURNITURE_FACTORY) then
				xyd.WindowManager.get():openWindow("furniture_factory")
			else
				arg_2_0:lockTip(xyd.FunctionID.ID_FURNITURE_FACTORY)
			end
		end
	end)

	local var_2_2 = arg_2_0:nodeByName("course_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_COURSE) then
		xyd.nodeEventSample(var_2_2, {}, function()
			arg_2_0.course:enterCourseWindow()
		end)
	else
		arg_2_0:addLockAndTips(var_2_2, xyd.FunctionID.ID_COURSE)
	end

	arg_2_0.libraryRedP = arg_2_0:nodeByName("library_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.LIBRARY)

	arg_2_0.courseRedP = arg_2_0:nodeByName("course_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.COURSE)

	arg_2_0.albumRedP = arg_2_0:nodeByName("album_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.WHITE_ALBUM)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.CHECK_MIDDLE_RED_MARK, function(arg_9_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:checkRedMark(arg_9_0.params)
		end
	end)

	for iter_2_0 = 1, 6 do
		arg_2_0:nodeByName("des" .. iter_2_0):setString(xyd.tables.translation:translation("XUEYUANJINXIU_TIP" .. iter_2_0))
	end
end

function var_0_0.isEventPossibleOnNode(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_1[1]
	local var_10_1 = arg_10_1[2]
	local var_10_2 = arg_10_1[3]
	local var_10_3 = arg_10_1[4]
	local var_10_4 = (var_10_1.x - var_10_0.x) * (arg_10_3 - var_10_0.y) - (var_10_1.y - var_10_0.y) * (arg_10_2 - var_10_0.x)
	local var_10_5 = (var_10_2.x - var_10_1.x) * (arg_10_3 - var_10_1.y) - (var_10_2.y - var_10_1.y) * (arg_10_2 - var_10_1.x)
	local var_10_6 = (var_10_3.x - var_10_2.x) * (arg_10_3 - var_10_2.y) - (var_10_3.y - var_10_2.y) * (arg_10_2 - var_10_2.x)
	local var_10_7 = (var_10_0.x - var_10_3.x) * (arg_10_3 - var_10_3.y) - (var_10_0.y - var_10_3.y) * (arg_10_2 - var_10_3.x)

	if var_10_4 >= 0 and var_10_5 >= 0 and var_10_6 >= 0 and var_10_7 >= 0 or var_10_4 <= 0 and var_10_5 <= 0 and var_10_6 <= 0 and var_10_7 <= 0 then
		return true
	else
		return false
	end
end

function var_0_0.addLockAndTips(arg_11_0, arg_11_1, arg_11_2)
	arg_11_0:addLock(arg_11_1, arg_11_2)
	xyd.nodeEventSample(arg_11_1, {}, function()
		arg_11_0:lockTip(arg_11_2)
	end)
end

function var_0_0.addLock(arg_13_0, arg_13_1, arg_13_2)
	arg_13_1:runActionOnce(cc.TintBy:create(0, -100, -100, -100))

	local var_13_0 = xyd.AssetLoader.get():loadSprite("windows/common/lock.png")

	var_13_0:addTo(arg_13_1)

	local var_13_1 = arg_13_1:getContentSize()

	var_13_0:setPosition(var_13_1.width / 2, var_13_1.height / 2)
end

function var_0_0.lockTip(arg_14_0, arg_14_1)
	local var_14_0 = var_0_1:tip(arg_14_1)

	if var_14_0 == "" then
		var_14_0 = var_0_2:translation("FUNCTION_OPEN_TIP_OTHER")
	end

	xyd.WindowManager.get():openWindow("toast", {
		message = var_14_0
	})
end

function var_0_0.checkRedMark(arg_15_0, arg_15_1)
	if arg_15_1 == xyd.CheckMiddleRed.LIBRARY then
		arg_15_0.libraryRedP:setVisible(arg_15_0.library:isLibraryRedPointShow() or false)
	elseif arg_15_1 == xyd.CheckMiddleRed.COURSE then
		arg_15_0.courseRedP:setVisible(arg_15_0.course:isCourseRedPointShow() or false)
	elseif arg_15_1 == xyd.CheckMiddleRed.WHITE_ALBUM then
		arg_15_0.albumRedP:setVisible(arg_15_0.selfPlayer.albumNormalRedP or arg_15_0.selfPlayer.albumSpecialRedP or false)
	end
end

function var_0_0.didClose(arg_16_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

return var_0_0
