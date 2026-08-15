local var_0_0 = class("CommonAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.translation

function var_0_0.open(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6)
	local var_1_0 = arg_1_3 or {}

	var_1_0.type = arg_1_0
	var_1_0.txt = arg_1_1
	var_1_0.label = arg_1_6
	var_1_0.rcallback = arg_1_2
	var_1_0.rcallBefore = arg_1_4 or 1
	var_1_0.colorMode = arg_1_5

	if arg_1_1 and arg_1_1[2] and string.find(arg_1_1[2], xyd.tables.translation:translation("GIFT_PUSH_TEXT_3")) then
		xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):setSceneCondition(37)
	end

	return xyd.WindowManager.get():openWindow("common_alert", var_1_0)
end

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	var_0_0.super.ctor(arg_2_0, arg_2_1, arg_2_2)

	arg_2_0.alertType = arg_2_2.type or xyd.CommonAlertType.TWO_BTN
	arg_2_0.title = arg_2_2.title or var_0_3:translation("TIP")
	arg_2_0.isSplitLine = arg_2_2.isSplitLine or true
	arg_2_0.lcallback = arg_2_2.lcallback
	arg_2_0.rcallback = arg_2_2.rcallback
	arg_2_0.lcallBefore = arg_2_2.lcallBefore or 1
	arg_2_0.rcallBefore = arg_2_2.rcallBefore or 1
	arg_2_0.txt = arg_2_2.txt
	arg_2_0.label = arg_2_2.label
	arg_2_0.txtWidth = arg_2_2.width
	arg_2_0.txtHeight = arg_2_2.height
	arg_2_0.txtAlign = arg_2_2.align or xyd.ui_align.LEFT
	arg_2_0.txtValign = arg_2_2.valign or xyd.ui_valign.CENTER
	arg_2_0.addNewComponent = arg_2_2.addNewComponent
	arg_2_0.btnLeftName = arg_2_2.leftName or var_0_3:translation("CANCEL")
	arg_2_0.btnRightName = arg_2_2.rightName or var_0_3:translation("OK")
	arg_2_0.btnMiddleName = arg_2_2.middleName or var_0_3:translation("OK")
	arg_2_0.callbackParams = arg_2_2.callbackParams
	arg_2_0.showBegin = arg_2_2.showBegin
	arg_2_0.touchClose = arg_2_2.touchClose

	if not arg_2_2.colorMode or arg_2_2.colorMode == 0 then
		arg_2_0.colorMode = xyd.ColorMode.BLUE
	else
		arg_2_0.colorMode = arg_2_2.colorMode
	end

	arg_2_0.guideID = arg_2_2.guideID
	arg_2_0.btnImgs = {}
	arg_2_0.btnImgs[1] = "windows/button/btn195_1.png"

	if arg_2_0.colorMode == xyd.ColorMode.BLUE then
		arg_2_0.btnImgs[2] = "windows/button/btn195_2.png"
	elseif arg_2_0.colorMode == xyd.ColorMode.GREEN then
		arg_2_0.btnImgs[2] = "windows/button/btn195_green.png"
	elseif arg_2_0.colorMode == xyd.ColorMode.RED then
		arg_2_0.btnImgs[2] = "windows/button/btn_orange_italic.png"
	elseif arg_2_0.colorMode == xyd.ColorMode.YELLOW then
		arg_2_0.btnImgs[2] = "windows/button/btn_orange_italic.png"
	elseif arg_2_0.colorMode == xyd.ColorMode.PURPLE then
		arg_2_0.btnImgs[2] = "windows/button/btn_orange_italic.png"
	elseif arg_2_0.colorMode == xyd.ColorMode.ACTIVITY then
		arg_2_0.btnImgs[2] = "windows/button/btn_orange_italic.png"
	end
end

function var_0_0.willOpen(arg_3_0)
	local var_3_0 = xyd.tables.systemColor:alertBG(arg_3_0.colorMode)

	if var_3_0 then
		local var_3_1 = cc.rect(1, 130, 1, 1)
		local var_3_2 = xyd.AssetLoader.get():loadSprite(var_3_0, var_3_1)

		var_3_2:addTo(arg_3_0:background())
		var_3_2:setAnchorPoint(0, 0)
		var_3_2:setPosition(0, 0)
		var_3_2:setScale9Enabled(true)
		var_3_2:setContentSize(arg_3_0:background():getContentSize())
		var_3_2:setLocalZOrder(-100)
	end
