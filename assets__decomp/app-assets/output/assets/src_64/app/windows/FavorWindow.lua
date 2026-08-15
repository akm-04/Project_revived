local var_0_0 = class("FavorWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 50001113
local var_0_3 = 50001112
local var_0_4 = 120001018

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.dialog = arg_1_2.dialog
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayerWithNoTouchEvent()
	arg_2_0.blockLayer_:setPosition(-640, -360)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:updateDescLabel()
	arg_4_0:update()
	arg_4_0:setupButtonClick()
end

function var_0_0.update(arg_5_0)
	arg_5_0:updateRedPoint()
	arg_5_0:updateFavorDegree()
	arg_5_0:updateRingBtnState()
	arg_5_0:updateGiftContainer()
	arg_5_0:updateHeartImgState()
end

function var_0_0.updateRedPoint(arg_6_0)
	if arg_6_0:isHasNewDialog() then
		arg_6_0:nodeByName("red_point"):setVisible(true)
	else
		arg_6_0:nodeByName("red_point"):setVisible(false)
	end
end

function var_0_0.isHasNewDialog(arg_7_0)
	for iter_7_0 = 1, #arg_7_0.dialog do
		if arg_7_0.dialog[iter_7_0].is_read == 0 then
			return true
		end
	end

	return false
end

function var_0_0.updateDescLabel(arg_8_0)
	arg_8_0:nodeByName("desc_txt1"):setString(var_0_1:translation("FAVOR_DESC"))
end

function var_0_0.updateFavorDegree(arg_9_0)
	local var_9_0 = arg_9_0.hero:getFavorState()
	local var_9_1

	if var_9_0 == xyd.FavorState.NOT_OPEN then
		var_9_1 = var_0_1:translation("FAVOR_FUNCTION_NOT_OPEN2")
	elseif var_9_0 == xyd.FavorState.MARRIED then
		var_9_1 = var_0_1:translation("HAVE_MARRIED")
	else
		var_9_1 = var_0_1:translation("FAVOR_DEGREE") .. arg_9_0.hero:getFavorDegree() .. "/100"
	end

	arg_9_0:nodeByName("favor_degree_txt"):setString(var_9_1)
end

function var_0_0.updateRingBtnState(arg_10_0)
	local var_10_0 = arg_10_0.hero:getFavorState()

	if var_10_0 == xyd.FavorState.FULL or var_10_0 == xyd.FavorState.MARRIED then
		arg_10_0:nodeByName("buy_gift_txt"):setVisible(false)
		arg_10_0:nodeByName("buy_ring_txt"):setVisible(true)
	else
		arg_10_0:nodeByName("buy_gift_txt"):setVisible(true)
		arg_10_0:nodeByName("buy_ring_txt"):setVisible(false)
	end
end

function var_0_0.updateHeartImgState(arg_11_0)
	local var_11_0 = arg_11_0.hero:getFavorState()

	arg_11_0:nodeByName("heart_gray"):setVisible(false)
	arg_11_0:nodeByName("heart_read"):setVisible(false)
	arg_11_0:nodeByName("heart_married"):setVisible(false)

	if var_11_0 == xyd.FavorState.NOT_OPEN then
		arg_11_0:nodeByName("heart_gray"):setVisible(true)
	elseif var_11_0 == xyd.FavorState.MARRIED then
		arg_11_0:nodeByName("heart_married"):setVisible(true)
	else
		arg_11_0:nodeByName("heart_read"):setVisible(true)
	end
end

function var_0_0.updateGiftContainer(arg_12_0)
	local var_12_0
	local var_12_1 = arg_12_0.hero:getFavorState()

	if var_12_1 == xyd.FavorState.NOT_OPEN or var_12_1 == xyd.FavorState.NOT_FULL then
		var_12_0 = var_0_2

		arg_12_0:nodeByName("own_ring_txt"):setString(var_0_1:translation("GIFT_NAME"))
		arg_12_0:nodeByName("desc_txt2"):setString(var_0_1:translation("FAVOR_DESC3"))

		local var_12_2 = arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_0_2)

		arg_12_0:nodeByName("gift_num_txt"):setString(string.format(var_0_1:translation("OWN_NUMBER"), var_12_2))
	else
		var_12_0 = var_0_3

		arg_12_0:nodeByName("own_ring_txt"):setString(var_0_1:translation("RING_NAME"))
		arg_12_0:nodeByName("desc_txt2"):setString(var_0_1:translation("FAVOR_DESC2"))

		local var_12_3 = arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_0_3)

		arg_12_0:nodeByName("gift_num_txt"):setString(string.format(var_0_1:translation("OWN_NUMBER"), var_12_3))
	end

	arg_12_0:nodeByName("gift_container"):removeAllChildren()
	arg_12_0:setItemAndAddTips(arg_12_0:nodeByName("gift_container"), var_12_0, nil)
	arg_12_0:nodeByName("send_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0
			local var_13_1

			if var_12_1 == xyd.FavorState.NOT_FULL then
				var_13_0 = var_0_1:translation("SURE_SEND_GIFT")
				var_13_1 = var_0_2
			elseif var_12_1 == xyd.FavorState.FULL then
				var_13_0 = var_0_1:translation("SURE_SEND_RING")
				var_13_1 = var_0_3
			elseif var_12_1 == xyd.FavorState.MARRIED then
				var_13_0 = var_0_1:translation("HAVE_MARRIED")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_13_0
				})

				return
			end

			if arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_13_1) <= 0 then
				local var_13_2

				if var_13_1 == var_0_2 then
					var_13_2 = var_0_1:translation("GIFT_ABSENCE")
				else
					var_13_2 = var_0_1:translation("RING_ABSENCE")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_13_2
				})

				return
			end

			if var_13_1 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_13_0, function()
					local var_14_0 = {}

					var_14_0.gift_num = 1
					var_14_0.gift_id = var_13_1
					var_14_0.partner_id = arg_12_0.hero:getHeroID()

					arg_12_0:addFavorOrMarried(var_14_0)
				end, nil, nil, arg_12_0.colorMode)
			end
		end
	end)
