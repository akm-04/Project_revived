local var_0_0 = class("EditNameWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "edit_name"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)
end

function var_0_0.layout(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("background"):setContentSize(cc.size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))

	local var_2_0 = xyd.tables.translation
	local var_2_1 = arg_2_0:nodeByName("Label_enter_name")
	local var_2_2 = arg_2_0:nodeByName("Label_ok")

	var_2_1:setString(var_2_0:translation("ENTER_YOUR_PLAYER_NAME"))
	var_2_2:setString(var_2_0:translation("OK"))
	xyd.formatUIText(var_2_1, function(arg_3_0)
		arg_3_0:getVirtualRenderer():setAdditionalKerning(7)
	end)
	xyd.formatUIText(var_2_2, function(arg_4_0)
		arg_4_0:enableShadow()
	end)

	arg_2_0.okButton_ = arg_2_0:nodeByName("Button_ok")

	arg_2_0.okButton_:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = arg_2_0.editBox_:getText()

			if arg_2_0:checkName(var_5_0) then
				arg_2_0:editName(var_5_0)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, arg_2_0.alertMsg_, nil, nil, nil, arg_2_0.colorMode)

				arg_2_0.alertMsg_ = nil
			end
		end
	end)

	local var_2_3 = arg_2_0:nodeByName("edit_box_bg")
	local var_2_4 = var_2_3:getContentSize().width
	local var_2_5 = var_2_3:getContentSize().height
	local var_2_6 = 8

	arg_2_0.editBoxContainer_ = arg_2_0:nodeByName("edit_box_container")

	local var_2_7 = var_2_4 - var_2_6 * 2
	local var_2_8 = var_2_5 - var_2_6 * 2

	arg_2_0.editBoxContainer_:setContentSize(cc.size(var_2_7, var_2_8))

	local var_2_9 = xyd.AssetLoader.get():loadSprite("images/edit_name_box.png", cc.rect(18, 30, 1, 1))

	arg_2_0.editBox_ = ccui.EditBox:create(arg_2_0.editBoxContainer_:getContentSize(), var_2_9)

	arg_2_0.editBox_:setAnchorPoint(cc.p(0, 0))

	local var_2_10 = 20

	arg_2_0.editBox_:setFont(xyd.AssetLoader.get().FONT_NAME, var_2_10)
	arg_2_0.editBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_2_0.editBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_2_0.editBox_:setInputMode(cc.EDITBOX_INPUT_MODE_ANY)
	arg_2_0.editBox_:setInputFlag(3)

	local var_2_11 = var_2_0:translation("PLAYER_NAME_CONSTRAINT")

	arg_2_0.editBox_:setPlaceHolder(var_2_11)
	arg_2_0.editBox_:pos(0, 0):addTo(arg_2_0.editBoxContainer_)
end

function var_0_0.editBoxHandler(arg_6_0, arg_6_1)
	if arg_6_1 == "return" then
		local var_6_0 = xyd.tables.translation
		local var_6_1 = arg_6_0.editBox_:getText()

		if #var_6_1 == 0 then
			return
		end

		if arg_6_0:checkName(var_6_1) then
			arg_6_0:editName(var_6_1)
		else
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_6_0:translation("INVALID_PLAYER_NAME"), nil, nil, arg_6_0.colorMode)
		end
	end
end

function var_0_0.checkName(arg_7_0, arg_7_1)
	local var_7_0 = 0
	local var_7_1 = true

	for iter_7_0 = 1, string.utf8len(arg_7_1) do
		local var_7_2 = xyd.utf8str(arg_7_1, iter_7_0, 1)

		for iter_7_1 = 1, string.len(var_7_2) do
			print(string.format("%d byte: 0x%x", iter_7_1, string.byte(var_7_2, iter_7_1)))
		end

		if string.match(var_7_2, "[0-9a-zA-Z]") then
			print("english char")

			var_7_0 = var_7_0 + 1
		elseif string.len(var_7_2) > 1 and string.match(var_7_2, "[^N-\x9F]") then
			print("chinese char")

			var_7_0 = var_7_0 + 2
		else
			print("invalid char:", var_7_2)

			var_7_1 = false

			break
		end
	end

	arg_7_0.alertMsg_ = nil

	local var_7_3 = xyd.tables.translation

	if not var_7_1 then
		arg_7_0.alertMsg_ = var_7_3:translation("INVALID_PLAYER_NAME")
	elseif var_7_0 < xyd.tables.misc.playerNameMinLength then
		var_7_1 = false
		arg_7_0.alertMsg_ = var_7_3:translation("PLAYER_NAME_TOO_SHORT")
	elseif var_7_0 > xyd.tables.misc.playerNameMaxLength then
		var_7_1 = false
		arg_7_0.alertMsg_ = var_7_3:translation("PLAYER_NAME_TOO_LONG")
	end

	local var_7_4, var_7_5 = arg_7_0.filterWord:warningStrGsub(arg_7_1)

	if var_7_5 then
		var_7_1 = false
		arg_7_0.alertMsg_ = var_7_3:translation("INPUT_WITH_BAD_WORDS")
	end

	return var_7_1
end

function var_0_0.editName(arg_8_0, arg_8_1)
	local var_8_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_8_1 = {
		player_name = arg_8_1
	}
	local var_8_2 = xyd.tables.translation

	var_8_0:editName(var_8_1, xyd.backendCallbackWrapper(var_0_1, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			xyd.StoryData.get():setStoryID(1)
			xyd.StoryData.get():persist()
			arg_8_0.editBox_:removeFromParent(true)
			display.replaceScene(xyd.MainScene.new())
		else
			xyd.errorAlert(arg_9_1, var_8_2:translation("DUPLICATE_PLAYER_NAME"))
		end
	end))
end

return var_0_0
