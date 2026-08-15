local var_0_0 = class("CommonButton", function()
	return display.newNode()
end)
local var_0_1 = {
	HIGHLIGHT = 2,
	NULL = 0,
	NORMAL = 1,
	DISABLE = 3
}
local var_0_2 = {
	COLOR_CHANGE = 1,
	SIZE_CHANGE = 2
}
local var_0_3 = -100
local var_0_4 = 1

function var_0_0.ctor(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_1.normal_img
	local var_2_1 = arg_2_1.pressed_img
	local var_2_2 = arg_2_1.disabled_img
	local var_2_3 = arg_2_1.capInsets

	if not var_2_0 then
		return
	end

	arg_2_0.brightStyle = var_0_1.NULL
	arg_2_0.clickMode = arg_2_1.clickMode or var_0_2.COLOR_CHANGE
	arg_2_0.scale = arg_2_1.scale or 0.9
	arg_2_0.titleOffSetX = arg_2_1.titleOffSetX or 0
	arg_2_0.titleOffSetY = arg_2_1.titleOffSetY or 0
	arg_2_0.title = arg_2_1.title
	arg_2_0.titleSize = arg_2_1.titleSize
	arg_2_0.titleColor = arg_2_1.titleColor
	arg_2_0.redPointX = arg_2_1.redPointX or -15
	arg_2_0.redPointY = arg_2_1.redPointY or -10
	arg_2_0.normalSprite = xyd.AssetLoader.get():loadSprite(var_2_0, var_2_3)

	if not arg_2_0.normalSprite then
		return
	end

	local var_2_4 = arg_2_0.normalSprite:getContentSize()

	arg_2_0.maxWidth = var_2_4.width
	arg_2_0.maxHeight = var_2_4.height

	if var_2_1 then
		arg_2_0.pressedSprite = xyd.AssetLoader.get():loadSprite(var_2_1, var_2_3)

		local var_2_5 = arg_2_0.pressedSprite:getContentSize()

		if var_2_5.width > arg_2_0.maxWidth then
			arg_2_0.maxWidth = var_2_5.width
		end

		if var_2_5.height > arg_2_0.maxHeight then
			arg_2_0.maxHeight = var_2_5.height
		end
	end

	if var_2_2 then
		arg_2_0.disableSprite = xyd.AssetLoader.get():loadSprite(var_2_2, var_2_3)
	else
		local var_2_6

		if var_2_1 then
			var_2_6 = var_2_1
		else
			var_2_6 = var_2_0
		end

		arg_2_0.disableSprite = xyd.AssetLoader.get():loadSprite(var_2_6, nil, {
			filter = {
				name = "GRAY",
				value = {
					0.299,
					0.487,
					0,
					0.2
				}
			}
		})
	end

	local var_2_7 = arg_2_0.disableSprite:getContentSize()

	if var_2_7.width > arg_2_0.maxWidth then
		arg_2_0.maxWidth = var_2_7.width
	end

	if var_2_7.height > arg_2_0.maxHeight then
		arg_2_0.maxHeight = var_2_7.height
	end

	if not arg_2_0.maxWidth or not arg_2_0.maxHeight then
		return
	end

	arg_2_0:initButton()
end

function var_0_0.initButton(arg_3_0)
	arg_3_0:size(arg_3_0.maxWidth, arg_3_0.maxHeight)
	arg_3_0:add(arg_3_0.normalSprite, var_0_3)
	arg_3_0.normalSprite:setAnchorPoint(0, 0)
	arg_3_0.normalSprite:setPosition(0, 0)

	if arg_3_0.pressedSprite then
		arg_3_0:add(arg_3_0.pressedSprite, var_0_3)
		arg_3_0.pressedSprite:setAnchorPoint(0, 0)
		arg_3_0.pressedSprite:setPosition(0, 0)
	end

	if arg_3_0.disableSprite then
		arg_3_0:add(arg_3_0.disableSprite, var_0_3)
		arg_3_0.disableSprite:setAnchorPoint(0, 0)
		arg_3_0.disableSprite:setPosition(0, 0)
	end

	if arg_3_0.title and arg_3_0.titleSize and arg_3_0.titleColor then
		local var_3_0 = {
			color = xyd.convertHex2RGB(arg_3_0.titleColor),
			size = arg_3_0.titleSize
		}
		local var_3_1 = xyd.AssetLoader.get():loadLabel(var_3_0)
		local var_3_2 = arg_3_0.maxWidth / 2 + arg_3_0.titleOffSetX
		local var_3_3 = arg_3_0.maxHeight / 2 + arg_3_0.titleOffSetY

		arg_3_0:add(var_3_1, var_0_4)
		var_3_1:setAnchorPoint(0.5, 0.5)
		var_3_1:setPosition(var_3_2 - 5, var_3_3 + 2)
		var_3_1:setString(arg_3_0.title)
	end

	arg_3_0:setAnchorPoint(0.5, 0.5)
	arg_3_0:setBrightStyle(var_0_1.NORMAL)

	local var_3_4 = "windows/common/red_point.png"

	arg_3_0.redPoint = xyd.AssetLoader.get():loadSprite(var_3_4)

	arg_3_0.redPoint:addTo(arg_3_0)
	arg_3_0.redPoint:setAnchorPoint(0.5, 0.5)
	arg_3_0.redPoint:setPosition(arg_3_0.maxWidth + arg_3_0.redPointX, arg_3_0.maxHeight + arg_3_0.redPointY)
	arg_3_0.redPoint:setVisible(false)
	arg_3_0.redPoint:setScale(0.9)
	arg_3_0:onRegister()
end

function var_0_0.onRegister(arg_4_0)
	arg_4_0:setTouchEnabled(true)
	arg_4_0:setTouchSwallowEnabled(false)

	local var_4_0 = false
	local var_4_1 = arg_4_0:getContentSize()
	local var_4_2 = cc.rect(0, 0, var_4_1.width, var_4_1.height)

	arg_4_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0:setBrightStyle(var_0_1.HIGHLIGHT)

			if arg_4_0.callback then
				arg_4_0.callback(arg_5_0)
			end

			return true
		end

		if arg_5_0.name == "moved" then
			if var_4_0 == true then
				arg_4_0:setBrightStyle(var_0_1.NORMAL)

				return true
			end

			if arg_4_0.callback then
				arg_4_0.callback(arg_5_0)
			end

			local var_5_0 = arg_4_0:convertToNodeSpace(cc.p(arg_5_0.x, arg_5_0.y))

			if not cc.rectContainsPoint(var_4_2, var_5_0) then
				var_4_0 = true
			end

			return true
		end

		if arg_5_0.name == "ended" then
			arg_4_0:setBrightStyle(var_0_1.NORMAL)

			if var_4_0 == true then
				var_4_0 = false

				return
			end

			if arg_4_0.callback then
				arg_4_0.callback(arg_5_0)
			end

			return true
		end
	end)
