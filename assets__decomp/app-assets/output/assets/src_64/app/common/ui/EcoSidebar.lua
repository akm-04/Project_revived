local var_0_0 = class("EcoSidebar", import("app.common.ui.BaseWidget"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.translation
local var_0_3 = 120
local var_0_4 = 100

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.colorMode = arg_1_2.colorMode or xyd.ColorMode.BLUE

	if arg_1_0.colorMode <= 0 then
		arg_1_0.colorMode = xyd.ColorMode.BLUE
	end

	arg_1_0.style = arg_1_2.mainSceneStyle or xyd.MainSceneStyle.NORMAL
	arg_1_0.notShowParams = arg_1_2.notShowParams or {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)

	arg_1_0:init()
	arg_1_0:onRegister()
end

function var_0_0.init(arg_2_0)
	if arg_2_0.notShowParams[xyd.EconomicType.ENERGY] then
		arg_2_0:nodeByName("energy"):setVisible(false)
		arg_2_0:nodeByName("coin"):setPositionX(arg_2_0:nodeByName("coin"):getPositionX() + 230)
		arg_2_0:nodeByName("crystal"):setPositionX(arg_2_0:nodeByName("crystal"):getPositionX() + 230)
	end

	if arg_2_0.notShowParams[xyd.EconomicType.CRYSTAL] then
		arg_2_0:nodeByName("crystal"):setVisible(false)
		arg_2_0:nodeByName("coin"):setPositionX(arg_2_0:nodeByName("coin"):getPositionX() + 230)
	end

	if arg_2_0.notShowParams[xyd.EconomicType.MANA] then
		arg_2_0:nodeByName("coin"):setVisible(false)
	end

	arg_2_0:nodeByName("txt_coin"):setString(xyd.num2ThousandsStr(arg_2_0.selfPlayer.mana))
	arg_2_0:nodeByName("txt_crystal"):setString(xyd.num2ThousandsStr(arg_2_0.selfPlayer.crystal))
	arg_2_0:nodeByName("txt_energy"):setString(arg_2_0.selfPlayer.energy .. "/" .. arg_2_0.selfPlayer:getEnergyLimit())
	arg_2_0:nodeByName("txt_coin"):setLocalZOrder(var_0_4)
	arg_2_0:nodeByName("txt_crystal"):setLocalZOrder(var_0_4)
	arg_2_0:nodeByName("txt_energy"):setLocalZOrder(var_0_4)

	local var_2_0 = "windows/button/btn_add_eco.png"
	local var_2_1 = xyd.tables.systemColor:btnColors(arg_2_0.colorMode)
	local var_2_2 = {
		sprite = var_2_0,
		colorModes = var_2_1
	}

	if not arg_2_0.notShowParams[xyd.EconomicType.MANA] then
		local var_2_3 = var_0_1.new(var_2_2)

		var_2_3:setAnchorPoint(0.5, 0.5)
		var_2_3:addTo(arg_2_0:nodeByName("coin"))
		var_2_3:setPosition(arg_2_0:nodeByName("pos_btn_coin"):getPosition())
		var_2_3:setName("coin_btn")

		arg_2_0.children_.coin_btn = var_2_3
	end

	if not arg_2_0.notShowParams[xyd.EconomicType.CRYSTAL] then
		local var_2_4 = var_0_1.new(var_2_2)

		var_2_4:setAnchorPoint(0.5, 0.5)
		var_2_4:addTo(arg_2_0:nodeByName("crystal"))
		var_2_4:setPosition(arg_2_0:nodeByName("pos_btn_crystal"):getPosition())
		var_2_4:setName("crystal_btn")

		arg_2_0.children_.crystal_btn = var_2_4
	end

	if not arg_2_0.notShowParams[xyd.EconomicType.ENERGY] then
		local var_2_5 = var_0_1.new(var_2_2)

		var_2_5:setAnchorPoint(0.5, 0.5)
		var_2_5:addTo(arg_2_0:nodeByName("energy"))
		var_2_5:setPosition(arg_2_0:nodeByName("pos_btn_energy"):getPosition())
		var_2_5:setName("energy_btn")

		local var_2_6 = var_2_5:getContentSize()

		var_2_5:setContainerSize(var_2_6.width + 40, var_2_6.height + 40)

		arg_2_0.children_.energy_btn = var_2_5
	end

	if arg_2_0.style == xyd.MainSceneStyle.WINTER then
		local var_2_7 = "windows/main_top_window/winter_1.png"
		local var_2_8 = "windows/main_top_window/winter_2.png"
		local var_2_9 = "windows/main_top_window/winter_3.png"
		local var_2_10 = xyd.AssetLoader.get():loadSprite(var_2_7)
		local var_2_11 = xyd.AssetLoader.get():loadSprite(var_2_8)
		local var_2_12 = xyd.AssetLoader.get():loadSprite(var_2_9)
		local var_2_13 = var_2_10:getContentSize()

		if not arg_2_0.notShowParams[xyd.EconomicType.MANA] then
			var_2_10:addTo(arg_2_0:nodeByName("coin"))
			var_2_10:setAnchorPoint(0.5, 0.5)
			var_2_10:setTouchSwallowEnabled(false)
			var_2_10:setLocalZOrder(20)
			var_2_10:setPosition(cc.p(arg_2_0:nodeByName("coin"):getWidth() / 2 - 3, arg_2_0:nodeByName("coin"):getHeight() - 5))
		end

		if not arg_2_0.notShowParams[xyd.EconomicType.CRYSTAL] then
			var_2_11:addTo(arg_2_0:nodeByName("crystal"))
			var_2_11:setAnchorPoint(0.5, 0.5)
			var_2_11:setTouchSwallowEnabled(false)
			var_2_11:setLocalZOrder(20)
			var_2_11:setPosition(cc.p(arg_2_0:nodeByName("crystal"):getWidth() / 2 - 3, arg_2_0:nodeByName("crystal"):getHeight() - 7))
		end

		if not arg_2_0.notShowParams[xyd.EconomicType.ENERGY] then
			var_2_12:addTo(arg_2_0:nodeByName("energy"))
			var_2_12:setAnchorPoint(0.5, 0.5)
			var_2_12:setTouchSwallowEnabled(false)
			var_2_12:setLocalZOrder(20)
			var_2_12:setPosition(cc.p(arg_2_0:nodeByName("energy"):getWidth() / 2 - 3, arg_2_0:nodeByName("energy"):getHeight() - 5))
		end
	end

	local var_2_14 = 45

	if not arg_2_0.notShowParams[xyd.EconomicType.MANA] then
		arg_2_0.coinAreaNode = display.newNode()

		arg_2_0.coinAreaNode:addTo(arg_2_0:background())
		arg_2_0.coinAreaNode:setContentSize(arg_2_0:nodeByName("coin"):getWidth() - var_2_14, arg_2_0:nodeByName("coin"):getHeight())
		arg_2_0.coinAreaNode:setAnchorPoint(0, 0)
		arg_2_0.coinAreaNode:setPosition(arg_2_0:nodeByName("coin"):getPosition())
		arg_2_0.coinAreaNode:setTouchEnabled(true)
		arg_2_0.coinAreaNode:setTouchSwallowEnabled(true)
	end

	if not arg_2_0.notShowParams[xyd.EconomicType.CRYSTAL] then
		arg_2_0.crystalAreaNode = display.newNode()

		arg_2_0.crystalAreaNode:addTo(arg_2_0:background())
		arg_2_0.crystalAreaNode:setContentSize(arg_2_0:nodeByName("crystal"):getWidth() - var_2_14, arg_2_0:nodeByName("crystal"):getHeight())
		arg_2_0.crystalAreaNode:setAnchorPoint(0, 0)
		arg_2_0.crystalAreaNode:setPosition(arg_2_0:nodeByName("crystal"):getPosition())
		arg_2_0.crystalAreaNode:setTouchEnabled(true)
		arg_2_0.crystalAreaNode:setTouchSwallowEnabled(true)
	end

	if not arg_2_0.notShowParams[xyd.EconomicType.ENERGY] then
		arg_2_0.energyAreaNode = display.newNode()

		arg_2_0.energyAreaNode:addTo(arg_2_0:background())
		arg_2_0.energyAreaNode:setContentSize(arg_2_0:nodeByName("energy"):getWidth() - var_2_14 - 15, arg_2_0:nodeByName("energy"):getHeight())
		arg_2_0.energyAreaNode:setAnchorPoint(0, 0)
		arg_2_0.energyAreaNode:setPosition(arg_2_0:nodeByName("energy"):getPosition())
		arg_2_0.energyAreaNode:setTouchEnabled(true)
		arg_2_0.energyAreaNode:setTouchSwallowEnabled(true)
	end
end

function var_0_0.onRegister(arg_3_0)
	arg_3_0:registerCommon()
	arg_3_0:registerButton()
end

function var_0_0.registerCommon(arg_4_0)
	xyd.EventDispatcher.get():addEventListener(xyd.event.ECONOMY_AFTER, handler(arg_4_0, arg_4_0.update))
	xyd.EventDispatcher.get():addEventListener(xyd.event.TICK_UPDATE, handler(arg_4_0, arg_4_0.update))
end

function var_0_0.registerButton(arg_5_0)
	if arg_5_0:nodeByName("coin_btn") then
		arg_5_0:nodeByName("coin_btn"):addTouchEvent(function(arg_6_0)
			if arg_6_0.name == "ended" then
				xyd.playButtonSound()

				local var_6_0 = xyd.FunctionID.ID_GOLD_HAND

				if arg_5_0.selfPlayer:isFuncOpen(var_6_0) == true then
					xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
				else
					local var_6_1 = xyd.tables.functionOpen:level(var_6_0)
					local var_6_2 = string.format(var_0_2:translation("FUNCTION_OPEN_TIP_LEVEL"), var_6_1)

					if xyd.WindowManager.get():getWindow("toast") ~= nil then
						xyd.WindowManager.get():closeWindow("toast")
					end

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_2
					})

					return true
				end

				arg_5_0:removeMainTopGuide()
			end
		end)
	end

	if arg_5_0.coinAreaNode then
		arg_5_0.coinAreaNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				return true
			elseif arg_7_0.name == "ended" then
				xyd.playButtonSound()

				local var_7_0 = xyd.FunctionID.ID_GOLD_HAND

				if arg_5_0.selfPlayer:isFuncOpen(var_7_0) == true then
					xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
				else
					local var_7_1 = xyd.tables.functionOpen:level(var_7_0)
					local var_7_2 = string.format(var_0_2:translation("FUNCTION_OPEN_TIP_LEVEL"), var_7_1)

					if xyd.WindowManager.get():getWindow("toast") ~= nil then
						xyd.WindowManager.get():closeWindow("toast")
					end

					xyd.WindowManager.get():openWindow("toast", {
						message = var_7_2
					})

					return true
				end

				arg_5_0:removeMainTopGuide()
			end
		end)
	end

	if arg_5_0:nodeByName("crystal_btn") then
		arg_5_0:nodeByName("crystal_btn"):addTouchEvent(function(arg_8_0)
			if arg_8_0.name == "ended" then
				xyd.playButtonSound()
				arg_5_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.CHARGE)
				xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
			end
		end)
	end

	if arg_5_0.crystalAreaNode then
		arg_5_0.crystalAreaNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "began" then
				return true
			elseif arg_9_0.name == "ended" then
				xyd.playButtonSound()
				arg_5_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.CHARGE)

				if arg_5_0.selfPlayer.lev < 20 then
					arg_5_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CRYSTAL_LEV_LESS_20)
				end

				xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
			end
		end)
	end

	if arg_5_0:nodeByName("energy_btn") then
		arg_5_0:nodeByName("energy_btn"):addTouchEvent(function(arg_10_0)
			if arg_10_0.name == "ended" then
				xyd.playButtonSound()

				local var_10_0 = arg_5_0.selfPlayer.buyEnergyTimes
				local var_10_1 = xyd.tables.refreshCost:buyEnergyCost(var_10_0 + 1)
				local var_10_2 = xyd.tables.vip:numEnergy(arg_5_0.selfPlayer.vip)

				if arg_5_0.selfPlayer.privilegeLeftCardDay > 0 then
					var_10_2 = var_10_2 + xyd.tables.monthlyPrivilege:numEnergy(1)
				end

				local var_10_3 = xyd.tables.misc.energyMaxLimit

				if var_10_3 <= arg_5_0.selfPlayer.energy and var_10_0 < var_10_2 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("TILI_LIMIT_INFO")
					})
				else
					local function var_10_4()
						if var_10_0 >= var_10_2 then
							local var_11_0 = string.format(var_0_2:translation("CAN_NOT_ADDENERGY"), var_10_0)
							local var_11_1 = xyd.luaStringSplit(var_11_0, "\n")

							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_1, function()
								local var_12_0 = {}

								var_12_0.windowState = false

								xyd.WindowManager.get():openWindow("vip_recharge", var_12_0)
								xyd.WindowManager.get():closeWindow("add_energy")
							end, nil, nil, arg_5_0.colorMode)
						elseif arg_5_0.selfPlayer.energy >= var_10_3 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("TILI_LIMIT_INFO")
							})
							xyd.WindowManager.get():closeWindow("buy_tili")
						elseif var_10_1 > arg_5_0.selfPlayer.crystal then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
								local var_13_0 = {}

								var_13_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
							end, nil, nil, arg_5_0.colorMode)
						else
							arg_5_0.addEnergyModel:addEnergy()
							xyd.WindowManager.get():closeWindow("buy_tili")
						end
					end

					local var_10_5 = string.format(var_0_2:translation("ADD_ENERGY"), var_10_1, var_0_3, var_10_0)

					if arg_5_0.backpack:isHasEnergyItem() then
						local var_10_6 = {
							text = var_10_5,
							callback = var_10_4
						}

						xyd.WindowManager.get():openWindow("buy_tili", var_10_6)
					else
						local var_10_7 = xyd.luaStringSplit(var_10_5, "\n")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_7, function()
							if var_10_0 >= var_10_2 then
								local var_14_0 = string.format(var_0_2:translation("CAN_NOT_ADDENERGY"), var_10_0)
								local var_14_1 = xyd.luaStringSplit(var_14_0, "\n")

								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_1, function()
									local var_15_0 = {}

									var_15_0.windowState = false

									xyd.WindowManager.get():openWindow("vip_recharge", var_15_0)
									xyd.WindowManager.get():closeWindow("add_energy")
								end, nil, nil, arg_5_0.colorMode)
							elseif var_10_1 > arg_5_0.selfPlayer.crystal then
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
									local var_16_0 = {}

									var_16_0.windowState = true

									xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
								end, nil, nil, arg_5_0.colorMode)
							else
								arg_5_0.addEnergyModel:addEnergy()
								xyd.WindowManager.get():closeWindow("alert")
							end
						end, nil, 0, arg_5_0.colorMode)
					end
				end
			end
		end)
	end

	if arg_5_0.energyAreaNode then
		arg_5_0.energyAreaNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
			if arg_17_0.name == "began" then
				xyd.WindowManager.get():openWindow("energy_tips"):setPosition(405, 435)

				return true
			elseif arg_17_0.name == "ended" then
				xyd.playButtonSound()
				xyd.WindowManager.get():closeWindow("energy_tips")
			end
		end)
	end
