local var_0_0 = class("FifthAnniGachaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.fifthAnniGacha
local var_0_3 = xyd.tables.gift
local var_0_4 = xyd.tables.misc
local var_0_5 = import("framework.scheduler")
local var_0_6 = var_0_4:getValue("fifth_anni_gacha_item")
local var_0_7 = var_0_4:getValue("fifth_anni_gacha_pool_pick_nums")
local var_0_8 = var_0_4:getValue("fifth_anni_gacha_item_price")
local var_0_9 = var_0_4:getValue("fifth_anni_gacha_reset_item")
local var_0_10 = 3
local var_0_11 = 86
local var_0_12 = 69
local var_0_13 = 10
local var_0_14 = 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.selectItems = {}

	for iter_1_0 = 1, var_0_10 do
		arg_1_0.selectItems[iter_1_0] = arg_1_0.model:getPoolItems(iter_1_0)
	end
end

function var_0_0.willOpen(arg_2_0)
	local var_2_0 = {
		ecoCount = 2,
		show_rule = 1,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_6,
			2
		},
		ecoIcons = {
			"windows/activities/1232/gacha/coin.png",
			-1
		},
		ecoIsAdd = {
			true,
			true
		},
		ecoAddCallback = {
			handler(arg_2_0, arg_2_0.buyCoin)
		}
	}

	arg_2_0:addTopSidebar(var_2_0)
	arg_2_0:setButtonClick()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_tips"):setString(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_1"))
	arg_3_0:nodeByName("txt_tips"):getVirtualRenderer():setLineHeight(30)

	for iter_3_0 = 1, var_0_10 do
		arg_3_0:updatePoolItems(iter_3_0)
	end

	arg_3_0:initNormalPoolItems()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("btn_one"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0
			local var_5_1 = arg_4_0.backpack:getItemNumByID(var_0_6)

			if not arg_4_0.model:isGachaLock() then
				var_5_0 = var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_5")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_5_0
				})

				return
			end

			if var_5_1 >= 1 then
				var_5_0 = string.format(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_2"), 1, 1)
			elseif arg_4_0.selfPlayer.crystal >= var_0_8 then
				var_5_0 = string.format(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_3"), var_0_8, 1)
			else
				local var_5_2 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_2, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, arg_4_0.colorMode)

				return
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_0, function()
				arg_4_0.model:gachaDrawPool({
					draw_time = 1
				}, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						if var_5_1 >= 1 then
							arg_4_0.backpack:addItemsByID(var_0_6, -1)
						end

						arg_4_0.selfPlayer:handleRewards(arg_8_1.awards)
						arg_4_0:nodeByName("eco_sidebar"):update({
							true
						})
					end
				end)
			end)
		end
	end)
	arg_4_0:nodeByName("btn_ten"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0
			local var_9_1 = arg_4_0.backpack:getItemNumByID(var_0_6)

			if not arg_4_0.model:isGachaLock() then
				var_9_0 = var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_5")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_0
				})

				return
			end

			if var_9_1 >= 10 then
				var_9_0 = string.format(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_2"), 10, 10)
			elseif arg_4_0.selfPlayer.crystal >= (10 - var_9_1) * var_0_8 then
				if var_9_1 == 0 then
					var_9_0 = string.format(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_3"), 10 * var_0_8, 10)
				else
					var_9_0 = string.format(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_4"), var_9_1, (10 - var_9_1) * var_0_8, 10)
				end
			else
				local var_9_2 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_2, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, arg_4_0.colorMode)

				return
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
				arg_4_0.model:gachaDrawPool({
					draw_time = 10
				}, function(arg_12_0, arg_12_1)
					if arg_12_0 == xyd.error.OK then
						if var_9_1 >= 10 then
							arg_4_0.backpack:addItemsByID(var_0_6, -10)
						elseif var_9_1 > 0 then
							arg_4_0.backpack:addItemsByID(var_0_6, -var_9_1)
						end

						arg_4_0.selfPlayer:handleRewards(arg_12_1.awards)
						arg_4_0:nodeByName("eco_sidebar"):update({
							true
						})
					end
				end)
			end)
		end
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_lock"), nil, function()
		local var_13_0

		if arg_4_0.model:isGachaLock() then
			local var_13_1 = var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_18")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_13_1
			})

			return
		end

		for iter_13_0 = 1, var_0_10 do
			if #arg_4_0.selectItems[iter_13_0] < var_0_7[iter_13_0] then
				local var_13_2 = var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_6")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_13_2
				})

				return
			end
		end

		local var_13_3 = {}

		for iter_13_1 = 1, var_0_10 do
			var_13_3["pool_" .. iter_13_1] = table.concat(arg_4_0.selectItems[iter_13_1], "|")
		end

		local var_13_4 = var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_7")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_13_4, function()
			arg_4_0.model:gachaLockPool(var_13_3)
		end)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_refresh"), nil, function()
		local var_15_0

		if not arg_4_0.model:isGachaLock() then
			local var_15_1 = var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_5")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_15_1
			})

			return
		end

		local var_15_2 = arg_4_0.backpack:getItemNumByID(var_0_9)

		if var_15_2 < 1 then
			local var_15_3 = var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_9")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_15_3
			})

			return
		end

		local var_15_4 = string.format(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_8"), var_15_2)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_4, function()
			arg_4_0.model:gachaRefreshPool(nil, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					for iter_17_0 = 1, var_0_10 do
						arg_4_0.selectItems[iter_17_0] = {}

						arg_4_0:updatePoolItems(iter_17_0)
					end
				end
			end)
		end)
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function()
		local var_18_0 = {
			title_name = "FIFTH_ANNI_GACHA_RULE_TITLE",
			rule = "FIFTH_ANNI_GACHA_RULE_TEXT"
		}

		xyd.WindowManager.get():openWindow("new_text_rule", var_18_0)
	end)
