local var_0_0 = class("EcoDisplaySidebar", import("app.common.ui.BaseWidget"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.translation
local var_0_3 = 120
local var_0_4 = 100

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.colorMode = arg_1_2.colorMode or xyd.ColorMode.BLUE
	arg_1_0.ecoCount = arg_1_2.ecoCount
	arg_1_0.ecoTypes = arg_1_2.ecoTypes
	arg_1_0.ecoIcons = arg_1_2.ecoIcons
	arg_1_0.ecoIsAdd = arg_1_2.ecoIsAdd or {}
	arg_1_0.ecoScale = arg_1_2.ecoScale or {}
	arg_1_0.ecoAddCallback = arg_1_2.ecoAddCallback or {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)

	arg_1_0:init()
	arg_1_0:onRegister()
end

function var_0_0.init(arg_2_0)
	if not arg_2_0.ecoIcons or not next(arg_2_0.ecoIcons) or not arg_2_0.ecoTypes or not next(arg_2_0.ecoTypes) or #arg_2_0.ecoTypes ~= arg_2_0.ecoCount then
		return
	end

	local var_2_0
	local var_2_1 = arg_2_0.ecoCount >= 4 and 4 or arg_2_0.ecoCount

	for iter_2_0 = var_2_1 + 1, 4 do
		arg_2_0:nodeByName("eco_" .. iter_2_0):setVisible(false)
	end

	for iter_2_1 = 1, var_2_1 do
		arg_2_0:initEcoNum(iter_2_1)
	end
end

function var_0_0.initEcoNum(arg_3_0, arg_3_1)
	if arg_3_0.ecoTypes[arg_3_1] == xyd.EconomicType.MANA then
		local var_3_0 = "images/icon/eco/icon_coin.png"
		local var_3_1 = xyd.AssetLoader.get():loadSprite(var_3_0)

		arg_3_0:nodeByName("eco_" .. arg_3_1):add(var_3_1)
		var_3_1:setAnchorPoint(0.5, 0.5)
		var_3_1:setPosition(arg_3_0:nodeByName("pos_icon_" .. arg_3_1):getPosition())
		var_3_1:setScale(arg_3_0.ecoScale[arg_3_1] or 1)

		local var_3_2 = arg_3_0.selfPlayer:getEconomicItemNumByType(arg_3_0.ecoTypes[arg_3_1])

		arg_3_0:nodeByName("txt_eco_val_" .. arg_3_1):setString(xyd.num2ThousandsStr(var_3_2))
		arg_3_0:nodeByName("txt_eco_val_" .. arg_3_1):setLocalZOrder(var_0_4)
	elseif arg_3_0.ecoTypes[arg_3_1] == xyd.EconomicType.CRYSTAL then
		local var_3_3 = "images/icon/eco/icon_crystal.png"
		local var_3_4 = xyd.AssetLoader.get():loadSprite(var_3_3)

		arg_3_0:nodeByName("eco_" .. arg_3_1):add(var_3_4)
		var_3_4:setAnchorPoint(0.5, 0.5)
		var_3_4:setPosition(arg_3_0:nodeByName("pos_icon_" .. arg_3_1):getPosition())
		var_3_4:setScale(arg_3_0.ecoScale[arg_3_1] or 1)

		local var_3_5 = arg_3_0.selfPlayer:getEconomicItemNumByType(arg_3_0.ecoTypes[arg_3_1])

		arg_3_0:nodeByName("txt_eco_val_" .. arg_3_1):setString(xyd.num2ThousandsStr(var_3_5))
		arg_3_0:nodeByName("txt_eco_val_" .. arg_3_1):setLocalZOrder(var_0_4)
	elseif arg_3_0.ecoTypes[arg_3_1] == xyd.EconomicType.ENERGY then
		local var_3_6 = "images/icon/eco/icon_energy.png"
		local var_3_7 = xyd.AssetLoader.get():loadSprite(var_3_6)

		arg_3_0:nodeByName("eco_" .. arg_3_1):add(var_3_7)
		var_3_7:setAnchorPoint(0.5, 0.5)
		var_3_7:setPosition(arg_3_0:nodeByName("pos_icon_" .. arg_3_1):getPosition())
		var_3_7:setScale(arg_3_0.ecoScale[arg_3_1] or 1)

		local var_3_8 = arg_3_0.selfPlayer:getEconomicItemNumByType(arg_3_0.ecoTypes[arg_3_1])

		arg_3_0:nodeByName("txt_eco_val_" .. arg_3_1):setString(xyd.num2ThousandsStr(var_3_8))
		arg_3_0:nodeByName("txt_eco_val_" .. arg_3_1):setLocalZOrder(var_0_4)
	else
		local var_3_9

		if arg_3_0.ecoIcons and arg_3_0.ecoIcons[arg_3_1] then
			var_3_9 = arg_3_0.ecoIcons[arg_3_1]
		end

		local var_3_10 = xyd.AssetLoader.get():loadSprite(var_3_9)

		arg_3_0:nodeByName("eco_" .. arg_3_1):add(var_3_10)
		var_3_10:setAnchorPoint(0.5, 0.5)
		var_3_10:setPosition(arg_3_0:nodeByName("pos_icon_" .. arg_3_1):getPosition())
		var_3_10:setScale(arg_3_0.ecoScale[arg_3_1] or 1)

		local var_3_11 = arg_3_0.selfPlayer:getBackpack():getItemNumByID(arg_3_0.ecoTypes[arg_3_1])

		arg_3_0:nodeByName("txt_eco_val_" .. arg_3_1):setString(xyd.num2ThousandsStr(var_3_11))
		arg_3_0:nodeByName("txt_eco_val_" .. arg_3_1):setLocalZOrder(var_0_4)
	end

	if arg_3_0.ecoIsAdd[arg_3_1] then
		local var_3_12 = arg_3_0:nodeByName("eco_" .. arg_3_1)
		local var_3_13 = var_3_12:getContentSize()
		local var_3_14 = "windows/button/btn_add_eco.png"
		local var_3_15 = xyd.tables.systemColor:btnColors(arg_3_0.colorMode)
		local var_3_16 = {
			sprite = var_3_14,
			colorModes = var_3_15
		}
		local var_3_17 = var_0_1.new(var_3_16)

		var_3_17:setAnchorPoint(0.5, 0.5)
		var_3_17:setPosition(var_3_13.width - 18, var_3_13.height / 2)
		var_3_12:addChild(var_3_17)

		local var_3_18 = arg_3_0:nodeByName("txt_eco_val_" .. arg_3_1):getPositionX()

		arg_3_0:nodeByName("txt_eco_val_" .. arg_3_1):setPositionX(var_3_18 - 10)
		var_3_17:addTouchEvent(function(arg_4_0)
			if arg_4_0.name == "ended" then
				xyd.playButtonSound()

				if arg_3_0.ecoTypes[arg_3_1] == xyd.EconomicType.MANA then
					local var_4_0 = xyd.FunctionID.ID_GOLD_HAND

					if arg_3_0.selfPlayer:isFuncOpen(var_4_0) == true then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
					else
						local var_4_1 = xyd.tables.functionOpen:level(var_4_0)
						local var_4_2 = string.format(var_0_2:translation("FUNCTION_OPEN_TIP_LEVEL"), var_4_1)

						if xyd.WindowManager.get():getWindow("toast") ~= nil then
							xyd.WindowManager.get():closeWindow("toast")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_4_2
						})
					end
				elseif arg_3_0.ecoTypes[arg_3_1] == xyd.EconomicType.CRYSTAL then
					arg_3_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.CHARGE)
					xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
				elseif arg_3_0.ecoTypes[arg_3_1] == xyd.EconomicType.ENERGY then
					local var_4_3 = arg_3_0.selfPlayer.buyEnergyTimes
					local var_4_4 = xyd.tables.refreshCost:buyEnergyCost(var_4_3 + 1)
					local var_4_5 = xyd.tables.vip:numEnergy(arg_3_0.selfPlayer.vip)

					if arg_3_0.selfPlayer.privilegeLeftCardDay > 0 then
						var_4_5 = var_4_5 + xyd.tables.monthlyPrivilege:numEnergy(1)
					end

					local var_4_6 = xyd.tables.misc.energyMaxLimit

					if var_4_6 <= arg_3_0.selfPlayer.energy and var_4_3 < var_4_5 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("TILI_LIMIT_INFO")
						})
					else
						local function var_4_7()
							if var_4_3 >= var_4_5 then
								local var_5_0 = string.format(var_0_2:translation("CAN_NOT_ADDENERGY"), var_4_3)
								local var_5_1 = xyd.luaStringSplit(var_5_0, "\n")

								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_1, function()
									local var_6_0 = {}

									var_6_0.windowState = false

									xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
									xyd.WindowManager.get():closeWindow("add_energy")
								end, nil, nil, arg_3_0.colorMode)
							elseif arg_3_0.selfPlayer.energy >= var_4_6 then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_2:translation("TILI_LIMIT_INFO")
								})
								xyd.WindowManager.get():closeWindow("buy_tili")
							elseif var_4_4 > arg_3_0.selfPlayer.crystal then
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
									local var_7_0 = {}

									var_7_0.windowState = true

									xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
								end, nil, nil, arg_3_0.colorMode)
							else
								arg_3_0.addEnergyModel:addEnergy()
								xyd.WindowManager.get():closeWindow("buy_tili")
							end
						end

						local var_4_8 = string.format(var_0_2:translation("ADD_ENERGY"), var_4_4, var_0_3, var_4_3)

						if arg_3_0.backpack:isHasEnergyItem() then
							local var_4_9 = {
								text = var_4_8,
								callback = var_4_7
							}

							xyd.WindowManager.get():openWindow("buy_tili", var_4_9)
						else
							local var_4_10 = xyd.luaStringSplit(var_4_8, "\n")

							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_10, function()
								if var_4_3 >= var_4_5 then
									local var_8_0 = string.format(var_0_2:translation("CAN_NOT_ADDENERGY"), var_4_3)
									local var_8_1 = xyd.luaStringSplit(var_8_0, "\n")

									xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_1, function()
										local var_9_0 = {}

										var_9_0.windowState = false

										xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
										xyd.WindowManager.get():closeWindow("add_energy")
									end, nil, nil, arg_3_0.colorMode)
								elseif var_4_4 > arg_3_0.selfPlayer.crystal then
									xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
										local var_10_0 = {}

										var_10_0.windowState = true

										xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
									end, nil, nil, arg_3_0.colorMode)
								else
									arg_3_0.addEnergyModel:addEnergy()
									xyd.WindowManager.get():closeWindow("alert")
								end
							end, nil, 0, arg_3_0.colorMode)
						end
					end
				elseif arg_3_0.ecoAddCallback[arg_3_1] then
					arg_3_0.ecoAddCallback[arg_3_1]()
				end
			end
		end)
	end
