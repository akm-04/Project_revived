local var_0_0 = class("AssetWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 120

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.ECONOMY_AFTER, handler(arg_3_0, arg_3_0.updateEconomicInfo))
	arg_3_0:updateEconomicInfo()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("energy"):setFlippedX(false)
	arg_4_0:nodeByName("energy"):setScale(1)
	arg_4_0:setResourceBtnTouch()
end

function var_0_0.updateEconomicInfo(arg_5_0, arg_5_1)
	if not arg_5_1 then
		arg_5_0:nodeByName("mana_num_txt"):enableShadow(cc.c4b(1, 1, 1, 200), cc.size(1, -1), 1)
		arg_5_0:nodeByName("diamond_num_txt"):enableShadow(cc.c4b(1, 1, 1, 200), cc.size(1, -1), 1)
		arg_5_0:nodeByName("energy_num_txt"):enableShadow(cc.c4b(1, 1, 1, 200), cc.size(1, -1), 1)
		arg_5_0:nodeByName("mana_num_txt"):setString(xyd.num2ThousandsStr(arg_5_0.selfPlayer.mana))
		arg_5_0:nodeByName("diamond_num_txt"):setString(xyd.num2ThousandsStr(arg_5_0.selfPlayer.crystal))
		arg_5_0:nodeByName("energy_num_txt"):setString(arg_5_0.selfPlayer.energy .. "/" .. arg_5_0.selfPlayer:getEnergyLimit())

		return
	end

	local var_5_0 = arg_5_1.params

	if not var_5_0 or not next(var_5_0) then
		return
	end

	local var_5_1 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})

	if var_5_0.mana then
		arg_5_0:nodeByName("mana_num_txt"):setString(xyd.num2ThousandsStr(var_5_0.mana))

		local var_5_2 = cc.Spawn:create(var_5_1)

		arg_5_0:nodeByName("mana_num_txt"):runAction(var_5_2)
	end

	if var_5_0.crystal then
		arg_5_0:nodeByName("diamond_num_txt"):setString(xyd.num2ThousandsStr(var_5_0.crystal))

		local var_5_3 = cc.Spawn:create(var_5_1)

		arg_5_0:nodeByName("diamond_num_txt"):runAction(var_5_3)
	end

	if var_5_0.energy then
		local var_5_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		arg_5_0:nodeByName("energy_num_txt"):setString(var_5_4.energy .. "/" .. var_5_4:getEnergyLimit())

		local var_5_5 = cc.Spawn:create(var_5_1)

		arg_5_0:nodeByName("energy_num_txt"):runAction(var_5_5)
	end
end

