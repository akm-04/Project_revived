local var_0_0 = class("TeamConnectPresidentWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.p_id = arg_1_2.p_id
	arg_1_0.p_name = arg_1_2.p_name
	arg_1_0.message = ""
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("to_words"):setString(var_0_2:translation("SEND_TO"))

	local var_4_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_4_0, cc.rect(28, 28, 1, 1))

	arg_4_0.sidEditbox_ = ccui.EditBox:create(cc.size(arg_4_0:nodeByName("kuang"):getWidth(), arg_4_0:nodeByName("kuang"):getHeight()), var_4_0):align(display.CENTER, arg_4_0:nodeByName("kuang"):getX(), arg_4_0:nodeByName("kuang"):getY()):addTo(arg_4_0:nodeByName("container"))

	arg_4_0.sidEditbox_:registerScriptEditBoxHandler(handler(arg_4_0, arg_4_0.inputboxEventHandler))
	arg_4_0.sidEditbox_:setInputFlag(3)
	arg_4_0:nodeByName("name_text"):setString(arg_4_0.p_name)
	arg_4_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			if arg_4_0.p_id == var_5_0.playerID then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("CANT_TALK_SELF")
				})
			elseif arg_4_0.p_id and arg_4_0.p_id ~= 0 then
				params = {
					channel = 1,
					message = arg_4_0.message,
					to_player_id = arg_4_0.p_id
				}

				local var_5_1 = arg_4_0.message

				xyd.Backend.get():request(xyd.mid.CHAT_TO_PLAYER, params, function(arg_6_0, arg_6_1, arg_6_2)
					if arg_6_0 == xyd.error.OK then
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.PERSONAL_CHAT_MESSAGE,
							params = {
								message = var_5_1,
								from_player_id = var_5_0.playerID,
								player_name = var_5_0.playerName
							}
						})
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("SEND_OK")
						})
					end

					xyd.WindowManager.get():closeWindow(arg_4_0)
				end)
			else
				xyd.WindowManager.get():closeWindow(arg_4_0)
			end
		end
	end)
	arg_4_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_7_0, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.inputboxEventHandler(arg_8_0, arg_8_1)
	if arg_8_1 == "began" then
		arg_8_0.sidEditbox_:setText(arg_8_0:nodeByName("message_text"):getString())
		arg_8_0:nodeByName("message_text"):setString("")
	end

	if arg_8_1 == "return" then
		local var_8_0 = arg_8_0.sidEditbox_:getText()
		local var_8_1 = xyd.getTextLen(var_8_0)

		arg_8_0:nodeByName("message_text"):setString(var_8_0)

		arg_8_0.message = var_8_0

		arg_8_0.sidEditbox_:setText("")
		arg_8_0.sidEditbox_:setVisible(true)
	end
end

return var_0_0
