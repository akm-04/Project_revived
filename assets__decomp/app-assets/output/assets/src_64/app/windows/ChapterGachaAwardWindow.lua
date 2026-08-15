local var_0_0 = class("ActivityGachaAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.hero
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemId = arg_1_2.table_id
	arg_1_0.itemNum = arg_1_2.item_num
	arg_1_0.is_partner = arg_1_2.is_partner
	arg_1_0.to_stone = arg_1_2.to_stone
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.item = arg_2_0:nodeByName("item")
	arg_2_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:nodeByName("award_txt"):setString(var_0_1:translation("EXTRA_CHEST_TIP4"))
	arg_2_0.item:setScale(0)
	arg_2_0.item:setVisible(false)
	arg_2_0:nodeByName("name_txt"):setString(var_0_2:name(arg_2_0.itemId))

	arg_2_0.heroId = arg_2_0.itemId

	if arg_2_0.to_stone then
		arg_2_0.heroId = var_0_2:heroID(arg_2_0.itemId)
	end

	arg_2_0:nodeByName("rare"):setVisible(false)
	arg_2_0:nodeByName("star2"):setVisible(false)
	arg_2_0:nodeByName("star3"):setVisible(false)

	local var_2_0 = cc.Node:create()
	local var_2_1 = arg_2_0.itemId

	var_2_0:setContentSize(arg_2_0.item:getContentSize())
	var_2_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_2_0:setPosition(45, 45)
	var_2_0:setVisible(true)
	arg_2_0.item:addChild(var_2_0)
	xyd.setItemAndAddTips(var_2_0, var_2_1)

	local var_2_2 = "skeletons/ui_effect/activity_anniversary/gacha_open"
	local var_2_3 = var_0_4.new(var_2_2 .. ".json", var_2_2 .. ".atlas", 1)

	var_2_3:setAnchorPoint(cc.p(0.5, 0.5))

	local var_2_4 = arg_2_0:nodeByName("container")

	var_2_3:addTo(var_2_4)
	var_2_3:play(function()
		if arg_2_0.is_partner or arg_2_0.to_stone then
			local var_3_0

			if arg_2_0.to_stone then
				var_3_0 = arg_2_0.itemNum
			end

			local var_3_1 = {
				item_index = 0,
				partnerID = arg_2_0.heroId,
				toStone = var_3_0
			}
			local var_3_2 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_3_1)
		end

		arg_2_0.item:setVisible(true)
		transition.scaleTo(arg_2_0.item, {
			scale = 1.5,
			time = var_0_5.stoneSummonDuration
		})

		local var_3_3 = "skeletons/ui_effect/common_effect_bag2/common_effect_bag2"
		local var_3_4 = var_0_4.new(var_3_3 .. ".json", var_3_3 .. ".atlas", 1)

		var_3_4:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_4:addTo(var_2_4)
		var_3_4:play(nil, false)
		arg_2_0:nodeByName("block"):setVisible(false)
	end, false)
end

function var_0_0.star(arg_4_0, arg_4_1)
	return xyd.tables.activityGachaCollection:rarityById(arg_4_1)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
end

return var_0_0
