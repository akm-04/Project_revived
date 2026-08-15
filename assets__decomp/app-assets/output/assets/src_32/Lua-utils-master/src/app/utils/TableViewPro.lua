local var_0_0 = class("TableViewCell", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0.index = 0
end

function var_0_0.setIndex(arg_3_0, arg_3_1)
	arg_3_0.index = arg_3_1
end

function var_0_0.getIndex(arg_4_0, arg_4_1)
	return arg_4_0.index
end

function var_0_0.reset(arg_5_0)
	arg_5_0.index = 0
end

local var_0_1 = class("TableView", function()
	return ccui.ScrollView:create()
end)
local var_0_2 = {
	vertical = 1,
	horizontal = 2,
	none = 0
}
local var_0_3 = {
	cellLoad = "_loadCellAtIndex",
	cellUnload = "_unloadCellAtIndex",
	cellNum = "_numberOfCells",
	cellSize = "_cellSizeAtIndex"
}
local var_0_4 = {
	leftToRight = 3,
	bottomToTop = 2,
	rightToLeft = 4,
	topToBottom = 1
}

function var_0_1.ctor(arg_7_0, arg_7_1)
	arg_7_0._cellsPos = {}
	arg_7_0._cellsUsed = {}
	arg_7_0._cellsIndex = {}
	arg_7_0._cellsFreed = {}
	arg_7_0.direction = var_0_2.none
	arg_7_0.fillOrder = var_0_4.topToBottom

	arg_7_0:addEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 >= 4 then
			arg_8_0:_scrollViewDidScroll()
		end
	end)
	arg_7_0:setBounceEnabled(true)
	arg_7_0:init(arg_7_1)
end

function var_0_1.init(arg_9_0, arg_9_1)
	arg_9_0:setContentSize(arg_9_1 or cc.size(0, 0))
	arg_9_0:_updateCellsPosition()
	arg_9_0:_updateContentSize()
end

function var_0_1.registerFunc(arg_10_0, arg_10_1, arg_10_2)
	assert(arg_10_0[arg_10_1], "Invalid func type")

	arg_10_0[arg_10_1] = arg_10_2
end

function var_0_1.cellAtIndex(arg_11_0, arg_11_1)
	if arg_11_0._cellsIndex[arg_11_1] then
		for iter_11_0, iter_11_1 in pairs(arg_11_0._cellsUsed) do
			if iter_11_1:getIndex() == arg_11_1 then
				return iter_11_1, iter_11_0
			end
		end
	end
end

function var_0_1.reloadData(arg_12_0)
	arg_12_0:_correctFillOrder()

	arg_12_0.direction = var_0_2.none

	local var_12_0 = table.remove(arg_12_0._cellsUsed, 1)

	while var_12_0 do
		arg_12_0:_unloadCellAtIndex(var_12_0:getIndex())
		var_12_0:setVisible(false)
		table.insert(arg_12_0._cellsFreed, var_12_0)
		var_12_0:reset()

		var_12_0 = table.remove(arg_12_0._cellsUsed, 1)
	end

	arg_12_0._cellsUsed = {}
	arg_12_0._cellsIndex = {}

	arg_12_0:_updateCellsPosition()
	arg_12_0:_updateContentSize()

	if arg_12_0:_numberOfCells() > 0 then
		arg_12_0:_scrollViewDidScroll()
	end
end

