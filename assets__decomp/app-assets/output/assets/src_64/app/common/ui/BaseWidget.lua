local var_0_0 = class("BaseWidget", function()
	return display.newNode()
end)

var_0_0.BACKGROUND_NAME = "background"
var_0_0.NAME_SEPARATOR_PATTERN = "%$"
var_0_0.TEXT_TYPE_NAME = "Text"
var_0_0.SOUND_BUTTON_TYPE_NAME = "sound_button"

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	cc(arg_2_0):addComponent("components.behavior.EventProtocol"):exportMethods()

	if not xyd.tables.widget:hasWidget(arg_2_1) then
		return
	end

	if xyd.tables.widget:canTouch(arg_2_1) then
		arg_2_0:setTouchEnabled(true)
		arg_2_0:setTouchSwallowEnabled(true)
	end

	arg_2_0.name = arg_2_1

	arg_2_0:loadRes()
end

function var_0_0.loadRes(arg_3_0)
	if arg_3_0.hasLoadRes then
		return
	end

	local var_3_0 = xyd.tables.widget:resource(arg_3_0.name)

	if #var_3_0 == 0 then
		return
	end

	arg_3_0.hasLoadRes = true

	arg_3_0:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson(var_3_0))
end

function var_0_0.nodeByName(arg_4_0, arg_4_1)
	return arg_4_0.children_[arg_4_1]
end

function var_0_0.setupContentView_(arg_5_0, arg_5_1)
	arg_5_0.contentView_ = arg_5_1:addTo(arg_5_0)

	arg_5_0:parseChildren_()

	if arg_5_0:background() ~= nil then
		arg_5_0:size(arg_5_0:background():getContentSize())
	end

	xyd.setCascadeOpacityEnabled(arg_5_0, true)
end

function var_0_0.parseChildren_(arg_6_0, arg_6_1)
	if arg_6_1 == nil then
		arg_6_0.children_ = {}

		if arg_6_0.contentView_ == nil then
			return
		else
			arg_6_1 = arg_6_0.contentView_
		end
	else
		local var_6_0 = arg_6_0:splitName_(arg_6_1:getName())

		if #var_6_0 >= 2 then
			arg_6_1:setName(var_6_0[1])
			arg_6_0:processNodeType_(arg_6_1, var_6_0)
		end

		arg_6_0.children_[arg_6_1:getName()] = arg_6_1
	end

	for iter_6_0, iter_6_1 in ipairs(arg_6_1:getChildren()) do
		if iter_6_1 ~= nil then
			arg_6_0:parseChildren_(iter_6_1)
		end
	end
end

function var_0_0.background(arg_7_0)
	return arg_7_0:nodeByName(var_0_0.BACKGROUND_NAME)
end

function var_0_0.splitName_(arg_8_0, arg_8_1)
	local var_8_0 = {}

	if arg_8_1 == nil then
		return var_8_0
	end

	while true do
		local var_8_1, var_8_2 = arg_8_1:find(var_0_0.NAME_SEPARATOR_PATTERN)

		if var_8_1 == nil then
			table.insert(var_8_0, arg_8_1)

			break
		else
			table.insert(var_8_0, arg_8_1:sub(1, var_8_1 - 1))

			arg_8_1 = arg_8_1:sub(var_8_2 + 1)
		end
	end

	return var_8_0
end

function var_0_0.processNodeType_(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_2[2] == var_0_0.TEXT_TYPE_NAME then
		arg_9_0:processText_(arg_9_1, arg_9_2)
	elseif arg_9_2[2] == var_0_0.SOUND_BUTTON_TYPE_NAME then
		-- block empty
	end
end

function var_0_0.processText_(arg_10_0, arg_10_1, arg_10_2)
	local function var_10_0(arg_11_0)
		xyd.formatUIText(arg_11_0, function(arg_12_0)
			arg_12_0:enableShadow()
		end)
	end

	if arg_10_2[3] == nil then
		return
	end

	local var_10_1, var_10_2 = arg_10_2[3]:find(",")

	if var_10_1 == nil then
		if arg_10_2[3]:find("shadow") then
			var_10_0(arg_10_1)
		end

		return
	end

	local var_10_3 = xyd.hex2color4b(arg_10_2[3]:sub(1, var_10_1 - 1), true)
	local var_10_4 = tonumber(arg_10_2[3]:sub(var_10_2 + 1))

	if var_10_4 == nil or var_10_4 <= 0 then
		return
	end

	arg_10_1:enableOutline(var_10_3, var_10_4)

	if arg_10_2[4] and arg_10_2[4]:find("shadow") then
		var_10_0(arg_10_1)
	end
end

function var_0_0.processSoundButton(arg_13_0, arg_13_1, arg_13_2)
	arg_13_1:addTouchEventListener(handler(arg_13_0, arg_13_0.soundButtonClick))
end

function var_0_0.soundButtonClick(arg_14_0, arg_14_1, arg_14_2)
	if arg_14_2 == ccui.TouchEventType.ended then
		local var_14_0 = arg_14_0:getSoundByIndex()

		audio.playSound(var_14_0, false)
	end
end

function var_0_0.getSoundByIndex(arg_15_0)
	return xyd.tables.sound:getSound("ui_button_click")
end

return var_0_0
