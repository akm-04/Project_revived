local var_0_0 = {}
local var_0_1 = ccui.ListView

local function var_0_2(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_1:convertToWorldSpace(cc.p(0, 0))
	local var_1_1 = arg_1_0:convertToNodeSpace(var_1_0)

	var_1_1.x = var_1_1.x + arg_1_0._checkOffsetX
	var_1_1.y = var_1_1.y + arg_1_0._checkOffsetY

	local var_1_2 = arg_1_1:getContentSize()
	local var_1_3 = (var_1_2.width + arg_1_0._checkWidth) / 2
	local var_1_4 = (var_1_2.height + arg_1_0._checkHeight) / 2

	if var_1_3 >= math.abs(var_1_1.x + var_1_2.width / 2 - arg_1_0._checkWidth / 2) and var_1_4 >= math.abs(var_1_1.y + var_1_2.height / 2 - arg_1_0._checkHeight / 2) then
		return true
	end

	return false
end

local function var_0_3(arg_2_0)
	if arg_2_0._headIndex == nil then
		for iter_2_0 = arg_2_0._tailIndex, 1, -1 do
			local var_2_0 = var_0_1.getItem(arg_2_0, iter_2_0 - 1)

			if not var_0_2(arg_2_0, var_2_0) then
				break
			end

			if #var_2_0:getChildren() > 0 then
				break
			end

			var_2_0:addChild(arg_2_0:_loadSource(iter_2_0))

			arg_2_0._headIndex = iter_2_0
		end

		return
	end

	if arg_2_0._tailIndex == nil then
		local var_2_1 = var_0_1.getItems(arg_2_0)

		for iter_2_1 = arg_2_0._headIndex, #var_2_1 do
			local var_2_2 = var_2_1[iter_2_1]

			if not var_0_2(arg_2_0, var_2_2) then
				break
			end

			if #var_2_2:getChildren() > 0 then
				break
			end

			var_2_2:addChild(arg_2_0:_loadSource(iter_2_1))

			arg_2_0._tailIndex = iter_2_1
		end

		return
	end

	if arg_2_0._innerP == nil then
		return
	end

	local var_2_3 = arg_2_0:getDirection()
	local var_2_4 = false

	if var_2_3 == 1 then
		local var_2_5 = arg_2_0:getInnerContainer():getPositionY()

		if var_2_5 > arg_2_0._innerP then
			var_2_4 = true
		end

		arg_2_0._innerP = var_2_5
	else
		local var_2_6 = arg_2_0:getInnerContainer():getPositionX()

		if var_2_6 < arg_2_0._innerP then
			var_2_4 = true
		end

		arg_2_0._innerP = var_2_6
	end

	local var_2_7

	if var_2_4 then
		local var_2_8 = var_0_1.getItem(arg_2_0, arg_2_0._tailIndex - 1)

		if var_0_2(arg_2_0, var_2_8) then
			repeat
				local var_2_9 = var_0_1.getItem(arg_2_0, arg_2_0._tailIndex)

				if var_2_9 == nil then
					break
				end

				if not var_0_2(arg_2_0, var_2_9) then
					break
				end

				arg_2_0._tailIndex = arg_2_0._tailIndex + 1

				var_2_9:addChild(arg_2_0:_loadSource(arg_2_0._tailIndex))
			until false

			repeat
				local var_2_10 = var_0_1.getItem(arg_2_0, arg_2_0._headIndex - 1)

				if var_0_2(arg_2_0, var_2_10) then
					break
				end

				var_2_10:removeAllChildren()
				arg_2_0:_unloadSource(arg_2_0._headIndex)

				arg_2_0._headIndex = arg_2_0._headIndex + 1
			until false
		else
			for iter_2_2 = arg_2_0._headIndex, arg_2_0._tailIndex do
				var_0_1.getItem(arg_2_0, iter_2_2 - 1):removeAllChildren()
				arg_2_0:_unloadSource(iter_2_2)

				arg_2_0._headIndex = nil
			end

			repeat
				local var_2_11 = var_0_1.getItem(arg_2_0, arg_2_0._tailIndex)

				if var_2_11 == nil then
					break
				end

				if var_0_2(arg_2_0, var_2_11) then
					arg_2_0._tailIndex = arg_2_0._tailIndex + 1

					var_2_11:addChild(arg_2_0:_loadSource(arg_2_0._tailIndex))

					if arg_2_0._headIndex == nil then
						arg_2_0._headIndex = arg_2_0._tailIndex
					end
				elseif arg_2_0._headIndex then
					break
				else
					arg_2_0._tailIndex = arg_2_0._tailIndex + 1
				end
			until false
		end
	else
		local var_2_12 = var_0_1.getItem(arg_2_0, arg_2_0._headIndex - 1)

		if var_0_2(arg_2_0, var_2_12) then
			repeat
				local var_2_13 = var_0_1.getItem(arg_2_0, arg_2_0._headIndex - 2)

				if var_2_13 == nil then
					break
				end

				if not var_0_2(arg_2_0, var_2_13) then
					break
				end

				arg_2_0._headIndex = arg_2_0._headIndex - 1

				var_2_13:addChild(arg_2_0:_loadSource(arg_2_0._headIndex))
			until false

			repeat
				local var_2_14 = var_0_1.getItem(arg_2_0, arg_2_0._tailIndex - 1)

				if var_0_2(arg_2_0, var_2_14) then
					break
				end

				var_2_14:removeAllChildren()
				arg_2_0:_unloadSource(arg_2_0._tailIndex)

				arg_2_0._tailIndex = arg_2_0._tailIndex - 1
			until false
		else
			for iter_2_3 = arg_2_0._headIndex, arg_2_0._tailIndex do
				var_0_1.getItem(arg_2_0, iter_2_3 - 1):removeAllChildren()
				arg_2_0:_unloadSource(iter_2_3)

				arg_2_0._tailIndex = nil
			end

			repeat
				local var_2_15 = var_0_1.getItem(arg_2_0, arg_2_0._headIndex - 2)

				if var_2_15 == nil then
					break
				end

				if var_0_2(arg_2_0, var_2_15) then
					arg_2_0._headIndex = arg_2_0._headIndex - 1

					var_2_15:addChild(arg_2_0:_loadSource(arg_2_0._headIndex))

					if arg_2_0._tailIndex == nil then
						arg_2_0._tailIndex = arg_2_0._headIndex
					end
				elseif arg_2_0._tailIndex then
					break
				else
					arg_2_0._headIndex = arg_2_0._headIndex - 1
				end
			until false
		end
	end
end

local function var_0_4(arg_3_0, arg_3_1)
	arg_3_0:stopAllActions()
	arg_3_0:performWithDelay(function()
		local var_4_0 = arg_3_0:getDirection()
		local var_4_1 = arg_3_0:getContentSize()
		local var_4_2 = {}
		local var_4_3 = var_0_1.getItems(arg_3_0)

		for iter_4_0 = arg_3_0._headIndex, arg_3_0._tailIndex do
			var_4_2[iter_4_0] = false
		end

		local var_4_4 = var_4_3[arg_3_1]

		assert(arg_3_1 >= 1 and arg_3_1 <= #var_4_3, "Wrong index range")

		if var_4_0 == 1 then
			local var_4_5 = var_4_1.height - var_4_4:getPositionY() - var_4_4:getContentSize().height
			local var_4_6 = math.min(0, var_4_5)

			arg_3_0:getInnerContainer():setPositionY(var_4_6)

			arg_3_0._innerP = var_4_6
		else
			local var_4_7 = var_4_1.width - var_4_4:getPositionX() - var_4_4:getContentSize().width
			local var_4_8 = math.min(0, var_4_7)

			arg_3_0:getInnerContainer():setPositionX(var_4_8)

			arg_3_0._innerP = var_4_8
		end

		for iter_4_1 = arg_3_1, 1, -1 do
			if not var_0_2(arg_3_0, var_4_3[iter_4_1]) then
				break
			end

			arg_3_0._headIndex = iter_4_1
		end

		for iter_4_2 = arg_3_1, #var_4_3 do
			if not var_0_2(arg_3_0, var_4_3[iter_4_2]) then
				break
			end

			arg_3_0._tailIndex = iter_4_2
		end

		for iter_4_3 = arg_3_0._headIndex, arg_3_0._tailIndex do
			if var_4_2[iter_4_3] == nil then
				var_4_3[iter_4_3]:addChild(arg_3_0:_loadSource(iter_4_3))
			end

			var_4_2[iter_4_3] = true
		end

		for iter_4_4, iter_4_5 in pairs(var_4_2) do
			if iter_4_5 == false then
				var_4_3[iter_4_4]:removeAllChildren()
				arg_3_0:_unloadSource(iter_4_4)
			end
		end
	end, 0)
end

local function var_0_5()
	return (ccui.Layout:create())
end

local function var_0_6(arg_6_0, arg_6_1)
	local var_6_0 = var_0_1.getItems(arg_6_0)
	local var_6_1 = #var_6_0

	for iter_6_0 = arg_6_0._headIndex, arg_6_0._tailIndex do
		var_6_0[iter_6_0]:removeAllChildren()
		arg_6_0:_unloadSource(iter_6_0)
	end

	arg_6_0._headIndex = 0
	arg_6_0._tailIndex = -1
	arg_6_0._innerP = nil

	var_0_1.removeAllItems(arg_6_0)

	for iter_6_1 = 1, arg_6_1 do
		local var_6_2 = var_0_5()

		var_6_2:setContentSize(arg_6_0:_sizeSource(iter_6_1))
		var_0_1.pushBackCustomItem(arg_6_0, var_6_2)
	end
end

local function var_0_7(arg_7_0, arg_7_1)
	local var_7_0 = var_0_5()

	var_7_0:setContentSize(arg_7_0:_sizeSource(arg_7_1))
	var_0_1.insertCustomItem(arg_7_0, var_7_0, arg_7_1 - 1)

	if arg_7_1 > arg_7_0._tailIndex then
		return
	end

	if arg_7_1 <= arg_7_0._headIndex then
		arg_7_1 = arg_7_0._headIndex
	end

	var_0_1.getItem(arg_7_0, arg_7_1 - 1):addChild(arg_7_0:_loadSource(arg_7_1))

	arg_7_0._tailIndex = arg_7_0._tailIndex + 1
end

local function var_0_8(arg_8_0, arg_8_1)
	var_0_1.removeItem(arg_8_0, arg_8_1 - 1)

	if arg_8_1 > arg_8_0._tailIndex then
		return
	end

	if arg_8_1 < arg_8_0._headIndex then
		arg_8_0._headIndex = arg_8_0._headIndex - 1
	else
		arg_8_0:_unloadSource(arg_8_1)
	end

	local var_8_0 = var_0_1.getItem(arg_8_0, arg_8_0._tailIndex - 1)

	if var_8_0 then
		var_8_0:addChild(arg_8_0:_loadSource(arg_8_0._tailIndex))
	else
		arg_8_0._tailIndex = arg_8_0._tailIndex - 1
	end
end

function var_0_0.attachTo(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	arg_9_0._sizeSource = arg_9_1

	function arg_9_0._loadSource(arg_10_0, arg_10_1)
		local var_10_0 = arg_9_2(arg_10_0, arg_10_1)

		var_10_0:ignoreAnchorPointForPosition(false)
		var_10_0:setAnchorPoint(cc.p(0, 0))
		var_10_0:pos(0, 0)

		return var_10_0
	end

	arg_9_0._unloadSource = arg_9_3

	if arg_9_0._headIndex then
		return
	end

	local var_9_0 = arg_9_0:getContentSize()

	arg_9_0._checkOffsetX = var_9_0.width / 2
	arg_9_0._checkOffsetY = var_9_0.height / 2
	arg_9_0._checkWidth = var_9_0.width * 2
	arg_9_0._checkHeight = var_9_0.height * 2
	arg_9_0._headIndex = 0
	arg_9_0._tailIndex = -1

	local function var_9_1()
		assert(nil, "The ListView method is protected by TableView")
	end

	arg_9_0.pushBackDefaultItem = var_9_1
	arg_9_0.insertDefaultItem = var_9_1
	arg_9_0.pushBackCustomItem = var_9_1
	arg_9_0.insertCustomItem = var_9_1
	arg_9_0.removeLastItem = var_9_1
	arg_9_0.removeItem = var_9_1
	arg_9_0.removeAllItems = var_9_1
	arg_9_0.getItem = var_9_1
	arg_9_0.getItems = var_9_1
	arg_9_0.getIndex = var_9_1
	arg_9_0.jumpTo = var_0_4
	arg_9_0.initDefaultItems = var_0_6
	arg_9_0.insertRow = var_0_7
	arg_9_0.deleteRow = var_0_8

	arg_9_0:addScrollViewEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 >= 4 then
			arg_12_0:performWithDelay(function()
				var_0_3(arg_12_0)
			end, 0)
		end

		if arg_12_0._scrollCB then
			arg_12_0:_scrollCB(arg_12_1)
		end
	end)

	function arg_9_0.addScrollViewEventListener(arg_14_0, arg_14_1)
		arg_14_0._scrollCB = arg_14_1
	end
end

return var_0_0
