local var_0_0 = class("LvbuRaffleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.lvbuRaffleShop
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = import("framework.scheduler")
local var_0_5 = 161
local var_0_6 = 114
local var_0_7 = 150
local var_0_8 = 59009000
local var_0_9 = {
	Vip = 22,
	Normal = 21
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.exchangeLimit = arg_1_0.lvbuFestival:getExchangeLimit()
	arg_1_0.items = {}
	arg_1_0.raffleType = var_0_9.Normal
	arg_1_0.selectedEffectS = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.startPos = arg_2_0:nodeByName("start_pos")
	arg_2_0.shopContainer = arg_2_0:nodeByName("shop_container")

	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.LVBU_DOOR_BRANCH_FESIBLE
	})
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("bg"):setLocalZOrder(5)
	arg_4_0:nodeByName("bg"):setTouchSwallowEnabled(false)
	arg_4_0:nodeByName("normal_raffle_text1"):setString(var_0_1:translation("LVBU_NEW_TXT1"))
	arg_4_0:nodeByName("normal_raffle_text2"):setString(var_0_1:translation("LVBU_NEW_TXT1"))
	arg_4_0:nodeByName("vip_raffle_text1"):setString(var_0_1:translation("LVBU_NEW_TXT2"))
	arg_4_0:nodeByName("vip_raffle_text2"):setString(var_0_1:translation("LVBU_NEW_TXT2"))
	arg_4_0:nodeByName("gift_tips_container"):setVisible(false)

	arg_4_0.centre = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/raffle/centre_item.csb")

	arg_4_0.centre:addTo(arg_4_0.startPos)

	local var_4_0 = arg_4_0.centre:getChildByName("container")

	var_4_0:getChildByName("lucky_value_desc"):setString(var_0_1:translation("LUCKY_VALUE_DESC"))
	var_4_0:getChildByName("current_luck_text"):setString(var_0_1:translation("LVBU_NEW_TXT3"))
	var_4_0:getChildByName("raffle60_btn"):getChildByName("raffle60_text"):setString(var_0_1:translation("LVBU_NEW_TXT4"))
	var_4_0:getChildByName("raffle60_btn"):getChildByName("free"):setString(var_0_1:translation("SUMMON_PRICE_FREE"))
	var_4_0:getChildByName("raffle270_btn"):getChildByName("raffle270_text"):setString(var_0_1:translation("LVBU_NEW_TXT5"))
	var_4_0:setPosition(cc.p(var_0_5, var_0_6))
	xyd.nodeEventSample(var_4_0:getChildByName("raffle60_btn"), nil, function()
		local var_5_0 = xyd.tables.summon:crystal(arg_4_0.raffleType)

		if arg_4_0.lvbuFestival.free_summon_times > 0 then
			arg_4_0:raffle(1)
		else
			arg_4_0:raffle(2)
		end
	end)
	xyd.nodeEventSample(var_4_0:getChildByName("raffle270_btn"), nil, function()
		local var_6_0 = xyd.tables.summon:crystalTen(arg_4_0.raffleType)

		arg_4_0:raffle(3)
	end)
	xyd.nodeEventSample(var_4_0:getChildByName("rule_btn"), nil, function()
		xyd.WindowManager.get():openWindow("new_text_rule", {
			title_name = "LVBU_RAFFLE_RULER_TITLE",
			rule = "LVBU_RAFFLE_RULER"
		})
	end)
	arg_4_0:nodeByName("normal_raffle_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_4_0.raffleType = var_0_9.Normal

			arg_4_0:updateRaffleBtnState()
		end
	end)
	arg_4_0:nodeByName("vip_raffle_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_4_0.raffleType = var_0_9.Vip

			arg_4_0:updateRaffleBtnState()
		end
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_close"), nil, function()
		xyd.WindowManager.get():closeWindow(arg_4_0)
	end)
	arg_4_0:updateRaffleBaseOnType()
	arg_4_0:updateGifts()
	arg_4_0:initShop()
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	arg_11_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 150))
	arg_11_0:addBlockLayer2()
	arg_11_0.blockLayer2_:setVisible(false)
end

