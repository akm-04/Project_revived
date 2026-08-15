local var_0_0 = class("TableViewItem", function()
	return cc.Node:create()
end)

var_0_0.CONTENT_TAG = 11
var_0_0.CONTENT_Z_ORDER = 11

function var_0_0.ctor(arg_2_0)
	arg_2_0.index = 0
	arg_2_0.itemSize = cc.size(0, 0)
end

function var_0_0.setIndex(arg_3_0, arg_3_1)
	arg_3_0.index = arg_3_1
end

function var_0_0.setItemSize(arg_4_0, arg_4_1, arg_4_2)
	if type(arg_4_1) == "table" then
		arg_4_0.itemSize = arg_4_1
	elseif type(arg_4_1) == "number" then
		arg_4_0.itemSize = cc.size(arg_4_1, arg_4_2)
	end

	arg_4_0:setContentSize(arg_4_0.itemSize)
end

function var_0_0.getItemSize(arg_5_0)
	return arg_5_0.itemSize
end

function var_0_0.addContent(arg_6_0, arg_6_1)
	arg_6_0:addChild(arg_6_1, var_0_0.CONTENT_Z_ORDER, var_0_0.CONTENT_TAG)
end

function var_0_0.getContent(arg_7_0)
	return arg_7_0:getChildByTag(var_0_0.CONTENT_TAG)
end

function var_0_0.reset(arg_8_0)
	arg_8_0.index = 0
	arg_8_0.itemSize = cc.size(0, 0)
end

local var_0_1 = class("UITableView", function()
	return cc.ClippingRegionNode:create()
end)

var_0_1.DIRECTION_VERTICAL = 1
var_0_1.DIRECTION_HORIZONTAL = 2
var_0_1.CELL_TAG = 1
var_0_1.CELL_SIZE_TAG = 2
var_0_1.COUNT_TAG = 3
var_0_1.UNLOAD_CELL_TAG = 4
var_0_1.ALIGNMENT_CENTER = 0
var_0_1.ALIGNMENT_LEFT = 1
var_0_1.ALIGNMENT_RIGHT = 2
var_0_1.ALIGNMENT_TOP = 3
var_0_1.ALIGNMENT_BOTTOM = 4

function var_0_1.ctor(arg_10_0, arg_10_1)
	arg_10_0.direction = arg_10_1.direction or var_0_1.DIRECTION_VERTICAL
	arg_10_0.itemSize = arg_10_1.itemSize
	arg_10_0.itemGap = arg_10_1.itemGap or 0
	arg_10_0.sideResisVal = 0.01
	arg_10_0.sideViewVal = 0.9 / arg_10_0.sideResisVal
	arg_10_0.speed = {
		x = 0,
		y = 0
	}
	arg_10_0.bAsyncLoad = arg_10_1.async or false
	arg_10_0.alignment = arg_10_1.alignment or var_0_1.ALIGNMENT_CENTER
	arg_10_0.isMoving_ = false
	arg_10_0.itemsUsed_ = {}
	arg_10_0.itemsFreed_ = {}
	arg_10_0.itemsPos_ = {}

	arg_10_0:setTouchType(arg_10_1.touchOnContent or true)
	arg_10_0:init(arg_10_1.size)

	if arg_10_0.bAsyncLoad then
		arg_10_0:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(...)
			arg_10_0:update_(...)
		end)
		arg_10_0:scheduleUpdate()
	end
end

function var_0_1.init(arg_12_0, arg_12_1)
	arg_12_0:setClippingRegion(cc.rect(0, 0, arg_12_1.width, arg_12_1.height))

	arg_12_0.size = arg_12_1
	arg_12_0.touchNode = display.newNode():addTo(arg_12_0)

	arg_12_0.touchNode:setContentSize(arg_12_1)
	arg_12_0.touchNode:setTouchEnabled(true)
	arg_12_0.touchNode:setTouchSwallowEnabled(true)
	arg_12_0.touchNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		return arg_12_0:onTouch_(arg_13_0)
	end)

	arg_12_0.scrollNode = display.newNode():addTo(arg_12_0)

	arg_12_0.scrollNode:setTouchEnabled(true)
	arg_12_0.scrollNode:setTouchSwallowEnabled(false)
	arg_12_0.scrollNode:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, function(arg_14_0)
		if arg_12_0:isTouchInViewRect(arg_14_0) then
			return true
		else
			return false
		end
	end)
end

