local var_0_0 = import(".UIPageViewItem")
local var_0_1 = class("UIPageView", function()
	return (display.newClippingRegionNode())
end)

function var_0_1.ctor(arg_2_0, arg_2_1)
	arg_2_0.items_ = {}
	arg_2_0.viewRect_ = arg_2_1.viewRect or cc.rect(0, 0, display.width, display.height)
	arg_2_0.column_ = arg_2_1.column or 1
	arg_2_0.row_ = arg_2_1.row or 1
	arg_2_0.columnSpace_ = arg_2_1.columnSpace or 0
	arg_2_0.rowSpace_ = arg_2_1.rowSpace or 0
	arg_2_0.padding_ = arg_2_1.padding or {
		top = 0,
		bottom = 0,
		left = 0,
		right = 0
	}
	arg_2_0.bCirc = arg_2_1.bCirc or false

	arg_2_0:setClippingRegion(arg_2_0.viewRect_)
	arg_2_0:setTouchEnabled(true)
	arg_2_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
		return arg_2_0:onTouch_(arg_3_0)
	end)
end

function var_0_1.newItem(arg_4_0)
	local var_4_0 = var_0_0.new()
	local var_4_1 = (arg_4_0.viewRect_.width - arg_4_0.padding_.left - arg_4_0.padding_.right - arg_4_0.columnSpace_ * (arg_4_0.column_ - 1)) / arg_4_0.column_
	local var_4_2 = (arg_4_0.viewRect_.height - arg_4_0.padding_.top - arg_4_0.padding_.bottom - arg_4_0.rowSpace_ * (arg_4_0.row_ - 1)) / arg_4_0.row_

	var_4_0:setContentSize(var_4_1, var_4_2)

	return var_4_0
end

function var_0_1.addItem(arg_5_0, arg_5_1)
	table.insert(arg_5_0.items_, arg_5_1)

	return arg_5_0
end

function var_0_1.removeItem(arg_6_0, arg_6_1)
	local var_6_0

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.items_) do
		if iter_6_1 == arg_6_1 then
			var_6_0 = iter_6_0
		end
	end

	if not var_6_0 then
		print("ERROR! item isn't exist")

		return arg_6_0
	end

	if var_6_0 then
		table.remove(arg_6_0.items_, var_6_0)
	end

	arg_6_0:reload(arg_6_0.curPageIdx_)

	return arg_6_0
end

function var_0_1.removeAllItems(arg_7_0)
	arg_7_0.items_ = {}

	arg_7_0:reload(arg_7_0.curPageIdx_)

	return arg_7_0
end

function var_0_1.onTouch(arg_8_0, arg_8_1)
	arg_8_0.touchListener = arg_8_1

	return arg_8_0
end

function var_0_1.reload(arg_9_0, arg_9_1)
	local var_9_0
	local var_9_1

	arg_9_0.pages_ = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.items_) do
		iter_9_1:retain()
	end

	arg_9_0:removeAllChildren()

	local var_9_2 = arg_9_0:getPageCount()

	if var_9_2 < 1 then
		return arg_9_0
	end

	if var_9_2 > 0 then
		for iter_9_2 = 1, var_9_2 do
			local var_9_3 = arg_9_0:createPage_(iter_9_2)

			var_9_3:setVisible(false)
			table.insert(arg_9_0.pages_, var_9_3)
			arg_9_0:addChild(var_9_3)
		end
	end

	if not arg_9_1 or arg_9_1 < 1 then
		arg_9_1 = 1
	elseif var_9_2 < arg_9_1 then
		arg_9_1 = var_9_2
	end

	arg_9_0.curPageIdx_ = arg_9_1

	arg_9_0.pages_[arg_9_1]:setVisible(true)
	arg_9_0.pages_[arg_9_1]:setPosition(arg_9_0.viewRect_.x, arg_9_0.viewRect_.y)

	for iter_9_3, iter_9_4 in ipairs(arg_9_0.items_) do
		iter_9_4:release()
	end

	return arg_9_0
end