end

function var_0_0.didOpen(arg_4_0)
	arg_4_0.container = arg_4_0:nodeByName("container")
	arg_4_0.width = arg_4_0.container:getWidth()
	arg_4_0.height = arg_4_0.container:getHeight()
	arg_4_0.txtWidth = arg_4_0.txtWidth or arg_4_0.width
	arg_4_0.txtHeight = arg_4_0.txtHeight or arg_4_0.height

	if arg_4_0.touchClose then
		arg_4_0:addBlockLayer()
	else
		arg_4_0:addBlockLayerWithNoTouchEvent()
	end

	arg_4_0:layout()
	arg_4_0:onRegister()

	if arg_4_0.addNewComponent then
		arg_4_0.addNewComponent(arg_4_0)
	end

	if arg_4_0.guideID and arg_4_0.guideID == xyd.GuideStoryType.GUIDE_STONE_ONE then
		arg_4_0:playGuide()
	end
end

function var_0_0.layout(arg_5_0)
	if arg_5_0.title then
		local var_5_0
		local var_5_1 = arg_5_0.colorMode == xyd.ColorMode.ACTIVITY and "#5D371D" or "#FFFFFF"
		local var_5_2 = xyd.createAutoFixLabel({
			height = 30,
			fontSize = 24,
			width = 400,
			txtColor = var_5_1,
			text = arg_5_0.title
		})

		var_5_2:addTo(arg_5_0:background())
		var_5_2:setAnchorPoint(0, 0.5)
		var_5_2:setPosition(arg_5_0:nodeByName("pos_title"):getPosition())
	end

	if arg_5_0.txtAlign == xyd.ui_align.LEFT and arg_5_0.txt and type(arg_5_0.txt) == "string" then
		local var_5_3 = string.find(arg_5_0.txt, "\n")

		if arg_5_0.showBegin then
			dump(2222222222222)

			arg_5_0.txt = arg_5_0.txt
		elseif var_5_3 then
			arg_5_0.txt = xyd.luaStringSplit(arg_5_0.txt, "\n")
		else
			arg_5_0.txt = "        " .. arg_5_0.txt
		end
	end

	if arg_5_0.label then
		arg_5_0.label:addTo(arg_5_0.container)

		if arg_5_0.txtValign == xyd.ui_valign.TOP then
			arg_5_0.label:setAnchorPoint(0.5, 1)
			arg_5_0.label:setPosition(arg_5_0.width / 2, arg_5_0.height)
		else
			arg_5_0.label:setAnchorPoint(0.5, 0.5)
			arg_5_0.label:setPosition(arg_5_0.width / 2, arg_5_0.height / 2)
		end
	elseif arg_5_0.txt then
		if type(arg_5_0.txt) == "table" then
			local var_5_4 = ""

			for iter_5_0 = 1, #arg_5_0.txt do
				if iter_5_0 > 1 then
					var_5_4 = var_5_4 .. "\n"
				end

				if arg_5_0.txtAlign == xyd.ui_align.LEFT then
					var_5_4 = var_5_4 .. "        "
				end

				var_5_4 = var_5_4 .. arg_5_0.txt[iter_5_0]
			end

			arg_5_0.txtLabel = xyd.createAutoFixLabel({
				fontSize = 24,
				txtColor = "#44454D",
				width = arg_5_0.txtWidth,
				height = arg_5_0.txtHeight,
				text = var_5_4,
				align = xyd.getTextAlign(arg_5_0.txtAlign),
				valign = xyd.getTextValign(arg_5_0.txtValign)
			})

			arg_5_0.txtLabel:addTo(arg_5_0.container)

			if arg_5_0.txtValign == xyd.ui_valign.TOP then
				arg_5_0.txtLabel:setAnchorPoint(0.5, 1)
				arg_5_0.txtLabel:setPosition(arg_5_0.width / 2, arg_5_0.height)
			else
				arg_5_0.txtLabel:setAnchorPoint(0.5, 0.5)
				arg_5_0.txtLabel:setPosition(arg_5_0.width / 2, arg_5_0.height / 2)
			end
		else
			arg_5_0.txtLabel = xyd.createAutoFixLabel({
				fontSize = 24,
				txtColor = "#44454D",
				width = arg_5_0.txtWidth,
				height = arg_5_0.txtHeight,
				text = arg_5_0.txt,
				align = xyd.getTextAlign(arg_5_0.txtAlign),
				valign = xyd.getTextValign(arg_5_0.txtValign)
			})

			arg_5_0.txtLabel:addTo(arg_5_0.container)

			if arg_5_0.txtValign == xyd.ui_valign.TOP then
				arg_5_0.txtLabel:setAnchorPoint(0.5, 1)
				arg_5_0.txtLabel:setPosition(arg_5_0.width / 2, arg_5_0.height)
			else
				arg_5_0.txtLabel:setAnchorPoint(0.5, 0.5)
				arg_5_0.txtLabel:setPosition(arg_5_0.width / 2, arg_5_0.height / 2)
			end
		end
	end

	if arg_5_0.isSplitLine then
		local var_5_5 = var_0_1.new({
			size = arg_5_0.width - 3
		})

		var_5_5:addTo(arg_5_0:background())
		var_5_5:setAnchorPoint(0.5, 0.5)
		var_5_5:setPosition(arg_5_0:nodeByName("pos_splitline"):getPosition())
	end

	if arg_5_0.alertType == xyd.CommonAlertType.TWO_BTN then
		arg_5_0.leftBtn = var_0_2.new({
			titleSize = 24,
			sprite = arg_5_0.btnImgs[1],
			title = arg_5_0.btnLeftName,
			clickMode = xyd.ButtonClickMode.SCALE
		})

		arg_5_0.leftBtn:addTo(arg_5_0:nodeByName("background"))
		arg_5_0.leftBtn:setAnchorPoint(0.5, 0.5)
		arg_5_0.leftBtn:setPosition(arg_5_0:nodeByName("pos_btn_left"):getPosition())

		arg_5_0.rightBtn = var_0_2.new({
			titleSize = 24,
			sprite = arg_5_0.btnImgs[2],
			title = arg_5_0.btnRightName,
			clickMode = xyd.ButtonClickMode.SCALE
		})

		arg_5_0.rightBtn:addTo(arg_5_0:nodeByName("background"))
		arg_5_0.rightBtn:setAnchorPoint(0.5, 0.5)
		arg_5_0.rightBtn:setPosition(arg_5_0:nodeByName("pos_btn_right"):getPosition())
	else
		arg_5_0.middleBtn = var_0_2.new({
			titleSize = 24,
			sprite = arg_5_0.btnImgs[2],
			title = arg_5_0.btnMiddleName,
			clickMode = xyd.ButtonClickMode.SCALE
		})

		arg_5_0.middleBtn:addTo(arg_5_0:nodeByName("background"))
		arg_5_0.middleBtn:setAnchorPoint(0.5, 0.5)
		arg_5_0.middleBtn:setPosition(arg_5_0:nodeByName("pos_btn_middle"):getPosition())
	end
