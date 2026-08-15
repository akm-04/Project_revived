local var_0_0 = class("FishGamblingShopDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.item
local var_0_5 = xyd.tables.misc:getValue("activity_fish_gambling_gold_coin")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.shop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.idx = arg_1_2.index
	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.itemNum = arg_1_2.itemNum
	arg_1_0.price = arg_1_2.sellPrice
	arg_1_0.buyTimes = arg_1_2.buyTimes
	arg_1_0.shopType = arg_1_2.shopType
	arg_1_0.sellType = arg_1_2.sellType

	if arg_1_0.sellType == xyd.currencyType.MANA then
		arg_1_0.maxNum = math.floor(arg_1_0.selfPlayer.mana / arg_1_0.price)
	elseif arg_1_0.sellType == xyd.currencyType.CRYSTAL then
		arg_1_0.maxNum = math.floor(arg_1_0.selfPlayer.crystal / arg_1_0.price)
	elseif arg_1_0.sellType == xyd.currencyType.FISH_GAMBLING_GOLD then
		arg_1_0.maxNum = math.floor(arg_1_0.backpack:getItemNumByID(var_0_5) / arg_1_0.price)
	end

	local var_1_0 = xyd.tables.shop:limitTimes(arg_1_0.shopType)[arg_1_0.idx]

	if var_1_0 and var_1_0 > 0 and arg_1_0.buyTimes then
		arg_1_0.maxNum = math.min(arg_1_0.maxNum, var_1_0 - arg_1_0.buyTimes)
	end

	arg_1_0.currentNum = math.min(1, arg_1_0.maxNum)
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

	local var_4_1 = arg_4_0:nodeByName("txt_have1"):getPositionX() + arg_4_0:nodeByName("txt_have1"):getContentSize().width

	arg_4_0:nodeByName("txt_have_num"):setAnchorPoint(0, 0.5)
	arg_4_0:nodeByName("txt_have_num"):setPositionX(var_4_1)

	local var_4_2 = var_4_1 + arg_4_0:nodeByName("txt_have_num"):getContentSize().width

	arg_4_0:nodeByName("txt_have2"):setAnchorPoint(0, 0.5)
	arg_4_0:nodeByName("txt_have2"):setPositionX(var_4_2)
	arg_4_0:nodeByName("txt_name"):setString(var_0_4:name(arg_4_0.itemID))

	if arg_4_0.sellType == xyd.currencyType.MANA then
		arg_4_0:nodeByName("coin"):setTexture("images/jinbi.png")
	elseif arg_4_0.sellType == xyd.currencyType.CRYSTAL then
		arg_4_0:nodeByName("coin"):setTexture("images/zuanshi.png")
	elseif arg_4_0.sellType == xyd.currencyType.FISH_GAMBLING_GOLD then
		arg_4_0:nodeByName("coin"):setTexture("windows/fish_gambling/fish_gold_coin.png")
		arg_4_0:nodeByName("coin"):setScale(0.5)
	end

	xyd.nodeEventSample(arg_4_0:nodeByName("btn_max"), nil, function()
		arg_4_0.currentNum = arg_4_0.maxNum

		arg_4_0:updateNum()
	end)

	local var_4_3 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_4_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_3:setScale(1, 1)
	var_4_3:addTo(arg_4_0:nodeByName("btn_sub"))
	var_4_3:setName("jiandian")

	local var_4_4 = false

	var_4_3:onButtonPressed(function(arg_6_0)
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
				var_4_4 = true

				if arg_4_0.decreaseCurrentNum then
					arg_4_0:decreaseCurrentNum()
				end
			elseif var_6_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_6_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_4 = false
			end
		end

		var_4_4 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_6_2, 0.1)
	end)
	var_4_3:onButtonRelease(function(arg_9_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_4 == false and arg_4_0.decreaseCurrentNum then
			arg_4_0:decreaseCurrentNum()
		end
	end)

	local var_4_5 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_4_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_5:setScale(1, 1)
	var_4_5:addTo(arg_4_0:nodeByName("btn_add"))
	var_4_5:setName("jiadian")

	local var_4_6 = false

	var_4_5:onButtonPressed(function(arg_10_0)
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
				var_4_6 = true

				if arg_4_0.addCurrentNum then
					arg_4_0:addCurrentNum()
				end
			elseif var_10_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_10_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_6 = false
			end
		end

		var_4_6 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_10_2, 0.1)
	end)
	var_4_5:onButtonRelease(function(arg_13_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_6 == false and arg_4_0.addCurrentNum then
			arg_4_0:addCurrentNum()
		end
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_buy"), nil, function()
		arg_4_0:buy()
	end)
end

function var_0_0.decreaseCurrentNum(arg_15_0)
	if arg_15_0.currentNum - 1 <= 0 then
		return
	else
		arg_15_0.currentNum = arg_15_0.currentNum - 1
	end

	arg_15_0:updateNum()
end

function var_0_0.addCurrentNum(arg_16_0)
	if arg_16_0.currentNum >= arg_16_0.maxNum then
		return
	else
		arg_16_0.currentNum = arg_16_0.currentNum + 1
	end

	arg_16_0:updateNum()
end

function var_0_0.updateNum(arg_17_0)
	arg_17_0:nodeByName("txt_buy_num"):setString(arg_17_0.currentNum .. "/" .. arg_17_0.maxNum)
	arg_17_0:nodeByName("txt_cost"):setString(arg_17_0.currentNum * arg_17_0.price)
end

function var_0_0.buy(arg_18_0)
	if arg_18_0.currentNum == 0 then
		local var_18_0 = var_0_3:translation("FISH_GAMBLING_SHOP_TIP")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_18_0
		})

		return
	end

	local var_18_1 = {
		index = arg_18_0.idx,
		shop_type = arg_18_0.shopType,
		num = arg_18_0.currentNum
	}

	arg_18_0.shop_:buy(var_18_1, function(arg_19_0)
		if arg_19_0 == xyd.error.OK then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.SHOP_DIALOG,
				messageType = xyd.ShopMessageType.BUY
			})
			arg_18_0.backpack:addItemsByID(var_0_5, -arg_18_0.price * arg_18_0.currentNum)

			local var_19_0 = xyd.WindowManager.get():getWindow("fish_gambling_shop")

			if var_19_0 and not tolua.isnull(var_19_0) then
				var_19_0:upadteEco()
			end

			local var_19_1 = xyd.WindowManager.get():getWindow("fish_gambling_main")

			if var_19_1 and not tolua.isnull(var_19_1) then
				var_19_1.hasNum = var_19_1.player_:getBackpack():getItemNumByID(var_19_1.itemID)
				var_19_1.maxNum = var_19_1.hasNum

				var_19_1:updateEco()
				var_19_1:reloadCardFish()
			end

			arg_18_0:close()
		end
	end)
end

return var_0_0
