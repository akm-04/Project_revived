local var_0_0 = class("BattlePassBuySeniorWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.battlePassReward
local var_0_3 = xyd.tables.charge
local var_0_4 = xyd.tables.gift
local var_0_5 = xyd.tables.misc
local var_0_6 = {
	var_0_5:getValue("battle_pass_charge_id"),
	var_0_5:getValue("battle_pass_deluxe_charge_id")
}
local var_0_7 = var_0_5:getValue("battle_pass_deluxe_edition_level")
local var_0_8 = var_0_5:getValue("battle_pass_extra_bonus_id")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.battlePass = xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		show_rule = true
	})
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_buy_1"):setString(var_0_1:translation("BATTLE_PASS_TEXT_18"))
	arg_3_0:nodeByName("txt_buy_2"):setString(string.format(var_0_1:translation("BATTLE_PASS_TEXT_19"), var_0_7))
	arg_3_0:nodeByName("txt_maks_1"):setString(var_0_1:translation("BATTLE_PASS_TEXT_24"))
	arg_3_0:nodeByName("txt_maks_2"):setString(var_0_1:translation("BATTLE_PASS_TEXT_24"))
	arg_3_0:nodeByName("txt_maks_1"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
	arg_3_0:nodeByName("txt_maks_2"):enableOutline(cc.c4b(0, 0, 0, 255), 2)

	if arg_3_0.battlePass:isBuySenior() then
		arg_3_0:nodeByName("mask_1"):setVisible(true)
		arg_3_0:nodeByName("mask_2"):setVisible(true)
		arg_3_0:nodeByName("mask_1"):setTouchEnabled(true)
		arg_3_0:nodeByName("mask_1"):setTouchSwallowEnabled(true)
		arg_3_0:nodeByName("mask_2"):setTouchEnabled(true)
		arg_3_0:nodeByName("mask_2"):setTouchSwallowEnabled(true)
		arg_3_0:nodeByName("bg_discount"):setVisible(false)
		arg_3_0:nodeByName("txt_original_price_2"):setVisible(false)
		arg_3_0:nodeByName("txt_price_1"):setString(var_0_1:translation("BATTLE_PASS_TEXT_35"))
		arg_3_0:nodeByName("txt_price_2"):setString(var_0_1:translation("BATTLE_PASS_TEXT_35"))
		arg_3_0:nodeByName("txt_price_2"):setAnchorPoint(cc.p(0.5, 0.5))
		arg_3_0:nodeByName("txt_price_2"):setPosition(cc.p(129, 31))
		arg_3_0:nodeByName("btn_buy_1"):setBright(false)
		arg_3_0:nodeByName("btn_buy_2"):setBright(false)
		arg_3_0:nodeByName("btn_buy_1"):setTouchEnabled(false)
		arg_3_0:nodeByName("btn_buy_2"):setTouchEnabled(false)
	else
		arg_3_0:nodeByName("mask_1"):setVisible(false)
		arg_3_0:nodeByName("mask_2"):setVisible(false)
		arg_3_0:nodeByName("bg_discount"):setVisible(true)
		arg_3_0:nodeByName("txt_original_price_2"):setVisible(true)

		local var_3_0 = var_0_1:translation("BATTLE_PASS_TEXT_22")

		arg_3_0:nodeByName("txt_price_1"):setString(var_0_3:charge(var_0_6[1]) .. var_3_0)
		arg_3_0:nodeByName("txt_price_2"):setString(var_0_3:charge(var_0_6[2]) .. var_3_0)

		local var_3_1 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_17"), math.ceil(var_0_3:charge(var_0_6[2]) / var_0_5:getValue("battle_pass_deluxe_discount")))

		arg_3_0:nodeByName("txt_original_price_2"):setString(var_3_1)
	end

	local var_3_2 = xyd.createLabel(20, cc.c3b(57, 64, 70))
	local var_3_3 = var_0_1:translation("BATTLE_PASS_TEXT_20")

	var_3_2:setAnchorPoint(0, 1)
	var_3_2:setWidth(300)
	var_3_2:setLineHeight(30)
	var_3_2:setString(var_3_3)
	arg_3_0:nodeByName("pos_desc_1"):addChild(var_3_2)

	local var_3_4 = xyd.createLabel(20, cc.c3b(57, 64, 70))
	local var_3_5 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_21"), var_0_7, var_0_7)

	var_3_4:setAnchorPoint(0, 1)
	var_3_4:setWidth(300)
	var_3_4:setLineHeight(30)
	var_3_4:setString(var_3_5)
	arg_3_0:nodeByName("pos_desc_2"):addChild(var_3_4)

	local var_3_6 = xyd.createLabel(20, cc.c3b(255, 255, 255))
	local var_3_7 = var_0_1:translation("BATTLE_PASS_TEXT_34")

	var_3_6:setAnchorPoint(0, 1)
	var_3_6:setWidth(300)
	var_3_6:setLineHeight(30)
	var_3_6:setString(var_3_7)
	arg_3_0:nodeByName("pos_desc_3"):addChild(var_3_6)

	arg_3_0.items = arg_3_0:getItems()
	arg_3_0.seniorItems = arg_3_0:getSeniorItems()
	arg_3_0.extraGift = xyd.getFormatItemsByGiftId(var_0_8)

	local var_3_8 = arg_3_0:nodeByName("list_1"):getContentSize()

	arg_3_0.list1 = cc.ui.UITableView.new({
		async = true,
		itemGap = 16,
		size = var_3_8,
		direction = cc.ui.UITableView.DIRECTION_VERTICAL,
		itemSize = cc.size(var_3_8.width, 78)
	}):addTo(arg_3_0:nodeByName("list_1"))

	arg_3_0.list1:setDelegate(handler(arg_3_0, arg_3_0.delegate1))
	arg_3_0.list1:reload()

	local var_3_9 = arg_3_0:nodeByName("list_2"):getContentSize()

	arg_3_0.list2 = cc.ui.UITableView.new({
		async = true,
		itemGap = 16,
		size = var_3_9,
		direction = cc.ui.UITableView.DIRECTION_VERTICAL,
		itemSize = cc.size(var_3_9.width, 78)
	}):addTo(arg_3_0:nodeByName("list_2"))

	arg_3_0.list2:setDelegate(handler(arg_3_0, arg_3_0.delegate2))
	arg_3_0.list2:reload()

	local var_3_10 = arg_3_0:nodeByName("list_3"):getContentSize()

	arg_3_0.list3 = cc.ui.UITableView.new({
		async = true,
		itemGap = 16,
		size = var_3_10,
		direction = cc.ui.UITableView.DIRECTION_VERTICAL,
		itemSize = cc.size(var_3_9.width, 78)
	}):addTo(arg_3_0:nodeByName("list_3"))

	arg_3_0.list3:setDelegate(handler(arg_3_0, arg_3_0.delegate3))
	arg_3_0.list3:reload()
	arg_3_0:initBtns()
end

function var_0_0.initBtns(arg_4_0)
	for iter_4_0 = 1, 2 do
		arg_4_0:nodeByName("btn_buy_" .. iter_4_0):addTouchEventListener(function(arg_5_0, arg_5_1)
			xyd.buttonScaleAnim(arg_5_0, arg_5_1)

			if arg_5_1 == ccui.TouchEventType.ended then
				if arg_4_0.battlePass:isBuySenior() then
					local var_5_0 = var_0_1:translation("BATTLE_PASS_TEXT_24")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_5_0
					})

					return
				end

				arg_4_0:purchaseGiftBag(var_0_6[iter_4_0])
			end
		end)
	end

	xyd.nodeEventSample(arg_4_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function()
		local var_6_0 = {
			title_name = "BATTLE_PASS_RULE_TITLE",
			rule = "BATTLE_PASS_RULE_TEXT",
			style = xyd.RuleStyle.BLUE
		}

		xyd.WindowManager.get():openWindow("new_text_rule", var_6_0)
	end)
