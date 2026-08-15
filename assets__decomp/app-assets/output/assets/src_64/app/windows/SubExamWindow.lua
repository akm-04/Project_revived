local var_0_0 = class("SubExamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.functionOpen
local var_0_2 = xyd.tables.translation
local var_0_3 = cc.Director:getInstance():getVisibleSize()
local var_0_4 = (var_0_3.width - xyd.STAGE_WIDTH) / 2
local var_0_5 = (var_0_3.height - xyd.STAGE_HEIGHT) / 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()

	local var_2_0 = arg_2_0:nodeByName("time_travel_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CAVE) then
		xyd.nodeEventSample(var_2_0, {}, function()
			xyd.WindowManager.get():openWindow("time_travel")
		end)
	else
		arg_2_0:addLockAndTips(var_2_0, xyd.FunctionID.ID_CAVE)
	end

	local var_2_1 = arg_2_0:nodeByName("illusion_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ILLUSION) then
		xyd.nodeEventSample(var_2_1, {}, function()
			xyd.WindowManager.get():openWindow("illusion")
		end)
	else
		arg_2_0:addLockAndTips(var_2_1, xyd.FunctionID.ID_ILLUSION)
	end

	local var_2_2 = arg_2_0:nodeByName("occult_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_OCCULT) then
		xyd.nodeEventSample(var_2_2, {}, function()
			arg_2_0.occult = arg_2_0.occult or xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)

			arg_2_0.occult:openOccultWindow()
		end)
	else
		arg_2_0:addLockAndTips(var_2_2, xyd.FunctionID.ID_OCCULT)
	end

	local var_2_3 = arg_2_0:nodeByName("throw_sandbag_node")

	if xyd.isSystemFuncOpen(xyd.FunctionID.ID_THROW_SANDBAG) then
		xyd.nodeEventSample(var_2_3, {}, function()
			xyd.ModelManager.get():loadModel(xyd.ModelType.THROW_SANDBAG):loadInfo(function()
				xyd.WindowManager.get():openWindow("throw_sandbag_main")
			end)
		end)
	else
		arg_2_0:addLockAndTips(var_2_3)
	end

	local var_2_4 = arg_2_0:nodeByName("memories_node")

	var_2_4:setTouchEnabled(true)
	var_2_4:setTouchSwallowEnabled(false)

	if not arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.MEMORIES_OF_SCHOOL) then
		arg_2_0:addLock(var_2_4)
	end

	var_2_4.points = {
		{
			x = 602,
			y = 82
		},
		{
			x = 704,
			y = 386
		},
		{
			x = 884,
			y = 386
		},
		{
			x = 884,
			y = 82
		}
	}

	var_2_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			if not arg_2_0:isEventPossibleOnNode(var_2_4.points, arg_8_0.x - var_0_4, arg_8_0.y - var_0_5) then
				return
			end

			var_2_4:setScale(0.9)

			return true
		elseif arg_8_0.name == "moved" then
			if arg_2_0:isEventPossibleOnNode(var_2_4.points, arg_8_0.x - var_0_4, arg_8_0.y - var_0_5) then
				return
			end

			var_2_4:setScale(1)
		elseif arg_8_0.name == "ended" then
			var_2_4:setScale(1)

			if not arg_2_0:isEventPossibleOnNode(var_2_4.points, arg_8_0.x - var_0_4, arg_8_0.y - var_0_5) then
				return
			end

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.MEMORIES_OF_SCHOOL) then
				arg_2_0.memoriesOfSchool = arg_2_0.memoriesOfSchool or xyd.ModelManager.get():loadModel(xyd.ModelType.MEMORIES_OF_SCHOOL)

				arg_2_0.memoriesOfSchool:getInfo({}, function(arg_9_0, arg_9_1)
					xyd.WindowManager.get():openWindow("memories_of_school_main", {
						response = clone(arg_9_1)
					})
				end)
			else
				arg_2_0:lockTip(xyd.FunctionID.MEMORIES_OF_SCHOOL)
			end
		end
	end)

	local var_2_5 = arg_2_0:nodeByName("hunqi_node")

	var_2_5:setTouchEnabled(true)
	var_2_5:setTouchSwallowEnabled(false)

	if not arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_HUNQI) then
		arg_2_0:addLock(var_2_5)
	end

	var_2_5.points = {
		{
			x = 385,
			y = 82
		},
		{
			x = 385,
			y = 386
		},
		{
			x = 685,
			y = 386
		},
		{
			x = 586,
			y = 82
		}
	}

	var_2_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			if not arg_2_0:isEventPossibleOnNode(var_2_5.points, arg_10_0.x - var_0_4, arg_10_0.y - var_0_5) then
				return
			end

			var_2_5:setScale(0.9)

			return true
		elseif arg_10_0.name == "moved" then
			if arg_2_0:isEventPossibleOnNode(var_2_5.points, arg_10_0.x - var_0_4, arg_10_0.y - var_0_5) then
				return
			end

			var_2_5:setScale(1)
		elseif arg_10_0.name == "ended" then
			var_2_5:setScale(1)

			if not arg_2_0:isEventPossibleOnNode(var_2_5.points, arg_10_0.x - var_0_4, arg_10_0.y - var_0_5) then
				return
			end

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_HUNQI) then
				xyd.Backend.get():request(xyd.mid.HUNQI_GET_CAMPAIGN_INFO, {}, function(arg_11_0, arg_11_1)
					if arg_11_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("hunqi_campaign", arg_11_1)
					end
				end)
			else
				arg_2_0:lockTip(xyd.FunctionID.ID_HUNQI)
			end
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.CHECK_MIDDLE_RED_MARK, function(arg_12_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:checkRedMark(arg_12_0.params)
		end
	end)

	arg_2_0.illusionRedP = arg_2_0:nodeByName("illusion_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.ILLUSION)

	for iter_2_0 = 1, 6 do
		arg_2_0:nodeByName("des" .. iter_2_0):setString(xyd.tables.translation:translation("XUEYUANKAOHE_TIP" .. iter_2_0))
	end
end

function var_0_0.isEventPossibleOnNode(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = arg_13_1[1]
	local var_13_1 = arg_13_1[2]
	local var_13_2 = arg_13_1[3]
	local var_13_3 = arg_13_1[4]
	local var_13_4 = (var_13_1.x - var_13_0.x) * (arg_13_3 - var_13_0.y) - (var_13_1.y - var_13_0.y) * (arg_13_2 - var_13_0.x)
	local var_13_5 = (var_13_2.x - var_13_1.x) * (arg_13_3 - var_13_1.y) - (var_13_2.y - var_13_1.y) * (arg_13_2 - var_13_1.x)
	local var_13_6 = (var_13_3.x - var_13_2.x) * (arg_13_3 - var_13_2.y) - (var_13_3.y - var_13_2.y) * (arg_13_2 - var_13_2.x)
	local var_13_7 = (var_13_0.x - var_13_3.x) * (arg_13_3 - var_13_3.y) - (var_13_0.y - var_13_3.y) * (arg_13_2 - var_13_3.x)

	if var_13_4 >= 0 and var_13_5 >= 0 and var_13_6 >= 0 and var_13_7 >= 0 or var_13_4 <= 0 and var_13_5 <= 0 and var_13_6 <= 0 and var_13_7 <= 0 then
		return true
	else
		return false
	end
end

function var_0_0.addLockAndTips(arg_14_0, arg_14_1, arg_14_2)
	arg_14_0:addLock(arg_14_1, arg_14_2)
	xyd.nodeEventSample(arg_14_1, {}, function()
		arg_14_0:lockTip(arg_14_2)
	end)
end

function var_0_0.addLock(arg_16_0, arg_16_1, arg_16_2)
	arg_16_1:runActionOnce(cc.TintBy:create(0, -100, -100, -100))

	local var_16_0 = xyd.AssetLoader.get():loadSprite("windows/common/lock.png")

	var_16_0:addTo(arg_16_1)

	local var_16_1 = arg_16_1:getContentSize()

	var_16_0:setPosition(var_16_1.width / 2, var_16_1.height / 2)
end

function var_0_0.lockTip(arg_17_0, arg_17_1)
	local var_17_0 = var_0_1:tip(arg_17_1)

	if var_17_0 == "" then
		var_17_0 = var_0_2:translation("FUNCTION_OPEN_TIP_OTHER")
	end

	xyd.WindowManager.get():openWindow("toast", {
		message = var_17_0
	})
end

function var_0_0.checkRedMark(arg_18_0, arg_18_1)
	if arg_18_1 == xyd.CheckMiddleRed.ILLUSION then
		arg_18_0.illusionModel = arg_18_0.illusionModel or xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)

		local var_18_0 = xyd.ServerTime.get():getSecondsOfDay()

		if arg_18_0.illusionModel.isOpen and arg_18_0.illusionModel.times == arg_18_0.illusionModel.initTimes and arg_18_0.illusionModel.buyPre == 0 and var_18_0 > xyd.tables.misc.dungenBossStart and var_18_0 < xyd.tables.misc.dungenBossStop then
			arg_18_0.illusionRedP:setVisible(true)
		else
			arg_18_0.illusionRedP:setVisible(false)
		end
	end
end

function var_0_0.didClose(arg_19_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

return var_0_0