end

function var_0_0.updatePoolItems(arg_19_0, arg_19_1)
	local var_19_0 = arg_19_0:nodeByName("pool_items_" .. arg_19_1)
	local var_19_1 = var_0_7[arg_19_1]

	var_19_0:removeAllChildren()

	if var_19_1 <= 0 then
		return
	end

	for iter_19_0 = 1, var_19_1 do
		local var_19_2 = display.newNode()

		var_19_2:setContentSize(var_0_11, var_0_11)
		var_19_2:setAnchorPoint(0.5, 0.5)
		var_19_2:setPosition((2 * iter_19_0 - var_19_1 - 1) / 2 * (var_0_12 + var_0_11), 0)

		if arg_19_0.selectItems[arg_19_1][iter_19_0] then
			local var_19_3 = var_0_2:giftId(arg_19_0.selectItems[arg_19_1][iter_19_0])

			xyd.setItemAndAddTips(var_19_2, var_0_3:items(var_19_3)[1], var_0_3:itemNum(var_19_3)[1])
		else
			arg_19_0:setNullItem(var_19_2, arg_19_1)
		end

		var_19_2:setTouchEnabled(true)
		var_19_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
			if arg_20_0.name == "began" then
				return true
			elseif arg_20_0.name == "ended" then
				if arg_19_0.model:isGachaLock() then
					return
				end

				local var_20_0 = var_19_2:convertToNodeSpace(cc.p(arg_20_0.x, arg_20_0.y))

				if var_20_0.x < 0 or var_20_0.x > var_0_11 or var_20_0.y < 0 or var_20_0.y > var_0_11 then
					return
				end

				local var_20_1 = {
					pool = arg_19_1,
					num = var_0_7[arg_19_1],
					selectItems = arg_19_0.selectItems[arg_19_1],
					callback = handler(arg_19_0, arg_19_0.onSelect)
				}

				xyd.WindowManager.get():openWindow("fifth_anni_gacha_select", var_20_1)
			end
		end)
		var_19_0:addChild(var_19_2)
	end
end

function var_0_0.initNormalPoolItems(arg_21_0)
	local var_21_0 = arg_21_0:nodeByName("list")
	local var_21_1 = var_21_0:getContentSize()
	local var_21_2 = var_0_2:getPoolItems(4)

	arg_21_0.list = cc.ui.UITableView.new({
		itemGap = 50,
		size = var_21_1,
		direction = cc.ui.UITableView.DIRECTION_HORIZONTAL
	}):addTo(var_21_0):onScroll(handler(arg_21_0, arg_21_0.scrollListener))

	for iter_21_0, iter_21_1 in ipairs(var_21_2) do
		local var_21_3 = arg_21_0.list:newItem()
		local var_21_4 = display.newNode()
		local var_21_5 = var_0_2:giftId(iter_21_1)

		var_21_4:setContentSize(var_0_11, var_0_11)
		var_21_4:setAnchorPoint(0.5, 0.5)
		var_21_4:setNormalizedPosition(cc.p(0.5, 0.5))
		xyd.setItemAndAddTips(var_21_4, var_0_3:items(var_21_5)[1], var_0_3:itemNum(var_21_5)[1])
		var_21_3:addContent(var_21_4)
		var_21_3:setItemSize(var_21_1.height, var_21_1.height)
		arg_21_0.list:addItem(var_21_3)
	end

	arg_21_0.list:reload()
	arg_21_0:createListAction()
