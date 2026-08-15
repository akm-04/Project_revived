local var_0_0 = class("AlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "alert"
local var_0_2 = 18

function var_0_0.open(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
	local var_1_0 = arg_1_3 or {}

	var_1_0.alertType = arg_1_0
	var_1_0.message = arg_1_1
	var_1_0.callback = arg_1_2

	if arg_1_1 and arg_1_1[2] and string.find(arg_1_1[2], xyd.tables.translation:translation("GIFT_PUSH_TEXT_3")) then
		xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):setSceneCondition(37)
	end

	return xyd.WindowManager.get():openWindow(var_0_1, var_1_0)
end

function var_0_0.close(arg_2_0)
	xyd.WindowManager.get():closeWindow(var_0_1, arg_2_0)
end

function var_0_0.ctor(arg_3_0, arg_3_1, arg_3_2)
	var_0_0.super.ctor(arg_3_0, arg_3_1, arg_3_2)

	arg_3_0.type_ = arg_3_2.alertType
	arg_3_0.callback_ = arg_3_2.callback
	arg_3_0.yesText_ = arg_3_2.yesText
	arg_3_0.noText_ = arg_3_2.noText

	if arg_3_2.showGuide then
		arg_3_0.showGuide = arg_3_2.showGuide
	end

	if arg_3_2.guideDirection then
		arg_3_0.guideDirection = arg_3_2.guideDirection
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	arg_4_0:createLabels(arg_4_1)
	arg_4_0:setupButtons_()
	arg_4_0:layoutChildren_()
	arg_4_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	local function var_5_0(arg_6_0)
		if arg_5_0.callback_ ~= nil then
			arg_5_0.callback_(arg_6_0)
		end

		arg_5_0.callback_ = nil
	end

	arg_5_0:confirmButton_():addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			if arg_5_0.showGuide then
				xyd.WindowManager.get():closeWindow("guide")
			end

			if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_STONE_END then
				xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):sendOperationLog(xyd.StatID.ID_STONE_4)
				xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_START)
				xyd.StoryData.get():persist()
			end

			xyd.playButtonSound()
			var_0_0.close(function()
				var_5_0(true)
			end)
		end
	end)
	arg_5_0:rejectButton_():addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			var_0_0.close(function()
				var_5_0(false)
			end)
		end
	end)

	if arg_5_1.guideID and arg_5_1.guideID == xyd.GuideStoryType.GUIDE_STONE_ONE then
		arg_5_0:playGuide()
	end
end

