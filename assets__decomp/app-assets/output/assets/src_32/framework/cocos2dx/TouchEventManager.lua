local var_0_0 = class("TouchEventManager")
local var_0_1 = 0
local var_0_2 = 1
local var_0_3 = 2
local var_0_4 = 3
local var_0_5 = 4
local var_0_6 = 5
local var_0_7 = 6
local var_0_8 = {
	[var_0_2] = "moved",
	[var_0_3] = "ended",
	[var_0_4] = "cancelled"
}

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.ctor(arg_2_0)
	arg_2_0._touchableNodes = {}
	arg_2_0._touchingTargets = {}
	arg_2_0._globalZOrderNodeMap = {}
	arg_2_0._eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	arg_2_0._bDispatching = false
	arg_2_0._nodeCount = 0

	arg_2_0:enableTouchDispatching()
end

function var_0_0.findInTable(arg_3_0, arg_3_1, arg_3_2)
	for iter_3_0, iter_3_1 in ipairs(arg_3_0._touchableNodes) do
		if iter_3_1 == arg_3_2 then
			return iter_3_0
		end
	end

	return false
end

function var_0_0.addTouchableNode(arg_4_0, arg_4_1)
	if not arg_4_1 then
		return
	end

	if arg_4_0:findInTable(arg_4_0._touchableNodes, arg_4_1) then
		return
	end

	table.insert(arg_4_0._touchableNodes, arg_4_1)

	if not arg_4_1._touchID then
		arg_4_1._touchID = arg_4_0._nodeCount
		arg_4_0._nodeCount = arg_4_0._nodeCount + 1
	end
end

function var_0_0.removeTouchableNode(arg_5_0, arg_5_1)
	if arg_5_0._bDispatching then
		return
	end

	local var_5_0 = arg_5_0:findInTable(arg_5_0._touchableNodes, arg_5_1)

	if var_5_0 then
		table.remove(arg_5_0._touchableNodes, var_5_0)
	end
end

function var_0_0.cleanDisabledNode(arg_6_0)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0._touchableNodes) do
		if not iter_6_1 or tolua.isnull(iter_6_1) or not iter_6_1:isTouchEnabled() then
			table.insert(var_6_0, iter_6_0)
		end
	end

	if #var_6_0 == 0 or not next(var_6_0) then
		return
	end

	for iter_6_2 = #var_6_0, 1, -1 do
		table.remove(arg_6_0._touchableNodes, var_6_0[iter_6_2])
	end
end

function var_0_0.onTouchBegan(arg_7_0, arg_7_1, arg_7_2)
	if #arg_7_0._touchableNodes < 1 then
		return
	end

	arg_7_0:sortAllTouchableNodes(arg_7_0._touchableNodes)

	for iter_7_0, iter_7_1 in ipairs(arg_7_0._touchableNodes) do
		repeat
			if not iter_7_1 or tolua.isnull(iter_7_1) then
				break
			end

			local var_7_0 = arg_7_1:getLocation()

			if not arg_7_0:hitTest(iter_7_1, var_7_0) then
				break
			end

			arg_7_0:setNodePath()

			if not arg_7_0:checkTouchEnable(iter_7_1) or not iter_7_1:isTouchEnabled() then
				break
			end

			local var_7_1 = arg_7_0:getNodePath()
			local var_7_2 = true

			for iter_7_2 = #var_7_1, 1, -1 do
				local var_7_3 = var_7_1[iter_7_2]

				var_7_2 = arg_7_0:onNodeTouchBegan(var_7_3, arg_7_1, "capturing")

				if not var_7_2 then
					break
				end
			end

			if not var_7_2 then
				break
			end

			if arg_7_0:onNodeTouchBegan(iter_7_1, arg_7_1) then
				table.insert(arg_7_0._touchingTargets, iter_7_1)
			end

			if iter_7_1:isTouchSwallowEnabled() then
				return
			end
		until true
	end
end