end

function var_0_0.onSelect(arg_22_0, arg_22_1, arg_22_2)
	arg_22_0.selectItems[arg_22_1] = arg_22_2

	arg_22_0:updatePoolItems(arg_22_1)
end

function var_0_0.createListAction(arg_23_0)
	local var_23_0 = arg_23_0.list.scrollNode
	local var_23_1 = arg_23_0.list.size.width - arg_23_0.list.total
	local var_23_2 = var_23_0:getPositionX()

	if var_23_1 >= 0 then
		return
	end

	transition.stopTarget(var_23_0)

	local var_23_3 = cc.Sequence:create(cc.MoveBy:create(math.abs(var_23_1 - var_23_2) / var_0_13, cc.p(var_23_1 - var_23_2, 0)), cc.CallFunc:create(function()
		local var_24_0 = cc.MoveBy:create(math.abs(var_23_1) / var_0_13, cc.p(-var_23_1, 0))
		local var_24_1 = cc.RepeatForever:create(cc.Sequence:create(var_24_0, var_24_0:reverse()))

		var_23_0:runAction(var_24_1)
	end))

	var_23_0:runAction(var_23_3)
end

function var_0_0.scrollListener(arg_25_0, arg_25_1)
	if arg_25_1.name == "began" then
		arg_25_0.waitingTime = 0
	elseif arg_25_1.name == "ended" or arg_25_1.name == "clicked" then
		if arg_25_0.handle then
			var_0_5.unscheduleGlobal(arg_25_0.handle)

			arg_25_0.handle = nil
		end

		arg_25_0.handle = var_0_5.scheduleGlobal(function()
			if not arg_25_0.list.isMoving_ then
				arg_25_0.waitingTime = arg_25_0.waitingTime + 1

				if arg_25_0.waitingTime > var_0_14 then
					var_0_5.unscheduleGlobal(arg_25_0.handle)
					arg_25_0:createListAction()
				end
			end
		end, 1)
	end
end

function var_0_0.setNullItem(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = xyd.AssetLoader.get():loadSprite("windows/activities/1232/gacha/egg_" .. arg_27_2 .. ".png")
	local var_27_1 = xyd.createLabel(22, cc.c3b(255, 255, 255))

	var_27_1:setAnchorPoint(0.5, 0.5)
	var_27_1:setString(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_10"))
	var_27_1:enableOutline(cc.c4b(131, 57, 134, 255), 2)
	var_27_1:setPosition(52, 12)
	var_27_0:addChild(var_27_1)
	var_27_0:setNormalizedPosition(cc.p(0.5, 0.5))
	arg_27_1:addChild(var_27_0)
end

function var_0_0.buyCoin(arg_28_0)
	local var_28_0 = string.format(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_17"), var_0_8)
	local var_28_1 = {
		lcallBefore = 0,
		touchClose = true,
		leftName = var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_11"),
		rightName = var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_12"),
		lcallback = function()
			if arg_28_0.selfPlayer.crystal < var_0_8 then
				local var_29_0 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_29_0, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, arg_28_0.colorMode)
			else
				arg_28_0.model:gachaBuyDrawItem({
					num = 1
				}, function(arg_31_0, arg_31_1)
					if arg_31_0 == xyd.error.OK then
						arg_28_0.backpack:addItemsByID(var_0_6, 1)
						arg_28_0:nodeByName("eco_sidebar"):update({
							true
						})
					end
				end)
			end
		end
	}

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_28_0, function()
		if arg_28_0.selfPlayer.crystal < 10 * var_0_8 then
			local var_32_0 = var_0_1:translation("ZUANSHI_ABSENCE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_32_0, function()
				xyd.WindowManager.get():openWindow("vip_recharge")
			end, nil, nil, arg_28_0.colorMode)
		else
			arg_28_0.model:gachaBuyDrawItem({
				num = 10
			}, function(arg_34_0, arg_34_1)
				if arg_34_0 == xyd.error.OK then
					arg_28_0.backpack:addItemsByID(var_0_6, 10)
					arg_28_0:nodeByName("eco_sidebar"):update({
						true
					})
				end
			end)
		end
	end, var_28_1, 0, xyd.ColorMode.ACTIVITY)
end

function var_0_0.willClose(arg_35_0)
	if arg_35_0.handle then
		var_0_5.unscheduleGlobal(arg_35_0.handle)

		arg_35_0.handle = nil
	end
end

return var_0_0