function var_0_0.setupButtons_(arg_11_0)
	local var_11_0 = arg_11_0.yesText_ or "images/text/txt_sure.png"
	local var_11_1 = arg_11_0.noText_ or "images/text/txt_cancel.png"

	arg_11_0:nodeByName("txt_yes"):removeAllChildren()
	arg_11_0:nodeByName("txt_no"):removeAllChildren()
	arg_11_0:nodeByName("txt_yes"):setTouchEnabled(false)
	arg_11_0:nodeByName("txt_no"):setTouchEnabled(false)

	if arg_11_0.type_ == xyd.AlertType.CONFIRM then
		arg_11_0:confirmButton_():setVisible(true)
		arg_11_0:rejectButton_():setVisible(false)
		arg_11_0:nodeByName("txt_yes"):setVisible(true)
		arg_11_0:nodeByName("txt_no"):setVisible(false)

		local var_11_2 = xyd.AssetLoader:get():loadSprite(var_11_0)

		xyd.displaySpriteOnContainer(var_11_2, arg_11_0:nodeByName("txt_yes"), true)
	elseif arg_11_0.type_ == xyd.AlertType.YES_NO then
		arg_11_0:confirmButton_():setVisible(true)
		arg_11_0:rejectButton_():setVisible(true)
		arg_11_0:nodeByName("txt_yes"):setVisible(true)
		arg_11_0:nodeByName("txt_no"):setVisible(true)

		local var_11_3 = xyd.AssetLoader:get():loadSprite(var_11_0)

		xyd.displaySpriteOnContainer(var_11_3, arg_11_0:nodeByName("txt_yes"), true)

		local var_11_4 = xyd.AssetLoader:get():loadSprite(var_11_1)

		xyd.displaySpriteOnContainer(var_11_4, arg_11_0:nodeByName("txt_no"), true)
	elseif arg_11_0.type_ == xyd.AlertType.AGREE_REJECT then
		arg_11_0:confirmButton_():setVisible(true)
		arg_11_0:rejectButton_():setVisible(true)
		arg_11_0:nodeByName("txt_yes"):setVisible(true)
		arg_11_0:nodeByName("txt_no"):setVisible(true)

		local var_11_5 = xyd.AssetLoader:get():loadSprite("images/text/txt_agree.png")

		xyd.displaySpriteOnContainer(var_11_5, arg_11_0:nodeByName("txt_yes"), true)

		local var_11_6 = xyd.AssetLoader:get():loadSprite("images/text/txt_reject.png")

		xyd.displaySpriteOnContainer(var_11_6, arg_11_0:nodeByName("txt_no"), true)
	elseif arg_11_0.type_ == xyd.AlertType.DRAGON_BOAT2 then
		arg_11_0:confirmButton_():setVisible(true)
		arg_11_0:rejectButton_():setVisible(true)
		arg_11_0:nodeByName("txt_yes"):setVisible(true)
		arg_11_0:nodeByName("txt_no"):setVisible(true)

		local var_11_7 = xyd.AssetLoader:get():loadSprite(var_11_0)

		xyd.displaySpriteOnContainer(var_11_7, arg_11_0:nodeByName("txt_yes"), true)

		local var_11_8 = xyd.AssetLoader:get():loadSprite("windows/activities/1104/main/change_team_text.png")

		xyd.displaySpriteOnContainer(var_11_8, arg_11_0:nodeByName("txt_no"), true)
	elseif arg_11_0.type_ == xyd.AlertType.LOTTERY then
		arg_11_0:confirmButton_():setVisible(true)
		arg_11_0:rejectButton_():setVisible(true)
		arg_11_0:nodeByName("txt_yes"):setVisible(true)
		arg_11_0:nodeByName("txt_no"):setVisible(true)

		local var_11_9 = xyd.AssetLoader:get():loadSprite("windows/activities/1116/hand_choose.png")

		xyd.displaySpriteOnContainer(var_11_9, arg_11_0:nodeByName("txt_yes"), true)

		local var_11_10 = xyd.AssetLoader:get():loadSprite("windows/activities/1116/auto_choose.png")

		xyd.displaySpriteOnContainer(var_11_10, arg_11_0:nodeByName("txt_no"), true)
	elseif arg_11_0.type_ == xyd.AlertType.LOTTERY_CONSUME then
		arg_11_0:confirmButton_():setVisible(true)
		arg_11_0:rejectButton_():setVisible(true)
		arg_11_0:nodeByName("txt_yes"):setVisible(true)
		arg_11_0:nodeByName("txt_no"):setVisible(true)

		local var_11_11 = xyd.AssetLoader:get():loadSprite("windows/activities/1148/hand_choose.png")

		xyd.displaySpriteOnContainer(var_11_11, arg_11_0:nodeByName("txt_yes"), true)

		local var_11_12 = xyd.AssetLoader:get():loadSprite("windows/activities/1148/auto_choose.png")

		xyd.displaySpriteOnContainer(var_11_12, arg_11_0:nodeByName("txt_no"), true)
	elseif arg_11_0.type_ == xyd.AlertType.BUYTEN_BUYONE then
		arg_11_0:addBlockLayer()
		arg_11_0.blockLayer_:setPosition(cc.p(-640, -360))
		arg_11_0:nodeByName("bg_1"):setTexture("windows/stick_bless_word/main_wnd/bg_small.png")
		arg_11_0:nodeByName("bg_1"):setVisible(true)
		arg_11_0:nodeByName("line"):setVisible(false)
		arg_11_0:nodeByName("bg"):setVisible(false)
		arg_11_0:confirmButton_():setVisible(true)
		arg_11_0:rejectButton_():setVisible(true)
		arg_11_0:nodeByName("txt_yes"):setVisible(true)
		arg_11_0:nodeByName("txt_no"):setVisible(true)

		local var_11_13 = xyd.AssetLoader:get():loadSprite("windows/stick_bless_word/main_wnd/word_ten.png")

		xyd.displaySpriteOnContainer(var_11_13, arg_11_0:nodeByName("txt_yes"), false)

		local var_11_14 = xyd.AssetLoader:get():loadSprite("windows/stick_bless_word/main_wnd/word_one.png")

		xyd.displaySpriteOnContainer(var_11_14, arg_11_0:nodeByName("txt_no"), false)
	end
end

function var_0_0.layoutChildren_(arg_12_0)
	local var_12_0 = arg_12_0:nodeByName("container"):getContentSize().width
	local var_12_1 = {}
	local var_12_2 = 0

	if arg_12_0:rejectButton_():isVisible() then
		table.insert(var_12_1, arg_12_0:rejectButton_())

		var_12_2 = var_12_2 + arg_12_0:rejectButton_():getContentSize().width
	end

	if arg_12_0:confirmButton_():isVisible() then
		table.insert(var_12_1, arg_12_0:confirmButton_())

		var_12_2 = var_12_2 + arg_12_0:confirmButton_():getContentSize().width
	end

	local var_12_3 = #var_12_1 <= 0 and 0 or var_0_2 * (#var_12_1 - 1)
	local var_12_4 = 0.5 * (var_12_0 - var_12_2 - var_12_3)

	for iter_12_0, iter_12_1 in ipairs(var_12_1) do
		local var_12_5 = cc.p(iter_12_1:getPosition())

		var_12_5.x = var_12_4 + iter_12_1:getContentSize().width / 2

		iter_12_1:setPosition(var_12_5)

		var_12_4 = var_12_4 + iter_12_1:getContentSize().width + var_0_2
	end

	local var_12_6, var_12_7 = arg_12_0:confirmButton_():getPosition()

	arg_12_0:nodeByName("txt_yes"):setPosition(var_12_6, var_12_7)

	local var_12_8, var_12_9 = arg_12_0:rejectButton_():getPosition()

	arg_12_0:nodeByName("txt_no"):setPosition(var_12_8, var_12_9)
