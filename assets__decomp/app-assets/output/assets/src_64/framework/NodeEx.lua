local var_0_0 = cc
local var_0_1 = var_0_0.Node

var_0_0.NODE_EVENT = 1
var_0_0.NODE_ENTER_FRAME_EVENT = 2
var_0_0.NODE_TOUCH_EVENT = 3
var_0_0.KEYPAD_EVENT = 4
var_0_0.ACCELEROMETER_EVENT = 5
var_0_0.TOUCH_MODE_ALL_AT_ONCE = cc.TOUCHES_ALL_AT_ONCE
var_0_0.TOUCH_MODE_ONE_BY_ONE = cc.TOUCHES_ONE_BY_ONE

local function var_0_2(arg_1_0, arg_1_1)
	local var_1_0 = var_0_0.rect(arg_1_0.x, arg_1_0.y, arg_1_0.width, arg_1_0.height)

	return var_0_0.rectContainsPoint(var_1_0, arg_1_1)
end

function var_0_1.align(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	arg_2_0:setAnchorPoint(display.ANCHOR_POINTS[arg_2_1])

	if arg_2_2 and arg_2_3 then
		arg_2_0:setPosition(arg_2_2, arg_2_3)
	end

	return arg_2_0
end

function var_0_1.schedule(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = var_0_0.Sequence:create(var_0_0.DelayTime:create(arg_3_2), var_0_0.CallFunc:create(arg_3_1))
	local var_3_1 = var_0_0.RepeatForever:create(var_3_0)

	arg_3_0:runAction(var_3_1)

	return var_3_1
end

function var_0_1.performWithDelay(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = var_0_0.Sequence:create(var_0_0.DelayTime:create(arg_4_2), var_0_0.CallFunc:create(arg_4_1))

	arg_4_0:runAction(var_4_0)

	return var_4_0
end

function var_0_1.hitTest(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0:convertToNodeSpace(arg_5_1)
	local var_5_1 = arg_5_0:getContentSize()

	var_5_1.x = 0
	var_5_1.y = 0

	if var_0_0.rectContainsPoint(var_5_1, var_5_0) then
		return true
	end

	return false
end

function var_0_1.removeSelf(arg_6_0)
	arg_6_0:removeFromParent(true)
end

function var_0_1.onEnter(arg_7_0)
	return
end

function var_0_1.onExit(arg_8_0)
	return
end

function var_0_1.onEnterTransitionFinish(arg_9_0)
	return
end

function var_0_1.onExitTransitionStart(arg_10_0)
	return
end

function var_0_1.onCleanup(arg_11_0)
	return
end

function var_0_1.setAccelerometerEnabled(arg_12_0, arg_12_1)
	cc.Device:setAccelerometerEnabled(arg_12_1)

	if not arg_12_1 then
		return
	end

	local var_12_0 = cc.EventListenerAcceleration:create(function(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
		arg_12_0._LuaListeners[var_0_0.ACCELEROMETER_EVENT]({
			x = arg_13_1,
			y = arg_13_2,
			z = arg_13_3,
			timestamp = arg_13_4
		})
	end)

	arg_12_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_12_0, arg_12_0)
end

function var_0_1.setNodeEventEnabled(arg_14_0, arg_14_1)
	if arg_14_1 then
		local function var_14_0(arg_15_0)
			local var_15_0 = arg_15_0.name

			if var_15_0 == "enter" then
				arg_14_0:onEnter()
			elseif var_15_0 == "exit" then
				arg_14_0:onExit()
			elseif var_15_0 == "enterTransitionFinish" then
				arg_14_0:onEnterTransitionFinish()
			elseif var_15_0 == "exitTransitionStart" then
				arg_14_0:onExitTransitionStart()
			elseif var_15_0 == "cleanup" then
				arg_14_0:onCleanup()
			end
		end

		arg_14_0:addNodeEventListener(var_0_0.NODE_EVENT, var_14_0)
	else
		arg_14_0:removeNodeEventListener(var_0_0.NODE_EVENT)
	end

	return arg_14_0
end

local function var_0_3(arg_16_0)
	local var_16_0

	return arg_16_0 == 6 and "back" or arg_16_0 == 16 and "menu" or tostring(arg_16_0)
end

function var_0_1.setKeypadEnabled(arg_17_0, arg_17_1)
	if arg_17_1 == arg_17_0:isKeypadEnabled() then
		return arg_17_0
	end

	local var_17_0 = arg_17_0:getEventDispatcher()

	if arg_17_1 then
		local function var_17_1(arg_18_0, arg_18_1)
			arg_17_0._LuaListeners[var_0_0.KEYPAD_EVENT]({
				type = "Pressed",
				code = arg_18_0,
				key = var_0_3(arg_18_0)
			})
		end

		local function var_17_2(arg_19_0, arg_19_1)
			arg_17_0._LuaListeners[var_0_0.KEYPAD_EVENT]({
				type = "Released",
				code = arg_19_0,
				key = var_0_3(arg_19_0)
			})
		end

		local var_17_3 = var_0_0.EventListenerKeyboard:create()

		var_17_3:registerScriptHandler(var_17_1, var_0_0.Handler.EVENT_KEYBOARD_PRESSED)
		var_17_3:registerScriptHandler(var_17_2, var_0_0.Handler.EVENT_KEYBOARD_RELEASED)
		var_17_0:addEventListenerWithSceneGraphPriority(var_17_3, arg_17_0)

		arg_17_0.__key_event_handle__ = var_17_3
	else
		var_17_0:removeEventListener(arg_17_0.__key_event_handle__)

		arg_17_0.__key_event_handle__ = nil
	end

	return arg_17_0
end

function var_0_1.isKeypadEnabled(arg_20_0)
	if arg_20_0.__key_event_handle__ then
		return true
	end

	return false
end

function var_0_1.scheduleUpdate(arg_21_0)
	local function var_21_0(arg_22_0)
		arg_21_0._LuaListeners[var_0_0.NODE_ENTER_FRAME_EVENT](arg_22_0)
	end

	arg_21_0:scheduleUpdateWithPriorityLua(var_21_0, 0)

	return arg_21_0
end

function var_0_1.setTouchMode(arg_23_0, arg_23_1)
	if arg_23_1 ~= var_0_0.TOUCH_MODE_ALL_AT_ONCE and arg_23_1 ~= var_0_0.TOUCHES_ONE_BY_ONE then
		print("== wrong mode", arg_23_1)

		return
	end

	arg_23_0._luaTouchMode = arg_23_1
end

function var_0_1.setTouchEnabled(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_0:getEventDispatcher()

	if arg_24_0._luaTouchListener then
		var_24_0:removeEventListener(arg_24_0._luaTouchListener)

		arg_24_0._luaTouchListener = nil
	end

	if not arg_24_1 then
		return
	end

	local var_24_1 = true

	if arg_24_0._luaTouchMode and arg_24_0._luaTouchMode == var_0_0.TOUCH_MODE_ALL_AT_ONCE then
		var_24_1 = false
	end

	if var_24_1 then
		arg_24_0._luaTouchListener = var_0_0.EventListenerTouchOneByOne:create()

		arg_24_0._luaTouchListener:setSwallowTouches(true)

		local function var_24_2(arg_25_0, arg_25_1)
			local var_25_0 = arg_25_0:getLocation()
			local var_25_1 = arg_25_0:getStartLocation()
			local var_25_2 = arg_25_0:getPreviousLocation()

			if arg_25_1 == "began" then
				if not arg_24_0:isVisible(true) or not arg_24_0:hitTest(var_25_0) then
					return false
				end
			elseif arg_25_1 == "ended" and not arg_24_0:hitTest(var_25_0) then
				arg_25_1 = "cancelled"
			end

			return arg_24_0._LuaListeners[var_0_0.NODE_TOUCH_EVENT]({
				name = arg_25_1,
				x = var_25_0.x,
				y = var_25_0.y,
				startX = var_25_1.x,
				startY = var_25_1.y,
				prevX = var_25_2.x,
				prevY = var_25_2.y
			})
		end

		arg_24_0._luaTouchListener:registerScriptHandler(function(arg_26_0, arg_26_1)
			return var_24_2(arg_26_0, "began")
		end, var_0_0.Handler.EVENT_TOUCH_BEGAN)
		arg_24_0._luaTouchListener:registerScriptHandler(function(arg_27_0, arg_27_1)
			var_24_2(arg_27_0, "moved")
		end, var_0_0.Handler.EVENT_TOUCH_MOVED)
		arg_24_0._luaTouchListener:registerScriptHandler(function(arg_28_0, arg_28_1)
			var_24_2(arg_28_0, "ended")
		end, var_0_0.Handler.EVENT_TOUCH_ENDED)
		arg_24_0._luaTouchListener:registerScriptHandler(function(arg_29_0, arg_29_1)
			var_24_2(arg_29_0, "cancelled")
		end, var_0_0.Handler.EVENT_TOUCH_CANCELLED)
	else
		arg_24_0._luaTouchListener = var_0_0.EventListenerTouchAllAtOnce:create()

		local function var_24_3(arg_30_0, arg_30_1)
			local var_30_0 = {}

			for iter_30_0, iter_30_1 in pairs(arg_30_0) do
				local var_30_1 = iter_30_1:getLocation()
				local var_30_2 = iter_30_1:getStartLocation()
				local var_30_3 = iter_30_1:getPreviousLocation()

				var_30_0[iter_30_1:getId()] = {
					x = var_30_1.x,
					y = var_30_1.y,
					startX = var_30_2.x,
					startY = var_30_2.y,
					prevX = var_30_3.x,
					prevY = var_30_3.y
				}
			end

			arg_24_0._LuaListeners[var_0_0.NODE_TOUCH_EVENT]({
				name = arg_30_1,
				points = var_30_0
			})
		end

		arg_24_0._luaTouchListener:registerScriptHandler(function(arg_31_0, arg_31_1)
			var_24_3(arg_31_0, "began")
		end, var_0_0.Handler.EVENT_TOUCHES_BEGAN)
		arg_24_0._luaTouchListener:registerScriptHandler(function(arg_32_0, arg_32_1)
			var_24_3(arg_32_0, "moved")
		end, var_0_0.Handler.EVENT_TOUCHES_MOVED)
		arg_24_0._luaTouchListener:registerScriptHandler(function(arg_33_0, arg_33_1)
			var_24_3(arg_33_0, "ended")
		end, var_0_0.Handler.EVENT_TOUCHES_ENDED)
		arg_24_0._luaTouchListener:registerScriptHandler(function(arg_34_0, arg_34_1)
			var_24_3(arg_34_0, "cancelled")
		end, var_0_0.Handler.EVENT_TOUCHES_CANCELLED)
	end

	var_24_0:addEventListenerWithSceneGraphPriority(arg_24_0._luaTouchListener, arg_24_0)
end

function var_0_1.setTouchSwallowEnabled(arg_35_0, arg_35_1)
	if arg_35_0._luaTouchListener then
		arg_35_0._luaTouchListener:setSwallowTouches(arg_35_1)
	end
end

function var_0_1.addNodeEventListener(arg_36_0, arg_36_1, arg_36_2)
	arg_36_0._LuaListeners = arg_36_0._LuaListeners or {}

	if arg_36_1 == var_0_0.NODE_EVENT then
		arg_36_0:registerScriptHandler(function(arg_37_0)
			arg_36_0._LuaListeners[var_0_0.NODE_EVENT]({
				name = arg_37_0
			})
		end)
	elseif arg_36_1 == var_0_0.NODE_TOUCH_EVENT then
		arg_36_0:registerScriptHandler(function(arg_38_0)
			arg_36_0._LuaListeners[var_0_0.NODE_TOUCH_EVENT]({
				name = arg_38_0
			})
		end)
	end

	arg_36_0._LuaListeners[arg_36_1] = arg_36_2
end

function var_0_1.removeNodeEventListener(arg_39_0, arg_39_1)
	if not arg_39_0._LuaListeners then
		return
	end

	if arg_39_1 == var_0_0.KEYPAD_EVENT then
		arg_39_0:setKeypadEnabled(false)
	elseif arg_39_1 == var_0_0.NODE_EVENT then
		arg_39_0:unregisterScriptHandler()
	elseif arg_39_1 == var_0_0.NODE_ENTER_FRAME_EVENT then
		arg_39_0:unscheduleUpdate()
	elseif arg_39_1 == var_0_0.NODE_TOUCH_EVENT then
		arg_39_0:setTouchEnabled(false)
	elseif arg_39_1 == var_0_0.ACCELEROMETER_EVENT then
		cc.Device:setAccelerometerEnabled(false)
	end

	arg_39_0._LuaListeners[arg_39_1] = nil
end

function var_0_1.removeAllNodeEventListeners(arg_40_0)
	arg_40_0:removeNodeEventListener(var_0_0.NODE_EVENT)
	arg_40_0:removeNodeEventListener(var_0_0.NODE_ENTER_FRAME_EVENT)
	arg_40_0:removeNodeEventListener(var_0_0.NODE_TOUCH_EVENT)
	arg_40_0:removeNodeEventListener(var_0_0.KEYPAD_EVENT)
	arg_40_0:removeNodeEventListener(var_0_0.ACCELEROMETER_EVENT)
end

function var_0_1.setupMaskShader(arg_41_0)
	if not arg_41_0.isMvpShader_ then
		arg_41_0.grayScale = 1

		local var_41_0 = cc.GLProgram:createWithByteArrays(xyd.shader.MVP_VERT_STRING, xyd.shader.MVP_FRAG_STRING)
		local var_41_1 = cc.GLProgramState:create(var_41_0)

		arg_41_0.MaskColorLocation_ = gl.getUniformLocation(var_41_0:getProgram(), "maskColor")
		arg_41_0.GrayScaleLocation_ = gl.getUniformLocation(var_41_0:getProgram(), "grayScale")

		arg_41_0:setGLProgramState(var_41_1)

		arg_41_0.isMvpShader_ = true
		arg_41_0.isNoMvpShader_ = nil
	end
end

function var_0_1.setMaskColor(arg_42_0, arg_42_1)
	if not arg_42_0:isGLStateDiff(arg_42_1 or xyd.shader.Default_Dusk_Color) then
		return
	end

	arg_42_0:setupMaskShader()

	local var_42_0 = arg_42_1 or xyd.shader.Default_Dusk_Color

	arg_42_0.glState_ = var_42_0

	arg_42_0:getGLProgramState():setUniformVec4(arg_42_0.MaskColorLocation_, cc.v4Fromc4(var_42_0))
end

function var_0_1.unsetMaskColor(arg_43_0)
	if not arg_43_0:isGLStateDiff(xyd.shader.Default_Color) then
		return
	end

	arg_43_0:setupMaskShader()

	local var_43_0 = xyd.shader.Default_Color

	arg_43_0.glState_ = var_43_0

	arg_43_0:getGLProgramState():setUniformVec4(arg_43_0.MaskColorLocation_, cc.v4Fromc4(var_43_0))
end

function var_0_1.setGrayScale(arg_44_0, arg_44_1)
	local var_44_0 = arg_44_1 or arg_44_0.grayScale

	if not arg_44_0:isGLStateDiff(var_44_0) then
		return
	end

	arg_44_0:setupMaskShader()

	arg_44_0.glStateGray_ = var_44_0

	arg_44_0:getGLProgramState():setUniformVec4(arg_44_0.MaskColorLocation_, cc.v4Fromc4(xyd.shader.Clear_Color))
	arg_44_0:getGLProgramState():setUniformFloat(arg_44_0.GrayScaleLocation_, var_44_0)
end

function var_0_1.unsetGrayScale(arg_45_0)
	if not arg_45_0:isGLStateDiff(xyd.shader.Default_Gray_Ratio) then
		return
	end

	arg_45_0:setupMaskShader()

	arg_45_0.glStateGray_ = xyd.shader.Default_Gray_Ratio

	arg_45_0:getGLProgramState():setUniformVec4(arg_45_0.MaskColorLocation_, cc.v4Fromc4(xyd.shader.Clear_Color))
	arg_45_0:getGLProgramState():setUniformFloat(arg_45_0.GrayScaleLocation_, xyd.shader.Default_Gray_Ratio)
end

function var_0_1.isGLStateDiff(arg_46_0, arg_46_1)
	arg_46_0.glState_ = arg_46_0.glState_ or xyd.shader.Default_Color
	arg_46_0.glStateGray_ = arg_46_0.glStateGray_ or xyd.shader.Default_Gray_Ratio

	if type(arg_46_1) == "number" then
		return arg_46_0.glStateGray_ ~= arg_46_1
	end

	if type(arg_46_1) == "table" and arg_46_0.glState_ == arg_46_1 then
		return false
	end

	for iter_46_0, iter_46_1 in pairs(arg_46_0.glState_) do
		if arg_46_1[iter_46_0] ~= iter_46_1 then
			return true
		end
	end

	return false
end

function var_0_1.runActionOnce(arg_47_0, arg_47_1, arg_47_2, arg_47_3, arg_47_4)
	local var_47_0 = {}

	if arg_47_4 ~= nil then
		table.insert(var_47_0, cc.DelayTime:create(arg_47_4))
	end

	table.insert(var_47_0, arg_47_1)

	if arg_47_2 then
		table.insert(var_47_0, cc.RemoveSelf:create())
	end

	if arg_47_3 ~= nil then
		table.insert(var_47_0, cc.CallFunc:create(arg_47_3))
	end

	if #var_47_0 == 1 then
		arg_47_0:runAction(var_47_0[1])
	else
		arg_47_0:runAction(transition.sequence(var_47_0))
	end

	return arg_47_0
end
