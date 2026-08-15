local var_0_0 = class("StarTreasureEntreWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.starTreasure = xyd.ModelManager.get():loadModel(xyd.ModelType.STAR_TREASURE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:addBlockLayer()
	arg_3_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:nodeByName("found_des_words"):setString(var_0_1:translation("YOU_FOUND"))
	arg_3_0:nodeByName("next_words"):setString(var_0_1:translation("NEXT_ENTRE"))
	arg_3_0:nodeByName("des_words"):setString(var_0_1:translation("NEXT_ENTRE_DES"))

	local var_3_0 = xyd.AssetLoader:get():loadSprite("windows/star_treasure/star_treasure_main/entre_sence/entre.png")
	local var_3_1 = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")
	local var_3_2 = arg_3_0:nodeByName("entre_icon"):getWidth()
	local var_3_3 = arg_3_0:nodeByName("entre_icon"):getHeight()

	var_3_1:setPosition(var_3_2 / 2, var_3_3 / 2)
	var_3_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_3_1:setScale(var_3_3 / var_3_1:getHeight())

	local var_3_4 = var_3_3 / var_3_1:getHeight()
	local var_3_5 = cc.ClippingNode:create()

	var_3_5:setStencil(var_3_1)
	var_3_5:setInverted(true)
	var_3_5:setAlphaThreshold(0)
	arg_3_0:nodeByName("entre_icon"):addChild(var_3_5)
	var_3_5:addChild(var_3_0)
	var_3_0:setPosition(var_3_2 / 2, var_3_3 / 2)
	var_3_0:setAnchorPoint(cc.p(0.5, 0.5))

	local var_3_6 = var_3_3 / var_3_0:getHeight()

	var_3_0:setScale(var_3_6)
	var_3_5:setLocalZOrder(-1)

	local var_3_7 = xyd.tables.item:quality(itemID)
	local var_3_8 = xyd.getBorder(1, false)

	xyd.displaySpriteOnContainer(var_3_8, arg_3_0:nodeByName("entre_icon"), true)
end

function var_0_0.didClose(arg_5_0)
	var_0_0.super.didClose()
end

return var_0_0