function var_0_0.setResourceBtnTouch(arg_6_0)
	arg_6_0:nodeByName("mana_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			return true
		elseif arg_7_1 == ccui.TouchEventType.ended then
			arg_6_0:handleManaTouchEvent()
		end
	end)
	arg_6_0:nodeByName("diamond_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			return true
		elseif arg_8_1 == ccui.TouchEventType.ended then
			arg_6_0:handleDiamondTouchEvent()
		end
	end)
	arg_6_0:nodeByName("energy_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			arg_6_0.energyTips = xyd.WindowManager.get():getWindow("energy_tips")

			if arg_6_0.energyTips then
				xyd.WindowManager.get():closeWindow("energy_tips")
			end
		end

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_9_0

			arg_6_0.buyEnergyTimes = arg_6_0.selfPlayer.buyEnergyTimes
			arg_6_0.buyEnergyCost = xyd.tables.refreshCost:buyEnergyCost(arg_6_0.buyEnergyTimes + 1)
			arg_6_0.maxBuyTimes = xyd.tables.vip:numEnergy(arg_6_0.selfPlayer.vip)

			if arg_6_0.selfPlayer.privilegeLeftCardDay > 0 then
				local var_9_1 = xyd.tables.monthlyPrivilege:numEnergy(1)

				arg_6_0.maxBuyTimes = arg_6_0.maxBuyTimes + var_9_1
			end

			local var_9_2 = xyd.tables.misc.energyMaxLimit

			if var_9_2 <= arg_6_0.selfPlayer.energy and arg_6_0.buyEnergyTimes < arg_6_0.maxBuyTimes then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TILI_LIMIT_INFO")
				})
			else
				str = string.format(var_0_1:translation("ADD_ENERGY"), arg_6_0.buyEnergyCost, var_0_2, arg_6_0.buyEnergyTimes)

				if arg_6_0:isHasTiLiItem() then
					local var_9_3 = {
						text = str,
						callback = function()
							if arg_6_0.buyEnergyTimes >= arg_6_0.maxBuyTimes then
								str = string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), arg_6_0.buyEnergyTimes)
								var_9_0 = xyd.AlertType.CONFIRM

								local var_10_0 = xyd.luaStringSplit(str, "\n")

								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_0, function()
									local var_11_0 = {}

									var_11_0.windowState = false

									xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
									xyd.WindowManager.get():closeWindow("add_energy")
								end, nil, nil, arg_6_0.colorMode)
							elseif arg_6_0.selfPlayer.energy >= var_9_2 then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_1:translation("TILI_LIMIT_INFO")
								})
								xyd.WindowManager.get():closeWindow("buy_tili")
							else
								local var_10_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

								if arg_6_0.buyEnergyCost > var_10_1.crystal then
									xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
										local var_12_0 = {}

										var_12_0.windowState = true

										xyd.WindowManager.get():openWindow("vip_recharge", var_12_0)
									end, nil, nil, arg_6_0.colorMode)
								else
									arg_6_0.addEnergyModel:addEnergy(function(arg_13_0)
										if arg_13_0 == xyd.error.OK then
											return true
										end
									end)
									xyd.WindowManager.get():closeWindow("buy_tili")
								end
							end
						end
					}

					xyd.WindowManager.get():openWindow("buy_tili", var_9_3)
				else
					local var_9_4 = xyd.luaStringSplit(str, "\n")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_4, function()
						local var_14_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

						if arg_6_0.buyEnergyTimes >= arg_6_0.maxBuyTimes then
							str = string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), arg_6_0.buyEnergyTimes)
							var_9_0 = xyd.AlertType.CONFIRM

							local var_14_1 = xyd.luaStringSplit(str, "\n")

							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_1, function()
								local var_15_0 = {}

								var_15_0.windowState = false

								xyd.WindowManager.get():openWindow("vip_recharge", var_15_0)
								xyd.WindowManager.get():closeWindow("add_energy")
							end, nil, nil, arg_6_0.colorMode)
						elseif arg_6_0.buyEnergyCost > var_14_0.crystal then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_16_0 = {}

								var_16_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
							end, nil, nil, arg_6_0.colorMode)
						else
							arg_6_0.addEnergyModel:addEnergy(function(arg_17_0)
								if arg_17_0 == xyd.error.OK then
									return true
								end
							end)
							xyd.WindowManager.get():closeWindow("alert")
						end
					end, nil, 0, arg_6_0.colorMode)
				end
			end
		end
	end)

	arg_6_0.tmpNode = cc.Node:create()

	arg_6_0.tmpNode:setContentSize(arg_6_0:nodeByName("energy_container"):getContentSize())
	arg_6_0.tmpNode:addTo(arg_6_0:nodeByName("container"))
	arg_6_0.tmpNode:setAnchorPoint(cc.p(0, 0))
	arg_6_0.tmpNode:setPosition(arg_6_0:nodeByName("energy_container"):getPosition())
	arg_6_0.tmpNode:setTouchEnabled(true)
	arg_6_0.tmpNode:setGlobalZOrder(100)
	arg_6_0.tmpNode:setTouchSwallowEnabled(false)

	arg_6_0.jinbiNode = cc.Node:create()

	arg_6_0.jinbiNode:size(arg_6_0:nodeByName("mana_container"):getWidth() - 50, arg_6_0:nodeByName("mana_container"):getHeight())
	arg_6_0.jinbiNode:addTo(arg_6_0:nodeByName("container"), -1)
	arg_6_0.jinbiNode:setAnchorPoint(cc.p(0, 0))
	arg_6_0.jinbiNode:pos(arg_6_0:nodeByName("mana_container"):getX() + 50, arg_6_0:nodeByName("mana_container"):getY())
	arg_6_0.jinbiNode:setTouchEnabled(true)

	arg_6_0.zuanshiNode = cc.Node:create()

	arg_6_0.zuanshiNode:setContentSize(arg_6_0:nodeByName("diamond_container"):getWidth() - 50, arg_6_0:nodeByName("diamond_container"):getHeight())
	arg_6_0.zuanshiNode:addTo(arg_6_0:nodeByName("container"), -1)
	arg_6_0.zuanshiNode:setAnchorPoint(cc.p(0, 0))
	arg_6_0.zuanshiNode:pos(arg_6_0:nodeByName("diamond_container"):getX() + 50, arg_6_0:nodeByName("diamond_container"):getY())
	arg_6_0.zuanshiNode:setTouchEnabled(true)
	arg_6_0.tmpNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
		if arg_18_0.name == "began" then
			guildWnd = xyd.WindowManager.get():getWindow("team")

			if guildWnd == nil then
				arg_6_0.energyTips = xyd.WindowManager.get():openWindow("energy_tips")

				arg_6_0.energyTips:setPosition(405, 435)
			end

			return true
		elseif arg_18_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("energy_tips")
		end
	end)
	arg_6_0.jinbiNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			return true
		elseif arg_19_0.name == "ended" then
			arg_6_0:handleManaTouchEvent()
		end

		return true
	end)
	arg_6_0.zuanshiNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "began" then
			return true
		elseif arg_20_0.name == "ended" then
			arg_6_0:handleDiamondTouchEvent()
		end

		return true
	end)
end

function var_0_0.handleManaTouchEvent(arg_21_0)
	local var_21_0 = xyd.FunctionID.ID_GOLD_HAND

	if arg_21_0.selfPlayer:isFuncOpen(var_21_0) == true then
		xyd.playButtonSound()
		xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
	else
		local var_21_1 = xyd.tables.functionOpen:level(var_21_0)
		local var_21_2 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_21_1)

		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_21_2
		})
	end
end

function var_0_0.handleDiamondTouchEvent(arg_22_0)
	xyd.playButtonSound()
	arg_22_0:functionClickRecord(xyd.FunctionClick.CHARGE)

	if arg_22_0.selfPlayer.lev < 20 then
		arg_22_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CRYSTAL_LEV_LESS_20)
	end

	xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
end

function var_0_0.functionClickRecord(arg_23_0, arg_23_1)
	arg_23_0.selfPlayer:sendFunctionClick(arg_23_1)
end

function var_0_0.isHasTiLiItem(arg_24_0)
	local var_24_0 = arg_24_0.selfPlayer:getBackpack():getItems()

	for iter_24_0, iter_24_1 in pairs(var_24_0) do
		if xyd.tables.item:subType(iter_24_1.itemID) == xyd.ConsumeItemType.ENERGY_ITEM then
			return true
		end
	end

	return false
end

return var_0_0
