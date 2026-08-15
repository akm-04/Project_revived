local var_0_0 = import(".UIScrollView")
local var_0_1 = class("UIListViewItem", function()
	return cc.Node:create()
end)

var_0_1.BG_TAG = 1
var_0_1.BG_Z_ORDER = 1
var_0_1.CONTENT_TAG = 11
var_0_1.CONTENT_Z_ORDER = 11
var_0_1.ID_COUNTER = 0

function var_0_1.ctor(arg_2_0, arg_2_1)
	arg_2_0.width = 0
	arg_2_0.height = 0
	arg_2_0.margin_ = {
		top = 0,
		bottom = 0,
		left = 0,
		right = 0
	}
	var_0_1.ID_COUNTER = var_0_1.ID_COUNTER + 1
	arg_2_0.id = var_0_1.ID_COUNTER

	arg_2_0:setTag(arg_2_0.id)
	arg_2_0:addContent(arg_2_1)
end

function var_0_1.addContent(arg_3_0, arg_3_1)
	if not arg_3_1 then
		return
	end

	arg_3_0:addChild(arg_3_1, var_0_1.CONTENT_Z_ORDER, var_0_1.CONTENT_TAG)
end

function var_0_1.getContent(arg_4_0)
	return arg_4_0:getChildByTag(var_0_1.CONTENT_TAG)
end

function var_0_1.setItemSize(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if not arg_5_3 then
		if var_0_0.DIRECTION_VERTICAL == arg_5_0.lvDirection_ then
			arg_5_2 = arg_5_2 + arg_5_0.margin_.top + arg_5_0.margin_.bottom
		else
			arg_5_1 = arg_5_1 + arg_5_0.margin_.left + arg_5_0.margin_.right
		end
	end

	local var_5_0 = {
		width = arg_5_0.width,
		height = arg_5_0.height
	}
	local var_5_1 = {
		width = arg_5_1,
		height = arg_5_2
	}

	arg_5_0.width = arg_5_1 or 0
	arg_5_0.height = arg_5_2 or 0

	arg_5_0:setContentSize(arg_5_1, arg_5_2)

	local var_5_2 = arg_5_0:getChildByTag(var_0_1.BG_TAG)

	if var_5_2 then
		var_5_2:setContentSize(arg_5_1, arg_5_2)
		var_5_2:setPosition(cc.p(arg_5_1 / 2, arg_5_2 / 2))
	end

	arg_5_0.listener(arg_5_0, var_5_1, var_5_0)
end

function var_0_1.getItemSize(arg_6_0)
	return arg_6_0.width, arg_6_0.height
end

function var_0_1.setMargin(arg_7_0, arg_7_1)
	arg_7_0.margin_ = arg_7_1
end

function var_0_1.getMargin(arg_8_0)
	return arg_8_0.margin_
end

function var_0_1.setBg(arg_9_0, arg_9_1)
	local var_9_0 = display.newScale9Sprite(arg_9_1)

	var_9_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_9_0:setPosition(cc.p(arg_9_0.width / 2, arg_9_0.height / 2))
	arg_9_0:addChild(var_9_0, var_0_1.BG_Z_ORDER, var_0_1.BG_TAG)
end

function var_0_1.onSizeChange(arg_10_0, arg_10_1)
	arg_10_0.listener = arg_10_1

	return arg_10_0
end

function var_0_1.setDirction(arg_11_0, arg_11_1)
	arg_11_0.lvDirection_ = arg_11_1
end

return var_0_1