function var_0_0.checkTouchEnable(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0:getNodePath()

	if arg_8_1 and arg_8_1:isRunning() and arg_8_1:isVisible() and arg_8_1:isTouchCaptureEnabled() then
		if var_8_0 then
			table.insert(var_8_0, arg_8_1)
		end

		if not arg_8_1:getParent() then
			return true
		else
			return arg_8_0:checkTouchEnable(arg_8_1:getParent())
		end
	end

	return false
end

function var_0_0.setNodePath(arg_9_0)
	arg_9_0.nodePath_ = {}
end

function var_0_0.getNodePath(arg_10_0)
	return arg_10_0.nodePath_
end

function var_0_0.onNodeTouchBegan(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	arg_11_3 = arg_11_3 or "targeting"

	local var_11_0 = arg_11_2:getLocation()
	local var_11_1 = arg_11_2:getStartLocation()
	local var_11_2 = arg_11_2:getPreviousLocation()
	local var_11_3 = false

	if arg_11_3 == "capturing" then
		var_11_3 = true

		if arg_11_1._LuaListeners and arg_11_1._LuaListeners[cc.NODE_TOUCH_CAPTURE_EVENT] and next(arg_11_1._LuaListeners[cc.NODE_TOUCH_CAPTURE_EVENT]) then
			for iter_11_0, iter_11_1 in ipairs(arg_11_1._LuaListeners[cc.NODE_TOUCH_CAPTURE_EVENT]) do
				var_11_3 = iter_11_1.listener_({
					name = "began",
					phase = arg_11_3,
					x = var_11_0.x,
					y = var_11_0.y,
					startX = var_11_1.x,
					startY = var_11_1.y,
					prevX = var_11_2.x,
					prevY = var_11_2.y
				})
			end
		end
	elseif arg_11_1._LuaListeners and arg_11_1._LuaListeners[cc.NODE_TOUCH_EVENT] and next(arg_11_1._LuaListeners[cc.NODE_TOUCH_EVENT]) then
		for iter_11_2, iter_11_3 in ipairs(arg_11_1._LuaListeners[cc.NODE_TOUCH_EVENT]) do
			var_11_3 = iter_11_3.listener_({
				name = "began",
				phase = arg_11_3,
				x = var_11_0.x,
				y = var_11_0.y,
				startX = var_11_1.x,
				startY = var_11_1.y,
				prevX = var_11_2.x,
				prevY = var_11_2.y
			})
		end
	end

	return var_11_3
end

function var_0_0.hitTest(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1:getCascadeBoundingBox()

	if cc.rectContainsPoint(var_12_0, arg_12_2) then
		return true
	end

	return false
end

function var_0_0.onTouchMoved(arg_13_0, arg_13_1, arg_13_2)
	arg_13_0:dispatchingTouchEvent(arg_13_1, arg_13_2, var_0_2)
end

function var_0_0.onTouchEnded(arg_14_0, arg_14_1, arg_14_2)
	arg_14_0:dispatchingTouchEvent(arg_14_1, arg_14_2, var_0_3)

	arg_14_0._touchingTargets = {}
end

function var_0_0.onTouchCancelled(arg_15_0, arg_15_1, arg_15_2)
	arg_15_0:dispatchingTouchEvent(arg_15_1, arg_15_2, var_0_4)

	arg_15_0._touchingTargets = {}
end

function var_0_0.dispatchingTouchEvent(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	arg_16_0._bDispatching = true

	arg_16_0:dispatchingTouchEventReal(arg_16_1, arg_16_2, arg_16_3)

	arg_16_0._bDispatching = false

	arg_16_0:cleanDisabledNode()
end

function var_0_0.dispatchingTouchEventReal(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	local var_17_0 = #arg_17_0._touchingTargets

	if var_17_0 < 1 then
		return
	end

	local var_17_1 = arg_17_1:getLocation()
	local var_17_2 = arg_17_1:getStartLocation()
	local var_17_3 = arg_17_1:getPreviousLocation()

	for iter_17_0 = 1, var_17_0 do
		local var_17_4 = arg_17_0._touchingTargets[iter_17_0]

		if var_17_4 and not tolua.isnull(var_17_4) and var_17_4:isRunning() and var_17_4._LuaListeners and var_17_4._LuaListeners[cc.NODE_TOUCH_EVENT] and next(var_17_4._LuaListeners[cc.NODE_TOUCH_EVENT]) then
			for iter_17_1, iter_17_2 in ipairs(var_17_4._LuaListeners[cc.NODE_TOUCH_EVENT]) do
				iter_17_2.listener_({
					name = var_0_8[arg_17_3],
					x = var_17_1.x,
					y = var_17_1.y,
					startX = var_17_2.x,
					startY = var_17_2.y,
					prevX = var_17_3.x,
					prevY = var_17_3.y
				})
			end
		end
	end
end

function var_0_0.enableTouchDispatching(arg_18_0)
	if arg_18_0._touchListener then
		return
	end

	arg_18_0._touchListener = cc.EventListenerTouchOneByOne:create()

	if not arg_18_0._touchListener then
		print("create EventListenerTouchOneByOne filure")

		return
	end

	arg_18_0._touchListener:registerScriptHandler(function(arg_19_0, arg_19_1)
		arg_18_0:onTouchBegan(arg_19_0, arg_19_1)

		return true
	end, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_18_0._touchListener:registerScriptHandler(function(arg_20_0, arg_20_1)
		arg_18_0:onTouchMoved(arg_20_0, arg_20_1)
	end, cc.Handler.EVENT_TOUCH_MOVED)
	arg_18_0._touchListener:registerScriptHandler(function(arg_21_0, arg_21_1)
		arg_18_0:onTouchEnded(arg_21_0, arg_21_1)
	end, cc.Handler.EVENT_TOUCH_ENDED)
	arg_18_0._touchListener:registerScriptHandler(function(arg_22_0, arg_22_1)
		arg_18_0:onTouchCancelled(arg_22_0, arg_22_1)
	end, cc.Handler.EVENT_TOUCH_CANCELLED)
	arg_18_0._eventDispatcher:addEventListenerWithFixedPriority(arg_18_0._touchListener, -1)
end

function var_0_0.sortAllTouchableNodes(arg_23_0, arg_23_1)
	if #arg_23_1 < 1 then
		return
	end

	arg_23_0:cleanDisabledNode()

	arg_23_0._nodePriorityIndex = 0
	arg_23_0._nodePriorityMap = {}

	local var_23_0 = cc.Director:getInstance():getRunningScene()

	if not var_23_0 then
		return
	end

	arg_23_0:visitTarget(var_23_0, true)
	table.sort(arg_23_1, function(arg_24_0, arg_24_1)
		if not arg_23_0._nodePriorityMap[arg_24_0._touchID] and arg_23_0._nodePriorityMap[arg_24_1._touchID] then
			return false
		elseif arg_23_0._nodePriorityMap[arg_24_0._touchID] and not arg_23_0._nodePriorityMap[arg_24_1._touchID] then
			return true
		elseif not arg_23_0._nodePriorityMap[arg_24_0._touchID] and not arg_23_0._nodePriorityMap[arg_24_1._touchID] then
			return false
		else
			return arg_23_0._nodePriorityMap[arg_24_0._touchID] > arg_23_0._nodePriorityMap[arg_24_1._touchID]
		end
	end)
end

function var_0_0.visitTarget(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1:getChildren()
	local var_25_1 = #var_25_0
	local var_25_2 = var_25_1

	if var_25_1 > 0 then
		local var_25_3

		for iter_25_0 = 1, var_25_1 do
			local var_25_4 = var_25_0[iter_25_0]

			if var_25_4 and var_25_4:getLocalZOrder() < 0 then
				arg_25_0:visitTarget(var_25_4, false)
			else
				var_25_2 = iter_25_0

				break
			end
		end

		arg_25_0._globalZOrderNodeMap[arg_25_1:getGlobalZOrder()] = arg_25_0._globalZOrderNodeMap[arg_25_1:getGlobalZOrder()] or {}

		table.insert(arg_25_0._globalZOrderNodeMap[arg_25_1:getGlobalZOrder()], arg_25_1)

		for iter_25_1 = var_25_2, var_25_1 do
			local var_25_5 = var_25_0[iter_25_1]

			if var_25_5 then
				arg_25_0:visitTarget(var_25_5, false)
			end
		end
	else
		arg_25_0._globalZOrderNodeMap[arg_25_1:getGlobalZOrder()] = arg_25_0._globalZOrderNodeMap[arg_25_1:getGlobalZOrder()] or {}

		table.insert(arg_25_0._globalZOrderNodeMap[arg_25_1:getGlobalZOrder()], arg_25_1)
	end

	if arg_25_2 then
		local var_25_6 = {}

		for iter_25_2, iter_25_3 in pairs(arg_25_0._globalZOrderNodeMap) do
			table.insert(var_25_6, iter_25_2)
		end

		table.sort(var_25_6, function(arg_26_0, arg_26_1)
			return arg_26_0 < arg_26_1
		end)

		for iter_25_4, iter_25_5 in ipairs(var_25_6) do
			for iter_25_6, iter_25_7 in ipairs(arg_25_0._globalZOrderNodeMap[iter_25_5]) do
				if iter_25_7._touchID then
					arg_25_0._nodePriorityMap[iter_25_7._touchID] = arg_25_0._nodePriorityIndex
					arg_25_0._nodePriorityIndex = arg_25_0._nodePriorityIndex + 1
				end
			end
		end

		arg_25_0._globalZOrderNodeMap = {}
	end
end

return var_0_0