function var_0_1.gotoPage(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if arg_10_1 < 1 or arg_10_1 > arg_10_0:getPageCount() then
		return arg_10_0
	end

	if arg_10_1 == arg_10_0.curPageIdx_ and arg_10_2 then
		return arg_10_0
	end

	if arg_10_2 then
		arg_10_0:resetPagePos(arg_10_1, arg_10_3)
		arg_10_0:scrollPagePos(arg_10_1, arg_10_3)
	else
		arg_10_0.pages_[arg_10_0.curPageIdx_]:setVisible(false)
		arg_10_0.pages_[arg_10_1]:setVisible(true)
		arg_10_0.pages_[arg_10_1]:setPosition(arg_10_0.viewRect_.x, arg_10_0.viewRect_.y)

		arg_10_0.curPageIdx_ = arg_10_1

		arg_10_0:notifyListener_({
			name = "pageChange"
		})
	end

	return arg_10_0
end

function var_0_1.getPageCount(arg_11_0)
	return math.ceil(table.nums(arg_11_0.items_) / (arg_11_0.column_ * arg_11_0.row_))
end

function var_0_1.getCurPageIdx(arg_12_0)
	return arg_12_0.curPageIdx_
end

function var_0_1.setCirculatory(arg_13_0, arg_13_1)
	arg_13_0.bCirc = arg_13_1

	return arg_13_0
end

function var_0_1.createPage_(arg_14_0, arg_14_1)
	local var_14_0 = display.newNode()
	local var_14_1
	local var_14_2 = arg_14_0.row_ * arg_14_0.column_ * (arg_14_1 - 1) + 1
	local var_14_3
	local var_14_4
	local var_14_5 = (arg_14_0.viewRect_.width - arg_14_0.padding_.left - arg_14_0.padding_.right - arg_14_0.columnSpace_ * (arg_14_0.column_ - 1)) / arg_14_0.column_
	local var_14_6 = (arg_14_0.viewRect_.height - arg_14_0.padding_.top - arg_14_0.padding_.bottom - arg_14_0.rowSpace_ * (arg_14_0.row_ - 1)) / arg_14_0.row_
	local var_14_7 = false

	for iter_14_0 = 1, arg_14_0.row_ do
		for iter_14_1 = 1, arg_14_0.column_ do
			local var_14_8 = arg_14_0.items_[var_14_2]

			var_14_2 = var_14_2 + 1

			if not var_14_8 then
				var_14_7 = true

				break
			end

			var_14_0:addChild(var_14_8)
			var_14_8:setAnchorPoint(cc.p(0.5, 0.5))
			var_14_8:setPosition(arg_14_0.padding_.left + (iter_14_1 - 1) * arg_14_0.columnSpace_ + iter_14_1 * var_14_5 - var_14_5 / 2, arg_14_0.viewRect_.height - arg_14_0.padding_.top - (iter_14_0 - 1) * arg_14_0.rowSpace_ - iter_14_0 * var_14_6 + var_14_6 / 2)
		end

		if var_14_7 then
			break
		end
	end

	var_14_0:setTag(1500 + arg_14_1)

	return var_14_0
end

function var_0_1.isTouchInViewRect_(arg_15_0, arg_15_1, arg_15_2)
	arg_15_2 = arg_15_2 or arg_15_0.viewRect_

	local var_15_0 = arg_15_0:convertToWorldSpace(cc.p(arg_15_2.x, arg_15_2.y))

	var_15_0.width = arg_15_2.width
	var_15_0.height = arg_15_2.height

	return cc.rectContainsPoint(var_15_0, cc.p(arg_15_1.x, arg_15_1.y))
end

function var_0_1.onTouch_(arg_16_0, arg_16_1)
	if arg_16_1.name == "began" and not arg_16_0:isTouchInViewRect_(arg_16_1) then
		printInfo("UIPageView - touch didn't in viewRect")

		return false
	end

	if arg_16_1.name == "began" then
		arg_16_0:stopAllTransition()

		arg_16_0.bDrag_ = false
	elseif arg_16_1.name == "moved" then
		arg_16_0.bDrag_ = true
		arg_16_0.speed = arg_16_1.x - arg_16_1.prevX

		arg_16_0:scroll(arg_16_0.speed)
	elseif arg_16_1.name == "ended" then
		if arg_16_0.bDrag_ then
			arg_16_0:scrollAuto()
		else
			arg_16_0:resetPages_()
			arg_16_0:onClick_(arg_16_1)
		end
	end

	return true
end

function var_0_1.resetPages_(arg_17_0)
	local var_17_0, var_17_1 = arg_17_0.pages_[arg_17_0.curPageIdx_]:getPosition()

	if var_17_0 == arg_17_0.viewRect_.x then
		return
	end

	print("UIPageView - resetPages_")
	arg_17_0:disablePage()
	arg_17_0:gotoPage(arg_17_0.curPageIdx_)
end

function var_0_1.resetPagePos(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_0.curPageIdx_
	local var_18_1
	local var_18_2 = arg_18_0.viewRect_.width
	local var_18_3
	local var_18_4 = #arg_18_0.pages_
	local var_18_5 = arg_18_1 - var_18_0

	if arg_18_0.bCirc then
		local var_18_6
		local var_18_7

		if var_18_5 > 0 then
			var_18_7 = var_18_5
			var_18_6 = var_18_7 - var_18_4
		else
			var_18_6 = var_18_5
			var_18_7 = var_18_6 + var_18_4
		end

		if arg_18_2 == nil then
			var_18_5 = math.abs(var_18_6) > math.abs(var_18_7) and var_18_7 or var_18_6
		elseif arg_18_2 then
			var_18_5 = var_18_7
		else
			var_18_5 = var_18_6
		end
	end

	local var_18_8 = math.abs(var_18_5)
	local var_18_9 = arg_18_0.pages_[var_18_0]:getPosition()

	for iter_18_0 = 1, var_18_8 do
		if var_18_5 > 0 then
			var_18_0 = var_18_0 + 1
			var_18_9 = var_18_9 + var_18_2
		else
			var_18_0 = var_18_0 + var_18_4
			var_18_0 = var_18_0 - 1
			var_18_9 = var_18_9 - var_18_2
		end

		var_18_0 = var_18_0 % var_18_4

		if var_18_0 == 0 then
			var_18_0 = var_18_4
		end

		local var_18_10 = arg_18_0.pages_[var_18_0]

		if var_18_10 then
			var_18_10:setVisible(true)
			var_18_10:setPosition(var_18_9, arg_18_0.viewRect_.y)
		end
	end
end

function var_0_1.scrollPagePos(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_0.curPageIdx_
	local var_19_1
	local var_19_2 = arg_19_0.viewRect_.width
	local var_19_3
	local var_19_4 = #arg_19_0.pages_
	local var_19_5 = arg_19_1 - var_19_0

	if arg_19_0.bCirc then
		local var_19_6
		local var_19_7

		if var_19_5 > 0 then
			var_19_7 = var_19_5
			var_19_6 = var_19_7 - var_19_4
		else
			var_19_6 = var_19_5
			var_19_7 = var_19_6 + var_19_4
		end

		if arg_19_2 == nil then
			var_19_5 = math.abs(var_19_6) > math.abs(var_19_7) and var_19_7 or var_19_6
		elseif arg_19_2 then
			var_19_5 = var_19_7
		else
			var_19_5 = var_19_6
		end
	end

	local var_19_8 = math.abs(var_19_5)
	local var_19_9 = arg_19_0.viewRect_.x
	local var_19_10 = var_19_5 * var_19_2

	for iter_19_0 = 1, var_19_8 do
		if var_19_5 > 0 then
			var_19_0 = var_19_0 + 1
		else
			var_19_0 = var_19_0 + var_19_4
			var_19_0 = var_19_0 - 1
		end

		var_19_0 = var_19_0 % var_19_4

		if var_19_0 == 0 then
			var_19_0 = var_19_4
		end

		local var_19_11 = arg_19_0.pages_[var_19_0]

		if var_19_11 then
			var_19_11:setVisible(true)
			transition.moveBy(var_19_11, {
				time = 0.3,
				y = 0,
				x = -var_19_10
			})
		end
	end

	transition.moveBy(arg_19_0.pages_[arg_19_0.curPageIdx_], {
		time = 0.3,
		y = 0,
		x = -var_19_10,
		onComplete = function()
			local var_20_0 = (arg_19_0.curPageIdx_ + var_19_5 + var_19_4) % var_19_4

			if var_20_0 == 0 then
				var_20_0 = var_19_4
			end

			arg_19_0.curPageIdx_ = var_20_0

			arg_19_0:disablePage()
			arg_19_0:notifyListener_({
				name = "pageChange"
			})
		end
	})
end

function var_0_1.stopAllTransition(arg_21_0)
	for iter_21_0, iter_21_1 in ipairs(arg_21_0.pages_) do
		transition.stopTarget(iter_21_1)
	end
end

function var_0_1.disablePage(arg_22_0)
	local var_22_0 = arg_22_0.curPageIdx_
	local var_22_1

	for iter_22_0, iter_22_1 in ipairs(arg_22_0.pages_) do
		if iter_22_0 ~= arg_22_0.curPageIdx_ then
			iter_22_1:setVisible(false)
		end
	end
end

function var_0_1.scroll(arg_23_0, arg_23_1)
	local var_23_0 = {}
	local var_23_1

	if arg_23_0.pages_ then
		var_23_1 = #arg_23_0.pages_
	else
		var_23_1 = 0
	end

	local var_23_2

	if var_23_1 == 0 then
		return
	elseif var_23_1 == 1 then
		table.insert(var_23_0, false)
		table.insert(var_23_0, arg_23_0.pages_[arg_23_0.curPageIdx_])
	elseif var_23_1 == 2 then
		local var_23_3, var_23_4 = arg_23_0.pages_[arg_23_0.curPageIdx_]:getPosition()

		if var_23_3 > arg_23_0.viewRect_.x then
			local var_23_5 = arg_23_0:getNextPage(false) or false

			table.insert(var_23_0, var_23_5)
			table.insert(var_23_0, arg_23_0.pages_[arg_23_0.curPageIdx_])
		else
			table.insert(var_23_0, false)
			table.insert(var_23_0, arg_23_0.pages_[arg_23_0.curPageIdx_])
			table.insert(var_23_0, arg_23_0:getNextPage(true))
		end
	else
		local var_23_6 = arg_23_0:getNextPage(false) or false

		table.insert(var_23_0, var_23_6)
		table.insert(var_23_0, arg_23_0.pages_[arg_23_0.curPageIdx_])
		table.insert(var_23_0, arg_23_0:getNextPage(true))
	end

	arg_23_0:scrollLCRPages(var_23_0, arg_23_1)
end

function var_0_1.scrollLCRPages(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0
	local var_24_1
	local var_24_2 = arg_24_1[1]
	local var_24_3 = arg_24_1[2]
	local var_24_4 = arg_24_1[3]
	local var_24_5, var_24_6 = var_24_3:getPosition()
	local var_24_7 = var_24_6
	local var_24_8 = var_24_5 + arg_24_2

	var_24_3:setPosition(var_24_8, var_24_7)

	local var_24_9 = var_24_8 - arg_24_0.viewRect_.width

	if var_24_2 and type(var_24_2) ~= "boolean" then
		var_24_2:setPosition(var_24_9, var_24_7)

		if not var_24_2:isVisible() then
			var_24_2:setVisible(true)
		end
	end

	local var_24_10 = var_24_9 + arg_24_0.viewRect_.width * 2

	if var_24_4 then
		var_24_4:setPosition(var_24_10, var_24_7)

		if not var_24_4:isVisible() then
			var_24_4:setVisible(true)
		end
	end
end

function var_0_1.scrollAuto(arg_25_0)
	local var_25_0 = arg_25_0.pages_[arg_25_0.curPageIdx_]
	local var_25_1 = arg_25_0:getNextPage(false)
	local var_25_2 = arg_25_0:getNextPage(true)
	local var_25_3 = false
	local var_25_4, var_25_5 = var_25_0:getPosition()
	local var_25_6 = var_25_4 - arg_25_0.viewRect_.x
	local var_25_7 = arg_25_0.viewRect_.x + arg_25_0.viewRect_.width
	local var_25_8 = arg_25_0.viewRect_.x - arg_25_0.viewRect_.width
	local var_25_9 = #arg_25_0.pages_

	if var_25_9 == 0 then
		return
	elseif var_25_9 == 1 then
		var_25_1 = nil
		var_25_2 = nil
	end

	if (var_25_6 > arg_25_0.viewRect_.width / 2 or arg_25_0.speed > 10) and (arg_25_0.curPageIdx_ > 1 or arg_25_0.bCirc) and var_25_9 > 1 then
		var_25_3 = true
	elseif (-var_25_6 > arg_25_0.viewRect_.width / 2 or -arg_25_0.speed > 10) and (arg_25_0.curPageIdx_ < arg_25_0:getPageCount() or arg_25_0.bCirc) and var_25_9 > 1 then
		var_25_3 = true
	end

	if var_25_6 > 0 then
		if var_25_3 then
			transition.moveTo(var_25_0, {
				time = 0.3,
				x = var_25_7,
				y = var_25_5,
				onComplete = function()
					arg_25_0.curPageIdx_ = arg_25_0:getNextPageIndex(false)

					arg_25_0:disablePage()
					arg_25_0:notifyListener_({
						name = "pageChange"
					})
				end
			})
			transition.moveTo(var_25_1, {
				time = 0.3,
				x = arg_25_0.viewRect_.x,
				y = var_25_5
			})
		else
			transition.moveTo(var_25_0, {
				time = 0.3,
				x = arg_25_0.viewRect_.x,
				y = var_25_5,
				onComplete = function()
					arg_25_0:disablePage()
					arg_25_0:notifyListener_({
						name = "pageChange"
					})
				end
			})

			if var_25_1 then
				transition.moveTo(var_25_1, {
					time = 0.3,
					x = var_25_8,
					y = var_25_5
				})
			end
		end
	elseif var_25_3 then
		transition.moveTo(var_25_0, {
			time = 0.3,
			x = var_25_8,
			y = var_25_5,
			onComplete = function()
				arg_25_0.curPageIdx_ = arg_25_0:getNextPageIndex(true)

				arg_25_0:disablePage()
				arg_25_0:notifyListener_({
					name = "pageChange"
				})
			end
		})
		transition.moveTo(var_25_2, {
			time = 0.3,
			x = arg_25_0.viewRect_.x,
			y = var_25_5
		})
	else
		transition.moveTo(var_25_0, {
			time = 0.3,
			x = arg_25_0.viewRect_.x,
			y = var_25_5,
			onComplete = function()
				arg_25_0:disablePage()
				arg_25_0:notifyListener_({
					name = "pageChange"
				})
			end
		})

		if var_25_2 then
			transition.moveTo(var_25_2, {
				time = 0.3,
				x = var_25_7,
				y = var_25_5
			})
		end
	end
end

function var_0_1.onClick_(arg_30_0, arg_30_1)
	local var_30_0
	local var_30_1
	local var_30_2 = (arg_30_0.viewRect_.width - arg_30_0.padding_.left - arg_30_0.padding_.right - arg_30_0.columnSpace_ * (arg_30_0.column_ - 1)) / arg_30_0.column_
	local var_30_3 = (arg_30_0.viewRect_.height - arg_30_0.padding_.top - arg_30_0.padding_.bottom - arg_30_0.rowSpace_ * (arg_30_0.row_ - 1)) / arg_30_0.row_
	local var_30_4 = {
		width = var_30_2,
		height = var_30_3
	}
	local var_30_5

	for iter_30_0 = 1, arg_30_0.row_ do
		var_30_4.y = arg_30_0.viewRect_.y + arg_30_0.viewRect_.height - arg_30_0.padding_.top - iter_30_0 * var_30_3 - (iter_30_0 - 1) * arg_30_0.rowSpace_

		for iter_30_1 = 1, arg_30_0.column_ do
			var_30_4.x = arg_30_0.viewRect_.x + arg_30_0.padding_.left + (iter_30_1 - 1) * (var_30_2 + arg_30_0.columnSpace_)

			if arg_30_0:isTouchInViewRect_(arg_30_1, var_30_4) then
				var_30_5 = (iter_30_0 - 1) * arg_30_0.column_ + iter_30_1

				break
			end
		end

		if var_30_5 then
			break
		end
	end

	if not var_30_5 then
		return
	end

	local var_30_6 = var_30_5 + arg_30_0.column_ * arg_30_0.row_ * (arg_30_0.curPageIdx_ - 1)

	arg_30_0:notifyListener_({
		name = "clicked",
		item = arg_30_0.items_[var_30_6],
		itemIdx = var_30_6
	})
end

function var_0_1.notifyListener_(arg_31_0, arg_31_1)
	if not arg_31_0.touchListener then
		return
	end

	arg_31_1.pageView = arg_31_0
	arg_31_1.pageIdx = arg_31_0.curPageIdx_

	arg_31_0.touchListener(arg_31_1)
end

function var_0_1.getNextPage(arg_32_0, arg_32_1)
	if not arg_32_0.pages_ then
		return
	end

	if arg_32_0.pages_ and #arg_32_0.pages_ < 2 then
		return
	end

	local var_32_0 = arg_32_0:getNextPageIndex(arg_32_1)

	return arg_32_0.pages_[var_32_0]
end

function var_0_1.getNextPageIndex(arg_33_0, arg_33_1)
	local var_33_0 = #arg_33_0.pages_
	local var_33_1

	if arg_33_1 then
		var_33_1 = arg_33_0.curPageIdx_ + 1
	else
		var_33_1 = arg_33_0.curPageIdx_ - 1
	end

	if arg_33_0.bCirc then
		var_33_1 = var_33_1 + var_33_0
		var_33_1 = var_33_1 % var_33_0

		if var_33_1 == 0 then
			var_33_1 = var_33_0
		end
	end

	return var_33_1
end

return var_0_1
