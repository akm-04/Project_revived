local var_0_0 = class("SplitLine", function()
	return display.newNode()
end)
local var_0_1 = 1280
local var_0_2 = "#3C3C3C"
local var_0_3 = 90

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.width = arg_2_1.size

	if arg_2_0.width > var_0_1 then
		return
	end

	arg_2_0.color = arg_2_1.color or var_0_2
	arg_2_0.type = arg_2_1.type or xyd.SplitlineType.DOTED
	arg_2_0.offset = arg_2_1.offset or 0
	arg_2_0.align = arg_2_1.align or xyd.SplitLineAlign.LEFT
	arg_2_0.isVertical = arg_2_1.isVertical or false

	if arg_2_0.type == xyd.SplitlineType.DOTED then
		arg_2_0.source = "windows/common/icons/bg_split_line.png"
	elseif arg_2_0.type == xyd.SplitlineType.SOLID then
		arg_2_0.source = "windows/common/icons/bg_split_line_solid.png"
	end

	arg_2_0.lineSprite = xyd.AssetLoader.get():loadSprite(arg_2_0.source)

	if not arg_2_0.lineSprite then
		return
	end

	arg_2_0.lines = {}

	table.insert(arg_2_0.lines, arg_2_0.lineSprite)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = display.newNode()
	local var_3_1 = arg_3_0.lineSprite:getContentSize()

	var_3_1.height = var_3_1.height + 2

	arg_3_0:setContentSize(arg_3_0.width, var_3_1.height + 2)

	local var_3_2 = 0
	local var_3_3 = arg_3_0.width

	while var_3_3 > 0 do
		var_3_2 = var_3_2 + 1
		var_3_3 = var_3_3 - var_3_1.width
	end

	var_3_0:setContentSize(var_3_1.width * var_3_2, var_3_1.height + 2)
	arg_3_0.lineSprite:addTo(var_3_0)
	arg_3_0.lineSprite:setAnchorPoint(0, 0)
	arg_3_0.lineSprite:setPosition(0, 1)
	arg_3_0.lineSprite:setColor(xyd.convertHex2RGB(arg_3_0.color))
	arg_3_0.lineSprite:setLocalZOrder(-100)

	if var_3_2 > 1 then
		for iter_3_0 = 1, var_3_2 - 1 do
			local var_3_4 = xyd.AssetLoader.get():loadSprite(arg_3_0.source)

			var_3_4:addTo(var_3_0)
			var_3_4:setAnchorPoint(0, 0)
			var_3_4:setPosition(iter_3_0 * var_3_1.width, 1)
			var_3_4:setColor(xyd.convertHex2RGB(arg_3_0.color))
			var_3_4:setLocalZOrder(-100)
			table.insert(arg_3_0.lines, var_3_4)
		end
	end

	local var_3_5 = display.newScale9Sprite("images/line_mask.png", 0, 0, cc.size(arg_3_0.width, 3))

	var_3_5:setAnchorPoint(0, 0)

	local var_3_6 = cc.ClippingNode:create()

	var_3_6:setStencil(var_3_5)
	var_3_6:addTo(arg_3_0, 5)
	var_3_6:setAnchorPoint(0, 0)
	var_3_6:setPosition(0, 0)
	var_3_6:setInverted(false)
	var_3_6:setAlphaThreshold(0)
	var_3_6:addChild(var_3_0)

	if arg_3_0.align == xyd.SplitLineAlign.CENTER then
		var_3_5:setPositionX(arg_3_0:getWidth() / 2 - arg_3_0.width / 2 + arg_3_0.offset)
		arg_3_0:setAnchorPoint(cc.p(0.5, 0))
	elseif arg_3_0.align == xyd.SplitLineAlign.RIGHT then
		var_3_5:setPositionX(arg_3_0:getWidth() - arg_3_0.width + arg_3_0.offset)
		arg_3_0:setAnchorPoint(cc.p(1, 0))
	end

	if arg_3_0.isVertical then
		arg_3_0:setRotation(var_0_3)
	end
end

function var_0_0.setColor(arg_4_0, arg_4_1)
	arg_4_1 = xyd.convertHex2RGB(arg_4_1)

	if not arg_4_1 then
		return
	end

	if not arg_4_0.lines or not next(arg_4_0.lines) then
		return
	end

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.lines) do
		iter_4_1:setColor(arg_4_1)
	end
end

return var_0_0