end

function var_0_0.setItemAndAddTips(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local var_15_0 = arg_15_1:getContentSize().height
	local var_15_1 = display.newNode()

	var_15_1:setContentSize(var_15_0, var_15_0)

	local var_15_2 = xyd.tables.item:type(arg_15_2)

	xyd.setItemBorder(var_15_1, arg_15_2, nil, nil, arg_15_3)
	var_15_1:addTo(arg_15_1)
	var_15_1:setAnchorPoint(cc.p(0, 0))

	local var_15_3 = {
		id = arg_15_2,
		lev = xyd.tables.item:level(arg_15_2)
	}

	if xyd.tables.item:type(arg_15_2) == -1 then
		var_15_3.tipsType = 0
		var_15_3.desc1 = xyd.tables.hero:getDes(arg_15_2)
	elseif specialItem then
		var_15_3.tipsType = 1
		var_15_3.id = -3
	else
		var_15_3.tipsType = 1
		var_15_3.desc1 = xyd.tables.item:desc1(arg_15_2)
		var_15_3.desc2 = xyd.tables.item:desc2(arg_15_2)
	end

	var_15_3.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_15_2)
	var_15_3.name = xyd.tables.item:name(arg_15_2)

	arg_15_0:addTips(var_15_1, var_15_3)
end

