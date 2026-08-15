local var_0_0 = class("IncubusDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.incubusTable
local var_0_3 = xyd.tables.hero
local var_0_4 = 90
local var_0_5 = 90
local var_0_6 = 5
local var_0_7 = 50001013

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.id = arg_1_2.id
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.incubus = xyd.ModelManager.get():loadModel(xyd.ModelType.INCUBUS)
	arg_1_0.info = arg_1_0.incubus:getInfoById(arg_1_0.id)
	arg_1_0.wave = arg_1_0.info.max_floor
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initAward()
	arg_2_0:initMonster()
	arg_2_0:initSweep()
	arg_2_0:initContinueBtn()
end

function var_0_0.initAward(arg_3_0)
	local var_3_0 = xyd.HeroAnimation.new(nil, var_0_3:modelID(var_0_2:hero(arg_3_0.id)), 1, {})

	var_3_0:addTo(arg_3_0:nodeByName("model_container"))
	var_3_0:setScale(0.8)
	var_3_0:idle(true)
	arg_3_0:nodeByName("name_txt"):loadTexture("windows/incubus/text/" .. var_0_2:name(arg_3_0.id))
	arg_3_0:updateCost()

	local var_3_1 = arg_3_0:nodeByName("award_container")
	local var_3_2 = var_3_1:getContentSize()

	arg_3_0.awardList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_2.width, var_3_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_3_1):onScroll(handler(arg_3_0, arg_3_0.awardListener))

	local var_3_3 = var_0_2:awardShow(arg_3_0.id)

	for iter_3_0, iter_3_1 in ipairs(var_3_3) do
		local var_3_4 = arg_3_0.awardList:newItem()
		local var_3_5 = cc.Node:create()

		var_3_5:setContentSize(var_0_4, var_0_4)
		xyd.setItemBorder(var_3_5, iter_3_1)
		var_3_4:addContent(var_3_5)
		var_3_4:setItemSize(var_0_4, var_0_4)
		arg_3_0.awardList:addItem(var_3_4)

		local var_3_6 = {
			id = iter_3_1,
			hasNum = arg_3_0.player:getBackpack():getItemNumByID(iter_3_1)
		}

		xyd.addTips(var_3_5, var_3_6)
	end

	arg_3_0.awardList:reload()
end

function var_0_0.awardListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.awardListMoved_ = false
		arg_4_0.prevX_ = arg_4_1.x
	elseif arg_4_1.name == "moved" and 20 <= math.abs(arg_4_1.x - arg_4_0.prevX_) then
		arg_4_0.awardListMoved_ = true
	end
end

function var_0_0.initMonster(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("enemy_container")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.monsterList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.monsterListener))

	local var_5_2 = var_0_2:monsterShow(arg_5_0.id)
	local var_5_3 = math.ceil(#var_5_2 / var_0_6)

	for iter_5_0 = 1, var_5_3 do
		local var_5_4 = arg_5_0.monsterList:newItem()
		local var_5_5 = cc.Node:create()

		var_5_5:setContentSize(var_5_1.width, var_0_5)
		var_5_4:addContent(var_5_5)
		var_5_4:setItemSize(var_5_1.width, var_0_5 + 7)
		arg_5_0.monsterList:addItem(var_5_4)

		for iter_5_1 = 1, var_0_6 do
			local var_5_6 = (iter_5_0 - 1) * var_0_6 + iter_5_1
			local var_5_7 = var_5_2[var_5_6]

			if var_5_6 > #var_5_2 then
				break
			end

			local var_5_8 = cc.Node:create()

			var_5_8:setContentSize(var_0_5, var_0_5)
			var_5_8:setPosition((iter_5_1 - 1) * (var_0_5 + 7), 0)
			var_5_5:addChild(var_5_8)

			local var_5_9 = var_0_3:color(var_5_7)

			xyd.setAvatarBorder(var_5_7, var_5_8, var_5_9, var_0_3:star(var_5_7))

			local var_5_10 = {
				isBoss = false,
				isHero = true,
				id = var_5_2[var_5_6],
				quality = var_5_9,
				lev = var_0_3:level(var_5_7),
				name = var_0_3:name(var_5_7),
				desc = var_0_3:getDes(var_5_7)
			}

			var_5_8:setTouchSwallowEnabled(false)
			var_5_8:setTouchEnabled(true)
			var_5_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
				if arg_6_0.name == "began" then
					if not xyd.WindowManager.get():getWindow("new_item_tips") then
						local var_6_0 = xyd.WindowManager.get():openWindow("new_item_tips", var_5_10)

						xyd.adaptToWorldPosition(var_5_8, var_6_0)
					end

					return true
				elseif arg_6_0.name == "moved" and arg_5_0.monsterListMoved_ then
					wnd = xyd.WindowManager.get():closeWindow("new_item_tips")
				elseif arg_6_0.name == "ended" then
					xyd.WindowManager.get():closeWindow("new_item_tips")
				end
			end)
		end
	end

	arg_5_0.monsterList:reload()
end

function var_0_0.monsterListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.monsterListMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.monsterListMoved_ = true
	end
end

