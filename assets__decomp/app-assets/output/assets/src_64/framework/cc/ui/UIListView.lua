local var_0_0 = import(".UIScrollView")
local var_0_1 = class("UIListView", var_0_0)
local var_0_2 = import(".UIListViewItem")

var_0_1.DELEGATE = "ListView_delegate"
var_0_1.TOUCH_DELEGATE = "ListView_Touch_delegate"
var_0_1.CELL_TAG = "Cell"
var_0_1.CELL_SIZE_TAG = "CellSize"
var_0_1.COUNT_TAG = "Count"
var_0_1.CLICKED_TAG = "Clicked"
var_0_1.UNLOAD_CELL_TAG = "UnloadCell"
var_0_1.BG_ZORDER = -1
var_0_1.CONTENT_ZORDER = 10
var_0_1.ALIGNMENT_LEFT = 0
var_0_1.ALIGNMENT_RIGHT = 1
var_0_1.ALIGNMENT_VCENTER = 2
var_0_1.ALIGNMENT_TOP = 3
var_0_1.ALIGNMENT_BOTTOM = 4
var_0_1.ALIGNMENT_HCENTER = 5

function var_0_1.ctor(arg_1_0, arg_1_1)
	var_0_1.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.items_ = {}
	arg_1_0.direction = arg_1_1.direction or var_0_0.DIRECTION_VERTICAL
	arg_1_0.alignment = arg_1_1.alignment or var_0_1.ALIGNMENT_VCENTER
	arg_1_0.bAsyncLoad = arg_1_1.async or false
	arg_1_0.framing = arg_1_1.framing or false

	if arg_1_0.framing then
		arg_1_0.framingOriginDuration = (arg_1_1.framingDuration or 0.04) * 30
		arg_1_0.framingDuration = arg_1_0.framingOriginDuration
	end

	arg_1_0.framingCount = 0
	arg_1_0.bBounceCheckCount = 0
	arg_1_0.container = cc.Node:create()

	arg_1_0:setDirection(arg_1_1.direction)
	arg_1_0:setViewRect(arg_1_1.viewRect)
	arg_1_0:addScrollNode(arg_1_0.container)
	arg_1_0:onScroll(handler(arg_1_0, arg_1_0.scrollListener))

	arg_1_0.size = {}
	arg_1_0.itemsFree_ = {}
	arg_1_0.delegate_ = {}
	arg_1_0.redundancyViewVal = 0.001

	arg_1_0:setNodeEventEnabled(true)
end

function var_0_1.onCleanup(arg_2_0)
	arg_2_0:releaseAllFreeItems_()
end

function var_0_1.onTouch(arg_3_0, arg_3_1)
	arg_3_0.touchListener_ = arg_3_1

	return arg_3_0
end

function var_0_1.setAlignment(arg_4_0, arg_4_1)
	arg_4_0.alignment = arg_4_1
end

function var_0_1.newItem(arg_5_0, arg_5_1)
	arg_5_1 = var_0_2.new(arg_5_1)

	arg_5_1:setDirction(arg_5_0.direction)
	arg_5_1:onSizeChange(handler(arg_5_0, arg_5_0.itemSizeChangeListener))

	return arg_5_1
end

function var_0_1.setViewRect(arg_6_0, arg_6_1)
	if var_0_0.DIRECTION_VERTICAL == arg_6_0.direction then
		arg_6_0.redundancyViewVal = arg_6_1.height
	else
		arg_6_0.redundancyViewVal = arg_6_1.width
	end

	var_0_1.super.setViewRect(arg_6_0, arg_6_1)
end