function var_0_0.initShop(arg_12_0)
	arg_12_0:nodeByName("label_my_num"):setString(arg_12_0.lvbuFestival.luckyStar)

	local var_12_0 = arg_12_0:nodeByName("shop_list")
	local var_12_1 = var_12_0:getContentSize()
	local var_12_2 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_12_1.width, var_12_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_12_0)
	local var_12_3 = 146
	local var_12_4 = math.ceil(var_0_2.count / 2)

	for iter_12_0 = 1, var_12_4 do
		local var_12_5 = var_12_2:newItem()
		local var_12_6 = display.newNode()

		for iter_12_1 = 1, 2 do
			local var_12_7 = (iter_12_0 - 1) * 2 + iter_12_1

			if var_12_7 > var_0_2.count then
				break
			end

			local var_12_8 = arg_12_0:createShopItem(var_12_7)

			var_12_8:addTo(var_12_6)
			var_12_8:setPosition((iter_12_1 - 1) * 405, 0)
		end

		var_12_6:setContentSize(var_12_1.width, var_12_3)
		var_12_5:setItemSize(var_12_1.width, var_12_3)
		var_12_5:addContent(var_12_6)
		var_12_2:addItem(var_12_5)
	end

	var_12_2:reload()
end

function var_0_0.createShopItem(arg_13_0, arg_13_1)
	local var_13_0
	local var_13_1 = var_0_2:vip(arg_13_1)

	if var_13_1 > 0 then
		var_13_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/raffle/shop_item_rare.csb")
	else
		var_13_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/raffle/shop_item.csb")
	end

	local var_13_2 = var_13_0:getChildByName("container")
	local var_13_3 = var_13_2:getChildByName("btn")
	local var_13_4 = xyd.tables.gift:items(var_0_2:gift(arg_13_1))[1]
	local var_13_5 = var_0_2:cost(arg_13_1)
	local var_13_6 = var_0_2:limit(arg_13_1)
	local var_13_7 = arg_13_0.exchangeLimit[arg_13_1]

	xyd.setItemAndAddTips(var_13_2:getChildByName("item_container"), var_13_4, var_0_2:num(arg_13_1))
	var_13_2:getChildByName("label_name"):setString(xyd.tables.item:name(var_13_4))
	var_13_2:getChildByName("label_num"):setString(var_13_5)
	var_13_3:getChildByName("txt"):setString(var_0_1:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT2"))

	if var_13_6 ~= -1 then
		var_13_2:getChildByName("txt_limit"):setString("(" .. var_13_7 .. "/" .. var_13_6 .. ")")
	else
		var_13_2:getChildByName("txt_limit"):setVisible(false)
	end

	xyd.nodeEventSample(var_13_3, nil, function()
		if arg_13_0.selfPlayer.vip < var_13_1 then
			xyd.WindowManager.get():openWindow("toast", {
				message = string.format(var_0_1:translation("ACTIVITY_VIP_BOX_DRAW_LEV_TIP"), var_0_2:vip(arg_13_1))
			})

			return
		end

		if var_13_5 > arg_13_0.lvbuFestival.luckyStar then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("SQUARE_TURNTABLE2_POINT_TIP")
			})

			return
		end

		if var_13_6 ~= -1 and var_13_7 >= var_13_6 then
			return
		end

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
			var_0_1:translation("LV_EXCHANGE_TIPS")
		}, function()
			arg_13_0.lvbuFestival:shopExchange({
				id = arg_13_1
			}, function(arg_16_0, arg_16_1)
				arg_13_0.exchangeLimit = arg_16_1.exchange_times
				arg_13_0.lvbuFestival.exchangeLimit = arg_16_1.exchange_times
				var_13_7 = arg_13_0.exchangeLimit[arg_13_1]

				if var_13_6 ~= -1 then
					var_13_2:getChildByName("txt_limit"):setString("(" .. var_13_7 .. "/" .. var_13_6 .. ")")
				else
					var_13_2:getChildByName("txt_limit"):setVisible(false)
				end

				arg_13_0:nodeByName("label_my_num"):setString(arg_13_0.lvbuFestival.luckyStar)
				arg_13_0.selfPlayer:handleRewards(arg_16_1.awards)
			end)
		end)
	end)

	return var_13_0
end