function var_0_1.reloadDataInPos(arg_13_0)
	arg_13_0:_correctFillOrder()

	local var_13_0 = arg_13_0:getContentSize()
	local var_13_1, var_13_2 = arg_13_0:getInnerContainer():getPosition()
	local var_13_3 = arg_13_0:getInnerContainerSize()
	local var_13_4 = table.remove(arg_13_0._cellsUsed, 1)

	while var_13_4 do
		arg_13_0:_unloadCellAtIndex(var_13_4:getIndex())
		var_13_4:setVisible(false)
		table.insert(arg_13_0._cellsFreed, var_13_4)
		var_13_4:reset()

		var_13_4 = table.remove(arg_13_0._cellsUsed, 1)
	end

	arg_13_0._cellsUsed = {}
	arg_13_0._cellsIndex = {}

	arg_13_0:_updateCellsPosition()
	arg_13_0:_updateContentSize()

	local var_13_5 = arg_13_0:getInnerContainerSize()

	if arg_13_0.fillOrder == var_0_4.topToBottom then
		var_13_2 = math.max(math.min(0, var_13_3.height - var_13_5.height + var_13_2), var_13_0.height - var_13_5.height)
	elseif arg_13_0.fillOrder == var_0_4.bottomToTop then
		var_13_2 = math.max(math.min(0, var_13_2), var_13_0.height - var_13_5.height)
	end

	if arg_13_0.fillOrder == var_0_4.rightToLeft then
		var_13_1 = math.max(math.min(0, var_13_3.width - var_13_5.width + var_13_1), var_13_0.width - var_13_5.width)
	elseif arg_13_0.fillOrder == var_0_4.leftToRight then
		var_13_1 = math.max(math.min(0, var_13_1), var_13_0.width - var_13_5.width)
	end

	arg_13_0:getInnerContainer():setPosition(cc.p(var_13_1, var_13_2))

	if arg_13_0:_numberOfCells() > 0 then
		arg_13_0:_scrollViewDidScroll()
	end
end

function var_0_1.dequeueCell(arg_14_0)
	return table.remove(arg_14_0._cellsFreed, 1)
end

function var_0_1.setFillOrder(arg_15_0, arg_15_1)
	if arg_15_0.fillOrder ~= arg_15_1 then
		arg_15_0.fillOrder = arg_15_1

		if #arg_15_0._cellsUsed > 0 then
			arg_15_0:reloadData()
		end
	end
end

function var_0_1.updateCellAtIndex(arg_16_0, arg_16_1)
	if arg_16_1 <= 0 then
		return
	end

	local var_16_0 = arg_16_0:_numberOfCells()

	if var_16_0 == 0 or var_16_0 < arg_16_1 then
		return
	end

	local var_16_1, var_16_2 = arg_16_0:cellAtIndex(arg_16_1)

	if var_16_1 then
		arg_16_0:_moveCellOutOfSight(var_16_1, var_16_2)
	end

	local var_16_3 = arg_16_0:_loadCellAtIndex(arg_16_1)

	arg_16_0:_setIndexForCell(arg_16_1, var_16_3)
	arg_16_0:_addCellIfNecessary(var_16_3)
end

function var_0_1.insertCellAtIndex(arg_17_0, arg_17_1)
	if arg_17_1 <= 0 then
		return
	end

	local var_17_0 = arg_17_0:_numberOfCells()

	if var_17_0 == 0 or var_17_0 < arg_17_1 then
		return
	end

	local var_17_1, var_17_2 = arg_17_0:cellAtIndex(arg_17_1)

	if var_17_1 then
		for iter_17_0 = var_17_2, #arg_17_0._cellsUsed do
			local var_17_3 = arg_17_0._cellsUsed[iter_17_0]

			arg_17_0:_setIndexForCell(var_17_3:getIndex() + 1, var_17_3)

			arg_17_0._cellsIndex[var_17_3:getIndex()] = true
		end
	end

	local var_17_4 = arg_17_0:_loadCellAtIndex(arg_17_1)

	arg_17_0:_setIndexForCell(arg_17_1, var_17_4)
	arg_17_0:_addCellIfNecessary(var_17_4)
	arg_17_0:_updateCellsPosition()
	arg_17_0:_updateContentSize()
end

