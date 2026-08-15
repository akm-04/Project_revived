local var_0_0 = class("ActivityCardMatchMemoryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityCardMatch
local var_0_3 = 6
local var_0_4 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_2.details
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.card_container = arg_4_0:nodeByName("card_container")

	arg_4_0:initCard()
end

function var_0_0.initCard(arg_5_0)
	arg_5_0.cardItems = {}

	arg_5_0.card_container:removeAllChildren(true)

	for iter_5_0 = 1, var_0_4 do
		for iter_5_1 = 1, var_0_3 do
			local var_5_0 = arg_5_0:getCardItem()

			arg_5_0.cardItems[(iter_5_0 - 1) * var_0_3 + iter_5_1] = var_5_0

			var_5_0:addTo(arg_5_0.card_container)
			var_5_0:setPosition(cc.p((iter_5_1 - 1) * 110 + 10, (iter_5_0 - 1) * 135 + 5))
		end
	end

	arg_5_0:showAllCardsInObverseSide(true)
end

function var_0_0.showAllCardsInObverseSide(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in pairs(arg_6_0.cardItems) do
		local var_6_0 = iter_6_1:getChildByName("source"):getChildByName("container")

		var_6_0:getChildByName("bg1"):setVisible(false)
		var_6_0:getChildByName("bg2"):setVisible(true)

		local var_6_1 = var_6_0:getChildByName("bg2"):getChildByName("icon_container")

		var_6_1:removeAllChildren(true)

		if arg_6_1 then
			local var_6_2 = arg_6_0.details.cards[math.ceil(iter_6_0 / 2)]
			local var_6_3 = var_0_2:itemId(var_6_2)
			local var_6_4 = var_0_2:itemNum(var_6_2)

			if var_6_3 > 0 then
				xyd.setItemAndAddTips(var_6_1, var_6_3, var_6_4)
			else
				local var_6_5 = xyd.AssetLoader.get():loadSprite("windows/activities/1161/main/special_item.png")

				xyd.displaySpriteOnContainer(var_6_5, var_6_1)
			end
		end
	end
end

function var_0_0.getCardItem(arg_7_0)
	local var_7_0 = display.newNode()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1161/card_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")

	var_7_1:addTo(var_7_0)
	var_7_1:setAnchorPoint(cc.p(0, 0))
	var_7_0:setContentSize(var_7_2:getContentSize())
	var_7_1:setName("source")

	return var_7_0
end

return var_0_0