end

function var_0_0.onRegister(arg_11_0)
	arg_11_0:registerCommon()
	arg_11_0:registerClick()
end

function var_0_0.registerCommon(arg_12_0)
	return
end

function var_0_0.registerClick(arg_13_0)
	return
end

function var_0_0.update(arg_14_0, arg_14_1)
	if not arg_14_1 or not next(arg_14_1) then
		return
	end

	if not arg_14_0.ecoTypes or not next(arg_14_0.ecoTypes) or #arg_14_0.ecoTypes ~= arg_14_0.ecoCount then
		return
	end

	local var_14_0 = arg_14_1.ecos or arg_14_0.ecoTypes

	if not var_14_0 or not next(var_14_0) then
		return
	end

	for iter_14_0, iter_14_1 in pairs(var_14_0) do
		if not iter_14_1 then
			return
		end

		if iter_14_1 == xyd.EconomicType.MANA then
			arg_14_0:updateCoinAtIndex(iter_14_0)
		elseif iter_14_1 == xyd.EconomicType.CRYSTAL then
			arg_14_0:updateCrystalAtIndex(iter_14_0)
		elseif iter_14_1 == xyd.EconomicType.ENERGY then
			arg_14_0:updateEnergyAtIndex(iter_14_0)
		else
			arg_14_0:updateEcoByIdx(iter_14_0)
		end
	end
