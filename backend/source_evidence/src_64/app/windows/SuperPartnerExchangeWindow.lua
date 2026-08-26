local var_0_0 = class("SuperPartnerExchangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.translation
local var_0_4 = require("framework.scheduler")
local var_0_5 = xyd.tables.hero
local var_0_6 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.tableID = arg_1_2.tableID
	arg_1_0.currentNum = arg_1_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.taitanItemID) >= xyd.tables.misc.taitanExchangeSuperHero and 1 or 0
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.didClose(arg_4_0)
	return
end

function var_0_0.willClose(arg_5_0)
	return
end

function var_0_0.layout(arg_6_0)
	xyd.setItemBorder(arg_6_0:nodeByName("item"), var_0_5:stoneID(arg_6_0.tableID))
	arg_6_0:nodeByName("item_name"):setString(var_0_6:name(var_0_5:stoneID(arg_6_0.tableID)))
	arg_6_0:nodeByName("text_num"):setString(var_0_3:translation("TAITAN_TEXT_2"))
	arg_6_0:nodeByName("text_use"):setString(var_0_3:translation("TAITAN_TEXT_3"))
	arg_6_0:nodeByName("label_own1"):setString(var_0_2:translation("ITEM_OWN"))
	arg_6_0:nodeByName("label_own2"):setString(var_0_2:translation("ITEM_OWN_SUFFIX"))
	arg_6_0:nodeByName("word_max"):setString(var_0_3:translation("MAX"))
	arg_6_0:nodeByName("word_exchange"):setString(var_0_3:translation("SURE"))
	arg_6_0:nodeByName("word_cancel"):setString(var_0_3:translation("CANCEL"))
	arg_6_0:update()
	arg_6_0:updateNum()

	local var_6_0

	arg_6_0:nodeByName("btn_exchange"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("btn_exchange"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_6_0.currentNum == 0 or xyd.tables.misc.taitanExchangeSuperHero * arg_6_0.currentNum > arg_6_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.taitanItemID) then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_3:translation("TAITAN_NO_JINGHUA"))
				})
			else
				local var_7_0 = string.format(var_0_3:translation("TAITAN_TEXT_4"), xyd.tables.misc.taitanExchangeSuperHero * arg_6_0.currentNum, arg_6_0.currentNum, var_0_6:name(var_0_5:stoneID(arg_6_0.tableID)))

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_0, function()
					local var_8_0 = {
						table_id = arg_6_0.tableID,
						times = arg_6_0.currentNum
					}

					xyd.Backend.get():request(xyd.mid.SUPER_HERO_STONE_EXCHANGE, var_8_0, function(arg_9_0, arg_9_1, arg_9_2)
						if arg_9_0 == xyd.error.OK then
							arg_6_0.selfPlayer:handleRewards(arg_9_1.awards)

							local var_9_0 = {
								itemID = xyd.tables.misc.taitanItemID,
								itemNum = xyd.tables.misc.taitanExchangeSuperHero * arg_6_0.currentNum
							}

							arg_6_0.selfPlayer:getBackpack():removeItem(var_9_0)
							xyd.WindowManager.get():closeWindow(arg_6_0)
						end
					end)
				end, {
					showBegin = true
				}, nil, arg_6_0.colorMode)
			end
		end
	end)
	arg_6_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("btn_cancel"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end)

	local var_6_1 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_6_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_1:setScale(1, 1)
	var_6_1:addTo(arg_6_0:nodeByName("btn_jian"))
	var_6_1:setName("jiandian")

	local var_6_2 = false

	var_6_1:onButtonPressed(function(arg_11_0)
		local var_11_0 = 0

		local function var_11_1()
			var_11_0 = var_11_0 + 0.03

			if arg_6_0.decreaseCurrentNum then
				arg_6_0:decreaseCurrentNum()
			end
		end

		local function var_11_2()
			var_11_0 = var_11_0 + 0.1

			if var_11_0 > 0.5 and var_11_0 <= 4 then
				var_6_2 = true

				if arg_6_0.decreaseCurrentNum then
					arg_6_0:decreaseCurrentNum()
				end
			elseif var_11_0 > 4 then
				arg_6_0.handler[2] = var_0_4.scheduleGlobal(var_11_1, 0.03)

				var_0_4.unscheduleGlobal(arg_6_0.handler[1])
			else
				var_6_2 = false
			end
		end

		var_6_2 = false
		arg_6_0.handler[1] = var_0_4.scheduleGlobal(var_11_2, 0.1)
	end)
	var_6_1:onButtonRelease(function(arg_14_0)
		if arg_6_0.handler[1] ~= nil then
			var_0_4.unscheduleGlobal(arg_6_0.handler[1])
		end

		if arg_6_0.handler[2] ~= nil then
			var_0_4.unscheduleGlobal(arg_6_0.handler[2])
		end

		if var_6_2 == false and arg_6_0.decreaseCurrentNum then
			arg_6_0:decreaseCurrentNum()
		end
	end)

	local var_6_3 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_6_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_3:setScale(1, 1)
	var_6_3:addTo(arg_6_0:nodeByName("btn_add"))
	var_6_3:setName("jiadian")

	local var_6_4 = false

	var_6_3:onButtonPressed(function(arg_15_0)
		local var_15_0 = 0

		local function var_15_1()
			var_15_0 = var_15_0 + 0.03

			if arg_6_0.addCurrentNum then
				arg_6_0:addCurrentNum()
			end
		end

		local function var_15_2()
			var_15_0 = var_15_0 + 0.1

			if var_15_0 > 0.5 and var_15_0 <= 4 then
				var_6_4 = true

				if arg_6_0.addCurrentNum then
					arg_6_0:addCurrentNum()
				end
			elseif var_15_0 > 4 then
				arg_6_0.handler[2] = var_0_4.scheduleGlobal(var_15_1, 0.03)

				var_0_4.unscheduleGlobal(arg_6_0.handler[1])
			else
				var_6_4 = false
			end
		end

		var_6_4 = false
		arg_6_0.handler[1] = var_0_4.scheduleGlobal(var_15_2, 0.1)
	end)
	var_6_3:onButtonRelease(function(arg_18_0)
		if arg_6_0.handler[1] ~= nil then
			var_0_4.unscheduleGlobal(arg_6_0.handler[1])
		end

		if arg_6_0.handler[2] ~= nil then
			var_0_4.unscheduleGlobal(arg_6_0.handler[2])
		end

		if var_6_4 == false and arg_6_0.addCurrentNum then
			arg_6_0:addCurrentNum()
		end
	end)
	arg_6_0:nodeByName("btn_max"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("btn_max"), arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_6_0.currentNum = arg_6_0.maxNum

			arg_6_0:updateNum()

			if arg_6_0.currentNum == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_3:translation("TAITAN_NO_JINGHUA"))
				})
			end
		end
	end)