function var_0_1.isTouchInViewRect(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0:convertToWorldSpace(cc.p(0, 0))

	var_15_0.width = arg_15_0.size.width
	var_15_0.height = arg_15_0.size.height

	return cc.rectContainsPoint(var_15_0, cc.p(arg_15_1.x, arg_15_1.y))
end

function var_0_1.setViewCanNotScroll(arg_16_0, arg_16_1)
	arg_16_0.listViewCanNotScroll = arg_16_1
end

function var_0_1.setTouchType(arg_17_0, arg_17_1)
	arg_17_0.touchOnContent = arg_17_1

	return arg_17_0
end

function var_0_1.setSideResisVal(arg_18_0, arg_18_1)
	arg_18_0.sideResisVal = arg_18_1

	if arg_18_0.sideResisVal == 0 then
		arg_18_0.sideViewVal = 9999
	else
		arg_18_0.sideViewVal = 0.9 / arg_18_0.sideResisVal
	end
end

function var_0_1.setAlignment(arg_19_0, arg_19_1)
	arg_19_0.alignment = arg_19_1
end

function var_0_1.update_(arg_20_0, arg_20_1)
	if not arg_20_0.isMoving_ then
		return
	end

	arg_20_0:increaseOrReduceItem_()
end

function var_0_1.setDelegate(arg_21_0, arg_21_1)
	arg_21_0.delegate_ = arg_21_1
end

function var_0_1.disableScrollAuto(arg_22_0, arg_22_1)
	arg_22_0.disScrollAuto = arg_22_1
end

function var_0_1.onScroll(arg_23_0, arg_23_1)
	arg_23_0.scrollListener_ = arg_23_1

	return arg_23_0
end

function var_0_1.onTouch_(arg_24_0, arg_24_1)
	if arg_24_0.listViewCanNotScroll then
		return false
	end

	if arg_24_1.name == "began" and arg_24_0.touchOnContent then
		local var_24_0 = arg_24_0.scrollNode:getCascadeBoundingBox()

		if not cc.rectContainsPoint(var_24_0, cc.p(arg_24_1.x, arg_24_1.y)) then
			return false
		end
	end

	if arg_24_1.name == "began" then
		arg_24_0.isMoving_ = true
		arg_24_0.bDrag_ = false

		transition.stopTarget(arg_24_0.scrollNode)
		arg_24_0:callListener_({
			name = "began",
			x = arg_24_1.x,
			y = arg_24_1.y
		})

		return true
	elseif arg_24_1.name == "moved" then
		if math.abs(arg_24_1.x - arg_24_1.startX) < 5 and math.abs(arg_24_1.y - arg_24_1.startY) < 5 then
			return
		end

		arg_24_0.bDrag_ = true

		if arg_24_0.direction == var_0_1.DIRECTION_VERTICAL then
			arg_24_0.speed.y = arg_24_1.y - arg_24_1.prevY

			arg_24_0:scrollByY(arg_24_0.speed.y)
		elseif arg_24_0.direction == var_0_1.DIRECTION_HORIZONTAL then
			arg_24_0.speed.x = arg_24_1.x - arg_24_1.prevX

			arg_24_0:scrollByX(arg_24_0.speed.x)
		end

		arg_24_0:callListener_({
			name = "moved",
			x = arg_24_1.x,
			y = arg_24_1.y
		})
	elseif arg_24_1.name == "ended" then
		if arg_24_0.bDrag_ then
			arg_24_0.bDrag_ = false

			arg_24_0:scrollAuto()
			arg_24_0:callListener_({
				name = "ended",
				x = arg_24_1.x,
				y = arg_24_1.y
			})
		else
			if arg_24_0:isSideShow() then
				arg_24_0:elasticScroll()
			else
				arg_24_0.isMoving_ = false

				arg_24_0:increaseOrReduceItem_()
			end

			arg_24_0:callListener_({
				name = "clicked",
				x = arg_24_1.x,
				y = arg_24_1.y
			})
		end
	end
end

function var_0_1.scrollByX(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0.scrollNode:getPositionX()

	if var_25_0 > 0 then
		var_25_0 = var_25_0 / (1 - arg_25_0.sideResisVal * var_25_0)
	elseif arg_25_0.size.width - arg_25_0.total - var_25_0 > 0 then
		local var_25_1 = arg_25_0.size.width - arg_25_0.total - var_25_0

		var_25_0 = arg_25_0.size.width - arg_25_0.total - var_25_1 / (1 - arg_25_0.sideResisVal * var_25_1)
	end

	local var_25_2 = var_25_0 + arg_25_1
	local var_25_3 = var_25_2

	if var_25_3 >= 0 then
		var_25_2 = var_25_3 / (1 + arg_25_0.sideResisVal * var_25_3)
	end

	local var_25_4 = arg_25_0.size.width - arg_25_0.total - var_25_2

	if var_25_4 >= 0 then
		var_25_2 = arg_25_0.size.width - arg_25_0.total - var_25_4 / (1 + arg_25_0.sideResisVal * var_25_4)
	end

	arg_25_0.scrollNode:setPositionX(var_25_2)
end

function var_0_1.scrollByY(arg_26_0, arg_26_1)
	local var_26_0 = arg_26_0.scrollNode:getPositionY()

	if -var_26_0 > 0 then
		var_26_0 = var_26_0 / (1 + arg_26_0.sideResisVal * var_26_0)
	elseif var_26_0 - arg_26_0.total + arg_26_0.size.height > 0 then
		local var_26_1 = var_26_0 - arg_26_0.total + arg_26_0.size.height

		var_26_0 = arg_26_0.total - arg_26_0.size.height + var_26_1 / (1 - arg_26_0.sideResisVal * var_26_1)
	end

	local var_26_2 = var_26_0 + arg_26_1
	local var_26_3 = -var_26_2

	if var_26_3 > 0 then
		var_26_2 = -var_26_3 / (1 + arg_26_0.sideResisVal * var_26_3)
	end

	local var_26_4 = var_26_2 - arg_26_0.total + arg_26_0.size.height

	if var_26_4 > 0 then
		var_26_2 = arg_26_0.total - arg_26_0.size.height + var_26_4 / (1 + arg_26_0.sideResisVal * var_26_4)
	end

	arg_26_0.scrollNode:setPositionY(var_26_2)
end

function var_0_1.scrollAuto(arg_27_0)
	if arg_27_0.disScrollAuto then
		arg_27_0.isMoving_ = false

		arg_27_0:increaseOrReduceItem_()

		return
	end

	if arg_27_0:twiningScroll() then
		return
	end

	arg_27_0:elasticScroll()
end

function var_0_1.twiningScroll(arg_28_0)
	if arg_28_0:isSideShow() then
		return
	end

	if math.abs(arg_28_0.speed.x) < 10 and math.abs(arg_28_0.speed.y) < 10 then
		return
	end

	local var_28_0 = 210
	local var_28_1, var_28_2 = arg_28_0.scrollNode:getPosition()
	local var_28_3 = 0
	local var_28_4 = 0
	local var_28_5

	if arg_28_0.direction == var_0_1.DIRECTION_VERTICAL then
		arg_28_0.speed.y = math.max(-var_28_0, math.min(var_28_0, arg_28_0.speed.y))
		var_28_4 = math.max(-arg_28_0.sideViewVal - var_28_2, math.min(arg_28_0.total + arg_28_0.sideViewVal - var_28_2 - arg_28_0.size.height, arg_28_0.speed.y * 12))
		var_28_5 = math.abs(var_28_4) / 840
	elseif arg_28_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		arg_28_0.speed.x = math.max(-var_28_0, math.min(var_28_0, arg_28_0.speed.x))
		var_28_3 = math.max(arg_28_0.size.width - arg_28_0.total - arg_28_0.sideViewVal - var_28_1, math.min(arg_28_0.sideViewVal - var_28_1, arg_28_0.speed.x * 12))
		var_28_5 = math.abs(var_28_3) / 840
	end

	transition.moveBy(arg_28_0.scrollNode, {
		easing = "sineOut",
		x = var_28_3,
		y = var_28_4,
		time = var_28_5,
		onComplete = function()
			if arg_28_0:isSideShow() then
				arg_28_0:elasticScroll()
			else
				arg_28_0.isMoving_ = false

				arg_28_0:increaseOrReduceItem_()
			end

			arg_28_0.speed.x = 0
			arg_28_0.speed.y = 0
		end
	})

	return true
end

function var_0_1.elasticScroll(arg_30_0)
	local var_30_0, var_30_1 = arg_30_0.scrollNode:getPosition()
	local var_30_2 = 0
	local var_30_3 = 0

	if arg_30_0.direction == var_0_1.DIRECTION_VERTICAL then
		if var_30_1 < 0 then
			var_30_3 = -var_30_1
		elseif var_30_1 > arg_30_0.total - arg_30_0.size.height then
			var_30_3 = arg_30_0.total - arg_30_0.size.height - var_30_1
		end
	elseif arg_30_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		if var_30_0 > 0 then
			var_30_2 = -var_30_0
		elseif var_30_0 < arg_30_0.size.width - arg_30_0.total then
			var_30_2 = arg_30_0.size.width - arg_30_0.total - var_30_0
		end
	end

	if var_30_2 == 0 and var_30_3 == 0 then
		arg_30_0.isMoving_ = false

		arg_30_0:increaseOrReduceItem_()

		return
	end

	transition.moveBy(arg_30_0.scrollNode, {
		easing = "backout",
		time = 0.3,
		x = var_30_2,
		y = var_30_3,
		onComplete = function()
			arg_30_0.isMoving_ = false

			arg_30_0:increaseOrReduceItem_()
			arg_30_0:callListener_({
				name = "scrollEnd"
			})
		end
	})
end

function var_0_1.callListener_(arg_32_0, arg_32_1)
	if not arg_32_0.scrollListener_ then
		return
	end

	arg_32_1.scrollView = arg_32_0

	arg_32_0.scrollListener_(arg_32_1)
end

function var_0_1.alignItem(arg_33_0, arg_33_1)
	local var_33_0 = arg_33_1:getContent()

	if not var_33_0 or tolua.isnull(var_33_0) then
		return
	end

	local var_33_1 = var_33_0:getContentSize()

	if var_33_1.width == 0 or var_33_1.height == 0 then
		return
	end

	local var_33_2 = arg_33_1:getItemSize()

	var_33_0:setAnchorPoint(0.5, 0.5)

	if arg_33_0.direction == var_0_1.DIRECTION_VERTICAL then
		if arg_33_0.alignment == var_0_1.ALIGNMENT_LEFT then
			var_33_0:setPosition(var_33_1.width / 2, var_33_2.height / 2)
		elseif arg_33_0.alignment == var_0_1.ALIGNMENT_RIGHT then
			var_33_0:setPosition(var_33_2.width - var_33_1.width / 2, var_33_2.height / 2)
		else
			var_33_0:setPosition(var_33_2.width / 2, var_33_2.height / 2)
		end
	elseif arg_33_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		if arg_33_0.alignment == var_0_1.ALIGNMENT_TOP then
			var_33_0:setPosition(var_33_2.width / 2, var_33_2.height - var_33_1.height / 2)
		elseif arg_33_0.alignment == var_0_1.ALIGNMENT_BOTTOM then
			var_33_0:setPosition(var_33_2.width / 2, var_33_1.height / 2)
		else
			var_33_0:setPosition(var_33_2.width / 2, var_33_2.height / 2)
		end
	end
end

function var_0_1.changeItemSize(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0
	local var_34_1

	if type(arg_34_1) == "number" then
		var_34_0 = arg_34_1
		var_34_1 = arg_34_0.itemsUsed_[arg_34_1]
	elseif type(arg_34_1) == "userdata" then
		for iter_34_0, iter_34_1 in ipairs(arg_34_0.itemsUsed_) do
			if iter_34_1 == arg_34_1 then
				var_34_0 = iter_34_0

				break
			end
		end

		var_34_1 = arg_34_1
	end

	if not var_34_0 or not var_34_1 then
		return
	end

	local var_34_2 = var_34_1:getItemSize()

	var_34_1:setItemSize(arg_34_2)

	if arg_34_0.direction == var_0_1.DIRECTION_VERTICAL then
		itemH = arg_34_2.height - var_34_2.height

		transition.moveBy(var_34_1, {
			time = 0.2,
			x = 0,
			y = -itemH / 2
		})
		arg_34_0:moveItems(var_34_0 + 1, #arg_34_0.itemsUsed_, 0, -itemH)
		arg_34_0:setTotal(arg_34_0.total + itemH)
	elseif arg_34_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		itemW = arg_34_2.width - var_34_2.width

		transition.moveBy(var_34_1, {
			time = 0.2,
			y = 0,
			x = itemW / 2
		})
		arg_34_0:moveItems(var_34_0 + 1, #arg_34_0.itemsUsed_, itemW, 0)
		arg_34_0:setTotal(arg_34_0.total + itemW)
	end
end

function var_0_1.moveItems(arg_35_0, arg_35_1, arg_35_2, arg_35_3, arg_35_4)
	local var_35_0 = {
		time = 0.2,
		x = arg_35_3,
		y = arg_35_4
	}

	for iter_35_0 = arg_35_1, arg_35_2 do
		if iter_35_0 == arg_35_1 then
			function var_35_0.onComplete()
				arg_35_0:elasticScroll()
			end
		end

		transition.moveBy(arg_35_0.itemsUsed_[iter_35_0], var_35_0)
	end
end

function var_0_1.setTotal(arg_37_0, arg_37_1)
	arg_37_0.total = arg_37_1

	if arg_37_0.direction == var_0_1.DIRECTION_VERTICAL and arg_37_1 < arg_37_0.size.height then
		arg_37_0.total = arg_37_0.size.height
	elseif arg_37_0.direction == var_0_1.DIRECTION_HORIZONTAL and arg_37_1 < arg_37_0.size.width then
		arg_37_0.total = arg_37_0.size.width
	end
end

function var_0_1.isSideShow(arg_38_0)
	local var_38_0, var_38_1 = arg_38_0.scrollNode:getPosition()

	if arg_38_0.direction == var_0_1.DIRECTION_VERTICAL then
		return var_38_1 < 0 or var_38_1 > arg_38_0.total - arg_38_0.size.height
	elseif arg_38_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		return var_38_0 > 0 or var_38_0 < arg_38_0.size.width - arg_38_0.total
	end
end

function var_0_1.updateItemAtIndex(arg_39_0, arg_39_1)
	if arg_39_1 <= 0 then
		return
	end

	local var_39_0 = arg_39_0.delegate_(arg_39_0, var_0_1.COUNT_TAG)

	if var_39_0 == 0 or var_39_0 < arg_39_1 then
		return
	end

	local var_39_1 = arg_39_0.itemsUsed_[arg_39_1]

	if var_39_1 then
		arg_39_0:moveItemOutOfSight(var_39_1)
	end

	local var_39_2 = arg_39_0.delegate_(arg_39_0, var_0_1.CELL_TAG, arg_39_1)
	local var_39_3 = arg_39_0.itemSize or arg_39_0.delegate_(arg_39_0, var_0_1.CELL_SIZE_TAG, arg_39_1)

	var_39_2:setItemSize(var_39_3.width, var_39_3.height)
	arg_39_0:alignItem(var_39_2)

	if arg_39_0.direction == var_0_1.DIRECTION_VERTICAL then
		var_39_2:setPosition(0, arg_39_0:offsetFromIndex(arg_39_1))
	elseif arg_39_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		var_39_2:setPosition(arg_39_0:offsetFromIndex(arg_39_1), 0)
	end

	var_39_2:setIndex(arg_39_1)
	arg_39_0:addItemIfNecessary(var_39_2)
end

function var_0_1.moveItemOutOfSight(arg_40_0, arg_40_1)
	arg_40_0.itemsUsed_[arg_40_1.index] = nil

	table.insert(arg_40_0.itemsFreed_, arg_40_1)
	arg_40_0.delegate_(arg_40_0, var_0_1.UNLOAD_CELL_TAG, arg_40_1.index)
	arg_40_1:reset()
	arg_40_1:setVisible(false)
end

function var_0_1.addItemIfNecessary(arg_41_0, arg_41_1)
	arg_41_1:setVisible(true)

	if arg_41_1:getParent() ~= arg_41_0.scrollNode then
		arg_41_1:addTo(arg_41_0.scrollNode)
	end

	arg_41_0.itemsUsed_[arg_41_1.index] = arg_41_1
end

function var_0_1.offsetFromIndex(arg_42_0, arg_42_1)
	local var_42_0

	if arg_42_0.direction == var_0_1.DIRECTION_VERTICAL then
		local var_42_1 = arg_42_0.itemSize or arg_42_0.delegate_(arg_42_0, var_0_1.CELL_SIZE_TAG, arg_42_1)

		var_42_0 = arg_42_0.size.height - arg_42_0.itemsPos_[arg_42_1] - var_42_1.height
	elseif var_0_1.DIRECTION_HORIZONTAL then
		var_42_0 = arg_42_0.itemsPos_[arg_42_1]
	end

	return var_42_0
end

function var_0_1.updateItemsPosition_(arg_43_0)
	local var_43_0 = arg_43_0.delegate_(arg_43_0, var_0_1.COUNT_TAG)

	arg_43_0.itemsPos_ = {}

	if var_43_0 <= 0 then
		return
	end

	local var_43_1 = 0
	local var_43_2

	for iter_43_0 = 1, var_43_0 do
		table.insert(arg_43_0.itemsPos_, var_43_1)

		local var_43_3 = arg_43_0.itemSize or arg_43_0.delegate_(arg_43_0, var_0_1.CELL_SIZE_TAG, iter_43_0)

		if arg_43_0.direction == var_0_1.DIRECTION_VERTICAL then
			var_43_1 = var_43_1 + var_43_3.height + arg_43_0.itemGap
		elseif arg_43_0.direction == var_0_1.DIRECTION_HORIZONTAL then
			var_43_1 = var_43_1 + var_43_3.width + arg_43_0.itemGap
		end
	end

	table.insert(arg_43_0.itemsPos_, var_43_1)
	arg_43_0:setTotal(var_43_1 - arg_43_0.itemGap)
end

function var_0_1.dequeueItem(arg_44_0)
	return table.remove(arg_44_0.itemsFreed_, 1)
end

function var_0_1.newItem(arg_45_0)
	return var_0_0.new()
end

function var_0_1.getItem(arg_46_0)
	local var_46_0 = arg_46_0:dequeueItem()

	if var_46_0 then
		var_46_0:removeAllChildren()
	else
		var_46_0 = arg_46_0:newItem()
	end

	return var_46_0
end

function var_0_1.addItem(arg_47_0, arg_47_1, arg_47_2)
	if arg_47_2 then
		table.insert(arg_47_0.itemsUsed_, arg_47_2, arg_47_1)
	else
		table.insert(arg_47_0.itemsUsed_, arg_47_1)
	end

	arg_47_0.scrollNode:addChild(arg_47_1)
end

function var_0_1.reload(arg_48_0)
	transition.stopTarget(arg_48_0.scrollNode)

	if arg_48_0.bAsyncLoad then
		arg_48_0:asyncLoad_()
	else
		arg_48_0:layout_()
	end

	return arg_48_0
end

function var_0_1.reloadAtIndex(arg_49_0, arg_49_1, arg_49_2)
	if not arg_49_0.bAsyncLoad then
		return
	end

	local var_49_0 = arg_49_0.delegate_(arg_49_0, var_0_1.COUNT_TAG)

	arg_49_1 = math.min(math.max(arg_49_1, 1), var_49_0)

	transition.stopTarget(arg_49_0.scrollNode)
	arg_49_0:removeAllItems()
	arg_49_0:updateItemsPosition_()

	if var_49_0 <= 0 then
		return
	end

	local var_49_1

	if arg_49_0.direction == var_0_1.DIRECTION_VERTICAL then
		if arg_49_2 then
			var_49_1 = math.min(arg_49_0.itemsPos_[arg_49_1], arg_49_0.total - arg_49_0.size.height)
		else
			var_49_1 = math.max(arg_49_0.itemsPos_[arg_49_1 + 1] - arg_49_0.size.height - arg_49_0.itemGap, 0)
		end

		arg_49_0.scrollNode:setPosition(0, var_49_1)
	elseif arg_49_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		if arg_49_2 then
			var_49_1 = math.max(-arg_49_0.itemsPos_[arg_49_1], arg_49_0.size.width - arg_49_0.total)
		else
			var_49_1 = math.min(arg_49_0.size.width - arg_49_0.itemsPos_[arg_49_1 + 1] + arg_49_0.itemGap, 0)
		end

		arg_49_0.scrollNode:setPosition(var_49_1, 0)
	end

	arg_49_0.startIndex = arg_49_1
	arg_49_0.endIndex = arg_49_1

	arg_49_0:updateItemAtIndex(arg_49_1)
	arg_49_0:increaseOrReduceItem_()
end

function var_0_1.refreshList(arg_50_0)
	transition.stopTarget(arg_50_0.scrollNode)

	if not arg_50_0.bAsyncLoad then
		arg_50_0:layout_(true)

		return
	end

	if not next(arg_50_0.itemsUsed_) then
		arg_50_0:reload()

		return
	end

	arg_50_0:updateItemsPosition_()

	local var_50_0 = clone(arg_50_0.itemsUsed_)

	for iter_50_0, iter_50_1 in pairs(var_50_0) do
		arg_50_0:updateItemAtIndex(iter_50_0)
	end
end

function var_0_1.layout_(arg_51_0, arg_51_1)
	if not next(arg_51_0.itemsUsed_) then
		return
	end

	local var_51_0 = 0

	arg_51_0.itemsPos_ = {}

	if arg_51_0.direction == var_0_1.DIRECTION_VERTICAL then
		for iter_51_0, iter_51_1 in ipairs(arg_51_0.itemsUsed_) do
			arg_51_0:alignItem(iter_51_1)
			table.insert(arg_51_0.itemsPos_, var_51_0)
			iter_51_1:setPosition(0, arg_51_0.size.height - var_51_0 - iter_51_1:getItemSize().height)

			var_51_0 = var_51_0 + iter_51_1:getItemSize().height + arg_51_0.itemGap
		end
	elseif arg_51_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		for iter_51_2, iter_51_3 in ipairs(arg_51_0.itemsUsed_) do
			arg_51_0:alignItem(iter_51_3)
			table.insert(arg_51_0.itemsPos_, var_51_0)
			iter_51_3:setPosition(var_51_0, 0)

			var_51_0 = var_51_0 + iter_51_3:getItemSize().width + arg_51_0.itemGap
		end
	end

	table.insert(arg_51_0.itemsPos_, var_51_0)
	arg_51_0:setTotal(var_51_0 - arg_51_0.itemGap)

	if not arg_51_1 then
		arg_51_0.scrollNode:setPosition(0, 0)
	end
end

function var_0_1.asyncLoad_(arg_52_0)
	arg_52_0:removeAllItems()
	arg_52_0:updateItemsPosition_()
	arg_52_0.scrollNode:setPosition(0, 0)

	local var_52_0 = arg_52_0.delegate_(arg_52_0, var_0_1.COUNT_TAG)
	local var_52_1 = var_52_0
	local var_52_2

	if arg_52_0.direction == var_0_1.DIRECTION_VERTICAL then
		var_52_2 = arg_52_0.size.height
	elseif arg_52_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		var_52_2 = arg_52_0.size.width
	end

	for iter_52_0, iter_52_1 in ipairs(arg_52_0.itemsPos_) do
		if var_52_2 < iter_52_1 then
			var_52_1 = iter_52_0 - 1

			break
		end
	end

	local var_52_3 = math.min(var_52_1, var_52_0)

	for iter_52_2 = 1, var_52_3 do
		arg_52_0:updateItemAtIndex(iter_52_2)
	end

	arg_52_0.startIndex = 1
	arg_52_0.endIndex = var_52_3
end

function var_0_1.removeAllItems(arg_53_0)
	if arg_53_0.bAsyncLoad then
		for iter_53_0, iter_53_1 in pairs(arg_53_0.itemsUsed_) do
			arg_53_0:moveItemOutOfSight(iter_53_1)
		end
	else
		arg_53_0.scrollNode:removeAllChildren()

		arg_53_0.itemsUsed_ = {}
	end
end

function var_0_1.isItemInViewRect(arg_54_0, arg_54_1)
	local var_54_0

	if type(arg_54_1) == "number" then
		var_54_0 = arg_54_0.itemsUsed_[arg_54_1]
	elseif type(arg_54_1) == "userdata" then
		var_54_0 = arg_54_1
	end

	if not var_54_0 then
		return
	end

	if arg_54_0.bAsyncLoad then
		return true
	end

	local var_54_1, var_54_2 = arg_54_0.scrollNode:getPosition()
	local var_54_3, var_54_4 = var_54_0:getPosition()
	local var_54_5 = var_54_0:getItemSize()
	local var_54_6 = cc.rect(var_54_1 + var_54_3, var_54_2 + var_54_4, var_54_5.width, var_54_5.height)

	return cc.rectIntersectsRect(cc.rect(0, 0, arg_54_0.size.width, arg_54_0.size.height), var_54_6)
end

function var_0_1.increaseOrReduceItem_(arg_55_0)
	if not arg_55_0.startIndex or not arg_55_0.endIndex then
		return
	end

	local var_55_0 = arg_55_0.delegate_(arg_55_0, var_0_1.COUNT_TAG)

	if var_55_0 <= 0 then
		return
	end

	if not next(arg_55_0.itemsUsed_) then
		return
	end

	local var_55_1, var_55_2 = arg_55_0.scrollNode:getPosition()
	local var_55_3 = 2

	if arg_55_0.direction == var_0_1.DIRECTION_VERTICAL then
		if var_55_0 > arg_55_0.endIndex and arg_55_0:offsetFromIndex(arg_55_0.startIndex) + var_55_2 > arg_55_0.size.height then
			arg_55_0:moveItemOutOfSight(arg_55_0.itemsUsed_[arg_55_0.startIndex])

			arg_55_0.startIndex = arg_55_0.startIndex + 1
		elseif arg_55_0.startIndex > 1 and arg_55_0:offsetFromIndex(arg_55_0.startIndex - 1) + var_55_2 < arg_55_0.size.height then
			arg_55_0:updateItemAtIndex(arg_55_0.startIndex - 1)

			arg_55_0.startIndex = arg_55_0.startIndex - 1
		else
			var_55_3 = var_55_3 - 1
		end

		if arg_55_0.startIndex > 1 and arg_55_0:offsetFromIndex(arg_55_0.endIndex - 1) + var_55_2 < arg_55_0.itemGap then
			arg_55_0:moveItemOutOfSight(arg_55_0.itemsUsed_[arg_55_0.endIndex])

			arg_55_0.endIndex = arg_55_0.endIndex - 1
		elseif var_55_0 > arg_55_0.endIndex and arg_55_0:offsetFromIndex(arg_55_0.endIndex) + var_55_2 > arg_55_0.itemGap then
			arg_55_0:updateItemAtIndex(arg_55_0.endIndex + 1)

			arg_55_0.endIndex = arg_55_0.endIndex + 1
		else
			var_55_3 = var_55_3 - 1
		end
	elseif arg_55_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		if var_55_0 > arg_55_0.endIndex and arg_55_0:offsetFromIndex(arg_55_0.startIndex + 1) + var_55_1 < arg_55_0.itemGap then
			arg_55_0:moveItemOutOfSight(arg_55_0.itemsUsed_[arg_55_0.startIndex])

			arg_55_0.startIndex = arg_55_0.startIndex + 1
		elseif arg_55_0.startIndex > 1 and arg_55_0:offsetFromIndex(arg_55_0.startIndex) + var_55_1 > arg_55_0.itemGap then
			arg_55_0:updateItemAtIndex(arg_55_0.startIndex - 1)

			arg_55_0.startIndex = arg_55_0.startIndex - 1
		else
			var_55_3 = var_55_3 - 1
		end

		if arg_55_0.startIndex > 1 and arg_55_0:offsetFromIndex(arg_55_0.endIndex) + var_55_1 > arg_55_0.size.width then
			arg_55_0:moveItemOutOfSight(arg_55_0.itemsUsed_[arg_55_0.endIndex])

			arg_55_0.endIndex = arg_55_0.endIndex - 1
		elseif var_55_0 > arg_55_0.endIndex and arg_55_0:offsetFromIndex(arg_55_0.endIndex + 1) + var_55_1 < arg_55_0.size.width then
			arg_55_0:updateItemAtIndex(arg_55_0.endIndex + 1)

			arg_55_0.endIndex = arg_55_0.endIndex + 1
		else
			var_55_3 = var_55_3 - 1
		end
	end

	if var_55_3 > 0 then
		return arg_55_0:increaseOrReduceItem_()
	end
end

function var_0_1.scrollTo(arg_56_0, arg_56_1)
	if arg_56_0.direction == var_0_1.DIRECTION_VERTICAL then
		arg_56_0.scrollNode:setPosition(0, arg_56_1)
	elseif arg_56_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		arg_56_0.scrollNode:setPosition(arg_56_1, 0)
	end

	arg_56_0:increaseOrReduceItem_()
end

function var_0_1.scrollToIndex(arg_57_0, arg_57_1, arg_57_2)
	local var_57_0

	if arg_57_0.direction == var_0_1.DIRECTION_VERTICAL then
		if arg_57_2 then
			var_57_0 = math.min(arg_57_0.itemsPos_[arg_57_1], arg_57_0.total - arg_57_0.size.height)
		else
			var_57_0 = math.max(arg_57_0.itemsPos_[arg_57_1 + 1] - arg_57_0.size.height - arg_57_0.itemGap, 0)
		end
	elseif arg_57_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		if arg_57_2 then
			var_57_0 = math.max(-arg_57_0.itemsPos_[arg_57_1], arg_57_0.size.width - arg_57_0.total)
		else
			var_57_0 = math.min(arg_57_0.size.width - arg_57_0.itemsPos_[arg_57_1 + 1] + arg_57_0.itemGap, 0)
		end
	end

	arg_57_0:scrollTo(var_57_0)
end

function var_0_1.scrollToEnd(arg_58_0)
	if arg_58_0.direction == var_0_1.DIRECTION_VERTICAL then
		arg_58_0.scrollNode:setPosition(0, arg_58_0.total - arg_58_0.size.height)
	elseif arg_58_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		arg_58_0.scrollNode:setPosition(arg_58_0.size.width - arg_58_0.total, 0)
	end

	arg_58_0:increaseOrReduceItem_()
end

function var_0_1.scrollMoveTo(arg_59_0, arg_59_1, arg_59_2)
	local var_59_0 = 0
	local var_59_1 = 0
	local var_59_2, var_59_3 = arg_59_0.scrollNode:getPosition()

	if arg_59_0.direction == var_0_1.DIRECTION_VERTICAL then
		var_59_1 = arg_59_1 - var_59_3
	elseif arg_59_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		var_59_0 = arg_59_1 - var_59_2
	end

	arg_59_0.isMoving_ = true

	transition.moveBy(arg_59_0.scrollNode, {
		easing = "sineOut",
		x = var_59_0,
		y = var_59_1,
		time = arg_59_2,
		onComplete = function()
			if arg_59_0:isSideShow() then
				arg_59_0:elasticScroll()
			else
				arg_59_0.isMoving_ = false

				arg_59_0:increaseOrReduceItem_()
			end
		end
	})
end

function var_0_1.scrollMoveToIndex(arg_61_0, arg_61_1, arg_61_2, arg_61_3)
	local var_61_0

	if arg_61_0.direction == var_0_1.DIRECTION_VERTICAL then
		if arg_61_3 then
			var_61_0 = math.min(arg_61_0.itemsPos_[arg_61_1], arg_61_0.total - arg_61_0.size.height)
		else
			var_61_0 = math.max(arg_61_0.itemsPos_[arg_61_1 + 1] - arg_61_0.size.height - arg_61_0.itemGap, 0)
		end
	elseif arg_61_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		if arg_61_3 then
			var_61_0 = math.max(-arg_61_0.itemsPos_[arg_61_1], arg_61_0.size.width - arg_61_0.total)
		else
			var_61_0 = math.min(arg_61_0.size.width - arg_61_0.itemsPos_[arg_61_1 + 1] + arg_61_0.itemGap, 0)
		end
	end

	arg_61_0:scrollMoveTo(var_61_0, arg_61_2)
end

function var_0_1.scrollMoveToEnd(arg_62_0, arg_62_1)
	local var_62_0

	if arg_62_0.direction == var_0_1.DIRECTION_VERTICAL then
		var_62_0 = arg_62_0.total - arg_62_0.size.height
	elseif arg_62_0.direction == var_0_1.DIRECTION_HORIZONTAL then
		var_62_0 = arg_62_0.size.width - arg_62_0.total
	end

	arg_62_0:scrollMoveTo(var_62_0, arg_62_1)
end

function var_0_1.getStartIndex(arg_63_0)
	return arg_63_0.startIndex
end

function var_0_1.getEndIndex(arg_64_0)
	return arg_64_0.endIndex
end

return var_0_1
