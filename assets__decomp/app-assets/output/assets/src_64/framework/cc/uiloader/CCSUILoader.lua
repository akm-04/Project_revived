local var_0_0 = import(".UILoaderUtilitys")
local var_0_1 = class("CCSUILoader")

function var_0_1.load(arg_1_0, arg_1_1, arg_1_2)
	if arg_1_2 then
		arg_1_0.bUseEditBox = arg_1_2.bUseEditBox or false
	else
		arg_1_0.bUseEditBox = false
	end

	if cc.bPlugin_ and arg_1_0.bUseEditBox then
		arg_1_0.bUseEditBox = false

		print("Error! not support CCEditbox in cocostudio layout file")
	end

	arg_1_0.texturesPng = arg_1_1.texturesPng

	arg_1_0:loadTexture(arg_1_1)

	local var_1_0, var_1_1 = arg_1_0:parserJson(arg_1_1)

	arg_1_0.texturesPng = nil

	if var_1_1 then
		return var_1_0, display.width, display.height
	else
		return var_1_0, arg_1_1.designWidth, arg_1_1.designHeight
	end
end

function var_0_1.loadFile(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = cc.FileUtils:getInstance()
	local var_2_1 = var_2_0:fullPathForFilename(arg_2_1)
	local var_2_2 = var_2_0:getStringFromFile(var_2_1)
	local var_2_3 = json.decode(var_2_2)

	var_0_0.addSearchPathIf(io.pathinfo(var_2_1).dirname)

	local var_2_4, var_2_5, var_2_6 = arg_2_0:load(var_2_3, arg_2_2)

	var_0_0.clearPath()

	return var_2_4, var_2_5, var_2_6
end

function var_0_1.parserJson(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.nodeTree or arg_3_1.widgetTree

	if not var_3_0 then
		printInfo("CCSUILoader - parserJson havn't found root node")

		return
	end

	arg_3_0:prettyJson(var_3_0)

	return arg_3_0:generateUINode(var_3_0), var_3_0.options.adaptScreen
end

function var_0_1.generateUINode(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	arg_4_2 = arg_4_2 or 0
	arg_4_3 = arg_4_3 or 0

	local var_4_0 = arg_4_1.classname
	local var_4_1 = arg_4_1.options

	var_4_1.x = var_4_1.x or 0
	var_4_1.y = var_4_1.y or 0
	var_4_1.x = var_4_1.x + arg_4_2
	var_4_1.y = var_4_1.y + arg_4_3

	local var_4_2 = arg_4_0:createUINode(var_4_0, var_4_1, arg_4_4)

	if not var_4_2 then
		return
	end

	arg_4_0:modifyPanelChildPos_(var_4_0, var_4_1.adaptScreen, var_4_1.sizeType, var_4_2:getContentSize(), arg_4_1.children)

	local var_4_3 = var_4_2:getAnchorPoint()
	local var_4_4 = var_4_2:getContentSize()

	var_4_3.x = var_4_3.x * var_4_4.width
	var_4_3.y = var_4_3.y * var_4_4.height
	var_4_2.name = var_4_1.name or "unknow node"
	var_4_2.subChildren = {}

	if arg_4_4 then
		arg_4_4.subChildren[var_4_2.name] = var_4_2
	end

	if var_4_1.fileName then
		var_4_2:setSpriteFrame(var_4_1.fileName)
	end

	if var_4_1.flipX and var_4_2.setFlippedX then
		var_4_2:setFlippedX(var_4_1.flipX)
	end

	if var_4_1.flipY and var_4_2.setFlippedY then
		var_4_2:setFlippedY(var_4_1.flipY)
	end

	var_4_2:setRotation(var_4_1.rotation or 0)
	var_4_2:setScaleX((var_4_1.scaleX or 1) * var_4_2:getScaleX())
	var_4_2:setScaleY((var_4_1.scaleY or 1) * var_4_2:getScaleY())
	var_4_2:setVisible(var_4_1.visible)
	var_4_2:setLocalZOrder(var_4_1.ZOrder or 0)
	var_4_2:setTag(var_4_1.tag or 0)

	local var_4_5

	if var_4_0 == "ScrollView" then
		var_4_5 = cc.Node:create()

		var_4_5:setPosition(var_4_1.x, var_4_1.y)
		var_4_2:addScrollNode(var_4_5)
	end

	local var_4_6 = arg_4_1.children

	for iter_4_0, iter_4_1 in ipairs(var_4_6) do
		local var_4_7 = arg_4_0:generateUINode(iter_4_1, var_4_3.x, var_4_3.y, var_4_2)

		if var_4_7 then
			if var_4_0 == "ScrollView" then
				var_4_5:addChild(var_4_7)
			elseif var_4_0 == "ListView" then
				local var_4_8 = var_4_2:newItem()

				var_4_8:addContent(var_4_7)

				local var_4_9 = var_4_7:getContentSize()

				var_4_8:setItemSize(var_4_9.width, var_4_9.height)
				var_4_2:addItem(var_4_8)

				if iter_4_1.classname == "Button" then
					var_4_6:setTouchSwallowEnabled(false)
				end
			elseif var_4_0 == "PageView" then
				local var_4_10 = var_4_2:newItem()

				var_4_7:setPosition(0, 0)
				var_4_10:addChild(var_4_7)
				var_4_10:setTag(10001)
				var_4_2:addItem(var_4_10)
			else
				var_4_2:addChild(var_4_7)
			end
		end
	end

	if var_4_0 == "ListView" or var_4_0 == "PageView" then
		var_4_2:reload()
	elseif var_4_0 == "ScrollView" then
		var_4_2:resetPosition()
	end

	return var_4_2
end

function var_0_1.createUINode(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if not arg_5_1 then
		return
	end

	local var_5_0

	if arg_5_1 == "Node" then
		var_5_0 = arg_5_0:createNode(arg_5_2)
	elseif arg_5_1 == "Sprite" or arg_5_1 == "Scale9Sprite" then
		var_5_0 = arg_5_0:createSprite(arg_5_2)
	elseif arg_5_1 == "ImageView" then
		var_5_0 = arg_5_0:createImage(arg_5_2)
	elseif arg_5_1 == "Button" then
		var_5_0 = arg_5_0:createButton(arg_5_2)
	elseif arg_5_1 == "LoadingBar" then
		var_5_0 = arg_5_0:createLoadingBar(arg_5_2)
	elseif arg_5_1 == "Slider" then
		var_5_0 = arg_5_0:createSlider(arg_5_2)
	elseif arg_5_1 == "CheckBox" then
		var_5_0 = arg_5_0:createCheckBox(arg_5_2)
	elseif arg_5_1 == "LabelBMFont" then
		var_5_0 = arg_5_0:createBMFontLabel(arg_5_2)
	elseif arg_5_1 == "Label" then
		var_5_0 = arg_5_0:createLabel(arg_5_2)
	elseif arg_5_1 == "LabelAtlas" then
		var_5_0 = arg_5_0:createLabelAtlas(arg_5_2)
	elseif arg_5_1 == "TextField" then
		var_5_0 = arg_5_0:createEditBox(arg_5_2)
	elseif arg_5_1 == "Panel" then
		var_5_0 = arg_5_0:createPanel(arg_5_2)
	elseif arg_5_1 == "ScrollView" then
		var_5_0 = arg_5_0:createScrollView(arg_5_2)
	elseif arg_5_1 == "ListView" then
		var_5_0 = arg_5_0:createListView(arg_5_2)
	elseif arg_5_1 == "PageView" then
		var_5_0 = arg_5_0:createPageView(arg_5_2)
	else
		printInfo("CCSUILoader not support node:" .. arg_5_1)
	end

	return var_5_0
end

function var_0_1.getChildOptionJson(arg_6_0, arg_6_1)
	return arg_6_1.options.layoutParameter
end

function var_0_1.newWapperNode(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = display.newNode()
	local var_7_1 = arg_7_1:getContentSize()

	var_7_1.width = var_7_1.width + arg_7_2.marginLeft + arg_7_2.marginRight
	var_7_1.height = var_7_1.height + arg_7_2.marginTop + arg_7_2.marginDown

	var_7_0:setContentSize(var_7_1)
	var_7_0:addChild(arg_7_1)
	arg_7_1:setPosition()
end

function var_0_1.getButtonStateImages(arg_8_0, arg_8_1)
	local var_8_0 = {}

	if arg_8_1.normalData and arg_8_1.normalData.path then
		var_8_0.normal = arg_8_0:transResName(arg_8_1.normalData)
	end

	if arg_8_1.pressedData and arg_8_1.pressedData.path then
		var_8_0.pressed = arg_8_0:transResName(arg_8_1.pressedData)
	end

	if arg_8_1.disabledData and arg_8_1.disabledData.path then
		var_8_0.disabled = arg_8_0:transResName(arg_8_1.disabledData)
	end

	return var_8_0
end

function var_0_1.getAnchorType(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_1 == 1 then
		if arg_9_2 == 1 then
			return display.RIGHT_TOP
		elseif arg_9_2 == 0.5 then
			return display.RIGHT_CENTER
		else
			return display.RIGHT_BOTTOM
		end
	elseif arg_9_1 == 0.5 then
		if arg_9_2 == 1 then
			return display.CENTER_TOP
		elseif arg_9_2 == 0.5 then
			return display.CENTER
		else
			return display.CENTER_BOTTOM
		end
	elseif arg_9_2 == 1 then
		return display.LEFT_TOP
	elseif arg_9_2 == 0.5 then
		return display.LEFT_CENTER
	else
		return display.LEFT_BOTTOM
	end
end

function var_0_1.getCheckBoxImages(arg_10_0, arg_10_1)
	local var_10_0 = {}

	local function var_10_1(arg_11_0)
		local var_11_0 = arg_10_1.backGroundBoxData

		if arg_11_0 == "pressed" then
			var_11_0 = arg_10_1.backGroundBoxSelectedData
		elseif arg_11_0 == "disabled" then
			var_11_0 = arg_10_1.backGroundBoxDisabledData
		end

		return var_11_0
	end

	var_10_0.off = arg_10_0:transResName(var_10_1("normal"))
	var_10_0.off_pressed = arg_10_0:transResName(var_10_1("pressed"))
	var_10_0.off_disabled = arg_10_0:transResName(var_10_1("disabled"))
	var_10_0.on = {
		var_10_0.off,
		arg_10_0:transResName(arg_10_1.frontCrossData)
	}
	var_10_0.on_pressed = var_10_0.on
	var_10_0.on_disabled = {
		var_10_0.off_disabled,
		arg_10_0:transResName(arg_10_1.frontCrossDisabledData)
	}

	return var_10_0
end

function var_0_1.loadTexture(arg_12_0, arg_12_1)
	for iter_12_0, iter_12_1 in ipairs(arg_12_1.textures) do
		arg_12_0.bUseTexture = true

		var_0_0.loadTexture(iter_12_1)
	end
end

function var_0_1.getTexturePng(arg_13_0, arg_13_1)
	if not arg_13_1 then
		return
	end

	local var_13_0 = io.pathinfo(arg_13_1)
	local var_13_1

	if var_13_0.dirname then
		var_13_1 = var_13_0.dirname .. var_13_0.basename .. ".png"
	else
		var_13_1 = var_13_0.basename .. ".png"
	end

	return var_13_1
end

function var_0_1.transResName(arg_14_0, arg_14_1)
	if not arg_14_1 then
		return
	end

	local var_14_0 = arg_14_1.path

	if not var_14_0 then
		return var_14_0
	end

	var_0_0.loadTexture(arg_14_1.plistFile)

	if arg_14_1.resourceType == 1 then
		return "#" .. var_14_0
	else
		return var_0_0.getFileFullName(var_14_0)
	end
end

function var_0_1.createNode(arg_15_0, arg_15_1)
	local var_15_0 = cc.Node:create()

	if not arg_15_1.ignoreSize then
		var_15_0:setContentSize(cc.size(arg_15_1.width or 0, arg_15_1.height or 0))
	end

	var_15_0:setPositionX(arg_15_1.x or 0)
	var_15_0:setPositionY(arg_15_1.y or 0)
	var_15_0:setAnchorPoint(cc.p(arg_15_1.anchorPointX or 0.5, arg_15_1.anchorPointY or 0.5))

	return var_15_0
end

function var_0_1.createSprite(arg_16_0, arg_16_1)
	local var_16_0 = cc.Sprite:create()

	if not arg_16_1.ignoreSize then
		var_16_0:setContentSize(cc.size(arg_16_1.width, arg_16_1.height))
	end

	if arg_16_1.opacity then
		var_16_0:setOpacity(arg_16_1.opacity)
	end

	var_16_0:setPositionX(arg_16_1.x or 0)
	var_16_0:setPositionY(arg_16_1.y or 0)
	var_16_0:setAnchorPoint(cc.p(arg_16_1.anchorPointX or 0.5, arg_16_1.anchorPointY or 0.5))

	return var_16_0
end

function var_0_1.createImage(arg_17_0, arg_17_1)
	local var_17_0 = {
		scale9 = arg_17_1.scale9Enable
	}

	if var_17_0.scale9 then
		var_17_0.capInsets = cc.rect(arg_17_1.capInsetsX, arg_17_1.capInsetsY, arg_17_1.capInsetsWidth, arg_17_1.capInsetsHeight)
	end

	local var_17_1 = cc.ui.UIImage.new(arg_17_0:transResName(arg_17_1.fileNameData), var_17_0)

	if not arg_17_1.scale9Enable then
		local var_17_2 = var_17_1:getContentSize()

		if arg_17_1.width then
			arg_17_1.scaleX = (arg_17_1.scaleX or 1) * arg_17_1.width / var_17_2.width
		end

		if arg_17_1.height then
			arg_17_1.scaleY = (arg_17_1.scaleY or 1) * arg_17_1.height / var_17_2.height
		end
	end

	if not arg_17_1.ignoreSize then
		var_17_1:setLayoutSize(arg_17_1.width, arg_17_1.height)

		arg_17_1.scaleX = 1
		arg_17_1.scaleY = 1
	end

	var_17_1:setPositionX(arg_17_1.x or 0)
	var_17_1:setPositionY(arg_17_1.y or 0)
	var_17_1:setAnchorPoint(cc.p(arg_17_1.anchorPointX or 0.5, arg_17_1.anchorPointY or 0.5))

	if arg_17_1.touchAble then
		var_17_1:setTouchEnabled(true)
		var_17_1:setTouchSwallowEnabled(true)
	end

	if arg_17_1.opacity then
		var_17_1:setOpacity(arg_17_1.opacity)
	end

	return var_17_1
end

function var_0_1.createButton(arg_18_0, arg_18_1)
	local var_18_0 = cc.ui.UIPushButton.new(arg_18_0:getButtonStateImages(arg_18_1), {
		scale9 = arg_18_1.scale9Enable,
		flipX = arg_18_1.flipX,
		flipY = arg_18_1.flipY
	})

	if arg_18_1.opacity then
		var_18_0:setCascadeOpacityEnabled(true)
		var_18_0:setOpacity(arg_18_1.opacity)
	end

	if arg_18_1.text then
		var_18_0:setButtonLabel(cc.ui.UILabel.new({
			text = arg_18_1.text,
			size = arg_18_1.fontSize,
			color = cc.c3b(arg_18_1.textColorR, arg_18_1.textColorG, arg_18_1.textColorB)
		}))
	end

	if not arg_18_1.ignoreSize then
		var_18_0:setButtonSize(arg_18_1.width, arg_18_1.height)
	end

	var_18_0:align(arg_18_0:getAnchorType(arg_18_1.anchorPointX or 0.5, arg_18_1.anchorPointY or 0.5), arg_18_1.x or 0, arg_18_1.y or 0)

	return var_18_0
end

function var_0_1.createLoadingBar(arg_19_0, arg_19_1)
	local var_19_0 = {
		image = arg_19_0:transResName(arg_19_1.textureData),
		scale9 = arg_19_1.scale9Enable,
		capInsets = cc.rect(arg_19_1.capInsetsX, arg_19_1.capInsetsY, arg_19_1.capInsetsWidth, arg_19_1.capInsetsHeight),
		direction = arg_19_1.direction,
		percent = arg_19_1.percent or 100,
		viewRect = cc.rect(arg_19_1.x, arg_19_1.y, arg_19_1.width, arg_19_1.height)
	}
	local var_19_1 = cc.ui.UILoadingBar.new(var_19_0)

	var_19_1:setDirction(arg_19_1.direction)
	var_19_1:setPositionX(arg_19_1.x or 0)
	var_19_1:setPositionY(arg_19_1.y or 0)
	var_19_1:setContentSize(arg_19_1.width, arg_19_1.height)
	var_19_1:setAnchorPoint(cc.p(arg_19_1.anchorPointX or 0.5, arg_19_1.anchorPointY or 0.5))

	return var_19_1
end

function var_0_1.createSlider(arg_20_0, arg_20_1)
	local var_20_0 = cc.ui.UISlider.new(display.LEFT_TO_RIGHT, {
		bar = arg_20_0:transResName(arg_20_1.barFileNameData),
		barfg = arg_20_0:transResName(arg_20_1.progressBarData),
		button = arg_20_0:transResName(arg_20_1.ballNormalData),
		button_pressed = arg_20_0:transResName(arg_20_1.ballPressedData),
		button_disabled = arg_20_0:transResName(arg_20_1.ballDisabledData)
	}, {
		scale9 = arg_20_1.scale9Enable
	})

	if not arg_20_1.ignoreSize then
		var_20_0:setSliderSize(arg_20_1.width, arg_20_1.height)
	end

	var_20_0:align(arg_20_0:getAnchorType(arg_20_1.anchorPointX, arg_20_1.anchorPointY), arg_20_1.x or 0, arg_20_1.y or 0)
	var_20_0:setSliderValue(arg_20_1.percent)

	return var_20_0
end

function var_0_1.createCheckBox(arg_21_0, arg_21_1)
	local var_21_0 = cc.ui.UICheckBoxButton.new(arg_21_0:getCheckBoxImages(arg_21_1), {
		scale9 = not arg_21_1.ignoreSize
	})

	if not arg_21_1.ignoreSize then
		var_21_0:setButtonSize(arg_21_1.width, arg_21_1.height)
	end

	var_21_0:align(arg_21_0:getAnchorType(arg_21_1.anchorPointX or 0.5, arg_21_1.anchorPointY or 0.5), arg_21_1.x or 0, arg_21_1.y or 0)

	return var_21_0
end

function var_0_1.createBMFontLabel(arg_22_0, arg_22_1)
	local var_22_0 = cc.ui.UILabel.new({
		UILabelType = 1,
		text = arg_22_1.text,
		font = arg_22_1.fileNameData.path,
		textAlign = cc.ui.TEXT_ALIGN_CENTER
	})

	var_22_0:align(arg_22_0:getAnchorType(arg_22_1.anchorPointX or 0.5, arg_22_1.anchorPointY or 0.5), arg_22_1.x or 0, arg_22_1.y or 0)

	return var_22_0
end

function var_0_1.createLabel(arg_23_0, arg_23_1)
	local var_23_0 = cc.ui.UILabel.new({
		text = arg_23_1.text,
		font = arg_23_1.fontName,
		size = arg_23_1.fontSize,
		color = cc.c3b(arg_23_1.colorR or 255, arg_23_1.colorG or 255, arg_23_1.colorB or 255),
		align = arg_23_1.hAlignment,
		valign = arg_23_1.vAlignment,
		dimensions = cc.size(arg_23_1.areaWidth or 0, arg_23_1.areaHeight or 0),
		x = arg_23_1.x,
		y = arg_23_1.y
	})

	if not arg_23_1.ignoreSize then
		var_23_0:setLayoutSize(arg_23_1.areaWidth, arg_23_1.areaHeight)
	end

	var_23_0:align(arg_23_0:getAnchorType(arg_23_1.anchorPointX or 0.5, arg_23_1.anchorPointY or 0.5), arg_23_1.x or 0, arg_23_1.y or 0)

	return var_23_0
end

function var_0_1.createLabelAtlas(arg_24_0, arg_24_1)
	local var_24_0

	if type(cc.LabelAtlas._create) == "function" then
		var_24_0 = cc.LabelAtlas:_create()

		var_24_0:initWithString(arg_24_1.stringValue, arg_24_1.charMapFileData.path, arg_24_1.itemWidth, arg_24_1.itemHeight, string.byte(arg_24_1.startCharMap))
	else
		var_24_0 = cc.LabelAtlas:create(arg_24_1.stringValue, arg_24_1.charMapFileData.path, arg_24_1.itemWidth, arg_24_1.itemHeight, string.byte(arg_24_1.startCharMap))
	end

	var_24_0:setAnchorPoint(cc.p(arg_24_1.anchorPointX or 0.5, arg_24_1.anchorPointY or 0.5))
	var_24_0:setPosition(arg_24_1.x, arg_24_1.y)

	if not arg_24_1.ignoreSize then
		var_24_0:setContentSize(arg_24_1.width, arg_24_1.height)
	end

	return var_24_0
end

function var_0_1.createEditBox(arg_25_0, arg_25_1)
	local var_25_0

	if arg_25_0.bUseEditBox then
		var_25_0 = cc.ui.UIInput.new({
			UIInputType = 1,
			size = cc.size(arg_25_1.width, arg_25_1.height)
		})

		var_25_0:setPlaceHolder(arg_25_1.placeHolder)
		var_25_0:setFontName(arg_25_1.fontName)
		var_25_0:setFontSize(arg_25_1.fontSize or 20)
		var_25_0:setText(arg_25_1.text)

		if arg_25_1.passwordEnable then
			var_25_0:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		end

		if arg_25_1.maxLengthEnable then
			var_25_0:setMaxLength(arg_25_1.maxLength)
		end

		var_25_0:setPosition(arg_25_1.x, arg_25_1.y)
	else
		if not arg_25_1.maxLengthEnable then
			arg_25_1.maxLength = 0
		end

		var_25_0 = cc.ui.UIInput.new({
			UIInputType = 2,
			placeHolder = arg_25_1.placeHolder,
			x = arg_25_1.x,
			y = arg_25_1.y,
			text = arg_25_1.text,
			size = cc.size(arg_25_1.width, arg_25_1.height),
			passwordEnable = arg_25_1.passwordEnable,
			font = arg_25_1.fontName,
			fontSize = arg_25_1.fontSize,
			maxLength = arg_25_1.maxLength
		})
	end

	var_25_0:setAnchorPoint(cc.p(arg_25_1.anchorPointX or 0.5, arg_25_1.anchorPointY or 0.5))

	return var_25_0
end

function var_0_1.createPanel(arg_26_0, arg_26_1)
	local var_26_0

	if arg_26_1.clipAble then
		var_26_0 = cc.ClippingRegionNode:create()
	else
		var_26_0 = display.newNode()
	end

	local var_26_1
	local var_26_2

	if arg_26_1.colorType == 1 then
		var_26_1 = cc.LayerColor:create()

		if not cc.bPlugin_ then
			var_26_1:resetCascadeBoundingBox()
		end

		var_26_1:setTouchEnabled(false)
		var_26_1:setColor(cc.c3b(arg_26_1.bgColorR, arg_26_1.bgColorG, arg_26_1.bgColorB))
	elseif arg_26_1.colorType == 2 then
		var_26_1 = cc.LayerGradient:create()

		if not cc.bPlugin_ then
			var_26_1:resetCascadeBoundingBox()
		end

		var_26_1:setTouchEnabled(false)
		var_26_1:setStartColor(cc.c3b(arg_26_1.bgStartColorR, arg_26_1.bgStartColorG, arg_26_1.bgStartColorB))
		var_26_1:setEndColor(cc.c3b(arg_26_1.bgEndColorR, arg_26_1.bgEndColorG, arg_26_1.bgEndColorB))
		var_26_1:setVector(cc.p(arg_26_1.vectorX or 0, arg_26_1.vectorY or -0.5))
	end

	if var_26_1 then
		var_26_1:setAnchorPoint(cc.p(0, 0))
		var_26_1:setOpacity(arg_26_1.bgColorOpacity or 100)
	end

	if arg_26_1.backGroundScale9Enable then
		if arg_26_1.backGroundImageData and arg_26_1.backGroundImageData.path then
			local var_26_3 = cc.rect(arg_26_1.capInsetsX, arg_26_1.capInsetsY, arg_26_1.capInsetsWidth, arg_26_1.capInsetsHeight)
			local var_26_4 = ccui.Scale9Sprite or cc.Scale9Sprite

			if arg_26_0.bUseTexture then
				var_26_2 = var_26_4:createWithSpriteFrameName(arg_26_1.backGroundImageData.path, var_26_3)

				var_26_2:setContentSize(cc.size(arg_26_1.width, arg_26_1.height))
			else
				var_26_2 = var_26_4:create(var_26_3, arg_26_1.backGroundImageData.path)

				var_26_2:setContentSize(cc.size(arg_26_1.width, arg_26_1.height))
			end
		end
	elseif arg_26_1.backGroundImageData and arg_26_1.backGroundImageData.path then
		var_26_2 = display.newSprite(arg_26_0:transResName(arg_26_1.backGroundImageData))
	end

	local var_26_5

	if arg_26_1.adaptScreen then
		arg_26_1.width = display.width
		arg_26_1.height = display.height
	end

	local var_26_6 = cc.size(arg_26_1.width, arg_26_1.height)

	if arg_26_1.clipAble then
		var_26_0:setClippingRegion(cc.rect(0, 0, arg_26_1.width, arg_26_1.height))
	end

	if not arg_26_1.ignoreSize and var_26_1 then
		var_26_1:setContentSize(var_26_6)
	end

	if var_26_2 then
		var_26_2:setPosition(var_26_6.width / 2, var_26_6.height / 2)
	end

	var_26_0:setContentSize(var_26_6)

	if var_26_1 then
		var_26_0:addChild(var_26_1)
	end

	if var_26_2 then
		var_26_0:addChild(var_26_2)
	end

	var_26_0:setPositionX(arg_26_1.x or 0)
	var_26_0:setPositionY(arg_26_1.y or 0)
	var_26_0:setAnchorPoint(cc.p(arg_26_1.anchorPointX or 0.5, arg_26_1.anchorPointY or 0.5))

	return var_26_0
end

function var_0_1.createScrollView(arg_27_0, arg_27_1)
	local var_27_0 = {
		viewRect = cc.rect(arg_27_1.x, arg_27_1.y, arg_27_1.width, arg_27_1.height)
	}

	if arg_27_1.colorType == 1 then
		var_27_0.bgColor = cc.c4b(arg_27_1.bgColorR, arg_27_1.bgColorG, arg_27_1.bgColorB, arg_27_1.bgColorOpacity)
	elseif arg_27_1.colorType == 2 then
		var_27_0.bgStartColor = cc.c4b(arg_27_1.bgStartColorR, arg_27_1.bgStartColorG, arg_27_1.bgStartColorB, arg_27_1.bgColorOpacity)
		var_27_0.bgEndColor = cc.c4b(arg_27_1.bgEndColorR, arg_27_1.bgEndColorG, arg_27_1.bgEndColorB, arg_27_1.bgColorOpacity)
		var_27_0.bgVector = cc.p(arg_27_1.vectorX, arg_27_1.vectorY)
	end

	var_27_0.bg = arg_27_0:transResName(arg_27_1.backGroundImageData)

	if arg_27_1.backGroundScale9Enable then
		var_27_0.bgScale9 = arg_27_1.backGroundScale9Enable
		var_27_0.capInsets = cc.rect(arg_27_1.capInsetsX, arg_27_1.capInsetsY, arg_27_1.capInsetsWidth, arg_27_1.capInsetsHeight)
	end

	local var_27_1 = cc.ui.UIScrollView.new(var_27_0)
	local var_27_2 = arg_27_1.direction

	if var_27_2 == 0 then
		var_27_2 = 0
	elseif var_27_2 == 3 then
		var_27_2 = 0
	end

	var_27_1:setDirection(var_27_2)
	var_27_1:setBounceable(arg_27_1.bounceEnable or false)

	return var_27_1
end

function var_0_1.createListView(arg_28_0, arg_28_1)
	local var_28_0 = {
		viewRect = cc.rect(arg_28_1.x, arg_28_1.y, arg_28_1.width, arg_28_1.height)
	}

	if arg_28_1.colorType == 1 then
		var_28_0.bgColor = cc.c4b(arg_28_1.bgColorR, arg_28_1.bgColorG, arg_28_1.bgColorB, arg_28_1.bgColorOpacity)
	elseif arg_28_1.colorType == 2 then
		var_28_0.bgStartColor = cc.c4b(arg_28_1.bgStartColorR, arg_28_1.bgStartColorG, arg_28_1.bgStartColorB, arg_28_1.bgColorOpacity)
		var_28_0.bgEndColor = cc.c4b(arg_28_1.bgEndColorR, arg_28_1.bgEndColorG, arg_28_1.bgEndColorB, arg_28_1.bgColorOpacity)
		var_28_0.bgVector = cc.p(arg_28_1.vectorX, arg_28_1.vectorY)
	end

	local var_28_1 = cc.ui.UIListView.new(var_28_0)
	local var_28_2 = arg_28_1.direction or 1

	if var_28_2 == 0 then
		var_28_2 = 1
	elseif var_28_2 == 3 then
		var_28_2 = 0
	end

	var_28_1:setDirection(var_28_2)
	var_28_1:setAlignment(arg_28_1.gravity)
	var_28_1:setBounceable(arg_28_1.bounceEnable or false)

	return var_28_1
end

function var_0_1.createPageView(arg_29_0, arg_29_1)
	local var_29_0 = {}

	var_29_0.column = 1
	var_29_0.row = 1
	var_29_0.viewRect = cc.rect(arg_29_1.x, arg_29_1.y, arg_29_1.width, arg_29_1.height)

	return (cc.ui.UIPageView.new(var_29_0))
end

function var_0_1.prettyJson(arg_30_0, arg_30_1)
	local var_30_0

	local function var_30_1(arg_31_0, arg_31_1)
		if not arg_31_0 then
			return
		end

		local var_31_0 = arg_31_0.options
		local var_31_1 = arg_31_1 and arg_31_1.options

		if var_31_0.adaptScreen then
			var_31_0.width = display.width
			var_31_0.height = display.height
		elseif var_31_0.sizeType == 1 and var_31_1 then
			var_31_0.width = var_31_1.width * var_31_0.sizePercentX
			var_31_0.height = var_31_1.height * var_31_0.sizePercentY
		end

		if var_31_1 and var_31_1.scale9Enable then
			arg_31_0.options.ZOrder = arg_31_0.options.ZOrder or 3
		end

		if not arg_31_0.children then
			return
		end

		if #arg_31_0.children == 0 then
			return
		end

		for iter_31_0, iter_31_1 in ipairs(arg_31_0.children) do
			var_30_1(iter_31_1, arg_31_0)
		end
	end

	var_30_1(arg_30_1)
end

function var_0_1.modifyPanelChildPos_(arg_32_0, arg_32_1, arg_32_2, arg_32_3, arg_32_4, arg_32_5)
	if arg_32_1 ~= "Panel" or not arg_32_2 and arg_32_3 == 0 or not arg_32_5 then
		return
	end

	arg_32_0:modifyLayoutChildPos_(arg_32_4, arg_32_5)
end

function var_0_1.modifyLayoutChildPos_(arg_33_0, arg_33_1, arg_33_2)
	for iter_33_0, iter_33_1 in ipairs(arg_33_2) do
		arg_33_0:calcChildPosByName_(arg_33_2, iter_33_1.options.name, arg_33_1)
	end
end

function var_0_1.calcChildPosByName_(arg_34_0, arg_34_1, arg_34_2, arg_34_3)
	local var_34_0 = arg_34_0:getPanelChild_(arg_34_1, arg_34_2)

	if not var_34_0 then
		return
	end

	if var_34_0.posFixed_ then
		return
	end

	local var_34_1
	local var_34_2 = var_34_0.options
	local var_34_3
	local var_34_4
	local var_34_5 = false
	local var_34_6 = var_34_2.width
	local var_34_7 = var_34_2.height
	local var_34_8 = var_34_2.layoutParameter

	if not var_34_8 then
		return
	end

	if var_34_8.type == 1 then
		if var_34_8.gravity == 1 then
			var_34_3 = var_34_6 * 0.5
		elseif var_34_8.gravity == 2 then
			var_34_4 = arg_34_3.height - var_34_7 * 0.5
		elseif var_34_8.gravity == 3 then
			var_34_3 = arg_34_3.width - var_34_6 * 0.5
		elseif var_34_8.gravity == 4 then
			var_34_4 = var_34_7 * 0.5
		elseif var_34_8.gravity == 5 then
			var_34_4 = arg_34_3.height * 0.5
		elseif var_34_8.gravity == 6 then
			var_34_3 = arg_34_3.width * 0.5
		else
			var_34_3 = var_34_2.x
			var_34_4 = var_34_2.y

			local var_34_9 = true

			print("CCSUILoader - modifyLayoutChildPos_ not support gravity:" .. var_34_8.type)
		end

		if var_34_8.gravity == 1 or var_34_8.gravity == 3 or var_34_8.gravity == 6 then
			var_34_3 = ((var_34_2.anchorPointX or 0.5) - 0.5) * var_34_6 + var_34_3
			var_34_4 = var_34_2.y
		else
			var_34_3 = var_34_2.x
			var_34_4 = ((var_34_2.anchorPointY or 0.5) - 0.5) * var_34_7 + var_34_4
		end
	elseif var_34_8.type == 2 then
		local var_34_10 = arg_34_0:getPanelChild_(arg_34_1, var_34_8.relativeToName)
		local var_34_11

		if var_34_10 then
			arg_34_0:calcChildPosByName_(arg_34_1, var_34_8.relativeToName, arg_34_3)

			var_34_11 = cc.rect(var_34_10.options.x - (var_34_10.options.anchorPointX or 0.5) * var_34_10.options.width or 0, var_34_10.options.y - (var_34_10.options.anchorPointY or 0.5) * var_34_10.options.height or 0, var_34_10.options.width or 0, var_34_10.options.height or 0)
		end

		if var_34_8.align == 1 then
			var_34_3 = var_34_6 * 0.5
			var_34_4 = arg_34_3.height - var_34_7 * 0.5
			var_34_3 = var_34_3 + (var_34_8.marginLeft or 0)
			var_34_4 = var_34_4 - (var_34_8.marginTop or 0)
		elseif var_34_8.align == 2 then
			var_34_3 = arg_34_3.width * 0.5
			var_34_4 = arg_34_3.height - var_34_7 * 0.5
			var_34_4 = var_34_4 - (var_34_8.marginTop or 0)
		elseif var_34_8.align == 3 then
			var_34_3 = arg_34_3.width - var_34_6 * 0.5
			var_34_4 = arg_34_3.height - var_34_7 * 0.5
			var_34_3 = var_34_3 - (var_34_8.marginRight or 0)
			var_34_4 = var_34_4 - (var_34_8.marginTop or 0)
		elseif var_34_8.align == 4 then
			var_34_3 = var_34_6 * 0.5
			var_34_4 = arg_34_3.height * 0.5
			var_34_3 = var_34_3 + (var_34_8.marginLeft or 0)
		elseif var_34_8.align == 5 then
			var_34_3 = arg_34_3.width * 0.5
			var_34_4 = arg_34_3.height * 0.5
		elseif var_34_8.align == 6 then
			var_34_3 = arg_34_3.width - var_34_6 * 0.5
			var_34_4 = arg_34_3.height * 0.5
			var_34_3 = var_34_3 - (var_34_8.marginRight or 0)
		elseif var_34_8.align == 7 then
			var_34_3 = var_34_6 * 0.5
			var_34_4 = var_34_7 * 0.5
			var_34_3 = var_34_3 + (var_34_8.marginLeft or 0)
			var_34_4 = var_34_4 + (var_34_8.marginDown or 0)
		elseif var_34_8.align == 8 then
			var_34_3 = arg_34_3.width * 0.5
			var_34_4 = var_34_7 * 0.5
			var_34_4 = var_34_4 + (var_34_8.marginDown or 0)
		elseif var_34_8.align == 9 then
			var_34_3 = arg_34_3.width - var_34_6 * 0.5
			var_34_4 = var_34_7 * 0.5
			var_34_3 = var_34_3 - (var_34_8.marginRight or 0)
			var_34_4 = var_34_4 + (var_34_8.marginDown or 0)
		elseif var_34_8.align == 10 then
			var_34_3 = var_34_11.x + var_34_6 * 0.5
			var_34_4 = var_34_11.y + var_34_11.height + var_34_7 * 0.5
			var_34_3 = var_34_3 + (var_34_8.marginLeft or 0)
			var_34_4 = var_34_4 + (var_34_8.marginDown or 0)
		elseif var_34_8.align == 11 then
			var_34_3 = var_34_11.x + var_34_11.width * 0.5
			var_34_4 = var_34_11.y + var_34_11.height + var_34_7 * 0.5
			var_34_4 = var_34_4 + (var_34_8.marginDown or 0)
		elseif var_34_8.align == 12 then
			var_34_3 = var_34_11.x + var_34_11.width - var_34_6 * 0.5
			var_34_4 = var_34_11.y + var_34_11.height + var_34_7 * 0.5
			var_34_3 = var_34_3 - (var_34_8.marginRight or 0)
			var_34_4 = var_34_4 + (var_34_8.marginDown or 0)
		elseif var_34_8.align == 13 then
			var_34_3 = var_34_11.x - var_34_6 * 0.5
			var_34_4 = var_34_11.y + var_34_11.height - var_34_7 * 0.5
			var_34_3 = var_34_3 - (var_34_8.marginRight or 0)
			var_34_4 = var_34_4 - (var_34_8.marginTop or 0)
		elseif var_34_8.align == 14 then
			var_34_3 = var_34_11.x - var_34_6 * 0.5
			var_34_4 = var_34_11.y + var_34_11.height * 0.5
			var_34_3 = var_34_3 - (var_34_8.marginRight or 0)
		elseif var_34_8.align == 15 then
			var_34_3 = var_34_11.x - var_34_6 * 0.5
			var_34_4 = var_34_11.y + var_34_7 * 0.5
			var_34_3 = var_34_3 - (var_34_8.marginRight or 0)
			var_34_4 = var_34_4 + (var_34_8.marginDown or 0)
		elseif var_34_8.align == 16 then
			var_34_3 = var_34_11.x + var_34_11.width + var_34_6 * 0.5
			var_34_4 = var_34_11.y + var_34_11.height - var_34_7 * 0.5
			var_34_3 = var_34_3 + (var_34_8.marginLeft or 0)
			var_34_4 = var_34_4 - (var_34_8.marginTop or 0)
		elseif var_34_8.align == 17 then
			var_34_3 = var_34_11.x + var_34_11.width + var_34_6 * 0.5
			var_34_4 = var_34_11.y + var_34_11.height * 0.5
			var_34_3 = var_34_3 + (var_34_8.marginLeft or 0)
		elseif var_34_8.align == 18 then
			var_34_3 = var_34_11.x + var_34_11.width + var_34_6 * 0.5
			var_34_4 = var_34_11.y + var_34_7 * 0.5
			var_34_3 = var_34_3 + (var_34_8.marginLeft or 0)
			var_34_4 = var_34_4 + (var_34_8.marginDown or 0)
		elseif var_34_8.align == 19 then
			var_34_3 = var_34_11.x + var_34_6 * 0.5
			var_34_4 = var_34_11.y - var_34_7 * 0.5
			var_34_3 = var_34_3 + (var_34_8.marginLeft or 0)
			var_34_4 = var_34_4 - (var_34_8.marginTop or 0)
		elseif var_34_8.align == 20 then
			var_34_3 = var_34_11.x + var_34_11.width * 0.5
			var_34_4 = var_34_11.y - var_34_7 * 0.5
			var_34_4 = var_34_4 - (var_34_8.marginTop or 0)
		elseif var_34_8.align == 21 then
			var_34_3 = var_34_11.x + var_34_11.width - var_34_6 * 0.5
			var_34_4 = var_34_11.y - var_34_7 * 0.5
			var_34_3 = var_34_3 - (var_34_8.marginRight or 0)
			var_34_4 = var_34_4 - (var_34_8.marginTop or 0)
		else
			var_34_3 = var_34_2.x
			var_34_4 = var_34_2.y

			local var_34_12 = true

			print("CCSUILoader - modifyLayoutChildPos_ not support align:" .. var_34_8.align)
		end

		var_34_3 = ((var_34_2.anchorPointX or 0.5) - 0.5) * var_34_6 + var_34_3
		var_34_4 = ((var_34_2.anchorPointY or 0.5) - 0.5) * var_34_7 + var_34_4
	elseif var_34_8.type == 0 then
		var_34_3 = var_34_2.x
		var_34_4 = var_34_2.y
	else
		print("CCSUILoader - modifyLayoutChildPos_ not support type:" .. var_34_8.type)
	end

	var_34_2.x = var_34_3
	var_34_2.y = var_34_4
	var_34_0.posFixed_ = true
end

function var_0_1.getPanelChild_(arg_35_0, arg_35_1, arg_35_2)
	for iter_35_0, iter_35_1 in ipairs(arg_35_1) do
		if iter_35_1.options.name == arg_35_2 then
			return iter_35_1
		end
	end
end

return var_0_1
