local var_0_0 = class("SubResearchWindow", import("app.common.ui.BaseWindow"))
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

	local var_2_0 = arg_2_0:nodeByName("forge_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_FUMO) then
		xyd.nodeEventSample(var_2_0, {}, function()
			xyd.WindowManager.get():openWindow("fumo")
		end)
	else
		arg_2_0:addLockAndTips(var_2_0, xyd.FunctionID.ID_FUMO)
	end

	local var_2_1 = arg_2_0:nodeByName("event_centre_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ACT_CENTRE) then
		xyd.nodeEventSample(var_2_1, {}, function()
			xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE):getBuildingList({}, function(arg_5_0)
				if arg_5_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("event_centre")
				end
			end)
		end)
	else
		arg_2_0:addLockAndTips(var_2_1, xyd.FunctionID.ID_ACT_CENTRE)
	end

	local var_2_2 = arg_2_0:nodeByName("wash_node")

	var_2_2:setTouchEnabled(true)
	var_2_2:setTouchSwallowEnabled(false)

	if not arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PRACTICE) then
		arg_2_0:addLock(var_2_2)
	end

	var_2_2.points = {
		{
			x = 402,
			y = 83
		},
		{
			x = 402,
			y = 386
		},
		{
			x = 685,
			y = 386
		},
		{
			x = 586,
			y = 83
		}
	}

	var_2_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			if not arg_2_0:isEventPossibleOnNode(var_2_2.points, arg_6_0.x - var_0_4, arg_6_0.y - var_0_5) then
				return
			end

			var_2_2:setScale(0.9)

			return true
		elseif arg_6_0.name == "moved" then
			if arg_2_0:isEventPossibleOnNode(var_2_2.points, arg_6_0.x - var_0_4, arg_6_0.y - var_0_5) then
				return
			end

			var_2_2:setScale(1)
		elseif arg_6_0.name == "ended" then
			var_2_2:setScale(1)

			if not arg_2_0:isEventPossibleOnNode(var_2_2.points, arg_6_0.x - var_0_4, arg_6_0.y - var_0_5) then
				return
			end

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PRACTICE) then
				xyd.WindowManager.get():openWindow("wash_hero")
			else
				arg_2_0:lockTip(xyd.FunctionID.ID_PRACTICE)
			end
		end
	end)

	local var_2_3 = arg_2_0:nodeByName("contract_node")

	var_2_3:setTouchEnabled(true)
	var_2_3:setTouchSwallowEnabled(false)

	if not arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_SUPER_PARTNER) then
		arg_2_0:addLock(var_2_3)
	end

	var_2_3.points = {
		{
			x = 602,
			y = 83
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
			y = 83
		}
	}

	var_2_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			if not arg_2_0:isEventPossibleOnNode(var_2_3.points, arg_7_0.x - var_0_4, arg_7_0.y - var_0_5) then
				return
			end

			var_2_3:setScale(0.9)

			return true
		elseif arg_7_0.name == "moved" then
			if arg_2_0:isEventPossibleOnNode(var_2_3.points, arg_7_0.x - var_0_4, arg_7_0.y - var_0_5) then
				return
			end

			var_2_3:setScale(1)
		elseif arg_7_0.name == "ended" then
			var_2_3:setScale(1)

			if not arg_2_0:isEventPossibleOnNode(var_2_3.points, arg_7_0.x - var_0_4, arg_7_0.y - var_0_5) then
				return
			end

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_SUPER_PARTNER) then
				xyd.WindowManager.get():openWindow("super_partner")
			else
				arg_2_0:lockTip(xyd.FunctionID.ID_SUPER_PARTNER)
			end
		end
	end)

	local var_2_4 = arg_2_0:nodeByName("inscription_node")

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_INSCRIPTION) then
		xyd.nodeEventSample(var_2_4, {}, function()
			xyd.WindowManager.get():openWindow("inscription")
		end)
	else
		arg_2_0:addLockAndTips(var_2_4, xyd.FunctionID.ID_INSCRIPTION)
	end

	arg_2_0.eventCentreP = arg_2_0:nodeByName("event_centre_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.EVENT_CENTRE_CANCEL)

	arg_2_0.washRedP = arg_2_0:nodeByName("wash_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.PRACTICE)

	arg_2_0.contractRedP = arg_2_0:nodeByName("contract_red_p")

	arg_2_0:checkRedMark(xyd.CheckMiddleRed.SUPER_PARTNER)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.CHECK_MIDDLE_RED_MARK, function(arg_9_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:checkRedMark(arg_9_0.params)
		end
	end)

	for iter_2_0 = 1, 5 do
		arg_2_0:nodeByName("des" .. iter_2_0):setString(xyd.tables.translation:translation("YANJIUSUO_TIP" .. iter_2_0))
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
	if arg_15_1 == xyd.CheckMiddleRed.EVENT_CENTRE then
		arg_15_0.eventCentreP:setVisible(true)
	elseif arg_15_1 == xyd.CheckMiddleRed.EVENT_CENTRE_CANCEL then
		arg_15_0.eventCentreP:setVisible(false)
	elseif arg_15_1 == xyd.CheckMiddleRed.PRACTICE then
		arg_15_0.washRedP:setVisible(arg_15_0.selfPlayer:checkPracticeRedMark())
	elseif arg_15_1 == xyd.CheckMiddleRed.SUPER_PARTNER then
		arg_15_0.contractRedP:setVisible(arg_15_0.selfPlayer:checkSuperPartnerRedMark())
	end
end

function var_0_0.didClose(arg_16_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

return var_0_0
