local var_0_0 = {}
local var_0_1 = cc
local var_0_2 = var_0_1.SpriteFrameCache:getInstance()

local function var_0_3(arg_1_0)
	for iter_1_0, iter_1_1 in ipairs(arg_1_0) do
		iter_1_1.rect.width = iter_1_1.rect.w
		iter_1_1.rect.height = iter_1_1.rect.h
		iter_1_1.originalSize.width = iter_1_1.rect.w
		iter_1_1.originalSize.height = iter_1_1.rect.h

		local var_1_0 = var_0_1.SpriteFrame:create(iter_1_1.texturePath, iter_1_1.rect, iter_1_1.rotated, iter_1_1.offset, iter_1_1.originalSize)

		if var_1_0 then
			var_0_2:addSpriteFrame(var_1_0, iter_1_1.name)
			print("Added frame:" .. iter_1_1.name)
		end
	end
end

local function var_0_4(arg_2_0, arg_2_1)
	arg_2_0:setAnchorPoint(arg_2_1.anchorPoint)
	arg_2_0:setCascadeOpacityEnabled(arg_2_1.cascadeOpacityEnabled)

	if arg_2_1.color then
		arg_2_0:setColor(arg_2_1.color)
	end

	if arg_2_1.contentSize then
		arg_2_0:setContentSize(arg_2_1.contentSize)
	end

	arg_2_0:setVisible(arg_2_1.enabled)

	if arg_2_1.globalZOrder then
		arg_2_0:setGlobalZOrder(arg_2_1.globalZOrder)
	end

	arg_2_0:setLocalZOrder(arg_2_1.localZOrder)
	arg_2_0:setOpacity(arg_2_1.opacity)
	arg_2_0:setOpacityModifyRGB(arg_2_1.opacityModifyRGB)

	if arg_2_1.tag then
		arg_2_0:setTag(arg_2_1.tag)
	end

	arg_2_0.name = arg_2_1.name

	if arg_2_1.position then
		arg_2_0:setPosition(arg_2_1.position.x, arg_2_1.position.y)
	end

	if arg_2_1.rotationSkewX then
		arg_2_0:setRotationSkewX(arg_2_1.rotationSkewX)
	end

	if arg_2_1.rotationSkewY then
		arg_2_0:setRotationSkewY(arg_2_1.rotationSkewY)
	end

	if arg_2_1.scaleX then
		arg_2_0:setScaleX(arg_2_1.scaleX)
	end

	if arg_2_1.scaleY then
		arg_2_0:setScaleY(arg_2_1.scaleY)
	end

	if arg_2_1.skewX then
		arg_2_0:setSkewX(arg_2_1.skewX)
	end

	if arg_2_1.skewY then
		arg_2_0:setSkewY(arg_2_1.skewY)
	end

	return arg_2_0
end

local var_0_5 = {
	Scene = function(arg_3_0)
		local var_3_0 = var_0_1.Node:create()

		return var_0_4(var_3_0, arg_3_0.node)
	end,
	Node = function(arg_4_0)
		local var_4_0 = var_0_1.Node:create()

		return var_0_4(var_4_0, arg_4_0)
	end,
	Sprite = function(arg_5_0)
		local var_5_0 = var_0_1.Sprite:createWithSpriteFrameName(arg_5_0.spriteFrameName)

		var_5_0:setBlendFunc(arg_5_0.srcBlend, arg_5_0.dstBlend)

		return var_0_4(var_5_0, arg_5_0.node)
	end,
	EditBox = function(arg_6_0)
		local var_6_0 = var_0_1.Node:create()

		return var_0_4(var_6_0, arg_6_0.node)
	end,
	Button = function(arg_7_0)
		local var_7_0 = ccui.Button:create(arg_7_0.spriteFrameName, arg_7_0.pressedSpriteFrameName, arg_7_0.disabledSpriteFrameName, 1)

		return var_0_4(var_7_0, arg_7_0.node)
	end,
	Label = function(arg_8_0)
		local var_8_0 = ccui.Text:create(arg_8_0.labelText, arg_8_0.fontName, arg_8_0.fontSize)

		var_8_0:setTextColor(arg_8_0.node.color)

		if arg_8_0.horizontalAlignment == "Left" then
			var_8_0:setTextHorizontalAlignment(var_0_1.TEXT_ALIGNMENT_LEFT)
		elseif arg_8_0.horizontalAlignment == "Center" then
			var_8_0:setTextHorizontalAlignment(var_0_1.TEXT_ALIGNMENT_CENTER)
		else
			var_8_0:setTextHorizontalAlignment(var_0_1.TEXT_ALIGNMENT_RIGHT)
		end

		if arg_8_0.verticalAlignment == "Bottom" then
			var_8_0:setTextVerticalAlignment(var_0_1.VERTICAL_TEXT_ALIGNMENT_BOTTOM)
		elseif arg_8_0.verticalAlignment == "Center" then
			var_8_0:setTextVerticalAlignment(var_0_1.VERTICAL_TEXT_ALIGNMENT_CENTER)
		else
			var_8_0:setTextVerticalAlignment(var_0_1.VERTICAL_TEXT_ALIGNMENT_TOP)
		end

		arg_8_0.node.color = nil
		arg_8_0.node.contentSize = nil

		return var_0_4(var_8_0, arg_8_0.node)
	end,
	ScrollView = function(arg_9_0)
		local var_9_0 = var_0_1.Node:create()

		return var_0_4(var_9_0, arg_9_0.node)
	end,
	Toggle = function(arg_10_0)
		local var_10_0 = var_0_1.Node:create()

		return var_0_4(var_10_0, arg_10_0.node)
	end,
	ToggleGroup = function(arg_11_0)
		local var_11_0 = var_0_1.Node:create()

		return var_0_4(var_11_0, arg_11_0.node)
	end,
	Slider = function(arg_12_0)
		local var_12_0 = var_0_1.Node:create()

		return var_0_4(var_12_0, arg_12_0.node)
	end
}

local function var_0_6(arg_13_0)
	local var_13_0 = arg_13_0:getParent()
	local var_13_1 = var_13_0:getAnchorPoint()
	local var_13_2 = var_13_0:getContentSize()
	local var_13_3 = var_13_1.x * var_13_2.width
	local var_13_4 = var_13_1.y * var_13_2.height

	arg_13_0:setPosition(arg_13_0:getPositionX() + var_13_3, arg_13_0:getPositionY() + var_13_4)
end

local function var_0_7(arg_14_0)
	if not var_0_5[arg_14_0.object_type] then
		print("Unsupport node tpye:", arg_14_0.object_type)

		return
	end

	local var_14_0 = var_0_5[arg_14_0.object_type](arg_14_0.object)

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.children) do
		local var_14_1 = var_0_7(iter_14_1)

		var_14_0:addChild(var_14_1)
		var_0_6(var_14_1)
	end

	return var_14_0
end

function var_0_0.parseJson(arg_15_0)
	local var_15_0 = var_0_1.FileUtils:getInstance():getDataFromFile(arg_15_0)
	local var_15_1 = json.decode(var_15_0)

	if not var_15_1 then
		print("==Fail to parse json from file:", arg_15_0)

		return
	end

	print(var_15_1.version)
	var_0_3(var_15_1.spriteFrames)

	return var_0_7(var_15_1.root)
end

return var_0_0