function var_0_0.initSweep(arg_8_0)
	if arg_8_0.wave == 0 then
		arg_8_0:nodeByName("sweep_container"):setVisible(false)

		return
	end

	arg_8_0.hasItemNum = arg_8_0.player:getBackpack():getItemNumByID(var_0_7)

	arg_8_0:nodeByName("sweep_txt"):setString(var_0_1:translation("MAP_SWEEP"))
	arg_8_0:nodeByName("sweep_item_num"):setString(string.format(var_0_1:translation("MAP_SWEEP_ITEM"), tostring(arg_8_0.hasItemNum)))
	arg_8_0:nodeByName("sweep_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.incubus.times < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TRIAL_NO_TIMES_LEFT")
				})

				return
			end

			if arg_8_0.player.energy < arg_8_0.cost then
				arg_8_0:buyEnergy()

				return
			end

			if arg_8_0.hasItemNum < arg_8_0.wave then
				local var_9_0 = string.format(var_0_1:translation("INCUBUS_SWEEP_ALERT_2"), arg_8_0.wave)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
					if arg_8_0.player.crystal < arg_8_0.wave then
						arg_8_0:chargeAlert()
					else
						arg_8_0:sweep(xyd.SweepType.CRYSTAL_SWEEP)
					end
				end, nil, 0, arg_8_0.colorMode)
			else
				local var_9_1 = string.format(var_0_1:translation("INCUBUS_SWEEP_ALERT_1"), arg_8_0.wave, arg_8_0.wave)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_1, function()
					arg_8_0:sweep(xyd.SweepType.ITEM_SWEEP)
				end, nil, nil, arg_8_0.colorMode)
			end
		end
	end)
end

function var_0_0.sweep(arg_12_0, arg_12_1)
	local var_12_0 = {
		incubus_id = arg_12_0.id,
		sweep_type = arg_12_1
	}

	arg_12_0.incubus:sweep(var_12_0, function(arg_13_0)
		arg_12_0:updateCost()

		if arg_12_1 == xyd.SweepType.ITEM_SWEEP then
			arg_12_0.hasItemNum = arg_12_0.hasItemNum - arg_12_0.wave

			arg_12_0:nodeByName("sweep_item_num"):setString(string.format(var_0_1:translation("MAP_SWEEP_ITEM"), tostring(arg_12_0.hasItemNum)))
		end

		local var_13_0 = xyd.WindowManager.get():getWindow("incubus")

		if var_13_0 then
			var_13_0:updateTimes()
		end

		xyd.WindowManager.get():openWindow("incubus_sweep", {
			awards = arg_13_0
		})
	end)
end

function var_0_0.updateCost(arg_14_0)
	arg_14_0.cost = arg_14_0.incubus.incubusEnergy[arg_14_0.info.count + 1] or arg_14_0.incubus.incubusEnergy[#arg_14_0.incubus.incubusEnergy]

	arg_14_0:nodeByName("cost_txt"):setString(string.format(var_0_1:translation("TRIAL_ENERGY"), arg_14_0.cost))
end

function var_0_0.initContinueBtn(arg_15_0)
	arg_15_0:nodeByName("continue_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_15_0.incubus.times < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TRIAL_NO_TIMES_LEFT")
				})

				return
			end

			if arg_15_0.player.energy < arg_15_0.cost then
				arg_15_0:buyEnergy()

				return
			end

			local var_16_0 = {
				type = xyd.SelectTeamType.INCUBUS,
				bannedHeros = var_0_2:banList(arg_15_0.id),
				campaignType = xyd.CampaignType.INCUBUS,
				campaignID = arg_15_0.id
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_16_0)
		end
	end)
end

function var_0_0.buyEnergy(arg_17_0)
	local var_17_0 = arg_17_0.player.buyEnergyTimes
	local var_17_1 = xyd.tables.refreshCost:buyEnergyCost(var_17_0 + 1)

	if var_17_0 >= xyd.tables.vip:numEnergy(arg_17_0.player.vip) then
		local var_17_2 = xyd.luaStringSplit(string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), var_17_0), "\n")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_17_2, function()
			xyd.WindowManager.get():openWindow("vip_recharge", {
				windowState = false
			})
			xyd.WindowManager.get():closeWindow("add_energy")
		end, nil, nil, arg_17_0.colorMode)
	else
		local var_17_3 = xyd.luaStringSplit(string.format(var_0_1:translation("ADD_ENERGY"), var_17_1, 120, var_17_0), "\n")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_17_3, function()
			if var_17_1 > arg_17_0.player.crystal then
				arg_17_0:chargeAlert()
			else
				xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY):addEnergy(function(arg_20_0)
					if arg_20_0 == xyd.error.OK then
						return true
					end
				end)
				xyd.WindowManager.get():closeWindow("common_alert")
			end
		end, nil, 0, arg_17_0.colorMode)
	end
end

function var_0_0.chargeAlert(arg_21_0)
	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
		xyd.WindowManager.get():openWindow("vip_recharge", {
			windowState = true
		})
	end, nil, nil, arg_21_0.colorMode)
end

function var_0_0.didOpen(arg_23_0, arg_23_1)
	arg_23_0:nodeByName("close_btn"):addTouchEventListener(function(arg_24_0, arg_24_1)
		if arg_24_1 == ccui.TouchEventType.ended then
			audio.playSound(xyd.tables.sound:getSound("ui_close_window"), false)
			xyd.WindowManager.get():closeWindow(arg_23_0)
		end
	end)
end

return var_0_0
