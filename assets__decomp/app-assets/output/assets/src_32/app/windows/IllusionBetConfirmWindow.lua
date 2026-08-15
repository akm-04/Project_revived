local var_0_0 = class("IllusionBetConfirmWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.illusion = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
	arg_1_0.idx = arg_1_2.id
	arg_1_0.mana = arg_1_2.mana
	arg_1_0.preMana = arg_1_0.illusion.betInfo[arg_1_0.idx]
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.initEditBox(arg_3_0)
	arg_3_0.textInput = arg_3_0:nodeByName("text_input")

	arg_3_0.textInput:setString(arg_3_0.mana)

	local var_3_0 = arg_3_0:nodeByName("edit_box"):getContentSize()
	local var_3_1 = "windows/login/transparent.png"

	arg_3_0.editBox = ccui.EditBox:create(var_3_0, var_3_1)

	arg_3_0:nodeByName("edit_box"):addChild(arg_3_0.editBox)
	arg_3_0.editBox:setAnchorPoint(cc.p(0, 0))
	arg_3_0.editBox:setPosition(0, 0)
	arg_3_0.editBox:registerScriptEditBoxHandler(handler(arg_3_0, arg_3_0.inputContentbox))
	arg_3_0.editBox:setInputFlag(3)
	arg_3_0.editBox:setInputMode(cc.EDITBOX_INPUT_MODE_ANY)
	arg_3_0.editBox:setMaxLength(40)
end

function var_0_0.inputContentbox(arg_4_0, arg_4_1)
	if arg_4_1 == "began" then
		arg_4_0:nodeByName("text_input"):setVisible(false)

		if not arg_4_0.mana or arg_4_0.mana == "" then
			arg_4_0.textInput:setString("")
		else
			arg_4_0.editBox:setText(arg_4_0.textInput:getString())
		end
	elseif arg_4_1 == "return" then
		local var_4_0 = arg_4_0.editBox:getText()

		if var_4_0 == "" then
			arg_4_0.textInput:setString(arg_4_0.mana)
		elseif arg_4_0:checkStrInvalid(var_4_0) then
			arg_4_0.mana = math.ceil(tonumber(var_4_0))

			arg_4_0.textInput:setString(arg_4_0.mana)
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("ACTIVITY_GAMBLE_TEXT5")
			})
			arg_4_0.textInput:setString(arg_4_0.mana)
		end

		arg_4_0.editBox:setText("")
		arg_4_0.editBox:setVisible(true)
		arg_4_0:nodeByName("text_input"):setVisible(true)
	end
end

function var_0_0.checkStrInvalid(arg_5_0, arg_5_1)
	local var_5_0 = tonumber(arg_5_1)

	if var_5_0 and var_5_0 >= 0 and math.ceil(var_5_0) == var_5_0 then
		return true
	end

	return false
end

function var_0_0.layout(arg_6_0)
	arg_6_0:initEditBox()
	arg_6_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_7_0)
	arg_7_0:nodeByName("btn_plus1"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			if arg_7_0.mana + 100000 > xyd.tables.misc.illusionBetUpLimit then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_GAMBLE_TIP3")
				})
			else
				arg_7_0.mana = arg_7_0.mana + 100000

				arg_7_0.textInput:setString(arg_7_0.mana)
			end
		end
	end)
	arg_7_0:nodeByName("btn_plus2"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_7_0.mana + 1000000 > xyd.tables.misc.illusionBetUpLimit then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_GAMBLE_TIP3")
				})
			else
				arg_7_0.mana = arg_7_0.mana + 1000000

				arg_7_0.textInput:setString(arg_7_0.mana)
			end
		end
	end)
	arg_7_0:nodeByName("btn_plus3"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			if arg_7_0.mana + 10000000 > xyd.tables.misc.illusionBetUpLimit then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_GAMBLE_TIP3")
				})
			else
				arg_7_0.mana = arg_7_0.mana + 10000000

				arg_7_0.textInput:setString(arg_7_0.mana)
			end
		end
	end)
	arg_7_0:nodeByName("btn_yes"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			if arg_7_0.mana - arg_7_0.preMana > arg_7_0.player.mana then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_GAMBLE_TEXT6")
				})
			elseif arg_7_0.mana > xyd.tables.misc.illusionBetUpLimit then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_GAMBLE_TIP3")
				})
			elseif arg_7_0.mana < xyd.tables.misc.illusionBetDownLimit then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_GAMBLE_TIP4")
				})
			elseif arg_7_0.mana < arg_7_0.preMana then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_GAMBLE_TEXT7")
				})
			else
				arg_7_0.illusion.betPreSetInfo[arg_7_0.idx] = arg_7_0.mana

				local var_11_0 = xyd.WindowManager.get():getWindow("illusion_bet")

				if var_11_0 and not tolua.isnull(var_11_0) then
					var_11_0:updateListInfo()
					var_11_0.list:reload()
				end

				xyd.WindowManager.get():closeWindow(arg_7_0)
			end
		end
	end)
	arg_7_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_7_0)
		end
	end)
end

function var_0_0.didOpen(arg_13_0, arg_13_1)
	return
end

return var_0_0