end

function var_0_0.addTouchEvent(arg_6_0, arg_6_1)
	arg_6_0.callback = arg_6_1
end

function var_0_0.setBrightStyle(arg_7_0, arg_7_1)
	if arg_7_0.brightStyle == arg_7_1 then
		return
	end

	arg_7_0.brightStyle = arg_7_1

	if arg_7_1 == var_0_1.NORMAL then
		arg_7_0:onPressState2Normal()
	end

	if arg_7_1 == var_0_1.HIGHLIGHT then
		arg_7_0:onPressState2Pressed()
	end

	if arg_7_1 == var_0_1.DISABLE then
		arg_7_0:setTouchEnabled(false)
		arg_7_0:onPressState2Disabled()
	else
		arg_7_0:setTouchEnabled(true)
	end
end

function var_0_0.onPressState2Normal(arg_8_0)
	if arg_8_0.clickMode == var_0_2.COLOR_CHANGE then
		arg_8_0.normalSprite:setVisible(true)

		if arg_8_0.pressedSprite then
			arg_8_0.pressedSprite:setVisible(false)
		end

		if arg_8_0.disableSprite then
			arg_8_0.disableSprite:setVisible(false)
		end
	elseif arg_8_0.clickMode == var_0_2.SIZE_CHANGE then
		arg_8_0.sprite:setScale(1)
	end
end

function var_0_0.onPressState2Pressed(arg_9_0)
	if arg_9_0.clickMode == var_0_2.COLOR_CHANGE then
		arg_9_0.normalSprite:setVisible(false)

		if arg_9_0.pressedSprite then
			arg_9_0.pressedSprite:setVisible(true)
		end

		if arg_9_0.disableSprite then
			arg_9_0.disableSprite:setVisible(false)
		end
	elseif arg_9_0.clickMode == var_0_2.SIZE_CHANGE then
		arg_9_0.sprite:setScale(arg_9_0.scale)
	end
end

function var_0_0.onPressState2Disabled(arg_10_0)
	if arg_10_0.clickMode == var_0_2.COLOR_CHANGE then
		arg_10_0.normalSprite:setVisible(false)

		if arg_10_0.pressedSprite then
			arg_10_0.pressedSprite:setVisible(false)
		end

		if arg_10_0.disableSprite then
			arg_10_0.disableSprite:setVisible(true)
		end
	elseif arg_10_0.clickMode == var_0_2.SIZE_CHANGE then
		arg_10_0.sprite:setScale(arg_10_0.scale)
	end
end

function var_0_0.updateTitle(arg_11_0, arg_11_1, arg_11_2)
	arg_11_0.title:setPosition(arg_11_1, arg_11_2)
end

function var_0_0.showRedPoint(arg_12_0, arg_12_1)
	if arg_12_1 then
		arg_12_0.redPoint:setVisible(true)
	else
		arg_12_0.redPoint:setVisible(false)
	end
end

return var_0_0
