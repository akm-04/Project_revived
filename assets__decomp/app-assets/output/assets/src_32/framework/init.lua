print("===========================================================")
print("              LOAD QUICK FRAMEWORK")
print("===========================================================")

if type(DEBUG) ~= "number" then
	DEBUG = 0
end

if type(DEBUG_FPS) ~= "boolean" then
	DEBUG_FPS = false
end

if type(DEBUG_MEM) ~= "boolean" then
	DEBUG_MEM = false
end

local var_0_0 = ...

cc = cc or {}
cc.PACKAGE_NAME = string.sub(var_0_0, 1, -6)

require(cc.PACKAGE_NAME .. ".debug")
require(cc.PACKAGE_NAME .. ".functions")
printInfo("")
printInfo("# DEBUG                        = " .. DEBUG)
printInfo("#")

device = require(cc.PACKAGE_NAME .. ".device")
display = require(cc.PACKAGE_NAME .. ".display")
filter = require(cc.PACKAGE_NAME .. ".filter")
audio = require(cc.PACKAGE_NAME .. ".audio")
network = require(cc.PACKAGE_NAME .. ".network")
crypto = require(cc.PACKAGE_NAME .. ".crypto")
json = require(cc.PACKAGE_NAME .. ".json")
transition = require(cc.PACKAGE_NAME .. ".transition")

require(cc.PACKAGE_NAME .. ".shortcodes")
require(cc.PACKAGE_NAME .. ".WidgetEx")
require(cc.PACKAGE_NAME .. ".cocos2dx")
require(cc.PACKAGE_NAME .. ".debug")

local var_0_1 = cc

var_0_1.NODE_EVENT = 0
var_0_1.NODE_ENTER_FRAME_EVENT = 1
var_0_1.NODE_TOUCH_EVENT = 2
var_0_1.NODE_TOUCH_CAPTURE_EVENT = 3
var_0_1.MENU_ITEM_CLICKED_EVENT = 4
var_0_1.ACCELERATE_EVENT = 5
var_0_1.KEYPAD_EVENT = 6
var_0_1.NODE_TOUCH_CAPTURING_PHASE = 0
var_0_1.NODE_TOUCH_TARGETING_PHASE = 1

if device.platform == "android" then
	require(cc.PACKAGE_NAME .. ".platform.android")
elseif device.platform == "ios" then
	require(cc.PACKAGE_NAME .. ".platform.ios")
elseif device.platform == "mac" then
	require(cc.PACKAGE_NAME .. ".platform.mac")
end

require(cc.PACKAGE_NAME .. ".cc.init")

local var_0_2 = cc.Director:getInstance():getTextureCache()
local var_0_3 = cc.Director:getInstance()

if DEBUG_FPS then
	var_0_3:setDisplayStats(true)
else
	var_0_3:setDisplayStats(false)
end

if DEBUG_MEM then
	local var_0_4 = cc.Director:getInstance():getTextureCache()

	local function var_0_5()
		printInfo(string.format("LUA VM MEMORY USED: %0.2f KB", collectgarbage("count")))
		printInfo(var_0_4:getCachedTextureInfo())
		printInfo("---------------------------------------------------")
	end

	var_0_3:getScheduler():scheduleScriptFunc(var_0_5, DEBUG_MEM_INTERVAL or 10, false)
end