end

function var_0_0.update(arg_20_0)
	arg_20_0.maxNum = math.floor(arg_20_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.taitanItemID) / xyd.tables.misc.taitanExchangeSuperHero)
	arg_20_0.minNum = arg_20_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.taitanItemID) >= xyd.tables.misc.taitanExchangeSuperHero and 1 or 0

	arg_20_0:nodeByName("label_own_value"):setString(arg_20_0.selfPlayer:getBackpack():getItemNumByID(var_0_5:stoneID(arg_20_0.tableID)))

	local var_20_0, var_20_1 = arg_20_0:nodeByName("label_own_value"):getPosition()

	arg_20_0:nodeByName("label_own2"):x(var_20_0 + arg_20_0:nodeByName("label_own_value"):getContentSize().width + 5)

	arg_20_0.currentNum = arg_20_0.minNum
end

function var_0_0.addCurrentNum(arg_21_0)
	if arg_21_0.currentNum + 1 >= arg_21_0.maxNum then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_3:translation("TAITAN_TEXT_11"))
		})

		arg_21_0.currentNum = arg_21_0.maxNum
	else
		arg_21_0.currentNum = arg_21_0.currentNum + 1
	end

	arg_21_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_22_0)
	if arg_22_0.currentNum - 1 < arg_22_0.minNum then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_3:translation("TAITAN_TEXT_10"))
		})

		arg_22_0.currentNum = arg_22_0.minNum
	else
		arg_22_0.currentNum = arg_22_0.currentNum - 1
	end

	arg_22_0:updateNum()
end

function var_0_0.updateNum(arg_23_0)
	arg_23_0:nodeByName("exchange_num"):setString(arg_23_0.currentNum .. "/" .. arg_23_0.maxNum)
	arg_23_0:nodeByName("use_num"):setString(xyd.tables.misc.taitanExchangeSuperHero * arg_23_0.currentNum)
end

function var_0_0.didClose(arg_24_0)
	if arg_24_0.handler then
		if arg_24_0.handler[1] then
			var_0_4.unscheduleGlobal(arg_24_0.handler[1])
		end

		if arg_24_0.handler[2] then
			var_0_4.unscheduleGlobal(arg_24_0.handler[2])
		end
	end
end

return var_0_0
