local var_0_0 = require("framework.cocos2dx.TouchEventManager")
local var_0_1 = cc
local var_0_2 = var_0_1.Node

var_0_1.NODE_EVENT = 1
var_0_1.NODE_ENTER_FRAME_EVENT = 2
var_0_1.NODE_TOUCH_EVENT = 3
var_0_1.KEYPAD_EVENT = 4
var_0_1.ACCELEROMETER_EVENT = 5
var_0_1.TOUCH_MODE_ALL_AT_ONCE = cc.TOUCHES_ALL_AT_ONCE
var_0_1.TOUCH_MODE_ONE_BY_ONE = cc.TOUCHES_ONE_BY_ONE

local function var_0_3(arg_1_0, arg_1_1)
	local var_1_0 = var_0_1.rect(arg_1_0.x, arg_1_0.y, arg_1_0.width, arg_1_0.height)

	return var_0_1.rectContainsPoint(var_1_0, arg_1_1)
end

function var_0_2.align(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	arg_2_0:setAnchorPoint(display.ANCHOR_POINTS[arg_2_1])

	if arg_2_2 and arg_2_3 then
		arg_2_0:setPosition(arg_2_2, arg_2_3)
	end

	return arg_2_0
end

function var_0_2.schedule(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = var_0_1.Sequence:create(var_0_1.DelayTime:create(arg_3_2), var_0_1.CallFunc:create(arg_3_1))
	local var_3_1 = var_0_1.RepeatForever:create(var_3_0)

	arg_3_0:runAction(var_3_1)

	return var_3_1
end

function var_0_2.performWithDelay(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = var_0_1.Sequence:create(var_0_1.DelayTime:create(arg_4_2), var_0_1.CallFunc:create(arg_4_1))

	arg_4_0:runAction(var_4_0)

	return var_4_0
end

function var_0_2.getCascadeBoundingBox(arg_5_0)
	local var_5_0
	local var_5_1 = tolua.getcfunction(arg_5_0, "getCascadeBoundingBox")

	if var_5_1 then
		var_5_0 = var_5_1(arg_5_0)
	end

	var_5_0.origin = {
		x = var_5_0.x,
		y = var_5_0.y
	}
	var_5_0.size = {
		width = var_5_0.width,
		height = var_5_0.height
	}
	var_5_0.containsPoint = var_0_3

	return var_5_0
end

function var_0_2.hitTest(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0:getCascadeBoundingBox()

	if var_0_1.rectContainsPoint(var_6_0, arg_6_1) then
		return true
	end

	return false
end

function var_0_2.removeSelf(arg_7_0)
	arg_7_0:removeFromParent(true)
end

function var_0_2.onEnter(arg_8_0)
	return
end

function var_0_2.onExit(arg_9_0)
	local var_9_0 = arg_9_0.name or ""

	print("node  exit " .. var_9_0)
end

function var_0_2.onEnterTransitionFinish(arg_10_0)
	return
end

function var_0_2.onExitTransitionStart(arg_11_0)
	return
end

function var_0_2.onCleanup(arg_12_0)
	return
end

function var_0_2.setAccelerometerEnabled(arg_13_0, arg_13_1)
	cc.Device:setAccelerometerEnabled(arg_13_1)

	if not arg_13_1 then
		return
	end

	local var_13_0 = cc.EventListenerAcceleration:create(function(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4)
		if arg_13_0._LuaListeners and arg_13_0._LuaListeners[var_0_1.ACCELEROMETER_EVENT] and next(arg_13_0._LuaListeners[var_0_1.ACCELEROMETER_EVENT]) then
			for iter_14_0, iter_14_1 in pairs(arg_13_0._LuaListeners) do
				iter_14_1.listener_({
					x = arg_14_1,
					y = arg_14_2,
					z = arg_14_3,
					timestamp = arg_14_4
				})
			end
		end
	end)

	arg_13_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_13_0, arg_13_0)
end

function var_0_2.setNodeEventEnabled(arg_15_0, arg_15_1)
	if not arg_15_0.name then
		local var_15_0 = ""
	end

	if arg_15_1 then
		local function var_15_1(arg_16_0)
			local var_16_0 = arg_16_0.name

			if var_16_0 == "enter" then
				arg_15_0:onEnter()
			elseif var_16_0 == "exit" then
				arg_15_0:onExit()
			elseif var_16_0 == "enterTransitionFinish" then
				arg_15_0:onEnterTransitionFinish()
			elseif var_16_0 == "exitTransitionStart" then
				arg_15_0:onExitTransitionStart()
			elseif var_16_0 == "cleanup" then
				arg_15_0:onCleanup()
			end
		end

		arg_15_0:addNodeEventListener(var_0_1.NODE_EVENT, var_15_1)
	else
		arg_15_0:removeNodeEventListenersByEvent(var_0_1.NODE_EVENT)
	end

	return arg_15_0
end

local function var_0_4(arg_17_0)
	local var_17_0

	return arg_17_0 == 6 and "back" or arg_17_0 == 16 and "menu" or tostring(arg_17_0)
end

function var_0_2.setKeypadEnabled(arg_18_0, arg_18_1)
	if arg_18_1 == arg_18_0:isKeypadEnabled() then
		return arg_18_0
	end

	local var_18_0 = arg_18_0:getEventDispatcher()

	if arg_18_1 then
		local function var_18_1(arg_19_0, arg_19_1)
			if arg_18_0._LuaListeners[var_0_1.KEYPAD_EVENT] and next(arg_18_0._LuaListeners[var_0_1.KEYPAD_EVENT]) then
				for iter_19_0, iter_19_1 in pairs(arg_18_0._LuaListeners[var_0_1.KEYPAD_EVENT]) do
					iter_19_1.listener_({
						type = "Pressed",
						code = arg_19_0,
						key = var_0_4(arg_19_0)
					})
				end
			end
		end

		local function var_18_2(arg_20_0, arg_20_1)
			if arg_18_0._LuaListeners[var_0_1.KEYPAD_EVENT] and next(arg_18_0._LuaListeners[var_0_1.KEYPAD_EVENT]) then
				for iter_20_0, iter_20_1 in pairs(arg_18_0._LuaListeners[var_0_1.KEYPAD_EVENT]) do
					iter_20_1.listener_({
						type = "Released",
						code = arg_20_0,
						key = var_0_4(arg_20_0)
					})
				end
			end
		end

		local var_18_3 = var_0_1.EventListenerKeyboard:create()

		var_18_3:registerScriptHandler(var_18_1, var_0_1.Handler.EVENT_KEYBOARD_PRESSED)
		var_18_3:registerScriptHandler(var_18_2, var_0_1.Handler.EVENT_KEYBOARD_RELEASED)
		var_18_0:addEventListenerWithSceneGraphPriority(var_18_3, arg_18_0)

		arg_18_0.__key_event_handle__ = var_18_3
	else
		var_18_0:removeEventListener(arg_18_0.__key_event_handle__)

		arg_18_0.__key_event_handle__ = nil
	end

	return arg_18_0
end

function var_0_2.isKeypadEnabled(arg_21_0)
	if arg_21_0.__key_event_handle__ then
		return true
	end

	return false
end

function var_0_2.scheduleUpdate(arg_22_0)
	local function var_22_0(arg_23_0)
		if arg_22_0._LuaListeners[var_0_1.NODE_ENTER_FRAME_EVENT] and next(arg_22_0._LuaListeners[var_0_1.NODE_ENTER_FRAME_EVENT]) then
			for iter_23_0, iter_23_1 in pairs(arg_22_0._LuaListeners[var_0_1.NODE_ENTER_FRAME_EVENT]) do
				iter_23_1.listener_(arg_23_0)
			end
		end
	end

	arg_22_0:scheduleUpdateWithPriorityLua(var_22_0, 0)

	return arg_22_0
end

function var_0_2.setTouchMode(arg_24_0, arg_24_1)
	if arg_24_1 ~= var_0_1.TOUCH_MODE_ALL_AT_ONCE and arg_24_1 ~= var_0_1.TOUCHES_ONE_BY_ONE then
		print("== wrong mode", arg_24_1)

		return
	end

	arg_24_0._luaTouchMode = arg_24_1
end

function var_0_2.setTouchEnabled(arg_25_0, arg_25_1)
	arg_25_0._touchEnable = arg_25_0._touchEnable or false

	if arg_25_0._touchEnable == arg_25_1 then
		return
	end

	arg_25_0._touchEnable = arg_25_1

	if arg_25_0._swallowTouchEnable == nil then
		arg_25_0:setTouchSwallowEnabled(true)
	end

	if arg_25_1 then
		var_0_0.get():addTouchableNode(arg_25_0)
	else
		var_0_0.get():removeTouchableNode(arg_25_0)
	end
end

function var_0_2.setAllAtOnceTouchEnabled(arg_26_0, arg_26_1)
	local var_26_0 = arg_26_0:getEventDispatcher()

	if arg_26_0._allAtOnceTouchListener then
		var_26_0:removeEventListener(arg_26_0._allAtOnceTouchListener)

		arg_26_0._allAtOnceTouchListener = nil
	end

	arg_26_0:setNodeEventEnabled(arg_26_1)

	if not arg_26_1 then
		return
	end

	arg_26_0.targetPoints = {}
	arg_26_0._allAtOnceTouchListener = var_0_1.EventListenerTouchOneByOne:create()

	arg_26_0._allAtOnceTouchListener:setSwallowTouches(true)

	local function var_26_1(arg_27_0, arg_27_1)
		local var_27_0 = arg_27_0:getLocation()
		local var_27_1 = arg_27_0:getPreviousLocation()
		local var_27_2 = {}
		local var_27_3 = {
			id = arg_27_0:getId(),
			prevX = var_27_1.x,
			prevY = var_27_1.y,
			x = var_27_0.x,
			y = var_27_0.y
		}

		table.insert(var_27_2, var_27_3)

		if arg_27_1 == "began" then
			if not arg_26_0:isVisible(true) or not arg_26_0:hitTest(var_27_0) then
				return false
			end

			if next(arg_26_0.targetPoints) then
				arg_27_1 = "added"
			end

			table.insert(arg_26_0.targetPoints, var_27_3)
		elseif arg_27_1 == "ended" then
			if #arg_26_0.targetPoints > 1 then
				arg_27_1 = "removed"

				for iter_27_0, iter_27_1 in ipairs(arg_26_0.targetPoints) do
					if iter_27_1.id == arg_27_0:getId() then
						table.remove(arg_26_0.targetPoints, iter_27_0)

						break
					end
				end
			else
				arg_26_0.targetPoints = {}
			end
		end

		if arg_26_0._LuaListeners and arg_26_0._LuaListeners[var_0_1.NODE_TOUCH_EVENT] and next(arg_26_0._LuaListeners[var_0_1.NODE_TOUCH_EVENT]) then
			for iter_27_2, iter_27_3 in ipairs(arg_26_0._LuaListeners[var_0_1.NODE_TOUCH_EVENT]) do
				iter_27_3.listener_({
					phase = "targeting",
					mode = var_0_1.TOUCH_MODE_ALL_AT_ONCE,
					name = arg_27_1,
					points = var_27_2
				})
			end
		end

		return true
	end

	arg_26_0._allAtOnceTouchListener:registerScriptHandler(function(arg_28_0, arg_28_1)
		return var_26_1(arg_28_0, "began")
	end, var_0_1.Handler.EVENT_TOUCH_BEGAN)
	arg_26_0._allAtOnceTouchListener:registerScriptHandler(function(arg_29_0, arg_29_1)
		var_26_1(arg_29_0, "moved")
	end, var_0_1.Handler.EVENT_TOUCH_MOVED)
	arg_26_0._allAtOnceTouchListener:registerScriptHandler(function(arg_30_0, arg_30_1)
		var_26_1(arg_30_0, "ended")
	end, var_0_1.Handler.EVENT_TOUCH_ENDED)
	arg_26_0._allAtOnceTouchListener:registerScriptHandler(function(arg_31_0, arg_31_1)
		var_26_1(arg_31_0, "cancelled")
	end, var_0_1.Handler.EVENT_TOUCH_CANCELLED)
	var_26_0:addEventListenerWithSceneGraphPriority(arg_26_0._allAtOnceTouchListener, arg_26_0)
end

function var_0_2.isTouchEnabled(arg_32_0)
	return arg_32_0._touchEnable or false
end

function var_0_2.setTouchSwallowEnabled(arg_33_0, arg_33_1)
	arg_33_0._swallowTouchEnable = arg_33_1
end

function var_0_2.isTouchSwallowEnabled(arg_34_0)
	return arg_34_0._swallowTouchEnable
end

function var_0_2.setTouchCaptureEnabled(arg_35_0, arg_35_1)
	arg_35_0._captureTouchEnable = arg_35_1
end

function var_0_2.isTouchCaptureEnabled(arg_36_0)
	return arg_36_0._captureTouchEnable or true
end

function var_0_2.addNodeEventListener(arg_37_0, arg_37_1, arg_37_2)
	arg_37_0._LuaListeners = arg_37_0._LuaListeners or {}

	local var_37_0 = (arg_37_0._nextScriptEventHandleIndex_ or 0) + 1

	arg_37_0._nextScriptEventHandleIndex_ = var_37_0

	if arg_37_1 == var_0_1.NODE_EVENT then
		arg_37_0:registerScriptHandler(function(arg_38_0)
			if arg_37_0._LuaListeners[var_0_1.NODE_EVENT] and next(arg_37_0._LuaListeners[var_0_1.NODE_EVENT]) then
				for iter_38_0, iter_38_1 in pairs(arg_37_0._LuaListeners[var_0_1.NODE_EVENT]) do
					iter_38_1.listener_({
						name = arg_38_0
					})
				end
			end
		end)
	end

	local var_37_1 = {
		index_ = var_37_0,
		listener_ = arg_37_2
	}

	arg_37_0._LuaListeners[arg_37_1] = arg_37_0._LuaListeners[arg_37_1] or {}

	table.insert(arg_37_0._LuaListeners[arg_37_1], var_37_1)

	return arg_37_0._nextScriptEventHandleIndex_
end

function var_0_2.removeNodeEventListener(arg_39_0, arg_39_1)
	if not arg_39_0._LuaListeners then
		return
	end

	for iter_39_0, iter_39_1 in pairs(arg_39_0._LuaListeners) do
		for iter_39_2, iter_39_3 in ipairs(iter_39_1) do
			if iter_39_3.index_ == arg_39_1 then
				table.remove(iter_39_1, iter_39_2)

				if #iter_39_1 == 0 then
					arg_39_0:removeNodeEventListenersByEvent(iter_39_0)
				end

				return
			end
		end
	end
end

function var_0_2.removeNodeEventListenersByEvent(arg_40_0, arg_40_1)
	if not arg_40_0._LuaListeners then
		return
	end

	if arg_40_1 == var_0_1.KEYPAD_EVENT then
		arg_40_0:setKeypadEnabled(false)
	elseif arg_40_1 == var_0_1.NODE_EVENT then
		arg_40_0:unregisterScriptHandler()
	elseif arg_40_1 == var_0_1.NODE_ENTER_FRAME_EVENT then
		arg_40_0:unscheduleUpdate()
	elseif arg_40_1 == var_0_1.NODE_TOUCH_EVENT then
		arg_40_0:setTouchEnabled(false)
	elseif arg_40_1 == var_0_1.ACCELEROMETER_EVENT then
		cc.Device:setAccelerometerEnabled(false)
	end

	arg_40_0._LuaListeners[arg_40_1] = nil
end

function var_0_2.removeAllNodeEventListeners(arg_41_0)
	arg_41_0:removeNodeEventListenersByEvent(var_0_1.NODE_EVENT)
	arg_41_0:removeNodeEventListenersByEvent(var_0_1.NODE_ENTER_FRAME_EVENT)
	arg_41_0:removeNodeEventListenersByEvent(var_0_1.NODE_TOUCH_EVENT)
	arg_41_0:removeNodeEventListenersByEvent(var_0_1.KEYPAD_EVENT)
	arg_41_0:removeNodeEventListenersByEvent(var_0_1.ACCELEROMETER_EVENT)
end

function var_0_2.clone(arg_42_0)
	local var_42_0 = arg_42_0:createCloneInstance_()

	var_42_0:copyProperties_(arg_42_0)
	var_42_0:copySpecialPeerVal_(arg_42_0)
	var_42_0:copyClonedWidgetChildren_(arg_42_0)

	return var_42_0
end

function var_0_2.createCloneInstance_(arg_43_0)
	local var_43_0 = tolua.type(arg_43_0)
	local var_43_1

	if var_43_0 == "cc.Sprite" then
		var_43_1 = cc.Sprite:create()
	elseif var_43_0 == "ccui.Scale9Sprite" then
		var_43_1 = ccui.Scale9Sprite:create()
	elseif var_43_0 == "cc.LayerColor" then
		local var_43_2 = arg_43_0:getColor()

		var_43_2.a = arg_43_0:getOpacity()
		var_43_1 = cc.LayerColor:create(var_43_2)
	else
		var_43_1 = display.newNode()

		if var_43_0 ~= "cc.Node" then
			print("WARING! treat " .. var_43_0 .. " as cc.Node")
		end
	end

	return var_43_1
end

function var_0_2.copyClonedWidgetChildren_(arg_44_0, arg_44_1)
	local var_44_0 = arg_44_1:getChildren()

	if not var_44_0 or #var_44_0 == 0 then
		return
	end

	for iter_44_0, iter_44_1 in ipairs(var_44_0) do
		local var_44_1 = iter_44_1:clone()

		if var_44_1 then
			arg_44_0:addChild(var_44_1)
		end
	end
end

function var_0_2.copySpecialProperties_(arg_45_0, arg_45_1)
	local var_45_0 = tolua.type(arg_45_0)

	if var_45_0 == "cc.Sprite" then
		arg_45_0:setSpriteFrame(arg_45_1:getSpriteFrame())
	elseif var_45_0 == "ccui.Scale9Sprite" then
		arg_45_0:setSpriteFrame(arg_45_1:getSprite():getSpriteFrame())
	elseif var_45_0 == "cc.LayerColor" then
		arg_45_0:setTouchEnabled(false)
	end

	local var_45_1 = tolua.getpeer(arg_45_1)

	if var_45_1 then
		local var_45_2 = clone(var_45_1)

		tolua.setpeer(arg_45_0, var_45_2)
	end
end

function var_0_2.copyProperties_(arg_46_0, arg_46_1)
	arg_46_0:setVisible(arg_46_1:isVisible())
	arg_46_0:setTouchEnabled(arg_46_1:isTouchEnabled())
	arg_46_0:setLocalZOrder(arg_46_1:getLocalZOrder())
	arg_46_0:setTag(arg_46_1:getTag())
	arg_46_0:setName(arg_46_1:getName())
	arg_46_0:setContentSize(arg_46_1:getContentSize())
	arg_46_0:setPosition(arg_46_1:getPosition())
	arg_46_0:setAnchorPoint(arg_46_1:getAnchorPoint())
	arg_46_0:setScaleX(arg_46_1:getScaleX())
	arg_46_0:setScaleY(arg_46_1:getScaleY())
	arg_46_0:setRotation(arg_46_1:getRotation())
	arg_46_0:setRotationSkewX(arg_46_1:getRotationSkewX())
	arg_46_0:setRotationSkewY(arg_46_1:getRotationSkewY())

	if arg_46_0.isFlippedX and arg_46_1.isFlippedX then
		arg_46_0:setFlippedX(arg_46_1:isFlippedX())
		arg_46_0:setFlippedY(arg_46_1:isFlippedY())
	end

	arg_46_0:setColor(arg_46_1:getColor())
	arg_46_0:setOpacity(arg_46_1:getOpacity())
	arg_46_0:copySpecialProperties_(arg_46_1)
end

function var_0_2.copySpecialPeerVal_(arg_47_0, arg_47_1)
	if arg_47_1.name then
		arg_47_0.name = arg_47_1.name
	end
end

function var_0_2.setupMaskShader(arg_48_0)
	if not arg_48_0.isMvpShader_ then
		arg_48_0.grayScale = 1

		local var_48_0 = cc.GLProgram:createWithByteArrays(xyd.shader.MVP_VERT_STRING, xyd.shader.MVP_FRAG_STRING)
		local var_48_1 = cc.GLProgramState:create(var_48_0)

		arg_48_0.MaskColorLocation_ = gl.getUniformLocation(var_48_0:getProgram(), "maskColor")
		arg_48_0.GrayScaleLocation_ = gl.getUniformLocation(var_48_0:getProgram(), "grayScale")

		arg_48_0:setGLProgramState(var_48_1)

		arg_48_0.isMvpShader_ = true
		arg_48_0.isNoMvpShader_ = nil
	end
end

function var_0_2.setMaskColor(arg_49_0, arg_49_1)
	if not arg_49_0:isGLStateDiff(arg_49_1 or xyd.shader.Default_Dusk_Color) then
		return
	end

	arg_49_0:setupMaskShader()

	local var_49_0 = arg_49_1 or xyd.shader.Default_Dusk_Color

	arg_49_0.glState_ = var_49_0

	arg_49_0:getGLProgramState():setUniformVec4(arg_49_0.MaskColorLocation_, cc.v4Fromc4(var_49_0))
end

function var_0_2.unsetMaskColor(arg_50_0)
	if not arg_50_0:isGLStateDiff(xyd.shader.Default_Color) then
		return
	end

	arg_50_0:setupMaskShader()

	local var_50_0 = xyd.shader.Default_Color

	arg_50_0.glState_ = var_50_0

	arg_50_0:getGLProgramState():setUniformVec4(arg_50_0.MaskColorLocation_, cc.v4Fromc4(var_50_0))
end

function var_0_2.setGrayScale(arg_51_0, arg_51_1)
	local var_51_0 = arg_51_1 or arg_51_0.grayScale

	if not arg_51_0:isGLStateDiff(var_51_0) then
		return
	end

	arg_51_0:setupMaskShader()

	arg_51_0.glStateGray_ = var_51_0

	arg_51_0:getGLProgramState():setUniformVec4(arg_51_0.MaskColorLocation_, cc.v4Fromc4(xyd.shader.Clear_Color))
	arg_51_0:getGLProgramState():setUniformFloat(arg_51_0.GrayScaleLocation_, var_51_0)
end

function var_0_2.unsetGrayScale(arg_52_0)
	if not arg_52_0:isGLStateDiff(xyd.shader.Default_Gray_Ratio) then
		return
	end

	arg_52_0:setupMaskShader()

	arg_52_0.glStateGray_ = xyd.shader.Default_Gray_Ratio

	arg_52_0:getGLProgramState():setUniformVec4(arg_52_0.MaskColorLocation_, cc.v4Fromc4(xyd.shader.Clear_Color))
	arg_52_0:getGLProgramState():setUniformFloat(arg_52_0.GrayScaleLocation_, xyd.shader.Default_Gray_Ratio)
end

function var_0_2.isGLStateDiff(arg_53_0, arg_53_1)
	arg_53_0.glState_ = arg_53_0.glState_ or xyd.shader.Default_Color
	arg_53_0.glStateGray_ = arg_53_0.glStateGray_ or xyd.shader.Default_Gray_Ratio

	if type(arg_53_1) == "number" then
		return arg_53_0.glStateGray_ ~= arg_53_1
	end

	if type(arg_53_1) == "table" and arg_53_0.glState_ == arg_53_1 then
		return false
	end

	for iter_53_0, iter_53_1 in pairs(arg_53_0.glState_) do
		if arg_53_1[iter_53_0] ~= iter_53_1 then
			return true
		end
	end

	return false
end

function var_0_2.runActionOnce(arg_54_0, arg_54_1, arg_54_2, arg_54_3, arg_54_4)
	local var_54_0 = {}

	if arg_54_4 ~= nil then
		table.insert(var_54_0, cc.DelayTime:create(arg_54_4))
	end

	table.insert(var_54_0, arg_54_1)

	if arg_54_2 then
		table.insert(var_54_0, cc.RemoveSelf:create())
	end

	if arg_54_3 ~= nil then
		table.insert(var_54_0, cc.CallFunc:create(arg_54_3))
	end

	if #var_54_0 == 1 then
		arg_54_0:runAction(var_54_0[1])
	else
		arg_54_0:runAction(transition.sequence(var_54_0))
	end

	return arg_54_0
end