end

function var_0_0.onRegister(arg_6_0)
	if arg_6_0.leftBtn and not tolua.isnull(arg_6_0.leftBtn) then
		arg_6_0.leftBtn:addTouchEvent(function(arg_7_0)
			if arg_7_0.name == "ended" then
				local var_7_0 = false

				if arg_6_0.lcallBefore == 1 and arg_6_0.lcallback then
					if arg_6_0.callbackParams then
						var_7_0 = arg_6_0.lcallback(arg_6_0.callbackParams, arg_7_0, arg_6_0)
					else
						var_7_0 = arg_6_0.lcallback(arg_7_0, arg_6_0)
					end
				end

				if not var_7_0 then
					arg_6_0:close(function()
						if arg_6_0.lcallBefore == 0 and arg_6_0.lcallback then
							if arg_6_0.callbackParams then
								arg_6_0.lcallback(arg_6_0.callbackParams, arg_7_0, arg_6_0)
							else
								arg_6_0.lcallback(arg_7_0, arg_6_0)
							end
						end
					end)
				end
			end
		end)
	end

	if arg_6_0.rightBtn and not tolua.isnull(arg_6_0.rightBtn) then
		arg_6_0.rightBtn:addTouchEvent(function(arg_9_0)
			if arg_9_0.name == "ended" then
				if arg_6_0.showGuide then
					xyd.WindowManager.get():closeWindow("guide")
				end

				if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_STONE_END then
					xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):sendOperationLog(xyd.StatID.ID_STONE_4)
					xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_START)
					xyd.StoryData.get():persist()
				end

				local var_9_0 = false

				if arg_6_0.rcallBefore == 1 and arg_6_0.rcallback then
					if arg_6_0.callbackParams then
						var_9_0 = arg_6_0.rcallback(arg_6_0.callbackParams, arg_9_0, arg_6_0)
					else
						var_9_0 = arg_6_0.rcallback(arg_9_0, arg_6_0)
					end
				end

				if not var_9_0 then
					arg_6_0:close(function()
						if arg_6_0.rcallBefore == 0 and arg_6_0.rcallback then
							if arg_6_0.callbackParams then
								arg_6_0.rcallback(arg_6_0.callbackParams, arg_9_0, arg_6_0)
							else
								arg_6_0.rcallback(arg_9_0, arg_6_0)
							end
						end
					end)
				end
			end
		end)
	end

	if arg_6_0.middleBtn and not tolua.isnull(arg_6_0.middleBtn) then
		arg_6_0.middleBtn:addTouchEvent(function(arg_11_0)
			if arg_11_0.name == "ended" then
				local var_11_0 = false

				if arg_6_0.rcallBefore == 1 and arg_6_0.rcallback then
					if arg_6_0.callbackParams then
						var_11_0 = arg_6_0.rcallback(arg_6_0.callbackParams, arg_11_0, arg_6_0)
					else
						var_11_0 = arg_6_0.rcallback(arg_11_0, arg_6_0)
					end
				end

				if not var_11_0 then
					arg_6_0:close(function()
						if arg_6_0.rcallBefore == 0 and arg_6_0.rcallback then
							if arg_6_0.callbackParams then
								arg_6_0.rcallback(arg_6_0.callbackParams, arg_11_0, arg_6_0)
							else
								arg_6_0.rcallback(arg_11_0, arg_6_0)
							end
						end
					end)
				end
			end
		end)
	end
