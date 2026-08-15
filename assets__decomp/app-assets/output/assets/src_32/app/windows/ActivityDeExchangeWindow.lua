local var_0_0 = class("ActivityDeExchangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityDeExchange
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.hero
local var_0_6 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.id = arg_1_2.id

	if var_0_3:isSx(arg_1_0.id) == 1 then
		arg_1_0.rate = var_0_4:getValue("activity_exchange_sx_rate")
		arg_1_0.itemID = 50005149
	else
		arg_1_0.rate = var_0_4:getValue("activity_exchange_nomal_rate")
		arg_1_0.itemID = 50005148
	end

	arg_1_0.callback = arg_1_2.callback
	arg_1_0.times = arg_1_2.times
	arg_1_0.stoneNum = arg_1_2.stone_num
	arg_1_0.maxNum = math.min(math.floor(arg_1_0.stoneNum / arg_1_0.rate), arg_1_0.times)
	arg_1_0.currentNum = math.min(1, arg_1_0.maxNum)
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_middle"):setString(var_0_2:translation("ACTIVITY_1229_TEXT_4"))
	arg_4_0:nodeByName("txt_choose_nun"):setString(var_0_2:translation("ACTIVITY_1229_TEXT_5"))
	arg_4_0:nodeByName("txt_max"):setString(var_0_2:translation("MAX"))
	arg_4_0:nodeByName("txt_qiyueshu"):setString(var_0_2:translation("ACTIVITY_1229_TEXT_6"))
	arg_4_0:nodeByName("txt_cancel"):setString(var_0_2:translation("CANCEL"))
	arg_4_0:nodeByName("txt_sure"):setString(var_0_2:translation("SURE"))

	local var_4_0 = var_0_3:partnerId(arg_4_0.id)

	arg_4_0.stoneId = var_0_5:stoneID(var_4_0)

	xyd.setItemAndAddTips(arg_4_0:nodeByName("icon_hero"), arg_4_0.stoneId)
	xyd.setItemAndAddTips(arg_4_0:nodeByName("icon_item"), arg_4_0.itemID)
	arg_4_0:nodeByName("txt_hero_name"):setString(var_0_6:name(arg_4_0.stoneId))
	arg_4_0:nodeByName("txt_item_name"):setString(var_0_6:name(arg_4_0.itemID))
	arg_4_0:nodeByName("txt_from"):setString(string.format(var_0_2:translation("ACTIVITY_1229_TEXT_7"), arg_4_0.stoneNum))
	arg_4_0:nodeByName("txt_to"):setString(string.format(var_0_2:translation("ACTIVITY_1229_TEXT_7"), arg_4_0.backpack:getItemNumByID(arg_4_0.itemID)))

	local var_4_1 = string.format(var_0_2:translation("ACTIVITY_1229_TEXT_8"), arg_4_0.rate)
	local var_4_2 = xyd.getColorlabel({
		size = 22,
		color = cc.c3b(86, 35, 23)
	}, var_4_1)

	var_4_2:setAnchorPoint(0.5, 0.5)
	arg_4_0:nodeByName("pos_txt_rate"):addChild(var_4_2)

	local var_4_3 = arg_4_0:nodeByName("pos_stone")

	xyd.setItemBorder(var_4_3, arg_4_0.stoneId)
	arg_4_0:initBtns()
	arg_4_0:updateNum()
end

function var_0_0.initBtns(arg_5_0)
	local var_5_0 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_5_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_0:setScale(1, 1)
	var_5_0:addTo(arg_5_0:nodeByName("btn_sub"))
	var_5_0:setName("jiandian")

	local var_5_1 = false

	var_5_0:onButtonPressed(function(arg_6_0)
		local var_6_0 = 0

		local function var_6_1()
			var_6_0 = var_6_0 + 0.03

			if arg_5_0.decreaseCurrentNum then
				arg_5_0:decreaseCurrentNum()
			end
		end

		local function var_6_2()
			var_6_0 = var_6_0 + 0.1

			if var_6_0 > 0.5 and var_6_0 <= 4 then
				var_5_1 = true

				if arg_5_0.decreaseCurrentNum then
					arg_5_0:decreaseCurrentNum()
				end
			elseif var_6_0 > 4 then
				arg_5_0.handler[2] = var_0_1.scheduleGlobal(var_6_1, 0.03)

				var_0_1.unscheduleGlobal(arg_5_0.handler[1])
			else
				var_5_1 = false
			end
		end

		var_5_1 = false
		arg_5_0.handler[1] = var_0_1.scheduleGlobal(var_6_2, 0.1)
	end)
	var_5_0:onButtonRelease(function(arg_9_0)
		if arg_5_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_5_0.handler[1])
		end

		if arg_5_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_5_0.handler[2])
		end

		if var_5_1 == false and arg_5_0.decreaseCurrentNum then
			arg_5_0:decreaseCurrentNum()
		end
	end)

	local var_5_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_5_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_2:setScale(1, 1)
	var_5_2:addTo(arg_5_0:nodeByName("btn_add"))
	var_5_2:setName("jiadian")

	local var_5_3 = false

	var_5_2:onButtonPressed(function(arg_10_0)
		local var_10_0 = 0

		local function var_10_1()
			var_10_0 = var_10_0 + 0.03

			if arg_5_0.addCurrentNum then
				arg_5_0:addCurrentNum()
			end
		end

		local function var_10_2()
			var_10_0 = var_10_0 + 0.1

			if var_10_0 > 0.5 and var_10_0 <= 4 then
				var_5_3 = true

				if arg_5_0.addCurrentNum then
					arg_5_0:addCurrentNum()
				end
			elseif var_10_0 > 4 then
				arg_5_0.handler[2] = var_0_1.scheduleGlobal(var_10_1, 0.03)

				var_0_1.unscheduleGlobal(arg_5_0.handler[1])
			else
				var_5_3 = false
			end
		end

		var_5_3 = false
		arg_5_0.handler[1] = var_0_1.scheduleGlobal(var_10_2, 0.1)
	end)
	var_5_2:onButtonRelease(function(arg_13_0)
		if arg_5_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_5_0.handler[1])
		end

		if arg_5_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_5_0.handler[2])
		end

		if var_5_3 == false and arg_5_0.addCurrentNum then
			arg_5_0:addCurrentNum()
		end
	end)
	arg_5_0:nodeByName("btn_max"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			arg_5_0.currentNum = arg_5_0.maxNum

			arg_5_0:updateNum()
		end
	end)
	arg_5_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			arg_5_0:close()
		end
	end)
	arg_5_0:nodeByName("btn_sure"):addTouchEventListener(function(arg_16_0, arg_16_1)
		xyd.buttonScaleAnim(arg_16_0, arg_16_1)

		if arg_16_1 == ccui.TouchEventType.ended then
			arg_5_0:exchange()
		end
	end)