end

function var_0_0.delegate1(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if arg_7_2 == cc.ui.UITableView.COUNT_TAG then
		return math.ceil(#arg_7_0.items / 3)
	elseif arg_7_2 == cc.ui.UITableView.CELL_TAG then
		local var_7_0 = arg_7_0.list1:getItem()
		local var_7_1 = arg_7_0:createContent(arg_7_3, arg_7_0.items)

		var_7_0:addContent(var_7_1)

		return var_7_0
	end
end

function var_0_0.delegate2(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if arg_8_2 == cc.ui.UITableView.COUNT_TAG then
		return math.ceil(#arg_8_0.seniorItems / 3)
	elseif arg_8_2 == cc.ui.UITableView.CELL_TAG then
		local var_8_0 = arg_8_0.list2:getItem()
		local var_8_1 = arg_8_0:createContent(arg_8_3, arg_8_0.seniorItems)

		var_8_0:addContent(var_8_1)

		return var_8_0
	end
end

function var_0_0.delegate3(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if arg_9_2 == cc.ui.UITableView.COUNT_TAG then
		return math.ceil(#arg_9_0.extraGift / 3)
	elseif arg_9_2 == cc.ui.UITableView.CELL_TAG then
		local var_9_0 = arg_9_0.list3:getItem()
		local var_9_1 = arg_9_0:createContent(arg_9_3, arg_9_0.extraGift)

		var_9_0:addContent(var_9_1)

		return var_9_0
	end
end

function var_0_0.createContent(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = display.newNode()

	for iter_10_0 = 1, 3 do
		local var_10_1 = (arg_10_1 - 1) * 3 + iter_10_0

		if not arg_10_2[var_10_1] then
			break
		end

		local var_10_2 = display.newNode()

		var_10_2:setContentSize(78, 78)
		var_10_2:setPosition((iter_10_0 - 1) * 99, 0)
		xyd.setItemAndAddTips(var_10_2, arg_10_2[var_10_1].item_id, arg_10_2[var_10_1].item_num)
		var_10_0:addChild(var_10_2)
	end

	return var_10_0
end

function var_0_0.getItems(arg_11_0)
	local var_11_0 = {}
	local var_11_1 = {}
	local var_11_2 = var_0_5:getValue("battle_pass_award_loop_range")
	local var_11_3 = var_0_5:getValue("battle_pass_award_max_level") - var_11_2

	for iter_11_0 = 1, var_11_3 do
		local var_11_4, var_11_5 = var_0_2:getItem(iter_11_0, true)

		if var_11_4 and var_11_4 ~= 0 then
			if var_11_0[var_11_4] then
				var_11_0[var_11_4] = var_11_0[var_11_4] + var_11_5
			else
				var_11_0[var_11_4] = var_11_5
			end
		end
	end

	if next(var_11_0) then
		for iter_11_1, iter_11_2 in pairs(var_11_0) do
			table.insert(var_11_1, {
				item_id = iter_11_1,
				item_num = iter_11_2
			})
		end
	end

	return var_11_1
end

function var_0_0.getSeniorItems(arg_12_0)
	local var_12_0 = {}
	local var_12_1 = {}
	local var_12_2 = var_0_5:getValue("battle_pass_award_loop_range")
	local var_12_3 = var_0_5:getValue("battle_pass_award_max_level")
	local var_12_4 = var_12_3 - var_12_2

	for iter_12_0 = 1, var_12_4 do
		local var_12_5, var_12_6 = var_0_2:getItem(iter_12_0, true)

		if var_12_5 and var_12_5 ~= 0 then
			if var_12_0[var_12_5] then
				var_12_0[var_12_5] = var_12_0[var_12_5] + var_12_6
			else
				var_12_0[var_12_5] = var_12_6
			end
		end
	end

	for iter_12_1 = arg_12_0.battlePass:getLevel() + 1, arg_12_0.battlePass:getLevel() + var_0_7 do
		local var_12_7 = iter_12_1

		if var_12_3 < iter_12_1 and (iter_12_1 - var_12_3) % var_12_2 == 0 then
			var_12_7 = var_12_3
		end

		local var_12_8, var_12_9 = var_0_2:getItem(var_12_7)

		if var_12_8 and var_12_8 ~= 0 then
			if var_12_0[var_12_8] then
				var_12_0[var_12_8] = var_12_0[var_12_8] + var_12_9
			else
				var_12_0[var_12_8] = var_12_9
			end
		end
	end

	if next(var_12_0) then
		for iter_12_2, iter_12_3 in pairs(var_12_0) do
			table.insert(var_12_1, {
				item_id = iter_12_2,
				item_num = iter_12_3
			})
		end
	end

	return var_12_1
end

function var_0_0.purchaseGiftBag(arg_13_0, arg_13_1)
	local var_13_0 = true

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_13_1
		}, {}, arg_13_1, false, var_0_3:charge(arg_13_1), var_0_3:chargeName(arg_13_1))
	elseif device.platform == "ios" then
		local var_13_1 = var_0_3:iosProductID(arg_13_1)

		xyd.sdkPurchase(var_13_1, var_13_0, arg_13_1, {}, {}, {
			arg_13_1
		})
	end
end

return var_0_0