function var_0_1.itemSizeChangeListener(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = arg_7_0:getItemPos(arg_7_1)

	if not var_7_0 then
		return
	end

	local var_7_1 = arg_7_2.width - arg_7_3.width
	local var_7_2 = arg_7_2.height - arg_7_3.height

	if var_0_0.DIRECTION_VERTICAL == arg_7_0.direction then
		var_7_1 = 0
	else
		var_7_2 = 0
	end

	local var_7_3 = arg_7_1:getContent()

	transition.moveBy(var_7_3, {
		time = 0.2,
		x = var_7_1 / 2,
		y = var_7_2 / 2
	})

	arg_7_0.size.width = arg_7_0.size.width + var_7_1
	arg_7_0.size.height = arg_7_0.size.height + var_7_2

	if var_0_0.DIRECTION_VERTICAL == arg_7_0.direction then
		transition.moveBy(arg_7_0.container, {
			time = 0.2,
			x = -var_7_1,
			y = -var_7_2
		})
		arg_7_0:moveItems(1, var_7_0 - 1, var_7_1, var_7_2, true)
	else
		arg_7_0:moveItems(var_7_0 + 1, table.nums(arg_7_0.items_), var_7_1, var_7_2, true)
	end
end

function var_0_1.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "clicked" then
		local var_8_0 = arg_8_0.container:convertToNodeSpace(cc.p(arg_8_1.x, arg_8_1.y))
		local var_8_1
		local var_8_2

		if arg_8_0.bAsyncLoad then
			local var_8_3

			for iter_8_0, iter_8_1 in ipairs(arg_8_0.items_) do
				local var_8_4, var_8_5 = iter_8_1:getPosition()
				local var_8_6, var_8_7 = iter_8_1:getItemSize()
				local var_8_8 = cc.rect(var_8_4, var_8_5, var_8_6, var_8_7)

				if cc.rectContainsPoint(var_8_8, var_8_0) then
					var_8_2 = iter_8_1.idx_
					var_8_1 = iter_8_0

					break
				end
			end
		else
			var_8_0.x = var_8_0.x - arg_8_0.viewRect_.x
			var_8_0.y = var_8_0.y - arg_8_0.viewRect_.y

			local var_8_9 = 0
			local var_8_10 = arg_8_0.size.height or 0
			local var_8_11 = 0
			local var_8_12 = 0

			if var_0_0.DIRECTION_VERTICAL == arg_8_0.direction then
				for iter_8_2, iter_8_3 in ipairs(arg_8_0.items_) do
					local var_8_13, var_8_14 = iter_8_3:getItemSize()

					if var_8_10 > var_8_0.y and var_8_0.y > var_8_10 - var_8_14 then
						var_8_1 = iter_8_2
						var_8_2 = var_8_1
						var_8_0.y = var_8_0.y - (var_8_10 - var_8_14)

						break
					end

					var_8_10 = var_8_10 - var_8_14
				end
			else
				for iter_8_4, iter_8_5 in ipairs(arg_8_0.items_) do
					local var_8_15, var_8_16 = iter_8_5:getItemSize()

					if var_8_9 < var_8_0.x and var_8_0.x < var_8_9 + var_8_15 then
						var_8_1 = iter_8_4
						var_8_2 = var_8_1

						break
					end

					var_8_9 = var_8_9 + var_8_15
				end
			end
		end

		arg_8_0:notifyListener_({
			name = "clicked",
			listView = arg_8_0,
			itemPos = var_8_2,
			item = arg_8_0.items_[var_8_1],
			point = var_8_0
		})
	else
		arg_8_1.scrollView = nil
		arg_8_1.listView = arg_8_0

		arg_8_0:notifyListener_(arg_8_1)
	end
end

function var_0_1.addItem(arg_9_0, arg_9_1, arg_9_2)
	arg_9_0:modifyItemSizeIf_(arg_9_1)

	if arg_9_2 then
		table.insert(arg_9_0.items_, arg_9_2, arg_9_1)
	else
		table.insert(arg_9_0.items_, arg_9_1)
	end

	arg_9_0.container:addChild(arg_9_1)

	return arg_9_0
end

function var_0_1.removeItem(arg_10_0, arg_10_1, arg_10_2)
	assert(not arg_10_0.bAsyncLoad, "UIListView:removeItem() - syncload not support remove")

	local var_10_0, var_10_1 = arg_10_1:getItemSize()

	arg_10_0.container:removeChild(arg_10_1)

	local var_10_2 = arg_10_0:getItemPos(arg_10_1)

	if var_10_2 then
		table.remove(arg_10_0.items_, var_10_2)
	end

	if var_0_0.DIRECTION_VERTICAL == arg_10_0.direction then
		var_10_0 = 0
	else
		var_10_1 = 0
	end

	arg_10_0.size.width = arg_10_0.size.width - var_10_0
	arg_10_0.size.height = arg_10_0.size.height - var_10_1

	if table.nums(arg_10_0.items_) == 0 then
		return
	end

	if var_0_0.DIRECTION_VERTICAL == arg_10_0.direction then
		arg_10_0:moveItems(1, var_10_2 - 1, -var_10_0, -var_10_1, arg_10_2)
	else
		arg_10_0:moveItems(var_10_2, table.nums(arg_10_0.items_), -var_10_0, -var_10_1, arg_10_2)
	end

	return arg_10_0
end

function var_0_1.removeAllItems(arg_11_0)
	arg_11_0.container:removeAllChildren()

	arg_11_0.items_ = {}

	return arg_11_0
end

function var_0_1.getItemPos(arg_12_0, arg_12_1)
	for iter_12_0, iter_12_1 in ipairs(arg_12_0.items_) do
		if iter_12_1 == arg_12_1 then
			return iter_12_0
		end
	end
end

function var_0_1.isItemInViewRect(arg_13_0, arg_13_1)
	local var_13_0

	if type(arg_13_1) == "number" then
		var_13_0 = arg_13_0.items_[arg_13_1]
	elseif type(arg_13_1) == "userdata" then
		var_13_0 = arg_13_1
	end

	if not var_13_0 then
		return
	end

	local var_13_1 = var_13_0:getBoundingBox()
	local var_13_2 = arg_13_0.container:convertToWorldSpace(cc.p(var_13_1.x, var_13_1.y))

	var_13_1.x = var_13_2.x
	var_13_1.y = var_13_2.y

	return cc.rectIntersectsRect(arg_13_0.viewRect_, var_13_1)
end

function var_0_1.reload(arg_14_0, arg_14_1)
	if arg_14_0.framing then
		arg_14_0:framingLoad_(arg_14_1)
	elseif arg_14_0.bAsyncLoad then
		arg_14_0:asyncLoad_(arg_14_1)
	else
		arg_14_0:layout_()
	end

	return arg_14_0
end

function var_0_1.dequeueItem(arg_15_0)
	if #arg_15_0.itemsFree_ < 1 then
		return
	end

	local var_15_0
	local var_15_1 = table.remove(arg_15_0.itemsFree_, 1)

	var_15_1.bFromFreeQueue_ = true

	return var_15_1
end

function var_0_1.layout_(arg_16_0)
	local var_16_0 = 0
	local var_16_1 = 0
	local var_16_2 = 0
	local var_16_3 = 0
	local var_16_4

	if var_0_0.DIRECTION_VERTICAL == arg_16_0.direction then
		var_16_0 = arg_16_0.viewRect_.width

		for iter_16_0, iter_16_1 in ipairs(arg_16_0.items_) do
			local var_16_5, var_16_6 = iter_16_1:getItemSize()
			local var_16_7 = var_16_6

			if not var_16_5 then
				local var_16_8 = 0
			end

			var_16_7 = var_16_7 or 0
			var_16_1 = var_16_1 + var_16_7
		end
	else
		var_16_1 = arg_16_0.viewRect_.height

		for iter_16_2, iter_16_3 in ipairs(arg_16_0.items_) do
			local var_16_9, var_16_10 = iter_16_3:getItemSize()
			local var_16_11 = var_16_10
			local var_16_12 = var_16_9 or 0
			local var_16_13

			var_16_13 = var_16_11 or 0
			var_16_0 = var_16_0 + var_16_12
		end
	end

	arg_16_0:setActualRect({
		x = arg_16_0.viewRect_.x,
		y = arg_16_0.viewRect_.y,
		width = var_16_0,
		height = var_16_1
	})

	arg_16_0.size.width = var_16_0
	arg_16_0.size.height = var_16_1

	local var_16_14 = var_16_0
	local var_16_15 = var_16_1

	if var_0_0.DIRECTION_VERTICAL == arg_16_0.direction then
		local var_16_16 = 0, 0
		local var_16_17

		for iter_16_4, iter_16_5 in ipairs(arg_16_0.items_) do
			local var_16_18, var_16_19 = iter_16_5:getItemSize()
			local var_16_20 = var_16_19
			local var_16_21 = var_16_18 or 0

			var_16_20 = var_16_20 or 0
			var_16_15 = var_16_15 - var_16_20

			local var_16_22 = iter_16_5:getContent()

			var_16_22:setAnchorPoint(0.5, 0.5)
			arg_16_0:setPositionByAlignment_(var_16_22, var_16_21, var_16_20, iter_16_5:getMargin())
			iter_16_5:setPosition(arg_16_0.viewRect_.x, arg_16_0.viewRect_.y + var_16_15)
		end
	else
		local var_16_23 = 0, 0
		local var_16_24 = 0

		for iter_16_6, iter_16_7 in ipairs(arg_16_0.items_) do
			local var_16_25, var_16_26 = iter_16_7:getItemSize()
			local var_16_27 = var_16_26
			local var_16_28 = var_16_25 or 0

			var_16_27 = var_16_27 or 0
			content = iter_16_7:getContent()

			content:setAnchorPoint(0.5, 0.5)
			arg_16_0:setPositionByAlignment_(content, var_16_28, var_16_27, iter_16_7:getMargin())
			iter_16_7:setPosition(arg_16_0.viewRect_.x + var_16_24, arg_16_0.viewRect_.y)

			var_16_24 = var_16_24 + var_16_28
		end
	end

	arg_16_0.container:setPosition(0, arg_16_0.viewRect_.height - arg_16_0.size.height)
end

function var_0_1.notifyItem(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_0.delegate_[var_0_1.DELEGATE](arg_17_0, var_0_1.COUNT_TAG)
	local var_17_1 = arg_17_0.direction == var_0_1.DIRECTION_VERTICAL and arg_17_0.container:getContentSize().height or 0
	local var_17_2 = 0
	local var_17_3 = 0
	local var_17_4 = 0

	for iter_17_0 = 1, var_17_0 do
		local var_17_5, var_17_6 = arg_17_0.delegate_[var_0_1.DELEGATE](arg_17_0, var_0_1.CELL_SIZE_TAG, iter_17_0)

		if arg_17_0.direction == var_0_1.DIRECTION_VERTICAL then
			var_17_1 = var_17_1 - var_17_6

			if var_17_1 < arg_17_1.y then
				arg_17_1.y = arg_17_1.y - var_17_1
				var_17_4 = iter_17_0

				break
			end
		else
			var_17_1 = var_17_1 + var_17_5

			if var_17_1 > arg_17_1.x then
				arg_17_1.x = arg_17_1.x + var_17_5 - var_17_1
				var_17_4 = iter_17_0

				break
			end
		end
	end

	if var_17_4 == 0 then
		printInfo("UIListView - didn't found item")

		return
	end

	arg_17_0.delegate_[var_0_1.DELEGATE](arg_17_0, var_0_1.CLICKED_TAG, var_17_4, arg_17_1)
end

function var_0_1.moveItems(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4, arg_18_5)
	if arg_18_2 == 0 then
		arg_18_0:elasticScroll()
	end

	local var_18_0 = 0
	local var_18_1 = 0
	local var_18_2 = {
		time = 0.2,
		x = arg_18_3,
		y = arg_18_4
	}

	for iter_18_0 = arg_18_1, arg_18_2 do
		if arg_18_5 then
			if iter_18_0 == arg_18_1 then
				function var_18_2.onComplete()
					arg_18_0:elasticScroll()
				end
			else
				var_18_2.onComplete = nil
			end

			transition.moveBy(arg_18_0.items_[iter_18_0], var_18_2)
		else
			local var_18_3, var_18_4 = arg_18_0.items_[iter_18_0]:getPosition()

			arg_18_0.items_[iter_18_0]:setPosition(var_18_3 + arg_18_3, var_18_4 + arg_18_4)

			if iter_18_0 == arg_18_1 then
				arg_18_0:elasticScroll()
			end
		end
	end
end

function var_0_1.notifyListener_(arg_20_0, arg_20_1)
	if not arg_20_0.touchListener_ then
		return
	end

	arg_20_0.touchListener_(arg_20_1)
end

function var_0_1.modifyItemSizeIf_(arg_21_0, arg_21_1)
	local var_21_0, var_21_1 = arg_21_1:getItemSize()

	if var_0_0.DIRECTION_VERTICAL == arg_21_0.direction then
		if var_21_0 ~= arg_21_0.viewRect_.width then
			arg_21_1:setItemSize(arg_21_0.viewRect_.width, var_21_1, true)
		end
	elseif var_21_1 ~= arg_21_0.viewRect_.height then
		arg_21_1:setItemSize(var_21_0, arg_21_0.viewRect_.height, true)
	end
end

function var_0_1.update_(arg_22_0, arg_22_1)
	var_0_1.super.update_(arg_22_0, arg_22_1)
	arg_22_0:checkItemsInStatus_()
	arg_22_0:updateFramingDuration()

	if arg_22_0.framing then
		if #arg_22_0.items_ > 0 then
			arg_22_0.framingCount = arg_22_0.framingCount + 1

			if arg_22_0.framingCount > arg_22_0.framingDuration then
				arg_22_0.framingCount = 0

				arg_22_0:increaseOrReduceItem_()
			end
		end
	elseif arg_22_0.bAsyncLoad then
		arg_22_0:increaseOrReduceItem_()
	end
end

function var_0_1.updateFramingDuration(arg_23_0)
	if not arg_23_0.framing or #arg_23_0.items_ == 0 then
		return
	end

	local var_23_0, var_23_1 = arg_23_0.items_[1]:getItemSize()

	if var_0_0.DIRECTION_VERTICAL == arg_23_0.direction then
		local var_23_2 = arg_23_0.speed.y / var_23_1

		if var_23_2 ~= 0 then
			local var_23_3 = math.abs(1 / var_23_2)
			local var_23_4 = math.min(var_23_3, arg_23_0.framingOriginDuration)

			arg_23_0.framingDuration = math.max(var_23_4, 0)
		end
	else
		local var_23_5 = arg_23_0.speed.x / var_23_0

		if var_23_5 ~= 0 then
			local var_23_6 = math.abs(1 / var_23_5)
			local var_23_7 = math.min(var_23_6, arg_23_0.framingOriginDuration)

			arg_23_0.framingDuration = math.max(var_23_7, 0)
		end
	end
end

function var_0_1.checkItemsInStatus_(arg_24_0)
	if not arg_24_0.itemInStatus_ then
		arg_24_0.itemInStatus_ = {}
	end

	local function var_24_0(arg_25_0, arg_25_1)
		local var_25_0

		return arg_25_0.x <= arg_25_1.x and arg_25_0.x + arg_25_0.width >= arg_25_1.x + arg_25_1.width and arg_25_0.y <= arg_25_1.y and arg_25_0.y + arg_25_0.height >= arg_25_1.y + arg_25_1.height and 2 or (arg_25_0.x > arg_25_1.x + arg_25_1.width or arg_25_0.x + arg_25_0.width < arg_25_1.x or arg_25_0.y > arg_25_1.y + arg_25_1.height or arg_25_0.y + arg_25_0.height < arg_25_1.y) and 0 or 1
	end

	local var_24_1 = {}
	local var_24_2
	local var_24_3

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.items_) do
		local var_24_4 = iter_24_1:getBoundingBox()
		local var_24_5 = arg_24_0.container:convertToWorldSpace(cc.p(var_24_4.x, var_24_4.y))

		var_24_4.x = var_24_5.x
		var_24_4.y = var_24_5.y
		var_24_1[iter_24_0] = var_24_0(arg_24_0.viewRect_, var_24_4)
	end

	for iter_24_2, iter_24_3 in ipairs(var_24_1) do
		if arg_24_0.itemInStatus_[iter_24_2] and arg_24_0.itemInStatus_[iter_24_2] ~= iter_24_3 then
			local var_24_6 = {
				listView = arg_24_0,
				itemPos = iter_24_2,
				item = arg_24_0.items_[iter_24_2]
			}

			if iter_24_3 == 0 then
				var_24_6.name = "itemDisappear"
			elseif iter_24_3 == 1 then
				var_24_6.name = "itemAppearChange"
			elseif iter_24_3 == 2 then
				var_24_6.name = "itemAppear"
			end

			arg_24_0:notifyListener_(var_24_6)
		end
	end

	arg_24_0.itemInStatus_ = var_24_1
end

function var_0_1.increaseOrReduceItem_(arg_26_0)
	if #arg_26_0.items_ == 0 then
		return
	end

	local function var_26_0()
		local var_27_0

		for iter_27_0, iter_27_1 in ipairs(arg_26_0.items_) do
			local var_27_1, var_27_2 = iter_27_1:getItemSize()
			local var_27_3, var_27_4 = iter_27_1:getPosition()
			local var_27_5 = iter_27_1:getAnchorPoint()
			local var_27_6 = var_27_3 - var_27_5.x * var_27_1
			local var_27_7 = var_27_4 - var_27_5.y * var_27_2

			if var_27_0 then
				var_27_0 = cc.rectUnion(var_27_0, cc.rect(var_27_6, var_27_7, var_27_1, var_27_2))
			else
				var_27_0 = cc.rect(var_27_6, var_27_7, var_27_1, var_27_2)
			end
		end

		local var_27_8 = arg_26_0.container:convertToWorldSpace(cc.p(var_27_0.x, var_27_0.y))

		var_27_0.x = var_27_8.x
		var_27_0.y = var_27_8.y

		return var_27_0
	end

	local var_26_1 = arg_26_0.delegate_[var_0_1.DELEGATE](arg_26_0, var_0_1.COUNT_TAG)
	local var_26_2 = 2
	local var_26_3 = var_26_0()
	local var_26_4 = arg_26_0:convertToNodeSpace(cc.p(var_26_3.x, var_26_3.y))
	local var_26_5
	local var_26_6
	local var_26_7

	if var_0_0.DIRECTION_VERTICAL == arg_26_0.direction then
		local var_26_8 = var_26_4.y + var_26_3.height - arg_26_0.viewRect_.y - arg_26_0.viewRect_.height
		local var_26_9
		local var_26_10 = arg_26_0.items_[1]

		if not var_26_10 then
			print("increaseOrReduceItem_ item is nil, all item count:" .. #arg_26_0.items_)

			return
		end

		local var_26_11 = var_26_10.idx_

		if var_26_8 > arg_26_0.redundancyViewVal then
			local var_26_12, var_26_13 = var_26_10:getItemSize()

			if var_26_3.height - var_26_13 > arg_26_0.viewRect_.height and var_26_8 - var_26_13 > arg_26_0.redundancyViewVal then
				arg_26_0:unloadOneItem_(var_26_11)
			else
				var_26_2 = var_26_2 - 1
			end
		else
			local var_26_14
			local var_26_15 = var_26_11 - 1

			if var_26_15 > 0 then
				local var_26_16 = arg_26_0.container:convertToNodeSpace(cc.p(var_26_3.x, var_26_3.y + var_26_3.height))

				var_26_14 = arg_26_0:loadOneItem_(var_26_16, var_26_15, true)
			end

			if var_26_14 == nil then
				var_26_2 = var_26_2 - 1
			end
		end

		local var_26_17 = arg_26_0.viewRect_.y - var_26_4.y
		local var_26_18 = arg_26_0.items_[#arg_26_0.items_]

		if not var_26_18 then
			return
		end

		local var_26_19 = var_26_18.idx_

		if var_26_17 > arg_26_0.redundancyViewVal then
			local var_26_20, var_26_21 = var_26_18:getItemSize()

			if var_26_3.height - var_26_21 > arg_26_0.viewRect_.height and var_26_17 - var_26_21 > arg_26_0.redundancyViewVal then
				arg_26_0:unloadOneItem_(var_26_19)
			else
				var_26_2 = var_26_2 - 1
			end
		else
			local var_26_22
			local var_26_23 = var_26_19 + 1

			if var_26_23 <= var_26_1 then
				local var_26_24 = arg_26_0.container:convertToNodeSpace(cc.p(var_26_3.x, var_26_3.y))

				var_26_22 = arg_26_0:loadOneItem_(var_26_24, var_26_23)
			end

			if var_26_22 == nil then
				var_26_2 = var_26_2 - 1
			end
		end
	else
		local var_26_25 = arg_26_0.viewRect_.x - var_26_4.x
		local var_26_26 = arg_26_0.items_[1]
		local var_26_27 = var_26_26.idx_

		if var_26_25 > arg_26_0.redundancyViewVal then
			local var_26_28, var_26_29 = var_26_26:getItemSize()

			if var_26_3.width - var_26_28 > arg_26_0.viewRect_.width and var_26_25 - var_26_28 > arg_26_0.redundancyViewVal then
				arg_26_0:unloadOneItem_(var_26_27)
			else
				var_26_2 = var_26_2 - 1
			end
		else
			local var_26_30
			local var_26_31 = var_26_27 - 1

			if var_26_31 > 0 then
				local var_26_32 = arg_26_0.container:convertToNodeSpace(cc.p(var_26_3.x, var_26_3.y))

				var_26_30 = arg_26_0:loadOneItem_(var_26_32, var_26_31, true)
			end

			if var_26_30 == nil then
				var_26_2 = var_26_2 - 1
			end
		end

		local var_26_33 = var_26_4.x + var_26_3.width - arg_26_0.viewRect_.x - arg_26_0.viewRect_.width
		local var_26_34 = arg_26_0.items_[#arg_26_0.items_]
		local var_26_35 = var_26_34.idx_

		if var_26_33 > arg_26_0.redundancyViewVal then
			local var_26_36, var_26_37 = var_26_34:getItemSize()

			if var_26_3.width - var_26_36 > arg_26_0.viewRect_.width and var_26_33 - var_26_36 > arg_26_0.redundancyViewVal then
				arg_26_0:unloadOneItem_(var_26_35)
			else
				var_26_2 = var_26_2 - 1
			end
		else
			local var_26_38
			local var_26_39 = var_26_35 + 1

			if var_26_39 <= var_26_1 then
				local var_26_40 = arg_26_0.container:convertToNodeSpace(cc.p(var_26_3.x + var_26_3.width, var_26_3.y))

				var_26_38 = arg_26_0:loadOneItem_(var_26_40, var_26_39)
			end

			if var_26_38 == nil then
				var_26_2 = var_26_2 - 1
			end
		end
	end

	if not arg_26_0.framing and var_26_2 > 0 then
		return arg_26_0:increaseOrReduceItem_()
	end
end

function var_0_1.asyncLoad_(arg_28_0, arg_28_1)
	arg_28_0:removeAllItems()
	arg_28_0.container:setPosition(0, 0)
	arg_28_0.container:setContentSize(cc.size(0, 0))

	local var_28_0 = arg_28_0.delegate_[var_0_1.DELEGATE](arg_28_0, var_0_1.COUNT_TAG)

	arg_28_0.items_ = {}

	local var_28_1 = 0
	local var_28_2 = 0
	local var_28_3
	local var_28_4 = 0
	local var_28_5 = 0
	local var_28_6 = 0
	local var_28_7 = 0
	local var_28_8 = arg_28_1

	if not var_28_8 or var_28_0 < var_28_8 then
		var_28_8 = 1
	end

	for iter_28_0 = var_28_8, var_28_0 do
		local var_28_9, var_28_10, var_28_11 = arg_28_0:loadOneItem_(cc.p(var_28_6, var_28_7), iter_28_0)

		if var_0_0.DIRECTION_VERTICAL == arg_28_0.direction then
			var_28_7 = var_28_7 - var_28_11
			var_28_5 = var_28_5 + var_28_11
		else
			var_28_6 = var_28_6 + var_28_10
			var_28_4 = var_28_4 + var_28_10
		end

		if var_28_4 > arg_28_0.viewRect_.width + arg_28_0.redundancyViewVal or var_28_5 > arg_28_0.viewRect_.height + arg_28_0.redundancyViewVal then
			break
		end
	end

	if var_0_0.DIRECTION_VERTICAL == arg_28_0.direction then
		arg_28_0.container:setPosition(arg_28_0.viewRect_.x, arg_28_0.viewRect_.y + arg_28_0.viewRect_.height)
	else
		arg_28_0.container:setPosition(arg_28_0.viewRect_.x, arg_28_0.viewRect_.y)
	end

	return arg_28_0
end

function var_0_1.framingLoad_(arg_29_0, arg_29_1)
	arg_29_0:removeAllItems()
	arg_29_0.container:setPosition(0, 0)
	arg_29_0.container:setContentSize(cc.size(0, 0))

	local var_29_0 = arg_29_0.delegate_[var_0_1.DELEGATE](arg_29_0, var_0_1.COUNT_TAG)

	arg_29_0.items_ = {}

	local var_29_1 = 0
	local var_29_2 = 0
	local var_29_3
	local var_29_4 = 0
	local var_29_5 = 0
	local var_29_6 = 0
	local var_29_7 = 0
	local var_29_8 = arg_29_1

	if not var_29_8 or var_29_0 < var_29_8 then
		var_29_8 = 1
	end

	local var_29_9, var_29_10, var_29_11 = arg_29_0:loadOneItem_(cc.p(var_29_6, var_29_7), var_29_8)

	if var_0_0.DIRECTION_VERTICAL == arg_29_0.direction then
		arg_29_0.container:setPosition(arg_29_0.viewRect_.x, arg_29_0.viewRect_.y + arg_29_0.viewRect_.height)
	else
		arg_29_0.container:setPosition(arg_29_0.viewRect_.x, arg_29_0.viewRect_.y)
	end

	return arg_29_0
end

function var_0_1.getListEndPosAndHeight(arg_30_0)
	local var_30_0 = {}
	local var_30_1 = arg_30_0.delegate_[var_0_1.DELEGATE](arg_30_0, var_0_1.COUNT_TAG)
	local var_30_2 = 0
	local var_30_3 = 0
	local var_30_4
	local var_30_5 = 0
	local var_30_6 = 0
	local var_30_7 = 0
	local var_30_8 = 0

	for iter_30_0 = 1, var_30_1 do
		local var_30_9, var_30_10, var_30_11 = arg_30_0:loadOneItem_(cc.p(var_30_7, var_30_8), iter_30_0)

		if var_0_0.DIRECTION_VERTICAL == arg_30_0.direction then
			var_30_8 = var_30_8 - var_30_11
			var_30_6 = var_30_6 + var_30_11
		else
			var_30_7 = var_30_7 + var_30_10
			var_30_5 = var_30_5 + var_30_10
		end
	end

	var_30_0.x = var_30_7
	var_30_0.y = var_30_8

	local var_30_12 = 0

	if var_0_0.DIRECTION_VERTICAL == arg_30_0.direction then
		var_30_12 = var_30_6
	else
		var_30_12 = var_30_5
	end

	return var_30_12
end

function var_0_1.setDelegate(arg_31_0, arg_31_1)
	arg_31_0.delegate_[var_0_1.DELEGATE] = arg_31_1
end

function var_0_1.setPositionByAlignment_(arg_32_0, arg_32_1, arg_32_2, arg_32_3, arg_32_4)
	local var_32_0 = arg_32_1:getContentSize()

	if arg_32_4.left == 0 and arg_32_4.right == 0 and arg_32_4.top == 0 and arg_32_4.bottom == 0 then
		if var_0_0.DIRECTION_VERTICAL == arg_32_0.direction then
			if var_0_1.ALIGNMENT_LEFT == arg_32_0.alignment then
				arg_32_1:setPosition(var_32_0.width / 2, arg_32_3 / 2)
			elseif var_0_1.ALIGNMENT_RIGHT == arg_32_0.alignment then
				arg_32_1:setPosition(arg_32_2 - var_32_0.width / 2, arg_32_3 / 2)
			else
				arg_32_1:setPosition(arg_32_2 / 2, arg_32_3 / 2)
			end
		elseif var_0_1.ALIGNMENT_TOP == arg_32_0.alignment then
			arg_32_1:setPosition(arg_32_2 / 2, arg_32_3 - var_32_0.height / 2)
		elseif var_0_1.ALIGNMENT_RIGHT == arg_32_0.alignment then
			arg_32_1:setPosition(arg_32_2 / 2, var_32_0.height / 2)
		else
			arg_32_1:setPosition(arg_32_2 / 2, arg_32_3 / 2)
		end
	else
		local var_32_1
		local var_32_2

		if arg_32_4.right ~= 0 then
			var_32_1 = arg_32_2 - arg_32_4.right - var_32_0.width / 2
		else
			var_32_1 = var_32_0.width / 2 + arg_32_4.left
		end

		if arg_32_4.top ~= 0 then
			var_32_2 = arg_32_3 - arg_32_4.top - var_32_0.height / 2
		else
			var_32_2 = var_32_0.height / 2 + arg_32_4.bottom
		end

		arg_32_1:setPosition(var_32_1, var_32_2)
	end
end

function var_0_1.loadOneItem_(arg_33_0, arg_33_1, arg_33_2, arg_33_3)
	local var_33_0
	local var_33_1
	local var_33_2
	local var_33_3 = 0
	local var_33_4 = 0
	local var_33_5 = arg_33_1.x
	local var_33_6 = arg_33_1.y
	local var_33_7
	local var_33_8 = arg_33_0.delegate_[var_0_1.DELEGATE](arg_33_0, var_0_1.CELL_TAG, arg_33_2)

	if var_33_8 == nil then
		print("ERROR! UIListView load nil item")

		return
	end

	var_33_8.idx_ = arg_33_2

	local var_33_9, var_33_10 = var_33_8:getItemSize()

	if var_0_0.DIRECTION_VERTICAL == arg_33_0.direction then
		var_33_9 = var_33_9 or 0
		var_33_10 = var_33_10 or 0

		if arg_33_3 then
			-- block empty
		else
			var_33_6 = var_33_6 - var_33_10
		end

		local var_33_11 = var_33_8:getContent()

		var_33_11:setAnchorPoint(0.5, 0.5)
		arg_33_0:setPositionByAlignment_(var_33_11, var_33_9, var_33_10, var_33_8:getMargin())
		var_33_8:setPosition(0, var_33_6)

		local var_33_12 = var_33_4 + var_33_10
	else
		var_33_9 = var_33_9 or 0
		var_33_10 = var_33_10 or 0

		if arg_33_3 then
			var_33_5 = var_33_5 - var_33_9
		end

		local var_33_13 = var_33_8:getContent()

		var_33_13:setAnchorPoint(0.5, 0.5)
		arg_33_0:setPositionByAlignment_(var_33_13, var_33_9, var_33_10, var_33_8:getMargin())
		var_33_8:setPosition(var_33_5, 0)

		local var_33_14 = var_33_3 + var_33_9
	end

	if arg_33_3 then
		table.insert(arg_33_0.items_, 1, var_33_8)
	else
		table.insert(arg_33_0.items_, var_33_8)
	end

	arg_33_0.container:addChild(var_33_8)

	if var_33_8.bFromFreeQueue_ then
		var_33_8.bFromFreeQueue_ = nil

		var_33_8:release()
	end

	return var_33_8, var_33_9, var_33_10
end

function var_0_1.unloadOneItem_(arg_34_0, arg_34_1)
	local var_34_0 = arg_34_0.items_[1]

	if var_34_0 == nil then
		return
	end

	if arg_34_1 < var_34_0.idx_ then
		return
	end

	local var_34_1 = arg_34_1 - var_34_0.idx_ + 1
	local var_34_2 = arg_34_0.items_[var_34_1]

	if var_34_2 == nil then
		return
	end

	table.remove(arg_34_0.items_, var_34_1)
	arg_34_0:addFreeItem_(var_34_2)
	arg_34_0.container:removeChild(var_34_2, false)
	arg_34_0.delegate_[var_0_1.DELEGATE](arg_34_0, var_0_1.UNLOAD_CELL_TAG, arg_34_1)
end

function var_0_1.addFreeItem_(arg_35_0, arg_35_1)
	arg_35_1:retain()
	table.insert(arg_35_0.itemsFree_, arg_35_1)
end

function var_0_1.releaseAllFreeItems_(arg_36_0)
	for iter_36_0, iter_36_1 in ipairs(arg_36_0.itemsFree_) do
		iter_36_1:removeAllChildren(true)
		iter_36_1:release()
	end

	arg_36_0.itemsFree_ = {}
end

function var_0_1.refreshList(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = clone(arg_37_0.items_)
	local var_37_1 = #var_37_0
	local var_37_2

	if arg_37_1 then
		var_37_2 = arg_37_1
	else
		var_37_2 = 2
	end

	for iter_37_0 = 1, var_37_1 do
		local var_37_3 = var_37_0[iter_37_0]
		local var_37_4, var_37_5 = var_37_3:getItemSize()

		arg_37_0:unloadOneItem_(var_37_3.idx_)

		local var_37_6 = cc.p(var_37_3:getPositionX() + var_37_4, var_37_3:getPositionY() + var_37_5)

		if arg_37_0.direction == var_0_0.DIRECTION_HORIZONTAL then
			var_37_6 = cc.p(var_37_3:getPositionX(), var_37_3:getPositionY() + var_37_5)
		end

		arg_37_0:loadOneItem_(var_37_6, var_37_3.idx_, false)
	end

	if not arg_37_0.items_ or not next(arg_37_0.items_) or var_37_2 >= #arg_37_0.items_ then
		arg_37_0:asyncLoad_()

		local var_37_7 = arg_37_0:getListEndPosAndHeight()
		local var_37_8
		local var_37_9 = arg_37_0:getViewRect()

		if arg_37_0.direction == var_0_0.DIRECTION_VERTICAL then
			var_37_8 = var_37_9.height
		else
			var_37_8 = var_37_9.width
		end

		if not arg_37_2 and var_37_8 < var_37_7 then
			arg_37_0:scrollTo(0, var_37_7)
		end
	end

	arg_37_0:onCleanup()
end

function var_0_1.isSideShow(arg_38_0)
	if #arg_38_0.items_ == 0 or not arg_38_0.bAsyncLoad and not arg_38_0.framing then
		return var_0_1.super.isSideShow(arg_38_0)
	end

	local function var_38_0()
		local var_39_0

		for iter_39_0, iter_39_1 in ipairs(arg_38_0.items_) do
			local var_39_1, var_39_2 = iter_39_1:getItemSize()
			local var_39_3, var_39_4 = iter_39_1:getPosition()
			local var_39_5 = iter_39_1:getAnchorPoint()
			local var_39_6 = var_39_3 - var_39_5.x * var_39_1
			local var_39_7 = var_39_4 - var_39_5.y * var_39_2

			if var_39_0 then
				var_39_0 = cc.rectUnion(var_39_0, cc.rect(var_39_6, var_39_7, var_39_1, var_39_2))
			else
				var_39_0 = cc.rect(var_39_6, var_39_7, var_39_1, var_39_2)
			end
		end

		local var_39_8 = arg_38_0.container:convertToWorldSpace(cc.p(var_39_0.x, var_39_0.y))

		var_39_0.x = var_39_8.x
		var_39_0.y = var_39_8.y

		return var_39_0
	end

	if not arg_38_0.delegate_[var_0_1.DELEGATE] then
		return false
	end

	local var_38_1 = arg_38_0.delegate_[var_0_1.DELEGATE](arg_38_0, var_0_1.COUNT_TAG)
	local var_38_2 = 2
	local var_38_3 = var_38_0()
	local var_38_4 = arg_38_0:convertToNodeSpace(cc.p(var_38_3.x, var_38_3.y))
	local var_38_5
	local var_38_6
	local var_38_7

	if var_0_0.DIRECTION_VERTICAL == arg_38_0.direction then
		local var_38_8 = var_38_4.y + var_38_3.height - arg_38_0.viewRect_.y - arg_38_0.viewRect_.height
		local var_38_9
		local var_38_10 = arg_38_0.items_[1]

		if not var_38_10 then
			print("increaseOrReduceItem_ item is nil, all item count:" .. #arg_38_0.items_)

			return
		end

		local var_38_11 = var_38_10.idx_

		if var_38_8 > arg_38_0.redundancyViewVal then
			local var_38_12, var_38_13 = var_38_10:getItemSize()

			if var_38_3.height - var_38_13 > arg_38_0.viewRect_.height and var_38_8 - var_38_13 > arg_38_0.redundancyViewVal then
				arg_38_0:unloadOneItem_(var_38_11)
			else
				var_38_2 = var_38_2 - 1
			end
		else
			local var_38_14
			local var_38_15 = var_38_11 - 1

			if var_38_15 > 0 then
				local var_38_16 = arg_38_0.container:convertToNodeSpace(cc.p(var_38_3.x, var_38_3.y + var_38_3.height))

				var_38_14 = arg_38_0:loadOneItem_(var_38_16, var_38_15, true)
			end

			if var_38_14 == nil then
				var_38_2 = var_38_2 - 1
			end
		end

		local var_38_17 = arg_38_0.viewRect_.y - var_38_4.y
		local var_38_18 = arg_38_0.items_[#arg_38_0.items_]

		if not var_38_18 then
			return
		end

		local var_38_19 = var_38_18.idx_

		if var_38_17 > arg_38_0.redundancyViewVal then
			local var_38_20, var_38_21 = var_38_18:getItemSize()

			if var_38_3.height - var_38_21 > arg_38_0.viewRect_.height and var_38_17 - var_38_21 > arg_38_0.redundancyViewVal then
				arg_38_0:unloadOneItem_(var_38_19)
			else
				var_38_2 = var_38_2 - 1
			end
		else
			local var_38_22
			local var_38_23 = var_38_19 + 1

			if var_38_23 <= var_38_1 then
				local var_38_24 = arg_38_0.container:convertToNodeSpace(cc.p(var_38_3.x, var_38_3.y))

				var_38_22 = arg_38_0:loadOneItem_(var_38_24, var_38_23)
			end

			if var_38_22 == nil then
				var_38_2 = var_38_2 - 1
			end
		end
	else
		local var_38_25 = arg_38_0.viewRect_.x - var_38_4.x
		local var_38_26 = arg_38_0.items_[1]
		local var_38_27 = var_38_26.idx_

		if var_38_25 > arg_38_0.redundancyViewVal then
			local var_38_28, var_38_29 = var_38_26:getItemSize()

			if var_38_3.width - var_38_28 > arg_38_0.viewRect_.width and var_38_25 - var_38_28 > arg_38_0.redundancyViewVal then
				arg_38_0:unloadOneItem_(var_38_27)
			else
				var_38_2 = var_38_2 - 1
			end
		else
			local var_38_30
			local var_38_31 = var_38_27 - 1

			if var_38_31 > 0 then
				local var_38_32 = arg_38_0.container:convertToNodeSpace(cc.p(var_38_3.x, var_38_3.y))

				var_38_30 = arg_38_0:loadOneItem_(var_38_32, var_38_31, true)
			end

			if var_38_30 == nil then
				var_38_2 = var_38_2 - 1
			end
		end

		local var_38_33 = var_38_4.x + var_38_3.width - arg_38_0.viewRect_.x - arg_38_0.viewRect_.width
		local var_38_34 = arg_38_0.items_[#arg_38_0.items_]
		local var_38_35 = var_38_34.idx_

		if var_38_33 > arg_38_0.redundancyViewVal then
			local var_38_36, var_38_37 = var_38_34:getItemSize()

			if var_38_3.width - var_38_36 > arg_38_0.viewRect_.width and var_38_33 - var_38_36 > arg_38_0.redundancyViewVal then
				arg_38_0:unloadOneItem_(var_38_35)
			else
				var_38_2 = var_38_2 - 1
			end
		else
			local var_38_38
			local var_38_39 = var_38_35 + 1

			if var_38_39 <= var_38_1 then
				local var_38_40 = arg_38_0.container:convertToNodeSpace(cc.p(var_38_3.x + var_38_3.width, var_38_3.y))

				var_38_38 = arg_38_0:loadOneItem_(var_38_40, var_38_39)
			end

			if var_38_38 == nil then
				var_38_2 = var_38_2 - 1
			end
		end
	end

	if var_38_2 > 0 then
		return false
	else
		local var_38_41 = 20
		local var_38_42 = arg_38_0.scrollNode:getCascadeBoundingBox()
		local var_38_43 = arg_38_0:convertToNodeSpace(cc.p(var_38_42.x, var_38_42.y))
		local var_38_44 = var_38_43.y > arg_38_0.viewRect_.y + var_38_41 or var_38_43.y + var_38_42.height + var_38_41 < arg_38_0.viewRect_.y + arg_38_0.viewRect_.height
		local var_38_45 = var_38_43.x > arg_38_0.viewRect_.x + var_38_41 or var_38_43.x + var_38_42.width + var_38_41 < arg_38_0.viewRect_.x + arg_38_0.viewRect_.width

		if var_0_0.DIRECTION_VERTICAL == arg_38_0.direction then
			return var_38_44
		elseif var_0_0.DIRECTION_HORIZONTAL == arg_38_0.direction then
			return var_38_45
		else
			return var_38_44 or var_38_45
		end
	end
end

function var_0_1.checkBounce_(arg_40_0)
	if arg_40_0.bBounceCheckCount > 15 then
		arg_40_0.bBounceCheckCount = 0

		if arg_40_0:isSideShow() then
			transition.stopTarget(arg_40_0.scrollNode)
			arg_40_0:elasticScroll()
		end
	else
		arg_40_0.bBounceCheckCount = arg_40_0.bBounceCheckCount + 1
	end
end

return var_0_1