function var_0_1.removeCellAtIndex(arg_18_0, arg_18_1)
	if arg_18_1 <= 0 then
		return
	end

	local var_18_0 = arg_18_0:_numberOfCells()

	if var_18_0 == 0 or var_18_0 < arg_18_1 then
		return
	end

	local var_18_1, var_18_2 = arg_18_0:cellAtIndex(arg_18_1)

	if var_18_1 then
		arg_18_0:_moveCellOutOfSight(var_18_1, var_18_2)
		arg_18_0:_updateCellsPosition()

		local var_18_3 = #arg_18_0._cellsUsed

		for iter_18_0 = var_18_3, var_18_2, -1 do
			local var_18_4 = arg_18_0._cellsUsed[iter_18_0]

			if iter_18_0 == var_18_3 then
				arg_18_0._cellsIndex[var_18_4:getIndex()] = nil
			end

			arg_18_0:_setIndexForCell(var_18_4:getIndex() - 1, var_18_4)

			arg_18_0._cellsIndex[var_18_4:getIndex()] = true
		end
	end
end

function var_0_1._correctFillOrder(arg_19_0)
	arg_19_0.direction = arg_19_0:getDirection()
	arg_19_0.fillOrder = (arg_19_0.fillOrder - 1) % 2 + 1 + 2 * (arg_19_0.direction - 1)
end

