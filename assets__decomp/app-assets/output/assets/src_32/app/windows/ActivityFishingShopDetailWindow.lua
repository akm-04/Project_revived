local var_0_0 = class("ActivityFishingShopDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.item
local var_0_5 = xyd.tables.misc:getValue("activity_fishing_coin_item_id")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.idx = arg_1_2.idx
	arg_1_0.itemID = arg_1_2.item_id
	arg_1_0.itemNum = arg_1_2.item_num
	arg_1_0.maxNum = arg_1_2.max_num
	arg_1_0.leftNum = arg_1_2.left_num
	arg_1_0.price = arg_1_2.price
	arg_1_0.costType = arg_1_2.cost_type
	arg_1_0.currentNum = math.min(1, arg_1_0.maxNum)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_have1"):setString(var_0_3:translation("ACTIVITY_FISHING_TEXT_23"))
	arg_4_0:nodeByName("txt_have2"):setString(var_0_3:translation("ACTIVITY_FISHING_TEXT_24"))
	arg_4_0:nodeByName("txt_select"):setString(var_0_3:translation("ACTIVITY_FISHING_TEXT_25"))
	arg_4_0:nodeByName("txt_max"):setString(var_0_3:translation("ACTIVITY_FISHING_TEXT_26"))
	arg_4_0:nodeByName("txt_total"):setString(var_0_3:translation("ACTIVITY_FISHING_TEXT_27"))
	arg_4_0:nodeByName("txt_buy"):setString(var_0_3:translation("ACTIVITY_FISHING_TEXT_28"))
	var_0_1.new({
		size = 402
	}):addTo(arg_4_0:nodeByName("pos_line"))
	xyd.setItemAndAddTips(arg_4_0:nodeByName("item"), arg_4_0.itemID, arg_4_0.itemNum)
	arg_4_0:updateNum()

	local var_4_0 = arg_4_0.backpack:getItemNumByID(arg_4_0.itemID)

	arg_4_0:nodeByName("txt_have_num"):setString(var_4_0)
	arg_4_0:nodeByName("txt_name"):setString(var_0_4:name(arg_4_0.itemID))

	local var_4_1 = xyd.tables.ecoType:getEcoPathByID(arg_4_0.costType)

	if var_4_1 then
		arg_4_0:nodeByName("coin"):setTexture(var_4_1)
	end

	xyd.nodeEventSample(arg_4_0:nodeByName("btn_max"), nil, function()
		arg_4_0.currentNum = arg_4_0.maxNum

		arg_4_0:updateNum()
	end)

	local var_4_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_4_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_2:setScale(1, 1)
	var_4_2:addTo(arg_4_0:nodeByName("btn_sub"))
	var_4_2:setName("jiandian")

	local var_4_3 = false

	var_4_2:onButtonPressed(function(arg_6_0)
		local var_6_0 = 0

		local function var_6_1()
			var_6_0 = var_6_0 + 0.03

			if arg_4_0.decreaseCurrentNum then
				arg_4_0:decreaseCurrentNum()
			end
		end

		local function var_6_2()
			var_6_0 = var_6_0 + 0.1

			if var_6_0 > 0.5 and var_6_0 <= 4 then
				var_4_3 = true

				if arg_4_0.decreaseCurrentNum then
					arg_4_0:decreaseCurrentNum()
				end
			elseif var_6_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_6_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_3 = false
			end
		end

		var_4_3 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_6_2, 0.1)
	end)
	var_4_2:onButtonRelease(function(arg_9_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_3 == false and arg_4_0.decreaseCurrentNum then
			arg_4_0:decreaseCurrentNum()
		end
	end)

	local var_4_4 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_4_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_4:setScale(1, 1)
	var_4_4:addTo(arg_4_0:nodeByName("btn_add"))
	var_4_4:setName("jiadian")

	local var_4_5 = false

	var_4_4:onButtonPressed(function(arg_10_0)
		local var_10_0 = 0

		local function var_10_1()
			var_10_0 = var_10_0 + 0.03

			if arg_4_0.addCurrentNum then
				arg_4_0:addCurrentNum()
			end
		end

		local function var_10_2()
			var_10_0 = var_10_0 + 0.1

			if var_10_0 > 0.5 and var_10_0 <= 4 then
				var_4_5 = true

				if arg_4_0.addCurrentNum then
					arg_4_0:addCurrentNum()
				end
			elseif var_10_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_10_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_5 = false
			end
		end

		var_4_5 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_10_2, 0.1)
	end)
	var_4_4:onButtonRelease(function(arg_13_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_5 == false and arg_4_0.addCurrentNum then
			arg_4_0:addCurrentNum()
		end
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_buy"), nil, function()
		if arg_4_0.currentNum == 0 then
			if arg_4_0.costType == 1 then
				xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("JINBI_ABSENCE"), function()
					local var_15_0 = xyd.FunctionID.ID_GOLD_HAND

					if arg_4_0.selfPlayer:isFuncOpen(var_15_0) == true then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
						arg_4_0:close()
					else
						local var_15_1 = xyd.tables.functionOpen:level(var_15_0)
						local var_15_2 = string.format(var_0_3:translation("FUNCTION_OPEN_TIP_LEVEL"), var_15_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_15_2
						})
					end
				end, nil, nil, arg_4_0.colorMode)

				return
			elseif arg_4_0.costType == 2 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
					local var_16_0 = {}

					var_16_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
					arg_4_0:close()
				end, nil, nil, arg_4_0.colorMode)

				return
			else
				local var_14_0 = var_0_3:translation("ACTIVITY_FISHING_TEXT_29")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_14_0
				})

				return
			end
		end

		local var_14_1 = {
			id = arg_4_0.idx,
			num = arg_4_0.currentNum
		}

		xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_BUY_ITEM, var_14_1, function(arg_17_0, arg_17_1)
			if arg_17_0 == xyd.error.OK then
				arg_4_0.selfPlayer:handleRewards(arg_17_1.awards)

				if arg_4_0.costType > 1000 then
					local var_17_0 = {
						itemID = var_0_5,
						itemNum = arg_4_0.currentNum * arg_4_0.price
					}

					arg_4_0.backpack:removeItem(var_17_0)
				end

				if arg_4_0.callback then
					arg_4_0.callback(var_14_1)
				end

				arg_4_0:close()
			end
		end)
	end)
end

function var_0_0.decreaseCurrentNum(arg_18_0)
	if arg_18_0.currentNum - 1 <= 0 then
		return
	else
		arg_18_0.currentNum = arg_18_0.currentNum - 1
	end

	arg_18_0:updateNum()
end

function var_0_0.addCurrentNum(arg_19_0)
	if arg_19_0.currentNum >= arg_19_0.maxNum then
		return
	else
		arg_19_0.currentNum = arg_19_0.currentNum + 1
	end

	arg_19_0:updateNum()
end

function var_0_0.updateNum(arg_20_0)
	arg_20_0:nodeByName("txt_buy_num"):setString(arg_20_0.currentNum .. "/" .. arg_20_0.maxNum)
	arg_20_0:nodeByName("txt_cost"):setString(arg_20_0.currentNum * arg_20_0.price)
end

return var_0_0
