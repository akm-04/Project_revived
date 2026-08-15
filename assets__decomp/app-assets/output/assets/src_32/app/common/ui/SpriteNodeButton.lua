local var_0_0 = class("SpriteNodeButton", function()
	return display.newNode()
end)
local var_0_1 = {
	HIGHLIGHT = 2,
	NULL = 0,
	NORMAL = 1
}
local var_0_2 = {
	COLOR_CHANGE = 1,
	SIZE_CHANGE = 2
}
local var_0_3 = 1

function var_0_0.ctor(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_1.sprite

	if not var_2_0 then
		return
	end

	local var_2_1 = arg_2_1.capInsets

	if var_2_1 then
		arg_2_0.isScale9 = true
	end

	arg_2_0.brightStyle = var_0_1.NULL
	arg_2_0.titleOffSetX = arg_2_1.titleOffSetX or 0
	arg_2_0.titleOffSetY = arg_2_1.titleOffSetY or 0
	arg_2_0.clickMode = arg_2_1.clickMode or var_0_2.COLOR_CHANGE
	arg_2_0.isSound = arg_2_1.isSound or 1
	arg_2_0.colorModes = arg_2_1.colorModes

	if arg_2_0.clickMode == var_0_2.COLOR_CHANGE and (not arg_2_0.colorModes or not next(arg_2_0.colorModes)) then
		return
	end

	arg_2_0.scale = arg_2_1.scale or 0.95
	arg_2_0.title = arg_2_1.title
	arg_2_0.titleSize = arg_2_1.titleSize
	arg_2_0.titleColor = arg_2_1.titleColor or "#333737"
	arg_2_0.sprite = xyd.AssetLoader.get():loadSprite(var_2_0, var_2_1)
	arg_2_0.graySprite = xyd.AssetLoader.get():loadSprite(var_2_0, nil, {
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

	arg_2_0:initButton()
end

function var_0_0.initButton(arg_3_0)
	if not arg_3_0.sprite then
		return
	end

	local var_3_0 = arg_3_0.sprite:getContentSize()

	arg_3_0:size(var_3_0)
	arg_3_0:add(arg_3_0.sprite)
	arg_3_0.sprite:setAnchorPoint(0.5, 0.5)
	arg_3_0.sprite:setPosition(var_3_0.width / 2, var_3_0.height / 2)
	arg_3_0:add(arg_3_0.graySprite)
	arg_3_0.graySprite:setAnchorPoint(0.5, 0.5)
	arg_3_0.graySprite:setPosition(var_3_0.width / 2, var_3_0.height / 2)
	arg_3_0.graySprite:setVisible(false)

	if arg_3_0.title and arg_3_0.titleColor and arg_3_0.titleColor then
		local var_3_1 = {
			color = xyd.convertHex2RGB(arg_3_0.titleColor),
			size = arg_3_0.titleSize
		}
		local var_3_2 = xyd.AssetLoader.get():loadLabel(var_3_1)
		local var_3_3 = var_3_0.width / 2 + arg_3_0.titleOffSetX
		local var_3_4 = var_3_0.height / 2 + arg_3_0.titleOffSetY

		arg_3_0:add(var_3_2, var_0_3)
		var_3_2:setAnchorPoint(0.5, 0.5)
		var_3_2:setPosition(var_3_3 - 1, var_3_4 + 2)
		var_3_2:setString(arg_3_0.title)

		arg_3_0.titleLabel = var_3_2
	end

	arg_3_0:setAnchorPoint(0.5, 0.5)
	arg_3_0:setBrightStyle(var_0_1.NORMAL)
	arg_3_0:onRegister()
end

function var_0_0.setButtonSize(arg_4_0, arg_4_1, arg_4_2)
	if not arg_4_0.isScale9 then
		return
	end

	arg_4_0:setContentSize(arg_4_1, arg_4_2)
	arg_4_0.sprite:setScale9Enabled(true)
	arg_4_0.sprite:setContentSize(arg_4_1, arg_4_2)
	arg_4_0.sprite:setPosition(arg_4_1 / 2, arg_4_2 / 2)

	if arg_4_0.titleLabel then
		local var_4_0 = arg_4_1 / 2 + arg_4_0.titleOffSetX
		local var_4_1 = arg_4_2 / 2 + arg_4_0.titleOffSetY

		arg_4_0.titleLabel:setPosition(var_4_0 - 1, var_4_1 + 2)
	end
end

function var_0_0.setContainerSize(arg_5_0, arg_5_1, arg_5_2)
	arg_5_0:setContentSize(arg_5_1, arg_5_2)
	arg_5_0.sprite:setPosition(arg_5_1 / 2, arg_5_2 / 2)

	if arg_5_0.titleLabel then
		local var_5_0 = arg_5_1 / 2 + arg_5_0.titleOffSetX
		local var_5_1 = arg_5_2 / 2 + arg_5_0.titleOffSetY

		arg_5_0.titleLabel:setPosition(var_5_0 - 1, var_5_1 + 2)
	end
end

function var_0_0.onRegister(arg_6_0)
	arg_6_0:setTouchEnabled(true)
	arg_6_0:setTouchSwallowEnabled(false)

	local var_6_0 = false
	local var_6_1 = arg_6_0:getContentSize()
	local var_6_2 = cc.rect(0, 0, var_6_1.width, var_6_1.height)

	arg_6_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			arg_6_0:setBrightStyle(var_0_1.HIGHLIGHT)

			if arg_6_0.callback then
				arg_6_0.callback(arg_7_0)
			end

			return true
		end

		if arg_7_0.name == "moved" then
			if var_6_0 == true then
				arg_6_0:setBrightStyle(var_0_1.NORMAL)

				return true
			end

			if arg_6_0.callback then
				arg_6_0.callback(arg_7_0)
			end

			local var_7_0 = arg_6_0:convertToNodeSpace(cc.p(arg_7_0.x, arg_7_0.y))

			if not cc.rectContainsPoint(var_6_2, var_7_0) then
				var_6_0 = true
			end

			return true
		end

		if arg_7_0.name == "ended" then
			if arg_6_0.isSound == 1 then
				xyd.playButtonSound()
			end

			arg_6_0:setBrightStyle(var_0_1.NORMAL)

			if var_6_0 == true then
				var_6_0 = false

				return
			end

			if arg_6_0.callback then
				arg_6_0.callback(arg_7_0)
			end

			return true
		end
	end)
end

function var_0_0.addTouchEvent(arg_8_0, arg_8_1)
	arg_8_0.callback = arg_8_1
end

function var_0_0.setBrightStyle(arg_9_0, arg_9_1)
	if arg_9_0.brightStyle == arg_9_1 then
		return
	end

	arg_9_0.brightStyle = arg_9_1

	if arg_9_1 == var_0_1.NORMAL then
		arg_9_0:onPressState2Normal()
	end

	if arg_9_1 == var_0_1.HIGHLIGHT then
		arg_9_0:onPressState2Pressed()
	end
end

function var_0_0.onPressState2Normal(arg_10_0)
	if arg_10_0.clickMode == var_0_2.COLOR_CHANGE then
		if not arg_10_0.colorModes or not arg_10_0.colorModes[var_0_1.NORMAL] then
			return
		end

		arg_10_0.sprite:setColor(xyd.convertHex2RGB(arg_10_0.colorModes[var_0_1.NORMAL]))
	elseif arg_10_0.clickMode == var_0_2.SIZE_CHANGE then
		arg_10_0:setScale(1)
	end
end

function var_0_0.onPressState2Pressed(arg_11_0)
	if arg_11_0.clickMode == var_0_2.COLOR_CHANGE then
		if not arg_11_0.colorModes or not arg_11_0.colorModes[var_0_1.HIGHLIGHT] then
			return
		end

		arg_11_0.sprite:setColor(xyd.convertHex2RGB(arg_11_0.colorModes[var_0_1.HIGHLIGHT]))
	elseif arg_11_0.clickMode == var_0_2.SIZE_CHANGE then
		arg_11_0:setScale(arg_11_0.scale)
	end
end

function var_0_0.updateTitle(arg_12_0, arg_12_1, arg_12_2)
	arg_12_0.title:setPosition(arg_12_1, arg_12_2)
end

function var_0_0.changeSpriteColor(arg_13_0, arg_13_1)
	arg_13_0.sprite:setColor(xyd.convertHex2RGB(arg_13_1))
end

function var_0_0.setTitle(arg_14_0, arg_14_1)
	arg_14_0.titleLabel:setString(arg_14_1)
end

function var_0_0.setDisabled(arg_15_0, arg_15_1)
	if arg_15_1 then
		arg_15_0:setTouchEnabled(false)
		arg_15_0.sprite:setVisible(false)
		arg_15_0.graySprite:setVisible(true)
	else
		arg_15_0:setTouchEnabled(true)
		arg_15_0.sprite:setVisible(true)
		arg_15_0.graySprite:setVisible(false)
	end
end

return var_0_0