function var_0_1._scrollViewDidScroll(arg_20_0)
	local var_20_0 = arg_20_0:_numberOfCells()

	if var_20_0 <= 0 then
		return
	end

	local var_20_1 = arg_20_0:getContentSize()

	if arg_20_0._isUsedCellsDirty then
		arg_20_0._isUsedCellsDirty = false

		table.sort(arg_20_0._cellsUsed, function(arg_21_0, arg_21_1)
			return arg_21_0:getIndex() < arg_21_1:getIndex()
		end)
	end

	local var_20_2 = 0
	local var_20_3 = 0
	local var_20_4 = 0
	local var_20_5 = 0
	local var_20_6 = cc.p(arg_20_0:getInnerContainer():getPosition())
	local var_20_7 = cc.p(-var_20_6.x, -var_20_6.y)
	local var_20_8 = math.max(var_20_0, 1)

	if arg_20_0.fillOrder == var_0_4.topToBottom then
		var_20_7.y = var_20_7.y + var_20_1.height
	elseif arg_20_0.fillOrder == var_0_4.rightToLeft then
		var_20_7.x = var_20_7.x + var_20_1.width
	end

	local var_20_9 = arg_20_0:_indexFromOffset(clone(var_20_7)) or var_20_8

	if arg_20_0.fillOrder == var_0_4.topToBottom then
		var_20_7.y = var_20_7.y - var_20_1.height
	elseif arg_20_0.fillOrder == var_0_4.bottomToTop then
		var_20_7.y = var_20_7.y + var_20_1.height
	end

	if arg_20_0.fillOrder == var_0_4.leftToRight then
		var_20_7.x = var_20_7.x + var_20_1.width
	elseif arg_20_0.fillOrder == var_0_4.rightToLeft then
		var_20_7.x = var_20_7.x - var_20_1.width
	end

	local var_20_10 = arg_20_0:_indexFromOffset(clone(var_20_7)) or var_20_8

	if #arg_20_0._cellsUsed > 0 then
		local var_20_11 = arg_20_0._cellsUsed[1]
		local var_20_12 = var_20_11:getIndex()

		while var_20_12 < var_20_9 do
			arg_20_0:_moveCellOutOfSight(var_20_11, 1)

			if #arg_20_0._cellsUsed > 0 then
				var_20_11 = arg_20_0._cellsUsed[1]
				var_20_12 = var_20_11:getIndex()
			else
				break
			end
		end
	end

	if #arg_20_0._cellsUsed > 0 then
		local var_20_13 = arg_20_0._cellsUsed[#arg_20_0._cellsUsed]
		local var_20_14 = var_20_13:getIndex()

		while var_20_14 <= var_20_8 and var_20_10 < var_20_14 do
			arg_20_0:_moveCellOutOfSight(var_20_13, #arg_20_0._cellsUsed)

			if #arg_20_0._cellsUsed > 0 then
				var_20_13 = arg_20_0._cellsUsed[#arg_20_0._cellsUsed]
				var_20_14 = var_20_13:getIndex()
			else
				break
			end
		end
	end

	for iter_20_0 = var_20_9, var_20_10 do
		if not arg_20_0._cellsIndex[iter_20_0] then
			arg_20_0:updateCellAtIndex(iter_20_0)
		end
	end
end

function var_0_1._setIndexForCell(arg_22_0, arg_22_1, arg_22_2)
	arg_22_2:setAnchorPoint(cc.p(0, 0))
	arg_22_2:setPosition(arg_22_0:_offsetFromIndex(arg_22_1))
	arg_22_2:setIndex(arg_22_1)
end

function var_0_1._moveCellOutOfSight(arg_23_0, arg_23_1, arg_23_2)
	table.insert(arg_23_0._cellsFreed, table.remove(arg_23_0._cellsUsed, arg_23_2))

	arg_23_0._cellsIndex[arg_23_1:getIndex()] = nil
	arg_23_0._isUsedCellsDirty = true

	arg_23_0:_unloadCellAtIndex(arg_23_1:getIndex())
	arg_23_1:reset()
	arg_23_1:setVisible(false)
end

function var_0_1._addCellIfNecessary(arg_24_0, arg_24_1)
	arg_24_1:setVisible(true)

	if arg_24_1:getParent() ~= arg_24_0:getInnerContainer() then
		arg_24_0:addChild(arg_24_1)
	end

	table.insert(arg_24_0._cellsUsed, arg_24_1)

	arg_24_0._cellsIndex[arg_24_1:getIndex()] = true
	arg_24_0._isUsedCellsDirty = true
end

function var_0_1._indexFromOffset(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0:getInnerContainerSize()

	if arg_25_0.fillOrder == var_0_4.topToBottom then
		arg_25_1.y = var_25_0.height - arg_25_1.y
	elseif arg_25_0.fillOrder == var_0_4.rightToLeft then
		arg_25_1.x = var_25_0.width - arg_25_1.x
	end

	local var_25_1

	if arg_25_0.direction == var_0_2.horizontal then
		var_25_1 = arg_25_1.x
	else
		var_25_1 = arg_25_1.y
	end

	local var_25_2 = 1
	local var_25_3 = arg_25_0:_numberOfCells()

	while var_25_2 <= var_25_3 do
		local var_25_4 = math.floor(var_25_2 + (var_25_3 - var_25_2) / 2)
		local var_25_5 = arg_25_0._cellsPos[var_25_4]
		local var_25_6 = arg_25_0._cellsPos[var_25_4 + 1]

		if var_25_5 <= var_25_1 and var_25_1 <= var_25_6 then
			return var_25_4
		elseif var_25_1 < var_25_5 then
			var_25_3 = var_25_4 - 1
		else
			var_25_2 = var_25_4 + 1
		end
	end

	if var_25_2 <= 1 then
		return 1
	end
end

function var_0_1._offsetFromIndex(arg_26_0, arg_26_1)
	local var_26_0

	if arg_26_0.direction == var_0_2.horizontal then
		var_26_0 = cc.p(arg_26_0._cellsPos[arg_26_1], 0)
	else
		var_26_0 = cc.p(0, arg_26_0._cellsPos[arg_26_1])
	end

	local var_26_1 = cc.size(arg_26_0:_cellSizeAtIndex(arg_26_1))

	if arg_26_0.fillOrder == var_0_4.topToBottom then
		var_26_0.y = arg_26_0:getInnerContainerSize().height - var_26_0.y - var_26_1.height
	elseif arg_26_0.fillOrder == var_0_4.rightToLeft then
		var_26_0.x = arg_26_0:getInnerContainerSize().width - var_26_0.x - var_26_1.width
	end

	return var_26_0
end

function var_0_1._updateContentSize(arg_27_0)
	local var_27_0 = arg_27_0:getContentSize()
	local var_27_1 = arg_27_0:getInnerContainerSize()
	local var_27_2 = arg_27_0:_numberOfCells()
	local var_27_3 = arg_27_0:getDirection()

	if var_27_2 > 0 then
		local var_27_4 = arg_27_0._cellsPos[#arg_27_0._cellsPos]

		if var_27_3 == var_0_2.horizontal then
			var_27_1.width = math.max(var_27_0.width, var_27_4)
		else
			var_27_1.height = math.max(var_27_0.height, var_27_4)
		end
	end

	arg_27_0:getInnerContainer():setContentSize(var_27_1)
	arg_27_0:_setInnerContainerInitPos()
end

function var_0_1._setInnerContainerInitPos(arg_28_0)
	local var_28_0 = arg_28_0:getDirection()

	if arg_28_0.direction ~= var_28_0 then
		if var_28_0 == var_0_2.horizontal then
			if arg_28_0.fillOrder == var_0_4.leftToRight then
				arg_28_0:getInnerContainer():setPosition(cc.p(0, 0))
			elseif arg_28_0.fillOrder == var_0_4.rightToLeft then
				arg_28_0:getInnerContainer():setPosition(cc.p(arg_28_0:_getMinContainerOffset().x, 0))
			end
		elseif arg_28_0.fillOrder == var_0_4.topToBottom then
			arg_28_0:getInnerContainer():setPosition(cc.p(0, arg_28_0:_getMinContainerOffset().y))
		elseif arg_28_0.fillOrder == var_0_4.bottomToTop then
			arg_28_0:getInnerContainer():setPosition(cc.p(0, 0))
		end

		arg_28_0.direction = var_28_0
	end
end

function var_0_1._updateCellsPosition(arg_29_0)
	local var_29_0 = arg_29_0:_numberOfCells()

	arg_29_0._cellsPos = {}

	if var_29_0 > 0 then
		local var_29_1 = 0
		local var_29_2
		local var_29_3 = arg_29_0:getDirection()

		for iter_29_0 = 1, var_29_0 do
			table.insert(arg_29_0._cellsPos, var_29_1)

			local var_29_4 = cc.size(arg_29_0:_cellSizeAtIndex(iter_29_0))

			if var_29_3 == var_0_2.horizontal then
				var_29_1 = var_29_1 + var_29_4.width
			else
				var_29_1 = var_29_1 + var_29_4.height
			end
		end

		table.insert(arg_29_0._cellsPos, var_29_1)
	end
end

function var_0_1._getMinContainerOffset(arg_30_0)
	local var_30_0 = arg_30_0:getInnerContainer()
	local var_30_1 = var_30_0:getAnchorPoint()
	local var_30_2 = var_30_0:getContentSize()
	local var_30_3 = arg_30_0:getContentSize()

	return cc.p(var_30_3.width - (1 - var_30_1.x) * var_30_2.width, var_30_3.height - (1 - var_30_1.y) * var_30_2.height)
end

function var_0_1._cellSizeAtIndex(arg_31_0, arg_31_1)
	return 0, 0
end

function var_0_1._numberOfCells(arg_32_0)
	return 0
end

function var_0_1._loadCellAtIndex(arg_33_0, arg_33_1)
	local var_33_0 = arg_33_0:dequeueCell()

	if not var_33_0 then
		return var_0_0.new()
	end

	return var_33_0
end

function var_0_1._unloadCellAtIndex(arg_34_0, arg_34_1)
	return
end

cc.TableView = var_0_1
cc.TableViewCell = var_0_0
cc.TableViewFillOrder = var_0_4
cc.TableViewDirection = var_0_2
cc.TableViewFuncType = var_0_3