end

function var_0_0.decreaseCurrentNum(arg_17_0)
	if arg_17_0.currentNum - 1 <= 0 then
		return
	else
		arg_17_0.currentNum = arg_17_0.currentNum - 1
	end

	arg_17_0:updateNum()
end

function var_0_0.addCurrentNum(arg_18_0)
	if arg_18_0.currentNum >= arg_18_0.maxNum then
		return
	else
		arg_18_0.currentNum = arg_18_0.currentNum + 1
	end

	arg_18_0:updateNum()
end

function var_0_0.updateNum(arg_19_0)
	arg_19_0:nodeByName("txt_use_num"):setString(arg_19_0.currentNum)
	arg_19_0:nodeByName("txt_qiyueshu_num"):setString(arg_19_0.currentNum * arg_19_0.rate)
end

function var_0_0.exchange(arg_20_0)
	if arg_20_0.maxNum <= 0 then
		local var_20_0 = var_0_2:translation("ACTIVITY_1229_TEXT_9")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_20_0)

		return
	end

	local var_20_1 = {
		id = arg_20_0.id,
		time = arg_20_0.currentNum
	}

	xyd.Backend.get():request(xyd.mid.ACTIVITY_STONE_EXCHANGE_BUY, var_20_1, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			arg_20_0.selfPlayer:handleRewards({
				arg_21_1.awards
			})
			arg_20_0.backpack:addItemsByID(arg_20_0.stoneId, -arg_20_0.currentNum * arg_20_0.rate)

			if arg_20_0.callback then
				arg_20_0.callback(arg_20_0.id, arg_20_0.currentNum)
			end

			arg_20_0:close()
		end
	end)
end

return var_0_0
