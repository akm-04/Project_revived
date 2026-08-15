local var_0_0 = class("TeamSettingDataWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc.guildBulletinMaxCharNum
local var_0_5 = xyd.tables.misc.guildBulletinMinCharNum

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.teamDes = arg_2_0.guild.guild_des

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.teamDes == nil then
		arg_4_0.teamDes = var_0_3:translation("TEAM_JOIN_ITEM_DEFAULT_DES")
	end

	arg_4_0:nodeByName("title_words"):setString(var_0_3:translation("GUILD_SETTING_DATA_TITLE"))
	arg_4_0:nodeByName("tips"):setString(var_0_3:translation("SHE_TUAN_TEXT_14"))
	arg_4_0:nodeByName("text_cancel"):setString(var_0_3:translation("SHE_TUAN_TEXT_16"))
	arg_4_0:nodeByName("text_sure"):setString(var_0_3:translation("SHE_TUAN_TEXT_15"))

	local var_4_0 = var_0_2.new({
		size = 500
	})

	var_4_0:addTo(arg_4_0:nodeByName("line"))
	var_4_0:setAnchorPoint(0, 0.5)

	local var_4_1 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_4_1, cc.rect(28, 28, 1, 1))

	arg_4_0.sidEditbox_ = ccui.EditBox:create(cc.size(arg_4_0:nodeByName("kuang"):getWidth(), arg_4_0:nodeByName("kuang"):getHeight()), var_4_1):align(display.LEFT_BOTTOM, arg_4_0:nodeByName("kuang"):getX(), arg_4_0:nodeByName("kuang"):getY()):addTo(arg_4_0:nodeByName("container"))

	arg_4_0.sidEditbox_:registerScriptEditBoxHandler(handler(arg_4_0, arg_4_0.inputboxEventHandler))
	arg_4_0.sidEditbox_:setInputFlag(3)

	arg_4_0.editY = arg_4_0:nodeByName("kuang"):getY()

	arg_4_0:nodeByName("data_text"):setString(arg_4_0.teamDes)
	arg_4_0:nodeByName("change_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("change_btn"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if var_0_5 > 0 and xyd.getTextLen(arg_4_0.teamDes) < var_0_5 then
				local var_5_0 = string.format(var_0_3:translation("TEAM_NOTICE_LIMMIT_MIN_ALERT"), var_0_5)

				xyd.commonAlertWindow.open(xyd.commonAlertType.ONE_BTN, var_5_0, nil, nil, nil, arg_4_0.colorMode)
			else
				local var_5_1 = {
					des = arg_4_0.teamDes
				}

				arg_4_0.guild:updateDes(var_5_1, function(arg_6_0)
					if arg_6_0 == xyd.error.OK then
						return true
					end
				end)
				xyd.WindowManager.get():closeWindow(arg_4_0)
			end
		end
	end)
	arg_4_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("cancel_btn"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_7_0, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.inputboxEventHandler(arg_8_0, arg_8_1)
	if arg_8_1 == "began" then
		arg_8_0.sidEditbox_:setPositionY(-1000)

		local var_8_0 = arg_8_0.filterWord:warningStrGsub(arg_8_0:nodeByName("data_text"):getString())

		arg_8_0.sidEditbox_:setText(var_8_0)
		arg_8_0:nodeByName("data_text"):setString("")
	end

	if arg_8_1 == "return" then
		local var_8_1 = arg_8_0.filterWord:warningStrGsub(arg_8_0.sidEditbox_:getText())

		if xyd.getTextLen(var_8_1) <= var_0_4 then
			local var_8_2 = arg_8_0.filterWord:warningStrGsub(arg_8_0.sidEditbox_:getText())

			arg_8_0:nodeByName("data_text"):setString(var_8_2)

			arg_8_0.teamDes = var_8_2
		else
			local var_8_3 = string.format(var_0_3:translation("TEAM_NOTICE_LIMMIT_ALERT"), var_0_4)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_8_3, nil, nil, nil, arg_8_0.colorMode)
		end

		arg_8_0.sidEditbox_:setText("")
		arg_8_0.sidEditbox_:setVisible(true)
		arg_8_0.sidEditbox_:setPositionY(arg_8_0.editY)
	end
end

return var_0_0