end

function var_0_0.didClose(arg_13_0)
	var_0_0.super.didClose()

	if arg_13_0.showGuide then
		xyd.WindowManager.get():closeWindow("guide")
	end
end

function var_0_0.createLabels(arg_14_0, arg_14_1)
	arg_14_0:nodeByName("message"):removeAllChildren()

	local var_14_0 = 0
	local var_14_1 = 0
	local var_14_2 = {}
	local var_14_3 = arg_14_1.message
	local var_14_4 = arg_14_1.align or cc.ui.TEXT_ALIGN_LEFT

	for iter_14_0 = 1, #var_14_3 do
		local var_14_5 = {
			size = 24,
			color = arg_14_1.color or cc.c3b(17, 17, 17)
		}
		local var_14_6 = xyd.AssetLoader:get():loadLabel(var_14_5)

		var_14_6:setString(var_14_3[iter_14_0])
		var_14_6:setMaxLineWidth(arg_14_0:nodeByName("message"):getContentSize().width)
		var_14_6:setAnchorPoint(cc.p(0, 0))
		var_14_6:addTo(arg_14_0:nodeByName("message"))

		var_14_0 = var_14_0 + var_14_6:getContentSize().height

		table.insert(var_14_2, var_14_6)
	end

	local var_14_7 = var_14_0
	local var_14_8 = (arg_14_0:nodeByName("message"):getContentSize().height + var_14_0) / 2

	for iter_14_1 = 1, #var_14_2 do
		var_14_8 = var_14_8 - var_14_2[iter_14_1]:getContentSize().height

		if var_14_4 == cc.ui.TEXT_ALIGN_CENTER then
			var_14_1 = (arg_14_0:nodeByName("message"):getContentSize().width - var_14_2[iter_14_1]:getContentSize().width) / 2
		elseif var_14_4 == cc.ui.TEXT_ALIGN_RIGHT then
			var_14_1 = arg_14_0:nodeByName("message"):getContentSize().width - var_14_2[iter_14_1]:getContentSize().width
		end

		var_14_2[iter_14_1]:setPosition(var_14_1, var_14_8)
	end

	if var_14_7 < 110 then
		var_14_7 = 110
	end

	local var_14_9 = var_14_7 + 190

	arg_14_0:nodeByName("bg"):setContentSize(arg_14_0:nodeByName("bg"):getContentSize().width, var_14_9)

	local var_14_10 = arg_14_0:nodeByName("bg"):getPositionY() + var_14_9 / 2 - 40 - var_14_7 / 2
	local var_14_11 = var_14_10 - var_14_7 / 2 - 20
	local var_14_12 = var_14_11 - 30 - arg_14_0:nodeByName("no"):getContentSize().height / 2

	arg_14_0:nodeByName("message"):setPositionY(var_14_10)
	arg_14_0:nodeByName("line"):setPositionY(var_14_11)
	arg_14_0:nodeByName("no"):setPositionY(var_14_12)
	arg_14_0:nodeByName("yes"):setPositionY(var_14_12)
end

function var_0_0.confirmButton_(arg_15_0)
	return arg_15_0:nodeByName("yes")
end

function var_0_0.rejectButton_(arg_16_0)
	return arg_16_0:nodeByName("no")
end

function var_0_0.playGuide(arg_17_0)
	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_STONE_ONE then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):sendOperationLog(xyd.StatID.ID_STONE_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_STONE_END)

		arg_17_0.showGuide = true

		local var_17_0 = arg_17_0:nodeByName("yes")
		local var_17_1 = var_17_0:getPositionX()
		local var_17_2 = var_17_0:getPositionY()

		xyd.WindowManager.get():closeWindow("guide")
		xyd.WindowManager.get():openWindow("guide")

		local var_17_3 = xyd.WindowManager.get():getWindow("guide")

		var_17_3:setLocalZOrder(100)

		local var_17_4 = var_17_3:convertToNodeSpace(var_17_0:getParent():convertToWorldSpace(cc.p(var_17_1, var_17_2)))

		var_17_3:addNode()
		var_17_3:setStencil(var_17_0:getContentSize().width, var_17_0:getContentSize().height, var_17_4.x, var_17_4.y, 1, {
			right = true,
			position = {
				300,
				500
			}
		})
	end
end

return var_0_0