function var_0_0.addFavorOrMarried(arg_16_0, arg_16_1)
	arg_16_0.library:addFavor(arg_16_1, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			arg_16_0.selfPlayer:getBackpack():addItemsByID(arg_16_1.gift_id, -1)

			if arg_16_0.selfPlayer:getBackpack():getItemNumByID(arg_16_1.gift_id) <= 0 then
				local var_17_0 = {}

				var_17_0.itemNum = 0
				var_17_0.itemID = arg_17_1.gift_id

				arg_16_0.selfPlayer:getBackpack():removeItem(var_17_0)
			end

			if arg_16_1.gift_id == var_0_2 and arg_17_1.favor_degree then
				arg_16_0.hero:setFavorDegree(arg_17_1.favor_degree)
			end

			if arg_16_1.gift_id == var_0_3 then
				local var_17_1 = {
					hero = arg_16_0.hero
				}

				arg_16_0.hero:setMarried()

				local var_17_2 = xyd.WindowManager.get():getWindow("hero_main")

				if var_17_2 then
					var_17_2:updateFavorContainer()
				end

				if not arg_16_0.selfPlayer:getBackpack():getItemByID(var_0_4) then
					local var_17_3 = {}

					var_17_3.itemNum = 1
					var_17_3.itemID = var_0_4

					arg_16_0.selfPlayer:getBackpack():addItem(var_17_3)
				end

				xyd.WindowManager.get():openWindow("get_married", var_17_1)
			end

			if arg_17_1.partner_dialog then
				arg_16_0.dialog = arg_17_1.partner_dialog.open_dialog

				arg_16_0:updateLogs(arg_17_1)
			end
		end

		arg_16_0:update()
	end)
end

function var_0_0.updateLogs(arg_18_0, arg_18_1)
	local var_18_0 = xyd.WindowManager.get():getWindow("tujian_herodetail")

	if var_18_0 then
		var_18_0.partnerDialogs[tostring(arg_18_0.hero:getHeroID())].open_dialog = arg_18_1.partner_dialog.open_dialog

		var_18_0:updateInfoScroll()
		var_18_0:updateAbilityScroll()
		var_18_0:updateLikability()
	end
end

function var_0_0.setupButtonClick(arg_19_0)
	arg_19_0:nodeByName("visit_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_20_0 = {
				hero = arg_19_0.hero,
				dialog = arg_19_0.dialog
			}

			xyd.WindowManager.get():openWindow("hero_dialog", var_20_0)
		end
	end)
	arg_19_0:nodeByName("ring_btn"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_21_0 = var_0_2
			local var_21_1 = xyd.tables.item:priceCrystal(var_21_0)
			local var_21_2 = string.format(var_0_1:translation("COST_TO_BUY_GIFT"), var_21_1)

			if arg_19_0.hero:getFavorState() == xyd.FavorState.FULL or arg_19_0.hero:getFavorState() == xyd.FavorState.MARRIED then
				var_21_0 = var_0_3
				var_21_1 = xyd.tables.item:priceCrystal(var_21_0)
				var_21_2 = string.format(var_0_1:translation("COST_TO_BUY_RING"), var_21_1)
			end

			if var_21_1 > arg_19_0.selfPlayer.crystal then
				local var_21_3 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_21_3, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, arg_19_0.colorMode)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_21_2, function()
					local var_23_0 = {}

					var_23_0.gift_num = 1
					var_23_0.gift_id = var_21_0

					arg_19_0:buy(var_23_0)
				end, nil, nil, arg_19_0.colorMode)
			end
		end
	end)
end

function var_0_0.buy(arg_24_0, arg_24_1)
	arg_24_0.library:buyGift(arg_24_1, function(arg_25_0, arg_25_1)
		if arg_25_0 == xyd.error.OK and arg_25_1.gift_id and arg_25_1.gift_num then
			if not arg_24_0.selfPlayer:getBackpack():getItemByID(arg_25_1.gift_id) then
				local var_25_0 = {}

				var_25_0.itemNum = 0
				var_25_0.itemID = arg_25_1.gift_id

				arg_24_0.selfPlayer:getBackpack():addItem(var_25_0)
			end

			arg_24_0.selfPlayer:getBackpack():setItemNumByID(arg_25_1.gift_id, arg_25_1.gift_num)
			arg_24_0:update()
		end
	end)
end

return var_0_0
