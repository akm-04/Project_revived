local var_0_0 = class("AlertGreenWindow", import("app.windows.CommonAlertWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.alertType = arg_1_2.type or xyd.CommonAlertType.TWO_BTN
	arg_1_0.title = arg_1_2.title
	arg_1_0.isSplitLine = arg_1_2.isSplitLine or true
	arg_1_0.lcallback = arg_1_2.lcallback
	arg_1_0.rcallback = arg_1_2.rcallback
	arg_1_0.lcallBefore = arg_1_2.lcallBefore or 1
	arg_1_0.rcallBefore = arg_1_2.rcallBefore or 1
	arg_1_0.txt = arg_1_2.txt
	arg_1_0.label = arg_1_2.label
	arg_1_0.txtWidth = arg_1_2.width
	arg_1_0.txtHeight = arg_1_2.height
	arg_1_0.txtAlign = arg_1_2.align or xyd.ui_align.LEFT
	arg_1_0.txtValign = arg_1_2.valign or xyd.ui_valign.CENTER
	arg_1_0.addNewComponent = arg_1_2.addNewComponent
	arg_1_0.btnLeftName = arg_1_2.leftName or var_0_3:translation("CANCEL")
	arg_1_0.btnRightName = arg_1_2.rightName or var_0_3:translation("OK")
	arg_1_0.btnMiddleName = arg_1_2.middleName or var_0_3:translation("OK")
	arg_1_0.callbackParams = arg_1_2.callbackParams
	arg_1_0.colorMode = arg_1_2.colorMode or xyd.ColorMode.GREEN
	arg_1_0.guideID = arg_1_2.guideID
	arg_1_0.btnImgs = {}
	arg_1_0.btnImgs[1] = "windows/button/btn195_1.png"

	if arg_1_0.colorMode == xyd.ColorMode.BLUE then
		arg_1_0.btnImgs[2] = "windows/button/btn195_2.png"
	elseif arg_1_0.colorMode == xyd.ColorMode.GREEN then
		arg_1_0.btnImgs[2] = "windows/button/btn195_green.png"
	elseif arg_1_0.colorMode == xyd.ColorMode.RED then
		arg_1_0.btnImgs[2] = "windows/button/btn195_red.png"
	elseif arg_1_0.colorMode == xyd.ColorMode.YELLOW then
		arg_1_0.btnImgs[2] = "windows/button/btn_orange_italic.png"
	elseif arg_1_0.colorMode == xyd.ColorMode.PURPLE then
		arg_1_0.btnImgs[2] = "windows/button/btn195_purple.png"
	elseif arg_1_0.colorMode == xyd.ColorMode.ACTIVITY then
		arg_1_0.btnImgs[2] = "windows/button/btn_orange_italic.png"
	end
end

function var_0_0.layout(arg_2_0)
	if arg_2_0.title then
		local var_2_0
		local var_2_1 = arg_2_0.colorMode == xyd.ColorMode.ACTIVITY and "#5D371D" or "#FFFFFF"
		local var_2_2 = xyd.createAutoFixLabel({
			height = 30,
			fontSize = 24,
			width = 400,
			txtColor = var_2_1,
			text = arg_2_0.title
		})

		var_2_2:addTo(arg_2_0:background())
		var_2_2:setAnchorPoint(0, 0.5)
		var_2_2:setPosition(arg_2_0:nodeByName("pos_title"):getPosition())
	end

	if arg_2_0.label then
		arg_2_0.label:addTo(arg_2_0.container)
		arg_2_0.label:setAnchorPoint(0.5, 0.5)
		arg_2_0.label:setPosition(arg_2_0.width / 2, arg_2_0.height / 2)
	elseif arg_2_0.txt then
		if type(arg_2_0.txt) == "table" then
			local var_2_3 = ""

			for iter_2_0 = 1, #arg_2_0.txt do
				if iter_2_0 > 1 then
					var_2_3 = var_2_3 .. "\n"
				end

				var_2_3 = var_2_3 .. arg_2_0.txt[iter_2_0]
			end

			arg_2_0.txtLabel = xyd.createAutoFixLabel({
				fontSize = 24,
				txtColor = "#44454D",
				width = arg_2_0.txtWidth,
				height = arg_2_0.txtHeight,
				text = var_2_3,
				align = xyd.getTextAlign(arg_2_0.txtAlign),
				valign = xyd.getTextValign(arg_2_0.txtValign)
			})

			arg_2_0.txtLabel:addTo(arg_2_0.container)
			arg_2_0.txtLabel:setAnchorPoint(0.5, 0.5)
			arg_2_0.txtLabel:setPosition(arg_2_0.width / 2, arg_2_0.height / 2)
		else
			local var_2_4
			local var_2_5
			local var_2_6

			if arg_2_0.colorMode == xyd.ColorMode.ACTIVITY then
				var_2_4 = "#44454D"
				var_2_6 = 24
			else
				var_2_4 = "#44454D"
				var_2_6 = 24
			end

			arg_2_0.txtLabel = xyd.createAutoFixLabel({
				width = arg_2_0.txtWidth,
				height = arg_2_0.txtHeight,
				txtColor = var_2_4,
				text = arg_2_0.txt,
				fontSize = var_2_6,
				align = xyd.getTextAlign(arg_2_0.txtAlign),
				valign = xyd.getTextValign(arg_2_0.txtValign)
			})

			arg_2_0.txtLabel:addTo(arg_2_0.container)
			arg_2_0.txtLabel:setAnchorPoint(0.5, 0.5)
			arg_2_0.txtLabel:setPosition(arg_2_0.width / 2, arg_2_0.height / 2)
		end
	end

	if arg_2_0.isSplitLine then
		local var_2_7 = var_0_1.new({
			size = arg_2_0.width - 3
		})

		var_2_7:addTo(arg_2_0:background())
		var_2_7:setAnchorPoint(0.5, 0.5)
		var_2_7:setPosition(arg_2_0:nodeByName("pos_splitline"):getPosition())
	end

	if arg_2_0.colorMode == xyd.ColorMode.ACTIVITY then
		arg_2_0.leftBtn = var_0_2.new({
			titleSize = 24,
			sprite = "windows/button/btn195_1.png",
			title = arg_2_0.btnLeftName,
			clickMode = xyd.ButtonClickMode.SCALE
		})

		arg_2_0.leftBtn:addTo(arg_2_0:nodeByName("background"))
		arg_2_0.leftBtn:setAnchorPoint(0.5, 0.5)
		arg_2_0.leftBtn:setPosition(arg_2_0:nodeByName("pos_btn_left"):getPosition())

		arg_2_0.rightBtn = var_0_2.new({
			titleSize = 24,
			sprite = "windows/button/btn_orange_italic.png",
			title = arg_2_0.btnRightName,
			clickMode = xyd.ButtonClickMode.SCALE
		})

		arg_2_0.rightBtn:addTo(arg_2_0:nodeByName("background"))
		arg_2_0.rightBtn:setAnchorPoint(0.5, 0.5)
		arg_2_0.rightBtn:setPosition(arg_2_0:nodeByName("pos_btn_right"):getPosition())
	elseif arg_2_0.alertType == xyd.CommonAlertType.TWO_BTN then
		arg_2_0.leftBtn = var_0_2.new({
			titleSize = 24,
			sprite = "windows/button/btn195_1.png",
			title = arg_2_0.btnLeftName,
			clickMode = xyd.ButtonClickMode.SCALE
		})

		arg_2_0.leftBtn:addTo(arg_2_0:nodeByName("background"))
		arg_2_0.leftBtn:setAnchorPoint(0.5, 0.5)
		arg_2_0.leftBtn:setPosition(arg_2_0:nodeByName("pos_btn_left"):getPosition())

		arg_2_0.rightBtn = var_0_2.new({
			titleSize = 24,
			sprite = "windows/button/btn195_green.png",
			title = arg_2_0.btnRightName,
			clickMode = xyd.ButtonClickMode.SCALE
		})

		arg_2_0.rightBtn:addTo(arg_2_0:nodeByName("background"))
		arg_2_0.rightBtn:setAnchorPoint(0.5, 0.5)
		arg_2_0.rightBtn:setPosition(arg_2_0:nodeByName("pos_btn_right"):getPosition())
	else
		arg_2_0.middleBtn = var_0_2.new({
			titleSize = 24,
			sprite = "windows/button/btn195_2.png",
			title = arg_2_0.btnMiddleName,
			clickMode = xyd.ButtonClickMode.SCALE
		})

		arg_2_0.middleBtn:addTo(arg_2_0:nodeByName("background"))
		arg_2_0.middleBtn:setAnchorPoint(0.5, 0.5)
		arg_2_0.middleBtn:setPosition(arg_2_0:nodeByName("pos_btn_middle"):getPosition())
	end
end

return var_0_0