function var_0_0.raffle(arg_17_0, arg_17_1)
	if arg_17_0.raffleType == var_0_9.Vip and arg_17_0.selfPlayer.vip < xyd.tables.misc.lvbuVipLimit then
		local var_17_0 = string.format(var_0_1:translation("UNDER_RAFFLE_VIP_LIMIT"), xyd.tables.misc.lvbuVipLimit)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_17_0
		})

		return
	end

	local var_17_1 = xyd.tables.summon:crystals(arg_17_0.raffleType)[arg_17_1]

	if var_17_1 > arg_17_0.selfPlayer.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
			local var_18_0 = {}

			var_18_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_18_0)
		end, nil, nil, arg_17_0.colorMode)
	else
		local var_17_2 = string.format(xyd.tables.translation:translation("LVBU_SURE_COST_TO_RAFFLE"), var_17_1)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_17_2, function()
			local var_19_0 = {
				summon_type = arg_17_0.raffleType,
				summon_index = arg_17_1
			}

			arg_17_0.lvbuFestival:summon(var_19_0, function(arg_20_0, arg_20_1)
				if arg_20_0 == xyd.error.OK then
					arg_17_0.isOnSimulation = true

					arg_17_0:simulationRaffle(arg_20_1.awards)
					arg_17_0:updateRaffleBtnState()
					arg_17_0:nodeByName("label_my_num"):setString(arg_17_0.lvbuFestival.luckyStar)
				end
			end)
		end, nil, nil, arg_17_0.colorMode)
	end
end

function var_0_0.updateRaffleBaseOnType(arg_21_0)
	arg_21_0.items = {}
	arg_21_0.luckyLabel = xyd.AssetLoader.get():loadLabel(nil, "lucky_value")

	arg_21_0.luckyLabel:setAnchorPoint(cc.p(0.5, 0.5))
	arg_21_0.centre:getChildByName("container"):getChildByName("lucky_value_pos"):removeAllChildren(true)
	arg_21_0.luckyLabel:addTo(arg_21_0.centre:getChildByName("container"):getChildByName("lucky_value_pos"))

	local var_21_0 = arg_21_0.startPos:getChildren()

	if var_21_0 then
		for iter_21_0, iter_21_1 in ipairs(var_21_0) do
			if iter_21_1 ~= arg_21_0.centre then
				arg_21_0.startPos:removeChild(iter_21_1)
			end
		end
	end

	local var_21_1 = xyd.tables.activityLvbuRaffle

	if arg_21_0.raffleType == var_0_9.Vip then
		var_21_1 = xyd.tables.activityLvbuVipRaffle
	end

	arg_21_0:updateLuckyLabel()

	for iter_21_2 = 1, var_21_1:getCounts() do
		local var_21_2 = var_21_1:itemID(iter_21_2)
		local var_21_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/raffle/raffle_item.csb")
		local var_21_4 = var_21_3:getChildByName("container")

		xyd.setItemAndAddTips(var_21_4:getChildByName("icon_container"), var_21_2)
		var_21_4:getChildByName("name_txt"):setString(xyd.tables.item:name(var_21_2))
		var_21_4:getChildByName("item_num_txt"):setString(var_21_1:itemNum(iter_21_2))

		if var_21_1:isValua(iter_21_2) == 0 then
			var_21_4:getChildByName("rare_item_bg"):setVisible(false)
			var_21_4:getChildByName("name_txt"):setColor(cc.c3b(255, 255, 255))
			var_21_4:getChildByName("name_txt"):enableOutline(cc.c4b(155, 31, 2, 255), 2)
		else
			var_21_4:getChildByName("name_txt"):enableOutline(cc.c4b(199, 52, 0, 255), 2)
		end

		var_21_3:addTo(arg_21_0.startPos)
		var_21_3:setPosition(cc.p(var_0_5 * var_21_1:x(iter_21_2), var_0_6 * var_21_1:y(iter_21_2)))

		arg_21_0.items[iter_21_2] = var_21_3
	end

	arg_21_0:updateRaffleBtnState()
end

function var_0_0.updateLuckyLabel(arg_22_0)
	if arg_22_0.raffleType == var_0_9.Vip then
		arg_22_0.luckyLabel:setString(math.floor(arg_22_0.lvbuFestival.details.super / var_0_7))
	else
		arg_22_0.luckyLabel:setString(math.floor(arg_22_0.lvbuFestival.details.normal / var_0_7))
	end
end

