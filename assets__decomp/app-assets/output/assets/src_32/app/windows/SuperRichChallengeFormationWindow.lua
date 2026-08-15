local var_0_0 = class("SuperRichChallengeFormationWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "windows/zillionaire/challenge/"
local var_0_3 = xyd.tables.activityRichCampaign

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.campaignId = arg_1_2.campaignID
	arg_1_0.idx = var_0_3:getIdxByCampaignId(arg_1_0.campaignId)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.herosA = arg_1_2.herosA
	arg_1_0.herosB = arg_1_2.herosB[1]
	arg_1_0.petsA = arg_1_2.petsA
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("desc_text"):setString(var_0_3:campaignDes(arg_4_0.campaignId))
	arg_4_0:nodeByName("tip_text"):setString(var_0_1:translation("SUPER_RICH_CHALLENGE_FORMATION_TIP"))
	xyd.AssetLoader.get():loadSprite(var_0_2 .. "word_" .. arg_4_0.idx .. ".png"):addTo(arg_4_0:nodeByName("campaign_pos"))
	arg_4_0:setButtonClick()

	if arg_4_0.herosB[6] then
		local var_4_0 = arg_4_0:getNode(arg_4_0.herosB[6], true, true)

		var_4_0:addTo(arg_4_0:nodeByName("enermy_pos"))
		var_4_0:setPosition(cc.p(0, -4))
	end

	for iter_4_0 = 1, #arg_4_0.herosB - 1 do
		local var_4_1 = arg_4_0:getNode(arg_4_0.herosB[iter_4_0], true, false)

		var_4_1:addTo(arg_4_0:nodeByName("enermy_pos"))
		var_4_1:setPosition(cc.p(iter_4_0 * 160 + 20, -4))
	end

	if arg_4_0.petsA and next(arg_4_0.petsA) then
		local var_4_2 = arg_4_0:getNode(arg_4_0.petsA[1], false, true)

		var_4_2:addTo(arg_4_0:nodeByName("my_pos"))
		var_4_2:setPosition(cc.p(0, -4))
	end

	for iter_4_1 = 1, #arg_4_0.herosA do
		local var_4_3 = arg_4_0:getNode(arg_4_0.herosA[iter_4_1], false, false)

		var_4_3:addTo(arg_4_0:nodeByName("my_pos"))
		var_4_3:setPosition(cc.p(iter_4_1 * 160 + 20, -4))
	end
end

function var_0_0.getNode(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = display.newNode()

	var_5_0:setContentSize(148, 228)
	var_5_0:setAnchorPoint(cc.p(0, 0.5))
	arg_5_0:setAvatarCard(arg_5_1, var_5_0, arg_5_2, arg_5_3)

	return var_5_0
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0:nodeByName("go_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_6_0.callback(true)
		end
	end)
	arg_6_0:closeButton():addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_8_0, false)
			arg_6_0.callback(false)
			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end)
end

function var_0_0.setAvatarCard(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0 = xyd.tables.model:card(arg_9_1:getModelID())
	local var_9_1 = arg_9_1:getColor()
	local var_9_2 = xyd.SpriteLoader.new(var_9_0, nil, nil, xyd.DefaultImageType.SMALL_CARD)
	local var_9_3 = arg_9_2:getContentSize().height
	local var_9_4 = arg_9_2:getContentSize().width

	var_9_2 = var_9_2 or xyd.AssetLoader.get():loadSprite("images/cards/10001001.png")

	local var_9_5 = xyd.AssetLoader:get():loadSprite("windows/zillionaire/challenge/cover.png")

	var_9_5:setPosition(var_9_4 / 2, var_9_3 / 2)
	var_9_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_9_5:setScale(var_9_3 / var_9_5:getHeight() * 1.01)

	local var_9_6 = cc.ClippingNode:create()

	var_9_6:setStencil(var_9_5)
	var_9_6:setAlphaThreshold(0)
	arg_9_2:addChild(var_9_6)
	var_9_6:addChild(var_9_2)
	var_9_2:setPosition(var_9_4 / 2, var_9_3 / 2)
	var_9_2:setAnchorPoint(cc.p(0.5, 0.5))

	local var_9_7 = var_9_3 / var_9_2:getHeight()

	var_9_2:setScale(var_9_3 / var_9_2:getHeight(), var_9_3 / var_9_2:getHeight())
	var_9_6:setLocalZOrder(-1)

	local var_9_8

	if not arg_9_3 and not arg_9_4 then
		var_9_8 = xyd.AssetLoader.get():loadSprite("windows/zillionaire/challenge/blue_card_hero.png")
	elseif not arg_9_3 and arg_9_4 then
		var_9_8 = xyd.AssetLoader.get():loadSprite("windows/zillionaire/challenge/blue_card_pet.png")
	elseif arg_9_3 and not arg_9_4 then
		var_9_8 = xyd.AssetLoader.get():loadSprite("windows/zillionaire/challenge/red_card_hero.png")
	else
		var_9_8 = xyd.AssetLoader.get():loadSprite("windows/zillionaire/challenge/red_card_pet.png")
	end

	xyd.displaySpriteOnContainer(var_9_8, arg_9_2, true)
end

return var_0_0
