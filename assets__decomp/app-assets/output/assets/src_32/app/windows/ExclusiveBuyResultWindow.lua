local var_0_0 = class("ExclusiveBuyResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.misc
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.items_ = arg_1_2.items or {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 220), true)
	arg_3_0:showAnimation()
end

function var_0_0.didClose(arg_4_0)
	return
end

function var_0_0.willClose(arg_5_0)
	return
end

function var_0_0.layout(arg_6_0)
	arg_6_0.tmpNode = {}

	arg_6_0:getBackAnimation()
	arg_6_0:setItems()
	arg_6_0:setInitPosition()
	arg_6_0:getDesText():setVisible(false)
end

function var_0_0.getSummonItem(arg_7_0, arg_7_1)
	return arg_7_0:nodeByName("item_" .. arg_7_1)
end

function var_0_0.setItems(arg_8_0, arg_8_1)
	for iter_8_0, iter_8_1 in pairs(arg_8_0.items_) do
		arg_8_0:updateItemIcon(iter_8_0, iter_8_1)
	end
end

function var_0_0.updateItemIcon(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_2.item_id
	local var_9_1 = arg_9_2.item_num
	local var_9_2 = arg_9_0:getSummonItem(arg_9_1)

	var_9_2:removeAllChildren()
	xyd.setItemBorder(var_9_2, var_9_0, true, false, var_9_1)

	local var_9_3 = display.newNode()

	var_9_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_9_3:setPosition(var_9_2:getPosition())
	var_9_3:setContentSize(var_9_2:getContentSize())
	var_9_3:setLocalZOrder(100)
	var_9_3:addTo(arg_9_0:nodeByName("container"))
	table.insert(arg_9_0.tmpNode, var_9_3)

	local var_9_4 = #arg_9_0.tmpNode
	local var_9_5 = arg_9_0:nodeByName("node_pos" .. var_9_4)

	var_9_3:pos(var_9_5:getPosition())
	arg_9_0:addTips(var_9_3, var_9_0)

	local var_9_6 = {
		size = 22,
		y = -30,
		text = xyd.tables.item:name(var_9_0),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_9_2:getContentSize().width / 2
	}
	local var_9_7 = xyd.AssetLoader.get():loadLabel(var_9_6)

	var_9_7:addTo(var_9_2)
	var_9_7:setAnchorPoint(0.5, 0)
end

function var_0_0.addTips(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {
		id = arg_10_2
	}

	xyd.addTips(arg_10_1, var_10_0)
end

function var_0_0.getBackAnimation(arg_11_0)
	if not arg_11_0.effect_ then
		local var_11_0 = arg_11_0:nodeByName("container"):getContentSize()
		local var_11_1 = var_11_0.width / 2
		local var_11_2 = var_11_0.height / 2 - 50
		local var_11_3 = "skeletons/ui_effect/common_effect_summon10/common_effect_summon10"
		local var_11_4 = var_11_3 .. ".json"
		local var_11_5 = var_11_3 .. ".atlas"

		arg_11_0.effect_ = var_0_2.new(var_11_4, var_11_5, 1)

		arg_11_0.effect_:pos(var_11_1, var_11_2)
		arg_11_0.effect_:addTo(arg_11_0:nodeByName("container"), 1)
		arg_11_0.effect_:play(nil, true)
	end

	return arg_11_0.effect_
end

function var_0_0.getItemEffect(arg_12_0)
	local var_12_0 = "skeletons/ui_effect/common_effect_bag2/common_effect_bag2"
	local var_12_1 = var_12_0 .. ".json"
	local var_12_2 = var_12_0 .. ".atlas"

	return (var_0_2.new(var_12_1, var_12_2, 1))
end

function var_0_0.showAnimation(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0
	local var_13_1
	local var_13_2 = arg_13_1 or 1
	local var_13_3 = arg_13_0:getSummonItem(var_13_2)

	var_13_3:setVisible(true)
	transition.scaleTo(var_13_3, {
		scale = 1,
		time = var_0_1.stoneSummonDuration,
		onComplete = function()
			if var_13_2 == #arg_13_0.items_ then
				arg_13_0.isAnimated = false

				return
			end

			var_13_2 = var_13_2 + 1

			arg_13_0:showAnimation(var_13_2)
		end
	})

	local var_13_4 = xyd.tables.sound:getSound("draw_item_sound")

	audio.playSound(var_13_4)

	local var_13_5 = arg_13_0:getItemEffect()

	var_13_5:addTo(arg_13_0:nodeByName("container"))
	var_13_5:pos(arg_13_0:nodeByName("node_pos" .. var_13_2):getPosition())
	var_13_5:play(function()
		var_13_5:setVisible(false)
	end)
	var_13_5:setScale(0)
	transition.scaleTo(var_13_5, {
		scale = 1,
		time = var_0_1.stoneSummonDuration
	})
end

function var_0_0.getDesText(arg_16_0)
	return arg_16_0:nodeByName("des")
end

function var_0_0.setInitPosition(arg_17_0)
	for iter_17_0 = 1, #arg_17_0.items_ do
		local var_17_0 = arg_17_0:nodeByName("node_pos" .. iter_17_0)

		arg_17_0:getSummonItem(iter_17_0):setScale(0)
		arg_17_0:getSummonItem(iter_17_0):pos(var_17_0:getPosition())
	end
end

return var_0_0