end

function var_0_0.addLeftBtnEvent(arg_13_0, arg_13_1)
	arg_13_0.lcallback = arg_13_1
end

function var_0_0.addRightBtnEvent(arg_14_0, arg_14_1)
	arg_14_0.rcallback = arg_14_1
end

function var_0_0.addMiddleBtnEvent(arg_15_0, arg_15_1)
	arg_15_0.rcallback = arg_15_1
end

function var_0_0.playGuide(arg_16_0)
	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_STONE_ONE then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):sendOperationLog(xyd.StatID.ID_STONE_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_STONE_END)

		arg_16_0.showGuide = true

		local var_16_0 = arg_16_0.rightBtn
		local var_16_1 = var_16_0:getPositionX()
		local var_16_2 = var_16_0:getPositionY()

		xyd.WindowManager.get():closeWindow("guide")
		xyd.WindowManager.get():openWindow("guide")

		local var_16_3 = xyd.WindowManager.get():getWindow("guide")

		var_16_3:setLocalZOrder(100)

		local var_16_4 = var_16_3:convertToNodeSpace(var_16_0:getParent():convertToWorldSpace(cc.p(var_16_1, var_16_2)))

		var_16_3:addNode()
		var_16_3:setStencil(var_16_0:getContentSize().width, var_16_0:getContentSize().height, var_16_4.x, var_16_4.y, 1, {
			right = true,
			position = {
				300,
				500
			}
		})
	end
end

function var_0_0.didClose(arg_17_0)
	if arg_17_0.showGuide then
		xyd.WindowManager.get():closeWindow("guide")
	end
end

return var_0_0
