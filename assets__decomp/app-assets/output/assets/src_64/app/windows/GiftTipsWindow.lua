local var_0_0 = class("GiftTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.gift
local var_0_3 = 60
local var_0_4 = 70

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.title = arg_1_2.title or var_0_1:translation("MISSION_REWARD_TIPS")
	arg_1_0.titleColor = arg_1_2.title_color
	arg_1_0.giftID = arg_1_2.gift_id
	arg_1_0.awards = arg_1_2.awards or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	audio.playSound(var_2_0, false)
	var_0_0.super.willOpen()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen()
	arg_3_0:setTouchSwallowEnabled(true)
end

function var_0_0.willClose(arg_4_0)
	var_0_0.super.willClose()
end

function var_0_0.didClose(arg_5_0)
	var_0_0.super.didClose()
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("tips_txt"):setString(arg_6_0.title)

	if arg_6_0.titleColor then
		arg_6_0:nodeByName("tips_txt"):setColor(arg_6_0.titleColor)
	end

	if arg_6_0.giftID then
		arg_6_0:showGift()
	else
		arg_6_0:showAwards()
	end
end

function var_0_0.showGift(arg_7_0)
	arg_7_0.awards = arg_7_0:getAwards()

	arg_7_0:showAwards()
end

function var_0_0.showAwards(arg_8_0)
	local var_8_0 = #arg_8_0.awards
	local var_8_1 = var_8_0 * var_0_4 - 10

	arg_8_0:nodeByName("container"):setContentSize(342, var_8_1 + 85)
	arg_8_0:nodeByName("item_container"):setContentSize(290, var_8_1)
	arg_8_0:nodeByName("tips_txt"):setPositionY(var_8_1 + 69)
	arg_8_0:nodeByName("bg_line"):setPositionY(var_8_1 + 33)

	for iter_8_0 = 1, var_8_0 do
		local var_8_2 = arg_8_0.awards[iter_8_0]
		local var_8_3 = cc.Node:create()

		var_8_3:setContentSize(var_0_3, var_0_3)

		if var_8_2.item_id > 0 then
			xyd.setItemBorder(var_8_3, var_8_2.item_id)
		else
			local var_8_4 = xyd.tables.asset:transparentIcon(var_8_2.item_id)
			local var_8_5 = xyd.AssetLoader:get():loadSprite(var_8_4)

			xyd.displaySpriteOnContainer(var_8_5, var_8_3, false)
		end

		var_8_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_3:setPosition(var_0_4 / 2, var_8_1 - iter_8_0 * var_0_4 + var_0_4 / 2 + 5)
		arg_8_0:nodeByName("item_container"):addChild(var_8_3)

		local var_8_6 = {
			size = 22,
			color = cc.c4b(255, 239, 148, 255)
		}
		local var_8_7 = xyd.AssetLoader:get():loadLabel(var_8_6)

		if var_8_2.item_id < 0 then
			var_8_7:setString("X " .. var_8_2.item_num)
		else
			local var_8_8 = xyd.tables.item:name(var_8_2.item_id)

			var_8_7:setString(var_8_8 .. " X " .. var_8_2.item_num)
		end

		var_8_7:setAnchorPoint(cc.p(0, 0.5))
		var_8_7:setPosition(95, var_8_1 - iter_8_0 * var_0_4 + var_0_4 / 2 + 5)
		arg_8_0:nodeByName("item_container"):addChild(var_8_7)
	end
end

function var_0_0.getAwards(arg_9_0)
	local var_9_0 = {}

	if var_0_2:crystal(arg_9_0.giftID) > 0 then
		table.insert(var_9_0, {
			item_id = -1,
			item_num = var_0_2:crystal(arg_9_0.giftID)
		})
	end

	if var_0_2:mana(arg_9_0.giftID) > 0 then
		table.insert(var_9_0, {
			item_id = -2,
			item_num = var_0_2:mana(arg_9_0.giftID)
		})
	end

	if var_0_2:arenaCoin(arg_9_0.giftID) > 0 then
		table.insert(var_9_0, {
			item_id = -3,
			item_num = var_0_2:arenaCoin(arg_9_0.giftID)
		})
	end

	if var_0_2:marchCoin(arg_9_0.giftID) > 0 then
		table.insert(var_9_0, {
			item_id = -4,
			item_num = var_0_2:marchCoin(arg_9_0.giftID)
		})
	end

	if var_0_2:exp(arg_9_0.giftID) > 0 then
		table.insert(var_9_0, {
			item_id = -15,
			item_num = var_0_2:exp(arg_9_0.giftID)
		})
	end

	if var_0_2:skinCoin(arg_9_0.giftID) > 0 then
		table.insert(var_9_0, {
			item_id = -17,
			item_num = var_0_2:skinCoin(arg_9_0.giftID)
		})
	end

	local var_9_1 = var_0_2:items(arg_9_0.giftID)
	local var_9_2 = var_0_2:itemNum(arg_9_0.giftID)

	for iter_9_0 = 1, #var_9_1 do
		table.insert(var_9_0, {
			item_id = var_9_1[iter_9_0],
			item_num = var_9_2[iter_9_0]
		})
	end

	return var_9_0
end

function var_0_0.getTipHeight(arg_10_0)
	return arg_10_0:nodeByName("container"):getHeight()
end

function var_0_0.getTipWidth(arg_11_0)
	return arg_11_0:nodeByName("container"):getWidth()
end

return var_0_0
