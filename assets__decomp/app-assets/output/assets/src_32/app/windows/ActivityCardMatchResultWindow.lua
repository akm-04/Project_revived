local var_0_0 = class("ActivitCardMatchResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityCardMatch
local var_0_3 = import("framework.scheduler")
local var_0_4 = "skeletons/ui_effect/activity_card_match/activity_card_match"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.cardID = arg_1_2.card_id
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:getCardItem()
	local var_3_1 = arg_3_0:getCardItem()

	arg_3_0:initItemByCardID(var_3_0, arg_3_0.cardID)
	arg_3_0:initItemByCardID(var_3_1, arg_3_0.cardID)
	arg_3_0:showCardIsOberserve(var_3_0, true)
	arg_3_0:showCardIsOberserve(var_3_1, true)
	arg_3_0:nodeByName("success_text"):setVisible(false)

	local var_3_2 = xyd.createEffect(var_0_4)

	var_3_2:addTo(arg_3_0:nodeByName("card_pos"))
	var_3_2:play(function()
		if arg_3_0 and arg_3_0.cardItem1 and not tolua.isnull(arg_3_0.cardItem1) then
			var_3_2:play(nil, true, nil, "texiao03")
		end
	end, false, nil, "texiao01")

	local var_3_3 = xyd.createEffect(var_0_4)

	var_3_3:addTo(arg_3_0:nodeByName("card_pos"))
	var_3_3:play(function()
		var_3_3:play(nil, true, nil, "texiao04")
	end, false, nil, "texiao02")
	var_3_0:addTo(arg_3_0:nodeByName("card_pos"))
	var_3_1:addTo(arg_3_0:nodeByName("card_pos"))
	var_3_0:setRotation(-20)
	var_3_0:setPositionX(-40)
	var_3_0:setPositionY(-20)
	var_3_1:setRotation(20)
	var_3_1:setPositionX(-20)
	var_3_1:setPositionY(-5)

	arg_3_0.cardItem1 = var_3_0
	arg_3_0.cardItem2 = var_3_1

	arg_3_0.cardItem1:setVisible(false)
	arg_3_0.cardItem2:setVisible(false)
	var_0_3.performWithDelayGlobal(function()
		if arg_3_0 and arg_3_0.cardItem1 and not tolua.isnull(arg_3_0.cardItem1) then
			arg_3_0.cardItem1:setVisible(true)
			arg_3_0.cardItem2:setVisible(true)
		end
	end, 0.4666666666666667)
	arg_3_0:nodeByName("container"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_7_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.willClose(arg_8_0)
	var_0_0.super.willClose()

	if arg_8_0.callback then
		arg_8_0.callback()
	end
end

function var_0_0.showCardIsOberserve(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1:getChildByName("source"):getChildByName("container")
	local var_9_1 = var_9_0:getChildByName("bg1")
	local var_9_2 = var_9_0:getChildByName("bg2")

	var_9_1:setVisible(not arg_9_2)
	var_9_2:setVisible(arg_9_2)

	arg_9_1.isObserveSide = arg_9_2
end

function var_0_0.getCardItem(arg_10_0)
	local var_10_0 = display.newNode()
	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1161/card_item.csb")
	local var_10_2 = var_10_1:getChildByName("container")

	var_10_2:setScale(1.2)
	var_10_1:addTo(var_10_0)
	var_10_1:setAnchorPoint(cc.p(0, 0))
	var_10_0:setContentSize(var_10_2:getContentSize())
	var_10_1:setName("source")

	return var_10_0
end

function var_0_0.initItemByCardID(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1:getChildByName("source"):getChildByName("container"):getChildByName("bg2"):getChildByName("icon_container")

	var_11_0:removeAllChildren(true)

	local var_11_1 = var_0_2:itemId(arg_11_2)
	local var_11_2 = var_0_2:itemNum(arg_11_2)

	if var_11_1 > 0 then
		xyd.setItemAndAddTips(var_11_0, var_11_1, var_11_2)
	else
		local var_11_3 = xyd.AssetLoader.get():loadSprite("windows/activities/1161/main/special_item.png")

		xyd.displaySpriteOnContainer(var_11_3, var_11_0)
	end
end

return var_0_0
