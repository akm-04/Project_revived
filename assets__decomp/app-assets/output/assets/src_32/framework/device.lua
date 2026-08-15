local var_0_0 = {}

var_0_0.platform = "unknown"
var_0_0.model = "unknown"

local var_0_1 = cc.Application:getInstance()
local var_0_2 = var_0_1:getTargetPlatform()

if var_0_2 == cc.PLATFORM_OS_WINDOWS then
	var_0_0.platform = "windows"
elseif var_0_2 == cc.PLATFORM_OS_MAC then
	var_0_0.platform = "mac"
elseif var_0_2 == cc.PLATFORM_OS_ANDROID then
	var_0_0.platform = "android"
elseif var_0_2 == cc.PLATFORM_OS_IPHONE or var_0_2 == cc.PLATFORM_OS_IPAD then
	var_0_0.platform = "ios"

	if var_0_2 == cc.PLATFORM_OS_IPHONE then
		var_0_0.model = "iphone"
	else
		var_0_0.model = "ipad"
	end
end

local var_0_3 = var_0_1:getCurrentLanguage()

var_0_3 = var_0_3 == cc.LANGUAGE_CHINESE and "cn" or var_0_3 == cc.LANGUAGE_FRENCH and "fr" or var_0_3 == cc.LANGUAGE_ITALIAN and "it" or var_0_3 == cc.LANGUAGE_GERMAN and "gr" or var_0_3 == cc.LANGUAGE_SPANISH and "sp" or var_0_3 == cc.LANGUAGE_RUSSIAN and "ru" or var_0_3 == cc.LANGUAGE_KOREAN and "kr" or var_0_3 == cc.LANGUAGE_JAPANESE and "jp" or var_0_3 == cc.LANGUAGE_HUNGARIAN and "hu" or var_0_3 == cc.LANGUAGE_PORTUGUESE and "pt" or var_0_3 == cc.LANGUAGE_ARABIC and "ar" or "en"
var_0_0.language = var_0_3
var_0_0.writablePath = cc.FileUtils:getInstance():getWritablePath()
var_0_0.directorySeparator = "/"
var_0_0.pathSeparator = ":"

if var_0_0.platform == "windows" then
	var_0_0.directorySeparator = "\\"
	var_0_0.pathSeparator = ";"
end

printInfo("# device.platform              = " .. var_0_0.platform)
printInfo("# device.model                 = " .. var_0_0.model)
printInfo("# device.language              = " .. var_0_0.language)
printInfo("# device.writablePath          = " .. var_0_0.writablePath)
printInfo("# device.directorySeparator    = " .. var_0_0.directorySeparator)
printInfo("# device.pathSeparator         = " .. var_0_0.pathSeparator)
printInfo("#")

function var_0_0.showActivityIndicator()
	if DEBUG > 1 then
		printInfo("device.showActivityIndicator()")
	end

	cc.Native:showActivityIndicator()
end

function var_0_0.hideActivityIndicator()
	if DEBUG > 1 then
		printInfo("device.hideActivityIndicator()")
	end

	cc.Native:hideActivityIndicator()
end

function var_0_0.showAlert(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	if type(arg_3_2) ~= "table" then
		arg_3_2 = {
			tostring(arg_3_2)
		}
	else
		table.map(arg_3_2, function(arg_4_0)
			return tostring(arg_4_0)
		end)
	end

	if DEBUG > 1 then
		printInfo("device.showAlert() - title: %s", arg_3_0)
		printInfo("    message: %s", arg_3_1)
		printInfo("    buttonLabels: %s", table.concat(arg_3_2, ", "))
	end

	if var_0_0.platform == "android" then
		local function var_3_0(arg_5_0)
			if type(arg_5_0) == "string" then
				arg_5_0 = require("framework.json").decode(arg_5_0)
				arg_5_0.buttonIndex = tonumber(arg_5_0.buttonIndex)
			end

			if arg_3_3 then
				arg_3_3(arg_5_0)
			end
		end

		luaj.callStaticMethod("org/cocos2dx/utils/PSNative", "createAlert", {
			arg_3_0,
			arg_3_1,
			arg_3_2,
			var_3_0
		}, "(Ljava/lang/String;Ljava/lang/String;Ljava/util/Vector;I)V")
	else
		local var_3_1 = ""

		if #arg_3_2 > 0 then
			var_3_1 = arg_3_2[1]

			table.remove(arg_3_2, 1)
		end

		cc.Native:createAlert(arg_3_0, arg_3_1, var_3_1)

		for iter_3_0, iter_3_1 in ipairs(arg_3_2) do
			cc.Native:addAlertButton(iter_3_1)
		end

		if type(arg_3_3) ~= "function" then
			function arg_3_3()
				return
			end
		end

		cc.Native:showAlert(arg_3_3)
	end
end

function var_0_0.cancelAlert()
	if DEBUG > 1 then
		printInfo("device.cancelAlert()")
	end

	cc.Native:cancelAlert()
end

function var_0_0.getOpenUDID()
	local var_8_0 = cc.Native:getOpenUDID()

	if DEBUG > 1 then
		printInfo("device.getOpenUDID() - Open UDID: %s", tostring(var_8_0))
	end

	return var_8_0
end

function var_0_0.openURL(arg_9_0)
	if DEBUG > 1 then
		printInfo("device.openURL() - url: %s", tostring(arg_9_0))
	end

	cc.Native:openURL(arg_9_0)
end

function var_0_0.showInputBox(arg_10_0, arg_10_1, arg_10_2)
	arg_10_0 = tostring(arg_10_0 or "INPUT TEXT")
	arg_10_1 = tostring(arg_10_1 or "INPUT TEXT, CLICK OK BUTTON")
	arg_10_2 = tostring(arg_10_2 or "")

	if DEBUG > 1 then
		printInfo("device.showInputBox() - title: %s", tostring(arg_10_0))
		printInfo("    message: %s", tostring(arg_10_1))
		printInfo("    defaultValue: %s", tostring(arg_10_2))
	end

	return cc.Native:getInputText(arg_10_0, arg_10_1, arg_10_2)
end

return var_0_0