function var_0_0.updateRaffleBtnState(arg_23_0)
	dump(arg_23_0.raffleType)

	if arg_23_0.raffleType == var_0_9.Normal then
		arg_23_0.startPos:setVisible(true)
		arg_23_0.shopContainer:setVisible(false)
		arg_23_0:nodeByName("normal_raffle_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_23_0:nodeByName("normal_raffle_btn"):pos(110, 576.5)
		arg_23_0:nodeByName("normal_raffle_btn"):setLocalZOrder(10)
		arg_23_0:nodeByName("vip_raffle_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("vip_raffle_btn"):pos(126, 502.5)
		arg_23_0:nodeByName("vip_raffle_btn"):setLocalZOrder(0)
		arg_23_0:nodeByName("normal_raffle_text1"):setVisible(true)
		arg_23_0:nodeByName("normal_raffle_text2"):setVisible(false)
		arg_23_0:nodeByName("vip_raffle_text1"):setVisible(false)
		arg_23_0:nodeByName("vip_raffle_text2"):setVisible(true)
	else
		arg_23_0.startPos:setVisible(false)
		arg_23_0.shopContainer:setVisible(true)
		arg_23_0:nodeByName("normal_raffle_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("normal_raffle_btn"):pos(126, 576.5)
		arg_23_0:nodeByName("normal_raffle_btn"):setLocalZOrder(0)
		arg_23_0:nodeByName("vip_raffle_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_23_0:nodeByName("vip_raffle_btn"):pos(110, 502.5)
		arg_23_0:nodeByName("vip_raffle_btn"):setLocalZOrder(10)
		arg_23_0:nodeByName("normal_raffle_text1"):setVisible(false)
		arg_23_0:nodeByName("normal_raffle_text2"):setVisible(true)
		arg_23_0:nodeByName("vip_raffle_text1"):setVisible(true)
		arg_23_0:nodeByName("vip_raffle_text2"):setVisible(false)
	end

	local var_23_0 = arg_23_0.centre:getChildByName("container")

	if arg_23_0.lvbuFestival.free_summon_times > 0 then
		var_23_0:getChildByName("raffle60_btn"):getChildByName("free"):setVisible(true)
		var_23_0:getChildByName("raffle60_btn"):getChildByName("raffle60_text"):setVisible(false)
		var_23_0:getChildByName("raffle60_btn"):getChildByName("yuanbao"):setVisible(false)
	else
		var_23_0:getChildByName("raffle60_btn"):getChildByName("free"):setVisible(false)
		var_23_0:getChildByName("raffle60_btn"):getChildByName("raffle60_text"):setVisible(true)
		var_23_0:getChildByName("raffle60_btn"):getChildByName("yuanbao"):setVisible(true)
	end
end

function var_0_0.simulationRaffle(arg_24_0, arg_24_1)
	arg_24_0.blockLayer2_:setVisible(true)

	local var_24_0 = clone(arg_24_1)
	local var_24_1 = xyd.tables.activityLvbuRaffle

	if arg_24_0.raffleType == var_0_9.Vip then
		var_24_1 = xyd.tables.activityLvbuVipRaffle
	end

	local var_24_2 = 0
	local var_24_3 = var_24_1:getCounts()

	if arg_24_0.handle then
		var_0_4.unscheduleGlobal(arg_24_0.handle)

		arg_24_0.handle = nil
	end

	local var_24_4 = 1
	local var_24_5 = arg_24_0:getRandomRotateCount()
	local var_24_6 = 0.05
	local var_24_7 = 0
	local var_24_8 = math.random(2, 4)

	arg_24_0.handle = var_0_4.scheduleGlobal(function()
		var_24_7 = var_24_7 + 1

		if var_24_2 > 0 and not arg_24_0.isOnSimulationt then
			var_24_2 = var_24_2 - 1

			if var_24_2 <= 0 and arg_24_0.effect then
				arg_24_0.effect:setVisible(true)
			end
		elseif not arg_24_0 or tolua.isnull(arg_24_0) or #var_24_0 < 1 or arg_24_0.forceStopSimulation then
			arg_24_0.isOnSimulation = false
			arg_24_0.forceStopSimulation = false

			if arg_24_0.handle then
				arg_24_0.blockLayer2_:setVisible(false)
				var_0_4.unscheduleGlobal(arg_24_0.handle)

				arg_24_0.handle = nil

				var_0_4.performWithDelayGlobal(function()
					if arg_24_0 and not tolua.isnull(arg_24_0) then
						arg_24_0:updateLuckyLabel()
						arg_24_0:updateGifts()
						arg_24_0:releaseAllEffects()
						arg_24_0.selfPlayer:handleRewards(arg_24_1)
					end
				end, 0.5)
			end
		elseif var_24_5 > 0 then
			if var_24_5 < var_24_8 and var_24_7 % 2 == 0 or var_24_5 >= var_24_8 then
				var_24_5 = var_24_5 - 1
				var_24_4 = var_24_4 - 1
				var_24_4 = (var_24_4 - 1 + var_24_3) % var_24_3 + 1

				arg_24_0:addSelectEffectForItem(arg_24_0.items[var_24_4])
			end
		elseif var_24_7 % 2 == 0 then
			var_24_4 = var_24_4 - 1
			var_24_4 = (var_24_4 - 1 + var_24_3) % var_24_3 + 1

			arg_24_0:addSelectEffectForItem(arg_24_0.items[var_24_4])

			if var_24_1:itemID(var_24_4) == xyd.tables.item:heroID(var_24_0[1].table_id) or var_24_1:itemID(var_24_4) == var_0_8 and var_24_0[1].table_id == -1 or var_24_1:itemID(var_24_4) == var_24_0[1].table_id and var_24_1:itemNum(var_24_4) == (var_24_0[1].item_num or 1) then
				table.remove(var_24_0, 1)

				var_24_2 = 10

				arg_24_0:addSelectedEffectForItem(arg_24_0.items[var_24_4])

				if arg_24_0.selectedEffect then
					arg_24_0.selectedEffect:setVisible(true)
				end

				if arg_24_0.effect then
					arg_24_0.effect:setVisible(false)
				end
			end
		end
	end, var_24_6)
end

function var_0_0.getRandomRotateCount(arg_27_0)
	return xyd.tables.activityLvbuRaffle:getCounts() * math.random(2, 3)
end

function var_0_0.addSelectEffectForItem(arg_28_0, arg_28_1)
	if not arg_28_1 or tolua.isnull(arg_28_1) then
		return
	end

	if not arg_28_0.effect or tolua.isnull(arg_28_0.effect) then
		local var_28_0 = "skeletons/ui_effect/raffle/effect_raffle1" .. ".json"
		local var_28_1 = "skeletons/ui_effect/raffle/effect_raffle1" .. ".atlas"

		arg_28_0.effect = var_0_3.new(var_28_0, var_28_1, 1)

		arg_28_0.effect:addTo(arg_28_0.startPos)
		arg_28_0.effect:setName("effect")
		arg_28_0.effect:play(nil, true)
	end

	arg_28_1:getPosition()
	arg_28_0.effect:setPosition(cc.p(arg_28_1:getPositionX() + 80, arg_28_1:getPositionY() + 64))
end

function var_0_0.addSelectedEffectForItem(arg_29_0, arg_29_1)
	if not arg_29_1 or tolua.isnull(arg_29_1) then
		return
	end

	local var_29_0 = "skeletons/ui_effect/raffle/effect_raffle2" .. ".json"
	local var_29_1 = "skeletons/ui_effect/raffle/effect_raffle2" .. ".atlas"
	local var_29_2 = var_0_3.new(var_29_0, var_29_1, 1)

	var_29_2:addTo(arg_29_0.startPos)
	var_29_2:setName("effect")
	var_29_2:play(nil, true)
	arg_29_1:getPosition()
	var_29_2:setPosition(cc.p(arg_29_1:getPositionX() + 80, arg_29_1:getPositionY() + 64))
	table.insert(arg_29_0.selectedEffectS, var_29_2)
end

function var_0_0.releaseAllEffects(arg_30_0)
	if not arg_30_0 or tolua.isnull(arg_30_0) then
		return
	end

	for iter_30_0, iter_30_1 in ipairs(arg_30_0.selectedEffectS) do
		if not tolua.isnull(iter_30_1) then
			iter_30_1:removeSelf()
		end
	end

	if arg_30_0.effect and not tolua.isnull(arg_30_0.effect) then
		arg_30_0.effect:removeSelf()

		arg_30_0.effect = nil
	end

	arg_30_0.selectedEffectS = {}
end

function var_0_0.updateGifts(arg_31_0)
	arg_31_0:nodeByName("gift_pos"):removeAllChildren(true)
	arg_31_0:nodeByName("extra_award_text"):setString(var_0_1:translation("EXTRA_AWARD_TEXT"))
	arg_31_0:nodeByName("count_time_txt"):setString(string.format(var_0_1:translation("N_TIMES_TEXT"), arg_31_0.lvbuFestival.details.summon_times))

	for iter_31_0 = 1, xyd.tables.activityLvbuRaffleGift:getCounts() do
		local var_31_0 = xyd.tables.activityLvbuRaffleGift:itemID(iter_31_0)
		local var_31_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/raffle/gift_item.csb")
		local var_31_2 = var_31_1:getChildByName("container")

		var_31_2:getChildByName("time_txt"):setString(xyd.tables.activityLvbuRaffleGift:raffleTime(iter_31_0))
		var_31_1:addTo(arg_31_0:nodeByName("gift_pos"))
		var_31_1:setPositionY(-(iter_31_0 - 1) * var_31_2:getContentSize().height)
		var_31_2:getChildByName("gift_light"):setVisible(false)
		var_31_2:getChildByName("gift_gray"):setVisible(false)
		var_31_2:getChildByName("gift_open"):setVisible(false)
		var_31_2:getChildByName("time_txt"):enableOutline(cc.c4b(47, 61, 113, 255), 2)

		if arg_31_0.lvbuFestival.details.summon_times < xyd.tables.activityLvbuRaffleGift:raffleTime(iter_31_0) then
			var_31_2:getChildByName("gift_gray"):setVisible(true)
			var_31_2:getChildByName("time_txt"):enableOutline(cc.c4b(78, 78, 78, 255), 2)
		elseif arg_31_0.lvbuFestival.isAwards[iter_31_0] == 0 then
			var_31_2:getChildByName("gift_light"):setVisible(true)
		else
			var_31_2:getChildByName("gift_open"):setVisible(true)
		end

		var_31_2:getChildByName("gift_light"):setTouchEnabled(true)
		var_31_2:getChildByName("gift_light"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_32_0)
			if arg_32_0.name == "began" then
				var_31_2:getChildByName("gift_light"):setScale(0.9)

				return true
			elseif arg_32_0.name == "ended" then
				var_31_2:getChildByName("gift_light"):setScale(1)
				arg_31_0.activitiesModel:getActivityReward(arg_31_0.lvbuFestival.activity.table_id, iter_31_0, function(arg_33_0, arg_33_1)
					if arg_33_0 == xyd.error.OK then
						arg_31_0.lvbuFestival.isAwards[iter_31_0] = 1

						arg_31_0.selfPlayer:handleRewards(arg_33_1.awards)
						var_31_2:getChildByName("gift_light"):setVisible(false)
						var_31_2:getChildByName("gift_open"):setVisible(true)
					end
				end)
			end
		end)
		var_31_2:getChildByName("gift_gray"):setTouchEnabled(true)
		var_31_2:getChildByName("gift_gray"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_34_0)
			if arg_34_0.name == "began" then
				var_31_2:getChildByName("gift_gray"):setScale(0.9)
				xyd.setItemBorder(arg_31_0:nodeByName("icon_container"), var_31_0)
				arg_31_0:nodeByName("item_num_txt"):setString(xyd.tables.activityLvbuRaffleGift:itemNum(iter_31_0))

				local var_34_0 = arg_31_0:nodeByName("gift_pos"):getPositionY()

				arg_31_0:nodeByName("gift_tips_container"):setPositionY(var_34_0 - (iter_31_0 - 1) * var_31_2:getContentSize().height)
				arg_31_0:nodeByName("gift_tips_container"):setVisible(true)

				return true
			elseif arg_34_0.name == "ended" then
				var_31_2:getChildByName("gift_gray"):setScale(1)
				arg_31_0:nodeByName("gift_tips_container"):setVisible(false)
			end
		end)
	end
end

function var_0_0.didClose(arg_35_0, arg_35_1)
	var_0_0.super.didClose(arg_35_1)

	if arg_35_0.handle then
		var_0_4.unscheduleGlobal(arg_35_0.handle)

		arg_35_0.handle = nil
	end
end

function var_0_0.addBlockLayer2(arg_36_0)
	arg_36_0.blockLayer2_ = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	local var_36_0 = arg_36_0:nodeByName("container"):convertToWorldSpace(cc.p(0, 0))

	arg_36_0.blockLayer2_:pos(-var_36_0.x, -var_36_0.y):addTo(arg_36_0:nodeByName("container"), 20)
	arg_36_0.blockLayer2_:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_36_0.blockLayer2_:setTouchEnabled(true)
	arg_36_0.blockLayer2_:setTouchSwallowEnabled(true)
	arg_36_0.blockLayer2_:setVisible(false)
	arg_36_0.blockLayer2_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_37_0)
		if arg_37_0.name == "began" then
			return true
		elseif arg_37_0.name == "ended" then
			arg_36_0.blockLayer2_:setVisible(false)

			arg_36_0.forceStopSimulation = true
		end
	end)
end

return var_0_0
