local var_0_0 = class("InputInviteCodeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.invite = xyd.ModelManager.get():loadModel(xyd.ModelType.INVITE_FRIENDS_INFOS)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layOut()
end

function var_0_0.inputboxEventHandler(arg_3_0, arg_3_1)
	if arg_3_1 == "began" then
		arg_3_0.nameEditbox_:setText(arg_3_0:nodeByName("name_txt"):getString())
		arg_3_0:nodeByName("place_holder"):setString("")
		arg_3_0:nodeByName("name_txt"):setString("")
	end

	if arg_3_1 == "return" then
		local var_3_0 = arg_3_0.nameEditbox_:getText()

		arg_3_0:nodeByName("name_txt"):setString(var_3_0)
		arg_3_0.nameEditbox_:setText("")

		if arg_3_0:nodeByName("name_txt"):getString() == "" then
			arg_3_0:nodeByName("place_holder"):setString(var_0_1:translation("INPUT_EXCHANGE_CODE"))
		else
			arg_3_0:nodeByName("place_holder"):setString("")
		end
	end
end

function var_0_0.layOut(arg_4_0)
	arg_4_0:nodeByName("ok_text"):setString(var_0_1:translation("OK"))
	arg_4_0:nodeByName("close_text"):setString(var_0_1:translation("CANCEL"))
	arg_4_0:nodeByName("input_desc"):setString(var_0_1:translation("INPUT_INVITE_CODE") .. var_0_1:translation("COLON"))
	arg_4_0:nodeByName("name_txt"):setString("")

	local var_4_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_4_0, cc.rect(28, 28, 1, 1))

	arg_4_0.nameEditbox_ = ccui.EditBox:create(cc.size(375, 40), var_4_0)

	arg_4_0:nodeByName("edit_container"):addChild(arg_4_0.nameEditbox_)
	arg_4_0.nameEditbox_:setAnchorPoint(cc.p(0, 0))
	arg_4_0.nameEditbox_:setPosition(0, 0)

	if arg_4_0:nodeByName("name_txt"):getString() == "" then
		arg_4_0:nodeByName("place_holder"):setString(var_0_1:translation("INPUT_INVITE_CODE"))
	else
		arg_4_0:nodeByName("place_holder"):setString("")
	end

	arg_4_0.nameEditbox_:registerScriptEditBoxHandler(handler(arg_4_0, arg_4_0.inputboxEventHandler))
	arg_4_0.nameEditbox_:setInputFlag(3)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = {
				invite_code = arg_5_0:nodeByName("name_txt"):getString()
			}

			xyd.Backend.get():request(xyd.mid.SEND_INVITE_CODE, var_6_0, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					arg_5_0.invite:setInvitorName(arg_7_1.invitor_name)
					arg_5_0.invite:setInvitorId(arg_7_1.invitor_id)

					local var_7_0 = string.format(var_0_1:translation("HAS_BEEN_INVITED"), arg_7_1.invitor_name)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_7_0
					})

					local var_7_1 = xyd.WindowManager.get():getWindow("invite_friends")

					if var_7_1 then
						var_7_1:layOut()
					end

					xyd.WindowManager.get():closeWindow("input_invite_code")
				elseif arg_7_1.error_code == 20033 then
					local var_7_2 = xyd.tables.message:getContent(20033)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_7_2
					})
				else
					local var_7_3 = var_0_1:translation("INVALID_CODE2")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_7_3
					})
				end
			end)
		end
	end)
	arg_5_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