end

function var_0_0.updateCoinAtIndex(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0:nodeByName("txt_eco_val_" .. arg_15_1)
	local var_15_1 = var_15_0:getString()
	local var_15_2 = xyd.num2ThousandsStr(arg_15_0.selfPlayer.mana)

	if var_15_1 == var_15_2 then
		return
	end

	var_15_0:setString(var_15_2)

	local var_15_3 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_15_4 = cc.Spawn:create(var_15_3)

	var_15_0:runAction(var_15_4)
end

function var_0_0.updateCrystalAtIndex(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0:nodeByName("txt_eco_val_" .. arg_16_1)
	local var_16_1 = var_16_0:getString()
	local var_16_2 = xyd.num2ThousandsStr(arg_16_0.selfPlayer.crystal)

	if var_16_1 == var_16_2 then
		return
	end

	var_16_0:setString(var_16_2)

	local var_16_3 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_16_4 = cc.Spawn:create(var_16_3)

	var_16_0:runAction(var_16_4)
end

function var_0_0.updateEnergyAtIndex(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_0:nodeByName("txt_eco_val_" .. arg_17_1)
	local var_17_1 = var_17_0:getString()
	local var_17_2 = arg_17_0.selfPlayer:getEnergy() .. "/" .. arg_17_0.selfPlayer:getEnergyLimit()

	if var_17_1 == var_17_2 then
		return
	end

	var_17_0:setString(var_17_2)

	local var_17_3 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_17_4 = cc.Spawn:create(var_17_3)

	var_17_0:runAction(var_17_4)
end

function var_0_0.updateEcoByIdx(arg_18_0, arg_18_1)
	local var_18_0 = arg_18_0:nodeByName("txt_eco_val_" .. arg_18_1):getString()
	local var_18_1 = xyd.num2ThousandsStr(arg_18_0.selfPlayer:getBackpack():getItemNumByID(arg_18_0.ecoTypes[arg_18_1]))

	if var_18_0 == var_18_1 then
		return
	end

	arg_18_0:nodeByName("txt_eco_val_" .. arg_18_1):setString(var_18_1)

	local var_18_2 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_18_3 = cc.Spawn:create(var_18_2)

	arg_18_0:nodeByName("txt_eco_val_" .. arg_18_1):runAction(var_18_3)
end

return var_0_0