end

function var_0_0.update(arg_18_0)
	if arg_18_0.updateCoin then
		arg_18_0:updateCoin()
	end

	if arg_18_0.updateCrystal then
		arg_18_0:updateCrystal()
	end

	if arg_18_0.updateEnergy then
		arg_18_0:updateEnergy()
	end
end

function var_0_0.updateCoin(arg_19_0)
	local var_19_0 = arg_19_0:nodeByName("txt_coin"):getString()
	local var_19_1 = xyd.num2ThousandsStr(arg_19_0.selfPlayer.mana)

	if var_19_0 == var_19_1 then
		return
	end

	arg_19_0:nodeByName("txt_coin"):setString(var_19_1)

	local var_19_2 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_19_3 = cc.Spawn:create(var_19_2)

	arg_19_0:nodeByName("txt_coin"):runAction(var_19_3)
end

function var_0_0.updateCrystal(arg_20_0)
	local var_20_0 = arg_20_0:nodeByName("txt_crystal"):getString()
	local var_20_1 = xyd.num2ThousandsStr(arg_20_0.selfPlayer.crystal)

	if var_20_0 == var_20_1 then
		return
	end

	arg_20_0:nodeByName("txt_crystal"):setString(var_20_1)

	local var_20_2 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_20_3 = cc.Spawn:create(var_20_2)

	arg_20_0:nodeByName("txt_crystal"):runAction(var_20_3)
