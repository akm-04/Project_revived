DeprecatedExtensionClass = {} or DeprecatedExtensionClass

local function var_0_0(arg_1_0, arg_1_1)
	print("\n********** \n" .. arg_1_0 .. " was deprecated please use " .. arg_1_1 .. " instead.\n**********")
end

function DeprecatedExtensionClass.CCControl()
	var_0_0("CCControl", "cc.Control")

	return cc.Control
end

_G.CCControl = DeprecatedExtensionClass.CCControl()

function DeprecatedExtensionClass.CCEditBox()
	var_0_0("CCEditBox", "ccui.EditBox")

	return ccui.EditBox
end

_G.CCEditBox = DeprecatedExtensionClass.CCEditBox()

function DeprecatedExtensionClass.CCUIEditBox()
	var_0_0("cc.EditBox", "ccui.EditBox")

	return ccui.EditBox
end

_G.cc.EditBox = DeprecatedExtensionClass.CCUIEditBox()

function DeprecatedExtensionClass.CCScrollView()
	var_0_0("CCScrollView", "cc.ScrollView")

	return cc.ScrollView
end

_G.CCScrollView = DeprecatedExtensionClass.CCScrollView()

function DeprecatedExtensionClass.CCTableView()
	var_0_0("CCTableView", "cc.TableView")

	return cc.TableView
end

_G.CCTableView = DeprecatedExtensionClass.CCTableView()

function DeprecatedExtensionClass.CCControlPotentiometer()
	var_0_0("CCControlPotentiometer", "cc.ControlPotentiometer")

	return cc.ControlPotentiometer
end

_G.CCControlPotentiometer = DeprecatedExtensionClass.CCControlPotentiometer()

function DeprecatedExtensionClass.CCControlStepper()
	var_0_0("CCControlStepper", "cc.ControlStepper")

	return cc.ControlStepper
end

_G.CCControlStepper = DeprecatedExtensionClass.CCControlStepper()

function DeprecatedExtensionClass.CCControlHuePicker()
	var_0_0("CCControlHuePicker", "cc.ControlHuePicker")

	return cc.ControlHuePicker
end

_G.CCControlHuePicker = DeprecatedExtensionClass.CCControlHuePicker()

function DeprecatedExtensionClass.CCControlSlider()
	var_0_0("CCControlSlider", "cc.ControlSlider")

	return cc.ControlSlider
end

_G.CCControlSlider = DeprecatedExtensionClass.CCControlSlider()

function DeprecatedExtensionClass.CCControlSaturationBrightnessPicker()
	var_0_0("CCControlSaturationBrightnessPicker", "cc.ControlSaturationBrightnessPicker")

	return cc.ControlSaturationBrightnessPicker
end

_G.CCControlSaturationBrightnessPicker = DeprecatedExtensionClass.CCControlSaturationBrightnessPicker()

function DeprecatedExtensionClass.CCControlSwitch()
	var_0_0("CCControlSwitch", "cc.ControlSwitch")

	return cc.ControlSwitch
end

_G.CCControlSwitch = DeprecatedExtensionClass.CCControlSwitch()

function DeprecatedExtensionClass.CCControlButton()
	var_0_0("CCControlButton", "cc.ControlButton")

	return cc.ControlButton
end

_G.CCControlButton = DeprecatedExtensionClass.CCControlButton()

function DeprecatedExtensionClass.CCScale9Sprite()
	var_0_0("CCScale9Sprite", "ccui.Scale9Sprite")

	return ccui.Scale9Sprite
end

_G.CCScale9Sprite = DeprecatedExtensionClass.CCScale9Sprite()

function DeprecatedExtensionClass.UIScale9Sprite()
	var_0_0("cc.Scale9Sprite", "ccui.Scale9Sprite")

	return ccui.Scale9Sprite
end

_G.cc.Scale9Sprite = DeprecatedExtensionClass.UIScale9Sprite()

function DeprecatedExtensionClass.CCControlColourPicker()
	var_0_0("CCControlColourPicker", "cc.ControlColourPicker")

	return cc.ControlColourPicker
end

_G.CCControlColourPicker = DeprecatedExtensionClass.CCControlColourPicker()
