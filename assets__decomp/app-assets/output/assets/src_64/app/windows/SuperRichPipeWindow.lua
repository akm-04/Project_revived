local var_0_0 = class("SuperRichPipeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "windows/zillionaire/pipe/"
local var_0_3 = {
	{
		[2] = cc.p(0, -1),
		[4] = cc.p(0, 1)
	},
	{
		cc.p(1, 0),
		[3] = cc.p(-1, 0)
	},
	{
		[2] = cc.p(1, 0),
		[3] = cc.p(0, 1)
	},
	{
		[3] = cc.p(0, -1),
		[4] = cc.p(1, 0)
	},
	{
		[4] = cc.p(-1, 0),
		(cc.p(0, -1))
	},
	{
		cc.p(0, 1),
		(cc.p(-1, 0))
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.length = xyd.tables.misc.activityRichWaterPipe
	arg_1_0.pixLength = 101
	arg_1_0.info = {}

	arg_1_0:initInfo()

	arg_1_0.page = 1
	arg_1_0.pos = arg_1_2.pos
	arg_1_0.gridInfo = arg_1_2.info
	arg_1_0.stationType = arg_1_2.grid_type
end

function var_0_0.initInfo(arg_2_0)
	arg_2_0.info = {}
	arg_2_0.info.length = 6
	arg_2_0.info.lineInfo = arg_2_0:randomDoorPosition()
	arg_2_0.info.pipeInfo = {}

	arg_2_0:initOwnItems()
end

function var_0_0.initOwnItems(arg_3_0)
	arg_3_0.pipeIds = {}

	local var_3_0 = arg_3_0.superRich.pipeInfo.pipe_nums

	for iter_3_0 = 1, #var_3_0 do
		for iter_3_1 = 1, var_3_0[iter_3_0] do
			table.insert(arg_3_0.pipeIds, iter_3_0)
		end
	end
end

function var_0_0.update(arg_4_0)
	arg_4_0:initInfo()
	arg_4_0:initPipeBg()
	arg_4_0:updateInOut()
	arg_4_0:initItems()
	arg_4_0:updateArrow()
end

function var_0_0.willOpen(arg_5_0, arg_5_1)
	var_0_0.super.willOpen(arg_5_0, arg_5_1)
	arg_5_0:layout()
end

function var_0_0.layout(arg_6_0)
	arg_6_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_7_0)
	arg_7_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_8_0 = {
				giftId = xyd.tables.misc.activityRichWaterPipeReward,
				text = var_0_1:translation("ACTIVITY_RICH_WATER_RULE_TEXT")
			}

			xyd.WindowManager.get():openWindow("super_rich_rule", var_8_0)
		end
	end)
	arg_7_0:nodeByName("right_arrow"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_7_0.page = arg_7_0.page + 1

			if arg_7_0.page > arg_7_0:getMaxPage() then
				arg_7_0.page = arg_7_0:getMaxPage()
			end

			arg_7_0:updateArrow()
		end
	end)
	arg_7_0:nodeByName("left_arrow"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_7_0.page = arg_7_0.page - 1

			if arg_7_0.page < 1 then
				arg_7_0.page = 1
			end

			arg_7_0:updateArrow()
		end
	end)

	local function var_7_0(arg_11_0)
		local var_11_0 = {
			grid_type = arg_7_0.stationType,
			pos = arg_7_0.pos,
			idx = arg_11_0
		}

		arg_7_0.superRich:monopolyUseCard(var_11_0, function(arg_12_0, arg_12_1)
			if arg_12_0 == xyd.error.OK then
				table.insert(arg_7_0.pipeIds, arg_11_0)
				arg_7_0:addItem(#arg_7_0.pipeIds)
				arg_7_0:updateArrow()
			end
		end)
	end

	arg_7_0:nodeByName("backpack_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_13_0()
				local var_14_0 = {
					callback = var_7_0
				}

				xyd.WindowManager.get():openWindow("super_rich_select_pipe", var_14_0)
			end

			local var_13_1 = {
				callback = var_13_0,
				use_type = {
					0,
					1,
					0
				}
			}
			local var_13_2 = xyd.WindowManager.get():openWindow("super_rich_backpack", var_13_1)

			var_13_2:setPosition(cc.p(1160, 120))
			var_13_2:addBlockLayer(cc.c4b(0, 0, 0, 0))
		end
	end)
	arg_7_0:update()
end

function var_0_0.updateArrow(arg_15_0)
	arg_15_0:nodeByName("left_arrow"):setVisible(true)
	arg_15_0:nodeByName("right_arrow"):setVisible(true)

	if arg_15_0.page >= arg_15_0:getMaxPage() then
		arg_15_0:nodeByName("right_arrow"):setVisible(false)
	end

	if arg_15_0.page <= 1 then
		arg_15_0:nodeByName("left_arrow"):setVisible(false)
	end

	arg_15_0:updateItems()
end

function var_0_0.getMaxPage(arg_16_0, ...)
	return math.ceil(#arg_16_0:getItems() / 9)
end

function var_0_0.updateInOut(arg_17_0)
	local function var_17_0(arg_18_0, arg_18_1)
		local var_18_0 = 29
		local var_18_1 = 5.5
		local var_18_2 = xyd.AssetLoader.get():loadSprite(var_0_2 .. "enter_gray.png")

		var_18_2.lightPath = var_0_2 .. "enter.png"

		if arg_18_0 == 3 then
			var_18_2 = xyd.AssetLoader.get():loadSprite(var_0_2 .. "out_gray.png")
			var_18_2.lightPath = var_0_2 .. "out.png"
		end

		var_18_2:setAnchorPoint(cc.p(0.5, 0))
		var_18_2:addTo(arg_17_0:nodeByName("left_pos"))

		if arg_18_0 == 1 then
			var_18_2:setRotation(-90)
			var_18_2:setPosition(var_18_0, (arg_18_1 - 0.5) * arg_17_0.pixLength - var_18_1)
		elseif arg_18_0 == 2 then
			var_18_2:setPosition((arg_18_1 - 0.5) * arg_17_0.pixLength - var_18_1, arg_17_0.length * arg_17_0.pixLength - var_18_0)
		elseif arg_18_0 == 4 then
			var_18_2:setRotation(180)
			var_18_2:setPosition((arg_18_1 - 0.5) * arg_17_0.pixLength + var_18_1, var_18_0)
		elseif arg_18_0 == 3 then
			var_18_2:setAnchorPoint(cc.p(0, 1))
			var_18_2:setPosition(arg_17_0.length * arg_17_0.pixLength - var_18_0, arg_18_1 * arg_17_0.pixLength - var_18_1 + 3)
		end

		return var_18_2
	end

	local var_17_1 = arg_17_0.info.lineInfo

	arg_17_0.inPipe = var_17_0(var_17_1.startType, var_17_1.startPos)
	arg_17_0.outPipe = var_17_0(var_17_1.endType, var_17_1.endPos)
end

function var_0_0.initPipeBg(arg_19_0)
	arg_19_0:nodeByName("left_pos"):removeAllChildren()

	local var_19_0 = arg_19_0.length
	local var_19_1 = 101

	for iter_19_0 = 1, var_19_0 do
		for iter_19_1 = 1, var_19_0 do
			local var_19_2 = arg_19_0:getBoxIcon(iter_19_0, iter_19_1)

			var_19_2:addTo(arg_19_0:nodeByName("left_pos"))
			var_19_2:setPosition((iter_19_0 - 0.5) * var_19_1, (iter_19_1 - 0.5) * var_19_1)
		end
	end
end

function var_0_0.getBoxIcon(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_0.length
	local var_20_1 = {
		180,
		270,
		0,
		90
	}
	local var_20_2 = {
		"box.png",
		"box_line.png",
		"box_angle.png"
	}
	local var_20_3 = var_20_2[1]
	local var_20_4 = 0

	if (arg_20_1 == 1 or arg_20_1 == var_20_0) and (arg_20_2 == 1 or arg_20_2 == var_20_0) then
		var_20_3 = var_20_2[3]

		if arg_20_1 == 1 and arg_20_2 == 1 then
			var_20_4 = 180
		elseif arg_20_1 == 1 and arg_20_2 == var_20_0 then
			var_20_4 = 270
		elseif arg_20_1 == var_20_0 and arg_20_2 == 1 then
			var_20_4 = 90
		end
	elseif arg_20_1 == 1 or arg_20_1 == var_20_0 or arg_20_2 == 1 or arg_20_2 == var_20_0 then
		var_20_3 = var_20_2[2]

		if arg_20_1 == 1 then
			var_20_4 = 270
		elseif arg_20_1 == var_20_0 then
			var_20_4 = 90
		elseif arg_20_2 == 1 then
			var_20_4 = 180
		end
	end

	local var_20_5 = xyd.AssetLoader.get():loadSprite(var_0_2 .. var_20_3)

	var_20_5:setRotation(var_20_4)

	return var_20_5
end

function var_0_0.randomDoorPosition(arg_21_0)
	local var_21_0 = arg_21_0.length
	local var_21_1 = {}

	var_21_1.startType, var_21_1.startPos = arg_21_0:getTypeAndPos(arg_21_0.superRich.pipeInfo.begin_pos)
	var_21_1.endType, var_21_1.endPos = arg_21_0:getTypeAndPos(arg_21_0.superRich.pipeInfo.end_pos)

	return var_21_1
end

function var_0_0.getTypeAndPos(arg_22_0, arg_22_1)
	local var_22_0 = math.ceil(arg_22_1 / 6)
	local var_22_1 = arg_22_1 - (var_22_0 - 1) * 6

	if var_22_0 == 3 or var_22_0 == 4 then
		var_22_1 = 7 - var_22_1
	end

	return var_22_0, var_22_1
end

function var_0_0.initItems(arg_23_0)
	arg_23_0:nodeByName("item_pos"):removeAllChildren(true)
	arg_23_0:nodeByName("item_pos"):setPosition(cc.p(892, 554))

	arg_23_0.pipeItems = {}

	local var_23_0 = arg_23_0:getItems()

	for iter_23_0 = 1, #var_23_0 do
		arg_23_0:addItem(iter_23_0)
	end

	arg_23_0:updateItems()
end

function var_0_0.addItem(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_0:getItems()[arg_24_1]
	local var_24_1 = arg_24_0:createItem(var_24_0)

	var_24_1:retain()
	var_24_1:setTouchEnabled(true)
	var_24_1:setTouchSwallowEnabled(false)

	var_24_1.itemId = var_24_0

	var_24_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
		if arg_25_0.name == "began" then
			var_24_1:getChildByName("container"):getChildByName("item_bg"):setVisible(true)

			if arg_24_0.info.pipeInfo[var_24_1.key] then
				arg_24_0.info.pipeInfo[var_24_1.key] = nil
			end

			arg_24_0.itemPos = cc.p(var_24_1:getPosition())
			arg_24_0.orgPos = cc.p(arg_25_0.x, arg_25_0.y)

			var_24_1:setLocalZOrder(100)

			return true
		elseif arg_25_0.name == "moved" then
			local var_25_0 = xyd.subPosition(arg_25_0, arg_24_0.orgPos)
			local var_25_1 = xyd.addPosition(arg_24_0.itemPos, var_25_0)

			var_24_1:setPosition(var_25_1)

			return true
		elseif arg_25_0.name == "ended" then
			var_24_1:setLocalZOrder(0)

			local var_25_2 = arg_24_0:nodeByName("left_pos"):convertToNodeSpace(cc.p(arg_25_0.x, arg_25_0.y))

			targetX = math.floor(var_25_2.x / arg_24_0.pixLength) + 1
			targetY = math.floor(var_25_2.y / arg_24_0.pixLength) + 1
			var_24_1.key = arg_24_0:updateInfo(targetX, targetY, var_24_1)

			if not var_24_1.key then
				var_24_1:removeFromParent(false)
				var_24_1:addTo(arg_24_0:nodeByName("item_pos"))
				var_24_1:setPosition(var_24_1.orgPos)
				arg_24_0:updateItems()

				return
			else
				arg_24_0:updateItemByKey(var_24_1)
			end
		end
	end)
	var_24_1:addTo(arg_24_0:nodeByName("item_pos"))

	local var_24_2 = math.floor((arg_24_1 - 1) / 9) + 1
	local var_24_3 = (arg_24_1 - 1) % 9 + 1

	var_24_1:setPosition((var_24_3 - 1) % 3 * 133, -math.floor((var_24_3 - 1) / 3) * 115)

	var_24_1.orgPos = cc.p(var_24_1:getPosition())
	var_24_1.page = var_24_2

	table.insert(arg_24_0.pipeItems, var_24_1)
end

function var_0_0.updateItems(arg_26_0)
	for iter_26_0, iter_26_1 in pairs(arg_26_0.pipeItems) do
		if iter_26_1.page == arg_26_0.page or iter_26_1.key then
			iter_26_1:setVisible(true)
		else
			iter_26_1:setVisible(false)
		end
	end
end

function var_0_0.updateItemByKey(arg_27_0, arg_27_1)
	local var_27_0 = xyd.splitToNumber(arg_27_1.key, "@")
	local var_27_1 = var_27_0[1]
	local var_27_2 = var_27_0[2]

	arg_27_1:removeFromParent(false)
	arg_27_1:addTo(arg_27_0:nodeByName("left_pos"))
	arg_27_1:setPosition((var_27_1 - 0.5) * arg_27_0.pixLength, (var_27_2 - 0.5) * arg_27_0.pixLength)
	arg_27_1:getChildByName("container"):getChildByName("item_bg"):setVisible(false)
end

function var_0_0.updateInfo(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	if arg_28_1 < 1 or arg_28_1 > arg_28_0.length or arg_28_2 < 1 or arg_28_2 > arg_28_0.length then
		return
	end

	local var_28_0 = tostring(arg_28_1) .. "@" .. tostring(arg_28_2)

	if arg_28_0.info.pipeInfo[var_28_0] then
		return
	else
		arg_28_0.info.pipeInfo[var_28_0] = arg_28_3
		arg_28_3.key = var_28_0
	end

	if arg_28_0:isConnected() then
		arg_28_0:showSuceess()
	end

	return var_28_0
end

function var_0_0.getNextInfo(arg_29_0, arg_29_1)
	local var_29_0 = arg_29_1.key
	local var_29_1 = arg_29_0.info.pipeInfo
	local var_29_2 = arg_29_1.lineType
	local var_29_3 = var_29_1[var_29_0]

	if not var_29_3 then
		return
	end

	local var_29_4 = var_29_3.itemId
	local var_29_5 = arg_29_0:getDeltaInfo(var_29_4, var_29_2)

	if not var_29_5 then
		return
	end

	local var_29_6 = xyd.splitToNumber(var_29_3.key, "@")
	local var_29_7 = cc.p(var_29_6[1], var_29_6[2])
	local var_29_8 = xyd.addPosition(var_29_7, var_29_5.delta)

	return {
		key = tostring(var_29_8.x) .. "@" .. tostring(var_29_8.y),
		lineType = var_29_5.lineType,
		lastItem = var_29_3
	}
end

function var_0_0.isConnected(arg_30_0)
	arg_30_0.items = {}

	local var_30_0 = arg_30_0.info.lineInfo
	local var_30_1 = arg_30_0.info.pipeInfo
	local var_30_2 = arg_30_0:getInOutNeedInfo(var_30_0.startType, var_30_0.startPos, false)
	local var_30_3 = arg_30_0:getInOutNeedInfo(var_30_0.endType, var_30_0.endPos, true)

	while true do
		local var_30_4 = arg_30_0:getNextInfo(var_30_2)

		if not var_30_4 then
			break
		end

		var_30_2 = var_30_4

		table.insert(arg_30_0.items, var_30_2.lastItem)
	end

	if var_30_2.key == var_30_3.key then
		for iter_30_0, iter_30_1 in pairs(arg_30_0.items) do
			local var_30_5 = iter_30_1:getChildByName("container")
			local var_30_6 = xyd.AssetLoader.get():loadSprite(var_0_2 .. "pipe_line.png")

			var_30_5:getChildByName("pip_line_gray"):setSpriteFrame(var_30_6:getSpriteFrame())

			local var_30_7 = xyd.AssetLoader.get():loadSprite(var_0_2 .. "pip_angle.png")

			var_30_5:getChildByName("pip_angle_gray"):setSpriteFrame(var_30_7:getSpriteFrame())
		end

		arg_30_0.inPipe:setSpriteFrame(xyd.AssetLoader.get():loadSprite(arg_30_0.inPipe.lightPath):getSpriteFrame())
		arg_30_0.outPipe:setSpriteFrame(xyd.AssetLoader.get():loadSprite(arg_30_0.outPipe.lightPath):getSpriteFrame())

		return true
	end

	return false
end

function var_0_0.getInOutNeedInfo(arg_31_0, arg_31_1, arg_31_2, arg_31_3)
	local var_31_0

	if arg_31_1 == 1 then
		var_31_0 = "1" .. "@" .. arg_31_2

		if arg_31_3 then
			var_31_0 = "0" .. "@" .. arg_31_2
		end
	elseif arg_31_1 == 2 then
		var_31_0 = tostring(arg_31_2) .. "@" .. arg_31_0.length

		if arg_31_3 then
			var_31_0 = tostring(arg_31_2) .. "@" .. arg_31_0.length + 1
		end
	elseif arg_31_1 == 3 then
		var_31_0 = tostring(arg_31_0.length) .. "@" .. arg_31_2

		if arg_31_3 then
			var_31_0 = tostring(arg_31_0.length + 1) .. "@" .. arg_31_2
		end
	elseif arg_31_1 == 4 then
		var_31_0 = tostring(arg_31_2) .. "@" .. 1

		if arg_31_3 then
			var_31_0 = tostring(arg_31_2) .. "@" .. 0
		end
	end

	return {
		key = var_31_0,
		lineType = arg_31_1
	}
end

function var_0_0.getDeltaInfo(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = {}
	local var_32_1 = var_0_3[arg_32_1]

	if not var_32_1[arg_32_2] then
		return
	end

	for iter_32_0, iter_32_1 in pairs(var_32_1) do
		if iter_32_0 == arg_32_2 then
			var_32_0.delta = iter_32_1
		else
			var_32_0.lineType = (iter_32_0 - 1 + 2) % 4 + 1
		end
	end

	return var_32_0
end

function var_0_0.showSuceess(arg_33_0)
	local var_33_0 = {
		pipe_nums = {
			0,
			0,
			0,
			0,
			0,
			0
		}
	}

	for iter_33_0, iter_33_1 in pairs(arg_33_0.items) do
		var_33_0.pipe_nums[iter_33_1.itemId] = var_33_0.pipe_nums[iter_33_1.itemId] + 1
	end

	arg_33_0.superRich:monopolyPipeLink(var_33_0, function(arg_34_0, arg_34_1)
		if arg_34_0 == xyd.error.OK then
			arg_33_0.page = 1

			arg_33_0:update()
		end
	end)
end

function var_0_0.createItem(arg_35_0, arg_35_1)
	local var_35_0 = xyd.AssetLoader.get():loadNodeFromJson(var_0_2 .. "item.csb")
	local var_35_1 = var_35_0:getChildByName("container")

	var_35_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_35_1:getChildByName("item_bg"):setVisible(true)

	if arg_35_1 == 1 or arg_35_1 == 2 then
		var_35_1:getChildByName("pip_line_gray"):setVisible(true)
		var_35_0:setRotation(90 * (arg_35_1 - 1))
	else
		var_35_1:getChildByName("pip_angle_gray"):setVisible(true)
		var_35_0:setRotation(90 * (arg_35_1 - 3))
	end

	return var_35_0
end

function var_0_0.getItems(arg_36_0)
	return arg_36_0.pipeIds
end

return var_0_0