end

function var_0_0.updateEnergy(arg_21_0)
	local var_21_0 = arg_21_0:nodeByName("txt_energy"):getString()
	local var_21_1 = arg_21_0.selfPlayer:getEnergy() .. "/" .. arg_21_0.selfPlayer:getEnergyLimit()

	if var_21_0 == var_21_1 then
		return
	end

	arg_21_0:nodeByName("txt_energy"):setString(var_21_1)

	local var_21_2 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_21_3 = cc.Spawn:create(var_21_2)

	arg_21_0:nodeByName("txt_energy"):runAction(var_21_3)
end

function var_0_0.removeMainTopGuide(arg_22_0)
	local var_22_0 = xyd.WindowManager.get():getWindow("main_scene_top")

	if not var_22_0 then
		return
	end

	var_22_0:removeGuideHand("coin_btn")
end

function var_0_0.touchEnable(arg_23_0, arg_23_1)
	if arg_23_0:nodeByName("coin_btn") then
		arg_23_0:nodeByName("coin_btn"):setTouchEnabled(arg_23_1)
	end

	if arg_23_0:nodeByName("crystal_btn") then
		arg_23_0:nodeByName("crystal_btn"):setTouchEnabled(arg_23_1)
	end

	if arg_23_0:nodeByName("energy_btn") then
		arg_23_0:nodeByName("energy_btn"):setTouchEnabled(arg_23_1)
	end

	if arg_23_0.coinAreaNode then
		arg_23_0.coinAreaNode:setTouchEnabled(arg_23_1)
	end

	if arg_23_0.crystalAreaNode then
		arg_23_0.crystalAreaNode:setTouchEnabled(arg_23_1)
	end

	if arg_23_0.energyAreaNode then
		arg_23_0.energyAreaNode:setTouchEnabled(arg_23_1)
	end
end

return var_0_0
